const fs = require('fs');
const files = fs.readdirSync('content/lessons').filter(f => f.startsWith('algo')).sort();
files.forEach(f => {
  const c = fs.readFileSync('content/lessons/' + f, 'utf8');
  const lines = c.split('\n');
  // Find first ## section
  let firstSection = '';
  let firstSectionLine = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].match(/^##\s+(.*)$/)) {
      firstSection = lines[i].match(/^##\s+(.*)$/)[1].trim();
      firstSectionLine = i + 1;
      break;
    }
  }
  console.log(f + ' -> first section: "' + firstSection + '" at line ' + firstSectionLine);
});