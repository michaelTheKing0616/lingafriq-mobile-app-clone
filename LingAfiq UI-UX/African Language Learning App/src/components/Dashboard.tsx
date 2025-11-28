import { motion } from 'motion/react';
import { Button } from './ui/button';
import { Card } from './ui/card';
import { Progress } from './ui/progress';
import { Avatar, AvatarFallback, AvatarImage } from './ui/avatar';
import { Badge } from './ui/badge';
import {
  Flame,
  Target,
  BookOpen,
  Trophy,
  MessageCircle,
  Users,
  Newspaper,
  Settings,
  ChevronRight,
  Star,
  Zap,
  Clock,
  TrendingUp,
} from 'lucide-react';

interface DashboardProps {
  onNavigate: (screen: string) => void;
}

export default function Dashboard({ onNavigate }: DashboardProps) {
  const userStats = {
    name: 'Kwame',
    avatar: 'https://images.unsplash.com/photo-1744809482817-9a9d4fc280af?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhZnJpY2FuJTIwc3R1ZGVudCUyMGxlYXJuaW5nfGVufDF8fHx8MTc2NDMwNTUzNHww&ixlib=rb-4.1.0&q=80&w=1080',
    streak: 12,
    xp: 2450,
    level: 8,
    todayGoal: 75,
    language: 'Swahili',
  };

  const quickActions = [
    {
      icon: BookOpen,
      label: 'Continue Learning',
      color: 'from-[#CE1126] to-[#FF6B35]',
      screen: 'lesson',
    },
    {
      icon: MessageCircle,
      label: 'AI Tutor',
      color: 'from-[#007A3D] to-[#00A8E8]',
      screen: 'ai-chat',
    },
    {
      icon: Target,
      label: 'Daily Challenge',
      color: 'from-[#FCD116] to-[#FF6B35]',
      screen: 'daily-challenge',
    },
    {
      icon: Trophy,
      label: 'Games',
      color: 'from-[#7B2CBF] to-[#CE1126]',
      screen: 'games',
    },
  ];

  const todayProgress = [
    { label: 'Vocabulary', completed: 15, total: 20, color: 'bg-[#CE1126]' },
    { label: 'Grammar', completed: 8, total: 10, color: 'bg-[#007A3D]' },
    { label: 'Speaking', completed: 5, total: 5, color: 'bg-[#FCD116]' },
  ];

  return (
    <div className="min-h-screen bg-background pb-24">
      {/* Header */}
      <div className="relative bg-gradient-to-br from-[#CE1126] to-[#FF6B35] rounded-b-[2.5rem] px-6 pt-12 pb-8 shadow-lg">
        {/* Decorative Pattern */}
        <div className="absolute inset-0 opacity-10">
          <div
            className="absolute inset-0"
            style={{
              backgroundImage: `repeating-linear-gradient(45deg, transparent, transparent 35px, rgba(255, 255, 255, 0.3) 35px, rgba(255, 255, 255, 0.3) 70px)`,
            }}
          />
        </div>

        <div className="relative">
          {/* Top Bar */}
          <div className="flex justify-between items-center mb-6">
            <div className="flex items-center gap-3">
              <Avatar className="w-12 h-12 border-2 border-white shadow-lg">
                <AvatarImage src={userStats.avatar} alt={userStats.name} />
                <AvatarFallback>{userStats.name[0]}</AvatarFallback>
              </Avatar>
              <div className="text-white">
                <p className="text-sm opacity-90">Hello,</p>
                <h2 className="text-xl">{userStats.name}!</h2>
              </div>
            </div>
            <Button
              variant="ghost"
              size="icon"
              onClick={() => onNavigate('settings')}
              className="rounded-full bg-white/20 hover:bg-white/30 text-white"
            >
              <Settings className="w-5 h-5" />
            </Button>
          </div>

          {/* Stats Cards */}
          <div className="grid grid-cols-3 gap-3">
            <Card className="bg-white/95 backdrop-blur-sm p-3 rounded-2xl border-0 shadow-md">
              <div className="flex items-center gap-2 mb-1">
                <div className="p-1.5 rounded-lg bg-[#FF6B35]/10">
                  <Flame className="w-4 h-4 text-[#FF6B35]" />
                </div>
              </div>
              <p className="text-2xl">{userStats.streak}</p>
              <p className="text-xs text-muted-foreground">Day Streak</p>
            </Card>

            <Card className="bg-white/95 backdrop-blur-sm p-3 rounded-2xl border-0 shadow-md">
              <div className="flex items-center gap-2 mb-1">
                <div className="p-1.5 rounded-lg bg-[#FCD116]/10">
                  <Zap className="w-4 h-4 text-[#CE1126]" />
                </div>
              </div>
              <p className="text-2xl">{userStats.xp}</p>
              <p className="text-xs text-muted-foreground">Total XP</p>
            </Card>

            <Card className="bg-white/95 backdrop-blur-sm p-3 rounded-2xl border-0 shadow-md">
              <div className="flex items-center gap-2 mb-1">
                <div className="p-1.5 rounded-lg bg-[#007A3D]/10">
                  <Star className="w-4 h-4 text-[#007A3D]" />
                </div>
              </div>
              <p className="text-2xl">Lvl {userStats.level}</p>
              <p className="text-xs text-muted-foreground">Current</p>
            </Card>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="px-6 -mt-4">
        {/* Today's Goal */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
        >
          <Card className="p-5 rounded-2xl shadow-lg border-0 mb-6">
            <div className="flex justify-between items-center mb-3">
              <div className="flex items-center gap-2">
                <Target className="w-5 h-5 text-primary" />
                <h3>Today's Goal</h3>
              </div>
              <Badge className="bg-primary/10 text-primary hover:bg-primary/20">
                {userStats.todayGoal}%
              </Badge>
            </div>
            <Progress value={userStats.todayGoal} className="h-3 mb-3" />
            <div className="grid grid-cols-3 gap-3">
              {todayProgress.map((item, index) => (
                <div key={index} className="text-center">
                  <div className={`h-1 ${item.color} rounded-full mb-1`} />
                  <p className="text-xs text-muted-foreground">{item.label}</p>
                  <p className="text-sm">
                    {item.completed}/{item.total}
                  </p>
                </div>
              ))}
            </div>
          </Card>
        </motion.div>

        {/* Quick Actions */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="mb-6"
        >
          <h3 className="mb-4">Quick Actions</h3>
          <div className="grid grid-cols-2 gap-3">
            {quickActions.map((action, index) => (
              <motion.button
                key={index}
                onClick={() => onNavigate(action.screen)}
                whileTap={{ scale: 0.95 }}
                className="relative overflow-hidden rounded-2xl p-5 text-left group"
              >
                <div
                  className={`absolute inset-0 bg-gradient-to-br ${action.color} opacity-90 group-hover:opacity-100 transition-opacity`}
                />
                <div className="relative">
                  <action.icon className="w-8 h-8 text-white mb-3" />
                  <p className="text-white">{action.label}</p>
                </div>
              </motion.button>
            ))}
          </div>
        </motion.div>

        {/* Current Course */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="mb-6"
        >
          <div className="flex justify-between items-center mb-4">
            <h3>Continue {userStats.language}</h3>
            <Button variant="ghost" size="sm" onClick={() => onNavigate('course')}>
              View All
              <ChevronRight className="w-4 h-4 ml-1" />
            </Button>
          </div>
          <Card
            className="p-5 rounded-2xl shadow-lg border-0 cursor-pointer hover:shadow-xl transition-shadow"
            onClick={() => onNavigate('lesson')}
          >
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#007A3D] to-[#00A8E8] flex items-center justify-center">
                <BookOpen className="w-8 h-8 text-white" />
              </div>
              <div className="flex-1">
                <h4>Lesson 5: Greetings & Introductions</h4>
                <p className="text-sm text-muted-foreground mt-1">Unit 2 • 15 min</p>
                <div className="flex items-center gap-2 mt-2">
                  <Progress value={60} className="h-2 flex-1" />
                  <span className="text-xs text-muted-foreground">60%</span>
                </div>
              </div>
            </div>
          </Card>
        </motion.div>

        {/* Community & Resources */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mb-6"
        >
          <h3 className="mb-4">Explore More</h3>
          <div className="grid grid-cols-2 gap-3">
            <Card
              className="p-4 rounded-2xl border-0 shadow cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => onNavigate('community')}
            >
              <Users className="w-6 h-6 text-primary mb-2" />
              <p className="text-sm">Community Chat</p>
              <p className="text-xs text-muted-foreground mt-1">Join the conversation</p>
            </Card>
            <Card
              className="p-4 rounded-2xl border-0 shadow cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => onNavigate('magazine')}
            >
              <Newspaper className="w-6 h-6 text-accent mb-2" />
              <p className="text-sm">Magazines</p>
              <p className="text-xs text-muted-foreground mt-1">Culture & stories</p>
            </Card>
            <Card
              className="p-4 rounded-2xl border-0 shadow cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => onNavigate('ranking')}
            >
              <TrendingUp className="w-6 h-6 text-secondary mb-2" />
              <p className="text-sm">Global Ranking</p>
              <p className="text-xs text-muted-foreground mt-1">See your position</p>
            </Card>
            <Card
              className="p-4 rounded-2xl border-0 shadow cursor-pointer hover:shadow-lg transition-shadow"
              onClick={() => onNavigate('progress')}
            >
              <Clock className="w-6 h-6 text-destructive mb-2" />
              <p className="text-sm">Progress</p>
              <p className="text-xs text-muted-foreground mt-1">Track your journey</p>
            </Card>
          </div>
        </motion.div>
      </div>
    </div>
  );
}
