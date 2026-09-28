/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class',
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        'primary': '#E53935',
        'on-primary': '#ffffff',
        'primary-container': '#ff544c',
        'on-primary-container': '#ffffff',
        'secondary': '#ab8985',
        'on-secondary': '#ffffff',
        'surface': '#131313',
        'on-surface': '#ffffff',
        'surface-variant': '#1e1e1e',
        'on-surface-variant': '#b3b3b3',
        'surface-container-lowest': '#0a0a0a',
        'surface-container-low': '#111111',
        'surface-container': '#1a1a1a',
        'surface-container-high': '#262626',
        'surface-container-highest': '#333333',
        'outline': '#4d4d4d',
        'error': '#ffb4ab',
        'on-error': '#690005',
        'error-container': '#93000a',
        'on-error-container': '#ffdad6',
        'tertiary': '#72d4ef',
        'on-tertiary': '#003641',
        'tertiary-container': '#319db6',
        'on-tertiary-container': '#002e39',
        'background': '#0a0a0a',
        'on-background': '#ffffff',
      },
      borderRadius: {
        'DEFAULT': '0.25rem',
        'lg': '0.5rem',
        'xl': '0.75rem',
        'full': '9999px'
      },
      spacing: {
        'space-xxs': '0.25rem',
        'space-md': '1.5rem',
        'space-lg': '2rem',
        'space-xl': '2.5rem',
        'space-xs': '0.5rem',
        'space-xxl': '3rem',
        'space-sm': '1rem'
      },
      fontFamily: {
        'body-md': ['Plus Jakarta Sans'],
        'display-mobile': ['Plus Jakarta Sans'],
        'headline-md': ['Plus Jakarta Sans'],
        'display': ['Plus Jakarta Sans'],
        'headline-lg': ['Plus Jakarta Sans'],
        'headline-sm': ['Plus Jakarta Sans'],
        'headline-lg-mobile': ['Plus Jakarta Sans'],
        'label-sm': ['Plus Jakarta Sans'],
        'label-lg': ['Plus Jakarta Sans'],
        'body-lg': ['Plus Jakarta Sans'],
        'body-sm': ['Plus Jakarta Sans'],
        'label-md': ['Plus Jakarta Sans']
      },
      fontSize: {
        'body-md': ['14px', { lineHeight: '20px', letterSpacing: '0.01em', fontWeight: '400' }],
        'display-mobile': ['32px', { lineHeight: '38px', letterSpacing: '-0.02em', fontWeight: '700' }],
        'headline-md': ['20px', { lineHeight: '26px', letterSpacing: '-0.01em', fontWeight: '600' }],
        'display': ['40px', { lineHeight: '48px', letterSpacing: '-0.02em', fontWeight: '700' }],
        'headline-lg': ['28px', { lineHeight: '36px', letterSpacing: '-0.015em', fontWeight: '700' }],
        'headline-sm': ['16px', { lineHeight: '22px', letterSpacing: '0em', fontWeight: '600' }],
        'headline-lg-mobile': ['24px', { lineHeight: '30px', letterSpacing: '-0.015em', fontWeight: '700' }],
        'label-sm': ['10px', { lineHeight: '12px', letterSpacing: '0.04em', fontWeight: '700' }],
        'label-lg': ['14px', { lineHeight: '18px', letterSpacing: '0.02em', fontWeight: '600' }],
        'body-lg': ['16px', { lineHeight: '24px', letterSpacing: '0em', fontWeight: '400' }],
        'body-sm': ['12px', { lineHeight: '16px', letterSpacing: '0.01em', fontWeight: '400' }],
        'label-md': ['12px', { lineHeight: '16px', letterSpacing: '0.02em', fontWeight: '600' }]
      }
    },
  },
  plugins: [],
}
