import { Send, Users, ChevronDown } from 'lucide-react';

export function GlobalChatScreen() {
  const messages = [
    { id: 1, user: 'Amara', country: '🇳🇬', message: 'Jambo everyone! Just finished my first Swahili lesson!', time: '10:24 AM', isMe: false },
    { id: 2, user: 'Kwame', country: '🇬🇭', message: 'Congratulations Amara! Keep it up!', time: '10:25 AM', isMe: false },
    { id: 3, user: 'You', country: '🇬🇭', message: 'That\'s amazing! How did you find it?', time: '10:26 AM', isMe: true },
    { id: 4, user: 'Amara', country: '🇳🇬', message: 'It was challenging but fun! The pronunciation is tricky 😅', time: '10:27 AM', isMe: false },
    { id: 5, user: 'Zainab', country: '🇰🇪', message: 'Practice makes perfect! Polie AI tutor really helps with pronunciation', time: '10:28 AM', isMe: false },
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-4 flex-shrink-0">
        <div className="flex items-center justify-between mb-4">
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </button>
          <h2 className="text-white">Global Chat</h2>
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <Users className="w-6 h-6 text-white" />
          </button>
        </div>

        {/* Room Selector */}
        <div className="flex items-center gap-2 bg-white/10 backdrop-blur-sm px-4 py-2 rounded-xl">
          <span className="text-white">Room: Swahili Learners</span>
          <ChevronDown className="w-4 h-4 text-white ml-auto" />
        </div>

        {/* Online Count */}
        <div className="flex items-center gap-2 mt-3">
          <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
          <span className="text-white/80 text-sm">2,845 online</span>
        </div>
      </div>

      {/* Room Chips */}
      <div className="px-6 py-3 bg-white border-b border-gray-200 flex-shrink-0">
        <div className="flex gap-2 overflow-x-auto">
          <button className="px-4 py-2 bg-[#007A3D] text-white rounded-full text-sm whitespace-nowrap">
            General
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Help & Questions
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Cultural Exchange
          </button>
          <button className="px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm whitespace-nowrap hover:bg-gray-200">
            Practice Partners
          </button>
        </div>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto px-6 py-4">
        <div className="space-y-4">
          {messages.map((msg) => (
            <div key={msg.id} className={`flex gap-3 ${msg.isMe ? 'flex-row-reverse' : ''}`}>
              {/* Avatar */}
              {!msg.isMe && (
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#007A3D] to-[#FF6B35] flex items-center justify-center flex-shrink-0 text-white">
                  {msg.user[0]}
                </div>
              )}
              
              {/* Message Content */}
              <div className={`flex-1 max-w-[75%] ${msg.isMe ? 'items-end' : ''}`}>
                {!msg.isMe && (
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm text-gray-900">{msg.user}</span>
                    <span className="text-sm">{msg.country}</span>
                  </div>
                )}
                
                <div className={`rounded-2xl px-4 py-3 ${
                  msg.isMe 
                    ? 'bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white rounded-br-none' 
                    : 'bg-white shadow-sm rounded-bl-none'
                }`}>
                  <p className={msg.isMe ? 'text-white' : 'text-gray-900'}>{msg.message}</p>
                </div>
                
                <span className={`text-xs text-gray-500 mt-1 block ${msg.isMe ? 'text-right' : ''}`}>
                  {msg.time}
                </span>
              </div>
              
              {msg.isMe && (
                <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#FF6B35] to-[#FCD116] flex items-center justify-center flex-shrink-0 text-white">
                  Y
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Typing Indicator */}
        <div className="flex gap-3 mt-4">
          <div className="w-10 h-10 rounded-full bg-gradient-to-br from-gray-300 to-gray-400 flex items-center justify-center flex-shrink-0 text-white">
            T
          </div>
          <div className="bg-white shadow-sm rounded-2xl rounded-bl-none px-4 py-3">
            <div className="flex gap-1">
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" />
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }} />
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.4s' }} />
            </div>
          </div>
        </div>
      </div>

      {/* Input Area */}
      <div className="px-6 py-4 bg-white border-t border-gray-200 flex-shrink-0">
        <div className="flex items-center gap-3">
          <button className="p-2 text-gray-400 hover:text-gray-600">
            <svg className="w-6 h-6" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM7 9a1 1 0 100-2 1 1 0 000 2zm7-1a1 1 0 11-2 0 1 1 0 012 0zm-.464 5.535a1 1 0 10-1.415-1.414 3 3 0 01-4.242 0 1 1 0 00-1.415 1.414 5 5 0 007.072 0z" clipRule="evenodd" />
            </svg>
          </button>
          
          <input
            type="text"
            placeholder="Type a message..."
            className="flex-1 px-4 py-3 rounded-full border-2 border-gray-200 focus:border-[#007A3D] outline-none transition-colors"
          />
          
          <button className="w-12 h-12 bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white rounded-full flex items-center justify-center hover:shadow-lg transition-all">
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
