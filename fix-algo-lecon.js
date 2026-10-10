const fs = require('fs');
var c = JSON.parse(fs.readFileSync('content/chapters/algo-c1.json', 'utf8'));
c.lecon = 'algo-bases.txt';
fs.writeFileSync('content/chapters/algo-c1.json', JSON.stringify(c, null, 2));
console.log('Updated algo-c1.json: lecon now points to algo-bases.txt');