import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lingafriq/widgets/content_label_badge.dart';

/// Copy keys (P5-047): quality.title, quality.no_data.
abstract final class QualityReportCopy {
  static const title = 'quality.title';
  static const noData = 'quality.no_data';
}

const String qualityReportApiPath = '/api/v2/quality/report';

enum QualityReportUiState { loading, data, notEnoughData, error }

class QualityLabelRate {
  const QualityLabelRate({
    required this.qualityLabel,
    required this.sampleCount,
    required this.errorCount,
    required this.errorRate,
    required this.insufficientData,
    this.asOf,
  });

  final String qualityLabel;
  final int sampleCount;
  final int errorCount;
  final double? errorRate;
  final bool insufficientData;
  final String? asOf;

  factory QualityLabelRate.fromJson(Map<String, dynamic> json) {
    final rate = json['error_rate'];
    return QualityLabelRate(
      qualityLabel: json['quality_label'] as String? ?? '',
      sampleCount: (json['sample_count'] as num?)?.toInt() ?? 0,
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      errorRate: rate is num ? rate.toDouble() : null,
      insufficientData: json['insufficient_data'] == true,
      asOf: json['as_of'] as String?,
    );
  }
}

class LanguageQualityRates {
  const LanguageQualityRates({required this.language, required this.labels});

  final String language;
  final List<QualityLabelRate> labels;

  factory LanguageQualityRates.fromJson(Map<String, dynamic> json) {
    final raw = json['labels'];
    final labels = <QualityLabelRate>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          labels.add(QualityLabelRate.fromJson(entry));
        }
      }
    }
    return LanguageQualityRates(
      language: json['language'] as String? ?? '',
      labels: labels,
    );
  }
}

class QualityReportPayload {
  const QualityReportPayload({
    required this.minSampleSize,
    required this.publishedAt,
    required this.languages,
  });

  final int minSampleSize;
  final String publishedAt;
  final List<LanguageQualityRates> languages;

  factory QualityReportPayload.fromJson(Map<String, dynamic> json) {
    final raw = json['languages'];
    final languages = <LanguageQualityRates>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is Map<String, dynamic>) {
          languages.add(LanguageQualityRates.fromJson(entry));
        }
      }
    }
    return QualityReportPayload(
      minSampleSize: (json['min_sample_size'] as num?)?.toInt() ?? 0,
      publishedAt: json['published_at'] as String? ?? '',
      languages: languages,
    );
  }
}

QualityReportPayload? parseQualityReportResponse(Object? body) {
  if (body is! Map<String, dynamic>) {
    return null;
  }
  if (body['ok'] != true) {
    return null;
  }
  final report = body['report'];
  if (report is! Map<String, dynamic>) {
    return null;
  }
  return QualityReportPayload.fromJson(report);
}

String formatPublishedErrorRate(QualityLabelRate row) {
  if (row.insufficientData || row.errorRate == null) {
    return QualityReportCopy.noData;
  }
  return '${(row.errorRate! * 100).toStringAsFixed(1)}%';
}

String formatSampleMeta(QualityLabelRate row) {
  if (row.insufficientData) {
    return QualityReportCopy.noData;
  }
  final date = _shortDate(row.asOf);
  return 'n=${row.sampleCount}${date == null ? '' : ' · $date'}';
}

String? _shortDate(String? iso) {
  if (iso == null || iso.isEmpty) {
    return null;
  }
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) {
    return null;
  }
  final y = parsed.year.toString().padLeft(4, '0');
  final m = parsed.month.toString().padLeft(2, '0');
  final d = parsed.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

Color labelChipColor(String label) {
  final normalized = label.toLowerCase();
  if (normalized.contains('beta')) {
    return ContentLabelColors.beta;
  }
  if (normalized.contains('native')) {
    return ContentLabelColors.native;
  }
  return ContentLabelColors.expert;
}

typedef QualityReportLoader = Future<QualityReportPayload?> Function();

class QualityReportScreen extends StatefulWidget {
  const QualityReportScreen({
    super.key,
    this.loader,
  });

  final QualityReportLoader? loader;

  @override
  State<QualityReportScreen> createState() => _QualityReportScreenState();
}

class _QualityReportScreenState extends State<QualityReportScreen> {
  QualityReportUiState _state = QualityReportUiState.loading;
  QualityReportPayload? _report;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = QualityReportUiState.loading);
    try {
      final loader = widget.loader ?? _defaultLoader;
      final report = await loader();
      if (!mounted) {
        return;
      }
      if (report == null || report.languages.isEmpty) {
        setState(() {
          _report = report;
          _state = QualityReportUiState.notEnoughData;
        });
        return;
      }
      setState(() {
        _report = report;
        _state = QualityReportUiState.data;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _state = QualityReportUiState.error);
    }
  }

  static Future<QualityReportPayload?> _defaultLoader() async {
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(QualityReportCopy.title),
      ),
      body: switch (_state) {
        QualityReportUiState.loading => const Center(child: CircularProgressIndicator()),
        QualityReportUiState.error => Center(
            child: Text(
              QualityReportCopy.noData,
              style: theme.textTheme.bodyLarge,
            ),
          ),
        QualityReportUiState.notEnoughData => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                QualityReportCopy.noData,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        QualityReportUiState.data => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final lang in _report!.languages) ...[
                Text(
                  lang.language.toUpperCase(),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (final label in lang.labels)
                  _LabelRateCard(label: label),
                const SizedBox(height: 16),
              ],
            ],
          ),
      },
    );
  }
}

class _LabelRateCard extends StatelessWidget {
  const _LabelRateCard({required this.label});

  final QualityLabelRate label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rateText = formatPublishedErrorRate(label);
    final meta = formatSampleMeta(label);
    final chipColor = labelChipColor(label.qualityLabel);
    return Semantics(
      label: '${label.qualityLabel} $rateText $meta',
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label.qualityLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rateText,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

QualityReportPayload decodeQualityReportJson(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('report root');
  }
  final parsed = parseQualityReportResponse(decoded);
  if (parsed == null) {
    throw const FormatException('report payload');
  }
  return parsed;
}
