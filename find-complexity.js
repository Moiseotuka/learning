const fs = require('fs');
const files = fs.readdirSync('content/lessons').filter(f => f.startsWith('algo'));
files.forEach(f => {
  const c = fs.readFileSync('content/lessons/' + f, 'utf8');
  const lines = c.split('\n');
  lines.forEach((l, i) => {
    if (l.includes('Complexit')) {
      console.log(f + ' L' + (i+1) + ': ' + l.substring(0, 100));
    }
  });
});