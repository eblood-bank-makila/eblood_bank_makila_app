import 'package:eblood_bank_mak_app/utilisateurs/ui/pages/notification/NotificationPageState.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../business/interactors/UtilisateurInteractor.dart';
import '../../../business/models/notification/SuppressionDatumNotificationModel.dart';

part 'NotificationCtrl.g.dart';

@Riverpod(keepAlive: true)
class NotificationCtrl extends _$NotificationCtrl {
  @override
  NotificationPageState build() {
    return NotificationPageState();
  }

  Future<void> listenotification() async {
    var usecase = ref
        .watch(utilisateurInteractorProvider)
        .recuperationNotificationUseCase;
    var res = await usecase.run();
    state = state.copyWith(notification: res);
  }

  Future<void> supprimer_notification(
      SuppressionDatumNotificationModel notification) async {
    var usecase =
        ref.watch(utilisateurInteractorProvider).suppressionNotificationUseCase;
    var id_not = notification.id;
    var res = await usecase.run(id_not);
    state = state.copyWith(supprimer_notification: res);
  }
}
