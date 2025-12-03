import React from 'react';
import { ArrowLeft, Bell, Volume2, Sun, BookOpen, User, Info, ChevronRight } from 'lucide-react';

export function SettingsScreen() {
  const [darkMode, setDarkMode] = React.useState(false);
  const [soundEffects, setSoundEffects] = React.useState(true);
  const [notifications, setNotifications] = React.useState(true);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-8 shadow-lg">
        <div className="flex items-center gap-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div>
            <h1 className="text-white">Settings</h1>
            <p className="text-white/80 text-sm">Customize your experience</p>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Notifications Section */}
        <div className="bg-white rounded-2xl shadow-md overflow-hidden">
          <div className="p-5 border-b border-gray-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-[#FF6B35]/10 rounded-full flex items-center justify-center">
                <Bell className="w-5 h-5 text-[#FF6B35]" />
              </div>
              <h3 className="text-gray-800">Notifications</h3>
            </div>
          </div>

          <div className="p-5 space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-800">Daily Reminders</p>
                <p className="text-gray-500 text-sm">Get reminded to practice</p>
              </div>
              <label className="relative inline-block w-12 h-6">
                <input
                  type="checkbox"
                  checked={notifications}
                  onChange={() => setNotifications(!notifications)}
                  className="sr-only peer"
                />
                <span className="absolute inset-0 bg-gray-300 rounded-full peer-checked:bg-[#007A3D] transition-colors cursor-pointer"></span>
                <span className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full transition-transform peer-checked:translate-x-6"></span>
              </label>
            </div>

            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-800">Achievement Alerts</p>
                <p className="text-gray-500 text-sm">Celebrate your wins</p>
              </div>
              <label className="relative inline-block w-12 h-6">
                <input type="checkbox" defaultChecked className="sr-only peer" />
                <span className="absolute inset-0 bg-gray-300 rounded-full peer-checked:bg-[#007A3D] transition-colors cursor-pointer"></span>
                <span className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full transition-transform peer-checked:translate-x-6"></span>
              </label>
            </div>

            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-800">Leaderboard Updates</p>
                <p className="text-gray-500 text-sm">Track your ranking</p>
              </div>
              <label className="relative inline-block w-12 h-6">
                <input type="checkbox" className="sr-only peer" />
                <span className="absolute inset-0 bg-gray-300 rounded-full peer-checked:bg-[#007A3D] transition-colors cursor-pointer"></span>
                <span className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full transition-transform peer-checked:translate-x-6"></span>
              </label>
            </div>

            <div className="pt-4 border-t border-gray-100">
              <p className="text-gray-700 mb-2">Reminder Time</p>
              <select className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none">
                <option>9:00 AM</option>
                <option>12:00 PM</option>
                <option>6:00 PM</option>
                <option>9:00 PM</option>
              </select>
            </div>
          </div>
        </div>

        {/* Audio Section */}
        <div className="bg-white rounded-2xl shadow-md overflow-hidden">
          <div className="p-5 border-b border-gray-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-[#7B2CBF]/10 rounded-full flex items-center justify-center">
                <Volume2 className="w-5 h-5 text-[#7B2CBF]" />
              </div>
              <h3 className="text-gray-800">Audio</h3>
            </div>
          </div>

          <div className="p-5 space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-800">Sound Effects</p>
                <p className="text-gray-500 text-sm">Button clicks and alerts</p>
              </div>
              <label className="relative inline-block w-12 h-6">
                <input
                  type="checkbox"
                  checked={soundEffects}
                  onChange={() => setSoundEffects(!soundEffects)}
                  className="sr-only peer"
                />
                <span className="absolute inset-0 bg-gray-300 rounded-full peer-checked:bg-[#007A3D] transition-colors cursor-pointer"></span>
                <span className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full transition-transform peer-checked:translate-x-6"></span>
              </label>
            </div>

            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-800">Voice Output</p>
                <p className="text-gray-500 text-sm">Pronunciation audio</p>
              </div>
              <label className="relative inline-block w-12 h-6">
                <input type="checkbox" defaultChecked className="sr-only peer" />
                <span className="absolute inset-0 bg-gray-300 rounded-full peer-checked:bg-[#007A3D] transition-colors cursor-pointer"></span>
                <span className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full transition-transform peer-checked:translate-x-6"></span>
              </label>
            </div>

            <div className="pt-4 border-t border-gray-100">
              <p className="text-gray-700 mb-3">Volume</p>
              <input type="range" min="0" max="100" defaultValue="70" className="w-full accent-[#007A3D]" />
            </div>
          </div>
        </div>

        {/* Display Section */}
        <div className="bg-white rounded-2xl shadow-md overflow-hidden">
          <div className="p-5 border-b border-gray-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-[#FCD116]/10 rounded-full flex items-center justify-center">
                <Sun className="w-5 h-5 text-[#FCD116]" />
              </div>
              <h3 className="text-gray-800">Display</h3>
            </div>
          </div>

          <div className="p-5 space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-gray-800">Dark Mode</p>
                <p className="text-gray-500 text-sm">Easier on the eyes</p>
              </div>
              <label className="relative inline-block w-12 h-6">
                <input
                  type="checkbox"
                  checked={darkMode}
                  onChange={() => setDarkMode(!darkMode)}
                  className="sr-only peer"
                />
                <span className="absolute inset-0 bg-gray-300 rounded-full peer-checked:bg-[#007A3D] transition-colors cursor-pointer"></span>
                <span className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full transition-transform peer-checked:translate-x-6"></span>
              </label>
            </div>

            <div>
              <p className="text-gray-700 mb-2">Text Size</p>
              <div className="flex gap-2">
                <button className="flex-1 py-2 border-2 border-gray-200 rounded-xl hover:border-[#007A3D] transition-colors">
                  Small
                </button>
                <button className="flex-1 py-2 border-2 border-[#007A3D] bg-[#007A3D]/10 rounded-xl">
                  Medium
                </button>
                <button className="flex-1 py-2 border-2 border-gray-200 rounded-xl hover:border-[#007A3D] transition-colors">
                  Large
                </button>
              </div>
            </div>

            <div className="flex items-center justify-between pt-4 border-t border-gray-100">
              <div>
                <p className="text-gray-800">High Contrast</p>
                <p className="text-gray-500 text-sm">For better visibility</p>
              </div>
              <label className="relative inline-block w-12 h-6">
                <input type="checkbox" className="sr-only peer" />
                <span className="absolute inset-0 bg-gray-300 rounded-full peer-checked:bg-[#007A3D] transition-colors cursor-pointer"></span>
                <span className="absolute left-1 top-1 w-4 h-4 bg-white rounded-full transition-transform peer-checked:translate-x-6"></span>
              </label>
            </div>
          </div>
        </div>

        {/* Learning Section */}
        <div className="bg-white rounded-2xl shadow-md overflow-hidden">
          <div className="p-5 border-b border-gray-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-[#007A3D]/10 rounded-full flex items-center justify-center">
                <BookOpen className="w-5 h-5 text-[#007A3D]" />
              </div>
              <h3 className="text-gray-800">Learning</h3>
            </div>
          </div>

          <div className="p-5 space-y-4">
            <div>
              <p className="text-gray-700 mb-2">Daily Goal</p>
              <select className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none">
                <option>10 minutes</option>
                <option>15 minutes</option>
                <option>20 minutes</option>
                <option>30 minutes</option>
              </select>
            </div>

            <div>
              <p className="text-gray-700 mb-2">Difficulty Preference</p>
              <select className="w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none">
                <option>Beginner</option>
                <option>Intermediate</option>
                <option>Advanced</option>
              </select>
            </div>
          </div>
        </div>

        {/* Account Section */}
        <div className="bg-white rounded-2xl shadow-md overflow-hidden">
          <div className="p-5 border-b border-gray-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-[#CE1126]/10 rounded-full flex items-center justify-center">
                <User className="w-5 h-5 text-[#CE1126]" />
              </div>
              <h3 className="text-gray-800">Account</h3>
            </div>
          </div>

          <div className="p-5 space-y-3">
            <button className="w-full flex items-center justify-between py-3 hover:bg-gray-50 transition-colors rounded-lg px-3">
              <span className="text-gray-700">Change Password</span>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </button>
            <button className="w-full flex items-center justify-between py-3 hover:bg-gray-50 transition-colors rounded-lg px-3">
              <span className="text-gray-700">Privacy Settings</span>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </button>
            <button className="w-full flex items-center justify-between py-3 hover:bg-gray-50 transition-colors rounded-lg px-3">
              <span className="text-red-600">Delete Account</span>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </button>
          </div>
        </div>

        {/* About Section */}
        <div className="bg-white rounded-2xl shadow-md overflow-hidden">
          <div className="p-5 border-b border-gray-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gray-100 rounded-full flex items-center justify-center">
                <Info className="w-5 h-5 text-gray-600" />
              </div>
              <h3 className="text-gray-800">About</h3>
            </div>
          </div>

          <div className="p-5 space-y-3">
            <button className="w-full flex items-center justify-between py-3 hover:bg-gray-50 transition-colors rounded-lg px-3">
              <span className="text-gray-700">App Version</span>
              <span className="text-gray-500">v1.2.3</span>
            </button>
            <button className="w-full flex items-center justify-between py-3 hover:bg-gray-50 transition-colors rounded-lg px-3">
              <span className="text-gray-700">Terms of Service</span>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </button>
            <button className="w-full flex items-center justify-between py-3 hover:bg-gray-50 transition-colors rounded-lg px-3">
              <span className="text-gray-700">Privacy Policy</span>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </button>
            <button className="w-full flex items-center justify-between py-3 hover:bg-gray-50 transition-colors rounded-lg px-3">
              <span className="text-gray-700">Contact Support</span>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
