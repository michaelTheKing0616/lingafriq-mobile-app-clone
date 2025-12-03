import React from 'react';
import { ArrowLeft, Trophy, Star, Lock } from 'lucide-react';

export function AchievementsScreen() {
  const [activeTab, setActiveTab] = React.useState<'badges' | 'streaks' | 'xp'>('badges');

  const badges = [
    { icon: '🎓', name: 'First Lesson', description: 'Complete your first lesson', xp: 50, unlocked: true, rarity: 'common' },
    { icon: '🔥', name: '7 Day Streak', description: 'Practice for 7 days in a row', xp: 100, unlocked: true, rarity: 'uncommon' },
    { icon: '⭐', name: 'Perfect Quiz', description: 'Score 100% on any quiz', xp: 150, unlocked: true, rarity: 'rare' },
    { icon: '👑', name: 'Language Master', description: 'Complete all lessons in a language', xp: 500, unlocked: false, rarity: 'epic' },
    { icon: '🏆', name: 'Top 10 Global', description: 'Reach top 10 on global leaderboard', xp: 1000, unlocked: false, rarity: 'legendary' },
    { icon: '💬', name: 'Chat Champion', description: 'Send 100 messages in AI chat', xp: 75, unlocked: true, rarity: 'common' },
    { icon: '🎮', name: 'Game Master', description: 'Win 50 language games', xp: 200, unlocked: false, rarity: 'rare' },
    { icon: '📚', name: 'Bookworm', description: 'Read 20 culture magazine articles', xp: 100, unlocked: false, rarity: 'uncommon' },
    { icon: '🌍', name: 'Polyglot', description: 'Learn 3 different languages', xp: 300, unlocked: false, rarity: 'epic' }
  ];

  const getRarityColor = (rarity: string) => {
    switch (rarity) {
      case 'common': return 'border-gray-400';
      case 'uncommon': return 'border-green-500';
      case 'rare': return 'border-blue-500';
      case 'epic': return 'border-purple-500';
      case 'legendary': return 'border-orange-500';
      default: return 'border-gray-400';
    }
  };

  const getRarityBg = (rarity: string) => {
    switch (rarity) {
      case 'common': return 'bg-gray-100';
      case 'uncommon': return 'bg-green-100';
      case 'rare': return 'bg-blue-100';
      case 'epic': return 'bg-purple-100';
      case 'legendary': return 'bg-orange-100';
      default: return 'bg-gray-100';
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#FCD116] to-[#FF6B35] px-6 py-8 shadow-lg">
        <div className="flex items-center gap-4 mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div>
            <h1 className="text-white">Achievements</h1>
            <p className="text-white/80 text-sm">Your rewards & badges</p>
          </div>
        </div>

        {/* Level & XP Card */}
        <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-6 border border-white/40">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-16 h-16 bg-white rounded-full flex items-center justify-center">
              <Star className="w-8 h-8 text-[#FCD116]" />
            </div>
            <div className="flex-1">
              <h2 className="text-white">Level 12</h2>
              <p className="text-white/80 text-sm">8,450 Total XP</p>
            </div>
          </div>
          
          {/* Progress to next level */}
          <div className="mb-3">
            <div className="h-3 bg-white/30 rounded-full overflow-hidden">
              <div className="h-full bg-white rounded-full w-3/4"></div>
            </div>
          </div>
          <p className="text-white/80 text-sm">750 XP to Level 13</p>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-4 mt-4 pt-4 border-t border-white/30">
            <div className="text-center">
              <p className="text-white text-xl">12</p>
              <p className="text-white/70 text-xs">Unlocked</p>
            </div>
            <div className="text-center">
              <p className="text-white text-xl">24</p>
              <p className="text-white/70 text-xs">Total</p>
            </div>
            <div className="text-center">
              <p className="text-white text-xl">50%</p>
              <p className="text-white/70 text-xs">Complete</p>
            </div>
          </div>
        </div>

        {/* Tabs */}
        <div className="flex gap-2 mt-6">
          <button
            onClick={() => setActiveTab('badges')}
            className={`flex-1 py-3 rounded-xl transition-all ${
              activeTab === 'badges'
                ? 'bg-white text-gray-800'
                : 'bg-white/20 text-white'
            }`}
          >
            Badges
          </button>
          <button
            onClick={() => setActiveTab('streaks')}
            className={`flex-1 py-3 rounded-xl transition-all ${
              activeTab === 'streaks'
                ? 'bg-white text-gray-800'
                : 'bg-white/20 text-white'
            }`}
          >
            Streaks
          </button>
          <button
            onClick={() => setActiveTab('xp')}
            className={`flex-1 py-3 rounded-xl transition-all ${
              activeTab === 'xp'
                ? 'bg-white text-gray-800'
                : 'bg-white/20 text-white'
            }`}
          >
            XP
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6">
        {activeTab === 'badges' && (
          <div className="grid grid-cols-3 gap-4">
            {badges.map((badge, index) => (
              <div
                key={index}
                className={`bg-white rounded-2xl p-4 shadow-md border-2 ${getRarityColor(badge.rarity)} ${
                  !badge.unlocked ? 'opacity-40' : ''
                }`}
              >
                <div className={`w-16 h-16 ${getRarityBg(badge.rarity)} rounded-full flex items-center justify-center mx-auto mb-3 ${
                  !badge.unlocked ? 'relative' : ''
                }`}>
                  <span className="text-3xl">{badge.icon}</span>
                  {!badge.unlocked && (
                    <div className="absolute inset-0 bg-black/50 rounded-full flex items-center justify-center">
                      <Lock className="w-6 h-6 text-white" />
                    </div>
                  )}
                </div>
                <h4 className="text-gray-800 text-center text-xs mb-1">{badge.name}</h4>
                <p className="text-gray-500 text-xs text-center mb-2">{badge.description}</p>
                <p className="text-[#FCD116] text-xs text-center">+{badge.xp} XP</p>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'streaks' && (
          <div className="bg-white rounded-2xl p-8 shadow-md text-center">
            <div className="w-24 h-24 bg-gradient-to-br from-[#FF6B35] to-[#CE1126] rounded-full flex items-center justify-center mx-auto mb-4">
              <span className="text-5xl">🔥</span>
            </div>
            <h2 className="text-gray-800 mb-2">7 Day Streak</h2>
            <p className="text-gray-600 mb-6">You're on fire! Keep it up!</p>
            
            {/* Weekly Calendar */}
            <div className="flex justify-center gap-2 mb-6">
              {['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day, index) => (
                <div
                  key={index}
                  className={`w-10 h-10 rounded-full flex items-center justify-center ${
                    index < 5 ? 'bg-[#007A3D] text-white' : 'bg-gray-200 text-gray-400'
                  }`}
                >
                  {day}
                </div>
              ))}
            </div>
            
            <p className="text-gray-500">Longest streak: 14 days</p>
          </div>
        )}

        {activeTab === 'xp' && (
          <div className="space-y-4">
            <div className="bg-white rounded-2xl p-6 shadow-md text-center">
              <h2 className="text-[#007A3D] mb-2">8,450 XP</h2>
              <p className="text-gray-600 mb-4">Total Experience Points</p>
              
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-gray-50 rounded-xl p-4">
                  <p className="text-gray-800">Level 12</p>
                  <p className="text-gray-500 text-sm">Current Level</p>
                </div>
                <div className="bg-gray-50 rounded-xl p-4">
                  <p className="text-gray-800">750 XP</p>
                  <p className="text-gray-500 text-sm">To Next Level</p>
                </div>
              </div>
            </div>

            {/* XP Breakdown */}
            <div className="bg-white rounded-2xl p-6 shadow-md">
              <h3 className="text-gray-800 mb-4">XP Breakdown</h3>
              <div className="space-y-3">
                {[
                  { activity: 'Lessons', xp: 3200, color: 'bg-[#007A3D]' },
                  { activity: 'Quizzes', xp: 2450, color: 'bg-[#FF6B35]' },
                  { activity: 'Games', xp: 1800, color: 'bg-[#7B2CBF]' },
                  { activity: 'Achievements', xp: 1000, color: 'bg-[#FCD116]' }
                ].map((item, index) => (
                  <div key={index} className="flex items-center gap-3">
                    <div className={`w-3 h-3 rounded-full ${item.color}`}></div>
                    <div className="flex-1">
                      <p className="text-gray-700 text-sm">{item.activity}</p>
                    </div>
                    <p className="text-gray-800">{item.xp} XP</p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
