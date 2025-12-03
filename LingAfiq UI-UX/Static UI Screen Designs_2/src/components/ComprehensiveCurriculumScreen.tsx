import { Book, Lock, CheckCircle, ChevronDown, ChevronUp } from 'lucide-react';

export function ComprehensiveCurriculumScreen() {
  const curriculum = [
    {
      level: 'A1',
      title: 'Beginner',
      color: '#007A3D',
      progress: 75,
      units: [
        {
          title: 'Unit 1: Greetings & Introductions',
          lessons: 8,
          completed: 8,
          locked: false
        },
        {
          title: 'Unit 2: Numbers & Time',
          lessons: 6,
          completed: 4,
          locked: false
        },
        {
          title: 'Unit 3: Family & Friends',
          lessons: 7,
          completed: 0,
          locked: true
        }
      ]
    },
    {
      level: 'A2',
      title: 'Elementary',
      color: '#FF6B35',
      progress: 30,
      units: [
        {
          title: 'Unit 1: Daily Routines',
          lessons: 8,
          completed: 3,
          locked: false
        },
        {
          title: 'Unit 2: Shopping & Food',
          lessons: 10,
          completed: 0,
          locked: true
        }
      ]
    },
    {
      level: 'B1',
      title: 'Intermediate',
      color: '#FCD116',
      progress: 0,
      units: [
        {
          title: 'Unit 1: Travel & Transportation',
          lessons: 12,
          completed: 0,
          locked: true
        }
      ]
    }
  ];

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
          <Book className="w-16 h-16 mx-auto mb-4" />
          <h1 className="mb-2">Comprehensive Curriculum</h1>
          <p className="text-white/90">Structured learning path</p>
        </div>
      </div>

      {/* Language Selector */}
      <div className="px-6 py-4">
        <label className="block text-gray-700 mb-3">Select Language</label>
        <select className="w-full px-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors bg-white">
          <option>🇹🇿 Swahili</option>
          <option>🇳🇬 Yoruba</option>
          <option>🇪🇹 Amharic</option>
          <option>🇿🇦 Zulu</option>
        </select>
      </div>

      {/* Curriculum Content */}
      <div className="px-6 pb-6 space-y-4">
        {curriculum.map((level, levelIndex) => (
          <div key={level.level} className="bg-white rounded-3xl shadow-sm overflow-hidden">
            {/* Level Header */}
            <div 
              className="p-6 cursor-pointer"
              style={{
                background: `linear-gradient(135deg, ${level.color}15 0%, ${level.color}05 100%)`
              }}
            >
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div 
                    className="w-12 h-12 rounded-xl flex items-center justify-center text-white"
                    style={{ backgroundColor: level.color }}
                  >
                    <span className="text-lg">{level.level}</span>
                  </div>
                  <div>
                    <h3 className="text-gray-900">{level.title}</h3>
                    <p className="text-sm text-gray-600">{level.units.length} units</p>
                  </div>
                </div>
                <ChevronDown className="w-6 h-6 text-gray-400" />
              </div>

              {/* Progress Bar */}
              <div className="mb-2">
                <div className="flex items-center justify-between text-sm text-gray-600 mb-2">
                  <span>Progress</span>
                  <span>{level.progress}%</span>
                </div>
                <div className="bg-gray-200 rounded-full h-2 overflow-hidden">
                  <div 
                    className="h-full rounded-full transition-all"
                    style={{
                      width: `${level.progress}%`,
                      backgroundColor: level.color
                    }}
                  />
                </div>
              </div>
            </div>

            {/* Units */}
            <div className="p-6 pt-0 space-y-3">
              {level.units.map((unit, unitIndex) => (
                <div 
                  key={unitIndex}
                  className={`border-2 rounded-2xl p-4 transition-all ${
                    unit.locked 
                      ? 'border-gray-200 bg-gray-50 opacity-60' 
                      : 'border-gray-200 bg-white hover:border-gray-300'
                  }`}
                >
                  <div className="flex items-start gap-3">
                    {/* Icon */}
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${
                      unit.locked 
                        ? 'bg-gray-200' 
                        : unit.completed === unit.lessons
                        ? 'bg-green-100'
                        : 'bg-blue-100'
                    }`}>
                      {unit.locked ? (
                        <Lock className="w-5 h-5 text-gray-500" />
                      ) : unit.completed === unit.lessons ? (
                        <CheckCircle className="w-5 h-5 text-green-600" />
                      ) : (
                        <Book className="w-5 h-5 text-blue-600" />
                      )}
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0">
                      <h4 className="text-gray-900 mb-1">{unit.title}</h4>
                      <div className="flex items-center gap-4 text-sm text-gray-600">
                        <span>{unit.lessons} lessons</span>
                        {!unit.locked && (
                          <span className="text-green-600">{unit.completed}/{unit.lessons} completed</span>
                        )}
                      </div>

                      {/* Mini Progress */}
                      {!unit.locked && unit.completed > 0 && unit.completed < unit.lessons && (
                        <div className="mt-2 bg-gray-100 rounded-full h-1.5 overflow-hidden">
                          <div 
                            className="h-full rounded-full"
                            style={{
                              width: `${(unit.completed / unit.lessons) * 100}%`,
                              backgroundColor: level.color
                            }}
                          />
                        </div>
                      )}
                    </div>

                    {/* Arrow */}
                    {!unit.locked && (
                      <svg className="w-5 h-5 text-gray-400 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                      </svg>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Info Card */}
      <div className="px-6 pb-6">
        <div className="bg-gradient-to-br from-blue-50 to-purple-50 border-l-4 border-blue-400 p-4 rounded-r-xl">
          <div className="flex gap-3">
            <div className="text-2xl">📚</div>
            <div>
              <p className="text-sm text-gray-700 mb-2">
                <strong>CEFR Aligned Curriculum</strong>
              </p>
              <p className="text-xs text-gray-600">
                Our curriculum follows the Common European Framework of Reference for Languages (CEFR) standards from A1 to C2 levels.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
