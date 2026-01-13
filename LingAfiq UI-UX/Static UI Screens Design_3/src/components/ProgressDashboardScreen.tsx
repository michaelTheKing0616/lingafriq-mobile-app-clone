import React from 'react';
import { ArrowLeft, BookOpen, Sparkles, Headphones, Mic, Calendar } from 'lucide-react';
import { LineChart, Line, PieChart, Pie, Cell, BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from 'recharts';

export function ProgressDashboardScreen() {
  const [filter, setFilter] = React.useState<'week' | 'month' | 'year' | 'all'>('week');

  const wordsLearned = [
    { date: 'Mon', words: 15 },
    { date: 'Tue', words: 22 },
    { date: 'Wed', words: 18 },
    { date: 'Thu', words: 25 },
    { date: 'Fri', words: 20 },
    { date: 'Sat', words: 30 },
    { date: 'Sun', words: 28 }
  ];

  const activityDistribution = [
    { name: 'Lessons', value: 35, color: '#007A3D' },
    { name: 'Quizzes', value: 25, color: '#FF6B35' },
    { name: 'Games', value: 20, color: '#7B2CBF' },
    { name: 'Chat', value: 20, color: '#FCD116' }
  ];

  const weeklyActivity = [
    { day: 'Mon', minutes: 25 },
    { day: 'Tue', minutes: 30 },
    { day: 'Wed', minutes: 20 },
    { day: 'Thu', minutes: 35 },
    { day: 'Fri', minutes: 28 },
    { day: 'Sat', minutes: 40 },
    { day: 'Sun', minutes: 32 }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-8 shadow-lg">
        <div className="flex items-center gap-4 mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div>
            <h1 className="text-white">Progress Dashboard</h1>
            <p className="text-white/80 text-sm">Track your learning journey</p>
          </div>
        </div>

        {/* Filter Tabs */}
        <div className="flex gap-2 bg-white/20 backdrop-blur-sm rounded-full p-1">
          {(['week', 'month', 'year', 'all'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`flex-1 py-2 rounded-full transition-all text-sm ${
                filter === f ? 'bg-white text-gray-800' : 'text-white'
              }`}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Overview Cards */}
        <div className="grid grid-cols-2 gap-4">
          <div className="bg-white rounded-2xl p-5 shadow-md">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-[#007A3D]/10 rounded-full flex items-center justify-center">
                <BookOpen className="w-5 h-5 text-[#007A3D]" />
              </div>
              <div>
                <p className="text-gray-600 text-xs">Words Learned</p>
                <p className="text-2xl text-gray-800">158</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 shadow-md">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-[#FCD116]/10 rounded-full flex items-center justify-center">
                <Sparkles className="w-5 h-5 text-[#FCD116]" />
              </div>
              <div>
                <p className="text-gray-600 text-xs">Known Words</p>
                <p className="text-2xl text-gray-800">342</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 shadow-md">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-[#7B2CBF]/10 rounded-full flex items-center justify-center">
                <Headphones className="w-5 h-5 text-[#7B2CBF]" />
              </div>
              <div>
                <p className="text-gray-600 text-xs">Listening Hours</p>
                <p className="text-2xl text-gray-800">12.5</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-2xl p-5 shadow-md">
            <div className="flex items-center gap-3 mb-2">
              <div className="w-10 h-10 bg-[#FF6B35]/10 rounded-full flex items-center justify-center">
                <Mic className="w-5 h-5 text-[#FF6B35]" />
              </div>
              <div>
                <p className="text-gray-600 text-xs">Speaking Hours</p>
                <p className="text-2xl text-gray-800">8.2</p>
              </div>
            </div>
          </div>
        </div>

        {/* Words Learned Chart */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4">Words Learned This Week</h3>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={wordsLearned}>
              <XAxis dataKey="date" stroke="#9CA3AF" />
              <YAxis stroke="#9CA3AF" />
              <Tooltip />
              <Line type="monotone" dataKey="words" stroke="#007A3D" strokeWidth={3} dot={{ fill: '#007A3D', r: 4 }} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Activity Distribution */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4">Activity Distribution</h3>
          <div className="flex items-center gap-6">
            <div className="flex-shrink-0">
              <ResponsiveContainer width={150} height={150}>
                <PieChart>
                  <Pie
                    data={activityDistribution}
                    cx="50%"
                    cy="50%"
                    innerRadius={40}
                    outerRadius={60}
                    paddingAngle={5}
                    dataKey="value"
                  >
                    {activityDistribution.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="flex-1 space-y-2">
              {activityDistribution.map((activity, index) => (
                <div key={index} className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full" style={{ backgroundColor: activity.color }}></div>
                    <span className="text-gray-700 text-sm">{activity.name}</span>
                  </div>
                  <span className="text-gray-600">{activity.value}%</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Time Spent Per Day */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4">Daily Practice Time</h3>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={weeklyActivity}>
              <XAxis dataKey="day" stroke="#9CA3AF" />
              <YAxis stroke="#9CA3AF" />
              <Tooltip />
              <Bar dataKey="minutes" fill="#007A3D" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
          <p className="text-gray-500 text-sm mt-3 text-center">Average: 30 minutes/day</p>
        </div>

        {/* Weekly Heatmap Calendar */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4 flex items-center gap-2">
            <Calendar className="w-5 h-5" />
            Activity Heatmap
          </h3>
          <div className="grid grid-cols-7 gap-2">
            {[...Array(28)].map((_, i) => {
              const intensity = Math.floor(Math.random() * 4);
              const colors = ['bg-gray-100', 'bg-green-200', 'bg-green-400', 'bg-green-600'];
              return (
                <div
                  key={i}
                  className={`aspect-square rounded ${colors[intensity]}`}
                  title={`Day ${i + 1}`}
                ></div>
              );
            })}
          </div>
          <div className="flex items-center justify-between mt-4 text-xs text-gray-500">
            <span>Less</span>
            <div className="flex gap-1">
              <div className="w-3 h-3 bg-gray-100 rounded"></div>
              <div className="w-3 h-3 bg-green-200 rounded"></div>
              <div className="w-3 h-3 bg-green-400 rounded"></div>
              <div className="w-3 h-3 bg-green-600 rounded"></div>
            </div>
            <span>More</span>
          </div>
        </div>

        {/* Insights */}
        <div className="bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] rounded-2xl p-6 text-white shadow-md">
          <h3 className="mb-4">📊 Insights</h3>
          <div className="space-y-3">
            <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3">
              <p className="text-sm">✨ You're most productive on <span className="font-bold">Saturdays</span></p>
            </div>
            <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3">
              <p className="text-sm">🌟 Best learning time: <span className="font-bold">Evening (6-8 PM)</span></p>
            </div>
            <div className="bg-white/20 backdrop-blur-sm rounded-xl p-3">
              <p className="text-sm">🎯 Current CEFR Level: <span className="font-bold">A2 (Elementary)</span></p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
