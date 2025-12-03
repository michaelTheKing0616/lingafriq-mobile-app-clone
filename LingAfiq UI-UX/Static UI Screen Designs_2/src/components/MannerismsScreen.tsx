import { Play, Clock, CheckCircle } from 'lucide-react';

export function MannerismsScreen() {
  const topics = [
    {
      id: 1,
      title: 'Greetings & Respect',
      icon: '🙏',
      description: 'Learn proper ways to greet elders and show respect',
      duration: '8 min',
      completed: true
    },
    {
      id: 2,
      title: 'Eating Etiquette',
      icon: '🍽️',
      description: 'Traditional dining customs and table manners',
      duration: '10 min',
      completed: true
    },
    {
      id: 3,
      title: 'Body Language',
      icon: '👋',
      description: 'Understanding gestures and non-verbal communication',
      duration: '12 min',
      completed: false
    },
    {
      id: 4,
      title: 'Gift Giving',
      icon: '🎁',
      description: 'Customs around giving and receiving gifts',
      duration: '7 min',
      completed: false
    },
    {
      id: 5,
      title: 'Social Gatherings',
      icon: '🎉',
      description: 'Behavior at weddings, funerals, and celebrations',
      duration: '15 min',
      completed: false
    },
    {
      id: 6,
      title: 'Conversation Topics',
      icon: '💬',
      description: 'What to talk about and what to avoid',
      duration: '9 min',
      completed: false
    },
    {
      id: 7,
      title: 'Dress Code',
      icon: '👔',
      description: 'Appropriate attire for different occasions',
      duration: '6 min',
      completed: false
    },
    {
      id: 8,
      title: 'Time & Punctuality',
      icon: '⏰',
      description: 'Cultural perspectives on time and being on time',
      duration: '8 min',
      completed: false
    }
  ];

  const completedCount = topics.filter(t => t.completed).length;
  const progressPercent = (completedCount / topics.length) * 100;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#FF6B35] to-[#FCD116] px-6 py-4 flex items-center justify-between">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        <h2 className="text-white">Cultural Mannerisms</h2>
        <div className="w-10" />
      </div>

      {/* Language Header */}
      <div className="px-6 py-6">
        <div className="bg-gradient-to-br from-[#FF6B35]/10 to-[#FCD116]/10 rounded-3xl p-6 border-2 border-[#FF6B35]/20">
          <div className="flex items-start gap-4">
            <div className="text-5xl">🇹🇿</div>
            <div className="flex-1">
              <h2 className="text-gray-900 mb-2">Swahili Cultural Etiquette</h2>
              <p className="text-gray-700 text-sm mb-4">
                Master the cultural norms and mannerisms to communicate respectfully and authentically in Swahili-speaking communities.
              </p>
              
              {/* Progress */}
              <div className="mb-3">
                <div className="flex items-center justify-between text-sm text-gray-600 mb-2">
                  <span>Your Progress</span>
                  <span>{completedCount}/{topics.length} topics</span>
                </div>
                <div className="bg-gray-200 rounded-full h-2 overflow-hidden">
                  <div 
                    className="bg-gradient-to-r from-[#FF6B35] to-[#FCD116] h-full rounded-full transition-all"
                    style={{ width: `${progressPercent}%` }}
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Topics Grid */}
      <div className="px-6 pb-6">
        <h3 className="text-gray-900 mb-4">Topics</h3>
        
        <div className="grid grid-cols-1 gap-3">
          {topics.map((topic) => (
            <div 
              key={topic.id}
              className={`bg-white rounded-2xl p-4 shadow-sm transition-all ${
                topic.completed ? 'border-2 border-green-200' : 'hover:shadow-md'
              }`}
            >
              <div className="flex items-start gap-4">
                {/* Icon */}
                <div className={`w-14 h-14 rounded-xl flex items-center justify-center text-2xl flex-shrink-0 ${
                  topic.completed ? 'bg-green-100' : 'bg-gradient-to-br from-[#FF6B35]/10 to-[#FCD116]/10'
                }`}>
                  {topic.icon}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between mb-1">
                    <h4 className="text-gray-900">{topic.title}</h4>
                    {topic.completed && (
                      <CheckCircle className="w-5 h-5 text-green-600 flex-shrink-0" />
                    )}
                  </div>
                  <p className="text-sm text-gray-600 mb-3">{topic.description}</p>
                  
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1 text-sm text-gray-500">
                      <Clock className="w-4 h-4" />
                      <span>{topic.duration}</span>
                    </div>
                    
                    <button className={`px-4 py-2 rounded-xl text-sm flex items-center gap-2 transition-all ${
                      topic.completed
                        ? 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                        : 'bg-gradient-to-r from-[#FF6B35] to-[#FCD116] text-white hover:shadow-lg'
                    }`}>
                      <Play className="w-4 h-4" />
                      <span>{topic.completed ? 'Review' : 'Learn'}</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Info Card */}
      <div className="px-6 pb-6">
        <div className="bg-blue-50 border-l-4 border-blue-400 p-4 rounded-r-xl">
          <div className="flex gap-3">
            <div className="text-2xl">💡</div>
            <div>
              <p className="text-sm text-gray-700 mb-2">
                <strong>Why Cultural Mannerisms Matter</strong>
              </p>
              <p className="text-xs text-gray-600">
                Understanding cultural etiquette helps you communicate more effectively and shows respect for the people and traditions you're engaging with. These topics will help you avoid misunderstandings and build stronger connections.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
