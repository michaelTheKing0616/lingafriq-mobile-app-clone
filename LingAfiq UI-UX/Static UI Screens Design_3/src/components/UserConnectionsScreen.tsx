import React from 'react';
import { ArrowLeft, Search, MessageCircle, UserPlus, Mail } from 'lucide-react';

export function UserConnectionsScreen() {
  const [connectionStatus, setConnectionStatus] = React.useState('connected');

  const users = [
    {
      username: 'SwahiliStar',
      country: '🇰🇪',
      languages: ['Swahili', 'English'],
      level: 'B1',
      online: true
    },
    {
      username: 'YorubaLearner',
      country: '🇳🇬',
      languages: ['Yoruba', 'English'],
      level: 'A2',
      online: true
    },
    {
      username: 'AmharicPro',
      country: '🇪🇹',
      languages: ['Amharic', 'English'],
      level: 'C1',
      online: false
    },
    {
      username: 'ZuluMaster',
      country: '🇿🇦',
      languages: ['Zulu', 'English'],
      level: 'B2',
      online: true
    },
    {
      username: 'HausaExpert',
      country: '🇳🇬',
      languages: ['Hausa', 'English'],
      level: 'B1',
      online: false
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] px-6 py-6 shadow-lg">
        <div className="flex items-center gap-4 mb-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div className="flex-1">
            <h1 className="text-white">Connect with Learners</h1>
            <p className="text-white/80 text-sm">Find language partners</p>
          </div>
          <button className="text-white">
            <Mail className="w-6 h-6" />
          </button>
        </div>

        {/* Connection Status */}
        <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3 mb-4 border border-white/40">
          <div className="flex items-center gap-2">
            <div className={`w-3 h-3 rounded-full ${connectionStatus === 'connected' ? 'bg-green-500' : 'bg-gray-400'}`}></div>
            <p className="text-white text-sm">
              {connectionStatus === 'connected' ? 'Connected' : 'Disconnected'} • {users.filter(u => u.online).length} users online
            </p>
          </div>
        </div>

        {/* Search Bar */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-white/60 w-5 h-5" />
          <input
            type="text"
            placeholder="Search users..."
            className="w-full pl-12 pr-4 py-3 bg-white/20 backdrop-blur-sm border border-white/40 rounded-xl text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50"
          />
        </div>
      </div>

      {/* Filter Chips */}
      <div className="px-6 py-4 flex gap-2 overflow-x-auto">
        <button className="bg-white border-2 border-[#7B2CBF] text-[#7B2CBF] px-4 py-2 rounded-full flex-shrink-0 text-sm">
          All
        </button>
        <button className="bg-gray-100 text-gray-600 px-4 py-2 rounded-full flex-shrink-0 text-sm">
          Online
        </button>
        <button className="bg-gray-100 text-gray-600 px-4 py-2 rounded-full flex-shrink-0 text-sm">
          Learning Swahili
        </button>
        <button className="bg-gray-100 text-gray-600 px-4 py-2 rounded-full flex-shrink-0 text-sm">
          Same Country
        </button>
      </div>

      {/* Users List */}
      <div className="px-6 pb-6 space-y-4">
        {users.map((user, index) => (
          <div key={index} className="bg-white rounded-2xl p-5 shadow-md hover:shadow-lg transition-shadow">
            <div className="flex items-start gap-4">
              {/* Avatar */}
              <div className="relative">
                <div className="w-14 h-14 bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] rounded-full flex items-center justify-center">
                  <span className="text-white text-xl">{user.username.charAt(0)}</span>
                </div>
                {user.online && (
                  <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-green-500 rounded-full border-2 border-white"></div>
                )}
              </div>

              {/* User Info */}
              <div className="flex-1">
                <div className="flex items-center gap-2 mb-1">
                  <h4 className="text-gray-800">{user.username}</h4>
                  <span>{user.country}</span>
                </div>
                
                {/* Languages */}
                <div className="flex flex-wrap gap-2 mb-2">
                  {user.languages.map((lang, i) => (
                    <span key={i} className="bg-[#7B2CBF]/10 text-[#7B2CBF] text-xs px-3 py-1 rounded-full">
                      {lang}
                    </span>
                  ))}
                </div>

                {/* Level Badge */}
                <div className="flex items-center gap-2">
                  <span className="bg-[#FCD116]/20 text-[#FCD116] text-xs px-3 py-1 rounded-full">
                    Level {user.level}
                  </span>
                  {user.online && (
                    <span className="text-green-600 text-xs">● Online now</span>
                  )}
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex flex-col gap-2">
                <button className="w-10 h-10 bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] rounded-full flex items-center justify-center shadow-md hover:shadow-lg transition-shadow">
                  <MessageCircle className="w-5 h-5 text-white" />
                </button>
                <button className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center hover:bg-gray-200 transition-colors">
                  <UserPlus className="w-5 h-5 text-gray-600" />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Empty State (hidden when users present) */}
      {/* <div className="px-6 py-12 text-center">
        <p className="text-5xl mb-4">👥</p>
        <h3 className="text-gray-800 mb-2">No users found</h3>
        <p className="text-gray-600">Try adjusting your filters</p>
      </div> */}
    </div>
  );
}
