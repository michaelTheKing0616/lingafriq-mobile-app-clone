import React from 'react';
import { Home, FolderOpen, BarChart3, User } from 'lucide-react';

export function MainTabsScreen() {
  const [activeTab, setActiveTab] = React.useState('home');
  
  const tabs = [
    { id: 'home', icon: Home, label: 'Home' },
    { id: 'courses', icon: FolderOpen, label: 'Courses' },
    { id: 'standings', icon: BarChart3, label: 'Standings' },
    { id: 'profile', icon: User, label: 'Profile' },
  ];
  
  return (
    <div className="h-screen bg-white flex flex-col">
      {/* Main Content Area */}
      <div className="flex-1 overflow-y-auto bg-gradient-to-b from-slate-50 to-white">
        <div className="p-8 text-center">
          <div className="text-6xl mb-4">
            {activeTab === 'home' && '🏠'}
            {activeTab === 'courses' && '📚'}
            {activeTab === 'standings' && '🏆'}
            {activeTab === 'profile' && '👤'}
          </div>
          <h2 className="text-gray-900 text-2xl mb-2 capitalize">{activeTab} Tab</h2>
          <p className="text-gray-600">Content for {activeTab} will appear here</p>
        </div>
      </div>

      {/* Bottom Navigation */}
      <div className="bg-[#007A3D] rounded-t-[24px] shadow-2xl">
        <div className="flex items-center justify-around px-4 py-4">
          {tabs.map((tab) => {
            const Icon = tab.icon;
            const isActive = activeTab === tab.id;
            
            return (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex flex-col items-center gap-1 transition-all ${
                  isActive ? 'transform scale-110' : ''
                }`}
              >
                <div
                  className={`p-2.5 rounded-xl transition-all ${
                    isActive 
                      ? 'bg-white/20' 
                      : ''
                  }`}
                >
                  <Icon
                    className={`w-6 h-6 transition-colors ${
                      isActive ? 'text-[#FCD116]' : 'text-white/70'
                    }`}
                  />
                </div>
                <span
                  className={`text-xs transition-colors ${
                    isActive ? 'text-[#FCD116]' : 'text-white/70'
                  }`}
                >
                  {tab.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
