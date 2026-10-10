const https = require('https');
const fs = require('fs');

const env = fs.readFileSync('.env.local', 'utf8');
const keyMatch = env.match(/SUPABASE_SERVICE_ROLE_KEY=(.*)/);
const key = keyMatch ? keyMatch[1].trim() : null;

const url = 'https://gmgmrywvloszxlqmellw.supabase.co/rest/v1/chapters?select=id,title,slug&order=id';
const opts = {
  headers: {
    'apikey': key,
    'Authorization': 'Bearer ' + key
  }
};
https.get(url, opts, function(r) {
  let d = '';
  r.on('data', function(c) { d += c; });
  r.on('end', function() {
    const rows = JSON.parse(d);
    const algoChapters = rows.filter(row => row.id.startsWith('algo'));
    algoChapters.forEach(row => console.log(row.id + ' | ' + row.title + ' | ' + row.slug));
  });
}).on('error', function(e) { console.log('Error: ' + e.message); });