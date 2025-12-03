import { Bell, Volume2, Eye, BookOpen, User, Info, ChevronRight, Moon, Sun } from 'lucide-react';

export function SettingsScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-12 rounded-b-[32px]">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors mb-6">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        
        <div className="text-center text-white">
          <svg className="w-16 h-16 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          <h1 className="mb-2">Settings</h1>
          <p className="text-white/90">Customize your experience</p>
        </div>
      </div>

      <div className="px-6 py-6 space-y-6">
        {/* Notifications Section */}
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <Bell className="w-6 h-6 text-[#007A3D]" />
            <h3 className="text-gray-900">Notifications</h3>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Daily reminders</span>
              <div className="relative">
                <input type="checkbox" defaultChecked className="sr-only peer" />
                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#007A3D]" />
              </div>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-gray-700">Achievement alerts</span>
              <div className="relative">
                <input type="checkbox" defaultChecked className="sr-only peer" />
                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#007A3D]" />
              </div>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-gray-700">Leaderboard updates</span>
              <div className="relative">
                <input type="checkbox" className="sr-only peer" />
                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#007A3D]" />
              </div>
            </div>

            <div className="pt-2">
              <label className="block text-sm text-gray-600 mb-2">Reminder time</label>
              <select className="w-full px-4 py-2 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors bg-white text-sm">
                <option>8:00 AM</option>
                <option>9:00 AM</option>
                <option>10:00 AM</option>
                <option>6:00 PM</option>
                <option>7:00 PM</option>
              </select>
            </div>
          </div>
        </div>

        {/* Audio Section */}
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <Volume2 className="w-6 h-6 text-[#FF6B35]" />
            <h3 className="text-gray-900">Audio</h3>
          </div>

          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-gray-700">Sound effects</span>
              <div className="relative">
                <input type="checkbox" defaultChecked className="sr-only peer" />
                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#FF6B35]" />
              </div>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-gray-700">Voice output</span>
              <div className="relative">
                <input type="checkbox" defaultChecked className="sr-only peer" />
                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#FF6B35]" />
              </div>
            </div>

            <div className="pt-2">
              <label className="block text-sm text-gray-600 mb-2">TTS Speed</label>
              <input type="range" min="0.5" max="2" step="0.1" defaultValue="1" className="w-full h-2 bg-gray-200 rounded-lg appearance-none cursor-pointer" />
              <div className="flex justify-between text-xs text-gray-500 mt-1">
                <span>0.5x</span>
                <span>1x</span>
                <span>2x</span>
              </div>
            </div>
          </div>
        </div>

        {/* Display Section */}
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <Eye className="w-6 h-6 text-[#7B2CBF]" />
            <h3 className="text-gray-900">Display</h3>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-sm text-gray-600 mb-3">Theme</label>
              <div className="grid grid-cols-3 gap-2">
                <button className="px-4 py-2 bg-[#7B2CBF] text-white rounded-xl text-sm">
                  Auto
                </button>
                <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-xl text-sm hover:bg-gray-200">
                  Light
                </button>
                <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-xl text-sm hover:bg-gray-200">
                  Dark
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm text-gray-600 mb-3">Text size</label>
              <div className="grid grid-cols-3 gap-2">
                <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-xl text-sm hover:bg-gray-200">
                  Small
                </button>
                <button className="px-4 py-2 bg-[#7B2CBF] text-white rounded-xl text-sm">
                  Medium
                </button>
                <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-xl text-sm hover:bg-gray-200">
                  Large
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <span className="text-gray-700">High contrast</span>
              <div className="relative">
                <input type="checkbox" className="sr-only peer" />
                <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-[#7B2CBF]" />
              </div>
            </div>
          </div>
        </div>

        {/* Learning Section */}
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <div className="flex items-center gap-3 mb-4">
            <BookOpen className="w-6 h-6 text-[#FCD116]" />
            <h3 className="text-gray-900">Learning</h3>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-sm text-gray-600 mb-2">Daily goal</label>
              <select className="w-full px-4 py-2 rounded-xl border-2 border-gray-200 focus:border-[#FCD116] outline-none transition-colors bg-white text-sm">
                <option>10 minutes</option>
                <option selected>15 minutes</option>
                <option>20 minutes</option>
                <option>30 minutes</option>
              </select>
            </div>

            <div>
              <label className="block text-sm text-gray-600 mb-2">Difficulty preference</label>
              <select className="w-full px-4 py-2 rounded-xl border-2 border-gray-200 focus:border-[#FCD116] outline-none transition-colors bg-white text-sm">
                <option>Beginner</option>
                <option selected>Intermediate</option>
                <option>Advanced</option>
              </select>
            </div>
          </div>
        </div>

        {/* Account Section */}
        <div className="bg-white rounded-3xl shadow-sm overflow-hidden">
          <button className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors">
            <div className="flex items-center gap-3">
              <User className="w-6 h-6 text-gray-600" />
              <span className="text-gray-900">Change password</span>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>

          <div className="h-px bg-gray-100" />

          <button className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors">
            <div className="flex items-center gap-3">
              <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
              <span className="text-gray-900">Update email</span>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>

          <div className="h-px bg-gray-100" />

          <button className="w-full px-6 py-4 flex items-center justify-between hover:bg-red-50 transition-colors">
            <div className="flex items-center gap-3">
              <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
              </svg>
              <span className="text-red-600">Delete account</span>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>
        </div>

        {/* About Section */}
        <div className="bg-white rounded-3xl shadow-sm overflow-hidden">
          <button className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors">
            <div className="flex items-center gap-3">
              <Info className="w-6 h-6 text-gray-600" />
              <span className="text-gray-900">About Us</span>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>

          <div className="h-px bg-gray-100" />

          <button className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors">
            <div className="flex items-center gap-3">
              <svg className="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <span className="text-gray-900">Privacy policy</span>
            </div>
            <ChevronRight className="w-5 h-5 text-gray-400" />
          </button>

          <div className="h-px bg-gray-100" />

          <div className="px-6 py-4 text-center">
            <p className="text-sm text-gray-500">Version 2.1.0</p>
          </div>
        </div>

        {/* Logout Button */}
        <button className="w-full bg-red-500 text-white py-4 rounded-2xl hover:bg-red-600 transition-colors">
          Logout
        </button>
      </div>

      <div className="h-20" />
    </div>
  );
}
