import { MessageCircle, UserPlus, Book, Award, Flame, Calendar } from 'lucide-react';

export function UserProfileViewScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header with Pattern */}
      <div className="relative bg-gradient-to-br from-[#CE1126] via-[#FF6B35] to-[#FCD116] px-6 pt-12 pb-24 overflow-hidden">
        {/* African Pattern Overlay */}
        <div 
          className="absolute inset-0 opacity-20"
          style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23000000' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
          }}
        />
        
        <div className="relative z-10">
          <button className="p-2 hover:bg-white/20 rounded-lg transition-colors mb-6">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </button>
          
          <div className="flex flex-col items-center">
            <div className="w-28 h-28 rounded-full bg-white flex items-center justify-center text-5xl shadow-2xl ring-4 ring-white/30">
              👤
            </div>
            <h2 className="text-white mt-4">Amara Okafor</h2>
            <div className="flex items-center gap-2 mt-2">
              <span className="text-2xl">🇳🇬</span>
              <span className="text-white/90">Nigeria</span>
            </div>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="px-6 -mt-16 relative z-20">
        <div className="bg-white rounded-3xl shadow-xl p-6">
          {/* Level & XP */}
          <div className="text-center pb-6 border-b border-gray-100">
            <div className="inline-flex items-center gap-3 bg-gradient-to-r from-[#FCD116] to-[#FF6B35] text-white px-6 py-2 rounded-full">
              <Award className="w-5 h-5" />
              <span>Level 15</span>
            </div>
            <p className="text-gray-600 mt-3">12,750 Total XP</p>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-2 gap-4 mt-6">
            <div className="bg-gradient-to-br from-[#007A3D]/10 to-[#007A3D]/5 rounded-2xl p-4 text-center">
              <Book className="w-6 h-6 text-[#007A3D] mx-auto mb-2" />
              <p className="text-2xl text-[#007A3D]">127</p>
              <p className="text-sm text-gray-600">Lessons</p>
            </div>
            
            <div className="bg-gradient-to-br from-[#FF6B35]/10 to-[#FF6B35]/5 rounded-2xl p-4 text-center">
              <svg className="w-6 h-6 text-[#FF6B35] mx-auto mb-2" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
              </svg>
              <p className="text-2xl text-[#FF6B35]">84</p>
              <p className="text-sm text-gray-600">Quizzes</p>
            </div>
            
            <div className="bg-gradient-to-br from-[#FCD116]/10 to-[#FCD116]/5 rounded-2xl p-4 text-center">
              <Flame className="w-6 h-6 text-[#FCD116] mx-auto mb-2 fill-[#FCD116]" />
              <p className="text-2xl text-[#FCD116]">28</p>
              <p className="text-sm text-gray-600">Day Streak</p>
            </div>
            
            <div className="bg-gradient-to-br from-[#7B2CBF]/10 to-[#7B2CBF]/5 rounded-2xl p-4 text-center">
              <Calendar className="w-6 h-6 text-[#7B2CBF] mx-auto mb-2" />
              <p className="text-2xl text-[#7B2CBF]">156</p>
              <p className="text-sm text-gray-600">Days Active</p>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="px-6 mt-6">
        <h3 className="text-gray-900 mb-4">Recent Activity</h3>
        
        <div className="space-y-3">
          <div className="bg-white rounded-2xl p-4 shadow-sm flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#007A3D] to-[#005A2D] flex items-center justify-center text-white">
              📚
            </div>
            <div className="flex-1">
              <p className="text-gray-900">Completed "Greetings in Swahili"</p>
              <p className="text-sm text-gray-500">2 hours ago</p>
            </div>
            <div className="text-[#007A3D]">+50 XP</div>
          </div>
          
          <div className="bg-white rounded-2xl p-4 shadow-sm flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#FF6B35] to-[#FCD116] flex items-center justify-center text-white">
              🎯
            </div>
            <div className="flex-1">
              <p className="text-gray-900">Scored 95% on Yoruba Quiz</p>
              <p className="text-sm text-gray-500">Yesterday</p>
            </div>
            <div className="text-[#FF6B35]">+120 XP</div>
          </div>
          
          <div className="bg-white rounded-2xl p-4 shadow-sm flex items-center gap-4">
            <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#FCD116] to-[#FF6B35] flex items-center justify-center text-white">
              🏆
            </div>
            <div className="flex-1">
              <p className="text-gray-900">Earned "Week Warrior" Badge</p>
              <p className="text-sm text-gray-500">2 days ago</p>
            </div>
            <div className="text-[#FCD116]">+200 XP</div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="px-6 py-6 space-y-3">
        <button className="w-full bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] text-white py-4 rounded-2xl shadow-lg hover:shadow-xl transition-all flex items-center justify-center gap-2">
          <MessageCircle className="w-5 h-5" />
          <span>Send Message</span>
        </button>
        
        <button className="w-full bg-white text-[#007A3D] py-4 rounded-2xl border-2 border-[#007A3D] hover:bg-[#007A3D]/5 transition-all flex items-center justify-center gap-2">
          <UserPlus className="w-5 h-5" />
          <span>Add Friend</span>
        </button>
      </div>

      <div className="h-20" />
    </div>
  );
}
