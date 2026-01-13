import { useState } from 'react';
import { motion } from 'motion/react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Input } from './ui/input';
import { Badge } from './ui/badge';
import { ArrowLeft, Send, Volume2, Mic, Languages, GraduationCap, Sparkles } from 'lucide-react';

interface Message {
  id: number;
  sender: 'user' | 'ai';
  text: string;
  translation?: string;
  timestamp: Date;
}

interface AIChatScreensProps {
  onBack?: () => void;
}

// Mode Selection Screen
export function AIModeSelection({ onSelectMode }: { onSelectMode: (mode: 'translator' | 'tutor') => void }) {
  return (
    <div className="min-h-screen bg-background flex flex-col">
      <div className="relative bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="absolute inset-0 opacity-10">
          <div
            className="absolute inset-0"
            style={{
              backgroundImage: `repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.3) 35px, rgba(255, 255, 255, 0.3) 70px)`,
            }}
          />
        </div>
        <div className="relative text-center text-white pt-8">
          <Sparkles className="w-16 h-16 mx-auto mb-4" />
          <h1 className="text-3xl mb-2">AI Language Assistant</h1>
          <p className="opacity-90">Choose how you'd like to practice</p>
        </div>
      </div>

      <div className="flex-1 px-6 py-8 flex flex-col justify-center gap-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
        >
          <Card
            onClick={() => onSelectMode('translator')}
            className="p-6 rounded-2xl shadow-lg border-2 border-transparent hover:border-primary cursor-pointer transition-all group"
          >
            <div className="flex items-start gap-4">
              <div className="p-4 rounded-2xl bg-gradient-to-br from-[#007A3D] to-[#00A8E8] shadow-md">
                <Languages className="w-8 h-8 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="mb-2">Translator Mode</h3>
                <p className="text-sm text-muted-foreground mb-3">
                  Instant translations between English and Swahili. Perfect for quick lookups and
                  understanding phrases.
                </p>
                <Badge className="bg-[#007A3D]/10 text-[#007A3D]">Quick & Easy</Badge>
              </div>
            </div>
          </Card>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          <Card
            onClick={() => onSelectMode('tutor')}
            className="p-6 rounded-2xl shadow-lg border-2 border-transparent hover:border-primary cursor-pointer transition-all group"
          >
            <div className="flex items-start gap-4">
              <div className="p-4 rounded-2xl bg-gradient-to-br from-[#CE1126] to-[#FF6B35] shadow-md">
                <GraduationCap className="w-8 h-8 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="mb-2">Tutor Mode</h3>
                <p className="text-sm text-muted-foreground mb-3">
                  Practice conversations with your AI tutor. Get feedback, corrections, and
                  explanations to improve your skills.
                </p>
                <Badge className="bg-primary/10 text-primary">Interactive Learning</Badge>
              </div>
            </div>
          </Card>
        </motion.div>
      </div>
    </div>
  );
}

// Main AI Chat Screen
export default function AIChatScreens({ onBack }: AIChatScreensProps) {
  const [mode, setMode] = useState<'translator' | 'tutor' | null>(null);
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 1,
      sender: 'ai',
      text: mode === 'translator' 
        ? 'Hello! I can help you translate between English and Swahili. Just type a phrase!' 
        : 'Jambo! I\'m your Swahili tutor. Let\'s practice together! Try introducing yourself.',
      timestamp: new Date(),
    },
  ]);
  const [inputText, setInputText] = useState('');

  if (!mode) {
    return <AIModeSelection onSelectMode={setMode} />;
  }

  const sendMessage = () => {
    if (!inputText.trim()) return;

    const userMessage: Message = {
      id: messages.length + 1,
      sender: 'user',
      text: inputText,
      timestamp: new Date(),
    };

    // Simulate AI response
    const aiResponse: Message = {
      id: messages.length + 2,
      sender: 'ai',
      text:
        mode === 'translator'
          ? `Translation: "${inputText}" → "Tafsiri: ${inputText}"`
          : `Great! "${inputText}" is a good attempt. Here's a tip: Remember to use proper greetings like "Jina langu ni..." when introducing yourself.`,
      translation: mode === 'translator' ? inputText : undefined,
      timestamp: new Date(),
    };

    setMessages([...messages, userMessage, aiResponse]);
    setInputText('');
  };

  return (
    <div className="min-h-screen bg-background flex flex-col">
      {/* Header */}
      <div className="sticky top-0 z-10 bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] px-6 py-4 shadow-lg">
        <div className="flex items-center gap-3">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => mode ? setMode(null) : onBack?.()}
            className="text-white hover:bg-white/20 rounded-full"
          >
            <ArrowLeft className="w-5 h-5" />
          </Button>
          <div className="flex-1">
            <h2 className="text-white">{mode === 'translator' ? 'Translator' : 'AI Tutor'}</h2>
            <p className="text-sm text-white/80">Powered by Polie AI</p>
          </div>
          <Badge className="bg-white/20 text-white">
            {mode === 'translator' ? <Languages className="w-4 h-4" /> : <GraduationCap className="w-4 h-4" />}
          </Badge>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 px-6 py-6 overflow-y-auto">
        <div className="space-y-4 max-w-2xl mx-auto">
          {messages.map((message) => (
            <motion.div
              key={message.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className={`flex ${message.sender === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              <div
                className={`max-w-[80%] ${
                  message.sender === 'user'
                    ? 'bg-gradient-to-br from-[#CE1126] to-[#FF6B35] text-white rounded-2xl rounded-tr-sm'
                    : 'bg-card rounded-2xl rounded-tl-sm shadow'
                } p-4`}
              >
                {message.sender === 'ai' && (
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-6 h-6 rounded-full bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] flex items-center justify-center">
                      <Sparkles className="w-4 h-4 text-white" />
                    </div>
                    <span className="text-xs text-muted-foreground">Polie AI</span>
                  </div>
                )}
                <p className="text-sm leading-relaxed">{message.text}</p>
                {message.sender === 'ai' && (
                  <div className="flex gap-2 mt-3">
                    <Button variant="ghost" size="sm" className="h-8 rounded-lg">
                      <Volume2 className="w-4 h-4 mr-1" />
                      Listen
                    </Button>
                  </div>
                )}
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Input */}
      <div className="sticky bottom-0 p-6 bg-gradient-to-t from-background via-background to-transparent">
        <div className="max-w-2xl mx-auto">
          <div className="flex gap-2">
            <Button variant="outline" size="icon" className="rounded-full">
              <Mic className="w-5 h-5" />
            </Button>
            <Input
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
              placeholder={
                mode === 'translator'
                  ? 'Type a phrase to translate...'
                  : 'Type your response...'
              }
              className="flex-1 h-12 rounded-2xl bg-card border-0 shadow"
            />
            <Button
              onClick={sendMessage}
              disabled={!inputText.trim()}
              className="rounded-full w-12 h-12 bg-gradient-to-br from-[#7B2CBF] to-[#CE1126]"
              size="icon"
            >
              <Send className="w-5 h-5" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}
