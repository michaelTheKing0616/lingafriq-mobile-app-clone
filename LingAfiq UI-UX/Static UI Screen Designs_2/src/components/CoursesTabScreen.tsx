import { BookOpen, Play, Clock } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function CoursesTabScreen() {
  const enrolledCourses = [
    {
      id: 1,
      language: 'Swahili',
      flag: '🇹🇿',
      progress: 65,
      lessonsCompleted: 45,
      totalLessons: 70,
      lastAccessed: '2 hours ago',
      image: 'https://images.unsplash.com/photo-1535940360221-641a69c43bac?w=400'
    },
    {
      id: 2,
      language: 'Yoruba',
      flag: '🇳🇬',
      progress: 30,
      lessonsCompleted: 18,
      totalLessons: 60,
      lastAccessed: 'Yesterday',
      image: 'https://images.unsplash.com/photo-1664629153222-a5a66e6c961f?w=400'
    },
    {
      id: 3,
      language: 'Zulu',
      flag: '🇿🇦',
      progress: 15,
      lessonsCompleted: 9,
      totalLessons: 60,
      lastAccessed: '3 days ago',
      image: 'https://images.unsplash.com/photo-1542725752-e9f7259b3881?w=400'
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-12 rounded-b-[32px]">
        <div className="flex items-center justify-between mb-6">
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>
          <h1 className="text-white">My Courses</h1>
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </button>
        </div>
        
        <div className="text-center text-white">
          <p className="text-white/90">Continue your learning journey</p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="px-6 py-6">
        <div className="grid grid-cols-3 gap-3">
          <div className="bg-white rounded-2xl p-4 shadow-sm text-center">
            <p className="text-2xl text-[#007A3D] mb-1">3</p>
            <p className="text-xs text-gray-600">Active Courses</p>
          </div>
          <div className="bg-white rounded-2xl p-4 shadow-sm text-center">
            <p className="text-2xl text-[#FF6B35] mb-1">72</p>
            <p className="text-xs text-gray-600">Total Lessons</p>
          </div>
          <div className="bg-white rounded-2xl p-4 shadow-sm text-center">
            <p className="text-2xl text-[#FCD116] mb-1">37%</p>
            <p className="text-xs text-gray-600">Avg Progress</p>
          </div>
        </div>
      </div>

      {/* Enrolled Courses */}
      <div className="px-6 pb-6">
        <h3 className="text-gray-900 mb-4">Your Languages</h3>
        
        <div className="space-y-4">
          {enrolledCourses.map((course) => (
            <div key={course.id} className="bg-white rounded-3xl overflow-hidden shadow-sm">
              {/* Course Header with Image */}
              <div className="relative h-32">
                <ImageWithFallback
                  src={course.image}
                  alt={course.language}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/60 to-transparent" />
                <div className="absolute bottom-4 left-4 text-white">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-2xl">{course.flag}</span>
                    <h3 className="text-white">{course.language}</h3>
                  </div>
                  <p className="text-white/90 text-sm">{course.lessonsCompleted}/{course.totalLessons} lessons</p>
                </div>
              </div>

              {/* Course Content */}
              <div className="p-4">
                {/* Progress */}
                <div className="mb-4">
                  <div className="flex items-center justify-between text-sm text-gray-600 mb-2">
                    <span>Progress</span>
                    <span>{course.progress}%</span>
                  </div>
                  <div className="bg-gray-100 rounded-full h-2 overflow-hidden">
                    <div 
                      className="bg-gradient-to-r from-[#007A3D] to-[#FF6B35] h-full rounded-full transition-all"
                      style={{ width: `${course.progress}%` }}
                    />
                  </div>
                </div>

                {/* Last Accessed */}
                <div className="flex items-center gap-2 text-sm text-gray-500 mb-4">
                  <Clock className="w-4 h-4" />
                  <span>Last accessed {course.lastAccessed}</span>
                </div>

                {/* Actions */}
                <div className="flex gap-2">
                  <button className="flex-1 bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white py-3 rounded-xl hover:shadow-lg transition-all flex items-center justify-center gap-2">
                    <Play className="w-4 h-4" />
                    <span>Continue</span>
                  </button>
                  <button className="px-4 py-3 bg-gray-100 text-gray-700 rounded-xl hover:bg-gray-200 transition-colors">
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Browse More */}
      <div className="px-6 pb-6">
        <div className="bg-gradient-to-br from-[#FF6B35]/10 to-[#FCD116]/10 rounded-3xl p-6 border-2 border-[#FF6B35]/20">
          <div className="flex items-start gap-4">
            <div className="text-4xl">🌍</div>
            <div className="flex-1">
              <h3 className="text-gray-900 mb-2">Explore More Languages</h3>
              <p className="text-gray-700 text-sm mb-4">
                Discover 20+ African languages available to learn. Start a new course today!
              </p>
              <button className="bg-gradient-to-r from-[#FF6B35] to-[#FCD116] text-white px-6 py-3 rounded-xl hover:shadow-lg transition-all">
                Browse All Languages
              </button>
            </div>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
