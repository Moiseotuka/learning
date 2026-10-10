const api = async (title, width = 960) => {
  const url = `https://commons.wikimedia.org/w/api.php?action=query&titles=${encodeURIComponent(title)}&prop=imageinfo&iiprop=url&iiurlwidth=${width}&format=json`;
  try {
    const r = await fetch(url);
    const j = await r.json();
    const pages = j.query.pages;
    const p = Object.values(pages)[0];
    if (p && p.imageinfo && p.imageinfo[0]) {
      const thumb = p.imageinfo[0].thumburl || p.imageinfo[0].url;
      const s = await fetch(thumb, { method: "HEAD" });
      return { title, status: s.status, url: thumb };
    }
    return { title, status: 0, url: null, note: "missing" };
  } catch (e) {
    return { title, status: -1, url: null, note: String(e) };
  }
};

const direct = async (url) => {
  try {
    const s = await fetch(url, { method: "HEAD" });
    return { url, status: s.status };
  } catch (e) {
    return { url, status: -1, note: String(e) };
  }
};

const titles = [
  "File:Virtualbox logo.svg",
  "File:Oracle VM VirtualBox logo.svg",
  "File:VirtualBox logo.svg",
  "File:Metasploit logo.svg",
  "File:Metasploit Project logo.svg",
  "File:Metasploit.svg",
  "File:Kali linux purple logo.svg",
  "File:Kali Linux 2.0 wordmark.svg",
  "File:Kali-dragon-icon.svg",
  "File:NetworkTopologies.svg",
  "File:Firewall.svg",
  "File:Internet map 1024.jpg",
  "File:Bash Logo.svg",
  "File:Linux logo.svg",
  "File:Metasploitable logo.png",
  "File:Oracle VM VirtualBox icon.svg",
  "File:VirtualBox 6 icon.png",
  "File:GNOME Terminal.png",
  "File:Xterm-color.png",
];

for (const t of titles) {
  const r = await api(t);
  console.log(JSON.stringify(r));
}

const urls = [
  "https://www.virtualbox.org/manual/",
  "https://docs.metasploit.com/",
  "https://fr.wikipedia.org/wiki/Metasploit_Project",
  "https://fr.wikipedia.org/wiki/VirtualBox",
  "https://www.metasploit.com/",
  "https://github.com/rapid7/metasploit-framework",
  "https://www.offensive-security.com/metasploit-unleashed/",
  "https://fr.wikipedia.org/wiki/Reverse_shell",
  "https://owasp.org/www-project-web-security-testing-guide/",
  "https://www.anssi.gouv.fr/",
  "https://fr.wikipedia.org/wiki/Machine_virtual",
  "https://fr.wikipedia.org/wiki/Shell_(informatique)",
];

for (const u of urls) {
  const r = await direct(u);
  console.log(JSON.stringify(r));
}
