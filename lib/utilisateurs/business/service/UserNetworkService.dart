import '../../../apps/models/api_response.dart';

abstract class UserNetworkService {
  Future<IApiResponse> listUsers({
    int page = 0,
    int limit = 20,
    String? searchQuery,
  });

  Future<IApiResponse> createUser(Map<String, dynamic> userData);

  Future<IApiResponse> updateUser(String userId, Map<String, dynamic> updateData);

  Future<IApiResponse> deleteUser(String userId);

  Future<IApiResponse> getRoles();
}

