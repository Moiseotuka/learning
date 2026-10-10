const fs = require('fs');
var c = JSON.parse(fs.readFileSync('content/chapters/algo-c1.json', 'utf8'));
console.log('exercise:', c.exercise.substring(0, 120));
console.log('starter_code:', c.starter_code ? c.starter_code.substring(0, 80) : 'none');
console.log('solution_code:', c.solution_code ? c.solution_code.substring(0, 80) : 'none');
console.log('code_language:', c.code_language);