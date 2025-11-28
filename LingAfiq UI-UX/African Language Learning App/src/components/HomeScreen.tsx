import { useState } from 'react';
import { motion } from 'motion/react';
import { 
  BookOpen, MessageCircle, Trophy, Target, TrendingUp, 
  Users, Library, Upload, Settings, Menu, Bell, Flame, Star
} from 'lucide-react';
import { User, Screen } from '../lib/types';
import { courses, challenges } from '../lib/mock-data';
import LogoutDialog from './LogoutDialog';
import { ImageWithFallback } from './figma/ImageWithFallback';

interface HomeScreenProps {
  user: User;
  onNavigate: (screen: Screen) => void;
  onLogout: () => void;
}

export default function HomeScreen({ user, onNavigate, onLogout }: HomeScreenProps) {
  const [showLogoutDialog, setShowLogoutDialog] = useState(false);
  const [showMenu, setShowMenu] = useState(false);

  const quickActions = [
    { icon: BookOpen, label: 'Learn', gradient: 'from-red-500 to-orange-500', screen: 'language-select' as Screen },
    { icon: MessageCircle, label: 'AI Chat', gradient: 'from-purple-500 to-pink-500', screen: 'ai-chat-select' as Screen },
    { icon: Trophy, label: 'Games', gradient: 'from-green-500 to-teal-500', screen: 'games-menu' as Screen },
    { icon: Users, label: 'Community', gradient: 'from-blue-500 to-cyan-500', screen: 'community-chat' as Screen }
  ];

  const menuItems = [
    { icon: Target, label: 'Challenges', screen: 'challenges' as Screen },
    { icon: TrendingUp, label: 'Progress', screen: 'progress' as Screen },
    { icon: Trophy, label: 'Ranking', screen: 'ranking' as Screen },
    { icon: Star, label: 'Incentives', screen: 'incentives' as Screen },
    { icon: Library, label: 'Magazine', screen: 'magazine-home' as Screen },
    { icon: MessageCircle, label: 'Messages', screen: 'direct-messages' as Screen },
    { icon: Upload, label: 'Import Media', screen: 'media-import' as Screen },
    { icon: Settings, label: 'Settings', screen: 'settings' as Screen }
  ];

  return (
    <div className="w-full min-h-screen bg-gray-50">
      {/* Header with Gradient */}
      <div className="relative pb-24" style={{
        background: 'linear-gradient(135deg, #E74C3C 0%, #F1C40F 50%, #27AE60 100%)'
      }}>
        {/* Top Bar */}
        <div className="flex items-center justify-between p-6">
          <button
            onClick={() => setShowMenu(!showMenu)}
            className="w-10 h-10 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center text-white"
          >
            <Menu className="w-5 h-5" />
          </button>
          <button
            onClick={() => onNavigate('profile')}
            className="w-10 h-10 rounded-xl bg-white/20 backdrop-blur-sm flex items-center justify-center text-white relative"
          >
            <Bell className="w-5 h-5" />
            <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full" />
          </button>
        </div>

        {/* User Info */}
        <div className="px-6 mt-4">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex items-center gap-4"
          >
            <div className="w-16 h-16 rounded-2xl overflow-hidden shadow-lg">
              <ImageWithFallback
                src={user.avatar || ''}
                alt={user.name}
                className="w-full h-full object-cover"
              />
            </div>
            <div>
              <h2 className="text-white mb-1">
                Hello, {user.name.split(' ')[0]}! 👋
              </h2>
              <p className="text-white/90 text-sm">Ready to learn today?</p>
            </div>
          </motion.div>

          {/* Stats Cards */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="grid grid-cols-3 gap-3 mt-6"
          >
            <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center">
              <div className="flex items-center justify-center gap-1 mb-1">
                <Flame className="w-4 h-4 text-orange-300" />
                <span className="text-white">{user.streak}</span>
              </div>
              <p className="text-white/80 text-xs">Day Streak</p>
            </div>
            <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center">
              <div className="flex items-center justify-center gap-1 mb-1">
                <Star className="w-4 h-4 text-yellow-300" />
                <span className="text-white">{user.xp}</span>
              </div>
              <p className="text-white/80 text-xs">Total XP</p>
            </div>
            <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 text-center">
              <div className="flex items-center justify-center gap-1 mb-1">
                <Trophy className="w-4 h-4 text-yellow-300" />
                <span className="text-white">{user.level}</span>
              </div>
              <p className="text-white/80 text-xs">Level</p>
            </div>
          </motion.div>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-6 -mt-16 pb-24">
        {/* Quick Actions */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="grid grid-cols-4 gap-3 mb-6"
        >
          {quickActions.map((action, index) => (
            <button
              key={index}
              onClick={() => onNavigate(action.screen)}
              className="flex flex-col items-center"
            >
              <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${action.gradient} shadow-lg flex items-center justify-center mb-2 hover:scale-105 transition-transform`}>
                <action.icon className="w-7 h-7 text-white" />
              </div>
              <span className="text-xs text-gray-700">{action.label}</span>
            </button>
          ))}
        </motion.div>

        {/* Daily Challenges */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="mb-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-900">Daily Challenges</h3>
            <button
              onClick={() => onNavigate('challenges')}
              className="text-sm text-green-600 hover:text-green-700"
            >
              View All
            </button>
          </div>
          <div className="space-y-3">
            {challenges.slice(0, 2).map((challenge) => (
              <div key={challenge.id} className="bg-white rounded-2xl p-4 shadow-sm border border-gray-100">
                <div className="flex items-start justify-between mb-2">
                  <div className="flex-1">
                    <h4 className="text-gray-900 mb-1">{challenge.title}</h4>
                    <p className="text-sm text-gray-600">{challenge.description}</p>
                  </div>
                  <span className="text-xs px-2 py-1 rounded-full bg-yellow-100 text-yellow-700">
                    +{challenge.reward.xp} XP
                  </span>
                </div>
                <div className="mt-3">
                  <div className="flex items-center justify-between text-xs text-gray-600 mb-1">
                    <span>{challenge.progress}/{challenge.target}</span>
                    <span>{Math.round((challenge.progress / challenge.target) * 100)}%</span>
                  </div>
                  <div className="h-2 bg-gray-100 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-green-400 to-green-600 rounded-full transition-all"
                      style={{ width: `${(challenge.progress / challenge.target) * 100}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* Continue Learning */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mb-6"
        >
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-900">Continue Learning</h3>
            <button
              onClick={() => onNavigate('course-overview')}
              className="text-sm text-green-600 hover:text-green-700"
            >
              View All
            </button>
          </div>
          <div className="space-y-3">
            {courses.filter(c => c.progress > 0 && c.progress < 100).slice(0, 2).map((course) => (
              <button
                key={course.id}
                onClick={() => onNavigate('course-overview')}
                className="w-full bg-white rounded-2xl overflow-hidden shadow-sm border border-gray-100 hover:shadow-md transition-shadow"
              >
                <div className="flex gap-4">
                  <div className="w-24 h-24 flex-shrink-0">
                    <ImageWithFallback
                      src={course.image || ''}
                      alt={course.title}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div className="flex-1 py-3 pr-4 text-left">
                    <h4 className="text-gray-900 mb-1">{course.title}</h4>
                    <p className="text-sm text-gray-600 mb-2">{course.lessonsCount} lessons</p>
                    <div className="flex items-center gap-2">
                      <div className="flex-1 h-2 bg-gray-100 rounded-full overflow-hidden">
                        <div
                          className="h-full bg-gradient-to-r from-orange-400 to-red-500 rounded-full"
                          style={{ width: `${course.progress}%` }}
                        />
                      </div>
                      <span className="text-xs text-gray-600">{course.progress}%</span>
                    </div>
                  </div>
                </div>
              </button>
            ))}
          </div>
        </motion.div>
      </div>

      {/* Side Menu */}
      {showMenu && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setShowMenu(false)}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-40"
          />
          <motion.div
            initial={{ x: -300 }}
            animate={{ x: 0 }}
            exit={{ x: -300 }}
            className="fixed left-0 top-0 bottom-0 w-80 bg-white shadow-2xl z-50 p-6 overflow-y-auto"
          >
            <div className="flex items-center gap-4 mb-8">
              <div className="w-14 h-14 rounded-xl overflow-hidden">
                <ImageWithFallback
                  src={user.avatar || ''}
                  alt={user.name}
                  className="w-full h-full object-cover"
                />
              </div>
              <div>
                <h3 className="text-gray-900">{user.name}</h3>
                <p className="text-sm text-gray-600">Level {user.level}</p>
              </div>
            </div>

            <div className="space-y-2">
              {menuItems.map((item, index) => (
                <button
                  key={index}
                  onClick={() => {
                    onNavigate(item.screen);
                    setShowMenu(false);
                  }}
                  className="w-full flex items-center gap-4 px-4 py-3 rounded-xl hover:bg-gray-100 transition-colors text-left"
                >
                  <item.icon className="w-5 h-5 text-gray-600" />
                  <span className="text-gray-700">{item.label}</span>
                </button>
              ))}
            </div>

            <div className="mt-8 pt-8 border-t border-gray-200">
              <button
                onClick={() => {
                  setShowMenu(false);
                  setShowLogoutDialog(true);
                }}
                className="w-full py-3 px-4 rounded-xl bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
              >
                Logout
              </button>
            </div>
          </motion.div>
        </>
      )}

      {/* Logout Dialog */}
      <LogoutDialog
        isOpen={showLogoutDialog}
        onClose={() => setShowLogoutDialog(false)}
        onConfirm={onLogout}
      />
    </div>
  );
}
