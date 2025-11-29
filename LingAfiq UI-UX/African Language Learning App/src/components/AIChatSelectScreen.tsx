import { motion } from 'motion/react';
import { ChevronLeft, MessageCircle, Bot } from 'lucide-react';

interface AIChatSelectScreenProps {
  onSelectTranslator: () => void;
  onSelectTutor: () => void;
  onBack: () => void;
}

export default function AIChatSelectScreen({ onSelectTranslator, onSelectTutor, onBack }: AIChatSelectScreenProps) {
  return (
    <div className="w-full min-h-screen bg-gradient-to-br from-purple-50 to-pink-50 flex flex-col">
      <div className="p-6">
        <button onClick={onBack} className="w-10 h-10 rounded-xl bg-white flex items-center justify-center shadow-sm">
          <ChevronLeft className="w-5 h-5 text-gray-700" />
        </button>
      </div>

      <div className="flex-1 flex flex-col items-center justify-center p-6">
        <h1 className="text-gray-900 mb-4 text-center">Choose AI Mode</h1>
        <p className="text-gray-600 mb-12 text-center">Select how you'd like PolieAI to assist you</p>

        <div className="w-full max-w-md space-y-4">
          <motion.button
            onClick={onSelectTranslator}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="w-full bg-white rounded-3xl p-8 shadow-xl border-2 border-transparent hover:border-blue-300 transition-all"
          >
            <div className="w-20 h-20 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-blue-400 to-cyan-500 flex items-center justify-center">
              <MessageCircle className="w-10 h-10 text-white" />
            </div>
            <h2 className="text-gray-900 mb-2">Translator Mode</h2>
            <p className="text-gray-600">Get instant translations and understand conversations in real-time</p>
          </motion.button>

          <motion.button
            onClick={onSelectTutor}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            className="w-full bg-white rounded-3xl p-8 shadow-xl border-2 border-transparent hover:border-purple-300 transition-all"
          >
            <div className="w-20 h-20 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-purple-400 to-pink-500 flex items-center justify-center">
              <Bot className="w-10 h-10 text-white" />
            </div>
            <h2 className="text-gray-900 mb-2">Tutor Mode</h2>
            <p className="text-gray-600">Practice conversations, get corrections, and improve your skills</p>
          </motion.button>
        </div>
      </div>
    </div>
  );
}
