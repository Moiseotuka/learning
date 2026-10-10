const fs = require('fs');
const path = require('path');

const templatePath = path.join(__dirname, 'grafikart-video-ids.json');
const template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));

const chaptersDir = path.join(__dirname, 'content', 'chapters');
let updated = 0;
let skipped = 0;

Object.entries(template).forEach(([chapterKey, videos]) => {
  // Append .json if not present
  const chapterFile = chapterKey.endsWith('.json') ? chapterKey : chapterKey + '.json';
  const filepath = path.join(__dirname, 'content', 'chapters', chapterFile);
  
  if (!fs.existsSync(filepath)) {
    console.log(`Skipping ${chapterFile}: chapter file not found`);
    skipped++;
    return;
  }
  
  // Check if any videoId is still placeholder
  const hasPlaceholder = videos.some(v => v.videoId === 'REPLACE_WITH_GRAFIKART_VIDEO_ID');
  if (hasPlaceholder) {
    console.log(`Skipping ${chapterFile}: contains placeholder video IDs`);
    skipped++;
    return;
  }
  
  const chapterPath = path.join(__dirname, 'content', 'chapters', chapterFile);
  const chapter = JSON.parse(fs.readFileSync(filepath, 'utf8'));
  
  // Convert videoId to full video object
  chapter.videos = videos.map(v => ({
    title: v.title,
    url: `https://www.youtube.com/watch?v=${v.videoId}`,
    channel: v.channel || 'Grafikart'
  }));
  
  fs.writeFileSync(filepath, JSON.stringify(chapter, null, 2));
  console.log(`Updated ${chapterFile}: ${videos.length} videos`);
  updated++;
});

console.log(`\nDone! Updated: ${updated}, Skipped: ${skipped}`);
if (skipped > 0) {
  console.log('\nEdit grafikart-video-ids.json and replace REPLACE_WITH_GRAFIKART_VIDEO_ID with actual YouTube video IDs from Grafikart channel.');
}