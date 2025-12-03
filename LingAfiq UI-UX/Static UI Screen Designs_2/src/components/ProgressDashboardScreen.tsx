import { Book, Headphones, Mic, TrendingUp, Calendar } from 'lucide-react';

export function ProgressDashboardScreen() {
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
          <h1 className="mb-2">Your Progress</h1>
          <p className="text-white/90">Track your learning journey</p>
        </div>
      </div>

      {/* Time Filter */}
      <div className="px-6 py-4">
        <div className="bg-white rounded-full p-1 flex shadow-sm">
          <button className="flex-1 py-2 px-3 rounded-full text-gray-600 text-sm transition-all">
            Week
          </button>
          <button className="flex-1 py-2 px-3 rounded-full bg-[#007A3D] text-white text-sm shadow-sm transition-all">
            Month
          </button>
          <button className="flex-1 py-2 px-3 rounded-full text-gray-600 text-sm transition-all">
            Year
          </button>
          <button className="flex-1 py-2 px-3 rounded-full text-gray-600 text-sm transition-all">
            All
          </button>
        </div>
      </div>

      {/* Overview Cards */}
      <div className="px-6 pb-6">
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white rounded-2xl p-4 shadow-sm">
            <div className="flex items-center justify-between mb-2">
              <Book className="w-6 h-6 text-[#007A3D]" />
              <TrendingUp className="w-4 h-4 text-green-500" />
            </div>
            <p className="text-2xl text-gray-900">342</p>
            <p className="text-sm text-gray-600">Words Learned</p>
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm">
            <div className="flex items-center justify-between mb-2">
              <svg className="w-6 h-6 text-[#FF6B35]" fill="currentColor" viewBox="0 0 20 20">
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>
              </svg>
              <TrendingUp className="w-4 h-4 text-green-500" />
            </div>
            <p className="text-2xl text-gray-900">156</p>
            <p className="text-sm text-gray-600">Known Words</p>
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm">
            <div className="flex items-center justify-between mb-2">
              <Headphones className="w-6 h-6 text-[#7B2CBF]" />
              <TrendingUp className="w-4 h-4 text-green-500" />
            </div>
            <p className="text-2xl text-gray-900">12.5h</p>
            <p className="text-sm text-gray-600">Listening</p>
          </div>

          <div className="bg-white rounded-2xl p-4 shadow-sm">
            <div className="flex items-center justify-between mb-2">
              <Mic className="w-6 h-6 text-[#FCD116]" />
              <TrendingUp className="w-4 h-4 text-green-500" />
            </div>
            <p className="text-2xl text-gray-900">8.2h</p>
            <p className="text-sm text-gray-600">Speaking</p>
          </div>
        </div>
      </div>

      {/* Words Learned Chart */}
      <div className="px-6 pb-6">
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <h3 className="text-gray-900 mb-4">Words Learned Over Time</h3>
          
          {/* Simple Line Chart Visualization */}
          <div className="h-48 flex items-end gap-2">
            {[45, 52, 48, 65, 58, 72, 68, 85, 78, 92, 88, 95].map((height, i) => (
              <div key={i} className="flex-1 flex flex-col items-center">
                <div 
                  className="w-full bg-gradient-to-t from-[#007A3D] to-[#FF6B35] rounded-t-lg transition-all hover:opacity-80"
                  style={{ height: `${height}%` }}
                />
                {i % 3 === 0 && (
                  <span className="text-xs text-gray-500 mt-2">W{i+1}</span>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Activity Distribution */}
      <div className="px-6 pb-6">
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <h3 className="text-gray-900 mb-4">Activity Distribution</h3>
          
          {/* Pie Chart (Simple Representation) */}
          <div className="flex items-center justify-center mb-6">
            <div className="relative w-48 h-48">
              <svg className="w-48 h-48 transform -rotate-90">
                {/* Lessons - 40% */}
                <circle
                  cx="96"
                  cy="96"
                  r="80"
                  fill="none"
                  stroke="#007A3D"
                  strokeWidth="32"
                  strokeDasharray="503"
                  strokeDashoffset="0"
                />
                {/* Quizzes - 30% */}
                <circle
                  cx="96"
                  cy="96"
                  r="80"
                  fill="none"
                  stroke="#FF6B35"
                  strokeWidth="32"
                  strokeDasharray="503"
                  strokeDashoffset="-201"
                />
                {/* Games - 20% */}
                <circle
                  cx="96"
                  cy="96"
                  r="80"
                  fill="none"
                  stroke="#FCD116"
                  strokeWidth="32"
                  strokeDasharray="503"
                  strokeDashoffset="-352"
                />
                {/* Chat - 10% */}
                <circle
                  cx="96"
                  cy="96"
                  r="80"
                  fill="none"
                  stroke="#7B2CBF"
                  strokeWidth="32"
                  strokeDasharray="503"
                  strokeDashoffset="-453"
                />
              </svg>
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="text-center">
                  <p className="text-3xl text-gray-900">28h</p>
                  <p className="text-sm text-gray-600">Total Time</p>
                </div>
              </div>
            </div>
          </div>

          {/* Legend */}
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded-full bg-[#007A3D]" />
                <span className="text-sm text-gray-700">Lessons</span>
              </div>
              <span className="text-sm text-gray-900">40% (11.2h)</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded-full bg-[#FF6B35]" />
                <span className="text-sm text-gray-700">Quizzes</span>
              </div>
              <span className="text-sm text-gray-900">30% (8.4h)</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded-full bg-[#FCD116]" />
                <span className="text-sm text-gray-700">Games</span>
              </div>
              <span className="text-sm text-gray-900">20% (5.6h)</span>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-4 h-4 rounded-full bg-[#7B2CBF]" />
                <span className="text-sm text-gray-700">Chat</span>
              </div>
              <span className="text-sm text-gray-900">10% (2.8h)</span>
            </div>
          </div>
        </div>
      </div>

      {/* Weekly Calendar Heatmap */}
      <div className="px-6 pb-6">
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <h3 className="text-gray-900 mb-4">This Month</h3>
          
          <div className="grid grid-cols-7 gap-2">
            {['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day, i) => (
              <div key={i} className="text-center text-xs text-gray-500">{day}</div>
            ))}
            {[...Array(30)].map((_, i) => {
              const intensity = Math.random();
              return (
                <div
                  key={i}
                  className={`aspect-square rounded-lg ${
                    intensity > 0.7 ? 'bg-[#007A3D]' :
                    intensity > 0.4 ? 'bg-[#007A3D]/60' :
                    intensity > 0.2 ? 'bg-[#007A3D]/30' :
                    'bg-gray-100'
                  }`}
                />
              );
            })}
          </div>
          
          <div className="mt-4 flex items-center justify-between text-xs text-gray-500">
            <span>Less active</span>
            <div className="flex gap-1">
              <div className="w-4 h-4 rounded bg-gray-100" />
              <div className="w-4 h-4 rounded bg-[#007A3D]/30" />
              <div className="w-4 h-4 rounded bg-[#007A3D]/60" />
              <div className="w-4 h-4 rounded bg-[#007A3D]" />
            </div>
            <span>More active</span>
          </div>
        </div>
      </div>

      {/* Insights */}
      <div className="px-6 pb-6">
        <div className="bg-gradient-to-br from-[#007A3D]/10 to-[#FF6B35]/10 rounded-3xl p-6 border-2 border-[#007A3D]/20">
          <div className="flex items-start gap-4">
            <div className="text-3xl">💡</div>
            <div className="flex-1">
              <h3 className="text-gray-900 mb-2">Insights</h3>
              <ul className="space-y-2 text-sm text-gray-700">
                <li className="flex items-start gap-2">
                  <span className="text-[#007A3D]">•</span>
                  <span>Your best learning time is 8-10 AM</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-[#007A3D]">•</span>
                  <span>Most productive on Wednesdays</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-[#007A3D]">•</span>
                  <span>Current CEFR level: <strong>A2</strong></span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
