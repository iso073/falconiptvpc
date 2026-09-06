abstract final class PhoneRemoteHtml {
  static String page({required String token}) {
    return '''
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <title>Falcon Kumanda</title>
  <style>
    :root { color-scheme: dark; }
    * {
      box-sizing: border-box;
      -webkit-tap-highlight-color: transparent;
      -webkit-touch-callout: none;
      -webkit-user-select: none;
      user-select: none;
      touch-action: none;
    }
    html, body {
      margin: 0; height: 100%; background: #0A0B10; color: #F4F7FF;
      font-family: Segoe UI, Roboto, sans-serif;
      overflow: hidden; overscroll-behavior: none;
    }
    body { display: flex; flex-direction: column; padding: 18px 16px 24px; touch-action: none; }
    h1 { margin: 0; font-size: 22px; letter-spacing: .4px; }
    .sub { color: #A8B0C4; margin: 6px 0 16px; font-size: 13px; }
    .status { min-height: 20px; color: #00F0FF; font-weight: 700; font-size: 13px; margin-bottom: 12px; }
    .pad { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; max-width: 360px; width: 100%; margin: 0 auto 16px; }
    button {
      appearance: none; border: 1.5px solid #33FFFFFF; background: #181B26; color: #F4F7FF;
      border-radius: 16px; min-height: 64px; font-size: 18px; font-weight: 800; letter-spacing: .3px;
      touch-action: none;
    }
    button:active { border-color: #00F0FF; box-shadow: 0 0 16px #00F0FF55; transform: scale(.97); }
    .ok { background: #101325; border-color: #00F0FF; color: #00F0FF; }
    .back { border-color: #B026FF; color: #B026FF; }
    .row { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; max-width: 360px; width: 100%; margin: 0 auto 10px; }
    .wide { grid-column: 1 / -1; }
    .ghost { color: #A8B0C4; font-size: 15px; min-height: 52px; }
  </style>
</head>
<body>
  <h1>Falcon IPTV</h1>
  <div class="sub">Telefon kumandası • Aynı Wi‑Fi</div>
  <div class="status" id="status">Bağlandı</div>
  <div class="pad">
    <span></span>
    <button data-act="up">▲</button>
    <span></span>
    <button data-act="left">◀</button>
    <button class="ok" data-act="ok">OK</button>
    <button data-act="right">▶</button>
    <span></span>
    <button data-act="down">▼</button>
    <span></span>
  </div>
  <div class="row">
    <button class="back" data-act="back">Geri</button>
    <button data-act="play">Oynat</button>
    <button data-act="menu">Menü</button>
    <button class="ghost" data-act="seek_back">-10 sn</button>
    <button class="ghost" data-act="home">Ana menü</button>
    <button class="ghost" data-act="seek_fwd">+10 sn</button>
    <button class="ghost" data-act="ch_down">Kanal −</button>
    <button class="ghost" data-act="vol_down">Ses −</button>
    <button class="ghost" data-act="vol_up">Ses +</button>
    <button class="ghost wide" data-act="ch_up">Kanal +</button>
  </div>
<script>
const token = ${jsonEncodeToken(token)};
const status = document.getElementById('status');
document.addEventListener('gesturestart', (e) => e.preventDefault());
document.addEventListener('gesturechange', (e) => e.preventDefault());
document.addEventListener('gestureend', (e) => e.preventDefault());
document.addEventListener('touchmove', (e) => { if (e.touches.length > 1) e.preventDefault(); }, { passive: false });
let lastTap = 0;
document.addEventListener('touchend', (e) => {
  const now = Date.now();
  if (now - lastTap < 350) e.preventDefault();
  lastTap = now;
}, { passive: false });
async function send(action) {
  try {
    const res = await fetch('/api/key', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ t: token, action })
    });
    const data = await res.json();
    status.textContent = data.ok ? 'Gönderildi: ' + action : (data.error || 'Hata');
  } catch (e) {
    status.textContent = 'PC bağlantısı koptu. Aynı ağda olduğunuzdan emin olunuz.';
  }
}
document.querySelectorAll('button[data-act]').forEach((btn) => {
  const action = btn.getAttribute('data-act');
  btn.addEventListener('click', (e) => { e.preventDefault(); send(action); });
  btn.addEventListener('touchend', (e) => {
    e.preventDefault();
    if (action !== 'ok') send(action);
  });
});
let hold = null;
let okSent = false;
const ok = document.querySelector('[data-act="ok"]');
ok.addEventListener('touchstart', (e) => {
  e.preventDefault();
  okSent = false;
  hold = setTimeout(() => { okSent = true; send('menu'); }, 500);
});
['touchend','touchcancel'].forEach((ev) => {
  ok.addEventListener(ev, (e) => {
    e.preventDefault();
    if (hold) { clearTimeout(hold); hold = null; }
    if (ev === 'touchend' && !okSent) send('ok');
  });
});
ok.addEventListener('mouseup', () => { if (hold) { clearTimeout(hold); hold = null; } });
setInterval(() => fetch('/api/ping?t=' + encodeURIComponent(token)).catch(() => {}), 5000);
</script>
</body>
</html>
''';
  }

  static String jsonEncodeToken(String token) {
    return '"${token.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
  }
}
