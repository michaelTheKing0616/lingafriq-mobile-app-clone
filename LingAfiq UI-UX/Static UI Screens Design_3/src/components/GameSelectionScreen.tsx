import React from 'react';
import { ArrowLeft, Menu, Puzzle, Zap, Mic, Trophy } from 'lucide-react';

export function GameSelectionScreen() {
  const games = [
    {
      icon: Puzzle,
      title: 'Word Match',
      description: 'Match words to their translations',
      difficulty: 'Easy',
      highScore: 1250,
      color: 'from-[#007A3D] to-[#005A2D]'
    },
    {
      icon: Zap,
      title: 'Speed Challenge',
      description: 'Answer as fast as you can',
      difficulty: 'Medium',
      highScore: 2890,
      color: 'from-[#FF6B35] to-[#CE1126]'
    },
    {
      icon: Mic,
      title: 'Pronunciation Practice',
      description: 'Listen and identify correct pronunciation',
      difficulty: 'Hard',
      highScore: 980,
      color: 'from-[#7B2CBF] to-[#CE1126]'
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#FCD116] to-[#FF6B35] rounded-b-3xl shadow-lg px-6 py-8">
        <div className="flex items-center gap-4 mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div className="flex-1">
            <h1 className="text-white">Language Games</h1>
            <p className="text-white/80 text-sm">Learn through play</p>
          </div>
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <Menu className="w-5 h-5 text-white" />
          </button>
        </div>

        {/* Language Selector */}
        <div className="bg-white/20 backdrop-blur-sm rounded-2xl p-4 border border-white/40">
          <p className="text-white/80 text-sm mb-2">Playing in:</p>
          <select className="w-full bg-white rounded-xl px-4 py-3 text-gray-800 focus:outline-none">
            <option>Swahili</option>
            <option>Yoruba</option>
            <option>Amharic</option>
            <option>Zulu</option>
          </select>
        </div>
      </div>

      {/* Games Grid */}
      <div className="px-6 py-6 space-y-6">
        {games.map((game, index) => {
          const Icon = game.icon;
          return (
            <div
              key={index}
              className="bg-white rounded-3xl shadow-lg overflow-hidden cursor-pointer hover:shadow-xl transition-shadow"
            >
              <div className={`h-40 bg-gradient-to-br ${game.color} p-6 flex items-center justify-center relative overflow-hidden`}>
                <div className="absolute inset-0 opacity-20">
                  <div className="w-full h-full" style={{
                    backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 10px, rgba(255,255,255,.1) 10px, rgba(255,255,255,.1) 20px)'
                  }}></div>
                </div>
                <div className="relative z-10 w-24 h-24 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center border-2 border-white/40">
                  <Icon className="w-12 h-12 text-white" />
                </div>
              </div>

              <div className="p-6">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex-1">
                    <h3 className="text-gray-800 mb-2">{game.title}</h3>
                    <p className="text-gray-600 text-sm mb-3">{game.description}</p>
                  </div>
                  <span className={`px-3 py-1 rounded-full text-xs ${
                    game.difficulty === 'Easy' ? 'bg-green-100 text-green-700' :
                    game.difficulty === 'Medium' ? 'bg-yellow-100 text-yellow-700' :
                    'bg-red-100 text-red-700'
                  }`}>
                    {game.difficulty}
                  </span>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Trophy className="w-4 h-4 text-[#FCD116]" />
                    <span className="text-gray-600 text-sm">High Score: {game.highScore}</span>
                  </div>
                  <button className={`bg-gradient-to-r ${game.color} text-white px-6 py-3 rounded-xl shadow-md hover:shadow-lg transition-shadow`}>
                    Play
                  </button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Leaderboard Preview */}
      <div className="px-6 pb-6">
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4 flex items-center gap-2">
            <Trophy className="w-5 h-5 text-[#FCD116]" />
            Top Players This Week
          </h3>
          <div className="space-y-3">
            {[
              { rank: 1, name: 'SwahiliMaster', score: 5430 },
              { rank: 2, name: 'GameChamp', score: 4890 },
              { rank: 3, name: 'You', score: 4120 }
            ].map((player, index) => (
              <div key={index} className={`flex items-center gap-3 ${player.name === 'You' ? 'text-[#007A3D]' : 'text-gray-600'}`}>
                <span className="w-8 text-center">
                  {player.rank <= 3 ? ['🥇', '🥈', '🥉'][player.rank - 1] : `#${player.rank}`}
                </span>
                <span className="flex-1">{player.name}</span>
                <span>{player.score}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
