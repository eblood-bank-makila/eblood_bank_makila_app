import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sticky batch-number ("numéro de lot") selection for the current app session.
///
/// A plain, top-level (non-autoDispose) [StateProvider] is kept alive for the
/// lifetime of the [ProviderScope]: the selection survives navigation and every
/// re-open of the add-blood-stock page during the session, and resets to null
/// only on app restart. Mirrors the existing `deliveryPersonIdProvider` pattern.
final selectedBatchNumberProvider = StateProvider<String?>((ref) => null);
