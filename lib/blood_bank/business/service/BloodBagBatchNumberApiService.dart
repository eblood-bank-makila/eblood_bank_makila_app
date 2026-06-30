import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';

/// Thin client over the platform's generic, organization-scoped CRUD endpoints
/// for the `bloodBagBatchNumbers` collection.
///
/// The backend `/generic/org/*` routes inject `sys_organization_id` +
/// `created_by_id` from the authenticated user's token, so the org scoping is
/// entirely server-side — no org id is sent from the client.
class BloodBagBatchNumberApiService {
  // collection name (camelCase) as registered in the backend CollectionKey enum
  static const String _collection = 'bloodBagBatchNumbers';

  static const String _fetchUrl = '/generic/org/fetch/$_collection';
  static const String _addUrl = '/generic/org/add/$_collection';
  static const String _putUrl = '/generic/org/put/$_collection';
  static const String _deleteUrl = '/generic/org/hard-delete/$_collection';

  /// Paginated list for the current organization.
  /// Response envelope `{data:[...docs], max, limit}` is unwrapped by
  /// [IApiResponse.fromData] → `res.data` is the list, `res.max` is the total.
  Future<IApiResponse> getBatchNumbers({int page = 0, int limit = 20}) async {
    return await getWithDio(
      _fetchUrl,
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );
  }

  /// Create a new batch number for the current organization.
  /// Returns `{item_id, message}` on success.
  Future<IApiResponse> createBatchNumber(String batchNumber) async {
    return await postWithDio(
      _addUrl,
      body: {'batch_number': batchNumber},
    );
  }

  /// Update an existing batch number (item id travels as a query param).
  Future<IApiResponse> updateBatchNumber(String id, String batchNumber) async {
    return await putWithDio(
      _putUrl,
      queryParams: {'item_id': id},
      body: {'batch_number': batchNumber},
    );
  }

  /// Delete a batch number (item id travels as a query param).
  Future<IApiResponse> deleteBatchNumber(String id) async {
    return await deleteWithDio(
      _deleteUrl,
      queryParams: {'item_id': id},
    );
  }
}

/// Org scoping is server-side, so this service needs no RBAC URL resolution —
/// a plain provider is enough.
final bloodBagBatchNumberApiServiceProvider =
    Provider<BloodBagBatchNumberApiService>(
  (ref) => BloodBagBatchNumberApiService(),
);
