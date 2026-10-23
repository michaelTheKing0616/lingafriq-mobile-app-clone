# Hybrid Polie Architecture - Complete Guide

## Overview

Hybrid Polie is a **composite AI system** that combines multiple specialized models to provide the best possible language learning experience. Instead of relying on a single model for all tasks, it intelligently routes each request to the model that excels at that specific task.

## Core Philosophy

**"Use the right tool for the right job"**

- **LLaMA-3.1-70B-Versatile**: Best for dialogue, roleplay, tutoring, and long-form explanations
- **NLLB-200**: Best for translation accuracy (200+ languages)
- **AfriTeVa/AfriT5**: Best for generating orthographically correct canonical phrases
- **ASR + MFA**: Best for pronunciation scoring and feedback

## Architecture Flow

```
User Message
    ↓
[Language Identification] (Optional - can use existing language selection)
    ↓
[Task Classification] (TRANSLATE | TUTOR | ROLEPLAY | VOCAB | etc.)
    ↓
[Model Router] → Routes to appropriate model
    ↓
┌─────────────────────────────────────────┐
│                                         │
│  TRANSLATE → NLLB-200                   │
│  CANONICAL → AfriTeVa                   │
│  PRONUNCIATION → ASR + MFA              │
│  DIALOGUE/ROLEPLAY/TUTOR → LLaMA-70B    │
│                                         │
└─────────────────────────────────────────┘
    ↓
[Post-Processing]
    ├─ Diacritics Enforcement
    ├─ Orthography Validation
    └─ Canonical Phrase Matching
    ↓
[Response Assembly]
    ├─ Add metadata (model used, confidence, corrections)
    ├─ Flag for native review if needed
    └─ Stream to user
```

## Detailed Component Breakdown

### 1. Model Router (`model_router.dart`)

**Purpose**: Intelligent routing based on task type and language requirements.

**Routing Logic**:
```dart
- TRANSLATE → NLLB-200 (best translation accuracy)
- CANONICAL_PHRASE → AfriTeVa (best orthography)
- PRONUNCIATION → ASR + MFA (phoneme-level accuracy)
- ROLEPLAY/TUTOR/CONVERSATION → LLaMA-3.1-70B (best dialogue)
```

**Key Features**:
- Automatic task classification
- Language-aware routing
- Fallback mechanisms

### 2. Translation Service (`translation_service.dart`)

**Purpose**: High-quality translation using NLLB-200.

**How it works**:
1. Receives text, source language, target language
2. Maps languages to NLLB language codes (e.g., `yoruba` → `yor_Latn`)
3. Calls HuggingFace Inference API for NLLB-200
4. Returns translation with confidence score
5. Falls back to LLaMA if NLLB fails

**Example**:
```
Input: "Hello" (English → Yoruba)
Output: "Báwo" (with correct diacritics)
Confidence: 0.9
Model: NLLB-200
```

**Why NLLB-200?**
- Explicitly trained on 200+ languages including African languages
- Better translation accuracy than general-purpose LLMs
- Handles low-resource languages better

### 3. Canonical Phrase Service (`canonical_phrase_service.dart`)

**Purpose**: Generate orthographically correct phrases with proper diacritics.

**How it works**:
1. Receives phrase and target language
2. Tries local AfriTeVa service first (if available)
3. Falls back to HuggingFace Inference API
4. Returns canonical form with confidence
5. Ultimate fallback: returns original (will be corrected by diacritics module)

**Example**:
```
Input: "bawo ni" (Yoruba, missing diacritics)
Output: "Báwo ní" (canonical form)
Confidence: 0.85
Model: AfriTeVa
```

**Why AfriTeVa?**
- Specifically trained on African language corpora
- Better orthography than general models
- Understands diacritics and tone marks

### 4. Hybrid Polie Orchestrator (`hybrid_polie_orchestrator.dart`)

**Purpose**: Main coordination layer that orchestrates all models.

**Orchestration Flow**:

1. **Task Classification**
   ```dart
   TaskType taskType = _modeToTaskType(mode);
   // Maps PolieMode → TaskType
   ```

2. **Model Selection**
   ```dart
   ModelType modelType = ModelRouter.routeTask(
     taskType: taskType,
     language: targetLanguage,
     ...
   );
   ```

3. **Model Execution**
   - **NLLB-200**: Direct translation
   - **AfriTeVa**: Canonical phrase generation
   - **LLaMA-70B**: Enhanced prompt with canonical phrase injection
   - **ASR+MFA**: Pronunciation scoring

4. **Post-Processing**
   ```dart
   // Enforce diacritics
   final result = DiacriticsEnforcer.enforceWithMetadata(
     rawOutput,
     targetLanguage,
   );
   
   // Validate orthography
   final isValid = _validateOrthography(finalOutput, targetLanguage);
   ```

5. **Response Assembly**
   ```dart
   return HybridPolieResponse(
     output: finalOutput,
     model: modelUsed,
     diacriticsCorrected: wasCorrected,
     confidence: confidence,
     metadata: metadata,
     needsNativeReview: !isValid || confidence < 0.65,
   );
   ```

### 5. Integration with Existing Provider (`ai_chat_provider_groq.dart`)

**How Hybrid Polie integrates**:

1. **Feature Flag**: `_useHybridPolie = true` (enabled by default)

2. **Conditional Routing**:
   ```dart
   if (_useHybridPolie && shouldUseHybrid) {
     // Use hybrid orchestrator
     final response = await _hybridOrchestrator!.orchestrate(...);
     // Stream response word-by-word
   } else {
     // Fall back to standard Groq flow
   }
   ```

3. **Backward Compatibility**:
   - If hybrid fails, automatically falls back to standard mode
   - All existing features (SRS, CEFR tracking, etc.) still work
   - No breaking changes

## Canonical Phrase Injection

**For Tutor/Vocab modes**, Hybrid Polie:

1. **Generates canonical phrase first** using AfriTeVa
2. **Injects into LLaMA prompt**:
   ```
   CANONICAL_PHRASE_CONSTRAINT: You MUST use this exact phrase verbatim: "Báwo ní"
   Do not modify, translate, or paraphrase this phrase.
   
   User request: How do I say "How are you?" in Yoruba?
   ```

3. **LLaMA uses canonical phrase** in its response while still providing:
   - Grammar breakdown
   - Pronunciation guide
   - Practice exercises
   - Cultural context

**Result**: Best of both worlds - orthographic accuracy + pedagogical excellence

## Post-Processing Pipeline

### Diacritics Enforcement

Every output goes through `DiacriticsEnforcer`:

1. **NFC Normalization**: Ensures Unicode consistency
2. **Exact Phrase Matching**: Checks against curated phrasebook
3. **Fuzzy Matching**: Levenshtein distance for similar phrases
4. **Token Overlap**: Heuristic matching for partial matches

**Example**:
```
Input: "bawo ni" (from NLLB or LLaMA)
Process: Fuzzy match finds "Báwo ní" in phrasebook
Output: "Báwo ní" (corrected)
Metadata: {method: 'fuzzy', score: 0.92, changed: true}
```

### Orthography Validation

Validates that all characters are valid for the target language:

```dart
final validChars = SupportedLanguages.getValidCharacters(language);
// Checks each character against valid set
// Logs warnings for invalid characters
```

## Telemetry & Quality Control

### Events Tracked

1. **Diacritics Corrected**: When diacritics module fixes output
2. **Low Confidence**: When model confidence < 0.65
3. **Native Review Queued**: When output needs human verification
4. **Model Used**: Which model handled the request
5. **Fallback Triggered**: When primary model failed

### Native Review Queue

Outputs are flagged for native review if:
- Orthography validation fails
- Confidence < 0.65
- Diacritics were heavily corrected
- User reports inaccuracy

## Mode-Specific Behavior

### Translation Mode
```
User: "Translate 'Hello' to Yoruba"
  ↓
Router: TRANSLATE → NLLB-200
  ↓
NLLB-200: "Báwo"
  ↓
Diacritics: Already correct, no change
  ↓
Response: "Báwo" (with metadata)
```

### Tutor Mode
```
User: "How do I say 'Good morning' in Yoruba?"
  ↓
Router: TUTOR → LLaMA-70B (but needs canonical)
  ↓
AfriTeVa: Generates "Ẹ káàrọ̀"
  ↓
LLaMA Prompt: "CANONICAL: Ẹ káàrọ̀. Explain this phrase..."
  ↓
LLaMA: Provides breakdown, pronunciation, practice
  ↓
Diacritics: Validates and corrects if needed
  ↓
Response: Full tutor response with canonical phrase
```

### Roleplay Mode
```
User: "Let's practice ordering food"
  ↓
Router: ROLEPLAY → LLaMA-70B
  ↓
LLaMA: Creates scenario, generates dialogue
  ↓
Diacritics: Corrects any phrases in target language
  ↓
Response: Roleplay scenario with corrections
```

## Backend API Endpoints

### `/api/hybrid-polie/translate`
- **Method**: POST
- **Body**: `{text, sourceLang, targetLang}`
- **Returns**: Translation with confidence

### `/api/hybrid-polie/canonical`
- **Method**: POST
- **Body**: `{phrase, language}`
- **Returns**: Canonical phrase

### `/api/hybrid-polie/pronounce`
- **Method**: POST
- **Body**: `{audioUrl, referenceText, language}`
- **Returns**: Pronunciation score and feedback

### `/api/hybrid-polie/orchestrate`
- **Method**: POST
- **Body**: `{userMessage, mode, targetLanguage, sourceLanguage}`
- **Returns**: Full orchestrated response

## Configuration

### Environment Variables

**Mobile App**:
- `GROQ_API_KEY`: For LLaMA-3.1-70B (via Groq)
- `HUGGINGFACE_TOKEN`: For NLLB-200 and AfriTeVa (optional)

**Backend**:
- `NLLB_API_URL`: NLLB service endpoint
- `AFRITEVA_URL`: Local AfriTeVa service (optional)
- `MFA_SERVICE_URL`: MFA pronunciation service (optional)
- `HUGGINGFACE_TOKEN`: For HuggingFace Inference API

### Feature Flags

```dart
// Enable/disable hybrid mode
groqProvider.setHybridMode(true); // or false
```

## Performance Characteristics

### Latency
- **NLLB Translation**: ~500-1000ms (HuggingFace API)
- **AfriTeVa Canonical**: ~300-800ms (local) or ~1000-2000ms (HF API)
- **LLaMA Dialogue**: ~1000-3000ms (streaming)
- **MFA Pronunciation**: ~2000-5000ms (depends on audio length)

### Fallback Strategy
1. Try primary model
2. If fails, try fallback model
3. If still fails, use standard Groq flow
4. Log error for monitoring

## Benefits Over Single-Model Approach

1. **Better Translation Accuracy**: NLLB-200 > LLaMA for translation
2. **Better Orthography**: AfriTeVa > LLaMA for canonical phrases
3. **Better Dialogue**: LLaMA-70B > NLLB for conversations
4. **Better Pronunciation**: MFA > LLM for phoneme-level feedback
5. **Quality Assurance**: Multi-layer validation (model → diacritics → orthography)

## Limitations & Future Improvements

### Current Limitations
1. **NLLB-200**: Requires HuggingFace API (rate limits)
2. **AfriTeVa**: Local service not always available
3. **MFA**: Requires separate service deployment
4. **Latency**: Multiple API calls can add delay

### Future Improvements
1. **Caching**: Cache translations and canonical phrases
2. **Batch Processing**: Batch multiple requests
3. **Local Models**: Deploy models locally for lower latency
4. **Model Fine-tuning**: Fine-tune models on LingAfriq data
5. **Ensemble Voting**: Use multiple models and vote on best output

## Testing

### Test Scenarios

1. **Translation Accuracy**: Compare NLLB vs LLaMA translations
2. **Orthography**: Verify diacritics are correct
3. **Fallback**: Test when services are unavailable
4. **Performance**: Measure latency and throughput
5. **User Experience**: A/B test hybrid vs standard mode

## Monitoring

### Key Metrics
- Model usage distribution
- Diacritics correction rate
- Confidence scores
- Fallback frequency
- User satisfaction (via ratings)

### Alerts
- High fallback rate (>10%)
- Low confidence rate (>20%)
- Service unavailability
- High latency (>5s)

## Conclusion

Hybrid Polie represents a **production-ready, intelligent routing system** that leverages the strengths of multiple specialized models to provide the best possible language learning experience. It maintains backward compatibility while significantly improving accuracy and quality.

