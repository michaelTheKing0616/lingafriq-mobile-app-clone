import { Mail, Globe, Twitter, Facebook, Instagram } from 'lucide-react';

export function AboutUsScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-12 rounded-b-[32px]">
        <button className="p-2 hover:bg-white/10 rounded-lg transition-colors mb-6">
          <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
          </svg>
        </button>
        
        <div className="text-center text-white">
          <div className="text-6xl mb-4">🌍</div>
          <h1 className="mb-2">LingAfriq</h1>
          <p className="text-white/90">African Language Learning</p>
        </div>
      </div>

      <div className="px-6 py-8">
        {/* Mission Section */}
        <div className="bg-white rounded-3xl p-6 shadow-sm mb-6">
          <h2 className="text-gray-900 mb-4">Our Mission</h2>
          <p className="text-gray-700 leading-relaxed mb-4">
            LingAfriq is dedicated to preserving and promoting African languages through innovative, engaging, and accessible language learning experiences.
          </p>
          <p className="text-gray-700 leading-relaxed">
            We believe that language is the gateway to culture, and by learning African languages, we connect people across the continent and around the world.
          </p>
        </div>

        {/* Vision Section */}
        <div className="bg-gradient-to-br from-[#007A3D]/10 to-[#FF6B35]/10 rounded-3xl p-6 mb-6 border-2 border-[#007A3D]/20">
          <div className="flex items-start gap-4">
            <div className="text-4xl">✨</div>
            <div>
              <h3 className="text-gray-900 mb-2">Our Vision</h3>
              <p className="text-gray-700 text-sm leading-relaxed">
                To become the world's leading platform for African language education, making every African language accessible to learners worldwide while celebrating the rich cultural heritage of the African continent.
              </p>
            </div>
          </div>
        </div>

        {/* Team Section */}
        <div className="bg-white rounded-3xl p-6 shadow-sm mb-6">
          <h2 className="text-gray-900 mb-4">Our Team</h2>
          <p className="text-gray-700 leading-relaxed mb-4">
            LingAfriq was founded by a passionate team of linguists, educators, and technology experts from across Africa, united by the goal of preserving and promoting African languages.
          </p>
          
          <div className="grid grid-cols-2 gap-4">
            <div className="text-center">
              <div className="w-20 h-20 bg-gradient-to-br from-[#007A3D] to-[#FF6B35] rounded-full flex items-center justify-center mx-auto mb-2 text-white text-2xl">
                A
              </div>
              <p className="text-sm text-gray-900">Adisa Okafor</p>
              <p className="text-xs text-gray-500">Founder & CEO</p>
            </div>
            
            <div className="text-center">
              <div className="w-20 h-20 bg-gradient-to-br from-[#FF6B35] to-[#FCD116] rounded-full flex items-center justify-center mx-auto mb-2 text-white text-2xl">
                K
              </div>
              <p className="text-sm text-gray-900">Kwame Mensah</p>
              <p className="text-xs text-gray-500">Head of Education</p>
            </div>
          </div>
        </div>

        {/* Contact Section */}
        <div className="bg-white rounded-3xl p-6 shadow-sm mb-6">
          <h2 className="text-gray-900 mb-4">Contact Us</h2>
          
          <div className="space-y-4">
            <a href="mailto:hello@lingafriq.com" className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors">
              <Mail className="w-5 h-5 text-[#007A3D]" />
              <span className="text-gray-700">hello@lingafriq.com</span>
            </a>
            
            <a href="https://lingafriq.com" className="flex items-center gap-3 p-3 bg-gray-50 rounded-xl hover:bg-gray-100 transition-colors">
              <Globe className="w-5 h-5 text-[#007A3D]" />
              <span className="text-gray-700">www.lingafriq.com</span>
            </a>
          </div>
        </div>

        {/* Social Media */}
        <div className="bg-white rounded-3xl p-6 shadow-sm mb-6">
          <h2 className="text-gray-900 mb-4">Follow Us</h2>
          
          <div className="grid grid-cols-3 gap-3">
            <button className="p-4 bg-gradient-to-br from-blue-500 to-blue-600 rounded-2xl text-white flex flex-col items-center gap-2 hover:shadow-lg transition-all">
              <Twitter className="w-6 h-6" />
              <span className="text-xs">Twitter</span>
            </button>
            
            <button className="p-4 bg-gradient-to-br from-blue-600 to-blue-700 rounded-2xl text-white flex flex-col items-center gap-2 hover:shadow-lg transition-all">
              <Facebook className="w-6 h-6" />
              <span className="text-xs">Facebook</span>
            </button>
            
            <button className="p-4 bg-gradient-to-br from-pink-500 to-purple-600 rounded-2xl text-white flex flex-col items-center gap-2 hover:shadow-lg transition-all">
              <Instagram className="w-6 h-6" />
              <span className="text-xs">Instagram</span>
            </button>
          </div>
        </div>

        {/* Values */}
        <div className="bg-white rounded-3xl p-6 shadow-sm">
          <h2 className="text-gray-900 mb-4">Our Values</h2>
          
          <div className="space-y-4">
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-[#007A3D]/10 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-lg">🎯</span>
              </div>
              <div>
                <p className="text-gray-900 mb-1">Excellence</p>
                <p className="text-sm text-gray-600">Delivering the highest quality learning experience</p>
              </div>
            </div>
            
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-[#FF6B35]/10 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-lg">🤝</span>
              </div>
              <div>
                <p className="text-gray-900 mb-1">Community</p>
                <p className="text-sm text-gray-600">Building connections across cultures</p>
              </div>
            </div>
            
            <div className="flex items-start gap-3">
              <div className="w-8 h-8 bg-[#FCD116]/10 rounded-lg flex items-center justify-center flex-shrink-0">
                <span className="text-lg">🌱</span>
              </div>
              <div>
                <p className="text-gray-900 mb-1">Preservation</p>
                <p className="text-sm text-gray-600">Safeguarding linguistic heritage</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="h-20" />
    </div>
  );
}
