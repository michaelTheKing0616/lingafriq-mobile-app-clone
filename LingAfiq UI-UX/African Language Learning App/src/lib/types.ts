// Type definitions for the African Language Learning App

export type Screen = 
  | 'splash'
  | 'onboarding'
  | 'signin'
  | 'signup'
  | 'home'
  | 'language-select'
  | 'proficiency'
  | 'course-overview'
  | 'lesson'
  | 'quiz'
  | 'ai-chat-select'
  | 'ai-translator'
  | 'ai-tutor'
  | 'games-menu'
  | 'game-word-match'
  | 'game-pronunciation'
  | 'game-speed'
  | 'profile'
  | 'settings'
  | 'ranking'
  | 'progress'
  | 'challenges'
  | 'incentives'
  | 'community-chat'
  | 'direct-messages'
  | 'magazine-home'
  | 'magazine-music'
  | 'magazine-stories'
  | 'magazine-news'
  | 'magazine-history'
  | 'magazine-art'
  | 'media-import';

export interface User {
  id: string;
  name: string;
  email: string;
  avatar?: string;
  level: number;
  xp: number;
  streak: number;
  joinDate: string;
  learningLanguages: string[];
  nativeLanguage: string;
}

export interface Language {
  id: string;
  name: string;
  nativeName: string;
  flag: string;
  speakers: string;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  region: string;
}

export type Proficiency = 'beginner' | 'intermediate' | 'expert';

export interface Course {
  id: string;
  languageId: string;
  title: string;
  description: string;
  level: Proficiency;
  lessonsCount: number;
  progress: number;
  estimatedTime: string;
  image?: string;
}

export interface Lesson {
  id: string;
  courseId: string;
  title: string;
  type: 'vocabulary' | 'grammar' | 'conversation' | 'culture' | 'pronunciation';
  duration: number;
  completed: boolean;
  locked: boolean;
  order: number;
}

export interface Question {
  id: string;
  type: 'multiple-choice' | 'fill-blank' | 'matching' | 'speaking' | 'listening';
  question: string;
  options?: string[];
  correctAnswer: string;
  explanation?: string;
  audioUrl?: string;
  imageUrl?: string;
}

export interface Badge {
  id: string;
  name: string;
  description: string;
  icon: string;
  earned: boolean;
  earnedDate?: string;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
}

export interface Achievement {
  id: string;
  type: 'badge' | 'trophy' | 'medal';
  name: string;
  description: string;
  icon: string;
  earned: boolean;
  progress?: number;
  target?: number;
}

export interface ChatMessage {
  id: string;
  userId: string;
  userName: string;
  userAvatar?: string;
  message: string;
  timestamp: string;
  isOwn: boolean;
}

export interface DirectMessage {
  id: string;
  participantId: string;
  participantName: string;
  participantAvatar?: string;
  lastMessage: string;
  timestamp: string;
  unread: boolean;
  unreadCount: number;
}

export interface MagazineArticle {
  id: string;
  category: 'music' | 'stories' | 'news' | 'history' | 'art';
  title: string;
  excerpt: string;
  content: string;
  author: string;
  publishDate: string;
  readTime: string;
  imageUrl?: string;
  tags: string[];
}

export interface Challenge {
  id: string;
  title: string;
  description: string;
  type: 'daily' | 'weekly' | 'special';
  progress: number;
  target: number;
  reward: {
    xp: number;
    badge?: string;
  };
  expiresAt?: string;
}

export interface ProgressData {
  date: string;
  lessonsCompleted: number;
  xpEarned: number;
  timeSpent: number;
  accuracy: number;
}

export interface LeaderboardEntry {
  rank: number;
  userId: string;
  userName: string;
  userAvatar?: string;
  xp: number;
  streak: number;
  country: string;
  isCurrentUser: boolean;
}
