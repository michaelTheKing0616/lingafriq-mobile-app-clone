import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/gamification/gamification_widgets.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

enum _FundPhase { loading, idle, donating, success, error, offline }

/// Heritage Fund — reference: Duolingo gem charity sink + Kiva impact ledger layout.
class PreservationFundScreen extends ConsumerStatefulWidget {
  const PreservationFundScreen({super.key, this.initialSummaryForTest});

  /// Widget tests inject ledger summary without network (not used in production routes).
  @visibleForTesting
  final Map<String, dynamic>? initialSummaryForTest;

  @override
  ConsumerState<PreservationFundScreen> createState() => _PreservationFundScreenState();
}

class _PreservationFundScreenState extends ConsumerState<PreservationFundScreen> {
  static const _amounts = [50, 100, 200];

  _FundPhase _phase = _FundPhase.loading;
  int _selectedAmount = 50;
  String? _errorMessage;
  String? _errorCode;
  int _fundReceived = 0;
  int _fundDisbursed = 0;
  int _yourDonations = 0;
  bool _impactRecorded = false;
  List<Map<String, dynamic>> _disbursements = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final seed = widget.initialSummaryForTest;
      if (seed != null) {
        _applySummary(Map<String, dynamic>.from(seed));
        setState(() => _phase = _FundPhase.idle);
        return;
      }
      _loadSummary();
    });
  }

  Future<void> _loadSummary() async {
    setState(() {
      _phase = _FundPhase.loading;
      _errorMessage = null;
      _errorCode = null;
    });
    try {
      final res = await ref.read(client).get('/api/rewards/preservation-fund/summary');
      if (!mounted) return;
      if (res.statusCode == 200 && res.data is Map) {
        final raw = (res.data as Map)['data'];
        final data = raw is Map ? Map<String, dynamic>.from(raw) : null;
        _applySummary(data);
        setState(() => _phase = _FundPhase.idle);
        return;
      }
      setState(() {
        _phase = _FundPhase.error;
        _errorMessage = 'We could not load the fund page. Try again.';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final offline = e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout;
      setState(() {
        _phase = offline ? _FundPhase.offline : _FundPhase.error;
        _errorMessage = offline
            ? 'You are offline. Connect to see fund totals and donate.'
            : 'We could not load the fund page. Try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _FundPhase.error;
        _errorMessage = 'We could not load the fund page. Try again.';
      });
    }
  }

  void _applySummary(Map<String, dynamic>? data) {
    if (data == null) return;
    _fundReceived = (data['total_cowries_received'] as num?)?.toInt() ?? 0;
    _fundDisbursed = (data['total_cowries_disbursed'] as num?)?.toInt() ?? 0;
    _yourDonations = (data['your_donations_count'] as num?)?.toInt() ?? 0;
    _impactRecorded = data['impact_recorded'] == true;
    final raw = data['disbursements'] as List<dynamic>? ?? [];
    _disbursements = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _confirmDonate() async {
    final balance = ref.read(gamificationProvider.notifier).gamification.cowries;
    if (balance < _selectedAmount) {
      setState(() {
        _phase = _FundPhase.error;
        _errorCode = 'INSUFFICIENT_COWRIES';
        _errorMessage = 'You need ${_selectedAmount - balance} more Cowries for this gift.';
      });
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            PanAfricanSpacing.lg,
            PanAfricanSpacing.sm,
            PanAfricanSpacing.lg,
            PanAfricanSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Send to the Heritage Fund', style: PanAfricanTypography.titleLarge(ctx)),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                'Your $_selectedAmount Cowries go to community language-preservation work. You will not receive a personal item.',
                style: PanAfricanTypography.bodyMedium(ctx),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(minimumSize: Size.fromHeight(48.h)),
                child: const Text('Confirm gift'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Not now'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;
    await _donate();
  }

  Future<void> _donate() async {
    setState(() {
      _phase = _FundPhase.donating;
      _errorMessage = null;
      _errorCode = null;
    });

    final evidenceId = 'fund_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final res = await ref.read(client).post(
        '/api/rewards/preservation-fund/donate',
        data: {
          'evidence_id': evidenceId,
          'amount': _selectedAmount,
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200 && res.data is Map) {
        await ref.read(gamificationProvider.notifier).refreshGamification();
        await _loadSummary();
        if (!mounted) return;
        setState(() => _phase = _FundPhase.success);
        return;
      }
      final body = res.data is Map ? res.data as Map : {};
      setState(() {
        _phase = _FundPhase.error;
        _errorCode = body['code']?.toString();
        _errorMessage = body['error']?.toString() ?? 'Your gift did not go through. Try again.';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final offline = e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout;
      final body = e.response?.data is Map ? e.response!.data as Map : {};
      setState(() {
        _phase = offline ? _FundPhase.offline : _FundPhase.error;
        _errorCode = body['code']?.toString();
        _errorMessage = offline
            ? 'You are offline. Your Cowries were not spent.'
            : body['error']?.toString() ?? 'Your gift did not go through. Try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _FundPhase.error;
        _errorCode = 'DONATION_FAILED';
        _errorMessage = 'Your gift did not go through. Try again.';
      });
    }
  }

  List<Widget> _amountChoiceChips(bool donating) {
    return _amounts.map((amount) {
      final selected = _selectedAmount == amount;
      return Semantics(
        label: '$amount Cowries',
        selected: selected,
        button: true,
        child: ChoiceChip(
          label: Text('$amount Cowries'),
          selected: selected,
          onSelected: donating ? null : (_) => setState(() => _selectedAmount = amount),
        ),
      );
    }).toList();
  }

  Widget _impactSection(BuildContext context) {
    if (!_impactRecorded) {
      return Semantics(
        label: 'Community impact. Nothing has been funded from the ledger yet.',
        child: Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Text(
              'Community impact will appear here once funded projects are recorded in our ledger. Nothing has been funded yet.',
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Funded from the ledger', style: PanAfricanTypography.titleMedium(context)),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          '$_fundDisbursed Cowries disbursed · $_fundReceived Cowries received from learners',
          style: PanAfricanTypography.bodySmall(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        ..._disbursements.map((row) {
          final title = row['title']?.toString() ?? '';
          final amount = (row['cowries_amount'] as num?)?.toInt() ?? 0;
          return Padding(
            padding: EdgeInsets.only(bottom: PanAfricanSpacing.xs),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(title, style: PanAfricanTypography.bodyLarge(context)),
              trailing: Text('$amount', style: PanAfricanTypography.labelLarge(context)),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(gamificationProvider);
    final balance = ref.read(gamificationProvider.notifier).gamification.cowries;
    final donating = _phase == _FundPhase.donating;

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text('Heritage Fund', style: PanAfricanTypography.titleLarge(context)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
            child: CowriesBalanceChip(amount: balance, compact: true),
          ),
        ],
      ),
      body: ResponsiveSafeArea(
        child: _phase == _FundPhase.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                children: [
                  Text(
                    'Gift Cowries to language-preservation work across Africa. Every figure on this page comes from our server ledger—never estimates.',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                  if (_yourDonations > 0) ...[
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      'You have made $_yourDonations gift${_yourDonations == 1 ? '' : 's'} so far. Thank you.',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                  if (_phase == _FundPhase.success) ...[
                    SizedBox(height: PanAfricanSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        'Thank you — your Cowries reached the fund.',
                        style: PanAfricanTypography.bodyLarge(context).copyWith(
                          color: PanAfricanColors.primary,
                        ),
                      ),
                    ),
                  ],
                  if (_phase == _FundPhase.error || _phase == _FundPhase.offline) ...[
                    SizedBox(height: PanAfricanSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _errorMessage ?? 'Something went wrong.',
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    OutlinedButton(
                      onPressed: donating
                          ? null
                          : () {
                              if (_phase == _FundPhase.offline ||
                                  _errorCode == null ||
                                  _errorCode == 'DONATION_FAILED') {
                                if (_phase == _FundPhase.offline) {
                                  _loadSummary();
                                } else {
                                  _donate();
                                }
                              } else {
                                _loadSummary();
                              }
                            },
                      style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(48.h)),
                      child: Text(_phase == _FundPhase.offline ? 'Try again when online' : 'Retry'),
                    ),
                  ],
                  SizedBox(height: PanAfricanSpacing.lg),
                  _impactSection(context),
                  SizedBox(height: PanAfricanSpacing.lg),
                  Text('Choose a gift size', style: PanAfricanTypography.titleMedium(context)),
                  SizedBox(height: PanAfricanSpacing.sm),
                  Wrap(
                    spacing: PanAfricanSpacing.sm,
                    runSpacing: PanAfricanSpacing.sm,
                    children: _amountChoiceChips(donating),
                  ),
                  SizedBox(height: PanAfricanSpacing.lg),
                  Semantics(
                    button: true,
                    label: 'Send $_selectedAmount Cowries to the Heritage Fund',
                    child: FilledButton(
                      onPressed: donating || _phase == _FundPhase.offline
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              _confirmDonate();
                            },
                      style: FilledButton.styleFrom(minimumSize: Size.fromHeight(48.h)),
                      child: donating
                          ? SizedBox(
                              width: 22.w,
                              height: 22.w,
                              child: const CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send gift'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
