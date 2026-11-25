import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Copy keys: school.provision.title, school.consent.missing (P9-916).
/// Reference: Google Classroom roster + Apple School Manager consent flow.
const String schoolProvisionTitle = 'School learner accounts';
const String schoolConsentMissingTitle = 'School consent needed';

class SchoolProvisionStatus {
  SchoolProvisionStatus({
    required this.consentStatus,
    this.authorityName,
    this.schoolName,
    this.students = const [],
  });

  final String consentStatus;
  final String? authorityName;
  final String? schoolName;
  final List<SchoolProvisionStudentRow> students;

  bool get consentActive => consentStatus == 'active';

  factory SchoolProvisionStatus.fromJson(Map<String, dynamic> json) {
    final consentRaw = json['consent'];
    final consent = consentRaw is Map ? Map<String, dynamic>.from(consentRaw) : null;
    final studentsRaw = json['students'];
    final students = <SchoolProvisionStudentRow>[];
    if (studentsRaw is List) {
      for (final item in studentsRaw) {
        if (item is Map) {
          students.add(SchoolProvisionStudentRow.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return SchoolProvisionStatus(
      consentStatus: consent?['status']?.toString() ?? 'missing',
      authorityName: consent?['authority_name']?.toString(),
      schoolName: consent?['school_name']?.toString(),
      students: students,
    );
  }
}

class SchoolProvisionStudentRow {
  SchoolProvisionStudentRow({required this.studentUserId, required this.status});

  final int studentUserId;
  final String status;

  factory SchoolProvisionStudentRow.fromJson(Map<String, dynamic> json) {
    return SchoolProvisionStudentRow(
      studentUserId: (json['student_user_id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'pending_consent',
    );
  }
}

typedef SchoolProvisionGet = Future<Map<String, dynamic>> Function(String path);
typedef SchoolProvisionPost = Future<Map<String, dynamic>> Function(
  String path, {
  Map<String, Object?>? data,
});

class SchoolProvisioningService {
  SchoolProvisioningService({
    SchoolProvisionGet? get,
    SchoolProvisionPost? post,
  })  : _get = get ?? _defaultGet,
        _post = post ?? _defaultPost;

  final SchoolProvisionGet _get;
  final SchoolProvisionPost _post;

  static Future<Map<String, dynamic>> _defaultGet(String path) async {
    await ApiService.initialize();
    final response = await ApiService.get(path);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  static Future<Map<String, dynamic>> _defaultPost(
    String path, {
    Map<String, Object?>? data,
  }) async {
    await ApiService.initialize();
    final response = await ApiService.post(path, data: data);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  Future<SchoolProvisionStatus> fetchStatus(String classroomTribeId) async {
    final json = await _get(
      '/api/v2/classroom/school/provision/status?classroom_tribe_id=$classroomTribeId',
    );
    if (json['ok'] != true) {
      throw SchoolProvisioningException(json['code']?.toString() ?? 'load_failed');
    }
    return SchoolProvisionStatus.fromJson(json);
  }

  Future<bool> submitConsent({
    required String classroomTribeId,
    required String schoolName,
    required String authorityName,
    required String authorityTitle,
  }) async {
    final json = await _post(
      '/api/v2/classroom/school/consent',
      data: {
        'classroom_tribe_id': classroomTribeId,
        'school_name': schoolName,
        'authority_name': authorityName,
        'authority_title': authorityTitle,
      },
    );
    return json['ok'] == true;
  }

  Future<bool> provisionStudent({
    required String classroomTribeId,
    required String studentLocalId,
    required String firstName,
    required int birthYear,
  }) async {
    final json = await _post(
      '/api/v2/classroom/school/students',
      data: {
        'classroom_tribe_id': classroomTribeId,
        'student_local_id': studentLocalId,
        'first_name': firstName,
        'birth_year': birthYear,
      },
    );
    return json['ok'] == true;
  }
}

class SchoolProvisioningException implements Exception {
  SchoolProvisioningException(this.code);
  final String code;
}

enum SchoolProvisionUiPhase { loading, empty, consentMissing, active, error, provisioning }

class SchoolProvisioningScreen extends HookConsumerWidget {
  const SchoolProvisioningScreen({
    super.key,
    required this.classroomTribeId,
    required this.classroomName,
    this.service,
  });

  final String classroomTribeId;
  final String classroomName;
  final SchoolProvisioningService? service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = service ?? SchoolProvisioningService();
    final phase = useState(SchoolProvisionUiPhase.loading);
    final status = useState<SchoolProvisionStatus?>(null);
    final errorMessage = useState<String?>(null);
    final submitting = useState(false);

    final schoolController = useTextEditingController();
    final authorityController = useTextEditingController();
    final titleController = useTextEditingController();
    final studentIdController = useTextEditingController();
    final firstNameController = useTextEditingController();

    Future<void> load() async {
      phase.value = SchoolProvisionUiPhase.loading;
      errorMessage.value = null;
      try {
        final next = await svc.fetchStatus(classroomTribeId);
        status.value = next;
        if (next.students.isEmpty && !next.consentActive) {
          phase.value = SchoolProvisionUiPhase.empty;
        } else if (!next.consentActive) {
          phase.value = SchoolProvisionUiPhase.consentMissing;
        } else {
          phase.value = SchoolProvisionUiPhase.active;
        }
      } catch (e) {
        phase.value = SchoolProvisionUiPhase.error;
        errorMessage.value = 'We could not load school provisioning right now.';
      }
    }

    useEffect(() {
      unawaited(load());
      return null;
    }, [classroomTribeId]);

    Future<void> submitConsent() async {
      submitting.value = true;
      phase.value = SchoolProvisionUiPhase.provisioning;
      try {
        final ok = await svc.submitConsent(
          classroomTribeId: classroomTribeId,
          schoolName: schoolController.text.trim(),
          authorityName: authorityController.text.trim(),
          authorityTitle: titleController.text.trim(),
        );
        if (!ok) {
          phase.value = SchoolProvisionUiPhase.consentMissing;
          errorMessage.value = 'Please check the consent details and try again.';
          return;
        }
        await load();
      } finally {
        submitting.value = false;
      }
    }

    Future<void> addStudent() async {
      submitting.value = true;
      phase.value = SchoolProvisionUiPhase.provisioning;
      try {
        final birthYear = DateTime.now().year - 10;
        final ok = await svc.provisionStudent(
          classroomTribeId: classroomTribeId,
          studentLocalId: studentIdController.text.trim(),
          firstName: firstNameController.text.trim(),
          birthYear: birthYear,
        );
        if (!ok) {
          errorMessage.value = 'We could not add that learner yet.';
          await load();
          return;
        }
        studentIdController.clear();
        firstNameController.clear();
        await load();
      } finally {
        submitting.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          schoolProvisionTitle,
          style: PanAfricanTypography.titleLarge(context),
        ),
      ),
      body: ResponsiveSafeArea(
        child: switch (phase.value) {
          SchoolProvisionUiPhase.loading => const Center(
              child: CircularProgressIndicator(),
            ),
          SchoolProvisionUiPhase.error => _ErrorBody(
              message: errorMessage.value ?? 'Something went wrong.',
              onRetry: load,
            ),
          SchoolProvisionUiPhase.provisioning => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: PanAfricanSpacing.md.h),
                  const Text('Saving…'),
                ],
              ),
            ),
          SchoolProvisionUiPhase.empty ||
          SchoolProvisionUiPhase.consentMissing =>
            _ConsentForm(
              classroomName: classroomName,
              showMissingBanner: phase.value == SchoolProvisionUiPhase.consentMissing,
              schoolController: schoolController,
              authorityController: authorityController,
              titleController: titleController,
              onSubmit: submitConsent,
              errorMessage: errorMessage.value,
            ),
          SchoolProvisionUiPhase.active => _ActiveBody(
              status: status.value,
              classroomName: classroomName,
              studentIdController: studentIdController,
              firstNameController: firstNameController,
              onAddStudent: addStudent,
              onRefresh: load,
              submitting: submitting.value,
            ),
        },
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: PanAfricanTypography.bodyLarge(context), textAlign: TextAlign.center),
          SizedBox(height: PanAfricanSpacing.lg.h),
          Semantics(
            button: true,
            label: 'Try again',
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentForm extends StatelessWidget {
  const _ConsentForm({
    required this.classroomName,
    required this.showMissingBanner,
    required this.schoolController,
    required this.authorityController,
    required this.titleController,
    required this.onSubmit,
    this.errorMessage,
  });

  final String classroomName;
  final bool showMissingBanner;
  final TextEditingController schoolController;
  final TextEditingController authorityController;
  final TextEditingController titleController;
  final Future<void> Function() onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
      children: [
        if (showMissingBanner)
          Semantics(
            container: true,
            label: schoolConsentMissingTitle,
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md.w),
                child: Text(
                  '$schoolConsentMissingTitle. Add the signed school authority record before learners can sign in.',
                  style: PanAfricanTypography.bodyMedium(context),
                ),
              ),
            ),
          ),
        SizedBox(height: PanAfricanSpacing.md.h),
        Text(
          'Class: $classroomName',
          style: PanAfricanTypography.titleMedium(context),
        ),
        SizedBox(height: PanAfricanSpacing.lg.h),
        TextField(
          controller: schoolController,
          decoration: const InputDecoration(labelText: 'School name'),
        ),
        SizedBox(height: PanAfricanSpacing.md.h),
        TextField(
          controller: authorityController,
          decoration: const InputDecoration(labelText: 'Signing authority name'),
        ),
        SizedBox(height: PanAfricanSpacing.md.h),
        TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Authority title'),
        ),
        if (errorMessage != null) ...[
          SizedBox(height: PanAfricanSpacing.md.h),
          Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        SizedBox(height: PanAfricanSpacing.xl.h),
        Semantics(
          button: true,
          label: 'Save school consent',
          child: SizedBox(
            width: double.infinity,
            height: 48.h,
            child: FilledButton(
              onPressed: onSubmit,
              child: const Text('Save consent'),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveBody extends StatelessWidget {
  const _ActiveBody({
    required this.status,
    required this.classroomName,
    required this.studentIdController,
    required this.firstNameController,
    required this.onAddStudent,
    required this.onRefresh,
    required this.submitting,
  });

  final SchoolProvisionStatus? status;
  final String classroomName;
  final TextEditingController studentIdController;
  final TextEditingController firstNameController;
  final Future<void> Function() onAddStudent;
  final Future<void> Function() onRefresh;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final students = status?.students ?? const [];
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
        children: [
          Text(
            classroomName,
            style: PanAfricanTypography.titleMedium(context),
          ),
          if (status?.authorityName != null && status!.authorityName!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: PanAfricanSpacing.sm.h),
              child: Text(
                'Consent: ${status!.authorityName}',
                style: PanAfricanTypography.bodyMedium(context),
              ),
            ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          Text('Provisioned learners', style: PanAfricanTypography.titleSmall(context)),
          if (students.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md.h),
              child: Text(
                'No school accounts yet. Add a learner ID and first name below.',
                style: PanAfricanTypography.bodyMedium(context),
              ),
            )
          else
            ...students.map(
              (s) => ListTile(
                title: Text('Learner #${s.studentUserId}'),
                subtitle: Text(s.status.replaceAll('_', ' ')),
              ),
            ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          TextField(
            controller: studentIdController,
            decoration: const InputDecoration(labelText: 'School learner ID'),
          ),
          SizedBox(height: PanAfricanSpacing.md.h),
          TextField(
            controller: firstNameController,
            decoration: const InputDecoration(labelText: 'First name'),
          ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          Semantics(
            button: true,
            label: 'Add school learner',
            child: SizedBox(
              width: double.infinity,
              height: 48.h,
              child: FilledButton(
                onPressed: submitting ? null : onAddStudent,
                child: const Text('Add learner'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
