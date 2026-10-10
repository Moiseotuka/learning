const urls = [
  "https://upload.wikimedia.org/wikipedia/commons/thumb/f/fb/Sword_26-_Cyber_Range_26_%289706738%29.jpg/960px-Sword_26-_Cyber_Range_26_%289706738%29.jpg",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/1/18/Red_team_%2851872210227%29.jpg/960px-Red_team_%2851872210227%29.jpg",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Wazuh_SIEM_screenshot.webp/960px-Wazuh_SIEM_screenshot.webp",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Fichier_syslog.jpg/960px-Fichier_syslog.jpg",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/8/81/Network_based_intrusion_detection_system.png/960px-Network_based_intrusion_detection_system.png",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/7/76/Honeypot_diagram.jpg/960px-Honeypot_diagram.jpg",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ab/DHS_Secretary_Alejandro_Mayorkas_Visits_EcuCERT_National_Cybersecurity_Center_%2852554002980%29.jpg/960px-DHS_Secretary_Alejandro_Mayorkas_Visits_EcuCERT_National_Cybersecurity_Center_%2852554002980%29.jpg",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/5/58/645th_Cyberspace_Squadron_Conducts_Joint_Cosmic_Chimera_Cyber_Exercise_%289910036%29.jpg/960px-645th_Cyberspace_Squadron_Conducts_Joint_Cosmic_Chimera_Cyber_Exercise_%289910036%29.jpg",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/9/96/Host_based_intrusion_detection_system.png/960px-Host_based_intrusion_detection_system.png",
  "https://upload.wikimedia.org/wikipedia/commons/thumb/a/aa/Sword_26-_Cyber_Range_26_%289706755%29.jpg/960px-Sword_26-_Cyber_Range_26_%289706755%29.jpg",
];
for (const u of urls) {
  try {
    const r = await fetch(u, { headers: { "User-Agent": "easyLearn-content/1.0 (contact@example.org)" } });
    console.log(r.status, r.headers.get("content-type"), u);
  } catch (e) {
    console.log("ERR", e.message, u);
  }
}
