import { Phone, Video, MoreVertical, Send, Paperclip, Smile } from 'lucide-react';

export function PrivateChatScreen() {
  const messages = [
    { id: 1, text: 'Hey! How did your quiz go?', time: '10:24 AM', isMe: false, status: 'read' },
    { id: 2, text: 'It went great! Got 95%! 🎉', time: '10:25 AM', isMe: true, status: 'read' },
    { id: 3, text: 'Wow, that\'s amazing! Congratulations!', time: '10:25 AM', isMe: false, status: 'read' },
    { id: 4, text: 'Thank you! Your tips really helped', time: '10:26 AM', isMe: true, status: 'read' },
    { id: 5, text: 'Want to practice pronunciation together later?', time: '10:27 AM', isMe: false, status: 'read' },
    { id: 6, text: 'Yes! That would be great. How about 3pm?', time: '10:28 AM', isMe: true, status: 'delivered' },
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] px-6 py-4 flex-shrink-0">
        <div className="flex items-center gap-4">
          <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </button>

          {/* User Info */}
          <div className="flex-1 flex items-center gap-3">
            <div className="relative">
              <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center text-white">
                A
              </div>
              <div className="absolute bottom-0 right-0 w-3 h-3 bg-green-400 border-2 border-[#7B2CBF] rounded-full" />
            </div>
            <div>
              <h3 className="text-white flex items-center gap-2">
                Amara Okafor
                <span>🇳🇬</span>
              </h3>
              <p className="text-white/80 text-xs">Online</p>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-1">
            <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
              <Phone className="w-5 h-5 text-white" />
            </button>
            <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
              <Video className="w-5 h-5 text-white" />
            </button>
            <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
              <MoreVertical className="w-5 h-5 text-white" />
            </button>
          </div>
        </div>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto px-6 py-4">
        <div className="space-y-4">
          {messages.map((msg) => (
            <div key={msg.id} className={`flex ${msg.isMe ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[75%] ${msg.isMe ? 'items-end' : 'items-start'} flex flex-col`}>
                <div
                  className={`rounded-2xl px-4 py-3 ${
                    msg.isMe
                      ? 'bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] text-white rounded-br-none'
                      : 'bg-white shadow-sm rounded-bl-none'
                  }`}
                >
                  <p className={msg.isMe ? 'text-white' : 'text-gray-900'}>{msg.text}</p>
                </div>
                <div className="flex items-center gap-1 mt-1">
                  <span className="text-xs text-gray-500">{msg.time}</span>
                  {msg.isMe && (
                    <div className="flex gap-0.5">
                      {msg.status === 'delivered' && (
                        <svg className="w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                          <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                        </svg>
                      )}
                      {msg.status === 'read' && (
                        <>
                          <svg className="w-4 h-4 text-[#7B2CBF]" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                          </svg>
                          <svg className="w-4 h-4 text-[#7B2CBF] -ml-2" fill="currentColor" viewBox="0 0 20 20">
                            <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                          </svg>
                        </>
                      )}
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Typing Indicator */}
        <div className="flex justify-start mt-4">
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
            <Paperclip className="w-6 h-6" />
          </button>

          <input
            type="text"
            placeholder="Type a message..."
            className="flex-1 px-4 py-3 rounded-full border-2 border-gray-200 focus:border-[#7B2CBF] outline-none transition-colors"
          />

          <button className="p-2 text-gray-400 hover:text-gray-600">
            <Smile className="w-6 h-6" />
          </button>

          <button className="w-12 h-12 bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] text-white rounded-full flex items-center justify-center hover:shadow-lg transition-all">
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}
