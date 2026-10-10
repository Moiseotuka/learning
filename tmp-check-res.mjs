const urls = [
  "https://attack.mitre.org/",
  "https://sigmahq.io/",
  "https://fr.wikipedia.org/wiki/Matrice_ATTACK",
  "https://fr.wikipedia.org/wiki/S%C3%A9curit%C3%A9_des_syst%C3%A8mes_d%27information",
  "https://cyber.gouv.fr/",
  "https://attack.mitre.org/resources/matrices/enterprise/",
  "https://www.elastic.co/guide/en/security/current/detection-rules.html",
  "https://docs.wazuh.com/current/user-manual/ruleset/index.html",
];
for (const u of urls) {
  try {
    const r = await fetch(u, { headers: { "User-Agent": "Mozilla/5.0 easyLearn-content/1.0" }, redirect: "follow" });
    console.log(r.status, u, "->", r.url);
  } catch (e) {
    console.log("ERR", e.message, u);
  }
}
