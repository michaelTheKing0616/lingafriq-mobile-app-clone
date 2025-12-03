import { Clock, Trophy, Flame, Star, Calendar } from 'lucide-react';

export function DailyChallengesScreen() {
  const challenges = [
    {
      id: 1,
      title: 'Early Bird',
      description: 'Complete a lesson before 9 AM',
      reward: 100,
      timeLeft: '3h 24m',
      completed: false,
      difficulty: 'Easy'
    },
    {
      id: 2,
      title: 'Vocabulary Master',
      description: 'Learn 20 new words today',
      reward: 150,
      progress: 14,
      total: 20,
      timeLeft: '8h 12m',
      completed: false,
      difficulty: 'Medium'
    },
    {
      id: 3,
      title: 'Perfect Score',
      description: 'Get 100% on any quiz',
      reward: 200,
      timeLeft: '10h 45m',
      completed: false,
      difficulty: 'Hard'
    },
    {
      id: 4,
      title: 'Social Butterfly',
      description: 'Send 5 messages in global chat',
      reward: 80,
      progress: 3,
      total: 5,
      timeLeft: '12h 30m',
      completed: false,
      difficulty: 'Easy'
    }
  ];

  const completedChallenges = [
    {
      id: 5,
      title: '7-Day Streak',
      description: 'Maintain your learning streak for 7 days',
      reward: 500,
      completedAt: 'Yesterday',
      badge: '🔥'
    },
    {
      id: 6,
      title: 'Game Master',
      description: 'Win 3 language games',
      reward: 180,
      completedAt: '2 days ago',
      badge: '🎮'
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-br from-[#FCD116] via-[#FF6B35] to-[#CE1126] px-6 py-12 rounded-b-[32px]">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors mb-6">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        
        <div className="text-center text-white">
          <Trophy className="w-16 h-16 mx-auto mb-4" />
          <h1 className="mb-2">Daily Challenges</h1>
          <p className="text-white/90">Complete tasks for bonus rewards</p>
        </div>
      </div>

      {/* Timer Card */}
      <div className="px-6 py-6">
        <div className="bg-white rounded-3xl p-6 shadow-lg border-2 border-[#FCD116]">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <Calendar className="w-6 h-6 text-[#FF6B35]" />
              <h3 className="text-gray-900">Today's Challenges</h3>
            </div>
            <div className="flex items-center gap-2 bg-[#FF6B35]/10 px-3 py-1 rounded-full">
              <Clock className="w-4 h-4 text-[#FF6B35]" />
              <span className="text-sm text-[#FF6B35]">Resets in 12h</span>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div className="text-center">
              <p className="text-2xl text-gray-900">4</p>
              <p className="text-xs text-gray-600">Active</p>
            </div>
            <div className="text-center">
              <p className="text-2xl text-green-600">2</p>
              <p className="text-xs text-gray-600">Completed</p>
            </div>
            <div className="text-center">
              <p className="text-2xl text-[#FCD116]">730</p>
              <p className="text-xs text-gray-600">Potential XP</p>
            </div>
          </div>
        </div>
      </div>

      {/* Active Challenges */}
      <div className="px-6 pb-6">
        <h3 className="text-gray-900 mb-4">Active Challenges</h3>
        
        <div className="space-y-3">
          {challenges.map((challenge) => (
            <div key={challenge.id} className="bg-white rounded-2xl p-4 shadow-sm">
              <div className="flex items-start justify-between mb-3">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <h4 className="text-gray-900">{challenge.title}</h4>
                    <span className={`px-2 py-0.5 rounded-full text-xs ${
                      challenge.difficulty === 'Easy' ? 'bg-green-100 text-green-700' :
                      challenge.difficulty === 'Medium' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-red-100 text-red-700'
                    }`}>
                      {challenge.difficulty}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600">{challenge.description}</p>
                </div>
              </div>

              {/* Progress Bar (if applicable) */}
              {challenge.progress !== undefined && (
                <div className="mb-3">
                  <div className="flex items-center justify-between text-xs text-gray-600 mb-1">
                    <span>Progress</span>
                    <span>{challenge.progress}/{challenge.total}</span>
                  </div>
                  <div className="bg-gray-100 rounded-full h-2 overflow-hidden">
                    <div 
                      className="bg-gradient-to-r from-[#007A3D] to-[#FF6B35] h-full rounded-full transition-all"
                      style={{ width: `${(challenge.progress / challenge.total) * 100}%` }}
                    />
                  </div>
                </div>
              )}

              {/* Footer */}
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-4 text-sm">
                  <div className="flex items-center gap-1 text-[#FCD116]">
                    <Star className="w-4 h-4 fill-[#FCD116]" />
                    <span>+{challenge.reward} XP</span>
                  </div>
                  <div className="flex items-center gap-1 text-gray-500">
                    <Clock className="w-4 h-4" />
                    <span>{challenge.timeLeft}</span>
                  </div>
                </div>
                
                <button className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white px-4 py-2 rounded-xl text-sm hover:shadow-lg transition-all">
                  Start
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Completed Challenges */}
      <div className="px-6 pb-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-gray-900">Recently Completed</h3>
          <button className="text-[#007A3D] text-sm">View All</button>
        </div>
        
        <div className="space-y-3">
          {completedChallenges.map((challenge) => (
            <div key={challenge.id} className="bg-gradient-to-br from-green-50 to-emerald-50 rounded-2xl p-4 border-2 border-green-200">
              <div className="flex items-center gap-3">
                <div className="text-3xl">{challenge.badge}</div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <h4 className="text-gray-900">{challenge.title}</h4>
                    <svg className="w-5 h-5 text-green-600" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                    </svg>
                  </div>
                  <p className="text-sm text-gray-600">{challenge.description}</p>
                </div>
              </div>
              
              <div className="flex items-center justify-between mt-3 pt-3 border-t border-green-200">
                <span className="text-sm text-gray-600">{challenge.completedAt}</span>
                <span className="text-sm text-green-600">+{challenge.reward} XP earned</span>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Weekly Bonus Card */}
      <div className="px-6 pb-6">
        <div className="bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] rounded-3xl p-6 text-white">
          <div className="flex items-start gap-4">
            <div className="text-4xl">🎁</div>
            <div className="flex-1">
              <h3 className="text-white mb-2">Weekly Bonus Challenge</h3>
              <p className="text-white/90 text-sm mb-4">
                Complete all daily challenges for 5 days this week to unlock a special 1000 XP bonus!
              </p>
              <div className="flex items-center gap-2">
                <div className="flex gap-1">
                  {[1, 2, 3, 4, 5, 6, 7].map((day) => (
                    <div 
                      key={day}
                      className={`w-8 h-8 rounded-lg flex items-center justify-center text-sm ${
                        day <= 3 ? 'bg-white/30 text-white' : 'bg-white/10'
                      }`}
                    >
                      {day <= 3 ? '✓' : day}
                    </div>
                  ))}
                </div>
              </div>
              <p className="text-white/70 text-xs mt-2">3/5 days completed</p>
            </div>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
