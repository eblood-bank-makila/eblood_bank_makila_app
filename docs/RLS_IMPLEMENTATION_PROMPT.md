# Row Level Security (RLS) — Full Implementation Prompt

> **Purpose**: This document is a complete, self-contained specification for implementing Row Level Security on a multi-tenant SaaS backend. It describes the exact architecture, data model, middleware flow, query-layer integration, and edge cases — with enough detail that a developer can implement it from scratch on any FastAPI + MongoDB stack.

---

## 1. WHAT IS RLS AND WHY IT MATTERS

Row Level Security restricts **which database rows** a user can see or modify, based on their identity and the organization they belong to. Unlike RBAC (which controls **what operations** a user can perform), RLS controls **which data** is visible within an operation.

In a multi-tenant SaaS:
- Every organization independently enables/disables RLS
- Every organization independently toggles strict vs. permissive mode
- Every endpoint can have RLS enabled or disabled per-organization
- Users can be globally whitelisted (see everything) or blacklisted (see nothing)
- Users can have per-endpoint access at the row level (see only specific documents)
- Users can be assigned to security groups for bulk access management
- RLS applies to ALL HTTP methods (GET/POST/PUT/PATCH/DELETE) — not just reads

**RLS is NOT controlled by env vars or global flags.** Every tenant configures it independently through database-stored configuration models.

---

## 2. DATA MODEL (5 MongoDB collections)

### 2.1 `cfgRlsSetup` — Organization Master Switch

**One document per organization.** Controls whether RLS is enabled org-wide.

```
{
  "_id": ObjectId,
  "identifier": "a1b2c3d4",          // auto-generated 8-char hex
  "is_enabled": false,                // MASTER SWITCH — if false, RLS is off for entire org
  "is_strict_mode": false,            // strict = deny by default; permissive = allow by default
  "strict_mode_message": "...",       // user-facing message when strict mode active
  "no_strict_mode_message": "...",    // user-facing message when permissive mode active
  "sys_organization_id": ObjectId,    // FK to the organization
  "soft_deleted_at": null,
  "created_at": ISODate,
  "updated_at": ISODate
}
```

**Admin endpoints:**
- `GET /security/rls/settings` — read current setup
- `PATCH /security/rls/protection-settings` — toggle `is_enabled`
- `PATCH /security/rls/strict-settings` — toggle `is_strict_mode`

### 2.2 `cfgOrganizationRls` — Per-Endpoint RLS Activation

**One document per (organization, endpoint, permission) triplet.** Controls whether a specific API endpoint has RLS enabled for this org.

```
{
  "_id": ObjectId,
  "identifier": "e5f6g7h8",
  "is_enabled": false,                // if false, this endpoint skips RLS for this org
  "is_strict_mode": false,            // per-endpoint strict mode override
  "strict_mode_message": "...",
  "no_strict_mode_message": "...",
  "rbac_endpoint_id": ObjectId,       // FK to the RBAC endpoint (matched by URL)
  "rbac_permission_id": ObjectId,     // FK to the RBAC permission
  "sys_organization_id": ObjectId,
  "soft_deleted_at": null
}
```

**Created during org setup:** For every RBAC endpoint with `is_available_for_rls = true`, one `cfgOrganizationRls` row is seeded with `is_enabled: false`. The org admin then enables specific endpoints.

### 2.3 `cfgRlsAccesses` — Access Grants (whitelist / blacklist / custom)

**The core grant table.** Each document says "user X (or group G) has access type T to resource R."

```
{
  "_id": ObjectId,
  "identifier": "i9j0k1l2",
  "targeted_id": ObjectId,            // the user ID or security group ID
  "targeted_type": "user",            // "user" | "sudo_rls_security_group"
  "rls_access_type": "global_access", // "global_access" | "revoked_access" | "custom_access"
  "cfg_organization_rls_id": null,    // null = GLOBAL grant; ObjectId = per-endpoint grant
  "collection_name": null,            // only for custom_access: target collection name
  "targeted_row_id": null,            // only for custom_access: specific document ID
  "sys_organization_id": ObjectId,
  "soft_deleted_at": null
}
```

**TWO LEVELS OF GRANTS:**

**Level 1 — Global grants** (`cfg_organization_rls_id == null`):
- Apply to ALL RLS-protected endpoints in the org
- `rls_access_type = "global_access"` → user is **globally whitelisted** (skip all RLS filtering)
- `rls_access_type = "revoked_access"` → user is **globally blacklisted** (deny everything)

**Level 2 — Per-endpoint grants** (`cfg_organization_rls_id = <ObjectId>`):
- Apply only to the endpoint identified by the linked `cfgOrganizationRls` document
- `rls_access_type = "global_access"` → user can access all data from this endpoint
- `rls_access_type = "revoked_access"` → user cannot access data from this endpoint
- `rls_access_type = "custom_access"` → user can only access the specific row identified by `targeted_row_id` in `collection_name`

**Priority order:** REVOKED always wins over GLOBAL, which wins over CUSTOM.

### 2.4 `refSudoRlsSecurityGroups` — Security Group Definitions

```
{
  "_id": ObjectId,
  "identifier": "m3n4o5p6",
  "name": "Finance Team",
  "description_str": "Access to financial data",
  "sys_organization_id": ObjectId
}
```

### 2.5 `refSudoRlsSecurityGroupUsers` — Group Membership

```
{
  "_id": ObjectId,
  "identifier": "q7r8s9t0",
  "ref_sudo_rls_security_group_id": ObjectId,  // FK to security group
  "sys_user_id": ObjectId,                      // FK to user
  "sys_organization_id": ObjectId
}
```

### 2.6 Enum Values

```python
class ERlsAccessTypeFlag(str, Enum):
    GLOBAL_ACCESS = "global_access"      # whitelist — user sees all data
    REVOKED_ACCESS = "revoked_access"    # blacklist — user sees nothing
    CUSTOM_ACCESS = "custom_access"      # row-level — user sees specific rows only
    NONE = "none"

class ESudoActionAccessTargetedTypeFlag(str, Enum):
    USER = "user"
    SUDO_RLS_SECURITY_GROUP = "sudo_rls_security_group"
```

---

## 3. ARCHITECTURE — THREE LAYERS

```
┌──────────────────────────────────────────────────────────────┐
│  LAYER 1: MIDDLEWARE (runs once per request)                  │
│  RowLevelSecurityMiddleware                                   │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ 1. Get authenticated user                              │  │
│  │ 2. Check CfgRlsSetup → org master switch              │  │
│  │ 3. Resolve user's security group memberships           │  │
│  │ 4. LEVEL 1: Check global whitelist/blacklist           │  │
│  │ 5. LEVEL 2: Match URL → endpoint → CfgOrganizationRls │  │
│  │ 6. Fetch per-endpoint grants, classify access type     │  │
│  │ → Sets request.state.rls_context                       │  │
│  └────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────┤
│  LAYER 2: CONTEXT BRIDGE (passes context through user dict)  │
│  AuthenticatedService.get_user_info()                        │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Reads request.state.rls_context                        │  │
│  │ Attaches to user_details["_rls_context"]               │  │
│  │ Returns enriched user dict to controller               │  │
│  └────────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────┤
│  LAYER 3: QUERY FILTER (modifies every DB query)             │
│  GenericService._apply_rls_filter()                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ Reads user["_rls_context"]                             │  │
│  │ FAST PATH: skip/global/revoked/custom/none             │  │
│  │ Returns modified db_filter before DAO executes query   │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

---

## 4. LAYER 1 — THE MIDDLEWARE (complete logic)

### 4.1 Position in Middleware Stack

The RLS middleware **MUST** run after the authentication middleware (because it needs the authenticated user) and before any business logic middleware.

```
Request
  → AuthMiddleware              (authenticates user, sets request.state.user)
  → RowLevelSecurityMiddleware  (resolves RLS context, sets request.state.rls_context)
  → PermissionMiddleware        (RBAC checks)
  → Route Handler
```

### 4.2 Resolution Flow (6 steps)

```python
class RowLevelSecurityMiddleware:
    async def dispatch(self, request, call_next):
        try:
            # ── EXCLUSIONS ────────────────────────────────────────
            # Skip for auth routes, websocket routes, health checks
            # where no authenticated user is expected.
            if is_excluded_route(request.url.path):
                request.state.rls_context = SKIP_CONTEXT
                return await call_next(request)

            # ── STEP 1: Get authenticated user ────────────────────
            user = request.state.user
            if not user:
                request.state.rls_context = SKIP_CONTEXT
                return await call_next(request)
            
            user_id = user["id"]
            org_id = user["sys_organization_id"]
            # Handle nested dict: org_id might be {"id": "...", "_id": "..."}
            if isinstance(org_id, dict):
                org_id = org_id.get("id") or org_id.get("_id")

            # ── STEP 2: Org master switch ─────────────────────────
            # Query cfgRlsSetup where sys_organization_id = org_id
            # Use a RAW query method that bypasses RLS (avoid recursion!)
            rls_setup = await db.cfgRlsSetup.find_one({
                "sys_organization_id": ObjectId(org_id),
                "soft_deleted_at": None
            })
            if not rls_setup or not rls_setup["is_enabled"]:
                request.state.rls_context = SKIP_CONTEXT
                return await call_next(request)
            
            setup_strict_mode = rls_setup.get("is_strict_mode", False)

            # ── STEP 3: Resolve user's group memberships ──────────
            # Query refSudoRlsSecurityGroupUsers where
            #   sys_user_id = user_id AND sys_organization_id = org_id
            targeted_ids = [ObjectId(user_id)]
            memberships = await db.refSudoRlsSecurityGroupUsers.find({
                "sys_user_id": ObjectId(user_id),
                "sys_organization_id": ObjectId(org_id),
                "soft_deleted_at": None
            }).to_list()
            for m in memberships:
                targeted_ids.append(m["ref_sudo_rls_security_group_id"])

            # ── STEP 4: LEVEL 1 — Global whitelist/blacklist ─────
            # Query cfgRlsAccesses where
            #   cfg_organization_rls_id IS NULL (global scope)
            #   targeted_id IN targeted_ids
            #   sys_organization_id = org_id
            global_grants = await db.cfgRlsAccesses.find({
                "sys_organization_id": ObjectId(org_id),
                "cfg_organization_rls_id": None,
                "targeted_id": {"$in": targeted_ids},
                "soft_deleted_at": None
            }).to_list()

            # REVOKED wins over everything — check first
            for grant in global_grants:
                if grant["rls_access_type"] == "revoked_access":
                    request.state.rls_context = DENY_CONTEXT
                    return await call_next(request)
            
            # GLOBAL_ACCESS = user is org-wide whitelisted
            for grant in global_grants:
                if grant["rls_access_type"] == "global_access":
                    request.state.rls_context = {
                        "skip": False,
                        "is_strict_mode": setup_strict_mode,
                        "user_access": "global",
                        "custom_rows": {}
                    }
                    return await call_next(request)

            # ── STEP 5: LEVEL 2 — Per-endpoint RLS ───────────────
            # Match current URL → RBAC endpoint → CfgOrganizationRls
            
            # 5a. Find the RBAC endpoint by exact URL match
            rbac_endpoint = await db.rbacEndpoints.find_one({
                "url": request.url.path.strip(),
                "soft_deleted_at": None
            })
            if not rbac_endpoint:
                # Endpoint not in RBAC table → RLS cannot apply
                request.state.rls_context = SKIP_CONTEXT
                return await call_next(request)
            
            # 5b. Find the org's RLS config for this endpoint
            org_rls = await db.cfgOrganizationRls.find_one({
                "rbac_endpoint_id": rbac_endpoint["_id"],
                "sys_organization_id": ObjectId(org_id),
                "soft_deleted_at": None
            })
            if not org_rls or not org_rls["is_enabled"]:
                # This endpoint doesn't have RLS enabled for this org
                request.state.rls_context = SKIP_CONTEXT
                return await call_next(request)
            
            endpoint_strict = org_rls.get("is_strict_mode", False)
            is_strict_mode = setup_strict_mode or endpoint_strict

            # ── STEP 6: Fetch per-endpoint grants ────────────────
            endpoint_grants = await db.cfgRlsAccesses.find({
                "cfg_organization_rls_id": org_rls["_id"],
                "targeted_id": {"$in": targeted_ids},
                "soft_deleted_at": None
            }).to_list()

            # Classify grants
            has_revoked = False
            has_global = False
            custom_rows = {}  # {collection_name: [ObjectId, ...]}

            for grant in endpoint_grants:
                access_type = grant["rls_access_type"]
                if access_type == "revoked_access":
                    has_revoked = True
                elif access_type == "global_access":
                    has_global = True
                elif access_type == "custom_access":
                    coll = grant.get("collection_name")
                    row_id = grant.get("targeted_row_id")
                    if coll and row_id:
                        custom_rows.setdefault(coll, []).append(ObjectId(str(row_id)))

            # Priority: REVOKED > GLOBAL > CUSTOM > None
            if has_revoked:
                user_access = "revoked"
            elif has_global:
                user_access = "global"
            elif custom_rows:
                user_access = "custom"
            else:
                user_access = None

            request.state.rls_context = {
                "skip": False,
                "is_strict_mode": is_strict_mode,
                "user_access": user_access,
                "custom_rows": custom_rows
            }
            return await call_next(request)

        except Exception as e:
            # FAIL-CLOSED: any unhandled error → deny everything
            print(f"[RLS MW] fail-closed error: {e}")
            request.state.rls_context = DENY_CONTEXT
            return await call_next(request)
```

### 4.3 Sentinel Contexts

```python
SKIP_CONTEXT = {
    "skip": True,
    "is_strict_mode": False,
    "user_access": None,
    "custom_rows": {}
}

DENY_CONTEXT = {
    "skip": False,
    "is_strict_mode": True,
    "user_access": "revoked",
    "custom_rows": {}
}
```

### 4.4 Critical Rule: Middleware DB Queries Must Bypass RLS

The middleware queries `cfgRlsSetup`, `cfgRlsAccesses`, `cfgOrganizationRls`, `rbacEndpoints`, and `refSudoRlsSecurityGroupUsers`. These queries **MUST NOT** go through the RLS filter, otherwise you get infinite recursion:

```
Middleware → query cfgRlsSetup → _apply_rls_filter → calls middleware logic → query cfgRlsSetup → ∞
```

**Solutions (pick one):**
- Use a raw database query method that doesn't go through the generic service
- Add a `_skip_rls: bool` parameter to your fetch methods and set it to `True` for these internal queries
- Maintain a `RLS_META_COLLECTIONS` set of collection names that are always exempt from RLS

We use **all three**: the middleware uses `fetch_native_query_one_from_collection` (raw, no RLS hook), the service uses `_skip_rls=True`, and `_apply_rls_filter` checks against `RLS_META_COLLECTIONS`:

```python
RLS_META_COLLECTIONS = frozenset({
    "cfgRlsSetup",
    "cfgOrganizationRls",
    "cfgRlsAccesses",
    "refSudoRlsSecurityGroups",
    "refSudoRlsSecurityGroupUsers",
})
```

---

## 5. LAYER 2 — CONTEXT BRIDGE

The middleware sets `request.state.rls_context`. But the generic service (which applies the filter) doesn't have access to `request` — it only receives a `user: dict` parameter from the controller.

**Bridge pattern:** In the authentication service's `get_user_info(request)` method, after building the user dict, attach the RLS context:

```python
@staticmethod
async def get_user_info(request, accept_language='fr') -> dict:
    user_details = request.state.user
    # ... existing authentication logic ...

    # Bridge: attach RLS context to user dict so it flows to the generic service
    rls_context = getattr(request.state, "rls_context", None)
    if rls_context is not None:
        user_details["_rls_context"] = rls_context

    return user_details
```

This must be done at **every return point** of every `get_user_info` variant (there may be multiple: `get_user_info`, `get_optional_user_info`, `get_user_info_from_unsecured_path`, etc.).

---

## 6. LAYER 3 — QUERY FILTER (the single chokepoint)

### 6.1 Where to Hook

Every method that queries the database must pass through a single `_apply_rls_filter` method. In our implementation, these are 5 methods:

| Method | Type | RLS Hook |
|--------|------|----------|
| `fetch_data_from_collection` | List query (find) | `_apply_rls_filter` modifies `db_filter` |
| `fetch_one_from_collection` | Single doc (find_one) | `_apply_rls_filter` modifies `db_filter` |
| `count_data_from_collection` | Count | `_apply_rls_filter` modifies `db_filter` |
| `fetch_native_query_data_from_collection` | Raw list query | `_apply_rls_filter` modifies `db_filter` |
| `fetch_native_aggregate_data_from_collection` | Aggregation pipeline | Prepends `{"$match": rls_filter}` to pipeline |

Each method accepts:
- `user: Optional[Dict] = None` — the user dict (with `_rls_context` attached)
- `_skip_rls: bool = False` — escape hatch for internal RLS queries

### 6.2 `_apply_rls_filter` Logic

```python
async def _apply_rls_filter(self, collection_key, db_filter, user):
    db_filter = db_filter or {}

    # ── Skip conditions ───────────────────────────────────
    # 1. RLS meta-collections (avoid recursion)
    if collection_key in RLS_META_COLLECTIONS:
        return db_filter

    # 2. Non-tenant-scoped collections (global refs: countries, currencies, etc.)
    #    Determined by checking if the model has a sys_organization_id field.
    if not is_tenant_scoped(collection_key):
        return db_filter

    # ── Fast path: middleware already resolved everything ──
    rls_ctx = (user or {}).get("_rls_context")
    if rls_ctx:
        if rls_ctx.get("skip"):
            return db_filter  # RLS disabled for this org/endpoint

        access = rls_ctx.get("user_access")

        if access == "global":
            # Whitelisted → see all rows, scoped to org
            return inject_org_filter(db_filter, user)

        if access == "revoked":
            # Blacklisted → see nothing
            return {"_id": {"$in": []}}

        if access == "custom":
            # Only specific rows
            row_ids = rls_ctx.get("custom_rows", {}).get(collection_key.value, [])
            if row_ids:
                org_filter = inject_org_filter(db_filter, user)
                return {"$and": [org_filter, {"_id": {"$in": row_ids}}]}
            # No rows for THIS collection
            if rls_ctx.get("is_strict_mode"):
                return {"_id": {"$in": []}}  # Deny
            return inject_org_filter(db_filter, user)  # Permissive

        # access is None — no grants
        if rls_ctx.get("is_strict_mode"):
            return {"_id": {"$in": []}}  # Strict: deny
        return inject_org_filter(db_filter, user)  # Permissive: org scope only

    # ── Fallback: no middleware context (internal/batch calls) ──
    # Query RLS config from DB directly (slower, used by cron jobs, seeds, etc.)
    return await rls_service.resolve_filter(collection_key, user, db_filter)
```

### 6.3 `inject_org_filter` — Defence-in-Depth

Even when RLS is disabled or the user is whitelisted, always add `sys_organization_id` to the filter for tenant-scoped collections. This prevents cross-tenant data leaks:

```python
def inject_org_filter(db_filter, user):
    if not user or not user.get("sys_organization_id"):
        return db_filter
    
    org_id = user["sys_organization_id"]
    
    # Don't override if caller already specified sys_organization_id
    if "sys_organization_id" in db_filter:
        return db_filter
    
    new_filter = dict(db_filter)
    new_filter["sys_organization_id"] = org_id
    return new_filter
```

### 6.4 Tenant Scoping — Auto-Detection

Not all collections are tenant-scoped. Global reference tables (countries, currencies, RBAC roles) don't have `sys_organization_id` and must be exempt from RLS. Auto-detect at app startup:

```python
def is_tenant_scoped(model_class) -> bool:
    """True if model declares a sys_organization_id field."""
    return "sys_organization_id" in model_class.model_fields

# At mapping construction time, add this flag to each collection's metadata:
metadata.is_tenant_scoped = is_tenant_scoped(metadata.model_class)
```

### 6.5 Aggregation Pipelines — Prepend, Don't Append

For aggregation pipelines, the RLS filter must be **prepended** as the first `$match` stage. If you append it after `$lookup`/`$group`, the pipeline processes unfiltered data first, which is both a security hole and a performance disaster:

```python
if not _skip_rls:
    rls_filter = await self._apply_rls_filter(collection_key, {}, user)
    if rls_filter:
        pipeline = [{"$match": rls_filter}] + pipeline
```

---

## 7. THE `rls_context` SCHEMA

```python
{
    "skip": bool,              # True = RLS disabled for this org/endpoint/user
    "is_strict_mode": bool,    # True = deny by default (no grant = no access)
    "user_access": str | None, # "global" | "revoked" | "custom" | None
    "custom_rows": dict        # {"collectionName": [ObjectId, ...]} 
}
```

---

## 8. RLS SERVICE (fallback for internal/batch calls)

When code runs outside an HTTP request (cron jobs, seed scripts, background tasks), there's no middleware and no `_rls_context` on the user dict. The RLS service handles this by querying the DB directly:

```python
class RowLevelSecurityService:
    async def get_rls_filter_for_user_and_collection(self, collection_key, user):
        # ── Fast path: middleware context ──
        rls_ctx = user.get("_rls_context")
        if rls_ctx:
            # Map rls_ctx to result (same logic as _apply_rls_filter)
            ...
            return result

        # ── Slow path: no middleware, query DB directly ──
        org_id = user.get("sys_organization_id")
        
        # 1. Check org master switch
        rls_setup = await db.cfgRlsSetup.find_one({...})  # BYPASS RLS!
        if not rls_setup or not rls_setup["is_enabled"]:
            return BYPASS_RESULT
        
        # 2. Resolve groups
        group_ids = await resolve_user_groups(user_id, org_id)
        
        # 3. Fetch grants
        grants = await fetch_grants(collection_key, org_id, user_id, group_ids)
        
        # 4. Classify and return
        return classify_grants(grants, rls_setup["is_strict_mode"])
```

**Return shape:**
```python
{
    "deny_all": bool,
    "bypass": bool,
    "extra_filter": dict,
    "extra_doc_ids": [ObjectId, ...]
}
```

**CRITICAL: All DB queries inside the RLS service must bypass RLS** (use `_skip_rls=True` or raw queries). Otherwise: infinite recursion.

---

## 9. EDGE CASES & RULES

### 9.1 Priority Order (non-negotiable)

```
REVOKED_ACCESS  →  always wins, user sees NOTHING
GLOBAL_ACCESS   →  user sees EVERYTHING in their org
CUSTOM_ACCESS   →  user sees ONLY the targeted rows
None (no grant) →  depends on strict_mode:
                     strict  → deny (see nothing)
                     permissive → allow (see everything in org)
```

A single REVOKED grant overrides any number of GLOBAL or CUSTOM grants.

### 9.2 Two-Level Evaluation

Level 1 (global, `cfg_organization_rls_id == null`) is evaluated FIRST and short-circuits:
- If global REVOKED → stop, deny everything
- If global GLOBAL → stop, allow everything

Level 2 (per-endpoint, `cfg_organization_rls_id != null`) is evaluated only if Level 1 didn't short-circuit.

### 9.3 Strict Mode Sources

`is_strict_mode` can be set at two levels:
- `CfgRlsSetupModel.is_strict_mode` — org-wide default
- `CfgOrganizationRlsModel.is_strict_mode` — per-endpoint override

The effective strict mode is: `org_strict OR endpoint_strict` (either one being true makes it strict).

### 9.4 Group-Based Access

Users can be members of security groups. When resolving access:
1. Find all groups the user belongs to
2. Build `targeted_ids = [user_id, group1_id, group2_id, ...]`
3. Query grants where `targeted_id IN targeted_ids`

This means a user inherits all grants assigned to their groups.

### 9.5 Custom Access with Multiple Collections

A single endpoint may query multiple collections. `custom_rows` is a dict keyed by collection name:

```python
custom_rows = {
    "refLines": [ObjectId("..."), ObjectId("...")],
    "refBusStops": [ObjectId("...")]
}
```

When `_apply_rls_filter` runs for `refLines`, it looks up `custom_rows["refLines"]`. If the collection isn't in the dict and strict mode is on → deny. If permissive → allow.

### 9.6 Fail-Closed Everywhere

Every `except` block in the middleware and service returns DENY, never ALLOW:

```python
except Exception as e:
    request.state.rls_context = DENY_CONTEXT  # NOT skip!
    return await call_next(request)
```

A database error, a malformed ObjectId, or a missing field → user sees nothing. Never fail-open.

### 9.7 `sys_organization_id` Always Injected

Even when RLS is disabled (skip=True), the `inject_org_filter` function adds `sys_organization_id` to the query for any tenant-scoped collection. This is defence-in-depth against cross-tenant data leaks.

### 9.8 Excluded Routes

Routes where no authenticated user exists (login, registration, health checks, WebSocket) → `skip: True`. The middleware does not attempt any DB queries for these routes.

---

## 10. IMPLEMENTATION CHECKLIST

### Phase 1: Data Model
- [ ] Create `cfgRlsSetup` collection + model
- [ ] Create `cfgOrganizationRls` collection + model
- [ ] Create `cfgRlsAccesses` collection + model
- [ ] Create `refSudoRlsSecurityGroups` collection + model
- [ ] Create `refSudoRlsSecurityGroupUsers` collection + model
- [ ] Create `ERlsAccessTypeFlag` enum (global_access, revoked_access, custom_access)
- [ ] Create `ESudoActionAccessTargetedTypeFlag` enum (user, sudo_rls_security_group)
- [ ] Register all collections in collection mapping
- [ ] Add `is_tenant_scoped` flag to collection metadata (auto-derived from `sys_organization_id` field)

### Phase 2: Middleware
- [ ] Create `RowLevelSecurityMiddleware` with the 6-step resolution flow
- [ ] Register it AFTER auth middleware, BEFORE permission middleware
- [ ] Define excluded routes (auth, websocket, health)
- [ ] Ensure all middleware DB queries bypass RLS
- [ ] Add fail-closed error handling
- [ ] Set `request.state.rls_context` on every code path

### Phase 3: Context Bridge
- [ ] Modify `get_user_info()` to attach `_rls_context` from `request.state` to user dict
- [ ] Do this at EVERY return point of every auth method variant

### Phase 4: Query Filter
- [ ] Add `_apply_rls_filter` method to the generic service
- [ ] Add `inject_org_filter` helper
- [ ] Define `RLS_META_COLLECTIONS` set
- [ ] Wire `_apply_rls_filter` into every fetch/count/aggregate method
- [ ] Add `_skip_rls: bool = False` parameter to every wired method
- [ ] For aggregation pipelines: **prepend** `$match` stage, don't append

### Phase 5: Fallback Service
- [ ] Create `RowLevelSecurityService` for batch/internal calls without middleware
- [ ] Implement fast path (read `_rls_context`) + slow path (query DB)
- [ ] All internal DB queries use `_skip_rls=True` or raw methods

### Phase 6: Admin UI (seeding + endpoints)
- [ ] Seed `cfgRlsSetup` (one per org, `is_enabled: false`) during org creation
- [ ] Seed `cfgOrganizationRls` (one per RLS-eligible endpoint per org) during org creation
- [ ] Build admin endpoints: toggle org RLS, toggle strict mode
- [ ] Build admin endpoints: add/remove users/groups to whitelist/blacklist
- [ ] Build admin endpoints: add/remove custom row-level grants

### Phase 7: Verification
- [ ] Test: org with RLS disabled → all data visible
- [ ] Test: globally whitelisted user → all data visible
- [ ] Test: globally blacklisted user → no data visible
- [ ] Test: endpoint RLS disabled → data visible for that endpoint
- [ ] Test: custom access → only targeted rows visible
- [ ] Test: group-based access → user inherits group grants
- [ ] Test: strict mode + no grants → no data visible
- [ ] Test: permissive mode + no grants → all org data visible
- [ ] Test: REVOKED overrides GLOBAL → deny wins
- [ ] Test: DB error in middleware → deny (fail-closed)
- [ ] Test: internal call without middleware → fallback service queries DB
- [ ] Test: RLS meta-collections are never filtered (no recursion)

---

## 11. PERFORMANCE CONSIDERATIONS

| Concern | Solution |
|---------|----------|
| N DB queries per request for RLS setup | Middleware resolves ONCE per request → zero DB calls at fetch time |
| Group membership lookup per request | One query in middleware, cached in `rls_context` |
| Grants lookup per request | One query in middleware per level (global + endpoint) |
| Aggregation pipeline RLS | Prepend `$match` stage → MongoDB optimizes filter push-down |
| `inject_org_filter` on every query | Simple dict merge, negligible cost |
| `is_tenant_scoped` check | Pre-computed at app startup in collection metadata |

**Total DB overhead per request:** 3-5 additional queries in the middleware (setup, groups, global grants, endpoint lookup, endpoint grants). These replace what would otherwise be N queries per request (one per fetch call).

---

## 12. SECURITY INVARIANTS

1. **NEVER fail-open.** Every `except` block returns DENY, not ALLOW.
2. **NEVER trust the client.** RLS context comes from the server-side middleware, not from request headers or query parameters.
3. **NEVER skip org scoping.** Even when RLS is disabled, `sys_organization_id` is injected into every tenant-scoped query.
4. **NEVER let RLS filter its own config.** The 5 RLS meta-collections are always exempt.
5. **REVOKED always wins.** No combination of other grants can override a REVOKED grant.
6. **Per-org configuration only.** No env vars, no global flags, no process-wide toggles. Each tenant controls their own RLS independently.
