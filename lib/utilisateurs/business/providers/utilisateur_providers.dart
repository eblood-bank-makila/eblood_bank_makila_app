import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/utilisateurLocalService.dart';
import '../../ui/framework/UtilisateurLocalServiceImpl.dart';

// This provider would typically be initialized in your app's bootstrap
// with the actual database instance
final utilisateurLocalServiceProvider = Provider<UtilisateurLocalService>((ref) {
  // This is a placeholder. In your actual code, this would be initialized
  // in the main.dart with the real database instance
  throw UnimplementedError(
      'utilisateurLocalServiceProvider must be overridden with a database instance.');
});

// Override this provider in your main.dart with:
// container.read(utilisateurLocalServiceProvider.overrideWithValue(utilisateurLocalImpl));