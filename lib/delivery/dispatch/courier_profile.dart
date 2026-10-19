/// Is the logged-in account an ACTIVATED courier? Login adds
/// `mobile_app_delivery_person_profil` (the mobile `_profil` spelling) to
/// `user_profils` only while the console has the courier activated.
library;

import 'package:get_storage/get_storage.dart';

const courierLoginFlag = 'mobile_app_delivery_person_profil';

bool isActivatedCourier() {
  try {
    final profiles = GetStorage().read('user_profiles');
    if (profiles is! List) return false;
    return profiles.whereType<Map>().any((p) =>
        (p['profil'] ?? p['flag'])?.toString() == courierLoginFlag && p['enabled'] != false);
  } catch (_) {
    return false; // storage not ready: not a courier yet
  }
}
