import React from 'react';
import { Menu, Search } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function HomeScreen() {
  const languages = [
    {
      name: 'Swahili',
      image: 'https://images.unsplash.com/photo-1630067458414-0080622bc0df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxTd2FoaWxpJTIwY3VsdHVyZSUyMFRhbnphbmlhfGVufDF8fHx8MTc2NDc1ODg2M3ww&ixlib=rb-4.1.0&q=80&w=1080',
      featured: true
    },
    {
      name: 'Yoruba',
      image: 'https://images.unsplash.com/photo-1665646155658-bdcd66e854db?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxZb3J1YmElMjBOaWdlcmlhJTIwY3VsdHVyZXxlbnwxfHx8fDE3NjQ3NTg4NjN8MA&ixlib=rb-4.1.0&q=80&w=1080',
      featured: true
    },
    {
      name: 'Amharic',
      image: 'https://images.unsplash.com/photo-1633980990916-74317cba1ea3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxFdGhpb3BpYW4lMjBjdWx0dXJlJTIwQW1oYXJpY3xlbnwxfHx8fDE3NjQ3NTg4NjR8MA&ixlib=rb-4.1.0&q=80&w=1080',
      featured: false
    },
    {
      name: 'Zulu',
      image: 'https://images.unsplash.com/photo-1672505155432-f25c16aef2a8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxadWx1JTIwU291dGglMjBBZnJpY2F8ZW58MXx8fHwxNzY0NzU4ODY0fDA&ixlib=rb-4.1.0&q=80&w=1080',
      featured: false
    },
    {
      name: 'Hausa',
      image: 'https://images.unsplash.com/photo-1658402834610-66f1110edbd9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxIYXVzYSUyME5pZ2VyaWElMjBtYXJrZXR8ZW58MXx8fHwxNzY0NzU4ODY1fDA&ixlib=rb-4.1.0&q=80&w=1080',
      featured: false
    },
    {
      name: 'Igbo',
      image: 'https://images.unsplash.com/photo-1729974897977-0696b5e90aa8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxJZ2JvJTIwTmlnZXJpYSUyMGN1bHR1cmV8ZW58MXx8fHwxNzY0NzU4ODY1fDA&ixlib=rb-4.1.0&q=80&w=1080',
      featured: false
    }
  ];

  const greetings = ['Sannu da zuwa', 'Wehcome o', 'Karibu', 'Sawubona', 'Selam'];
  const [currentGreeting, setCurrentGreeting] = React.useState(0);

  React.useEffect(() => {
    const interval = setInterval(() => {
      setCurrentGreeting((prev) => (prev + 1) % greetings.length);
    }, 3000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-b-3xl shadow-lg">
        <div className="px-6 py-6">
          <div className="flex items-center justify-between mb-4">
            <button className="text-white">
              <Menu className="w-6 h-6" />
            </button>
            <div className="w-10 h-10 rounded-full bg-[#FCD116] flex items-center justify-center">
              <span className="text-xl">👤</span>
            </div>
          </div>
          
          <div className="text-white">
            <h2 className="opacity-90 mb-1 transition-all duration-500">
              {greetings[currentGreeting]}
            </h2>
            <h1>Welcome, Learner!</h1>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6">
        {/* Featured Languages Section */}
        <div className="mb-8">
          <h2 className="text-gray-800 mb-2">Featured Languages</h2>
          <p className="text-gray-500 mb-6">Start your learning journey</p>

          <div className="grid grid-cols-2 gap-4">
            {languages.map((language, index) => (
              <div
                key={index}
                className="relative h-48 rounded-2xl overflow-hidden shadow-lg hover:shadow-xl transition-shadow cursor-pointer group"
              >
                <ImageWithFallback 
                  src={language.image}
                  alt={language.name}
                  className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-300"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/30 to-transparent"></div>
                <div className="absolute bottom-0 left-0 right-0 p-4">
                  <h3 className="text-white">{language.name}</h3>
                  {language.featured && (
                    <span className="inline-block bg-[#FCD116] text-black text-xs px-2 py-1 rounded-full mt-2">
                      Featured
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* More Languages Section */}
        <div>
          <h2 className="text-gray-800 mb-4">More Languages</h2>
          
          {/* Search Bar */}
          <div className="relative mb-4">
            <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search languages..."
              className="w-full pl-12 pr-4 py-3 bg-white border-2 border-gray-200 rounded-xl focus:border-[#007A3D] focus:outline-none transition-colors"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            {['Twi', 'Kinyarwanda', 'Shona', 'Somali'].map((lang, index) => (
              <div
                key={index}
                className="bg-white border-2 border-gray-200 rounded-xl p-4 hover:border-[#007A3D] transition-colors cursor-pointer"
              >
                <p className="text-gray-800">{lang}</p>
                <p className="text-gray-500 text-sm mt-1">Coming soon</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
