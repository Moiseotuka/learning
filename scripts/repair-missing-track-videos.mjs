import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const envText = readFileSync(new URL('../.env.local', import.meta.url), 'utf8');
const envValue = (key) => {
  const match = envText.match(new RegExp(`^${key}=(.*)$`, 'm'));
  return match ? match[1].trim() : '';
};

const url = envValue('NEXT_PUBLIC_SUPABASE_URL');
const key = envValue('SUPABASE_SERVICE_ROLE_KEY') || envValue('SUPABASE_SECRET_KEY');

if (!url || !key) {
  console.error('Missing Supabase service credentials in .env.local');
  process.exit(1);
}

const TRACK_VIDEO_MAP = {
  'mobile-flutter-react-native': [
    {
      title: 'Flutter pour débutants : widgets, layout et navigation',
      url: 'https://www.youtube.com/watch?v=VPvVD8t0Yj8',
      channel: 'Flutter',
    },
    {
      title: 'React Native en français : composants, navigation et styling',
      url: 'https://www.youtube.com/watch?v=0-S5a0eXPoc',
      channel: 'React Native',
    },
  ],
  'java-spring-backend': [
    {
      title: 'Java pour débutants : classes, collections et exceptions',
      url: 'https://www.youtube.com/watch?v=grEKMHGYyns',
      channel: 'Java',
    },
    {
      title: 'Spring Boot pour débutants : créer votre première API REST',
      url: 'https://www.youtube.com/watch?v=9SGDpanrc8M',
      channel: 'Spring Boot',
    },
  ],
  'php-modern': [
    {
      title: 'PHP pour débutants : syntaxe, fonctions et tableaux',
      url: 'https://www.youtube.com/watch?v=1dL6ZzM4K7M',
      channel: 'PHP',
    },
    {
      title: 'Créer une API PHP sécurisée avec bonnes pratiques',
      url: 'https://www.youtube.com/watch?v=8BbqJ6-YBjQ',
      channel: 'PHP',
    },
  ],
  'django-web': [
    {
      title: 'Django pour débutants : créer un projet et l’ORM',
      url: 'https://www.youtube.com/watch?v=F5mRW0jo-U4',
      channel: 'Django',
    },
    {
      title: 'Django REST Framework : construire une API sécurisée',
      url: 'https://www.youtube.com/watch?v=xjD0C0qtlkQ',
      channel: 'Django REST',
    },
  ],
  'algorithmique-fondamentaux': [
    {
      title: 'Algorithmique : complexité et structures de données',
      url: 'https://www.youtube.com/watch?v=8hly31xKli0',
      channel: 'Algorithmique',
    },
    {
      title: 'Graphes et parcours en algorithmique',
      url: 'https://www.youtube.com/watch?v=pcKY4hjS3TY',
      channel: 'Algorithmique',
    },
  ],
  'bases-donnees-sql': [
    {
      title: 'SQL pour débutants : tables, jointures et requêtes',
      url: 'https://www.youtube.com/watch?v=HXV3zeQKqGY',
      channel: 'SQL',
    },
    {
      title: 'Modéliser une base de données relationnelle',
      url: 'https://www.youtube.com/watch?v=5sDQqxdn3l8',
      channel: 'Base de données',
    },
  ],
  'devops-cloud': [
    {
      title: 'Linux et automation : les bases de la chaîne DevOps',
      url: 'https://www.youtube.com/watch?v=Jf4FtJr2UG0',
      channel: 'DevOps',
    },
    {
      title: 'Docker pour débutants : conteneurs et images',
      url: 'https://www.youtube.com/watch?v=3c-iBn73dDE',
      channel: 'Docker',
    },
  ],
  'cybersecurite-offensive': [
    {
      title: 'Cyberdéfense : reconnaissance et vulnérabilités web',
      url: 'https://www.youtube.com/watch?v=DK_5COGdGTE',
      channel: 'Sécurité',
    },
    {
      title: 'Pentest et sécurité offensive : méthodologie',
      url: 'https://www.youtube.com/watch?v=G1bnNTLrFsQ',
      channel: 'Sécurité',
    },
  ],
};

const sqlFile = join(process.cwd(), 'supabase', 'migrations', '202610070004_missing_tracks_videos.sql');
const statements = [];

async function main() {
  const headers = {
    apikey: key,
    Authorization: `Bearer ${key}`,
  };

  const response = await fetch(`${url}/rest/v1/chapters?select=id,track_id,slug,level,videos&published=eq.true`, {
    headers,
  });

  if (!response.ok) {
    console.error('Failed to query chapters:', response.status, await response.text());
    process.exit(1);
  }

  const chapters = await response.json();
  const targetIds = new Set(Object.keys(TRACK_VIDEO_MAP));
  const toUpdate = chapters.filter((chapter) => targetIds.has(chapter.track_id) && (!Array.isArray(chapter.videos) || chapter.videos.length === 0));

  if (toUpdate.length === 0) {
    console.log('No missing video arrays found.');
    return;
  }

  for (const chapter of toUpdate) {
    const videos = TRACK_VIDEO_MAP[chapter.track_id] ?? [
      {
        title: `Cours ${chapter.level} : ${chapter.slug}`,
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        channel: 'EasyLearn',
      },
    ];

    const patch = await fetch(`${url}/rest/v1/chapters?id=eq.${encodeURIComponent(chapter.id)}`, {
      method: 'PATCH',
      headers: { ...headers, 'Content-Type': 'application/json', Prefer: 'return=minimal' },
      body: JSON.stringify({ videos }),
    });

    if (!patch.ok) {
      console.error('PATCH failed for', chapter.id, patch.status, await patch.text());
      process.exit(1);
    }

    statements.push(`update public.chapters set videos = '${JSON.stringify(videos).replace(/'/g, "''")}'::jsonb where id = '${chapter.id}';`);
    console.log(`✓ ${chapter.id} (${chapter.track_id}) -> ${videos.length} vidéos`);
  }

  writeFileSync(sqlFile, `-- easyLearn — correction des vidéos manquantes sur les parcours ajoutés\n-- Généré par scripts/repair-missing-track-videos.mjs\n\n${statements.join('\n')}\n`, 'utf8');
  console.log(`\nSQL migration written to ${sqlFile}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
