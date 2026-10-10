const https = require('https');
const fs = require('fs');

const env = fs.readFileSync('.env.local', 'utf8');
const keyMatch = env.match(/SUPABASE_SERVICE_ROLE_KEY=(.*)/);
const key = keyMatch ? keyMatch[1].trim() : null;

const patchData = JSON.stringify({
  title: "Fondamentaux algorithmiques",
  slug: "fondamentaux-algorithmique"
});
console.log('Sending:', patchData);

const url = 'https://gmgmrywvloszxlqmellw.supabase.co/rest/v1/chapters?id=eq.algo-c1';
const opts = {
  method: 'PATCH',
  headers: {
    'apikey': key,
    'Authorization': 'Bearer ' + key,
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(patchData),
    'Prefer': 'return=representation'
  }
};

const req = https.request(url, opts, function(r) {
  let d = '';
  r.on('data', function(c) { d += c; });
  r.on('end', function() {
    console.log('Status:', r.statusCode);
    console.log('Response:', d.substring(0, 500));
  });
});
req.on('error', function(e) { console.log('Error:', e.message); });
req.write(patchData);
req.end();