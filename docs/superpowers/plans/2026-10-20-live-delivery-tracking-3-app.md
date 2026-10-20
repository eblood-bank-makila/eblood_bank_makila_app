# Live delivery tracking — part 3: makila app — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
- The courier's 90 % delivery sheet: Google map, road route, slide-to-confirm, a « Réduire » bar.
- Read-only follower sheets for the buyer and the seller.
- An « En service / Hors service » switch with background position sharing.

**Architecture:**
- **One `DeliverySheet` widget for all three roles.** It's fed by a 10 s polling stream of the server's `/tracking` read.
- **`ActiveDeliverySheetController` opens it.** It's a singleton that owns the modal and the minimized state. A bar it drives sits in a `Stack` around the router in `MonApplication`.
- **`CourierDutyService` owns the switch.** It also runs the geolocator foreground-service stream that feeds presence and delivery location.

**Tech Stack:** Flutter 3.44 / Dart 3.8, Riverpod 2.6, GetX 4.7 (routing + translations), google_maps_flutter (new), geolocator 13, url_launcher 6.3, firebase_messaging, flutter_test.

**Spec:** `docs/superpowers/specs/2026-10-20-live-delivery-tracking-design.md` (this repo).

**Depends on:** part 1 (API), deployed. Field names and push types come from the "Shared interfaces" of `2026-10-20-live-delivery-tracking-1-api.md`.

**Workspace:** `git worktree add ../eblood_bank_makila_app-live-tracking -b feat/live-delivery-tracking main`. Tests: `flutter test test/<file>.dart`.

## Global Constraints

- **Android only.** Don't add iOS keys or background modes.
- **Map key.** `MAPS_API_KEY` is read from `android/local.properties` (gitignored) into the manifest placeholder `mapsApiKey`. A missing key must still build: the map renders empty and everything else works.
- **Release build.** It's R8-minified and resource-shrunk; verify features on a **release** APK (see the 2026-10-19 Gson trap).
- **No new packages except `google_maps_flutter`.** Polyline decoding is hand-written; the slide control is a custom widget.
- **Courier sheet:** `isDismissible: false`, `enableDrag: false`, a `PopScope(canPop: false)`, height factor `0.9`.
- **Follower sheets:** dismissible, with an ✕ (`Key('sheet-close')`).
- **Timings:**
  - followers and courier poll `/tracking` every **10 s**, only while the sheet is open;
  - a position is stale after **120 s**;
  - presence ping every **60 s** while on duty;
  - delivery location every **≥ 15 s**, or 30 m moved.
- **Foreground-service notification:** title `e-Blood · En service`, text `Position partagée pour les livraisons`.
- **« Naviguer »:**
  - first `google.navigation:q={lat},{lng}&mode=l`;
  - fallback `https://www.google.com/maps/dir/?api=1&destination={lat},{lng}`.
- **Support number:** `AppConfig.getEnvValue('SUPPORT_PHONE')`. Add the empty key `SUPPORT_PHONE=` to `.env`; hide the button when it's empty.
- **All new strings are GetX keys** in all 5 locales of `lib/apps/translations/AppTranslations.dart` (fr_FR :8, en_US :2159, es_ES :4178, ln_CD :5487, ru_RU :6722). The keys are listed in Task 9; missing keys print raw on screen.
- **Push types handled:**
  - `delivery_call` and `delivery_call_closed` (unchanged);
  - `delivery_assigned`;
  - `delivery_closed` (`reason` `unassigned` | `cancelled`);
  - `delivery_progress` (`audience` `buyer` | `seller`).

## Review Focus

1. **A slide whose server call fails** (409 « remise pas encore confirmée », or no network). Expected: the knob snaps back, an error snackbar shows, the step doesn't advance. Pinned in Tasks 4 and 5.
2. **The courier is unassigned or the delivery cancelled while the app was in the background** (the `delivery_closed` push missed). Expected: the next poll gets 403 or `delivery_phase == cancelled`, and the sheet and bar close with the matching message. Pinned in Tasks 3 and 6.
3. **No courier GPS fix yet / blood bank without coordinates.** Expected: the sheet renders the pins it has, no route line, `—` for ETA, no exception. Pinned in Tasks 2 and 5.
4. **« Hors service » tapped during a delivery**, or the server answers 409 on logout. Expected: the switch stays on with the message; logout still completes. Pinned in Task 8.
5. **Two `delivery_assigned`/accept events for the same delivery** (push + call screen, or a double tap). Expected: one sheet, not two stacked. Pinned in Task 6.

---

### Task 1: Build plumbing (Google Maps SDK, key, permissions)

**Files:**
- Modify: `pubspec.yaml` (add `google_maps_flutter`, a version compatible with Flutter 3.44)
- Modify: `android/app/build.gradle.kts`: read `MAPS_API_KEY` from `rootProject.file("local.properties")` and set `manifestPlaceholders["mapsApiKey"] = key ?: ""` in `defaultConfig`
- Modify: `android/app/src/main/AndroidManifest.xml`: `<meta-data android:name="com.google.android.geo.API_KEY" android:value="${mapsApiKey}"/>` in `<application>`; permissions `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`
- Modify: `.env` (add `SUPPORT_PHONE=`)
- Test: `test/live_tracking_android_config_test.dart`

- [ ] **Step 1: Failing source-scan test** (pattern: `test/delivery_call_review_test.dart:74-84`):
  - the manifest contains `com.google.android.geo.API_KEY` with `${mapsApiKey}` and the three permissions;
  - `build.gradle.kts` contains `MAPS_API_KEY` and `manifestPlaceholders`;
  - `pubspec.yaml` contains `google_maps_flutter:`.
- [ ] **Step 2:** `flutter test test/live_tracking_android_config_test.dart` → FAIL.
- [ ] **Step 3:** Implement, then `flutter pub get`.
- [ ] **Step 4:**
  - The test → PASS.
  - `flutter build apk --release --target-platform android-arm64` succeeds **without** `MAPS_API_KEY` in `local.properties`.
  - Run `df -h` first. Free disk < 5 GB → stop and tell the user (Gradle fails with misleading errors when the disk is full).
- [ ] **Step 5:** Commit `build(android): google maps sdk, maps key placeholder, location foreground service permissions`.

### Task 2: Tracking model, polyline, hospital status fix

**Files:**
- Create: `lib/delivery/business/model/route_polyline.dart`, `lib/delivery/business/model/delivery_tracking.dart`
- Modify: `lib/delivery/business/model/DeliveryModels.dart` (`IncomingDelivery.fromJson` :669-692)
- Test: `test/delivery_tracking_model_test.dart`

**Interfaces:**
- Produces: `List<({double lat, double lng})> decodePolyline(String encoded)`. Returns `[]` on empty or invalid input.
- Produces: `class TrackingPlace { final String? id, name, address, phone; final double? lat, lng; }`
- Produces: `class TrackingLeg { final List<({double lat, double lng})> points; final int distanceM; final int durationS; final bool approximate; }`
- Produces `class DeliveryTracking` with:
  - fields `String id, identifier, bloodRequestId, phase, assignmentStatus`
  - `DateTime? pickupConfirmedAt`
  - `TrackingPlace bloodBank, hospital`
  - `String? courierName, courierPhone`
  - `({double lat, double lng})? courierPosition`
  - `DateTime? courierLastSeenAt` (UTC; parse with `parseServerTime`)
  - `Map<String, TrackingLeg> routeLegs`
  - `String? activeLeg`
  - `int? etaSeconds`, `int? etaToHospitalSeconds` (the buyer sheet shows this one)
  - `String? verificationCode`
  - `int? bagCount`, `String bloodSummary` (cargo line « 1 poche · AB- »)
  - getters `bool get isCancelled` (phase `cancelled`), `bool get isDelivered` (phase `delivered_and_confirmed`), `TrackingLeg? get currentLeg`, `Duration? positionAge(DateTime nowUtc)`, `bool isStale(DateTime nowUtc)` (age > 120 s)
  - `factory DeliveryTracking.fromJson(Map<String, dynamic>)` for the part 1 tracking shape.
- `IncomingDelivery.status` now reads `json['delivery_phase'] ?? json['status']`. Names come from the nested `delivery_person` / `blood_bank` objects as `_enrich_delivery_details` emits them (read `eblood_apps_api` origin/main S:1179-1231).

- [ ] **Step 1: Failing tests:**
  - `decodePolyline` on Google's reference string → 3 points ≈ (38.5,-120.2), (40.7,-120.95), (43.252,-126.453).
  - `fromJson` on a full sample → every field; `currentLeg` follows `active_leg`.
  - `fromJson` with `blood_bank.lat == null`, `courier_position == null` and no `route_legs` → no throw, `currentLeg == null` (Review Focus 3).
  - `isStale` false at 30 s, true at 3 min.
  - `IncomingDelivery.fromJson({'status':'in_transit','delivery_phase':'at_hospital', …}).isAtHospital == true`.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(delivery): tracking model with route legs; hospital reads the delivery phase`.

### Task 3: Polling stream + provider

**Files:**
- Create: `lib/delivery/business/interactors/delivery_tracking_provider.dart`
- Modify: `lib/delivery/business/service/DeliveryApiService.dart` (`getDeliveryTracking` :415 and `ApiResponse` :563-581): add `final int? statusCode` to `ApiResponse` and set it in `getDeliveryTracking`
- Test: `test/delivery_tracking_poll_test.dart`

**Interfaces:**
- Produces: `class DeliveryTrackingClosed implements Exception { final bool forbidden; }`
- Produces: `Stream<DeliveryTracking> pollDeliveryTracking(String deliveryId, {required Future<ApiResponse<Map<String, dynamic>>> Function(String) fetch, Duration every = const Duration(seconds: 10)})`.
  - Fetches immediately, then every `every`. Skips a failed tick and keeps the last value.
  - A 403 → emits a `DeliveryTrackingClosed(forbidden: true)` error and closes.
  - A `cancelled` phase → emits the value, then closes.
- Produces: `final deliveryTrackingProvider = StreamProvider.autoDispose.family<DeliveryTracking, String>(…)`, using `DeliveryApiService().getDeliveryTracking`.

- [ ] **Step 1: Failing tests** (`fakeAsync`):
  - 2 fetches after 10 s.
  - A 500 tick keeps the stream alive.
  - A 403 → error `DeliveryTrackingClosed`, then done (Review Focus 2).
  - A cancelled payload → value, then done.
  - Cancelling the subscription stops fetching.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(delivery): poll the tracking read while a sheet is open`.

### Task 4: Slide to confirm

**Files:**
- Create: `lib/delivery/ui/widgets/slide_to_confirm.dart`
- Test: `test/slide_to_confirm_test.dart`

**Interfaces:** Produces `SlideToConfirm({Key? key, required String label, required Future<bool> Function() onConfirmed, bool enabled = true})`.
- The knob (`Key('slide-knob')`) fires once when released past **90 %** of the track, and shows a spinner while `onConfirmed` runs.
- `false` → it animates back to start.
- Disabled → greyed, no drag.
- Style per the approved mockup: red track `Color(0xFFD0021B)`, white round knob with `›`, label centred, offset by the knob width.

- [ ] **Step 1: Failing widget tests:**
  - A drag of 50 % → `onConfirmed` not called.
  - A drag of 95 % → called exactly once, even if dragged again while it's running.
  - `onConfirmed` returns false → the knob is back at its start offset (Review Focus 1).
  - `enabled: false` → a drag does nothing.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(delivery): slide-to-confirm control`.

### Task 5: The delivery sheet (all roles)

**Files:**
- Create: `lib/delivery/ui/sheet/delivery_sheet.dart`, `lib/delivery/ui/sheet/delivery_map_view.dart`, `lib/delivery/ui/sheet/courier_step.dart`
- Create: `lib/delivery/ui/sheet/confirm_reception_dialog.dart`. Extract `_confirmDelivery` from `IncomingDeliveryWidget.dart:323-393` unchanged and call it from both places.
- Test: `test/delivery_sheet_test.dart`, `test/courier_step_test.dart`

**Interfaces:**
- Consumes: Tasks 2-4; `incomingDeliveriesProvider.notifier.confirmDelivery(id, {bloodRequestId, verificationCode})`; `outgoingDeliveriesProvider.notifier.confirmPickup(id)`; `DeliveryApiService().updateDeliveryPhase(id, phase, location:)`.
- Produces: `enum DeliverySheetRole { courier, buyer, seller }`.
- Produces: `({String labelKey, String? nextPhase})? courierStep(DeliveryTracking t)`. A `null` nextPhase = waiting text, no slide.

| phase | labelKey | nextPhase |
|---|---|---|
| `en_route_to_blood_bank` | `slide_arrived_bank` | `at_blood_bank` |
| `at_blood_bank`, pickup not confirmed | `waiting_bank_handover` | null |
| `at_blood_bank`, pickup confirmed | `slide_picked_up` | `picked_up_from_blood_bank` |
| `picked_up_from_blood_bank` | `slide_leave_for_hospital` | `en_route_to_hospital` |
| `en_route_to_hospital` | `slide_arrived_hospital` | `at_hospital` |
| `at_hospital` | `waiting_hospital_confirm` | null |
| other | — | returns null |

- Produces: `DeliverySheet({Key? key, required String deliveryId, required DeliverySheetRole role, Widget Function(BuildContext, DeliveryTracking)? mapBuilder, VoidCallback? onMinimize, VoidCallback? onClose})`.
  - `mapBuilder` defaults to `DeliveryMapView`. Tests pass a placeholder, because `GoogleMap` is a platform view.
- Layout per the approved mockup `courier-sheet-v3.html` / `followers.html`:
  - pill + identifier + (courier: « Réduire » `Key('sheet-minimize')` and a ⋮ menu with « Contacter le support » | followers: ✕);
  - map (235 dp high) with « Naviguer » (courier) or the live badge (followers);
  - ETA (`etaSeconds` → minutes, or `—`) + distance;
  - 4-step bar;
  - stop card(s) with a `tel:` button;
  - code card (courier, phases from `picked_up_from_blood_bank` to `at_hospital`, `Key('handover-code')`);
  - the bottom action.
- **Bottom action by role:**
  - **Courier:** `SlideToConfirm` from `courierStep`. It updates the phase with the best-effort current position; on failure it shows a snackbar with the server message and returns false.
  - **Buyer:** at `at_hospital`, a `Confirmer la réception` button → the dialog.
  - **Seller:** at `at_blood_bank` with no pickup confirmation, a `Confirmer la remise` button → `confirmPickup`.
- **Followers' freshness badge:** `live_seconds_ago`, or `position_stale_minutes` when stale.
- `DeliveryMapView` draws `currentLeg.points` as a polyline (solid if not `approximate`, dashed otherwise), marker pins for the bank, the hospital and the courier, and a recenter FAB. The camera fits all points on the first build.

- [ ] **Step 1: Failing tests:**
  - `courierStep` for each table row.
  - Courier sheet at `en_route_to_blood_bank` shows the slide labelled `Glisser · Arrivé à la banque`, no code card.
  - At `en_route_to_hospital` it shows `Key('handover-code')` with the code.
  - At `at_blood_bank` without confirmation: no slide, the waiting text.
  - The slide's server call fails (fake returns 409) → snackbar + the slide is back (Review Focus 1).
  - Buyer at `at_hospital` → `Confirmer la réception`; seller at `at_blood_bank` → `Confirmer la remise`.
  - A buyer with a 3-min-old position → the `⚠ position il y a 3 min` text.
  - No route and no courier position → renders, ETA `—` (Review Focus 3).
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(delivery): delivery sheet for courier, buyer and seller`.

### Task 6: Opening, minimizing, closing (controller + bar)

**Files:**
- Create: `lib/delivery/ui/sheet/active_delivery_sheet_controller.dart`, `lib/delivery/ui/sheet/active_delivery_bar.dart`
- Modify: `lib/apps/MonApplication.dart` (`builder` :56-64): wrap `child` in `Stack(children: [child, const ActiveDeliveryBar()])`
- Test: `test/active_delivery_sheet_controller_test.dart`

**Interfaces:** Produces `class ActiveDeliverySheetController extends ChangeNotifier`, `static final instance`. It has:
- `String? courierDeliveryId`, `bool minimized`;
- `Future<void> open(NavigatorState navigator, String deliveryId, DeliverySheetRole role)`;
- `void minimize()`;
- `void closeFor(String deliveryId, {String? message})`;
- `bool get showBar` (a courier delivery set and minimized).
- **`open`:**
  - No-op if a sheet for the same id and role is already up (Review Focus 5).
  - Uses `showModalBottomSheet(isScrollControlled: true, useSafeArea: true, isDismissible: role != courier, enableDrag: role != courier, backgroundColor: Colors.transparent)` with `FractionallySizedBox(heightFactor: 0.9, child: DeliverySheet(...))`.
  - The courier variant is wrapped in `PopScope(canPop: false)`.
- **`minimize`** pops the courier sheet and keeps `courierDeliveryId`.
- **`closeFor`** pops the sheet if it's showing, clears the courier state, and shows `message` in a snackbar.
- The sheet also calls `closeFor` itself when its stream errors with `DeliveryTrackingClosed`, or the phase is `cancelled` / `delivered_and_confirmed`. Messages: `delivery_cancelled_by_admin` / `delivery_reassigned` / none for delivered.
- **`ActiveDeliveryBar`** is positioned above the bottom nav (bottom: 62). Its text is `Livraison en cours · {eta}` / `Vers {stop} · position partagée`; tapping reopens via the global `navigatorKey` from `main.dart:46`.

- [ ] **Step 1: Failing widget tests:**
  - `open` twice with the same id → one route.
  - A back press on the courier sheet → still open; « Réduire » → sheet gone, bar visible; tapping the bar → sheet back.
  - `closeFor` → sheet and bar gone, snackbar text.
  - A follower sheet closes with ✕ and with a drag.
  - A 403 poll on the courier sheet closes it with `Livraison réassignée à un autre livreur.` (Review Focus 2).
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(delivery): open, minimize and close the delivery sheet`.

### Task 7: Wire the entry points; retire the old pages

**Files:**
- Modify: `lib/delivery/dispatch/delivery_call_service.dart`:
  - default `openActiveDelivery` (:56-57) → controller `.open(courier)`;
  - `handle(Map data, {bool fromTap = false})`;
  - `attach` (:61-74): `onMessageOpenedApp`, notification taps and the launch payload pass `fromTap: true`; also handle `FirebaseMessaging.instance.getInitialMessage()` with `fromTap: true`
- Modify: `lib/delivery/dispatch/delivery_call_payload.dart`: add the `delivery_assigned` / `delivery_closed` / `delivery_progress` type constants and parsers
- Modify: `lib/delivery/ui/widgets/ActiveDeliveryWidget.dart:26-35` → `.open(courier)`
- Modify: `IncomingDeliveryWidget.dart:275-285` → `.open(buyer)`
- Modify: `OutgoingDeliveryWidget.dart:40-46`: list every outgoing delivery; the confirm button only when `canConfirmPickup`; add `Suivre` → `.open(seller)`
- Delete: `lib/delivery/ui/pages/ActiveDeliveryTrackingPage.dart`, `lib/delivery/ui/pages/HospitalDeliveryTrackingPage.dart`
- Test: update `test/delivery_call_test.dart`, `test/delivery_call_review_test.dart`; add `test/delivery_push_types_test.dart`

**Interfaces — `handle` additions:**
- `delivery_assigned` → if courier and a navigator: `open(courier)`.
- `delivery_closed` → `closeFor(id, message: reason == 'cancelled' ? 'delivery_cancelled_by_admin'.tr : 'delivery_reassigned'.tr)`.
- `delivery_progress` → only when `fromTap`: `open(audience == 'seller' ? seller : buyer)`.
- Existing call behaviour is unchanged. The background handler ignores the new types.

- [ ] **Step 1: Failing tests:**
  - `delivery_assigned` → `openActiveDelivery` called once with the id.
  - `delivery_closed` → the injected close callback called with the right message key.
  - `delivery_progress` with `fromTap: false` → nothing; with `fromTap: true, audience: seller` → opens as seller.
  - A source scan: no file under `lib/` references `ActiveDeliveryTrackingPage` or `HospitalDeliveryTrackingPage`.
  - Existing call tests stay green.
- [ ] **Step 2:** FAIL.
- [ ] **Step 3:** Implement. Add injectable `openSheet` / `closeSheet` callbacks next to `openActiveDelivery` so tests don't need the real controller. Delete the two pages; also drop their RBAC flag constants if nothing else uses them.
- [ ] **Step 4:** PASS (all `test/delivery_*`).
- [ ] **Step 5:** Commit `feat(delivery): calls, assignments and progress pushes open the delivery sheet`.

### Task 8: « En service / Hors service » + background position

**Files:**
- Create: `lib/delivery/business/service/courier_duty_service.dart`
- Modify: `lib/delivery/business/service/courier_presence_service.dart`:
  - default `isCourier` → `isActivatedCourier() && CourierDutyService.instance.onDuty`;
  - in `didChangeAppLifecycleState` (:119), keep the 60 s timer while on duty;
  - `_goOffline` (:130) on logout tolerates a 409
- Modify: `lib/delivery/ui/pages/DeliveryPersonHomePage.dart` (`_buildHeader` :123-185): a `Switch` with the label `duty_on`/`duty_off`, `Key('duty-switch')`, replacing the trailing truck icon (:171-183)
- Modify: `lib/main.dart` (:187), calling `CourierDutyService.instance.resumeIfNeeded()` after presence attach
- Test: `test/courier_duty_service_test.dart`; update `test/courier_presence_service_test.dart`

**Interfaces:** Produces `class CourierDutyService extends ChangeNotifier`, `static final instance`. Its constructor takes:
- `Future<int?> Function(Map<String, dynamic>) sendPresence`
- `Future<void> Function(double lat, double lng, double accuracy) sendDeliveryLocation`
- `Stream<({double lat, double lng, double accuracy})> Function() positions`
- `Future<bool> Function() ensurePermission`
- `bool Function() hasActiveDelivery`
- `DateTime Function() clock`
- `GetStorage storage`

The default `positions` is `Geolocator.getPositionStream` with `AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 30, intervalDuration: Duration(seconds: 15), foregroundNotificationConfig: ForegroundNotificationConfig(notificationTitle: 'e-Blood · En service', notificationText: 'Position partagée pour les livraisons', enableWakeLock: true, setOngoing: true))`.

API:
- **`bool get onDuty`.**
- **`Future<String?> setOnDuty(bool value)`.** Returns a message key on refusal.
  - Off during a delivery → `duty_finish_delivery_first`, with no server call.
  - Server 409 → the same key, stays on.
  - Permission denied → `duty_location_needed`.
  - On: `sendPresence({'online': true, …})`, start the stream, persist `courier_on_duty = true`.
  - Off: stop the stream, `sendPresence({'online': false})`, persist false.
- **`Future<void> resumeIfNeeded()`.** Restarts the stream if persisted true and the permission is already granted, else sets off.
- **Stream ticks:**
  - during a delivery, `sendDeliveryLocation` at most every 15 s;
  - presence keeps flowing from `CourierPresenceService`'s timer, which uses the last position.
- Login/logout (the `user_profiles` key change) resets to off.

- [ ] **Step 1: Failing tests:**
  - `setOnDuty(false)` with an active delivery → `duty_finish_delivery_first`, the stream not stopped, no presence call (Review Focus 4).
  - Presence 409 → same key, still on.
  - On → the stream subscribed and presence online sent.
  - Ticks every 5 s during a delivery → `sendDeliveryLocation` called once per 15 s.
  - `resumeIfNeeded` with persisted true → the stream subscribed.
  - A profile change → off.
  - Presence tests: on-duty false → no pings; a logout 409 → no throw (Review Focus 4).
  - Widget: `Key('duty-switch')` toggles and shows the refusal snackbar.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS.
- [ ] **Step 5:** Commit `feat(couriers): on-duty switch with background position sharing`.

### Task 9: Translations

**Files:**
- Modify: `lib/apps/translations/AppTranslations.dart` (all 5 locales)
- Test: `test/live_tracking_translations_test.dart` (pattern: `test/location_access_translations_test.dart`)

Keys (fr / en; es, ln, ru translated alike, `@s` / `@m` are GetX params):

| key | fr | en |
|---|---|---|
| `sheet_minimize` | Réduire | Minimize |
| `sheet_navigate` | Naviguer | Navigate |
| `slide_arrived_bank` | Glisser · Arrivé à la banque | Slide · Arrived at the blood bank |
| `slide_picked_up` | Glisser · Poche récupérée | Slide · Bag picked up |
| `slide_leave_for_hospital` | Glisser · Partir vers l'hôpital | Slide · Leave for the hospital |
| `slide_arrived_hospital` | Glisser · Arrivé à l'hôpital | Slide · Arrived at the hospital |
| `waiting_bank_handover` | En attente de la remise par la banque… | Waiting for the blood bank's handover… |
| `waiting_hospital_confirm` | En attente de la confirmation de l'hôpital… | Waiting for the hospital's confirmation… |
| `handover_code_label` | Code à donner à l'hôpital | Code to give the hospital |
| `live_seconds_ago` | en direct · il y a @s s | live · @s s ago |
| `position_stale_minutes` | ⚠ position il y a @m min | ⚠ position @m min ago |
| `pill_to_bank` | En route vers la banque | On the way to the blood bank |
| `pill_to_hospital` | En route vers l'hôpital | On the way to the hospital |
| `pill_to_you` | En route vers vous | On the way to you |
| `pill_courier_coming` | Livreur en approche | Courier on the way |
| `confirm_reception` | Confirmer la réception | Confirm reception |
| `confirm_handover` | Confirmer la remise | Confirm handover |
| `follow_delivery` | Suivre | Follow |
| `duty_on` | En service | On duty |
| `duty_off` | Hors service | Off duty |
| `duty_finish_delivery_first` | Terminez la livraison en cours avant de passer hors service. | Finish the current delivery before going off duty. |
| `duty_location_needed` | Autorisez la localisation pour passer en service. | Allow location access to go on duty. |
| `contact_support` | Contacter le support | Contact support |
| `delivery_cancelled_by_admin` | Livraison annulée par l'administration. | Delivery cancelled by the administration. |
| `delivery_reassigned` | Livraison réassignée à un autre livreur. | Delivery reassigned to another courier. |
| `delivery_in_progress_bar` | Livraison en cours · @eta | Delivery in progress · @eta |

Reuse any key that already exists with the same meaning (`confirm_reception`, `track`). Don't duplicate keys.

- [ ] **Step 1: Failing test:** every key above exists and is non-empty in all 5 locales.
- [ ] **Step 2:** FAIL. **Step 3:** Add the keys. **Step 4:** PASS.
- [ ] **Step 5:** Commit `i18n(delivery): live tracking strings in 5 languages`.

### Task 10: Release build, device check, PR

- [ ] **Step 1:** `flutter analyze lib/delivery lib/apps/MonApplication.dart` → no errors. `flutter test` → no new failures against `main`.
- [ ] **Step 2:** Once the user has added `MAPS_API_KEY` to `android/local.properties`: `flutter build apk --release --target-platform android-arm64`, then `adb -s R8YL60Z8QRN install -r` (the phone has the release-signed build, so install over it to keep the login).
- [ ] **Step 3 (needs the user's go-ahead for the prod reset each time):** on the Galaxy A07, with prod delivery `del-E8E2D3E1` re-dispatched by the documented recipe:
  - turn « En service » on → the permanent notification shows;
  - accept the call → the 90 % sheet opens, the map shows a solid road line (not dashed) once part 1 has the routes key;
  - back and swipe-down don't close it; « Réduire » → the bar;
  - « Naviguer » opens Google Maps; while it's in front, the server's `delivery_person_last_seen_at` keeps advancing (check through `/tracking` or the console);
  - the slide `Arrivé à la banque` advances the phase;
  - logcat has no `Unhandled Exception`.
- [ ] **Step 4:** Push and open a PR to `main` (no attribution lines). The Play Console foreground-service declaration + video is the user's task before uploading the `.aab`.
