import React from 'react';
import { ArrowLeft, BookOpen, Target, Gamepad2, MessageCircle, Book, CheckCircle2, Lock } from 'lucide-react';

const goalsData = {
  streak: 12,
  goals: [
    {
      id: 1,
      icon: BookOpen,
      title: 'Complete Lessons',
      description: 'Finish 2 lessons today',
      current: 1,
      target: 2,
      xp: 50,
      completed: false,
    },
    {
      id: 2,
      icon: Target,
      title: 'Take Quizzes',
      description: 'Complete 3 quizzes',
      current: 3,
      target: 3,
      xp: 75,
      completed: true,
    },
    {
      id: 3,
      icon: Gamepad2,
      title: 'Play Games',
      description: 'Win 1 language game',
      current: 0,
      target: 1,
      xp: 40,
      completed: false,
    },
    {
      id: 4,
      icon: MessageCircle,
      title: 'Chat with Polie',
      description: 'Have a 5-minute conversation',
      current: 2,
      target: 5,
      xp: 60,
      completed: false,
    },
    {
      id: 5,
      icon: Book,
      title: 'Learn New Words',
      description: 'Master 10 vocabulary words',
      current: 7,
      target: 10,
      xp: 30,
      completed: false,
    },
  ],
};

export function DailyGoalsScreen() {
  const completedGoals = goalsData.goals.filter(g => g.completed).length;
  const totalGoals = goalsData.goals.length;
  const overallProgress = (completedGoals / totalGoals) * 100;
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
      {/* Header */}
      <div className="bg-white shadow-sm px-4 py-4 mb-6">
        <div className="flex items-center gap-3 mb-4">
          <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
            <ArrowLeft className="w-6 h-6 text-gray-700" />
          </button>
          <div>
            <h1 className="text-gray-900 text-2xl">Daily Goals</h1>
            <p className="text-gray-600 text-sm">Keep up the great work!</p>
          </div>
        </div>
        
        {/* Overall Progress */}
        <div className="bg-gradient-to-r from-[#007A3D]/10 to-[#00a84f]/10 rounded-2xl p-4">
          <div className="flex items-center justify-between mb-2">
            <span className="text-gray-700">Today's Progress</span>
            <span className="text-[#007A3D]">{completedGoals}/{totalGoals} completed</span>
          </div>
          <div className="w-full h-3 bg-gray-200 rounded-full overflow-hidden">
            <div
              className="h-full bg-gradient-to-r from-[#007A3D] to-[#00a84f] transition-all duration-500 rounded-full"
              style={{ width: `${overallProgress}%` }}
            />
          </div>
        </div>
      </div>

      <div className="px-4 space-y-4">
        {/* Streak Card */}
        <div className="relative overflow-hidden bg-gradient-to-br from-[#007A3D] via-[#00a84f] to-[#00d661] rounded-3xl p-6 shadow-xl">
          {/* Decorative glow effect */}
          <div className="absolute -top-10 -right-10 w-40 h-40 bg-white/20 rounded-full blur-3xl" />
          <div className="absolute -bottom-10 -left-10 w-40 h-40 bg-[#FCD116]/30 rounded-full blur-3xl" />
          
          <div className="relative z-10">
            <div className="flex items-center justify-between mb-4">
              <div>
                <p className="text-white/80 text-sm mb-1">Current Streak</p>
                <div className="flex items-baseline gap-2">
                  <span className="text-5xl text-white">{goalsData.streak}</span>
                  <span className="text-2xl text-white/90">Days</span>
                </div>
              </div>
              <div className="text-6xl">🔥</div>
            </div>
            <p className="text-white/90 text-sm">
              Amazing! You're on fire! Keep learning to maintain your streak.
            </p>
          </div>
        </div>

        {/* Goals List */}
        <div className="space-y-3">
          {goalsData.goals.map((goal) => {
            const progress = (goal.current / goal.target) * 100;
            const Icon = goal.icon;
            
            return (
              <div
                key={goal.id}
                className={`bg-white rounded-2xl p-5 shadow-sm border-2 transition-all ${
                  goal.completed
                    ? 'border-[#007A3D] bg-gradient-to-br from-[#007A3D]/5 to-[#00a84f]/5'
                    : 'border-gray-100 hover:border-gray-200'
                }`}
              >
                <div className="flex items-start gap-4">
                  {/* Icon */}
                  <div
                    className={`w-12 h-12 rounded-xl flex items-center justify-center shrink-0 ${
                      goal.completed
                        ? 'bg-gradient-to-br from-[#007A3D] to-[#00a84f] text-white'
                        : 'bg-gradient-to-br from-gray-100 to-gray-200 text-gray-600'
                    }`}
                  >
                    {goal.completed ? (
                      <CheckCircle2 className="w-6 h-6" />
                    ) : (
                      <Icon className="w-6 h-6" />
                    )}
                  </div>

                  {/* Content */}
                  <div className="flex-1">
                    <div className="flex items-start justify-between mb-2">
                      <div>
                        <h3 className="text-gray-900 mb-1">{goal.title}</h3>
                        <p className="text-sm text-gray-600">{goal.description}</p>
                      </div>
                      <div
                        className={`px-3 py-1 rounded-full text-xs ${
                          goal.completed
                            ? 'bg-[#007A3D] text-white'
                            : 'bg-[#FCD116] text-gray-900'
                        }`}
                      >
                        +{goal.xp} XP
                      </div>
                    </div>

                    {/* Progress */}
                    <div className="space-y-2">
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-gray-600">
                          {goal.current} / {goal.target} {goal.completed ? '✓ Done' : ''}
                        </span>
                        <span
                          className={
                            goal.completed ? 'text-[#007A3D]' : 'text-gray-500'
                          }
                        >
                          {Math.round(progress)}%
                        </span>
                      </div>
                      <div className="w-full h-2 bg-gray-200 rounded-full overflow-hidden">
                        <div
                          className={`h-full transition-all duration-500 rounded-full ${
                            goal.completed
                              ? 'bg-gradient-to-r from-[#007A3D] to-[#00a84f]'
                              : 'bg-gradient-to-r from-gray-400 to-gray-500'
                          }`}
                          style={{ width: `${progress}%` }}
                        />
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Bonus Challenge Card */}
        <div className="bg-gradient-to-br from-[#FF6B35]/10 via-[#FCD116]/10 to-[#FF6B35]/10 rounded-2xl p-5 border-2 border-dashed border-[#FF6B35]/30">
          <div className="flex items-start gap-4">
            <div className="w-12 h-12 bg-gradient-to-br from-[#FF6B35] to-[#FCD116] rounded-xl flex items-center justify-center shrink-0 text-2xl">
              ⭐
            </div>
            <div className="flex-1">
              <div className="flex items-start justify-between mb-2">
                <div>
                  <h3 className="text-gray-900 mb-1">Bonus Challenge</h3>
                  <p className="text-sm text-gray-600">Complete all daily goals</p>
                </div>
                <div className="px-3 py-1 rounded-full text-xs bg-[#FF6B35] text-white">
                  +100 XP
                </div>
              </div>
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Lock className="w-4 h-4" />
                <span>Complete {totalGoals - completedGoals} more goal{totalGoals - completedGoals !== 1 ? 's' : ''} to unlock</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
