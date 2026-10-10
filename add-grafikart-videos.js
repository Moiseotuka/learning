const fs = require('fs');
const path = require('path');

// Mapping of pathway prefixes to relevant grafikart search queries
const grafikartVideos = {
  // Algorithmique - not many grafikart videos on pure algo, but some on data structures in JS/PHP
  algo: [
    { label: "Grafikart — Structures de données en JavaScript", url: "https://www.youtube.com/@grafikart/search?query=structures%20de%20donn%C3%A9es%20javascript" },
    { label: "Grafikart — Algorithmes de tri en JavaScript", url: "https://www.youtube.com/@grafikart/search?query=tri%20javascript" },
    { label: "Grafikart — Complexité algorithmique", url: "https://www.youtube.com/@grafikart/search?query=complexit%C3%A9%20algorithmique" }
  ],
  // Arduino/ESP32 - limited grafikart content, maybe some IoT
  ard: [
    { label: "Grafikart — Arduino et ESP32", url: "https://www.youtube.com/@grafikart/search?query=arduino%20esp32" },
    { label: "Grafikart — IoT et objets connectés", url: "https://www.youtube.com/@grafikart/search?query=iot%20objets%20connect%C3%A9s" }
  ],
  // Cybersécurité - grafikart has some security videos
  cyb: [
    { label: "Grafikart — Sécurité web : authentification et JWT", url: "https://www.youtube.com/@grafikart/search?query=s%C3%A9curit%C3%A9%20web%20jwt" },
    { label: "Grafikart — Protection CSRF, XSS, injection SQL", url: "https://www.youtube.com/@grafikart/search?query=csrf%20xss%20injection%20sql" },
    { label: "Grafikart — HTTPS, certificats SSL/TLS", url: "https://www.youtube.com/@grafikart/search?query=https%20ssl%20tls" }
  ],
  // Bases de données - grafikart has SQL, PostgreSQL, MySQL videos
  db: [
    { label: "Grafikart — PostgreSQL : installation et bases", url: "https://www.youtube.com/@grafikart/search?query=postgresql%20tutoriel" },
    { label: "Grafikart — Modélisation Merise, MLD, MCD", url: "https://www.youtube.com/@grafikart/search?query=merise%20mld%20mcd" },
    { label: "Grafikart — Requêtes SQL avancées", url: "https://www.youtube.com/@grafikart/search?query=sql%20avanc%C3%A9" }
  ],
  // Django - grafikart has Django videos!
  dj: [
    { label: "Grafikart — Django : créer un projet complet", url: "https://www.youtube.com/@grafikart/search?query=django%20tutoriel" },
    { label: "Grafikart — Django ORM : modèles, migrations, requêtes", url: "https://www.youtube.com/@grafikart/search?query=django%20orm" },
    { label: "Grafikart — Django REST Framework", url: "https://www.youtube.com/@grafikart/search?query=django%20rest%20framework" }
  ],
  // DevOps - grafikart has Docker, CI/CD, Linux videos
  do: [
    { label: "Grafikart — Docker : créer et gérer des conteneurs", url: "https://www.youtube.com/@grafikart/search?query=docker%20tutoriel" },
    { label: "Grafikart — CI/CD avec GitHub Actions / GitLab CI", url: "https://www.youtube.com/@grafikart/search?query=ci%20cd%20github%20actions" },
    { label: "Grafikart — Linux : commandes essentielles, SSH, scripts", url: "https://www.youtube.com/@grafikart/search?query=linux%20commandes%20ssh" },
    { label: "Grafikart — Nginx : configuration, reverse proxy, SSL", url: "https://www.youtube.com/@grafikart/search?query=nginx%20configuration" }
  ],
  // IA/Data Science - limited grafikart content, but some Python data videos
  ia: [
    { label: "Grafikart — Python pour la data : pandas, numpy", url: "https://www.youtube.com/@grafikart/search?query=python%20pandas%20numpy" },
    { label: "Grafikart — Visualisation de données avec Python", url: "https://www.youtube.com/@grafikart/search?query=visualisation%20donn%C3%A9es%20python" }
  ],
  // Réseaux - grafikart has some network videos
  net: [
    { label: "Grafikart — Réseau : TCP/IP, DNS, HTTP", url: "https://www.youtube.com/@grafikart/search?query=r%C3%A9seau%20tcp%20ip%20dns" },
    { label: "Grafikart — Configuration réseau Linux", url: "https://www.youtube.com/@grafikart/search?query=r%C3%A9seau%20linux%20configuration" }
  ],
  // Offensive Security - limited grafikart content
  off: [
    { label: "Grafikart — Sécurité offensive : bases", url: "https://www.youtube.com/@grafikart/search?query=s%C3%A9curit%C3%A9%20offensive" },
    { label: "Grafikart — Outils de pentest : Burp Suite, Nmap", url: "https://www.youtube.com/@grafikart/search?query=burp%20suite%20nmap" }
  ],
  // Python - grafikart has many Python videos!
  py: [
    { label: "Grafikart — Python : bases, variables, structures de contrôle", url: "https://www.youtube.com/@grafikart/search?query=python%20bases%20tutoriel" },
    { label: "Grafikart — Python POO : classes, héritage, propriétés", url: "https://www.youtube.com/@grafikart/search?query=python%20poo" },
    { label: "Grafikart — Python : modules, packages, virtualenv", url: "https://www.youtube.com/@grafikart/search?query=python%20modules%20virtualenv" },
    { label: "Grafikart — Python : gestion d'erreurs, exceptions, logging", url: "https://www.youtube.com/@grafikart/search?query=python%20exceptions%20logging" }
  ],
  // Web - grafikart's specialty! HTML, CSS, JS, React, Vue, etc.
  web: [
    { label: "Grafikart — HTML5 : structure sémantique, formulaires", url: "https://www.youtube.com/@grafikart/search?query=html5%20s%C3%A9mantique%20formulaires" },
    { label: "Grafikart — CSS3 : flexbox, grid, animations", url: "https://www.youtube.com/@grafikart/search?query=css3%20flexbox%20grid" },
    { label: "Grafikart — JavaScript ES6+ : arrow functions, destructuring, modules", url: "https://www.youtube.com/@grafikart/search?query=javascript%20es6" },
    { label: "Grafikart — React : hooks, context, routing", url: "https://www.youtube.com/@grafikart/search?query=react%20hooks%20context" },
    { label: "Grafikart — Vue.js : composition API, composants", url: "https://www.youtube.com/@grafikart/search?query=vuejs%20composition%20api" },
    { label: "Grafikart — TypeScript : types, interfaces, generics", url: "https://www.youtube.com/@grafikart/search?query=typescript%20tutoriel" }
  ]
};

const chaptersDir = path.join(__dirname, 'content', 'chapters');
const files = fs.readdirSync(chaptersDir).filter(f => f.endsWith('.json'));

let updated = 0;
let skipped = 0;

files.forEach(file => {
  const filepath = path.join(chaptersDir, file);
  const chapter = JSON.parse(fs.readFileSync(filepath, 'utf8'));
  
  // Extract pathway prefix from filename (e.g., "algo-c1.json" -> "algo")
  const match = file.match(/^([a-z]+)-/);
  if (!match) {
    console.log(`Skipping ${file}: no pathway prefix found`);
    skipped++;
    return;
  }
  
  const prefix = match[1];
  const videos = grafikartVideos[prefix];
  
  if (!videos || videos.length === 0) {
    console.log(`Skipping ${file}: no grafikart videos defined for prefix "${prefix}"`);
    skipped++;
    return;
  }
  
  // Check if grafikart videos already exist
  const hasGrafikart = chapter.resources.some(r => r.url.includes('grafikart') || r.label.includes('Grafikart'));
  if (hasGrafikart) {
    console.log(`Skipping ${file}: already has grafikart videos`);
    skipped++;
    return;
  }
  
  // Add grafikart videos to resources
  chapter.resources = [...chapter.resources, ...videos];
  
  fs.writeFileSync(filepath, JSON.stringify(chapter, null, 2));
  console.log(`Updated ${file}: added ${videos.length} grafikart videos`);
  updated++;
});

console.log(`\nDone! Updated: ${updated}, Skipped: ${skipped}`);