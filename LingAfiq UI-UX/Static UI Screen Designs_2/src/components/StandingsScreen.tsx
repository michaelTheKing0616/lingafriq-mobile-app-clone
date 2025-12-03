import { Trophy, Medal, Star } from 'lucide-react';

export function StandingsScreen() {
  const leaderboardData = [
    { rank: 1, name: 'Amara Okafor', country: '🇳🇬', points: 15840, avatar: '👑' },
    { rank: 2, name: 'Kwame Mensah', country: '🇬🇭', points: 14920, avatar: '🥈' },
    { rank: 3, name: 'Zainab Hassan', country: '🇰🇪', points: 14105, avatar: '🥉' },
    { rank: 4, name: 'Thandiwe Nkosi', country: '🇿🇦', points: 12750, avatar: '👤' },
    { rank: 5, name: 'Ibrahim Diallo', country: '🇸🇳', points: 11890, avatar: '👤' },
    { rank: 6, name: 'Fatima Abdi', country: '🇪🇹', points: 10920, avatar: '👤' },
    { rank: 7, name: 'Chidera Obi', country: '🇳🇬', points: 9845, avatar: '👤' },
    { rank: 8, name: 'Kofi Mensah', country: '🇬🇭', points: 8920, isCurrentUser: true, avatar: '👤' },
    { rank: 9, name: 'Nia Kenyatta', country: '🇰🇪', points: 8450, avatar: '👤' },
    { rank: 10, name: 'Tariq El-Amin', country: '🇪🇬', points: 7890, avatar: '👤' },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-white">
      {/* Header */}
      <div className="relative bg-gradient-to-br from-[#FCD116] via-[#FF6B35] to-[#FF6B35] px-6 pt-12 pb-8 rounded-b-[32px] shadow-lg">
        {/* African Pattern Overlay */}
        <div className="absolute inset-0 opacity-10 rounded-b-[32px]"
          style={{
            backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 10px, rgba(0,0,0,.1) 10px, rgba(0,0,0,.1) 20px)'
          }}
        />
        
        <div className="relative z-10">
          <div className="flex items-center justify-between mb-4">
            <button className="p-2 hover:bg-white/20 rounded-lg transition-colors">
              <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
            </button>
            <Trophy className="w-8 h-8 text-white" />
            <button className="p-2 hover:bg-white/20 rounded-lg transition-colors">
              <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
            </button>
          </div>
          
          <h1 className="text-white text-center mb-2">Standings</h1>
          <p className="text-white/90 text-center text-sm">Top learners worldwide</p>
          
          {/* Gold Bar Illustration */}
          <div className="mt-6 flex justify-center">
            <div className="bg-gradient-to-r from-yellow-300 via-yellow-200 to-yellow-300 rounded-lg px-8 py-3 shadow-xl transform rotate-1">
              <div className="flex items-center gap-2">
                <Star className="w-5 h-5 text-yellow-600 fill-yellow-600" />
                <span className="text-yellow-800">Global Champions</span>
                <Star className="w-5 h-5 text-yellow-600 fill-yellow-600" />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Segmented Control */}
      <div className="px-6 py-4">
        <div className="bg-gray-100 rounded-full p-1 flex">
          <button className="flex-1 py-2 px-4 rounded-full bg-white text-[#007A3D] shadow-sm transition-all">
            Global
          </button>
          <button className="flex-1 py-2 px-4 rounded-full text-gray-600 transition-all">
            Country
          </button>
        </div>
      </div>

      {/* Leaderboard List */}
      <div className="px-6 pb-6">
        {leaderboardData.map((user) => (
          <div
            key={user.rank}
            className={`flex items-center gap-4 p-4 mb-3 rounded-2xl transition-all ${
              user.isCurrentUser
                ? 'bg-gradient-to-r from-[#007A3D]/10 to-[#007A3D]/5 border-2 border-[#007A3D] shadow-lg scale-105'
                : 'bg-white shadow-sm hover:shadow-md'
            }`}
          >
            {/* Rank */}
            <div className="flex-shrink-0 w-12 text-center">
              {user.rank <= 3 ? (
                <div className="text-2xl">
                  {user.rank === 1 && '🏆'}
                  {user.rank === 2 && '🥈'}
                  {user.rank === 3 && '🥉'}
                </div>
              ) : (
                <span className="text-gray-600">#{user.rank}</span>
              )}
            </div>

            {/* Avatar */}
            <div className={`w-12 h-12 rounded-full flex items-center justify-center text-xl ${
              user.isCurrentUser ? 'bg-[#007A3D] ring-4 ring-[#007A3D]/20' : 'bg-gradient-to-br from-gray-200 to-gray-300'
            }`}>
              {user.isCurrentUser ? '👤' : user.avatar}
            </div>

            {/* User Info */}
            <div className="flex-1">
              <div className="flex items-center gap-2">
                <span className={user.isCurrentUser ? 'text-[#007A3D]' : 'text-gray-900'}>{user.name}</span>
                <span className="text-lg">{user.country}</span>
              </div>
              {user.isCurrentUser && (
                <span className="text-xs text-[#007A3D]">You</span>
              )}
            </div>

            {/* Points */}
            <div className="text-right">
              <div className={`flex items-center gap-1 ${user.isCurrentUser ? 'text-[#007A3D]' : 'text-gray-900'}`}>
                <Medal className={`w-4 h-4 ${user.rank <= 3 ? 'text-[#FCD116] fill-[#FCD116]' : ''}`} />
                <span>{user.points.toLocaleString()}</span>
              </div>
              <span className="text-xs text-gray-500">XP</span>
            </div>
          </div>
        ))}
      </div>

      {/* Bottom spacing for navigation */}
      <div className="h-20" />
    </div>
  );
}
