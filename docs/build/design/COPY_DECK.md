# Copy deck

A reviewer has not approved this file.

Status: Draft.

This file lists the strings that will ship. It does not change the app, the screens, or the ARB files. Each ARB key is a proposal written here only.

The old village questions are quoted, then replaced with plain questions. Warmth stays in the meaning. A puzzle does not.

Sound and haptic cues stay in the motion spec. This file does not restate them.

## Grade

Every new string is scored with the Flesch-Kincaid grade level:

Grade = 0.39 * (words / sentences) + 11.8 * (syllables / words) - 15.59

How a string is counted:

- A sentence ends at a full stop, a question mark, or an exclamation mark. A string with no end mark is one sentence.
- Words split on spaces. A hyphen splits one token into two words, so "long-press" is "long" and "press", and "target-language" is "target" and "language".
- A comma does not end a sentence and does not split a word.
- Syllables are the spoken count. A silent e is not a syllable, so "Save" and "Close" are one syllable each. "Continue" is three (con-tin-ue). "Practise" and "practised" are two. "Polie" is two. "Curiosity" is five (cu-ri-os-i-ty).
- A number is spoken as a word. 5 is "five" (1). 10 is "ten" (1). 12 is "twelve" (1). 15 is "fifteen" (2). 20 is "twenty" (2). 60 is "sixty" (2). The digit 2 is "two" (1).

The grade cell shows the result and the three inputs, in this order: words, syllables, sentences. A reader can put those three numbers into the formula.

Worked example. "Try again" is 2 words, 3 syllables (try, a-gain), 1 sentence.

0.39 * (2 / 1) + 11.8 * (3 / 2) - 15.59 = 0.78 + 17.70 - 15.59 = 2.89

A grade below 0 means the line is easier than grade 1. It still passes, because the bar is 7 or lower.

A draft over 7 is listed below as rejected. The fix is the shipped string. Every string in a shipped column is 7 or lower. None of those grades is a hidden failure.

Spoken counts this file relies on, when the word is not a single short syllable: about 2, account 2, after 2, again 2, another 3, answer 2, answers 2, anyway 3, audio 3, avatar 3, before 2, begin 2, camera 3, casual 3, celebrate 3, celebration 4, chosen 2, clients 2, colleagues 2, colour 2, community 4, complete 2, connect 2, continue 3, correct 2, culture 2, curious 3, curiosity 5, daily 2, data 2, deleted 3, directions 3, elders 2, empty 2, enough 2, family 3, features 2, finished 2, gatherings 3, greeting 2, greetings 2, happened 2, heritage 3, import 2, intense 2, journey 2, language 2, later 2, learning 2, lesson 2, lessons 2, listening 3, markets 2, matters 2, meaning 2, media 3, mentor 2, messages 3, minutes 2, missing 2, morning 2, music 2, native 2, network 2, nothing 2, object 2, offline 2, open 2, opened 2, optional 3, partner 2, people 2, perfection 3, photo 2, picture 2, polie 2, practise 2, practised 2, preview 2, profile 2, progress 2, proverbs 2, quiet 2, ready 2, reply 2, review 2, sample 2, seconds 2, serious 3, session 2, someone 2, speaker 2, spoken 2, steady 2, stories 2, study 2, syllable 3, talking 2, target 2, teacher 2, timer 2, today 2, travel 2, tutor 2, unit 2, unlocks 2, unsure 2, until 2, village 2, welcome 2, within 2. "Cannot" is two. Any other word in the tables is one syllable.

## Rejected for grade

These drafts are over 7. They do not ship. The fix does.

| Draft | Grade | Shipped fix | Fix grade |
| --- | --- | --- | --- |
| Practise | 8.40 (1 word, 2 syllables, 1 sentence) | Practise this word | 1.31 (3, 4, 1) |
| Continue | 20.20 (1, 3, 1) | Continue to the next unit | 5.24 (5, 8, 1) |
| Play audio | 8.79 (2, 4, 1) | Play the audio | 5.25 (3, 5, 1) |
| Preview | 8.40 (1, 2, 1) | See a preview | 1.31 (3, 4, 1) |
| Open anyway | 14.69 (2, 5, 1) | Open the locked lesson | 3.67 (4, 6, 1) |
| Begin Journey | 8.79 (2, 4, 1) | Hear it | -3.01 (2, 2, 1) |
| 15 minutes | 8.79 (2, 4, 1) | 15 minutes a day | 3.67 (4, 6, 1) |
| 20 minutes | 8.79 (2, 4, 1) | 20 minutes a day | 3.67 (4, 6, 1) |
| Casual | 20.20 (1, 3, 1) | 5 minutes a day | 0.72 (4, 5, 1) |
| Steady | 8.40 (1, 2, 1) | 10 minutes a day | 0.72 (4, 5, 1) |
| Serious | 20.20 (1, 3, 1) | 15 minutes a day | 3.67 (4, 6, 1) |
| Intense | 8.40 (1, 2, 1) | 20 minutes a day | 3.67 (4, 6, 1) |
| Colleagues, clients and community | 12.52 (4, 9, 1) | Talk with people at work. | 0.52 (5, 6, 1) |
| Heritage and culture | 9.18 (3, 6, 1) | For my heritage | 5.25 (3, 5, 1) |
| Travel | 8.40 (1, 2, 1) | For travel | 2.89 (2, 3, 1) |
| Partner | 8.40 (1, 2, 1) | For a partner | 1.31 (3, 4, 1) |
| Curiosity | 43.80 (1, 5, 1) | I am curious | 5.25 (3, 5, 1) |
| Unlocks after Morning greetings. | 9.57 (4, 8, 1) | Morning greetings comes first. | 3.67 (4, 6, 1) |
| Lesson complete. | 8.79 (2, 4, 1) | The lesson is complete. | 3.67 (4, 6, 1) |
| Lesson unit complete. | 9.18 (3, 6, 1) | The unit is complete. | 3.67 (4, 6, 1) |
| Unit 2. Family. | 8.60 (3, 6, 2) | Next is the Family unit. | 5.24 (5, 8, 1) |
| Avatar can wait until after lesson 2. | 7.37 (7, 12, 1) | You can make an avatar after lesson two. | 5.23 (8, 12, 1) |
| Polie is listening. | 9.18 (3, 6, 1) | Polie is listening to you. | 5.24 (5, 8, 1) |
| Celebrate progress, not perfection. | 12.52 (4, 9, 1) | You said the greeting. | 0.72 (4, 5, 1) |

"Unit 2. Family." is two sentences because of the full stop: "Unit 2" and "Family".

## Onboarding questions

The nine old steps are Welcome, Elder, Weaver, Elder's Question, Path Chooser, Rhythm Master, Timekeeper, Griot, and Naming Ceremony. ELEVATION.md section 5.1 names them. Section 5.3 says to replace "Who are you, and why do you seek knowledge?" with plain questions.

A search of lib/ does not find that full sentence. The citation points at an older line in unified_onboarding_screen.dart. The live lines that ask the same thing are in lib/screens/onboarding/kijiji_onboarding_screen.dart: "Tell me: who are you?" and "Why are you learning?" The avatar lines are in lib/avatars/onboarding/onboarding_avatar_widget.dart. Newer plain lines already live under lib/screens/onboarding/unified/. Where a live line is already plain and at grade 7 or lower, this deck ships it. Where it is a riddle, a boast, or over grade 7, the table gives the replacement.

The Rhythm Master step asked how the learner learns. That question does not ship. ELEVATION.md section 5.1 says a learning-style question sets a false hope. The speaking question replaces it.

| Step | Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- | --- |
| Welcome | Welcome, young one, to our village of languages. | Welcome. You will hear a greeting, then say it. | 0.59 (9, 11, 2) | onboardingWelcome | First screen, before any question |
| Welcome | Welcome to Kijiji cha Lugha | Welcome. You will hear a greeting, then say it. | 0.59 (9, 11, 2) | onboardingWelcome | Same screen. The old title is the Kijiji welcome |
| Elder (home language) | What language do you speak? | Which language do you speak at home? | 0.63 (7, 8, 1) | onboardingAskHome | Language step, home language. The live label is "I speak" |
| Weaver (language to learn) | I am Adisa, the Weaver. Choose the threads of your voice. | What do you want to learn? | -1.45 (6, 6, 1) | onboardingAskTarget | Language step, the language to learn |
| Elder's Question | Who are you, and why do you seek knowledge? | What year were you born? | -1.84 (5, 5, 1) | onboardingAskBirthYear | Birth year, before anything social |
| Elder's Question | Tell me: who are you? | Why are you learning this language? | 2.48 (6, 8, 1) | onboardingAskWhy | Goal step, with the choices below |
| Path Chooser | Choose your path. | What do you want to use it for? | -0.67 (8, 8, 1) | onboardingAskGoal | Same goal step. The key is the goal question |
| Path Chooser | What brings you to learn this beautiful language? | What do you want to use it for? | -0.67 (8, 8, 1) | onboardingAskGoal | Same question. The old line is the pathfinder riddle |
| Rhythm Master | I am Nuru the Rhythm Master. Tap the drum that sings to your spirit. | Can you say this greeting out loud? | 0.63 (7, 8, 1) | onboardingAskSpeak | First spoken word, in place of the style riddle |
| Rhythm Master | How does your spirit best receive knowledge? | Can you say this greeting out loud? | 0.63 (7, 8, 1) | onboardingAskSpeak | Same speaking question |
| Timekeeper | I am Zawadi, keeper of time. When shall we train your tongue? | How much time a day feels right? | -1.06 (7, 7, 1) | onboardingAskTime | Time step. The live line is already this question |
| Griot | I am Amina the Griot. How shall I speak to you? | How should Polie talk with you? | 0.52 (6, 7, 1) | onboardingAskPolie | How Polie talks. No points choice on this step |
| Naming Ceremony | A learner without a name is a drum without a rhythm. | What should we call you? | -1.84 (5, 5, 1) | onboardingAskName | Name step. The live question is "Pick a name" |
| Save | Save your progress and your streak. | Save your progress? | 1.31 (3, 4, 1) | onboardingAskSave | After the first lesson, before an account |
| Save | None | You finished the first lesson. | 2.88 (5, 7, 1) | onboardingSaveDone | Line under the save question |
| Save | None | An account keeps it if you change phones. | 0.80 (8, 9, 1) | onboardingSaveWhy | Why the account helps |
| Save | Later. My answers stay on this phone | Your answers stay on this phone. | 0.52 (6, 7, 1) | onboardingSaveLater | Quiet line if the learner waits. The button is Skip for now |
| Notification | A soft nudge when it matters | Want a nudge at the time you practised today? | 2.34 (9, 11, 1) | onboardingAskNudge | After lesson 1. The time is the learner's own practice time |
| Family chip | None | My family speaks this. | 3.67 (4, 6, 1) | onboardingFamilySpeaks | Optional chip on the language step |

Goal choices. The old one-word labels that failed grade are in the rejected table. These ship:

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| Talk to family | For my family | 5.25 (3, 5, 1) | onboardingGoalFamily | Goal choices |
| Heritage and culture | For my heritage | 5.25 (3, 5, 1) | onboardingGoalHeritage | Goal choices |
| Travel | For travel | 2.89 (2, 3, 1) | onboardingGoalTravel | Goal choices |
| None | For work | -3.01 (2, 2, 1) | onboardingGoalWork | Goal choices |
| None | For school | -3.01 (2, 2, 1) | onboardingGoalSchool | Goal choices |
| None | For a partner | 1.31 (3, 4, 1) | onboardingGoalPartner | Goal choices |
| Curiosity | I am curious | 5.25 (3, 5, 1) | onboardingGoalCurious | Goal choices |
| Greet elders and keep up at gatherings | Greet elders and keep up at gatherings | 4.00 (7, 10, 1) | onboardingHintFamily | Hint under For my family |
| Proverbs, names, music and stories | Proverbs, names, music and stories | 5.24 (5, 8, 1) | onboardingHintHeritage | Hint under For my heritage |
| Markets, directions and small talk | Markets, directions and small talk | 5.24 (5, 8, 1) | onboardingHintTravel | Hint under For travel |
| Colleagues, clients and community | Talk with people at work. | 0.52 (5, 6, 1) | onboardingHintWork | Hint under For work |

Time choices. Casual, Steady, Serious, and Intense do not ship. Neither do the short labels "15 minutes" and "20 minutes".

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| Casual | 5 minutes a day | 0.72 (4, 5, 1) | onboardingTime5 | Time choices |
| Steady | 10 minutes a day | 0.72 (4, 5, 1) | onboardingTime10 | Time choices |
| Serious | 15 minutes a day | 3.67 (4, 6, 1) | onboardingTime15 | Time choices |
| Intense | 20 minutes a day | 3.67 (4, 6, 1) | onboardingTime20 | Time choices |

How Polie talks. The old question "How much game feel?" does not ship. See the last section.

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | Warm and kind | -2.62 (3, 3, 1) | onboardingPolieWarm | Polie talk choices |
| None | Short and clear | -2.62 (3, 3, 1) | onboardingPolieClear | Polie talk choices |

## Buttons

Each shipped button starts with a verb, except "I said it". That label is the one on the first-word frame and the lesson frame. It reports the act. The verb in the line is "said". This deck keeps it.

"All features" is the visible label on the Profile frame. It does not start with a verb. The spoken name on that frame already starts with a verb. This deck ships that spoken name as the button: "Open all features".

"Practise", "Continue", "Play audio", "Preview", "Open anyway", and "Begin Journey" are rejected above because their grade is over 7. The fixes start with the same kind of verb.

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| Start | Start | -3.40 (1, 1, 1) | buttonStart | Today, and the current lesson on Path |
| Try again | Try again | 2.89 (2, 3, 1) | buttonTryAgain | Error and empty states that ask for another try |
| Open Path | Open Path | 2.89 (2, 3, 1) | buttonOpenPath | Today empty, and Lesson empty |
| Close | Close | -3.40 (1, 1, 1) | buttonClose | Lesson, Word Card, and Lens |
| Save | Save | -3.40 (1, 1, 1) | buttonSave | Word Card, beside Practise this word |
| Practise | Practise this word | 1.31 (3, 4, 1) | buttonPractiseWord | Word Card, the filled accent button |
| Hold to talk | Hold to talk | -2.62 (3, 3, 1) | buttonHoldToTalk | Polie, before the mic is open |
| Stop | Stop | -3.40 (1, 1, 1) | buttonStop | Polie, while the mic is open |
| Skip for now | Skip for now | -2.62 (3, 3, 1) | buttonSkipForNow | Profile, and the save step if the learner waits |
| Continue | Continue to the next unit | 5.24 (5, 8, 1) | buttonContinueNextUnit | Level up |
| Back to Today | Back to Today | 1.31 (3, 4, 1) | buttonBackToToday | Lesson complete, and Level up when there is no next unit |
| I said it | I said it | -2.62 (3, 3, 1) | buttonISaidIt | First spoken word, and the speaking step in Lesson |
| Hear it | Hear it | -3.01 (2, 2, 1) | buttonHearIt | First spoken word, and the welcome screen in place of Begin Journey |
| All features | Open all features | 5.25 (3, 5, 1) | buttonOpenAllFeatures | Profile, the filled accent button |
| Open Square | Open Square | 2.89 (2, 3, 1) | buttonOpenSquare | Village, the filled accent button |
| Play | Play | -3.40 (1, 1, 1) | buttonPlay | Arcade, on the first game |
| Show a word | Show a word | -2.62 (3, 3, 1) | buttonShowWord | Tone Lens empty, and Word Card empty |
| Play audio | Play the audio | 5.25 (3, 5, 1) | buttonPlayAudio | Word Card |
| Preview | See a preview | 1.31 (3, 4, 1) | buttonSeePreview | Path, on a locked lesson |
| Open anyway | Open the locked lesson | 3.67 (4, 6, 1) | buttonOpenLockedLesson | Path, on a locked lesson |
| Check | Check | -3.40 (1, 1, 1) | buttonCheck | Lesson, after the learner picks a line |
| Say it | Say it | -3.01 (2, 2, 1) | buttonSayIt | Lens, the filled accent button |
| Point again | Point again | 2.89 (2, 3, 1) | buttonPointAgain | Lens empty |
| Back to Path | Back to Path | -2.62 (3, 3, 1) | buttonBackToPath | Lesson error |
| Save look | Save look | -3.01 (2, 2, 1) | buttonSaveLook | Wardrobe, when a look is chosen |

## Error, empty, and offline

The pattern is three short lines: what happened, why, and what to do. These are the lines already on the approved frames. A line that was over grade 7 is not repeated here. Its fix is in the rejected table and, where it is a button or a status line, in the tables above.

The labels of the pattern:

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | What happened | 2.89 (2, 3, 1) | stateWhatHappened | Every empty, error, and offline state |
| None | Why | -3.40 (1, 1, 1) | stateWhy | Every empty, error, and offline state |
| None | What to do | -2.62 (3, 3, 1) | stateWhatToDo | Every empty, error, and offline state |
| None | You are offline | 1.31 (3, 4, 1) | stateYouAreOffline | Title on each offline state |

Shared lines:

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | The phone has no network. | 0.52 (5, 6, 1) | errorNoNetwork | What happened, on every offline state |
| None | Try again. | 2.89 (2, 3, 1) | buttonTryAgain | What to do, on error states that can be tried again. Same words as the button |
| None | Try again later. | 5.25 (3, 5, 1) | errorTryLater | Path empty, what to do |
| None | Connect, then try again. | 3.67 (4, 6, 1) | errorConnectTryAgain | What to do, on offline states other than Lens |
| None | The list did not come back. | -1.45 (6, 6, 1) | errorListDidNotReturn | Why, on Village error and Arcade error |

Today:

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | Today has nothing queued. | 3.67 (4, 6, 1) | emptyTodayWhat | Today empty, what happened |
| None | There is no review due, and no lesson is chosen. | 3.65 (10, 13, 1) | emptyTodayWhy | Today empty, why |
| None | Open Path and start the first lesson. | 2.31 (7, 9, 1) | emptyTodayDo | Today empty, what to do |
| None | The plan did not open. | 0.52 (5, 6, 1) | errorTodayWhat | Today error, what happened |
| None | The lesson list did not come back. | 0.63 (7, 8, 1) | errorTodayWhy | Today error, why |
| None | This plan is not saved on the phone. | -0.67 (8, 8, 1) | offlineTodayWhy | Today offline, why |

Path:

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | This path has no lessons. | 0.52 (5, 6, 1) | emptyPathWhat | Path empty, what happened |
| None | The lesson list is empty. | 2.88 (5, 7, 1) | emptyPathWhy | Path empty, why |
| None | The lesson map did not open. | 2.48 (6, 8, 1) | errorPathWhat | Path error, what happened |
| None | The lesson list failed to load. | 0.52 (6, 7, 1) | errorPathWhy | Path error, why |
| None | This path is not saved on the phone. | -0.67 (8, 8, 1) | offlinePathWhy | Path offline, why |
| Unlocks after Morning greetings. | Morning greetings comes first. | 3.67 (4, 6, 1) | pathLockedAfter | Locked lesson on Path |

Lesson:

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | The session has no lesson. | 2.88 (5, 7, 1) | emptyLessonWhat | Lesson empty, what happened |
| None | You have not chosen a lesson. | 2.48 (6, 8, 1) | emptyLessonWhy | Lesson empty, why |
| None | Open Path and choose a lesson. | 2.48 (6, 8, 1) | emptyLessonDo | Lesson empty, what to do |
| None | The lesson stopped before the first word. | 2.31 (7, 9, 1) | errorLessonWhat | Lesson error, what happened |
| None | The lesson file is missing on this phone. | 2.28 (8, 10, 1) | errorLessonWhy | Lesson error, why |
| None | Try again. If it fails, go back to Path and pick another lesson. | 2.38 (13, 17, 2) | errorLessonDo | Lesson error, what to do |
| None | This lesson is not saved on the phone. | 0.80 (8, 9, 1) | offlineLessonWhy | Lesson offline, why |

Village and Arcade:

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | The place list is empty. | 0.52 (5, 6, 1) | emptyVillageWhat | Village empty, what happened |
| None | No place came back. | -2.23 (4, 4, 1) | emptyVillageWhy | Village empty, why |
| None | The place list did not open. | 0.52 (6, 7, 1) | errorVillageWhat | Village error, what happened |
| None | This village list is not saved on the phone. | 1.03 (9, 10, 1) | offlineVillageWhy | Village offline, why |
| None | The shelves have no games. | -1.84 (5, 5, 1) | emptyArcadeWhat | Arcade empty, what happened |
| None | No game came back. | -2.23 (4, 4, 1) | emptyArcadeWhy | Arcade empty, why |
| None | The game list did not open. | 0.52 (6, 7, 1) | errorArcadeWhat | Arcade error, what happened |
| None | These games are not saved on the phone. | -0.67 (8, 8, 1) | offlineArcadeWhy | Arcade offline, why |

Polie. The AI line says Polie did not speak for the learner. Polie is the tutor.

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | Polie has not spoken. | 3.67 (4, 6, 1) | emptyPolieWhat | Polie empty, what happened |
| None | You have not held to talk. | -1.45 (6, 6, 1) | emptyPolieWhy | Polie empty, why |
| None | Hold to talk when you are ready. | 0.63 (7, 8, 1) | emptyPolieDo | Polie empty, what to do |
| None | The voice screen did not load. | -1.45 (6, 6, 1) | errorPolieWhat | Polie error, what happened |
| None | The tutor screen did not come back. | 0.63 (7, 8, 1) | errorPolieWhy | Polie error, why |
| None | No reply came back. | 0.72 (4, 5, 1) | errorPolieAiWhat | Polie when AI is unavailable, what happened |
| None | The tutor cannot answer right now. | 4.45 (6, 9, 1) | errorPolieAiWhy | Polie when AI is unavailable, why |
| None | Try again later. Polie did not speak for you. | 1.90 (9, 12, 2) | errorPolieAiDo | Polie when AI is unavailable, what to do |
| None | Polie needs the network to answer. | 4.45 (6, 9, 1) | offlinePolieWhy | Polie offline, why |
| Polie is listening. | Polie is listening to you. | 5.24 (5, 8, 1) | polieListening | Polie, while the mic is open |
| None | You are talking. | 1.31 (3, 4, 1) | polieYouTalk | Polie, while the mic is open |

Tone Lens, Word Card, and Lens:

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | There is no word to mark. | -1.45 (6, 6, 1) | emptyToneWhat | Tone Lens empty, what happened |
| None | Tone Lens needs a target-language word. | 2.31 (7, 9, 1) | emptyToneWhy | Tone Lens empty, why |
| None | Long-press a word. | -2.23 (4, 4, 1) | emptyToneDo | Tone Lens empty, what to do |
| None | The tone shapes did not open. | 0.52 (6, 7, 1) | errorToneWhat | Tone Lens error, what happened |
| None | This word has no saved tone on the phone. | -0.28 (9, 9, 1) | errorToneWhy | Tone Lens error, why |
| None | The tone for this word is not saved on the phone. | 0.50 (11, 11, 1) | offlineToneWhy | Tone Lens offline, why |
| None | No word is open. | 0.72 (4, 5, 1) | emptyCardWhat | Word Card empty, what happened |
| None | A long press has not chosen a word. | 0.80 (8, 9, 1) | emptyCardWhy | Word Card empty, why |
| None | Long-press a target-language word. | 2.48 (6, 8, 1) | emptyCardDo | Word Card empty, what to do |
| None | The card did not load. | -1.84 (5, 5, 1) | errorCardWhat | Word Card error, what happened |
| None | The meaning did not come back. | 0.52 (6, 7, 1) | errorCardWhy | Word Card error, why |
| None | This word is not saved on the phone. | -0.67 (8, 8, 1) | offlineCardWhy | Word Card offline, why |
| None | The camera sees no object. | 5.24 (5, 8, 1) | emptyLensWhat | Lens empty, what happened |
| None | Nothing is close enough to name. | 2.48 (6, 8, 1) | emptyLensWhy | Lens empty, why |
| None | Point at one thing, or use Import Media. | 3.76 (8, 11, 1) | emptyLensDo | Lens empty, what to do |
| None | No word came back. | -2.23 (4, 4, 1) | errorLensWhat | Lens error, what happened. Also the why on First word empty |
| None | The picture was too dark to read. | 0.63 (7, 8, 1) | errorLensWhy | Lens error, why |
| None | Add light, then try again. | 0.52 (5, 6, 1) | errorLensDo | Lens error, what to do |
| None | This object is not in the offline pack. | 2.28 (8, 10, 1) | offlineLensWhy | Lens offline, why |
| None | Connect, then point again. | 3.67 (4, 6, 1) | offlineLensDo | Lens offline, what to do |

Profile, Wardrobe, First word, and Level up:

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | This profile is empty. | 3.67 (4, 6, 1) | emptyProfileWhat | Profile empty, what happened |
| None | You have not saved a lesson yet. | 0.63 (7, 8, 1) | emptyProfileWhy | Profile empty, why |
| None | Say the first word. | -2.23 (4, 4, 1) | emptyProfileDo | Profile empty, what to do |
| None | The profile did not open. | 2.88 (5, 7, 1) | errorProfileWhat | Profile error, what happened |
| None | The profile did not come back. | 0.52 (6, 7, 1) | errorProfileWhy | Profile error, why |
| None | This profile is not saved on the phone. | 0.80 (8, 9, 1) | offlineProfileWhy | Profile offline, why |
| None | No look is chosen. | 0.72 (4, 5, 1) | emptyWardrobeWhat | Wardrobe empty, what happened |
| None | You have not picked one. | -1.84 (5, 5, 1) | emptyWardrobeWhy | Wardrobe empty, why |
| None | Pick a look, or skip for now. | -1.06 (7, 7, 1) | emptyWardrobeDo | Wardrobe empty, what to do |
| Avatar can wait until after lesson 2. | You can make an avatar after lesson two. | 5.23 (8, 12, 1) | profileAvatarLater | Profile, under Skip for now |
| None | There is no greeting to say. | 0.52 (6, 7, 1) | emptyFirstWhat | First word empty, what happened |
| None | The greeting did not load. | 0.52 (5, 6, 1) | errorFirstWhat | First word error, what happened |
| None | The word did not come back. | -1.45 (6, 6, 1) | errorFirstWhy | First word error, why |
| None | This greeting is not saved on the phone. | 0.80 (8, 9, 1) | offlineFirstWhy | First word offline, why |
| None | There is no next unit. | 0.52 (5, 6, 1) | emptyLevelWhat | Level up empty, what happened |
| None | The path did not name one. | -1.45 (6, 6, 1) | emptyLevelWhy | Level up empty, why |
| None | Go back to Today. | 0.72 (4, 5, 1) | emptyLevelDo | Level up empty, what to do |
| None | The celebration did not start. | 5.24 (5, 8, 1) | errorLevelWhat | Level up error, what happened |
| None | The next unit did not come back. | 0.63 (7, 8, 1) | errorLevelWhy | Level up error, why |
| None | The next unit is not saved on the phone. | 1.03 (9, 10, 1) | offlineLevelWhy | Level up offline, why |

## Lines beside the buttons

These are the short lines the frames already use for a wrong try, a first word, a celebration, a locked lesson, and an honest note. They ship. They are not a new boast.

| Old string | Shipped string | Grade | ARB key | Where it is used |
| --- | --- | --- | --- | --- |
| None | The check is unsure. | 0.72 (4, 5, 1) | toneUnsure | Tone Lens, when the check cannot say |
| None | Say the word again in a quiet place. | 2.28 (8, 10, 1) | toneTryQuiet | Tone Lens, the next step after an unsure check |
| None | This is sample data. | 3.67 (4, 6, 1) | toneSample | Tone Lens sample block. It is not a score |
| None | You speak now. | -2.62 (3, 3, 1) | firstWordTitle | First spoken word |
| None | It was mid. The high tone sits up. | -2.23 (8, 8, 2) | firstWordFeedback | First spoken word, about one syllable |
| None | We heard this syllable. | 3.67 (4, 6, 1) | firstWordHeard | First spoken word, above the syllable |
| None | Speak within 60 seconds. | 6.62 (4, 7, 1) | firstWordTarget | First spoken word. It is a target, not a timer |
| None | This is a target, not a timer. | 2.31 (7, 9, 1) | firstWordNotTimer | Line under the 60 second note |
| None | No account yet. | 1.31 (3, 4, 1) | firstWordNoAccount | First spoken word |
| None | Polie greets you in the language. | 2.48 (6, 8, 1) | firstWordGreet | First spoken word |
| None | Good morning. | 2.89 (2, 3, 1) | glossGoodMorning | Meaning under the morning greeting |
| Lesson complete. | The lesson is complete. | 3.67 (4, 6, 1) | lineLessonComplete | Lesson complete |
| None | You said the greeting. | 0.72 (4, 5, 1) | lineYouSaidGreeting | Lesson complete |
| Lesson unit complete. | The unit is complete. | 3.67 (4, 6, 1) | lineUnitComplete | Level up |
| Unit 2. Family. | Next is the Family unit. | 5.24 (5, 8, 1) | lineNextUnit | Level up |
| None | Shape shows the tone. Colour is optional. | 2.63 (7, 10, 2) | toneShapeNote | Tone Lens. Colour is not the only cue |
| None | The photo is checked, then deleted. | 4.45 (6, 9, 1) | lensPhotoDeleted | Lens. The photo is not kept |
| None | You say this in the morning. | 0.52 (6, 7, 1) | wordCardExample | Word Card example line |

## Plain lines that still do not ship

These pass the grade bar. They still do not ship.

| Line | Grade | Why it stays out |
| --- | --- | --- |
| How do you learn best? | -1.84 (5, 5, 1) | It is the live Rhythm Master question. A learning-style question sets a false hope. The speaking question replaces it. |
| How much game feel? | -2.23 (4, 4, 1) | It is the live Griot follow-up. One choice under it names a points total. No points total ships. |
| Save your progress and your streak. | 0.52 (6, 7, 1) | ELEVATION.md names this save line. This deck asks "Save your progress?" and does not push a streak. |
| You did it! | -2.62 (3, 3, 1) | It is the live first-win boast. The celebration line is "You said the greeting." |
| A soft nudge when it matters | 0.52 (6, 7, 1) | It is vague. The shipped question uses the time the learner practised. |

## Where the old lines live

- ELEVATION.md section 5.3: "Who are you, and why do you seek knowledge?"
- ELEVATION.md section 5.2: the save line with a streak, the nudge example, and the family chip.
- lib/screens/onboarding/kijiji_onboarding_screen.dart: the village welcomes, "Tell me: who are you?", "Why are you learning?", the Weaver, Rhythm Master, Timekeeper, and Griot lines, "Choose your path.", the naming riddle, and "Begin Journey".
- lib/avatars/onboarding/onboarding_avatar_widget.dart: "Welcome, young one, to our village of languages.", "What brings you to learn this beautiful language?", and "How does your spirit best receive knowledge?"
- lib/screens/onboarding/unified/: "What do you want to learn?", "What year were you born?", "How much time a day feels right?", "How do you learn best?", "How should Polie sound?", "How much game feel?", "Pick a name", the drum hint, "Save your progress?", "A soft nudge when it matters", "You did it!", and "Celebrate progress, not perfection."
- lib/screens/onboarding/enhanced_onboarding_flow_screen.dart: "What language do you speak?"
- The approved frames under docs/build/design/screens/: the error, empty, and offline lines, and the button labels this deck keeps or lengthens.
