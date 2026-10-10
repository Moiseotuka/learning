const fs = require('fs');

const algoVideos = {
  'algo-c1.txt': [
    '[Grafikart — Structures de données en JavaScript](https://www.youtube.com/@grafikart/search?query=structures%20de%20donn%C3%A9es%20javascript)',
    '[Grafikart — Algorithmes de tri en JavaScript](https://www.youtube.com/@grafikart/search?query=tri%20javascript)',
    '[Grafikart — Complexité algorithmique](https://www.youtube.com/@grafikart/search?query=complexit%C3%A9%20algorithmique)'
  ],
  'algo-c2.txt': [
    '[Grafikart — Tableaux et listes en JavaScript](https://www.youtube.com/@grafikart/search?query=tableaux%20listes%20javascript)',
    '[Grafikart — Tri à bulles, insertion, sélection](https://www.youtube.com/@grafikart/search?query=tri%20bulles%20insertion%20selection)',
    '[Grafikart — Complexité temporelle et spatiale](https://www.youtube.com/@grafikart/search?query=complexit%C3%A9%20temporelle%20spatiale)'
  ],
  'algo-c3.txt': [
    '[Grafikart — Recherche dichotomique en JavaScript](https://www.youtube.com/@grafikart/search?query=recherche%20dichotomique%20javascript)',
    '[Grafikart — Tri fusion et tri rapide](https://www.youtube.com/@grafikart/search?query=tri%20fusion%20rapide%20javascript)',
    '[Grafikart — Récursion et pile d\'appel](https://www.youtube.com/@grafikart/search?query=recursion%20javascript)'
  ],
  'algo-c4.txt': [
    '[Grafikart — Graphes : représentation et parcours](https://www.youtube.com/@grafikart/search?query=graphes%20parcours%20javascript)',
    '[Grafikart — Algorithme de Dijkstra en JavaScript](https://www.youtube.com/@grafikart/search?query=dijkstra%20javascript)',
    '[Grafikart — Arbres binaires de recherche](https://www.youtube.com/@grafikart/search?query=arbres%20binaires%20recherche)'
  ],
  'algo-c5.txt': [
    '[Grafikart — Récursivité en JavaScript](https://www.youtube.com/@grafikart/search?query=recursivit%C3%A9%20javascript)',
    '[Grafikart — Programmation dynamique](https://www.youtube.com/@grafikart/search?query=programmation%20dynamique%20javascript)',
    '[Grafikart — Mémoïsation et tabulation](https://www.youtube.com/@grafikart/search?query=m%C3%A9mo%C3%AFsation%20tabulation)'
  ],
  'algo-c6.txt': [
    '[Grafikart — Projet algorithmique complet](https://www.youtube.com/@grafikart/search?query=projet%20algorithmique%20javascript)',
    '[Grafikart — Benchmark et profilage JavaScript](https://www.youtube.com/@grafikart/search?query=benchmark%20profilage%20javascript)',
    '[Grafikart — Bonnes pratiques algorithmiques](https://www.youtube.com/@grafikart/search?query=bonnes%20pratiques%20algorithmiques)'
  ]
};

Object.entries(algoVideos).forEach(([file, videos]) => {
  const filepath = 'content/lessons/' + file;
  let content = fs.readFileSync(filepath, 'utf8');
  
  // Find and replace the existing video section
  const startMarker = '## Ressources video recommandees';
  const idx = content.indexOf(startMarker);
  if (idx === -1) {
    console.log(file + ': video section not found');
    return;
  }
  
  // Find end of section (next ## or end of file)
  const sectionStart = content.indexOf('\n', content.indexOf(startMarker));
  let sectionEnd = content.indexOf('\n## ', sectionStart + 1);
  if (sectionEnd === -1) sectionEnd = content.length;
  
  const before = content.substring(0, sectionStart + 1);
  const after = content.substring(sectionEnd);
  
  const videoSection = '\n\n' + videos.map(v => '- ' + v).join('\n') + '\n';
  content = before + videoSection + after;
  
  fs.writeFileSync(filepath, content, 'utf8');
  console.log('Updated ' + file);
});
console.log('Done!');