# Using Llama in Polie - Complete Guide

## 🧠 Current Llama Integration

### ✅ What We Have

**Current Implementation:**
- **Llama 3.1-70B** via Groq API (excellent quality, free tier)
- Integrated in `ai_chat_provider_groq.dart`
- Used by Hybrid Polie orchestrator for dialogue/tutor/roleplay modes
- Streaming responses
- Context-aware conversations

**Location:**
- `lib/providers/ai_chat_provider_groq.dart`
- `lib/services/hybrid_polie/hybrid_polie_orchestrator.dart`

---

## 📋 How Llama is Used in Polie

### 1. **Via Groq API (Current - Recommended)**

**Why Groq:**
- ✅ Free tier with excellent limits
- ✅ Fast inference (low latency)
- ✅ Llama 3.1-70B (high quality)
- ✅ No infrastructure needed
- ✅ Reliable uptime

**Usage:**
```dart
// Already integrated in GroqChatProvider
final response = await _dio.post(
  _groqUrl,
  data: {
    "model": "llama-3.1-70b-versatile",
    "messages": messagesList,
    "temperature": 0.7,
    "stream": true,
  },
);
```

**Models Available:**
- `llama-3.1-70b-versatile` - Best quality (default)
- `llama-3.1-8b-instant` - Faster fallback

---

### 2. **Via Hybrid Polie Orchestrator**

**Routing Logic:**
```dart
// In hybrid_polie_orchestrator.dart
case ModelType.llama70b:
  // Dialogue/roleplay/tutor → LLaMA-3.1-70B
  rawOutput = await _callLlamaDirectly(
    prompt: enhancedPrompt,
    systemPrompt: groqProvider.currentSystemPrompt,
  );
```

**When Llama is Used:**
- ✅ Tutor mode (adaptive teaching)
- ✅ Roleplay mode (conversation scenarios)
- ✅ Conversation mode (natural dialogue)
- ✅ When canonical phrases are needed

**When Other Models are Used:**
- Translation → NLLB-200
- Canonical phrases → AfriTeVa
- Pronunciation → MFA/Wav2Vec2

---

## 🔧 Configuration

### API Key Setup

**Environment Variable:**
```dart
// In env_config.dart
static String get groqApiKey => 
  const String.fromEnvironment('GROQ_API_KEY') ?? 
  Platform.environment['GROQ_API_KEY'] ?? 
  '';
```

**Get Free API Key:**
1. Visit: https://console.groq.com/
2. Sign up (free, no credit card)
3. Get API key
4. Set in environment or `.env` file

---

## 🚀 Advanced Usage

### Custom System Prompts

```dart
// Set custom system prompt for Llama
await groqProvider.setSystemPrompt('''
You are a Yoruba language tutor.
Focus on tone accuracy and cultural context.
''');
```

### Temperature Control

```dart
// In ai_chat_provider_groq.dart
"temperature": _mode == PolieMode.translation ? 0.2 : 0.7,
// Lower for translation (more deterministic)
// Higher for conversation (more creative)
```

### Context Management

```dart
// Conversation context manager handles:
// - Context window management
// - Conversation summarization
// - Long-term memory
// Already integrated!
```

---

## 🔄 Alternative: Local Llama (Optional)

### When to Use Local

- ✅ Offline requirements
- ✅ Data privacy concerns
- ✅ High volume usage
- ✅ Custom fine-tuning needed

### Implementation (Future)

**Option 1: Ollama (Easiest)**
```dart
// Local Llama via Ollama
final response = await dio.post(
  'http://localhost:11434/api/generate',
  data: {
    'model': 'llama3.1',
    'prompt': prompt,
    'stream': true,
  },
);
```

**Option 2: Direct Integration**
- Use `llama_cpp` or `transformers`
- Requires GPU infrastructure
- More complex setup

**Current Recommendation:**
- ✅ **Keep Groq** (excellent, free, reliable)
- ⚠️ **Add local option** only if needed for offline/privacy

---

## 📊 Performance Comparison

| Aspect | Groq (Current) | Local Llama |
|--------|----------------|-------------|
| **Quality** | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐⭐ Good |
| **Speed** | ⭐⭐⭐⭐⭐ Very Fast | ⭐⭐⭐ Medium |
| **Cost** | ⭐⭐⭐⭐⭐ Free | ⭐⭐⭐ Hardware |
| **Setup** | ⭐⭐⭐⭐⭐ Easy | ⭐⭐ Complex |
| **Reliability** | ⭐⭐⭐⭐⭐ High | ⭐⭐⭐ Medium |
| **Offline** | ❌ No | ✅ Yes |
| **Privacy** | ⚠️ API | ✅ Local |

**Verdict:** Groq is excellent for most use cases. Local only if offline/privacy critical.

---

## 🎯 Best Practices

### 1. **Use Appropriate Models**
```dart
// High quality for important tasks
'model': 'llama-3.1-70b-versatile'

// Faster for simple tasks
'model': 'llama-3.1-8b-instant'
```

### 2. **Manage Context Window**
```dart
// Already handled by ConversationContextManager
// Keeps last 15 messages, summarizes older ones
```

### 3. **Error Handling**
```dart
// Already integrated with ErrorRecoveryService
// Automatic retries, graceful degradation
```

### 4. **Performance Tracking**
```dart
// Already integrated with PerformanceAnalytics
// Tracks latency, success rates
```

---

## 🔍 Troubleshooting

### Issue: API Key Not Working
**Solution:**
1. Check environment variable
2. Verify key at https://console.groq.com/
3. Check rate limits

### Issue: Slow Responses
**Solution:**
1. Use `llama-3.1-8b-instant` for faster responses
2. Reduce context window
3. Check network connection

### Issue: Poor Quality
**Solution:**
1. Use `llama-3.1-70b-versatile` (better quality)
2. Improve system prompts
3. Add more context

---

## 📚 Integration Examples

### Example 1: Basic Usage
```dart
final provider = ref.read(groqChatProvider.notifier);
await provider.sendMessage('Hello in Yoruba');
```

### Example 2: With Context
```dart
// Context manager automatically handles:
// - Conversation history
// - Summarization
// - Long-term memory
final response = await provider.sendMessageStream('Continue conversation');
```

### Example 3: Custom Mode
```dart
await provider.setMode(PolieMode.tutor);
await provider.sendMessage('Teach me greetings');
```

---

## 🎓 Summary

**Current Setup:**
- ✅ Llama 3.1-70B via Groq (excellent)
- ✅ Fully integrated
- ✅ Error recovery
- ✅ Performance tracking
- ✅ Context management

**Recommendation:**
- ✅ **Keep current setup** (Groq is excellent)
- ⚠️ **Add local option** only if needed
- ✅ **Focus on other upgrades** (visual pitch, ML curriculum)

**You're already using world-class Llama integration!** 🎉

