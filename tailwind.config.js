/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/**/*.{ts,tsx,js,jsx}",
    "./src/app/**/*.{ts,tsx,js,jsx}",
    "./src/components/**/*.{ts,tsx,js,jsx}",
    "./public/**/*.{html,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        electric: "#2563eb",
        "electric-strong": "#1d4ed8",
        vivid: "#0e7490",
        elevated: "#ffffff",
        hairline: "rgba(10, 16, 32, 0.1)",
        glow: "rgba(37, 99, 235, 0.35)",
      },
      fontFamily: {
        inter: ["Inter", "system-ui", "-apple-system", "sans-serif"],
      },
    },
  },
  plugins: [],
}