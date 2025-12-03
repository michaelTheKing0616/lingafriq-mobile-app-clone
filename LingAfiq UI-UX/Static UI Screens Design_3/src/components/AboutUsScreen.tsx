import React from 'react';
import { ArrowLeft, Mail, Globe, MapPin, Heart } from 'lucide-react';

export function AboutUsScreen() {
  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] px-6 py-8 shadow-lg">
        <div className="flex items-center gap-4 mb-6">
          <button className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center">
            <ArrowLeft className="w-5 h-5 text-white" />
          </button>
          <h1 className="text-white">About LingAfriq</h1>
        </div>

        {/* Logo */}
        <div className="flex justify-center mb-6">
          <div className="w-24 h-24 bg-white/20 backdrop-blur-sm rounded-full flex items-center justify-center border-2 border-white/40">
            <span className="text-5xl">🌍</span>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="px-6 py-6 space-y-6">
        {/* Mission Statement */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h2 className="text-gray-800 mb-4">Our Mission</h2>
          <p className="text-gray-600 mb-4">
            LingAfriq is dedicated to preserving and promoting African languages through innovative, 
            accessible, and engaging digital learning experiences.
          </p>
          <p className="text-gray-600">
            We believe that every African language carries centuries of wisdom, culture, and 
            identity. By making these languages accessible to learners worldwide, we help 
            preserve cultural heritage and build bridges between communities.
          </p>
        </div>

        {/* Values */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4">Our Values</h3>
          <div className="space-y-4">
            <div className="flex gap-3">
              <div className="w-10 h-10 bg-[#007A3D]/10 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-2xl">🌍</span>
              </div>
              <div>
                <h4 className="text-gray-800 mb-1">Cultural Preservation</h4>
                <p className="text-gray-600 text-sm">
                  Protecting and celebrating Africa's linguistic diversity
                </p>
              </div>
            </div>

            <div className="flex gap-3">
              <div className="w-10 h-10 bg-[#FCD116]/10 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-2xl">📚</span>
              </div>
              <div>
                <h4 className="text-gray-800 mb-1">Accessible Education</h4>
                <p className="text-gray-600 text-sm">
                  Making language learning free and accessible to all
                </p>
              </div>
            </div>

            <div className="flex gap-3">
              <div className="w-10 h-10 bg-[#FF6B35]/10 rounded-full flex items-center justify-center flex-shrink-0">
                <span className="text-2xl">🤝</span>
              </div>
              <div>
                <h4 className="text-gray-800 mb-1">Community First</h4>
                <p className="text-gray-600 text-sm">
                  Building a supportive global community of learners
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Team */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4">Our Team</h3>
          <p className="text-gray-600 mb-4">
            LingAfriq is built by a diverse team of linguists, educators, developers, and 
            cultural enthusiasts from across Africa and the diaspora.
          </p>
          <div className="flex items-center gap-2">
            <Heart className="w-5 h-5 text-red-500" />
            <p className="text-gray-600 text-sm">Made with love from Nigeria, Kenya, Ethiopia, and beyond</p>
          </div>
        </div>

        {/* Contact Information */}
        <div className="bg-white rounded-2xl p-6 shadow-md">
          <h3 className="text-gray-800 mb-4">Get in Touch</h3>
          <div className="space-y-3">
            <div className="flex items-center gap-3 text-gray-600">
              <Mail className="w-5 h-5 text-[#007A3D]" />
              <span>contact@lingafriq.com</span>
            </div>
            <div className="flex items-center gap-3 text-gray-600">
              <Globe className="w-5 h-5 text-[#007A3D]" />
              <span>www.lingafriq.com</span>
            </div>
            <div className="flex items-center gap-3 text-gray-600">
              <MapPin className="w-5 h-5 text-[#007A3D]" />
              <span>Pan-African Initiative</span>
            </div>
          </div>
        </div>

        {/* Social Media */}
        <div className="bg-gradient-to-r from-[#007A3D] to-[#005A2D] rounded-2xl p-6 text-white text-center shadow-md">
          <h3 className="mb-4">Follow Us</h3>
          <div className="flex justify-center gap-4">
            <button className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition-colors">
              <span className="text-xl">📱</span>
            </button>
            <button className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition-colors">
              <span className="text-xl">🐦</span>
            </button>
            <button className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition-colors">
              <span className="text-xl">📘</span>
            </button>
            <button className="w-12 h-12 bg-white/20 rounded-full flex items-center justify-center hover:bg-white/30 transition-colors">
              <span className="text-xl">📸</span>
            </button>
          </div>
        </div>

        {/* Version */}
        <div className="text-center text-gray-500 text-sm">
          <p>LingAfriq v1.2.3</p>
          <p className="mt-1">© 2024 LingAfriq. All rights reserved.</p>
        </div>
      </div>
    </div>
  );
}
