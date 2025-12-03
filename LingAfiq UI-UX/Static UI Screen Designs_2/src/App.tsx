import { StandingsScreen } from './components/StandingsScreen';
import { ProfileEditScreen } from './components/ProfileEditScreen';
import { UserProfileViewScreen } from './components/UserProfileViewScreen';
import { GameSelectionScreen } from './components/GameSelectionScreen';
import { WordMatchGameScreen } from './components/WordMatchGameScreen';
import { SpeedChallengeGameScreen } from './components/SpeedChallengeGameScreen';
import { PronunciationGameScreen } from './components/PronunciationGameScreen';
import { GameResultsScreen } from './components/GameResultsScreen';
import { ProgressDashboardScreen } from './components/ProgressDashboardScreen';
import { GlobalProgressScreen } from './components/GlobalProgressScreen';
import { AIChatSelectScreen } from './components/AIChatSelectScreen';
import { GlobalChatScreen } from './components/GlobalChatScreen';
import { PrivateChatListScreen } from './components/PrivateChatListScreen';
import { PrivateChatScreen } from './components/PrivateChatScreen';
import { UserConnectionsScreen } from './components/UserConnectionsScreen';
import { CultureMagazineScreen } from './components/CultureMagazineScreen';
import { ImportMediaScreen } from './components/ImportMediaScreen';
import { ComprehensiveCurriculumScreen } from './components/ComprehensiveCurriculumScreen';
import { SettingsScreen } from './components/SettingsScreen';
import { AboutUsScreen } from './components/AboutUsScreen';
import { ChangePasswordScreen } from './components/ChangePasswordScreen';
import { SuggestLanguageScreen } from './components/SuggestLanguageScreen';
import { DailyChallengesScreen } from './components/DailyChallengesScreen';
import { CoursesTabScreen } from './components/CoursesTabScreen';
import { HistorySectionsScreen } from './components/HistorySectionsScreen';
import { MannerismsScreen } from './components/MannerismsScreen';

export default function App() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* LingAfriq Mobile App - Static UI Screens */}
      <div className="max-w-md mx-auto bg-white shadow-xl min-h-screen">
        
        {/* Screen Navigator - For demonstration purposes */}
        <div className="p-4 bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white">
          <h1 className="text-center">LingAfriq UI Screens</h1>
          <p className="text-center text-sm opacity-90">Static Design Showcase</p>
          <p className="text-center text-xs mt-2 opacity-75">24 Beautiful Mobile Screens Created</p>
        </div>

        {/* Display Standings Screen as Default */}
        <StandingsScreen />
        
        {/* All Available Screens:
        
        HIGH PRIORITY SCREENS:
        ✅ StandingsScreen - Global leaderboard
        ✅ ProfileEditScreen - Edit user profile
        ✅ UserProfileViewScreen - View another user's profile
        
        GAME SCREENS:
        ✅ GameSelectionScreen - Choose game type
        ✅ WordMatchGameScreen - Match words game
        ✅ SpeedChallengeGameScreen - Timed quiz game
        ✅ PronunciationGameScreen - Pronunciation practice
        ✅ GameResultsScreen - Game completion results
        
        PROGRESS & ANALYTICS:
        ✅ ProgressDashboardScreen - Detailed progress charts
        ✅ GlobalProgressScreen - Worldwide statistics
        
        CHAT & SOCIAL:
        ✅ AIChatSelectScreen - Choose AI chat mode
        ✅ GlobalChatScreen - Public language chat rooms
        ✅ PrivateChatListScreen - Private conversations list
        ✅ PrivateChatScreen - 1-on-1 chat
        ✅ UserConnectionsScreen - Find learning partners
        
        CONTENT & LEARNING:
        ✅ CultureMagazineScreen - Cultural articles
        ✅ ImportMediaScreen - Upload custom content
        ✅ ComprehensiveCurriculumScreen - Structured curriculum
        ✅ CoursesTabScreen - Enrolled courses
        ✅ HistorySectionsScreen - Language history lessons
        ✅ MannerismsScreen - Cultural etiquette
        
        CHALLENGES & GOALS:
        ✅ DailyChallengesScreen - Daily tasks & rewards
        
        SETTINGS & ACCOUNT:
        ✅ SettingsScreen - App preferences
        ✅ AboutUsScreen - App information
        ✅ ChangePasswordScreen - Security settings
        ✅ SuggestLanguageScreen - Request new languages
        */}
      </div>
    </div>
  );
}