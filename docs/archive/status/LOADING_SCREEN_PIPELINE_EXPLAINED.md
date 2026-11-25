# AI Loading Screen Pipeline - Complete Technical Explanation

## 🎯 Overview

The AI loading screen pipeline is a multi-layered system that displays culturally rich, rotating content during app initialization. It combines client-side content management, optional AI image generation, and backend content delivery.

---

## 📱 **Current Implementation (Client-Side Only)**

### **Flow Diagram:**
```
App Launch
    ↓
SplashScreen (3 seconds)
    ↓
DynamicLoadingScreen
    ↓
LoadingScreenProvider (Riverpod)
    ↓
LoadingScreenContentData (Static Content)
    ↓
SharedPreferences (Track Viewed Content)
    ↓
Display Content → Navigate to App
```

### **Step-by-Step Breakdown:**

#### **1. App Initialization (`main.dart`)**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ... Firebase, etc.
  runApp(ProviderScope(child: MyApp()));
}
```
- App starts, initializes Flutter framework
- Sets up Riverpod providers
- No loading screen logic here yet

#### **2. MyApp Widget (`my_app.dart`)**
```dart
MaterialApp(
  home: SplashScreen(), // First screen shown
)
```
- `SplashScreen` is the initial route
- This is where the loading screen pipeline begins

#### **3. SplashScreen (`splash_screen.dart`)**
```dart
class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showDynamicLoading = true;
  
  @override
  void initState() {
    Timer(const Duration(seconds: 3), () {
      setState(() => _showDynamicLoading = false);
      ref.read(authProvider.notifier).navigateBasedOnCondition();
    });
  }
  
  Widget build(BuildContext context) {
    if (_showDynamicLoading) {
      return DynamicLoadingScreen(...);
    }
    // Fallback
  }
}
```

**What happens:**
- Timer starts (3 seconds)
- Shows `DynamicLoadingScreen` immediately
- After 3 seconds, hides loading screen and navigates

#### **4. DynamicLoadingScreen (`dynamic_loading_screen.dart`)**

**Initialization:**
```dart
@override
void initState() {
  // Refresh content to get a new one
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(loadingScreenProvider.notifier).refreshContent();
  });
  
  // Setup progress animation
  _progressController = AnimationController(
    duration: const Duration(seconds: 3),
    vsync: this,
  );
  
  _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(...);
  _progressController.forward();
}
```

**Rendering:**
```dart
Widget build(BuildContext context) {
  final content = ref.watch(loadingScreenProvider); // Watches provider
  
  return Scaffold(
    body: Column(
      children: [
        _buildLogo(),                    // App logo
        _buildPersonIllustration(content), // Circular image
        _buildGreeting(content),         // "Karibu!" + translation
        _buildFact(content),             // "Did you know?" fact
        _buildLoadingIndicator(),        // Progress bar
      ],
    ),
  );
}
```

**What happens:**
- Watches `loadingScreenProvider` for content
- Provider automatically loads new content
- Displays: logo, image, greeting, fact, progress bar
- Progress bar animates from 0% to 100% over 3 seconds

#### **5. LoadingScreenProvider (`loading_screen_provider.dart`)**

**State Management:**
```dart
final loadingScreenProvider = 
    StateNotifierProvider<LoadingScreenNotifier, LoadingScreenContent>(...);

class LoadingScreenNotifier extends StateNotifier<LoadingScreenContent> {
  final SharedPreferences? _prefs;
  
  LoadingScreenNotifier() : super(LoadingScreenContentData.defaultContent.first) {
    _loadContent(); // Loads content immediately
  }
}
```

**Content Selection Logic:**
```dart
void _loadContent() {
  // 1. Get last shown content ID
  final lastId = _prefs?.getString('last_loading_content_id');
  
  // 2. Get list of recently viewed content IDs
  final viewedIds = _prefs?.getStringList('viewed_loading_content_ids') ?? [];
  
  // 3. Filter out recently viewed content
  var availableContent = LoadingScreenContentData.defaultContent
      .where((c) => c.id != lastId && !viewedIds.contains(c.id))
      .toList();
  
  // 4. If all content viewed, reset
  if (availableContent.isEmpty) {
    availableContent = LoadingScreenContentData.defaultContent;
    _prefs?.remove('viewed_loading_content_ids');
  }
  
  // 5. Randomly select from available content
  final random = Random();
  final selected = availableContent[random.nextInt(availableContent.length)];
  
  // 6. Update state (triggers UI rebuild)
  state = selected;
  
  // 7. Save to SharedPreferences
  _prefs?.setString('last_loading_content_id', selected.id);
  final updatedViewed = [...viewedIds, selected.id];
  if (updatedViewed.length > 5) {
    updatedViewed.removeAt(0); // Keep only last 5
  }
  _prefs?.setStringList('viewed_loading_content_ids', updatedViewed);
}
```

**Key Points:**
- Uses `SharedPreferences` for local storage (persists across app restarts)
- Tracks last 5 viewed content items to ensure variety
- Randomly selects from available (non-recent) content
- Updates Riverpod state, which triggers UI rebuild

#### **6. LoadingScreenContentData (`loading_screen_content.dart`)**

**Static Content Storage:**
```dart
class LoadingScreenContentData {
  static final List<LoadingScreenContent> defaultContent = [
    LoadingScreenContent(
      id: 'swahili_kenya_1',
      imageUrl: 'assets/images/loading/swahili_kenya_1.png',
      country: 'Kenya',
      countryFlag: '🇰🇪',
      greeting: 'Karibu!',
      greetingTranslation: 'Welcome!',
      language: 'Swahili',
      fact: 'Did you know? "Jambo" is a common Swahili greeting...',
    ),
    // ... 10+ more entries
  ];
}
```

**Current State:**
- All content is **hardcoded** in the Flutter app
- Images are **local assets** (not AI-generated yet)
- No backend API calls
- No database storage

---

## 🔄 **How Content Rotation Works**

### **First Launch:**
1. No `SharedPreferences` data exists
2. All 10+ content items are available
3. Randomly selects one (e.g., "swahili_kenya_1")
4. Saves to `SharedPreferences`:
   - `last_loading_content_id`: "swahili_kenya_1"
   - `viewed_loading_content_ids`: ["swahili_kenya_1"]

### **Second Launch:**
1. Reads `SharedPreferences`
2. Last shown: "swahili_kenya_1"
3. Available: All except "swahili_kenya_1" (9 items)
4. Randomly selects from 9 items (e.g., "yoruba_nigeria_1")
5. Updates `SharedPreferences`:
   - `last_loading_content_id`: "yoruba_nigeria_1"
   - `viewed_loading_content_ids`: ["swahili_kenya_1", "yoruba_nigeria_1"]

### **After 5 Launches:**
1. `viewed_loading_content_ids` has 5 items
2. Available: All except those 5 (5+ items remaining)
3. Continues rotating

### **After All Content Viewed:**
1. All 10+ items in `viewed_loading_content_ids`
2. `availableContent` is empty
3. **Resets**: Clears `viewed_loading_content_ids`
4. Starts fresh rotation

---

## 🤖 **AI Image Generation Pipeline (Future/Backend)**

### **Current State:**
- **Not Implemented** - Images are static assets
- Framework exists in `AIImageService` but not connected

### **How It Would Work (Backend Integration):**

#### **Option A: Client-Side Generation (Current Plan)**
```
App Launch
    ↓
Check if image exists locally
    ↓
If not: Call AIImageService.generatePersonImage()
    ↓
AIImageService calls Stability AI API
    ↓
Receives base64 image
    ↓
Save to local cache
    ↓
Display image
```

**Pros:**
- Simple implementation
- No backend needed
- Direct API calls

**Cons:**
- API keys exposed in app (security risk)
- Each device generates images independently (wasteful)
- No centralized image library

#### **Option B: Backend Proxy (Recommended for Production)**

**Flow:**
```
App Launch
    ↓
Call Backend: GET /api/loading-screen/content
    ↓
Backend checks database for content
    ↓
If image exists in CDN: Return URL
    ↓
If not: Backend calls Stability AI API
    ↓
Backend saves image to CDN/S3
    ↓
Backend saves URL to database
    ↓
Return content + image URL to app
    ↓
App displays content
```

**Backend Endpoints Needed:**
1. `GET /api/loading-screen/content` - Get random content
2. `POST /api/loading-screen/generate-image` - Generate new image (admin)
3. `GET /api/loading-screen/content/:id` - Get specific content

**Database Schema:**
```javascript
{
  _id: ObjectId,
  id: "swahili_kenya_1",
  country: "Kenya",
  language: "Swahili",
  greeting: "Karibu!",
  greetingTranslation: "Welcome!",
  fact: "Did you know? ...",
  imageUrl: "https://cdn.lingafriq.com/images/swahili_kenya_1.png",
  imageGeneratedAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🗄️ **Data Storage Layers**

### **1. Static Content (Current)**
- **Location**: `lib/models/loading_screen_content.dart`
- **Type**: Hardcoded Dart list
- **Size**: ~10-15 entries
- **Update**: Requires app update

### **2. Local Preferences (Current)**
- **Location**: `SharedPreferences` (device storage)
- **Data**: 
  - `last_loading_content_id`: String
  - `viewed_loading_content_ids`: List<String>
- **Purpose**: Track rotation to avoid repeats
- **Persistence**: Survives app restarts

### **3. Image Cache (Future)**
- **Location**: Device file system or `cached_network_image`
- **Data**: Downloaded/generated images
- **Purpose**: Avoid re-downloading images
- **Implementation**: `flutter_cache_manager` or `path_provider`

### **4. Backend Database (Future)**
- **Location**: MongoDB (via node-backend)
- **Data**: All content entries, image URLs, metadata
- **Purpose**: Centralized content management
- **Update**: Can update without app release

---

## 🔐 **API Key Management**

### **Current Implementation:**
```dart
// lib/services/ai_image_service.dart
static String? get _apiKey {
  const stabilityKey = String.fromEnvironment('STABILITY_AI_KEY', defaultValue: '');
  if (stabilityKey.isNotEmpty && stabilityKey != 'YOUR_STABILITY_AI_KEY') {
    return stabilityKey;
  }
  // ... try other providers
  return null;
}
```

### **How Keys Are Passed:**

#### **GitHub Actions (CI/CD):**
```yaml
# .github/workflows/build-and-release.yml
env:
  STABILITY_AI_KEY: ${{ secrets.STABILITY_AI_KEY }}
run: |
  flutter build appbundle --release \
    --dart-define=STABILITY_AI_KEY=$STABILITY_AI_KEY
```

#### **Local Development:**
```bash
# Windows PowerShell
$env:STABILITY_AI_KEY="sk-your-key-here"
flutter run

# Or directly
flutter run --dart-define=STABILITY_AI_KEY=sk-your-key-here
```

### **Security Considerations:**
- ⚠️ **Keys are embedded in app binary** (can be extracted via reverse engineering)
- ✅ **For production**: Use backend proxy (keys never leave server)
- ✅ **Key restrictions**: Set IP whitelist, rate limits in provider console

---

## 🎨 **Image Loading Flow**

### **Current (Static Assets):**
```
DynamicLoadingScreen.build()
    ↓
_buildPersonIllustration(content)
    ↓
content.imageUrl = 'assets/images/loading/swahili_kenya_1.png'
    ↓
Image.asset('assets/images/loading/swahili_kenya_1.png')
    ↓
Flutter loads from app bundle
    ↓
Displays image
```

### **Future (Network/CDN):**
```
DynamicLoadingScreen.build()
    ↓
_buildPersonIllustration(content)
    ↓
content.imageUrl = 'https://cdn.lingafriq.com/images/swahili_kenya_1.png'
    ↓
CachedNetworkImage(imageUrl)
    ↓
Check local cache
    ↓
If cached: Display from cache
    ↓
If not: Download from CDN → Cache → Display
```

### **Future (AI Generated):**
```
DynamicLoadingScreen.build()
    ↓
Check if image exists locally
    ↓
If not: AIImageService.generatePersonImage()
    ↓
Call Stability AI API (or backend proxy)
    ↓
Receive base64 image
    ↓
Convert to File, save locally
    ↓
Display image
```

---

## ⚡ **Performance Optimizations**

### **Current:**
1. **Static Assets**: Fast, no network calls
2. **SharedPreferences**: In-memory after first read
3. **Riverpod**: Efficient state management, minimal rebuilds

### **Future Optimizations:**
1. **Image Preloading**: Load next content's image in background
2. **CDN Caching**: Fast image delivery
3. **Database Indexing**: Quick content queries
4. **Batch Generation**: Generate all images once, store in CDN

---

## 🔧 **Backend Integration (To Be Implemented)**

### **What's Missing:**
1. ❌ No backend endpoint for loading screen content
2. ❌ No database model for loading screen content
3. ❌ No image generation service on backend
4. ❌ No CDN integration

### **What Needs to Be Added:**

#### **1. Database Model** (`src/models/loadingScreenContent.model.ts`)
```typescript
interface ILoadingScreenContent {
  id: string;
  country: string;
  countryFlag: string;
  greeting: string;
  greetingTranslation: string;
  language: string;
  fact: string;
  imageUrl?: string;
  imageGeneratedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
```

#### **2. API Endpoint** (`src/routes/loadingScreen.route.ts`)
```typescript
GET /api/loading-screen/content
  - Returns random content (excluding recently viewed)
  - Tracks viewed content per user
  
POST /api/loading-screen/generate-image (admin)
  - Generates new AI image
  - Saves to CDN
  - Updates database
```

#### **3. Service** (`src/services/loadingScreen.service.ts`)
```typescript
- getRandomContent(userId: string): Promise<LoadingScreenContent>
- generateImage(country: string, language: string): Promise<string>
- uploadToCDN(imageBuffer: Buffer): Promise<string>
```

---

## 📊 **Complete Flow Diagram (Future with Backend)**

```
App Launch
    ↓
SplashScreen
    ↓
DynamicLoadingScreen
    ↓
LoadingScreenProvider.refreshContent()
    ↓
API Call: GET /api/loading-screen/content
    ↓
Backend: Query MongoDB
    ↓
Backend: Check user's viewed content (from user model)
    ↓
Backend: Select random content (excluding viewed)
    ↓
Backend: Check if image exists in CDN
    ↓
If not: Generate via Stability AI API
    ↓
Backend: Upload to CDN (S3/Cloudinary)
    ↓
Backend: Save URL to database
    ↓
Backend: Return content + imageUrl
    ↓
App: Cache content locally
    ↓
App: Load image from CDN (cached_network_image)
    ↓
App: Display loading screen
    ↓
After 3 seconds: Navigate to app
```

---

## 🎯 **Summary**

### **Current State:**
- ✅ **Client-side only**: All content in Flutter app
- ✅ **Local rotation**: SharedPreferences tracks viewed content
- ✅ **Static images**: Local assets, no AI generation
- ✅ **No backend**: No API calls, no database

### **Future State (Recommended):**
- 🔄 **Backend integration**: Content in MongoDB
- 🔄 **CDN images**: Images hosted on CDN
- 🔄 **AI generation**: Backend generates images (keeps keys secure)
- 🔄 **User tracking**: Track viewed content per user
- 🔄 **Admin panel**: Manage content via admin interface

### **Next Steps:**
1. Add backend endpoints (see implementation below)
2. Create database model
3. Set up CDN (S3/Cloudinary)
4. Implement image generation service
5. Update Flutter app to call backend API
6. Migrate static content to database

---

## 🔗 **Related Files**

- **Flutter**: `lib/screens/loading/dynamic_loading_screen.dart`
- **Provider**: `lib/providers/loading_screen_provider.dart`
- **Model**: `lib/models/loading_screen_content.dart`
- **Service**: `lib/services/ai_image_service.dart`
- **Splash**: `lib/screens/splash/splash_screen.dart`

