import '../../../core/network/api_client.dart';
import 'peak_hour_model.dart';

class SystemConfigApi {
  const SystemConfigApi();

  Future<PeakHourConfig?> getPeakHourConfig() async {
    final response = await apiClient.get('/api/systemconfig/peak-hours');

    if (response == null) {
      return null;
    }

    if (response is List) {
      if (response.isEmpty) {
        return null;
      }

      final current = response.last;

      if (current is Map) {
        return PeakHourConfig.fromJson(Map<String, dynamic>.from(current));
      }

      throw const FormatException(
        'Dữ liệu cấu hình giờ cao điểm không hợp lệ.',
      );
    }

    if (response is Map) {
      return PeakHourConfig.fromJson(Map<String, dynamic>.from(response));
    }

    throw const FormatException(
      'Dữ liệu cấu hình giờ cao điểm không đúng định dạng.',
    );
  }
}

const systemConfigApi = SystemConfigApi();
