const fs = require('fs');

const algoFiles = [
  'algo-c1.txt', 'algo-c2.txt', 'algo-c3.txt', 
  'algo-c4.txt', 'algo-c5.txt', 'algo-c6.txt'
];

algoFiles.forEach(file => {
  const filepath = 'content/lessons/' + file;
  let content = fs.readFileSync(filepath, 'utf8');
  
  // Find and remove the video section
  const startMarker = '## Ressources video recommandees';
  const idx = content.indexOf(startMarker);
  if (idx === -1) {
    console.log(file + ': no video section found');
    return;
  }
  
  // Find end of section (next ## or end of file)
  const sectionStart = content.indexOf('\n', content.indexOf(startMarker));
  let sectionEnd = content.indexOf('\n## ', sectionStart + 1);
  if (sectionEnd === -1) sectionEnd = content.length;
  
  const before = content.substring(0, sectionStart);
  const after = content.substring(sectionEnd);
  
  content = before + after;
  fs.writeFileSync(filepath, content, 'utf8');
  console.log('Removed video section from ' + file);
});

console.log('Done!');