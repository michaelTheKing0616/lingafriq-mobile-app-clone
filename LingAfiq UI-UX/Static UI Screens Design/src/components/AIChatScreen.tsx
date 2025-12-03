import React from 'react';
import { ArrowLeft, Menu, Volume2, VolumeX, Trash2, Mic, Send, ArrowDown } from 'lucide-react';

const mockMessages = [
  {
    id: 1,
    sender: 'ai',
    text: 'Jambo! 👋 I am Polie, your LingAfriq language assistant. How can I help you learn today?',
    timestamp: '10:30 AM',
  },
  {
    id: 2,
    sender: 'user',
    text: 'Hi! Can you help me translate "How are you?" to Swahili?',
    timestamp: '10:31 AM',
  },
  {
    id: 3,
    sender: 'ai',
    text: 'Of course! "How are you?" in Swahili is "Habari yako?" or more casually "Habari?"\n\nLet me break it down:\n• Habari = news/how\n• Yako = your\n\nYou can respond with "Nzuri" (good) or "Sijambo" (I\'m fine).',
    timestamp: '10:31 AM',
  },
  {
    id: 4,
    sender: 'user',
    text: 'That\'s helpful! How do I pronounce it?',
    timestamp: '10:32 AM',
  },
];

export function AIChatScreen() {
  const [mode, setMode] = React.useState<'translation' | 'tutor'>('translation');
  const [isMuted, setIsMuted] = React.useState(false);
  const [inputText, setInputText] = React.useState('');
  const [isRecording, setIsRecording] = React.useState(false);
  
  return (
    <div className="h-screen bg-gradient-to-b from-slate-50 to-white flex flex-col">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] text-white px-4 py-3 shadow-lg">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-3">
            <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
              <Menu className="w-5 h-5" />
            </button>
            <div>
              <h1 className="text-lg">LingAfriq Polyglot (Polie)</h1>
              <p className="text-xs text-white/80">{mockMessages.length} messages</p>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <button 
              onClick={() => setIsMuted(!isMuted)}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              {isMuted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
            </button>
            <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
              <Trash2 className="w-5 h-5" />
            </button>
            <button className="p-2 hover:bg-white/10 rounded-lg transition-colors">
              <ArrowLeft className="w-5 h-5" />
            </button>
          </div>
        </div>
        
        {/* Mode Selector */}
        <div className="flex gap-2 bg-white/20 rounded-lg p-1">
          <button
            onClick={() => setMode('translation')}
            className={`flex-1 py-2 px-4 rounded-md text-sm transition-all ${
              mode === 'translation' 
                ? 'bg-white text-[#7B2CBF]' 
                : 'text-white hover:bg-white/10'
            }`}
          >
            Translation Mode
          </button>
          <button
            onClick={() => setMode('tutor')}
            className={`flex-1 py-2 px-4 rounded-md text-sm transition-all ${
              mode === 'tutor' 
                ? 'bg-white text-[#CE1126]' 
                : 'text-white hover:bg-white/10'
            }`}
          >
            Tutor Mode
          </button>
        </div>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto px-4 py-6 space-y-4">
        {mockMessages.map((message) => (
          <div
            key={message.id}
            className={`flex ${message.sender === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-[75%] rounded-2xl px-4 py-3 ${
                message.sender === 'user'
                  ? 'bg-gradient-to-br from-[#007A3D] to-[#005a2d] text-white rounded-br-sm'
                  : 'bg-white border border-gray-200 text-gray-900 rounded-bl-sm shadow-sm'
              }`}
            >
              <p className="whitespace-pre-line">{message.text}</p>
              <p
                className={`text-xs mt-2 ${
                  message.sender === 'user' ? 'text-white/70' : 'text-gray-500'
                }`}
              >
                {message.timestamp}
              </p>
            </div>
          </div>
        ))}
        
        {/* Typing Indicator */}
        <div className="flex justify-start">
          <div className="bg-white border border-gray-200 rounded-2xl rounded-bl-sm px-4 py-3 shadow-sm">
            <div className="flex gap-1">
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
            </div>
          </div>
        </div>
      </div>

      {/* Scroll to Bottom Button */}
      <button className="absolute bottom-24 right-6 bg-white shadow-lg rounded-full p-3 hover:bg-gray-50 transition-colors">
        <ArrowDown className="w-5 h-5 text-gray-700" />
      </button>

      {/* Input Area */}
      <div className="bg-white border-t border-gray-200 px-4 py-4">
        <div className="flex items-end gap-3">
          <div className="flex-1 bg-gray-100 rounded-2xl px-4 py-3 flex items-center gap-2">
            <input
              type="text"
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder={mode === 'translation' ? 'Type a word or phrase to translate...' : 'Ask me anything about the language...'}
              className="flex-1 bg-transparent outline-none text-gray-900 placeholder:text-gray-500"
            />
          </div>
          
          <button
            onClick={() => setIsRecording(!isRecording)}
            className={`p-3 rounded-full transition-all ${
              isRecording 
                ? 'bg-[#CE1126] text-white animate-pulse' 
                : 'bg-[#FF6B35] text-white hover:bg-[#e55a2a]'
            }`}
          >
            <Mic className="w-5 h-5" />
          </button>
          
          <button className="p-3 rounded-full bg-[#007A3D] text-white hover:bg-[#005a2d] transition-colors">
            <Send className="w-5 h-5" />
          </button>
        </div>
        
        {isRecording && (
          <div className="mt-2 flex items-center justify-center gap-2 text-[#CE1126]">
            <div className="w-2 h-2 bg-[#CE1126] rounded-full animate-pulse" />
            <span className="text-sm">Recording...</span>
          </div>
        )}
      </div>
    </div>
  );
}
