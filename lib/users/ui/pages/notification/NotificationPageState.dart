import 'package:eblood_bank_mak_app/users/business/models/notification/SuppressionDatumNotificationModel.dart';

import '../../../business/models/notification/DatumNotificationModel.dart';

class NotificationPageState {
  bool isLoading;
  List<DatumNotificationModel> notification;
  SuppressionDatumNotificationModel? supprimer_notification;

  NotificationPageState({
    this.isLoading = false,
    this.notification = const [],
    this.supprimer_notification = null,
    //chargement
  });

  NotificationPageState copyWith(
          {bool? isLoading,
          List<DatumNotificationModel>? notification,
          SuppressionDatumNotificationModel? supprimer_notification}) =>
      NotificationPageState(
          isLoading: isLoading ?? this.isLoading,
          notification: notification ?? this.notification,
          supprimer_notification:
              supprimer_notification ?? this.supprimer_notification);
}
