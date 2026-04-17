# LingAfriq — Snapchat-Style UI Design Spec (Flutter)
# Paste into Cursor AI alongside the Snapchat build prompt.
# Design size: 428 × 926 (flutter_screenutil baseline)

---

## 1. BRAND & COLOUR SYSTEM

```dart
// lib/styles/snap_colors.dart
class SnapColors {
  // Snapchat uses yellow as primary — LingAfriq adapts to its orange/green
  // but Snap UI chrome stays predominantly black/dark

  // Core surfaces
  static const scaffoldBg        = Color(0xFF000000); // camera screen = pure black
  static const surfaceDark       = Color(0xFF111111);
  static const surfaceCard       = Color(0xFF1C1C1E);
  static const surfaceCardLight  = Color(0xFFF2F2F7);

  // Primary accent (LingAfriq brand, replaces Snap yellow)
  static const accent            = Color(0xFFE05C2A); // LingAfriq orange
  static const accentLight       = Color(0xFFFFF3EE);
  static const accentGreen       = Color(0xFF16A34A); // LingAfriq green

  // Story ring gradients
  static const storyRingA        = Color(0xFFE05C2A);
  static const storyRingB        = Color(0xFFF59E0B);
  static const storyRingSeen     = Color(0xFF6B7280);

  // Snap inbox state colours
  static const snapNew           = Color(0xFFE05C2A); // unopened snap
  static const snapOpened        = Color(0xFF9CA3AF); // opened
  static const snapDelivered     = Color(0xFF6B7280); // delivered not opened
  static const snapScreenshot    = Color(0xFFF59E0B); // screenshot taken

  // Streak colours
  static const streakFire        = Color(0xFFFF6B00);
  static const streakHourglass   = Color(0xFFF59E0B);
  static const streakBg          = Color(0xFFFFF7ED);
  static const streakBgDark      = Color(0xFF2D1E12);

  // Overlay & capture chrome
  static const captureButton     = Color(0xFFFFFFFF);
  static const captureRing       = Color(0xFFFFFFFF);
  static const overlayText       = Color(0xFFFFFFFF);
  static const overlayBg         = Color(0x99000000);

  // Language overlay card
  static const langCard          = Color(0xCC000000);
  static const langCardBorder    = Color(0xFFE05C2A);
  static const langNativeText    = Color(0xFFFFFFFF);
  static const langPronText      = Color(0xFFD1D5DB);
  static const langTransText     = Color(0xFF9CA3AF);

  // Sticker picker
  static const stickerBg        = Color(0xFF1C1C1E);
  static const stickerSelected  = Color(0xFFE05C2A);

  // Story viewer chrome
  static const progressTrack    = Color(0x4DFFFFFF); // 30% white
  static const progressFill     = Color(0xFFFFFFFF);
  static const viewerChrome     = Color(0x80000000);

  // Bottom nav (Snapchat-style icon nav)
  static const navBg            = Color(0xFF000000);
  static const navActive        = Color(0xFFFFFFFF);
  static const navInactive      = Color(0x80FFFFFF);

  // Inbox list
  static const inboxBg          = Color(0xFF000000);
  static const inboxItem        = Color(0xFF1C1C1E);
  static const inboxText        = Color(0xFFFFFFFF);
  static const inboxSubtext     = Color(0xFF9CA3AF);
}
```

---

## 2. TYPOGRAPHY

```dart
// lib/styles/snap_typography.dart
// All fonts use existing Dosis family from pubspec.yaml
class SnapTypography {
  // Snap inbox friend name
  static TextStyle friendName(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: SnapColors.inboxText,
  );

  // Snap status sub-label (e.g. "New Snap • 2h")
  static TextStyle snapStatus(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: SnapColors.snapNew,
  );

  // Opened/delivered status sub-label
  static TextStyle snapStatusMuted(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: SnapColors.inboxSubtext,
  );

  // Story viewer name
  static TextStyle storyName(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 13.sp,
    fontWeight: FontWeight.w700,
    color: SnapColors.overlayText,
  );

  // Story viewer time
  static TextStyle storyTime(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: SnapColors.overlayText.withOpacity(0.7),
  );

  // Language phrase overlay — native word (large)
  static TextStyle nativePhrase(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 26.sp,
    fontWeight: FontWeight.w800,
    color: SnapColors.langNativeText,
    letterSpacing: 0.2,
  );

  // Language overlay pronunciation
  static TextStyle pronunciation(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: SnapColors.langPronText,
  );

  // Language overlay translation
  static TextStyle translation(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: SnapColors.langTransText,
  );

  // Streak count number
  static TextStyle streakCount(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 20.sp,
    fontWeight: FontWeight.w800,
    color: SnapColors.streakFire,
  );

  // Caption overlay text on snap
  static TextStyle captionText(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
  );

  // Screen section header
  static TextStyle sectionHeader(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: SnapColors.inboxSubtext,
  );

  // App bar title
  static TextStyle appBarTitle(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 20.sp,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );
}
```

---

## 3. SPACING & RADIUS

```dart
class SnapSpacing {
  static double get xxs  => 2.h;
  static double get xs   => 4.h;
  static double get sm   => 8.h;
  static double get md   => 12.h;
  static double get lg   => 16.h;
  static double get xl   => 24.h;
  static double get xxl  => 32.h;
}

class SnapRadius {
  // Snap media preview tile
  static BorderRadius snapTile    = BorderRadius.circular(14.r);
  // Story ring
  static BorderRadius storyRing   = BorderRadius.circular(40.r);
  // Capture button outer ring
  static BorderRadius captureRing = BorderRadius.circular(40.r);
  // Bottom sheet modals
  static BorderRadius sheet       = BorderRadius.vertical(top: Radius.circular(20.r));
  // Badge chips
  static BorderRadius pill        = BorderRadius.circular(24.r);
  // Sticker/tool button
  static BorderRadius toolBtn     = BorderRadius.circular(12.r);
  // Language overlay card
  static BorderRadius langCard    = BorderRadius.circular(16.r);
  // Streak badge
  static BorderRadius streakBadge = BorderRadius.circular(20.r);
}
```

---

## 4. SHADOWS

```dart
class SnapShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> captureButton = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  static List<BoxShadow> storyRing = [
    BoxShadow(
      color: SnapColors.accent.withOpacity(0.4),
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];
}
```

---

## 5. SCREEN-BY-SCREEN LAYOUT SPECS

### 5.1 SnapCameraScreen (entry point — camera first)

```
Scaffold backgroundColor: Color(0xFF000000)
Body: Stack [

  // Full-screen camera preview
  CameraPreview(controller) → full 428.w × 926.h fill
  Fallback if camera unavailable:
    Container(color: black, Center(Icon(camera_alt, grey, 80.sp)))

  // TOP chrome (above camera)
  Positioned(top: 0, left: 0, right: 0):
    SafeArea child: Padding(horizontal: 16.w, vertical: 8.h)
    Row [
      IconButton(close_rounded, white, 28.sp) → pop
      Spacer
      Column center-aligned [
        IconButton(bolt, white, 26.sp)       → flash toggle (bolt_off if off)
        SizedBox(16.h)
        IconButton(timer_outlined, white, 26.sp) → timer selector
        SizedBox(16.h)
        IconButton(auto_fix_high, white, 26.sp)  → filter toggle
        SizedBox(16.h)
        IconButton(music_note_outlined, white, 26.sp) → sound
      ]
    ]

  // BOTTOM chrome (shutter row)
  Positioned(bottom: 0, left: 0, right: 0):
    SafeArea child:
    Container(
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h)
      child: Row(mainAxisAlignment: spaceBetween) [

        // Gallery thumbnail
        GestureDetector(onTap: pickFromGallery,
          Container(
            width: 52.w, height: 52.w
            border-radius: SnapRadius.snapTile
            child: Image.asset(lastGalleryThumb, fit: BoxFit.cover)
                   or Icon(photo_library_outlined, white, 28.sp)
          )
        )

        // Shutter — MAIN CAPTURE BUTTON
        GestureDetector(
          onTap: → capturePhoto
          onLongPressStart: → startVideoRecord (ring animates to red)
          onLongPressEnd:   → stopVideoRecord → go to preview
          child: Stack [
            Container(
              width: 76.w, height: 76.w
              decoration: BoxDecoration(
                shape: BoxShape.circle
                color: Colors.white.withOpacity(0.2)   // outer ring
              )
            )
            Positioned center:
              Container(
                width: 62.w, height: 62.w
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white
                )
              )
            // Recording progress ring (animated):
            if isRecording:
              SizedBox(76.w, 76.w,
                CircularProgressIndicator(
                  value: recordProgress,   // 0.0 → 1.0
                  color: Colors.red,
                  strokeWidth: 5,
                  backgroundColor: Colors.transparent
                )
              )
          ]
        )

        // Flip camera
        GestureDetector(onTap: flipCamera,
          Container(
            width: 52.w, height: 52.w
            decoration: BoxDecoration(
              shape: BoxShape.circle
              color: Colors.black.withOpacity(0.35)
            )
            child: Icon(flip_camera_ios_outlined, white, 26.sp)
          )
        )

      ]
    )

  // Friends shortcut row (above shutter row)
  Positioned(bottom: 104.h, left: 0, right: 0):
    SizedBox(height: 52.h)
    ListView.builder horizontal, itemCount: top5Friends
    Each item: Column [
      CircleAvatar 38.r (friend avatar)
      SizedBox(3.h)
      Text(firstName, 10.sp, white, maxLines:1, overflow: ellipsis)
    ]
    padding horizontal 16.w, spacing 12.w

]

Bottom nav bar (persistent across snap screens):
  height: 60.h + bottom safe area
  color: SnapColors.navBg
  Row(mainAxisAlignment: spaceEvenly) [
    _NavItem(icon: chat_bubble_outline,   label: "Chat",    active: false)
    _NavItem(icon: camera_alt,            label: "",        active: true)  ← center, larger 32.sp
    _NavItem(icon: auto_stories,          label: "Stories", active: false)
    _NavItem(icon: explore_outlined,      label: "Discover",active: false)
  ]
  Each _NavItem:
    Column [
      Icon(icon, active? navActive : navInactive, 24.sp)
      if label.isNotEmpty: Text(label, 9.sp, active? navActive : navInactive)
    ]
    if active (camera): no label, icon 32.sp
```

### 5.2 SnapPreviewScreen (after capture)

```
Scaffold backgroundColor: black
Stack [

  // Full-screen snap preview
  if isPhoto: Image.memory(imageBytes, fit: BoxFit.cover, width: 428.w, height: 926.h)
  if isVideo: VideoPlayer(controller) loop: true

  // RIGHT toolbar
  Positioned(top: 100.h, right: 12.w):
    Column spacing 20.h [
      _SnapTool(icon: text_fields,    label: "Text")    → enable text overlay
      _SnapTool(icon: emoji_emotions, label: "Sticker") → open sticker picker sheet
      _SnapTool(icon: crop_square,    label: "Crop")
      _SnapTool(icon: language,       label: "Language") → toggle lang overlay
      _SnapTool(icon: draw,           label: "Draw")    → toggle draw mode
    ]
  Each _SnapTool:
    Column [
      Container(
        width: 44.w, height: 44.h
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle)
        child: Icon(icon, white, 22.sp)
      )
      Text(label, 9.sp, white)
    ]

  // TOP row
  Positioned(top: 40.h, left: 0, right: 0):
    Row [
      IconButton(close, white, 28.sp) → pop (discard)
      Spacer
      IconButton(download_outlined, white, 26.sp) → save to device
      SizedBox(8.w)
      IconButton(create, white, 26.sp) → enter draw mode
    ]
    padding horizontal 16.w

  // Language overlay (shown when langOverlayEnabled):
  Positioned(bottom: 160.h, left: 16.w, right: 16.w):
    Container(
      decoration: BoxDecoration(
        color: SnapColors.langCard,
        borderRadius: SnapRadius.langCard,
        border: Border.all(color: SnapColors.langCardBorder, width: 1.5)
      )
      padding: EdgeInsets.all(14.h)
      child: Column crossAxisAlignment.start [
        Row [
          Container(
            padding: 3.h × 8.w
            decoration: BoxDecoration(color: accent, borderRadius: pill)
            child: Text(languageCode.toUpperCase(), 10.sp, white, w700)
          )
          Spacer
          IconButton(close, white, 16.sp) → hide overlay
        ]
        SizedBox(6.h)
        Text(nativeText,     style: SnapTypography.nativePhrase)
        Text("/pronunciation/", style: SnapTypography.pronunciation)
        SizedBox(4.h)
        Text(translation,    style: SnapTypography.translation)
      ]
    )

  // Caption text overlay (if user typed caption):
  Positioned(bottom: 120.h, left: 0, right: 0):
    Center(
      child: Container(
        padding: 8.h × 16.w
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          borderRadius: pill
        )
        child: TextField(
          style: SnapTypography.captionText,
          textAlign: TextAlign.center,
          decoration: no-border,
          hint: "Add a caption…"
        )
      )
    )

  // SEND bar (bottom)
  Positioned(bottom: 0, left: 0, right: 0):
    SafeArea child:
    Container(
      height: 72.h
      padding horizontal 16.w
      color: Colors.black.withOpacity(0.6)
      child: Row [
        // Duration chip (photos)
        if !isVideo:
          Container(
            padding: 6.h × 12.w, color: Colors.black38, borderRadius: pill
            child: Row [Icon(timer, white, 14.sp), SizedBox(4.w), Text("5s", 12.sp, white)]
          )
        Spacer
        // Send-to button
        GestureDetector(onTap: showSendToSheet,
          Container(
            padding: 10.h × 24.w
            decoration: BoxDecoration(
              color: SnapColors.accent,
              borderRadius: SnapRadius.pill
            )
            child: Row [
              Text("Send To", 16.sp, white, w700)
              SizedBox(6.w)
              Icon(arrow_forward_ios, white, 14.sp)
            ]
          )
        )
      ]
    )
]
```

### 5.3 SnapSendToSheet (BottomSheet from preview)

```
ModalBottomSheet:
  borderRadius: SnapRadius.sheet
  background: SnapColors.surfaceDark
  minChildSize: 0.6, maxChildSize: 0.95

  Header:
    Drag handle 4.h × 40.w, grey, rounded, centered top
    SizedBox(12.h)
    Text("Send To", SnapTypography.appBarTitle, center)
    SizedBox(12.h)

  "My Story" row (always first):
    ListTile(
      leading: Container(
        width: 46.r, height: 46.r
        decoration: BoxDecoration(
          gradient: LinearGradient(SnapColors.storyRingA, SnapColors.storyRingB)
          shape: BoxShape.circle
        )
        child: Icon(auto_stories, white, 24.sp)
      )
      title: Text("My Story", 15.sp, white, w600)
      subtitle: Text("Friends · 24h", 12.sp, grey)
      trailing: _SelectCircle(selected: myStorySelected)
    )

  Divider grey 0.5px
  Padding(8.h) Text("FRIENDS", SnapTypography.sectionHeader)

  Friend list (lazy ListView):
    Each item ListTile:
      leading: CircleAvatar 46.r
      title: Text(friendName, 15.sp, white, w600)
      trailing: _SelectCircle(selected: friendSelected[id])
      onTap: toggle selected

  _SelectCircle widget:
    if selected:
      Container 26.r circle, accent color, Icon(check, white, 14.sp)
    else:
      Container 26.r circle, border 2px grey, no child

  Bottom send button:
    Container height 54.h, accent color, borderRadius.only(top 0, bottom SnapRadius.pill equivalent)
    Center Text("Send", 17.sp, white, w700)
    Disabled (grey) if nothing selected
```

### 5.4 SnapInboxScreen (Chat/Inbox tab)

```
Scaffold backgroundColor: SnapColors.inboxBg

AppBar:
  transparent, elevation 0
  Row [
    IconButton(search, white, 24.sp)
    Spacer
    Text("LingaFriq", SnapTypography.appBarTitle)
    Spacer
    IconButton(person_add_outlined, white, 24.sp) → add friend
  ]
  padding horizontal 16.w

Body: Column [

  // Story row (horizontal scroll, top of inbox)
  Container(height: 100.h):
    Row [
      // My story add item (always leftmost)
      Column [
        Stack [
          CircleAvatar 58.r (own avatar)
          Positioned(bottom:0, right:0):
            Container(
              width: 22.r, height: 22.r
              color: accent, shape: circle
              child: Icon(add, white, 14.sp)
            )
        ]
        SizedBox(4.h)
        Text("My Story", 10.sp, white)
      ]
      // Friend stories (horizontal scroll)
      ListView.builder horizontal:
        Each friend with story: Column [
          _SnapStoryRing(child: CircleAvatar 58.r, seen: bool)
          SizedBox(4.h)
          Text(firstName, 10.sp, white, maxLines:1, overflow: ellipsis, width: 62.w)
        ]
        spacing: 12.w
    ]
    padding horizontal 16.w

  Divider 0.5px grey

  // Friend list
  Expanded:
    ListView.builder:
      Each SnapInboxTile [height 72.h]:
        Row [
          Stack [
            CircleAvatar 52.r
            _SnapStateIndicator(state: snapState)
              // small icon bottom-right of avatar:
              // new snap: orange filled square 14.r
              // opened:   grey outlined square 14.r
              // screenshot: yellow triangle 14.r
              // delivered: purple outlined square 14.r
          ]
          SizedBox(12.w)
          Expanded Column cross.start [
            Text(friendName, SnapTypography.friendName)
            SizedBox(2.h)
            Text(statusLabel, style based on state:
              new → SnapTypography.snapStatus (orange bold)
              opened → SnapTypography.snapStatusMuted (grey)
            )
          ]
          Column cross.end [
            if hasStreak: _StreakChip(count: streakCount)
            SizedBox(4.h)
            Text(relativeTime, 11.sp, grey)
          ]
        ]
        padding: EdgeInsets.symmetric(horizontal:16.w, vertical:10.h)

  // _StreakChip widget:
  Container(
    padding: 4.h × 8.w
    decoration: BoxDecoration(
      color: SnapColors.streakBg, borderRadius: SnapRadius.streakBadge
    )
    child: Row [
      Text("🔥", 13.sp)
      SizedBox(3.w)
      Text(count.toString(), SnapTypography.streakCount → 14.sp here)
    ]
  )
]
```

### 5.5 SnapViewScreen (viewing a snap)

```
Scaffold backgroundColor: black
WillPopScope(onWillPop: preventAccidentalBack)

Stack [

  // Full-screen media
  if mediaType == image:
    Image.network(url, fit: BoxFit.cover, width: 428.w, height: 926.h)
    // After media loaded: start 5-second timer → auto-close after view
  if mediaType == video:
    VideoPlayer + auto-play, once video ends → auto-close

  // TOP bar (minimal)
  Positioned(top: 0, left: 0, right: 0):
    SafeArea child:
    Padding(horizontal: 16.w, vertical: 8.h)
    Row [
      GestureDetector(onTap: pop,
        Icon(close, white, 26.sp)
      )
      Spacer
      if canReplay: GestureDetector(onTap: replay,
        Container(
          padding: 6.h × 12.w
          color: Colors.black38, borderRadius: pill
          child: Row [Icon(replay, white, 16.sp), SizedBox(4.w), Text("Replay", 12.sp, white)]
        )
      )
    ]

  // Sender info
  Positioned(top: 54.h, left: 16.w):
    Row [
      CircleAvatar 36.r (sender)
      SizedBox(8.w)
      Column crossAxisAlignment.start [
        Text(senderName, 14.sp, white, w700)
        Text(relativeTime, 11.sp, white.withOpacity(0.7))
      ]
    ]

  // Caption (if exists, overlay at bottom)
  if snap.caption.isNotEmpty:
    Positioned(bottom: 80.h, left: 0, right: 0):
    Container(
      padding: 12.h × 20.w
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter
        )
      )
      child: Text(snap.caption, SnapTypography.captionText, textAlign: center)
    )

  // BOTTOM action row
  Positioned(bottom: 0, left: 0, right: 0):
    SafeArea child:
    Container(
      color: Colors.black.withOpacity(0.4)
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h)
      child: Row [
        Expanded(
          TextField(
            style: white 14.sp
            hintText: "Reply…"
            hintStyle: grey 14.sp
            decoration: OutlineInputBorder(rounded 24.r, white.withOpacity(0.4))
          )
        )
        SizedBox(8.w)
        IconButton(favorite_border, white, 24.sp) → react
        IconButton(send, white, 24.sp)            → send reply
      ]
    )
]

Screenshot detection handling:
  AppLifecycleListener listening for inactive→paused transition:
    → call POST /api/snap/messages/:id/screenshot
    → show own overlay banner: Container height 36.h, yellow bg
      Center Text("📸  Screenshot taken", black, 13.sp, w600)
      Auto-dismiss after 2s
```

### 5.6 SnapStoryFeedScreen (Stories tab)

```
Scaffold backgroundColor: SnapColors.surfaceCard (light: surfaceCardLight)

AppBar:
  Text("Stories") dosis 20.sp w800
  actions: [IconButton(settings_outlined, 22.sp)]
  background transparent

Body: CustomScrollView slivers [

  // "My Story" header card
  SliverToBoxAdapter:
    Container(
      margin: EdgeInsets.all(16.h)
      decoration: BoxDecoration(color: surfaceDark, borderRadius: SnapRadius.snapTile)
      padding: EdgeInsets.all(14.h)
      child: Row [
        Stack [
          CircleAvatar 50.r
          Positioned(bottom:0, right:0):
            Container 20.r circle accent Icon(add, white, 12.sp)
        ]
        SizedBox(12.w)
        Column crossAxisAlignment.start [
          Text("My Story", 15.sp, white, w700)
          SizedBox(2.h)
          Text("Tap to add a snap", 12.sp, grey)
        ]
        Spacer
        TextButton("Add") → navigate to snap-camera
      ]
    )

  // Section: "Friends' Stories"
  SliverPadding(padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 0)):
    SliverList builder:
      Each story group (one per user with unseen stories):
        GestureDetector(onTap: → navigate to snap-story-viewer with user stories)
        Container(
          margin: EdgeInsets.only(bottom: 8.h)
          padding: EdgeInsets.all(12.h)
          decoration: BoxDecoration(color: surfaceDark, borderRadius: SnapRadius.snapTile)
          child: Row [
            _SnapStoryRing(
              child: CircleAvatar 52.r
              seen: allStoriesSeen
              gradient colors: [storyRingA, storyRingB]
              seenColor: storyRingSeen
              ringThickness: 3.w
              gap: 4.w
            )
            SizedBox(14.w)
            Expanded Column cross.start [
              Text(displayName, 15.sp, white, w700)
              SizedBox(3.h)
              Text(latestStoryTime, 12.sp, grey)
            ]
            if !allStoriesSeen:
              Container(
                width: 10.r, height: 10.r
                color: accent, shape: BoxShape.circle
              )
          ]
        )

  // Section: "Discover / Spotlight" (LingAfriq: language content)
  SliverPadding padding 16.w:
    SliverToBoxAdapter:
      Text("Language Spotlight", SnapTypography.sectionHeader)
      SizedBox(8.h)
    SliverGrid(
      delegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.65
      )
      each cell: _SpotlightTile(story) [
        Stack [
          ClipRRect(borderRadius: SnapRadius.snapTile)
            Image.network(thumbnailUrl, fit: BoxFit.cover)
          // Gradient overlay bottom
          Positioned fill:
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                  begin: Alignment.center, end: Alignment.bottomCenter
                ),
                borderRadius: SnapRadius.snapTile
              )
            )
          // Language badge top-left
          Positioned(top: 8.h, left: 8.w):
            Container(
              padding: 3.h × 7.w
              color: accent, borderRadius: pill
              child: Text(languageCode, 9.sp, white, w700)
            )
          // Text bottom
          Positioned(bottom: 10.h, left: 8.w, right: 8.w):
            Text(story.caption, 13.sp, white, w700, maxLines: 2)
        ]
      ]
    )
]
```

### 5.7 SnapStoryViewerScreen (full-screen viewer)

```
Scaffold backgroundColor: black

Stack [

  // Story content (full screen)
  PageView.builder(
    scrollDirection: Axis.horizontal, physics: NeverScrollableScrollPhysics
    (navigation via tap gestures below)
    each page:
      if type == image: Image.network(mediaUrl, fit: BoxFit.cover, width: 428.w, height: 926.h)
      if type == video: VideoPlayer full screen
      if type == text:
        Container(
          width: 428.w, height: 926.h,
          color: story.backgroundColor ?? SnapColors.accent
          Center Padding(24.w):
            Text(textContent, style: SnapTypography.nativePhrase, textAlign: center)
        )
  )

  // PROGRESS BARS (top)
  SafeArea child:
  Padding(horizontal: 8.w, top: 8.h):
    Row spacing 3.w [
      for each storyItem i:
        Expanded Container(height: 2.5.h, color: progressTrack, borderRadius: pill
          child: FractionallySizedBox(
            widthFactor: i < current ? 1.0 : i == current ? _animProgress : 0.0
            child: Container(color: progressFill)
          )
        )
    ]

  // HEADER (below progress bars)
  Positioned(top: 30.h, left: 0, right: 0):
    SafeArea child: Padding(horizontal: 12.w, vertical: 8.h):
    Row [
      CircleAvatar 38.r (story author)
      SizedBox(10.w)
      Column crossAxisAlignment.start [
        Text(authorName, SnapTypography.storyName)
        Text(storyTime, SnapTypography.storyTime)
      ]
      Spacer
      IconButton(more_horiz, white, 22.sp) → mute/report sheet
      IconButton(close, white, 24.sp)      → pop
    ]

  // GESTURE LAYER (tap prev/next, hold pause)
  Positioned.fill:
    GestureDetector(
      onTapUp: (d) {
        if d.localPosition.dx < 428.w * 0.35 → goPrevious()
        else                                  → goNext()
      }
      onLongPressStart: (_) → pauseAnimation()
      onLongPressEnd:   (_) → resumeAnimation()
    )

  // CAPTION bar (bottom of media)
  if story.caption.isNotEmpty:
    Positioned(bottom: 80.h, left: 0, right: 0):
      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withOpacity(0.65)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter
          )
        )
        padding: 12.h × 16.w
        child: Text(story.caption, SnapTypography.captionText)
      )

  // LANGUAGE OVERLAY (if story has phrase overlay)
  if story.hasLanguageOverlay:
    Positioned(bottom: 80.h, left: 16.w, right: 16.w):
      Container(
        decoration: BoxDecoration(
          color: SnapColors.langCard,
          borderRadius: SnapRadius.langCard,
          border: Border.all(color: SnapColors.langCardBorder, width: 1.5)
          boxShadow: SnapShadows.card
        )
        padding: EdgeInsets.all(14.h)
        child: Column cross.start [
          Row [
            Container pill accent Text(languageCode, 9.sp, white, w700)
            Spacer
            IconButton(volume_up, white, 16.sp) → TTS play
          ]
          SizedBox(8.h)
          Text(nativeText, SnapTypography.nativePhrase)
          Text(pronunciation, SnapTypography.pronunciation)
          SizedBox(4.h)
          Text(translation, SnapTypography.translation)
          SizedBox(8.h)
          Row [
            TextButton("Save word") → save to vocab  (accent color, dosis 12.sp)
            Spacer
            TextButton("Practice") → pronunciation screen
          ]
        ]
      )

  // REPLY BAR (bottom)
  Positioned(bottom: 0, left: 0, right: 0):
    SafeArea child:
    Container(
      color: Colors.black.withOpacity(0.3)
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h)
      child: Row [
        Expanded:
          TextField(
            style: white 14.sp
            decoration: InputDecoration(
              hintText: "Reply to story…"
              hintStyle: white.withOpacity(0.5) 14.sp
              border: OutlineInputBorder(rounded 24.r, white.withOpacity(0.35))
              contentPadding: 10.h × 16.w
            )
            onFocus: pauseAnimation()
            onUnfocus: resumeAnimation()
          )
        SizedBox(8.w)
        IconButton(favorite_border, white, 24.sp)
        IconButton(send_rounded, accent, 24.sp)
      ]
    )

  // Viewer count (own stories only)
  if isOwnStory:
    Positioned(bottom: 66.h, right: 16.w):
      GestureDetector(onTap: showViewersList,
        Row [
          Icon(remove_red_eye_outlined, white, 16.sp)
          SizedBox(4.w)
          Text(viewerCount.toString(), 12.sp, white)
        ]
      )
]
```

### 5.8 SnapStreaksScreen

```
Scaffold backgroundColor: black

AppBar:
  Text("Streaks 🔥") SnapTypography.appBarTitle
  leading: back arrow white

Body: Column [

  // Info banner at top
  Container(
    margin: EdgeInsets.all(16.h)
    padding: EdgeInsets.all(14.h)
    decoration: BoxDecoration(
      color: SnapColors.streakBg (dark: streakBgDark),
      borderRadius: SnapRadius.snapTile
    )
    child: Row [
      Text("🔥", 28.sp)
      SizedBox(12.w)
      Expanded Column crossAxisAlignment.start [
        Text("Keep your streaks!", 15.sp, w700)
        SizedBox(4.h)
        Text("Send a snap or story to friends every day to keep streaks alive.",
             12.sp, grey, maxLines: 2)
      ]
    ]
  )

  // Active streaks list
  Expanded ListView.builder padding 16.h:
    Each streak item:
      Container(
        margin bottom 8.h
        padding: 14.h × 16.w
        decoration: BoxDecoration(
          color: surfaceDark, borderRadius: SnapRadius.snapTile
        )
        child: Row [
          CircleAvatar 48.r (friend)
          SizedBox(12.w)
          Expanded Column crossAxisAlignment.start [
            Text(friendName, 15.sp, white, w700)
            SizedBox(4.h)
            Row [
              if isWarning: Text("⏳", 13.sp) else Text("🔥", 13.sp)
              SizedBox(4.w)
              Text(
                isWarning ? "Expiring soon!" : "${streakDays} day streak",
                12.sp,
                isWarning ? streakHourglass : streakFire,
                w600
              )
            ]
            SizedBox(2.h)
            Text("Last exchanged: ${relativeTime}", 11.sp, grey)
          ]
          // Quick send button
          GestureDetector(
            onTap: → navigate to camera with friend pre-selected
            Container(
              width: 44.w, height: 44.h
              decoration: BoxDecoration(
                color: accent, borderRadius: SnapRadius.snapTile
              )
              child: Icon(camera_alt, white, 22.sp)
            )
          )
        ]
      )
]
```

### 5.9 SnapStickersSheet (bottom sheet)

```
DraggableScrollableSheet
  initialChildSize: 0.5, minChildSize: 0.35, maxChildSize: 0.9
  background: surfaceDark, borderRadius: SnapRadius.sheet

Column [
  // Drag handle
  Center Container(4.h × 40.w, grey, pill, margin top 8.h)
  SizedBox(12.h)

  // Search
  Padding(horizontal: 12.w)
  TextField(
    hintText: "Search stickers…"
    style white, decoration rounded 24.r
    prefix: Icon(search, grey)
  )
  SizedBox(8.h)

  // Category pills (horizontal scroll)
  SizedBox height 36.h:
    ListView horizontal [
      for each category: GestureDetector(
        onTap: selectCategory,
        Container(
          padding: 6.h × 14.w
          decoration: BoxDecoration(
            color: isSelected ? accent : surfaceCard,
            borderRadius: pill
          )
          child: Text(category, 12.sp, white, w600)
        )
      )
    ]
  SizedBox(8.h)

  // Sticker grid
  Expanded GridView.builder:
    crossAxisCount: 4, spacing: 6
    each sticker:
      GestureDetector(
        onTap: → selectSticker(sticker) → close sheet
        Container(
          decoration: BoxDecoration(
            color: isSelected ? accent.withOpacity(0.2) : transparent
            borderRadius: SnapRadius.toolBtn
          )
          padding: 8.h
          child: if sticker.type == emoji:
                   Text(sticker.emoji, 28.sp, textAlign: center)
                 else:
                   Image.network(sticker.url, 48.sp, fit: BoxFit.contain)
        )
      )
]
```

---

## 6. ANIMATIONS (flutter_animate)

```dart
// Camera shutter press feedback:
shutterInner.animate(trigger: onCapturePress)
  .scaleXY(begin: 1.0, end: 0.88, duration: 80.ms, curve: Curves.easeIn)
  .then()
  .scaleXY(begin: 0.88, end: 1.0, duration: 100.ms, curve: Curves.elasticOut)

// Preview screen appear:
previewImage.animate()
  .fadeIn(duration: 200.ms)
  .scaleXY(begin: const Offset(1.06, 1.06), end: Offset(1,1), duration: 200.ms, curve: Curves.easeOut)

// Snap inbox item enter:
inboxTile.animate(delay: (index * 40).ms)
  .fadeIn(duration: 180.ms)
  .slideX(begin: -0.08, duration: 180.ms, curve: Curves.easeOut)

// Story ring pulse (unseen):
storyRing.animate(onPlay: (c) => c.repeat(reverse: true))
  .scaleXY(begin: 1.0, end: 1.05, duration: 900.ms, curve: Curves.easeInOut)

// Story progress bar fill:
// Use AnimationController → Tween<double>(0,1) → width fraction
// duration = storyDurationMs (photo: 5000, video: actual)
// curve: Curves.linear

// Streak fire bounce (warning state):
streakIcon.animate(onPlay: (c) => c.repeat())
  .moveY(begin: 0, end: -4, duration: 400.ms, curve: Curves.easeInOut)
  .then().moveY(begin: -4, end: 0, duration: 400.ms, curve: Curves.easeInOut)

// Snap view dismiss (swipe down):
snapContainer.animate()
  .moveY(begin: 0, end: 120, duration: 250.ms, curve: Curves.easeIn)
  .fadeOut(duration: 250.ms)

// Language overlay card entrance:
langCard.animate()
  .fadeIn(duration: 220.ms)
  .slideY(begin: 0.12, duration: 220.ms, curve: Curves.easeOut)

// Sticker picker sheet slide up:
stickerSheet.animate()
  .slideY(begin: 0.3, end: 0, duration: 280.ms, curve: Curves.easeOut)
  .fadeIn(duration: 200.ms)

// Bottom nav icon tap feedback:
navIcon.animate(trigger: onTap)
  .scaleXY(begin: 1.0, end: 1.25, duration: 100.ms, curve: Curves.easeOut)
  .then()
  .scaleXY(begin: 1.25, end: 1.0, duration: 120.ms, curve: Curves.elasticOut)

// Capture button hold-to-record progress ring:
// Use AnimationController with vsync → CircularProgressIndicator value
// tween: 0 → 1, duration: maxVideoDuration (e.g. 15s)

// Snap opened flash (opening animation):
snapMedia.animate()
  .fadeIn(duration: 100.ms)
  .scaleXY(begin: const Offset(0.95, 0.95), end: Offset(1,1), duration: 180.ms)
```

---

## 7. DARK MODE MAPPING

All backgrounds in Snapchat's design are already dark-first.
Light mode variants:

| Element           | Dark (default)       | Light                 |
|---|---|---|
| Scaffold bg       | `0xFF000000`         | `0xFFF2F2F7`         |
| Surface card      | `0xFF1C1C1E`         | `0xFFFFFFFF`         |
| Inbox bg          | `0xFF000000`         | `0xFFF2F2F7`         |
| Inbox item        | `0xFF1C1C1E`         | `0xFFFFFFFF`         |
| Text primary      | `0xFFFFFFFF`         | `0xFF111827`         |
| Text secondary    | `0xFF9CA3AF`         | `0xFF6B7280`         |
| Story bg          | `0xFF111111`         | `0xFFF9FAFB`         |
| Nav bar           | `0xFF000000`         | `0xFFFFFFFF`         |
| Accent (brand)    | `0xFFE05C2A`         | `0xFFE05C2A`         |
| Streak bg         | `0xFF2D1E12`         | `0xFFFFF7ED`         |

---

## 8. COMPLETE FLUTTER FILE LIST FOR UI

- `lib/styles/snap_colors.dart`
- `lib/styles/snap_typography.dart`
- `lib/styles/snap_spacing.dart`
- `lib/screens/snap/snap_camera_screen.dart`
- `lib/screens/snap/snap_preview_screen.dart`
- `lib/screens/snap/snap_inbox_screen.dart`
- `lib/screens/snap/snap_view_screen.dart`
- `lib/screens/snap/snap_story_feed_screen.dart`
- `lib/screens/snap/snap_story_viewer_screen.dart`
- `lib/screens/snap/snap_story_create_screen.dart`
- `lib/screens/snap/snap_story_viewers_screen.dart`
- `lib/screens/snap/snap_streaks_screen.dart`
- `lib/screens/snap/snap_sticker_picker_screen.dart`
- `lib/widgets/snap/snap_story_ring.dart`
- `lib/widgets/snap/snap_state_indicator.dart`
- `lib/widgets/snap/snap_capture_button.dart`
- `lib/widgets/snap/snap_preview_toolbar.dart`
- `lib/widgets/snap/snap_inbox_tile.dart`
- `lib/widgets/snap/snap_story_progress.dart`
- `lib/widgets/snap/snap_streak_chip.dart`
- `lib/widgets/snap/snap_language_overlay.dart`
- `lib/widgets/snap/snap_send_to_sheet.dart`
- `lib/widgets/snap/snap_sticker_grid.dart`
- `lib/widgets/snap/snap_reply_bar.dart`
- `lib/widgets/snap/snap_spotlight_tile.dart`
- `lib/widgets/snap/snap_nav_bar.dart`
