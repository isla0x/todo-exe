const { chromium } = require('playwright');
const fs = require('fs');
const out = __dirname + '/threads';
(async () => {
  fs.mkdirSync(out + '/frames', { recursive: true });
  const b = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium' });
  const p = await b.newPage({ viewport: { width: 432, height: 540 }, deviceScaleFactor: 2.5 });
  for (let n = 1; n <= 5; n++) {
    await p.goto(`file://${__dirname}/threads.html?mode=img&n=${n}`);
    await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(150);
    await p.screenshot({ path: `${out}/todo-threads-0${n}.png` });
  }
  if (process.argv[2] !== 'imgonly') {
    const v = await b.newPage({ viewport: { width: 432, height: 768 }, deviceScaleFactor: 2.5 });
    await v.goto(`file://${__dirname}/threads.html?mode=video&t=0`);
    await v.evaluate(() => document.fonts.ready); await v.waitForTimeout(200);
    const fps = 30, dur = 12;
    for (let i = 0; i < fps * dur; i++) {
      await v.evaluate(t => window.renderVideo(t), i / fps);
      await v.screenshot({ path: `${out}/frames/f${String(i).padStart(4, '0')}.png` });
    }
  }
  await b.close();
})();
