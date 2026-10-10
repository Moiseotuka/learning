const fs = require('fs');
var c = JSON.parse(fs.readFileSync('content/chapters/algo-c1.json', 'utf8'));
console.log('lecon: ' + c.lecon);
console.log('concepts: ' + c.concepts.join(', '));