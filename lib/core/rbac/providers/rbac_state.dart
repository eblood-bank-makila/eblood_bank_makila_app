import 'package:flutter/foundation.dart';
import '../models/rbac_models.dart';

@immutable
class RbacState {
  final bool isLoading;
  final bool isLoaded;
  final String? errorMessage;
  final List<RbacApplication> applications;

  const RbacState({
    this.isLoading = false,
    this.isLoaded = false,
    this.errorMessage,
    this.applications = const [],
  });

  bool get hasError => errorMessage != null;

  /// Get all menus across all applications (flattened).
  List<RbacMenu> get allMenus {
    return applications.expand((app) => app.subMenus).toList();
  }

  RbacState copyWith({
    bool? isLoading,
    bool? isLoaded,
    String? errorMessage,
    List<RbacApplication>? applications,
    bool clearError = false,
  }) {
    return RbacState(
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      applications: applications ?? this.applications,
    );
  }

  RbacState asLoading() => copyWith(isLoading: true, clearError: true);

  RbacState asError(String message) =>
      copyWith(isLoading: false, errorMessage: message);

  RbacState asLoaded(List<RbacApplication> apps) => copyWith(
        isLoading: false,
        isLoaded: true,
        applications: apps,
      );
}
