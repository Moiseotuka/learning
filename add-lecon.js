const fs = require('fs');
const paths = ["algo", "ard", "cyb", "db", "dj", "do", "ia", "net", "off", "py", "web"];

paths.forEach(p => {
  try {
    const chapters = fs.readdirSync("content/chapters").filter(f => f.startsWith(p+"-") && f.endsWith(".json"));
    for (const c of chapters) {
      const chapterPath = "content/chapters/" + c;
      let chapter = JSON.parse(fs.readFileSync(chapterPath, "utf8"));
      const lessonName = c.replace(".json", ".txt");
      chapter.lecon = lessonName;
      fs.writeFileSync(chapterPath, JSON.stringify(chapter, null, 2));
      console.log("Updated " + c + " : added lecon=" + lessonName);
    }
  } catch(e) {
    console.log("Error with " + p + ": " + e.message);
  }
});