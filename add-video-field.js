const fs = require('fs');
const path = require('path');

const grafikartVideos = {
  algo: [
    { title: "Structures de données en JavaScript", url: "https://www.youtube.com/@grafikart/search?query=structures%20de%20donn%C3%A9es%20javascript", channel: "Grafikart" },
    { title: "Algorithmes de tri en JavaScript", url: "https://www.youtube.com/@grafikart/search?query=tri%20javascript", channel: "Grafikart" },
    { title: "Complexité algorithmique", url: "https://www.youtube.com/@grafikart/search?query=complexit%C3%A9%20algorithmique", channel: "Grafikart" }
  ],
  ard: [
    { title: "Arduino et ESP32", url: "https://www.youtube.com/@grafikart/search?query=arduino%20esp32", channel: "Grafikart" },
    { title: "IoT et objets connectés", url: "https://www.youtube.com/@grafikart/search?query=iot%20objets%20connect%C3%A9s", channel: "Grafikart" }
  ],
  cyb: [
    { title: "Sécurité web : authentification et JWT", url: "https://www.youtube.com/@grafikart/search?query=s%C3%A9curit%C3%A9%20web%20jwt", channel: "Grafikart" },
    { title: "Protection CSRF, XSS, injection SQL", url: "https://www.youtube.com/@grafikart/search?query=csrf%20xss%20injection%20sql", channel: "Grafikart" },
    { title: "HTTPS, certificats SSL/TLS", url: "https://www.youtube.com/@grafikart/search?query=https%20ssl%20tls", channel: "Grafikart" }
  ],
  db: [
    { title: "PostgreSQL : installation et bases", url: "https://www.youtube.com/@grafikart/search?query=postgresql%20tutoriel", channel: "Grafikart" },
    { title: "Modélisation Merise, MLD, MCD", url: "https://www.youtube.com/@grafikart/search?query=merise%20mld%20mcd", channel: "Grafikart" },
    { title: "Requêtes SQL avancées", url: "https://www.youtube.com/@grafikart/search?query=sql%20avanc%C3%A9", channel: "Grafikart" }
  ],
  dj: [
    { title: "Django : créer un projet complet", url: "https://www.youtube.com/@grafikart/search?query=django%20tutoriel", channel: "Grafikart" },
    { title: "Django ORM : modèles, migrations, requêtes", url: "https://www.youtube.com/@grafikart/search?query=django%20orm", channel: "Grafikart" },
    { title: "Django REST Framework", url: "https://www.youtube.com/@grafikart/search?query=django%20rest%20framework", channel: "Grafikart" }
  ],
  do: [
    { title: "Docker : créer et gérer des conteneurs", url: "https://www.youtube.com/@grafikart/search?query=docker%20tutoriel", channel: "Grafikart" },
    { title: "CI/CD avec GitHub Actions / GitLab CI", url: "https://www.youtube.com/@grafikart/search?query=ci%20cd%20github%20actions", channel: "Grafikart" },
    { title: "Linux : commandes essentielles, SSH, scripts", url: "https://www.youtube.com/@grafikart/search?query=linux%20commandes%20ssh", channel: "Grafikart" },
    { title: "Nginx : configuration, reverse proxy, SSL", url: "https://www.youtube.com/@grafikart/search?query=nginx%20configuration", channel: "Grafikart" }
  ],
  ia: [
    { title: "Python pour la data : pandas, numpy", url: "https://www.youtube.com/@grafikart/search?query=python%20pandas%20numpy", channel: "Grafikart" },
    { title: "Visualisation de données avec Python", url: "https://www.youtube.com/@grafikart/search?query=visualisation%20donn%C3%A9es%20python", channel: "Grafikart" }
  ],
  net: [
    { title: "Réseau : TCP/IP, DNS, HTTP", url: "https://www.youtube.com/@grafikart/search?query=r%C3%A9seau%20tcp%20ip%20dns", channel: "Grafikart" },
    { title: "Configuration réseau Linux", url: "https://www.youtube.com/@grafikart/search?query=r%C3%A9seau%20linux%20configuration", channel: "Grafikart" }
  ],
  off: [
    { title: "Sécurité offensive : bases", url: "https://www.youtube.com/@grafikart/search?query=s%C3%A9curit%C3%A9%20offensive", channel: "Grafikart" },
    { title: "Outils de pentest : Burp Suite, Nmap", url: "https://www.youtube.com/@grafikart/search?query=burp%20suite%20nmap", channel: "Grafikart" }
  ],
  py: [
    { title: "Python : bases, variables, structures de contrôle", url: "https://www.youtube.com/@grafikart/search?query=python%20bases%20tutoriel", channel: "Grafikart" },
    { title: "Python POO : classes, héritage, propriétés", url: "https://www.youtube.com/@grafikart/search?query=python%20poo", channel: "Grafikart" },
    { title: "Python : modules, packages, virtualenv", url: "https://www.youtube.com/@grafikart/search?query=python%20modules%20virtualenv", channel: "Grafikart" },
    { title: "Python : gestion d'erreurs, exceptions, logging", url: "https://www.youtube.com/@grafikart/search?query=python%20exceptions%20logging", channel: "Grafikart" }
  ],
  web: [
    { title: "HTML5 : structure sémantique, formulaires", url: "https://www.youtube.com/@grafikart/search?query=html5%20s%C3%A9mantique%20formulaires", channel: "Grafikart" },
    { title: "CSS3 : flexbox, grid, animations", url: "https://www.youtube.com/@grafikart/search?query=css3%20flexbox%20grid", channel: "Grafikart" },
    { title: "JavaScript ES6+ : arrow functions, destructuring, modules", url: "https://www.youtube.com/@grafikart/search?query=javascript%20es6", channel: "Grafikart" },
    { title: "React : hooks, context, routing", url: "https://www.youtube.com/@grafikart/search?query=react%20hooks%20context", channel: "Grafikart" },
    { title: "Vue.js : composition API, composants", url: "https://www.youtube.com/@grafikart/search?query=vuejs%20composition%20api", channel: "Grafikart" },
    { title: "TypeScript : types, interfaces, generics", url: "https://www.youtube.com/@grafikart/search?query=typescript%20tutoriel", channel: "Grafikart" }
  ]
};

const chaptersDir = path.join(__dirname, 'content', 'chapters');
const files = fs.readdirSync(chaptersDir).filter(f => f.endsWith('.json'));

let updated = 0;

files.forEach(file => {
  const filepath = path.join(chaptersDir, file);
  const chapter = JSON.parse(fs.readFileSync(filepath, 'utf8'));
  
  const match = file.match(/^([a-z]+)-/);
  if (!match) return;
  
  const prefix = match[1];
  const videos = grafikartVideos[prefix];
  
  if (!videos || videos.length === 0) return;
  
  // Check if videos field already exists
  if (chapter.videos && chapter.videos.length > 0) {
    console.log(`Skipping ${file}: already has videos`);
    return;
  }
  
  chapter.videos = videos;
  
  fs.writeFileSync(filepath, JSON.stringify(chapter, null, 2));
  console.log(`Updated ${file}: added ${videos.length} videos`);
  updated++;
});

console.log(`\nDone! Updated: ${updated}`);