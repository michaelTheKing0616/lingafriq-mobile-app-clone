import React from 'react';
import { ArrowLeft, Video, MoreVertical, Send, Paperclip, Smile, Mic } from 'lucide-react';

export function PrivateChatScreen() {
  const messages = [
    { sender: 'other', text: 'Jambo! How are you?', time: '10:30 AM', read: true },
    { sender: 'user', text: 'Hi! I\'m good, thanks! How about you?', time: '10:31 AM', read: true },
    { sender: 'other', text: 'Nzuri sana! I\'m doing great. Did you finish lesson 3?', time: '10:32 AM', read: true },
    { sender: 'user', text: 'Yes! It was challenging but fun. The pronunciation section helped a lot.', time: '10:33 AM', read: true },
    { sender: 'other', text: 'That\'s awesome! Want to practice together sometime?', time: '10:34 AM', read: false },
    { sender: 'user', text: 'Absolutely! That would be really helpful 😊', time: '10:35 AM', read: false }
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] px-6 py-4 shadow-lg">
        <div className="flex items-center gap-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>

          {/* User Info */}
          <div className="flex items-center gap-3 flex-1">
            <div className="relative">
              <div className="w-10 h-10 rounded-full bg-white/20 flex items-center justify-center">
                <span className="text-xl">🌟</span>
              </div>
              <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-green-500 rounded-full border-2 border-white"></div>
            </div>
            <div>
              <h3 className="text-white">SwahiliStar</h3>
              <p className="text-white/70 text-xs">Online</p>
            </div>
          </div>

          {/* Action Buttons */}
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <Video className="w-5 h-5 text-white" />
          </button>
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <MoreVertical className="w-5 h-5 text-white" />
          </button>
        </div>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto px-6 py-6 space-y-4">
        {messages.map((msg, index) => (
          <div
            key={index}
            className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div className={`max-w-[75%]`}>
              <div
                className={`rounded-2xl p-4 ${
                  msg.sender === 'user'
                    ? 'bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] text-white rounded-tr-sm'
                    : 'bg-white text-gray-800 shadow-md rounded-tl-sm'
                }`}
              >
                <p className="mb-1">{msg.text}</p>
                <div className={`flex items-center gap-2 text-xs ${msg.sender === 'user' ? 'text-white/70 justify-end' : 'text-gray-400'}`}>
                  <span>{msg.time}</span>
                  {msg.sender === 'user' && (
                    <span>{msg.read ? '✓✓' : '✓'}</span>
                  )}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Input Area */}
      <div className="bg-white border-t border-gray-200 p-4">
        <div className="flex items-center gap-3">
          <button className="text-gray-400">
            <Paperclip className="w-6 h-6" />
          </button>
          
          <div className="flex-1 flex items-center gap-2 bg-gray-100 rounded-full px-4 py-3">
            <input
              type="text"
              placeholder="Type a message..."
              className="flex-1 bg-transparent focus:outline-none"
            />
            <button className="text-gray-400">
              <Smile className="w-5 h-5" />
            </button>
          </div>

          <button className="w-12 h-12 bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] rounded-full flex items-center justify-center">
            <Send className="w-5 h-5 text-white" />
          </button>
        </div>
      </div>
    </div>
  );
}
