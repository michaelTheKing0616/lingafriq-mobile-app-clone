import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/classroom/school_provisioning_screen.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => ProviderScope(child: MaterialApp(home: child)),
  );
}

class _FakeSchoolService extends SchoolProvisioningService {
  _FakeSchoolService(this._status);

  final SchoolProvisionStatus _status;

  @override
  Future<SchoolProvisionStatus> fetchStatus(String classroomTribeId) async => _status;

  @override
  Future<bool> submitConsent({
    required String classroomTribeId,
    required String schoolName,
    required String authorityName,
    required String authorityTitle,
  }) async =>
      true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('consent missing banner and 48dp save button', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        SchoolProvisioningScreen(
          classroomTribeId: 'abc123',
          classroomName: 'Yoruba 101',
          service: _FakeSchoolService(
            SchoolProvisionStatus(
              consentStatus: 'pending',
              students: [
                SchoolProvisionStudentRow(studentUserId: 7, status: 'pending_consent'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(schoolConsentMissingTitle), findsOneWidget);
    final save = find.widgetWithText(FilledButton, 'Save consent');
    expect(save, findsOneWidget);
    expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
  });

  testWidgets('active state lists learners', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      _wrap(
        SchoolProvisioningScreen(
          classroomTribeId: 'abc123',
          classroomName: 'Yoruba 101',
          service: _FakeSchoolService(
            SchoolProvisionStatus(
              consentStatus: 'active',
              authorityName: 'Mrs Adebayo',
              students: [
                SchoolProvisionStudentRow(studentUserId: 42, status: 'active'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Learner #42'), findsOneWidget);
    expect(find.text('Add learner'), findsOneWidget);
  });
}
