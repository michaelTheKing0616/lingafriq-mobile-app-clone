# Groq API Integration with Aya 8B

## Overview

The AI chat system has been upgraded from HuggingFace to Groq API with the Aya 8B model. This provides:

✅ **FREE unlimited usage** (no credit card required)
✅ **Better African language support** - Aya 8B is trained on 53 African languages
✅ **Streaming responses** - Real-time text generation like ChatGPT
✅ **Advanced features** - Tutor mode, SRS, CEFR tracking, grammar checking, pronunciation scoring

## Setup

### 1. Get Groq API Key

1. Visit https://console.groq.com/
2. Sign up for a free account
3. Create an API key
4. Copy your API key

### 2. Configure API Key

**Option A: Environment Variable (Recommended for CI/CD)**
```bash
export GROQ_API_KEY=your_api_key_here
```

**Option B: Direct Configuration**
Edit `lib/providers/ai_chat_provider_groq.dart`:
```dart
static String get _groqApiKey {
  return 'your_api_key_here'; // Replace with your actual key
}
```

## Features

### 1. Streaming Chat
- Real-time response streaming
- Sentence-aware chunking for natural flow
- Interrupt on user input

### 2. Adaptive Tutor Mode
- Automatically adjusts difficulty based on user performance
- Provides structured learning prompts
- Turn-based conversation flow

### 3. Spaced Repetition System (SRS)
- Tracks vocabulary mastery
- Schedules automatic reviews
- Long-term memory retention

### 4. CEFR Level Tracking
- Tracks user progress from A1 to C2
- Updates based on grammar, pronunciation, comprehension, and vocabulary scores
- Visual progress indicators

### 5. Grammar Error Detection
- Analyzes user text for errors
- Provides corrections and explanations
- Scores accuracy (0.0-1.0)

### 6. Pronunciation Scoring
- Speech shadowing exercises
- Word Error Rate (WER) calculation
- Pronunciation accuracy feedback

### 7. Listening Comprehension
- Generates listening passages
- Multiple choice and open-ended questions
- Automatic answer evaluation

### 8. Curriculum Generation
- Creates structured lesson plans
- Week-by-week progression
- CEFR-aligned content

## Usage

### Basic Chat
```dart
final provider = ref.read(groqChatProvider.notifier);

// Streaming
await for (final chunk in provider.sendMessageStream('Hello in Yoruba')) {
  print(chunk); // Real-time chunks
}

// Non-streaming
final response = await provider.sendMessage('Hello in Yoruba');
```

### Grammar Check
```dart
final feedback = await provider.grammarCheck('Yoruba', 'Mo wa dada');
print(feedback.corrected);
print(feedback.score);
```

### Shadowing Exercise
```dart
final result = await provider.shadowingExercise(audioBytes, 'E kaaro');
print(result['score']); // 0.0-1.0
print(result['wer']); // Word Error Rate
```

### Listening Comprehension
```dart
final passage = await provider.generateListeningPassage('Yoruba', 2);
// Returns passage text and questions
```

### Curriculum Generation
```dart
final curriculum = await provider.generateCurriculum(
  language: 'Yoruba',
  targetCEFR: 'B1',
  weeks: 8,
);
```

## UI Components

### Shadowing Exercise Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ShadowingExerciseScreen(
      referenceText: 'E kaaro',
      language: 'Yoruba',
    ),
  ),
);
```

### Listening Quiz Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ListeningQuizScreen(
      passageData: passageData,
    ),
  ),
);
```

### Curriculum Viewer
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CurriculumViewerScreen(
      curriculum: curriculum,
    ),
  ),
);
```

### CEFR Progress Card
```dart
final cefr = ref.watch(groqChatProvider.notifier).cefrInfo;
CEFRProgressCard(cefr: cefr)
```

## Migration from HuggingFace

The old `huggingFaceChatProvider` has been replaced with `groqChatProvider`. Update your imports:

**Before:**
```dart
import 'package:lingafriq/providers/ai_chat_provider_huggingface.dart';
ref.read(huggingFaceChatProvider.notifier)
```

**After:**
```dart
import 'package:lingafriq/providers/ai_chat_provider_groq.dart';
ref.read(groqChatProvider.notifier)
```

## API Limits

Groq provides:
- **FREE tier**: Unlimited requests (no credit card)
- **Fast responses**: 20-60 tokens/second
- **Production-ready**: Stable endpoints

## Supported Languages

Aya 8B supports 53 African languages including:
- Swahili
- Yoruba
- Hausa
- Igbo
- Zulu
- Xhosa
- Amharic
- Somali
- Lingala
- Shona
- Kinyarwanda
- Nigerian Pidgin
- And many more!

## Testing

Run unit tests:
```bash
flutter test test/ai_chat_provider_test.dart
```

Tests cover:
- Word Error Rate (WER) calculation
- CEFR level mapping
- Grammar parser JSON handling

## Troubleshooting

### "AI Chat is not configured"
- Ensure `GROQ_API_KEY` is set or configured in the provider
- Check that the API key is valid

### Streaming not working
- Check internet connection
- Verify API key permissions
- Check Groq API status

### Audio recording issues
- Ensure microphone permissions are granted
- Check that `record` package is properly configured

## Next Steps

1. Set your Groq API key
2. Test the basic chat functionality
3. Explore advanced features (tutor mode, SRS, etc.)
4. Integrate UI components into your app flow

## Resources

- Groq Console: https://console.groq.com/
- Aya 8B Model: https://huggingface.co/CohereForAI/aya-8b
- API Documentation: https://console.groq.com/docs

