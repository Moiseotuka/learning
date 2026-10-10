const https = require('https');
const fs = require('fs');

// Read the service role key from .env.local
const env = fs.readFileSync('.env.local', 'utf8');
const keyMatch = env.match(/SUPABASE_SERVICE_ROLE_KEY=(.*)/);
const key = keyMatch ? keyMatch[1].trim() : null;
console.log('Using service key: ' + (key ? key.substring(0, 30) + '...' : 'NOT FOUND'));

const url = 'https://gmgmrywvloszxlqmellw.supabase.co/rest/v1/chapters?select=id,title,slug&limit=10';
const opts = {
  headers: {
    'apikey': key,
    'Authorization': 'Bearer ' + key
  }
};
https.get(url, opts, function(r) {
  let d = '';
  r.on('data', function(c) { d += c; });
  r.on('end', function() { console.log(d.substring(0, 500)); });
}).on('error', function(e) { console.log('Error: ' + e.message); });