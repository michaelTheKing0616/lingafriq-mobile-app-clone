import React from 'react';
import { ArrowLeft, Bookmark, Clock, Search } from 'lucide-react';
import { ImageWithFallback } from './figma/ImageWithFallback';

export function CultureMagazineScreen() {
  const [activeTab, setActiveTab] = React.useState<'featured' | 'history' | 'culture' | 'music' | 'food'>('featured');

  const articles = [
    {
      id: 1,
      title: 'The Rich History of Swahili Language',
      excerpt: 'Discover how Swahili became one of the most widely spoken languages in East Africa...',
      category: 'History',
      readTime: '5 min read',
      image: 'https://images.unsplash.com/photo-1630067458414-0080622bc0df?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxTd2FoaWxpJTIwY3VsdHVyZSUyMFRhbnphbmlhfGVufDF8fHx8MTc2NDc1ODg2M3ww&ixlib=rb-4.1.0&q=80&w=1080',
      featured: true
    },
    {
      id: 2,
      title: 'Yoruba Music and Dance Traditions',
      excerpt: 'Explore the vibrant musical heritage of the Yoruba people and its influence on modern music...',
      category: 'Music',
      readTime: '7 min read',
      image: 'https://images.unsplash.com/photo-1630510590499-fdd4ff8cb295?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBZnJpY2FuJTIwbXVzaWMlMjBkYW5jZXxlbnwxfHx8fDE3NjQ3NTkyNjd8MA&ixlib=rb-4.1.0&q=80&w=1080',
      featured: false
    },
    {
      id: 3,
      title: 'Ethiopian Cuisine: A Cultural Journey',
      excerpt: 'From injera to doro wat, discover the flavors and traditions of Ethiopian food...',
      category: 'Food',
      readTime: '6 min read',
      image: 'https://images.unsplash.com/photo-1665332561290-cc6757172890?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBZnJpY2FuJTIwZm9vZCUyMGN1aXNpbmV8ZW58MXx8fHwxNzY0NzU5MjY3fDA&ixlib=rb-4.1.0&q=80&w=1080',
      featured: false
    },
    {
      id: 4,
      title: 'Zulu Cultural Practices and Traditions',
      excerpt: 'Learn about the customs, ceremonies, and way of life of the Zulu nation...',
      category: 'Culture',
      readTime: '8 min read',
      image: 'https://images.unsplash.com/photo-1672505155432-f25c16aef2a8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxadWx1JTIwU291dGglMjBBZnJpY2F8ZW58MXx8fHwxNzY0NzU4ODY0fDA&ixlib=rb-4.1.0&q=80&w=1080',
      featured: false
    }
  ];

  const getCategoryColor = (category: string) => {
    switch (category.toLowerCase()) {
      case 'history': return 'bg-[#7B2CBF] text-white';
      case 'music': return 'bg-[#FF6B35] text-white';
      case 'food': return 'bg-[#FCD116] text-gray-800';
      case 'culture': return 'bg-[#007A3D] text-white';
      default: return 'bg-gray-200 text-gray-800';
    }
  };

  const featuredArticle = articles.find(a => a.featured);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#FF6B35] to-[#7B2CBF] px-6 py-8 shadow-lg">
        <div className="flex items-center gap-4 mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <div className="flex-1">
            <h1 className="text-white">Cultural Magazine</h1>
            <p className="text-white/80 text-sm">Explore African culture</p>
          </div>
        </div>

        {/* Search Bar */}
        <div className="relative">
          <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-white/60 w-5 h-5" />
          <input
            type="text"
            placeholder="Search articles..."
            className="w-full pl-12 pr-4 py-3 bg-white/20 backdrop-blur-sm border border-white/40 rounded-xl text-white placeholder-white/60 focus:outline-none focus:ring-2 focus:ring-white/50"
          />
        </div>
      </div>

      {/* Tabs */}
      <div className="px-6 py-4 flex gap-2 overflow-x-auto">
        {(['featured', 'history', 'culture', 'music', 'food'] as const).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-5 py-2 rounded-full flex-shrink-0 transition-colors ${
              activeTab === tab
                ? 'bg-[#FF6B35] text-white'
                : 'bg-white text-gray-600 border border-gray-200'
            }`}
          >
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Featured Article */}
        {featuredArticle && activeTab === 'featured' && (
          <div className="bg-white rounded-3xl shadow-xl overflow-hidden">
            <div className="relative h-56">
              <ImageWithFallback 
                src={featuredArticle.image}
                alt={featuredArticle.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
              <div className="absolute top-4 right-4">
                <button className="w-10 h-10 bg-white/90 rounded-full flex items-center justify-center">
                  <Bookmark className="w-5 h-5 text-gray-800" />
                </button>
              </div>
              <div className="absolute bottom-4 left-4 right-4">
                <span className={`inline-block px-3 py-1 rounded-full text-xs mb-2 ${getCategoryColor(featuredArticle.category)}`}>
                  {featuredArticle.category}
                </span>
                <h2 className="text-white mb-1">{featuredArticle.title}</h2>
                <div className="flex items-center gap-2 text-white/80 text-sm">
                  <Clock className="w-4 h-4" />
                  <span>{featuredArticle.readTime}</span>
                </div>
              </div>
            </div>
            <div className="p-6">
              <p className="text-gray-600 mb-4">{featuredArticle.excerpt}</p>
              <button className="bg-gradient-to-r from-[#FF6B35] to-[#7B2CBF] text-white px-6 py-3 rounded-xl shadow-md hover:shadow-lg transition-shadow">
                Read Article
              </button>
            </div>
          </div>
        )}

        {/* Article Grid */}
        <div className="grid grid-cols-2 gap-4">
          {articles.filter(a => !a.featured).map((article) => (
            <div key={article.id} className="bg-white rounded-2xl shadow-md overflow-hidden hover:shadow-lg transition-shadow cursor-pointer">
              <div className="relative h-32">
                <ImageWithFallback 
                  src={article.image}
                  alt={article.title}
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                <span className={`absolute top-2 left-2 px-2 py-1 rounded-full text-xs ${getCategoryColor(article.category)}`}>
                  {article.category}
                </span>
              </div>
              <div className="p-4">
                <h4 className="text-gray-800 text-sm mb-2 line-clamp-2">{article.title}</h4>
                <p className="text-gray-500 text-xs mb-3 line-clamp-2">{article.excerpt}</p>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1 text-gray-500 text-xs">
                    <Clock className="w-3 h-3" />
                    <span>{article.readTime}</span>
                  </div>
                  <button className="text-[#FF6B35] hover:text-[#7B2CBF] transition-colors">
                    <Bookmark className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Load More */}
        <button className="w-full bg-white border-2 border-gray-200 text-gray-700 py-4 rounded-xl hover:border-[#FF6B35] transition-colors">
          Load More Articles
        </button>
      </div>
    </div>
  );
}
