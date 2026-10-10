import { readFileSync, writeFileSync } from 'fs';
import { join } from 'path';

const lessonsDir = join(process.cwd(), 'content', 'lessons');
const outputFile = join(process.cwd(), 'supabase', 'migrations', '202610050002_new_chapters_pages_seed.sql');

const newChapters = [
  'cyb-c1',
  'ia-c1', 'ia-c2', 'ia-c3', 'ia-c4', 'ia-c5', 'ia-c6', 'ia-c7', 'ia-c8',
  'net-c1', 'net-c2', 'net-c3', 'net-c4', 'net-c5', 'net-c6', 'net-c7',
  'ard-c1', 'ard-c2', 'ard-c3', 'ard-c4', 'ard-c5', 'ard-c6'
];

function splitIntoPages(content) {
  // Split by ## headers (markdown level 2)
  const lines = content.split('\n');
  const pages = [];
  let currentPage = { title: 'Introduction', content: '' };
  
  for (const line of lines) {
    const match = line.match(/^##\s+(.+)$/);
    if (match) {
      // Save previous page if it has content
      if (currentPage.content.trim()) {
        pages.push({ ...currentPage });
      }
      // Start new page
      currentPage = { title: match[1].trim(), content: '' };
    } else {
      currentPage.content += line + '\n';
    }
  }
  // Don't forget the last page
  if (currentPage.content.trim()) {
    pages.push({ ...currentPage });
  }
  
  // If no ## headers found, treat whole content as one page
  if (pages.length === 0) {
    pages.push({ title: 'Leçon complète', content: content });
  }
  
  return pages;
}

function generatePageInsert(chapterId, pages) {
  let sql = '';
  for (let i = 0; i < pages.length; i++) {
    const page = pages[i];
    const pageId = `${chapterId}-p${i + 1}`;
    const position = i + 1;
    const delimiter = escapeDollarQuotes(page.content);
    
    sql += `  ('${pageId}', '${chapterId}', ${position}, $${delimiter}$
${page.title}
$${delimiter}$, $${delimiter}$
${page.content.trim()}
$${delimiter}$),\n`;
  }
  return sql;
}

function escapeDollarQuotes(text) {
  const delimiters = ['lesson', 'content', 'data', 'text', 'body', 'page', 'section', 'title'];
  for (const d of delimiters) {
    if (!text.includes(`$${d}$`)) return d;
  }
  return 'page_' + Date.now() + Math.random().toString(36).substr(2, 9);
}

let sql = `-- easyLearn — seed des pages numérotées pour nouveaux chapitres
-- Chapitres : ${newChapters.join(', ')}
-- Généré automatiquement — à appliquer après 202610040004_chapter_pages.sql
-- Prérequis : 202610040004_chapter_pages.sql (table chapter_pages)

delete from public.chapter_pages where chapter_id in (${newChapters.map(c => `'${c}'`).join(', ')});

insert into public.chapter_pages (id, chapter_id, position, title, content) values
`;

for (const chapterId of newChapters) {
  const filePath = join(lessonsDir, `${chapterId}.txt`);
  try {
    const content = readFileSync(filePath, 'utf-8');
    const pages = splitIntoPages(content);
    sql += generatePageInsert(chapterId, pages);
    console.log(`✓ ${chapterId}: ${pages.length} pages`);
  } catch (e) {
    console.error(`✗ ${chapterId}: ${e.message}`);
  }
}

// Remove trailing comma and add semicolon
sql = sql.replace(/,\s*$/, ';') + '\n';

writeFileSync(outputFile, sql);
console.log(`\nFichier généré : ${outputFile}`);
console.log('Appliquez cette migration dans Supabase SQL Editor après 202610040004_chapter_pages.sql.');