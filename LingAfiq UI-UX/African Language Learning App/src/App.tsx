import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import OnboardingFlow from './components/OnboardingFlow';
import { SignInScreen, SignUpScreen } from './components/AuthScreens';
import Dashboard from './components/Dashboard';
import LanguageSelection from './components/LanguageSelection';
import ProficiencySelection from './components/ProficiencySelection';
import CourseOverview from './components/CourseOverview';
import LessonScreens from './components/LessonScreens';
import QuizScreenComponent from './components/QuizScreenComponent';
import AIChatScreens from './components/AIChatScreens';
import LogoutDialogComponent from './components/LogoutDialogComponent';
import {
  LanguageGames,
  UserProfile,
  SettingsScreen,
  GlobalRanking,
  ProgressTracking,
  DailyChallenges,
  IncentivesScreen,
  CommunityChatRoom,
  DirectMessaging,
  MagazineHub,
  MediaImport,
} from './components/RemainingScreens';
import { Card } from './components/ui/card';
import {
  Home,
  BookOpen,
  MessageCircle,
  User,
  Trophy,
  Newspaper,
  BarChart3,
  Target,
  Award,
  Users,
  Mail,
  Upload,
  Settings,
} from 'lucide-react';
import { Toaster } from './components/ui/sonner';

type Screen = 
  | 'onboarding'
  | 'signin'
  | 'signup'
  | 'language-select'
  | 'proficiency'
  | 'dashboard'
  | 'course'
  | 'lesson'
  | 'quiz'
  | 'ai-chat'
  | 'games'
  | 'profile'
  | 'settings'
  | 'ranking'
  | 'progress'
  | 'daily-challenge'
  | 'incentives'
  | 'community'
  | 'messages'
  | 'magazine'
  | 'media-import';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<Screen>('onboarding');
  const [showLogoutDialog, setShowLogoutDialog] = useState(false);
  const [selectedLanguage, setSelectedLanguage] = useState('Swahili');
  const [selectedMagazineCategory, setSelectedMagazineCategory] = useState<string | null>(null);

  // Main navigation items
  const mainNavItems = [
    { id: 'dashboard', icon: Home, label: 'Home' },
    { id: 'course', icon: BookOpen, label: 'Course' },
    { id: 'ai-chat', icon: MessageCircle, label: 'AI Chat' },
    { id: 'magazine', icon: Newspaper, label: 'Culture' },
    { id: 'profile', icon: User, label: 'Profile' },
  ];

  const handleNavigate = (screen: string) => {
    setCurrentScreen(screen as Screen);
  };

  const handleLogout = () => {
    setShowLogoutDialog(false);
    setCurrentScreen('signin');
  };

  const renderScreen = () => {
    switch (currentScreen) {
      case 'onboarding':
        return <OnboardingFlow onComplete={() => setCurrentScreen('signin')} />;
      
      case 'signin':
        return <SignInScreen onSignIn={() => setCurrentScreen('language-select')} />;
      
      case 'signup':
        return <SignUpScreen onSignIn={() => setCurrentScreen('language-select')} />;
      
      case 'language-select':
        return (
          <LanguageSelection
            onSelect={(lang) => {
              setSelectedLanguage(lang.name);
              setCurrentScreen('proficiency');
            }}
          />
        );
      
      case 'proficiency':
        return (
          <ProficiencySelection
            language={selectedLanguage}
            onSelect={() => setCurrentScreen('dashboard')}
            onBack={() => setCurrentScreen('language-select')}
          />
        );
      
      case 'dashboard':
        return <Dashboard onNavigate={handleNavigate} />;
      
      case 'course':
        return (
          <CourseOverview
            language={selectedLanguage}
            onStartLesson={(lessonId) => setCurrentScreen('lesson')}
            onBack={() => setCurrentScreen('dashboard')}
          />
        );
      
      case 'lesson':
        return (
          <LessonScreens
            onComplete={() => setCurrentScreen('quiz')}
            onBack={() => setCurrentScreen('course')}
          />
        );
      
      case 'quiz':
        return (
          <QuizScreenComponent
            onComplete={() => setCurrentScreen('course')}
            onBack={() => setCurrentScreen('course')}
          />
        );
      
      case 'ai-chat':
        return <AIChatScreens onBack={() => setCurrentScreen('dashboard')} />;
      
      case 'games':
        return <LanguageGames onBack={() => setCurrentScreen('dashboard')} />;
      
      case 'profile':
        return (
          <UserProfile
            onBack={() => setCurrentScreen('dashboard')}
            onLogout={() => setShowLogoutDialog(true)}
          />
        );
      
      case 'settings':
        return <SettingsScreen onBack={() => setCurrentScreen('profile')} />;
      
      case 'ranking':
        return <GlobalRanking onBack={() => setCurrentScreen('dashboard')} />;
      
      case 'progress':
        return <ProgressTracking onBack={() => setCurrentScreen('dashboard')} />;
      
      case 'daily-challenge':
        return <DailyChallenges onBack={() => setCurrentScreen('dashboard')} />;
      
      case 'incentives':
        return <IncentivesScreen onBack={() => setCurrentScreen('dashboard')} />;
      
      case 'community':
        return <CommunityChatRoom onBack={() => setCurrentScreen('dashboard')} />;
      
      case 'messages':
        return <DirectMessaging onBack={() => setCurrentScreen('dashboard')} />;
      
      case 'magazine':
        if (selectedMagazineCategory) {
          return (
            <MagazineArticles
              category={selectedMagazineCategory}
              onBack={() => setSelectedMagazineCategory(null)}
            />
          );
        }
        return (
          <MagazineHub
            onBack={() => setCurrentScreen('dashboard')}
            onSelectCategory={(cat) => setSelectedMagazineCategory(cat)}
          />
        );
      
      case 'media-import':
        return <MediaImport onBack={() => setCurrentScreen('magazine')} />;
      
      default:
        return <Dashboard onNavigate={handleNavigate} />;
    }
  };

  // Screens that should show bottom navigation
  const screensWithNav = [
    'dashboard',
    'course',
    'ai-chat',
    'magazine',
    'profile',
    'games',
    'ranking',
    'progress',
    'daily-challenge',
    'incentives',
    'community',
    'messages',
    'settings',
  ];

  const showBottomNav = screensWithNav.includes(currentScreen);

  return (
    <div className="relative min-h-screen bg-background">
      {/* Main Content */}
      <AnimatePresence mode="wait">
        <motion.div
          key={currentScreen}
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.2 }}
          className="pb-safe"
        >
          {renderScreen()}
        </motion.div>
      </AnimatePresence>

      {/* Bottom Navigation */}
      {showBottomNav && (
        <nav className="fixed bottom-0 left-0 right-0 z-40 bg-card border-t border-border shadow-lg pb-safe">
          <div className="max-w-md mx-auto px-2 py-2">
            <div className="flex items-center justify-around">
              {mainNavItems.map((item) => {
                const Icon = item.icon;
                const isActive = currentScreen === item.id;
                
                return (
                  <motion.button
                    key={item.id}
                    onClick={() => handleNavigate(item.id)}
                    whileTap={{ scale: 0.9 }}
                    className={`flex flex-col items-center gap-1 px-3 py-2 rounded-xl transition-all ${
                      isActive
                        ? 'text-primary'
                        : 'text-muted-foreground hover:text-foreground'
                    }`}
                  >
                    <div className={`relative ${isActive ? 'scale-110' : ''} transition-transform`}>
                      <Icon className="w-6 h-6" />
                      {isActive && (
                        <motion.div
                          layoutId="nav-indicator"
                          className="absolute -bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 bg-primary rounded-full"
                        />
                      )}
                    </div>
                    <span className={`text-xs ${isActive ? '' : 'text-muted-foreground'}`}>
                      {item.label}
                    </span>
                  </motion.button>
                );
              })}
            </div>
          </div>
        </nav>
      )}

      {/* Quick Actions FAB - Only on Dashboard */}
      {currentScreen === 'dashboard' && (
        <div className="fixed bottom-24 right-6 z-30">
          <div className="flex flex-col gap-3">
            <motion.button
              whileTap={{ scale: 0.9 }}
              onClick={() => setCurrentScreen('games')}
              className="w-14 h-14 rounded-full bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] shadow-lg flex items-center justify-center text-white hover:shadow-xl transition-all"
            >
              <Trophy className="w-6 h-6" />
            </motion.button>
            <motion.button
              whileTap={{ scale: 0.9 }}
              onClick={() => setCurrentScreen('daily-challenge')}
              className="w-14 h-14 rounded-full bg-gradient-to-br from-[#007A3D] to-[#00A8E8] shadow-lg flex items-center justify-center text-white hover:shadow-xl transition-all"
            >
              <Target className="w-6 h-6" />
            </motion.button>
          </div>
        </div>
      )}

      {/* Logout Dialog */}
      <LogoutDialogComponent
        open={showLogoutDialog}
        onOpenChange={setShowLogoutDialog}
        onConfirm={handleLogout}
      />

      {/* Toast Notifications */}
      <Toaster />
    </div>
  );
}

// Magazine Articles Component
function MagazineArticles({ category, onBack }: { category: string; onBack: () => void }) {
  const articles = [
    {
      title: 'The Evolution of Afrobeat Music',
      excerpt: 'Explore the rich history and modern transformation of Afrobeat...',
      image: 'https://images.unsplash.com/photo-1655902586913-e81bce3adeec',
      readTime: '5 min read',
    },
    {
      title: 'Traditional African Art Forms',
      excerpt: 'Discover the timeless beauty of African artistic traditions...',
      image: 'https://images.unsplash.com/photo-1757009400493-509e7b48c95d',
      readTime: '7 min read',
    },
    {
      title: 'Stories from the Sahara',
      excerpt: 'Journey through ancient tales passed down generations...',
      image: 'https://images.unsplash.com/photo-1586627789099-e9d422d1c5cb',
      readTime: '10 min read',
    },
  ];

  return (
    <div className="min-h-screen bg-background pb-24">
      <div className="relative bg-gradient-to-br from-[#FF6B35] to-[#7B2CBF] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="relative">
          <button
            onClick={onBack}
            className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full p-2"
          >
            ← Back
          </button>
          <div className="text-center text-white pt-8">
            <h1 className="text-3xl mb-2 capitalize">{category}</h1>
            <p className="opacity-90">Latest articles & stories</p>
          </div>
        </div>
      </div>

      <div className="px-6 py-6 space-y-4">
        {articles.map((article, i) => (
          <Card key={i} className="overflow-hidden rounded-2xl shadow-lg border-0 cursor-pointer hover:shadow-xl transition-all">
            <div className="h-48 bg-gradient-to-br from-primary/10 to-accent/10 relative overflow-hidden">
              <img
                src={article.image}
                alt={article.title}
                className="w-full h-full object-cover opacity-80"
              />
            </div>
            <div className="p-5">
              <h3 className="mb-2">{article.title}</h3>
              <p className="text-sm text-muted-foreground mb-3">{article.excerpt}</p>
              <div className="flex items-center justify-between">
                <span className="text-xs text-muted-foreground">{article.readTime}</span>
                <button className="text-sm text-primary">Read More →</button>
              </div>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
