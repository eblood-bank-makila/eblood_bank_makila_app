import '../../../apps/models/api_response.dart';
import '../../../apps/config/api/dio_client.dart';
import 'UserNetworkService.dart';

class UserNetworkServiceImpl implements UserNetworkService {
  static const String _usersList = '/users/fetch';
  static const String _userSearch = '/users/search';
  static const String _userCreate = '/organizations/add/users';
  static const String _userDelete = '/organizations/hard-delete/user';
  static String _userUpdate(String id) => '/organizations/update/sys_user/' + id;
  static const String _rolesList = '/cores/get-config-roles';

  @override
  Future<IApiResponse> listUsers({int page = 0, int limit = 20, String? searchQuery}) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (searchQuery != null && searchQuery.isNotEmpty) {
        params['search_key'] = searchQuery;
        return await getWithDio(_userSearch, queryParams: params);
      }
      return await getWithDio(_usersList, queryParams: params);
    } catch (e) {
      return IApiResponse.error('List users error: $e');
    }
  }

  @override
  Future<IApiResponse> createUser(Map<String, dynamic> userData) async {
    try {
      return await postWithDio(_userCreate, body: userData);
    } catch (e) {
      return IApiResponse.error('Create user error: $e');
    }
  }

  @override
  Future<IApiResponse> updateUser(String userId, Map<String, dynamic> updateData) async {
    try {
      return await putWithDio(_userUpdate(userId), body: updateData);
    } catch (e) {
      return IApiResponse.error('Update user error: $e');
    }
  }

  @override
  Future<IApiResponse> deleteUser(String userId) async {
    try {
      return await deleteWithDio(_userDelete, queryParams: {
        'item_id': userId,
      });
    } catch (e) {
      return IApiResponse.error('Delete user error: $e');
    }
  }

  @override
  Future<IApiResponse> getRoles() async {
    try {
      return await getWithDio(_rolesList, queryParams: {
        'limit': 100,
        'page': 0,
      });
    } catch (e) {
      return IApiResponse.error('Get roles error: $e');
    }
  }
}

