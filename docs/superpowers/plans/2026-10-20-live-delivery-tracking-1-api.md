# Live delivery tracking — part 1: API server — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Server side of live delivery tracking: stored road routes per leg, fresh courier positions, one owner-checked tracking read, per-user progress pushes, admin unassign/cancel, code-confirm that closes the delivery, and an on-duty presence rule.

**Architecture:** Two new pure/IO modules next to the dispatch (`route_geometry.py`, `delivery_route_service.py`, `delivery_progress_notifier.py`), hooked into the existing `DeliveryAssignmentService` and endpoint module. Route requests go to Google Routes API through `httpx`. Every failure falls back to a straight leg flagged `approximate`. Pushes reuse the dispatch's `_tokens_for` / `_push` / `_push_notification`. Everything is additive, so old app builds keep working.

**Tech Stack:** FastAPI, Motor/Beanie (MongoDB), httpx 0.28, pytest (+ `tests/fakes/fake_motor.FakeCollection`), Firebase Admin (FCM).

**Spec:** `eblood_bank_makila_app/docs/superpowers/specs/2026-10-20-live-delivery-tracking-design.md`. Read it first. Parts 2 (console) and 3 (app) depend on the field names this plan produces.

**Workspace:** `git -C eblood_apps_api fetch origin && git -C eblood_apps_api worktree add ../eblood_apps_api-live-tracking -b feat/live-delivery-tracking origin/main`. The main checkout is on a stale branch, so never work there. Run tests from the worktree with the main checkout's venv:
`cd ../eblood_apps_api-live-tracking && ../eblood_apps_api/.venv/bin/python -m pytest tests/<file>.py -q -p no:warnings`

## Global Constraints

- Paths: S = `app/modules/health_structures_org/services/delivery_assignment/delivery_assignment_service.py`, D = `…/delivery_assignment/courier_dispatch_service.py`, E = `app/modules/health_structures_org/api/endpoints/delivery_assignment_endpoint.py`.
- **Declare every new field and enum member.** `ops_blood_delivery_models.py` validates on save, and `update_data_with_query_in_collection` silently drops undeclared fields (200 OK, nothing written).
- **Never fail a delivery action because of Google:**
  - missing key, HTTP error or timeout → straight leg, `approximate: true`;
  - route work runs fire-and-forget through `D._spawn`.
- Route requests scale with legs and off-route recomputes only. Never compute a route from a read endpoint or a poll.
- Off-route threshold 200 m; recompute at most once per 2 min per delivery.
- Location history cap: 500 points.
- Settings, both in `app/modules/core/configs/config.py` (`Settings`): `GOOGLE_ROUTES_API_KEY: str = ""` and `GOOGLE_ROUTES_TRAVEL_MODE: str = "DRIVE"`. The live test may switch the mode to `TWO_WHEELER` via env.
- FCM data payload values are strings.
- All user-facing push copy is in French, verbatim from this plan.
- MAIN/platform check = profile flag in {MAIN_APP_PROFILE, TEST_SYS_PROFILE, SYSTEM_PROFILE}. Reuse `resolve_caller_context(request)` from `eblood_connect/api/endpoints/ewallet_endpoint.py:102` and add the SYSTEM flag check.
- Don't add `filter_query=` to `update_data_with_query_in_collection` calls: `tests/test_courier_dispatch.py:468` scans for it.

## Shared interfaces (produced here, consumed by parts 2 and 3)

**Fields on `ops_blood_deliveries`:**
- `route_legs: Optional[Dict[str, Any]]`, keyed `"to_blood_bank"` / `"to_hospital"`. Each leg is `{encoded_polyline: str, distance_m: int, duration_s: int, computed_at: datetime, origin: {lat: float, lng: float}, approximate: bool}`.
- `delivery_person_last_seen_at: Optional[datetime]`
- `cancelled_at: Optional[datetime]`
- `cancelled_by_user_id: Optional[str]`

**New enum members:**
- `EDeliveryAssignmentStatus.CANCELLED = "cancelled"`
- `EDeliveryPhase.CANCELLED = "cancelled"`
- (`EDeliveryStatus.CANCELLED` already exists.)

**`GET /delivery-assignment/{id}/tracking` response (`data`):**
- `id, identifier, blood_request_id` (= `ops_blood_request_id` as str), `delivery_phase, assignment_status, status, pickup_confirmed_by_seller_at`
- `blood_bank: {id, name, address, phone, lat, lng}` and `hospital: {…same}`
- `delivery_person: {name, phone} | null`
- `courier_position: {lat, lng, accuracy} | null`
- `courier_last_seen_at: str ISO-8601 UTC | null`
- `route_legs: {…as stored, computed_at as ISO}`
- `active_leg: "to_blood_bank" | "to_hospital" | null`
- `eta_s: int | null` (active leg) and `eta_to_hospital_s: int | null` (active-leg ETA plus `to_hospital.duration_s` while on leg 1; what the buyer shows)
- `bag_count: int | null`, `blood_summary: str` (from `D._bag_summary(delivery)`, e.g. `"1 × AB-"`; empty when unknown)
- `delivery_verification_code: str | null`, only for the delivery's own courier.

**Push data types (all string values):**
- To followers (visible notification + data): `{"type": "delivery_progress", "delivery_id", "phase", "event", "audience": "buyer"|"seller"}`.
- To the courier (data-only): `{"type": "delivery_closed", "delivery_id", "reason": "unassigned"|"cancelled"}`.
- Unchanged: `delivery_assigned` (visible + data, already sent by `admin_assign_delivery`).

**New endpoints** (both mounts, `/eblood` and `/eblood-connect`): `POST /delivery-assignment/{id}/unassign` and `POST /delivery-assignment/{id}/cancel` → `{"success": true, "data": {"assignment_status": "<new>"}}`.

**Map snapshot:** each delivery adds `route_legs` and `delivery_person_last_seen_at` (ISO).

## Review Focus

1. **Courier has no GPS fix when the delivery is accepted** (no `current_location`). Expected: leg 1 isn't computed yet (it starts from the first position), leg 2 is, and nothing raises. Pinned in Task 3.
2. **Blood bank or hospital without coordinates** (missing, `0,0`, or strings). Expected: no leg for that side, `lat/lng: null` in tracking, no 500. Pinned in Tasks 3 and 5.
3. **Google answers 403/429/timeout.** Expected: straight `approximate` leg, the accept/assign response is unaffected, nothing re-raises. Pinned in Task 3.
4. **A hospital user asks for another hospital's delivery.** Expected: 403 with no data. Pinned in Task 5.
5. **The app's second confirm call (`/{id}/confirm`) after the code confirm already closed the delivery.** Expected: 200, idempotent, no double courier release, no second push. Pinned in Task 9.

---

### Task 1: Enums, model fields, settings

**Files:**
- Modify: `app/modules/health_structures_org/enums/blood_delivery_enums.py:180-203`, `app/modules/health_structures_org/models/ops_blood_delivery/ops_blood_delivery_models.py` (near :431-493), `app/modules/core/configs/config.py` (near :226)
- Test: `tests/test_live_tracking_schema.py`

**Interfaces:** Produces the enum members, model fields and settings listed under *Shared interfaces*.

- [ ] **Step 1: Write the failing tests:**
  - `test_cancelled_members()` asserts `EDeliveryAssignmentStatus.CANCELLED.value == "cancelled"` and `EDeliveryPhase.CANCELLED.value == "cancelled"`.
  - `test_delivery_model_declares_tracking_fields()` asserts `{"route_legs", "delivery_person_last_seen_at", "cancelled_at", "cancelled_by_user_id"} <= set(OpsBloodDeliveryModel.model_fields)`.
  - `test_routes_settings_defaults()` asserts `Settings.model_fields["GOOGLE_ROUTES_API_KEY"].default == ""` and `…["GOOGLE_ROUTES_TRAVEL_MODE"].default == "DRIVE"`.
- [ ] **Step 2:** Run `…pytest tests/test_live_tracking_schema.py -q`. Expected: FAIL (AttributeError / assertion).
- [ ] **Step 3:** Add the two enum members, the four `Optional[...] = None` model fields, and the two settings.
- [ ] **Step 4:** Run the same file → PASS. Also run `tests/test_courier_dispatch.py` → still PASS.
- [ ] **Step 5:** Commit `feat(delivery): cancelled state + tracking fields + routes settings`.

### Task 2: Route geometry (pure)

**Files:**
- Create: `app/modules/health_structures_org/services/delivery_assignment/route_geometry.py`
- Test: `tests/test_route_geometry.py`

**Interfaces:**
- Produces: `encode_polyline(points: list[tuple[float, float]]) -> str`
- Produces: `decode_polyline(encoded: str) -> list[tuple[float, float]]`
- Produces: `haversine_m(a: tuple[float, float], b: tuple[float, float]) -> float`
- Produces: `distance_to_polyline_m(point: tuple[float, float], encoded: str) -> float`
- Produces: `estimate_eta_s(leg: dict, position: tuple[float, float] | None, destination: tuple[float, float] | None) -> int | None`
- Produces: `point_of(obj: dict | None) -> tuple[float, float] | None`. Reads `lat/lng` or `latitude/longitude` (numbers or numeric strings); returns None for missing or `(0, 0)`.

- [ ] **Step 1: Write the failing tests:**
  - `decode_polyline("_p~iF~ps|U_ulLnnqC_mqNvxq`@")` == `[(38.5, -120.2), (40.7, -120.95), (43.252, -126.453)]` (Google's reference string), within `abs=1e-5`.
  - `encode_polyline` of that list round-trips to the same string.
  - `haversine_m((-4.3, 15.3), (-4.3, 15.31))` is within ±5 m of 1110.
  - `distance_to_polyline_m` returns < 5 for a point on a segment's midpoint, and > 200 for a point 300 m off it.
  - `estimate_eta_s({"duration_s": 600, …}, position=halfway, destination=end)` is within 250-350; returns None when `position` or `destination` is None.
  - `point_of`: `{"latitude": "-4.3", "longitude": "15.3"} → (-4.3, 15.3)`; `{"lat": 0, "lng": 0} → None`; `None → None`.
- [ ] **Step 2:** Run → FAIL (module missing).
- [ ] **Step 3:** Implement. Polyline uses the standard Google algorithm, precision 1e5. Distance to polyline = min over segments of point-to-segment distance on an equirectangular projection around the point. ETA = `duration_s × min(1, haversine(position, destination) / haversine(leg origin, destination))`, rounded, and never below 60 while > 0.
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(delivery): polyline + distance helpers for live routes`.

### Task 3: Route service (Google Routes + fallback)

**Files:**
- Create: `app/modules/health_structures_org/services/delivery_assignment/delivery_route_service.py`
- Test: `tests/test_delivery_route_service.py`

**Interfaces:**
- Consumes: Task 2 helpers; `D._deliveries()`, `D._structures()`, `D._couriers()` (swap them in tests like `tests/test_courier_dispatch.py:211-221`).
- Produces: `async def compute_leg(origin: tuple[float, float], destination: tuple[float, float], now: datetime, *, client: httpx.AsyncClient | None = None) -> dict`. Returns the leg dict.
  - Calls `POST https://routes.googleapis.com/directions/v2:computeRoutes` with headers `X-Goog-Api-Key`, `X-Goog-FieldMask: routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline` and body `{origin:{location:{latLng:{latitude,longitude}}}, destination:{…}, travelMode: settings.GOOGLE_ROUTES_TRAVEL_MODE}`, with a timeout of 8 s.
  - `duration` arrives as `"123s"`.
  - Empty key, non-2xx, timeout or an empty `routes` → straight leg: `encode_polyline([origin, destination])`, `distance_m = round(haversine)`, `duration_s = round(distance_m / 6.0)`, `approximate=True`.
- Produces: `async def compute_routes_for_delivery(delivery_id: str, now: datetime | None = None) -> None`.
  - Loads the delivery, its two structures and its courier.
  - Leg `to_hospital` = bank → hospital.
  - Leg `to_blood_bank` = courier `current_location` → bank, only if both points exist.
  - Writes `route_legs` with a single `$set` through `D._deliveries().update_one`.
- Produces: `async def maybe_recompute_active_leg(delivery: dict, position: tuple[float, float], now: datetime) -> bool`.
  - Active leg = `to_blood_bank` while the phase is in {`en_route_to_blood_bank`, `at_blood_bank`}, `to_hospital` while in {`picked_up_from_blood_bank`, `en_route_to_hospital`, `at_hospital`}.
  - Recomputes from `position` to that leg's destination when the leg is missing, or `distance_to_polyline_m > 200` and `computed_at` is older than 2 min.
  - Returns True if it wrote.

- [ ] **Step 1: Write the failing tests.** Use `httpx.MockTransport`, pass `client=` explicitly, and freeze `now`.
  - `test_compute_leg_parses_google()`: a 200 with `{"routes":[{"distanceMeters":3200,"duration":"480s","polyline":{"encodedPolyline":"abc"}}]}` → `{"distance_m":3200,"duration_s":480,"encoded_polyline":"abc","approximate":False}`; the request carries the key header and the field mask.
  - `test_compute_leg_falls_back_on_429()` and `…_on_empty_key()` → `approximate is True`, `decode_polyline(...)` has 2 points.
  - `test_routes_skip_leg1_without_courier_fix()`: courier with no `current_location` → only `to_hospital` written (Review Focus 1).
  - `test_routes_skip_side_without_coordinates()`: hospital at `0,0` → no `to_hospital` (Review Focus 2).
  - `test_recompute_only_when_off_route_and_stale()`: on-route → False; off-route at 60 s → False; off-route at 3 min → True with `origin == position`.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement (FakeCollection supports `$set`; keep writes to `$set`).
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `feat(delivery): road routes per leg with straight fallback`.

### Task 4: Hook routes + fresh positions into accept, assign and location updates

**Files:**
- Modify: S `accept_delivery` (:289-366), `admin_assign_delivery` (:386-497), `update_delivery_person_location` (:743-809), `update_delivery_phase` history write (:708-716)
- Test: `tests/test_live_tracking_hooks.py`

**Interfaces:**
- Consumes: Task 3 (`compute_routes_for_delivery`, `maybe_recompute_active_leg`), `D._spawn`.
- Produces: `append_bounded_history(history: list | None, point: dict, cap: int = 500) -> list` in S (module level).
- Produces: the location update now also sets `delivery_person_last_seen_at = now` on the delivery and `last_seen_at = now` on the courier row.

- [ ] **Step 1: Write the failing tests.** Monkeypatch `D._spawn` to collect coroutines and `service.generic_service.update_data_with_query_in_collection` to an async recorder.
  - `append_bounded_history([…600 points], p)` has length 500 and ends with `p`.
  - The location update's recorded `data` contains `delivery_person_last_seen_at`, and its history is ≤ 500.
  - The location update spawns `maybe_recompute_active_leg` exactly once.
  - Accept (won) and admin assign each spawn `compute_routes_for_delivery(delivery_id)`.
  - Accept lost (409) spawns nothing.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement. Use `append_bounded_history` in both history writes; spawn the route work after the winning write.
  - Add the comment: `# shortcut: read-modify-write history can drop a point under concurrent updates; move to $push/$slice if the fake/DAO gains it`.
- [ ] **Step 4:** Run this file plus `tests/test_courier_dispatch.py` and `tests/test_delivery_*.py` → PASS.
- [ ] **Step 5:** Commit `feat(delivery): route on accept/assign, last-seen + bounded history on location`.

### Task 5: Owner-checked tracking read

**Files:**
- Modify: E `get_delivery_tracking` (:424-469); add helper `_caller_can_track(request, delivery, accept_language) -> tuple[bool, bool]` returning `(allowed, is_courier)`
- Test: `tests/test_delivery_tracking_endpoint.py`

**Interfaces:**
- Consumes: Task 2 `point_of`, `estimate_eta_s`; `_current_user`, `_courier_collection`, `resolve_caller_context`.
- Produces: the tracking response shape under *Shared interfaces*.
  - Allowed: the delivery's courier (courier row `sys_user_id` == caller); a caller whose org == the blood bank's or hospital's `sys_organization_id`; platform profiles.
  - Otherwise 403 `"Accès refusé à cette livraison."`.

- [ ] **Step 1: Write the failing tests** (handler called directly with `REQ` and monkeypatched helpers, as in the dispatch tests):
  - The courier gets `delivery_verification_code`; buyer and seller get `None`.
  - Another hospital's org → 403 (Review Focus 4).
  - MAIN → 200.
  - `courier_last_seen_at` is ISO with a `Z` or `+00:00` offset.
  - `active_leg == "to_hospital"` when the phase is `en_route_to_hospital`; `eta_s` is an int; `blood_summary` comes from a monkeypatched `D._bag_summary`.
  - Bank with no coordinates → `blood_bank.lat is None` and 200 (Review Focus 2).
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement. Read the raw delivery from `D._deliveries()`. Structures carry `latitude/longitude`; output `lat/lng` via `point_of`. ETA uses the active leg + `courier_position` + that leg's destination. Serialize datetimes as UTC ISO (the naive-datetime trap: treat naive as UTC).
- [ ] **Step 4:** Run → PASS.
- [ ] **Step 5:** Commit `fix(delivery): tracking is owner-checked and returns route, freshness and ETA`.

### Task 6: Per-user progress pushes (replace dead topic sends)

**Files:**
- Create: `app/modules/health_structures_org/services/delivery_assignment/delivery_progress_notifier.py`
- Modify: S `_notify_delivery_accepted` (:1233), `_notify_phase_update` (:1270), `_notify_delivery_completed` (:1302). Remove the topic sends at :1243, :1256, :1289, :1306 and the dead `fcm_token` send at :1325.
- Test: `tests/test_delivery_progress_notifier.py`

**Interfaces:**
- Consumes: `orders/services/order_notification_service.py` `_resolve_users_in_org(sys_organization_id)` (:173), `D._tokens_for`, `D._push_notification`.
- Produces: `async def notify_delivery_progress(delivery: dict, event: str) -> None`, where event ∈ {`accepted`, `picked_up`, `at_hospital`, `delivered`, `unassigned`, `cancelled`}.
  - Sends one push to the seller org's users (`audience: "seller"`) and one to the buyer org's users (`audience: "buyer"`).
  - Data as under *Shared interfaces*. Never raises (logs instead).
  - Titles/bodies, exact:

| event | title | body |
|---|---|---|
| accepted | `🛵 Un livreur est en route` | `{courier} va chercher la poche chez {bank}.` |
| picked_up | `🩸 Poche récupérée` | `En route vers {hospital}.` |
| at_hospital | `📍 Le livreur est arrivé` | `Confirmez la réception avec le code du livreur.` |
| delivered | `✅ Livraison confirmée` | `{bank} → {hospital}.` |
| unassigned | `🔄 Livreur réassigné` | `Un nouveau livreur va être appelé.` |
| cancelled | `❌ Livraison annulée` | `Annulée par l'administration.` |

  - `{courier}` falls back to `Le livreur`; `{bank}` and `{hospital}` fall back to `la banque de sang` and `l'hôpital`.

- [ ] **Step 1: Write the failing tests:**
  - With monkeypatched resolvers, `accepted` sends 2 pushes, `audience` seller then buyer, `type == "delivery_progress"`, all data values `str`.
  - An org with no users → no push for it, no error.
  - A source scan of S: no `send_to_topic(` / `topic="hopital"` / `topic="blood_bank"` remains in the three notify functions.
- [ ] **Step 2:** Run → FAIL.
- [ ] **Step 3:** Implement and call it from the three `_notify_*` functions. Phase mapping: AT_BLOOD_BANK→none, PICKED_UP_FROM_BLOOD_BANK→`picked_up`, AT_HOSPITAL→`at_hospital`.
- [ ] **Step 4:** Run → PASS; dispatch tests still PASS.
- [ ] **Step 5:** Commit `fix(delivery): progress pushes go to the buyer and seller users, not dead topics`.

### Task 7: Lists keep every active delivery

**Files:**
- Modify: S `get_outgoing_deliveries_for_seller` (:1102), `get_incoming_deliveries_for_hospital` (:1138); add `FOLLOWABLE_ASSIGNMENT_STATUSES` at module level
- Test: `tests/test_delivery_follow_lists.py`

**Interfaces:**
- Produces: `FOLLOWABLE_ASSIGNMENT_STATUSES = {ACCEPTED, AUTO_ASSIGNED, PICKED_UP, IN_TRANSIT_TO_HOSPITAL, DELIVERED}` (values).
- Both queries filter `assignment_status ∈ FOLLOWABLE` and `delivery_phase ∉ {delivered_and_confirmed, cancelled}`.
- Remove the `auto_assigned` exclusion (:1144-1149).

- [ ] **Step 1: Failing tests** with a FakeCollection: an `auto_assigned` delivery in `en_route_to_blood_bank` appears for both the seller and the buyer; an `in_transit` one after pickup appears for the seller; `delivered_and_confirmed` and `cancelled` appear for neither.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `fix(delivery): buyer and seller lists keep every active delivery`.

### Task 8: Admin unassign / cancel

**Files:**
- Modify: S (add the two methods), E (add the two routes after `broadcast_delivery_request` :405)
- Test: `tests/test_delivery_unassign_cancel.py`

**Interfaces:**
- Consumes: Task 6 `notify_delivery_progress`; `D._tokens_for`, `D._push`, `D.schedule_dispatch`.
- Produces: `async def admin_unassign_delivery(self, delivery_id: str, admin_user_id: str) -> dict` and `async def admin_cancel_delivery(self, delivery_id: str, admin_user_id: str) -> dict`.
  - Both: 409 `"Cette livraison n'a pas de livreur à retirer."` if there's no `delivery_person_id` or the phase is in {`delivered_and_confirmed`, `cancelled`}.
  - Both release the courier atomically (`update_one({_id: courier, current_delivery_id: delivery}, {$set: {current_delivery_id: None, status: "available", updated_at}})`) and send the courier data push `delivery_closed`.
- **Unassign:**
  - `$set` `assignment_status=pending_broadcast`, `delivery_phase=awaiting_assignment`, `status=pending`, `delivery_person_id=None`.
  - Appends the released courier to `rejected_by_delivery_persons` with `reason: "unassigned_by_admin"`, so the new call skips them.
  - Removes `route_legs.to_blood_bank`.
  - Then `schedule_dispatch`, then progress event `unassigned`.
- **Cancel:**
  - `$set` `assignment_status=cancelled`, `delivery_phase=cancelled`, `status=cancelled`, `cancelled_at`, `cancelled_by_user_id`.
  - Then progress event `cancelled`. Money is untouched.
- **Endpoints:** `POST /delivery-assignment/{delivery_id}/unassign` and `/cancel`. 403 `"Réservé à l'administration."` unless platform. Return `{"success": True, "data": {"assignment_status": …}}`. RBAC: the console's base grant already covers `/{id}/…` (eb_admin_rbac_title.py:24-29, :199-205), so no seed change.

- [ ] **Step 1: Failing tests:**
  - Unassign → courier freed, `delivery_closed` pushed to the courier's tokens with `reason "unassigned"`, `schedule_dispatch` called once, courier listed in `rejected_by_delivery_persons`.
  - Cancel → phase `cancelled`, no `schedule_dispatch`.
  - Both on a delivered delivery → 409.
  - A non-platform caller → 403.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(delivery): admin unassign and cancel free the courier and close their sheet`.

### Task 9: Code confirm closes the delivery; `/confirm` becomes idempotent

**Files:**
- Modify: S, extracting `async def _finalize_delivery(self, delivery: dict, confirmed_by_user_id: str | None) -> None` out of `confirm_delivery_by_hospital` (:811-912): sets the confirmed state, frees the courier, `_notify_delivery_completed`
- Modify: `app/modules/eblood_connect/api/endpoints/blood_request_endpoint.py` `confirm_delivery` (:3633-3720)
- Test: `tests/test_delivery_code_confirm_closes.py`

**Interfaces:**
- Produces: `async def finalize_delivery_for_request(self, blood_request_id: str, confirmed_by_user_id: str | None) -> bool`. Finds the request's delivery not in {`delivered_and_confirmed`, `cancelled`}, finalizes it, returns True if it closed one.
- `confirm_delivery_by_hospital` on an already `delivered_and_confirmed` delivery returns success without side effects.

- [ ] **Step 1: Failing tests:**
  - After the code confirm path calls `finalize_delivery_for_request`, the delivery is `delivered_and_confirmed` and the courier is freed.
  - A following `confirm_delivery_by_hospital` → success, courier update and `_notify_delivery_completed` not called again (Review Focus 5).
  - No delivery for the request → returns False, no error.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implement. In `confirm_delivery`, call it after `SettlementService(...).release(...)` (:3702) in a try/except that logs: a close failure must not undo the confirmed money.
- [ ] **Step 4:** PASS.
- [ ] **Step 5:** Commit `fix(delivery): the hospital's code confirm also closes the delivery`.

### Task 10: On duty — refuse going offline during a delivery

**Files:**
- Modify: E `update_courier_presence` (:268-283)
- Test: add to `tests/test_courier_presence_and_stats.py`

**Interfaces:** `PUT /presence` with `online=false` while the courier row has `current_delivery_id` → 409 `"Terminez la livraison en cours avant de passer hors service."`. Login/logout semantics are otherwise unchanged (the app tolerates this 409 on logout, see part 3).

- [ ] **Step 1: Failing test:** a courier with `current_delivery_id` + `online=False` → 409; without → 200 and `is_online False`.
- [ ] **Step 2:** FAIL. **Step 3:** Implement (read the courier row first). **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(couriers): cannot go off duty in the middle of a delivery`.

### Task 11: Map snapshot carries route + freshness

**Files:**
- Modify: S `get_delivery_map_snapshot` (:512)
- Test: add to `tests/test_delivery_map_snapshot*.py` (create `tests/test_delivery_map_snapshot_routes.py` if none)

- [ ] **Step 1: Failing test:** the snapshot item has `route_legs` (with ISO `computed_at`) and `delivery_person_last_seen_at` (ISO or None).
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(delivery): map snapshot exposes the road route and last seen`.

### Task 12: CNTS sellers can call `/tracking`

**Files:**
- Modify: `app/modules/api_conumers_seed/eblood_bank_flutter_app/rbac/blood_bank/delivery/eblood_bank_flutter_bb_delivery_rbac.py`, adding the `/api/v1/eblood-connect/delivery-assignment/tracking` grant to the seller handover permission (:55, which includes CNTS). The URL is already declared in `eblood_bank_flutter_all_rbac.py`; verify, and add it there if missing.
- Test: `tests/test_live_tracking_rbac_seed.py`

- [ ] **Step 1: Failing test:** load the seed list; the seller handover permission's `meta_data` contains the tracking URL; every granted URL in that file is declared in the title endpoints (no phantom URL).
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `fix(rbac): CNTS sellers can follow their outgoing deliveries`.

### Task 13: Full suite, PR, deploy checklist

- [ ] **Step 1:** Run `../eblood_apps_api/.venv/bin/python -m pytest -q -p no:warnings` in the worktree. Compare the failure list against `origin/main`'s; never trust absolute counts on this Mac. Expected: no new failures.
- [ ] **Step 2:** Push the branch and open a PR to `main` (no attribution lines).
- [ ] **Step 3 (user-gated, after merge):**
  - `ssh ebloodbacks /opt/eblood/deploy-bg.sh apps_api`.
  - Then reseed the makila consumer RBAC (Task 12) with the documented `seed_modules` docker exec on the live colour.
  - The user adds `GOOGLE_ROUTES_API_KEY` to `/opt/eblood/backends/apps_api/.env.production`, then force-recreates the live colour.
  - Verify on the host: `docker exec <live> python -c "from app.modules.core.configs.config import settings; print(bool(settings.GOOGLE_ROUTES_API_KEY))"` → `True`.
