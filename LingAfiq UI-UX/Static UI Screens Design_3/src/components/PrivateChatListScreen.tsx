import React from 'react';
import { ArrowLeft, Search, MessageCirclePlus } from 'lucide-react';

export function PrivateChatListScreen() {
  const chats = [
    {
      username: 'SwahiliStar',
      avatar: '🌟',
      lastMessage: 'Asante sana for the help!',
      time: '5m ago',
      unread: 2,
      online: true
    },
    {
      username: 'YorubaLearner',
      avatar: '📚',
      lastMessage: 'E kaasan! See you tomorrow',
      time: '1h ago',
      unread: 0,
      online: true
    },
    {
      username: 'AmharicPro',
      avatar: '🎓',
      lastMessage: 'That pronunciation tip was helpful',
      time: '3h ago',
      unread: 0,
      online: false
    },
    {
      username: 'ZuluMaster',
      avatar: '👑',
      lastMessage: 'Sawubona! Let\'s practice together',
      time: '1d ago',
      unread: 5,
      online: false
    },
    {
      username: 'HausaExpert',
      avatar: '💫',
      lastMessage: 'Na gode! Thank you',
      time: '2d ago',
      unread: 0,
      online: false
    }
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] px-6 py-8 shadow-lg">
        <div className="flex items-center gap-4 mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div className="flex-1">
            <h1 className="text-white">Private Chats</h1>
            <p className="text-white/80 text-sm">{chats.length} conversations</p>
          </div>
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <MessageCirclePlus className="w-5 h-5 text-white" />
          </button>
        </div>

        {/* Search Bar */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-white/60 w-5 h-5" />
          <input
            type="text"
            placeholder="Search conversations..."
            className="w-full pl-12 pr-4 py-3 bg-white/20 backdrop-blur-sm border border-white/40 rounded-xl text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50"
          />
        </div>
      </div>

      {/* Chat List */}
      <div className="px-6 py-6 space-y-3">
        {chats.map((chat, index) => (
          <div
            key={index}
            className="bg-white rounded-2xl p-4 shadow-md hover:shadow-lg transition-shadow cursor-pointer"
          >
            <div className="flex items-center gap-4">
              {/* Avatar */}
              <div className="relative">
                <div className="w-14 h-14 rounded-full bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] flex items-center justify-center">
                  <span className="text-2xl">{chat.avatar}</span>
                </div>
                {chat.online && (
                  <div className="absolute -bottom-1 -right-1 w-5 h-5 bg-green-500 rounded-full border-2 border-white"></div>
                )}
              </div>

              {/* Chat Info */}
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between mb-1">
                  <h4 className="text-gray-800">{chat.username}</h4>
                  <span className="text-gray-500 text-xs">{chat.time}</span>
                </div>
                <p className="text-gray-600 text-sm truncate">{chat.lastMessage}</p>
              </div>

              {/* Unread Badge */}
              {chat.unread > 0 && (
                <div className="w-6 h-6 bg-red-500 rounded-full flex items-center justify-center flex-shrink-0">
                  <span className="text-white text-xs">{chat.unread}</span>
                </div>
              )}
            </div>
          </div>
        ))}
      </div>

      {/* Empty State (hidden when chats present) */}
      {/* <div className="px-6 py-12 text-center">
        <p className="text-6xl mb-4">💬</p>
        <h3 className="text-gray-800 mb-2">No messages yet</h3>
        <p className="text-gray-600 mb-6">Start a conversation with other learners</p>
        <button className="bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] text-white px-8 py-3 rounded-xl shadow-lg">
          Find Users
        </button>
      </div> */}
    </div>
  );
}
