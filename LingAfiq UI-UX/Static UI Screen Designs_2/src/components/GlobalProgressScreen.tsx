import { Trophy, Users, Globe, Languages } from 'lucide-react';

export function GlobalProgressScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="relative bg-gradient-to-br from-[#FCD116] via-[#FF6B35] to-[#CE1126] px-6 py-12 rounded-b-[32px] shadow-lg overflow-hidden">
        <div 
          className="absolute inset-0 opacity-10"
          style={{
            backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 10px, rgba(0,0,0,.1) 10px, rgba(0,0,0,.1) 20px)'
          }}
        />
        
        <div className="relative z-10">
          <button className="p-2 hover:bg-white/20 rounded-lg transition-colors mb-6">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </button>
          
          <div className="text-center text-white">
            <Trophy className="w-16 h-16 mx-auto mb-4 text-white" />
            <h1 className="mb-2">Global Ranking</h1>
            <p className="text-white/90">Top learners worldwide</p>
          </div>
        </div>
      </div>

      {/* Global Stats */}
      <div className="px-6 py-6">
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white rounded-2xl p-4 shadow-sm text-center">
            <Globe className="w-8 h-8 text-[#007A3D] mx-auto mb-2" />
            <p className="text-2xl text-gray-900">2.4M</p>
            <p className="text-sm text-gray-600">Total Users</p>
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm text-center">
            <svg className="w-8 h-8 text-[#FF6B35] mx-auto mb-2" fill="currentColor" viewBox="0 0 20 20">
              <path d="M9 4.804A7.968 7.968 0 005.5 4c-1.255 0-2.443.29-3.5.804v10A7.969 7.969 0 015.5 14c1.669 0 3.218.51 4.5 1.385A7.962 7.962 0 0114.5 14c1.255 0 2.443.29 3.5.804v-10A7.968 7.968 0 0014.5 4c-1.255 0-2.443.29-3.5.804V12a1 1 0 11-2 0V4.804z"/>
            </svg>
            <p className="text-2xl text-gray-900">45.6M</p>
            <p className="text-sm text-gray-600">Words Learned</p>
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm text-center">
            <svg className="w-8 h-8 text-[#7B2CBF] mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <p className="text-2xl text-gray-900">128K</p>
            <p className="text-sm text-gray-600">Total Hours</p>
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm text-center">
            <Languages className="w-8 h-8 text-[#FCD116] mx-auto mb-2" />
            <p className="text-2xl text-gray-900">24</p>
            <p className="text-sm text-gray-600">Active Languages</p>
          </div>
        </div>
      </div>

      {/* Top Languages Chart */}
      <div className="px-6 pb-6">
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <h3 className="text-gray-900 mb-4">Most Popular Languages</h3>
          
          <div className="space-y-4">
            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="text-lg">🇹🇿</span>
                  <span className="text-gray-900">Swahili</span>
                </div>
                <span className="text-sm text-gray-600">850K learners</span>
              </div>
              <div className="bg-gray-100 rounded-full h-3 overflow-hidden">
                <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] h-full rounded-full" style={{ width: '85%' }} />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="text-lg">🇳🇬</span>
                  <span className="text-gray-900">Yoruba</span>
                </div>
                <span className="text-sm text-gray-600">720K learners</span>
              </div>
              <div className="bg-gray-100 rounded-full h-3 overflow-hidden">
                <div className="bg-gradient-to-r from-[#FF6B35] to-[#CE1126] h-full rounded-full" style={{ width: '72%' }} />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="text-lg">🇿🇦</span>
                  <span className="text-gray-900">Zulu</span>
                </div>
                <span className="text-sm text-gray-600">580K learners</span>
              </div>
              <div className="bg-gray-100 rounded-full h-3 overflow-hidden">
                <div className="bg-gradient-to-r from-[#FCD116] to-[#FF6B35] h-full rounded-full" style={{ width: '58%' }} />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="text-lg">🇪🇹</span>
                  <span className="text-gray-900">Amharic</span>
                </div>
                <span className="text-sm text-gray-600">450K learners</span>
              </div>
              <div className="bg-gray-100 rounded-full h-3 overflow-hidden">
                <div className="bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] h-full rounded-full" style={{ width: '45%' }} />
              </div>
            </div>

            <div>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className="text-lg">🇳🇬</span>
                  <span className="text-gray-900">Hausa</span>
                </div>
                <span className="text-sm text-gray-600">380K learners</span>
              </div>
              <div className="bg-gray-100 rounded-full h-3 overflow-hidden">
                <div className="bg-gradient-to-r from-[#007A3D] to-[#FF6B35] h-full rounded-full" style={{ width: '38%' }} />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Top Global Learners */}
      <div className="px-6 pb-6">
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-gray-900">Top Global Learners</h3>
            <button className="text-[#007A3D] text-sm">See All</button>
          </div>
          
          {/* Podium Style Top 3 */}
          <div className="flex items-end justify-center gap-2 mb-6">
            {/* 2nd Place */}
            <div className="flex-1 text-center">
              <div className="w-16 h-16 mx-auto mb-2 rounded-full bg-gradient-to-br from-gray-300 to-gray-400 flex items-center justify-center text-2xl ring-4 ring-gray-200">
                🥈
              </div>
              <div className="bg-gradient-to-b from-gray-300 to-gray-400 rounded-t-2xl p-4 h-24 flex flex-col justify-center">
                <p className="text-white text-sm">Kwame M.</p>
                <p className="text-white/80 text-xs">14,920 XP</p>
              </div>
            </div>

            {/* 1st Place */}
            <div className="flex-1 text-center">
              <div className="w-20 h-20 mx-auto mb-2 rounded-full bg-gradient-to-br from-[#FCD116] to-[#FF6B35] flex items-center justify-center text-3xl ring-4 ring-yellow-200 shadow-lg">
                🏆
              </div>
              <div className="bg-gradient-to-b from-[#FCD116] to-[#FF6B35] rounded-t-2xl p-4 h-32 flex flex-col justify-center">
                <p className="text-white">Amara O.</p>
                <p className="text-white/90 text-sm">15,840 XP</p>
              </div>
            </div>

            {/* 3rd Place */}
            <div className="flex-1 text-center">
              <div className="w-16 h-16 mx-auto mb-2 rounded-full bg-gradient-to-br from-orange-400 to-orange-600 flex items-center justify-center text-2xl ring-4 ring-orange-200">
                🥉
              </div>
              <div className="bg-gradient-to-b from-orange-400 to-orange-600 rounded-t-2xl p-4 h-20 flex flex-col justify-center">
                <p className="text-white text-sm">Zainab H.</p>
                <p className="text-white/80 text-xs">14,105 XP</p>
              </div>
            </div>
          </div>

          {/* Rest of Top 10 */}
          <div className="space-y-2">
            {[
              { rank: 4, name: 'Thandiwe Nkosi', country: '🇿🇦', xp: 12750 },
              { rank: 5, name: 'Ibrahim Diallo', country: '🇸🇳', xp: 11890 },
              { rank: 6, name: 'Fatima Abdi', country: '🇪🇹', xp: 10920 },
            ].map((user) => (
              <div key={user.rank} className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl">
                <div className="w-8 text-center text-gray-600">#{user.rank}</div>
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-gray-200 to-gray-300 flex items-center justify-center">
                  👤
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className="text-gray-900">{user.name}</span>
                    <span>{user.country}</span>
                  </div>
                </div>
                <span className="text-gray-600 text-sm">{user.xp.toLocaleString()} XP</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
