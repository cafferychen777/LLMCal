import React, { useState, useEffect } from 'react';
import { Calendar, Clock, Check, ChevronRight, X, Video, ChevronLeft, ChevronDown } from 'lucide-react';

export default function LLMCalDemo() {
  const [messages, setMessages] = useState([]);
  const [isTyping, setIsTyping] = useState(false);
  const [selectedText, setSelectedText] = useState(null);
  const [showMenu, setShowMenu] = useState(false);
  const [showCalendarAdd, setShowCalendarAdd] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [showCalendarView, setShowCalendarView] = useState(false);
  const [animate, setAnimate] = useState(false);

  const conversation = [
    {
      sender: "friend",
      text: "Hey! Should we schedule that product demo for the client?"
    },
    {
      sender: "me",
      text: "Yes! Let's do it next Tuesday at 3pm"
    },
    {
      sender: "friend",
      text: "Perfect! I'll set up the Zoom call. Here's the link: https://zoom.us/j/123"
    },
    {
      sender: "me",
      text: "Great! So we're set for product demo next Tuesday 3pm with client@example.com, 1 hour on Zoom https://zoom.us/j/123. I'll make sure to add a reminder 15 minutes before."
    }
  ];

  useEffect(() => {
    setTimeout(() => setAnimate(true), 100);
    // 模拟消息逐条发送
    conversation.forEach((msg, index) => {
      setTimeout(() => {
        setIsTyping(true);
        setTimeout(() => {
          setIsTyping(false);
          setMessages(prev => [...prev, msg]);
        }, 1000);
      }, index * 2000);
    });
  }, []);

  const handleTextSelect = () => {
    setSelectedText(conversation[3]);
    setTimeout(() => setShowMenu(true), 500);
  };

  const handleAddToCalendar = () => {
    setShowMenu(false);
    setShowCalendarAdd(true);
    setTimeout(() => {
      setShowCalendarAdd(false);
      setShowSuccess(true);
      setTimeout(() => {
        setShowSuccess(false);
        setShowCalendarView(true);
      }, 1500);
    }, 1500);
  };

  const Message = ({ message, isSelected }) => (
    <div className={`flex ${message.sender === 'me' ? 'justify-end' : 'justify-start'} mb-4`}>
      <div className={`max-w-[70%] rounded-2xl px-4 py-2 ${
        message.sender === 'me' 
          ? `${isSelected ? 'bg-blue-200' : 'bg-blue-500'} text-white` 
          : 'bg-gray-100 text-gray-800'
      } ${isSelected ? 'ring-2 ring-blue-400' : ''}`}>
        <p className="text-sm">{message.text}</p>
      </div>
    </div>
  );

  const TypingIndicator = () => (
    <div className="flex justify-start mb-4">
      <div className="bg-gray-100 rounded-2xl px-4 py-2">
        <div className="flex gap-1">
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.2s'}}></div>
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{animationDelay: '0.4s'}}></div>
        </div>
      </div>
    </div>
  );

  const CalendarView = () => (
    <div className="bg-white rounded-2xl shadow-2xl overflow-hidden">
      {/* Calendar Header */}
      <div className="bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-4 text-white">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <div className="flex gap-2">
              <div className="w-3 h-3 rounded-full bg-red-400"></div>
              <div className="w-3 h-3 rounded-full bg-yellow-400"></div>
              <div className="w-3 h-3 rounded-full bg-green-400"></div>
            </div>
            <span className="ml-4 font-medium">Calendar</span>
          </div>
          <button onClick={() => setShowCalendarView(false)} className="hover:bg-white/10 p-1 rounded">
            <X size={16} />
          </button>
        </div>
        <div className="flex justify-between items-center">
          <div>
            <h2 className="text-2xl font-bold">January 2025</h2>
            <p className="text-blue-100">Tuesday, 16th</p>
          </div>
          <div className="flex gap-2">
            <button className="p-2 hover:bg-white/10 rounded-lg">
              <ChevronLeft size={20} />
            </button>
            <button className="p-2 hover:bg-white/10 rounded-lg">
              <ChevronRight size={20} />
            </button>
          </div>
        </div>
      </div>

      <div className="flex h-[500px]">
        {/* Sidebar */}
        <div className="w-80 border-r border-gray-100 bg-gray-50/50">
          <div className="p-4">
            <div className="flex items-center justify-between mb-4">
              <span className="text-sm font-medium text-gray-600">UPCOMING</span>
              <button className="text-gray-400 hover:text-gray-600">
                <ChevronDown size={16} />
              </button>
            </div>
            <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-100">
              <div className="flex items-center gap-3 mb-3">
                <div className="w-2 h-8 bg-blue-500 rounded-full"></div>
                <div>
                  <h3 className="font-semibold text-gray-900">Product Demo</h3>
                  <p className="text-sm text-gray-500">Today at 3:00 PM</p>
                </div>
              </div>
              <div className="flex gap-2 ml-5">
                <span className="inline-flex items-center px-2.5 py-1.5 bg-blue-50 text-blue-700 text-xs font-medium rounded-lg">
                  <Video size={12} className="mr-1" />
                  Zoom
                </span>
                <span className="px-2.5 py-1.5 bg-blue-50 text-blue-700 text-xs font-medium rounded-lg">
                  15min reminder
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Main Calendar Area */}
        <div className="flex-1 p-6">
          <div className="space-y-6">
            {["Morning", "Afternoon", "Evening"].map((period, index) => (
              <div key={period}>
                <h3 className="text-sm font-medium text-gray-400 mb-4">{period}</h3>
                {period === "Afternoon" ? (
                  <div className="relative pl-12 py-4">
                    <div className="absolute left-0 top-6 text-sm text-gray-400">3:00</div>
                    <div className="bg-gradient-to-r from-blue-50 to-white p-4 rounded-xl border-l-4 border-blue-500 shadow-sm hover:shadow-md transition-shadow duration-200">
                      <div className="flex justify-between items-start mb-3">
                        <div>
                          <h4 className="font-semibold text-gray-900">Product Demo</h4>
                          <p className="text-sm text-gray-600">3:00 PM - 4:00 PM</p>
                        </div>
                        <a href="https://zoom.us/j/123" 
                           className="flex items-center gap-1 text-sm text-blue-600 hover:text-blue-700 hover:underline">
                          <Video size={14} />
                          Join Call
                        </a>
                      </div>
                      <div className="flex gap-2">
                        <span className="inline-flex items-center px-2.5 py-1.5 bg-blue-50 text-blue-700 text-xs font-medium rounded-lg">
                          <Video size={12} className="mr-1" />
                          Zoom Meeting
                        </span>
                        <span className="px-2.5 py-1.5 bg-blue-50 text-blue-700 text-xs font-medium rounded-lg">
                          15min reminder
                        </span>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="pl-12 py-4 text-sm text-gray-400">No events scheduled</div>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <div className={`p-8 bg-gradient-to-br from-blue-50 to-purple-50 min-h-[600px] rounded-xl shadow-lg transition-all duration-1000 ${animate ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'}`}>
      <div className="absolute top-0 left-0 w-32 h-32 bg-blue-100 rounded-full filter blur-3xl opacity-30"></div>
      <div className="absolute bottom-0 right-0 w-32 h-32 bg-purple-100 rounded-full filter blur-3xl opacity-30"></div>
      
      {showCalendarView ? (
        <CalendarView />
      ) : (
        <div className="relative bg-white rounded-2xl shadow-2xl overflow-hidden backdrop-blur-xl bg-opacity-90 border border-gray-100">
          {/* iMessage Header */}
          <div className="bg-gray-100 px-4 py-3 flex items-center justify-between border-b border-gray-200">
            <div className="flex gap-2">
              <div className="w-3 h-3 rounded-full bg-red-400"></div>
              <div className="w-3 h-3 rounded-full bg-yellow-400"></div>
              <div className="w-3 h-3 rounded-full bg-green-400"></div>
            </div>
            <span className="text-sm text-gray-500 font-medium">Messages</span>
            <div className="w-8"></div>
          </div>
          
          {/* Messages Container */}
          <div className="p-6 relative min-h-[400px]">
            <div className="space-y-4">
              {messages.map((msg, idx) => (
                <Message 
                  key={idx} 
                  message={msg} 
                  isSelected={selectedText === msg}
                />
              ))}
              {isTyping && <TypingIndicator />}
            </div>

            {messages.length === conversation.length && !selectedText && (
              <button
                onClick={handleTextSelect}
                className="mt-6 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-all duration-300 transform hover:scale-105 hover:shadow-lg flex items-center gap-2 mx-auto"
              >
                Select Message to Add Event
                <ChevronRight size={16} />
              </button>
            )}
            
            {showMenu && (
              <div className="absolute bottom-24 right-8 transform transition-all duration-300">
                <div className="bg-gray-800 rounded-lg shadow-xl p-1.5 backdrop-blur-lg">
                  <button
                    onClick={handleAddToCalendar}
                    className="flex items-center gap-2 text-white px-4 py-2.5 hover:bg-gray-700 rounded-md transition-colors"
                  >
                    <Calendar size={16} className="text-blue-400" />
                    <span className="whitespace-nowrap">Add to Calendar</span>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
      
      {/* Overlays */}
      {showCalendarAdd && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 backdrop-blur-sm transition-all duration-300">
          <div className="bg-white p-6 rounded-xl shadow-2xl flex items-center gap-4">
            <div className="p-3 bg-blue-50 rounded-full">
              <Clock className="text-blue-600 animate-spin" size={24} />
            </div>
            <span className="text-gray-700 font-medium">Adding to Calendar...</span>
          </div>
        </div>
      )}
      
      {showSuccess && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 backdrop-blur-sm transition-all duration-300">
          <div className="bg-white p-6 rounded-xl shadow-2xl flex items-center gap-4 transform scale-110">
            <div className="p-3 bg-green-50 rounded-full">
              <Check className="text-green-600" size={24} />
            </div>
            <span className="text-gray-700 font-medium">Event Added Successfully!</span>
          </div>
        </div>
      )}
    </div>
  );
}
