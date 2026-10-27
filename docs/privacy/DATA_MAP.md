# LingAfriq data map (P10-920)

Machine-readable retention schedule: [`RETENTION.yaml`](./RETENTION.yaml).
Counsel review for NDPC/DPIA remains **EXT-18** (not a substitute for legal sign-off).

- **Mongo collections mapped:** 137 (discovered models: 137)
- **High-risk (voice / minors):** 42

## High-risk collections

| Collection | Model | Default deletion rule | Retention |
|---|---|---|---|
| `call_logs` | CallLog | apply_collection_retention_job | 0 days |
| `feedUserLists` | FeedUserList | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `learnerStates` | LearnerState | apply_collection_retention_job | keep_until=account_deletion |
| `learnerprogress` | LearnerProgress | apply_collection_retention_job | keep_until=account_deletion |
| `lexicon_audio_attachments` | LexiconAudioAttachment | delete_raw_audio_after_scoring_unless_training_opt_in | 0 days |
| `mentor_sessions` | MentorSession | apply_collection_retention_job | 0 days |
| `micro_mentor_profiles` | MicroMentorProfile | apply_collection_retention_job | 0 days |
| `micro_mentor_safety_reports` | MicroMentorSafetyReport | apply_collection_retention_job | 0 days |
| `micro_mentor_sessions` | MicroMentorSession | apply_collection_retention_job | 0 days |
| `native_pronunciation_ratings` | NativePronunciationRating | apply_collection_retention_job | 0 days |
| `passkeyChallenges` | PasskeyChallenge | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `passkeyCredentials` | PasskeyCredential | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `personalitychatsessions` | PersonalityChatSession | apply_collection_retention_job | 0 days |
| `point_and_say_events` | PointAndSayEvent | apply_collection_retention_job | 0 days |
| `polie_requests` | PolieRequest | apply_collection_retention_job | 0 days |
| `polie_usage` | PolieUsage | apply_collection_retention_job | 0 days |
| `proficiency_credentials` | ProficiencyCredential | apply_collection_retention_job | 0 days |
| `proficiency_sessions` | ProficiencySession | apply_collection_retention_job | 0 days |
| `snapMessages` | SnapMessage | apply_collection_retention_job | 0 days |
| `snapScreenshotEvents` | SnapScreenshotEvent | apply_collection_retention_job | 0 days |
| `snapStickerPacks` | SnapStickerPack | apply_collection_retention_job | 0 days |
| `snapStoryViews` | SnapStoryView | apply_collection_retention_job | 0 days |
| `snapStreaks` | SnapStreak | apply_collection_retention_job | 0 days |
| `snapstories` | SnapStory | apply_collection_retention_job | 0 days |
| `socialAudioFollowings` | SocialAudioFollowing | delete_raw_audio_after_scoring_unless_training_opt_in | 0 days |
| `socialAudioLearnings` | SocialAudioLearning | delete_raw_audio_after_scoring_unless_training_opt_in | 0 days |
| `socialAudioParticipants` | SocialAudioParticipant | delete_raw_audio_after_scoring_unless_training_opt_in | 0 days |
| `socialAudioPronunciations` | SocialAudioPronunciation | delete_raw_audio_after_scoring_unless_training_opt_in | 0 days |
| `socialAudioRooms` | SocialAudioRoom | delete_raw_audio_after_scoring_unless_training_opt_in | 0 days |
| `socialAudioWordLearneds` | SocialAudioWordLearned | delete_raw_audio_after_scoring_unless_training_opt_in | 0 days |
| `speak_mission_attempts` | SpeakMissionAttempt | apply_collection_retention_job | 0 days |
| `speaker_queue_entries` | SpeakerQueueEntry | apply_collection_retention_job | 0 days |
| `synthetic_voice_preferences` | SyntheticVoicePreference | delete_raw_audio_after_scoring_unless_training_opt_in | 0 days |
| `userConnections` | UserConnection | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `userContents` | UserContent | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `userMilestones` | UserMilestone | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `user_items` | UserItem | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `user_journey_progress` | UserJourneyProgress | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `user_preferences` | UserPreferences | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `userhearts` | UserHearts | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `users` | User | erase_on_account_deletion_and_guardian_request | keep_until=account_deletion |
| `voiceContributions` | VoiceContribution | delete_raw_audio_after_scoring_unless_training_opt_in | 0 days |

## CI

Run `python3 scripts/privacy/data_map_check.py --gate` in CI; fails when a new
`*.model.ts` is added without a matching `RETENTION.yaml` row.
