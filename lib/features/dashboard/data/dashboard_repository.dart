import 'package:agniraksha_mobile/core/network/api_client.dart';
import 'package:agniraksha_mobile/core/network/api_endpoints.dart';
import 'package:agniraksha_mobile/features/dashboard/domain/dashboard_models.dart';

class DashboardRepository {
  final ApiClient _client;

  DashboardRepository(this._client);

  Future<DashboardSummary> fetchSummary() async {
    final res = await _client.dio.get(ApiEndpoints.dashboardSummary);
    return DashboardSummary.fromJson(res.data as Map<String, dynamic>);
  }
}
