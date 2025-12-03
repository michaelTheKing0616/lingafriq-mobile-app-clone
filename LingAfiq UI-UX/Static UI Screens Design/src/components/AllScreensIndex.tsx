import React from 'react';
import { HomeScreen } from './HomeScreen';
import { AIChatScreen } from './AIChatScreen';
import { TakeQuizScreen } from './TakeQuizScreen';
import { DailyGoalsScreen } from './DailyGoalsScreen';
import { AchievementsScreen } from './AchievementsScreen';
import { SplashScreen } from './SplashScreen';
import { OnboardingScreen } from './OnboardingScreen';
import { LoginScreen } from './LoginScreen';
import { SignUpScreen } from './SignUpScreen';
import { ForgotPasswordScreen } from './ForgotPasswordScreen';
import { ModernOnboardingScreen } from './ModernOnboardingScreen';
import { MainTabsScreen } from './MainTabsScreen';
import { LanguageDetailScreen } from './LanguageDetailScreen';
import { LessonsListScreen } from './LessonsListScreen';

const screens = [
  { id: 1, name: 'Splash Screen', component: SplashScreen, category: 'Auth' },
  { id: 2, name: 'Login Screen', component: LoginScreen, category: 'Auth' },
  { id: 3, name: 'Sign Up Screen', component: SignUpScreen, category: 'Auth' },
  { id: 4, name: 'Forgot Password', component: ForgotPasswordScreen, category: 'Auth' },
  { id: 5, name: 'Onboarding (Kijiji)', component: OnboardingScreen, category: 'Auth' },
  { id: 6, name: 'Modern Onboarding', component: ModernOnboardingScreen, category: 'Auth' },
  { id: 7, name: 'Main Tabs', component: MainTabsScreen, category: 'Navigation' },
  { id: 8, name: 'Home Dashboard', component: HomeScreen, category: 'Home' },
  { id: 9, name: 'Language Detail', component: LanguageDetailScreen, category: 'Home' },
  { id: 10, name: 'Lessons List', component: LessonsListScreen, category: 'Home' },
  { id: 11, name: 'Take Quiz', component: TakeQuizScreen, category: 'Learning' },
  { id: 12, name: 'AI Chat (Polie)', component: AIChatScreen, category: 'Chat' },
  { id: 13, name: 'Daily Goals', component: DailyGoalsScreen, category: 'Progress' },
  { id: 14, name: 'Achievements', component: AchievementsScreen, category: 'Progress' },
];

export function AllScreensIndex() {
  const [selectedScreen, setSelectedScreen] = React.useState<number | null>(null);
  
  const categories = Array.from(new Set(screens.map(s => s.category)));
  
  if (selectedScreen !== null) {
    const screen = screens.find(s => s.id === selectedScreen);
    if (screen) {
      const ScreenComponent = screen.component;
      return (
        <div className="relative h-screen">
          <button
            onClick={() => setSelectedScreen(null)}
            className="absolute top-4 right-4 z-50 bg-white/90 backdrop-blur-sm text-gray-900 px-4 py-2 rounded-lg shadow-lg hover:bg-white transition-colors"
          >
            ← Back to Index
          </button>
          <ScreenComponent />
        </div>
      );
    }
  }
  
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#007A3D] via-[#005a2d] to-black text-white">
      {/* Header */}
      <div className="px-6 py-12 text-center">
        <div className="w-24 h-24 bg-gradient-to-br from-[#FCD116] to-[#FF6B35] rounded-full flex items-center justify-center shadow-2xl shadow-[#FCD116]/30 mb-6 mx-auto">
          <span className="text-6xl">🌍</span>
        </div>
        <h1 className="text-5xl mb-3">LingAfriq</h1>
        <p className="text-xl text-white/80 mb-2">Complete UI Screen Collection</p>
        <p className="text-white/60">{screens.length} Screens Available</p>
      </div>

      {/* Screen Grid */}
      <div className="px-6 pb-12">
        {categories.map((category) => (
          <div key={category} className="mb-8">
            <h2 className="text-2xl text-[#FCD116] mb-4">{category}</h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {screens
                .filter((s) => s.category === category)
                .map((screen) => (
                  <button
                    key={screen.id}
                    onClick={() => setSelectedScreen(screen.id)}
                    className="bg-white/10 backdrop-blur-sm hover:bg-white/20 rounded-2xl p-6 text-left transition-all hover:scale-105 hover:shadow-xl group"
                  >
                    <div className="flex items-center justify-between mb-3">
                      <span className="text-3xl">📱</span>
                      <span className="text-xs text-white/60 bg-white/10 px-2 py-1 rounded-full">
                        #{screen.id}
                      </span>
                    </div>
                    <h3 className="text-white text-lg mb-2 group-hover:text-[#FCD116] transition-colors">
                      {screen.name}
                    </h3>
                    <p className="text-white/60 text-sm">Tap to view →</p>
                  </button>
                ))}
            </div>
          </div>
        ))}

        {/* Coming Soon Section */}
        <div className="mt-12 bg-white/5 backdrop-blur-sm rounded-2xl p-8 text-center border-2 border-dashed border-white/20">
          <div className="text-5xl mb-4">🚧</div>
          <h3 className="text-2xl mb-2">More Screens Coming Soon</h3>
          <p className="text-white/70">
            Additional 42+ screens including Games, Chat, Progress Tracking, Settings, and more...
          </p>
        </div>
      </div>
    </div>
  );
}
