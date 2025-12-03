import { Play, Clock, BookOpen } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function HistorySectionsScreen() {
  const sections = [
    {
      id: 1,
      title: 'Origins of Swahili',
      description: 'Learn about the birth and evolution of the Swahili language',
      duration: '12 min',
      completed: true,
      image: 'https://images.unsplash.com/photo-1535940360221-641a69c43bac?w=400'
    },
    {
      id: 2,
      title: 'Swahili City States',
      description: 'Explore the ancient coastal trading cities of East Africa',
      duration: '15 min',
      completed: true,
      image: 'https://images.unsplash.com/photo-1746189897983-ffd3a582a827?w=400'
    },
    {
      id: 3,
      title: 'Arab Influence',
      description: 'Discover how Arabic shaped Swahili language and culture',
      duration: '10 min',
      completed: false,
      image: 'https://images.unsplash.com/photo-1542725752-e9f7259b3881?w=400'
    },
    {
      id: 4,
      title: 'Colonial Period',
      description: 'Understanding Swahili during European colonization',
      duration: '18 min',
      completed: false,
      image: 'https://images.unsplash.com/photo-1664629153222-a5a66e6c961f?w=400'
    },
    {
      id: 5,
      title: 'Modern Swahili',
      description: 'Swahili as a pan-African language today',
      duration: '14 min',
      completed: false,
      image: 'https://images.unsplash.com/photo-1763256294121-303b83e7e767?w=400'
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] px-6 py-4 flex items-center justify-between">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        <h2 className="text-white">Swahili History</h2>
        <div className="w-10" />
      </div>

      {/* Language Header */}
      <div className="px-6 py-6">
        <div className="bg-gradient-to-br from-[#7B2CBF]/10 to-[#9D4EDD]/10 rounded-3xl p-6 border-2 border-[#7B2CBF]/20">
          <div className="flex items-start gap-4">
            <div className="text-5xl">🇹🇿</div>
            <div className="flex-1">
              <h2 className="text-gray-900 mb-2">History of Swahili</h2>
              <p className="text-gray-700 text-sm mb-4">
                Explore the fascinating journey of Swahili from ancient coastal cities to a modern pan-African language.
              </p>
              <div className="flex items-center gap-4 text-sm text-gray-600">
                <div className="flex items-center gap-1">
                  <BookOpen className="w-4 h-4" />
                  <span>5 sections</span>
                </div>
                <div className="flex items-center gap-1">
                  <Clock className="w-4 h-4" />
                  <span>69 min total</span>
                </div>
                <div className="flex items-center gap-1">
                  <svg className="w-4 h-4 text-green-600" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                  <span className="text-green-600">2/5 completed</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Sections List */}
      <div className="px-6 pb-6">
        <h3 className="text-gray-900 mb-4">Historical Sections</h3>
        
        <div className="space-y-4">
          {sections.map((section, index) => (
            <div 
              key={section.id}
              className={`bg-white rounded-2xl overflow-hidden shadow-sm ${
                section.completed ? 'border-2 border-green-200' : ''
              }`}
            >
              <div className="flex items-start gap-4 p-4">
                {/* Thumbnail */}
                <div className="relative w-24 h-24 rounded-xl overflow-hidden flex-shrink-0">
                  <ImageWithFallback
                    src={section.image}
                    alt={section.title}
                    className="w-full h-full object-cover"
                  />
                  {section.completed ? (
                    <div className="absolute inset-0 bg-green-600/80 flex items-center justify-center">
                      <svg className="w-8 h-8 text-white" fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                      </svg>
                    </div>
                  ) : (
                    <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                      <Play className="w-8 h-8 text-white" />
                    </div>
                  )}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between mb-2">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm text-gray-500">Section {index + 1}</span>
                        {section.completed && (
                          <svg className="w-4 h-4 text-green-600" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                          </svg>
                        )}
                      </div>
                      <h4 className="text-gray-900 mb-1">{section.title}</h4>
                      <p className="text-sm text-gray-600 mb-2">{section.description}</p>
                      <div className="flex items-center gap-1 text-sm text-gray-500">
                        <Clock className="w-4 h-4" />
                        <span>{section.duration}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Action Button */}
              <div className="px-4 pb-4">
                <button className={`w-full py-3 rounded-xl transition-all flex items-center justify-center gap-2 ${
                  section.completed
                    ? 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    : 'bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] text-white hover:shadow-lg'
                }`}>
                  <Play className="w-4 h-4" />
                  <span>{section.completed ? 'Watch Again' : 'Watch Now'}</span>
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Progress Card */}
      <div className="px-6 pb-6">
        <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-3xl p-6 text-white">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-white">Your Progress</h3>
            <span className="text-2xl">📚</span>
          </div>
          <div className="bg-white/20 backdrop-blur-sm rounded-full h-3 overflow-hidden mb-2">
            <div className="bg-white h-full rounded-full transition-all" style={{ width: '40%' }} />
          </div>
          <p className="text-white/90 text-sm">2 of 5 sections completed (40%)</p>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
