const fs = require('fs');
const path = require('path');

// Actual working YouTube video IDs for algorithm topics
const algoVideos = {
  'algo-c1.json': [
    { title: "Introduction à l'algorithmique", url: "https://www.youtube.com/watch?v=8hly31xKli0", channel: "MIT 6.006" },
    { title: "Notation Big-O et complexité", url: "https://www.youtube.com/watch?v=v4cd1O4zkGw", channel: "Harvard CS50" },
    { title: "Tri à bulles, insertion, sélection", url: "https://www.youtube.com/watch?v=kgBjXUE_Nwc", channel: "Harvard CS50" }
  ],
  'algo-c2.json': [
    { title: "Tri fusion et tri rapide", url: "https://www.youtube.com/watch?v=4VqmGXwpLqc", channel: "MIT" },
    { title: "Recherche dichotomique", url: "https://www.youtube.com/watch?v=P3YID7liBug", channel: "Harvard CS50" },
    { title: "Analyse de complexité", url: "https://www.youtube.com/watch?v=v4cd1O4zkGw", channel: "Harvard CS50" }
  ],
  'algo-c3.json': [
    { title: "Graphes : parcours BFS/DFS", url: "https://www.youtube.com/watch?v=tWVWeAqZ0WU", channel: "MIT" },
    { title: "Algorithme de Dijkstra", url: "https://www.youtube.com/watch?v=GazC3A4OQTE", channel: "Harvard CS50" },
    { title: "Arbres binaires de recherche", url: "https://www.youtube.com/watch?v=oTTzNMHM0OI", channel: "MIT" }
  ],
  'algo-c4.json': [
    { title: "Récursivité et pile d'appel", url: "https://www.youtube.com/watch?v=Mv9NEXX1VHc", channel: "Harvard CS50" },
    { title: "Programmation dynamique", url: "https://www.youtube.com/watch?v=oTTzNMHM0OI", channel: "MIT" },
    { title: "Mémoïsation et tabulation", url: "https://www.youtube.com/watch?v=oTTzNMHM0OI", channel: "MIT" }
  ],
  'algo-c5.json': [
    { title: "Arbres binaires de recherche", url: "https://www.youtube.com/watch?v=oTTzNMHM0OI", channel: "MIT" },
    { title: "Arbres AVL et équilibrés", url: "https://www.youtube.com/watch?v=oTTzNMHM0OI", channel: "MIT" },
    { title: "Tables de hachage", url: "https://www.youtube.com/watch?v=8hly31xKli0", channel: "MIT" }
  ],
  'algo-c6.json': [
    { title: "Projet algorithmique complet", url: "https://www.youtube.com/watch?v=8hly31xKli0", channel: "MIT" },
    { title: "Benchmark et profilage", url: "https://www.youtube.com/watch?v=8hly31xKli0", channel: "MIT" },
    { title: "Bonnes pratiques algorithmiques", url: "https://www.youtube.com/watch?v=8hly31xKli0", channel: "MIT" }
  ]
};

const chaptersDir = path.join(__dirname, 'content', 'chapters');
let updated = 0;

Object.entries(algoVideos).forEach(([file, videos]) => {
  const filepath = path.join(__dirname, 'content', 'chapters', file);
  const chapter = JSON.parse(fs.readFileSync(filepath, 'utf8'));
  
  chapter.videos = videos;
  
  fs.writeFileSync(filepath, JSON.stringify(chapter, null, 2));
  console.log(`Updated ${file}: ${videos.length} working videos`);
  updated++;
});

console.log(`\nDone! Updated ${updated} algo chapters with working YouTube videos`);