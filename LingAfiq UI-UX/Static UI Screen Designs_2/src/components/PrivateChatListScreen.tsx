import { Search, MessageCirclePlus } from 'lucide-react';

export function PrivateChatListScreen() {
  const chats = [
    { 
      id: 1, 
      name: 'Amara Okafor', 
      country: '🇳🇬', 
      lastMessage: 'Thanks for the help with pronunciation!', 
      time: '2m ago', 
      unread: 2, 
      online: true 
    },
    { 
      id: 2, 
      name: 'Kwame Mensah', 
      country: '🇬🇭', 
      lastMessage: 'See you in the study session tomorrow', 
      time: '1h ago', 
      unread: 0, 
      online: true 
    },
    { 
      id: 3, 
      name: 'Zainab Hassan', 
      country: '🇰🇪', 
      lastMessage: 'That lesson was really challenging 😅', 
      time: '3h ago', 
      unread: 0, 
      online: false 
    },
    { 
      id: 4, 
      name: 'Ibrahim Diallo', 
      country: '🇸🇳', 
      lastMessage: 'You: Great job on the quiz!', 
      time: 'Yesterday', 
      unread: 0, 
      online: false 
    },
    { 
      id: 5, 
      name: 'Thandiwe Nkosi', 
      country: '🇿🇦', 
      lastMessage: 'Can we practice together later?', 
      time: 'Yesterday', 
      unread: 1, 
      online: false 
    },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] px-6 py-12 rounded-b-[32px]">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors mb-6">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        
        <div className="flex items-center justify-between">
          <div className="text-white">
            <h1 className="mb-1">Private Chats</h1>
            <p className="text-white/90 text-sm">Your conversations</p>
          </div>
          <button className="p-3 bg-white/20 backdrop-blur-sm rounded-full hover:bg-white/30 transition-colors">
            <MessageCirclePlus className="w-6 h-6 text-white" />
          </button>
        </div>
      </div>

      {/* Search Bar */}
      <div className="px-6 py-4">
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search conversations..."
            className="w-full pl-12 pr-4 py-3 rounded-xl border-2 border-gray-200 focus:border-[#7B2CBF] outline-none transition-colors bg-white"
          />
        </div>
      </div>

      {/* Chat List */}
      <div className="px-6 pb-6">
        {chats.length > 0 ? (
          <div className="space-y-3">
            {chats.map((chat) => (
              <div
                key={chat.id}
                className="bg-white rounded-2xl p-4 shadow-sm hover:shadow-md transition-all cursor-pointer"
              >
                <div className="flex items-start gap-4">
                  {/* Avatar */}
                  <div className="relative">
                    <div className="w-14 h-14 rounded-full bg-gradient-to-br from-[#007A3D] to-[#FF6B35] flex items-center justify-center text-white text-xl">
                      {chat.name[0]}
                    </div>
                    {chat.online && (
                      <div className="absolute bottom-0 right-0 w-4 h-4 bg-green-400 border-2 border-white rounded-full" />
                    )}
                  </div>

                  {/* Content */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="text-gray-900">{chat.name}</h3>
                      <span className="text-lg">{chat.country}</span>
                    </div>
                    <p className={`text-sm truncate ${chat.unread > 0 ? 'text-gray-900' : 'text-gray-600'}`}>
                      {chat.lastMessage}
                    </p>
                  </div>

                  {/* Time & Badge */}
                  <div className="flex flex-col items-end gap-2">
                    <span className="text-xs text-gray-500 whitespace-nowrap">{chat.time}</span>
                    {chat.unread > 0 && (
                      <div className="w-6 h-6 bg-[#CE1126] text-white rounded-full flex items-center justify-center text-xs">
                        {chat.unread}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-16">
            <div className="text-6xl mb-4">💬</div>
            <h3 className="text-gray-900 mb-2">No messages yet</h3>
            <p className="text-gray-600 text-sm mb-6">Start connecting with other learners!</p>
            <button className="bg-gradient-to-r from-[#7B2CBF] to-[#9D4EDD] text-white px-6 py-3 rounded-xl hover:shadow-lg transition-all">
              Find Learning Partners
            </button>
          </div>
        )}
      </div>

      <div className="h-20" />
    </div>
  );
}
