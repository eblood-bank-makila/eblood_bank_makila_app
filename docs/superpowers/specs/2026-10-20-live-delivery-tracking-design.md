# Live delivery tracking: courier sheet, follower views, admin map

Date: 2026-10-20. Status: draft with the user's answers, waiting for approval.
Repos touched: `eblood_bank_makila_app` (Flutter), `eblood_apps_api` (FastAPI), `eb_enchanced_admin` (Angular console).
Mockups (approved): `EBLOOD_APP/.superpowers/brainstorm/81586-1792453021/content/courier-sheet-v3.html` and `followers.html`.

## Why

A blood delivery is a race against time, and today nobody can watch it happen:

- **Courier:** after « Accepter » they land on a plain page with no map.
- **Hospital:** its tracking screen has no map and shows the wrong status. It reads `status` (`in_transit`) before `delivery_phase` (`DeliveryModels.dart:676`), so « Confirmer la réception » never appears. Courier name, blood bank and ETA come back blank because the server nests or renames those fields.
- **Blood bank:** only a one-time handover card, and the delivery drops off its list once it's in transit.
- **Admin console:** a live map, but the line is straight, not a road route.
- **Courier position:** sent every 30 s, and only while the courier's tracking page is on screen. It stops in the background, which also starves the dispatch: it rings couriers by distance from the blood bank.

The goal is a Yango-like experience. The courier sees the road and the next step at a glance, and everyone else sees where the blood is and when it will arrive.

## Goals

1. **Courier delivery sheet** opens over the app, at 90 % height, the moment a delivery is accepted (from a call) or assigned (from the console). It shows:
   - a Google map with the road route and the courier's live position;
   - time and distance left, and a 4-step progress bar;
   - the stop to reach, with a call button;
   - the next stop, the cargo, the hospital handover code on the second leg;
   - one slide-to-confirm control for the next step.
2. **The courier's position keeps flowing in the background** while they're on duty, with a permanent « position partagée » notification. It feeds both the dispatch (who to ring) and the live views.
3. **Hospital and blood bank** each follow their delivery live in a read-only version of the same sheet, plus the one action each owns (confirm reception with the code / confirm the handover).
4. **Admin console** draws the road route instead of a straight line, and flags couriers whose position is stale.
5. **A delivery that goes wrong can be ended.** The admin can unassign or cancel it from the console, which frees the courier and closes their sheet. The courier can call support from the sheet.
6. **Couriers choose when they're on duty** with an « En service / Hors service » switch. Position sharing and incoming calls happen only while « En service ».
7. **Only the delivery's own parties** (its courier, hospital org, blood bank org) and MAIN can read a delivery's live position. Today `/{id}/tracking` has no ownership check.

## Non-goals

- In-app turn-by-turn navigation. « Naviguer » hands off to Google Maps, which couriers already know.
- Moving the four existing OpenStreetMap screens (`HealthStructureDetailPage`, `DeliveryMapPage`, `LocalisationBanquePage`) to Google Maps.
- WebSockets/SSE. Followers poll while their sheet is open. The existing `/delivery/stream-position` SSE stays untouched.
- Changing dispatch rules (circles, call length) or delivery pricing.
- Rewriting the legacy blood-request tracker screens (`BloodRequestTrackingPage` with its hard-coded `10.37.3.43` IP). They're left as they are.

## Anti-goals (it fails even if it "works")

- A courier can dismiss the sheet by accident (swipe, back gesture) and lose the delivery.
- A step gets confirmed by a pocket tap or a bump on a moto.
- The map shows an old position as if it were live.
- Route requests scale with viewers or with each poll, so the Google bill grows with usage instead of with deliveries.
- The courier's phone drains its battery or mobile data fast enough that couriers turn the app off. Data is expensive in Kinshasa.
- A delivery is blocked because Google is unreachable or the key is missing.

## Decisions taken with the user

| Topic | Decision |
|---|---|
| Map provider | **Google Maps** (map on the phones) + **Routes API** (road routes), chosen over OpenStreetMap for ETA quality and familiarity. Google Cloud project `e-blood-bankv1-1`. Billing gets set up by the user on 2026-10-20 afternoon. |
| Who computes routes | **The server**, once per leg, stored on the delivery. Every viewer draws the same stored line, and the Routes key never ships in the app. *(My call, presented to the user.)* |
| Courier sheet | 90 % bottom sheet. No swipe-down and no back-dismiss. « Réduire » shrinks it to a bar that stays on every screen until the delivery ends; tapping the bar reopens it. |
| Step confirmation | **Slide to confirm** (option A). |
| Background position | **Yes**, for couriers on duty, with a permanent notification. It's needed for dispatch calls too, not only during a delivery. |
| Follower sheets | Hospital and blood bank get the same map read-only, closable with ✕. They open from a push or the home card, never as a forced pop-up. |
| Admin map | Same stored road route + a stale-position warning. |
| Ending a delivery that goes wrong | Console « Désassigner » (back to waiting for a courier, re-dispatched) and « Annuler » (cancelled). Both free the courier and close their sheet with a push. Courier sheet gets « Contacter le support » (a phone call, no new workflow). No courier-side "report a problem" in v1. |
| On duty | « En service / Hors service » switch on the courier home, like Yango. Sharing + calls only while « En service ». Can't go « Hors service » during a delivery. Replaces "logged in = on duty". |

## Builder's calls (settled during review, not discussed with the user)

- **Buyer / seller, not just hospital / blood bank:** CNTS → blood bank deliveries exist and `BloodBankHomePage` already shows both cards. "Hospital" means the buying structure, "blood bank" the selling one, whatever their type.
- **Android only:** there's no `GoogleService-Info.plist` and the dispatch spec is Android-only. No iOS key, no iOS background mode in v1.
- **Both legs routed at accept:** the hospital sees an arrival time from the start. Same number of route requests in total.
- **One server call closes a delivery:** today the hospital's code confirm (`/blood-requests/confirm-delivery`, which releases the money) and the delivery close (`/delivery-assignment/{id}/confirm`) are two separate calls. If the second fails, the money is out and the delivery stays stuck at `at_hospital`. The code confirm closes the delivery server-side too, so the second call becomes a no-op kept for old clients.

## The how, part by part

### 1. Server (`eblood_apps_api`, module `health_structures_org`)

**Road routes.**
- On accept/assign, compute leg 1 (courier → blood bank) and leg 2 (blood bank → hospital), with Google Routes API `computeRoutes` (two-wheeler or drive mode; builder's call after a live test).
- Store on the `ops_blood_deliveries` row, per leg: `encoded_polyline`, `distance_m`, `duration_s`, `computed_at`, `origin`.
- Recompute a leg only when the courier is more than ~200 m off its polyline, at most once every 2 minutes.
- The key comes from env `GOOGLE_ROUTES_API_KEY`, host-only in `.env.production`.
- No key, a quota hit or an API error: fall back to a straight segment flagged `approximate: true`. Never fail the delivery action.

**Location.**
- Keep `PUT /delivery-assignment/update-location` and `/presence`.
- Bound `delivery_person_location_history` (capped `$push … $slice`); today it's unbounded and rewritten in place.
- Store `last_seen_at` next to the position, so clients can show freshness.

**One follower endpoint.**
- Make `GET /delivery-assignment/{id}/tracking` the single read for the sheets: phase, courier (name, phone), blood bank and hospital (name, address, phone, coordinates), courier position + `last_seen_at`, the current leg's route, ETA, and the handover code only for the courier.
- Add the **ownership check**: allowed only for the delivery's courier, the hospital org, the blood bank org, and MAIN/SYSTEM profiles.
- Keep the RBAC grants on the existing seeds (hospital and blood bank already hold `/tracking`). No phantom URLs: every new route goes in both the title endpoints and the grants (see the RBAC phantom-URL memory).

**Pushes.**
- On accept/assign and every phase change, push per user (same token lookup as the dispatch's `_tokens_for`) to the hospital org's users and the blood bank org's users.
- Payload type `delivery_progress`, with `delivery_id` and `phase`. Replaces today's sends to the dead topic `hopital`.
- Console assignment sends the courier a `delivery_assigned` data push carrying `delivery_id`.

**Ending a delivery early (MAIN only).**
- `POST /delivery-assignment/{id}/unassign`: clears the courier (`delivery_person_id`, the courier's `current_delivery_id`, status back to available), sets the delivery back to `pending_broadcast` and starts the dispatch again.
- `POST /delivery-assignment/{id}/cancel`: same release, then marks the delivery cancelled. There's no cancelled value today in `EDeliveryPhase` / `EDeliveryAssignmentStatus`. Add one, declared in the enum (see the phantom-enum memory: undeclared members crash with `AttributeError`).
- Both send the courier a `delivery_closed` data push, which closes the sheet and the « Réduire » bar, and send `delivery_progress` to the buyer and seller. Grants are seeded for MAIN/SYSTEM in the console's RBAC seeds.
- What happens to the money on cancel is out of scope: the cancel only stops the delivery. Refunds stay with the existing settlement tools.

**On duty.**
- `PUT /presence` already takes `online`. The switch drives it: « En service » sends `online: true` and starts the stream; « Hors service » sends `online: false` and stops it.
- The server refuses `online: false` while the courier has a `current_delivery_id`.

**List queries.**
- `incoming-deliveries` (hospital) and `outgoing-deliveries` (blood bank) return every active phase until `delivered_and_confirmed`, including admin-assigned (`auto_assigned`) ones.
- Fix the fields the app expects, or adapt the app's parser. Builder's call; the app parser is probably cheaper.

### 2. Courier app (`eblood_bank_makila_app`)

**`DeliverySheet` widget.**
- Built on `google_maps_flutter`.
- Map: route polyline (decoded from the server), courier marker, destination marker, recenter button, « Naviguer » button. « Naviguer » opens Google Maps navigation to the current stop; two-wheeler mode where available.
- Under the map:
  - ETA + distance;
  - a 4-step bar;
  - the current stop card with `tel:` call;
  - the next stop;
  - the cargo;
  - the handover code card on leg 2.
- Slide-to-confirm at the bottom.

**How it opens.**
- `DeliveryCallService` opens the sheet on `accepted`, replacing today's push of `ActiveDeliveryTrackingPage`.
- A `delivery_assigned` push opens it directly in the foreground, or when its notification is tapped.
- `ActiveDeliveryWidget` on the courier home opens the same sheet.
- It's shown with `isDismissible: false, enableDrag: false` and a `PopScope` that blocks back.

**« Réduire » bar.**
- An app-level overlay above the router's navigator, visible on every screen while the courier has an active delivery.
- Shows ETA and destination; tapping it reopens the sheet.

**Steps.**
- Keep today's phase mapping (`ActiveDeliveryTrackingPage._buildActionButton`):
  - en route → « Arrivé à la banque »;
  - at bank → waiting for the blood bank's confirmation (no slide);
  - picked up → « Partir vers l'hôpital »;
  - en route → « Arrivé à l'hôpital »;
  - at hospital → waiting for the hospital's code.
- `ActiveDeliveryTrackingPage` is retired once nothing links to it.

**« En service / Hors service » switch.**
- On the courier home (Tableau de livraison). Off after a fresh login; the last state is remembered across app restarts (my call).
- Disabled during a delivery, with « Terminez la livraison en cours ».
- If the app is swiped away or the phone reboots while « En service », sharing stops until the app is opened again. Dispatch still rings on a position up to 30 min old (existing dispatch rule, unchanged).

**« Contacter le support ».** A `tel:` link in the courier sheet's menu. The number comes from config; builder picks where (the app's `.env` or a server setting).

**Closing on cancel.** A `delivery_closed` push (foreground or background) closes the sheet and the bar, and shows « Livraison annulée par l'administration » or « Livraison réassignée ».

**Background position.**
- One position stream while the courier is « En service »: geolocator's `AndroidSettings(foregroundNotificationConfig: …)` gives a foreground service of type `location` without a new package.
- It feeds presence (every ~60 s) and, during a delivery, `update-location` (every ~15 s, or 50 m moved; builder tunes for battery/data).
- Manifest: `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_LOCATION`. Started from the foreground, so while-in-use location permission is enough.
- **User task:** Play Console → App content → foreground service declaration (location), with a short video.

**Keys.**
- `MAPS_API_KEY` from `android/local.properties` (gitignored) via `manifestPlaceholders`.
- The release build must not break when the key is absent: the map shows empty, everything else works.

### 3. Hospital and blood bank (same app, other profiles)

**Read-only sheet.**
- Same `DeliverySheet` in read-only mode, closable with ✕.
- Polls `/tracking` every ~10 s while open, and stops when closed.
- « en direct · il y a N s » badge, turning to a warning past ~2 min.

**How it opens.**
- Tap on a `delivery_progress` push.
- Tap on the delivery card: hospital `IncomingDeliveryWidget`, blood bank `OutgoingDeliveryWidget`.
- No auto pop-up.

**Actions.**
- **Hospital:** at `at_hospital`, « Confirmer la réception » asks for the courier's code (existing confirm endpoint).
- **Blood bank:** at `at_blood_bank`, « Confirmer la remise » (existing `confirm-pickup`).
- Afterwards the blood bank can keep following until « Livrée ».

**Parser fix.** Fix `IncomingDelivery.fromJson` (prefer `delivery_phase`, read the server's real field names), so the hospital's existing screens show the right status even outside the sheet.

### 4. Admin console (`eb_enchanced_admin`)

- Delivery detail (or map side panel) gets « Désassigner » and « Annuler », each with a confirmation dialog stating the effect.
- `delivery-map` draws the stored leg polyline (decoded) instead of the straight bank → courier → hospital line.
- Couriers whose `last_seen_at` is older than ~2 min get a stale badge.
- Leaflet + OpenStreetMap tiles stay. Only the route line and the badge change; keep the 10 s polling.

## Constraints

- **Keys arrive later.** Google billing is set up the afternoon of 2026-10-20. Everything must build, run and degrade gracefully without the keys (straight-line fallback, empty map).
- **Cost.** The Routes API is billed per request after the monthly free quota. Requests scale with legs and off-route recomputes, never with viewers or polls. Daily quota cap set in the console.
- **Play policy.** Background location runs through a foreground service with a declaration and video in the Play Console; that part is the user's. No `ACCESS_BACKGROUND_LOCATION` unless testing proves it's required.
- **Release builds.** R8 is on (`isMinifyEnabled`, `isShrinkResources`); see the 2026-10-19 Gson/TypeToken trap. Test a release APK on the device, not only debug.
- **Prod data.** There's one courier on prod (alvic dalton). Device tests reuse the recipe: back up fields, unassign, `pending_broadcast` + `start_dispatch`. Only with the user's go-ahead each time.
- **Deploy order.** Backend first (additive fields, old clients keep working), reseed RBAC if grants change, then the console, then the makila release. The user uploads the `.aab` to Play.
- **Data and battery.** Prefer distance filters and sensible intervals over a fixed fast timer.

## Testing

- **Backend unit:**
  - route fallback (no key / API error → straight + `approximate`);
  - off-route detection and the 2-minute throttle;
  - `/tracking` ownership (other hospital → 403);
  - per-user `delivery_progress` targets;
  - bounded history.
- **Backend unit (more):** unassign/cancel free the courier and push `delivery_closed`; `online: false` refused during a delivery.
- **App widget:** the switch can't turn off during a delivery; `delivery_closed` closes the sheet; sheet states per phase; slide fires only on a full slide; back/swipe can't dismiss; « Réduire » bar appears and reopens; follower badge turns stale.
- **Device (release APK, Galaxy A07):**
  - accept a real call;
  - check the sheet and the route;
  - background the app via « Naviguer » and see the position keep updating server-side;
  - follow the same delivery as a hospital account;
  - check the console line.

## Left to the builder

- Exact intervals and distance filters.
- Polyline decoding (small helper vs package).
- ETA math between recomputes.
- Off-route threshold tuning.
- Visual polish within the approved mockups.
- File layout.
- Whether the server or the parser adapts for the list fields.
- How to split the work into PRs.
