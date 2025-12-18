import React from 'react';
import { SplashScreen } from './SplashScreen';
import { LoginScreen } from './LoginScreen';
import { SignUpScreen } from './SignUpScreen';
import { ForgotPasswordScreen } from './ForgotPasswordScreen';
import { OnboardingScreen } from './OnboardingScreen';
import { ModernOnboardingScreen } from './ModernOnboardingScreen';
import { MainTabsScreen } from './MainTabsScreen';
import { HomeScreen } from './HomeScreen';
import { LanguageDetailScreen } from './LanguageDetailScreen';
import { LessonsListScreen } from './LessonsListScreen';
import { LessonDetailScreen } from './LessonDetailScreen';
import { QuizSelectionMapScreen } from './QuizSelectionMapScreen';
import { TakeQuizScreen } from './TakeQuizScreen';
import { StandingsScreen } from './StandingsScreen';
import { AchievementsScreen } from './AchievementsScreen';
import { DailyGoalsScreen } from './DailyGoalsScreen';
import { AIChatSelectScreen } from './AIChatSelectScreen';
import { AIChatScreen } from './AIChatScreen';
import { GameSelectionScreen } from './GameSelectionScreen';
import { WordMatchGameScreen } from './WordMatchGameScreen';
import { SpeedChallengeGameScreen } from './SpeedChallengeGameScreen';
import { PronunciationGameScreen } from './PronunciationGameScreen';
import { GameResultsScreen } from './GameResultsScreen';
import { ProgressDashboardScreen } from './ProgressDashboardScreen';
import { GlobalProgressScreen } from './GlobalProgressScreen';
import { UserConnectionsScreen } from './UserConnectionsScreen';
import { ProfileEditScreen } from './ProfileEditScreen';
import { SettingsScreen } from './SettingsScreen';
import { CultureMagazineScreen } from './CultureMagazineScreen';
import { CoursesTabScreen } from './CoursesTabScreen';
import { AboutUsScreen } from './AboutUsScreen';
import { ChangePasswordScreen } from './ChangePasswordScreen';
import { GlobalChatScreen } from './GlobalChatScreen';
import { PrivateChatListScreen } from './PrivateChatListScreen';
import { PrivateChatScreen } from './PrivateChatScreen';

export function AllScreensIndex() {
  const [selectedScreen, setSelectedScreen] = React.useState('splash');

  const screens = [
    { id: 'splash', name: '🌍 Splash Screen', component: SplashScreen, category: 'Auth' },
    { id: 'login', name: '🔐 Login', component: LoginScreen, category: 'Auth' },
    { id: 'signup', name: '📝 Sign Up', component: SignUpScreen, category: 'Auth' },
    { id: 'forgot', name: '🔑 Forgot Password', component: ForgotPasswordScreen, category: 'Auth' },
    { id: 'onboarding', name: '🏘️ Story Onboarding', component: OnboardingScreen, category: 'Onboarding' },
    { id: 'modern-onboarding', name: '📱 Modern Onboarding', component: ModernOnboardingScreen, category: 'Onboarding' },
    { id: 'main-tabs', name: '🏠 Main Tabs', component: MainTabsScreen, category: 'Navigation' },
    { id: 'home', name: '🏡 Home Dashboard', component: HomeScreen, category: 'Home' },
    { id: 'language-detail', name: '🗣️ Language Detail', component: LanguageDetailScreen, category: 'Learning' },
    { id: 'lessons-list', name: '📚 Lessons List', component: LessonsListScreen, category: 'Learning' },
    { id: 'lesson-detail', name: '📖 Lesson Detail', component: LessonDetailScreen, category: 'Learning' },
    { id: 'courses-tab', name: '📂 Courses Tab', component: CoursesTabScreen, category: 'Learning' },
    { id: 'quiz-map', name: '🗺️ Quiz Selection Map', component: QuizSelectionMapScreen, category: 'Quiz' },
    { id: 'take-quiz', name: '❓ Take Quiz', component: TakeQuizScreen, category: 'Quiz' },
    { id: 'standings', name: '🏆 Leaderboard', component: StandingsScreen, category: 'Progress' },
    { id: 'achievements', name: '🎖️ Achievements', component: AchievementsScreen, category: 'Progress' },
    { id: 'daily-goals', name: '🎯 Daily Goals', component: DailyGoalsScreen, category: 'Progress' },
    { id: 'progress-dashboard', name: '📊 Progress Dashboard', component: ProgressDashboardScreen, category: 'Progress' },
    { id: 'global-progress', name: '🌍 Global Progress', component: GlobalProgressScreen, category: 'Progress' },
    { id: 'ai-chat-select', name: '🤖 AI Chat Select', component: AIChatSelectScreen, category: 'AI Chat' },
    { id: 'ai-chat', name: '💬 AI Chat', component: AIChatScreen, category: 'AI Chat' },
    { id: 'game-selection', name: '🎮 Game Selection', component: GameSelectionScreen, category: 'Games' },
    { id: 'word-match', name: '🧩 Word Match', component: WordMatchGameScreen, category: 'Games' },
    { id: 'speed-challenge', name: '⚡ Speed Challenge', component: SpeedChallengeGameScreen, category: 'Games' },
    { id: 'pronunciation', name: '🎤 Pronunciation Game', component: PronunciationGameScreen, category: 'Games' },
    { id: 'game-results', name: '🏅 Game Results', component: GameResultsScreen, category: 'Games' },
    { id: 'user-connections', name: '👥 User Connections', component: UserConnectionsScreen, category: 'Social' },
    { id: 'global-chat', name: '🌐 Global Chat', component: GlobalChatScreen, category: 'Social' },
    { id: 'private-chat-list', name: '💬 Private Chat List', component: PrivateChatListScreen, category: 'Social' },
    { id: 'private-chat', name: '💭 Private Chat', component: PrivateChatScreen, category: 'Social' },
    { id: 'profile-edit', name: '✏️ Edit Profile', component: ProfileEditScreen, category: 'Profile' },
    { id: 'settings', name: '⚙️ Settings', component: SettingsScreen, category: 'Settings' },
    { id: 'change-password', name: '🔒 Change Password', component: ChangePasswordScreen, category: 'Settings' },
    { id: 'culture-magazine', name: '📰 Culture Magazine', component: CultureMagazineScreen, category: 'Content' },
    { id: 'about-us', name: 'ℹ️ About Us', component: AboutUsScreen, category: 'Info' }
  ];

  const categories = Array.from(new Set(screens.map(s => s.category)));

  const SelectedComponent = screens.find(s => s.id === selectedScreen)?.component || SplashScreen;

  return (
    <div className="min-h-screen bg-gray-100 flex">
      {/* Sidebar */}
      <div className="w-80 bg-white border-r border-gray-200 overflow-y-auto">
        <div className="sticky top-0 bg-gradient-to-r from-[#007A3D] to-[#005A2D] p-6 z-10">
          <h1 className="text-white mb-1">LingAfriq UI</h1>
          <p className="text-white/80 text-sm">{screens.length} Static Screens</p>
        </div>

        <div className="p-4">
          {categories.map((category) => (
            <div key={category} className="mb-6">
              <h3 className="text-gray-500 text-xs uppercase tracking-wider mb-2 px-2">
                {category}
              </h3>
              <div className="space-y-1">
                {screens.filter(s => s.category === category).map((screen) => (
                  <button
                    key={screen.id}
                    onClick={() => setSelectedScreen(screen.id)}
                    className={`w-full text-left px-4 py-2 rounded-lg transition-colors ${
                      selectedScreen === screen.id
                        ? 'bg-[#007A3D] text-white'
                        : 'text-gray-700 hover:bg-gray-100'
                    }`}
                  >
                    {screen.name}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Main Preview Area */}
      <div className="flex-1 overflow-hidden bg-gray-200 flex items-center justify-center p-8">
        <div className="bg-white rounded-3xl shadow-2xl overflow-hidden" style={{ width: '428px', height: '926px' }}>
          <SelectedComponent />
        </div>
      </div>
    </div>
  );
}
