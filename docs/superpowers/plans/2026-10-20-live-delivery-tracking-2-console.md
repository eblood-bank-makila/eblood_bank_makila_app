# Live delivery tracking — part 2: admin console — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The console's live delivery map draws the stored road route and flags stale courier positions, and MAIN can unassign or cancel a delivery.

**Architecture:**
- A small polyline decoder plus pure helpers in `delivery-map.types.ts`. The Leaflet renderer only consumes those helpers.
- The two new actions live in the existing "Livraison" card of `blood-request-detail.ts`, behind the shared `EbConfirmDialog`.

**Tech Stack:** Angular (zoneless, signals), Leaflet 1.9, Vitest 4 via `ng test`.

**Spec:** `eblood_bank_makila_app/docs/superpowers/specs/2026-10-20-live-delivery-tracking-design.md`.

**Depends on:** part 1 (API), for the snapshot fields `route_legs` / `delivery_person_last_seen_at` and the routes `POST /eblood/delivery-assignment/{id}/unassign|cancel`. Merge and deploy part 1 first.

**Workspace:** `git -C eb_enchanced_admin fetch origin && git -C eb_enchanced_admin worktree add ../eb_enchanced_admin-live-tracking -b feat/live-delivery-tracking origin/main`. The local checkout is on a stale branch. Tests: `npm test` (or `npx ng test --include=<spec>`).

## Global Constraints

- Leaflet + OpenStreetMap tiles stay; no new npm dependency.
- Keep the 10 s polling (`DELIVERY_MAP_POLL_MS`).
- Stale threshold: **120 000 ms**.
- Road line style:
  - solid, `weight: 4`, `opacity: 0.85`, color `MAP_COLORS.route`, when the active leg exists and `approximate === false`;
  - otherwise today's dashed straight line (`weight 2, opacity .55, dashArray '6 4'`).
- French copy, verbatim:
  - stale badge: `⚠ position il y a {n} min`
  - buttons: `Désassigner le livreur`, `Annuler la livraison`
  - unassign dialog: title `Désassigner le livreur ?`, message `Le livreur est libéré et un nouvel appel part vers les livreurs proches.`
  - cancel dialog: title `Annuler la livraison ?`, message `La livraison s'arrête et le livreur est libéré. Le remboursement éventuel se fait depuis Règlements.`
  - notices: `Livreur désassigné, nouvel appel lancé.` / `Livraison annulée.`
- Errors through `apiErrorMessage(err, fallback)`; buttons gated by the existing `allowed` computed of `blood-request-detail.ts:405-410`.

## Review Focus

1. **Snapshot from an old API (no `route_legs` / `delivery_person_last_seen_at` keys).** Expected: straight dashed line, no badge, no console error. Pinned in Task 2.
2. **Corrupt or empty `encoded_polyline`.** Expected: falls back to the straight line, never throws inside the render loop. Pinned in Tasks 1 and 2.
3. **The delivery is already delivered or cancelled** when the admin opens the detail. Expected: neither button shows. Pinned in Task 4.
4. **The API answers 409** (someone already finished or released it). Expected: the dialog shows the server message and stays open; the card reloads on close. Pinned in Task 4.
5. **`last_seen_at` without a timezone** (naive ISO). Expected: treated as UTC, not local time, or the badge lies by an hour. Pinned in Task 2.

---

### Task 1: Polyline decoder

**Files:**
- Create: `src/app/dashboard/delivery-map/polyline.ts`
- Test: `src/app/dashboard/delivery-map/polyline.spec.ts`

**Interfaces:** Produces `decodePolyline(encoded: string): [number, number][]`. Returns `[]` on empty or invalid input and never throws.

- [ ] **Step 1: Failing spec:**
  - `decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@')` ≈ `[[38.5,-120.2],[40.7,-120.95],[43.252,-126.453]]` (`toBeCloseTo(…, 5)`).
  - `decodePolyline('')` → `[]`.
  - A truncated string `'_p~iF~'` → `[]` or the complete points only, without throwing.
- [ ] **Step 2:** `npx ng test --include=src/app/dashboard/delivery-map/polyline.spec.ts` → FAIL.
- [ ] **Step 3:** Implement the standard Google algorithm (precision 1e5). Wrap it in a guard so malformed input stops at the last complete point.
- [ ] **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(delivery-map): decode encoded polylines`.

### Task 2: Route + freshness helpers and rendering

**Files:**
- Modify: `src/app/dashboard/delivery-map/delivery-map.types.ts` (`MapDelivery` :36, helpers near `routePoints` :125)
- Modify: `delivery-map.renderer.ts` (:102-111, courier marker :144)
- Modify: `delivery-map.ts` (side panel :146-188)
- Test: `delivery-map.spec.ts` (helpers section from :363, plus a component test)

**Interfaces:**
- Produces:
  - `interface MapRouteLeg { encoded_polyline: string; distance_m: number; duration_s: number; computed_at: string; approximate: boolean }`
  - `MapDelivery.route_legs?: { to_blood_bank?: MapRouteLeg; to_hospital?: MapRouteLeg } | null`
  - `MapDelivery.delivery_person_last_seen_at?: string | null`
- Produces `activeLegKey(d: MapDelivery): 'to_blood_bank' | 'to_hospital' | null`:
  - `to_blood_bank` for phases `en_route_to_blood_bank` / `at_blood_bank`;
  - `to_hospital` for `picked_up_from_blood_bank` / `en_route_to_hospital` / `at_hospital`;
  - else null.
- Produces `routeLine(d: MapDelivery): { points: [number, number][]; road: boolean }`. Returns the decoded active leg with `road = !approximate` when it has ≥ 2 points; otherwise `{points: routePoints(d), road: false}`.
- Produces `STALE_AFTER_MS = 120_000` and `courierStaleMinutes(d: MapDelivery, now: number): number | null`.
  - Source is `delivery_person_last_seen_at ?? delivery_person_current_location?.timestamp`, parsed as UTC when there's no offset.
  - Returns null when unknown or fresh; otherwise whole minutes, at least 2.

- [ ] **Step 1: Failing specs:**
  - `activeLegKey` per phase.
  - `routeLine` with a road leg → `road: true` and decoded points; with an `approximate` leg → `road: false`; with no `route_legs` → equals `routePoints(d)` (Review Focus 1); with `encoded_polyline: '###'` → straight fallback (Review Focus 2).
  - `courierStaleMinutes` → `null` at 30 s, `4` at 4 min, and the same result for `"2026-10-20T10:00:00"` and `"2026-10-20T10:00:00Z"` (Review Focus 5).
  - Component: a stale delivery's side-panel entry contains `⚠ position il y a 4 min`.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implement. The renderer uses `routeLine(d)` and the Global Constraints styles. A stale courier gets a grey circle marker (`#9aa0a6`) and a tooltip with the same badge text.
- [ ] **Step 4:** PASS (the full `delivery-map.spec.ts` stays green; the renderer stays stubbed in the component specs).
- [ ] **Step 5:** Commit `feat(delivery-map): road route line and stale courier badge`.

### Task 3: API methods for unassign / cancel

**Files:**
- Modify: `src/app/dashboard/blood-requests/blood-requests-api.service.ts` (next to `assignDeliveryPerson` :173-181)
- Test: `blood-requests-api.service.spec.ts` (pattern at :253)

**Interfaces:** Produces `unassignDelivery(deliveryId: string): Observable<void>` and `cancelDelivery(deliveryId: string): Observable<void>`. They POST `{}` to `${base}${OPS_ENDPOINTS.deliveryAssignmentBase}/${id}/unassign` and `/cancel`, then `assertRawSuccess(res, 'Action impossible sur cette livraison.')`.

- [ ] **Step 1: Failing spec:** `http.expectOne(`${base}/eblood/delivery-assignment/dl1/unassign`)` with method POST, and the same for cancel. A `{success:false}` body errors.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(blood-requests): API calls to unassign or cancel a delivery`.

### Task 4: « Désassigner » / « Annuler » in the Livraison card

**Files:**
- Modify: `src/app/dashboard/blood-requests/blood-request-detail.ts` (card :195-270, signals :383-410; import `EbConfirmDialog` from `../shared/components/eb-confirm-dialog`)
- Test: `blood-request-detail.spec.ts` (rbac stub pattern at :437)

**Interfaces:**
- Consumes: Task 3 methods.
- Produces: a component signal `pendingDeliveryAction = signal<'unassign' | 'cancel' | null>(null)`, plus `deliveryActionBusy` and `deliveryActionError`.
- Buttons show only when `allowed()`, the delivery has a courier, and `delivery_phase` ∉ {`delivered_and_confirmed`, `cancelled`}.

- [ ] **Step 1: Failing specs:**
  - The buttons are visible for an assigned, in-progress delivery and hidden when delivered or cancelled (Review Focus 3).
  - Clicking « Désassigner le livreur » opens the dialog with the exact title.
  - Confirming calls `unassignDelivery('dl1')`, closes the dialog, sets the notice, and reloads the request.
  - A 409 with detail `"Cette livraison n'a pas de livreur à retirer."` shows that text in the dialog, which stays open (Review Focus 4).
  - The same flow for cancel.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implement with one `<eb-confirm-dialog>` driven by `pendingDeliveryAction`, using `danger` for cancel. Copy is from Global Constraints.
- [ ] **Step 4:** PASS. Run the full `npm test` → no new failures.
- [ ] **Step 5:** Commit `feat(blood-requests): admin can unassign or cancel a delivery`.

### Task 5: PR and deploy

- [ ] **Step 1:** `npm run build` → success.
- [ ] **Step 2:** Push the branch and open a PR to `main` (no attribution lines).
- [ ] **Step 3 (user-gated, after part 1 is live and this PR is merged):** deploy the console the usual way (pm2 on its host; see the console deploy notes). Verify in the browser: the map shows a solid road line once a delivery has a computed leg, and the buttons work on a test delivery.
