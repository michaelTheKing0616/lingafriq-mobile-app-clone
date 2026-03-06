# LingAfriq — X (Twitter)-Style Feed UI Design Spec (Flutter)
# Paste into Cursor AI alongside the X build prompt.
# Design size: 428 × 926 (flutter_screenutil baseline)

---

## 1. BRAND & COLOUR SYSTEM

```dart
// lib/styles/x_colors.dart
class XColors {
  // Backgrounds
  static const scaffoldLight     = Color(0xFFFFFFFF);
  static const scaffoldDark      = Color(0xFF000000);
  static const surfaceLight      = Color(0xFFFFFFFF);
  static const surfaceDark       = Color(0xFF16181C);
  static const cardLight         = Color(0xFFFFFFFF);
  static const cardDark          = Color(0xFF1E2128);
  static const dimLight          = Color(0xFFF7F9F9);  // X's grey-tinted bg
  static const dimDark           = Color(0xFF15202B);  // X's "Dim" theme

  // Primary accent (LingAfriq orange — replaces X blue)
  static const accent            = Color(0xFFE05C2A);
  static const accentLight       = Color(0xFFFFF3EE);
  static const accentGreen       = Color(0xFF16A34A);  // secondary CTA

  // Like (heart)
  static const likeActive        = Color(0xFFE11D48);  // red heart
  static const likeBg            = Color(0xFFFFF1F2);  // like button bg active
  static const likeActiveDark    = Color(0xFFE11D48);

  // Repost
  static const repostActive      = Color(0xFF16A34A);
  static const repostActiveDark  = Color(0xFF22C55E);

  // Bookmark
  static const bookmarkActive    = Color(0xFFE05C2A);

  // Verified badge (teachers)
  static const verifiedBadge     = Color(0xFFE05C2A);

  // Hashtag / mention links
  static const linkColor         = Color(0xFFE05C2A);

  // Poll
  static const pollBarBg         = Color(0xFFE9E9E9);
  static const pollBarBgDark     = Color(0xFF2F3336);
  static const pollBarFill       = Color(0xFFE05C2A);
  static const pollLeader        = Color(0xFFE05C2A);

  // Quiz
  static const quizAccent        = Color(0xFF7C3AED);
  static const quizBg            = Color(0xFFF5F3FF);
  static const quizBgDark        = Color(0xFF1E1B2E);
  static const quizCorrect       = Color(0xFF16A34A);
  static const quizWrong         = Color(0xFFEF4444);

  // Phrase / word card
  static const phraseCardBg      = Color(0xFFFFF3EE);
  static const phraseCardBgDark  = Color(0xFF2D1A10);
  static const phraseCardBorder  = Color(0xFFE05C2A);
  static const wordOfDayGrad1    = Color(0xFF16A34A);
  static const wordOfDayGrad2    = Color(0xFF059669);

  // Post card dividers
  static const divider           = Color(0xFFEFF3F4);
  static const dividerDark       = Color(0xFF2F3336);

  // Thread connector line
  static const threadLine        = Color(0xFFCFD9DE);
  static const threadLineDark    = Color(0xFF2F3336);

  // Input / compose
  static const inputBorder       = Color(0xFFE1E8ED);
  static const inputBorderDark   = Color(0xFF2F3336);
  static const charCountOk       = Color(0xFF9CA3AF);
  static const charCountWarn     = Color(0xFFF59E0B);
  static const charCountOver     = Color(0xFFEF4444);

  // Notification type colours
  static const notifLike         = Color(0xFFE11D48);
  static const notifRepost       = Color(0xFF16A34A);
  static const notifReply        = Color(0xFFE05C2A);
  static const notifFollow       = Color(0xFF7C3AED);
  static const notifMention      = Color(0xFFE05C2A);

  // Audio room / Spaces
  static const liveRed           = Color(0xFFEF4444);
  static const speakerRing       = Color(0xFF16A34A);

  // Text
  static const textPrimary       = Color(0xFF0F1419);
  static const textPrimaryDark   = Color(0xFFE7E9EA);
  static const textSecondary     = Color(0xFF536471);
  static const textSecondaryDark = Color(0xFF71767B);
  static const textMuted         = Color(0xFF9CA3AF);
}
```

---

## 2. TYPOGRAPHY

```dart
// lib/styles/x_typography.dart
class XTypography {
  // Post author display name
  static TextStyle displayName(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: ctx.isDarkMode ? XColors.textPrimaryDark : XColors.textPrimary,
  );

  // Post @username and secondary info
  static TextStyle username(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: ctx.isDarkMode ? XColors.textSecondaryDark : XColors.textSecondary,
  );

  // Post body text
  static TextStyle postBody(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: ctx.isDarkMode ? XColors.textPrimaryDark : XColors.textPrimary,
  );

  // Post timestamp / metadata
  static TextStyle postMeta(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: ctx.isDarkMode ? XColors.textSecondaryDark : XColors.textSecondary,
  );

  // Action count (likes, reposts etc.)
  static TextStyle actionCount(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: ctx.isDarkMode ? XColors.textSecondaryDark : XColors.textSecondary,
  );

  // Native phrase text (large)
  static TextStyle nativePhrase(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 22.sp,
    fontWeight: FontWeight.w800,
    color: ctx.isDarkMode ? XColors.textPrimaryDark : XColors.textPrimary,
    letterSpacing: 0.2,
  );

  // Word of day title word
  static TextStyle wordOfDay(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 28.sp,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 0.3,
  );

  // Pronunciation (italic, muted)
  static TextStyle pronunciation(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    fontStyle: FontStyle.italic,
    color: ctx.isDarkMode ? XColors.textSecondaryDark : XColors.textSecondary,
  );

  // Translation text
  static TextStyle translation(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: ctx.isDarkMode ? XColors.textMuted : XColors.textMuted,
  );

  // Hashtag / mention within post body
  static TextStyle link(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 15.sp,
    fontWeight: FontWeight.w400,
    color: XColors.linkColor,
  );

  // Tab bar labels
  static TextStyle tabLabel(BuildContext ctx, bool active) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 15.sp,
    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
    color: active
        ? (ctx.isDarkMode ? XColors.textPrimaryDark : XColors.textPrimary)
        : (ctx.isDarkMode ? XColors.textSecondaryDark : XColors.textSecondary),
  );

  // Section header
  static TextStyle sectionHeader(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 19.sp,
    fontWeight: FontWeight.w800,
    color: ctx.isDarkMode ? XColors.textPrimaryDark : XColors.textPrimary,
  );

  // Trend tag label
  static TextStyle trendTag(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 15.sp,
    fontWeight: FontWeight.w700,
    color: ctx.isDarkMode ? XColors.textPrimaryDark : XColors.textPrimary,
  );

  // Trend count
  static TextStyle trendCount(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: ctx.isDarkMode ? XColors.textSecondaryDark : XColors.textSecondary,
  );

  // Notification body
  static TextStyle notifBody(BuildContext ctx) => TextStyle(
    fontFamily: 'dosis',
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: ctx.isDarkMode ? XColors.textPrimaryDark : XColors.textPrimary,
  );
}
```

---

## 3. SPACING & RADIUS

```dart
class XSpacing {
  static double get xxs  => 2.h;
  static double get xs   => 4.h;
  static double get sm   => 8.h;
  static double get md   => 12.h;
  static double get lg   => 16.h;
  static double get xl   => 20.h;
  static double get xxl  => 28.h;
}

class XRadius {
  // Post card avatar
  static BorderRadius avatar     = BorderRadius.circular(22.r);
  // Post media images (single)
  static BorderRadius media1     = BorderRadius.circular(14.r);
  // Post media grid (2+)
  static BorderRadius mediaGrid  = BorderRadius.circular(10.r);
  // Quote post inner card
  static BorderRadius quoteCard  = BorderRadius.circular(12.r);
  // Poll option bar
  static BorderRadius pollBar    = BorderRadius.circular(4.r);
  // Compose post button
  static BorderRadius composeFAB = BorderRadius.circular(28.r);
  // Tab indicator
  static BorderRadius tabIndicator = BorderRadius.circular(2.r);
  // Pill buttons
  static BorderRadius pill       = BorderRadius.circular(24.r);
  // Bottom sheet
  static BorderRadius sheet      = BorderRadius.vertical(top: Radius.circular(18.r));
  // Verified badge
  static BorderRadius verified   = BorderRadius.circular(10.r);
  // Trend card
  static BorderRadius trendCard  = BorderRadius.circular(14.r);
  // Audio room card
  static BorderRadius roomCard   = BorderRadius.circular(16.r);
}
```

---

## 4. SHADOWS

```dart
class XShadows {
  static List<BoxShadow> card = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];
  static List<BoxShadow> composeFab = [
    BoxShadow(
      color: XColors.accent.withOpacity(0.35),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static List<BoxShadow> quoteCard = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}
```

---

## 5. SCREEN-BY-SCREEN LAYOUT SPECS

### 5.1 FeedHomeScreen

```
Scaffold:
  backgroundColor: XColors.scaffoldLight (dark: scaffoldDark)
  resizeToAvoidBottomInset: false

AppBar:
  height: 52.h
  transparent / background:
    dark → scaffold 90% opacity + blur (BackdropFilter sigma 10)
    light → surface 95% opacity + blur
  elevation: 0
  titleSpacing: 0
  leading: CircleAvatar 32.r (own avatar) → opens profile drawer
  title: Image.asset('assets/images/logo.png', height: 28.h, width: 28.w) centered
  actions: [IconButton(add_circle_outline, 22.sp, accent)] → settings

TabBar (below AppBar, sticky):
  height: 48.h
  labelStyle: XTypography.tabLabel(ctx, true)
  unselectedLabelStyle: XTypography.tabLabel(ctx, false)
  indicator: Container(
    height: 3.h, width: 44.w  (fits label width, not full tab)
    color: XColors.accent
    borderRadius: XRadius.tabIndicator
  )
  tabs: ["For You", "Following"]

TabBarView:
  Each tab → FeedPostListView

FeedPostListView:
  RefreshIndicator(color: XColors.accent)
    CustomScrollView slivers [
      SliverList(delegate: SliverChildBuilderDelegate(
        childCount: posts.length + 1  // +1 for load-more
        builder: (ctx, i) {
          if i < posts.length: return XPostCard(post: posts[i])
          else: return _LoadMoreIndicator()
        }
      ))
    ]

  _LoadMoreIndicator:
    Container height 56.h, Center CircularProgressIndicator(color: accent, strokeWidth: 2)

New-posts chip (appears when socket delivers new posts while user scrolled down):
  AnimatedPositioned top: isVisible ? topPadding + 4.h : -44.h
  Center:
    GestureDetector(onTap: scrollToTop + loadNewPosts)
    Container(
      padding: 8.h × 18.w
      decoration: BoxDecoration(
        color: XColors.accent
        borderRadius: XRadius.pill
        boxShadow: XShadows.composeFab
      )
      child: Row [
        Icon(arrow_upward, white, 14.sp)
        SizedBox(6.w)
        Text("$newCount new posts", 13.sp, white, w600)
      ]
    )

Floating compose button (bottom right):
  FloatingActionButton.extended(
    backgroundColor: XColors.accent
    foregroundColor: Colors.white
    icon: Icon(edit_outlined, 20.sp)
    label: Text("Post", dosis 14.sp w700)
    shape: RoundedRectangleBorder(XRadius.composeFAB)
    elevation: 4
    heroTag: "compose-fab"
    onPressed: → navigate to feed-compose
  )
  bottom: 80.h + bottom safe area
  right: 16.w

Bottom nav bar (persistent):
  height: 50.h + bottom safe area
  backgroundColor: white (dark: scaffoldDark)
  border-top: 0.5px XColors.divider
  Row mainAxisAlignment.spaceEvenly [
    _XNavItem(icon: home_rounded,         label: "Home",         route: "feed-home")
    _XNavItem(icon: search_rounded,       label: "Search",       route: "feed-explore")
    _XNavItem(icon: notifications_none,   label: "Alerts",       route: "feed-notifications",
              badge: unreadNotifCount)
    _XNavItem(icon: mail_outline_rounded, label: "Messages",     route: "global_chat")
    _XNavItem(icon: person_outline,       label: "Profile",      route: "feed-user-profile")
  ]
  _XNavItem:
    Column [
      Stack [
        Icon(icon, 24.sp, active? textPrimary : textSecondary)
        if badge > 0: Positioned top-right:
          Container(
            min 16.r circle, accent color
            Text(badge > 9 ? "9+" : badge.toString(), 10.sp, white, w700)
          )
      ]
    ]
    no labels on X-style nav (icon only)
```

### 5.2 XPostCard (core reusable card)

```
Container(
  color: XColors.cardLight (dark: cardDark)
  child: Column [

    // Divider (hairline top)
    if !isFirst: Divider(height: 0.5.h, color: XColors.divider)

    Padding(horizontal: 12.w, vertical: 10.h):
      Row crossAxisAlignment.start [

        // AVATAR column (left)
        Column [
          GestureDetector(onTap: → navigateToProfile(post.userId))
          CircleAvatar(radius: 20.r, backgroundImage: NetworkImage(avatarUrl))
          // Thread connector line (if this post is part of a thread and not last)
          if isPartOfThread && !isLastInThread:
            Container(
              width: 2.w,
              height: remainingBubbleHeight,  // computed from content height
              color: XColors.threadLine,
              margin: EdgeInsets.only(top: 4.h)
            )
        ]

        SizedBox(10.w)

        // POST CONTENT column (right, flex 1)
        Expanded Column crossAxisAlignment.start [

          // AUTHOR ROW
          Row [
            Expanded Row [
              Text(displayName, XTypography.displayName, maxLines: 1, overflow: ellipsis)
              SizedBox(3.w)
              if isVerified: _VerifiedBadge()
              SizedBox(4.w)
              Text("@$username", XTypography.username)
              Text(" · ", XTypography.username)
              Text(timeAgo, XTypography.postMeta)
            ]
            _PostMoreMenu(post: post)  // "···" button → BottomSheet
          ]

          // REPLY CONTEXT (if replyToId != null)
          if post.replyToUsername != null:
            Text(
              "Replying to @${post.replyToUsername}",
              style: XTypography.username(ctx).copyWith(color: XColors.linkColor),
            )
            SizedBox(2.h)

          // BODY TEXT
          if post.content.isNotEmpty:
            _XRichText(
              text: post.content,
              baseStyle: XTypography.postBody(ctx),
              linkStyle: XTypography.link(ctx),
              onHashtagTap: (tag) → navigateToHashtag(tag),
              onMentionTap: (user) → navigateToProfile(user),
            )
            SizedBox(6.h)

          // POST TYPE CONTENT (rendered after body text)
          switch post.type:
            case 'image':   _PostMediaGrid(urls: post.mediaUrls)
            case 'video':   _PostVideoPlayer(url: post.mediaUrls.first)
            case 'poll':    _PostPollCard(poll: post.poll)
            case 'quiz':    _PostQuizCard(quiz: post.quiz)
            case 'phrase':  _PostPhraseCard(post: post)
            case 'word_of_day': _PostWordOfDayCard(post: post)
            case 'lesson_snippet': _PostLessonCard(post: post)

          // QUOTE POST (if quoteOfId != null)
          if post.quoteOf != null:
            _QuotePostCard(quote: post.quoteOf!)
            SizedBox(8.h)

          // ACTION ROW
          Padding(top: 10.h)
          Row mainAxisAlignment.spaceBetween [
            _PostAction(
              icon: chat_bubble_outline_rounded, 20.sp
              count: post.replyCount
              onTap: → openReplySheet(post)
              activeColor: null
            )
            _PostAction(
              icon: repeat_rounded, 20.sp
              count: post.repostCount
              onTap: → showRepostSheet(post)
              isActive: post.isReposted
              activeColor: XColors.repostActive
            )
            _PostAction(
              icon: post.isLiked ? favorite_rounded : favorite_border_rounded, 20.sp
              count: post.likeCount
              onTap: → toggleLike(post)
              isActive: post.isLiked
              activeColor: XColors.likeActive
            )
            _PostAction(
              icon: post.isBookmarked ? bookmark_rounded : bookmark_border_rounded, 20.sp
              count: null
              onTap: → toggleBookmark(post)
              isActive: post.isBookmarked
              activeColor: XColors.bookmarkActive
            )
            Row [
              Icon(bar_chart_rounded, 18.sp, textSecondary)
              SizedBox(3.w)
              Text(formatCount(post.viewCount), 12.sp, textSecondary)
              SizedBox(10.w)
              Icon(share_outlined, 18.sp, textSecondary)
            ]
          ]
        ]
      ]
  ]
)

_PostAction widget:
  GestureDetector(onTap: onTap)
  Row [
    AnimatedSwitcher(
      Icon(icon, size, isActive ? activeColor : XColors.textSecondary)
    )
    if count != null && count > 0:
      SizedBox(3.w)
      Text(formatCount(count), 12.sp, isActive ? activeColor : textSecondary)
  ]

_VerifiedBadge widget:
  Container(
    width: 16.w, height: 16.w
    decoration: BoxDecoration(
      color: XColors.verifiedBadge
      shape: BoxShape.circle
    )
    child: Icon(check, white, 10.sp)
  )

formatCount(int n) → "999" | "1.2K" | "12K" | "1.2M"

timeAgo(DateTime d):
  < 60s → "now"
  < 60m → "${m}m"
  < 24h → "${h}h"
  < 7d  → "${d}d"
  else  → "Jan 2"
```

### 5.3 Post Media Rendering

```
_PostMediaGrid (images):
  1 image:
    ClipRRect(XRadius.media1)
    Image.network(url, width: full, height: min(300.h, aspectHeight), fit: BoxFit.cover)

  2 images:
    Row spacing 2.w [
      Expanded ClipRRect(XRadius.mediaGrid) Image h: 200.h fit: cover
      Expanded ClipRRect(XRadius.mediaGrid) Image h: 200.h fit: cover
    ]

  3 images:
    Row [
      Expanded ClipRRect(XRadius.mediaGrid) Image full height 200.h cover
      SizedBox(2.w)
      Column spacing 2.h [
        Expanded ClipRRect(XRadius.mediaGrid) Image cover
        Expanded ClipRRect(XRadius.mediaGrid) Image cover
      ]
    ]
    height 200.h

  4 images:
    GridView 2×2 spacing 2, each cell ClipRRect(XRadius.mediaGrid) Image cover
    height 200.h

Tap any image → XImageLightbox (PageView full screen, swipe between images)

_PostVideoPlayer:
  Container ClipRRect(XRadius.media1)
  Stack [
    AspectRatio(16/9)
    VideoPlayer(controller) (autoplay muted when in viewport via VisibilityDetector)
    Positioned center: if !isPlaying → Container circle 42.r black50 Icon(play_arrow, white, 28.sp)
    Positioned bottom-left: duration Text 12.sp white w600 with shadow
    Positioned top-right: Icon(volume_off | volume_up, white, 16.sp) → toggle mute
  ]
```

### 5.4 Language Post Type Widgets

```
_PostPhraseCard:
  Container(
    margin top 8.h
    padding 14.h × 16.w
    decoration: BoxDecoration(
      color: XColors.phraseCardBg (dark: phraseCardBgDark)
      borderRadius: XRadius.quoteCard
      border: Border.all(color: XColors.phraseCardBorder, width: 1.5)
    )
    child: Column cross.start [
      Row [
        Container(
          padding: 3.h × 8.w, accent color, pill
          child: Text(languageCode, 9.sp, white, w700)
        )
        SizedBox(6.w)
        Text(languageName, 12.sp, grey)
        Spacer
        if audioUrl != null: IconButton(volume_up, accent, 18.sp) → TTS playback
      ]
      SizedBox(10.h)
      Text(nativeText, XTypography.nativePhrase(ctx))
      SizedBox(4.h)
      Text("/pronunciation/", XTypography.pronunciation(ctx))
      SizedBox(4.h)
      // Translation reveal (tap to show)
      GestureDetector(
        onTap: toggleTranslation
        if !translationVisible:
          Text("Tap to reveal translation", 13.sp, accent)
        else:
          Text(translation, XTypography.translation(ctx))
            .animate().fadeIn(duration: 200.ms)
      )
      SizedBox(8.h)
      Row [
        TextButton("Save to vocab list", accent, dosis 12.sp) → save vocab
        Spacer
        TextButton("Practice", accent, dosis 12.sp) → pronunciation screen
      ]
    ]
  )

_PostWordOfDayCard:
  Container(
    margin top 8.h
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [XColors.wordOfDayGrad1, XColors.wordOfDayGrad2],
        begin: Alignment.topLeft, end: Alignment.bottomRight
      )
      borderRadius: XRadius.quoteCard
    )
    padding: 16.h × 16.w
    child: Column cross.start [
      Row [
        Container(
          padding 3.h × 8.w, white.withOpacity(0.2), pill
          Row [Icon(auto_stories, white, 12.sp), SizedBox(4.w), Text("Word of the Day", 11.sp, white, w600)]
        )
        Spacer
        Container pill accent: Text(languageCode, 10.sp, white, w700)
      ]
      SizedBox(12.h)
      Text(nativeText, XTypography.wordOfDay(ctx))
      SizedBox(4.h)
      Text("/pronunciation/", 14.sp, white.withOpacity(0.75), italic, dosis)
      SizedBox(4.h)
      Text(translation, 15.sp, white.withOpacity(0.9), w500, dosis)
      SizedBox(8.h)
      if exampleSentence.isNotEmpty:
        Container(
          padding: 8.h × 12.w
          color: Colors.black.withOpacity(0.2)
          borderRadius: XRadius.quoteCard
          child: Column [
            Text(exampleSentence, 13.sp, white.withOpacity(0.85), italic)
            SizedBox(4.h)
            Text(exampleTranslation, 12.sp, white.withOpacity(0.65))
          ]
        )
      SizedBox(10.h)
      Row [
        if audioUrl != null:
          Container(
            padding: 6.h × 14.w, white.withOpacity(0.2), pill
            Row [Icon(volume_up, white, 16.sp), SizedBox(6.w), Text("Play", 12.sp, white, w600)]
          )
        SizedBox(8.w)
        Container(
          padding: 6.h × 14.w, white, pill
          child: Text("Save word", 12.sp, wordOfDayGrad1, w700)
          onTap: saveToVocab
        )
      ]
    ]
  )

_PostPollCard:
  Container(
    margin top 8.h
    padding 14.h × 14.w
    decoration: BoxDecoration(
      border: Border.all(color: XColors.divider, width: 1)
      borderRadius: XRadius.quoteCard
    )
    child: Column cross.start [
      Text(poll.question, 15.sp, textPrimary, w600)
      SizedBox(10.h)
      for each option (i):
        GestureDetector(onTap: hasVoted || poll.closed ? null : () → voteOnPoll(i))
        Container(
          height 40.h, margin bottom 6.h
          decoration: BoxDecoration(
            borderRadius: XRadius.pollBar,
            border: Border.all(color: divider, 1)
          )
          child: Stack [
            // Fill bar (shown after voting or poll closed)
            if hasVoted || poll.closed:
              FractionallySizedBox(widthFactor: option.percent / 100)
              Container(
                color: i == leadingOptionIndex ? XColors.pollLeader : XColors.pollBarBg
                borderRadius: XRadius.pollBar
              )
              .animate().scaleX(begin: 0, end: 1, duration: 600.ms, alignment: Alignment.centerLeft)

            // Option text
            Padding(horizontal: 12.w):
            Row [
              Text(option.text, 14.sp, textPrimary, w600)
              Spacer
              if hasVoted || poll.closed:
                Text("${option.percent}%", 13.sp, textSecondary)
              if userVotedOptionIndex == i:
                SizedBox(6.w) Icon(check_circle, accent, 16.sp)
            ]
          ]
        )
      SizedBox(4.h)
      Text(
        poll.closed ? "${poll.totalVotes} votes · Ended" : "${poll.totalVotes} votes · ${pollTimeRemaining(poll.endsAt)}",
        12.sp, textSecondary
      )
    ]
  )

_PostQuizCard:
  Container(
    margin top 8.h
    padding 14.h × 14.w
    decoration: BoxDecoration(
      color: XColors.quizBg (dark: quizBgDark)
      borderRadius: XRadius.quoteCard
      border: Border.all(color: XColors.quizAccent, width: 1.5)
    )
    child: Column cross.start [
      Row [
        Icon(bolt, quizAccent, 16.sp)
        SizedBox(4.w)
        Text("Language Quiz", 12.sp, quizAccent, w700)
        Spacer
        Container pill quizAccent: Text("+${xpReward} XP", 10.sp, white, w700)
      ]
      SizedBox(8.h)
      Text(quiz.question, 15.sp, textPrimary, w600)
      SizedBox(8.h)
      for each option (i):
        GestureDetector(onTap: hasAnswered ? null : () → answerQuiz(i))
        Container(
          height 40.h, margin bottom 6.h
          decoration: BoxDecoration(
            color: hasAnswered
              ? (i == quiz.correctIndex ? quizCorrect.withOpacity(0.1) :
                 i == userAnswerIndex   ? quizWrong.withOpacity(0.1) : transparent)
              : (userAnswerIndex == i ? quizAccent.withOpacity(0.1) : transparent),
            borderRadius: XRadius.pollBar,
            border: Border.all(
              color: hasAnswered
                ? (i == quiz.correctIndex ? quizCorrect :
                   i == userAnswerIndex   ? quizWrong : divider)
                : (userAnswerIndex == i ? quizAccent : divider),
              width: 1.5
            )
          )
          child: Padding(horizontal: 12.w) Row [
            Text(option, 14.sp, textPrimary)
            Spacer
            if hasAnswered && i == quiz.correctIndex: Icon(check_circle, quizCorrect, 18.sp)
            if hasAnswered && i == userAnswerIndex && i != quiz.correctIndex: Icon(cancel, quizWrong, 18.sp)
          ]
        )
      if hasAnswered && quiz.explanation.isNotEmpty:
        SizedBox(8.h)
        Container(
          padding 10.h × 12.w
          color: quizBg, borderRadius: XRadius.pollBar
          child: Text(quiz.explanation, 13.sp, textSecondary)
        ).animate().fadeIn(duration: 300.ms)
    ]
  )

_QuotePostCard:
  GestureDetector(onTap: → navigate to original post)
  Container(
    padding 10.h × 12.w
    decoration: BoxDecoration(
      border: Border.all(color: XColors.divider, 1)
      borderRadius: XRadius.quoteCard
    )
    child: Column cross.start [
      Row [
        CircleAvatar 16.r (quote author avatar)
        SizedBox(4.w)
        Text(displayName, 13.sp, textPrimary, w700, maxLines:1, overflow: ellipsis)
        SizedBox(3.w)
        Text("@username", 12.sp, textSecondary)
      ]
      SizedBox(4.h)
      Text(content, 14.sp, textPrimary, maxLines: 3, overflow: ellipsis)
    ]
  )
```

### 5.5 FeedComposeScreen

```
Scaffold:
  backgroundColor: scaffoldLight (dark: scaffoldDark)

AppBar:
  transparent, elevation 0
  leading: TextButton("Cancel", 16.sp, textSecondary) → pop
  actions: [
    _PostTypeChip(current type label)  // "Text" | "Phrase" | "Poll" | "Quiz" | "Word of Day"
    SizedBox(8.w)
    ElevatedButton("Post",
      backgroundColor: XColors.accent
      foregroundColor: white
      shape: pill, height 34.h, horizontal padding 18.w
      disabled: content empty OR over char limit
    )
  ]

Body: Column [

  // Author row
  Padding(horizontal: 16.w, top: 12.h):
    Row crossAxisAlignment.start [
      CircleAvatar 42.r (current user)
      SizedBox(10.w)
      Expanded Column [
        // Audience selector (optional)
        Container(
          padding 4.h × 10.w, borderRadius pill, border 1px divider
          child: Row [
            Text("Everyone", 13.sp, accent, w600)
            Icon(expand_more, accent, 16.sp)
          ]
        )
        SizedBox(8.h)

        // Main text field
        TextField(
          minLines: 3, maxLines: null
          style: XTypography.postBody(ctx)
          decoration: InputDecoration(
            hintText: "What's happening?",
            hintStyle: 15.sp textMuted,
            border: none, contentPadding: zero
          )
          onChanged: (val) {
            parseHashtags(val)
            parseMentions(val)
            updateCharCount(val.length)
          }
        )
        SizedBox(6.h)

        // Post type extra fields (shown depending on selected type)
        if type == 'phrase':
          _PhraseInputFields()
        if type == 'word_of_day':
          _WordOfDayInputFields()
        if type == 'poll':
          _PollBuilderWidget()
        if type == 'quiz':
          _QuizBuilderWidget()

        // Media previews
        if mediaFiles.isNotEmpty:
          _MediaPreviewGrid(files: mediaFiles)

        // Language tag (if user set language context)
        if languageCode != null:
          Row [
            Container(pill, accent.withOpacity(0.12))
              Text("🌍 $languageName", 12.sp, accent, w600)
            SizedBox(4.w)
            IconButton(close, grey, 14.sp) → clearLanguage
          ]
      ]
    ]

  // Thread divider (vertical line from avatar)
  // Handled via painting between avatar and content column

  Divider(color: divider, height: 0.5.h)

  // BOTTOM TOOLBAR
  Container(
    color: scaffoldLight (dark: scaffoldDark)
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h)
    child: Row [
      IconButton(image_outlined, 22.sp, accent)           → pick images (max 4)
      IconButton(video_library_outlined, 22.sp, accent)   → pick video
      IconButton(poll_outlined, 22.sp, accent)            → switch to poll type
      IconButton(emoji_events_outlined, 22.sp, accent)    → switch to quiz type
      IconButton(language, 22.sp, accent)                 → language picker sheet
      IconButton(location_on_outlined, 22.sp, grey)       → geolocation attach
      Spacer
      // Character count indicator
      if charCount > 260:
        Stack [
          SizedBox(28.r):
            CircularProgressIndicator(
              value: charCount / 280,
              color: charCount > 280 ? XColors.charCountOver :
                     charCount > 260 ? XColors.charCountWarn : XColors.accent,
              strokeWidth: 3,
              backgroundColor: dimLight
            )
          if charCount > 260:
            Center Text(
              (280 - charCount).toString(),
              10.sp,
              charCount > 280 ? XColors.charCountOver : XColors.charCountWarn
            )
        ]
    ]
  )
]

_PollBuilderWidget:
  Column [
    for each option (2 default, up to 4):
      TextField hint "Choice ${i+1}", border bottom 1px divider
    TextButton "+ Add choice", accent (if < 4 options)
    SizedBox(8.h)
    Row [
      Icon(access_time, grey, 14.sp)
      SizedBox(4.w)
      Text("Poll length", 13.sp, textSecondary)
      Spacer
      DropdownButton values: ["1h", "6h", "1d", "3d", "7d"] → sets poll.endsAt
    ]
  ]

_QuizBuilderWidget:
  Column [
    TextField "Question" hint, border bottom 1px
    SizedBox(8.h)
    Text("Options (tap ✓ to mark correct answer)", 12.sp, textSecondary)
    SizedBox(4.h)
    for each option (2 default, up to 4):
      Row [
        Radio(groupValue: correctIndex, value: i, activeColor: quizAccent, onChanged: setCorrect)
        Expanded TextField hint "Option ${i+1}"
      ]
    TextButton "+ Add option", quizAccent
    SizedBox(8.h)
    TextField "Explanation (shown after answer)" hint, maxLines 3
    DropdownButton XP reward: [5, 10, 15, 20] → sets quiz.xpReward
  ]
```

### 5.6 FeedPostDetailScreen (Thread view)

```
Scaffold:
  appBar: AppBar(
    title: Text("Post", XTypography.sectionHeader)
    leading: IconButton(arrow_back, textPrimary) → pop
    transparent, elevation 0
  )

Body: CustomScrollView [
  SliverToBoxAdapter:
    // ANCESTOR POSTS (reply chain above focal post)
    for each ancestor:
      Column [
        // ancestor XPostCard with isPartOfThread: true
        XPostCard(post: ancestor, isPartOfThread: true, isLastInThread: false)
      ]

  SliverToBoxAdapter:
    // FOCAL POST (larger rendering)
    _FocalPostCard(post: focalPost)

  SliverToBoxAdapter:
    // REPLY COMPOSER
    Container(
      padding: 12.h × 16.w
      borderTop: 0.5px divider
      child: Row [
        CircleAvatar 36.r (current user)
        SizedBox(10.w)
        Expanded TextField(
          hintText: "Post your reply"
          style: postBody, border: none
        )
        ElevatedButton("Reply", accent pill)
      ]
    )
    Divider 0.5px divider

  // REPLIES (SliverList)
  SliverList builder: replies.length
    each: XPostCard(post: reply)

_FocalPostCard:
  Padding(horizontal: 16.w, vertical: 12.h):
  Column [
    Row [
      CircleAvatar 46.r
      SizedBox(10.w)
      Column crossAxisAlignment.start [
        Text(displayName, 16.sp, textPrimary, w700)
        if verified: _VerifiedBadge() inline with name
        Text("@username", 14.sp, textSecondary)
      ]
      Spacer
      _PostMoreMenu(post)
    ]
    SizedBox(12.h)
    if replyToUsername != null: Text("Replying to @$u", 14.sp, linkColor)
    _XRichText(content, 17.sp body, 15.sp links)
    SizedBox(10.h)
    // Full media
    if hasMedia: _PostMediaGrid(urls)
    SizedBox(10.h)
    // Timestamp + client source
    Row [
      Text(formattedDateTime, 15.sp, textSecondary)
      Text(" · ", textSecondary)
      Text("LingAfriq", 15.sp, textSecondary)
    ]
    Divider(color: divider, height: 16.h)
    // Engagement counts row
    Row spacing 16.w [
      if post.repostCount > 0: Row [Text(repostCount, 15.sp, textPrimary, w700), SizedBox(3.w), Text("Reposts", 14.sp, textSecondary)]
      if post.quoteCount > 0: Row [Text(quoteCount, 15.sp, textPrimary, w700), SizedBox(3.w), Text("Quotes", 14.sp, textSecondary)]
      if post.likeCount > 0: Row [Text(likeCount, 15.sp, textPrimary, w700), SizedBox(3.w), Text("Likes", 14.sp, textSecondary)]
      if post.bookmarkCount > 0: Row [Text(bookmarkCount, 15.sp, textPrimary, w700), SizedBox(3.w), Text("Bookmarks", 14.sp, textSecondary)]
    ]
    Divider(color: divider, height: 16.h)
    // Action row (full)
    Row mainAxisAlignment.spaceAround [
      _PostAction(chat_bubble_outline, replyCount, onTap: openReplySheet)
      _PostAction(repeat_rounded, repostCount, isActive: isReposted, activeColor: repostActive)
      _PostAction(isLiked ? favorite_rounded : favorite_border_rounded, likeCount, isActive: isLiked, activeColor: likeActive)
      _PostAction(isBookmarked ? bookmark_rounded : bookmark_border_rounded, null, isActive: isBookmarked, activeColor: bookmarkActive)
      _PostAction(share_outlined, null)
    ]
    Divider(color: divider, height: 8.h)
  ]
```

### 5.7 FeedExploreScreen

```
Scaffold backgroundColor: scaffoldLight (dark: scaffoldDark)

AppBar:
  title: Text("Explore", XTypography.sectionHeader)
  background transparent

Body: CustomScrollView [

  // Sticky search bar
  SliverAppBar(
    floating: true, snap: true, pinned: false
    toolbarHeight: 52.h
    child: Padding(horizontal: 16.w, vertical: 6.h):
      GestureDetector(
        onTap: → navigate to feed-search
        Container(
          height 40.h, decoration boxDecoration:
            color dimLight (dark: surfaceDark), borderRadius 28.r
          Row [
            SizedBox(12.w)
            Icon(search, textSecondary, 20.sp)
            SizedBox(8.w)
            Text("Search LingaFriq", 15.sp, textMuted)
          ]
        )
      )
  )

  // Trending hashtags section
  SliverPadding padding 16.w:
    SliverToBoxAdapter:
      Text("Trending now", XTypography.sectionHeader)
      SizedBox(12.h)
      Column [
        for each trend in top10:
          _TrendTile(trend)
      ]

  // Language rooms section
  SliverPadding padding EdgeInsets.fromLTRB(16,8,16,0):
    SliverToBoxAdapter:
      Row [
        Text("Language Rooms", XTypography.sectionHeader)
        Spacer
        TextButton("See all", accent, 13.sp) → navigate to feed-language-rooms
      ]
      SizedBox(8.h)
    SliverToBoxAdapter:
      SizedBox(height: 120.h)
      ListView.builder horizontal, itemCount: rooms.length:
        each room: _AudioRoomCard(room)
        spacing 10.w, padding horizontal 16.w

  // Word of Day spotlight
  SliverPadding padding 16.w:
    SliverToBoxAdapter:
      Text("Word of the Day", XTypography.sectionHeader)
      SizedBox(8.h)
      Container accent gradient card:
        (use _PostWordOfDayCard expanded version, full width)

  // Suggested users to follow
  SliverPadding padding EdgeInsets.fromLTRB(16,16,16,0):
    SliverToBoxAdapter: Text("Who to follow", XTypography.sectionHeader) SizedBox(8.h)
    SliverList delegate: suggestedUsers.length:
      each: _SuggestedUserTile(user)

  // Language communities
  SliverPadding padding 16.w:
    SliverToBoxAdapter:
      Text("Language Communities", XTypography.sectionHeader)
      SizedBox(8.h)
    SliverGrid(crossAxisCount: 2, spacing 10):
      each language: _LanguageCommunityCard(language)
]

_TrendTile:
  Padding(vertical 12.h):
  Column crossAxisAlignment.start [
    Text(category, 12.sp, textSecondary)   // e.g. "Language · Trending"
    Text("#${trend.tag}", XTypography.trendTag)
    Text("${formatCount(trend.weeklyCount)} posts", XTypography.trendCount)
  ]
  Divider 0.5px

_AudioRoomCard:
  Container(
    width 200.w, padding 14.h × 14.w
    decoration BoxDecoration(color surfaceCard, borderRadius XRadius.roomCard, boxShadow XShadows.card)
    child: Column crossAxisAlignment.start [
      Row [
        Container pill liveRed: Row [Icon(radio_button_checked, white, 10.sp), SizedBox(3.w), Text("LIVE", 9.sp, white, w800)]
        Spacer
        Container pill accent: Text(languageCode, 9.sp, white, w700)
      ]
      SizedBox(8.h)
      Text(room.name, 14.sp, textPrimary, w700, maxLines: 2)
      SizedBox(6.h)
      Row [
        // Overlapping avatars (max 3)
        SizedBox(width: 54.w):
          Stack [
            Positioned(left:0):  CircleAvatar 22.r
            Positioned(left:16): CircleAvatar 22.r border white 1.5px
            Positioned(left:32): CircleAvatar 22.r border white 1.5px
          ]
        SizedBox(6.w)
        Text("${room.participantCount} listening", 11.sp, textSecondary)
      ]
      SizedBox(8.h)
      Container(
        height 32.h, fullWidth, accent color, pill
        child: Center Text("Join Room", 12.sp, white, w700)
      )
    ]
  )

_SuggestedUserTile:
  Container(
    padding 12.h × 16.w, color cardLight (dark: cardDark)
    child: Row [
      CircleAvatar 44.r (user avatar)
      SizedBox(10.w)
      Expanded Column crossAxisAlignment.start [
        Row [
          Text(displayName, 14.sp, textPrimary, w700)
          if verified: _VerifiedBadge()
        ]
        Text("@$username", 13.sp, textSecondary)
        if isFollowsMe: Text("Follows you", 12.sp, textMuted)
        if sharedLanguages.isNotEmpty:
          Row [Icon(language, accent, 12.sp), SizedBox(3.w), Text("Learning ${sharedLang}", 11.sp, accent)]
      ]
      _FollowButton(userId: user.id, isFollowing: user.isFollowing)
    ]
  )

_FollowButton:
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: isFollowing ? transparent : XColors.accent
      foregroundColor: isFollowing ? textPrimary : white
      shape: pill
      side: isFollowing ? BorderSide(color: divider) : BorderSide.none
      padding: EdgeInsets.symmetric(horizontal:14.w, vertical: 6.h)
      minimumSize: Size(72.w, 32.h)
    )
    child: Text(isFollowing ? "Following" : "Follow", 13.sp, w700)
    onPressed: toggleFollow
  )
  On hover/focus of "Following": show "Unfollow" in red (onHover logic)
```

### 5.8 FeedNotificationsScreen

```
Scaffold:
  appBar: AppBar(
    title: Text("Notifications", XTypography.sectionHeader)
    transparent, elevation 0
    actions: [TextButton("Mark all read", accent, 13.sp)]
  )

TabBar (sticky):
  tabs: ["All", "Mentions"]
  indicator: XColors.accent 2.5px bottom underline

Body TabBarView:
  each tab: ListView.builder:
    each notification: _NotificationTile(notif)
    Divider 0.5px divider

_NotificationTile:
  GestureDetector(onTap: navigateToContent(notif))
  Container(
    color: notif.isRead ? transparent : XColors.accentLight.withOpacity(0.5)
    padding: 12.h × 16.w
    child: Row crossAxisAlignment.start [
      Stack [
        CircleAvatar 44.r (actor avatar)
        // Notification type icon overlay (bottom-right of avatar)
        Positioned(bottom: 0, right: 0):
          Container(
            width 20.r, height 20.r
            color: _notifTypeColor(notif.type)  // like=likeActive, repost=repostActive, etc.
            shape: BoxShape.circle
            child: Icon(_notifTypeIcon(notif.type), white, 11.sp)
          )
      ]
      SizedBox(10.w)
      Expanded Column crossAxisAlignment.start [
        // Actor name + action text (rich)
        RichText [
          TextSpan(displayName, 14.sp, textPrimary, w700)
          TextSpan(" ${_notifVerb(notif.type)}", 14.sp, textPrimary)
        ]
        SizedBox(2.h)
        if notif.postPreview != null:
          Text(notif.postPreview, 13.sp, textSecondary, maxLines: 2, overflow: ellipsis)
        SizedBox(2.h)
        Text(timeAgo(notif.createdAt), 12.sp, textMuted)
      ]
      if notif.postThumbnail != null:
        ClipRRect(XRadius.mediaGrid)
        Image.network(notif.postThumbnail, width: 44.r, height: 44.r, fit: BoxFit.cover)
    ]
  )

_notifTypeColor: { like: likeActive, repost: repostActive, reply: accent, follow: quizAccent, mention: accent }
_notifTypeIcon:  { like: favorite_rounded, repost: repeat_rounded, reply: chat_bubble_rounded, follow: person_add_rounded, mention: alternate_email }
_notifVerb:      { like: "liked your post", repost: "reposted your post", reply: "replied to your post", follow: "followed you", mention: "mentioned you" }
```

### 5.9 FeedUserProfileScreen

```
Scaffold backgroundColor: scaffoldLight (dark: scaffoldDark)

Body: NestedScrollView(
  headerSliverBuilder: [
    SliverAppBar(
      expandedHeight: 200.h
      pinned: true, floating: false
      flexibleSpace: FlexibleSpaceBar(
        background: Stack [
          // Cover photo (full bleed, 200.h)
          coverUrl != null
            ? Image.network(coverUrl, fit: BoxFit.cover, width: full, height: 200.h)
            : Container(
                height: 200.h
                gradient: LinearGradient(wordOfDayGrad1 → wordOfDayGrad2, topLeft→bottomRight)
              )
          // Gradient scrim on bottom of cover
          Positioned(bottom: 0, left: 0, right: 0, height: 80.h):
            DecoratedBox gradient transparent → scaffoldLight/Dark
        ]
      )
      leading: IconButton(arrow_back, white) → pop
      actions: [IconButton(more_horiz, white)]
    )
  ]
  body: CustomScrollView [
    SliverToBoxAdapter:
      // Profile header block (below cover)
      Padding horizontal 16.w:
        // Avatar (overlaps cover)
        Transform.translate(offset: Offset(0, -30.h)):
          CircleAvatar(radius: 38.r, backgroundImage: NetworkImage(avatarUrl),
            border: Border.all(color: scaffoldLight/Dark, width: 3))
        // Actions row (Follow / Edit profile)
        Row crossAxisAlignment.start [
          SizedBox(80.w + spacing)  // space for avatar
          Spacer
          if isOwnProfile:
            OutlinedButton("Edit profile", accent, pill, 13.sp)
          else:
            Row spacing 8.w [
              IconButton(mail_outline, border 1px divider, 20.sp) → open DM
              _FollowButton(userId, isFollowing)
            ]
        ]
        // Name + bio block
        SizedBox(8.h)
        Row [
          Text(displayName, 18.sp, textPrimary, w800)
          SizedBox(4.w)
          if verified: _VerifiedBadge()
        ]
        Text("@$username", 14.sp, textSecondary)
        SizedBox(6.h)
        if bio.isNotEmpty: Text(bio, 14.sp, textPrimary, maxLines: 3)
        SizedBox(6.h)
        // Join date
        Row [Icon(calendar_today_outlined, 14.sp, textSecondary), SizedBox(4.w), Text("Joined ${joinDate}", 13.sp, textSecondary)]
        SizedBox(6.h)
        // Language tags
        Row wrap spacing 6.w [
          for each learningLang:
            Container(
              padding 3.h × 8.w, accent.withOpacity(0.12), pill
              child: Row [Text(flag, 12.sp), SizedBox(3.w), Text(langName, 11.sp, accent, w600)]
            )
        ]
        SizedBox(8.h)
        // Followers/Following counts
        Row spacing 16.w [
          GestureDetector(onTap: showFollowing):
            Row [Text(followingCount, 14.sp, textPrimary, w700), SizedBox(4.w), Text("Following", 13.sp, textSecondary)]
          GestureDetector(onTap: showFollowers):
            Row [Text(followerCount, 14.sp, textPrimary, w700), SizedBox(4.w), Text("Followers", 13.sp, textSecondary)]
        ]
        SizedBox(12.h)

    // Tab bar (pinned)
    SliverPersistentHeader(pinned: true,
      delegate: _TabBarDelegate(
        tabBar: TabBar(
          controller: _tabController,
          tabs: ["Posts", "Replies", "Media", "Likes"],
          labelStyle: XTypography.tabLabel(ctx, true),
          unselectedLabelStyle: XTypography.tabLabel(ctx, false),
          indicator: UnderlineTabIndicator(borderSide: BorderSide(accent, 2.5))
        )
      )
    )

    // Post list (lazy)
    SliverFillRemaining:
      TabBarView [
        each tab: ListView.builder → XPostCard items
      ]
  ]
)
```

---

## 6. REPOST SHEET (BottomSheet)

```
ModalBottomSheet borderRadius: SnapRadius.sheet, background surfaceDark (dark) / white (light)
height: 140.h

Column [
  Drag handle 4.h × 40.w centered, grey, pill, margin top 8.h
  SizedBox 8.h
  ListTile(
    leading: Icon(repeat_rounded, 22.sp, repostActive)
    title: Text("Repost", 15.sp, textPrimary, w600)
    onTap: → repost (no quote) → dismiss sheet
  )
  ListTile(
    leading: Icon(edit_rounded, 22.sp, accent)
    title: Text("Quote Post", 15.sp, textPrimary, w600)
    subtitle: Text("Add your own comment", 12.sp, textSecondary)
    onTap: → navigate to compose with quoteOfId → dismiss sheet
  )
]
If already reposted, first tile shows "Undo repost" with red icon.
```

---

## 7. ANIMATIONS (flutter_animate)

```dart
// Post card entrance (feed scroll):
XPostCard(...).animate(delay: (index * 30).ms)
  .fadeIn(duration: 200.ms)
  .slideY(begin: 0.04, duration: 200.ms, curve: Curves.easeOut)

// New post chip from socket (slide down from top):
newPostsChip.animate()
  .slideY(begin: -1.2, end: 0, duration: 280.ms, curve: Curves.easeOut)
  .fadeIn(duration: 200.ms)

// Like button heart tap (bounce + color):
likeIcon.animate(trigger: onLikeTap)
  .scaleXY(begin: 1.0, end: 1.4, duration: 100.ms, curve: Curves.easeOut)
  .then()
  .scaleXY(begin: 1.4, end: 0.9, duration: 80.ms)
  .then()
  .scaleXY(begin: 0.9, end: 1.0, duration: 100.ms, curve: Curves.elasticOut)
// Color swap via AnimatedSwitcher crossfade

// Repost icon rotate:
repostIcon.animate(trigger: onRepostTap)
  .rotate(begin: 0, end: 0.25, duration: 200.ms, curve: Curves.easeInOut)
  .then().rotate(begin: 0.25, end: 0, duration: 150.ms)

// Tab underline slide:
// Use DefaultTabController + custom indicator or AnimatedContainer
// indicator moves with Curves.easeInOut 200.ms

// Poll bar fill:
pollBar.animate()
  .custom(
    duration: 600.ms,
    curve: Curves.easeOut,
    builder: (ctx, value, child) => FractionallySizedBox(widthFactor: value * targetPercent / 100, child: child)
  )

// Quiz reveal animation:
quizExplanation.animate()
  .fadeIn(duration: 300.ms)
  .slideY(begin: 0.08, duration: 300.ms, curve: Curves.easeOut)

// Compose post screen enter:
composeBody.animate()
  .fadeIn(duration: 150.ms)

// Notification tile (unread highlight fade):
notifTile.animate()
  .fadeIn(duration: 180.ms)
  .slideX(begin: -0.04, duration: 180.ms, curve: Curves.easeOut)

// Word of Day card entrance:
wordOfDayCard.animate()
  .fadeIn(duration: 250.ms)
  .scaleXY(begin: const Offset(0.97, 0.97), end: Offset(1,1), duration: 250.ms, curve: Curves.easeOut)

// Profile screen cover parallax:
// Use FlexibleSpaceBar built-in background parallax

// Follow button state change:
followButton.animate(trigger: onFollowToggle)
  .scaleXY(begin: 1.0, end: 0.93, duration: 80.ms)
  .then()
  .scaleXY(begin: 0.93, end: 1.0, duration: 120.ms, curve: Curves.elasticOut)

// Bottom nav icon tap:
navIcon.animate(trigger: onTap)
  .scaleXY(begin: 1.0, end: 1.2, duration: 100.ms, curve: Curves.easeOut)
  .then()
  .scaleXY(begin: 1.2, end: 1.0, duration: 150.ms, curve: Curves.elasticOut)

// Thread connector line draw:
threadLine.animate()
  .custom(
    duration: 300.ms, curve: Curves.easeIn,
    builder: (ctx, v, child) => FractionallySizedBox(heightFactor: v, alignment: Alignment.topCenter, child: child)
  )
```

---

## 8. DARK MODE MAPPING

| Element                  | Light                 | Dark                  |
|---|---|---|
| Scaffold bg              | `0xFFFFFFFF`          | `0xFF000000`          |
| Card bg                  | `0xFFFFFFFF`          | `0xFF1E2128`          |
| Surface                  | `0xFFF7F9F9`          | `0xFF16181C`          |
| Post body text           | `0xFF0F1419`          | `0xFFE7E9EA`          |
| Secondary text           | `0xFF536471`          | `0xFF71767B`          |
| Dividers                 | `0xFFEFF3F4`          | `0xFF2F3336`          |
| Thread lines             | `0xFFCFD9DE`          | `0xFF2F3336`          |
| Input border             | `0xFFE1E8ED`          | `0xFF2F3336`          |
| Accent (brand)           | `0xFFE05C2A`          | `0xFFE05C2A`          |
| Like active              | `0xFFE11D48`          | `0xFFE11D48`          |
| Repost active            | `0xFF16A34A`          | `0xFF22C55E`          |
| Poll track bg            | `0xFFE9E9E9`          | `0xFF2F3336`          |
| Quote card bg            | `0xFFFFFFFF`          | `0xFF1E2128`          |
| Phrase card bg           | `0xFFFFF3EE`          | `0xFF2D1A10`          |
| Quiz card bg             | `0xFFF5F3FF`          | `0xFF1E1B2E`          |

---

## 9. COMPLETE FLUTTER FILE LIST FOR UI

- `lib/styles/x_colors.dart`
- `lib/styles/x_typography.dart`
- `lib/styles/x_spacing.dart`
- `lib/screens/feed/feed_home_screen.dart`
- `lib/screens/feed/feed_compose_screen.dart`
- `lib/screens/feed/feed_post_detail_screen.dart`
- `lib/screens/feed/feed_user_profile_screen.dart`
- `lib/screens/feed/feed_explore_screen.dart`
- `lib/screens/feed/feed_notifications_screen.dart`
- `lib/screens/feed/feed_bookmarks_screen.dart`
- `lib/screens/feed/feed_lists_screen.dart`
- `lib/screens/feed/feed_list_detail_screen.dart`
- `lib/screens/feed/feed_hashtag_screen.dart`
- `lib/screens/feed/feed_search_screen.dart`
- `lib/screens/feed/feed_language_rooms_screen.dart`
- `lib/screens/feed/feed_language_room_screen.dart`
- `lib/widgets/feed/x_post_card.dart`
- `lib/widgets/feed/x_post_action.dart`
- `lib/widgets/feed/x_post_media_grid.dart`
- `lib/widgets/feed/x_post_video_player.dart`
- `lib/widgets/feed/x_phrase_card.dart`
- `lib/widgets/feed/x_word_of_day_card.dart`
- `lib/widgets/feed/x_poll_card.dart`
- `lib/widgets/feed/x_quiz_card.dart`
- `lib/widgets/feed/x_quote_card.dart`
- `lib/widgets/feed/x_repost_sheet.dart`
- `lib/widgets/feed/x_reply_composer.dart`
- `lib/widgets/feed/x_verified_badge.dart`
- `lib/widgets/feed/x_rich_text.dart`
- `lib/widgets/feed/x_image_lightbox.dart`
- `lib/widgets/feed/x_notification_tile.dart`
- `lib/widgets/feed/x_trend_tile.dart`
- `lib/widgets/feed/x_audio_room_card.dart`
- `lib/widgets/feed/x_suggested_user_tile.dart`
- `lib/widgets/feed/x_follow_button.dart`
- `lib/widgets/feed/x_post_card_skeleton.dart`
- `lib/widgets/feed/x_nav_bar.dart`
- `lib/widgets/feed/x_language_community_card.dart`
