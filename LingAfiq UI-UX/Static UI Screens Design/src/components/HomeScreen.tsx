import React from 'react';
import { Menu, Search } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

const greetings = [
  { text: "Sannu da zuwa", language: "Hausa" },
  { text: "Jambo", language: "Swahili" },
  { text: "Ẹ káàbọ̀", language: "Yoruba" },
  { text: "Sawubona", language: "Zulu" },
];

const featuredLanguages = [
  {
    name: "Swahili",
    image: "https://images.unsplash.com/photo-1696299871960-59ae209db58b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzd2FoaWxpJTIwY3VsdHVyZXxlbnwxfHx8fDE3NjQ3NTA2NzB8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
    featured: true,
  },
  {
    name: "Yoruba",
    image: "https://images.unsplash.com/photo-1714124731489-7eb16af0ac91?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx5b3J1YmElMjBuaWdlcmlhfGVufDF8fHx8MTc2NDc1MDY3MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
    featured: true,
  },
  {
    name: "Amharic",
    image: "https://images.unsplash.com/photo-1580502696906-6528c9974126?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxldGhpb3BpYSUyMGFtaGFyaWN8ZW58MXx8fHwxNzY0NzUwNjcxfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
    featured: true,
  },
  {
    name: "Zulu",
    image: "https://images.unsplash.com/photo-1672505155432-f25c16aef2a8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx6dWx1JTIwc291dGglMjBhZnJpY2F8ZW58MXx8fHwxNzY0NzUwNjcxfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
    featured: false,
  },
  {
    name: "Hausa",
    image: "https://images.unsplash.com/photo-1658402834610-66f1110edbd9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxoYXVzYSUyMHdlc3QlMjBhZnJpY2F8ZW58MXx8fHwxNzY0NzUwNjcyfDA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
    featured: false,
  },
  {
    name: "Igbo",
    image: "https://images.unsplash.com/photo-1732027198077-4e29b491d15a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhZnJpY2FuJTIwc2F2YW5uYSUyMHN1bnNldHxlbnwxfHx8fDE3NjQ3NTA2NzB8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral",
    featured: false,
  },
];

export function HomeScreen() {
  const [currentGreeting] = React.useState(greetings[0]);
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
      {/* Header with Gradient */}
      <div className="bg-gradient-to-br from-[#007A3D] to-[#005a2d] rounded-b-[32px] shadow-lg pb-8 pt-12 px-6">
        <div className="flex items-center justify-between mb-6">
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <Menu className="w-6 h-6 text-white" />
          </button>
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <Search className="w-6 h-6 text-white" />
          </button>
        </div>
        
        <div className="text-white">
          <div className="flex items-baseline gap-2 mb-1">
            <p className="text-3xl">{currentGreeting.text}</p>
            <span className="text-sm text-white/70">({currentGreeting.language})</span>
          </div>
          <p className="text-xl text-white/90">Welcome back, Amina!</p>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-6 py-8">
        {/* Featured Languages Section */}
        <div className="mb-8">
          <h2 className="text-gray-900 mb-1">Featured Languages</h2>
          <p className="text-gray-600 mb-6">Start your learning journey</p>
          
          <div className="grid grid-cols-2 gap-4">
            {featuredLanguages.map((language, index) => (
              <div
                key={index}
                className="relative group cursor-pointer overflow-hidden rounded-2xl shadow-md hover:shadow-xl transition-all duration-300 h-48"
              >
                <ImageWithFallback
                  src={language.image}
                  alt={language.name}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
                
                {language.featured && (
                  <div className="absolute top-3 right-3 bg-[#FCD116] text-gray-900 px-3 py-1 rounded-full text-xs">
                    Featured
                  </div>
                )}
                
                <div className="absolute bottom-0 left-0 right-0 p-4">
                  <h3 className="text-white text-xl">{language.name}</h3>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* More Languages Section */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-gray-900">More Languages</h2>
            <button className="text-[#007A3D] text-sm hover:underline">
              View All
            </button>
          </div>
          
          <div className="bg-white rounded-2xl shadow-sm border border-gray-100 p-4">
            <div className="flex items-center gap-3 text-gray-500">
              <Search className="w-5 h-5" />
              <input
                type="text"
                placeholder="Search for languages..."
                className="flex-1 outline-none bg-transparent"
              />
            </div>
          </div>
        </div>
      </div>

      {/* Bottom Navigation Indicator */}
      <div className="fixed bottom-0 left-0 right-0 h-20 bg-white border-t border-gray-200 flex items-center justify-around px-6">
        <div className="flex flex-col items-center gap-1">
          <div className="w-6 h-6 bg-[#007A3D] rounded-lg" />
          <span className="text-xs text-[#007A3D]">Home</span>
        </div>
        <div className="flex flex-col items-center gap-1 opacity-40">
          <div className="w-6 h-6 bg-gray-400 rounded-lg" />
          <span className="text-xs text-gray-600">Courses</span>
        </div>
        <div className="flex flex-col items-center gap-1 opacity-40">
          <div className="w-6 h-6 bg-gray-400 rounded-lg" />
          <span className="text-xs text-gray-600">Standings</span>
        </div>
        <div className="flex flex-col items-center gap-1 opacity-40">
          <div className="w-6 h-6 bg-gray-400 rounded-lg" />
          <span className="text-xs text-gray-600">Profile</span>
        </div>
      </div>
    </div>
  );
}
