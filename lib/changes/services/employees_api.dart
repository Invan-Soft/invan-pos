import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/app_constants.dart';

class EmployeesApi {
  static Future<HttpResult> findEmployees() async {
    final response = await ApiProvider.getResponse(
      path: 'api/v1/employee?limit=100',
      headers: AppConstants.getHeaders(),
    );
    return response;
  }

  static Future<HttpResult> getEmployeesRoles(String id) async {
    final response = await ApiProvider.getResponse(
      path: 'api/v1/role/$id?limit=1000',
      headers: AppConstants.getHeaders(),
    );
    return response;
  }

  static Future<HttpResult> getRoleWithPermissions() async {
    final response = await ApiProvider.getResponse(
      path: 'api/v1/role_with_permissions?limit=1000&search=&page=1',
      headers: AppConstants.getHeaders(),
    );
    return response;
  }
}
