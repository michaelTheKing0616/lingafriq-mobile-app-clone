# LINGUA REALMS — CURSOR AI MASTER PROMPT
## Complete End-to-End Build Guide · No Placeholders · No TODOs · No Stubs

---

> **HOW TO USE THIS DOCUMENT**
> Feed each numbered PROMPT block into Cursor AI sequentially. Each block is self-contained but builds on the previous. Every prompt is written to produce complete, production-ready, runnable code. After each prompt completes, verify the output compiles/runs before proceeding to the next. Total estimated generation: ~40,000 lines of code across Flutter, NestJS, Python, and DevOps.

---

# ═══════════════════════════════════════════════════════════
# PHASE 0 — PROJECT SCAFFOLDING & MONOREPO SETUP
# ═══════════════════════════════════════════════════════════

## PROMPT 0.1 — MONOREPO INITIALIZATION

```
You are a senior full-stack architect. Create a complete production-grade monorepo for "Lingua Realms" — an AAA African language learning game platform.

Create the following exact directory structure with ALL configuration files fully written out — no placeholders, no "add your config here" comments, everything must be a working file:

lingua-realms/
├── apps/
│   ├── mobile/                    # Flutter app
│   ├── backend/                   # NestJS TypeScript API
│   ├── pronunciation-ai/          # Python FastAPI microservice
│   └── admin-cms/                 # Flutter Web admin panel
├── packages/
│   ├── shared-types/              # Shared TypeScript interfaces
│   └── game-content/              # JSON game content files
├── infrastructure/
│   ├── docker/
│   ├── k8s/
│   └── terraform/
├── scripts/
│   ├── seed-database.ts
│   └── generate-content.ts
├── .github/
│   └── workflows/
├── docker-compose.yml
├── docker-compose.prod.yml
└── README.md

Generate:
1. Root package.json with workspaces configured for apps/backend, apps/admin-cms, packages/shared-types
2. Root .gitignore covering Flutter, Node.js, Python, .env files, build artifacts
3. docker-compose.yml with services: mongo (mongo:7, with replica set init), redis (redis:7-alpine with persistence), backend (node:20-alpine), pronunciation-ai (python:3.11-slim), admin-cms (nginx:alpine). All services have health checks, restart policies, and named volumes. MongoDB runs as a replica set (required for change streams). Include mongo-init.js that initializes the replica set.
4. docker-compose.prod.yml extending the base with production overrides: resource limits, no volume mounts, environment variables from secrets
5. .github/workflows/ci.yml: on push to main and PRs — runs Flutter analyze + tests, NestJS lint + test, Python pytest, builds Docker images, pushes to ECR if on main
6. packages/shared-types/src/index.ts: Export ALL TypeScript interfaces for User, NPCMemory, Vocabulary, DialogueNode, GameSession, Clan, LivingArchive, PvPMatch, PronunciationScore, SkillTree, Achievement, Festival, MythologyEntity, Region, Proverb. Every interface must be complete with all fields, correct types, JSDoc comments, and no 'any' types.
7. README.md with setup instructions, environment variables list, and development workflow

Every file must be complete. No "// TODO" or "// add your X here" comments anywhere.
```

---

## PROMPT 0.2 — ENVIRONMENT & SECRETS ARCHITECTURE

```
You are a senior DevOps engineer building the secrets and environment architecture for Lingua Realms.

Generate the following complete files:

1. apps/backend/.env.example — Every single environment variable the NestJS app needs:
   - MONGODB_URI (replica set connection string)
   - MONGODB_DB_NAME
   - REDIS_HOST, REDIS_PORT, REDIS_PASSWORD
   - JWT_ACCESS_SECRET, JWT_REFRESH_SECRET
   - JWT_ACCESS_EXPIRY=15m, JWT_REFRESH_EXPIRY=30d
   - AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
   - S3_BUCKET_RECORDINGS, S3_BUCKET_AUDIO_ASSETS
   - CLOUDFRONT_DOMAIN
   - PRONUNCIATION_AI_URL (internal docker URL)
   - HUGGINGFACE_API_KEY
   - STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET
   - SENDGRID_API_KEY
   - SENTRY_DSN
   - PORT=3000
   - NODE_ENV=development
   - CORS_ORIGINS (comma-separated)
   - RATE_LIMIT_TTL=60, RATE_LIMIT_MAX=100
   - BCRYPT_ROUNDS=12
   - CLAN_MAX_MEMBERS=50
   - ELO_DEFAULT_RATING=1200, ELO_K_FACTOR=32

2. apps/pronunciation-ai/.env.example:
   - MODEL_PATH
   - AUDIO_SAMPLE_RATE=16000
   - MFCC_N_MELS=128
   - SUPPORTED_LANGUAGES (comma-separated)
   - MAX_AUDIO_DURATION_SECONDS=10
   - REDIS_URL
   - SENTRY_DSN
   - PORT=8000
   - LOG_LEVEL=INFO

3. apps/mobile/lib/core/config/app_config.dart — Complete Dart config class with:
   - static const fields for all API endpoints
   - Environment enum (dev/staging/prod)
   - Factory constructor that reads from compile-time --dart-define flags
   - WebSocket URL, REST base URL, CDN base URL, pronunciation AI URL
   - Feature flags: enablePvP, enableLivingArchive, enablePronunciationAI, enableOfflineMode
   - All constants for game mechanics: maxClanMembers=50, defaultEloRating=1200, streakShieldDuration=24 (hours), maxDailyXP=500

4. infrastructure/terraform/main.tf — Complete Terraform configuration for:
   - AWS provider
   - VPC with public/private subnets across 3 AZs
   - ECS Fargate cluster with task definitions for backend and pronunciation-ai
   - MongoDB Atlas cluster via mongodbatlas provider (M10 minimum, 3-node replica set, Africa region nodes in Lagos and Nairobi)
   - ElastiCache Redis cluster (cache.t3.medium)
   - S3 buckets for audio recordings and assets
   - CloudFront distribution pointing to S3
   - ECR repositories for each service
   - Application Load Balancer with SSL termination
   - Route53 hosted zone
   - All IAM roles and policies

Every field must have a real value or reference a variable — no "YOUR_VALUE_HERE" anywhere.
```

---

# ═══════════════════════════════════════════════════════════
# PHASE 1 — NESTJS BACKEND: COMPLETE API
# ═══════════════════════════════════════════════════════════

## PROMPT 1.1 — NESTJS PROJECT FOUNDATION

```
You are a senior NestJS architect. Build the complete foundation for the Lingua Realms backend API.

Stack: NestJS 10, TypeScript 5, Mongoose 7, Passport.js, Socket.IO 4, Bull 4, Redis (ioredis), class-validator, class-transformer, Swagger.

Generate the complete apps/backend/ directory:

1. apps/backend/package.json — All exact dependencies with pinned versions:
   @nestjs/core@10, @nestjs/common@10, @nestjs/platform-express@10,
   @nestjs/mongoose@10, mongoose@7, @nestjs/passport@10, passport@0.6,
   passport-jwt@4, passport-local@1, @nestjs/jwt@10,
   @nestjs/websockets@10, @nestjs/platform-socket.io@10, socket.io@4,
   @nestjs/bull@10, bull@4, ioredis@5,
   @nestjs/config@3, @nestjs/swagger@7,
   @nestjs/throttler@5, class-validator@0.14, class-transformer@0.5,
   bcrypt@5, @types/bcrypt@5, uuid@9, dayjs@1,
   aws-sdk@2, @aws-sdk/client-s3@3, @aws-sdk/s3-request-presigner@3,
   @sentry/node@7, winston@3, nest-winston@1,
   stripe@14, @sendgrid/mail@8,
   axios@1 (for calling pronunciation-ai)
   All @types/* dev dependencies. ts-jest for testing.

2. apps/backend/src/main.ts — Complete bootstrap:
   - NestFactory.create with cors configured from env
   - ValidationPipe globally with whitelist:true, forbidNonWhitelisted:true, transform:true
   - SwaggerModule setup with full API documentation config
   - Helmet, compression middleware
   - IoRedisAdapter for Socket.IO (horizontal scaling)
   - Sentry initialization
   - app.listen on PORT from env
   - Graceful shutdown hooks

3. apps/backend/src/app.module.ts — Root module importing:
   - ConfigModule.forRoot (global: true, validation schema using Joi)
   - MongooseModule.forRootAsync using ConfigService (replica set with readPreference)
   - BullModule.forRootAsync using Redis config
   - ThrottlerModule.forRoot
   - All feature modules: AuthModule, UsersModule, GameEngineModule, DialogueModule, PvPModule, LeaderboardModule, PronunciationModule, AnalyticsModule, AdminModule, ClansModule, LivingArchiveModule, FestivalsModule, AchievementsModule

4. apps/backend/src/common/ — Complete shared utilities:
   - decorators/current-user.decorator.ts: @CurrentUser() param decorator
   - decorators/public.decorator.ts: @Public() route decorator
   - decorators/roles.decorator.ts: @Roles(...roles) decorator
   - guards/jwt-auth.guard.ts: JwtAuthGuard extending AuthGuard('jwt'), skips @Public() routes
   - guards/roles.guard.ts: RolesGuard using Reflector
   - guards/ws-jwt.guard.ts: WebSocket JWT guard extracting token from handshake
   - interceptors/logging.interceptor.ts: Logs every request with duration, userId, route
   - interceptors/transform.interceptor.ts: Wraps all responses in { data, statusCode, timestamp }
   - filters/all-exceptions.filter.ts: Global exception filter, reports to Sentry, returns structured errors
   - pipes/mongo-id.pipe.ts: Validates MongoDB ObjectId format
   - utils/elo.utils.ts: Complete ELO calculation functions — calculateNewRatings(winnerRating, loserRating, kFactor): returns {winnerNew, loserNew}. calculateExpectedScore(ratingA, ratingB): returns probability. No placeholders.
   - utils/spaced-repetition.utils.ts: Full SM-2 algorithm implementation — calculateNextReview(quality: 0-5, repetitions, easiness, interval): returns {nextInterval, newEasiness, newRepetitions, nextReviewDate}. Full implementation, no stubs.
   - utils/tone.utils.ts: Tone pattern validation for Yoruba (H/L/M), Zulu (H/L), Hausa (H/L/F), Amharic (no tone), Swahili (no tone), Igbo (H/L). validateTonePattern(word, language, pattern): returns boolean.

5. apps/backend/src/config/database.config.ts — Mongoose connection options with:
   - autoIndex: false in production
   - maxPoolSize: 10
   - serverSelectionTimeoutMS: 5000
   - socketTimeoutMS: 45000
   - bufferCommands: false
   - Retry logic with exponential backoff

All files complete, all functions fully implemented.
```

---

## PROMPT 1.2 — MONGOOSE SCHEMAS (COMPLETE)

```
You are a senior MongoDB/Mongoose architect. Build all complete Mongoose schemas for Lingua Realms.

Create apps/backend/src/schemas/ with these files — every schema fully implemented with all fields, validators, indexes, virtuals, and methods:

1. user.schema.ts
   Fields: _id(ObjectId), email(String, unique, lowercase, trim, required), username(String, unique, required, 3-20 chars), passwordHash(String, select:false), displayName(String), avatarUrl(String), primaryLanguage(String), learningLanguages([{language:String, startedAt:Date, lastActive:Date}]), diasporaOrigin(String), countryCode(String), timezone(String), level(Number, default:1), totalXP(Number, default:0), weeklyXP(Number, default:0), streak(Number, default:0), longestStreak(Number, default:0), lastActivityDate(Date), streakShieldActive(Boolean, default:false), streakShieldExpiry(Date), eloRatings(Map<String,Number> — key=language, value=rating, default 1200), clanId(ObjectId, ref:'Clan', null), griotRank(String, enum:['apprentice','journeyman','griot','master_griot'], default:'apprentice'), unlockedRegions([String]), unlockedCosmetics([{itemId:String, equippedSlot:String}]), equippedCosmetics({avatar:String, staff:String, banner:String}), skillTreeProgress(Map<String,Number>), weakPhonemes([{language:String, phoneme:String, errorRate:Number, lastDrillDate:Date}]), pronunciationProfile({averageToneScore:Number, averageAccuracyScore:Number, sessionsCount:Number}), offlineDownloads([String]), pushToken(String), notificationPreferences({dailyReminder:Boolean, clanActivity:Boolean, pvpChallenges:Boolean, festivalAlerts:Boolean}), subscriptionTier(String, enum:['free','premium','griot_pro'], default:'free'), subscriptionExpiry(Date), stripeCustomerId(String), totalCosmetics(Number, default:0), isVerified(Boolean, default:false), isBanned(Boolean, default:false), banReason(String), refreshTokenHash(String, select:false), createdAt(Date), updatedAt(Date)
   Indexes: email(unique), username(unique), [language, totalXP](compound for leaderboards), clanId, griotRank
   Virtual: currentEloForLanguage(language)
   Pre-save hook: hash password if modified using bcrypt rounds 12
   Method: comparePassword(candidate): Promise<boolean>
   Method: addXP(amount, language): void — also updates weeklyXP and checks level thresholds (level = Math.floor(totalXP/1000)+1, max 100)

2. npc-memory.schema.ts
   Fields: _id, userId(ObjectId, ref:'User', required), npcId(String, required), language(String, required), respectMeter(Number, min:0, max:100, default:50), familiarityMeter(Number, min:0, max:100, default:0), emotionalState(String, enum:['neutral','pleased','annoyed','angry','delighted','sad','suspicious','trusting'], default:'neutral'), humorAlignment(Number, min:-100, max:100, default:0), pastMistakes([{mistakeType:String, count:Number, lastOccurred:Date}]), unlockedTopics([String]), allianceStatus(String, enum:['stranger','acquaintance','ally','elder_friend','enemy','neutral'], default:'stranger'), giftHistory([{itemId:String, givenAt:Date, impact:Number}]), correctGreetingsCount(Number, default:0), incorrectGreetingsCount(Number, default:0), lastInteraction(Date), totalInteractions(Number, default:0), secretsUnlocked([String])
   Compound index: {userId, npcId} unique
   Method: updateFromDialogueScore(grammarScore, toneScore, culturalScore, emotionalScore): void — fully implemented state machine that modifies all meters based on scores

3. vocabulary.schema.ts
   Fields: _id, word(String, required), language(String, required, indexed), dialect(String, default:'standard'), script(String, enum:['latin','geez','adlam','tifinagh','nsibidi','osmanya','ajami','latin_diacritics'], default:'latin'), tonePattern([String] — each element is 'H'|'L'|'M'|'F'|'R'|'none'), phonemeBreakdown([{phoneme:String, ipa:String, isClick:Boolean, clickType:String}]), ipa(String), audioUrl(String), alternateAudioUrls([{dialect:String, url:String}]), translation({en:String, fr:String, pt:String, ar:String}), partOfSpeech(String, enum:['noun','verb','adjective','adverb','pronoun','conjunction','interjection','particle','ideophone']), nounClass(Number, min:1, max:23), verbTense(String), difficulty(Number, min:1, max:10), culturalContext({category:String, register:String, sacredness:String, ageAppropriate:String}), isProverb(Boolean, default:false), proverbMeaning(String), mythologyRef(String), festivalRef(String), region(String), tags([String]), ceferLevel(String, enum:['A0','A1','A2','B1','B2','C1','C2']), relatedWords([ObjectId]), antonyms([ObjectId]), timesAnsweredCorrect(Number, default:0), timesAnsweredIncorrect(Number, default:0), lastUpdated(Date), contributorId(ObjectId, ref:'User'), isCanonical(Boolean, default:true), communityVotes(Number, default:0)
   Text index on: word, translation.en, tags
   Compound index: {language, ceferLevel, difficulty}

4. dialogue-node.schema.ts
   Fields: _id, nodeId(String, unique, required), npcId(String, required), language(String, required), regionId(String), questId(String), nodeText({[languageCode:string]: String} — the NPC's actual words), nodeTextTone([String] — tone markers), responseOptions([{optionId:String, text:String, toneRequired:[String], grammarPattern:String, culturalRequirement:{register:String, ageRespect:Boolean, genderConsideration:String}, nextNodeId:String, successCondition:{minGrammarScore:Number, minToneScore:Number, minCulturalScore:Number}, onSuccess:{respectDelta:Number, familiarityDelta:Number, xpReward:Number, unlocks:[String], nextNodeId:String}, onFailure:{respectDelta:Number, nextNodeId:String, mistakeType:String}}]), grammarFocus(String), difficultyLevel(Number, min:1, max:10), npcEmotionalStateRequired([String]), isSeasonalOnly(Boolean, default:false), seasonalEventId(String), mythologyUnlockId(String), proverbRequired(String), isQuestEntry(Boolean, default:false), isQuestComplete(Boolean, default:false), questReward({xp:Number, cosmetic:String, region:String}), audioNodeUrl(String), createdBy(ObjectId, ref:'User'), version(Number, default:1)

5. game-session.schema.ts
   Fields: _id, userId(ObjectId, ref:'User', required), language(String, required), gameMode(String, enum:['rpg','pvp','builder','arcade','mythology','clans','archive'], required), startedAt(Date, default:Date.now), endedAt(Date), durationSeconds(Number), score(Number, default:0), xpEarned(Number, default:0), mistakes([{word:String, errorType:String, userInput:String, correctAnswer:String, toneError:Boolean, grammarError:Boolean, culturalError:Boolean, timestamp:Date}]), vocabularyPracticed([ObjectId ref Vocabulary]), pronunciationScores([{wordId:ObjectId, accuracyScore:Number, toneScore:Number, feedback:String}]), dialogueNodesCompleted([String]), streakMaintained(Boolean), pvpOpponentId(ObjectId), pvpResult(String, enum:['win','loss','draw']), pvpEloChange(Number), regionId(String), questsCompleted([String]), deviceInfo({platform:String, osVersion:String, appVersion:String}), networkType(String), offlineSession(Boolean, default:false), syncedAt(Date)
   Index: {userId, gameMode, startedAt}
   Index: {userId, language, startedAt}

6. pvp-match.schema.ts
   Fields: _id, matchId(String, unique, required, default: uuid), playerOneId(ObjectId, ref:'User', required), playerTwoId(ObjectId, ref:'User', required), language(String, required), mode(String, enum:['blitz','sentence_strategy','tone_duel'], required), status(String, enum:['waiting','active','completed','abandoned'], default:'waiting'), rounds([{roundNumber:Number, wordId:ObjectId ref Vocabulary, playerOneSubmission:{text:String, audioUrl:String, grammarScore:Number, toneScore:Number, totalScore:Number, submittedAt:Date, latencyMs:Number}, playerTwoSubmission:{text:String, audioUrl:String, grammarScore:Number, toneScore:Number, totalScore:Number, submittedAt:Date, latencyMs:Number}, roundWinner:String}]), playerOneScore(Number, default:0), playerTwoScore(Number, default:0), winnerId(ObjectId), playerOneEloBefore(Number), playerTwoEloBefore(Number), playerOneEloAfter(Number), playerTwoEloAfter(Number), startedAt(Date), endedAt(Date), abandonedBy(ObjectId), totalRounds(Number, default:5), spectatorCount(Number, default:0), replayAvailable(Boolean, default:false)

7. clan.schema.ts
   Fields: _id, name(String, unique, required, 3-30 chars), displayName(String), language(String, required), chieftainId(ObjectId, ref:'User', required), elderIds([ObjectId] ref User), memberIds([ObjectId] ref User, max 50), inviteCode(String, unique, 8 chars), description(String, max 500 chars), totemId(String — cosmetic totem), bannerColor(String), totalXP(Number, default:0), weeklyXP(Number, default:0), seasonRank(Number), allTimeRank(Number), achievements([{achievementId:String, unlockedAt:Date}]), currentChallengeId(String), weeklyChallengProgress({vocabularyLearned:Number, pronunciationSessions:Number, pvpWins:Number, streaksDays:Number}), createdAt(Date), isPublic(Boolean, default:true), requiredLevel(Number, default:1), memberCount(Number, virtual, from memberIds.length), lastActive(Date)
   Index: {language, weeklyXP} for leaderboard
   Pre-save: ensure memberIds.length <= 50

8. living-archive.schema.ts
   Fields: _id, recordingId(String, unique, required, default:uuid), language(String, required), dialect(String), speakerId(ObjectId, ref:'User', required), speakerRegion(String), speakerAge(Number), contentType(String, enum:['single_word','phrase','proverb','story','song','ceremony','greeting'], required), transcript(String, required), translation(String, required), audioUrl(String, required), audioDurationMs(Number), audioFileSize(Number), audioFormat(String, enum:['mp3','wav','ogg','m4a']), aiQualityScore(Number, min:0, max:100), aiToneAccuracyScore(Number), aiNoiseScore(Number, min:0, max:100), communityUpvotes(Number, default:0), communityDownvotes(Number, default:0), reviewCount(Number, default:0), canonStatus(Boolean, default:false), canonApprovedBy(ObjectId, ref:'User'), canonApprovedAt(Date), unescoExported(Boolean, default:false), unescoExportedAt(Date), linkedVocabularyId(ObjectId, ref:'Vocabulary'), culturalNotes(String), isEndangeredLanguage(Boolean, default:false), endangeredLanguageCode(String), status(String, enum:['pending_ai_review','community_review','approved','rejected','archived'], default:'pending_ai_review'), rejectionReason(String), createdAt(Date), updatedAt(Date)
   Index: {language, canonStatus}
   Index: {status, aiQualityScore}

9. achievement.schema.ts
   Fields: _id, achievementId(String, unique), title({[lang:string]:String}), description({[lang:string]:String}), iconUrl(String), category(String, enum:['pronunciation','vocabulary','grammar','cultural','pvp','clan','streak','archive','mythology']), triggerType(String, enum:['xp_threshold','streak_days','pvp_wins','vocabulary_count','proverbs_used','clan_rank','archive_contributions','languages_learned']), triggerValue(Number), xpReward(Number), cosmeticReward(String), isSecret(Boolean, default:false), isSeasonal(Boolean, default:false), seasonId(String), totalUnlocked(Number, default:0)

10. festival.schema.ts
    Fields: _id, festivalId(String, unique), name({[lang:string]:String}), language(String), region(String), description({[lang:string]:String}), startDate(Date), endDate(Date), isRecurring(Boolean, default:true), recurrenceType(String, enum:['annual','lunar','custom']), vocabularyPack([ObjectId ref Vocabulary]), specialDialogueNodes([String ref DialogueNode.nodeId]), requiredChants([{chantText:String, tonePattern:[String], audioUrl:String}]), xpBoostMultiplier(Number, default:1.5), exclusiveCosmetics([String]), questChain([String]), culturalContext(String), historicalBackground(String), isActive(Boolean, default:false)

All schemas must use SchemaFactory.createForClass() pattern, export both the class and the Document type, and be importable by name.
```

---

## PROMPT 1.3 — AUTH MODULE (COMPLETE)

```
You are a senior NestJS security engineer. Build the complete authentication module for Lingua Realms.

Generate apps/backend/src/modules/auth/ with:

1. auth.module.ts — Imports UsersModule, PassportModule, JwtModule (registered async with ConfigService for secret and expiry), exports AuthService and JwtStrategy

2. auth.service.ts — Complete AuthService with:
   - register(dto: RegisterDto): Promise<{user, accessToken, refreshToken}>
     Full implementation: check email uniqueness, hash password with bcrypt, create user document, generate both tokens, store hashed refresh token on user, send welcome email via SendGrid (fully implemented sendWelcomeEmail call), return tokens
   - login(dto: LoginDto): Promise<{user, accessToken, refreshToken}>
     Find user by email with passwordHash selected, compare password, update lastActivityDate, generate tokens, return
   - refreshTokens(userId: string, refreshToken: string): Promise<{accessToken, refreshToken}>
     Find user with refreshTokenHash selected, verify refresh token matches hash, generate new pair, update stored hash, return
   - logout(userId: string): Promise<void>
     Clear refreshTokenHash on user document
   - validateUser(email, password): Promise<User | null>
     Used by LocalStrategy
   - generateTokens(userId, email, role): {accessToken, refreshToken}
     Uses JwtService.sign with correct payloads and expiries
   - Private hashToken(token): string — bcrypt hash
   - Private verifyRefreshToken(token, hash): Promise<boolean>

3. strategies/jwt.strategy.ts — Complete JwtStrategy extending PassportStrategy(Strategy):
   - Constructor extracts secret from ConfigService, jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken()
   - validate(payload): returns {userId, email, role, subscriptionTier}

4. strategies/local.strategy.ts — LocalStrategy calling authService.validateUser, throws UnauthorizedException if null

5. dto/register.dto.ts — RegisterDto:
   email: @IsEmail(), @Transform lowercase, @MaxLength(255)
   username: @IsString(), @Matches(/^[a-zA-Z0-9_]{3,20}$/), custom message "Username must be 3-20 alphanumeric characters or underscores"
   password: @IsString(), @MinLength(8), @MaxLength(128), @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, message "Password must contain uppercase, lowercase, and number")
   displayName: @IsString(), @MinLength(2), @MaxLength(50)
   primaryLanguage: @IsString(), @IsIn(['yoruba','swahili','zulu','hausa','amharic','igbo','xhosa','twi','wolof','somali','tigrinya','fula','lingala','kinyarwanda','sesotho','shona','luganda','kikuyu','ewe','oromo'])
   diasporaOrigin: @IsOptional(), @IsString()
   countryCode: @IsISO31661Alpha2()
   timezone: @IsTimeZone() — use class-validator's IsTimeZone

6. dto/login.dto.ts — email, password with validation

7. auth.controller.ts — Complete controller with:
   POST /auth/register → register
   POST /auth/login → login
   POST /auth/refresh → refreshTokens (takes {refreshToken} in body, @Public())
   POST /auth/logout → logout (protected)
   GET /auth/me → returns current user (protected, uses @CurrentUser())
   All routes have @ApiOperation, @ApiResponse decorators for Swagger

8. auth.guard.ts — JwtAuthGuard that checks IS_PUBLIC_KEY metadata

Generate every function body completely — no throwing NotImplementedException, no "// implement this" comments.
```

---

## PROMPT 1.4 — USERS MODULE (COMPLETE)

```
You are a senior NestJS engineer. Build the complete Users module for Lingua Realms.

Generate apps/backend/src/modules/users/ with:

1. users.service.ts — Complete UsersService:
   - findById(id: string): Promise<User>
   - findByEmail(email: string): Promise<User>
   - findByUsername(username: string): Promise<User>
   - updateProfile(userId: string, dto: UpdateProfileDto): Promise<User>
   - updateLanguageProgress(userId: string, language: string, xpEarned: number): Promise<User>
     Full implementation: add XP, update level (floor(totalXP/1000)+1 capped at 100), update weekly XP, check/update streak (compare lastActivityDate with today, if consecutive increment streak+longestStreak, else reset to 1), update lastActivityDate
   - updateSkillTree(userId: string, skillId: string, newValue: number): Promise<User>
   - updateWeakPhonemes(userId: string, language: string, phoneme: string, wasCorrect: boolean): Promise<User>
     Full implementation: find existing entry for language+phoneme, if correct decrement errorRate (min 0), if incorrect increment errorRate (max 1.0), if new phoneme entry create it. Update lastDrillDate.
   - uploadAvatar(userId: string, file: Express.Multer.File): Promise<string>
     Full implementation: validate file is image, resize to 256x256 using sharp, upload to S3 with userId prefix, invalidate CloudFront cache for old avatar, return new CDN URL
   - getUserLeaderboard(language: string, type: 'weekly'|'alltime', page: number, limit: number): Promise<{users, total, page}>
   - getUserStats(userId: string): Promise<complete stats object including all game modes, pvp record, clan info>
   - activateStreakShield(userId: string): Promise<User> — set streakShieldActive:true, streakShieldExpiry: now+24h, requires premium
   - getUserProgress(userId: string, language: string): Promise<detailed learning progress>
   - searchUsers(query: string, language?: string): Promise<User[]> — MongoDB text search
   - banUser(adminId: string, userId: string, reason: string): Promise<void> — requires admin role
   - deleteAccount(userId: string): Promise<void> — GDPR compliant, anonymize then soft delete

2. users.controller.ts — Routes:
   GET /users/me — full profile
   PATCH /users/me — update profile
   POST /users/me/avatar — upload avatar (MulterModule with 5MB limit, image/jpeg|png|webp only)
   GET /users/leaderboard — with ?language=&type=weekly|alltime&page=&limit=
   GET /users/:username/profile — public profile
   GET /users/me/stats — detailed stats
   GET /users/me/progress/:language — language progress
   POST /users/me/streak-shield — activate shield
   GET /users/search — search users

3. dto/update-profile.dto.ts — All optional fields: displayName, timezone, countryCode, notificationPreferences, equippedCosmetics

4. users.module.ts — exports UsersService

All service methods fully implemented. No TODOs.
```

---

## PROMPT 1.5 — DIALOGUE ENGINE MODULE (COMPLETE)

```
You are a senior game backend engineer. Build the complete Dialogue Engine module for Lingua Realms — the core RPG mechanic.

Generate apps/backend/src/modules/dialogue/ with:

1. dialogue.service.ts — Complete DialogueService:

   - getDialogueNode(nodeId: string): Promise<DialogueNode>

   - startDialogue(userId: string, npcId: string, language: string, regionId: string): Promise<DialogueStartResult>
     Full implementation: Load or create NPCMemory for this user+NPC. Find entry dialogue node for this NPC in this region that matches NPC's current emotional state requirements. Return node with localized text, response options (filtered by player's skill level), NPC emotional state for animation trigger, hint if player's level is below node difficulty.

   - submitResponse(userId: string, dto: SubmitResponseDto): Promise<DialogueResponseResult>
     Full implementation:
     a) Load NPCMemory and DialogueNode
     b) Find selected responseOption
     c) Score the response:
        - grammarScore: validate grammar pattern match (regex-based for now, NLP-enhanced later) → 0-100
        - toneScore: if pronunciation submitted, call pronounciation-ai microservice; else check text diacritics → 0-100
        - culturalScore: check register requirement (if elder NPC and player used informal register → -40pts), age respect, gender consideration → 0-100
        - emotionalScore: calculate based on NPC's current emotionalState and interaction history → 0-100
     d) Check success condition thresholds
     e) Update NPCMemory via updateFromDialogueScore()
     f) Calculate XP earned: base 10 + (grammarScore * 0.2) + (toneScore * 0.3) + (culturalScore * 0.2) + difficulty * 5
     g) Update user XP via UsersService.updateLanguageProgress()
     h) Record mistakes to GameSession
     i) Trigger spaced repetition scheduling for practiced vocabulary
     j) Return: {success, nextNodeId, npcEmotionalStateNew, scores, xpEarned, unlockedItems, feedbackMessage, nativePronunciationUrl}

   - evaluateGrammarPattern(input: string, pattern: string, language: string): number
     Full implementation: Pattern is a regex-like grammar rule string. Parse the pattern, apply language-specific grammar rules. For Bantu languages, check noun class agreement. For Yoruba, check verb serialization. Returns 0-100 score.

   - checkCulturalRequirement(requirement: any, npcId: string, memory: NPCMemory, language: string): number
     Full implementation checking register, respect, and context appropriateness.

   - getQuestDialogues(userId: string, questId: string, language: string): Promise<DialogueNode[]>

   - getNPCsInRegion(regionId: string, userId: string, language: string): Promise<NPCSummary[]>
     Returns NPCs with their current emotional state for this user, unlocked status, and whether they have active quests

   - triggerFestivalDialogue(userId: string, festivalId: string, npcId: string): Promise<DialogueNode>

2. dialogue.controller.ts — Routes:
   GET /dialogue/node/:nodeId
   POST /dialogue/start — {npcId, language, regionId}
   POST /dialogue/respond — SubmitResponseDto
   GET /dialogue/npcs/:regionId — NPCs with current relationship status
   GET /dialogue/quest/:questId
   GET /dialogue/npc/:npcId/memory — user's relationship with this NPC

3. dto/submit-response.dto.ts:
   nodeId: string (required)
   selectedOptionId: string (required)
   textInput: string (optional — player's typed response)
   audioBase64: string (optional — for tone scoring)
   audioDurationMs: number (optional)
   sessionId: string (required)

4. interfaces/dialogue-result.interface.ts — Complete interfaces for DialogueStartResult and DialogueResponseResult with all fields typed

5. dialogue.module.ts — Imports SchemasModule, PronunciationModule, UsersModule

Every method body fully implemented. The grammar evaluation must have real logic — not a stub returning 100.
```

---

## PROMPT 1.6 — PVP MODULE (COMPLETE)

```
You are a senior real-time systems engineer. Build the complete PvP module with WebSocket matchmaking for Lingua Realms.

Generate apps/backend/src/modules/pvp/ with:

1. pvp.gateway.ts — Complete Socket.IO WebSocket gateway:
   - @WebSocketGateway({ namespace: '/pvp', cors: { origin: '*' } })
   - @WebSocketServer() server: Server
   - Inject PvPService, UsersService, LeaderboardService

   Event handlers (all fully implemented):
   
   @SubscribeMessage('pvp:join_queue')
   handleJoinQueue(client: Socket, payload: {language: string, mode: 'blitz'|'sentence_strategy'|'tone_duel'})
     Full implementation:
     a) Extract userId from JWT in client.handshake.auth.token
     b) Check user is not banned, has required level for mode
     c) Add to Redis matchmaking queue: ZADD pvp:queue:{language}:{mode} {eloRating} {userId}:{socketId}
     d) Run matchmaking: ZRANGEBYSCORE pvp:queue:{language}:{mode} (playerElo-200) (playerElo+200) LIMIT 0 1
     e) If match found: remove both from queue, create PvPMatch document, create Socket.IO room, emit 'pvp:match_found' to both with match details, call startRound()
     f) If no match: set 30s timeout, widen ELO range by 50 each retry

   @SubscribeMessage('pvp:submit_answer')
   handleSubmitAnswer(client: Socket, payload: {matchId: string, answer: string, audioBase64?: string})
     Full implementation:
     a) Verify this socket belongs to this match
     b) Record submission with server timestamp (anti-cheat: client timestamp ignored)
     c) Score the submission using PvPService.scoreSubmission()
     d) Store score in match round
     e) If both players submitted (or timeout): call resolveRound()
     f) Emit 'pvp:round_result' to room with both scores, correct answer, round winner

   @SubscribeMessage('pvp:forfeit')
   handleForfeit(client: Socket, payload: {matchId: string})
     Full implementation: end match, award win to opponent, apply ELO change

   handleDisconnect(client: Socket)
     Full implementation: if player disconnects during active match, wait 30s for reconnect, then auto-forfeit

   Private startRound(matchId: string, roundNumber: number)
     Full implementation: select word based on both players' weak areas, emit 'pvp:round_start' with word + tone markers + difficulty. Set 30s round timer in Redis. For tone_duel mode include pronunciation challenge.

   Private resolveRound(matchId: string, roundNumber: number)
     Full implementation: determine round winner, update match scores, if 5 rounds done call endMatch(), else call startRound(roundNumber+1)

   Private endMatch(matchId: string)
     Full implementation: calculate ELO changes using elo.utils, update both users' eloRatings Map for language, save match, emit 'pvp:match_end' to room, update Redis leaderboard

2. pvp.service.ts — Complete PvPService:
   - createMatch(player1Id, player2Id, language, mode): Promise<PvPMatch>
   - scoreSubmission(answer: string, wordId: string, language: string, mode: string, audioBase64?: string): Promise<{grammarScore, toneScore, totalScore, feedback}>
     Full implementation: validate answer against correct answer and acceptable variants, score grammar (for sentence_strategy), call pronunciation AI if audio provided, calculate weighted total
   - selectRoundWord(language: string, player1WeakPhonemes: string[], player2WeakPhonemes: string[], difficulty: number): Promise<Vocabulary>
     Full implementation: find words that intersect with both players' weak areas, fallback to difficulty-filtered random if no intersection
   - getMatchHistory(userId: string, page: number, limit: number): Promise<{matches, total}>
   - getMatchReplay(matchId: string): Promise<PvPMatch>
   - getActivePlayers(language: string): Promise<number> — Redis ZCARD of queue + active matches

3. pvp.controller.ts — REST endpoints:
   GET /pvp/history — user's match history
   GET /pvp/match/:matchId/replay — replay data
   GET /pvp/stats — user's PvP statistics (win rate, ELO history, most played language)
   GET /pvp/active/:language — active players count

4. pvp.module.ts — Imports, Bull queue for async match cleanup

All gateway event handlers and service methods fully implemented. No placeholders.
```

---

## PROMPT 1.7 — PRONUNCIATION MODULE (COMPLETE)

```
You are a senior NestJS engineer building the pronunciation scoring integration module.

Generate apps/backend/src/modules/pronunciation/ with:

1. pronunciation.service.ts — Complete PronunciationService:

   - scoreAudio(dto: ScoreAudioDto): Promise<PronunciationScoreResult>
     Full implementation:
     a) Validate audio: check base64 is valid, decode, check duration < MAX_AUDIO_DURATION_SECONDS
     b) Call Python FastAPI microservice via axios: POST {PRONUNCIATION_AI_URL}/score with multipart form data containing audio file, language, expected_word, expected_tone_pattern
     c) Handle errors: if AI service unavailable, fall back to rule-based scoring using checkDiacriticsInText()
     d) Cache result in Redis with key pronunciation:{language}:{wordId}:{userId} TTL 300s
     e) Update user's weakPhonemes via UsersService.updateWeakPhonemes() for each phoneme scoring below 70
     f) Return complete PronunciationScoreResult

   - scoreText(text: string, word: string, language: string): number
     Full implementation: Diacritics-based fallback scoring. For Yoruba: check ̀ ́ ̄ marks match expected. For Zulu: check click consonants c/q/x present correctly. For Amharic: compare Ge'ez characters. Returns 0-100.

   - batchScoreForSession(sessionId: string, submissions: AudioSubmission[]): Promise<PronunciationScoreResult[]>
     Process up to 10 audio submissions in parallel, return all results

   - getUserPronunciationReport(userId: string, language: string): Promise<PronunciationReport>
     Full implementation: aggregate user's last 30 days of pronunciation sessions, calculate average per phoneme, identify top 5 weak phonemes, generate drill recommendations

   - scheduleWeaknessDrill(userId: string, language: string): Promise<Vocabulary[]>
     Full implementation: get user's weak phonemes (errorRate > 0.4), query vocabulary with those phonemes, apply spaced repetition scheduling, return 10 vocabulary items due for practice

2. pronunciation.controller.ts — Routes:
   POST /pronunciation/score — submit audio for scoring (accepts multipart/form-data OR JSON with base64)
   POST /pronunciation/score-text — text-based fallback scoring
   GET /pronunciation/report/:language — user's pronunciation report
   GET /pronunciation/drill/:language — get weakness drill words

3. dto/score-audio.dto.ts:
   audioBase64: @IsString(), @IsNotEmpty()
   audioDurationMs: @IsNumber(), @Max(10000)
   language: @IsIn([...all languages])
   wordId: @IsMongoId()
   expectedWord: @IsString()
   expectedTonePattern: @IsArray(), @IsString({ each: true }), @IsOptional()

4. interfaces/pronunciation-result.interface.ts:
   Complete PronunciationScoreResult interface with all fields from the Python AI response PLUS:
   wordId, userId, language, timestamp, cached, fallbackUsed, drillRecommendations

5. pronunciation.module.ts — HttpModule for axios call to Python service

All methods complete, error handling thorough, no stubs.
```

---

## PROMPT 1.8 — LEADERBOARD, CLANS & ACHIEVEMENTS MODULES (COMPLETE)

```
You are a senior NestJS engineer. Build three interconnected modules: Leaderboard, Clans, and Achievements.

LEADERBOARD MODULE — apps/backend/src/modules/leaderboard/

leaderboard.service.ts — Complete LeaderboardService using Redis Sorted Sets:
- updateScore(userId: string, language: string, xp: number, type: 'weekly'|'alltime'): Promise<void>
  ZADD lingua:leaderboard:{type}:{language} INCR xp userId
- getLeaderboard(language: string, type: 'weekly'|'alltime', offset=0, limit=50): Promise<LeaderboardEntry[]>
  ZREVRANGEBYSCORE with WITHSCORES, enrich with user data from MongoDB (batch lookup by userIds)
- getUserRank(userId: string, language: string, type: string): Promise<{rank, score}>
  ZREVRANK + ZSCORE
- getClanLeaderboard(language: string): Promise<ClanLeaderboardEntry[]>
  Similar pattern for clan scores
- resetWeeklyLeaderboard(): Promise<void>
  Called by cron job every Monday 00:00 UTC. DEL all weekly keys. Archive to MongoDB WeeklyLeaderboardArchive.
- Bull queue consumer for async leaderboard updates (so game events don't block on leaderboard writes)

CLANS MODULE — apps/backend/src/modules/clans/

clans.service.ts — Complete ClansService:
- createClan(userId: string, dto: CreateClanDto): Promise<Clan>
  Validate user has no current clan, generate unique 8-char invite code, set chieftainId, add userId to memberIds, update user.clanId
- joinClan(userId: string, inviteCode: string): Promise<Clan>
  Find by inviteCode, check not full (< 50), check user meets requiredLevel, add user, update user.clanId
- leaveClan(userId: string): Promise<void>
  Remove from memberIds, if chieftain and other members: promote longest-tenure elder or member to chieftain, update user.clanId to null
- kickMember(chieftainId: string, targetUserId: string, clanId: string): Promise<void>
- promoteMember(chieftainId: string, targetUserId: string, clanId: string): Promise<void> — to elder
- getClanProfile(clanId: string): Promise<Clan with populated members>
- updateClanXP(clanId: string, xpAmount: number): Promise<void>
  Increment totalXP and weeklyXP, update Redis sorted set for clan leaderboard
- getClanActivity(clanId: string): Promise<activity feed>
  Recent member sessions, achievements, PvP wins
- searchClans(language: string, query?: string, page=1, limit=20): Promise<Clan[]>
  Supports text search on name and description
- startWeeklyChallenge(clanId: string): Promise<ClanChallenge>

clans.controller.ts — Full REST routes for all clan operations with proper guards

ACHIEVEMENTS MODULE — apps/backend/src/modules/achievements/

achievements.service.ts — Complete AchievementsService:
- checkAndAwardAchievements(userId: string, triggerType: string, currentValue: number, language?: string): Promise<Achievement[]>
  Full implementation: query all achievements with matching triggerType, filter where currentValue >= triggerValue, check user doesn't already have it, award all qualifying achievements, send push notification for each
- getUserAchievements(userId: string): Promise<{earned: Achievement[], available: Achievement[], secret: Achievement[]}>
- awardAchievement(userId: string, achievementId: string): Promise<void>
  Add to user's achievement list, award XP and cosmetic rewards, update achievement.totalUnlocked counter
- seedAchievements(): Promise<void>
  Full seed implementation inserting ALL achievements for all categories:
  - Pronunciation: "First Word" (1 pronunciation), "Tone Master" (50 perfect tones), "Click Champion" (20 Zulu clicks)
  - Vocabulary: "Word Hoarder" (100 words), "Lexicon" (500 words), "Dictionary" (1000 words)  
  - Grammar: "Grammar Apprentice" (10 correct grammar), "Sentence Weaver" (100 sentences)
  - Cultural: "Proverb Keeper" (10 proverbs), "Elder's Friend" (respect > 80 with 5 NPCs)
  - PvP: "First Blood" (1 PvP win), "Warrior" (10 wins), "Champion" (100 wins), "Unbeaten" (10 win streak)
  - Clan: "Clan Founder", "Griot Council" (join 3 clans total), "Tournament Victor"
  - Streak: "Week Warrior" (7 day streak), "Iron Will" (30 days), "Legend" (100 days)
  - Archive: "Voice of the Ancestors" (first archive contribution), "Digital Griot" (50 approved recordings)
  - Languages: "Polyglot" (3 languages B1+), "Pan-African" (5 languages active)
  All achievement objects fully populated with title, description in en/yo/sw/zu, xpReward, cosmeticReward.

achievements.controller.ts — GET /achievements, GET /achievements/me

All modules export their services. All methods fully implemented.
```

---

## PROMPT 1.9 — LIVING ARCHIVE MODULE (COMPLETE)

```
You are a senior NestJS engineer building the UNESCO language preservation module.

Generate apps/backend/src/modules/living-archive/ with:

1. living-archive.service.ts — Complete LivingArchiveService:

   - submitRecording(userId: string, dto: SubmitRecordingDto, audioFile: Express.Multer.File): Promise<LivingArchive>
     Full implementation:
     a) Validate audio: max 60 seconds, supported format, not silent (check RMS amplitude)
     b) Upload to S3: bucket s3://lingua-realms-archive/{language}/{contentType}/{uuid}.{format}
     c) Create LivingArchive document with status 'pending_ai_review'
     d) Queue Bull job for AI quality assessment
     e) If user is first-time contributor: trigger achievement check
     f) Return created document

   - processAIQualityReview(recordingId: string): Promise<void>
     Bull queue consumer — Full implementation:
     a) Download audio from S3
     b) Call pronunciation AI service: POST /archive/assess with audio + language + transcript
     c) Update document: aiQualityScore, aiToneAccuracyScore, aiNoiseScore
     d) If aiQualityScore >= 60 AND aiNoiseScore >= 70: change status to 'community_review'
     e) Else: status to 'rejected', set rejectionReason based on which score failed
     f) Notify speaker of result via push notification

   - voteOnRecording(userId: string, recordingId: string, vote: 'up'|'down'): Promise<void>
     Full implementation: prevent double-voting (Redis SET vote:{userId}:{recordingId} TTL 0), increment/decrement counters, check if threshold reached for canon approval (50+ upvotes AND < 5 downvotes AND aiQualityScore >= 80)

   - approveForCanon(adminId: string, recordingId: string): Promise<LivingArchive>
     Full implementation: set canonStatus true, link to vocabulary document, award speaker 200 XP and 'Digital Griot' badge progress

   - exportToUNESCO(language: string, adminId: string): Promise<UNESCOExportResult>
     Full implementation: query all canon recordings for language, generate standardized export JSON in ELAR/ELDP format with all metadata, upload to S3 as compressed archive, mark all included recordings as unescoExported:true, create export log entry, return download URL

   - getArchiveByLanguage(language: string, page=1, limit=20, contentType?: string): Promise<paginated LivingArchive>

   - getUserContributions(userId: string): Promise<{recordings, approvedCount, canonCount, xpEarned}>

   - getEndangeredLanguageAlert(): Promise<{language, speakerCount, recordingCount, needed}[]>
     Full implementation: query languages with isEndangeredLanguage:true, count recordings per language, calculate how many more are needed to reach 1000 recording minimum

2. living-archive.controller.ts — Routes:
   POST /archive/submit — multipart upload (multer, 50MB limit, audio formats only)
   GET /archive/:language — browse recordings
   POST /archive/:id/vote — vote on recording
   GET /archive/my-contributions — user's contributions
   POST /archive/:id/approve — admin only
   GET /archive/export/:language — generate UNESCO export (admin)
   GET /archive/endangered — endangered language alerts

3. dto/submit-recording.dto.ts:
   language: required, validated against supported list
   dialect: optional
   speakerRegion: required
   speakerAge: optional, 10-120
   contentType: required, enum
   transcript: required, non-empty
   translation: required
   culturalNotes: optional
   isEndangeredLanguage: boolean
   endangeredLanguageCode: optional

4. living-archive.module.ts — BullModule.registerQueue('archive-processing'), MulterModule, HttpModule

All methods complete, no placeholders.
```

---

## PROMPT 1.10 — PEDAGOGICAL ENGINE & ANALYTICS MODULE (COMPLETE)

```
You are a senior learning systems engineer. Build the Pedagogical Engine and Analytics modules.

PEDAGOGICAL ENGINE — apps/backend/src/modules/pedagogy/

pedagogy.service.ts — Complete PedagogyService:

- getDailyLesson(userId: string, language: string): Promise<DailyLesson>
  Full implementation:
  a) Get user's CEFR level for this language (derived from totalXP for that language)
  b) Get due spaced-repetition items: query vocabulary where userId has review scheduled for today
  c) Get weak phoneme drill words (up to 5 from weakPhonemes with errorRate > 0.3)
  d) Get new vocabulary (10 words at appropriate CEFR level not yet seen by user)
  e) Wrap in a structured DailyLesson with sections: warmup(3 reviews), new_words(5), phoneme_drill(5), grammar_exercise(3), cultural_item(1 proverb or cultural fact)
  f) Cache in Redis for 24 hours
  g) Return complete lesson object

- recordLessonProgress(userId: string, sessionId: string, results: LessonResult[]): Promise<void>
  Full implementation: for each result, update spaced repetition schedule, update weak phonemes, award XP, check achievements, update streak, emit analytics event

- calculateCEFRLevel(userId: string, language: string): Promise<string>
  Full implementation based on:
  - Vocabulary breadth score (how many words at each CEFR level known)
  - Grammar accuracy rate
  - Pronunciation average score
  - Dialogue completion rate
  Formula produces A0-C2 classification

- generateAdaptiveQuest(userId: string, language: string, regionId: string): Promise<AdaptiveQuest>
  Full implementation: analyze user's error patterns, select dialogue nodes targeting weak grammar patterns, set appropriate NPC interactions, wrap in quest narrative, return structured quest with objectives

- predictDropoff(userId: string): Promise<{riskScore: number, factors: string[], recommendation: string}>
  Full implementation logistic regression model:
  Features: daysSinceLastSession, averageSessionDuration, streakLength, weeklyXPtrend (last 4 weeks), errorRateTrend, pvpActivity, clanActivity
  Each feature scored 0-1 and weighted:
  daysSinceLastSession: >3 = 0.8 risk weight
  weeklyXPtrend: if declining = 0.6 risk
  streakLength: 0 = 0.7 risk
  Returns risk 0-1, list of contributing factors, actionable recommendation

- getPersonalizedContent(userId: string, language: string): Promise<ContentRecommendations>
  Return recommended: NPC to visit, vocabulary pack to complete, PvP mode to try, clan to join

ANALYTICS MODULE — apps/backend/src/modules/analytics/

analytics.service.ts — Complete AnalyticsService:
- trackEvent(userId: string, event: AnalyticsEvent): Promise<void>
  Buffer events in Redis LIST, flush every 60 seconds to MongoDB analytics collection
- getDashboardStats(adminId: string): Promise<AdminDashboard>
  Full implementation: DAU/WAU/MAU, language breakdown, top performing content, error hotspots, retention cohorts
- getUserEngagementReport(userId: string): Promise<UserEngagementReport>
- getLanguageHealth(language: string): Promise<LanguageHealthReport>
  Tracks: active learners, average progress rate, most problematic grammar points, most mispronounced phonemes

analytics.controller.ts — Admin-only routes for dashboard and reports
pedagogy.controller.ts — Routes for daily lesson, quest generation, progress recording

Both modules fully implemented, no stubs.
```

---

# ═══════════════════════════════════════════════════════════
# PHASE 2 — PYTHON PRONUNCIATION AI MICROSERVICE
# ═══════════════════════════════════════════════════════════

## PROMPT 2.1 — FASTAPI PRONUNCIATION ENGINE (COMPLETE)

```
You are a senior ML engineer building a production-grade pronunciation scoring engine for African languages.

Generate apps/pronunciation-ai/ complete directory:

1. requirements.txt — All pinned dependencies:
   fastapi==0.104.1, uvicorn[standard]==0.24.0, python-multipart==0.0.6,
   librosa==0.10.1, numpy==1.26.2, scipy==1.11.4,
   praat-parselmouth==0.4.3, soundfile==0.12.1,
   transformers==4.35.2, torch==2.1.0,
   redis==5.0.1, sentry-sdk[fastapi]==1.38.0,
   pydantic==2.5.2, pydantic-settings==2.1.0,
   python-jose[cryptography]==3.3.0,
   boto3==1.33.6, httpx==0.25.2,
   pytest==7.4.3, pytest-asyncio==0.21.1

2. main.py — Complete FastAPI application:
   - App initialization with title, version, Sentry integration
   - CORS middleware
   - Lifespan handler that loads all language models on startup (with graceful fallback if model files missing)
   - Include routers: pronunciation, archive, health
   - Global exception handler returning structured errors

3. config.py — Pydantic Settings class reading all env vars with defaults and validation

4. models/pronunciation_scorer.py — Complete PronunciationScorer class:
   
   def __init__(self, language: str):
     Load language-specific config from language_configs/{language}.json
     If Wav2Vec2 model available: load from model path
     Else: set use_fallback = True

   def score(self, audio_bytes: bytes, expected_word: str, expected_tone_pattern: list[str]) -> dict:
     Full implementation:
     a) Load audio with librosa (sr=16000, mono)
     b) Validate: duration check, silence check via RMS threshold
     c) Extract features: MFCC (128 coefficients), spectral centroid, zero crossing rate
     d) If not use_fallback: run Wav2Vec2 phoneme prediction
     e) Get pitch contour via Parselmouth: Sound → Pitch → to_array()
     f) score_phonemes(): compare predicted phonemes to expected, calculate accuracy 0-100
     g) score_tone(): compare pitch contour shape to expected pattern
     h) score_click_consonants() if Zulu or Xhosa: detect burst transients at click positions
     i) score_vowel_harmony() if applicable language: check vowel formant consistency
     j) Build and return complete response dict

   def score_tone(self, pitch_array: np.ndarray, expected_pattern: list[str], language: str) -> dict:
     Full implementation:
     - Normalize pitch array, remove unvoiced segments
     - Segment by syllable boundaries (estimated from amplitude envelope)
     - For each syllable: classify pitch level as H/L/M/F(falling)/R(rising) using:
       H: mean > 75th percentile of speaker's range
       L: mean < 25th percentile
       M: 25th-75th
       F: end < start - 10Hz
       R: end > start + 10Hz
     - Compare classified pattern to expected_pattern
     - Return toneScore, toneContour (classified), expectedContour, syllableScores[]

   def score_click_consonants(self, audio: np.ndarray, sr: int, expected_clicks: list[str]) -> dict:
     Full implementation:
     - Detect burst transients using onset_detect with backtrack=True
     - Analyze burst spectral characteristics to classify click type: dental (c), palatal (q), lateral (x)
     - Score based on presence and classification accuracy
     - Return clickScore and individual click detections

5. language_configs/ — Complete JSON config files for each language:
   
   yoruba.json: {
     "language": "yoruba", "script": "latin_diacritics",
     "has_tones": true, "tone_levels": ["H", "L", "M"],
     "tone_markers": {"H": "\u0301", "L": "\u0300", "M": ""},
     "has_clicks": false, "has_vowel_harmony": true,
     "vowel_harmony_groups": [["e", "ẹ", "o", "ọ"], ["a", "i", "u"]],
     "phoneme_inventory": ["b", "d", "f", "g", "gb", "h", "j", "k", "l", "m", "n", "p", "r", "s", "ṣ", "t", "w", "y"],
     "vowels": ["a", "e", "ẹ", "i", "o", "ọ", "u"],
     "difficulty_features": ["tones", "vowel_harmony", "labiovelar_gb"]
   }
   
   swahili.json: no tones, noun classes affect agreement, no clicks
   zulu.json: has_tones:true, has_clicks:true, click_types:["c","q","x","gc","gq","gx","nc","nq","nx"]
   hausa.json: has_tones:true, tone_levels:["H","L","F"], has_glottal:true
   amharic.json: has_tones:false, script:"geez", consonant_gemination:true
   igbo.json: has_tones:true, tone_levels:["H","L"], has_downstep:true
   xhosa.json: has_tones:true, has_clicks:true (same types as Zulu plus more)

6. routers/pronunciation.py — Complete FastAPI router:
   
   POST /score — accepts multipart form: audio_file(UploadFile), language(str), expected_word(str), expected_tone_pattern(str, JSON array), user_id(str)
     Full implementation:
     a) Validate audio file type (wav/mp3/ogg/m4a), size < 5MB
     b) Read audio bytes
     c) Get or create PronunciationScorer(language) from module-level cache
     d) Call scorer.score()
     e) Cache result in Redis: SET pronunciation:{language}:{expected_word}:{user_id} {result_json} EX 300
     f) Return complete PronunciationScoreResponse

   POST /archive/assess — assess a recording for the Living Archive
     Accept audio file + language + transcript
     Run quality checks: SNR score, duration, pronunciation quality, tone accuracy
     Return: {qualityScore, toneScore, noiseScore, recommendation, feedback}

   GET /health — returns model load status for each language

7. schemas/responses.py — Complete Pydantic response models:
   PronunciationScoreResponse, PhonemeScore, ToneAnalysis, ClickScore, ArchiveAssessmentResponse

8. Dockerfile — Multi-stage build:
   Stage 1 (builder): python:3.11-slim, install build deps, install requirements
   Stage 2 (runtime): python:3.11-slim, copy from builder, create non-root user, EXPOSE 8000
   CMD: uvicorn main:app --host 0.0.0.0 --port 8000 --workers 2

9. tests/test_pronunciation.py — Complete pytest test suite:
   - test_score_yoruba_word_correct_tone()
   - test_score_yoruba_word_wrong_tone()
   - test_score_zulu_clicks()
   - test_silence_detection()
   - test_too_long_audio()
   - test_unsupported_language()
   All tests use sample audio generated programmatically (sine wave approximations), no external files needed.

All code complete, all functions fully implemented.
```

---

# ═══════════════════════════════════════════════════════════
# PHASE 3 — FLUTTER MOBILE APP: COMPLETE ARCHITECTURE
# ═══════════════════════════════════════════════════════════

## PROMPT 3.1 — FLUTTER PROJECT FOUNDATION

```
You are a senior Flutter architect. Set up the complete Lingua Realms Flutter app.

Generate apps/mobile/ complete setup:

1. pubspec.yaml — All dependencies with exact versions:
   flutter_riverpod: ^2.4.9
   riverpod_annotation: ^2.3.3
   go_router: ^13.0.0
   dio: ^5.4.0
   retrofit: ^4.1.0 (for type-safe API)
   flutter_secure_storage: ^9.0.0
   shared_preferences: ^2.2.2
   hive: ^2.2.3 (offline storage)
   hive_flutter: ^1.1.0
   flame: ^1.13.0 (mini-game engine)
   flame_audio: ^2.1.1
   rive: ^0.12.4 (character animations)
   lottie: ^3.0.0 (UI micro-animations)
   just_audio: ^0.9.36
   record: ^5.0.4 (microphone for pronunciation)
   permission_handler: ^11.1.0
   image_picker: ^1.0.5
   cached_network_image: ^3.3.1
   socket_io_client: ^2.0.3+1
   web_socket_channel: ^2.4.0
   flutter_animate: ^4.3.0
   google_fonts: ^6.1.0
   fl_chart: ^0.66.0 (progress charts)
   in_app_purchase: ^3.1.12 (IAP)
   firebase_messaging: ^14.7.10 (push notifications)
   firebase_core: ^2.24.2
   sentry_flutter: ^7.14.0
   connectivity_plus: ^5.0.2
   device_info_plus: ^9.1.1
   path_provider: ^2.1.2
   flutter_local_notifications: ^16.3.0
   freezed: ^2.4.6 (immutable models)
   freezed_annotation: ^2.4.1
   json_serializable: ^6.7.1
   build_runner: ^2.4.7

2. lib/core/router/app_router.dart — Complete GoRouter configuration:
   All routes defined:
   / → SplashScreen
   /onboarding → OnboardingFlow
   /auth/login → LoginScreen
   /auth/register → RegisterScreen
   /home → HomeScreen (shell route with bottom nav)
   /home/village → VillageScreen (RPG map)
   /home/pvp → PvPLobbyScreen
   /home/builder → BuilderScreen
   /home/archive → ArchiveScreen
   /home/profile → ProfileScreen
   /rpg/region/:regionId → RegionMapScreen
   /rpg/dialogue/:npcId → DialogueScreen
   /rpg/quest/:questId → QuestScreen
   /pvp/matchmaking → MatchmakingScreen
   /pvp/battle/:matchId → BattleScreen
   /pvp/result/:matchId → BattleResultScreen
   /arcade/tone-runner → ToneRunnerScreen
   /mythology/:entityId → MythologyScreen
   /clans → ClanListScreen
   /clans/:clanId → ClanProfileScreen
   /leaderboard → LeaderboardScreen
   /settings → SettingsScreen
   /lesson/daily → DailyLessonScreen
   /achievements → AchievementsScreen
   /cosmetics → CosmeticsShopScreen
   
   Each route has:
   - redirect logic (unauthenticated → /auth/login)
   - pageBuilder returning CustomTransitionPage with appropriate transition (slide/fade)
   - errorBuilder showing styled ErrorScreen

3. lib/core/theme/app_theme.dart — Complete Material 3 theme:
   Afro-futuristic color scheme:
   - Primary: Color(0xFFD4A843) — Gold
   - PrimaryVariant: Color(0xFFC4601A) — Ember
   - Secondary: Color(0xFF2D4A2D) — Forest
   - Background: Color(0xFF0A0806) — Obsidian
   - Surface: Color(0xFF1A1208) — Dark wood
   - Error: Color(0xFFB31B1B)
   - OnPrimary: Color(0xFF0A0806)
   Complete TextTheme using Google Fonts:
   - displayLarge: BebasNeue, 57sp
   - displayMedium: BebasNeue, 45sp
   - headlineLarge: PlayfairDisplay w700, 32sp
   - headlineMedium: PlayfairDisplay w700, 28sp
   - titleLarge: SpaceMono w700, 22sp
   - bodyLarge: CormorantGaramond, 16sp
   - bodyMedium: SpaceMono, 14sp
   - labelSmall: SpaceMono, 11sp letterSpacing 0.1
   Dark theme only — no light mode.
   Custom card theme, button theme (all outlined with gold border), input decoration theme (underline only, gold focus color), bottom nav theme.

4. lib/core/network/api_client.dart — Complete Dio configuration:
   - Base URL from AppConfig
   - Interceptors:
     AuthInterceptor: adds Authorization: Bearer {accessToken} header, handles 401 by refreshing token using secure storage, retries original request once
     LoggingInterceptor: logs all requests/responses in debug mode
     ErrorInterceptor: converts DioException to AppException types
   - connectTimeout: 30s, receiveTimeout: 60s
   - Cancel token management

5. lib/core/storage/secure_storage.dart — Complete SecureStorage service wrapping FlutterSecureStorage:
   Methods: saveTokens, getAccessToken, getRefreshToken, clearTokens, saveUserId, getUserId

6. lib/core/storage/offline_storage.dart — Complete offline storage using Hive:
   - HiveBoxes: vocabulary, dialogueNodes, userProgress, pendingSubmissions
   - Methods: cacheVocabulary, getCachedVocabulary, cacheDialogueNode, getDialogueNode, queueOfflineSubmission, getPendingSubmissions, clearPendingSubmissions
   - Sync manager: syncPendingSubmissions() — when connectivity restored, submit all queued sessions

7. lib/core/providers/auth_provider.dart — Complete Riverpod AuthNotifier:
   States: AuthInitial, AuthLoading, AuthAuthenticated(user), AuthUnauthenticated
   Methods: login, register, logout, refreshSession, checkAuthStatus (called on app start from secure storage)

All files complete, no TODOs.
```

---

## PROMPT 3.2 — FLUTTER DATA LAYER (COMPLETE)

```
You are a senior Flutter engineer. Build the complete data layer for Lingua Realms.

Generate lib/data/ with:

1. lib/data/models/ — Complete Freezed models for all entities:
   user.model.dart, vocabulary.model.dart, dialogue_node.model.dart, npc_memory.model.dart, pvp_match.model.dart, clan.model.dart, living_archive.model.dart, daily_lesson.model.dart, pronunciation_result.model.dart, achievement.model.dart, game_session.model.dart

   Each model uses @freezed annotation, has fromJson/toJson, copyWith, all required fields typed correctly matching the MongoDB schemas. No 'dynamic' types. Use DateTime for dates, List<T> for arrays.

   Example structure for UserModel:
   @freezed class UserModel with _$UserModel {
     const factory UserModel({
       required String id,
       required String email,
       required String username,
       String? displayName,
       String? avatarUrl,
       required String primaryLanguage,
       required List<LearningLanguage> learningLanguages,
       String? diasporaOrigin,
       required int level,
       required int totalXP,
       required int weeklyXP,
       required int streak,
       required int longestStreak,
       DateTime? lastActivityDate,
       required bool streakShieldActive,
       required Map<String, int> eloRatings,
       String? clanId,
       required String griotRank,
       required List<String> unlockedRegions,
       required List<WeakPhoneme> weakPhonemes,
       required PronunciationProfile pronunciationProfile,
       required String subscriptionTier,
     }) = _UserModel;
     factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
   }

2. lib/data/repositories/ — Complete repository implementations:

   auth_repository.dart — AuthRepository:
   - login(email, password): calls POST /auth/login, stores tokens, returns UserModel
   - register(dto): calls POST /auth/register
   - logout(): calls POST /auth/logout, clears secure storage
   - refreshTokens(): calls POST /auth/refresh
   - getCurrentUser(): calls GET /auth/me

   user_repository.dart — UserRepository:
   - getProfile(): GET /users/me
   - updateProfile(dto): PATCH /users/me
   - uploadAvatar(file): POST /users/me/avatar
   - getLeaderboard(language, type, page): GET /users/leaderboard
   - getUserStats(): GET /users/me/stats

   vocabulary_repository.dart — VocabularyRepository:
   - getDailyLesson(language): GET /pedagogy/daily-lesson
   - searchVocabulary(query, language): GET /vocabulary/search
   - getWord(wordId): GET /vocabulary/:id
   - cacheWords(words): store in Hive for offline

   dialogue_repository.dart — DialogueRepository:
   - startDialogue(npcId, language, regionId): POST /dialogue/start
   - submitResponse(dto): POST /dialogue/respond
   - getNPCsInRegion(regionId): GET /dialogue/npcs/:regionId
   - getNPCMemory(npcId): GET /dialogue/npc/:npcId/memory

   pvp_repository.dart — PvPRepository:
   - getMatchHistory(page): GET /pvp/history
   - getMatchReplay(matchId): GET /pvp/match/:matchId/replay
   - getActivePlayerCount(language): GET /pvp/active/:language

   clan_repository.dart — ClanRepository:
   - createClan(dto): POST /clans
   - joinClan(inviteCode): POST /clans/join
   - leaveClan(): DELETE /clans/me
   - getClan(clanId): GET /clans/:id
   - searchClans(language, query): GET /clans/search

   pronunciation_repository.dart — PronunciationRepository:
   - scoreAudio(audioBytes, language, wordId, expectedWord): POST /pronunciation/score (multipart)
   - scoreText(text, word, language): POST /pronunciation/score-text
   - getReport(language): GET /pronunciation/report/:language
   - getDrillWords(language): GET /pronunciation/drill/:language

   archive_repository.dart — ArchiveRepository:
   - submitRecording(audioFile, dto): POST /archive/submit (multipart)
   - getRecordings(language, page): GET /archive/:language
   - voteOnRecording(id, vote): POST /archive/:id/vote
   - getMyContributions(): GET /archive/my-contributions

3. lib/data/services/socket_service.dart — Complete Socket.IO service:
   - connect(): establish socket connection with JWT auth header
   - disconnect(): close connection
   - joinPvPQueue(language, mode): emit pvp:join_queue
   - submitPvPAnswer(matchId, answer, audioBase64?): emit pvp:submit_answer
   - forfeitMatch(matchId): emit pvp:forfeit
   - Stream<PvPMatchFoundEvent> get onMatchFound: listen to pvp:match_found
   - Stream<PvPRoundStartEvent> get onRoundStart: listen to pvp:round_start
   - Stream<PvPRoundResultEvent> get onRoundResult: listen to pvp:round_result
   - Stream<PvPMatchEndEvent> get onMatchEnd: listen to pvp:match_end
   - Stream<PronunciationLiveScoreEvent> get onLivePronunciationScore
   - Stream<NPCMemoryUpdateEvent> get onNPCMemoryUpdate
   - Stream<ClanXPUpdateEvent> get onClanXPUpdate
   All streams use StreamController.broadcast()

4. lib/data/services/audio_service.dart — Complete audio service:
   - startRecording(): request permission if needed, start record
   - stopRecording(): stop, return audio bytes as Uint8List
   - playAudio(url): play from CDN URL via just_audio
   - playLocalAudio(bytes): play from bytes
   - preloadAudio(urls: List<String>): preload list of CDN URLs
   - getRecordingLevel(): Stream<double> for microphone level visualization
   - isRecording: bool getter

All repositories use Either<Failure, T> pattern (create Failure sealed class with subtypes: NetworkFailure, ServerFailure, CacheFailure, AuthFailure). No exceptions thrown to UI.
```

---

## PROMPT 3.3 — FLUTTER UI: HOME, VILLAGE MAP & DIALOGUE SCREEN (COMPLETE)

```
You are a senior Flutter UI engineer building AAA-quality game screens.

Build the following complete screens in lib/features/:

1. lib/features/home/home_screen.dart — Main hub screen:
   Complete implementation with:
   - CustomScrollView with SliverAppBar (animated Kente-pattern header, collapses on scroll)
   - User stats card (XP, streak with flame animation, level badge, language flag)
   - Daily quest card (shows today's lesson progress, animated fill bar)
   - Language selector (horizontal scroll, card per language, shows progress ring)
   - Game mode grid: 6 animated cards (Village RPG, PvP Arena, Tone Runner, Builder, Mythology, Archive)
   - Clan activity strip (if in clan: recent member XP events)
   - Festival alert banner (if active festival: animated, dismissible)
   - Bottom navigation with 5 tabs: Home, Village, PvP, Clans, Profile
   All animations use flutter_animate with stagger effects on load.
   Background: dark gradient with subtle Adinkra pattern overlay (CustomPainter).

2. lib/features/rpg/village_screen.dart — Interactive village map:
   Complete implementation:
   - InteractiveViewer wrapping a CustomPainter village map
   - Draw 8 distinct regions as painted areas with proper African architectural silhouettes
   - Tap region → navigate to region_map_screen
   - Animated floating NPCs at their locations (Lottie animations)
   - Region lock overlay for locked regions (shows XP requirement)
   - Ambient sound: play village ambience via audio service
   - Top overlay: current language badge, XP counter
   - NPC speech bubbles that appear/disappear (show current quest hint)

3. lib/features/rpg/dialogue_screen.dart — Full dialogue interface:
   Complete implementation with all states:
   
   LOADING state: Skeleton loader shaped like dialogue interface
   
   ACTIVE state:
   - NPC avatar (Rive animation that transitions between emotional states: neutral/pleased/angry/delighted based on NPCMemoryUpdateEvent from WebSocket)
   - NPC name and title in correct African script
   - NPC speech text with animated typewriter reveal (50ms per character)
   - Tone markers displayed above text in gold (high/low/mid diacritics)
   - Native pronunciation button: plays audio via audio service
   - Response options list (2-4 options, each showing grammar hint on long press)
   - OR free-text input mode with:
     - Text field with diacritics keyboard extension (custom row above keyboard with tone markers)
     - Microphone button that starts recording
     - Recording waveform visualization (CustomPainter, animates while recording)
   - Submit button (disabled until response selected/typed)
   - Current scores display: Grammar/Tone/Cultural meters (thin horizontal bars)
   
   SCORING state (after submit):
   - Animated score reveal for each category
   - Phoneme breakdown visual if pronunciation scored
   - "The NPC's reaction" animation (respect meter change)
   - Correct feedback with translation
   - XP earned celebration (Lottie confetti for high scores)
   - Continue button → next dialogue node
   
   All state transitions use flutter_animate. All fonts use defined TextTheme.

4. lib/features/pvp/matchmaking_screen.dart — PvP lobby:
   Complete implementation:
   - Mode selector: Blitz / Sentence Strategy / Tone Duel (animated selection cards)
   - Language selector (shows user's ELO per language)
   - Active players count (updated via socket)
   - "Find Match" button → emits pvp:join_queue
   - Searching state: animated pulsing ring, estimated wait time, "Widening search..." feedback
   - Match found state: opponent card slides in (username, ELO, clan, language flag), countdown "3...2...1..."
   - Animated battlefield transition

5. lib/features/pvp/battle_screen.dart — Live PvP battle:
   Complete implementation:
   - Top: Player vs Opponent cards (avatar, ELO, score, current round wins)
   - Center: Current word display (large, with tone markers)
   - If Tone Duel mode: waveform visualizer + record button + live scoring stream
   - If Blitz mode: text input + timer bar (30s, turns red at 10s, animates urgency)
   - If Sentence Strategy: sentence construction cards
   - Round result animation: winner card flash, score delta pop-up
   - Round history strip (5 slots at bottom, fill with win/loss/draw icons)
   - Opponent submission indicator (shows "Opponent typing..." state)
   - Forfeit button (with confirmation dialog)

All screen files complete and renderable. No abstract methods or TODO comments.
```

---

## PROMPT 3.4 — TONE RUNNER ARCADE GAME (COMPLETE)

```
You are a senior Flutter game developer using the Flame engine.

Build the complete Tone Runner arcade game at lib/features/arcade/tone_runner_game.dart and supporting files.

This is a Guitar Hero-style tone practice game. Words fall from the top. Player must tap correct tone contour or speak it.

Generate:

1. lib/features/arcade/tone_runner_game.dart — Complete Flame Game class:
   class ToneRunnerGame extends FlameGame with HasGameRef, TapCallbacks, KeyboardEvents:
   
   - GameState enum: intro, playing, paused, gameover
   - Score, combo multiplier, accuracy percentage as game variables
   - Three lanes (Low tone, Mid tone, High tone) represented as vertical columns
   - Lane positions calculated dynamically from screen width
   - Lane decorators: CustomPainter drawing subtle African textile pattern borders
   
   onLoad():
   - Load AudioPool for hit sounds (correct, incorrect, perfect) using flame_audio
   - Load word queue from passed-in VocabularyList parameter
   - Initialize SpawnSystem, ScoreSystem, LaneSystem
   - Start background music (Afrobeats track from CDN, loop)
   - Create HUD (score, combo, lives, accuracy)
   
   update(dt):
   - Move all active FallingWordComponents downward (speed = baseSpeed + (level * 0.1))
   - Check for missed words (below screen = -1 life, -50 score, break combo)
   - Spawn new words on schedule
   - Check combo milestone (every 10: speed +10%, flash effect)
   - Check lives (0 → game over sequence)
   
   Spawning: schedule word spawns based on word list, assign to lane based on word's expected tone (H→lane2, M→lane1, L→lane0), assign random horizontal variance within lane

2. lib/features/arcade/components/falling_word_component.dart — Complete FallingWord:
   - PositionComponent with tap detection
   - Renders: word text (Google Fonts Bebas Neue), tone marker (◤◢◈), difficulty glow
   - onTap(): check if this is the lowest word in its lane, score it, play sound, remove
   - animate hit: scale + fade explosion, score delta floats upward
   - animate miss: shake + red flash + fall off screen

3. lib/features/arcade/components/hud_component.dart — Complete HUD:
   - Score (top right, large Bebas Neue, animated increment)
   - Combo counter (top left, multiplier badge that pulses on increment)
   - Lives display (5 Adinkra dots that dim on loss)
   - Accuracy percentage bar
   - Progress through word list (thin top bar)

4. lib/features/arcade/microphone_mode.dart — Optional mic mode:
   - Overlays a waveform visualizer on the game
   - Listens to audio stream during gameplay
   - For each falling word: when word reaches tap zone, activate listening window (500ms)
   - Submit captured audio to pronunciation service
   - Score based on AI result (async, applies retroactively)
   - Visual: word glows green during active listening window

5. lib/features/arcade/tone_runner_screen.dart — Screen wrapper:
   - GameWidget wrapping ToneRunnerGame
   - Overlay for intro (language selector, difficulty selector, start button)
   - Overlay for pause (resume, quit buttons)
   - Overlay for game over (final score, accuracy %, accuracy breakdown per tone, replay button, share score button)
   - Transition from overlays to game using flutter_animate

6. lib/features/arcade/models/tone_runner_result.dart — Complete result model:
   totalWords, correctWords, missedWords, perfectHits, comboMax, finalScore, accuracyPercentage, toneBreakdown({H: {correct, total}, L: {correct, total}, M: {correct, total}}), durationSeconds, xpEarned

All game logic fully implemented, no placeholder game loops.
```

---

## PROMPT 3.5 — LIVING ARCHIVE SCREEN & AUDIO RECORDER (COMPLETE)

```
You are a senior Flutter engineer. Build the complete Living Archive feature.

Generate lib/features/archive/ with all files:

1. archive_screen.dart — Main archive browser:
   - Top: Language selector + content type filter chips (Word/Phrase/Proverb/Story/All)
   - Endangered language alert banner (animated, orange, shows for endangered languages)
   - Recording list: ListView.builder showing ArchiveRecordingCard for each item
   - FAB: "Contribute Recording" → navigate to recording submission screen
   - Empty state: Stylized illustration with "Be the first to record this language"
   - Filter/sort bottom sheet: by content type, by status (community_review/approved), by date

2. archive_recording_card.dart — Complete card widget:
   - Speaker info (region, contribution count badge)
   - Content type chip
   - Transcript text (expandable)
   - Translation (smaller, italic)
   - Audio player: compact waveform + play button + duration
   - AI quality score badge (color coded: ≥80 green, 60-79 yellow, <60 red)
   - Community vote buttons (upvote/downvote with animated count, check if user already voted)
   - Canon badge (gold star) if canonStatus: true
   - UNESCO badge if unescoExported: true

3. recording_submission_screen.dart — Complete multi-step recording wizard:
   
   Step 1 - Setup:
   - Language selection (dropdown)
   - Content type selection (large icon cards)
   - Dialect (optional text field)
   - Speaker region (text field, required)
   - Cultural notes (optional, expandable)
   - Endangered language toggle with explanation
   
   Step 2 - Transcript:
   - Large text field for transcript in native language (correct keyboard locale set)
   - Translation text field (English required, French/Portuguese optional)
   - Character count
   - "Record audio for this text" indicator
   
   Step 3 - Record:
   - Full-screen recording interface
   - Large circular record button (hold to record, max 60s)
   - Real-time waveform visualization (CustomPainter animating live amplitude)
   - Recording duration timer
   - Playback section (after recording): waveform + play/pause, re-record button
   - Quality hints: "Speak clearly", "Avoid background noise", "Hold phone 20cm from mouth"
   - Live volume level indicator (shows if too loud/quiet)
   
   Step 4 - Review & Submit:
   - Summary of all entered data
   - Audio playback one more time
   - AI quality pre-check: call /pronunciation/archive-check before final submit
   - Quality result display (before official submission)
   - Submit button (disabled if quality < 40)
   - Success screen: Lottie animation, "Your voice is now part of the archive", XP earned display, social share button

4. archive_providers.dart — Complete Riverpod providers:
   - archiveListProvider(language, contentType): AsyncNotifier that fetches and paginates
   - myContributionsProvider: fetches user's contributions
   - recordingStateProvider: StateNotifier managing multi-step form state
   - audioRecordingProvider: manages recording lifecycle (permissions, start, stop, playback)

All widgets complete and renderable.
```

---

# ═══════════════════════════════════════════════════════════
# PHASE 4 — GAME CONTENT: SEED DATA & CONTENT ENGINE
# ═══════════════════════════════════════════════════════════

## PROMPT 4.1 — DATABASE SEED: YORUBA COMPLETE CONTENT

```
You are an expert in Yoruba language and culture. Generate complete seed data for the Lingua Realms database.

Generate scripts/seed/yoruba-seed.ts — Complete TypeScript seed script:

1. 200 Yoruba vocabulary words spanning CEFR levels A0-B1:
   Each word fully populated with: word (in Yoruba with correct diacritics), tonePattern array, phonemeBreakdown, IPA transcription, English translation, French translation, partOfSpeech, nounClass (where applicable), difficulty 1-10, culturalContext, CEFR level, tags, relatedWords (by word string for later linking).

   Include words from categories:
   - Greetings (20): Ẹ káàárọ̀, Ẹ káàbọ̀, Ẹ káalẹ̀, Báwo ni, Àlàáfíà, Ẹ jọ̀ọ́, Ẹ dúpẹ́, E wọlé, and more
   - Numbers (15): Ọ̀kan through ogún, plus common counting patterns
   - Family (20): Àbúrò, ẹgbọ́n, bàbá, ìyá, and extended family terms
   - Market/Trade (20): Ọjà, owó, ta, ra, ẹlẹsẹ̀, oja alẹ, and negotiation words
   - Nature (15): Ọrun, ilẹ̀, omi, igi, and environment
   - Food (15): Àmàlà, ẹbà, obe, ẹgúsí, and traditional dishes
   - Body (10): Orí, ojú, ọwọ́, ese, and body parts  
   - Colors (10): Pupa, funfun, dúdú, àwo and color terms
   - Verbs (30): jẹ, mu, lọ, wá, sọ, gbọ, ri, mọ, and core verbs
   - Proverbs (15): Full proverbs with meaning, usage context, cultural explanation
   - Orisha vocabulary (10): Key Yoruba deity names and associated vocabulary
   - Emotions (15): Ayọ̀, bùkún, ìbínú, ẹ̀rù, and emotional states

2. 5 NPC character definitions for Yoruba region:
   Each fully defined: npcId, name, age, role (Elder/Market Trader/Youth/Priestess/Storyteller), personality, speech style, emotion defaults, first dialogue node ID, location in village

3. 20 DialogueNode entries for the first Yoruba quest "The Elder's Greeting":
   Full dialogue tree where player must:
   - Greet the elder correctly with "Ẹ káàárọ̀ bàbá" (morning greeting to elder)
   - Respond to question about origin using correct pronoun agreement
   - Accept quest with proper respectful phrasing
   Each node has full response options with tone requirements, grammar patterns, success/failure paths, and consequence definitions.

4. 3 Region definitions:
   Ibadan Marketplace (markets, negotiation language, casual speech)
   Ifẹ Sacred Grove (formal language, Orisha vocabulary, sacred register)
   Ọyọ Palace (royal language, highest register, complex grammar)

5. 2 Festival definitions:
   Egungun Masquerade festival with required chants, vocabulary pack IDs, dates
   Osun-Osogbo Grove festival with water ceremony vocabulary, dates

All data realistic, culturally accurate, properly encoded in Unicode. The seed script connects to MongoDB, upserts all documents, and logs progress. Run with: npx ts-node scripts/seed/yoruba-seed.ts
```

---

## PROMPT 4.2 — DATABASE SEED: SWAHILI & ZULU CONTENT

```
You are an expert in Swahili and Zulu languages and cultures. Generate complete seed data.

Generate scripts/seed/swahili-seed.ts and scripts/seed/zulu-seed.ts:

SWAHILI SEED:
150 vocabulary words including:
- Greetings (15): Jambo, Habari, Salama, Karibu, Asante, Tafadhali, Samahani, Hujambo, Sijambo, and more
- Noun classes (20): Examples from all 15 noun classes showing agreement patterns. For each word: nounClass field populated, example phrases showing agreement
- Market words (15): Soko, pesa, bei, gali, punguza, and bargaining vocabulary
- Safari/nature (15): Simba, tembo, twiga, nyota, jua, mvua, and environment
- Verbs (25): kula, kunywa, kwenda, kuja, kusema, kusikia, kuona
- Family (10), Body (10), Food (15), Swahili proverbs (15)

4 NPCs: Mama wa Soko (market woman), Mzee wa Pwani (coastal elder), Daktari (modern doctor), Mwalimu (teacher)
15 dialogue nodes for "The Harbor Welcome" quest (Mombasa setting)
3 regions: Mombasa Old Town, Serengeti Camp, Nairobi Modern District

ZULU SEED:
150 vocabulary words with special attention to:
- Click consonants (25): words using c/q/x/gc/gq/gc/nc/nq/nx clicks. For each: phonemeBreakdown must mark isClick:true and clickType. IPA must include proper click notation ǀ ǃ ǁ
- Greetings with clicks (10): Sawubona, Yebo, Unjani, Sikhona
- Ubuntu philosophy words (10): Ubuntu, umuntu, umphakathi, isibaya
- Nguni cattle culture (10): izinkomo, umuzi, isigodi
- Ancestor reverence words (10): amadlozi, ukuthetha, iminyanya
- Warrior tradition (10): Impondo zankomo formation vocabulary, courage words
- Nature/Zululand (15), Food (10), Family (10), Verbs (25)
- Izibongo (praise poetry) excerpts (5): showing complex tone patterns

4 NPCs: Induna (headman), Inyanga (healer), Umfana (young man), Inkosi (chief — highest register required)
20 dialogue nodes for "The Kraal Introduction" quest (player must use clicks correctly to greet community)
3 regions: KwaZulu Kraal, Drakensberg Mountains, Durban Harbor

All words encoded correctly in Unicode with diacritics. Scripts fully runnable.
```

---

# ═══════════════════════════════════════════════════════════
# PHASE 5 — ADMIN CMS (FLUTTER WEB)
# ═══════════════════════════════════════════════════════════

## PROMPT 5.1 — ADMIN CMS COMPLETE

```
You are a senior Flutter Web engineer. Build the complete Admin CMS for Lingua Realms.

Generate apps/admin-cms/ as a Flutter Web application:

1. Complete dashboard with:
   - Platform stats: DAU, MAU, total XP earned today, active PvP matches, archive submissions pending
   - Language health grid: per-language cards showing active users, content completion %, pronunciation avg
   - Live feed: recent events (new users, archive approvals, PvP matches ending)

2. Vocabulary Manager:
   - Full CRUD table with search, filter by language/CEFR/difficulty
   - Vocabulary form: all fields from schema, rich diacritics keyboard (custom widget with tone mark buttons)
   - Bulk import: CSV upload with field mapping UI
   - Audio upload: record in-browser or upload file, preview before saving
   - Export: download full vocabulary set as JSON or CSV

3. Dialogue Tree Editor:
   - Visual node graph editor (custom Flutter canvas using CustomPainter + InteractiveViewer)
   - Nodes represented as cards connected by edges (arrows)
   - Click node to open edit panel (all dialogue node fields)
   - Drag to connect nodes (defines nextNodeId relationships)
   - Preview mode: simulate dialogue as a player would experience it
   - Import/export dialogue trees as JSON

4. Living Archive Review Queue:
   - List of recordings with status 'community_review'
   - Audio player per recording
   - Accept/Reject buttons with reason selector
   - Bulk operations
   - UNESCO export trigger (exports all canon recordings for a language)

5. User Management:
   - Search/filter users by language, level, subscriptionTier, isBanned
   - User detail view: full profile, session history, pronunciation report
   - Ban/unban with reason
   - Grant/revoke Griot rank

6. Festival & Events Manager:
   - Calendar view of all festivals with active/inactive toggle
   - Festival form: all fields, vocabulary pack selector, date range picker
   - Activate/deactivate festivals in real-time (triggers WebSocket events to all active players)

All screens use Material 3 with the same Lingua Realms theme. DataTables for lists. Form validation identical to backend DTOs. API calls use same ApiClient as mobile. Role-based: ADMIN role required for ban/UNESCO export.
```

---

# ═══════════════════════════════════════════════════════════
# PHASE 6 — TESTING, DEVOPS & DEPLOYMENT
# ═══════════════════════════════════════════════════════════

## PROMPT 6.1 — COMPLETE TEST SUITES

```
You are a senior QA/testing engineer. Write complete test suites.

NESTJS BACKEND TESTS — apps/backend/src/**/*.spec.ts:

1. apps/backend/src/modules/auth/auth.service.spec.ts
   Complete test suite with jest and @nestjs/testing:
   - describe('register') → test successful registration, duplicate email throws, weak password throws, welcome email called
   - describe('login') → test valid credentials, wrong password throws UnauthorizedException, non-existent user throws
   - describe('refreshTokens') → valid refresh succeeds, invalid/expired token throws, used token throws (rotation)
   - describe('logout') → clears refresh token hash
   Mock all dependencies: UsersService, JwtService, SendgridService, BcryptService
   All test cases fully written, not just describe blocks.

2. apps/backend/src/modules/dialogue/dialogue.service.spec.ts
   - describe('submitResponse') → correct grammar scores high, incorrect tone scores low, cultural register mismatch penalizes, xp calculated correctly, NPC memory updated
   - describe('evaluateGrammarPattern') → Yoruba verb pattern matches, Bantu noun class agreement checked
   - describe('startDialogue') → returns correct entry node, NPC memory created if not exists
   Mock: NPCMemory model, DialogueNode model, PronunciationService, UsersService

3. apps/backend/src/modules/pvp/pvp.service.spec.ts
   - describe('scoreSubmission') → correct answer scores 100, wrong answer scores 0, partial match scores between
   - describe('selectRoundWord') → prioritizes shared weak phonemes, falls back to difficulty filter
   - describe('createMatch') → creates with correct initial state

4. apps/backend/src/utils/elo.utils.spec.ts — Test all ELO edge cases:
   - Equal ratings → symmetric result
   - Higher rated wins → small change
   - Higher rated loses → large change
   - Extreme rating differences
   - K-factor effects

5. apps/backend/src/utils/spaced-repetition.utils.spec.ts
   - Quality 5 (perfect) → long interval
   - Quality 0 (blackout) → reset to interval 1
   - Easiness factor floor at 1.3
   - Repetitions increment correctly

FLUTTER WIDGET TESTS — apps/mobile/test/:

6. test/features/dialogue/dialogue_screen_test.dart
   Complete widget tests:
   - renders NPC name and speech text
   - shows correct number of response options
   - tapping option triggers submitResponse call
   - score display animates after submission
   - microphone button starts recording
   Mock: DialogueRepository, AudioService, SocketService

7. test/features/pvp/battle_screen_test.dart
   - timer counts down from 30
   - submit button disabled until input present
   - round result shows correct winner
   - match end navigates to result screen

PYTHON TESTS — apps/pronunciation-ai/tests/:

8. tests/test_pronunciation.py (full version beyond what was in Phase 2):
   - test_yoruba_high_tone_detection()
   - test_yoruba_low_tone_detection()
   - test_click_type_classification_dental()
   - test_click_type_classification_palatal()
   - test_api_returns_correct_schema()
   - test_silence_returns_low_score()
   - test_audio_too_long_rejected()
   - test_caching_works()
   All tests generate synthetic audio data (pure tones, click bursts) programmatically.

All test files complete, runnable, with real assertions. No placeholder "expect(true).toBe(true)".
```

---

## PROMPT 6.2 — COMPLETE CI/CD AND DEPLOYMENT

```
You are a senior DevOps engineer. Build complete deployment configuration.

Generate:

1. .github/workflows/ci.yml — Complete CI pipeline:
   Triggers: push to main, PR to main
   Jobs:
   
   backend-test:
     runs-on: ubuntu-latest
     services: mongodb (mongo:7 with replica set init script), redis (redis:7)
     steps: checkout, node 20 setup, npm ci, generate test env from secrets, run jest --coverage, upload coverage to Codecov
   
   flutter-test:
     runs-on: ubuntu-latest
     steps: checkout, flutter 3.16 setup, flutter pub get, flutter analyze --fatal-infos, flutter test --coverage
   
   python-test:
     runs-on: ubuntu-latest
     steps: checkout, python 3.11 setup, pip install -r requirements.txt, pytest --cov
   
   docker-build-push (only on main):
     needs: [backend-test, flutter-test, python-test]
     steps: checkout, AWS credentials, ECR login, build backend image, build pronunciation-ai image, push both to ECR with git SHA tag and 'latest' tag
   
   deploy-staging (only on main, after build):
     steps: update ECS task definitions with new image tags, deploy to staging cluster, run smoke tests (curl health endpoints), notify Slack on success/failure

2. infrastructure/docker/backend.Dockerfile — Production multi-stage:
   Stage 1 (deps): node:20-alpine, copy package.json, npm ci --only=production
   Stage 2 (build): node:20-alpine, copy all, npm ci, npm run build
   Stage 3 (runtime): node:20-alpine, copy node_modules from deps, copy dist from build, create non-root user (uid 1001), EXPOSE 3000, HEALTHCHECK curl http://localhost:3000/health, CMD node dist/main.js

3. infrastructure/docker/pronunciation-ai.Dockerfile — Production:
   Base: python:3.11-slim
   Install: apt-get install -y libsndfile1 ffmpeg (required by librosa)
   Copy requirements, pip install --no-cache-dir
   Copy app code, create non-root user
   HEALTHCHECK curl http://localhost:8000/health
   CMD uvicorn main:app --host 0.0.0.0 --port 8000 --workers 2 --timeout-keep-alive 30

4. infrastructure/k8s/ — Complete Kubernetes manifests:
   backend-deployment.yaml: Deployment with 2 replicas, resource limits (cpu: 500m, memory: 512Mi), liveness probe (GET /health, initialDelay 30s), readiness probe, env from Secret/ConfigMap
   backend-service.yaml: ClusterIP service
   backend-hpa.yaml: HorizontalPodAutoscaler (min 2, max 10, target CPU 70%)
   pronunciation-ai-deployment.yaml: 1 replica (GPU-optional), larger memory (1Gi), same probe pattern
   pronunciation-ai-service.yaml
   ingress.yaml: NGINX ingress with SSL termination, routes /api → backend, /pronunciation → pronunciation-ai
   configmap.yaml: non-secret environment variables
   secret-template.yaml: template showing all required secret keys (values replaced at deploy time)
   mongo-init-job.yaml: Kubernetes Job that runs once to initialize MongoDB replica set

5. scripts/deploy.sh — Complete deployment script:
   #!/bin/bash with set -euo pipefail
   Accepts environment argument (staging|production)
   Checks AWS credentials configured
   Builds Docker images with correct tags
   Runs tests before deploy
   Pushes to ECR
   Updates Kubernetes deployments with kubectl
   Waits for rollout to complete (kubectl rollout status)
   Runs smoke tests against deployed endpoints
   Sends Slack notification with deploy details

6. infrastructure/monitoring/alerts.yaml — Prometheus AlertManager rules:
   - BackendDown: if backend unreachable > 1 minute
   - HighErrorRate: if 5xx rate > 5% for 5 minutes
   - PronunciationAILatency: if p95 > 500ms for 5 minutes
   - MongoDBReplicationLag: if replica lag > 30 seconds
   - LowDiskSpace: if disk > 85%
   - HighMemory: if memory > 90% for 10 minutes

All files complete, all commands real and executable.
```

---

# ═══════════════════════════════════════════════════════════
# PHASE 7 — MONETIZATION & IN-APP PURCHASES
# ═══════════════════════════════════════════════════════════

## PROMPT 7.1 — STRIPE & IAP COMPLETE INTEGRATION

```
You are a senior payments engineer. Build the complete monetization system.

BACKEND — apps/backend/src/modules/payments/

payments.service.ts — Complete PaymentsService:
- createStripeCustomer(userId: string, email: string): Promise<string> — creates Stripe customer, saves stripeCustomerId to user
- createSubscriptionCheckout(userId: string, tier: 'premium'|'griot_pro'): Promise<{checkoutUrl: string}>
  Full implementation: create Stripe Checkout Session with correct price ID per tier, success_url and cancel_url pointing to app deep links
- handleWebhook(payload: Buffer, signature: string): Promise<void>
  Full implementation processing all events:
  - checkout.session.completed → update user subscriptionTier and subscriptionExpiry
  - customer.subscription.deleted → downgrade user to 'free'
  - invoice.payment_failed → send payment failure email, set grace period 7 days
- createCosmeticPayment(userId: string, itemId: string): Promise<{clientSecret: string}>
  One-time payment intent for cosmetic items with price lookup
- grantCosmetic(userId: string, itemId: string): Promise<void>
  Add to user's unlockedCosmetics array
- getSubscriptionStatus(userId: string): Promise<SubscriptionStatus>

PRICE DEFINITIONS — payments.constants.ts:
const STRIPE_PRICES = {
  premium_monthly: 'price_XXXX_premium_monthly', // $4.99
  premium_annual: 'price_XXXX_premium_annual',   // $39.99
  griot_pro_monthly: 'price_XXXX_griot_monthly', // $9.99
  griot_pro_annual: 'price_XXXX_griot_annual',   // $79.99
}
const COSMETIC_PRICES = {
  kente_outfit_1: 299, // cents
  adire_outfit_1: 299,
  gold_staff: 499,
  clan_totem_lion: 199,
  // ... 20 more items all defined
}
const SUBSCRIPTION_FEATURES = {
  free: { maxLanguages: 1, offlineRegions: 0, streakShield: false, pvpDailyLimit: 5 },
  premium: { maxLanguages: 5, offlineRegions: 3, streakShield: true, pvpDailyLimit: -1 },
  griot_pro: { maxLanguages: -1, offlineRegions: -1, streakShield: true, pvpDailyLimit: -1, griotCertification: true, adminCMSAccess: false }
}

payments.controller.ts:
POST /payments/subscribe/:tier — create checkout session
POST /payments/webhook — Stripe webhook (no auth, raw body)
POST /payments/cosmetic/:itemId — purchase cosmetic
GET /payments/status — subscription status

FLUTTER — lib/features/shop/

cosmetics_shop_screen.dart — Complete screen:
- Categories: Outfits / Staffs / Clan Totems / Banners
- Item grid with preview images, prices, "Owned" badge for unlocked
- Item detail bottom sheet: 3D-like preview (Rive animation), lore text, purchase flow
- Purchase flow: native IAP on iOS/Android, Stripe Web on Flutter Web
- PurchaseProvider using in_app_purchase package:
  Full implementation listening to purchaseStream, verifying with backend, granting items

subscription_screen.dart — Complete paywall:
- Free vs Premium vs Griot Pro comparison table (all features listed per tier)
- Annual discount badge ("Save 33%")
- Platform-appropriate payment: IAP on mobile, Stripe on web
- Restore purchases button
- Trial offer display

All payment flows complete, all edge cases handled (network failure during purchase, duplicate purchase prevention).
```

---

# ═══════════════════════════════════════════════════════════
# FINAL INTEGRATION PROMPT
# ═══════════════════════════════════════════════════════════

## PROMPT 8.1 — FINAL INTEGRATION & LAUNCH CHECKLIST

```
You are a senior staff engineer doing final integration for Lingua Realms. Complete all remaining integration points and generate the final launch artifacts.

1. apps/backend/src/modules/admin/admin.service.ts — Complete AdminService:
   - seedDatabase(): runs all seed scripts in correct order (achievements first, then vocabulary, then NPCs, then dialogues, then festivals)
   - runMigration(version: string): applies database migrations
   - getSystemHealth(): returns all service statuses (MongoDB ping, Redis ping, Pronunciation AI ping, S3 connectivity check)
   - triggerFestivalActivation(): cron job — checks current date against all festivals, activates/deactivates, emits WebSocket event to all connected clients
   - processWeeklyLeaderboardReset(): Monday 00:00 UTC — archives weekly leaderboard, resets weekly XP on all users, sends weekly summary emails

2. apps/backend/src/modules/notifications/notifications.service.ts — Complete service:
   - sendPush(userId: string, title: string, body: string, data: object): Promise<void>
     Calls Firebase Admin SDK messaging.send() with FCM token from user document
   - sendEmail(to: string, template: string, variables: object): Promise<void>
     SendGrid dynamic templates:
     - welcome: welcomeUserToLingua
     - streak_broken: encourageReturn (if user misses 2 days)
     - achievement_earned: celebrateAchievement
     - weekly_summary: weeklyProgressSummary
     - archive_approved: recordingCanonApproved
     - subscription_renewed: subscriptionRenewalConfirmation
   - scheduleStreakBreakReminder(userId: string): 48h after last session, sends reminder push + email
   - sendWeeklySummary(userId: string): every Sunday, sends XP earned, streak, next milestone

3. apps/mobile/lib/core/connectivity/sync_manager.dart — Complete offline sync:
   - Monitors connectivity changes via connectivity_plus
   - On reconnect: calls syncPendingSubmissions() from OfflineStorage
   - Uploads pending game sessions, pronunciation recordings, archive submissions
   - Resolves conflicts: server wins for scores, latest-timestamp wins for profile updates
   - Shows sync progress UI (small notification bar at top)

4. scripts/generate-content.ts — Complete content generation utility:
   A TypeScript CLI tool that:
   - Accepts language parameter
   - Generates vocabulary template JSON (all fields defined, values to be filled by linguists)
   - Generates NPC template JSON
   - Validates existing content against schemas using zod
   - Reports missing audio URLs, missing IPA transcriptions, incomplete tone patterns
   - Exports report as markdown file

5. packages/game-content/index.ts — Complete game content registry:
   Exports: SUPPORTED_LANGUAGES array (all language codes and metadata), REGION_DEFINITIONS, FESTIVAL_CALENDAR (all festivals with dates for next 2 years calculated), ACHIEVEMENT_CATALOG, NPC_CATALOG, CEFR_THRESHOLDS by language, TONE_SYSTEM_BY_LANGUAGE

6. README.md — Complete developer documentation:
   - Architecture overview diagram (text-based)
   - Local development setup (step by step, every command)
   - Environment variable documentation (every variable explained)
   - Database seeding instructions
   - Running tests
   - Deployment guide
   - Contributing guide (code style, branch naming, PR template)
   - Pronunciation AI: how to add a new language (step by step)
   - Adding new game content: vocabulary, NPCs, dialogues (step by step with examples)
   - Troubleshooting section (15 common issues with solutions)

All files generated completely. No stubs. Every function returns real data. Every API endpoint tested. Every screen renders. The codebase should compile and run on the first attempt.
```

---

# APPENDIX: CURSOR AI USAGE NOTES

## Execution Order
Run prompts in exact numerical order. Each prompt builds on previous code.

## Verification Steps After Each Prompt
- Prompt 0.x: `docker-compose up --build` runs without errors
- Prompt 1.x: `npm run test` passes, `npm run start:dev` serves swagger at /api
- Prompt 2.x: `pytest` passes, `uvicorn main:app` starts
- Prompt 3.x: `flutter analyze` passes, `flutter test` passes
- Prompt 4.x: `npx ts-node scripts/seed/yoruba-seed.ts` seeds without errors
- Prompt 5.x: Flutter Web app builds `flutter build web`
- Prompt 6.x: GitHub Actions CI runs green
- Prompt 7.x: Stripe test webhooks process correctly
- Prompt 8.x: Full integration test suite passes

## Context Preservation
If Cursor loses context between prompts, paste this summary at the start of each new session:
"This is Lingua Realms — an African language learning game platform. Stack: Flutter + NestJS + MongoDB + Redis + Python FastAPI. We are building prompt [X]. The monorepo is at lingua-realms/. Key models are in packages/shared-types/src/index.ts. Previous prompts have generated: [list what exists]."

## File Size Management
If Cursor truncates large files, split the prompt into sub-tasks:
"Generate ONLY the service class from prompt X.X — not the module, not the controller, just the service."

## No-Placeholder Rule
If Cursor generates a comment like "// TODO: implement" or "// Add your logic here" or returns a function that throws `new Error('Not implemented')`, immediately say:
"Complete the implementation of [function name]. Write the actual logic. No placeholders. Here is the expected behavior: [paste relevant section from this prompt]."
