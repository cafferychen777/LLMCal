import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { Calendar, Clock, Check, ChevronRight, X, Video, ChevronLeft, ChevronDown, Settings, Cpu } from 'lucide-react';

interface Message {
  sender: string;
  text: string;
}

interface ModelOption {
  id: string;
  name: string;
  description: string;
  pricing: string;
  recommended?: boolean;
}

export default function LLMCalDemo() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [isTyping, setIsTyping] = useState(false);
  const [selectedText, setSelectedText] = useState<Message | null>(null);
  const [showMenu, setShowMenu] = useState(false);
  const [showCalendarAdd, setShowCalendarAdd] = useState(false);
  const [showSuccess, setShowSuccess] = useState(false);
  const [showCalendarView, setShowCalendarView] = useState(false);
  const [animate, setAnimate] = useState(false);
  const [darkMode, setDarkMode] = useState(false);
  const [showSettings, setShowSettings] = useState(false);
  const [selectedModel, setSelectedModel] = useState('claude-sonnet-4-20250514');
  const initialized = useRef(false);
  const timeoutRefs = useRef<NodeJS.Timeout[]>([]);

  // Available Claude models
  const modelOptions: ModelOption[] = useMemo(() => [
    {
      id: 'claude-sonnet-4-20250514',
      name: 'Claude Sonnet 4',
      description: 'Best performance with advanced reasoning and coding',
      pricing: '$3/$15 per million tokens',
      recommended: true
    },
    {
      id: 'claude-3-7-sonnet-20250206',
      name: 'Claude 3.7 Sonnet',
      description: 'Extended thinking capabilities with hybrid reasoning',
      pricing: '$3/$15 per million tokens'
    },
    {
      id: 'claude-3-5-sonnet-20241022',
      name: 'Claude 3.5 Sonnet',
      description: 'Balanced performance for most use cases',
      pricing: '$3/$15 per million tokens'
    },
    {
      id: 'claude-3-5-haiku-20241022',
      name: 'Claude 3.5 Haiku',
      description: 'Fast and economical for simple tasks',
      pricing: '$0.25/$1.25 per million tokens'
    }
  ], []);

  // Memoize conversation to prevent re-creation
  const conversation: Message[] = useMemo(() => [
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
  ], []);

  // Cleanup timeouts on unmount
  useEffect(() => {
    return () => {
      timeoutRefs.current.forEach(clearTimeout);
    };
  }, []);

  useEffect(() => {
    if (initialized.current) return;
    initialized.current = true;
    
    // Use requestAnimationFrame for smooth initial animation
    requestAnimationFrame(() => {
      setAnimate(true);
      conversation.forEach((msg, index) => {
        const typingTimeout = setTimeout(() => {
          setIsTyping(true);
          const messageTimeout = setTimeout(() => {
            setIsTyping(false);
            setMessages(prev => [...prev, msg]);
          }, 800); // Reduced from 1000ms for better performance
          timeoutRefs.current.push(messageTimeout);
        }, index * 1500); // Reduced from 2000ms
        timeoutRefs.current.push(typingTimeout);
      });
    });
  }, [conversation]);

  const messageAnimation = useMemo(() => animate ? 'animate-fadeIn' : '', [animate]);

  // Memoized handlers to prevent re-renders
  const handleTextSelect = useCallback(() => {
    setSelectedText(conversation[3]);
    const timeout = setTimeout(() => setShowMenu(true), 300); // Reduced delay
    timeoutRefs.current.push(timeout);
  }, [conversation]);

  const handleAddToCalendar = useCallback(() => {
    setShowMenu(false);
    setShowCalendarAdd(true);
    const timeout1 = setTimeout(() => {
      setShowCalendarAdd(false);
      setShowSuccess(true);
      const timeout2 = setTimeout(() => {
        setShowSuccess(false);
        setShowCalendarView(true);
      }, 1200); // Reduced from 1500ms
      timeoutRefs.current.push(timeout2);
    }, 1200); // Reduced from 1500ms
    timeoutRefs.current.push(timeout1);
  }, []);

  const handleToggleDarkMode = useCallback(() => {
    setDarkMode(prev => !prev);
  }, []);

  const handleCloseCalendarView = useCallback(() => {
    setShowCalendarView(false);
  }, []);

  // Memoized Message component to prevent unnecessary re-renders
  const Message = useCallback(({ message, isSelected }: { message: Message; isSelected: boolean }) => (
    <div className={`flex ${message.sender === 'me' ? 'justify-end' : 'justify-start'} mb-4 items-end transition-all duration-300 ${messageAnimation}`}>
      {message.sender !== 'me' && (
        <div className="flex flex-col items-center mr-2">
          <div className={`w-8 h-8 rounded-full ${darkMode ? 'bg-gray-600' : 'bg-gray-300'} flex items-center justify-center mb-1`}>
            <span className="text-white text-sm">A</span>
          </div>
          <span className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>Alex</span>
        </div>
      )}
      <div className={`max-w-[70%] rounded-2xl px-4 py-2 transition-all duration-200 ${
        message.sender === 'me' 
          ? `${isSelected 
              ? (darkMode ? 'bg-blue-600' : 'bg-blue-200') 
              : 'bg-blue-500'} text-white` 
          : darkMode 
            ? 'bg-gray-700 text-gray-200' 
            : 'bg-gray-100 text-gray-800'
      } ${isSelected ? 'ring-2 ring-blue-400 transform scale-105' : ''}`}>
        <p className="text-sm">{message.text}</p>
      </div>
      {message.sender === 'me' && (
        <div className="flex flex-col items-center ml-2">
          <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center mb-1">
            <span className="text-white text-sm">M</span>
          </div>
          <span className={`text-xs ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>Me</span>
        </div>
      )}
    </div>
  ), [messageAnimation, darkMode]);

  // Optimized TypingIndicator with memoization
  const TypingIndicator = useMemo(() => (
    <div className="flex justify-start mb-4">
      <div className={`${darkMode ? 'bg-gray-700' : 'bg-gray-100'} rounded-2xl px-4 py-2 transition-colors duration-200`}>
        <div className="flex gap-1">
          <div className={`w-2 h-2 ${darkMode ? 'bg-gray-400' : 'bg-gray-400'} rounded-full animate-bounce`}></div>
          <div className={`w-2 h-2 ${darkMode ? 'bg-gray-400' : 'bg-gray-400'} rounded-full animate-bounce`} style={{animationDelay: '0.2s'}}></div>
          <div className={`w-2 h-2 ${darkMode ? 'bg-gray-400' : 'bg-gray-400'} rounded-full animate-bounce`} style={{animationDelay: '0.4s'}}></div>
        </div>
      </div>
    </div>
  ), [darkMode]);

  const ModelSelectionModal = () => (
    <div className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm flex items-center justify-center z-50 transition-all duration-300">
      <div className={`rounded-2xl shadow-2xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-hidden ${darkMode ? 'bg-gray-800' : 'bg-white'}`}>
        {/* Header */}
        <div className={`px-6 py-4 border-b ${darkMode ? 'border-gray-700' : 'border-gray-200'}`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 rounded-lg">
                <Cpu className="text-blue-600" size={20} />
              </div>
              <div>
                <h2 className={`text-lg font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>
                  Claude Model Selection
                </h2>
                <p className={`text-sm ${darkMode ? 'text-gray-300' : 'text-gray-500'}`}>
                  Choose the AI model that best fits your needs
                </p>
              </div>
            </div>
            <button 
              onClick={() => setShowSettings(false)} 
              className={`p-2 rounded-lg transition-colors ${darkMode ? 'hover:bg-gray-700' : 'hover:bg-gray-100'}`}
            >
              <X size={20} className={darkMode ? 'text-gray-400' : 'text-gray-500'} />
            </button>
          </div>
        </div>

        {/* Model Options */}
        <div className="p-6 max-h-96 overflow-y-auto">
          <div className="space-y-4">
            {modelOptions.map((model) => (
              <div 
                key={model.id}
                className={`relative rounded-xl border-2 cursor-pointer transition-all duration-200 ${
                  selectedModel === model.id 
                    ? 'border-blue-500 bg-blue-50' + (darkMode ? ' !bg-blue-900/20 !border-blue-400' : '')
                    : darkMode ? 'border-gray-600 bg-gray-700 hover:border-gray-500' : 'border-gray-200 hover:border-gray-300'
                }`}
                onClick={() => setSelectedModel(model.id)}
              >
                <div className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-start gap-3">
                      <div className={`mt-1 w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                        selectedModel === model.id 
                          ? 'border-blue-500 bg-blue-500' 
                          : darkMode ? 'border-gray-400' : 'border-gray-300'
                      }`}>
                        {selectedModel === model.id && (
                          <div className="w-2 h-2 bg-white rounded-full"></div>
                        )}
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                          <h3 className={`font-semibold ${darkMode ? 'text-white' : 'text-gray-900'}`}>
                            {model.name}
                          </h3>
                          {model.recommended && (
                            <span className="px-2 py-1 bg-green-100 text-green-800 text-xs font-medium rounded-full">
                              Recommended
                            </span>
                          )}
                        </div>
                        <p className={`text-sm mb-2 ${darkMode ? 'text-gray-300' : 'text-gray-600'}`}>
                          {model.description}
                        </p>
                        <div className={`text-sm font-mono ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
                          💰 {model.pricing}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Footer */}
        <div className={`px-6 py-4 border-t ${darkMode ? 'border-gray-700' : 'border-gray-200'}`}>
          <div className="flex items-center justify-between">
            <p className={`text-sm ${darkMode ? 'text-gray-400' : 'text-gray-500'}`}>
              Current selection: <span className="font-medium">{modelOptions.find(m => m.id === selectedModel)?.name}</span>
            </p>
            <button 
              onClick={() => setShowSettings(false)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Apply Changes
            </button>
          </div>
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
            {["Morning", "Afternoon", "Evening"].map((period) => (
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
    <div className={`p-4 sm:p-6 lg:p-8 ${
      darkMode 
        ? 'bg-gradient-to-br from-gray-900 to-gray-800' 
        : 'bg-gradient-to-br from-blue-50 to-purple-50'
    } min-h-[600px] rounded-xl shadow-lg transition-all duration-1000 ${
      animate ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-4'
    } relative overflow-hidden`}>
      {/* Background decoration */}
      <div className={`absolute top-0 left-0 w-32 h-32 ${
        darkMode ? 'bg-blue-900' : 'bg-blue-100'
      } rounded-full filter blur-3xl opacity-30`}></div>
      <div className={`absolute bottom-0 right-0 w-32 h-32 ${
        darkMode ? 'bg-purple-900' : 'bg-purple-100'
      } rounded-full filter blur-3xl opacity-30`}></div>
      
      {/* Top controls */}
      <div className="absolute top-4 right-4 flex gap-2 z-10">
        {/* Model selection button */}
        <button
          onClick={() => setShowSettings(true)}
          className={`p-2 rounded-full ${
            darkMode 
              ? 'bg-gray-700 text-gray-300 hover:bg-gray-600' 
              : 'bg-white text-gray-700 hover:bg-gray-100'
          } transition-all duration-200 shadow-lg`}
          aria-label="Model Settings"
          title="Choose Claude Model"
        >
          <Settings size={16} />
        </button>
        
        {/* Dark mode toggle */}
        <button
          onClick={handleToggleDarkMode}
          className={`p-2 rounded-full ${
            darkMode 
              ? 'bg-gray-700 text-yellow-400 hover:bg-gray-600' 
              : 'bg-white text-gray-700 hover:bg-gray-100'
          } transition-all duration-200 shadow-lg`}
          aria-label="Toggle dark mode"
        >
          {darkMode ? '☀️' : '🌙'}
        </button>
      </div>
      
      {showCalendarView ? (
        <CalendarView />
      ) : (
        <div className={`relative ${
          darkMode 
            ? 'bg-gray-800 border-gray-700' 
            : 'bg-white border-gray-100'
        } rounded-2xl shadow-2xl overflow-hidden backdrop-blur-xl bg-opacity-90 border transition-colors duration-300`}>
          {/* iMessage Header */}
          <div className={`${
            darkMode ? 'bg-gray-700 border-gray-600' : 'bg-gray-100 border-gray-200'
          } px-4 py-3 flex items-center justify-between border-b transition-colors duration-200`}>
            <div className="flex gap-2">
              <div className="w-3 h-3 rounded-full bg-red-400"></div>
              <div className="w-3 h-3 rounded-full bg-yellow-400"></div>
              <div className="w-3 h-3 rounded-full bg-green-400"></div>
            </div>
            <span className={`text-sm ${darkMode ? 'text-gray-300' : 'text-gray-500'} font-medium`}>
              Messages
            </span>
            <div className="w-8"></div>
          </div>
          
          {/* Messages Container */}
          <div className="p-4 sm:p-6 pb-20 sm:pb-24 relative min-h-[400px]">
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
              <div className="absolute bottom-4 sm:bottom-6 left-1/2 transform -translate-x-1/2 flex flex-col sm:flex-row gap-2">
                <button
                  onClick={handleTextSelect}
                  className="px-4 sm:px-6 py-2 sm:py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-all duration-300 transform hover:scale-105 hover:shadow-lg flex items-center justify-center gap-2 text-sm sm:text-base whitespace-nowrap"
                >
                  <span className="hidden sm:inline">Select Message to Add Event</span>
                  <span className="sm:hidden">Add Event</span>
                  <ChevronRight size={16} />
                </button>
                
                {/* Additional interactive examples */}
                <div className="flex gap-2">
                  <button
                    onClick={() => {
                      setMessages([]);
                      setSelectedText(null);
                      setShowMenu(false);
                      initialized.current = false;
                      requestAnimationFrame(() => {
                        initialized.current = true;
                        setAnimate(true);
                        conversation.forEach((msg, index) => {
                          const timeout = setTimeout(() => {
                            setIsTyping(true);
                            const msgTimeout = setTimeout(() => {
                              setIsTyping(false);
                              setMessages(prev => [...prev, msg]);
                            }, 800);
                            timeoutRefs.current.push(msgTimeout);
                          }, index * 1500);
                          timeoutRefs.current.push(timeout);
                        });
                      });
                    }}
                    className={`px-3 py-2 ${
                      darkMode 
                        ? 'bg-gray-600 hover:bg-gray-500 text-gray-200' 
                        : 'bg-gray-200 hover:bg-gray-300 text-gray-700'
                    } rounded-lg transition-all duration-200 text-sm`}
                    aria-label="Reset demo"
                  >
                    🔄
                  </button>
                </div>
              </div>
            )}
            
            {showMenu && (
              <div className="absolute bottom-4 sm:bottom-6 right-4 sm:right-8 transform transition-all duration-300">
                <div className={`${
                  darkMode ? 'bg-gray-900' : 'bg-gray-800'
                } rounded-lg shadow-xl p-1.5 backdrop-blur-lg border border-gray-600`}>
                  <button
                    onClick={handleAddToCalendar}
                    className="flex items-center gap-2 text-white px-3 sm:px-4 py-2 sm:py-2.5 hover:bg-gray-700 rounded-md transition-colors text-sm sm:text-base"
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
      
      {/* Optimized Overlays */}
      {showCalendarAdd && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 backdrop-blur-sm transition-all duration-300 z-50">
          <div className={`${
            darkMode ? 'bg-gray-800 text-gray-200' : 'bg-white text-gray-700'
          } p-4 sm:p-6 rounded-xl shadow-2xl flex items-center gap-3 sm:gap-4 mx-4 transform transition-transform duration-200`}>
            <div className={`p-2 sm:p-3 ${
              darkMode ? 'bg-blue-900' : 'bg-blue-50'
            } rounded-full`}>
              <Clock className="text-blue-600 animate-spin" size={20} />
            </div>
            <span className="font-medium text-sm sm:text-base">Adding to Calendar...</span>
          </div>
        </div>
      )}
      
      {showSuccess && (
        <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-30 backdrop-blur-sm transition-all duration-300 z-50">
          <div className={`${
            darkMode ? 'bg-gray-800 text-gray-200' : 'bg-white text-gray-700'
          } p-4 sm:p-6 rounded-xl shadow-2xl flex items-center gap-3 sm:gap-4 mx-4 transform scale-110 transition-all duration-200`}>
            <div className={`p-2 sm:p-3 ${
              darkMode ? 'bg-green-900' : 'bg-green-50'
            } rounded-full`}>
              <Check className="text-green-600" size={20} />
            </div>
            <span className="font-medium text-sm sm:text-base">Event Added Successfully!</span>
          </div>
        </div>
      )}

      {/* Model Selection Modal */}
      {showSettings && <ModelSelectionModal />}
    </div>
  );
}
