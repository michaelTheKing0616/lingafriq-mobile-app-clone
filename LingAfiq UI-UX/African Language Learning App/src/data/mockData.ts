import type { 
  Language, 
  User, 
  Course, 
  Lesson, 
  Badge, 
  Trophy, 
  LeaderboardEntry, 
  DailyChallenge,
  ProgressData,
  Magazine
} from '../types';

export const AFRICAN_LANGUAGES: Language[] = [
  {
    id: 'swahili',
    name: 'Swahili',
    nativeName: 'Kiswahili',
    flag: '🇹🇿',
    speakers: '200M+',
    difficulty: 'beginner',
    region: 'East Africa'
  },
  {
    id: 'yoruba',
    name: 'Yoruba',
    nativeName: 'Èdè Yorùbá',
    flag: '🇳🇬',
    speakers: '45M+',
    difficulty: 'intermediate',
    region: 'West Africa'
  },
  {
    id: 'zulu',
    name: 'Zulu',
    nativeName: 'isiZulu',
    flag: '🇿🇦',
    speakers: '27M+',
    difficulty: 'intermediate',
    region: 'Southern Africa'
  },
  {
    id: 'amharic',
    name: 'Amharic',
    nativeName: 'አማርኛ',
    flag: '🇪🇹',
    speakers: '32M+',
    difficulty: 'advanced',
    region: 'Horn of Africa'
  },
  {
    id: 'hausa',
    name: 'Hausa',
    nativeName: 'Harshen Hausa',
    flag: '🇳🇬',
    speakers: '80M+',
    difficulty: 'beginner',
    region: 'West Africa'
  },
  {
    id: 'igbo',
    name: 'Igbo',
    nativeName: 'Asụsụ Igbo',
    flag: '🇳🇬',
    speakers: '44M+',
    difficulty: 'intermediate',
    region: 'West Africa'
  },
  {
    id: 'somali',
    name: 'Somali',
    nativeName: 'Af-Soomaali',
    flag: '🇸🇴',
    speakers: '21M+',
    difficulty: 'intermediate',
    region: 'Horn of Africa'
  },
  {
    id: 'shona',
    name: 'Shona',
    nativeName: 'chiShona',
    flag: '🇿🇼',
    speakers: '15M+',
    difficulty: 'beginner',
    region: 'Southern Africa'
  }
];

export const MOCK_USER: User = {
  id: 'user-1',
  name: 'Amara Johnson',
  email: 'amara@example.com',
  avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
  xp: 3450,
  level: 12,
  streak: 23,
  badges: [],
  currentLanguage: AFRICAN_LANGUAGES[0],
  proficiency: 'beginner',
  joinedDate: '2024-01-15'
};

export const MOCK_COURSES: Course[] = [
  {
    id: 'course-1',
    languageId: 'swahili',
    title: 'Swahili Foundations',
    description: 'Learn the basics of Swahili with greetings, numbers, and common phrases.',
    level: 'beginner',
    lessons: 24,
    duration: '6 weeks',
    progress: 45,
    thumbnail: 'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?w=400'
  },
  {
    id: 'course-2',
    languageId: 'swahili',
    title: 'Everyday Conversations',
    description: 'Master daily conversations and practical communication skills.',
    level: 'beginner',
    lessons: 18,
    duration: '4 weeks',
    progress: 20,
    thumbnail: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400'
  },
  {
    id: 'course-3',
    languageId: 'swahili',
    title: 'Cultural Immersion',
    description: 'Explore Swahili culture, traditions, and idiomatic expressions.',
    level: 'intermediate',
    lessons: 16,
    duration: '5 weeks',
    progress: 0,
    thumbnail: 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=400'
  }
];

export const MOCK_LESSONS: Lesson[] = [
  {
    id: 'lesson-1',
    courseId: 'course-1',
    title: 'Greetings & Introductions',
    description: 'Learn how to greet people and introduce yourself in Swahili.',
    type: 'conversation',
    duration: 15,
    completed: true,
    locked: false,
    xpReward: 50
  },
  {
    id: 'lesson-2',
    courseId: 'course-1',
    title: 'Numbers 1-100',
    description: 'Master counting and numbers in Swahili.',
    type: 'vocabulary',
    duration: 20,
    completed: true,
    locked: false,
    xpReward: 50
  },
  {
    id: 'lesson-3',
    courseId: 'course-1',
    title: 'Family Members',
    description: 'Learn vocabulary related to family and relationships.',
    type: 'vocabulary',
    duration: 18,
    completed: false,
    locked: false,
    xpReward: 50
  },
  {
    id: 'lesson-4',
    courseId: 'course-1',
    title: 'Present Tense Verbs',
    description: 'Understand basic verb conjugation in the present tense.',
    type: 'grammar',
    duration: 25,
    completed: false,
    locked: false,
    xpReward: 75
  },
  {
    id: 'lesson-5',
    courseId: 'course-1',
    title: 'At the Market',
    description: 'Practice shopping vocabulary and bargaining phrases.',
    type: 'conversation',
    duration: 20,
    completed: false,
    locked: true,
    xpReward: 60
  }
];

export const MOCK_BADGES: Badge[] = [
  {
    id: 'badge-1',
    name: 'First Steps',
    description: 'Complete your first lesson',
    icon: '👣',
    rarity: 'common',
    dateEarned: new Date('2024-11-01')
  },
  {
    id: 'badge-2',
    name: 'Week Warrior',
    description: 'Maintain a 7-day streak',
    icon: '🔥',
    rarity: 'rare',
    dateEarned: new Date('2024-11-08')
  },
  {
    id: 'badge-3',
    name: 'Language Explorer',
    description: 'Try lessons in 3 different languages',
    icon: '🌍',
    rarity: 'epic',
    dateEarned: new Date('2024-11-15')
  },
  {
    id: 'badge-4',
    name: 'Perfect Score',
    description: 'Get 100% on a quiz',
    icon: '⭐',
    rarity: 'rare',
    dateEarned: new Date('2024-11-20')
  }
];

export const MOCK_TROPHIES: Trophy[] = [
  {
    id: 'trophy-1',
    name: 'Master Scholar',
    description: 'Complete 50 lessons',
    icon: '🏆',
    requirement: 'Complete 50 lessons in any language',
    progress: 23,
    maxProgress: 50
  },
  {
    id: 'trophy-2',
    name: 'Polyglot Pro',
    description: 'Learn 5 languages simultaneously',
    icon: '🌟',
    requirement: 'Start courses in 5 different languages',
    progress: 2,
    maxProgress: 5
  },
  {
    id: 'trophy-3',
    name: 'Community Champion',
    description: 'Send 1000 messages in community chat',
    icon: '💬',
    requirement: 'Be active in the community',
    progress: 347,
    maxProgress: 1000
  }
];

export const MOCK_LEADERBOARD: LeaderboardEntry[] = [
  {
    rank: 1,
    user: {
      id: 'user-2',
      name: 'Kofi Mensah',
      email: 'kofi@example.com',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      xp: 12450,
      level: 28,
      streak: 89,
      badges: [],
      joinedDate: '2024-01-01'
    },
    xp: 12450,
    streak: 89,
    country: 'Ghana 🇬🇭'
  },
  {
    rank: 2,
    user: {
      id: 'user-3',
      name: 'Zainab Mohammed',
      email: 'zainab@example.com',
      avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
      xp: 10850,
      level: 25,
      streak: 67,
      badges: [],
      joinedDate: '2024-02-01'
    },
    xp: 10850,
    streak: 67,
    country: 'Nigeria 🇳🇬'
  },
  {
    rank: 3,
    user: {
      id: 'user-4',
      name: 'Thandiwe Nkosi',
      email: 'thandiwe@example.com',
      avatar: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=400',
      xp: 9200,
      level: 22,
      streak: 45,
      badges: [],
      joinedDate: '2024-03-01'
    },
    xp: 9200,
    streak: 45,
    country: 'South Africa 🇿🇦'
  },
  {
    rank: 4,
    user: MOCK_USER,
    xp: 3450,
    streak: 23,
    country: 'Kenya 🇰🇪'
  }
];

export const MOCK_DAILY_CHALLENGES: DailyChallenge[] = [
  {
    id: 'challenge-1',
    title: 'Complete 3 Lessons',
    description: 'Finish any 3 lessons today',
    type: 'lesson',
    progress: 2,
    goal: 3,
    xpReward: 150,
    completed: false
  },
  {
    id: 'challenge-2',
    title: 'Practice 20 Minutes',
    description: 'Spend at least 20 minutes learning',
    type: 'practice',
    progress: 15,
    goal: 20,
    xpReward: 100,
    completed: false
  },
  {
    id: 'challenge-3',
    title: 'Perfect Quiz Score',
    description: 'Get 100% on any quiz',
    type: 'quiz',
    progress: 0,
    goal: 1,
    xpReward: 200,
    completed: false
  },
  {
    id: 'challenge-4',
    title: 'Keep Your Streak',
    description: 'Complete at least 1 lesson to maintain your streak',
    type: 'streak',
    progress: 1,
    goal: 1,
    xpReward: 50,
    completed: true
  }
];

export const MOCK_PROGRESS_DATA: ProgressData[] = [
  { date: '2024-11-22', xp: 250, lessons: 3, timeSpent: 45 },
  { date: '2024-11-23', xp: 300, lessons: 4, timeSpent: 52 },
  { date: '2024-11-24', xp: 180, lessons: 2, timeSpent: 30 },
  { date: '2024-11-25', xp: 400, lessons: 5, timeSpent: 68 },
  { date: '2024-11-26', xp: 350, lessons: 4, timeSpent: 55 },
  { date: '2024-11-27', xp: 280, lessons: 3, timeSpent: 42 },
  { date: '2024-11-28', xp: 320, lessons: 4, timeSpent: 50 }
];

export const MOCK_MAGAZINES: Magazine[] = [
  {
    id: 'mag-1',
    category: 'music',
    title: 'The Rise of Afrobeats: A Global Phenomenon',
    description: 'Explore how Afrobeats has conquered the world music scene and influenced pop culture globally.',
    author: 'Chimamanda Adichie',
    date: '2024-11-20',
    readTime: '8 min',
    thumbnail: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
    content: 'Full article content here...',
    likes: 1245,
    saved: false
  },
  {
    id: 'mag-2',
    category: 'history',
    title: 'Ancient African Kingdoms: The Mali Empire',
    description: 'Journey through the golden age of the Mali Empire and discover its lasting legacy.',
    author: 'Kwame Nkrumah Jr.',
    date: '2024-11-18',
    readTime: '12 min',
    thumbnail: 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=400',
    content: 'Full article content here...',
    likes: 892,
    saved: true
  },
  {
    id: 'mag-3',
    category: 'art',
    title: 'Contemporary African Art: Breaking Boundaries',
    description: 'Meet the artists redefining African art on the global stage.',
    author: 'Nnedi Okorafor',
    date: '2024-11-25',
    readTime: '10 min',
    thumbnail: 'https://images.unsplash.com/photo-1763256294121-303b83e7e767?w=400',
    content: 'Full article content here...',
    likes: 654,
    saved: false
  },
  {
    id: 'mag-4',
    category: 'stories',
    title: 'Folktales of the Savanna: Anansi the Spider',
    description: 'Rediscover the classic tales of Anansi and the wisdom they contain.',
    author: 'Yaa Gyasi',
    date: '2024-11-22',
    readTime: '6 min',
    thumbnail: 'https://images.unsplash.com/photo-1518978178014-e3b2d3b05876?w=400',
    content: 'Full article content here...',
    likes: 1567,
    saved: true
  },
  {
    id: 'mag-5',
    category: 'news',
    title: 'Tech Innovation in Africa: The Next Silicon Valley?',
    description: 'How African tech hubs are driving innovation and entrepreneurship.',
    author: 'Timnit Gebru',
    date: '2024-11-27',
    readTime: '7 min',
    thumbnail: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=400',
    content: 'Full article content here...',
    likes: 2103,
    saved: false
  }
];
