import { Search, MessageCircle, UserPlus, Wifi, WifiOff } from 'lucide-react';

export function UserConnectionsScreen() {
  const users = [
    { 
      id: 1, 
      name: 'Amara Okafor', 
      country: '🇳🇬', 
      languages: ['Swahili', 'Yoruba'], 
      level: 'Intermediate', 
      online: true,
      isConnected: false 
    },
    { 
      id: 2, 
      name: 'Kwame Mensah', 
      country: '🇬🇭', 
      languages: ['Swahili', 'Twi'], 
      level: 'Advanced', 
      online: true,
      isConnected: true 
    },
    { 
      id: 3, 
      name: 'Zainab Hassan', 
      country: '🇰🇪', 
      languages: ['Swahili'], 
      level: 'Beginner', 
      online: true,
      isConnected: false 
    },
    { 
      id: 4, 
      name: 'Ibrahim Diallo', 
      country: '🇸🇳', 
      languages: ['Wolof', 'French'], 
      level: 'Intermediate', 
      online: false,
      isConnected: true 
    },
    { 
      id: 5, 
      name: 'Thandiwe Nkosi', 
      country: '🇿🇦', 
      languages: ['Zulu', 'Xhosa'], 
      level: 'Advanced', 
      online: false,
      isConnected: false 
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-12 rounded-b-[32px]">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors mb-6">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        
        <div className="flex items-center justify-between">
          <div className="text-white">
            <h1 className="mb-1">Connect with Learners</h1>
            <p className="text-white/90 text-sm">Find study partners worldwide</p>
          </div>
          <button className="p-3 bg-white/20 backdrop-blur-sm rounded-full hover:bg-white/30 transition-colors">
            <MessageCircle className="w-6 h-6 text-white" />
          </button>
        </div>
      </div>

      {/* Connection Status */}
      <div className="px-6 py-4">
        <div className="bg-white rounded-xl p-4 shadow-sm flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-3 h-3 bg-green-400 rounded-full animate-pulse" />
            <span className="text-gray-900">Connected</span>
          </div>
          <span className="text-sm text-gray-600">2,845 users online</span>
        </div>
      </div>

      {/* Search & Filter */}
      <div className="px-6 pb-4">
        <div className="relative mb-4">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search users..."
            className="w-full pl-12 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors bg-white"
          />
        </div>

        {/* Filter Chips */}
        <div className="flex gap-2 overflow-x-auto">
          <button className="px-4 py-2 bg-[#007A3D] text-white rounded-full text-sm whitespace-nowrap">
            All
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Online
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Same Language
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Same Country
          </button>
        </div>
      </div>

      {/* User List */}
      <div className="px-6 pb-6">
        <div className="space-y-3">
          {users.map((user) => (
            <div key={user.id} className="bg-white rounded-2xl p-4 shadow-sm">
              <div className="flex items-start gap-4">
                {/* Avatar */}
                <div className="relative">
                  <div className="w-16 h-16 rounded-full bg-gradient-to-br from-[#007A3D] to-[#FF6B35] flex items-center justify-center text-white text-xl">
                    {user.name[0]}
                  </div>
                  {user.online && (
                    <div className="absolute bottom-0 right-0 w-4 h-4 bg-green-400 border-2 border-white rounded-full" />
                  )}
                </div>

                {/* User Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <h3 className="text-gray-900">{user.name}</h3>
                    <span className="text-lg">{user.country}</span>
                  </div>

                  {/* Languages */}
                  <div className="flex flex-wrap gap-1 mb-2">
                    {user.languages.map((lang, i) => (
                      <span
                        key={i}
                        className="px-2 py-1 bg-[#007A3D]/10 text-[#007A3D] rounded-full text-xs"
                      >
                        {lang}
                      </span>
                    ))}
                  </div>

                  {/* Level Badge */}
                  <div className="inline-flex items-center gap-1 px-2 py-1 bg-gray-100 rounded-full text-xs text-gray-600">
                    <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
                    </svg>
                    <span>{user.level}</span>
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div className="flex gap-2 mt-4">
                {user.isConnected ? (
                  <button className="flex-1 bg-[#7B2CBF] text-white py-2 rounded-xl hover:bg-[#6A25A8] transition-colors flex items-center justify-center gap-2">
                    <MessageCircle className="w-4 h-4" />
                    <span className="text-sm">Message</span>
                  </button>
                ) : (
                  <button className="flex-1 bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-2 rounded-xl hover:shadow-lg transition-all flex items-center justify-center gap-2">
                    <UserPlus className="w-4 h-4" />
                    <span className="text-sm">Connect</span>
                  </button>
                )}
                <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-xl hover:bg-gray-200 transition-colors text-sm">
                  View Profile
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
