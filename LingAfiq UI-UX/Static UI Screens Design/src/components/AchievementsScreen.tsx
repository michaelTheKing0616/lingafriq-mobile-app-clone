import React from 'react';
import { ArrowLeft, Trophy, Star, Flame, Zap } from 'lucide-react';

const achievementsData = {
  currentLevel: 15,
  totalXP: 3450,
  xpToNextLevel: 150,
  unlockedCount: 24,
  totalCount: 48,
  badges: [
    {
      id: 1,
      icon: '🎯',
      name: 'First Steps',
      description: 'Complete your first lesson',
      xp: 10,
      rarity: 'common',
      unlocked: true,
      unlockedDate: 'Nov 15, 2024',
    },
    {
      id: 2,
      icon: '🔥',
      name: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      xp: 50,
      rarity: 'uncommon',
      unlocked: true,
      unlockedDate: 'Nov 22, 2024',
    },
    {
      id: 3,
      icon: '📚',
      name: 'Bookworm',
      description: 'Complete 50 lessons',
      xp: 100,
      rarity: 'rare',
      unlocked: true,
      unlockedDate: 'Dec 1, 2024',
    },
    {
      id: 4,
      icon: '⚡',
      name: 'Speed Demon',
      description: 'Score 100% on a speed quiz',
      xp: 75,
      rarity: 'rare',
      unlocked: true,
      unlockedDate: 'Nov 28, 2024',
    },
    {
      id: 5,
      icon: '👑',
      name: 'Polyglot Master',
      description: 'Learn 3 languages to fluency',
      xp: 500,
      rarity: 'legendary',
      unlocked: false,
      unlockedDate: null,
    },
    {
      id: 6,
      icon: '🎮',
      name: 'Game Master',
      description: 'Win 100 language games',
      xp: 200,
      rarity: 'epic',
      unlocked: false,
      unlockedDate: null,
    },
    {
      id: 7,
      icon: '💬',
      name: 'Chatterbox',
      description: 'Send 1000 messages with Polie',
      xp: 150,
      rarity: 'rare',
      unlocked: false,
      unlockedDate: null,
    },
    {
      id: 8,
      icon: '🌟',
      name: 'Perfect Score',
      description: 'Get 100% on 10 quizzes',
      xp: 125,
      rarity: 'epic',
      unlocked: true,
      unlockedDate: 'Dec 2, 2024',
    },
    {
      id: 9,
      icon: '📖',
      name: 'Dictionary',
      description: 'Learn 500 vocabulary words',
      xp: 100,
      rarity: 'uncommon',
      unlocked: false,
      unlockedDate: null,
    },
  ],
};

const rarityColors = {
  common: {
    bg: 'from-gray-400 to-gray-500',
    border: 'border-gray-400',
    badge: 'bg-gray-500',
    text: 'text-gray-700',
  },
  uncommon: {
    bg: 'from-[#007A3D] to-[#00a84f]',
    border: 'border-[#007A3D]',
    badge: 'bg-[#007A3D]',
    text: 'text-[#007A3D]',
  },
  rare: {
    bg: 'from-blue-500 to-blue-600',
    border: 'border-blue-500',
    badge: 'bg-blue-500',
    text: 'text-blue-700',
  },
  epic: {
    bg: 'from-[#7B2CBF] to-[#9d4edd]',
    border: 'border-[#7B2CBF]',
    badge: 'bg-[#7B2CBF]',
    text: 'text-[#7B2CBF]',
  },
  legendary: {
    bg: 'from-[#FF6B35] via-[#FCD116] to-[#FF6B35]',
    border: 'border-[#FF6B35]',
    badge: 'bg-gradient-to-r from-[#FF6B35] to-[#FCD116]',
    text: 'text-[#FF6B35]',
  },
};

export function AchievementsScreen() {
  const [activeTab, setActiveTab] = React.useState<'badges' | 'streaks' | 'xp'>('badges');
  const levelProgress = (achievementsData.totalXP % 250) / 250 * 100;
  const completionPercentage = (achievementsData.unlockedCount / achievementsData.totalCount) * 100;
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white pb-20">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#FCD116] via-[#FF6B35] to-[#FF6B35] text-white px-4 py-6 rounded-b-[32px] shadow-xl mb-6">
        <div className="flex items-center gap-3 mb-6">
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6" />
          </button>
          <div className="flex-1">
            <h1 className="text-2xl mb-1">Achievements</h1>
            <p className="text-white/90 text-sm">Your rewards & badges</p>
          </div>
          <Trophy className="w-12 h-12" />
        </div>
        
        {/* Level & XP Card */}
        <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-5">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-white/80 text-sm mb-1">Current Level</p>
              <div className="flex items-baseline gap-2">
                <span className="text-4xl">{achievementsData.currentLevel}</span>
                <Star className="w-6 h-6 fill-white" />
              </div>
            </div>
            <div className="text-right">
              <p className="text-white/80 text-sm mb-1">Total XP</p>
              <p className="text-2xl">{achievementsData.totalXP.toLocaleString()}</p>
            </div>
          </div>
          
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm text-white/90">
              <span>Progress to Level {achievementsData.currentLevel + 1}</span>
              <span>{achievementsData.xpToNextLevel} XP to go</span>
            </div>
            <div className="w-full h-3 bg-white/30 rounded-full overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-white to-white/80 transition-all duration-500 rounded-full"
                style={{ width: `${levelProgress}%` }}
              />
            </div>
          </div>
          
          {/* Stats */}
          <div className="grid grid-cols-3 gap-4 mt-5 pt-5 border-t border-white/30">
            <div className="text-center">
              <p className="text-2xl mb-1">{achievementsData.unlockedCount}</p>
              <p className="text-xs text-white/80">Unlocked</p>
            </div>
            <div className="text-center">
              <p className="text-2xl mb-1">{achievementsData.totalCount}</p>
              <p className="text-xs text-white/80">Total</p>
            </div>
            <div className="text-center">
              <p className="text-2xl mb-1">{Math.round(completionPercentage)}%</p>
              <p className="text-xs text-white/80">Complete</p>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="px-4 mb-6">
        <div className="bg-white rounded-2xl p-1.5 shadow-sm flex gap-1">
          <button
            onClick={() => setActiveTab('badges')}
            className={`flex-1 py-3 px-4 rounded-xl transition-all ${
              activeTab === 'badges'
                ? 'bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-50'
            }`}
          >
            Badges
          </button>
          <button
            onClick={() => setActiveTab('streaks')}
            className={`flex-1 py-3 px-4 rounded-xl transition-all ${
              activeTab === 'streaks'
                ? 'bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-50'
            }`}
          >
            Streaks
          </button>
          <button
            onClick={() => setActiveTab('xp')}
            className={`flex-1 py-3 px-4 rounded-xl transition-all ${
              activeTab === 'xp'
                ? 'bg-gradient-to-r from-[#007A3D] to-[#00a84f] text-white shadow-md'
                : 'text-gray-600 hover:bg-gray-50'
            }`}
          >
            XP
          </button>
        </div>
      </div>

      {/* Badges Grid */}
      {activeTab === 'badges' && (
        <div className="px-4">
          <div className="grid grid-cols-3 gap-4">
            {achievementsData.badges.map((badge) => {
              const colors = rarityColors[badge.rarity];
              
              return (
                <div
                  key={badge.id}
                  className={`relative bg-white rounded-2xl p-4 shadow-sm border-2 transition-all ${
                    badge.unlocked
                      ? `${colors.border} hover:shadow-lg`
                      : 'border-gray-200 opacity-40'
                  }`}
                >
                  {/* Glow effect for unlocked badges */}
                  {badge.unlocked && badge.rarity !== 'common' && (
                    <div className={`absolute inset-0 rounded-2xl bg-gradient-to-br ${colors.bg} opacity-10 blur-sm`} />
                  )}
                  
                  <div className="relative z-10">
                    {/* Icon */}
                    <div className="text-center mb-3">
                      <div
                        className={`inline-flex items-center justify-center w-16 h-16 rounded-2xl text-3xl ${
                          badge.unlocked
                            ? `bg-gradient-to-br ${colors.bg} shadow-lg`
                            : 'bg-gray-200'
                        }`}
                      >
                        {badge.unlocked ? badge.icon : '🔒'}
                      </div>
                    </div>
                    
                    {/* Name */}
                    <h3 className="text-center text-xs text-gray-900 mb-1 line-clamp-2 min-h-[2rem]">
                      {badge.name}
                    </h3>
                    
                    {/* XP Badge */}
                    <div className={`text-center ${badge.unlocked ? colors.text : 'text-gray-500'}`}>
                      <span className="text-xs">+{badge.xp} XP</span>
                    </div>
                    
                    {/* Rarity Badge */}
                    <div className="mt-2 text-center">
                      <span
                        className={`inline-block px-2 py-0.5 rounded-full text-[10px] text-white ${
                          badge.unlocked ? colors.badge : 'bg-gray-400'
                        }`}
                      >
                        {badge.rarity}
                      </span>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Streaks Tab */}
      {activeTab === 'streaks' && (
        <div className="px-4 space-y-4">
          <div className="bg-gradient-to-br from-[#FF6B35] to-[#FCD116] text-white rounded-3xl p-8 shadow-xl text-center">
            <Flame className="w-16 h-16 mx-auto mb-4" />
            <div className="flex items-baseline justify-center gap-2 mb-2">
              <span className="text-6xl">12</span>
              <span className="text-2xl">Days</span>
            </div>
            <p className="text-white/90">Current Streak</p>
          </div>
          
          <div className="bg-white rounded-2xl p-6 shadow-sm">
            <h3 className="text-gray-900 mb-4">Longest Streak</h3>
            <div className="flex items-center justify-between">
              <span className="text-gray-600">Best performance</span>
              <span className="text-3xl text-[#007A3D]">28 days</span>
            </div>
          </div>
        </div>
      )}

      {/* XP Tab */}
      {activeTab === 'xp' && (
        <div className="px-4 space-y-4">
          <div className="bg-gradient-to-br from-[#7B2CBF] to-[#9d4edd] text-white rounded-3xl p-8 shadow-xl text-center">
            <Zap className="w-16 h-16 mx-auto mb-4 fill-white" />
            <div className="flex items-baseline justify-center gap-2 mb-2">
              <span className="text-6xl">{achievementsData.totalXP.toLocaleString()}</span>
            </div>
            <p className="text-white/90">Total XP Earned</p>
          </div>
          
          <div className="bg-white rounded-2xl p-6 shadow-sm space-y-4">
            <h3 className="text-gray-900 mb-4">XP Breakdown</h3>
            
            <div className="space-y-3">
              <div className="flex items-center justify-between py-3 border-b border-gray-100">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-[#007A3D]/10 rounded-lg flex items-center justify-center">
                    📚
                  </div>
                  <span className="text-gray-700">Lessons</span>
                </div>
                <span className="text-gray-900">1,250 XP</span>
              </div>
              
              <div className="flex items-center justify-between py-3 border-b border-gray-100">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-[#FF6B35]/10 rounded-lg flex items-center justify-center">
                    🎯
                  </div>
                  <span className="text-gray-700">Quizzes</span>
                </div>
                <span className="text-gray-900">1,050 XP</span>
              </div>
              
              <div className="flex items-center justify-between py-3 border-b border-gray-100">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-[#7B2CBF]/10 rounded-lg flex items-center justify-center">
                    🎮
                  </div>
                  <span className="text-gray-700">Games</span>
                </div>
                <span className="text-gray-900">750 XP</span>
              </div>
              
              <div className="flex items-center justify-between py-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-[#FCD116]/10 rounded-lg flex items-center justify-center">
                    🏆
                  </div>
                  <span className="text-gray-700">Achievements</span>
                </div>
                <span className="text-gray-900">400 XP</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
