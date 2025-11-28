import { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Input } from './ui/input';
import { Progress } from './ui/progress';
import { Badge } from './ui/badge';
import { Avatar, AvatarFallback, AvatarImage } from './ui/avatar';
import { Separator } from './ui/separator';
import { Switch } from './ui/switch';
import { Label } from './ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from './ui/tabs';
import {
  ArrowLeft,
  Trophy,
  Zap,
  Star,
  Target,
  Timer,
  Volume2,
  Check,
  X,
  Crown,
  Medal,
  Award,
  Flame,
  Calendar,
  TrendingUp,
  BarChart3,
  Users,
  Send,
  Image as ImageIcon,
  Newspaper,
  Music,
  BookOpen,
  Globe,
  Settings as SettingsIcon,
  Bell,
  Shield,
  Palette,
  LogOut,
  Upload,
  Sparkles,
  MessageCircle,
  Mic,
} from 'lucide-react';
import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

// ==================== LANGUAGE GAMES ====================

const wordPairs = [
  { english: 'Hello', swahili: 'Jambo' },
  { english: 'Thank you', swahili: 'Asante' },
  { english: 'Water', swahili: 'Maji' },
  { english: 'Food', swahili: 'Chakula' },
  { english: 'Friend', swahili: 'Rafiki' },
  { english: 'Good', swahili: 'Nzuri' },
];

export function LanguageGames({ onBack }: { onBack?: () => void }) {
  const [selectedGame, setSelectedGame] = useState<string | null>(null);

  const games = [
    {
      id: 'word-match',
      title: 'Word Match',
      description: 'Match English words with their Swahili translations',
      icon: Target,
      gradient: 'from-[#CE1126] to-[#FF6B35]',
    },
    {
      id: 'pronunciation',
      title: 'Pronunciation Practice',
      description: 'Listen and repeat words correctly',
      icon: Volume2,
      gradient: 'from-[#007A3D] to-[#00A8E8]',
    },
    {
      id: 'speed-quiz',
      title: 'Speed Quiz',
      description: 'Answer as many questions as possible in 60 seconds',
      icon: Zap,
      gradient: 'from-[#FCD116] to-[#FF6B35]',
    },
  ];

  if (selectedGame === 'word-match') {
    return <WordMatchGame onBack={() => setSelectedGame(null)} />;
  }
  if (selectedGame === 'pronunciation') {
    return <PronunciationGame onBack={() => setSelectedGame(null)} />;
  }
  if (selectedGame === 'speed-quiz') {
    return <SpeedQuizGame onBack={() => setSelectedGame(null)} />;
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="relative bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="absolute inset-0 opacity-10">
          <div
            className="absolute inset-0"
            style={{
              backgroundImage: `repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.3) 35px, rgba(255, 255, 255, 0.3) 70px)`,
            }}
          />
        </div>
        <div className="relative">
          {onBack && (
            <Button
              variant="ghost"
              size="icon"
              onClick={onBack}
              className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full"
            >
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="text-center text-white pt-8">
            <Trophy className="w-16 h-16 mx-auto mb-4" />
            <h1 className="text-3xl mb-2">Language Games</h1>
            <p className="opacity-90">Learn while having fun!</p>
          </div>
        </div>
      </div>

      <div className="px-6 py-8 space-y-4">
        {games.map((game, index) => {
          const Icon = game.icon;
          return (
            <motion.div
              key={game.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card
                onClick={() => setSelectedGame(game.id)}
                className="p-5 rounded-2xl shadow-lg border-0 cursor-pointer hover:shadow-xl transition-all"
              >
                <div className="flex items-center gap-4">
                  <div className={`p-4 rounded-2xl bg-gradient-to-br ${game.gradient} shadow-md`}>
                    <Icon className="w-8 h-8 text-white" />
                  </div>
                  <div className="flex-1">
                    <h3 className="mb-1">{game.title}</h3>
                    <p className="text-sm text-muted-foreground">{game.description}</p>
                  </div>
                </div>
              </Card>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}

function WordMatchGame({ onBack }: { onBack: () => void }) {
  const [selected, setSelected] = useState<string[]>([]);
  const [matched, setMatched] = useState<string[]>([]);
  const [score, setScore] = useState(0);

  const allWords = [...wordPairs.map(p => p.english), ...wordPairs.map(p => p.swahili)].sort(() => Math.random() - 0.5);

  const handleSelect = (word: string) => {
    if (matched.includes(word)) return;
    if (selected.includes(word)) {
      setSelected(selected.filter(w => w !== word));
      return;
    }

    const newSelected = [...selected, word];
    if (newSelected.length === 2) {
      const pair = wordPairs.find(
        p => (p.english === newSelected[0] && p.swahili === newSelected[1]) ||
            (p.english === newSelected[1] && p.swahili === newSelected[0])
      );
      if (pair) {
        setMatched([...matched, ...newSelected]);
        setScore(score + 10);
      }
      setTimeout(() => setSelected([]), 500);
    } else {
      setSelected(newSelected);
    }
  };

  return (
    <div className="min-h-screen bg-background p-6">
      <div className="flex items-center justify-between mb-6">
        <Button variant="ghost" size="icon" onClick={onBack} className="rounded-full">
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <Badge className="bg-primary text-white px-4 py-2">Score: {score}</Badge>
      </div>

      <h2 className="text-center mb-8">Match the Words!</h2>

      <div className="grid grid-cols-3 gap-3 max-w-md mx-auto">
        {allWords.map((word, index) => (
          <motion.button
            key={index}
            onClick={() => handleSelect(word)}
            whileTap={{ scale: 0.95 }}
            className={`p-4 rounded-xl border-2 transition-all ${
              matched.includes(word)
                ? 'bg-[#007A3D]/10 border-[#007A3D] opacity-50'
                : selected.includes(word)
                ? 'bg-primary/10 border-primary'
                : 'border-border hover:border-primary/50'
            }`}
          >
            {word}
          </motion.button>
        ))}
      </div>

      {matched.length === allWords.length && (
        <motion.div
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          className="text-center mt-8"
        >
          <Trophy className="w-16 h-16 text-[#FCD116] mx-auto mb-4" />
          <h2>Congratulations!</h2>
          <p className="text-muted-foreground">Final Score: {score}</p>
        </motion.div>
      )}
    </div>
  );
}

function PronunciationGame({ onBack }: { onBack: () => void }) {
  const [currentWord, setCurrentWord] = useState(0);
  const words = ['Jambo', 'Asante', 'Karibu', 'Rafiki'];

  return (
    <div className="min-h-screen bg-background p-6">
      <Button variant="ghost" size="icon" onClick={onBack} className="rounded-full mb-6">
        <ArrowLeft className="w-5 h-5" />
      </Button>

      <Card className="p-8 rounded-2xl shadow-lg text-center max-w-md mx-auto">
        <h2 className="mb-4">Pronounce this word:</h2>
        <div className="text-4xl mb-8 text-primary">{words[currentWord]}</div>
        <Button className="w-full h-14 rounded-xl bg-gradient-to-r from-[#007A3D] to-[#00A8E8] text-white mb-4">
          <Volume2 className="w-5 h-5 mr-2" />
          Play Audio
        </Button>
        <Button className="w-full h-14 rounded-xl" variant="outline">
          <Mic className="w-5 h-5 mr-2" />
          Record Your Voice
        </Button>
      </Card>
    </div>
  );
}

function SpeedQuizGame({ onBack }: { onBack: () => void }) {
  const [timeLeft, setTimeLeft] = useState(60);
  const [score, setScore] = useState(0);
  const [currentQ, setCurrentQ] = useState(0);

  const questions = [
    { q: 'Hello in Swahili?', a: 'Jambo', options: ['Jambo', 'Asante', 'Karibu'] },
    { q: 'Thank you in Swahili?', a: 'Asante', options: ['Jambo', 'Asante', 'Maji'] },
  ];

  useEffect(() => {
    if (timeLeft > 0) {
      const timer = setTimeout(() => setTimeLeft(timeLeft - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [timeLeft]);

  const question = questions[currentQ % questions.length];

  return (
    <div className="min-h-screen bg-background p-6">
      <div className="flex items-center justify-between mb-6">
        <Button variant="ghost" size="icon" onClick={onBack} className="rounded-full">
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <div className="flex gap-3">
          <Badge className="bg-destructive text-white px-4 py-2">
            <Timer className="w-4 h-4 mr-2" />
            {timeLeft}s
          </Badge>
          <Badge className="bg-primary text-white px-4 py-2">Score: {score}</Badge>
        </div>
      </div>

      <Card className="p-6 rounded-2xl shadow-lg max-w-md mx-auto">
        <h3 className="text-xl mb-6">{question.q}</h3>
        <div className="space-y-3">
          {question.options.map((opt, i) => (
            <Button
              key={i}
              onClick={() => {
                if (opt === question.a) setScore(score + 1);
                setCurrentQ(currentQ + 1);
              }}
              className="w-full h-12 rounded-xl"
              variant="outline"
            >
              {opt}
            </Button>
          ))}
        </div>
      </Card>
    </div>
  );
}

// ==================== USER PROFILE ====================

export function UserProfile({ onBack, onLogout }: { onBack?: () => void; onLogout: () => void }) {
  const user = {
    name: 'Kwame Johnson',
    email: 'kwame@example.com',
    avatar: 'https://images.unsplash.com/photo-1744809482817-9a9d4fc280af',
    level: 8,
    xp: 2450,
    streak: 12,
    language: 'Swahili',
    joinDate: 'January 2024',
  };

  return (
    <div className="min-h-screen bg-background pb-24">
      <div className="relative bg-gradient-to-br from-[#CE1126] to-[#FF6B35] px-6 pt-12 pb-24 rounded-b-[2.5rem] shadow-lg">
        <div className="absolute inset-0 opacity-10">
          <div
            className="absolute inset-0"
            style={{
              backgroundImage: `repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.3) 35px, rgba(255, 255, 255, 0.3) 70px)`,
            }}
          />
        </div>
        <div className="relative">
          {onBack && (
            <Button
              variant="ghost"
              size="icon"
              onClick={onBack}
              className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full"
            >
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="text-center text-white pt-8">
            <Avatar className="w-24 h-24 mx-auto mb-4 border-4 border-white shadow-2xl">
              <AvatarImage src={user.avatar} alt={user.name} />
              <AvatarFallback>{user.name[0]}</AvatarFallback>
            </Avatar>
            <h1 className="text-2xl mb-1">{user.name}</h1>
            <p className="opacity-90 mb-4">{user.email}</p>
            <div className="flex justify-center gap-4">
              <div className="text-center">
                <div className="text-2xl">Lvl {user.level}</div>
                <div className="text-sm opacity-80">Level</div>
              </div>
              <div className="text-center">
                <div className="text-2xl">{user.xp}</div>
                <div className="text-sm opacity-80">XP</div>
              </div>
              <div className="text-center">
                <div className="text-2xl">{user.streak}</div>
                <div className="text-sm opacity-80">Day Streak</div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="px-6 -mt-16">
        <Card className="p-5 rounded-2xl shadow-lg border-0 mb-6">
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Globe className="w-5 h-5 text-primary" />
                <div>
                  <p className="text-sm text-muted-foreground">Learning</p>
                  <p>{user.language}</p>
                </div>
              </div>
            </div>
            <Separator />
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Calendar className="w-5 h-5 text-accent" />
                <div>
                  <p className="text-sm text-muted-foreground">Member since</p>
                  <p>{user.joinDate}</p>
                </div>
              </div>
            </div>
          </div>
        </Card>

        <div className="space-y-3">
          <Button className="w-full h-12 rounded-xl justify-start" variant="outline">
            <SettingsIcon className="w-5 h-5 mr-3" />
            Settings
          </Button>
          <Button onClick={onLogout} className="w-full h-12 rounded-xl justify-start bg-destructive/10 text-destructive hover:bg-destructive/20" variant="ghost">
            <LogOut className="w-5 h-5 mr-3" />
            Logout
          </Button>
        </div>
      </div>
    </div>
  );
}

// ==================== SETTINGS ====================

export function SettingsScreen({ onBack }: { onBack?: () => void }) {
  return (
    <div className="min-h-screen bg-background">
      <div className="relative bg-gradient-to-br from-[#007A3D] to-[#00A8E8] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="relative">
          {onBack && (
            <Button variant="ghost" size="icon" onClick={onBack} className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full">
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="text-center text-white pt-8">
            <SettingsIcon className="w-16 h-16 mx-auto mb-4" />
            <h1 className="text-3xl mb-2">Settings</h1>
          </div>
        </div>
      </div>

      <div className="px-6 py-6 space-y-6">
        <Card className="p-5 rounded-2xl shadow-lg border-0">
          <h3 className="mb-4">Notifications</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-primary" />
                <Label>Daily Reminders</Label>
              </div>
              <Switch defaultChecked />
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Trophy className="w-5 h-5 text-primary" />
                <Label>Achievement Alerts</Label>
              </div>
              <Switch defaultChecked />
            </div>
          </div>
        </Card>

        <Card className="p-5 rounded-2xl shadow-lg border-0">
          <h3 className="mb-4">Learning</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <Label>Daily Goal</Label>
              <select className="px-3 py-1 rounded-lg border">
                <option>10 minutes</option>
                <option>20 minutes</option>
                <option>30 minutes</option>
              </select>
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Volume2 className="w-5 h-5 text-primary" />
                <Label>Sound Effects</Label>
              </div>
              <Switch defaultChecked />
            </div>
          </div>
        </Card>

        <Card className="p-5 rounded-2xl shadow-lg border-0">
          <h3 className="mb-4">Appearance</h3>
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Palette className="w-5 h-5 text-primary" />
                <Label>Dark Mode</Label>
              </div>
              <Switch />
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

// ==================== GLOBAL RANKING ====================

export function GlobalRanking({ onBack }: { onBack?: () => void }) {
  const rankings = [
    { rank: 1, name: 'Amara', xp: 8450, avatar: '👑', country: '🇬🇭' },
    { rank: 2, name: 'Kofi', xp: 7230, avatar: '🥈', country: '🇰🇪' },
    { rank: 3, name: 'Zuri', xp: 6890, avatar: '🥉', country: '🇹🇿' },
    { rank: 4, name: 'Kwame', xp: 6450, avatar: '😊', country: '🇳🇬' },
    { rank: 5, name: 'Nia', xp: 5920, avatar: '😄', country: '🇿🇦' },
    { rank: 12, name: 'You', xp: 2450, avatar: '⭐', country: '🌍', isCurrentUser: true },
  ];

  return (
    <div className="min-h-screen bg-background">
      <div className="relative bg-gradient-to-br from-[#FCD116] to-[#FF6B35] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="relative">
          {onBack && (
            <Button variant="ghost" size="icon" onClick={onBack} className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full">
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="text-center text-white pt-8">
            <Crown className="w-16 h-16 mx-auto mb-4" />
            <h1 className="text-3xl mb-2">Global Ranking</h1>
            <p className="opacity-90">Top learners worldwide</p>
          </div>
        </div>
      </div>

      <div className="px-6 py-6 space-y-3">
        {rankings.map((user, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: index * 0.05 }}
          >
            <Card className={`p-4 rounded-2xl shadow-lg border-2 ${user.isCurrentUser ? 'border-primary' : 'border-transparent'}`}>
              <div className="flex items-center gap-4">
                <div className="text-2xl w-12 text-center">{user.rank <= 3 ? user.avatar : `#${user.rank}`}</div>
                <div className="text-3xl">{user.country}</div>
                <div className="flex-1">
                  <h4>{user.name}</h4>
                  <div className="flex items-center gap-2 mt-1">
                    <Star className="w-4 h-4 text-[#FCD116]" />
                    <span className="text-sm text-muted-foreground">{user.xp} XP</span>
                  </div>
                </div>
                {user.rank <= 3 && <Trophy className="w-6 h-6 text-[#FCD116]" />}
              </div>
            </Card>
          </motion.div>
        ))}
      </div>
    </div>
  );
}

// ==================== PROGRESS TRACKING ====================

const progressData = [
  { day: 'Mon', xp: 45, lessons: 3 },
  { day: 'Tue', xp: 80, lessons: 5 },
  { day: 'Wed', xp: 62, lessons: 4 },
  { day: 'Thu', xp: 95, lessons: 6 },
  { day: 'Fri', xp: 78, lessons: 5 },
  { day: 'Sat', xp: 120, lessons: 8 },
  { day: 'Sun', xp: 88, lessons: 6 },
];

const skillData = [
  { name: 'Vocabulary', value: 85, color: '#CE1126' },
  { name: 'Grammar', value: 72, color: '#007A3D' },
  { name: 'Listening', value: 68, color: '#FCD116' },
  { name: 'Speaking', value: 55, color: '#FF6B35' },
];

export function ProgressTracking({ onBack }: { onBack?: () => void }) {
  return (
    <div className="min-h-screen bg-background pb-24">
      <div className="relative bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="relative">
          {onBack && (
            <Button variant="ghost" size="icon" onClick={onBack} className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full">
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="text-center text-white pt-8">
            <TrendingUp className="w-16 h-16 mx-auto mb-4" />
            <h1 className="text-3xl mb-2">Your Progress</h1>
            <p className="opacity-90">Track your learning journey</p>
          </div>
        </div>
      </div>

      <div className="px-6 py-6 space-y-6">
        <Card className="p-5 rounded-2xl shadow-lg border-0">
          <h3 className="mb-4">Weekly XP</h3>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={progressData}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="day" />
              <YAxis />
              <Tooltip />
              <Bar dataKey="xp" fill="#CE1126" />
            </BarChart>
          </ResponsiveContainer>
        </Card>

        <Card className="p-5 rounded-2xl shadow-lg border-0">
          <h3 className="mb-4">Skills Breakdown</h3>
          <div className="space-y-4">
            {skillData.map((skill, i) => (
              <div key={i}>
                <div className="flex justify-between mb-2">
                  <span className="text-sm">{skill.name}</span>
                  <span className="text-sm">{skill.value}%</span>
                </div>
                <Progress value={skill.value} className="h-2" style={{ backgroundColor: `${skill.color}20` }} />
              </div>
            ))}
          </div>
        </Card>

        <div className="grid grid-cols-2 gap-4">
          <Card className="p-4 rounded-2xl shadow-lg border-0 text-center">
            <BarChart3 className="w-8 h-8 text-primary mx-auto mb-2" />
            <div className="text-2xl mb-1">24</div>
            <div className="text-xs text-muted-foreground">Lessons Completed</div>
          </Card>
          <Card className="p-4 rounded-2xl shadow-lg border-0 text-center">
            <Flame className="w-8 h-8 text-[#FF6B35] mx-auto mb-2" />
            <div className="text-2xl mb-1">12</div>
            <div className="text-xs text-muted-foreground">Day Streak</div>
          </Card>
        </div>
      </div>
    </div>
  );
}

// ==================== DAILY CHALLENGES ====================

export function DailyChallenges({ onBack }: { onBack?: () => void }) {
  const challenges = [
    { id: 1, title: 'Complete 3 lessons', progress: 2, total: 3, xp: 50, completed: false },
    { id: 2, title: 'Practice for 20 minutes', progress: 15, total: 20, xp: 30, completed: false },
    { id: 3, title: 'Score 90% on a quiz', progress: 85, total: 90, xp: 75, completed: false },
    { id: 4, title: 'Use AI Tutor', progress: 1, total: 1, xp: 25, completed: true },
  ];

  const totalXP = challenges.reduce((sum, c) => sum + (c.completed ? c.xp : 0), 0);

  return (
    <div className="min-h-screen bg-background">
      <div className="relative bg-gradient-to-br from-[#007A3D] to-[#00A8E8] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="relative">
          {onBack && (
            <Button variant="ghost" size="icon" onClick={onBack} className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full">
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="text-center text-white pt-8">
            <Target className="w-16 h-16 mx-auto mb-4" />
            <h1 className="text-3xl mb-2">Daily Challenges</h1>
            <p className="opacity-90">Complete challenges to earn extra XP</p>
          </div>
        </div>
      </div>

      <div className="px-6 py-6">
        <Card className="p-5 rounded-2xl shadow-lg border-0 mb-6">
          <div className="flex items-center justify-between">
            <div>
              <h3>Today's Progress</h3>
              <p className="text-sm text-muted-foreground mt-1">{totalXP} XP earned</p>
            </div>
            <Badge className="bg-[#007A3D] text-white px-4 py-2">{challenges.filter(c => c.completed).length}/{challenges.length}</Badge>
          </div>
        </Card>

        <div className="space-y-3">
          {challenges.map((challenge, index) => (
            <motion.div
              key={challenge.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card className={`p-5 rounded-2xl shadow-lg border-2 ${challenge.completed ? 'border-[#007A3D] bg-[#007A3D]/5' : 'border-transparent'}`}>
                <div className="flex items-start gap-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${challenge.completed ? 'bg-[#007A3D]' : 'bg-muted'}`}>
                    {challenge.completed ? (
                      <Check className="w-5 h-5 text-white" />
                    ) : (
                      <Target className="w-5 h-5 text-muted-foreground" />
                    )}
                  </div>
                  <div className="flex-1">
                    <h4 className="mb-1">{challenge.title}</h4>
                    <div className="flex items-center gap-3 mb-2">
                      <Progress value={(challenge.progress / challenge.total) * 100} className="h-2 flex-1" />
                      <span className="text-xs text-muted-foreground">{challenge.progress}/{challenge.total}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Star className="w-4 h-4 text-[#FCD116]" />
                      <span className="text-sm text-muted-foreground">{challenge.xp} XP</span>
                    </div>
                  </div>
                </div>
              </Card>
            </motion.div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ==================== INCENTIVES ====================

export function IncentivesScreen({ onBack }: { onBack?: () => void }) {
  const badges = [
    { name: 'First Steps', icon: '🌱', earned: true, date: 'Jan 15' },
    { name: 'Week Warrior', icon: '⚔️', earned: true, date: 'Jan 22' },
    { name: 'Quiz Master', icon: '🎓', earned: true, date: 'Feb 1' },
    { name: 'Speed Demon', icon: '⚡', earned: false },
    { name: 'Perfect Score', icon: '💯', earned: false },
    { name: 'Legend', icon: '👑', earned: false },
  ];

  return (
    <div className="min-h-screen bg-background pb-24">
      <div className="relative bg-gradient-to-br from-[#FCD116] to-[#FF6B35] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="relative">
          {onBack && (
            <Button variant="ghost" size="icon" onClick={onBack} className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full">
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="text-center text-white pt-8">
            <Trophy className="w-16 h-16 mx-auto mb-4" />
            <h1 className="text-3xl mb-2">Achievements</h1>
            <p className="opacity-90">Your rewards & badges</p>
          </div>
        </div>
      </div>

      <div className="px-6 py-6">
        <Tabs defaultValue="badges" className="mb-6">
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="badges">Badges</TabsTrigger>
            <TabsTrigger value="streaks">Streaks</TabsTrigger>
            <TabsTrigger value="xp">XP</TabsTrigger>
          </TabsList>

          <TabsContent value="badges" className="space-y-3 mt-6">
            <div className="grid grid-cols-3 gap-3">
              {badges.map((badge, i) => (
                <Card
                  key={i}
                  className={`p-4 rounded-2xl text-center ${badge.earned ? 'shadow-lg border-primary/20' : 'opacity-40'}`}
                >
                  <div className="text-4xl mb-2">{badge.icon}</div>
                  <p className="text-xs mb-1">{badge.name}</p>
                  {badge.earned && <p className="text-xs text-muted-foreground">{badge.date}</p>}
                </Card>
              ))}
            </div>
          </TabsContent>

          <TabsContent value="streaks" className="mt-6">
            <Card className="p-6 rounded-2xl shadow-lg text-center">
              <Flame className="w-16 h-16 text-[#FF6B35] mx-auto mb-4" />
              <div className="text-4xl mb-2">12 Days</div>
              <p className="text-muted-foreground">Current Streak</p>
              <Separator className="my-4" />
              <div className="grid grid-cols-7 gap-2">
                {[...Array(7)].map((_, i) => (
                  <div key={i} className={`h-8 rounded-lg ${i < 5 ? 'bg-[#FF6B35]' : 'bg-muted'}`} />
                ))}
              </div>
            </Card>
          </TabsContent>

          <TabsContent value="xp" className="mt-6">
            <Card className="p-6 rounded-2xl shadow-lg text-center">
              <Zap className="w-16 h-16 text-primary mx-auto mb-4" />
              <div className="text-4xl mb-2">2,450</div>
              <p className="text-muted-foreground mb-4">Total XP</p>
              <Progress value={45} className="h-3 mb-2" />
              <p className="text-sm text-muted-foreground">550 XP to Level 9</p>
            </Card>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}

// ==================== COMMUNITY CHAT ====================

export function CommunityChatRoom({ onBack }: { onBack?: () => void }) {
  const [message, setMessage] = useState('');
  const messages = [
    { user: 'Amara', text: 'Jambo everyone! How is everyone doing today?', time: '10:30' },
    { user: 'Kofi', text: 'Nzuri sana! Just finished lesson 5 🎉', time: '10:32' },
    { user: 'You', text: 'Congratulations! I\'m working on lesson 3', time: '10:33', isYou: true },
  ];

  return (
    <div className="min-h-screen bg-background flex flex-col">
      <div className="sticky top-0 z-10 bg-gradient-to-br from-[#007A3D] to-[#00A8E8] px-6 py-4 shadow-lg">
        <div className="flex items-center gap-3">
          {onBack && (
            <Button variant="ghost" size="icon" onClick={onBack} className="text-white hover:bg-white/20 rounded-full">
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="flex-1">
            <h2 className="text-white">Community Chat</h2>
            <p className="text-sm text-white/80">1,234 learners online</p>
          </div>
          <Badge className="bg-white/20 text-white"><Users className="w-4 h-4" /></Badge>
        </div>
      </div>

      <div className="flex-1 px-6 py-6 overflow-y-auto">
        <div className="space-y-4">
          {messages.map((msg, i) => (
            <div key={i} className={`flex ${msg.isYou ? 'justify-end' : 'justify-start'}`}>
              <div className={`max-w-[80%] ${msg.isYou ? 'bg-primary text-white' : 'bg-card'} p-4 rounded-2xl ${msg.isYou ? 'rounded-tr-sm' : 'rounded-tl-sm'} shadow`}>
                {!msg.isYou && <p className="text-xs text-muted-foreground mb-1">{msg.user}</p>}
                <p className="text-sm">{msg.text}</p>
                <p className={`text-xs mt-1 ${msg.isYou ? 'text-white/70' : 'text-muted-foreground'}`}>{msg.time}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="sticky bottom-0 p-6 bg-gradient-to-t from-background via-background to-transparent">
        <div className="flex gap-2">
          <Input
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Type a message..."
            className="flex-1 h-12 rounded-2xl bg-card border-0 shadow"
          />
          <Button className="rounded-full w-12 h-12 bg-gradient-to-br from-[#007A3D] to-[#00A8E8]" size="icon">
            <Send className="w-5 h-5" />
          </Button>
        </div>
      </div>
    </div>
  );
}

// ==================== DIRECT MESSAGING ====================

export function DirectMessaging({ onBack }: { onBack?: () => void }) {
  const chats = [
    { name: 'Amara', lastMsg: 'See you in the next lesson!', time: '2m ago', unread: 2, avatar: '😊' },
    { name: 'Kofi', lastMsg: 'Thanks for the help!', time: '1h ago', unread: 0, avatar: '🙂' },
    { name: 'Zuri', lastMsg: 'That quiz was tough!', time: '3h ago', unread: 1, avatar: '😄' },
  ];

  return (
    <div className="min-h-screen bg-background">
      <div className="sticky top-0 z-10 bg-gradient-to-br from-[#7B2CBF] to-[#CE1126] px-6 py-4 shadow-lg">
        <div className="flex items-center gap-3">
          {onBack && (
            <Button variant="ghost" size="icon" onClick={onBack} className="text-white hover:bg-white/20 rounded-full">
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <h2 className="text-white flex-1">Messages</h2>
          <Button variant="ghost" size="icon" className="text-white hover:bg-white/20 rounded-full">
            <MessageCircle className="w-5 h-5" />
          </Button>
        </div>
      </div>

      <div className="px-6 py-6 space-y-3">
        {chats.map((chat, i) => (
          <Card key={i} className="p-4 rounded-2xl shadow-lg border-0 cursor-pointer hover:shadow-xl transition-all">
            <div className="flex items-center gap-4">
              <div className="text-3xl">{chat.avatar}</div>
              <div className="flex-1">
                <div className="flex items-center justify-between mb-1">
                  <h4>{chat.name}</h4>
                  <span className="text-xs text-muted-foreground">{chat.time}</span>
                </div>
                <p className="text-sm text-muted-foreground">{chat.lastMsg}</p>
              </div>
              {chat.unread > 0 && (
                <Badge className="bg-primary text-white rounded-full w-6 h-6 flex items-center justify-center p-0">
                  {chat.unread}
                </Badge>
              )}
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}

// ==================== MAGAZINES ====================

export function MagazineHub({ onBack, onSelectCategory }: { onBack?: () => void; onSelectCategory: (category: string) => void }) {
  const categories = [
    { id: 'music', name: 'Music', icon: Music, gradient: 'from-[#CE1126] to-[#FF6B35]', articles: 24 },
    { id: 'stories', name: 'Stories', icon: BookOpen, gradient: 'from-[#007A3D] to-[#00A8E8]', articles: 18 },
    { id: 'news', name: 'News', icon: Newspaper, gradient: 'from-[#FCD116] to-[#FF6B35]', articles: 32 },
    { id: 'history', name: 'History', icon: Globe, gradient: 'from-[#7B2CBF] to-[#CE1126]', articles: 15 },
    { id: 'art', name: 'Art', icon: Palette, gradient: 'from-[#FF6B35] to-[#7B2CBF]', articles: 21 },
  ];

  return (
    <div className="min-h-screen bg-background">
      <div className="relative bg-gradient-to-br from-[#FF6B35] to-[#7B2CBF] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="relative">
          {onBack && (
            <Button variant="ghost" size="icon" onClick={onBack} className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full">
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="text-center text-white pt-8">
            <Newspaper className="w-16 h-16 mx-auto mb-4" />
            <h1 className="text-3xl mb-2">Cultural Magazines</h1>
            <p className="opacity-90">Explore African culture & heritage</p>
          </div>
        </div>
      </div>

      <div className="px-6 py-6 space-y-4">
        {categories.map((cat, index) => {
          const Icon = cat.icon;
          return (
            <motion.div
              key={cat.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
            >
              <Card
                onClick={() => onSelectCategory(cat.id)}
                className="p-5 rounded-2xl shadow-lg border-0 cursor-pointer hover:shadow-xl transition-all overflow-hidden relative"
              >
                <div className={`absolute inset-0 bg-gradient-to-br ${cat.gradient} opacity-5`} />
                <div className="relative flex items-center gap-4">
                  <div className={`p-4 rounded-2xl bg-gradient-to-br ${cat.gradient} shadow-md`}>
                    <Icon className="w-8 h-8 text-white" />
                  </div>
                  <div className="flex-1">
                    <h3 className="mb-1">{cat.name}</h3>
                    <p className="text-sm text-muted-foreground">{cat.articles} articles</p>
                  </div>
                </div>
              </Card>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}

// ==================== MEDIA IMPORT ====================

export function MediaImport({ onBack }: { onBack?: () => void }) {
  return (
    <div className="min-h-screen bg-background">
      <div className="relative bg-gradient-to-br from-[#007A3D] to-[#00A8E8] px-6 pt-12 pb-8 rounded-b-[2.5rem] shadow-lg">
        <div className="relative">
          {onBack && (
            <Button variant="ghost" size="icon" onClick={onBack} className="absolute -left-2 -top-2 text-white hover:bg-white/20 rounded-full">
              <ArrowLeft className="w-5 h-5" />
            </Button>
          )}
          <div className="text-center text-white pt-8">
            <Upload className="w-16 h-16 mx-auto mb-4" />
            <h1 className="text-3xl mb-2">Media Import</h1>
            <p className="opacity-90">Share your content with the community</p>
          </div>
        </div>
      </div>

      <div className="px-6 py-8">
        <Card className="p-8 rounded-2xl shadow-lg border-2 border-dashed border-primary/30 text-center cursor-pointer hover:border-primary transition-all">
          <ImageIcon className="w-16 h-16 text-primary mx-auto mb-4" />
          <h3 className="mb-2">Upload Media</h3>
          <p className="text-sm text-muted-foreground mb-6">Drag and drop or click to browse</p>
          <Button className="bg-gradient-to-r from-[#007A3D] to-[#00A8E8] text-white">
            Select Files
          </Button>
        </Card>

        <div className="mt-8 space-y-3">
          <h3 className="mb-4">Supported Formats</h3>
          <div className="grid grid-cols-3 gap-3">
            <Card className="p-4 text-center rounded-xl">
              <p className="text-sm">Images</p>
              <p className="text-xs text-muted-foreground mt-1">JPG, PNG</p>
            </Card>
            <Card className="p-4 text-center rounded-xl">
              <p className="text-sm">Videos</p>
              <p className="text-xs text-muted-foreground mt-1">MP4, MOV</p>
            </Card>
            <Card className="p-4 text-center rounded-xl">
              <p className="text-sm">Audio</p>
              <p className="text-xs text-muted-foreground mt-1">MP3, WAV</p>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}
