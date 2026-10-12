const config = {
  plugins: {
    "@tailwindcss/postcss": {},
    // Les WebViews d'Android antérieurs à Chrome 99 ignorent @layer et
    // abandonnent alors la totalité des règles qu'ils contiennent : sans cette
    // étape, la plateforme s'affiche sans aucun style sur un vieux téléphone.
    "@csstools/postcss-cascade-layers": {},
  },
};

export default config;
