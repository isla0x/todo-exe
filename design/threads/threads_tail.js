
// ─────────────── Threads 홍보용 (이미지 1080x1350, 영상 1080x1920) ───────────────
const mode = q.get('mode') || 'img';
const W = 432, H = mode === 'video' ? 768 : 540;
const G = '#16C60C';
function phone(x, y, sw, body, bare) {
  const sc = sw / C.appW, sh = Math.round(sw * C.appH / C.appW), bz = Math.max(4, Math.round(sw * 8 / 350));
  const inner = bare
    ? `<div style="position:absolute;left:0;top:0;width:${C.appW}px;height:${C.appH}px;transform:scale(${sc});transform-origin:top left">${body}</div>`
    : body.replace('class="app" style="', `class="app" style="transform:scale(${sc});`);
  return `<div class="frame" style="left:${x}px;top:${y}px;width:${sw + bz * 2}px;height:${sh + bz * 2}px;border-radius:${Math.round(sw * 58 / 350)}px">
    <div class="screen" style="left:${bz}px;top:${bz}px;width:${sw}px;height:${sh}px;border-radius:${Math.round(sw * 50 / 350)}px">${inner}</div></div>`;
}
function cap(t, s, top = 34) {
  return `<div class="cap" style="top:${top}px"><div class="p" style="font-size:12px"><b>&gt;_</b> C:\\todo&gt;</div>
    <div class="t" style="font-size:30px;margin-top:6px">${t}</div>${s ? `<div class="s" style="font-size:13px;margin-top:6px">${s}</div>` : ''}</div>`;
}
function term(lines, x, y, w) {
  const col = { cmd: '#CCCCCC', ok: G, dim: '#8A8A8A', hi: '#F2F2F2', tag: '#F9F1A5' };
  return `<div class="mono" style="position:absolute;left:${x}px;top:${y}px;width:${w}px;border:1px solid #2A2A2A;background:#0C0C0C;box-shadow:0 30px 80px rgba(0,0,0,.6)">
    <div class="row" style="height:34px;background:#1A1A1A;padding:0 12px;gap:8px;font-size:13px;color:#F2F2F2">${promptIcon('#F2F2F2')}<span>todo.exe</span></div>
    <div style="padding:16px 16px 18px;font-size:15px;line-height:1.9">${lines.map(([k, s]) =>
      k === 'in' ? `<div><span style="color:#8A8A8A">C:\\todo&gt; </span><span style="color:#61D6D6">${esc(s)}</span></div>`
      : k === 'cur' ? `<div><span style="color:#8A8A8A">C:\\todo&gt; </span><span style="display:inline-block;width:9px;height:17px;background:${G};vertical-align:-3px"></span></div>`
      : `<div style="color:${col[k]}">${esc(s)}</div>`).join('')}</div></div>`;
}
const IMGS = {
  1: () => cap('투두 앱인데 터미널임', 'add · done · ls — 한 줄이면 끝') +
    phone((W - 316) / 2, 140, 300, mainScreen(P.cmd, { showPro: true, log: [['cmd', 'C:\\todo> done 6'], ['ok', '✓ #06 완료']] })),
  2: () => cap('명령어 한 줄이면 끝', '#태그 · ! 우선순위 · 기록까지') +
    term([['in', 'add 치과 예약하기 #life !'], ['ok', '+ #08 추가됨'], ['in', 'done 1'], ['ok', '✓ #01 완료'], ['in', 'stats'],
      ['hi', '연속 달성 12일 · 이번 주 23건'], ['cur', '']], 36, 170, W - 72),
  3: () => cap('테마 3종 + 라이트 모드', '') +
    `<div style="position:absolute;top:118px;left:0;right:0;text-align:center">${[['cmd', P.cmd], ['phosphor', P.phosphor], ['amber', P.amber], ['light', P.light]].map(([n, p]) =>
      `<span class="chip" style="background:${p.bg};color:${p.hi};border-color:${p.line};font-size:12px;padding:4px 10px;margin:0 3px">${n}</span>`).join('')}</div>` +
    [P.cmd, P.phosphor, P.amber].map((p, i) => phone(18 + i * 136, 170 + (i === 1 ? -10 : 10), 124, mainScreen(p, { showPro: true, log: [] }))).join(''),
  4: () => cap('잠금화면에서 바로 확인', '홈 화면 · 잠금화면 위젯 (PRO)') + phone((W - 316) / 2, 140, 300, lockScreen(), true),
  5: () => cap('선착순 10명 PRO 무료', '') +
    term([['in', 'upgrade'], ['hi', 'todo.exe PRO'], ['tag', '· 테마 3종 (phosphor · amber · light)'], ['tag', '· CRT 주사선 효과'], ['tag', '· 홈 화면 · 잠금화면 위젯'],
      ['ok', '선착순 10명 무료 코드 → 댓글 달면 DM'], ['cur', '']], 36, 150, W - 72),
};

const BASE = TASKS.slice(0, 6).map(x => ({ ...x }));
const ADD = 'add 분리수거하기 #home !', DONE = 'done 1', STATS = 'stats';
function typed(s, t0, t) { return t < t0 ? '' : s.slice(0, Math.min(s.length, Math.floor((t - t0) / 0.09) + 1)); }
function videoFrame(t) {
  const tasks = BASE.map(x => ({ ...x })), log = [];
  let input = '';
  const blink = Math.floor(t * 2) % 2 === 0;
  if (t >= 3.4) { tasks.push({ n: '#07', t: '분리수거하기', p: 1, g: 'home', d: false }); log.push(['cmd', 'C:\\todo> ' + ADD], ['ok', '+ #07 추가됨']); }
  if (t >= 5.0) { tasks[0].d = true; log.push(['cmd', 'C:\\todo> ' + DONE], ['ok', '✓ #01 완료']); }
  if (t < 3.4) input = typed(ADD, 0.9, t);
  else if (t < 5.0) input = typed(DONE, 4.2, t);
  else if (t < 6.5) input = typed(STATS, 5.8, t);
  const body = t >= 6.5 ? statsScreen(P.cmd) : mainScreen(P.cmd, { showPro: true, tasks, log: log.slice(-3), input });
  let html = `<div class="canvas" style="width:${W}px;height:${H}px">${cap('할 일도 터미널처럼', 'add · done · stats', 30)}${phone((W - 312) / 2, 118, 296, body)}`;
  if (t >= 10.2) {
    const a = Math.min(1, (t - 10.2) / 0.5);
    html += `<div style="position:absolute;inset:0;background:rgba(12,12,12,${0.94 * a});display:flex;flex-direction:column;align-items:center;justify-content:center;opacity:${a}">
      <img src="icon.png" style="width:120px;height:120px;border-radius:28px;box-shadow:0 20px 60px rgba(0,0,0,.6)">
      <div class="mono" style="margin-top:22px;font-size:34px;font-weight:700;color:#F2F2F2">todo.exe<span style="display:inline-block;width:14px;height:28px;background:${G};margin-left:6px;vertical-align:-3px;opacity:${blink ? 1 : 0}"></span></div>
      <div style="margin-top:10px;font-family:NSK,sans-serif;font-size:16px;color:#9A9A9A">App Store 에서 todo.exe 검색</div></div>`;
  }
  return html + '</div>';
}
window.renderVideo = t => { document.getElementById('root').innerHTML = videoFrame(t); };
if (mode === 'video') window.renderVideo(+(q.get('t') || 0));
else document.getElementById('root').innerHTML = `<div class="canvas" style="width:${W}px;height:${H}px">${IMGS[+(q.get('n') || 1)]()}</div>`;
</script>
</body>
</html>
