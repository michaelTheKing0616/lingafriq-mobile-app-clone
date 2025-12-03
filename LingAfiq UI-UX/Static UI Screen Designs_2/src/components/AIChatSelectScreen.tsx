import { MessageSquare, GraduationCap, Sparkles } from 'lucide-react';

export function AIChatSelectScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header with Pattern */}
      <div className="relative bg-gradient-to-br from-[#7B2CBF] via-[#9D4EDD] to-[#CE1126] px-6 py-12 rounded-b-[32px] overflow-hidden">
        <div 
          className="absolute inset-0 opacity-20"
          style={{
            backgroundImage: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='1'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`
          }}
        />
        
        <div className="relative z-10">
          <button className="p-2 hover:bg-white/20 rounded-lg transition-colors mb-6">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </button>
          
          <div className="text-center text-white">
            <Sparkles className="w-16 h-16 mx-auto mb-4" />
            <h1 className="mb-2">AI Language Assistant</h1>
            <p className="text-white/90">Choose how you'd like to practice</p>
          </div>
        </div>
      </div>

      {/* Mode Cards */}
      <div className="px-6 py-8 space-y-6">
        {/* Translator Mode */}
        <div className="bg-gradient-to-br from-[#007A3D] to-[#005A2D] rounded-3xl p-6 shadow-xl cursor-pointer hover:shadow-2xl transition-all transform hover:scale-[1.02]">
          <div className="flex items-start justify-between mb-4">
            <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center">
              <MessageSquare className="w-8 h-8 text-white" />
            </div>
            <div className="bg-white/20 backdrop-blur-sm px-3 py-1 rounded-full">
              <span className="text-white text-xs">Quick & Easy</span>
            </div>
          </div>
          
          <h2 className="text-white mb-3">Translator Mode</h2>
          <p className="text-white/80 text-sm mb-6">
            Instant translations between English and Swahili. Perfect for quick lookups and learning new phrases on the go.
          </p>
          
          <div className="flex items-center gap-2 text-white/60 text-sm mb-4">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            <span>Real-time translation</span>
          </div>
          <div className="flex items-center gap-2 text-white/60 text-sm mb-4">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            <span>Voice input support</span>
          </div>
          
          <button className="w-full bg-white text-[#007A3D] py-3 rounded-xl hover:bg-gray-100 transition-colors mt-2">
            Start Translating
          </button>
        </div>

        {/* Tutor Mode */}
        <div className="bg-gradient-to-br from-[#FF6B35] to-[#CE1126] rounded-3xl p-6 shadow-xl cursor-pointer hover:shadow-2xl transition-all transform hover:scale-[1.02]">
          <div className="flex items-start justify-between mb-4">
            <div className="w-16 h-16 bg-white/20 backdrop-blur-sm rounded-2xl flex items-center justify-center">
              <GraduationCap className="w-8 h-8 text-white" />
            </div>
            <div className="bg-white/20 backdrop-blur-sm px-3 py-1 rounded-full">
              <span className="text-white text-xs">Interactive Learning</span>
            </div>
          </div>
          
          <h2 className="text-white mb-3">Tutor Mode</h2>
          <p className="text-white/80 text-sm mb-6">
            Practice conversations with your AI tutor Polie. Get personalized feedback, corrections, and learn naturally through dialogue.
          </p>
          
          <div className="flex items-center gap-2 text-white/60 text-sm mb-4">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            <span>Personalized conversations</span>
          </div>
          <div className="flex items-center gap-2 text-white/60 text-sm mb-4">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            <span>Grammar corrections</span>
          </div>
          <div className="flex items-center gap-2 text-white/60 text-sm mb-4">
            <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
            </svg>
            <span>Cultural context tips</span>
          </div>
          
          <button className="w-full bg-white text-[#FF6B35] py-3 rounded-xl hover:bg-gray-100 transition-colors mt-2">
            Start Learning
          </button>
        </div>
      </div>

      {/* Info Card */}
      <div className="px-6 pb-6">
        <div className="bg-blue-50 border-l-4 border-blue-400 p-4 rounded-r-xl">
          <div className="flex gap-3">
            <div className="text-2xl">💬</div>
            <div>
              <p className="text-sm text-gray-700">
                <strong>Meet Polie!</strong> Your AI language companion is powered by advanced language models and trained on authentic African language conversations.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
