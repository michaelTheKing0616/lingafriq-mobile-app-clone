// P11-021 — Teacher persona-chapter assignment and debrief sheet (domain).

import 'dart:convert';

import 'package:flutter/foundation.dart';

const String kPersonaAssignmentKind = 'persona_chapter';

@immutable
class PersonaChapterAssignmentPayload {
  const PersonaChapterAssignmentPayload({
    required this.questId,
    required this.personaId,
    required this.chapterIndex,
    required this.chapterId,
    required this.canDoId,
    required this.canDoStatementEn,
    required this.recipientUserIds,
  });

  final String questId;
  final String personaId;
  final int chapterIndex;
  final String chapterId;
  final String canDoId;
  final String canDoStatementEn;
  final List<String> recipientUserIds;

  Map<String, dynamic> toAssignmentBody({
    required String title,
    String? description,
    DateTime? dueAt,
  }) {
    return {
      'title': title,
      if (description != null) 'description': description,
      'type': 'custom',
      if (dueAt != null) 'dueAt': dueAt.toUtc().toIso8601String(),
      'payload': {
        'kind': kPersonaAssignmentKind,
        'quest_id': questId,
        'persona_id': personaId,
        'chapter_index': chapterIndex,
        'chapter_id': chapterId,
        'can_do_id': canDoId,
        'can_do_statement_en': canDoStatementEn,
        'recipient_user_ids': recipientUserIds,
      },
    };
  }

  static PersonaChapterAssignmentPayload? fromAssignmentJson(
    Map<String, dynamic> assignment,
  ) {
    final payload = assignment['payload'];
    if (payload is! Map<String, dynamic>) return null;
    if (payload['kind'] != kPersonaAssignmentKind) return null;
    final recipients = payload['recipient_user_ids'];
    return PersonaChapterAssignmentPayload(
      questId: payload['quest_id'] as String,
      personaId: payload['persona_id'] as String,
      chapterIndex: payload['chapter_index'] as int,
      chapterId: payload['chapter_id'] as String,
      canDoId: payload['can_do_id'] as String,
      canDoStatementEn: payload['can_do_statement_en'] as String,
      recipientUserIds: (recipients as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }
}

bool isVerifiedClassroom({
  required bool isClassroom,
  required String? classroomCode,
}) {
  if (!isClassroom) return false;
  final code = (classroomCode ?? '').trim();
  return code.length >= 4;
}

bool isClassroomTeacherRole({
  required String ownerUserId,
  required String userId,
  required String memberRole,
}) {
  return ownerUserId == userId ||
      memberRole == 'admin' ||
      memberRole == 'officer';
}

List<String> enrolledStudentIds(Iterable<({String userId, String role})> members) {
  return members
      .where((m) => m.role == 'member')
      .map((m) => m.userId)
      .toList();
}

PersonaChapterAssignmentPayload? buildPersonaChapterAssignment({
  required String questId,
  required int chapterIndex,
  required List<String> enrolledStudentUserIds,
  List<String>? targetStudentUserIds,
  required PersonaChapterCatalogEntry? Function(String questId, int chapterIndex)
      catalogLookup,
}) {
  final chapter = catalogLookup(questId, chapterIndex);
  if (chapter == null) return null;
  final enrolled = enrolledStudentUserIds.toSet();
  if (enrolled.isEmpty) return null;
  final requested =
      (targetStudentUserIds != null && targetStudentUserIds.isNotEmpty)
          ? targetStudentUserIds
          : enrolledStudentUserIds;
  final recipients = requested.where(enrolled.contains).toList();
  if (recipients.isEmpty) return null;
  return PersonaChapterAssignmentPayload(
    questId: chapter.questId,
    personaId: chapter.personaId,
    chapterIndex: chapter.chapterIndex,
    chapterId: chapter.chapterId,
    canDoId: chapter.canDoId,
    canDoStatementEn: chapter.canDoStatementEn,
    recipientUserIds: recipients,
  );
}

@immutable
class PersonaChapterCatalogEntry {
  const PersonaChapterCatalogEntry({
    required this.questId,
    required this.personaId,
    required this.chapterIndex,
    required this.chapterId,
    required this.canDoId,
    required this.canDoStatementEn,
  });

  final String questId;
  final String personaId;
  final int chapterIndex;
  final String chapterId;
  final String canDoId;
  final String canDoStatementEn;
}

@immutable
class PersonaTurnEvidence {
  const PersonaTurnEvidence({
    required this.kind,
    required this.detail,
    this.artifactKey,
  });

  final String kind;
  final String detail;
  final String? artifactKey;

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'detail': detail,
        if (artifactKey != null) 'artifactKey': artifactKey,
      };
}

enum CanDoEvidenceStatus { met, notMet, unsure }

@immutable
class CanDoTurnGrade {
  const CanDoTurnGrade({
    required this.turnId,
    required this.canDoId,
    required this.canDoStatementEn,
    required this.status,
    required this.evidence,
    this.flagged = false,
    this.flagReason,
  });

  final String turnId;
  final String canDoId;
  final String canDoStatementEn;
  final CanDoEvidenceStatus status;
  final PersonaTurnEvidence evidence;
  final bool flagged;
  final String? flagReason;

  Map<String, dynamic> toJson() => {
        'turnId': turnId,
        'canDoId': canDoId,
        'canDoStatementEn': canDoStatementEn,
        'status': status.name,
        'evidence': evidence.toJson(),
        'flagged': flagged,
        if (flagReason != null) 'flagReason': flagReason,
      };
}

CanDoTurnGrade? gradePersonaTurn({
  required String turnId,
  required String questId,
  required int chapterIndex,
  required CanDoEvidenceStatus outcome,
  required PersonaTurnEvidence evidence,
  bool flagged = false,
  String? flagReason,
  required PersonaChapterCatalogEntry? chapter,
}) {
  if (chapter == null) return null;
  return CanDoTurnGrade(
    turnId: turnId,
    canDoId: chapter.canDoId,
    canDoStatementEn: chapter.canDoStatementEn,
    status: outcome,
    evidence: evidence,
    flagged: flagged,
    flagReason: flagReason,
  );
}

@immutable
class TeacherDebriefSheet {
  const TeacherDebriefSheet({
    required this.assignmentId,
    required this.tribeId,
    required this.questId,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.canDoSummaries,
    required this.flaggedTurns,
    required this.students,
  });

  final String assignmentId;
  final String tribeId;
  final String questId;
  final int chapterIndex;
  final String chapterTitle;
  final List<DebriefCanDoSummary> canDoSummaries;
  final List<DebriefFlaggedTurn> flaggedTurns;
  final List<StudentDebriefRow> students;

  static TeacherDebriefSheet fromJson(Map<String, dynamic> json) {
    return TeacherDebriefSheet(
      assignmentId: json['assignmentId'] as String,
      tribeId: json['tribeId'] as String,
      questId: json['questId'] as String,
      chapterIndex: json['chapterIndex'] as int,
      chapterTitle: json['chapterTitle'] as String,
      canDoSummaries: (json['canDoSummaries'] as List<dynamic>)
          .map((e) => DebriefCanDoSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      flaggedTurns: (json['flaggedTurns'] as List<dynamic>)
          .map((e) => DebriefFlaggedTurn.fromJson(e as Map<String, dynamic>))
          .toList(),
      students: (json['students'] as List<dynamic>)
          .map((e) => StudentDebriefRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class DebriefCanDoSummary {
  const DebriefCanDoSummary({
    required this.canDoId,
    required this.statementEn,
    required this.metCount,
    required this.notMetCount,
    required this.unsureCount,
  });

  final String canDoId;
  final String statementEn;
  final int metCount;
  final int notMetCount;
  final int unsureCount;

  static DebriefCanDoSummary fromJson(Map<String, dynamic> json) =>
      DebriefCanDoSummary(
        canDoId: json['canDoId'] as String,
        statementEn: json['statementEn'] as String,
        metCount: json['metCount'] as int,
        notMetCount: json['notMetCount'] as int,
        unsureCount: json['unsureCount'] as int,
      );
}

@immutable
class DebriefFlaggedTurn {
  const DebriefFlaggedTurn({
    required this.studentUserId,
    required this.turnId,
    required this.canDoId,
    required this.flagReason,
  });

  final String studentUserId;
  final String turnId;
  final String canDoId;
  final String flagReason;

  static DebriefFlaggedTurn fromJson(Map<String, dynamic> json) =>
      DebriefFlaggedTurn(
        studentUserId: json['studentUserId'] as String,
        turnId: json['turnId'] as String,
        canDoId: json['canDoId'] as String,
        flagReason: json['flagReason'] as String,
      );
}

@immutable
class StudentDebriefRow {
  const StudentDebriefRow({
    required this.studentUserId,
    required this.assignmentComplete,
    required this.canDoGrades,
  });

  final String studentUserId;
  final bool assignmentComplete;
  final List<CanDoTurnGrade> canDoGrades;

  static StudentDebriefRow fromJson(Map<String, dynamic> json) =>
      StudentDebriefRow(
        studentUserId: json['studentUserId'] as String,
        assignmentComplete: json['assignmentComplete'] as bool,
        canDoGrades: const [],
      );
}

/// Under-13 uses maximum persona safety tier (align with server agePolicy).
enum PersonaLearnerAgeTier { under13, under18, adult }

PersonaLearnerAgeTier personaAgeTierFromBirthYear({
  required int birthYear,
  int? nowYear,
}) {
  final year = nowYear ?? DateTime.now().toUtc().year;
  final age = year - birthYear;
  if (age < 13) return PersonaLearnerAgeTier.under13;
  if (age < 18) return PersonaLearnerAgeTier.under18;
  return PersonaLearnerAgeTier.adult;
}

bool personaTurnRequiresUnder13Policy(PersonaLearnerAgeTier tier) =>
    tier == PersonaLearnerAgeTier.under13;

String encodeDebriefSheetJson(TeacherDebriefSheet sheet) =>
    jsonEncode({
      'assignmentId': sheet.assignmentId,
      'tribeId': sheet.tribeId,
      'questId': sheet.questId,
      'chapterIndex': sheet.chapterIndex,
      'chapterTitle': sheet.chapterTitle,
      'canDoSummaries': sheet.canDoSummaries
          .map(
            (s) => {
              'canDoId': s.canDoId,
              'statementEn': s.statementEn,
              'metCount': s.metCount,
              'notMetCount': s.notMetCount,
              'unsureCount': s.unsureCount,
            },
          )
          .toList(),
      'flaggedTurns': sheet.flaggedTurns
          .map(
            (f) => {
              'studentUserId': f.studentUserId,
              'turnId': f.turnId,
              'canDoId': f.canDoId,
              'flagReason': f.flagReason,
            },
          )
          .toList(),
      'students': sheet.students
          .map(
            (s) => {
              'studentUserId': s.studentUserId,
              'assignmentComplete': s.assignmentComplete,
            },
          )
          .toList(),
    });
