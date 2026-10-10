const https = require('https');
const fs = require('fs');

const scriptPath = 'scripts/apply-chapter-extras.mjs';
let script = fs.readFileSync(scriptPath, 'utf8');

// Find and replace the patch body to include videos
const oldPatch = `  const patch = await rest(\`chapters?id=eq.\${id}\`, {
    method: "PATCH",
    body: JSON.stringify({
      exercise: extras.exercise,
      resources: extras.resources,
      code_language: extras.code_language ?? "",
      starter_code: extras.starter_code ?? "",
      solution_code: extras.solution_code ?? "",
    }),
  });`;

const newPatch = `  const patch = await rest(\`chapters?id=eq.\${id}\`, {
    method: "PATCH",
    body: JSON.stringify({
      exercise: extras.exercise,
      resources: extras.resources,
      code_language: extras.code_language ?? "",
      starter_code: extras.starter_code ?? "",
      solution_code: extras.solution_code ?? "",
      videos: extras.videos ?? [],
    }),
  });`;

if (script.includes(oldPatch)) {
  script = script.replace(oldPatch, newPatch);
  fs.writeFileSync(scriptPath, script, 'utf8');
  console.log('Updated apply-chapter-extras.mjs to include videos field');
} else {
  console.log('Could not find patch section to replace');
  // Try alternative pattern
  const altOld = 'exercise: extras.exercise,';
  const altNew = 'exercise: extras.exercise,\n      videos: extras.videos ?? [],';
  if (script.includes(altOld)) {
    script = script.replace(altOld, altNew);
    fs.writeFileSync(scriptPath, script, 'utf8');
    console.log('Updated with alternative pattern');
  }
}