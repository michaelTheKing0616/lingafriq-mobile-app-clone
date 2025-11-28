// Type definitions for the African Language Learning App

export type Language = {
  id: string;
  name: string;
  nativeName: string;
  flag: string;
  speakers: string;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  region: string;
};

export type ProficiencyLevel = 'beginner' | 'intermediate' | 'expert';

export type User = {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  xp: number;
  level: number;
  streak: number;
  badges: Badge[];
  currentLanguage?: Language;
  proficiency?: ProficiencyLevel;
  joinedDate: string;
};

export type Course = {
  id: string;
  languageId: string;
  title: string;
  description: string;
  level: ProficiencyLevel;
  lessons: number;
  duration: string;
  progress: number;
  thumbnail?: string;
};

export type Lesson = {
  id: string;
  courseId: string;
  title: string;
  description: string;
  type: 'vocabulary' | 'grammar' | 'conversation' | 'culture';
  duration: number;
  completed: boolean;
  locked: boolean;
  xpReward: number;
};

export type Question = {
  id: string;
  type: 'multiple-choice' | 'fill-blank' | 'translation' | 'pronunciation' | 'matching';
  question: string;
  options?: string[];
  correctAnswer: string | string[];
  audioUrl?: string;
  imageUrl?: string;
  explanation?: string;
};

export type Quiz = {
  id: string;
  lessonId: string;
  title: string;
  questions: Question[];
  timeLimit?: number;
  xpReward: number;
};

export type ChatMessage = {
  id: string;
  role: 'user' | 'ai';
  content: string;
  translation?: string;
  timestamp: Date;
  audioUrl?: string;
};

export type AIChatMode = 'translator' | 'tutor';

export type Badge = {
  id: string;
  name: string;
  description: string;
  icon: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
  dateEarned?: Date;
};

export type Trophy = {
  id: string;
  name: string;
  description: string;
  icon: string;
  requirement: string;
  progress: number;
  maxProgress: number;
};

export type LeaderboardEntry = {
  rank: number;
  user: User;
  xp: number;
  streak: number;
  country: string;
};

export type DailyChallenge = {
  id: string;
  title: string;
  description: string;
  type: 'lesson' | 'quiz' | 'practice' | 'streak';
  progress: number;
  goal: number;
  xpReward: number;
  completed: boolean;
};

export type ProgressData = {
  date: string;
  xp: number;
  lessons: number;
  timeSpent: number;
};

export type CommunityMessage = {
  id: string;
  user: User;
  content: string;
  timestamp: Date;
  likes: number;
  replies: number;
};

export type DirectMessage = {
  id: string;
  senderId: string;
  receiverId: string;
  content: string;
  timestamp: Date;
  read: boolean;
  type: 'text' | 'image' | 'audio';
  mediaUrl?: string;
};

export type Conversation = {
  id: string;
  otherUser: User;
  lastMessage: DirectMessage;
  unreadCount: number;
};

export type Magazine = {
  id: string;
  category: 'music' | 'stories' | 'news' | 'history' | 'art';
  title: string;
  description: string;
  author: string;
  date: string;
  readTime: string;
  thumbnail: string;
  content: string;
  likes: number;
  saved: boolean;
};

export type GameType = 'word-match' | 'pronunciation' | 'speed-challenge';

export type GameSession = {
  id: string;
  type: GameType;
  score: number;
  correctAnswers: number;
  totalQuestions: number;
  timeElapsed: number;
  xpEarned: number;
};

export type Screen =
  | 'onboarding'
  | 'sign-in'
  | 'sign-up'
  | 'home'
  | 'language-select'
  | 'proficiency'
  | 'course-overview'
  | 'lesson'
  | 'quiz'
  | 'ai-chat-mode-select'
  | 'ai-chat'
  | 'games'
  | 'game-play'
  | 'profile'
  | 'settings'
  | 'leaderboard'
  | 'progress'
  | 'daily-challenges'
  | 'incentives'
  | 'community-chat'
  | 'direct-messages'
  | 'dm-conversation'
  | 'magazines'
  | 'magazine-reader'
  | 'media-import';
