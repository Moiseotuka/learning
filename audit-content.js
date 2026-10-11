const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const envPath = path.join(process.cwd(), '.env.local');
const text = fs.readFileSync(envPath, 'utf8');
const envValue = (key) => {
  const match = text.match(new RegExp(`^${key}=(.*)$`, 'm'));
  return match ? match[1].trim() : '';
};

const url = envValue('NEXT_PUBLIC_SUPABASE_URL');
const key = envValue('SUPABASE_SERVICE_ROLE_KEY');
const supabase = createClient(url, key, {
  auth: { persistSession: false, autoRefreshToken: false },
});

(async () => {
  const [tracks, chapters, exams] = await Promise.all([
    supabase.from('tracks').select('id,slug,title,published').eq('published', true),
    supabase.from('chapters').select('id,track_id,level,videos,published').eq('published', true),
    supabase.from('level_exams').select('track_id,level,status'),
  ]);

  console.log('tracks:', tracks.data?.length ?? 0);
  console.log('chapters:', chapters.data?.length ?? 0);
  console.log('tracks list:');
  for (const track of tracks.data ?? []) {
    console.log('-', track.slug, '::', track.title);
  }

  const byTrack = new Map();
  for (const chapter of chapters.data ?? []) {
    const list = byTrack.get(chapter.track_id) ?? [];
    list.push(chapter);
    byTrack.set(chapter.track_id, list);
  }

  console.log('chapters by orphan track:');
  for (const [trackId, list] of byTrack.entries()) {
    if (!tracks.data?.some((row) => row.id === trackId)) {
      console.log('TRACK', trackId, 'chapters:', list.length);
      for (const ch of list) {
        console.log(JSON.stringify({
          id: ch.id,
          level: ch.level,
          slug: ch.slug,
          title: ch.title,
          videos: Array.isArray(ch.videos) ? ch.videos.length : 0,
        }, null, 2));
      }
    }
  }

  const missingVideoLevels = [];
  for (const [trackId, list] of byTrack.entries()) {
    const levels = new Map();
    for (const ch of list) {
      const arr = levels.get(ch.level) ?? [];
      arr.push(ch);
      levels.set(ch.level, arr);
    }

    for (const [level, items] of levels.entries()) {
      const videos = items.filter((ch) => Array.isArray(ch.videos) && ch.videos.length > 0).length;
      if (videos === 0) {
        missingVideoLevels.push({ trackId, level, chapters: items.length });
      }
    }
  }

  console.log('levels with 0 videos:', missingVideoLevels.length);
  console.log(JSON.stringify(missingVideoLevels.slice(0, 10), null, 2));
  console.log('exam rows:', exams.data?.length ?? 0);

  const examsByTrackLevel = new Set(
    (exams.data ?? []).filter((r) => r.status === 'passed').map((r) => `${r.track_id}:${r.level}`),
  );
  console.log('passed exam keys:', examsByTrackLevel.size);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
