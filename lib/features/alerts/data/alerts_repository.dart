import 'package:agniraksha_mobile/core/network/api_client.dart';
import 'package:agniraksha_mobile/core/network/api_endpoints.dart';
import 'package:agniraksha_mobile/features/alerts/domain/alert_model.dart';

class AlertsRepository {
  final ApiClient _client;

  AlertsRepository(this._client);

  Future<({List<AlertModel> items, int total})> fetchAlerts({
    int page = 1,
    int pageSize = 20,
    String? severity,
    bool? acknowledged,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (severity != null) params['severity'] = severity;
    if (acknowledged != null) params['acknowledged'] = acknowledged;

    final res = await _client.dio.get(
      ApiEndpoints.alerts,
      queryParameters: params,
    );
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>)
        .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = data['total'] as int? ?? 0;
    return (items: items, total: total);
  }

  Future<void> acknowledgeAlert(String alertId, {String? note}) async {
    await _client.dio.patch(
      ApiEndpoints.acknowledgeAlert(alertId),
      data: {'note': note},
    );
  }
}
