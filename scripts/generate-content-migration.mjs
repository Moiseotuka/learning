import { readFileSync, writeFileSync, readdirSync } from 'fs';
import { join } from 'path';

const lessonsDir = join(process.cwd(), 'content', 'lessons');
const outputFile = join(process.cwd(), 'supabase', 'migrations', '202610050001_new_chapters_content.sql');

const newChapters = [
  'cyb-c1',
  'ia-c1', 'ia-c2', 'ia-c3', 'ia-c4', 'ia-c5', 'ia-c6', 'ia-c7', 'ia-c8',
  'net-c1', 'net-c2', 'net-c3', 'net-c4', 'net-c5', 'net-c6', 'net-c7',
  'ard-c1', 'ard-c2', 'ard-c3', 'ard-c4', 'ard-c5', 'ard-c6'
];

function escapeDollarQuotes(text) {
  // Find a delimiter that doesn't appear in the text
  const delimiters = ['lesson', 'content', 'data', 'text', 'body'];
  for (const d of delimiters) {
    if (!text.includes(`$${d}$`)) {
      return d;
    }
  }
  // Fallback: use a random delimiter
  return 'lesson_' + Date.now();
}

function generateUpdate(chapterId, content) {
  const delimiter = escapeDollarQuotes(content);
  return `update public.chapters set content = $${delimiter}$
${content}
$${delimiter}$
where id = '${chapterId}';`;
}

let sql = `-- easyLearn — nouveaux chapitres : contenu des leçons
-- Chapitres : ${newChapters.join(', ')}
-- Généré automatiquement — à appliquer après 202610040007_track_structure.sql

`;

for (const chapterId of newChapters) {
  const filePath = join(lessonsDir, `${chapterId}.txt`);
  try {
    const content = readFileSync(filePath, 'utf-8');
    sql += generateUpdate(chapterId, content) + '\n\n';
    console.log(`✓ ${chapterId} (${content.length} chars)`);
  } catch (e) {
    console.error(`✗ ${chapterId}: ${e.message}`);
  }
}

writeFileSync(outputFile, sql);
console.log(`\nFichier généré : ${outputFile}`);
console.log('Appliquez cette migration dans Supabase SQL Editor.');