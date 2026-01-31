/// API response shape notes (for frontend/backend sync).
///
/// Key endpoints and expected response structure:
///
/// - **Auth:** POST auth/jwt/create/ → { access, refresh }; POST auth/jwt/refresh/ → { access }
/// - **Lessons:** GET lessons/ → { result: { count, next, previous, results }, total_score };
///   GET lessons/:id/all → [[...lessons], ...quizArray]; PATCH lesson_lesson/quiz_detail → { msg }
/// - **History:** Same pattern as lessons (history_lesson, quiz_detail)
/// - **History Quiz / Language Quiz:** GET :id/all → sections; PATCH .../quiz_detail → { msg }
/// - **Random Quiz:** GET :langId/all → [{ inst_question, word_question: [] }]; PATCH inst_ques_detail/word_ques_detail → { msg }
/// - **User preferences:** GET/PUT api/user/preferences → { ...preferences }
///
/// Keep models in lib/models/ in sync with these shapes when backend changes.
library;
