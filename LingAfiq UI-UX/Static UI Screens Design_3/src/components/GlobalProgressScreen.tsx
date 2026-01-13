import React from 'react';
import { ArrowLeft, Trophy, Users, BookOpen, Clock, Globe, RefreshCw } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';

export function GlobalProgressScreen() {
  const topLanguages = [
    { name: 'Swahili', learners: 45000 },
    { name: 'Yoruba', learners: 38000 },
    { name: 'Amharic', learners: 32000 },
    { name: 'Zulu', learners: 28000 },
    { name: 'Hausa', learners: 25000 }
  ];

  const topLearners = [
    { rank: 1, username: 'AfricanLinguist', country: '🇰🇪', points: 98450 },
    { rank: 2, username: 'PolyglotMaster', country: '🇳🇬', points: 87230 },
    { rank: 3, username: 'SwahiliKing', country: '🇹🇿', points: 76890 },
    { rank: 4, username: 'LanguageQueen', country: '🇪🇹', points: 65340 },
    { rank: 5, username: 'CulturalExplorer', country: '🇿🇦', points: 58920 },
    { rank: 6, username: 'WordNinja', country: '🇬🇭', points: 52100 },
    { rank: 7, username: 'LingAfriPro', country: '🇺🇬', points: 48750 }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#FCD116] via-[#FF6B35] to-[#CE1126] px-6 py-8 shadow-lg">
        <div className="flex items-center gap-4 mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div className="flex-1">
            <h1 className="text-white">Global Ranking</h1>
            <p className="text-white/80 text-sm">Top learners worldwide</p>
          </div>
          <button className="text-white">
            <RefreshCw className="w-5 h-5" />
          </button>
        </div>

        {/* Trophy Icon */}
        <div className="flex justify-center mb-6">
          <div className="w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center border-2 border-white/40">
            <Trophy className="w-10 h-10 text-[#FCD116]" />
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Global Stats Cards */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white rounded-2xl p-5 shadow-md text-center">
            <div className="w-12 h-12 bg-[#007A3D]/10 rounded-full flex items-center justify-center mx-auto mb-2">
              <Users className="w-6 h-6 text-[#007A3D]" />
            </div>
            <p className="text-2xl text-gray-800 mb-1">2.3M</p>
            <p className="text-gray-500 text-sm">Total Users</p>
          </div>

          <div className="bg-white rounded-2xl p-5 shadow-md text-center">
            <div className="w-12 h-12 bg-[#FF6B35]/10 rounded-full flex items-center justify-center mx-auto mb-2">
              <BookOpen className="w-6 h-6 text-[#FF6B35]" />
            </div>
            <p className="text-2xl text-gray-800 mb-1">45M</p>
            <p className="text-gray-500 text-sm">Words Learned</p>
          </div>

          <div className="bg-white rounded-2xl p-5 shadow-md text-center">
            <div className="w-12 h-12 bg-[#7B2CBF]/10 rounded-full flex items-center justify-center mx-auto mb-2">
              <Clock className="w-6 h-6 text-[#7B2CBF]" />
            </div>
            <p className="text-2xl text-gray-800 mb-1">890K</p>
            <p className="text-gray-500 text-sm">Total Hours</p>
          </div>

          <div className="bg-white rounded-2xl p-5 shadow-md text-center">
            <div className="w-12 h-12 bg-[#FCD116]/10 rounded-full flex items-center justify-center mx-auto mb-2">
              <Globe className="w-6 h-6 text-[#FCD116]" />
            </div>
            <p className="text-2xl text-gray-800 mb-1">18</p>
            <p className="text-gray-500 text-sm">Languages</p>
          </div>
        </div>

        {/* Top Languages Chart */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4">Most Learned Languages</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={topLanguages} layout="vertical">
              <XAxis type="number" stroke="#9CA3AF" />
              <YAxis type="category" dataKey="name" stroke="#9CA3AF" width={80} />
              <Tooltip />
              <Bar dataKey="learners" fill="#007A3D" radius={[0, 8, 8, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Top Learners List */}
        <div className="bg-white rounded-2xl shadow-md overflow-hidden">
          <div className="bg-gradient-to-r from-[#FCD116] to-[#FF6B35] p-4">
            <h3 className="text-white">🏆 Top Learners Worldwide</h3>
          </div>
          
          <div>
            {topLearners.map((learner, index) => {
              const isTop3 = learner.rank <= 3;
              const trophyEmoji = learner.rank === 1 ? '🥇' : learner.rank === 2 ? '🥈' : learner.rank === 3 ? '🥉' : null;

              return (
                <div
                  key={index}
                  className={`flex items-center gap-4 p-4 border-b border-gray-100 last:border-b-0 ${
                    isTop3 ? 'bg-gradient-to-r from-[#FCD116]/10 to-transparent' : ''
                  }`}
                >
                  {/* Rank */}
                  <div className="w-12 text-center">
                    {trophyEmoji ? (
                      <span className="text-2xl">{trophyEmoji}</span>
                    ) : (
                      <span className="text-gray-500">#{learner.rank}</span>
                    )}
                  </div>

                  {/* Avatar */}
                  <div className={`w-12 h-12 rounded-full flex items-center justify-center ${
                    isTop3 ? 'bg-gradient-to-br from-[#FCD116] to-[#FF6B35]' : 'bg-gray-200'
                  }`}>
                    <span className="text-xl">{isTop3 ? '👑' : learner.username.charAt(0)}</span>
                  </div>

                  {/* User Info */}
                  <div className="flex-1">
                    <p className="text-gray-800">{learner.username}</p>
                    <p className="text-gray-500 text-sm">{learner.country} {learner.points.toLocaleString()} XP</p>
                  </div>

                  {/* Points Badge */}
                  {isTop3 && (
                    <div className="bg-[#FCD116] text-gray-800 px-4 py-2 rounded-full">
                      <p className="text-sm">{learner.points.toLocaleString()}</p>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Community Message */}
        <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-2xl p-6 text-white shadow-md text-center">
          <p className="text-3xl mb-3">🌍</p>
          <h3 className="mb-2">Join the Global Community</h3>
          <p className="text-white/90 text-sm">
            Millions of learners around the world are preserving and celebrating African languages. Be part of the movement!
          </p>
        </div>
      </div>
    </div>
  );
}
