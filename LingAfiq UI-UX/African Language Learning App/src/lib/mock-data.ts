// Mock data for the African Language Learning App
import { 
  User, Language, Course, Lesson, Badge, Achievement, 
  ChatMessage, DirectMessage, MagazineArticle, Challenge, 
  ProgressData, LeaderboardEntry 
} from './types';

export const currentUser: User = {
  id: '1',
  name: 'Amara Okonkwo',
  email: 'amara@example.com',
  avatar: 'https://images.unsplash.com/photo-1688302529084-767fbc296565?w=400',
  level: 12,
  xp: 2850,
  streak: 7,
  joinDate: '2024-09-15',
  learningLanguages: ['swahili', 'yoruba'],
  nativeLanguage: 'English'
};

export const africanLanguages: Language[] = [
  {
    id: 'swahili',
    name: 'Swahili',
    nativeName: 'Kiswahili',
    flag: '🇰🇪',
    speakers: '200M',
    difficulty: 'beginner',
    region: 'East Africa'
  },
  {
    id: 'yoruba',
    name: 'Yoruba',
    nativeName: 'Èdè Yorùbá',
    flag: '🇳🇬',
    speakers: '45M',
    difficulty: 'intermediate',
    region: 'West Africa'
  },
  {
    id: 'zulu',
    name: 'Zulu',
    nativeName: 'isiZulu',
    flag: '🇿🇦',
    speakers: '27M',
    difficulty: 'intermediate',
    region: 'Southern Africa'
  },
  {
    id: 'amharic',
    name: 'Amharic',
    nativeName: 'አማርኛ',
    flag: '🇪🇹',
    speakers: '32M',
    difficulty: 'advanced',
    region: 'East Africa'
  },
  {
    id: 'hausa',
    name: 'Hausa',
    nativeName: 'Harshen Hausa',
    flag: '🇳🇬',
    speakers: '80M',
    difficulty: 'beginner',
    region: 'West Africa'
  },
  {
    id: 'igbo',
    name: 'Igbo',
    nativeName: 'Asụsụ Igbo',
    flag: '🇳🇬',
    speakers: '44M',
    difficulty: 'intermediate',
    region: 'West Africa'
  },
  {
    id: 'somali',
    name: 'Somali',
    nativeName: 'Af-Soomaali',
    flag: '🇸🇴',
    speakers: '21M',
    difficulty: 'intermediate',
    region: 'Horn of Africa'
  },
  {
    id: 'shona',
    name: 'Shona',
    nativeName: 'chiShona',
    flag: '🇿🇼',
    speakers: '14M',
    difficulty: 'beginner',
    region: 'Southern Africa'
  }
];

export const courses: Course[] = [
  {
    id: 'sw-101',
    languageId: 'swahili',
    title: 'Swahili Basics',
    description: 'Start your journey with essential Swahili phrases and greetings',
    level: 'beginner',
    lessonsCount: 20,
    progress: 65,
    estimatedTime: '4 weeks',
    image: 'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?w=400'
  },
  {
    id: 'yo-201',
    languageId: 'yoruba',
    title: 'Yoruba Conversations',
    description: 'Learn to hold everyday conversations in Yoruba',
    level: 'intermediate',
    lessonsCount: 15,
    progress: 30,
    estimatedTime: '3 weeks',
    image: 'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=400'
  },
  {
    id: 'sw-102',
    languageId: 'swahili',
    title: 'Swahili Grammar',
    description: 'Master the grammar foundations of Swahili',
    level: 'beginner',
    lessonsCount: 18,
    progress: 10,
    estimatedTime: '5 weeks',
    image: 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=400'
  }
];

export const lessons: Lesson[] = [
  {
    id: 'l1',
    courseId: 'sw-101',
    title: 'Greetings and Introductions',
    type: 'conversation',
    duration: 15,
    completed: true,
    locked: false,
    order: 1
  },
  {
    id: 'l2',
    courseId: 'sw-101',
    title: 'Common Phrases',
    type: 'vocabulary',
    duration: 12,
    completed: true,
    locked: false,
    order: 2
  },
  {
    id: 'l3',
    courseId: 'sw-101',
    title: 'Numbers and Counting',
    type: 'vocabulary',
    duration: 10,
    completed: false,
    locked: false,
    order: 3
  },
  {
    id: 'l4',
    courseId: 'sw-101',
    title: 'Family and Relationships',
    type: 'vocabulary',
    duration: 15,
    completed: false,
    locked: true,
    order: 4
  }
];

export const badges: Badge[] = [
  {
    id: 'b1',
    name: 'First Steps',
    description: 'Complete your first lesson',
    icon: '🌟',
    earned: true,
    earnedDate: '2024-11-20',
    rarity: 'common'
  },
  {
    id: 'b2',
    name: 'Week Warrior',
    description: 'Maintain a 7-day streak',
    icon: '🔥',
    earned: true,
    earnedDate: '2024-11-28',
    rarity: 'rare'
  },
  {
    id: 'b3',
    name: 'Language Master',
    description: 'Complete an entire course',
    icon: '👑',
    earned: false,
    rarity: 'legendary'
  },
  {
    id: 'b4',
    name: 'Perfect Score',
    description: 'Score 100% on a quiz',
    icon: '💯',
    earned: true,
    earnedDate: '2024-11-25',
    rarity: 'epic'
  },
  {
    id: 'b5',
    name: 'Night Owl',
    description: 'Complete a lesson after 10 PM',
    icon: '🦉',
    earned: false,
    rarity: 'common'
  },
  {
    id: 'b6',
    name: 'Social Butterfly',
    description: 'Send 50 messages in community chat',
    icon: '🦋',
    earned: false,
    rarity: 'rare'
  }
];

export const achievements: Achievement[] = [
  {
    id: 'a1',
    type: 'trophy',
    name: 'Bronze Trophy',
    description: 'Reach Level 10',
    icon: '🥉',
    earned: true,
    progress: 10,
    target: 10
  },
  {
    id: 'a2',
    type: 'trophy',
    name: 'Silver Trophy',
    description: 'Reach Level 25',
    icon: '🥈',
    earned: false,
    progress: 12,
    target: 25
  },
  {
    id: 'a3',
    type: 'medal',
    name: 'Speed Demon',
    description: 'Complete 10 speed challenges',
    icon: '⚡',
    earned: false,
    progress: 6,
    target: 10
  }
];

export const communityMessages: ChatMessage[] = [
  {
    id: 'cm1',
    userId: '2',
    userName: 'Kwame Mensah',
    userAvatar: 'https://images.unsplash.com/photo-1612214070782-b97cad77ca54?w=100',
    message: 'Just finished my first week of Swahili! Feeling great! 🎉',
    timestamp: '2024-11-28T10:30:00',
    isOwn: false
  },
  {
    id: 'cm2',
    userId: '3',
    userName: 'Zara Ibrahim',
    userAvatar: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=100',
    message: 'Does anyone have tips for remembering Yoruba tones?',
    timestamp: '2024-11-28T10:32:00',
    isOwn: false
  },
  {
    id: 'cm3',
    userId: '1',
    userName: 'Amara Okonkwo',
    message: 'Try practicing with music! It helped me a lot 🎵',
    timestamp: '2024-11-28T10:35:00',
    isOwn: true
  },
  {
    id: 'cm4',
    userId: '4',
    userName: 'Abeni Oladele',
    userAvatar: 'https://images.unsplash.com/photo-1509967419530-da38b4704bc6?w=100',
    message: 'That\'s a great idea! I also recommend watching movies with subtitles',
    timestamp: '2024-11-28T10:40:00',
    isOwn: false
  }
];

export const directMessages: DirectMessage[] = [
  {
    id: 'dm1',
    participantId: '2',
    participantName: 'Kwame Mensah',
    participantAvatar: 'https://images.unsplash.com/photo-1612214070782-b97cad77ca54?w=100',
    lastMessage: 'Thanks for the study tips!',
    timestamp: '2024-11-28T09:15:00',
    unread: true,
    unreadCount: 2
  },
  {
    id: 'dm2',
    participantId: '3',
    participantName: 'Zara Ibrahim',
    participantAvatar: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=100',
    lastMessage: 'Want to practice together tomorrow?',
    timestamp: '2024-11-27T18:30:00',
    unread: false,
    unreadCount: 0
  },
  {
    id: 'dm3',
    participantId: '4',
    participantName: 'Abeni Oladele',
    participantAvatar: 'https://images.unsplash.com/photo-1509967419530-da38b4704bc6?w=100',
    lastMessage: 'See you in the study group!',
    timestamp: '2024-11-26T14:20:00',
    unread: false,
    unreadCount: 0
  }
];

export const magazineArticles: MagazineArticle[] = [
  {
    id: 'ma1',
    category: 'music',
    title: 'The Rise of Afrobeats: A Global Phenomenon',
    excerpt: 'How African music is conquering the world stage',
    content: 'Full article content here...',
    author: 'Chioma Adebayo',
    publishDate: '2024-11-25',
    readTime: '5 min',
    imageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600',
    tags: ['Music', 'Culture', 'Entertainment']
  },
  {
    id: 'ma2',
    category: 'history',
    title: 'Ancient African Kingdoms: The Mali Empire',
    excerpt: 'Exploring the golden age of West African civilization',
    content: 'Full article content here...',
    author: 'Dr. Kofi Asante',
    publishDate: '2024-11-24',
    readTime: '8 min',
    imageUrl: 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=600',
    tags: ['History', 'Education', 'Culture']
  },
  {
    id: 'ma3',
    category: 'art',
    title: 'Contemporary African Art: Breaking Boundaries',
    excerpt: 'Meet the artists redefining African contemporary art',
    content: 'Full article content here...',
    author: 'Thandiwe Nkosi',
    publishDate: '2024-11-23',
    readTime: '6 min',
    imageUrl: 'https://images.unsplash.com/photo-1603703182693-51a19941fa59?w=600',
    tags: ['Art', 'Culture', 'Modern']
  },
  {
    id: 'ma4',
    category: 'stories',
    title: 'Folk Tales: Anansi the Spider',
    excerpt: 'The West African trickster god who taught valuable lessons',
    content: 'Full article content here...',
    author: 'Ama Boateng',
    publishDate: '2024-11-22',
    readTime: '4 min',
    imageUrl: 'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?w=600',
    tags: ['Stories', 'Folklore', 'Culture']
  },
  {
    id: 'ma5',
    category: 'news',
    title: 'African Tech Startups Attract Record Investment',
    excerpt: 'Innovation hubs across the continent are booming',
    content: 'Full article content here...',
    author: 'Segun Adeyemi',
    publishDate: '2024-11-28',
    readTime: '7 min',
    imageUrl: 'https://images.unsplash.com/photo-1488229297570-58520851e868?w=600',
    tags: ['News', 'Technology', 'Business']
  }
];

export const challenges: Challenge[] = [
  {
    id: 'ch1',
    title: 'Daily Streak',
    description: 'Complete at least one lesson today',
    type: 'daily',
    progress: 1,
    target: 1,
    reward: { xp: 50 },
    expiresAt: '2024-11-29T23:59:59'
  },
  {
    id: 'ch2',
    title: 'Vocabulary Master',
    description: 'Learn 20 new words this week',
    type: 'weekly',
    progress: 14,
    target: 20,
    reward: { xp: 200, badge: 'Word Wizard' },
    expiresAt: '2024-12-01T23:59:59'
  },
  {
    id: 'ch3',
    title: 'Perfect Practice',
    description: 'Score 100% on 3 quizzes',
    type: 'daily',
    progress: 1,
    target: 3,
    reward: { xp: 100 }
  }
];

export const progressData: ProgressData[] = [
  { date: '2024-11-22', lessonsCompleted: 2, xpEarned: 150, timeSpent: 30, accuracy: 85 },
  { date: '2024-11-23', lessonsCompleted: 3, xpEarned: 220, timeSpent: 45, accuracy: 92 },
  { date: '2024-11-24', lessonsCompleted: 1, xpEarned: 80, timeSpent: 20, accuracy: 78 },
  { date: '2024-11-25', lessonsCompleted: 4, xpEarned: 300, timeSpent: 60, accuracy: 95 },
  { date: '2024-11-26', lessonsCompleted: 2, xpEarned: 180, timeSpent: 35, accuracy: 88 },
  { date: '2024-11-27', lessonsCompleted: 3, xpEarned: 240, timeSpent: 50, accuracy: 90 },
  { date: '2024-11-28', lessonsCompleted: 5, xpEarned: 400, timeSpent: 75, accuracy: 97 }
];

export const leaderboard: LeaderboardEntry[] = [
  {
    rank: 1,
    userId: '5',
    userName: 'Chinwe Okoro',
    userAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100',
    xp: 5200,
    streak: 45,
    country: '🇳🇬',
    isCurrentUser: false
  },
  {
    rank: 2,
    userId: '6',
    userName: 'Tendai Moyo',
    userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
    xp: 4850,
    streak: 38,
    country: '🇿🇼',
    isCurrentUser: false
  },
  {
    rank: 3,
    userId: '7',
    userName: 'Fatima Hassan',
    userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
    xp: 4320,
    streak: 32,
    country: '🇪🇬',
    isCurrentUser: false
  },
  {
    rank: 12,
    userId: '1',
    userName: 'Amara Okonkwo',
    userAvatar: 'https://images.unsplash.com/photo-1688302529084-767fbc296565?w=100',
    xp: 2850,
    streak: 7,
    country: '🇳🇬',
    isCurrentUser: true
  }
];

export const quizQuestions = [
  {
    id: 'q1',
    type: 'multiple-choice' as const,
    question: 'How do you say "Hello" in Swahili?',
    options: ['Habari', 'Jambo', 'Mambo', 'Hujambo'],
    correctAnswer: 'Jambo',
    explanation: 'Jambo is the most common greeting in Swahili, used at any time of day.'
  },
  {
    id: 'q2',
    type: 'multiple-choice' as const,
    question: 'What does "Asante" mean in Swahili?',
    options: ['Please', 'Thank you', 'Sorry', 'Welcome'],
    correctAnswer: 'Thank you',
    explanation: 'Asante means "Thank you" in Swahili. Asante sana means "Thank you very much".'
  },
  {
    id: 'q3',
    type: 'fill-blank' as const,
    question: 'Complete the phrase: "Karibu ___" (You\'re welcome)',
    correctAnswer: 'sana',
    explanation: '"Karibu sana" is a warm way to say "You\'re very welcome" in Swahili.'
  }
];
