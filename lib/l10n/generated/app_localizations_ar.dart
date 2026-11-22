// ignore_for_file: text_direction_code_point_in_literal, text_direction_code_point_in_comment

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'LingAfriq';

  @override
  String get welcomeMessage => 'مرحباً بك في LingAfriq';

  @override
  String get continueButton => 'متابعة';

  @override
  String get startLearning => 'ابدأ التعلم';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get errorOccurred => 'حدث خطأ';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get home => 'الرئيسية';

  @override
  String get learn => 'تعلم';

  @override
  String get games => 'ألعاب';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get lessons => 'الدروس';

  @override
  String get quizzes => 'الاختبارات';

  @override
  String get takeQuiz => 'أخذ اختبار';

  @override
  String get takeLesson => 'أخذ درس';

  @override
  String get dailyStreak => 'السلسلة اليومية';

  @override
  String daysStreak(int count) {
    return '$count يوم';
  }

  @override
  String xpEarned(int count) {
    return '$count نقطة خبرة';
  }

  @override
  String get level => 'المستوى';

  @override
  String get beginner => 'مبتدئ';

  @override
  String get intermediate => 'متوسط';

  @override
  String get advanced => 'متقدم';

  @override
  String get correct => 'صحيح!';

  @override
  String get incorrect => 'غير صحيح';

  @override
  String get next => 'التالي';

  @override
  String get back => 'رجوع';

  @override
  String get skip => 'تخطي';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get done => 'تم';

  @override
  String get submit => 'إرسال';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signup => 'إنشاء حساب';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get congratulations => 'تهانينا!';

  @override
  String get lessonComplete => 'اكتمل الدرس!';

  @override
  String get quizComplete => 'اكتمل الاختبار!';

  @override
  String get accuracy => 'الدقة';

  @override
  String get score => 'النتيجة';

  @override
  String get aiTutor => 'معلم الذكاء الاصطناعي';

  @override
  String get cultureMagazine => 'مجلة الثقافة';

  @override
  String get tribes => 'القبائل';

  @override
  String get leaderboard => 'لوحة المتصدرين';

  @override
  String get flbHeritageTitle => 'FLB Heritage';

  @override
  String get flbHeritageSearchHint => 'Search title, country, or tags';

  @override
  String get flbHeritageEmptyMessage =>
      'No entries match your search. Try another keyword or pull to refresh.';

  @override
  String get flbHeritageLoadError =>
      'Could not load heritage archive. Pull to retry.';

  @override
  String get flbHeritageRefresh => 'Refresh';

  @override
  String get flbHeritageDetailTitle => 'Heritage';

  @override
  String get flbHeritageMissingContent => 'Missing heritage content';

  @override
  String get tooltipFlbHeritageArchive => 'FLB Heritage archive';

  @override
  String get tooltipTribeDiscovery => 'Tribe discovery';

  @override
  String get drawerFlbHeritageArchive => 'FLB Heritage Archive';

  @override
  String get tooltipTribes => 'Tribes';

  @override
  String get magazineKeyTakeaways => 'Key takeaways';

  @override
  String get magazineRelatedTopics => 'Related topics';

  @override
  String get magazineSourceAndLicense => 'Source & license';

  @override
  String magazineReadingTime(int minutes) {
    return '$minutes min read';
  }

  @override
  String get gameTutorialGotIt => 'Got it';

  @override
  String get gameTutorialHowToPlay => 'How to play';

  @override
  String get gamekitFeedbackTitle => 'Your answer';

  @override
  String get gamekitFeedbackInstructions => 'Tap an answer when you are ready.';

  @override
  String get gamekitFeedbackCorrect => 'Nice one!';

  @override
  String get gamekitFeedbackWrong => 'Not quite — try the next one.';

  @override
  String get gamekitFeedbackPending => 'Checking your answer…';

  @override
  String get gamekitFeedbackWhyWrong => 'Why was I wrong?';

  @override
  String get gamekitFeedbackPracticeLabel => 'Practice mode';

  @override
  String get gamekitPracticeModeTitle => 'Practice round';

  @override
  String get gamekitPracticeModeInstructions =>
      'Listen, repeat, and compare. Nothing here is scored.';

  @override
  String get gamekitPracticeModeWhyWrong => 'Tips';

  @override
  String get gamekitPracticeModePracticeLabel => 'Practice, not scored';

  @override
  String get gamekitPracticeModeError =>
      'Audio is not ready yet. You can still read the phrase.';

  @override
  String get gamesGreetingGauntletTitle => 'Greeting Gauntlet';

  @override
  String get gamesGreetingGauntletInstructions =>
      'Read the scene, pick the greeting and gesture that fit — before the timer runs out.';

  @override
  String get gamesGreetingGauntletWhyWrong =>
      'Listen to why that greeting or gesture did not match the moment.';

  @override
  String get gamesGreetingGauntletPracticeLabel =>
      'Practice — cultural rounds do not affect rank until scoring is verified.';

  @override
  String get gamesGreetingGauntletError =>
      'We could not load greeting scenarios for this language yet. Try again when you are online.';

  @override
  String get gamesGameMasteryResultsTitle => 'Round complete';

  @override
  String get gamesGameMasteryResultsInstructions =>
      'Here is how this round touched your skills in the learner model.';

  @override
  String get gamesGameMasteryResultsSkillsHeading => 'Skills this round';

  @override
  String get gamesGameMasteryResultsNoChange => 'No change';

  @override
  String get gamesGameMasteryResultsImproved => 'Improved';

  @override
  String get gamesGameMasteryResultsDeclined => 'Needs practice';

  @override
  String get gamesGameMasteryResultsPracticeLabel => 'Practice, not scored';

  @override
  String get gamesGameMasteryResultsError =>
      'Skill details are still syncing. Your practice was saved.';

  @override
  String get gamesGameMasteryResultsDone => 'Back to Play';

  @override
  String get gamesMasteryMapTitle => 'Mastery map';

  @override
  String get gamesMasteryMapInstructions =>
      'See which arcade games moved each skill in your learner model.';

  @override
  String get gamesMasteryMapGamesHeading => 'Games that moved this skill';

  @override
  String get gamesMasteryMapNotMeasured => 'Not measured';

  @override
  String get gamesMasteryMapUnsure => 'Unsure';

  @override
  String get gamesMasteryMapPracticeLabel => 'Practice, not scored';

  @override
  String get gamesMasteryMapError =>
      'We could not load your mastery map. Finish a scored arcade round and try again.';

  @override
  String get gamekitFeedbackError => 'We could not score that turn. Try again.';

  @override
  String gamekitFeedbackStreak(int count) {
    return '$count in a row!';
  }

  @override
  String chatPeerTyping(String name) {
    return '$name is typing…';
  }

  @override
  String get polieTranslationSourceLabel => 'From';

  @override
  String get polieTranslationTargetLabel => 'To';

  @override
  String get polieConversationIncludeEnglishTranslations =>
      'English translations';

  @override
  String get polieTutorSavedCards => 'Saved cards';

  @override
  String get polieTutorSaveCard => 'Save';

  @override
  String get polieTutorRemoveSavedCard => 'Remove';

  @override
  String get polieTutorNoSavedCardsYet => 'No saved cards yet.';

  @override
  String get liveTranslateTitle => 'Live translate';

  @override
  String get liveTranslateEndSession => 'End session';

  @override
  String liveTranslateStatus(Object status) {
    return 'Status: $status';
  }

  @override
  String get liveTranslateSource => 'Source';

  @override
  String get liveTranslateTranslation => 'Translation';

  @override
  String get liveTranslateSourceLanguageLabel =>
      'Source language (e.g. english)';

  @override
  String get liveTranslateTargetLanguageLabel =>
      'Target language (e.g. yoruba)';

  @override
  String get liveTranslateStartSession => 'Start session';

  @override
  String get liveTranslateStarting => 'Starting…';

  @override
  String get liveTranslateReconnect => 'Reconnect';

  @override
  String get liveTranslateListen => 'Listen';

  @override
  String get liveTranslateStopListening => 'Stop listening';

  @override
  String get liveTranslateInterruptBargeIn => 'Interrupt / barge-in';

  @override
  String get liveTranslatePlaceholderDash => '…';

  @override
  String get liveTranslateSpeechUnavailable =>
      'Speech input did not start. This phone cannot run live speech here. Type your phrase or use another device.';

  @override
  String get liveTranslateMicPermissionRequired =>
      'The mic is blocked. LingAfriq needs the mic to hear you. Open Settings and allow the mic.';

  @override
  String get liveTranslateInvalidSession =>
      'Could not start live translate. The server sent an invalid session. Tap Reconnect and try again.';

  @override
  String get liveTranslateStartSessionFirst =>
      'Listening is not active yet. You have not started a session. Tap Start session, then speak.';

  @override
  String get liveTranslateConnectionLost =>
      'Connection lost. Your network cut out. Tap reconnect to try again.';

  @override
  String liveTranslateSocketError(Object error) {
    return 'Could not connect for live translate. The socket failed: $error. Check your network and tap Reconnect.';
  }

  @override
  String get liveTranslateSessionFailed =>
      'Could not start a live translate session. The server rejected the request. Wait a moment and try again.';

  @override
  String liveTranslateCouldNotPlayAudio(Object error) {
    return 'Could not play the translation audio. Playback failed: $error. Tap Hear it again or check your volume.';
  }

  @override
  String get liveTranslateSessionError =>
      'Live translate hit a session error. Something went wrong on the connection. Leave the session and start again.';

  @override
  String get liveTranslateDefaultAudioMime => 'audio/wav';

  @override
  String get gameWordMatchConnectMeaningTitle => 'Connect the Meaning';

  @override
  String get gameWordMatchConnectMeaningSubtitle =>
      'Tap a word to hear its voice, then match it to its anchor.';

  @override
  String get gameWordMatchEnglishLabel => 'English';

  @override
  String get content_coming_soon => 'Coming Soon';

  @override
  String get content_not_available_yet => 'This content is not available yet.';

  @override
  String get content_coming_soon_badge => 'Soon';

  @override
  String get pron_practice_mode => 'Practice mode';

  @override
  String get pron_scoring_soon => 'Scoring coming soon';

  @override
  String get pron_unavailable =>
      'We could not score your speech. The scorer is temporarily unavailable. Try again in a moment; no score is shown.';

  @override
  String get contentPublishAction => 'Publish';

  @override
  String get contentPublishDone => 'Published';

  @override
  String get persona_ai_disclosure =>
      'This is an AI recreation based on sources.';

  @override
  String get personaBadgeAiRecreation => 'AI recreation';

  @override
  String personaOpeningHowBuilt(String personaName, String sourceSummary) {
    return 'AI version of $personaName from $sourceSummary.';
  }

  @override
  String get personaVoiceSynthesised => 'Synthesised voice';

  @override
  String get persona_error_retry =>
      'Couldn\'t reach the persona. The network or server timed out. Retry when you\'re ready.';

  @override
  String get personaChipSource => 'Source';

  @override
  String get personaChipInferred => 'Inferred';

  @override
  String get personaChipLegend => 'Legend';

  @override
  String get personaChipLoading => 'Checking sources';

  @override
  String get personaChipNoSource => 'Source unavailable';

  @override
  String get personaChipSourceSemantics =>
      'Documented claim. Source card ready. Double tap to open it.';

  @override
  String get personaChipInferredSemantics =>
      'Inferred claim. Drawn from context, not a direct citation.';

  @override
  String get personaChipLegendSemantics =>
      'Legend claim. Oral tradition, not one document.';

  @override
  String get personaChipNoSourceSemantics =>
      'Documented claim. Source card is not ready yet.';

  @override
  String get persona_dialogue_welcome =>
      'Eh, welcome back, friend. The path waits for you today.';

  @override
  String get labelBetaCopy =>
      'AI-assisted, machine-checked. Spotted a problem? Tell us.';

  @override
  String get labelNative => 'Native-verified';

  @override
  String get labelExpert => 'Expert-reviewed';

  @override
  String get audioSynthetic => 'Synthetic voice';

  @override
  String avatarSemanticsExpression(String name, String expression) {
    return '$name looks $expression';
  }

  @override
  String avatarSemanticsExpressionActivity(
    String name,
    String expression,
    String activity,
  ) {
    return '$name looks $expression and is $activity';
  }

  @override
  String get avatarEditorTitle => 'Your avatar';

  @override
  String get avatarEditorLoadError =>
      'We could not load avatar styles. Try again shortly.';

  @override
  String get avatarEditorSkinTone => 'Skin tone';

  @override
  String get avatarEditorSlotHair => 'Hair';

  @override
  String get avatarEditorSlotHeadwear => 'Headwear';

  @override
  String get avatarEditorSlotTop => 'Top';

  @override
  String get avatarEditorSlotBottom => 'Bottom';

  @override
  String get avatarEditorSlotAccessory => 'Accessory';

  @override
  String get avatarEditorSlotProp => 'Prop';

  @override
  String avatarItemLocked(String reason) {
    return 'Locked — $reason';
  }

  @override
  String get avatarItemLockedTitle => 'This look is still locked';

  @override
  String avatarItemNote(String note) {
    return '$note';
  }

  @override
  String get avatarItemLockedReasonGreetings =>
      'Finish the Greetings & respect can-do to unlock this headwear.';

  @override
  String get avatarItemLockedReasonTone =>
      'Pass a tone checkpoint to unlock this prop.';

  @override
  String get avatarItemLockedReasonCulturalReview =>
      'This garment unlocks after our cultural review gate clears.';

  @override
  String get avatarItemLockedReasonIsicholo =>
      'Isicholo needs cultural context — unlock with guided quest content.';

  @override
  String get avatarItemLockedReasonMastery =>
      'Earn this look through a mastery milestone, not the shop.';

  @override
  String get avatarItemLockedReasonStreamPack =>
      'Extra styles unlock when you complete a chapter can-do.';

  @override
  String get gamesArcadeHeadlinersTitle => 'Headliners';

  @override
  String get gamesArcadeHeadlinersInstructions =>
      'Tap a flagship to play — more are on the way.';

  @override
  String get gamesArcadeHeadlinersFeatured => 'Featured';

  @override
  String get gamesArcadeHeadlinersComingSoon => 'Coming soon';

  @override
  String get gamesArcadeHeadlinersError =>
      'This game is not ready yet. Try another headliner.';

  @override
  String get gamesArcadeHeadlinersWhyWrong =>
      'We will add a short tip here after you play.';

  @override
  String get duetStart => 'Start duet';

  @override
  String get duetBlocked => 'Duet unavailable';

  @override
  String get stitchLabel => 'Native correction';

  @override
  String get aiDisclosureLabel =>
      'محتوى مُولَّد بالذكاء الاصطناعي: الردود والصوت من معلّم ذكاء اصطناعي وقد تكون خاطئة.';

  @override
  String get aiDisclosureShort => 'محتوى مُولَّد بالذكاء الاصطناعي';

  @override
  String get aiDisclosureMoreHint =>
      'تعرّف على كيفية استخدام الذكاء الاصطناعي هنا';

  @override
  String get aiDisclosureSheetTitle => 'عن الذكاء الاصطناعي في LingAfriq';

  @override
  String get aiDisclosureSheetBody =>
      'بولي والمعلّمون والشخصيات الافتراضية ليسوا بشرًا. نصوصهم وأصواتهم مُولَّدة بالذكاء الاصطناعي وقد تكون خاطئة، لذا تحقّق من المعلومات المهمة. تجنّب مشاركة معلومات خاصة في المحادثات.';

  @override
  String get aiDisclosureGotIt => 'فهمت';

  @override
  String get voiceRetentionTitle => 'التسجيلات على هذا الجهاز';

  @override
  String get voiceRetentionBody =>
      'يُسجَّل صوتك أثناء التدريب فقط لتقييم النطق وتحويل الكلام إلى نص. تُحذف التسجيلات المحفوظة على هذا الهاتف تلقائيًا.';

  @override
  String get voiceRetentionSelectLabel => 'حذف التسجيلات تلقائيًا';

  @override
  String get voiceRetentionImmediate => 'مباشرة بعد التقييم';

  @override
  String get voiceRetention24h => 'بعد 24 ساعة';

  @override
  String get voiceRetention7d => 'بعد 7 أيام';

  @override
  String get voiceRetention30d => 'بعد 30 يومًا';

  @override
  String get voiceRetentionDeleteNow => 'احذف تسجيلاتي الآن';

  @override
  String get voiceRetentionConfirmTitle => 'حذف التسجيلات على هذا الجهاز؟';

  @override
  String get voiceRetentionConfirmBody =>
      'ستُزال تسجيلات التدريب المحفوظة على هذا الهاتف. لا يمكن التراجع عن ذلك. لا يتأثر ما اخترت حفظه في حسابك.';

  @override
  String get voiceRetentionConfirmDelete => 'حذف';

  @override
  String voiceRetentionDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُذف $count من التسجيلات من هذا الجهاز.',
      one: 'حُذف تسجيل واحد من هذا الجهاز.',
      zero: 'لا توجد تسجيلات لحذفها.',
    );
    return '$_temp0';
  }

  @override
  String get paywallTermsTitle => 'شروط الاشتراك';

  @override
  String get paywallRowPrice => 'السعر';

  @override
  String get paywallRowRenews => 'التجديد';

  @override
  String get paywallRowTrial => 'الفترة التجريبية';

  @override
  String get paywallRowCancel => 'الإلغاء';

  @override
  String paywallPriceValue(String premium, String family, String lifetime) {
    return 'بلس الشهري $premium شهريًا\nبلس العائلي $family شهريًا\nبلس مدى الحياة $lifetime تُدفع مرة واحدة';
  }

  @override
  String paywallChargedTo(String store) {
    return 'يُخصم المبلغ من حسابك في $store.';
  }

  @override
  String get paywallRenewsAuto =>
      'يتجدد بلس الشهري وبلس العائلي تلقائيًا بالسعر نفسه حتى تلغيهما. بلس مدى الحياة لا يتجدد.';

  @override
  String paywallRenewsOn(String date) {
    return 'تتجدد خطتك في $date.';
  }

  @override
  String paywallTrialOffered(int days, String price) {
    return 'تجربة مجانية لـ بلس الشهري لمدة $days يومًا، ثم $price شهريًا ما لم تلغِ قبل انتهائها بـ 24 ساعة على الأقل.';
  }

  @override
  String get paywallTrialGeneric =>
      'إذا عُرضت فترة تجريبية، تدفع سعر الخطة عند انتهائها ما لم تلغِ قبلها بـ 24 ساعة على الأقل.';

  @override
  String get paywallCancelApple =>
      'في أي وقت من الإعدادات ‹ اسمك ‹ الاشتراكات. يبقى وصولك حتى نهاية الفترة المدفوعة.';

  @override
  String get paywallCancelGoogle =>
      'في أي وقت من Google Play ‹ الدفعات والاشتراكات ‹ الاشتراكات. يبقى وصولك حتى نهاية الفترة المدفوعة.';

  @override
  String get paywallFreeStays =>
      'تبقى الميزات المجانية متاحة إن لم تشترك أو ألغيت.';

  @override
  String get paywallManage => 'إدارة الاشتراك';

  @override
  String get paywallTerms => 'شروط الخدمة';

  @override
  String get paywallPrivacy => 'سياسة الخصوصية';

  @override
  String get reportReasonHarassment => 'تحرّش أو تنمّر';

  @override
  String get reportReasonSpam => 'رسائل مزعجة أو احتيال';

  @override
  String get reportReasonHate => 'خطاب كراهية';

  @override
  String get reportReasonCopyright => 'انتهاك حقوق النشر';

  @override
  String get reportReasonCopyrightHint => 'نشر أحدهم عملك دون إذن';

  @override
  String get reportReasonOther => 'شيء آخر';

  @override
  String get settingsCopyright => 'حقوق النشر والإزالة';

  @override
  String get cpTitle => 'حقوق النشر والإزالة';

  @override
  String get cpIntro =>
      'إذا استخدم محتوى على LingAfriq عملك دون إذن، فأخبرنا. يراجع شخصٌ كل إشعار.';

  @override
  String get cpHowTitle => 'كيف تتم العملية';

  @override
  String get cpStep1 => 'ترسل إشعارًا بالتفاصيل أدناه.';

  @override
  String get cpStep2 => 'نزيل المحتوى أو نخفيه بسرعة ونُبلغ من رفعه.';

  @override
  String get cpStep3 =>
      'يمكن لمن رفع المحتوى إرسال إشعار مضاد إن كان خطأً. ما لم ترفع دعوى قضائية، قد يعود المحتوى بعد 10 إلى 14 يوم عمل.';

  @override
  String get cpRepeatTitle => 'المخالفون المتكرّرون';

  @override
  String get cpRepeatBody =>
      'تُغلق الحسابات التي تتلقى 3 إشعارات حقوق نشر مؤكَّدة. قد تترتب عواقب قانونية على الإشعارات الكاذبة.';

  @override
  String get cpAgentTitle => 'وكيل حقوق النشر المعيَّن';

  @override
  String get cpAgentPending =>
      'تسجيل الوكيل قيد الإجراء. حتى ذلك الحين، استخدم هذا النموذج.';

  @override
  String get cpKindNotice => 'الإبلاغ عن انتهاك';

  @override
  String get cpKindCounter => 'إشعار مضاد';

  @override
  String get cpFormTitle => 'إشعارك';

  @override
  String get cpFieldTarget => 'معرّف المحتوى أو رابطه على LingAfriq';

  @override
  String get cpFieldWork => 'صِف عملك الأصلي';

  @override
  String get cpFieldWorkCounter => 'صِف المحتوى المُزال';

  @override
  String get cpFieldWorkHelp => 'مثلًا: العنوان ومكان النشر الأول ورابط.';

  @override
  String get cpFieldName => 'الاسم القانوني الكامل';

  @override
  String get cpFieldEmail => 'البريد الإلكتروني للرد';

  @override
  String get cpFieldSignature => 'التوقيع: اكتب اسمك الكامل';

  @override
  String get cpStatementsTitle => 'الإقرارات';

  @override
  String get cpStmtGoodFaith =>
      'أعتقد بحسن نية أن هذا الاستخدام غير مُصرَّح به من المالك أو وكيله أو القانون.';

  @override
  String get cpStmtAccurate =>
      'هذا الإشعار دقيق، وأُقرّ تحت طائلة عقوبة الحنث باليمين بأنني المالك أو مفوَّض عنه.';

  @override
  String get cpStmtMistake =>
      'أُقرّ تحت طائلة عقوبة الحنث باليمين بأن المحتوى أُزيل خطأً أو بسبب سوء تعريف.';

  @override
  String get cpStmtJurisdiction =>
      'أوافق على اختصاص المحكمة المختصة وأقبل التبليغ من المُدّعي.';

  @override
  String get cpRequired => 'مطلوب';

  @override
  String get cpEmailInvalid => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get cpWorkTooShort => 'أضف مزيدًا من التفاصيل';

  @override
  String get cpStatementsMissing => 'حدّد الإقرارين للمتابعة';

  @override
  String get cpSend => 'إرسال الإشعار';

  @override
  String get cpSending => 'جارٍ الإرسال…';

  @override
  String get cpErrorTitle => 'تعذّر إرسال إشعارك';

  @override
  String get cpErrorBody =>
      'تحقّق من اتصالك وحاول مجددًا. لم يُفقد شيء مما كتبته.';

  @override
  String get cpRetry => 'حاول مجددًا';

  @override
  String get cpSuccessTitle => 'تم استلام الإشعار';

  @override
  String cpSuccessBody(String reference) {
    return 'سيراجعه شخص ويراسلك عبر البريد. احتفظ بهذا المرجع: $reference';
  }

  @override
  String get cpDone => 'تم';

  @override
  String get reportReasonTitle => 'لماذا تُبلغ عن هذا؟';

  @override
  String get settingsSecAppearance => 'المظهر';

  @override
  String get settingsSecNotifications => 'الإشعارات';

  @override
  String get settingsSecAudio => 'الصوت';

  @override
  String get settingsSecSecurity => 'الأمان';

  @override
  String get settingsSecAccount => 'الحساب';

  @override
  String get settingsSecLearning => 'التعلّم';

  @override
  String get settingsSecOffline => 'بدون اتصال والمزامنة';

  @override
  String get settingsSecAbout => 'حول التطبيق';

  @override
  String get settingsDarkMode => 'الوضع الداكن';

  @override
  String get settingsDarkModeSub => 'التبديل بين المظهر الفاتح والداكن';

  @override
  String get settingsPush => 'الإشعارات الفورية';

  @override
  String get settingsPushSub => 'تلقَّ الإشعارات الفورية';

  @override
  String get settingsDailyReminders => 'تذكيرات يومية';

  @override
  String get settingsDailyRemindersSub => 'تلقَّ تذكيرًا بالتدرّب يوميًا';

  @override
  String get settingsSoundEffects => 'المؤثرات الصوتية';

  @override
  String get settingsSoundEffectsSub => 'تشغيل المؤثرات الصوتية أثناء الدروس';

  @override
  String get settingsVoiceStyles => 'أنماط صوت المعلّم';

  @override
  String get settingsVoiceStylesSub =>
      'أصوات اصطناعية لا تكشف الهوية (اختيارية)';

  @override
  String get settingsAppLanguage => 'لغة التطبيق';

  @override
  String get settingsBiometric => 'تسجيل الدخول بالقياسات الحيوية';

  @override
  String get settingsBiometricSub =>
      'استخدم القياسات الحيوية لتسجيل الدخول بسرعة';

  @override
  String get settingsEncryptCache => 'تشفير البيانات المخزّنة مؤقتًا';

  @override
  String get settingsEncryptCacheSub =>
      'تشفير البيانات الحساسة المخزّنة على هذا الجهاز';

  @override
  String get settingsEditProfile => 'تعديل الملف الشخصي';

  @override
  String get settingsEditProfileSub => 'حدّث معلوماتك الشخصية';

  @override
  String get settingsChangePassword => 'تغيير كلمة المرور';

  @override
  String get settingsChangePasswordSub => 'حدّث كلمة مرور حسابك';

  @override
  String get settingsPrivacy => 'إعدادات الخصوصية';

  @override
  String get settingsPrivacySub => 'إدارة تفضيلات الخصوصية';

  @override
  String get settingsMentorReports => 'بلاغات المرشدين';

  @override
  String get settingsMentorReportsSub => 'مراجعة بلاغات السلامة (للفريق)';

  @override
  String get settingsGoals => 'أهداف التعلّم';

  @override
  String get settingsGoalsSub => 'حدّد أهداف تعلّمك اليومية';

  @override
  String get settingsStudyReminders => 'تذكيرات الدراسة';

  @override
  String get settingsStudyRemindersSub => 'اختر وقت التذكير';

  @override
  String get settingsSync => 'إعدادات المزامنة';

  @override
  String get settingsSyncSub => 'اختر ما تريد مزامنته';

  @override
  String get settingsCache => 'إدارة الذاكرة المؤقتة';

  @override
  String get settingsCacheSub => 'عرض البيانات المخزّنة مؤقتًا وإدارتها';

  @override
  String get settingsDownloads => 'التنزيلات';

  @override
  String get settingsDownloadsSub => 'حجم الوحدات وشبكة Wi-Fi والحذف';

  @override
  String get settingsAppVersion => 'إصدار التطبيق';

  @override
  String get settingsTerms => 'شروط الخدمة';

  @override
  String get settingsPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get settingsHelp => 'المساعدة والدعم';

  @override
  String get settingsLogoutConfirm => 'هل تريد تسجيل الخروج؟';

  @override
  String get settingsFeaturesGuide => 'دليل الميزات';

  @override
  String get settingsGamesTour => 'كيف تعمل الألعاب';

  @override
  String get lowBandwidthTitle => 'وضع البيانات المنخفضة';

  @override
  String get lowBandwidthAutoOn => 'مُفعّل لأن توفير البيانات مُفعّل';

  @override
  String get lowBandwidthManualOn => 'مُفعّل حتى توقفه';

  @override
  String get lowBandwidthOff => 'متوقف';

  @override
  String get lessonExit => 'الخروج من الدرس';

  @override
  String get lessonQuitTitle => 'هل تريد مغادرة هذا الدرس؟';

  @override
  String get lessonQuitBody =>
      'أنت تُبلي حسنًا. بضع دقائق أخرى وتُنهي هذا الدرس.';

  @override
  String get lessonKeepLearning => 'تابع التعلّم';

  @override
  String get lessonEndSession => 'إنهاء الدرس';

  @override
  String get lessonPreparing => 'جارٍ تحضير درسك';

  @override
  String get lessonLoadFailedTitle => 'لنحاول مرة أخرى';

  @override
  String get lessonRetry => 'إعادة المحاولة';

  @override
  String lessonProgressLabel(int current, int total, int percent) {
    return 'تقدّم الدرس. القسم $current من $total. اكتمل $percent بالمئة.';
  }

  @override
  String lessonSectionLabel(int current, int total) {
    return 'القسم $current من $total';
  }

  @override
  String get lessonContinueNext => 'المتابعة إلى القسم التالي';

  @override
  String pointsCount(int count) {
    return '$count نقطة';
  }

  @override
  String lessonQuitRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تبقّى $count قسم',
      many: 'تبقّى $count قسمًا',
      few: 'تبقّت $count أقسام',
      two: 'تبقّى قسمان',
      one: 'تبقّى قسم واحد',
      zero: 'لم يتبقَّ أي قسم',
    );
    return '$_temp0';
  }

  @override
  String get homeSearchLanguagesLabel => 'ابحث عن اللغات';

  @override
  String get homeSearchLanguagesAction => 'ابحث عن اللغات';

  @override
  String get homeOpenMenu => 'فتح القائمة';

  @override
  String get homeMenu => 'القائمة';

  @override
  String get homeFeaturedLanguages => 'لغات مميّزة';

  @override
  String get homeNoLanguagesTitle => 'لا توجد لغات بعد';

  @override
  String get homeNoLanguagesBody =>
      'ما زلنا نضيف لغات لمنطقتك. ابحث لترى المتاح، أو عد قريبًا.';

  @override
  String homeComingSoonSnack(String name) {
    return '$name قادمة قريبًا. نضع عليها اللمسات الأخيرة.';
  }

  @override
  String get homeOfflineTitle => 'أنت غير متصل';

  @override
  String get homeOfflineBody =>
      'تحقّق من اتصالك. سنعيد تحميل لغاتك فور عودتك إلى الإنترنت.';

  @override
  String get homeTryAgain => 'حاول مجددًا';

  @override
  String get homeLoadingLanguages => 'جارٍ تحميل لغاتك...';

  @override
  String get homeComingSoon => 'قريبًا';

  @override
  String homePercentComplete(int percent) {
    return 'اكتمل $percent%';
  }

  @override
  String get homeStartLearning => 'ابدأ التعلّم';

  @override
  String homeCardLocked(String name) {
    return 'بطاقة لغة $name، قريبًا، غير متاحة بعد';
  }

  @override
  String homeCardProgress(String name, int percent) {
    return 'بطاقة لغة $name، اكتمل $percent%';
  }

  @override
  String homeCardStart(String name) {
    return 'بطاقة لغة $name، ابدأ التعلّم';
  }

  @override
  String homeFlag(String name) {
    return 'صورة $name';
  }

  @override
  String get homeGuardianTitle => 'بانتظار وليّ الأمر';

  @override
  String get homeGuardianBody =>
      'الدروس متاحة. تبقى الدردشة والقرية والمشتريات متوقفة حتى يوافق وليّ الأمر.';

  @override
  String get homeGuardianLabel =>
      'بانتظار وليّ الأمر. الدروس متاحة، لكن الدردشة والقرية والمشتريات تبقى متوقفة حتى يوافق وليّ الأمر.';

  @override
  String homeWelcomeBack(String name) {
    return 'مرحبًا بعودتك، $name';
  }

  @override
  String get homeLearner => 'متعلّم';

  @override
  String get homeStreakNone => 'اختر لغة وابدأ سلسلتك اليوم.';

  @override
  String get homeStreakOne => 'هذا يومك الأول، حافظ على سلسلتك اليوم.';

  @override
  String homeStreakMany(int count) {
    return 'سلسلتك $count يومًا، واصل!';
  }

  @override
  String homeStreakBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String homeStreakSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سلسلة $count يومًا',
      few: 'سلسلة $count أيام',
      two: 'سلسلة يومين',
      one: 'سلسلة يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get homeDailyGoals => 'الأهداف اليومية';

  @override
  String homeGoalRing(int percent) {
    return 'تقدّم هدف اليوم: $percent%';
  }

  @override
  String get homeGoalCaption => 'اليوم';

  @override
  String homeWordOfDay(String word, String language) {
    return 'كلمة اليوم: $word، وتعني «مرحبًا» في $language';
  }

  @override
  String get homeLangHausa => 'الهوسا';

  @override
  String get homeLangPidgin => 'البيدجن';

  @override
  String get homeLangSwahili => 'السواحيلية';

  @override
  String get homeLangYoruba => 'اليوروبا';

  @override
  String get homeLangZulu => 'الزولو';

  @override
  String get homeLangIgbo => 'الإيغبو';

  @override
  String homeContinueTitle(String name) {
    return 'تابع $name';
  }

  @override
  String homeContinueLabel(String name, int percent) {
    return 'تابع $name، اكتمل $percent%';
  }

  @override
  String get homeErrorTitle => 'تعذّر تحميل لغاتك';

  @override
  String get homeErrorBody =>
      'المشكلة من جهتنا. تقدّمك محفوظ، فحاول مجددًا بعد قليل.';

  @override
  String get homeKidsTitle => 'وضع الأطفال مفعّل';

  @override
  String get homeKidsBody =>
      'كل الدروس متاحة. الدردشة والقرية والمشتريات متوقفة.';

  @override
  String get homeKidsLabel =>
      'وضع الأطفال مفعّل. كل الدروس متاحة. الدردشة والقرية والمشتريات متوقفة.';

  @override
  String get lessonNewPhrase => 'عبارة جديدة';

  @override
  String get lessonExampleLabel => 'مثال';

  @override
  String get lessonListen => 'استمع';

  @override
  String get lessonListenSlowly => 'استمع ببطء';

  @override
  String get lessonTutorialAudio => 'صوت الدرس';

  @override
  String get lessonTutorialVideo => 'فيديو الدرس';

  @override
  String lessonQuestionOf(int current, int total) {
    return 'السؤال $current من $total';
  }

  @override
  String lessonQuestionProgress(int current, int total, int percent) {
    return 'السؤال $current من $total. اكتمل $percent بالمئة.';
  }

  @override
  String get lessonPrevious => 'السابق';

  @override
  String get lessonPreviousQuestion => 'السؤال السابق';

  @override
  String get lessonCheck => 'تحقّق';

  @override
  String get lessonCheckAnswer => 'تحقّق من الإجابة';

  @override
  String get lessonNext => 'التالي';

  @override
  String get lessonNextQuestion => 'السؤال التالي';

  @override
  String get lessonFinish => 'إنهاء';

  @override
  String get lessonFinishQuiz => 'إنهاء الاختبار';

  @override
  String get lessonPickFirst => 'اختر إجابة أولًا، ثم نتحقق منها معًا.';

  @override
  String get lessonCorrectTitle => 'أحسنت!';

  @override
  String get lessonCorrectBody => 'إجابة صحيحة. واصل التقدّم.';

  @override
  String get lessonIncorrectTitle => 'ليس تمامًا';

  @override
  String lessonCorrectAnswer(String answer) {
    return 'الإجابة الصحيحة: $answer';
  }

  @override
  String lessonOptionLabel(String letter, String text) {
    return 'خيار الإجابة $letter: $text.';
  }

  @override
  String get lessonOptionSelected => 'محدّد';

  @override
  String lessonQuestionLabel(String question) {
    return 'السؤال. $question';
  }

  @override
  String lessonHintLabel(String hint) {
    return 'تلميح: $hint';
  }

  @override
  String get lessonFunFact => 'معلومة طريفة';

  @override
  String get lessonNotReadyTitle => 'هذا الجزء غير جاهز بعد';

  @override
  String get lessonNotReadyBody => 'ما زلنا نُعدّ هذه الأسئلة. عُد بعد قليل.';

  @override
  String get lessonLoadFailedBody =>
      'تحقّق من اتصالك وحاول مجددًا. تقدّمك محفوظ.';

  @override
  String lessonAvatarLabel(String points) {
    return 'ملفك الشخصي، $points';
  }

  @override
  String get lcMsgGreat => 'ثقتك في المحادثة تكبر فعلًا.';

  @override
  String get lcMsgGood => 'هذا الدرس دفعك إلى الأمام. أحسنت.';

  @override
  String get lcMsgSteady => 'كل جلسة تقوّي ذاكرتك. واصل.';

  @override
  String get lcMsgReview => 'مراجعة قصيرة في المرة القادمة ستثبّت ما تعلمته.';

  @override
  String get lcMsgNoQuiz =>
      'تعرّفت اليوم على عبارات جديدة، وستعود في اختبارك القادم.';

  @override
  String get lcStatXp => 'نقاط الخبرة';

  @override
  String get lcStatAccuracy => 'الدقة';

  @override
  String get lcStatTime => 'الوقت';

  @override
  String get lcNoQuizValue => 'بلا اختبار';

  @override
  String lcPercent(int value) {
    return '$value٪';
  }

  @override
  String lcTimeMinSec(int m, int s) {
    return '$m د $s ث';
  }

  @override
  String lcTimeSec(int s) {
    return '$s ث';
  }

  @override
  String lcBestRun(int count) {
    return 'أفضل سلسلة: $count متتالية';
  }

  @override
  String lcComboBonus(int xp) {
    return 'مكافأة السلسلة +$xp XP';
  }

  @override
  String get lcContinue => 'متابعة';

  @override
  String get lcShare => 'مشاركة';

  @override
  String get lcContinueA11y => 'المتابعة إلى الدرس التالي';

  @override
  String get lcShareA11y => 'شارك نتيجتك';

  @override
  String get lcOffline =>
      'أنت غير متصل. تقدّمك محفوظ على هذا الهاتف، وستعود المشاركة عند عودة الاتصال.';

  @override
  String lcSummaryA11y(int xp, String accuracy, String time) {
    return 'اكتمل الدرس. $xp نقطة خبرة. الدقة $accuracy. الوقت $time.';
  }

  @override
  String get lcHeroA11y => 'أمارا وكوفي يهتفان فرحًا';

  @override
  String get profOverview => 'نظرة عامة';

  @override
  String get profAccount => 'الحساب';

  @override
  String get profWallet => 'المحفظة';

  @override
  String profStreakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get profStreakLabel => 'سلسلة الأيام';

  @override
  String get profStreakZero => 'ابدأ اليوم';

  @override
  String profXpValue(int count) {
    return '$count XP';
  }

  @override
  String get profXpLabel => 'مجموع نقاط الخبرة';

  @override
  String profRankValue(int rank) {
    return '#$rank';
  }

  @override
  String get profRankLabel => 'الترتيب العالمي';

  @override
  String get profRankNone => 'بلا ترتيب بعد';

  @override
  String get profLevelLabel => 'المستوى';

  @override
  String get profLevelNone => 'في البداية';

  @override
  String get profPrivateValue => 'خاص';

  @override
  String get profPrivateHint => 'ملفك خاص، لذلك يبقى ترتيبك مخفيًا عن الآخرين.';

  @override
  String profLearning(String language) {
    return 'تتعلّم $language';
  }

  @override
  String get profEdit => 'تعديل الملف الشخصي';

  @override
  String get profChangePassword => 'تغيير كلمة المرور';

  @override
  String get profFeedback => 'شاركنا رأيك';

  @override
  String get profAbout => 'من نحن';

  @override
  String get profPolicy => 'الخصوصية وسياسة الاستخدام';

  @override
  String get profDelete => 'حذف حسابك';

  @override
  String get profDeleted => 'تم حذف الحساب';

  @override
  String get profLoading => 'جارٍ تحميل ملفك…';

  @override
  String get profErrorTitle => 'تعذّر تحميل ملفك';

  @override
  String get profErrorBody =>
      'تحقّق من اتصالك وحاول مجددًا. لن يضيع شيء مما تعلّمته.';

  @override
  String get profRetry => 'حاول مجددًا';

  @override
  String get profOffline => 'أنت غير متصل. نعرض ملفك المحفوظ.';

  @override
  String get profNgwenya => 'نغوينيا';

  @override
  String get profCowries => 'الودع';

  @override
  String get profBeads => 'الخرز';

  @override
  String get profOpenLeaderboard => 'افتح لوحة المتصدّرين';

  @override
  String get pgTitle => 'تقدّمك';

  @override
  String get pgThisWeek => 'هذا الأسبوع';

  @override
  String pgMinutes(int count) {
    return '$count د';
  }

  @override
  String pgVsUp(int count) {
    return '$count د أكثر من الأسبوع الماضي';
  }

  @override
  String pgVsDown(int count) {
    return '$count د أقل من الأسبوع الماضي';
  }

  @override
  String get pgVsSame => 'مثل الأسبوع الماضي';

  @override
  String get pgWordsLearned => 'كلمات تعلّمتها';

  @override
  String get pgKnownWords => 'كلمات تعرفها';

  @override
  String get pgListening => 'الاستماع';

  @override
  String get pgSpeaking => 'التحدّث';

  @override
  String pgHours(String value) {
    return '$value س';
  }

  @override
  String get pgDaily => 'الدقائق في اليوم';

  @override
  String get pgCalendar => 'آخر 4 أسابيع';

  @override
  String pgActiveDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يومًا نشطًا',
      few: '$count أيام نشطة',
      two: 'يومان نشطان',
      one: 'يوم نشط واحد',
      zero: 'لا أيام نشطة بعد',
    );
    return '$_temp0';
  }

  @override
  String get pgActivities => 'الوقت حسب النشاط';

  @override
  String get pgActLessons => 'الدروس';

  @override
  String get pgActQuizzes => 'الاختبارات';

  @override
  String get pgActGames => 'الألعاب';

  @override
  String get pgActChat => 'تمرين المحادثة';

  @override
  String get pgActStories => 'القصص';

  @override
  String get pgActReading => 'القراءة';

  @override
  String get pgActWriting => 'الكتابة';

  @override
  String get pgActOther => 'تمارين أخرى';

  @override
  String get pgOfflineCount => 'الأيام دون اتصال تُحتسب أيضًا.';

  @override
  String get pgOffline => 'أنت غير متصل. نعرض التقدّم المحفوظ على هذا الجهاز.';

  @override
  String get pgEmptyTitle => 'تقدّمك يبدأ من هنا';

  @override
  String get pgEmptyBody =>
      'أنهِ درسًا وستظهر هنا دقائقك وكلماتك وأيامك النشطة.';

  @override
  String get pgLoading => 'جارٍ تحميل تقدّمك…';

  @override
  String get pgErrorTitle => 'تعذّر تحميل تقدّمك';

  @override
  String get pgErrorBody =>
      'تقدّمك محفوظ على هذا الجهاز. حاول مجددًا بعد قليل.';

  @override
  String get pgRetry => 'حاول مجددًا';

  @override
  String get pgPrivate => 'تقدّمك خاص. أنت وحدك من يراه.';

  @override
  String pgDayA11y(String day, int count) {
    return '$day: $count دقيقة';
  }

  @override
  String pgCalA11y(String summary) {
    return 'تقويم النشاط: $summary';
  }

  @override
  String get pgOverviewTitle => 'المجاميع';

  @override
  String get profTitle => 'الملف الشخصي';

  @override
  String get profClose => 'إغلاق';

  @override
  String get profThisWeek => 'هذا الأسبوع';

  @override
  String get profSeeProgress => 'عرض كل التقدّم';

  @override
  String profDayA11y(String day, String status) {
    return '$day: $status';
  }

  @override
  String get profDayDone => 'تدرّبت';

  @override
  String get profDayMissed => 'بلا تدريب';

  @override
  String get profLanguages => 'اللغات';

  @override
  String profLangProgress(String level, int percent) {
    return 'المستوى $level · $percent٪';
  }

  @override
  String get profLangEmpty => 'اختر لغة من الصفحة الرئيسية لتبدأ رحلتك.';

  @override
  String get profBadges => 'الإنجازات';

  @override
  String profBadgesCount(int done, int total) {
    return '$done من $total مفتوحة';
  }

  @override
  String get profViewAll => 'عرض الكل';

  @override
  String profBadgeLocked(String name) {
    return '$name، مقفل';
  }

  @override
  String get profShareTitle => 'شارك تقدّمك';

  @override
  String get profShareBody => 'أرسل بطاقة بسلسلتك ونقاطك.';

  @override
  String get profShare => 'مشاركة';

  @override
  String profShareText(String language, int streak, int xp) {
    return 'أتعلّم $language على LingAfriq: سلسلة $streak يومًا و$xp نقطة خبرة!';
  }

  @override
  String get profHelpLegal => 'المساعدة والشؤون القانونية';

  @override
  String get profAboutApp => 'عن LingAfriq';

  @override
  String get profSecurity => 'الحساب والأمان';

  @override
  String get profTeenBadge => 'ملف شخصي خاص';

  @override
  String get profTeenTitle => 'يبقى ملفك الشخصي خاصًا';

  @override
  String get profTeenHidden => 'ترتيبك واسمك مخفيان من لوحات الصدارة.';

  @override
  String get profTeenNoDm => 'لا يمكن للبالغين إرسال رسائل مباشرة إليك.';

  @override
  String get profTeenParent => 'حسابك مرتبط بوليّ أمر وافق عليه.';

  @override
  String get pgClose => 'إغلاق';

  @override
  String get pgStreakTitle => 'السلسلة الحالية';

  @override
  String pgStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سلسلة $count يومًا',
      few: 'سلسلة $count أيام',
      two: 'سلسلة يومين',
      one: 'سلسلة يوم واحد',
      zero: 'لا توجد سلسلة بعد',
    );
    return '$_temp0';
  }

  @override
  String pgNextGoal(int left, int goal) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left يومًا متبقيًا لهدف $goal يومًا',
      few: '$left أيام متبقية لهدف $goal يومًا',
      two: 'يومان متبقيان لهدف $goal يومًا',
      one: 'يوم واحد متبقٍ لهدف $goal يومًا',
    );
    return '$_temp0';
  }

  @override
  String pgMilestoneHit(int goal) {
    return 'إنجاز! $goal يومًا متتاليًا';
  }

  @override
  String get pgStreakStart => 'تدرّب اليوم لتشعل سلسلتك.';

  @override
  String get pgErrorSaved => 'لن تتأثر سلسلتك وأيام تدريبك.';

  @override
  String get subTitle => 'LingAfriq Plus';

  @override
  String get subClose => 'إغلاق';

  @override
  String get subPlusBadge => 'بلس';

  @override
  String get subHeadline => 'تعلّم أسرع مع إضافات اختيارية';

  @override
  String get subFreeForever =>
      'كل درس ولعبة وقصة تبقى مجانية للأبد. بلس يضيف مزايا إضافية فقط.';

  @override
  String get subOffline =>
      'أنت غير متصل. الشراء يحتاج اتصالًا، لكن كل دروسك ما زالت تعمل.';

  @override
  String get subWhatYouGet => 'ما يضيفه بلس';

  @override
  String get subBenefitOffline => 'نزّل كل وحدة لتتعلم دون اتصال';

  @override
  String get subBenefitChat => 'محادثات تدريب غير محدودة مع معلّمك';

  @override
  String get subBenefitSpeaking => 'تقييم مفصّل للنطق والنغمات';

  @override
  String get subBenefitNoAds => 'بلا إعلانات أبدًا';

  @override
  String subYouHavePlus(String plan) {
    return 'لديك $plan. شكرًا لدعمك اللغات الأفريقية!';
  }

  @override
  String get subChoosePlan => 'اختر خطة';

  @override
  String get subPriceError =>
      'تعذّر تحميل أسعار المتجر، لذا هذه أسعار قياسية. يعرض المتجر السعر النهائي قبل الدفع.';

  @override
  String get subPlanMonthly => 'بلس الشهري';

  @override
  String get subPlanMonthlyDetail => 'يُحتسب كل شهر. ألغِ في أي وقت.';

  @override
  String get subPlanFamily => 'بلس العائلي';

  @override
  String get subPlanFamilyDetail => 'حتى 4 متعلمين. يُحتسب كل شهر.';

  @override
  String get subPlanLifetime => 'بلس مدى الحياة';

  @override
  String get subPlanLifetimeDetail => 'ادفع مرة واحدة. بلا تجديد.';

  @override
  String get subMostPopular => 'الأكثر شيوعًا';

  @override
  String subPerMonth(String price) {
    return '$price / شهريًا';
  }

  @override
  String subOnce(String price) {
    return '$price مرة واحدة';
  }

  @override
  String get subHowTrialWorks => 'كيف تعمل تجربتك المجانية';

  @override
  String get subStepToday => 'اليوم';

  @override
  String get subStepTodayBody => 'كل مزايا بلس مفتوحة.';

  @override
  String subStepDay(int day) {
    return 'اليوم $day';
  }

  @override
  String get subStepRemindBody => 'نذكّرك قبل انتهاء التجربة.';

  @override
  String subStepChargeBody(String price) {
    return 'يُخصم $price ما لم تلغِ قبل ذلك.';
  }

  @override
  String subStartTrial(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ابدأ تجربة مجانية لمدة $days يوم',
      many: 'ابدأ تجربة مجانية لمدة $days يومًا',
      few: 'ابدأ تجربة مجانية لمدة $days أيام',
      two: 'ابدأ تجربة مجانية لمدة يومين',
      one: 'ابدأ تجربة مجانية لمدة يوم واحد',
      zero: 'ابدأ تجربة مجانية لمدة 0 أيام',
    );
    return '$_temp0';
  }

  @override
  String get subGetPlus => 'احصل على بلس الشهري';

  @override
  String get subGetFamily => 'احصل على بلس العائلي';

  @override
  String get subGetLifetime => 'احصل على بلس مدى الحياة';

  @override
  String subFineTrial(int days, String price) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          'مجانًا لمدة $days يوم، ثم $price شهريًا. ألغِ في أي وقت من إعدادات المتجر.',
      many:
          'مجانًا لمدة $days يومًا، ثم $price شهريًا. ألغِ في أي وقت من إعدادات المتجر.',
      few:
          'مجانًا لمدة $days أيام، ثم $price شهريًا. ألغِ في أي وقت من إعدادات المتجر.',
      two:
          'مجانًا لمدة يومين، ثم $price شهريًا. ألغِ في أي وقت من إعدادات المتجر.',
      one:
          'مجانًا لمدة يوم واحد، ثم $price شهريًا. ألغِ في أي وقت من إعدادات المتجر.',
      zero:
          'مجانًا لمدة 0 أيام، ثم $price شهريًا. ألغِ في أي وقت من إعدادات المتجر.',
    );
    return '$_temp0';
  }

  @override
  String subFineMonthly(String price) {
    return '$price شهريًا، يتجدد تلقائيًا. ألغِ في أي وقت من إعدادات المتجر.';
  }

  @override
  String subFineOnce(String price) {
    return 'دفعة واحدة بقيمة $price. لا يوجد تجديد.';
  }

  @override
  String get subKeepFree => 'تابع التعلّم مجانًا';

  @override
  String get subRestore => 'استعادة المشتريات';

  @override
  String get subRestored => 'تمت استعادة المشتريات';

  @override
  String get subRestoreNone => 'لم يتم العثور على مشتريات لاستعادتها';

  @override
  String get subLoading => 'جارٍ تحميل الخطط';

  @override
  String get subParentTitle => 'بلس يحتاج إلى شخص بالغ';

  @override
  String get subParentBody =>
      'كل ما تتعلمه يبقى مجانيًا. اطلب من وليّ أمرك إن أردت مزايا بلس.';

  @override
  String get subAskParent => 'وليّ الأمر هنا';

  @override
  String get subGateTitle => 'للبالغين';

  @override
  String subGateQuestion(int a, int b) {
    return 'كم يساوي $a × $b؟';
  }

  @override
  String get subGateWrong => 'هذا غير صحيح. حاول مرة أخرى.';

  @override
  String get subGateContinue => 'متابعة';

  @override
  String get subCancel => 'إلغاء';

  @override
  String get lsTitle => 'ابحث عن لغة';

  @override
  String get lsAsk => 'أي لغة تريد أن تستكشف اليوم؟';

  @override
  String get lsAskChild => 'بأي لغة سنلعب اليوم؟';

  @override
  String get lsHint => 'ابحث: اليوروبا، السواحيلية، الزولو…';

  @override
  String get lsContinue => 'تابع التعلّم';

  @override
  String get lsAll => 'كل اللغات';

  @override
  String get lsSoon => 'قريبًا';

  @override
  String get lsNew => 'ابدأ من الصفر';

  @override
  String lsPercent(int p) {
    return 'أُنجز $p٪';
  }

  @override
  String lsNoMatch(String q) {
    return 'لا توجد لغة تطابق «$q»';
  }

  @override
  String get lsNoMatchBody => 'تحقّق من الإملاء أو جرّب اسم اللغة بلغتها.';

  @override
  String get lsClear => 'امسح البحث';

  @override
  String get lsEmptyTitle => 'لا توجد لغات بعد';

  @override
  String get lsEmptyBody => 'دورات جديدة في الطريق. عُد قريبًا.';

  @override
  String get lsOfflineTitle => 'أنت غير متصل';

  @override
  String get lsOfflineBody => 'اتصل بالإنترنت لترى كل اللغات.';

  @override
  String get lsErrorTitle => 'تعذّر تحميل اللغات';

  @override
  String get lsErrorBody => 'تقدّمك محفوظ. حاول مجددًا بعد قليل.';

  @override
  String get lsRetry => 'حاول مجددًا';

  @override
  String get lsBack => 'رجوع';

  @override
  String get lsLoading => 'جارٍ تحميل اللغات';

  @override
  String get lbTitle => 'لوحة الصدارة';

  @override
  String get lbBack => 'رجوع';

  @override
  String get lbGlobal => 'عالمي';

  @override
  String get lbTribe => 'قبيلتي';

  @override
  String get lbCountry => 'بلدي';

  @override
  String get lbWeek => 'هذا الأسبوع';

  @override
  String get lbLeader => 'صاحب الصدارة هذا الأسبوع';

  @override
  String get lbColRank => 'المركز';

  @override
  String get lbColLearner => 'المتعلّم';

  @override
  String get lbColXp => 'نقاط';

  @override
  String lbXp(int xp) {
    return '$xp نقطة';
  }

  @override
  String lbStreak(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'سلسلة $days يوم',
      many: 'سلسلة $days يومًا',
      few: 'سلسلة $days أيام',
      two: 'سلسلة يومين',
      one: 'سلسلة يوم واحد',
      zero: 'سلسلة 0 أيام',
    );
    return '$_temp0';
  }

  @override
  String lbUp(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'صعد $n مركز',
      many: 'صعد $n مركزًا',
      few: 'صعد $n مراكز',
      two: 'صعد مركزين',
      one: 'صعد مركزًا واحدًا',
    );
    return '$_temp0';
  }

  @override
  String lbDown(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'نزل $n مركز',
      many: 'نزل $n مركزًا',
      few: 'نزل $n مراكز',
      two: 'نزل مركزين',
      one: 'نزل مركزًا واحدًا',
    );
    return '$_temp0';
  }

  @override
  String lbRankN(int n) {
    return 'المركز $n';
  }

  @override
  String get lbYou => 'أنت';

  @override
  String lbYourRank(int n) {
    return 'مركزك: #$n';
  }

  @override
  String get lbUnranked => 'أكمل درسًا لتنضم إلى لوحة هذا الأسبوع';

  @override
  String get lbFriendly =>
      'الجميع يبدأ من جديد كل اثنين. المهم هو التدرّب، لا السرعة.';

  @override
  String lbLearner(int n) {
    return 'متعلّم $n';
  }

  @override
  String get lbMinorTeen =>
      'ملفك خاص: يراك الآخرون باسم «متعلّم»، ولا يرون اسمك أبدًا.';

  @override
  String get lbMinorChild =>
      'الأسماء مخفية ليبقى الجميع بأمان. ويمكنك أن ترى تقدّمك!';

  @override
  String get lbNoTribeTitle => 'اختر قبيلة أولًا';

  @override
  String get lbNoTribeBody => 'انضم إلى قبيلة لترى أداء مجموعتك هذا الأسبوع.';

  @override
  String get lbPickTribe => 'اختر قبيلة';

  @override
  String get lbNoCountryTitle => 'أضف بلدك';

  @override
  String get lbNoCountryBody =>
      'حدّد بلدك في ملفك لترى المتعلّمين القريبين منك.';

  @override
  String get lbEmptyTitle => 'لا ترتيب بعد هذا الأسبوع';

  @override
  String get lbEmptyBody => 'أكمل درسًا وقد تكون الأول في اللوحة.';

  @override
  String get lbErrorTitle => 'تعذّر تحميل اللوحة';

  @override
  String get lbErrorBody => 'نقاطك محفوظة. حاول مجددًا بعد قليل.';

  @override
  String get lbOfflineTitle => 'أنت غير متصل';

  @override
  String get lbOfflineBody =>
      'يتحدّث الترتيب عند عودتك للاتصال. الدروس التي تكملها دون اتصال تُحتسب.';

  @override
  String get lbRetry => 'حاول مجددًا';

  @override
  String get lbLoading => 'جارٍ تحميل لوحة الصدارة';

  @override
  String get lbMore => 'جارٍ تحميل المزيد';

  @override
  String get rmTitle => 'تذكيرات الدراسة';

  @override
  String get rmBack => 'رجوع';

  @override
  String get rmPreviewApp => '⁦LingAfriq⁩ · الآن';

  @override
  String get rmPreviewBody => '⁦Ẹ kú àárọ̀!⁩ خمس دقائق من اليوروبا؟';

  @override
  String get rmPreviewOff =>
      'التذكيرات متوقفة. شغّلها لتصلك دفعة لطيفة واحدة يوميًا.';

  @override
  String get rmMaster => 'تذكير التدرّب اليومي';

  @override
  String get rmMasterSub => 'مرة واحدة يوميًا على الأكثر، ولا يصل ليلًا أبدًا.';

  @override
  String get rmWhen => 'متى نذكّرك؟';

  @override
  String get rmMorning => 'صباحًا';

  @override
  String get rmLunch => 'الظهر';

  @override
  String get rmEvening => 'مساءً';

  @override
  String get rmCustom => 'وقت آخر';

  @override
  String rmQuiet(String start, String end) {
    return 'ساعات الهدوء ⁦$start–$end⁩: لا نرسل شيئًا خلالها.';
  }

  @override
  String rmQuietClash(String time) {
    return 'هذا الوقت ضمن ساعات الهدوء، لذا ضبطناه على ⁦$time⁩.';
  }

  @override
  String get rmTimezone => 'المنطقة الزمنية';

  @override
  String get rmUseDevice => 'استخدم منطقة الهاتف';

  @override
  String get rmAbout => 'ما نذكّرك به';

  @override
  String get rmGoal => 'الهدف اليومي';

  @override
  String get rmGoalSub => 'دفعة لطيفة لإكمال هدف اليوم.';

  @override
  String get rmRhythm => 'محطات التدرّب';

  @override
  String get rmRhythmSub => 'نحتفل بإنجازاتك ولا نُشعرك بالذنب أبدًا.';

  @override
  String get rmSync => 'محفوظة في حسابك، فتعود بعد إعادة التثبيت.';

  @override
  String get rmBlockedTitle => 'الإشعارات محظورة';

  @override
  String get rmBlockedBody =>
      'هاتفك يحظر ⁦LingAfriq⁩. اسمح بالإشعارات من الإعدادات لتصلك التذكيرات.';

  @override
  String get rmOpenSettings => 'افتح الإعدادات';

  @override
  String get rmOffline =>
      'أنت غير متصل. التغييرات محفوظة على هذا الهاتف وتُزامن لاحقًا.';

  @override
  String get rmCheckError => 'تعذّر التحقق من إذن الإشعارات.';

  @override
  String get rmRetry => 'حاول مجددًا';

  @override
  String get rmLoading => 'جارٍ التحقق من إعدادات الإشعارات';

  @override
  String get rmChild =>
      'لا تصل تذكيرات المتعلّمين الصغار ليلًا أبدًا، ويمكن لأحد الكبار إيقافها في أي وقت.';

  @override
  String get rmMasterA11y => 'المفتاح الرئيسي لتذكيرات الدراسة';

  @override
  String get gmTitle => 'الألعاب';

  @override
  String get gmBack => 'رجوع';

  @override
  String get gmWelcome => 'مرحبًا بك في مساحتك للعب.';

  @override
  String gmWelcomeSub(String language) {
    return 'كل لعبة تدرّبك على $language.';
  }

  @override
  String get gmLanguage => 'لغة التدرّب';

  @override
  String get gmFeatured => 'اختيار اليوم';

  @override
  String get gmPlay => 'العب';

  @override
  String get gmCore => 'الأساسية';

  @override
  String get gmCultural => 'الثقافية';

  @override
  String gmCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لعبة',
      many: '$count لعبة',
      few: '$count ألعاب',
      two: 'لعبتان',
      one: 'لعبة واحدة',
      zero: 'لا ألعاب',
    );
    return '$_temp0';
  }

  @override
  String get gmCatAll => 'الكل';

  @override
  String get gmCatVocabulary => 'المفردات';

  @override
  String get gmCatGrammar => 'القواعد';

  @override
  String get gmCatPronunciation => 'النطق';

  @override
  String get gmCatCultural => 'الثقافة';

  @override
  String get gmCatTraditional => 'تقليدية';

  @override
  String get gmEmpty => 'لا توجد ألعاب هنا بعد.';

  @override
  String get gmShowAll => 'اعرض كل الألعاب';

  @override
  String get gmOffline => 'أنت غير متصل، لذا هذه الألعاب المحفوظة على هاتفك.';

  @override
  String get gmSyncing => 'جارٍ البحث عن ألعاب جديدة';

  @override
  String get gmOpening => 'جارٍ فتح اللعبة…';

  @override
  String get gmLoadError => 'تعذّر تحميل هذه اللعبة.';

  @override
  String get gmRule1 => 'تعلّم واستمتع بهذا النمط من اللعب.';

  @override
  String get gmRule2 => 'ركّز على الدقة أولًا ثم السرعة.';

  @override
  String gmPlayA11y(String name, String category, String description) {
    return '$name، $category. $description';
  }

  @override
  String get peTitle => 'تعديل الملف الشخصي';

  @override
  String get peBack => 'رجوع';

  @override
  String get peAvatarEdit => 'تعديل الصورة الرمزية';

  @override
  String get peAvatarHint => 'اجعل صورتك الرمزية تشبهك، أو لا تشبهك أبدًا.';

  @override
  String get peAbout => 'عنك';

  @override
  String get peFirst => 'الاسم الأول';

  @override
  String get peLast => 'اسم العائلة';

  @override
  String peRequired(String field) {
    return 'يرجى إضافة $field.';
  }

  @override
  String get peHandle => 'المعرّف';

  @override
  String get peHandleNone => 'اختر معرّفًا ليجدك أصدقاؤك';

  @override
  String get peHandleEdit => 'تغيير المعرّف';

  @override
  String get peCountry => 'البلد';

  @override
  String get peCountryLocked => 'حُدّد عند التسجيل. تواصل مع الدعم لتغييره.';

  @override
  String get peEmail => 'البريد الإلكتروني';

  @override
  String get peSave => 'احفظ التغييرات';

  @override
  String get peSaving => 'جارٍ الحفظ…';

  @override
  String get peSaved => 'تم حفظ الملف الشخصي';

  @override
  String get peSaveError => 'تعذّر الحفظ. تغييراتك ما زالت هنا، فحاول مجددًا.';

  @override
  String get peMinorTip => 'نصيحة: استخدم لقبًا كمعرّف، لا اسمك الكامل.';

  @override
  String get peDanger => 'الحساب';

  @override
  String get peDelete => 'حذف الحساب';

  @override
  String get peDeleteSub => 'يحذف تقدّمك نهائيًا. لا يمكن التراجع عن ذلك.';

  @override
  String get peDeleteError => 'تعذّر حذف حسابك. يرجى المحاولة مجددًا.';

  @override
  String get peLoading => 'جارٍ تحميل ملفك الشخصي';

  @override
  String get dgTitle => 'الأهداف اليومية';

  @override
  String dgStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'سلسلة $n يوم',
      many: 'سلسلة $n يومًا',
      few: 'سلسلة $n أيام',
      two: 'سلسلة يومين',
      one: 'سلسلة يوم واحد',
      zero: 'سلسلة 0 أيام',
    );
    return '$_temp0';
  }

  @override
  String get dgStreakOn => 'واصل — تدرّب اليوم لتضيف يومًا.';

  @override
  String get dgStreakZero => 'أكمل هدفًا واحدًا اليوم لتبدأ سلسلة.';

  @override
  String dgRing(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'تم $done من $total هدف',
      many: 'تم $done من $total هدفًا',
      few: 'تم $done من $total أهداف',
      two: 'تم $done من هدفين',
      one: 'تم $done من هدف واحد',
    );
    return '$_temp0';
  }

  @override
  String get dgToday => 'اليوم';

  @override
  String get dgLessons => 'أكمل الدروس';

  @override
  String get dgQuizzes => 'أجب عن الاختبارات';

  @override
  String get dgGames => 'العب الألعاب';

  @override
  String get dgChat => 'تحدّث مع Polie';

  @override
  String get dgWords => 'تعلّم كلمات';

  @override
  String get dgGoal => 'هدف';

  @override
  String dgCount(int current, int target) {
    return '$current من $target';
  }

  @override
  String dgMinutes(int current, int target) {
    String _temp0 = intl.Intl.pluralLogic(
      target,
      locale: localeName,
      other: '$current من $target دقيقة',
      many: '$current من $target دقيقة',
      few: '$current من $target دقائق',
      two: '$current من دقيقتين',
      one: '$current من دقيقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get dgDone => 'تم';

  @override
  String get dgStart => 'ابدأ';

  @override
  String get dgAllDone => 'أنجزت كل أهداف اليوم. نراك غدًا!';

  @override
  String get dgEmptyTitle => 'لا أهداف اليوم بعد';

  @override
  String get dgEmptyBody => 'اسحب للأسفل أو اضغط تحديث لتعيين أهداف اليوم.';

  @override
  String get dgRefresh => 'تحديث';

  @override
  String get dgSyncing => 'جارٍ مزامنة تقدّمك…';

  @override
  String get dgError =>
      'تعذّرت مزامنة الأهداف. نعرض التقدّم المحفوظ على هذا الجهاز.';

  @override
  String get dgRetry => 'إعادة المحاولة';

  @override
  String get dgPickLessons => 'اختر لغة للدروس';

  @override
  String get dgPickQuiz => 'اختر لغة للاختبار';

  @override
  String get dgLangError => 'تعذّر تحميل اللغات.';

  @override
  String dgGoalA11y(String title, String progress, String status) {
    return '$title، $progress، $status';
  }

  @override
  String get gmNameWordMatchAudio => 'مطابقة الكلمات بالصوت';

  @override
  String get gmDescWordMatchAudio => 'طابق الكلمات مع الصوت';

  @override
  String get gmNamePronunciationDuel => 'مبارزة النطق';

  @override
  String get gmDescPronunciationDuel => 'أتقن النطق';

  @override
  String get gmNameSpeedRoundRemix => 'الجولة السريعة';

  @override
  String get gmDescSpeedRoundRemix => 'مفردات بإيقاع سريع';

  @override
  String get gmNameStoryBuilder => 'صانع القصص';

  @override
  String get gmDescStoryBuilder => 'ابنِ قصصًا';

  @override
  String get gmNameRoleplayAdventure => 'مغامرة تقمّص الأدوار';

  @override
  String get gmDescRoleplayAdventure => 'محادثات تفاعلية';

  @override
  String get gmNameGrammarDetective => 'محقّق القواعد';

  @override
  String get gmDescGrammarDetective => 'حلّ ألغاز القواعد';

  @override
  String get gmNameListenAndSketch => 'استمع وارسم';

  @override
  String get gmDescListenAndSketch => 'ارسم ما تسمعه';

  @override
  String get gmNamePictureWordAssociation => 'مطابقة الصور والكلمات';

  @override
  String get gmDescPictureWordAssociation => 'طابق الكلمات مع الصور';

  @override
  String get gmNameMemoryMap => 'خريطة الذاكرة';

  @override
  String get gmDescMemoryMap => 'تحدّي الذاكرة';

  @override
  String get gmNameConversationRelay => 'تتابع المحادثة';

  @override
  String get gmDescConversationRelay => 'سلسِل المحادثات';

  @override
  String get gmNameGrammarJam => 'إيقاع القواعد';

  @override
  String get gmDescGrammarJam => 'لعبة قواعد على الإيقاع';

  @override
  String get gmNamePronunciationKaraoke => 'كاريوكي النطق';

  @override
  String get gmDescPronunciationKaraoke => 'غنِّ وانطق';

  @override
  String get gmNameQuizChef => 'طاهي الاختبار';

  @override
  String get gmDescQuizChef => 'حضّر إجاباتك';

  @override
  String get gmNameToneTrainer => 'مدرّب النغمات';

  @override
  String get gmDescToneTrainer => 'أتقن النطق النغمي';

  @override
  String get gmNameScrabbleSprintArena => 'سباق الكلمات';

  @override
  String get gmDescScrabbleSprintArena => 'كوّن كلمات تحت الضغط';

  @override
  String get gmNameProverbUnlocker => 'مفتاح الأمثال';

  @override
  String get gmDescProverbUnlocker => 'اكتشف الحكمة';

  @override
  String get gmNameDrumRhythmShadowing => 'إيقاع الطبل';

  @override
  String get gmDescDrumRhythmShadowing => 'تابع الإيقاع';

  @override
  String get gmNameClanLineageStoryBuilder => 'قصص العشيرة';

  @override
  String get gmDescClanLineageStoryBuilder => 'ابنِ قصص العشيرة';

  @override
  String get gmNameMarketBargainingSimulator => 'المساومة في السوق';

  @override
  String get gmDescMarketBargainingSimulator => 'تدرّب على المساومة';

  @override
  String get gmNameTaxiBusStopSurvival => 'النجاة في التاكسي';

  @override
  String get gmDescTaxiBusStopSurvival => 'تنقّل في المواصلات';

  @override
  String get gmNameFoodQuest => 'رحلة الطعام';

  @override
  String get gmDescFoodQuest => 'استكشف المطبخ';

  @override
  String get gmNameCallAndResponse => 'النداء والجواب';

  @override
  String get gmDescCallAndResponse => 'أنماط تقليدية';

  @override
  String get gmNameGreetingDiplomacyChallenge => 'دبلوماسية التحية';

  @override
  String get gmDescGreetingDiplomacyChallenge => 'أتقن التحيات';

  @override
  String get gmNameFolktaleReconstruction => 'إعادة بناء الحكايات';

  @override
  String get gmDescFolktaleReconstruction => 'أعد بناء القصص';

  @override
  String get gmNamePhraseSniper => 'قنّاص العبارات';

  @override
  String get gmDescPhraseSniper => 'استهدف العبارات';

  @override
  String get gmNameLiarLiar => 'كاذب كاذب';

  @override
  String get gmDescLiarLiar => 'اكتشف الحقيقة';

  @override
  String get gmNameVillageQuest => 'مغامرة القرية';

  @override
  String get gmDescVillageQuest => 'مغامرة استكشافية';

  @override
  String get gmNameAccentDecodingPuzzle => 'لغز اللهجات';

  @override
  String get gmDescAccentDecodingPuzzle => 'فكّ رموز اللهجات';

  @override
  String get gmNameFlashcardSafari => 'سفاري البطاقات';

  @override
  String get gmDescFlashcardSafari => 'مفردات السفاري';

  @override
  String get gmNameRapidTongueTwisterRace => 'سباق الألسن';

  @override
  String get gmDescRapidTongueTwisterRace => 'أتقن الجمل الصعبة النطق';

  @override
  String get gmNameEmojiTranslator => 'مترجم الرموز التعبيرية';

  @override
  String get gmDescEmojiTranslator => 'ترجم الرموز التعبيرية';

  @override
  String get gmNameRhythmTyping => 'الكتابة على الإيقاع';

  @override
  String get gmDescRhythmTyping => 'اكتب على الإيقاع';

  @override
  String get gmNameEldersBlessingsChallenge => 'بركات الكبار';

  @override
  String get gmDescEldersBlessingsChallenge => 'تعلّم عبارات البركة';

  @override
  String get gmNameMultilingualRelayRace => 'تتابع متعدد اللغات';

  @override
  String get gmDescMultilingualRelayRace => 'سباق تتابع بين اللغات';

  @override
  String get gmNameCulturalEtiquetteScenarios => 'آداب ثقافية';

  @override
  String get gmDescCulturalEtiquetteScenarios => 'تعلّم آداب التعامل';

  @override
  String get gmNameDrumToWordMatching => 'مطابقة الطبل والكلمات';

  @override
  String get gmDescDrumToWordMatching => 'طابق أنماط الطبل';

  @override
  String get gmNameMarketMonopolyChallenge => 'احتكار السوق';

  @override
  String get gmDescMarketMonopolyChallenge => 'مفاوضات استراتيجية في السوق';

  @override
  String get gmNameAyoMancala => '⁦Ayo⁩ (منقلة)';

  @override
  String get gmDescAyoMancala => 'لعبة لوحية تقليدية مع مفردات';

  @override
  String get gmNameSuweHopscotch => '⁦Suwe⁩ (الحجلة)';

  @override
  String get gmDescSuweHopscotch => 'ارمِ الحجر وتابع النغمات على الشبكة';

  @override
  String get gmNameLudoLanguage => 'لودو اللغات';

  @override
  String get gmDescLudoLanguage => 'لودو أفريقي بحركات تفتحها أسئلة اختيار';

  @override
  String get gmNameSnakesAndLaddersCultural => 'السلالم والثعابين (ثقافية)';

  @override
  String get gmDescSnakesAndLaddersCultural =>
      'سلالم الأمثال وثعابين تصحيح الأخطاء';

  @override
  String get gmNameWhotCardGame => '⁦Whot⁩ (ورق نيجيري)';

  @override
  String get gmDescWhotCardGame => 'قواعد ⁦Whot⁩ كاملة مع كلمة لكل ورقة';

  @override
  String get gcTitle => 'الدردشة العامة';

  @override
  String get gcChannelGeneral => 'عام';

  @override
  String get gcChannels => 'القنوات';

  @override
  String get gcSwitchChannel => 'تبديل القناة';

  @override
  String get gcRefresh => 'تحديث';

  @override
  String get gcFindUser => 'ابحث عن شخص';

  @override
  String get gcMore => 'المزيد';

  @override
  String get gcGuidelines => 'إرشادات المجتمع';

  @override
  String get gcMutedBlocked => 'المكتومون والمحظورون';

  @override
  String get gcPolieTitle => 'تدرّب على انفراد مع ⁦Polie⁩ (ذكاء اصطناعي)';

  @override
  String get gcPolieSub => 'لا تُنشر رسائلك في القنوات';

  @override
  String get gcEmptyTitle => 'لا توجد رسائل بعد';

  @override
  String get gcEmptyBody => 'ألقِ التحية وابدأ المحادثة.';

  @override
  String get gcSayHello => 'ألقِ التحية';

  @override
  String get gcHelloText => 'مرحبًا بالجميع! سعيد بالتعلّم معكم.';

  @override
  String get gcErrorTitle => 'تعذّر تحميل الرسائل';

  @override
  String get gcErrorBody => 'تحقّق من اتصالك وحاول مجددًا.';

  @override
  String get gcRetry => 'إعادة المحاولة';

  @override
  String get gcOffline => 'غير متصل · عرض الرسائل المحفوظة';

  @override
  String gcHidden(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n رسالة مخفية من أشخاص مكتومين أو محظورين',
      many: '$n رسالة مخفية من أشخاص مكتومين أو محظورين',
      few: '$n رسائل مخفية من أشخاص مكتومين أو محظورين',
      two: 'رسالتان مخفيتان من أشخاص مكتومين أو محظورين',
      one: 'رسالة واحدة مخفية من أشخاص مكتومين أو محظورين',
    );
    return '$_temp0';
  }

  @override
  String get gcManage => 'إدارة';

  @override
  String get gcHint => 'اكتب رسالة… (⁦@Polie⁩ للمساعدة)';

  @override
  String get gcSend => 'إرسال';

  @override
  String get gcSending => 'جارٍ الإرسال…';

  @override
  String get gcYou => 'أنت';

  @override
  String get gcNow => 'الآن';

  @override
  String gcMinAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n دقيقة',
      many: '$n دقيقة',
      few: '$n دقائق',
      two: 'دقيقتان',
      one: 'دقيقة',
    );
    return '$_temp0';
  }

  @override
  String gcHourAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ساعة',
      many: '$n ساعة',
      few: '$n ساعات',
      two: 'ساعتان',
      one: 'ساعة',
    );
    return '$_temp0';
  }

  @override
  String get gcFlagged => 'أخفاه فريق الإشراف';

  @override
  String get gcShow => 'إظهار';

  @override
  String get gcSendFailed => 'لم تُرسل الرسالة. تحقّق من اتصالك.';

  @override
  String get gcPolieBusy => 'طلبات كثيرة إلى ⁦@Polie⁩. حاول بعد دقيقة تقريبًا.';

  @override
  String get gcSignIn => 'سجّل الدخول لإرسال الرسائل.';

  @override
  String gcActionsFor(String name) {
    return 'رسالة من $name';
  }

  @override
  String get gcMute => 'كتم';

  @override
  String get gcMuteSub => 'إخفاء رسائله على هذا الجهاز دون إبلاغه.';

  @override
  String get gcUnmute => 'إلغاء الكتم';

  @override
  String get gcReport => 'إبلاغ';

  @override
  String get gcReportSub => 'يراجع المشرفون كل بلاغ.';

  @override
  String get gcBlock => 'حظر';

  @override
  String get gcBlockSub => 'لن ترى رسائله ولقطاته في أي مكان.';

  @override
  String gcBlockConfirm(String name) {
    return 'حظر $name؟';
  }

  @override
  String get gcBlockConfirmBody =>
      'لن ترى رسائله أو لقطاته الجديدة. يمكنك إلغاء الحظر لاحقًا.';

  @override
  String get gcCancel => 'إلغاء';

  @override
  String get gcReasonTitle => 'لماذا تبلغ عن هذه الرسالة؟';

  @override
  String get gcReasonHarassment => 'تحرّش';

  @override
  String get gcReasonSpam => 'رسائل مزعجة';

  @override
  String get gcReasonHate => 'خطاب كراهية';

  @override
  String get gcReasonOther => 'شيء آخر';

  @override
  String gcReportSent(String ref) {
    return 'أُرسل البلاغ. المرجع $ref';
  }

  @override
  String get gcReportFailed => 'تعذّر إرسال البلاغ. حاول مجددًا.';

  @override
  String gcBlockedNote(String name) {
    return 'تم حظر $name';
  }

  @override
  String get gcBlockFailed => 'تعذّر الحظر. حاول مجددًا.';

  @override
  String gcMutedNote(String name) {
    return 'تم كتم $name';
  }

  @override
  String get gcMutedTitle => 'المكتومون';

  @override
  String get gcBlockedTitle => 'المحظورون';

  @override
  String get gcNobody => 'لا أحد';

  @override
  String get gcUnblock => 'إلغاء الحظر';

  @override
  String get gcProfileUnavailable => 'الملف الشخصي غير متاح لهذه الرسالة.';

  @override
  String get gcLockedTeenTitle => 'الدردشة العامة متاحة من سن 18';

  @override
  String get gcLockedTeenBody =>
      'حفاظًا على سلامتك، الدردشة المفتوحة مع الغرباء مخصّصة للبالغين. ما زال بإمكانك التدرّب مع ⁦Polie⁩ ومع صفّك.';

  @override
  String get gcLockedChildTitle => 'الدردشة العامة غير متاحة';

  @override
  String get gcLockedChildBody =>
      'لا يمكن لحسابات الأطفال استخدام الدردشة المفتوحة. واصل التعلّم بالدروس والألعاب و⁦Polie⁩.';

  @override
  String get gcLockedUnknownTitle => 'نحتاج إلى معرفة عمرك أولًا';

  @override
  String get gcLockedUnknownBody =>
      'الدردشة العامة للبالغين. ستظهر هنا بعد تأكيد عمر حسابك.';

  @override
  String get gcPracticePolie => 'تدرّب مع ⁦Polie⁩';

  @override
  String get gcChecking => 'جارٍ التحقق من الوصول…';

  @override
  String gcMessagesLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n رسالة',
      many: '$n رسالة',
      few: '$n رسائل',
      two: 'رسالتان',
      one: 'رسالة واحدة',
      zero: 'لا رسائل',
    );
    return '$_temp0';
  }

  @override
  String gcOpenProfile(String name) {
    return 'فتح ملف $name';
  }

  @override
  String get rbReasons => 'أسباب الإبلاغ';

  @override
  String get rbSendReport => 'إرسال البلاغ';

  @override
  String get rbSending => 'جارٍ إرسال البلاغ';

  @override
  String rbReceived(String ref) {
    return 'تم استلام البلاغ. المرجع $ref';
  }

  @override
  String get rbSendFailed => 'تعذّر الإرسال. حاول مرة أخرى.';

  @override
  String get rbBlockConfirm =>
      'هل تريد حظر هذا الشخص؟ لن ترى رسائله أو لقطاته الجديدة.';

  @override
  String get rbConfirmBlock => 'تأكيد الحظر';

  @override
  String get rbBlockUser => 'حظر المستخدم';

  @override
  String get rbBlockedNote => 'تم الحظر. لن ترى رسائله الجديدة.';

  @override
  String get rbBlockFailed => 'تعذّر حظر هذا الشخص. حاول مرة أخرى.';

  @override
  String get rbBlockedPeople => 'الأشخاص المحظورون';

  @override
  String get rbNoBlocked => 'لا يوجد أشخاص محظورون';

  @override
  String get rbHate => 'كراهية';

  @override
  String get rbOther => 'أخرى';

  @override
  String gcHeroTitle(String channel) {
    return 'مرحبًا بك في #$channel';
  }

  @override
  String gcHeroBody(String channel) {
    return 'هذه بداية #$channel. كن لطيفًا: يراجع المشرفون كل بلاغ.';
  }

  @override
  String gcGreetingIn(String greeting) {
    return 'قلها كأهلها: $greeting';
  }

  @override
  String get gcHintShort => 'رسالة';

  @override
  String get gcErrorServerTitle => 'لم تُحمَّل الدردشة العامة';

  @override
  String get gcErrorServerBody =>
      'حدث خطأ من جهتنا. لم يضِع شيء مما كتبته. حاول مرة أخرى بعد قليل.';

  @override
  String get gfamToolsTitle => 'أدوات العائلة';

  @override
  String get gfamToolsApprovals => 'موافقات المجموعات';

  @override
  String get gfamToolsApprovalsSub => 'حلقات وفصول بانتظارك';

  @override
  String get gfamToolsGuide => 'كيف تعمل الرسائل';

  @override
  String get gfamToolsGuideSub => 'ما الذي يُفحص ومن يمكنه المراسلة';

  @override
  String get gfamToolsCircles => 'الحلقات';

  @override
  String get gfamToolsCirclesSub => 'حلقات الدراسة التي تنتمي إليها';

  @override
  String gfamWhoMessages(int id) {
    return 'من يراسل المتعلم رقم $id';
  }

  @override
  String get gdmTitle => 'من يراسل متعلمك';

  @override
  String get gdmIntro => 'ترى من ومتى وأي بلاغات. لا ترى نص الرسائل أبدًا.';

  @override
  String get gdmEmptyTitle => 'لا توجد رسائل خاصة بعد';

  @override
  String get gdmEmptyBody =>
      'يمكن فقط للمعلمين وأعضاء المجموعات التي وافقت عليها مراسلة متعلمك.';

  @override
  String get gdmError => 'تعذّر تحميل الرسائل. حاول مرة أخرى.';

  @override
  String get gdmRetry => 'حاول مرة أخرى';

  @override
  String get gdmRoleTeacher => 'معلم';

  @override
  String get gdmRoleClassmate => 'زميل';

  @override
  String get gdmRoleContact => 'جهة اتصال';

  @override
  String gdmLastActive(String when) {
    return 'آخر رسالة $when';
  }

  @override
  String gdmMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count رسالة',
      many: '$count رسالة',
      few: '$count رسائل',
      two: 'رسالتان',
      one: 'رسالة واحدة',
      zero: 'لا رسائل',
    );
    return '$_temp0';
  }

  @override
  String gdmReports(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بلاغ',
      many: '$count بلاغًا',
      few: '$count بلاغات',
      two: 'بلاغان',
      one: 'بلاغ واحد',
      zero: 'لا بلاغات',
    );
    return '$_temp0';
  }

  @override
  String gdmBlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'أُوقفت $count رسائل بفحوص الأمان',
      one: 'أُوقفت رسالة واحدة بفحوص الأمان',
    );
    return '$_temp0';
  }

  @override
  String gdmHeld(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صور أو رسائل صوتية بانتظار المشرف',
      one: 'صورة أو رسالة صوتية واحدة بانتظار المشرف',
    );
    return '$_temp0';
  }

  @override
  String get gdmStop => 'إيقاف الرسائل';

  @override
  String get gdmAllow => 'السماح مرة أخرى';

  @override
  String get gdmStopped => 'الرسائل موقوفة';

  @override
  String gdmStopConfirmTitle(String name) {
    return 'إيقاف الرسائل من $name؟';
  }

  @override
  String get gdmStopConfirmBody =>
      'لن يتمكن من مراسلة متعلمك، ولن يتمكن متعلمك من مراسلته. يمكنك السماح مجددًا لاحقًا.';

  @override
  String get gdmCancel => 'إلغاء';

  @override
  String get gdmActionFailed => 'لم ينجح ذلك. حاول مرة أخرى.';

  @override
  String get gdmUnknownName => 'مستخدم غير معروف';

  @override
  String get gccJoinButton => 'أدخل رمز الفصل';

  @override
  String get gccTitle => 'الانضمام إلى فصل';

  @override
  String get gccHint => 'اطلب رمز الفصل من معلمك.';

  @override
  String get gccLabel => 'رمز الفصل';

  @override
  String get gccSubmit => 'انضمام';

  @override
  String get gccJoined => 'انضممت إلى الفصل.';

  @override
  String get gccWaitingTitle => 'بانتظار وليّ أمرك';

  @override
  String get gccWaitingBody =>
      'طلبنا من وليّ أمرك الموافقة على هذا الفصل. يمكنك الانضمام بعد موافقته.';

  @override
  String get gccNeedLink =>
      'اطلب أولًا من أحد الوالدين أو وليّ الأمر ربط حسابك في مركز العائلة.';

  @override
  String get gccNeedAge => 'أكّد عمرك في الإعدادات قبل الانضمام إلى فصل.';

  @override
  String get gccNotFound => 'لا يوجد فصل بهذا الرمز. تحقق منه مع معلمك.';

  @override
  String get gccAlready => 'أنت بالفعل في هذا الفصل.';

  @override
  String get gccError => 'تعذّر الانضمام الآن. حاول مرة أخرى.';

  @override
  String get gccEmpty => 'أدخل الرمز أولًا.';

  @override
  String get gccDone => 'تم';

  @override
  String get gtpTitle => 'طلبات الطلاب';

  @override
  String get gtpOpen => 'طلبات الطلاب';

  @override
  String get gtpWaitingSection => 'بانتظار وليّ الأمر';

  @override
  String get gtpWaitingHelp =>
      'استخدم هؤلاء الطلاب رمز فصلك. يقرر وليّ الأمر؛ لا تحتاج لفعل شيء.';

  @override
  String get gtpWaitingEmpty => 'لا أحد ينتظر.';

  @override
  String get gtpSchoolSection => 'حسابات المدرسة';

  @override
  String get gtpSchoolHelp =>
      'رسائل المعلم مغلقة حتى تفعّلها لكل طالب. أنت فقط يمكنك مراسلتهم، وتُفحص كل رسالة.';

  @override
  String get gtpSchoolEmpty => 'لا توجد حسابات مدرسية في هذا الفصل.';

  @override
  String get gtpTeacherDm => 'رسائل المعلم';

  @override
  String get gtpPendingConsent => 'موافقة المدرسة معلّقة';

  @override
  String gtpStudent(int id) {
    return 'الطالب رقم $id';
  }

  @override
  String gtpSince(String when) {
    return 'طُلب $when';
  }

  @override
  String get gtpError => 'تعذّر تحميل الطلبات. حاول مرة أخرى.';

  @override
  String get gtpNotTeacher => 'فقط معلم هذا الفصل يمكنه رؤية الطلبات.';

  @override
  String get gccClose => 'إغلاق';

  @override
  String get gccOpenFamilyHub => 'افتح مركز العائلة';

  @override
  String get gtpEmptyTitle => 'لا توجد طلبات من الطلاب بعد';

  @override
  String get gtpEmptyBody => 'شارك رمز الفصل. سيظهر هنا الطلاب الذين ينضمون.';

  @override
  String get gtpLocked => 'مقفل حتى تؤكد المدرسة الموافقة';

  @override
  String get gmeTitle => 'كيف تعمل الرسائل للمتعلمين الصغار';

  @override
  String get gmeBody =>
      'رسائل المتعلمين دون 18 عامًا ليست مشفرة من طرف إلى طرف، حتى تتمكن الفحوصات الآلية والمشرفون من التدخل قبل وصول أي محتوى ضار.';

  @override
  String get gmeModHeading => 'ما قد يراجعه المشرفون';

  @override
  String get gmeMod1 => 'نص الرسائل في المحادثات التي وافقت عليها';

  @override
  String get gmeMod2 => 'إشارات الأمان من الفحص الآلي';

  @override
  String get gmeMod3 => 'البلاغات من المتعلمين أو أولياء الأمور';

  @override
  String get gmeTradeoff =>
      'المحادثات المشفرة بين البالغين تخفي المحتوى عن الإشراف؛ أما حسابات الأطفال فتبقى على مراسلة خاضعة للإشراف.';

  @override
  String get gmeLoadError =>
      'تعذّر تحميل هذا الدليل الآن. اسحب للتحديث أو حاول مرة أخرى عند الاتصال.';

  @override
  String get gmeOffline => 'أنت غير متصل. نعرض آخر شرح محفوظ.';

  @override
  String get gmeLoading => 'جارٍ تحميل دليل الرسائل';

  @override
  String get gmeRetry => 'حاول مرة أخرى';

  @override
  String get gmeTileTitle => 'كيف تبقى رسائل المتعلمين آمنة';

  @override
  String get gmeTileSubtitle => 'لماذا تخضع المحادثات للإشراف ولا تُشفَّر';

  @override
  String get gcirTitle => 'حلقاتك';

  @override
  String get gcirLoadError => 'تعذّر تحميل حلقاتك الآن.';

  @override
  String get gcirOffline => 'أنت غير متصل. ستظهر حلقاتك عند إعادة الاتصال.';

  @override
  String get gcirRetry => 'حاول مرة أخرى';

  @override
  String get gcirEmpty =>
      'ابدأ حلقة دراسة أو انضم إلى قرية لغوية لتتعلموا معًا.';

  @override
  String get gcirEmptyTitle => 'لا توجد حلقات بعد';

  @override
  String gcirOpen(int count, int max) {
    return '$count من $max أعضاء · مفتوحة';
  }

  @override
  String gcirFull(int count) {
    return 'مكتملة · $count أعضاء';
  }

  @override
  String gcirOpensAt(int count, int min) {
    return '$count أعضاء · تُفتح عند $min';
  }

  @override
  String get gcirFallbackName => 'حلقة';

  @override
  String get gapTitle => 'موافقات المجموعات';

  @override
  String get gapLearnerFallback => 'متعلّمك';

  @override
  String get gapDenyConfirmTitle => 'هل ترفض هذا الطلب؟';

  @override
  String gapDenyConfirmBody(String child, String group) {
    return 'لن ينضم $child إلى $group. يمكنه الطلب مرة أخرى لاحقًا.';
  }

  @override
  String get gapCancel => 'إلغاء';

  @override
  String get gapDeny => 'رفض';

  @override
  String get gapApprove => 'موافقة';

  @override
  String get gapRevoke => 'إلغاء الموافقة';

  @override
  String gapApprovedToast(String group) {
    return 'تمت الموافقة: $group';
  }

  @override
  String gapDeniedToast(String group) {
    return 'تم الرفض: $group';
  }

  @override
  String gapRevokedToast(String group) {
    return 'أُلغيت الموافقة: $group';
  }

  @override
  String get gapActionFailed => 'لم يكتمل الإجراء. يُرجى المحاولة مرة أخرى.';

  @override
  String get gapReview => 'بانتظار مراجعتك';

  @override
  String get gapDecided => 'تم البتّ فيها';

  @override
  String get gapLoadError =>
      'تعذّر تحميل الموافقات. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get gapEmptyTitle => 'لا توجد طلبات حاليًا';

  @override
  String get gapEmptyBody =>
      'عندما يطلب متعلّمك الانضمام إلى حلقة أو صف، سيظهر الطلب هنا لتوافق عليه أو ترفضه.';

  @override
  String get gapRefresh => 'تحديث';

  @override
  String get gapOffline => 'أنت غير متصل. نعرض آخر قائمة تم تحميلها.';

  @override
  String get gapLoading => 'جارٍ تحميل الموافقات';

  @override
  String get gapRetry => 'إعادة المحاولة';

  @override
  String get gapStatusApproved => 'مقبول';

  @override
  String get gapStatusExpired => 'منتهي';

  @override
  String get gapStatusRevoked => 'ملغى';

  @override
  String get gapStatusDenied => 'مرفوض';

  @override
  String get gapStatusReapprove => 'تحتاج موافقة جديدة';

  @override
  String get gapStatusWaiting => 'بانتظارك';

  @override
  String get gapModerated => 'تُراجع الرسائل من قبل المشرفين';

  @override
  String get gapApprovalRequired => 'الانضمام يتطلب موافقتك';

  @override
  String get gapOpenCommunity => 'مجتمع مفتوح';

  @override
  String get gapKindCircle => 'حلقة';

  @override
  String get gapKindClassroom => 'صف';

  @override
  String gapWhyCircle(String child, String group) {
    return 'يريد $child الانضمام إلى حلقة $group';
  }

  @override
  String gapWhyClass(String child, String group) {
    return 'يريد $child الانضمام إلى صف $group';
  }

  @override
  String gapMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count عضوًا',
      few: '$count أعضاء',
      two: 'عضوان',
      one: 'عضو واحد',
    );
    return '$_temp0';
  }

  @override
  String gapAdults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count بالغًا',
      few: '$count بالغين',
      two: 'بالغان',
      one: 'بالغ واحد',
      zero: 'لا بالغين',
    );
    return '$_temp0';
  }

  @override
  String gapExpires(String date) {
    return 'تنتهي الموافقة في $date';
  }

  @override
  String get gccFormatHint => 'من 6 إلى 8 أحرف أو أرقام، من معلّمك';

  @override
  String get gccChecking => 'جارٍ التحقق من الرمز…';

  @override
  String get gcirLoading => 'جارٍ تحميل الحلقات';

  @override
  String get gcirJoinWithCode => 'انضم برمز الصف';

  @override
  String get gcirExplore => 'استكشف القرى';

  @override
  String get gcirPillOpen => 'مفتوحة';

  @override
  String get gcirPillFull => 'ممتلئة';

  @override
  String get gcirPillSoon => 'تبدأ قريبًا';

  @override
  String get gdmLoading => 'جارٍ تحميل جهات الاتصال';

  @override
  String gdmTitleFor(String name) {
    return 'من يراسل $name';
  }

  @override
  String get gfamHubTitle => 'مركز العائلة';

  @override
  String get gfamModeHub => 'مركز وليّ الأمر';

  @override
  String get gfamModeInvite => 'دعوة المتعلّم';

  @override
  String get gfamStatusActive => 'مقبول';

  @override
  String get gfamStatusVerifying => 'يحتاج إلى موافقتك';

  @override
  String get gfamStatusWithdrawn => 'سُحبت الموافقة';

  @override
  String gfamWhoMessagesName(String name) {
    return 'من يراسل $name';
  }

  @override
  String get gfamWhoMessagesYours => 'من يراسل متعلّمك';

  @override
  String get gmeSecCheckedTitle => 'تُفحص الرسائل أولًا';

  @override
  String get gmeSecHeldTitle =>
      'الصور والرسائل الصوتية والروابط تنتظر المراجعة';

  @override
  String get gmeSecHeldBody =>
      'عندما يرسل شخص بالغ صورة أو رسالة صوتية أو رابطًا إلى متعلّم صغير، يُحجز حتى يراجعه مشرف. لا يراه متعلّمك إلا بعد الموافقة عليه.';

  @override
  String get gmeSecStopTitle => 'يمكنك إيقاف جهة اتصال';

  @override
  String get gmeSecStopBody =>
      'في مركز العائلة، افتح الرسائل واختر إيقاف. لن يتمكن ذلك الشخص من مراسلة متعلّمك بعد ذلك.';

  @override
  String get gmeSecTeacherTitle => 'يحتاج المعلّمون إلى موافقتك';

  @override
  String get gmeSecTeacherBody =>
      'لا يمكن للمعلّم مراسلة متعلّمك إلا في صف وافقت عليه، أو عندما تملك المدرسة الموافقة ويفعّل المعلّم الرسائل. ينتهي هذا الإذن في تاريخ انتهائه.';

  @override
  String gtpDmOnTitle(String name) {
    return 'هل تفعّل الرسائل مع $name؟';
  }

  @override
  String gtpDmOffTitle(String name) {
    return 'هل توقف الرسائل مع $name؟';
  }

  @override
  String get gtpDmOnBody =>
      'تغطي موافقة المدرسة ذلك. تبقى الرسائل خاضعة للمراجعة، ويستمر ذلك عامًا واحدًا ما لم توقفه.';

  @override
  String get gtpDmOffBody => 'لن تتمكن بعد ذلك من مراسلة هذا الطالب مباشرة.';

  @override
  String get gtpDmOnAction => 'تفعيل';

  @override
  String get gtpDmOffAction => 'إيقاف';

  @override
  String gtpDmUntil(String date) {
    return 'الرسائل مفعّلة حتى $date';
  }

  @override
  String get gtpLoading => 'جارٍ تحميل الطلاب';

  @override
  String get gfamModeHubLabel => 'مركز وليّ الأمر، عرض المتعلّمين المرتبطين';

  @override
  String get gfamModeInviteLabel => 'دعوة المتعلّم، إنشاء رمز للمشاركة';

  @override
  String get gfamInviteSectionTitle => 'هل ينتظرك متعلّم؟';

  @override
  String get gfamAcceptInviteHint =>
      'الصق رمز الدعوة من تطبيق LingAfriq الخاص به.';

  @override
  String get gfamInviteCodeLabel => 'رمز الدعوة';

  @override
  String get gfamYourNameHint => 'اسمك (يظهر للمتعلّم)';

  @override
  String get gfamLinkedLearners => 'المتعلّمون المرتبطون';

  @override
  String get gfamLinkLearner => 'اربط المتعلّم';

  @override
  String get gdmEmptyAction => 'كيف تعمل الرسائل';

  @override
  String gccJoinedNamed(String className) {
    return 'انضممت إلى $className';
  }

  @override
  String get gccJoinedNext =>
      'يمكن لمعلّمك الآن مشاركة الدروس والرسائل معك هنا.';

  @override
  String gcirLastActivity(String date) {
    return 'آخر نشاط $date';
  }

  @override
  String get gfamRegimeNdpa => 'قانون حماية البيانات في نيجيريا (2023)';

  @override
  String get gfamRegimeOther => 'قواعد خصوصية الأطفال';

  @override
  String get gfamMembersTitle => 'عائلتك';

  @override
  String get gfamYou => 'أنت';

  @override
  String get gfamYouInitial => 'أ';

  @override
  String get gfamRoleGuardian => 'ولي الأمر';

  @override
  String get gfamRoleLearner => 'متعلم';

  @override
  String gfamNeedsYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلبات بانتظارك',
      one: 'طلب واحد بانتظارك',
    );
    return '$_temp0';
  }

  @override
  String get gfamNeedsYouAction => 'مراجعة';

  @override
  String get gapNotNow => 'ليس الآن';

  @override
  String get gapNotNowToast => 'حُفظ لوقت لاحق. يبقى في قائمتك.';

  @override
  String get gapShowAgain => 'إظهار';

  @override
  String gapApprovingAs(String name) {
    return 'أنت توافق بصفتك $name (ولي الأمر)';
  }

  @override
  String get gapApprovingAsYou => 'أنت توافق بصفتك ولي الأمر في هذا الحساب';

  @override
  String gapAudit(String status, String time) {
    return '$status بواسطتك · $time';
  }

  @override
  String gapAuditThisPhone(String status, String time) {
    return '$status بواسطتك · $time · هذا الهاتف';
  }

  @override
  String get gapPendingSync => 'بانتظار المزامنة';

  @override
  String get gapSavedOffline =>
      'حُفظ دون اتصال. سنرسله عند عودتك إلى الإنترنت.';

  @override
  String gdmSummary(int count, int fresh) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جهات اتصال',
      one: 'جهة اتصال واحدة',
    );
    return '$_temp0 · $fresh جديدة هذا الأسبوع';
  }

  @override
  String get gdmFilterAll => 'الكل';

  @override
  String get gdmFilterNew => 'جديد';

  @override
  String get gdmFilterStopped => 'متوقف';

  @override
  String get gdmFilterMedia => 'وسائط بانتظار المراجعة';

  @override
  String get gdmFilterEmpty => 'لا توجد جهات اتصال مطابقة لهذا الفلتر.';

  @override
  String gdmStoppedToast(String name) {
    return 'لم يعد بإمكان $name مراسلة المتعلم';
  }

  @override
  String get gdmUndo => 'تراجع';

  @override
  String get gccCheck => 'تحقّق من الرمز';

  @override
  String get gccPreviewTitle => 'هل هذا فصلك؟';

  @override
  String gccPreviewTeacher(String name) {
    return 'المعلّم: $name';
  }

  @override
  String gccPreviewMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count متعلمين',
      one: 'متعلم واحد',
      zero: 'لا متعلمين بعد',
    );
    return '$_temp0';
  }

  @override
  String get gccPreviewChange => 'استخدم رمزًا آخر';

  @override
  String get gtpVerified => 'موثّق من المدرسة';

  @override
  String gtpAllowUntil(String date) {
    return 'مسموح حتى $date';
  }

  @override
  String gtpExpiresIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ينتهي خلال $count أيام',
      one: 'ينتهي خلال يوم واحد',
      zero: 'ينتهي اليوم',
    );
    return '$_temp0';
  }

  @override
  String get commonActionContinue => 'Continue';

  @override
  String get commonActionSave => 'Save';

  @override
  String get commonActionTryAgain => 'Try again';

  @override
  String get commonActionClose => 'Close';

  @override
  String get commonActionShowMore => 'Show more';

  @override
  String get commonStateUnavailable => 'Unavailable';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingSelectBirthYear => 'Select birth year';

  @override
  String onboardingBirthYearValue(String value) {
    return 'Birth year, $value';
  }

  @override
  String get onboardingContinueToLessons => 'Continue to lessons';

  @override
  String get onboardingWeCouldNotSaveThatYear =>
      'We could not save that year. Try again.';

  @override
  String get onboardingChooseTheYearYouWereBorn =>
      'Choose the year you were born to continue.';

  @override
  String get onboardingYourAccountIsReadyForLessons =>
      'Your account is ready for lessons, but chat, Village, and purchases stay paused until a guardian approves.';

  @override
  String get onboardingWeNeedAGuardian => 'We need a guardian';

  @override
  String get onboardingYouAlreadyEnteredABirthYear =>
      'You already entered a birth year on this device. If something looks wrong, ask a guardian to help from their account.';

  @override
  String get onboardingWeUseThisToKeepLearners =>
      'We use this to keep learners safe and unlock the right features for your age. We only ask for the year, and we store your age group, not the year itself.';

  @override
  String get onboardingWhatYearWereYouBorn => 'What year were you born?';

  @override
  String onboardingPendingsyncsPendingSyncValue(
    String pendingSyncs,
    String value,
  ) {
    return '$pendingSyncs pending sync$value';
  }

  @override
  String get onboardingCouldNotVerifyAvailabilityYouCan =>
      'Could not verify availability. You can still continue.';

  @override
  String get onboardingOnlyLettersNumbersAndUnderscoresAre =>
      'Only letters, numbers, and underscores are allowed';

  @override
  String get onboardingUsernameMustBe30CharactersOr =>
      'Username must be 30 characters or less';

  @override
  String get onboardingUsernameMustBeAtLeast3 =>
      'Username must be at least 3 characters';

  @override
  String get onboardingUsernameIsAlreadyTaken => '✗ Username is already taken';

  @override
  String get onboardingUsernameIsAvailable => '✓ Username is available';

  @override
  String get onboardingCheckingAvailability => 'Checking availability...';

  @override
  String get onboardingEnterAUsername330Characters =>
      'Enter a username (3-30 characters, letters, numbers, and underscores only)';

  @override
  String get onboardingCompleteOnboarding => 'Complete Onboarding';

  @override
  String get onboardingChooseAUniqueUsername => 'Choose a unique username';

  @override
  String get onboardingUsername => 'Username';

  @override
  String get onboardingChangeAvatar => 'Change Avatar';

  @override
  String get onboardingSetYourUsernameAvatarIsOptional =>
      'Set your username (avatar is optional)';

  @override
  String get onboardingCompleteYourProfile => 'Complete Your Profile';

  @override
  String get onboardingEnableReminders => 'Enable Reminders';

  @override
  String get onboardingPreferredTimeOfDay => 'Preferred Time of Day';

  @override
  String onboardingValueMinutesPerDay(String value) {
    return '$value minutes per day';
  }

  @override
  String onboardingValueMinutes(String value) {
    return '$value minutes';
  }

  @override
  String get onboardingDailyDurationMinutes => 'Daily Duration (minutes)';

  @override
  String get onboardingWhenAndHowLongDoYou =>
      'When and how long do you want to learn?';

  @override
  String get onboardingSetYourLearningSchedule => 'Set your learning schedule';

  @override
  String get onboardingHowShouldPolieCommunicateWithYou =>
      'How should Polie communicate with you?';

  @override
  String get onboardingWhatToneDoYouPrefer => 'What tone do you prefer?';

  @override
  String get onboardingHowFastDoYouWantTo => 'How fast do you want to learn?';

  @override
  String get onboardingWhatPaceDoYouPrefer => 'What pace do you prefer?';

  @override
  String get onboardingSelectYourPreferredLearningStyle =>
      'Select your preferred learning style';

  @override
  String get onboardingHowDoYouLearnBest => 'How do you learn best?';

  @override
  String get onboardingChooseYourMainLearningObjective =>
      'Choose your main learning objective';

  @override
  String get onboardingWhatSYourPrimaryGoal => 'What\'s your primary goal?';

  @override
  String get onboardingChooseYourDailyLearningGoal =>
      'Choose your daily learning goal';

  @override
  String get onboardingHowMuchTimeCanYouCommit =>
      'How much time can you commit daily?';

  @override
  String get onboardingDedicatedStudy => 'Dedicated study';

  @override
  String get onboardingText20Min => '20 min';

  @override
  String get onboardingBalanced => 'Balanced';

  @override
  String get onboardingText15Min => '15 min';

  @override
  String get onboardingLightLearning => 'Light learning';

  @override
  String get onboardingText10Min => '10 min';

  @override
  String get onboardingQuickPractice => 'Quick practice';

  @override
  String get onboardingText5Min => '5 min';

  @override
  String get onboardingSelectAllThatApply => 'Select all that apply';

  @override
  String get onboardingWhyAreYouLearning => 'Why are you learning?';

  @override
  String get onboardingThisHelpsUsPersonalizeYourExperience =>
      'This helps us personalize your experience';

  @override
  String get onboardingWhatSYourAgeCategory => 'What\'s your age category?';

  @override
  String get onboardingSelectTheLanguageYouWantTo =>
      'Select the language you want to learn';

  @override
  String get onboardingWhatLanguageDoYouWishTo =>
      'What language do you wish to learn first?';

  @override
  String get onboardingXhosa => 'Xhosa';

  @override
  String get onboardingZulu => 'Zulu';

  @override
  String get onboardingSwahili => 'Swahili';

  @override
  String get onboardingNigerianPidginEnglish => 'Nigerian Pidgin English';

  @override
  String get onboardingIgbo => 'Igbo';

  @override
  String get onboardingHausa => 'Hausa';

  @override
  String get onboardingYoruba => 'Yoruba';

  @override
  String get onboardingHelpUsPersonalizeYourLearningExperienc =>
      'Help us personalize your learning experience';

  @override
  String get onboardingWhatSYourCurrentLevel => 'What\'s your current level?';

  @override
  String get onboardingISpeakThisLanguageNatively =>
      'I speak this language natively';

  @override
  String get onboardingNative => 'Native';

  @override
  String get onboardingIMQuiteFluent => 'I\'m quite fluent';

  @override
  String get onboardingAdvanced => 'Advanced';

  @override
  String get onboardingICanHaveBasicConversations =>
      'I can have basic conversations';

  @override
  String get onboardingIntermediate => 'Intermediate';

  @override
  String get onboardingIKnowAFewWords => 'I know a few words';

  @override
  String get onboardingElementary => 'Elementary';

  @override
  String get onboardingIMJustStartingOut => 'I\'m just starting out';

  @override
  String get onboardingBeginner => 'Beginner';

  @override
  String get onboardingContinueToNextStep => 'Continue to next step';

  @override
  String get onboardingSearchLanguages => 'Search languages...';

  @override
  String get onboardingSearchLanguagesea93 => 'Search languages';

  @override
  String get onboardingAllLanguages => 'All Languages';

  @override
  String onboardingShowAllLanguagesValueMore(String value) {
    return 'Show All Languages ($value more)';
  }

  @override
  String onboardingShowAllLanguagesValueMoreLanguages(String value) {
    return 'Show all languages. $value more languages available.';
  }

  @override
  String onboardingSelectValueAsProficiencyLanguageValue2(
    String value,
    String value2,
  ) {
    return 'Select $value as proficiency language. $value2';
  }

  @override
  String get onboardingPopularLanguages => 'Popular Languages';

  @override
  String get onboardingWeLlTranslateAllInApp =>
      'We\'ll translate all in-app content to this language';

  @override
  String get onboardingWhatLanguageDoYouSpeak => 'What language do you speak?';

  @override
  String get onboardingPolish => 'Polish';

  @override
  String get onboardingDutch => 'Dutch';

  @override
  String get onboardingTurkish => 'Turkish';

  @override
  String get onboardingRussian => 'Russian';

  @override
  String get onboardingHindi => 'Hindi';

  @override
  String get onboardingKorean => 'Korean';

  @override
  String get onboardingJapanese => 'Japanese';

  @override
  String get onboardingChinese => 'Chinese';

  @override
  String get onboardingItalian => 'Italian';

  @override
  String get onboardingGerman => 'German';

  @override
  String get onboardingBerber => 'Berber';

  @override
  String get onboardingArabic => 'Arabic';

  @override
  String get onboardingSango => 'Sango';

  @override
  String get onboardingKongo => 'Kongo';

  @override
  String get onboardingLingala => 'Lingala';

  @override
  String get onboardingChichewa => 'Chichewa';

  @override
  String get onboardingNdebele => 'Ndebele';

  @override
  String get onboardingSwati => 'Swati';

  @override
  String get onboardingTsonga => 'Tsonga';

  @override
  String get onboardingVenda => 'Venda';

  @override
  String get onboardingSetswana => 'Setswana';

  @override
  String get onboardingSesotho => 'Sesotho';

  @override
  String get onboardingAfrikaans => 'Afrikaans';

  @override
  String get onboardingSomali => 'Somali';

  @override
  String get onboardingOromo => 'Oromo';

  @override
  String get onboardingTigrinya => 'Tigrinya';

  @override
  String get onboardingAmharic => 'Amharic';

  @override
  String get onboardingKirundi => 'Kirundi';

  @override
  String get onboardingKinyarwanda => 'Kinyarwanda';

  @override
  String get onboardingLuganda => 'Luganda';

  @override
  String get onboardingLuo => 'Luo';

  @override
  String get onboardingKikuyu => 'Kikuyu';

  @override
  String get onboardingFon => 'Fon';

  @override
  String get onboardingEwe => 'Ewe';

  @override
  String get onboardingAkan => 'Akan';

  @override
  String get onboardingBambara => 'Bambara';

  @override
  String get onboardingFulfulde => 'Fulfulde';

  @override
  String get onboardingTwi => 'Twi';

  @override
  String get onboardingWolof => 'Wolof';

  @override
  String get onboardingNigerianPidgin => 'Nigerian Pidgin';

  @override
  String get onboardingSpanish => 'Spanish';

  @override
  String get onboardingPortuguese => 'Portuguese';

  @override
  String get onboardingFrench => 'French';

  @override
  String get onboardingEnglish => 'English';

  @override
  String get onboardingTakeTest => 'Take Test';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String onboardingWouldYouLikeToTakeA(String learningLanguage) {
    return 'Would you like to take a placement test to assess your current level in $learningLanguage? You can skip this and take it later.';
  }

  @override
  String get onboardingTakePlacementTest => 'Take Placement Test?';

  @override
  String onboardingProgresspercent(String progressPercent) {
    return '$progressPercent%';
  }

  @override
  String onboardingStepValueOfTotalsteps(String value, String totalSteps) {
    return 'Step $value of $totalSteps';
  }

  @override
  String get onboardingSkipOnboarding => 'Skip onboarding';

  @override
  String get onboardingOnboarding => 'Onboarding';

  @override
  String get onboardingGoBackToPreviousStep => 'Go back to previous step';

  @override
  String onboardingOnboardingProgressStepValueOfTotalstep(
    String value,
    String totalSteps,
    String progressPercent,
  ) {
    return 'Onboarding progress. Step $value of $totalSteps. $progressPercent percent complete.';
  }

  @override
  String get onboardingSkipTest => 'Skip test';

  @override
  String onboardingQuestionValueOfTotalquestions(
    String value,
    String totalQuestions,
  ) {
    return 'Question $value of $totalQuestions';
  }

  @override
  String get onboardingSkipForNowStartAsBeginner =>
      'Skip for now (start as beginner)';

  @override
  String get onboardingStartAssessment => 'Start Assessment';

  @override
  String get onboardingAnswer3QuickQuestionsToHelp =>
      'Answer 3 quick questions to help us personalize your learning journey.';

  @override
  String get onboardingLetUsSeeWhereYouStand =>
      'Let us see where you stand, traveler.';

  @override
  String get onboardingUnderstandComplexDiscussions =>
      'Understand complex discussions';

  @override
  String get onboardingUnderstandMostEverydayConversations =>
      'Understand most everyday conversations';

  @override
  String get onboardingUnderstandShortSimpleConversations =>
      'Understand short, simple conversations';

  @override
  String get onboardingUnderstandGreetingsAndSimpleWords =>
      'Understand greetings and simple words';

  @override
  String get onboardingCannotUnderstandAnything => 'Cannot understand anything';

  @override
  String get onboardingHowConfidentAreYouInUnderstanding =>
      'How confident are you in understanding spoken African languages?';

  @override
  String get onboardingICanReadFluently => 'I can read fluently';

  @override
  String get onboardingICanReadSentences => 'I can read sentences';

  @override
  String get onboardingICanReadSimpleWords => 'I can read simple words';

  @override
  String get onboardingICanRecognizeSomeLettersCharacters =>
      'I can recognize some letters/characters';

  @override
  String get onboardingNotAtAll => 'Not at all';

  @override
  String get onboardingCanYouReadOrWriteIn =>
      'Can you read or write in the African language you want to learn?';

  @override
  String get onboardingAdvancedSpeakFluently => 'Advanced - speak fluently';

  @override
  String get onboardingIntermediateCanHoldConversations =>
      'Intermediate - can hold conversations';

  @override
  String get onboardingBasicCanIntroduceMyself =>
      'Basic - can introduce myself';

  @override
  String get onboardingSomeExposureKnowAFewWords =>
      'Some exposure - know a few words';

  @override
  String get onboardingCompleteBeginnerNeverLearnedOne =>
      'Complete beginner - never learned one';

  @override
  String get onboardingHowWouldYouDescribeYourFamiliarity =>
      'How would you describe your familiarity with African languages?';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingEnterYourUsername => 'Enter your username';

  @override
  String get onboardingALearnerWithoutANameIs =>
      'A learner without a name is a drum without a rhythm!\nTell us what you wish to be called.';

  @override
  String get onboardingBuildYourClan => 'Build your clan.';

  @override
  String get onboardingIAmTheHealerLetMe =>
      'I am the Healer.\nLet me make your journey smooth.';

  @override
  String get onboardingGamification => 'Gamification';

  @override
  String get onboardingTonePreference => 'Tone Preference';

  @override
  String get onboardingIAmAminaTheGriotHow =>
      'I am Amina the Griot.\nHow shall I speak to you?';

  @override
  String get onboardingChooseYourPath => 'Choose your path.';

  @override
  String get onboardingBrainTraining => 'Brain Training';

  @override
  String get onboardingConfidence => 'Confidence';

  @override
  String get onboardingAcademic => 'Academic';

  @override
  String get onboardingBusiness => 'Business';

  @override
  String get onboardingHeritage => 'Heritage';

  @override
  String get onboardingTravel => 'Travel';

  @override
  String get onboardingIAmZawadiKeeperOfTime =>
      'I am Zawadi, keeper of time.\nWhen shall we train your tongue?';

  @override
  String get onboardingIAmNuruTheRhythmMaster =>
      'I am Nuru the Rhythm Master.\nTap the drum that sings to your spirit.';

  @override
  String get onboardingWhatSYourLevel => 'What\'s your level?';

  @override
  String get onboardingSelectLanguage => 'Select Language';

  @override
  String get onboardingIAmAdisaTheWeaverChoose =>
      'I am Adisa, the Weaver.\nChoose the threads of your voice.';

  @override
  String get onboardingTellMeWhoAreYou => 'Tell me: who are you?';

  @override
  String get onboardingWelcomeTravelerIAmPaLingafriq =>
      'Welcome, traveler. I am Pa LingAfriq,\nkeeper of the village memory.';

  @override
  String get onboardingBeginJourney => 'Begin Journey';

  @override
  String get onboardingTheLanguageVillageYourJourneyBegins =>
      'The Language Village\nYour journey begins here';

  @override
  String get onboardingWelcomeToKijijiChaLugha =>
      'Welcome to\nKijiji cha Lugha';

  @override
  String get onboardingLoading => 'Loading...';

  @override
  String get onboardingAlreadyLearningLogIn => 'Already learning? Log in';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get onboardingChooseYourPathAndUnlockNew =>
      'Choose your path and unlock new opportunities';

  @override
  String get onboardingYourLanguageJourneyStartsHere =>
      'Your Language Journey\nStarts Here!';

  @override
  String get onboardingPrioritizeHowYourCommunityReallySpeaks =>
      'Prioritize how your community really speaks';

  @override
  String get onboardingLocalDialectHeritage => 'Local Dialect & Heritage';

  @override
  String get onboardingPrepareForStudiesAndBroadenKnowledge =>
      'Prepare for studies and broaden knowledge';

  @override
  String get onboardingExcelAcademically => 'Excel Academically';

  @override
  String get onboardingOpenDoorsToInternationalOpportunities =>
      'Open doors to international opportunities';

  @override
  String get onboardingBoostYourCareer => 'Boost Your Career';

  @override
  String get onboardingDiscoverTheRichHeritageOfAfrican =>
      'Discover the rich heritage of African languages';

  @override
  String get onboardingExploreCultures => 'Explore Cultures';

  @override
  String get onboardingExplore54Countries2000LanguagesAnd =>
      'Explore 54 countries, 2000+ languages,\nand connect with 1+ billion voices';

  @override
  String get onboardingReadyForAPanAfricanAdventure =>
      'Ready for a\npan-African adventure?';

  @override
  String get onboardingLearnANewLanguageTheFun =>
      'Learn a new language,\nthe fun way';

  @override
  String get onboardingLearnAboutHistoryTraditionsAndCultural =>
      'Learn about history, traditions, and cultural expressions';

  @override
  String get onboardingConnectWithCulture => 'Connect with culture';

  @override
  String get onboardingStayMotivatedWithPersonalizedChallenge =>
      'Stay motivated with personalized challenges and daily goals';

  @override
  String get onboardingTrackYourProgress => 'Track your progress';

  @override
  String get onboardingFunBiteSizedLessonsMakeLearning =>
      'Fun, bite-sized lessons make learning addictive and effective';

  @override
  String get onboardingLearnLanguagesPlayGames => 'Learn languages, play games';

  @override
  String get onboardingDiscoverTheBeautyOfAfricanLanguages =>
      'Discover the beauty of African languages';

  @override
  String get onboardingYourJourneyToFluencyStartsNow =>
      'Your journey to fluency\nstarts now!';

  @override
  String get onboardingWhatDoWeOfferUniqely => 'What Do We Offer Uniqely';

  @override
  String get onboardingText54Countries2000Languages1Billion =>
      '54 countries, 2000+ languages, 1+ billion voices. One origin. ';

  @override
  String onboardingValueValue2(String value, String value2) {
    return '$value / $value2';
  }

  @override
  String get onboardingPlacementTest => 'Placement Test';

  @override
  String get onboardingGoBack => 'Go Back';

  @override
  String get onboardingPleaseTryAgainLater => 'Please try again later.';

  @override
  String get onboardingPlacementQuestionsAreNotAvailableRight =>
      'Placement questions are not available right now.';

  @override
  String get onboardingLoadingPlacementTest => 'Loading placement test...';

  @override
  String get onboardingAreasForImprovement => 'Areas for Improvement';

  @override
  String get onboardingYourProficiencyLevel => 'Your Proficiency Level';

  @override
  String get onboardingPlacementTestComplete => 'Placement Test Complete!';

  @override
  String get onboardingPrevious => 'Previous';

  @override
  String get onboardingYourAnswer => 'Your Answer';

  @override
  String get onboardingSelected => 'Selected';

  @override
  String onboardingAnswerOptionOptionValue(String option, String value) {
    return 'Answer option: $option$value';
  }

  @override
  String onboardingQuestionValueOfValue2(String value, String value2) {
    return 'Question $value of $value2';
  }

  @override
  String onboardingValueOfValue2(String value, String value2) {
    return '$value of $value2';
  }

  @override
  String onboardingProgressQuestionValueOfValue2(String value, String value2) {
    return 'Progress: question $value of $value2';
  }

  @override
  String get onboardingLoadingTest => 'Loading test...';

  @override
  String get onboardingTryAgain => 'Try Again';

  @override
  String get onboardingContinueWithoutTest => 'Continue Without Test';

  @override
  String get onboardingWeCouldnTConnectToThe =>
      'We couldn\'t connect to the server to generate your placement test. You can continue without it and take it later from your profile.';

  @override
  String get onboardingUnableToGeneratePlacementTest =>
      'Unable to Generate Placement Test';

  @override
  String get onboardingGeneratingYourPlacementTest =>
      'Generating your placement test...';

  @override
  String get onboardingPleaseAnswerAllQuestions =>
      'Please answer all questions';

  @override
  String get onboardingEngageWithNativeContent => 'Engage with native content';

  @override
  String get onboardingFocusOnFluencyAndNuance => 'Focus on fluency and nuance';

  @override
  String get onboardingAdvancedLessonsRecommended =>
      'Advanced lessons recommended';

  @override
  String get onboardingExpandVocabularyInSpecificTopics =>
      'Expand vocabulary in specific topics';

  @override
  String get onboardingPracticeConversationSkills =>
      'Practice conversation skills';

  @override
  String get onboardingContinueWithIntermediateContent =>
      'Continue with intermediate content';

  @override
  String get onboardingPracticePronunciationDaily =>
      'Practice pronunciation daily';

  @override
  String get onboardingFocusOnVocabularyBuilding =>
      'Focus on vocabulary building';

  @override
  String get onboardingStartWithBeginnerLessons =>
      'Start with beginner lessons';

  @override
  String get onboardingStartWithTheFirstLessonsA =>
      'Start with the first lessons. A level waits until calibrated items are available.';

  @override
  String get onboardingSomeGrammarConceptsNeedReview =>
      'Some grammar concepts need review';

  @override
  String get onboardingGrammarFundamentalsNeeded =>
      'Grammar fundamentals needed';

  @override
  String get onboardingNeedToBuildVocabulary => 'Need to build vocabulary';

  @override
  String get onboardingWillingnessToLearn => 'Willingness to learn';

  @override
  String get onboardingBasicVocabularyKnowledge => 'Basic vocabulary knowledge';

  @override
  String get onboardingGoodUnderstandingOfBasicGrammar =>
      'Good understanding of basic grammar';

  @override
  String get onboardingStrongVocabularyFoundation =>
      'Strong vocabulary foundation';

  @override
  String get onboardingAPreciseLevelNeedsMoreCalibrated =>
      'A precise level needs more calibrated items';

  @override
  String get onboardingKeepLearningMyParentWillAdd =>
      'Keep learning. My parent will add it later';

  @override
  String get onboardingParentSEmail => 'Parent\'s email';

  @override
  String get onboardingAParentOrGuardianSaysYes =>
      'A parent or guardian says yes before you chat or share. Add their email so they can approve your account.';

  @override
  String get onboardingAskAParent => 'Ask a parent';

  @override
  String get onboardingYourProfileStaysPrivateAndAdults =>
      'Your profile stays private, and adults cannot send you direct messages.';

  @override
  String get onboardingTypeItInstead => 'Type it instead';

  @override
  String onboardingValue(String value) {
    return '$value';
  }

  @override
  String get onboardingSwipeUpOrDownToChange =>
      'Swipe up or down to change the year';

  @override
  String get onboardingBirthYear => 'Birth year';

  @override
  String get onboardingUseTheYearWheel => 'Use the year wheel';

  @override
  String onboardingForExampleValue(String value) {
    return 'For example $value';
  }

  @override
  String get onboardingThisHelpsUsKeepLingafriqRight =>
      'This helps us keep LingAfriq right for you. We only ask for the year.';

  @override
  String onboardingMinutesMin(String minutes) {
    return '$minutes min';
  }

  @override
  String get onboardingYouCanChangeThisAnyTime =>
      'You can change this any time in Settings.';

  @override
  String get onboardingHowMuchTimeADayFeels =>
      'How much time a day feels right?';

  @override
  String get onboardingForATripOrABig => 'For a trip or a big day soon';

  @override
  String get onboardingHoldAShortChatInWeeks => 'Hold a short chat in weeks';

  @override
  String get onboardingAGoodDailyStart => 'A good daily start';

  @override
  String get onboardingAGreetingADay => 'A greeting a day';

  @override
  String get onboardingCanTSpeakNow => 'Can\'t speak now';

  @override
  String get onboardingISaidIt => 'I said it';

  @override
  String onboardingMarkThatYouSaidValue(String value) {
    return 'Mark that you said $value';
  }

  @override
  String get onboardingSayItWithPolie => 'Say it with Polie';

  @override
  String get onboardingTapTheGreeting => 'Tap the greeting';

  @override
  String get onboardingWeCouldNotPlaySoundRight =>
      'We could not play sound right now. You can still continue.';

  @override
  String get onboardingPlayGreeting => 'Play greeting';

  @override
  String get onboardingAudioUnavailable => 'Audio unavailable';

  @override
  String get onboardingHeardIt => 'Heard it';

  @override
  String onboardingPlayGreetingValue(String value) {
    return 'Play greeting $value';
  }

  @override
  String get onboardingPlayingGreeting => 'Playing greeting';

  @override
  String get onboardingGreetingPlayed => 'Greeting played';

  @override
  String onboardingHearValue(String value) {
    return 'Hear: $value';
  }

  @override
  String onboardingA60SecondTasteOfValue(String value) {
    return 'A 60-second taste of $value. Hear, tap, say.';
  }

  @override
  String get onboardingYourFirstWin => 'Your first win';

  @override
  String get onboardingLessonDone => 'Lesson done';

  @override
  String get onboardingNewWord => 'New word';

  @override
  String get onboardingCelebrateProgressNotPerfection =>
      'Celebrate progress, not perfection.';

  @override
  String get onboardingYouDidIt => 'You did it!';

  @override
  String get onboardingKeepGoing => 'Keep going';

  @override
  String get onboardingInaKwana => 'Ina kwana';

  @override
  String onboardingWordsWordsInYourBasket(String words) {
    return '$words words in your basket';
  }

  @override
  String get onboardingPolieIsKeepingYourSeatIn =>
      'Polie is keeping your seat in the village.';

  @override
  String get onboardingKB => 'Ẹ kú àbọ̀';

  @override
  String get onboardingText => 'እንኳን ደህና መጡ';

  @override
  String get onboardingHowFar => 'How far?';

  @override
  String get onboardingDalalAkJMm => 'Dalal ak jàmm';

  @override
  String onboardingValueValue26468(String value, String value2) {
    return '$value · $value2';
  }

  @override
  String get onboardingTryARegionAScriptName =>
      'Try a region, a script name, or clear the box.';

  @override
  String get onboardingNoLanguagesMatchThatSearch =>
      'No languages match that search.';

  @override
  String get onboardingNoLanguagesMatchYourSearch =>
      'No languages match your search';

  @override
  String get onboardingISpeak => 'I speak';

  @override
  String get onboardingWhatDoYouWantToLearn => 'What do you want to learn?';

  @override
  String get onboardingNorthAfrica => 'North Africa';

  @override
  String get onboardingText526f => 'ⵜⴰⵎⴰⵣⵉⵖⵜ';

  @override
  String get onboardingTamazight => 'Tamazight';

  @override
  String get onboardingTextd271 => 'الدارجة';

  @override
  String get onboardingDarija => 'Darija';

  @override
  String get onboardingSouthernAfrica => 'Southern Africa';

  @override
  String get onboardingIsixhosa => 'isiXhosa';

  @override
  String get onboardingIsizulu => 'isiZulu';

  @override
  String get onboardingEastAfrica => 'East Africa';

  @override
  String get onboardingText91cf => 'አማርኛ';

  @override
  String get onboardingKiswahili => 'Kiswahili';

  @override
  String get onboardingWestAfrica => 'West Africa';

  @override
  String get onboardingNaij => 'Naijá';

  @override
  String get onboardingAsSIgbo => 'Asụsụ Igbo';

  @override
  String get onboardingDYorB => 'Èdè Yorùbá';

  @override
  String get onboardingText9970 => 'العربية';

  @override
  String get onboardingPortuguS => 'Português';

  @override
  String get onboardingFranAis => 'Français';

  @override
  String get onboardingPickTheStyleThatFeelsMost =>
      'Pick the style that feels most natural.';

  @override
  String get onboardingVarietyOfMethods => 'Variety of methods';

  @override
  String get onboardingMixed => 'Mixed';

  @override
  String get onboardingTalkToLearn => 'Talk to learn';

  @override
  String get onboardingConversation => 'Conversation';

  @override
  String get onboardingRepetitionDrills => 'Repetition & drills';

  @override
  String get onboardingPractice => 'Practice';

  @override
  String get onboardingNarrativeLearning => 'Narrative learning';

  @override
  String get onboardingStories => 'Stories';

  @override
  String get onboardingSeeToRemember => 'See to remember';

  @override
  String get onboardingVisual => 'Visual';

  @override
  String get onboardingLearnByEar => 'Learn by ear';

  @override
  String get onboardingListening => 'Listening';

  @override
  String get onboardingKR => 'Ẹ káàárọ̀';

  @override
  String get onboardingNaGode => 'Na gode';

  @override
  String get onboardingQuickCheckTapEachWordYou =>
      'Quick check: tap each word you recognize.';

  @override
  String get onboardingNotSureTakeA1Minute => 'Not sure? Take a 1‑minute check';

  @override
  String onboardingHowMuchLangnameDoYouKnow(String langName) {
    return 'How much $langName do you know?';
  }

  @override
  String get onboardingThisLanguage => 'this language';

  @override
  String get onboardingICanHoldAConversation => 'I can hold a conversation';

  @override
  String get onboardingICanTalkAboutVariousTopics =>
      'I can talk about various topics';

  @override
  String get onboardingIKnowSomeCommonWords => 'I know some common words';

  @override
  String get onboardingIMNew => 'I\'m new';

  @override
  String get onboardingBestTime => 'Best time';

  @override
  String get onboardingSeeTheReminderBelowTurnIt =>
      'See the reminder below. Turn it on only if it helps you keep your streak. You pick the time.';

  @override
  String get onboardingASoftNudgeWhenItMatters =>
      'A soft nudge when it matters';

  @override
  String get onboardingNotNow => 'Not now';

  @override
  String get onboardingTurnOnReminders => 'Turn on reminders';

  @override
  String onboardingDailyminutesMinutes(String dailyMinutes) {
    return '$dailyMinutes minutes';
  }

  @override
  String get onboardingText5Minutes => '5 minutes';

  @override
  String get onboardingText810Pm => '8–10 PM';

  @override
  String get onboardingNight => 'Night';

  @override
  String get onboardingText57Pm => '5–7 PM';

  @override
  String get onboardingSunset => 'Sunset';

  @override
  String get onboardingText122Pm => '12–2 PM';

  @override
  String get onboardingMidday => 'Midday';

  @override
  String get onboardingText69Am => '6–9 AM';

  @override
  String get onboardingSunrise => 'Sunrise';

  @override
  String onboardingPreviewHowYouAppearInThe(String shown) {
    return 'Preview: how you appear in the village, $shown';
  }

  @override
  String get onboardingYourName => 'Your name';

  @override
  String get onboardingWeCouldnTCheckThatJust =>
      'We couldn\'t check that just now, but you can still continue';

  @override
  String get onboardingOnlyLettersNumbersAndUnderscoresPlease =>
      'Only letters, numbers, and underscores, please';

  @override
  String get onboardingKeepItTo30CharactersOr =>
      'Keep it to 30 characters or fewer';

  @override
  String get onboardingNeedsAtLeast3Characters => 'Needs at least 3 characters';

  @override
  String get onboardingSomeoneSAlreadyUsingThatOne =>
      'Someone\'s already using that one, try another';

  @override
  String get onboardingThatNameIsYours => 'That name is yours';

  @override
  String get onboardingCheckingIfThatNameIsFree =>
      'Checking if that name is free…';

  @override
  String get onboardingUse3To30LettersNumbers =>
      'Use 3 to 30 letters, numbers, or underscores';

  @override
  String onboardingUseTheNameIdea(String idea) {
    return 'Use the name $idea';
  }

  @override
  String get onboardingIdeasFromYourLanguage => 'Ideas from your language';

  @override
  String get onboardingAddAPhotoOptional => 'Add a photo (optional)';

  @override
  String get onboardingAddAProfilePhotoOptional =>
      'Add a profile photo, optional';

  @override
  String get onboardingALearnerWithoutANameIs56f4 =>
      'A learner without a name is a drum without a rhythm.';

  @override
  String get onboardingPickAName => 'Pick a name';

  @override
  String get onboardingSkipForNow => 'Skip for now';

  @override
  String get onboardingCompleteSetup => 'Complete setup';

  @override
  String get onboardingPickAllThatFitYourFirst =>
      'Pick all that fit. Your first lessons follow your answer.';

  @override
  String onboardingWhyAreYouLearningLanguagename(String languageName) {
    return 'Why are you learning $languageName?';
  }

  @override
  String get onboardingColleaguesClientsAndCommunity =>
      'Colleagues, clients and community';

  @override
  String get onboardingMarketsDirectionsAndSmallTalk =>
      'Markets, directions and small talk';

  @override
  String get onboardingProverbsNamesMusicAndStories =>
      'Proverbs, names, music and stories';

  @override
  String get onboardingHeritageAndCulture => 'Heritage and culture';

  @override
  String get onboardingGreetEldersAndKeepUpAt =>
      'Greet elders and keep up at gatherings';

  @override
  String get onboardingTalkToFamily => 'Talk to family';

  @override
  String get onboardingRetry => 'Retry';

  @override
  String get onboardingYouReOfflineYourAnswersAre =>
      'You\'re offline. Your answers are saved on this phone. Connect, then try again.';

  @override
  String get onboardingCouldnTReachSignIn => 'Couldn\'t reach sign-in';

  @override
  String get onboardingError => 'Error';

  @override
  String get onboardingSavingYourProgress => 'Saving your progress…';

  @override
  String get onboardingIAlreadyHaveAnAccount => 'I already have an account';

  @override
  String get onboardingSignUpWithEmail => 'Sign up with email';

  @override
  String get onboardingContinueWithApple => 'Continue with Apple';

  @override
  String get onboardingContinueWithGoogle => 'Continue with Google';

  @override
  String onboardingYouFinishedYourFirstLessonAnd(String words) {
    return 'You finished your first lesson and learned $words. An account keeps your progress safe if you change phones.';
  }

  @override
  String get onboardingSaveYourProgress => 'Save your progress?';

  @override
  String get onboardingLaterMyAnswersStayOnThis =>
      'Later. My answers stay on this phone';

  @override
  String onboardingWordslearnedWords(String wordsLearned) {
    return '$wordsLearned words';
  }

  @override
  String get onboardingYouReOfflineKeepGoingYour =>
      'You\'re offline. Keep going: your answers are saved on this phone and sync when you reconnect.';

  @override
  String get onboardingDoubleTapToChoose => 'Double tap to choose';

  @override
  String get onboardingSaving => 'Saving…';

  @override
  String get onboardingHowMuchGameFeel => 'How much game feel?';

  @override
  String get onboardingPickTheVoiceThatFeelsLike =>
      'Pick the voice that feels like a good study buddy.';

  @override
  String get onboardingHowShouldPolieSound => 'How should Polie sound?';

  @override
  String get onboardingJustLearning => 'Just learning';

  @override
  String get onboardingMinimal => 'Minimal';

  @override
  String get onboardingProgressTracking => 'Progress tracking';

  @override
  String get onboardingModerate => 'Moderate';

  @override
  String get onboardingXpBadgesStreaks => 'XP, badges, streaks';

  @override
  String get onboardingFull => 'Full';

  @override
  String get onboardingWarmCasual => 'Warm & casual';

  @override
  String get onboardingFriendly => 'Friendly';

  @override
  String get onboardingDirectEfficient => 'Direct & efficient';

  @override
  String get onboardingFocused => 'Focused';

  @override
  String get onboardingSupportive => 'Supportive';

  @override
  String get onboardingEncouraging => 'Encouraging';

  @override
  String get onboardingFunLight => 'Fun & light';

  @override
  String get onboardingPlayful => 'Playful';

  @override
  String get onboardingGetStarted90e4 => 'Get started';

  @override
  String get onboardingWorksOfflineAbout2MbPer =>
      'Works offline · about 2 MB per unit';

  @override
  String get onboardingWorksOfflineAbout2MegabytesPer =>
      'Works offline, about 2 megabytes per unit';

  @override
  String get onboardingShortLessonsWithPolieHearTap =>
      'Short lessons with Polie. Hear, tap, and say real phrases.';

  @override
  String get onboardingTheLanguageVillageThatGetsYou =>
      'The language village that gets you speaking.';

  @override
  String get onboardingLingafriq => 'LingAfriq';

  @override
  String get onboardingWelcomeTo => 'Welcome to';

  @override
  String get onboardingKBSannuNnKaribuAkwaaba =>
      'Ẹ kú àbọ̀ · Sannu · Nnọọ · Karibu · Akwaaba';

  @override
  String get onboardingPolieGreetsYouWelcomeInYoruba =>
      'Polie greets you: welcome, in Yoruba, Hausa, Igbo, Swahili and Twi.';

  @override
  String get onboardingLingafriqSpeakAfricanLanguagesWithConf =>
      'LingAfriq. Speak African languages with confidence. Learn with Polie. Works offline.';

  @override
  String onboardingStepValueOfTotal(String value, String total) {
    return 'Step $value of $total';
  }

  @override
  String get onboardingOnboardingProgress => 'Onboarding progress';

  @override
  String get onboardingGoBackToThePreviousStep =>
      'Go back to the previous step';

  @override
  String get onboardingTakeTheTest => 'Take the test';

  @override
  String get onboardingMaybeLater => 'Maybe later';

  @override
  String onboardingWeLlAskAFewShort(String learningLanguage) {
    return 'We\'ll ask a few short questions to find your starting level in $learningLanguage. You can always take it later from your profile.';
  }

  @override
  String get onboardingTakeAQuickPlacementTest =>
      'Take a quick placement test?';

  @override
  String get onboardingYouReOfflineRightNowBut =>
      'You\'re offline right now, but we\'ve saved your answers and will sync them the moment you reconnect.';

  @override
  String get onboardingKR5MinutesOfYoruba => 'Ẹ kú àárọ̀! 5 minutes of Yoruba?';

  @override
  String get onboardingBWoHello => 'Báwo, Hello';

  @override
  String get onboardingBWoNi => 'Báwo ni';

  @override
  String get onboardingSawubona5MinutesOfZulu => 'Sawubona! 5 minutes of Zulu?';

  @override
  String get onboardingSawubonaHello => 'Sawubona, Hello';

  @override
  String get onboardingText5MinutesOfAmharic => 'ሰላም! 5 minutes of Amharic?';

  @override
  String get onboardingHello => 'ሰላም, Hello';

  @override
  String get onboardingHabari5MinutesOfSwahili =>
      'Habari! 5 minutes of Swahili?';

  @override
  String get onboardingHabariHello => 'Habari, Hello';

  @override
  String get onboardingNdewo5MinutesOfIgbo => 'Ndewo! 5 minutes of Igbo?';

  @override
  String get onboardingNdewoHello => 'Ndewo, Hello';

  @override
  String get onboardingSannu5MinutesOfHausa => 'Sannu! 5 minutes of Hausa?';

  @override
  String get onboardingSannuHello => 'Sannu, Hello';

  @override
  String get onboardingTheAncestorsSmileUponYourDedication =>
      'The ancestors smile upon your dedication.';

  @override
  String get onboardingMayYourJourneyBeFilledWith =>
      'May your journey be filled with discovery.';

  @override
  String get onboardingVillageElder => 'Village Elder';

  @override
  String get onboardingPaLingafriq => 'Pa LingAfriq';

  @override
  String get onboardingChooseWiselyItWillBeKnown =>
      'Choose wisely — it will be known across the village.';

  @override
  String get onboardingEveryVillagerMustHaveAName =>
      'Every villager must have a name.';

  @override
  String get onboardingNowItIsTimeForYour =>
      'Now it is time for your naming ceremony.';

  @override
  String get onboardingHowDoesYourSpiritBestReceive =>
      'How does your spirit best receive knowledge?';

  @override
  String get onboardingEachSoulDancesDifferentlyToThe =>
      'Each soul dances differently to the rhythm of words.';

  @override
  String get onboardingLanguageIsMusicTraveler =>
      'Language is music, traveler!';

  @override
  String get onboardingTheRhythmMaster => 'The Rhythm Master';

  @override
  String get onboardingForInEveryWordLiesThe =>
      'For in every word lies the wisdom of generations.';

  @override
  String get onboardingLetMeTellYouTheStory =>
      'Let me tell you the story of our languages...';

  @override
  String get onboardingAhANewStudentIAm =>
      'Ah, a new student! I am Amara, the griot.';

  @override
  String get onboardingTheGriot => 'The Griot';

  @override
  String get onboardingHowMuchTimeCanYouDedicate =>
      'How much time can you dedicate each day?';

  @override
  String get onboardingConsistencyIsTheHeartbeatOfLearning =>
      'Consistency is the heartbeat of learning.';

  @override
  String get onboardingIAmKofiKeeperOfTime =>
      'I am Kofi, keeper of time and rhythm.';

  @override
  String get onboardingTheTimekeeper => 'The Timekeeper';

  @override
  String get onboardingWhatBringsYouToLearnThis =>
      'What brings you to learn this beautiful language?';

  @override
  String get onboardingEveryGreatJourneyNeedsADestination =>
      'Every great journey needs a destination.';

  @override
  String get onboardingGreetingsTravelerIAmZuriYour =>
      'Greetings, traveler! I am Zuri, your pathfinder.';

  @override
  String get onboardingThePathfinder => 'The Pathfinder';

  @override
  String get onboardingWhichThreadShallWeWeaveInto =>
      'Which thread shall we weave into your story?';

  @override
  String get onboardingEachLanguageIsAThreadIn =>
      'Each language is a thread in the tapestry of Africa.';

  @override
  String get onboardingIAmAdisaWeaverOfWords =>
      'I am Adisa, weaver of words and keeper of tongues.';

  @override
  String get onboardingTheWeaver => 'The Weaver';

  @override
  String get onboardingYourJourneyToConnectWithYour =>
      'Your journey to connect with your roots begins here.';

  @override
  String get onboardingIAmPaLingafriqGuardianOf =>
      'I am Pa LingAfriq, guardian of our ancestral tongues.';

  @override
  String get onboardingWelcomeYoungOneToOurVillage =>
      'Welcome, young one, to our village of languages.';

  @override
  String get shellLogout => 'Logout';

  @override
  String get shellCancel => 'Cancel';

  @override
  String get shellAreYouSureYouWantTo => 'Are you sure you want to logout?';

  @override
  String get shellSwitchBetweenLightAndDarkTheme =>
      'Switch between light and dark theme';

  @override
  String get shellDarkMode => 'Dark Mode';

  @override
  String get shellFriendQuests => 'Friend Quests';

  @override
  String get shellSocialHub => 'Social Hub';

  @override
  String get shellMicroMentorReports => 'Micro-mentor reports';

  @override
  String get shellPersonaMissions => 'Persona Missions';

  @override
  String get shellHistoricalPersonas => 'Historical Personas';

  @override
  String get shellMyTribes => 'My Tribes';

  @override
  String get shellLanguageVillages => 'Language Villages';

  @override
  String get shellPrivateChat => 'Private Chat';

  @override
  String get shellCommunityFeed => 'Community Feed';

  @override
  String get shellGlobalChat => 'Global Chat';

  @override
  String get shellCreateContent => 'Create Content';

  @override
  String get shellLiveTranslate => 'Live translate';

  @override
  String get shellPointSay => 'Point & Say';

  @override
  String get shellImportMedia => 'Import Media';

  @override
  String get shellCulturalMagazine => 'Cultural Magazine';

  @override
  String get shellCulturalHub => 'Cultural Hub';

  @override
  String get shellAddWordsInVocabularyBuilderTo =>
      'Add words in Vocabulary Builder to start flashcard review.';

  @override
  String get shellPleaseSelectALanguageFirst =>
      'Please select a language first';

  @override
  String get shellFlashcardReview => 'Flashcard Review';

  @override
  String get shellWritingPractice => 'Writing Practice';

  @override
  String get shellListeningPractice => 'Listening Practice';

  @override
  String get shellConversationScenarios => 'Conversation Scenarios';

  @override
  String get shellVocabularyBuilder => 'Vocabulary Builder';

  @override
  String get shellLearningPath => 'Learning Path';

  @override
  String get shellGrammarHub => 'Grammar Hub';

  @override
  String get shellAiChat => 'AI Chat';

  @override
  String get shellTutorMode => 'Tutor Mode';

  @override
  String get shellNativeContentReview => 'Native content review';

  @override
  String get shellAuthenticPathA1C1 => 'Authentic Path (A1–C1)';

  @override
  String get shellToggleDarkMode => 'Toggle Dark Mode';

  @override
  String shellDarkModeValue(String value) {
    return 'Dark mode $value';
  }

  @override
  String shellTitleSection(String title) {
    return '$title section';
  }

  @override
  String get shellToggleTheme => 'Toggle theme';

  @override
  String get shellDarkMode9cf8 => 'Dark mode';

  @override
  String get shellPracticeRooms => 'Practice Rooms';

  @override
  String get shellLiveClassroom => 'Live Classroom';

  @override
  String get shellDialectPreference => 'Dialect preference';

  @override
  String get shellHeritageMilestones => 'Heritage milestones';

  @override
  String get shellLivingDictionary => 'Living Dictionary';

  @override
  String get shellToneRhythm => 'Tone & Rhythm';

  @override
  String get shellPhraseDna => 'Phrase DNA';

  @override
  String get shellPolieTutor => 'Polie Tutor';

  @override
  String shellEmailValue(String value) {
    return 'Email: $value';
  }

  @override
  String shellUsernameValue(String value) {
    return 'Username: $value';
  }

  @override
  String get shellUserAvatar => 'User avatar';

  @override
  String shellLessonsCompletedValuePointsEarnedValue2(
    String value,
    String value2,
  ) {
    return 'Lessons completed: $value • Points earned: $value2';
  }

  @override
  String get shellLoadingCourses => 'Loading Courses ...';

  @override
  String get shellStartACourseToSeeYour =>
      'Start a course to see your progress';

  @override
  String get shellNoCourseStartedYet => 'No Course started yet';

  @override
  String shellHiValue(String value) {
    return 'Hi $value';
  }

  @override
  String get shellYourCourses => 'Your Courses!';

  @override
  String shellValue(String value) {
    return '$value%';
  }

  @override
  String get shellProgress => 'Progress';

  @override
  String shellProgressValue(String value) {
    return 'Progress $value%';
  }

  @override
  String shellLessonsCompletedValuePointsValue2(String value, String value2) {
    return 'Lessons completed: $value • Points: $value2';
  }

  @override
  String shellValueValue2CompleteTapToOpen(String value, String value2) {
    return '$value, $value2% complete. Tap to open.';
  }

  @override
  String get shellLoadingCourses7098 => 'Loading Courses...';

  @override
  String get shellNoLanguagesAvailable => 'No languages available';

  @override
  String get shellYourProgress => 'Your Progress';

  @override
  String get shellMenu => 'Menu';

  @override
  String get shellOpenMenu => 'Open menu';

  @override
  String get shellYourCourses9648 => 'Your Courses';

  @override
  String get shellNangaDef => 'Nanga def';

  @override
  String get shellHowFar => 'How far';

  @override
  String get shellAsSIgbo => 'Asụsụ Igbo';

  @override
  String get shellHarshenHausa => 'Harshen Hausa';

  @override
  String get shellKB => 'Ẹ káàbọ̀';

  @override
  String shellValueTapToOpen(String value) {
    return '$value. Tap to open.';
  }

  @override
  String shellLabelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String shellTitleSubtitle(String title, String subtitle) {
    return '$title. $subtitle';
  }

  @override
  String get shellViewDashboard => 'View dashboard';

  @override
  String get shellConversationWithPolie => 'Conversation with Polie';

  @override
  String get shellPolieModesSkills => 'Polie modes & skills';

  @override
  String get shellAiTutor => 'AI Tutor';

  @override
  String get shellQuickActions => 'Quick Actions';

  @override
  String shellValueLanguages(String value) {
    return '$value languages';
  }

  @override
  String shellValueBadges(String value) {
    return '$value badges';
  }

  @override
  String shellValueDayStreak(String value) {
    return '$value day streak';
  }

  @override
  String shellValueXpToNextLevel(String value) {
    return '$value XP to next level';
  }

  @override
  String shellXpValue(String value) {
    return 'XP $value';
  }

  @override
  String get shellLevel => 'Level';

  @override
  String shellValue75ce(String value) {
    return '$value';
  }

  @override
  String shellLevelValueXpValue2Value3Xp(
    String value,
    String value2,
    String value3,
    String value4,
    String value5,
    String value6,
  ) {
    return 'Level $value. XP $value2. $value3 XP to next level. $value4 day streak. $value5 badges. $value6 languages.';
  }

  @override
  String shellTitleValue(String title, String value) {
    return '$title$value';
  }

  @override
  String get shellLoadingLanguages => 'Loading Languages ...';

  @override
  String get shellSearchLanguages => 'Search languages';

  @override
  String get shellExploreMore => 'Explore More';

  @override
  String get shellFeaturedLanguages => 'Featured Languages';

  @override
  String get shellKBd95e => 'Ẹ Káàbọ';

  @override
  String get shellWehcomeO => 'Wehcome o';

  @override
  String get shellSannuDaZuwa => 'Sannu da zuwa';

  @override
  String shellPercent(String percent) {
    return '$percent%';
  }

  @override
  String get shellKBf733 => 'Ẹ Káàbọ̀';

  @override
  String get shellWelcomeO => 'Welcome o';

  @override
  String get shellConnectionTimedOut => 'connection timed out';

  @override
  String get shellConnectionRefused => 'connection refused';

  @override
  String get shellFailedHostLookup => 'failed host lookup';

  @override
  String get shellNetworkIsUnreachable => 'network is unreachable';

  @override
  String get shellNoInternet => 'no internet';

  @override
  String get shellAuthenticPath => 'Authentic Path';

  @override
  String get shellTakeQuiz => 'Take Quiz';

  @override
  String get shellBack => 'Back';

  @override
  String get shellPickWhereYouWantToLearn => 'Pick where you want to learn';

  @override
  String get shellStartLearning => 'Start learning';

  @override
  String shellValuePts(String value) {
    return '$value pts';
  }

  @override
  String get shellTryADifferentSearchTerm => 'Try a different search term';

  @override
  String get shellNoLanguagesFound => 'No languages found';

  @override
  String get shellClearSearch => 'Clear search';

  @override
  String get shellSearchLanguages2580 => 'Search languages...';

  @override
  String shellValuea1d1(String value) {
    return '$value ';
  }

  @override
  String get shellRetry => 'Retry';

  @override
  String get shellFailedToLoadQuizzesPleaseTry =>
      'Failed to load quizzes. Please try again.';

  @override
  String get shellConnectionTimedOut52c8 => 'Connection timed out';

  @override
  String shellWeReWorkingToAddRandom(String value) {
    return 'We\'re working to add random quizzes for $value!';
  }

  @override
  String shellLoadingQuizzesForValue(String value) {
    return 'Loading quizzes for $value...';
  }

  @override
  String get shellChooseAQuizType => 'Choose a quiz type';

  @override
  String get shellAppPolicy => 'App Policy';

  @override
  String get shellChangePassword => 'Change Password';

  @override
  String get shellPasswordChanged => 'Password Changed';

  @override
  String get shellConfirmYourNewPassword => 'Confirm your new password';

  @override
  String get shellConfirmPassword => 'Confirm Password';

  @override
  String get shellEnterNewPassword => 'Enter new password';

  @override
  String get shellNewPassword => 'New Password';

  @override
  String get shellEnterYourCurrentPassword => 'Enter your current password';

  @override
  String get shellCurrentPassword => 'Current Password';

  @override
  String get shellDeleteNow => 'Delete Now';

  @override
  String get shellEnterCurrentPassword => 'Enter Current Password';

  @override
  String get shellConfirmation => 'Confirmation';

  @override
  String get shellYes => 'Yes';

  @override
  String get shellNo => 'No';

  @override
  String get shellAreYouSureYouWantToecc5 =>
      'Are you sure you want to DELETE account?';

  @override
  String get shellAccountDeleted => 'Account Deleted';

  @override
  String get shellThisActionIsPermanent => 'This action is permanent';

  @override
  String get shellDeleteYourAccount => 'Delete your account';

  @override
  String get shellReadHowYourDataIsProtected =>
      'Read how your data is protected';

  @override
  String get shellPrivacyUserPolicy => 'Privacy & User Policy';

  @override
  String get shellLearnAboutTheLingafriqMission =>
      'Learn about the LingAfriq mission';

  @override
  String get shellWhoAreWe => 'Who are we?';

  @override
  String get shellHelpUsImproveLingafriq => 'Help us improve LingAfriq';

  @override
  String get shellGiveUsFeedback => 'Give us Feedback';

  @override
  String get shellUpdateYourCredentialsSecurely =>
      'Update your credentials securely';

  @override
  String shellValue12bd(String value) {
    return '#$value';
  }

  @override
  String shellGlobalRankValue(String value) {
    return 'Global rank: $value';
  }

  @override
  String get shellGlobalRanking => 'Global Ranking';

  @override
  String shellStreakValue(String value) {
    return 'Streak $value';
  }

  @override
  String shellValueXp(String value) {
    return '$value XP';
  }

  @override
  String shellAchievementProgressUnlockedbadgesOutOfTotal(
    String unlockedBadges,
    String totalBadges,
  ) {
    return 'Achievement progress: $unlockedBadges out of $totalBadges badges unlocked';
  }

  @override
  String shellUnlockedbadgesTotalbadges(
    String unlockedBadges,
    String totalBadges,
  ) {
    return '$unlockedBadges/$totalBadges';
  }

  @override
  String get shellAchievements => 'Achievements';

  @override
  String shellLevelValue(String value) {
    return 'Level $value';
  }

  @override
  String shellProfileValueValue2LevelValue3Streak(
    String value,
    String value2,
    String value3,
    String value4,
  ) {
    return 'Profile: $value, $value2, Level $value3, Streak $value4';
  }

  @override
  String get shellProfileAvatarTapToEditProfile =>
      'Profile avatar. Tap to edit profile';

  @override
  String get shellProfile => 'Profile';

  @override
  String get shellSubmit => 'Submit';

  @override
  String get shellFeedbackFormOnMobileApp => 'Feedback Form on Mobile App';

  @override
  String shellLanguageCountryCountry(String country) {
    return 'Language Country:\n$country\n\n';
  }

  @override
  String shellWouldYouLikeToSuggestA(String suggestion) {
    return 'Would you like to suggest a language? If yes, enter language below:\n$suggestion\n\n';
  }

  @override
  String shellWhatWouldYouLikeUsTo(String reason) {
    return 'What would you like us to know:\n$reason\n\n';
  }

  @override
  String get shellPleaseFillInSomeFields => 'Please fill in some fields';

  @override
  String get shellLanguageCountry => 'Language Country';

  @override
  String get shellWriteYourSuggestionHere => 'Write your suggestion here';

  @override
  String get shellWouldYouLikeToSuggestAb06a =>
      'Would you like to suggest a language? If yes, enter language below';

  @override
  String get shellPleaseExplainWhatWouldYouLike =>
      'Please explain What would you like us to know?';

  @override
  String get shellWhatWouldYouLikeUsTo0de8 => 'What would you like us to know?';

  @override
  String get shellStartACourseToSeeYoure3fc =>
      'Start a course to see your country ranking';

  @override
  String get shellNoPointsEarnedYet => 'No points earned yet';

  @override
  String shellSpaceTextSpace2(String space, String text, String space2) {
    return '$space$text$space2';
  }

  @override
  String get shellLoadingLeaderboard => 'Loading Leaderboard...';

  @override
  String get shellCountry => 'Country';

  @override
  String get shellGlobal => 'Global';

  @override
  String shellLeaderboardViewValueSwitchBetweenGlobal(String value) {
    return 'Leaderboard view: $value. Switch between Global and Country.';
  }

  @override
  String get shellLeaderboard => 'Leaderboard';

  @override
  String get shellProfileTab => 'Profile tab';

  @override
  String get shellSocial => 'Social';

  @override
  String get shellSocialTab => 'Social tab';

  @override
  String get shellAi => 'AI';

  @override
  String get shellAiTutorTab => 'AI Tutor tab';

  @override
  String get shellCourses => 'Courses';

  @override
  String get shellCoursesTab => 'Courses tab';

  @override
  String get shellHome => 'Home';

  @override
  String get shellHomeTab => 'Home tab';

  @override
  String get shellBackToLearning => 'Back to learning';

  @override
  String get shellBackToLearningHome => 'Back to learning home';

  @override
  String get shellNotAvailableYet => 'Not available yet';

  @override
  String get shellPrivateMessagesCallsSnapsAndThe =>
      'Private messages, calls, snaps, and the public feed unlock when you are 18 and your age is verified. Until then, keep going on lessons, games, and Polie.';

  @override
  String get shellLearningComesFirst => 'Learning comes first';

  @override
  String onboardingWordsInYourBasket(int words) {
    String _temp0 = intl.Intl.pluralLogic(
      words,
      locale: localeName,
      other: '$words words in your basket',
      one: '1 word in your basket',
    );
    return '$_temp0';
  }

  @override
  String get onboardingNotSelected => 'not selected';

  @override
  String get onboardingAddAvatarOptional => 'Add Avatar (Optional)';

  @override
  String get onboardingLevelNotPreciseYet => 'Level not precise yet';

  @override
  String get onboardingSelectedd7a1 => ', selected';

  @override
  String onboardingUseAYearBetween1900And(String nowYear) {
    return 'Use a year between 1900 and $nowYear.';
  }

  @override
  String get onboardingNiceYouSaidIt => 'Nice, you said it';

  @override
  String get onboardingYouMarkedThePhraseAsSaid =>
      'You marked the phrase as said';

  @override
  String get onboardingFinishLesson => 'Finish lesson';

  @override
  String get onboardingText1Word => '1 word';

  @override
  String shellUsername(String username) {
    return ', $username';
  }

  @override
  String get shellTabToday => 'Today';

  @override
  String get shellTabLearn => 'Learn';

  @override
  String get shellTabSpeak => 'Speak';

  @override
  String get shellTabPlay => 'Play';

  @override
  String get shellTabVillage => 'Village';

  @override
  String get shellMe => 'Me';

  @override
  String get shellSearch => 'Search';

  @override
  String get shellLens => 'Lens';

  @override
  String shellOpenSection(String tab) {
    return 'Open $tab';
  }

  @override
  String shellSectionOpen(String tab) {
    return '$tab is open';
  }

  @override
  String shellSectionLine(int index, String tab) {
    return 'Line $index in $tab';
  }

  @override
  String get shellLinkMissedWhat => 'This link did not open.';

  @override
  String shellLinkMissedWhy(String link) {
    return 'Nothing in the app matches $link.';
  }

  @override
  String shellLinkMissedWhyWithDetail(String link, String detail) {
    return 'Nothing in the app matches $link. $detail';
  }

  @override
  String get shellLinkMissedNext => 'Go back to Today.';

  @override
  String get shellLinkMissedAction => 'Go to Today';

  @override
  String get shellLinkWasEmpty => 'The link was empty.';

  @override
  String get shellOfflineWhat => 'The phone has no network.';

  @override
  String get shellOfflineWhy => 'These tabs are not saved offline.';

  @override
  String get shellOfflineNext => 'Connect, then try again.';

  @override
  String get searchFieldLabel => 'Search words, features, and content';

  @override
  String get searchWords => 'Words';

  @override
  String get searchFeatures => 'Features';

  @override
  String get searchContent => 'Content';

  @override
  String get searchIdleWhat => 'Search is ready.';

  @override
  String get searchIdleWhy => 'The box is empty.';

  @override
  String get searchIdleNext => 'Type a word or a feature name.';

  @override
  String get searchEmptyTitle => 'No match';

  @override
  String searchEmptyWhat(String query) {
    return 'Nothing matches $query.';
  }

  @override
  String get searchEmptyWhy =>
      'That name is not in words, features, or content on this phone.';

  @override
  String get searchEmptyNext => 'Open the directory to see every feature.';

  @override
  String get searchEmptyAction => 'Open the directory';

  @override
  String get searchOfflineLabel =>
      'Offline. Showing results saved on this phone.';

  @override
  String searchUnlockWhat(String feature) {
    return '$feature is not open yet.';
  }

  @override
  String searchUnlockWhy(String stage) {
    return 'It unlocks at $stage.';
  }

  @override
  String get searchUnlockNext => 'Read this preview, then go back.';

  @override
  String get searchPreviewLabel => 'Preview';

  @override
  String get searchBack => 'Back';

  @override
  String searchOpenWord(String word) {
    return 'Open Word Card for $word';
  }

  @override
  String searchOpenFeature(String feature) {
    return 'Open $feature';
  }

  @override
  String searchOpenContent(String title) {
    return 'Open $title';
  }

  @override
  String get hubTodayTitle => 'Today';

  @override
  String get hubTodayLead => 'One plan for today.';

  @override
  String get hubTodayDailyPlan => 'Daily plan';

  @override
  String get hubTodayDailyChallenges => 'Daily Challenges';

  @override
  String get hubTodayQuests => 'Quests';

  @override
  String get hubTodayEvents => 'Events and Festivals';

  @override
  String get hubTodayStreaks => 'Streaks';

  @override
  String get hubTodayBack => 'Back to Today';

  @override
  String hubTodayMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String hubTodayMinutesAbout(int minutes) {
    return 'About $minutes minutes';
  }

  @override
  String get hubTodayDueReviews => 'Due reviews';

  @override
  String get hubTodayNextLesson => 'Next lesson';

  @override
  String get hubTodayStart => 'Start';

  @override
  String hubTodayStartPlan(int minutes) {
    return 'Start the $minutes minute plan';
  }

  @override
  String get hubTodayEmptyTitle => 'No plan yet';

  @override
  String get hubTodayEmptyWhat => 'Today has nothing queued.';

  @override
  String get hubTodayEmptyWhy =>
      'There is no review due, and no lesson is chosen.';

  @override
  String get hubTodayEmptyNext => 'Open Path and start the first lesson.';

  @override
  String get hubTodayOpenPath => 'Open Path';

  @override
  String get hubTodayNotBuiltWhat => 'This part is not available yet.';

  @override
  String get hubTodayNotBuiltWhy => 'It is not built yet.';

  @override
  String get hubTodayNotBuiltNext => 'Go back to Today.';

  @override
  String get hubTodayProviderWhat => 'The daily plan is not available.';

  @override
  String get hubTodayProviderWhy => 'The plan provider is not here.';

  @override
  String get hubTodayProviderNext => 'Come back when the plan is ready.';

  @override
  String get hubTodayRangeWhat => 'This plan cannot be shown.';

  @override
  String get hubTodayRangeWhy =>
      'A shown plan is 10 to 15 minutes and lists due reviews and the next lesson.';

  @override
  String get hubTodayRangeNext => 'Come back when the plan is ready.';

  @override
  String get hubTodayErrorWhat => 'The plan did not open.';

  @override
  String get hubTodayErrorWhy => 'The lesson list did not come back.';

  @override
  String get hubTodayErrorNext => 'Try again.';

  @override
  String get hubTodayOfflineWhat => 'The phone has no network.';

  @override
  String get hubTodayOfflineWhy => 'This plan is not saved on the phone.';

  @override
  String get hubTodayOfflineNext => 'Connect, then try again.';

  @override
  String get hubLearnPathAndLessons => 'Path and lessons';

  @override
  String get hubLearnLessonRecap => 'Lesson Recap';

  @override
  String get hubLearnWordsAndReview => 'Words and Review';

  @override
  String get hubLearnReviewRush => 'Review Rush';

  @override
  String get hubLearnGrammar => 'Grammar';

  @override
  String get hubLearnPhraseDna => 'Phrase DNA';

  @override
  String get hubLearnListening => 'Listening';

  @override
  String get hubLearnWriting => 'Writing';

  @override
  String get hubLearnToneGym => 'Tone Gym';

  @override
  String get hubLearnCultureShelf => 'Culture shelf';

  @override
  String get hubLearnMagazine => 'Magazine';

  @override
  String get hubLearnHeritage => 'Heritage';

  @override
  String get hubLearnHistory => 'History';

  @override
  String get hubLearnMannerisms => 'Mannerisms';

  @override
  String get hubLearnCulturalHub => 'Cultural Hub';

  @override
  String get hubLearnPassport => 'Passport';

  @override
  String get hubLearnDownloads => 'Downloads';

  @override
  String get hubLearnBack => 'Back to Learn';

  @override
  String get hubLearnNotAvailableWhat => 'This part is not built yet.';

  @override
  String get hubLearnNotAvailableWhy => 'There is nothing to show.';

  @override
  String get hubLearnNotAvailableNext => 'Go back to Learn.';

  @override
  String get hubLearnEmptyTitle => 'Nothing is here yet';

  @override
  String get hubLearnEmptyWhat => 'Learn has no lessons yet.';

  @override
  String get hubLearnEmptyWhy => 'No units came back.';

  @override
  String get hubLearnEmptyNext => 'Open Path and start the first lesson.';

  @override
  String get hubLearnOpenPath => 'Open Path';

  @override
  String get hubLearnPathEmptyTitle => 'This path has no lessons';

  @override
  String get hubLearnPathEmptyWhat => 'No units are on this path.';

  @override
  String get hubLearnPathEmptyWhy => 'No units came back to group.';

  @override
  String get hubLearnPathEmptyNext => 'Try again later.';

  @override
  String get hubLearnGrammarEmptyTitle => 'No pattern yet';

  @override
  String get hubLearnGrammarEmptyWhat => 'Grammar has no pattern yet.';

  @override
  String get hubLearnGrammarEmptyWhy => 'No drill came back.';

  @override
  String get hubLearnGrammarEmptyNext => 'Open Path and start a lesson.';

  @override
  String hubLearnLevel(String level) {
    return 'Level $level';
  }

  @override
  String get hubLearnLevelNotSet => 'Level not set';

  @override
  String get hubLearnErrorWhat => 'Learn did not open.';

  @override
  String get hubLearnErrorWhy => 'The lesson list did not come back.';

  @override
  String get hubLearnErrorNext => 'Try again.';

  @override
  String get hubLearnOfflineWhy => 'This path is not saved on the phone.';

  @override
  String get hubLearnOfflineNext => 'Connect, then try again.';

  @override
  String get hubHSpeakTitle => 'Speak';

  @override
  String get hubHSpeakPolie => 'Polie';

  @override
  String get hubHSpeakScenarios => 'Scenarios';

  @override
  String get hubHSpeakPersonas => 'Personas and Missions';

  @override
  String get hubHSpeakShadowing => 'Shadowing';

  @override
  String get hubHSpeakCodeSwitch => 'Code-Switch and Respect';

  @override
  String get hubHSpeakMissions => 'Speak Missions';

  @override
  String get hubHSpeakCoach => 'Coach insights';

  @override
  String get hubHSpeakBack => 'Back to Speak';

  @override
  String get hubHSpeakNotAvailableTitle => 'Not available yet';

  @override
  String hubHSpeakNotAvailableWhat(String name) {
    return '$name is not available yet.';
  }

  @override
  String get hubHSpeakNotAvailableWhy => 'This screen is not built yet.';

  @override
  String get hubHSpeakNotAvailableNext => 'Go back to Speak.';

  @override
  String get hubHSpeakEmptyWhat => 'Speak has nothing to open yet.';

  @override
  String get hubHSpeakEmptyWhy => 'No speaking place is listed.';

  @override
  String get hubHSpeakEmptyNext => 'Open Polie and hold to talk.';

  @override
  String get hubHSpeakOpenPolie => 'Open Polie';

  @override
  String get hubHSpeakErrorWhat => 'Speak did not open.';

  @override
  String get hubHSpeakErrorWhy => 'The list did not come back.';

  @override
  String get hubHSpeakErrorNext => 'Try again.';

  @override
  String get hubHSpeakOfflineWhy => 'Speak is not saved on the phone.';

  @override
  String get hubHSpeakTalk => 'Talk with Polie.';

  @override
  String get hubHSpeakModeChat => 'Chat';

  @override
  String get hubHSpeakModeExplain => 'Explain';

  @override
  String get hubHSpeakModeCorrect => 'Correct me';

  @override
  String get hubHSpeakModeRoleplay => 'Roleplay';

  @override
  String get hubHSpeakModeStory => 'Story';

  @override
  String get hubHSpeakModeTranslate => 'Translate';

  @override
  String get hubHSpeakOn => 'On';

  @override
  String hubHSpeakModeOn(String mode) {
    return '$mode, on';
  }

  @override
  String get hubHSpeakNoReply => 'No reply yet';

  @override
  String get hubHSpeakPolieEmptyWhat => 'Polie has not spoken.';

  @override
  String get hubHSpeakPolieEmptyWhy => 'You have not held to talk.';

  @override
  String get hubHSpeakPolieEmptyNext => 'Hold to talk when you are ready.';

  @override
  String get hubHSpeakHoldToTalk => 'Hold to talk';

  @override
  String get hubHSpeakPolieErrorWhat => 'The voice screen did not load.';

  @override
  String get hubHSpeakPolieErrorWhy => 'The tutor screen did not come back.';

  @override
  String get hubHSpeakPolieOfflineWhy => 'Polie needs the network to answer.';

  @override
  String get hubHPlayTitle => 'Play';

  @override
  String get hubHPlaySubtitle => 'Games sit on skill shelves.';

  @override
  String get hubHPlayShelfTone => 'Tone & Sound';

  @override
  String get hubHPlayShelfWords => 'Words';

  @override
  String get hubHPlayShelfGrammar => 'Grammar';

  @override
  String get hubHPlayShelfSpeaking => 'Speaking';

  @override
  String get hubHPlayShelfCulture => 'Culture';

  @override
  String get hubHPlayShelfTraditional => 'Traditional';

  @override
  String get hubHPlayShelfMultiplayer => 'Multiplayer';

  @override
  String get hubHPlayToneForge => 'Tone Forge';

  @override
  String get hubHPlayGameGames => 'Games';

  @override
  String get hubHPlayGameChallengeFriend => 'Challenge Friend';

  @override
  String get hubHPlayGameFlashcardFocus => 'Flashcard Focus';

  @override
  String get hubHPlayGameApiLanguages => 'Games API Languages';

  @override
  String get hubHPlayGameEnhancedCatalog => 'Games Enhanced Catalog';

  @override
  String get hubHPlayGameMatchingPairs => 'Matching Pairs';

  @override
  String get hubHPlayBack => 'Back to Play';

  @override
  String get hubHPlayNotAvailableTitle => 'Not available yet';

  @override
  String hubHPlayNotAvailableWhat(String name) {
    return '$name is not available yet.';
  }

  @override
  String get hubHPlayNotAvailableWhy => 'This screen is not built yet.';

  @override
  String get hubHPlayNotAvailableNext => 'Go back to Play.';

  @override
  String get hubHPlayEmptyWhat => 'The shelves have no games.';

  @override
  String get hubHPlayEmptyWhy => 'No game came back.';

  @override
  String get hubHPlayEmptyNext => 'Try again.';

  @override
  String get hubHPlayErrorWhat => 'The game list did not open.';

  @override
  String get hubHPlayErrorWhy => 'The list did not come back.';

  @override
  String get hubHPlayErrorNext => 'Try again.';

  @override
  String get hubHPlayOfflineWhy => 'These games are not saved on the phone.';

  @override
  String get hubHPlayShelfEmptyWhat => 'This shelf has no game.';

  @override
  String get hubHPlayShelfEmptyWhy => 'No game is listed on this shelf.';

  @override
  String get hubHPlayShelfEmptyNext => 'Open the Arcade.';

  @override
  String get hubHPlayOpenArcade => 'Open the Arcade';

  @override
  String get hubHVillageTitle => 'Village';

  @override
  String get hubHVillageMap => 'Village map';

  @override
  String get hubHVillageCircles => 'Circles';

  @override
  String get hubHVillageSquare => 'Square';

  @override
  String get hubHVillageChats => 'Chats';

  @override
  String get hubHVillageStatus => 'Status';

  @override
  String get hubHVillageClips => 'Clips';

  @override
  String get hubHVillageRadio => 'Radio';

  @override
  String get hubHVillageSchool => 'School';

  @override
  String get hubHVillageElderHut => 'Elder Hut';

  @override
  String get hubHVillageCorrections => 'Corrections';

  @override
  String get hubHVillageCreate => 'Create';

  @override
  String get hubHVillageVerify => 'Verify';

  @override
  String get hubHVillageBack => 'Back to Village';

  @override
  String get hubHVillageLocked => 'Locked';

  @override
  String get hubHVillagePreview => 'Preview';

  @override
  String get hubHVillageOpenAnyway => 'Open anyway';

  @override
  String get hubHVillageGuardian => 'A guardian must open this.';

  @override
  String get hubHVillageUnlocksA2 => 'Unlocks at A2.';

  @override
  String get hubHVillageUnlocksB1 => 'Unlocks at B1.';

  @override
  String hubHVillageLockedSemantics(String name, String line) {
    return '$name, Locked. $line';
  }

  @override
  String get hubHVillageNotAvailableTitle => 'Not available yet';

  @override
  String hubHVillageNotAvailableWhat(String name) {
    return '$name is not available yet.';
  }

  @override
  String get hubHVillageNotAvailableWhy => 'This screen is not built yet.';

  @override
  String get hubHVillageNotAvailableNext => 'Go back to Village.';

  @override
  String get hubHVillageEmptyWhat => 'No places yet.';

  @override
  String get hubHVillageEmptyWhy => 'The place list is empty.';

  @override
  String get hubHVillageEmptyNext => 'Try again.';

  @override
  String get hubHVillageErrorWhat => 'Village did not open.';

  @override
  String get hubHVillageErrorWhy => 'The place list did not come back.';

  @override
  String get hubHVillageErrorNext => 'Try again.';

  @override
  String get hubHVillageOfflineWhy => 'Village is not saved on the phone.';

  @override
  String get hubHMeTitle => 'Me';

  @override
  String get hubHMeProfile => 'Profile and avatar';

  @override
  String get hubHMeProgress => 'Progress';

  @override
  String get hubHMeAchievements => 'Achievements';

  @override
  String get hubHMeLeagues => 'Leagues';

  @override
  String get hubHMeFamily => 'Family';

  @override
  String get hubHMePlus => 'Plus';

  @override
  String get hubHMeSettings => 'Settings';

  @override
  String get hubHMeAbout => 'About';

  @override
  String get hubHMeBack => 'Back to Me';

  @override
  String get hubHMeLeave => 'Back';

  @override
  String get hubHMeNotAvailableTitle => 'Not available yet';

  @override
  String hubHMeNotAvailableWhat(String name) {
    return '$name is not available yet.';
  }

  @override
  String get hubHMeNotAvailableWhy => 'This screen is not built yet.';

  @override
  String get hubHMeNotAvailableNext => 'Go back to Me.';

  @override
  String get hubHMeEmptyWhat => 'Me has nothing to open yet.';

  @override
  String get hubHMeEmptyWhy => 'No profile is saved.';

  @override
  String get hubHMeEmptyNext => 'Open Profile and avatar.';

  @override
  String get hubHMeOpenProfile => 'Open Profile';

  @override
  String get hubHMeErrorWhat => 'Me did not open.';

  @override
  String get hubHMeErrorWhy => 'The list did not come back.';

  @override
  String get hubHMeErrorNext => 'Try again.';

  @override
  String get hubHMeOfflineWhy => 'Me is not saved on the phone.';

  @override
  String get hubHMeNoName => 'No name is saved.';

  @override
  String get hubHMeNoAvatar => 'No avatar is saved.';

  @override
  String get hubHMeAvatar => 'Avatar';

  @override
  String get hubHMeProfileEmptyWhat => 'No profile is saved on this phone.';

  @override
  String get hubHMeProfileEmptyWhy => 'A name and avatar have not been saved.';

  @override
  String get hubHMeProfileEmptyNext => 'Go back to Me.';

  @override
  String get lensBridge => 'Conversation Bridge';

  @override
  String get lensPermissionWhat => 'The camera is blocked.';

  @override
  String get lensPermissionWhy =>
      'LingAfriq does not have permission to use the camera.';

  @override
  String get lensPermissionNext => 'Open Settings and allow the camera.';

  @override
  String get lensOfflineTranslateWhy =>
      'Live Translate needs the network to listen and translate.';

  @override
  String get lensRecognizerMissingWhat =>
      'Point & Say cannot name this offline.';

  @override
  String get lensRecognizerMissingWhy =>
      'The on-device recognizer is not on this phone.';

  @override
  String get lensRecognizerMissingNext =>
      'Connect, then open Point & Say again. This phone has no on-device recognizer.';

  @override
  String get lensNoWordWhat => 'No word is open.';

  @override
  String get lensNoWordWhy => 'Point & Say has not named a word.';

  @override
  String get lensNoWordNext =>
      'Point at one thing, then open Living Dictionary.';

  @override
  String get practiceGamePlayingLabel => 'Practice game';

  @override
  String get practiceGameSaveFailedWhat => 'This round was not saved.';

  @override
  String get practiceGameSaveFailedWhy =>
      'The learner record did not reach the outbox.';

  @override
  String get practiceGameSaveFailedNext =>
      'Try again. This round is not marked saved.';

  @override
  String get practiceGameRetry => 'Try again';

  @override
  String get practiceGameSaved => 'Saved to your learner record.';

  @override
  String get practiceGameUnavailable => 'Unavailable';

  @override
  String get directoryTitle => 'All features';

  @override
  String get directoryOpenSemantics => 'Open all features';

  @override
  String get directorySearchLabel => 'Search features';

  @override
  String get directoryLocked => 'Locked';

  @override
  String directoryUnlocksAt(String stage) {
    return 'Unlocks at $stage.';
  }

  @override
  String get directoryPreview => 'Preview';

  @override
  String directoryOpenFeature(String feature) {
    return 'Open $feature';
  }

  @override
  String directoryLockedSemantics(
    String feature,
    String stage,
    String preview,
  ) {
    return '$feature, Locked. Unlocks at $stage. $preview';
  }

  @override
  String get directoryEmptyTitle => 'No match';

  @override
  String directoryEmptyWhat(String query) {
    return 'Nothing matches $query.';
  }

  @override
  String get directoryEmptyWhy => 'That name is not in the directory.';

  @override
  String get directoryEmptyNext => 'Try another name.';

  @override
  String get directoryEmptyAction => 'Clear search';

  @override
  String get directoryBack => 'Back to Me';

  @override
  String get revRvMeHandleTitle => 'Global handle';

  @override
  String get revRvMeHandleEmptyWhat => 'No handle is saved.';

  @override
  String get revRvMeHandleEmptyWhy =>
      'Friends cannot find you by a handle yet.';

  @override
  String get revRvMeHandleEmptyNext => 'Choose a handle.';

  @override
  String get revRvMeHandleChoose => 'Choose a handle';

  @override
  String get revRvMeHandleErrorWhat => 'The handle did not open.';

  @override
  String get revRvMeHandleErrorWhy => 'The saved handle did not come back.';

  @override
  String get revRvMeHandleErrorNext => 'Try again.';

  @override
  String get revRvMeHandleOfflineWhy => 'The handle is not saved on the phone.';

  @override
  String get revRvMeHandleCurrent => 'Current handle';

  @override
  String get revRvMeHandleField => 'Handle';

  @override
  String get revRvMeHandleHint => 'Type the handle you want.';

  @override
  String get revRvMeHandleServer =>
      'The server checks that this handle is unique and not profane.';

  @override
  String get revRvMeHandleSave => 'Save handle';

  @override
  String get revRvMeHandleSaved => 'Handle saved.';

  @override
  String get revRvMeHandleNeeded => 'Enter a handle before saving.';

  @override
  String get revRvMeHandleRejected => 'The server rejected this handle.';

  @override
  String get revRvMeHandleCheckWhat => 'The handle was not saved.';

  @override
  String get revRvMeHandleCheckWhy =>
      'Uniqueness and profanity could not be checked.';

  @override
  String get revRvMeHandleCheckNext => 'Try again. Nothing was saved.';

  @override
  String get revRvMeHandleSaveWhat => 'The handle was not saved.';

  @override
  String get revRvMeHandleSaveWhy => 'The server did not keep this handle.';

  @override
  String get revRvMeHandleSaveNext => 'Try again. Nothing was saved.';

  @override
  String get revRvMeAboutEmptyWhat => 'No story is saved.';

  @override
  String get revRvMeAboutEmptyWhy => 'About has nothing to show.';

  @override
  String get revRvMeAboutEmptyNext => 'Go back to Me.';

  @override
  String get revRvMeAboutErrorWhat => 'About did not open.';

  @override
  String get revRvMeAboutErrorWhy => 'The story did not come back.';

  @override
  String get revRvMeAboutErrorNext => 'Try again.';

  @override
  String get revRvMeAboutOfflineWhy => 'About is not saved on the phone.';

  @override
  String get revRvTodayChallengesEmptyWhat => 'No challenges are saved.';

  @override
  String get revRvTodayChallengesEmptyWhy => 'Today has no challenge list yet.';

  @override
  String get revRvTodayChallengesEmptyNext => 'Go back to Today.';

  @override
  String get revRvTodayChallengesErrorWhat => 'Challenges did not open.';

  @override
  String get revRvTodayChallengesErrorWhy =>
      'The challenge list did not come back.';

  @override
  String get revRvTodayChallengesErrorNext => 'Try again.';

  @override
  String get revRvTodayChallengesOfflineWhy =>
      'Challenges are not saved on the phone.';

  @override
  String revRvTodayChallengesProgress(int current, int target) {
    return '$current of $target';
  }

  @override
  String get revRvLearnReviewDashboard => 'Review dashboard';

  @override
  String get revRvLearnReviewEmptyWhat => 'No review is saved.';

  @override
  String get revRvLearnReviewEmptyWhy => 'There is no review to show.';

  @override
  String get revRvLearnReviewEmptyNext => 'Open Path and start a lesson.';

  @override
  String get revRvLearnReviewFailWhat => 'The review did not open.';

  @override
  String get revRvLearnReviewFailWhy => 'The review list did not come back.';

  @override
  String get revRvLearnReviewFailNext => 'Try again.';

  @override
  String get revRvLearnReviewOfflineWhy =>
      'This review is not saved on the phone.';

  @override
  String get revRvLearnVocabDashboard => 'Vocabulary dashboard';

  @override
  String get revRvLearnVocabEmptyWhat => 'No saved word yet.';

  @override
  String get revRvLearnVocabEmptyWhy => 'Words you save show up here.';

  @override
  String get revRvLearnVocabEmptyNext =>
      'Long-press a target-language word and save it.';

  @override
  String get revRvLearnVocabFailWhat => 'The word list did not open.';

  @override
  String get revRvLearnVocabFailWhy => 'The saved words did not come back.';

  @override
  String get revRvLearnVocabFailNext => 'Try again.';

  @override
  String get revRvLearnVocabOfflineWhy =>
      'These words are not saved on the phone.';

  @override
  String get revRvLearnRecapEmptyTitle => 'No recap yet';

  @override
  String get revRvLearnRecapEmptyWhat => 'This lesson has no recap.';

  @override
  String get revRvLearnRecapEmptyWhy => 'The lesson has not been finished.';

  @override
  String get revRvLearnRecapEmptyNext => 'Open Path and start a lesson.';

  @override
  String get revRvLearnRecapFailWhat => 'The recap did not open.';

  @override
  String get revRvLearnRecapFailWhy => 'The lesson recap did not come back.';

  @override
  String get revRvLearnRecapFailNext => 'Try again.';

  @override
  String get revRvLearnRecapOfflineWhy =>
      'This recap is not saved on the phone.';

  @override
  String get revRvLearnRecapWords => 'Words from this lesson';

  @override
  String get revRvLearnDownloadsEmptyTitle => 'Nothing is saved';

  @override
  String get revRvLearnDownloadsEmptyWhat => 'Nothing is saved on the phone.';

  @override
  String get revRvLearnDownloadsEmptyWhy => 'No lesson pack is on this phone.';

  @override
  String get revRvLearnDownloadsEmptyNext =>
      'Open Path and choose a lesson to save.';

  @override
  String get revRvLearnDownloadsFailWhat => 'The download did not finish.';

  @override
  String get revRvLearnDownloadsFailWhy => 'The lesson pack did not come back.';

  @override
  String get revRvLearnDownloadsFailNext => 'Try again.';

  @override
  String get revRvLearnDownloadsStorageUnknown => 'Storage use is unknown.';

  @override
  String revRvLearnDownloadsStorage(String size) {
    return 'Storage use: $size';
  }

  @override
  String get revRvLearnDownloadsInProgress => 'Download in progress.';

  @override
  String get revRvShadowEmptyWhat => 'No clip is ready.';

  @override
  String get revRvShadowEmptyWhy => 'Shadowing has nothing to play.';

  @override
  String get revRvShadowEmptyNext => 'Go back to Speak.';

  @override
  String get revRvShadowNoAttemptWhat => 'No attempt yet.';

  @override
  String get revRvShadowNoAttemptWhy => 'You have not spoken this clip.';

  @override
  String get revRvShadowNoAttemptNext => 'Record when you are ready.';

  @override
  String get revRvShadowRecord => 'Record';

  @override
  String get revRvShadowErrorWhat => 'Shadowing did not open.';

  @override
  String get revRvShadowErrorWhy => 'The clip did not come back.';

  @override
  String get revRvShadowScoreErrorWhat => 'The attempt was not scored.';

  @override
  String get revRvShadowScoreErrorWhy =>
      'Nothing from that attempt is still on screen.';

  @override
  String get revRvShadowErrorNext => 'Try again.';

  @override
  String get revRvShadowPractice =>
      'Pronunciation scoring is unavailable. You can keep practising without a ranked score.';

  @override
  String get revRvShadowUnsure =>
      'We could not score this clearly. No score is shown.';

  @override
  String get revRvShadowScoreLabel => 'Score';

  @override
  String revRvShadowScoreValue(int percent) {
    return '$percent%';
  }

  @override
  String get revRvShadowOfflineWhy => 'Shadowing is not saved on the phone.';

  @override
  String get unlockLocked => 'Locked';

  @override
  String unlockUnlocksAt(String stage) {
    return 'Unlocks at $stage.';
  }

  @override
  String get unlockStageDay1 => 'Day 1';

  @override
  String get unlockStageAccount => 'Account created';

  @override
  String get unlockStageWeek1 => 'Week 1 or A1 unit 3';

  @override
  String get unlockStageA2 => 'A2';

  @override
  String get unlockStageB1 => 'B1';

  @override
  String get unlockNative => 'Unlocks for native speakers.';

  @override
  String get unlockPreview => 'Preview';

  @override
  String get unlockOpenAnyway => 'Open anyway';

  @override
  String get unlockPreviewNote => 'This preview does not mark a lesson done.';

  @override
  String unlockOpened(String name) {
    return '$name is open.';
  }

  @override
  String get unlockSafety => 'A guardian must open this.';

  @override
  String unlockSemantics(String name, String line) {
    return '$name, Locked. $line';
  }

  @override
  String get unlockBack => 'Back';

  @override
  String get unlockFeatureToday => 'Today';

  @override
  String get unlockFeatureFirstUnit => 'First unit';

  @override
  String get unlockFeaturePolieBasic => 'Polie basic';

  @override
  String get unlockFeatureLens => 'Lens';

  @override
  String get unlockFeatureGames => 'Games';

  @override
  String get unlockFeatureWordCard => 'Word Card';

  @override
  String get unlockFeatureMagazine => 'Magazine';

  @override
  String get unlockFeatureEvents => 'Events';

  @override
  String get unlockFeatureStreaks => 'Streaks';

  @override
  String get unlockFeatureCircles => 'Circles';

  @override
  String get unlockFeatureSquare => 'Square';

  @override
  String get unlockFeatureGlobalHandle => 'Global handle';

  @override
  String get unlockFeaturePersonas => 'Personas';

  @override
  String get unlockFeatureScenarios => 'Scenarios';

  @override
  String get unlockFeatureChats => 'Chats';

  @override
  String get unlockFeatureStatus => 'Status';

  @override
  String get unlockFeaturePractice => 'Practice';

  @override
  String get unlockFeatureClips => 'Clips';

  @override
  String get unlockFeatureNativeCorrections => 'Native Corrections';

  @override
  String get unlockFeaturePassport => 'Passport';

  @override
  String get unlockFeatureCodeSwitch => 'Code-Switch';

  @override
  String get unlockFeatureRespect => 'Respect';

  @override
  String get unlockFeatureRadio => 'Radio';

  @override
  String get unlockFeatureCreate => 'Create';

  @override
  String get unlockFeatureHostRooms => 'Host rooms';

  @override
  String get unlockFeatureMentoring => 'Mentoring';

  @override
  String get unlockFeatureContribute => 'Contribute';

  @override
  String get unlockFeatureVerify => 'Verify';

  @override
  String get unlockFeatureCalls => 'Calls';

  @override
  String get unlockFeaturePublicPost => 'Public post';

  @override
  String get unlockFeatureUnknown => 'This feature';
}
