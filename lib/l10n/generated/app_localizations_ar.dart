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
    return 'بريميوم $premium شهريًا\nالعائلة $family شهريًا\nمدى الحياة $lifetime تُدفع مرة واحدة';
  }

  @override
  String paywallChargedTo(String store) {
    return 'يُخصم المبلغ من حسابك في $store.';
  }

  @override
  String get paywallRenewsAuto =>
      'تتجدد الخطط الشهرية تلقائيًا بالسعر نفسه حتى تلغيها. خطة مدى الحياة لا تتجدد.';

  @override
  String paywallRenewsOn(String date) {
    return 'تتجدد خطتك في $date.';
  }

  @override
  String paywallTrialOffered(int days, String price) {
    return 'تجربة مجانية لمدة $days يومًا، ثم $price شهريًا ما لم تلغِ قبل انتهائها بـ 24 ساعة على الأقل.';
  }

  @override
  String get paywallTrialGeneric =>
      'إذا عُرضت فترة تجريبية، تدفع سعر الخطة عند انتهائها ما لم تلغِ قبلها بـ 24 ساعة على الأقل.';

  @override
  String get paywallCancelApple =>
      'في أي وقت من الإعدادات ‹ اسمك ‹ الاشتراكات. يبقى وصولك حتى نهاية الفترة المدفوعة.';

  @override
  String get paywallCancelGoogle =>
      'في أي وقت من ⁦Google Play⁩ ‹ الدفعات والاشتراكات ‹ الاشتراكات. يبقى وصولك حتى نهاية الفترة المدفوعة.';

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
}
