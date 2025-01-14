/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0', transform: 'translateY(10px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' }
        }
      },
      animation: {
        'spin-slow': 'spin 2s linear infinite',
        fadeIn: 'fadeIn 0.5s ease-out forwards'
      }
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
