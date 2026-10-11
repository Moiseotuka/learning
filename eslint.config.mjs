import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Scope linting to the actual application code and ignore temp/generated files.
  globalIgnores([
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
    ".tmp-cert/**",
    "scripts/**",
    "prototype_citizensynth/**",
    "certificat/**",
    "content/**",
    "figures_memoire/**",
    "**/*.js",
    "**/*.mjs",
    "**/*.cjs",
    "*.js",
    "*.mjs",
    "*.cjs",
  ]),
]);

export default eslintConfig;
