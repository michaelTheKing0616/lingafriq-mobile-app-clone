import React from 'react';
import { Plus, Clock, TrendingUp } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function CoursesTabScreen() {
  const enrolledCourses = [
    {
      language: 'Swahili',
      progress: 65,
      image: 'https://images.unsplash.com/photo-1630067458414-0080622bc0df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxTd2FoaWxpJTIwY3VsdHVyZSUyMFRhbnphbmlhfGVufDF8fHx8MTc2NDc1ODg2M3ww&ixlib=rb-4.1.0&q=80&w=1080',
      lastAccessed: '2 hours ago',
      level: 'A2'
    },
    {
      language: 'Yoruba',
      progress: 35,
      image: 'https://images.unsplash.com/photo-1665646155658-bdcd66e854db?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxZb3J1YmElMjBOaWdlcmlhJTIwY3VsdHVyZXxlbnwxfHx8fDE3NjQ3NTg4NjN8MA&ixlib=rb-4.1.0&q=80&w=1080',
      lastAccessed: '1 day ago',
      level: 'A1'
    },
    {
      language: 'Amharic',
      progress: 15,
      image: 'https://images.unsplash.com/photo-1633980990916-74317cba1ea3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxFdGhpb3BpYW4lMjBjdWx0dXJlJTIwQW1oYXJpY3xlbnwxfHx8fDE3NjQ3NTg4NjR8MA&ixlib=rb-4.1.0&q=80&w=1080',
      lastAccessed: '3 days ago',
      level: 'A1'
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-b-3xl shadow-lg px-6 py-8">
        <h1 className="text-white mb-2">My Courses</h1>
        <p className="text-white/80 text-sm">Continue your learning journey</p>
      </div>

      {/* Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Enrolled Courses */}
        <div>
          <h3 className="text-gray-800 mb-4">Your Languages</h3>
          <div className="space-y-4">
            {enrolledCourses.map((course, index) => (
              <div key={index} className="bg-white rounded-2xl shadow-md overflow-hidden hover:shadow-lg transition-shadow cursor-pointer">
                <div className="flex items-center gap-4 p-5">
                  {/* Language Image */}
                  <div className="w-20 h-20 rounded-xl overflow-hidden flex-shrink-0">
                    <ImageWithFallback 
                      src={course.image}
                      alt={course.language}
                      className="w-full h-full object-cover"
                    />
                  </div>

                  {/* Course Info */}
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-2">
                      <h3 className="text-gray-800">{course.language}</h3>
                      <span className="bg-[#007A3D]/10 text-[#007A3D] text-xs px-2 py-1 rounded-full">
                        {course.level}
                      </span>
                    </div>
                    
                    {/* Progress Bar */}
                    <div className="mb-2">
                      <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
                        <div 
                          className="h-full bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-full transition-all"
                          style={{ width: `${course.progress}%` }}
                        ></div>
                      </div>
                    </div>

                    <div className="flex items-center justify-between text-sm">
                      <span className="text-[#007A3D]">{course.progress}% Complete</span>
                      <div className="flex items-center gap-1 text-gray-500">
                        <Clock className="w-3 h-3" />
                        <span className="text-xs">{course.lastAccessed}</span>
                      </div>
                    </div>
                  </div>

                  {/* Continue Button */}
                  <button className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white px-6 py-3 rounded-xl shadow-md hover:shadow-lg transition-shadow">
                    Continue
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Browse All Languages */}
        <div className="bg-white rounded-2xl shadow-md p-6">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-12 h-12 bg-[#FF6B35]/10 rounded-full flex items-center justify-center">
              <Plus className="w-6 h-6 text-[#FF6B35]" />
            </div>
            <div className="flex-1">
              <h3 className="text-gray-800">Add New Language</h3>
              <p className="text-gray-600 text-sm">Explore 15+ African languages</p>
            </div>
          </div>
          <button className="w-full bg-gradient-to-r from-[#FF6B35] to-[#CE1126] text-white py-4 rounded-xl shadow-md hover:shadow-lg transition-shadow">
            Browse All Languages
          </button>
        </div>

        {/* Statistics */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white rounded-2xl p-5 shadow-md text-center">
            <div className="w-12 h-12 bg-[#007A3D]/10 rounded-full flex items-center justify-center mx-auto mb-2">
              <TrendingUp className="w-6 h-6 text-[#007A3D]" />
            </div>
            <p className="text-2xl text-gray-800 mb-1">3</p>
            <p className="text-gray-500 text-sm">Active Courses</p>
          </div>

          <div className="bg-white rounded-2xl p-5 shadow-md text-center">
            <div className="w-12 h-12 bg-[#FCD116]/10 rounded-full flex items-center justify-center mx-auto mb-2">
              <Clock className="w-6 h-6 text-[#FCD116]" />
            </div>
            <p className="text-2xl text-gray-800 mb-1">45h</p>
            <p className="text-gray-500 text-sm">Total Time</p>
          </div>
        </div>
      </div>
    </div>
  );
}
