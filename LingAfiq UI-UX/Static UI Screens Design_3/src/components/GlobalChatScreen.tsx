import React from 'react';
import { ArrowLeft, Send, Users, Menu } from 'lucide-react';

export function GlobalChatScreen() {
  const [activeRoom, setActiveRoom] = React.useState('general');

  const rooms = [
    { id: 'general', name: 'General', online: 234 },
    { id: 'swahili', name: 'Swahili Learners', online: 89 },
    { id: 'yoruba', name: 'Yoruba Learners', online: 67 },
    { id: 'help', name: 'Help & Questions', online: 45 },
    { id: 'cultural', name: 'Cultural Exchange', online: 123 }
  ];

  const messages = [
    { user: 'SwahiliStar', avatar: '🌟', message: 'Jambo everyone! How are you all doing today?', time: '10:30 AM', isCurrentUser: false },
    { user: 'YorubaLearner', avatar: '📚', message: 'E kaaro! Good morning!', time: '10:31 AM', isCurrentUser: false },
    { user: 'You', avatar: '👤', message: 'Hello everyone! Just started learning Swahili', time: '10:32 AM', isCurrentUser: true },
    { user: 'SwahiliStar', avatar: '🌟', message: 'Karibu! Welcome! Do you need any help?', time: '10:33 AM', isCurrentUser: false },
    { user: 'LanguageMaster', avatar: '🎓', message: 'This community is so supportive! Love it here 💚', time: '10:34 AM', isCurrentUser: false }
  ];

  const onlineUsers = [
    { username: 'SwahiliStar', avatar: '🌟' },
    { username: 'YorubaLearner', avatar: '📚' },
    { username: 'LanguageMaster', avatar: '🎓' },
    { username: 'AfricanPride', avatar: '🌍' },
    { username: 'CultureBuff', avatar: '🎭' }
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-4 shadow-lg">
        <div className="flex items-center gap-4 mb-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div className="flex-1">
            <h2 className="text-white">Global Chat</h2>
            <p className="text-white/80 text-sm">{rooms.find(r => r.id === activeRoom)?.name}</p>
          </div>
          <button className="text-white flex items-center gap-2">
            <Users className="w-5 h-5" />
            <span className="text-sm">{rooms.find(r => r.id === activeRoom)?.online}</span>
          </button>
        </div>

        {/* Room Selector */}
        <div className="flex gap-2 overflow-x-auto pb-2">
          {rooms.map((room) => (
            <button
              key={room.id}
              onClick={() => setActiveRoom(room.id)}
              className={`px-4 py-2 rounded-full flex-shrink-0 transition-colors ${
                activeRoom === room.id
                  ? 'bg-white text-[#007A3D]'
                  : 'bg-white/20 text-white'
              }`}
            >
              {room.name}
            </button>
          ))}
        </div>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto px-6 py-6 space-y-4">
        {messages.map((msg, index) => (
          <div
            key={index}
            className={`flex gap-3 ${msg.isCurrentUser ? 'flex-row-reverse' : ''}`}
          >
            {/* Avatar */}
            <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#007A3D] to-[#005A2D] flex items-center justify-center flex-shrink-0">
              <span className="text-xl">{msg.avatar}</span>
            </div>

            {/* Message Bubble */}
            <div className={`flex-1 max-w-[75%]`}>
              <div className={`flex items-center gap-2 mb-1 ${msg.isCurrentUser ? 'flex-row-reverse' : ''}`}>
                <span className="text-sm text-gray-700">{msg.user}</span>
                <span className="text-xs text-gray-400">{msg.time}</span>
              </div>
              <div
                className={`rounded-2xl p-4 ${
                  msg.isCurrentUser
                    ? 'bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white rounded-tr-sm'
                    : 'bg-white text-gray-800 shadow-md rounded-tl-sm'
                }`}
              >
                <p>{msg.message}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Online Users Sidebar (Collapsible) */}
      <div className="bg-white border-t border-gray-200 px-6 py-4">
        <h4 className="text-gray-700 mb-3 flex items-center gap-2">
          <Users className="w-4 h-4" />
          Online ({onlineUsers.length})
        </h4>
        <div className="flex gap-2 overflow-x-auto pb-2">
          {onlineUsers.map((user, index) => (
            <div key={index} className="flex flex-col items-center gap-1 flex-shrink-0">
              <div className="relative">
                <div className="w-12 h-12 rounded-full bg-gradient-to-br from-[#007A3D] to-[#005A2D] flex items-center justify-center">
                  <span className="text-xl">{user.avatar}</span>
                </div>
                <div className="absolute -bottom-1 -right-1 w-4 h-4 bg-green-500 rounded-full border-2 border-white"></div>
              </div>
              <span className="text-xs text-gray-600 text-center max-w-[60px] truncate">{user.username}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Input Area */}
      <div className="bg-white border-t border-gray-200 p-4">
        <div className="flex items-center gap-3">
          <button className="text-gray-400">
            <Menu className="w-6 h-6" />
          </button>
          
          <input
            type="text"
            placeholder="Type your message..."
            className="flex-1 bg-gray-100 rounded-full px-6 py-3 focus:outline-none focus:ring-2 focus:ring-[#007A3D]"
          />

          <button className="w-12 h-12 bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-full flex items-center justify-center">
            <Send className="w-5 h-5 text-white" />
          </button>
        </div>
      </div>
    </div>
  );
}
