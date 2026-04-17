import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';

/// Staff/admin API for micro-mentor safety reports (backend: `requireAdminOrStaff`).
class MicroMentorModerationService {
  Future<MicroMentorModerationListResult> listReports({
    String? status,
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    await ApiService.initialize();
    final uri = Uri.parse(ApiContract.url(ApiContract.microMentorsV2.adminReports)).replace(
      queryParameters: {
        'limit': '$limit',
        'offset': '$offset',
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (category != null && category.trim().isNotEmpty) 'category': category.trim(),
      },
    );
    final res = await ApiService.get(uri.toString());
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Failed to load reports (${res.statusCode})');
    }
    final m = res.data as Map;
    final raw = m['data'];
    final rows = raw is List
        ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : <Map<String, dynamic>>[];
    final total = m['total'] is num ? (m['total'] as num).toInt() : rows.length;
    return MicroMentorModerationListResult(
      rows: rows,
      total: total,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>> patchReport({
    required String reportId,
    required String status,
    String? reviewNote,
  }) async {
    await ApiService.initialize();
    final res = await ApiService.patch(
      ApiContract.url(ApiContract.microMentorsV2.adminReport(reportId)),
      data: {
        'status': status,
        if (reviewNote != null) 'reviewNote': reviewNote,
      },
    );
    if (res.statusCode != 200 || res.data is! Map) {
      throw Exception('Update failed (${res.statusCode})');
    }
    final data = (res.data as Map)['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    return Map<String, dynamic>.from(res.data as Map);
  }
}

class MicroMentorModerationListResult {
  final List<Map<String, dynamic>> rows;
  final int total;
  final int limit;
  final int offset;

  MicroMentorModerationListResult({
    required this.rows,
    required this.total,
    required this.limit,
    required this.offset,
  });

  bool get hasMore => offset + rows.length < total;
}
