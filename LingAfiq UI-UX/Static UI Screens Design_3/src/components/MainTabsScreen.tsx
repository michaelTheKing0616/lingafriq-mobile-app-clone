import React from 'react';
import { Home, BookOpen, BarChart3, User, Menu } from 'lucide-react';
import { HomeScreen } from './HomeScreen';

export function MainTabsScreen() {
  const [activeTab, setActiveTab] = React.useState(0);

  const tabs = [
    { icon: Home, label: 'Home', component: HomeScreen },
    { icon: BookOpen, label: 'Courses', component: null },
    { icon: BarChart3, label: 'Standings', component: null },
    { icon: User, label: 'Profile', component: null }
  ];

  const ActiveComponent = tabs[activeTab].component;

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Main Content Area */}
      <div className="flex-1 overflow-y-auto pb-20">
        {ActiveComponent ? <ActiveComponent /> : (
          <div className="flex items-center justify-center h-full">
            <p className="text-gray-500">Tab content here</p>
          </div>
        )}
      </div>

      {/* Bottom Navigation Bar */}
      <div className="fixed bottom-0 left-0 right-0 bg-[#007A3D] rounded-t-3xl shadow-2xl">
        <div className="flex justify-around items-center py-4 px-4">
          {tabs.map((tab, index) => {
            const Icon = tab.icon;
            const isActive = activeTab === index;
            return (
              <button
                key={index}
                onClick={() => setActiveTab(index)}
                className="flex flex-col items-center gap-1 transition-all"
              >
                <Icon 
                  className={`w-6 h-6 ${
                    isActive ? 'text-[#FCD116]' : 'text-white/70'
                  }`}
                />
                <span className={`text-xs ${
                  isActive ? 'text-[#FCD116]' : 'text-white/70'
                }`}>
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
