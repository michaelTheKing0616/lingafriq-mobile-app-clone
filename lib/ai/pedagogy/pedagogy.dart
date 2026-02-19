// LingAfriq AI Pedagogy System
//
// The AI tutor is a deterministic pedagogue, not a chatbot.
// It operates through structured tutor turns with strict JSON output.
//
// Modules:
//
// - AiTutorController — Main tutor controller (evaluation + generation)
// - TutorTurn — Structured turn schema
// - TutorFeedback — Constrained feedback output
// - ErrorClassifier — Error classification from responses
// - PromptTemplates — Layered prompt architecture

export 'ai_tutor_controller.dart';
export 'tutor_turn.dart';
export 'error_classifier.dart';
export 'prompt_templates.dart';
