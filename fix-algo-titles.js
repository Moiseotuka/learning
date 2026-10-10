const fs = require('fs');

const fixes = {
  'algo-c1.json': { 
    title: "Introduction a l'algorithmique", 
    summary: 'Variables, types, lecture/ecriture, tests' 
  },
  'algo-c2.json': { 
    title: 'Structures de controle : boucles', 
    summary: 'Boucles while/for, tableaux, tableaux multidimensionnels' 
  },
  'algo-c3.json': { 
    title: 'Fonctions et premiers tris', 
    summary: 'Fonctions personnalisees, tri a bulles' 
  },
  'algo-c4.json': { 
    title: 'Tris efficaces et recherche', 
    summary: 'Tri fusion, tri rapide, recherche dichotomique' 
  },
  'algo-c5.json': { 
    title: 'Recursivite et structures de donnees', 
    summary: 'Recursivite, arbres, tables de hachage' 
  },
  'algo-c6.json': { 
    title: 'Graphes et projet final', 
    summary: 'Parcours de graphes, Dijkstra, projet final' 
  }
};

Object.entries(fixes).forEach(([file, fix]) => {
  const filepath = 'content/chapters/' + file;
  const c = JSON.parse(fs.readFileSync('content/chapters/' + file, 'utf8'));
  c.title = fix.title;
  c.summary = fix.summary;
  fs.writeFileSync('content/chapters/' + file, JSON.stringify(c, null, 2));
  console.log('Fixed ' + file + ': ' + fix.title);
});
console.log('Done!');