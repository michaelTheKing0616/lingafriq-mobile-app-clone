# LingAfriq — WhatsApp-Style Chat UI Design Spec (Flutter)
# Paste into Cursor AI alongside the WhatsApp build prompt.
# Design size: 428 × 926 (flutter_screenutil baseline)

---

## 1. BRAND & COLOUR SYSTEM

```dart
// lib/styles/wa_colors.dart
class WAColors {
  // Surface & backgrounds
  static const chatListBg        = Color(0xFFF0FDF4); // light green tint
  static const chatListBgDark    = Color(0xFF111B21); // WhatsApp dark
  static const chatBg            = Color(0xFFF0FDF4);
  static const chatBgDark        = Color(0xFF0D1418);

  // Header
  static const headerBg          = Color(0xFF16A34A); // LingAfriq primary
  static const headerBgDark      = Color(0xFF1F2C34);
  static const headerFg          = Color(0xFFFFFFFF);

  // Own message bubble
  static const ownBubble         = Color(0xFFDCFCE7);
  static const ownBubbleDark     = Color(0xFF005C4B);
  static const ownText           = Color(0xFF111827);
  static const ownTextDark       = Color(0xFFE9EDEF);

  // Other message bubble
  static const otherBubble       = Color(0xFFFFFFFF);
  static const otherBubbleDark   = Color(0xFF1F2C34);
  static const otherText         = Color(0xFF111827);
  static const otherTextDark     = Color(0xFFE9EDEF);

  // Ticks
  static const tickGrey          = Color(0xFF8696A0);
  static const tickBlue          = Color(0xFF53BDEB);

  // Online dot
  static const onlineGreen       = Color(0xFF22C55E);

  // Unread badge
  static const unreadBadge       = Color(0xFF22C55E);
  static const unreadBadgeFg     = Color(0xFFFFFFFF);

  // Input bar
  static const inputBg           = Color(0xFFFFFFFF);
  static const inputBgDark       = Color(0xFF1F2C34);
  static const inputBorder       = Color(0xFFE5E7EB);
  static const inputBorderDark   = Color(0xFF374151);
  static const sendButton        = Color(0xFF22C55E);
  static const sendButtonDark    = Color(0xFF22C55E);

  // Status ring
  static const statusRingUnseen  = Color(0xFF16A34A);
  static const statusRingGradA   = Color(0xFF16A34A);
  static const statusRingGradB   = Color(0xFF059669);
  static const statusRingSeen    = Color(0xFF9CA3AF);

  // Reply preview bar
  static const replyBorder       = Color(0xFF16A34A);
  static const replyBg           = Color(0xFFECFDF5);
  static const replyBgDark       = Color(0xFF1A2E22);

  // System message pill
  static const systemPill        = Color(0xFFE8F5E9);
  static const systemPillDark    = Color(0xFF1A2E22);
  static const systemPillText    = Color(0xFF4B5563);
  static const systemPillTextDk  = Color(0xFF9CA3AF);

  // Dividers / hairlines
  static const divider           = Color(0xFFE5E7EB);
  static const dividerDark       = Color(0xFF2A3942);

  // Exercise accent
  static const exerciseAccent    = Color(0xFFE05C2A);
  static const exerciseBg        = Color(0xFFFFF7ED);
  static const exerciseBgDark    = Color(0xFF2D1E12);

  // Translation bubble
  static const transBorder       = Color(0xFF16A34A);
  static const transBg           = Color(0xFFECFDF5);
  static const transBgDark       = Color(0xFF1A2E22);
}
```

---

## 2. TYPOGRAPHY

```dart
// Use existing Dosis font family (already in pubspec.yaml)
class WATypography {
  // Chat list conversation name
  static TextStyle convName(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: ctx.isDarkMode ? WAColors.ownTextDark : WAColors.ownText,
  );

  // Chat list last-message preview
  static TextStyle convPreview(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: ctx.isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF6B7280),
  );

  // Chat list timestamp
  static TextStyle convTime(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: ctx.isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF9CA3AF),
  );

  // Message body (own and other)
  static TextStyle messageBody(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: ctx.isDarkMode ? WAColors.ownTextDark : WAColors.ownText,
  );

  // Message timestamp inside bubble
  static TextStyle messageMeta(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: ctx.isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF9CA3AF),
  );

  // Group sender name above bubble
  static TextStyle senderLabel(Color color) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 13.sp,
    fontWeight: FontWeight.w700,
    color: color,
  );

  // Date separator pill
  static TextStyle dateSeparator(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    color: ctx.isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF6B7280),
  );

  // Status card text (large phrase)
  static TextStyle statusPhrase(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 28.sp,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // App bar title
  static TextStyle appBarTitle(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 20.sp,
    fontWeight: FontWeight.w700,
    color: WAColors.headerFg,
  );

  // Section headers (e.g. "Pinned")
  static TextStyle sectionHeader(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: ctx.isDarkMode ? const Color(0xFF8696A0) : const Color(0xFF6B7280),
  );
}
```

---

## 3. SPACING & RADIUS

```dart
class WASpacing {
  static double get xxs  => 2.h;
  static double get xs   => 4.h;
  static double get sm   => 8.h;
  static double get md   => 12.h;
  static double get lg   => 16.h;
  static double get xl   => 20.h;
  static double get xxl  => 28.h;
}

class WARadius {
  // Bubble corners: 18 standard, 4 tail corner
  static BorderRadius ownBubble   = BorderRadius.only(
    topLeft:     Radius.circular(18.r),
    topRight:    Radius.circular(18.r),
    bottomLeft:  Radius.circular(18.r),
    bottomRight: Radius.circular(4.r),   // tail
  );
  static BorderRadius otherBubble = BorderRadius.only(
    topLeft:     Radius.circular(4.r),   // tail
    topRight:    Radius.circular(18.r),
    bottomLeft:  Radius.circular(18.r),
    bottomRight: Radius.circular(18.r),
  );
  static BorderRadius pill        = BorderRadius.circular(24.r);
  static BorderRadius input       = BorderRadius.circular(26.r);
  static BorderRadius card        = BorderRadius.circular(12.r);
  static BorderRadius statusRing  = BorderRadius.circular(40.r);
  static BorderRadius badge       = BorderRadius.circular(10.r);
}
```

---

## 4. SHADOWS

```dart
class WAShadows {
  static List<BoxShadow> bubble = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> inputBar = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, -2),
    ),
  ];
  static List<BoxShadow> statusCard = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
```

---

## 5. SCREEN-BY-SCREEN LAYOUT SPECS

### 5.1 WAChatListScreen

```
AppBar:
  height: 58.h
  background: WAColors.headerBg
  padding horizontal: 16.w
  title: "Chats" — WATypography.appBarTitle
  actions: [search IconButton 24.sp, more_vert IconButton 24.sp]
  elevation: 0

TabBar (below AppBar, NOT inside):
  height: 46.h
  background: WAColors.headerBg
  tabs: ["Chats", "Status", "Calls"]
  indicator: 2.5h thick white underline, width matches tab label
  labelStyle: dosis 14.sp w600 white
  unselectedLabelStyle: dosis 14.sp w400 white.withOpacity(0.7)

Conversation list item:
  height: 76.h (min)
  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h)
  Left: CircleAvatar 50.r
    - WAStatusRing wrapping the avatar if user has status
  Center column:
    - Row: name (flex 1) + timestamp right-aligned
    - Row: preview (flex 1) + unread badge or muted icon
  Pinned item: background Color(0xFFF0FDF4) light, pin icon 14.sp grey trailing

Unread badge:
  min 20.r × 20.r circle, WAColors.unreadBadge
  text: 11.sp white w700, centered
  if count > 99: show "99+"

Online ring around avatar:
  3px border, WAColors.onlineGreen
  rendered as Container with shape: BoxShape.circle, border

Swipe-to-reveal (using Dismissible or custom drag):
  right swipe threshold 60.w → archive tile (green, archive icon)
  left swipe threshold 60.w → delete tile (red, delete icon)

Section divider between pinned and regular:
  Container height 28.h, color surfaceContainer, child Text("Chats", labelStyle)
```

### 5.2 WAPrivateChatScreen + WAGroupChatScreen

```
AppBar:
  height: 58.h
  background: WAColors.headerBg
  leading: BackButton (white)
  title: Row [
    CircleAvatar 36.r + WAOnlineRing | WAStatusRing 2px
    SizedBox 10.w
    Column [
      Text(name) dosis 16.sp w700 white
      Text("Online" | "last seen …") dosis 12.sp white.withOpacity(0.7)
    ]
  ]
  actions: [video_call_outlined 24.sp, call_outlined 24.sp, more_vert 24.sp] white

Chat background:
  Container with DecorationImage using asset or network tile
  Fallback: solid WAColors.chatBg
  Repeat: ImageRepeat.repeat at 0.1 opacity green kente pattern

MessageList:
  ListView.builder reverse: false
  padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h)
  Between same-sender consecutive messages: gap 2.h
  Between different senders: gap 6.h
  Date separator pill:
    margin: EdgeInsets.symmetric(vertical: 8.h)
    Container padding 6.h × 14.w, WAColors.systemPill, WARadius.pill
    Text("Today" | "Yesterday" | "Mon 2 Jan") WATypography.dateSeparator

WAMessageBubble:
  maxWidth: 0.75.sw
  bubble container:
    padding: EdgeInsets.fromLTRB(10.w, 6.h, 10.w, 4.h) for text
    padding: EdgeInsets.zero for image/video (clip to radius)
    border-radius: WARadius.ownBubble | WARadius.otherBubble
    color: WAColors.ownBubble | WAColors.otherBubble
    shadow: WAShadows.bubble

  Message types:
    TEXT:
      SelectableText, WATypography.messageBody
      then SizedBox(4.h)
      then Row(mainAxisSize: min) [
        Text(HH:MM) 11.sp grey
        if own: SizedBox(4.w) + _TickIcon()
      ] → MainAxisAlignment.end

    IMAGE:
      ClipRRect(borderRadius: WARadius.card)
        Image.network(url, width: min(260.w, actual), fit: BoxFit.cover)
      if caption: Padding(8) Text(caption)
      metadata row below

    VOICE NOTE:
      Row height 44.h [
        _PlayPauseButton 36.r circle WAColors.headerBg
        SizedBox(8.w)
        _WaveformBars(waveform: List<double>, progress: 0-1)
          → 32 bars, width 2.5.w each, gap 2.w, height proportional to amplitude * 28.h
          → filled bars: WAColors.headerBg, unfilled: WAColors.headerBg.withOpacity(0.3)
        SizedBox(6.w)
        Text("1:23") 11.sp grey
      ]

    DOCUMENT:
      Row [
        Icon(description_outlined) 32.sp WAColors.headerBg
        SizedBox(8.w)
        Column [
          Text(filename) 13.sp w600
          Text(size_kb) 11.sp grey
        ]
      ]
      padding: 10.h × 12.w

    LOCATION:
      ClipRRect(WARadius.card)
        Image.network("https://staticmap.openstreetmap.de/staticmap.php?center=LAT,LNG&zoom=14&size=300x150")
        width: 260.w
      Text(address_name) 12.sp grey padding 6.h × 10.w

    EXERCISE:
      Container decoration border WAColors.exerciseAccent 1.5px WARadius.card
      padding 12.h × 14.w
      Column [
        Row [Icon(bolt) exerciseAccent 16.sp, Text("Exercise") 12.sp exerciseAccent w700]
        SizedBox(8.h)
        Text(prompt) 14.sp
        SizedBox(8.h)
        ...options as _OptionButton widgets
      ]

    DELETED:
      Row [
        Icon(block, 16.sp, grey)
        SizedBox(4.w)
        Text("This message was deleted", 13.sp, italic, grey)
      ]

  REPLY PREVIEW (above bubble content if replyTo != null):
    Container(
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.all(6.h),
      decoration: BoxDecoration(
        color: WAColors.replyBg,
        border: Border(left: BorderSide(WAColors.replyBorder, 3)),
        borderRadius: WARadius.card,
      ),
      child: Column [
        Text(replyTo.senderName, 12.sp, w700, WAColors.headerBg)
        Text(replyTo.content, 12.sp, grey, maxLines: 2, overflow: ellipsis)
      ]
    )

  FORWARD LABEL (if isForwarded):
    Row [Icon(reply_outlined, 12.sp, grey), Text("Forwarded", 11.sp, grey, italic)]
    margin bottom 2.h

  REACTIONS ROW (below bubble):
    Row [
      for each (emoji, count) in groupedReactions:
        GestureDetector(onTap: showWhoReacted,
          Container(
            padding: 3.h × 7.w
            decoration: BoxDecoration(
              color: surfaceContainer, borderRadius: pill, border 1px divider
            )
            child: Row [Text(emoji, 13.sp), SizedBox(3.w), Text(count, 11.sp)]
          )
        )
    ]
    margin top 3.h, MainAxisAlignment.start

_TickIcon():
  if status == 'read':    Icon(done_all) 14.sp WAColors.tickBlue
  if status == 'delivered': Icon(done_all) 14.sp WAColors.tickGrey
  if status == 'sent':    Icon(done)     14.sp WAColors.tickGrey
  if status == 'sending': SizedBox 14.sp CircularProgressIndicator strokeWidth 1.5

Long-press context menu (show as BottomSheet or HeroDialog overlay):
  Background: blurred backdrop (BackdropFilter blur 10)
  Pill menu cards (each 52.h):
    Row of 6 reaction emojis: 28.sp each, tap → react/un-react
    Divider 1px
    ListTiles: Reply, Forward, Copy, Star, Edit (own < 15min), Delete
  Enter animation: scale 0.8→1.0 + opacity 0→1, 180ms easeOut spring

Typing indicator (at bottom of message list):
  Row [
    CircleAvatar 30.r (other user)
    SizedBox 8.w
    Container(
      padding 8.h × 14.w, color otherBubble, borderRadius WARadius.otherBubble
      Row [dot, dot, dot] each 6.r grey
      each dot animates y: [0, -5, 0], duration 0.6s, stagger 150ms, repeat infinite
    )
  ]
  Show only when typingUsers[roomId].isNotEmpty

WAMessageInput (bottom bar):
  height: min 58.h, auto-expands to max 160.h
  background: WAColors.inputBar (surface variant)
  shadow: WAShadows.inputBar
  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h)
  Row [
    EmojiButton(icon: emoji_emotions_outlined, 26.sp, grey)
    SizedBox(4.w)
    Expanded(
      TextField(
        maxLines: null, keyboardType: multiline
        style: dosis 15.sp
        decoration: InputDecoration(
          hintText: "Message",
          hintStyle: 15.sp grey,
          border: none,
          contentPadding: 10.h × 0
        )
      )
    )
    SizedBox(4.w)
    if text.isEmpty: AttachButton(icon: attach_file, 26.sp, grey)
    if text.isEmpty: CameraButton(icon: camera_alt_outlined, 26.sp, grey)
    if text.isEmpty: MicButton(GestureDetector onLongPressStart → record, onLongPressEnd → send)
    if text.isNotEmpty: AnimatedSendButton(
      Container 40.r circle, WAColors.sendButton
      Icon(send_rounded, 22.sp, white)
      enter: scale 0→1 spring 400/30
    )
  ]

Voice Record Overlay (visible during hold-to-record):
  Full-width row replaces input:
  [red dot + "Recording…" + timer + animated waveform + "< Slide to cancel" + record button]
  background: surface red tint Color(0xFFFEF2F2)
  cancelled if drag > 80.w left

Reply bar (above input, visible when replyTo != null):
  Container height 52.h
  background: WAColors.replyBg, border-top WAColors.replyBorder 3.w
  Row [
    Expanded Column [
      Text(replyTo.senderName, 12.sp w700 headerBg)
      Text(replyTo.preview, 12.sp grey maxLines 1)
    ]
    IconButton(close, 20.sp, grey) → clears reply
  ]

Scroll-to-bottom FAB:
  if !isNearBottom && unreadCount > 0:
    Positioned bottom 80.h right 16.w
    FloatingActionButton.small
      Icon(expand_more, white) + Badge(unreadCount)
      background: WAColors.headerBg
```

### 5.3 WAStatusListScreen

```
Header same as chat list but tab = "Status"

My Status row (always first):
  height: 76.h
  leading: Stack [
    CircleAvatar 50.r (own avatar)
    Positioned bottom 0 right 0:
      Container 22.r WAColors.headerBg border 2px white
      Icon(add, white, 14.sp) → navigate to wa-status-create
  ]
  title: "My Status", dosis 15.sp w600
  subtitle: "Tap to add status update", 13.sp grey
  if hasOwnStatus: subtitle = "X updates, Y hours ago"

Contact status row:
  height: 76.h
  leading: WAStatusRing(child: CircleAvatar 50.r, seen: bool)
  title: contact.displayName 15.sp w600
  subtitle: "2 hours ago" 13.sp grey
  trailing: null

WAStatusRing widget:
  CustomPaint or Container border:
  Unseen: 3px border with LinearGradient(WAColors.statusRingGradA, statusRingGradB), 4px gap
  Seen: 3px border Color(0xFF9CA3AF), 4px gap
  Size: avatar + 7.w each side
```

### 5.4 WAStatusViewScreen

```
Scaffold backgroundColor: black
SafeArea child: Stack [

  Progress bars row (top):
    padding EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 0)
    Row [
      for each story item: Expanded(
        Container height 2.5.h margin horizontal 2.w
        background white.withOpacity(0.3) (track)
        Stack [
          AnimatedContainer width = progress * maxWidth (Tween)
            color: white
            duration: varies (photo 5s, video = actual duration)
        ]
      )
    ]

  Header (below progress bars):
    padding 12.h × 12.w
    Row [
      CircleAvatar 36.r
      SizedBox 10.w
      Column [
        Text(displayName, 13.sp, w700, white)
        Text(relativeTime, 11.sp, white.withOpacity(0.7))
      ]
      Spacer
      IconButton(more_vert, white) → mute / report
      IconButton(close, white, 22.sp) → pop
    ]

  Content area (fills screen):
    GestureDetector(
      onTapDown: (d) { if d.localPosition.dx < width/2 → prev else → next }
      onLongPress: → pause animation
      onLongPressUp: → resume
    )
    if type == image: Image.network(url, fit: BoxFit.contain)
    if type == video: VideoPlayer(controller) + VideoProgressIndicator
    if type == text:
      Container(
        decoration: BoxDecoration(color: backgroundColor)
        Center(child: Padding(
          padding 24.w,
          Text(textContent, style: WATypography.statusPhrase, textAlign: center)
        ))
      )

  Caption bar (bottom of media if caption not empty):
    Positioned bottom 64.h left 0 right 0:
    Container(
      padding 12.h × 16.w
      gradient: LinearGradient(transparent → black.withOpacity(0.6), begin: top, end: bottom)
      Text(caption, 14.sp, white)
    )

  Reply bar (very bottom):
    Positioned bottom 0 left 0 right 0 height 58.h:
    Container(
      color: Colors.black.withOpacity(0.3)
      Row [
        TextField(
          style: white 14.sp, hintText: "Reply to status…" hintStyle grey
          decoration: OutlineInputBorder(rounded 24.r, borderSide white.withOpacity(0.4))
        )
        SizedBox(8.w)
        IconButton(send_rounded, white, 22.sp)
        IconButton(thumb_up_outlined, white, 22.sp)
        IconButton(favorite_border, white, 22.sp)
      ]
    )

  Viewers count (own status only):
    Positioned bottom 64.h right 16.w:
    GestureDetector(onTap: showViewersList,
      Row [Icon(visibility, white, 16.sp), SizedBox(4.w), Text(viewCount, 12.sp, white)]
    )
]
```

### 5.5 WAStatusCreateScreen

```
Scaffold:
  AppBar: transparent, back arrow, "Status" title, Post button (disabled if no content)

Type selector (horizontal TabBar):
  tabs: Text | Image | Video
  indicator: 2px bottom line WAColors.headerBg

Text Status canvas:
  Container full width, height 360.h
  background: current selected color (default WAColors.headerBg)
  child:
    if textContent.isEmpty: placeholder "Type a status…" white.withOpacity(0.5) 22.sp center
    else: Text(textContent, style based on fontStyle, white, center, 22.sp)

  Below canvas:
    ColorPicker row: 8 circles 32.r each [#E05C2A, #16A34A, #1D4ED8, #7C3AED, #DB2777, #111827, #F59E0B, #FFFFFF]
    FontPicker row: "Aa" in 5 styles [sans, serif, mono, bold, italic]
    TextField for editing text content (hidden keyboard below)

Image preview:
  ClipRRect 16.r Image.file(selected), maxHeight 480.h
  Caption TextField below: hint "Add a caption…" 14.sp

Post button:
  Container 48.h × 160.w, WAColors.headerBg, WARadius.pill
  Text("Post") dosis 16.sp w700 white
  Positioned bottom 24.h centered
```

### 5.6 WAMediaGalleryScreen

```
AppBar: "$name — Media" title, share icon action

TabBar: "Media" | "Links" | "Documents"

Media grid:
  GridView.builder SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 2,
    mainAxisSpacing: 2,
  )
  Each cell:
    Image.network(thumbnailUrl, fit: BoxFit.cover)
    if video: Positioned center → Icon(play_circle_outline, white, 28.sp)

Links list:
  ListTile for each:
    leading: Image.network(favicon, 36.r)
    title: link title 14.sp w600
    subtitle: domain 12.sp grey

Documents list:
  ListTile:
    leading: Icon by extension (pdf→picture_as_pdf, doc→article, etc.) 32.sp headerBg
    title: filename 14.sp w600
    subtitle: "size • date" 12.sp grey
    trailing: IconButton(download, grey)
```

---

## 6. ANIMATIONS (flutter_animate)

```dart
// Message bubble enter (first appearance):
WAMessageBubble(...).animate(delay: (index * 25).ms)
  .fadeIn(duration: 180.ms)
  .slideX(begin: isOwn ? 0.15 : -0.15, duration: 180.ms, curve: Curves.easeOut)

// New message from socket (real-time):
bubble.animate()
  .fadeIn(duration: 150.ms)
  .slideY(begin: 0.1, duration: 150.ms, curve: Curves.easeOut)

// Reaction picker open:
reactionRow.animate()
  .scale(begin: const Offset(0.4, 0.4), duration: 200.ms, curve: Curves.elasticOut)
  .fadeIn(duration: 120.ms)

// Typing indicator dots (looping):
// Dot 0: delay 0ms, Dot 1: delay 150ms, Dot 2: delay 300ms
dot.animate(onPlay: (c) => c.repeat())
  .moveY(begin: 0, end: -5, duration: 300.ms, curve: Curves.easeInOut)
  .then(delay: 0.ms)
  .moveY(begin: -5, end: 0, duration: 300.ms, curve: Curves.easeInOut)

// Send button appear (text becomes non-empty):
sendButton.animate()
  .scale(begin: const Offset(0, 0), duration: 200.ms, curve: Curves.elasticOut)

// Status ring pulse (unseen statuses):
statusRing.animate(onPlay: (c) => c.repeat(reverse: true))
  .scaleXY(begin: 1.0, end: 1.04, duration: 1200.ms, curve: Curves.easeInOut)

// Context menu appear:
contextMenu.animate()
  .scale(begin: const Offset(0.85, 0.85), duration: 180.ms, curve: Curves.easeOut)
  .fadeIn(duration: 120.ms)

// Chat list item on load:
conversationTile.animate(delay: (index * 30).ms)
  .fadeIn(duration: 200.ms)
  .slideX(begin: -0.05, duration: 200.ms)

// Tab underline indicator:
// Use AnimatedContainer width/position or DefaultTabController built-in with custom indicator

// Status progress fill:
// Use AnimatedBuilder with AnimationController driving width % from 0 to 1
// duration = storyDurationMs, curve: Curves.linear
```

---

## 7. DARK MODE MAPPING

Every `Color` must switch via `Theme.of(context).brightness == Brightness.dark`:

| Element | Light | Dark |
|---|---|---|
| Chat list bg | `0xFFF0FDF4` | `0xFF111B21` |
| Chat bg | `0xFFF0FDF4` | `0xFF0D1418` |
| Own bubble | `0xFFDCFCE7` | `0xFF005C4B` |
| Other bubble | `0xFFFFFFFF` | `0xFF1F2C34` |
| Input bar bg | `0xFFFFFFFF` | `0xFF1F2C34` |
| App bar | `0xFF16A34A` | `0xFF1F2C34` |
| Status pill | `0xFFE8F5E9` | `0xFF1A2E22` |
| Divider | `0xFFE5E7EB` | `0xFF2A3942` |
| Body text | `0xFF111827` | `0xFFE9EDEF` |
| Secondary text | `0xFF6B7280` | `0xFF8696A0` |

---

## 8. COMPLETE FLUTTER FILE LIST FOR UI

- `lib/styles/wa_colors.dart`
- `lib/styles/wa_typography.dart`
- `lib/styles/wa_spacing.dart`
- `lib/screens/chat_whatsapp/wa_chat_list_screen.dart`
- `lib/screens/chat_whatsapp/wa_private_chat_screen.dart`
- `lib/screens/chat_whatsapp/wa_group_chat_screen.dart`
- `lib/screens/chat_whatsapp/wa_status_list_screen.dart`
- `lib/screens/chat_whatsapp/wa_status_view_screen.dart`
- `lib/screens/chat_whatsapp/wa_status_create_screen.dart`
- `lib/screens/chat_whatsapp/wa_media_gallery_screen.dart`
- `lib/screens/chat_whatsapp/wa_starred_messages_screen.dart`
- `lib/screens/chat_whatsapp/wa_group_info_screen.dart`
- `lib/screens/chat_whatsapp/wa_contact_profile_screen.dart`
- `lib/widgets/wa/wa_message_bubble.dart`
- `lib/widgets/wa/wa_message_input.dart`
- `lib/widgets/wa/wa_conversation_tile.dart`
- `lib/widgets/wa/wa_typing_indicator.dart`
- `lib/widgets/wa/wa_voice_note_player.dart`
- `lib/widgets/wa/wa_voice_recorder_overlay.dart`
- `lib/widgets/wa/wa_reaction_picker.dart`
- `lib/widgets/wa/wa_status_ring.dart`
- `lib/widgets/wa/wa_online_badge.dart`
- `lib/widgets/wa/wa_tick_icon.dart`
- `lib/widgets/wa/wa_waveform_bars.dart`
- `lib/widgets/wa/wa_reply_bar.dart`
- `lib/widgets/wa/wa_context_menu.dart`
- `lib/widgets/wa/wa_date_separator.dart`
