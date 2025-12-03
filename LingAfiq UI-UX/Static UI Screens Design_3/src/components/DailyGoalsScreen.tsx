import React from 'react';
import { ArrowLeft, CheckCircle, RefreshCw } from 'lucide-react';

export function DailyGoalsScreen() {
  const goals = [
    {
      icon: '📚',
      title: 'Complete Lessons',
      progress: 2,
      target: 3,
      completed: false,
      link: 'lessons'
    },
    {
      icon: '🎯',
      title: 'Take Quizzes',
      progress: 1,
      target: 2,
      completed: false,
      link: 'quizzes'
    },
    {
      icon: '🎮',
      title: 'Play Games',
      progress: 3,
      target: 3,
      completed: true,
      link: 'games'
    },
    {
      icon: '💬',
      title: 'Chat with Polie',
      progress: 5,
      target: 10,
      completed: false,
      link: 'chat'
    },
    {
      icon: '📝',
      title: 'Learn Words',
      progress: 15,
      target: 20,
      completed: false,
      link: 'vocabulary'
    }
  ];

  const streakDays = 7;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-6 shadow-lg">
        <div className="flex items-center gap-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div className="flex-1">
            <h1 className="text-white">Daily Goals</h1>
            <p className="text-white/80 text-sm">Keep up the momentum!</p>
          </div>
          <button className="text-white">
            <RefreshCw className="w-5 h-5" />
          </button>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Streak Card */}
        <div className="bg-gradient-to-br from-[#FF6B35] via-[#FCD116] to-[#FF6B35] rounded-3xl p-8 shadow-xl text-center relative overflow-hidden">
          <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZGVmcz48cGF0dGVybiBpZD0iYSIgcGF0dGVyblVuaXRzPSJ1c2VyU3BhY2VPblVzZSIgd2lkdGg9IjQwIiBoZWlnaHQ9IjQwIj48cGF0aCBkPSJNMCAwaDQwdjQwSDB6IiBmaWxsPSJub25lIi8+PHBhdGggZD0iTTAgMjBsMjAtMjAgMjAgMjAtMjAgMjB6IiBmaWxsPSIjZmZmIiBmaWxsLW9wYWNpdHk9Ii4wNSIvPjwvcGF0dGVybj48L2RlZnM+PHJlY3Qgd2lkdGg9IjEwMCUiIGhlaWdodD0iMTAwJSIgZmlsbD0idXJsKCNhKSIvPjwvc3ZnPg==')] opacity-50"></div>
          
          <div className="relative z-10">
            <div className="text-7xl mb-3">🔥</div>
            <h2 className="text-white mb-2">{streakDays} Day Streak</h2>
            <p className="text-white/90">You're unstoppable! Keep learning every day.</p>
          </div>
        </div>

        {/* Goals List */}
        <div className="space-y-4">
          <h3 className="text-gray-800">Today's Goals</h3>
          
          {goals.map((goal, index) => {
            const percentage = (goal.progress / goal.target) * 100;
            
            return (
              <div
                key={index}
                className={`bg-white rounded-2xl p-5 shadow-md cursor-pointer hover:shadow-lg transition-shadow ${
                  goal.completed ? 'border-2 border-green-500' : ''
                }`}
              >
                <div className="flex items-center gap-4 mb-3">
                  <div className={`w-14 h-14 rounded-full flex items-center justify-center ${
                    goal.completed ? 'bg-green-100' : 'bg-gray-100'
                  }`}>
                    <span className="text-3xl">{goal.icon}</span>
                  </div>
                  
                  <div className="flex-1">
                    <h4 className="text-gray-800 mb-1">{goal.title}</h4>
                    <p className={`text-sm ${
                      goal.completed ? 'text-green-600' : 'text-gray-500'
                    }`}>
                      {goal.progress} / {goal.target}
                      {goal.completed && ' ✓ Done'}
                    </p>
                  </div>

                  {goal.completed && (
                    <CheckCircle className="w-6 h-6 text-green-600" />
                  )}
                </div>

                {/* Progress Bar */}
                <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all ${
                      goal.completed ? 'bg-green-500' : 'bg-[#007A3D]'
                    }`}
                    style={{ width: `${Math.min(percentage, 100)}%` }}
                  ></div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Motivation */}
        <div className="bg-white rounded-2xl p-6 shadow-md border-2 border-[#FCD116]">
          <h4 className="text-gray-800 mb-2">💪 Keep Going!</h4>
          <p className="text-gray-600 text-sm">
            You've completed 60% of your daily goals. Just a few more tasks to go!
          </p>
        </div>
      </div>
    </div>
  );
}
