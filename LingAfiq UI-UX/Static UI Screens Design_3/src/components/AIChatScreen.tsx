import React from 'react';
import { ArrowLeft, Volume2, VolumeX, Trash2, Send, Mic, Menu } from 'lucide-react';

export function AIChatScreen() {
  const [mode, setMode] = React.useState<'translator' | 'tutor'>('translator');
  const [muted, setMuted] = React.useState(false);

  const messages = [
    { sender: 'ai', text: 'Jambo! I am Polie, your AI language assistant. How can I help you today?', time: '10:30 AM' },
    { sender: 'user', text: 'How do you say "Good morning" in Swahili?', time: '10:31 AM' },
    { sender: 'ai', text: '"Good morning" in Swahili is "Habari za asubuhi" (ha-BAR-ee za a-soo-BOO-hee). Would you like to practice pronunciation?', time: '10:31 AM' },
    { sender: 'user', text: 'Yes please!', time: '10:32 AM' },
    { sender: 'ai', text: 'Great! Try saying: "Habari za asubuhi". Break it down: Ha-ba-ri za a-su-bu-hi. Listen to the audio and repeat. 🔊', time: '10:32 AM' }
  ];

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#7B2CBF] to-[#CE1126] px-6 py-4 shadow-lg">
        <div className="flex items-center gap-4">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <Menu className="w-5 h-5 text-white" />
          </button>
          
          <div className="flex-1">
            <h2 className="text-white">LingAfriq Polyglot (Polie)</h2>
            <p className="text-white/80 text-sm">{messages.length} messages</p>
          </div>

          <button 
            onClick={() => setMuted(!muted)}
            className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center"
          >
            {muted ? <VolumeX className="w-5 h-5 text-white" /> : <Volume2 className="w-5 h-5 text-white" />}
          </button>

          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <Trash2 className="w-5 h-5 text-white" />
          </button>

          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
        </div>

        {/* Mode Selector */}
        <div className="flex gap-2 mt-4 bg-white/20 rounded-full p-1">
          <button
            onClick={() => setMode('translator')}
            className={`flex-1 py-2 rounded-full transition-all ${
              mode === 'translator' ? 'bg-white text-gray-800' : 'text-white'
            }`}
          >
            Translation
          </button>
          <button
            onClick={() => setMode('tutor')}
            className={`flex-1 py-2 rounded-full transition-all ${
              mode === 'tutor' ? 'bg-white text-gray-800' : 'text-white'
            }`}
          >
            Tutor
          </button>
        </div>
      </div>

      {/* Messages Area */}
      <div className="flex-1 overflow-y-auto px-6 py-6 space-y-4">
        {messages.map((message, index) => (
          <div
            key={index}
            className={`flex ${message.sender === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div className={`max-w-[75%] ${message.sender === 'user' ? 'order-2' : 'order-1'}`}>
              <div
                className={`rounded-2xl p-4 ${
                  message.sender === 'user'
                    ? 'bg-gradient-to-r from-[#007A3D] to-[#005A2D] text-white rounded-tr-sm'
                    : 'bg-white text-gray-800 rounded-tl-sm shadow-md'
                }`}
              >
                <p className="mb-1">{message.text}</p>
                <p className={`text-xs ${message.sender === 'user' ? 'text-white/70' : 'text-gray-400'}`}>
                  {message.time}
                </p>
              </div>
            </div>
          </div>
        ))}

        {/* Typing Indicator */}
        <div className="flex justify-start">
          <div className="bg-white rounded-2xl rounded-tl-sm shadow-md px-4 py-3">
            <div className="flex gap-1">
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
              <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
            </div>
          </div>
        </div>
      </div>

      {/* Input Area */}
      <div className="bg-white border-t border-gray-200 p-4">
        <div className="flex items-center gap-3">
          <button className="w-12 h-12 bg-[#7B2CBF] rounded-full flex items-center justify-center flex-shrink-0">
            <Mic className="w-5 h-5 text-white" />
          </button>
          
          <input
            type="text"
            placeholder="Type your message..."
            className="flex-1 bg-gray-100 rounded-full px-6 py-3 focus:outline-none focus:ring-2 focus:ring-[#7B2CBF]"
          />

          <button className="w-12 h-12 bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-full flex items-center justify-center flex-shrink-0">
            <Send className="w-5 h-5 text-white" />
          </button>
        </div>
      </div>
    </div>
  );
}
