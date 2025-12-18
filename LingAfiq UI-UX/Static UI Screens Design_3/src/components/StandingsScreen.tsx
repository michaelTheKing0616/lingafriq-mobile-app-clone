import React from 'react';
import { Trophy, RefreshCw } from 'lucide-react';

export function StandingsScreen() {
  const [activeTab, setActiveTab] = React.useState<'global' | 'country'>('global');

  const leaderboard = [
    { rank: 1, username: 'AdwoaLearner', country: '🇬🇭', points: 12450, isCurrentUser: false },
    { rank: 2, username: 'KofiMaster', country: '🇬🇭', points: 11230, isCurrentUser: false },
    { rank: 3, username: 'AmaniSwahili', country: '🇰🇪', points: 10890, isCurrentUser: false },
    { rank: 4, username: 'You', country: '🇳🇬', points: 9750, isCurrentUser: true },
    { rank: 5, username: 'ZuluKing', country: '🇿🇦', points: 9340, isCurrentUser: false },
    { rank: 6, username: 'EthiopianQueen', country: '🇪🇹', points: 8920, isCurrentUser: false },
    { rank: 7, username: 'TanzanianPro', country: '🇹🇿', points: 8650, isCurrentUser: false },
    { rank: 8, username: 'NigerianScholar', country: '🇳🇬', points: 8340, isCurrentUser: false }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#FCD116] via-[#FF6B35] to-[#CE1126] rounded-b-3xl shadow-lg">
        <div className="px-6 py-8">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-white/90">Karibu!</h2>
              <h1 className="text-white">Leaderboard</h1>
            </div>
            <button className="text-white">
              <RefreshCw className="w-6 h-6" />
            </button>
          </div>

          {/* Trophy Icon */}
          <div className="flex justify-center my-6">
            <div className="w-20 h-20 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center border-2 border-white/40">
              <Trophy className="w-10 h-10 text-[#FCD116]" />
            </div>
          </div>

          {/* Tabs */}
          <div className="flex gap-2 bg-white/20 backdrop-blur-sm rounded-full p-1">
            <button
              onClick={() => setActiveTab('global')}
              className={`flex-1 py-3 rounded-full transition-all ${
                activeTab === 'global'
                  ? 'bg-white text-gray-800'
                  : 'text-white'
              }`}
            >
              Global
            </button>
            <button
              onClick={() => setActiveTab('country')}
              className={`flex-1 py-3 rounded-full transition-all ${
                activeTab === 'country'
                  ? 'bg-white text-gray-800'
                  : 'text-white'
              }`}
            >
              Country
            </button>
          </div>
        </div>
      </div>

      {/* Leaderboard List */}
      <div className="px-6 py-6">
        <div className="bg-white rounded-2xl shadow-md overflow-hidden">
          {leaderboard.map((user, index) => {
            const isTop3 = user.rank <= 3;
            const trophyEmoji = user.rank === 1 ? '🥇' : user.rank === 2 ? '🥈' : user.rank === 3 ? '🥉' : null;

            return (
              <div
                key={index}
                className={`flex items-center gap-4 p-4 border-b border-gray-100 last:border-b-0 ${
                  user.isCurrentUser
                    ? 'bg-[#007A3D]/10 border-l-4 border-l-[#007A3D]'
                    : isTop3
                    ? 'bg-gradient-to-r from-[#FCD116]/10 to-transparent'
                    : ''
                }`}
              >
                {/* Rank */}
                <div className="w-12 text-center">
                  {trophyEmoji ? (
                    <span className="text-2xl">{trophyEmoji}</span>
                  ) : (
                    <span className="text-gray-500">#{user.rank}</span>
                  )}
                </div>

                {/* Avatar */}
                <div className={`w-12 h-12 rounded-full flex items-center justify-center ${
                  user.isCurrentUser
                    ? 'bg-[#007A3D] text-white'
                    : 'bg-gray-200 text-gray-600'
                }`}>
                  <span className="text-xl">
                    {user.isCurrentUser ? '👤' : user.username.charAt(0)}
                  </span>
                </div>

                {/* User Info */}
                <div className="flex-1">
                  <p className={`${user.isCurrentUser ? 'text-[#007A3D]' : 'text-gray-800'}`}>
                    {user.username}
                  </p>
                  <p className="text-gray-500 text-sm">{user.country} {user.points.toLocaleString()} XP</p>
                </div>

                {/* Points Badge */}
                <div className={`px-4 py-2 rounded-full ${
                  isTop3
                    ? 'bg-[#FCD116] text-gray-800'
                    : user.isCurrentUser
                    ? 'bg-[#007A3D] text-white'
                    : 'bg-gray-100 text-gray-600'
                }`}>
                  <p className="text-sm">{user.points.toLocaleString()}</p>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
