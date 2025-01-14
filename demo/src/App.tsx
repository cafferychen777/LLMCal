import LLMCalDemo from './llmcal-demo'
import './App.css'

function App() {
  return (
    <div className="min-h-screen bg-gray-100 flex flex-col items-center justify-center p-4">
      <div className="w-full max-w-5xl">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-4">LLMCal Demo</h1>
          <p className="text-lg text-gray-600">
            Experience how LLMCal converts text into calendar events using AI
          </p>
        </div>
        <LLMCalDemo />
        <div className="mt-8 text-center text-gray-500">
          <p>
            Made with ❤️ by{' '}
            <a 
              href="https://github.com/cafferychen777" 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-blue-600 hover:underline"
            >
              Caffery
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}

export default App
