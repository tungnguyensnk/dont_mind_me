const base = '/data/adb/modules/dont_mind_me/webroot/';
const $ = id => document.getElementById(id);
const HARD_KEYS = ['spoof_system', 'spoof_fingerprint', 'spoof_utc', 'spoof_date', 'spoof_os_patch', 'spoof_vendor_patch'];
const FLAGS = ['spoof_system', 'spoof_utc', 'spoof_date', 'spoof_fingerprint', 'spoof_os_patch', 'spoof_vendor_patch'];
const TABS = ['apps', 'spoof', 'keybox', 'system'];
const CHECK = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6 9 17l-5-5"/></svg>';
const CROSS = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M18 6 6 18"/><path d="M6 6l12 12"/></svg>';
const EXT = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h6v6"/><path d="M10 14 21 3"/><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/></svg>';
const REF = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12a9 9 0 1 1-2.64-6.36L21 8"/><path d="M21 3v5h-5"/></svg>';
const SAV = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M15.2 3a2 2 0 0 1 1.4.6l3.8 3.8a2 2 0 0 1 .6 1.4V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z"/><path d="M17 21v-7a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v7"/><path d="M7 3v4a1 1 0 0 0 1 1h7"/></svg>';

// bilingual: default English, Vietnamese only when the system language is Vietnamese
const I18N = {
  en: {
    appsHead: 'Target apps', spoofHead: 'Spoofed properties', certHead: 'Attestation', sysHead: 'System',
    nav: ['Apps', 'Properties', 'Attestation', 'System'],
    searchPh: 'Search package name', count: n => `${n} selected`,
    pLoading: 'Loading…', pSaving: 'Saving…', pError: 'Save failed', pUnsaved: 'Unsaved', pReboot: 'Reboot pending', pSynced: 'Synced',
    sbSaving: 'Saving…', sbErrTitle: 'Save incomplete', sbUnsavedTitle: 'Unsaved changes', sbSavedTitle: 'Saved',
    sbSavedDetail: 'Tap Reboot to apply.', sbSyncHint: 'Lists differ — tap Save to sync.', saveApps: 'Save apps', rebootBtn: 'Reboot',
    dapp: n => `+${n} app${n > 1 ? 's' : ''}`, drem: n => `−${n} app${n > 1 ? 's' : ''}`, dfl: n => `${n} propert${n > 1 ? 'ies' : 'y'}`,
    emptyNoMatch: 'No app found.', emptyNone: 'No user apps.', chipUnsaved: 'Unsaved',
    kbSection: 'Keybox', kbFileLabel: 'Keybox file (XML)', kbSetBtn: 'Set keybox', kbPickPh: 'Choose XML file',
    kbOpenTitle: 'Open keybox page', kbPickFirst: 'Choose an XML file first.', kbUsing: n => `Using ${n}`, kbSetOk: 'Keybox set',
    kbOpenOk: 'Opened keybox page', kbOpenDetail: 'Download the XML then come back here.',
    kbHintPre: 'No keybox yet? Tap ', kbHintPost: ' to download, then choose a .xml file.',
    patchSection: 'Security patch (attestation)', patchLabel: 'Patch date (YYYY-MM-DD)', patchApplyBtn: 'Set patch date',
    patchFetchTitle: 'Fetch latest patch date', patchHintPre: 'Tap ', patchHintPost: ' to fetch the latest patch date.',
    patchFetchOkPre: 'Fetched the latest patch date; tap ', patchFetchOkPost: ' to apply.', patchBad: 'Patch date must be YYYY-MM-01 or YYYY-MM-05.',
    patchSetOk: 'Patch date set', patchSetLine: d => `Set ${d}`,
    usbSection: 'USB debugging', adbSwLabel: 'ADB debugging', notifSection: 'Notifications', notifSwLabel: 'Fix Xiaomi notifications',
    adbName: 'USB debugging', notifName: 'Xiaomi notification fix', on: n => `${n} enabled`, off: n => `${n} disabled`,
    flags: { spoof_system: 'Spoof system properties', spoof_utc: 'Spoof UTC properties', spoof_date: 'Spoof date properties', spoof_fingerprint: 'Spoof fingerprint properties', spoof_os_patch: 'Spoof OS security patch level', spoof_vendor_patch: 'Spoof vendor security patch level' },
    dgDiscardT: 'Discard unsaved changes?', dgDiscardB: 'Discard unsaved changes and refresh?', dgDiscardC: 'Discard & refresh',
    dgRebootT: 'Reboot device?', dgRebootB: 'The app list and properties only take effect after a reboot.', dgRebootC: 'Reboot',
    cancel: 'Cancel', rbTitle: 'Rebooting…', rbDetail: 'Changes take effect once the device finishes booting',
    rbFail: 'Could not reboot automatically. Please reboot manually.',
    pullIdle: 'Pull to refresh', pullRelease: 'Release to refresh', pullLoading: 'Loading list…',
    noRoot: 'Open this WebUI from KernelSU or APatch.', cmdFail: n => `Command failed (${n})`,
    hmaBad: 'Incompatible HMA config; not overwriting existing data.',
    tsFailPre: 'Saved HMA but Tricky Store failed: ', tsFailPost: '. Keep your selection and tap Save to retry.'
  },
  vi: {
    appsHead: 'Ứng dụng mục tiêu', spoofHead: 'Spoof thông số', certHead: 'Chứng thực', sysHead: 'Hệ thống',
    nav: ['Ứng dụng', 'Thông số', 'Chứng thực', 'Hệ thống'],
    searchPh: 'Tìm tên gói ứng dụng', count: n => `${n} đã chọn`,
    pLoading: 'Đang tải…', pSaving: 'Đang lưu…', pError: 'Lỗi khi lưu', pUnsaved: 'Chưa lưu', pReboot: 'Chờ khởi động lại', pSynced: 'Đã đồng bộ',
    sbSaving: 'Đang lưu…', sbErrTitle: 'Lưu chưa xong', sbUnsavedTitle: 'Chưa lưu thay đổi', sbSavedTitle: 'Đã lưu',
    sbSavedDetail: 'Nhấn Khởi động lại để áp dụng.', sbSyncHint: 'Các danh sách đang khác nhau — nhấn Lưu để đồng bộ.', saveApps: 'Lưu ứng dụng', rebootBtn: 'Khởi động lại',
    dapp: n => `+${n} ứng dụng`, drem: n => `−${n} ứng dụng`, dfl: n => `${n} thông số`,
    emptyNoMatch: 'Không tìm thấy ứng dụng.', emptyNone: 'Không có ứng dụng người dùng nào.', chipUnsaved: 'Chưa lưu',
    kbSection: 'Keybox', kbFileLabel: 'Tệp keybox (XML)', kbSetBtn: 'Đặt keybox', kbPickPh: 'Chọn tệp XML',
    kbOpenTitle: 'Mở trang keybox', kbPickFirst: 'Chọn tệp XML trước.', kbUsing: n => `Đang dùng ${n}`, kbSetOk: 'Đã đặt keybox',
    kbOpenOk: 'Đã mở trang keybox', kbOpenDetail: 'Tải tệp XML rồi quay lại đây',
    kbHintPre: 'Chưa có keybox? Ấn ', kbHintPost: ' để tải, rồi chọn tệp .xml.',
    patchSection: 'Bản vá bảo mật (attestation)', patchLabel: 'Ngày bản vá (YYYY-MM-DD)', patchApplyBtn: 'Đặt ngày bản vá',
    patchFetchTitle: 'Lấy ngày bản vá mới nhất', patchHintPre: 'Ấn ', patchHintPost: ' để lấy ngày bản vá mới nhất.',
    patchFetchOkPre: 'Đã lấy ngày bản vá; nhấn ', patchFetchOkPost: ' để đặt.', patchBad: 'Ngày bản vá phải có dạng YYYY-MM-01 hoặc YYYY-MM-05.',
    patchSetOk: 'Đã đặt ngày bản vá', patchSetLine: d => `Đã đặt ${d}`,
    usbSection: 'USB debugging', adbSwLabel: 'ADB debugging', notifSection: 'Thông báo', notifSwLabel: 'Fix thông báo Xiaomi',
    adbName: 'USB debugging', notifName: 'fix thông báo Xiaomi', on: n => `Đã bật ${n}`, off: n => `Đã tắt ${n}`,
    flags: { spoof_system: 'Spoof thông số hệ thống', spoof_utc: 'Spoof thông số UTC', spoof_date: 'Spoof thông số ngày', spoof_fingerprint: 'Spoof fingerprint', spoof_os_patch: 'Spoof mức bản vá bảo mật OS', spoof_vendor_patch: 'Spoof mức bản vá bảo mật vendor' },
    dgDiscardT: 'Bỏ thay đổi chưa lưu?', dgDiscardB: 'Bỏ các thay đổi chưa lưu để làm mới?', dgDiscardC: 'Bỏ và làm mới',
    dgRebootT: 'Khởi động lại thiết bị?', dgRebootB: 'Danh sách ứng dụng và thông số chỉ có hiệu lực sau khi khởi động lại.', dgRebootC: 'Khởi động lại',
    cancel: 'Huỷ', rbTitle: 'Đang khởi động lại…', rbDetail: 'Thay đổi sẽ có hiệu lực khi máy khởi động xong',
    rbFail: 'Không thể khởi động lại tự động. Hãy khởi động lại thủ công.',
    pullIdle: 'Kéo xuống để làm mới', pullRelease: 'Thả để làm mới', pullLoading: 'Đang tải danh sách…',
    noRoot: 'Hãy mở WebUI bằng KernelSU hoặc APatch.', cmdFail: n => `Lệnh thất bại (${n})`,
    hmaBad: 'Cấu hình HMA không tương thích; không ghi đè dữ liệu hiện có.',
    tsFailPre: 'Đã lưu HMA nhưng Tricky Store thất bại: ', tsFailPost: '. Giữ lựa chọn rồi nhấn Lưu để thử lại.'
  }
};
const LANG = (navigator.languages || [navigator.language || 'en']).some(l => /^vi/i.test(l)) ? 'vi' : 'en';
const L = I18N[LANG];

// backend scripts emit short error codes on stderr; translate them here
const ERR = {
  not_installed: { en: 'Module not installed; reboot first.', vi: 'Module chưa cài; hãy khởi động lại trước.' },
  hma_multi: { en: 'Multiple HMA data directories found.', vi: 'Tìm thấy nhiều thư mục dữ liệu HMA.' },
  hma_no_data: { en: 'HMA data not found; reboot first.', vi: 'Không tìm thấy dữ liệu HMA; hãy khởi động lại.' },
  hma_not_ready: { en: 'HMA service is not ready.', vi: 'Dịch vụ HMA chưa sẵn sàng.' },
  ts_no_config: { en: 'Tricky Store config directory not found.', vi: 'Không tìm thấy thư mục cấu hình Tricky Store.' },
  bad_input: { en: 'Invalid input.', vi: 'Dữ liệu đầu vào không hợp lệ.' },
  input_too_big: { en: 'Input too large.', vi: 'Dữ liệu quá lớn.' },
  decode_fail: { en: 'Cannot decode data.', vi: 'Không giải mã được dữ liệu.' },
  empty_config: { en: 'Empty config.', vi: 'Cấu hình trống.' },
  bad_hma: { en: 'Invalid HMA config.', vi: 'Cấu hình HMA không hợp lệ.' },
  label_fail: { en: 'Cannot set SELinux label on the config.', vi: 'Không gán nhãn SELinux cho cấu hình được.' },
  backup_fail: { en: 'Cannot back up the config.', vi: 'Không sao lưu được cấu hình.' },
  save_fail: { en: 'Cannot save the file.', vi: 'Không lưu được tệp.' },
  bad_action: { en: 'Invalid action.', vi: 'Lệnh không hợp lệ.' },
  bad_flags: { en: 'Invalid property config.', vi: 'Cấu hình thông số không hợp lệ.' },
  bad_value: { en: 'Invalid value.', vi: 'Giá trị không hợp lệ.' },
  bad_list: { en: 'The list contains an invalid line.', vi: 'Danh sách chứa dòng không hợp lệ.' },
  browser_fail: { en: 'Could not open the browser.', vi: 'Không mở được trình duyệt.' },
  kb_bad_size: { en: 'Keybox is empty or too large.', vi: 'Keybox trống hoặc quá lớn.' },
  kb_missing_tags: { en: 'Keybox is missing required XML elements.', vi: 'Keybox thiếu thành phần XML bắt buộc.' },
  kb_dtd: { en: 'XML with a DTD/ENTITY declaration is not accepted.', vi: 'Không nhận XML có khai báo DTD/ENTITY.' },
  no_curl: { en: 'Device needs curl with TLS to fetch the Pixel bulletin.', vi: 'Thiết bị cần curl có TLS để lấy bản tin Pixel.' },
  bulletin_fail: { en: 'Could not fetch the Pixel bulletin.', vi: 'Không tải được bản tin Pixel.' },
  patch_fetch_fail: { en: 'Could not read the patch date from the Pixel bulletin.', vi: 'Không đọc được ngày bản vá từ bản tin Pixel.' },
  patch_bad: { en: 'Invalid patch date.', vi: 'Ngày bản vá không hợp lệ.' }
};
const errText = raw => (ERR[raw] && ERR[raw][LANG]) || raw;

let packages = [], selected = new Set(), original = new Set(), lines = [], hma, hardFlags = {}, savedFlags = {};
let dirty = false, busy = false, retry = false, savedScope, needsReboot = false, loading = true, saveError = '', callbackId = 0;
let tab = 0, kbPick = '', kbFile = null, kbSet = '', dialogKind = null, toastTimer, curPull = 0, rebootGuard;

function section(text, name) {
  const start = text.indexOf('===' + name + '===');
  if (start < 0) return '';
  const from = text.indexOf('\n', start) + 1;
  const next = text.indexOf('\n===', from);
  return text.slice(from, next < 0 ? undefined : next);
}
function run(action, service = 'tricky') {
  return new Promise((resolve, reject) => {
    if (!window.ksu || typeof ksu.exec !== 'function') return reject(new Error(L.noRoot));
    const cb = `cb${++callbackId}`;
    window[cb] = (errno, stdout, stderr) => {
      delete window[cb];
      if (errno) { const raw = (stderr || stdout || '').trim(); reject(new Error(raw ? errText(raw) : L.cmdFail(errno))); }
      else resolve(stdout);
    };
    try { ksu.exec(`sh ${base}${service === 'hma' ? 'api' : `${service}-api`}.sh ${action}`, '{}', cb); }
    catch (error) { delete window[cb]; reject(error); }
  });
}

function toast(title, ok = true, detail = '', html = false) {
  clearTimeout(toastTimer);
  const t = $('toast');
  t.classList.toggle('wrong', !ok);
  $('toast-ic').innerHTML = ok ? CHECK : CROSS;
  if (html) $('toast-title').innerHTML = title; else $('toast-title').textContent = title;
  const d = $('toast-detail');
  d.textContent = detail || '';
  d.hidden = !detail;
  t.hidden = false;
  toastTimer = setTimeout(() => { t.hidden = true; }, 3400);
}

function diff() {
  let add = 0, rem = 0;
  selected.forEach(n => { if (!original.has(n)) add++; });
  original.forEach(n => { if (!selected.has(n)) rem++; });
  const fl = HARD_KEYS.filter(k => !!hardFlags[k] !== !!savedFlags[k]).length;
  return { add, rem, fl };
}
function pillState() {
  if (loading) return [L.pLoading, 'var(--kg-hint)'];
  if (busy) return [L.pSaving, 'var(--kg-primary)'];
  if (saveError) return [L.pError, 'var(--kg-danger)'];
  if (dirty) return [L.pUnsaved, 'var(--kg-primary)'];
  if (needsReboot) return [L.pReboot, 'var(--kg-gold)'];
  return [L.pSynced, 'var(--kg-success)'];
}
function showSave(title, detail, action, disabled, err) {
  $('savebar').hidden = false;
  $('save-title').textContent = title;
  $('save-title').classList.toggle('err', !!err);
  $('save-detail').textContent = detail || '';
  const b = $('save-btn');
  b.textContent = action;
  b.disabled = !!disabled;
}
function updateChrome() {
  const [label, dot] = pillState();
  $('pill-label').textContent = label;
  $('pill-dot').style.background = dot;
  $('count').textContent = L.count(selected.size);
  TABS.forEach((name, i) => { $('sub-' + name).hidden = i !== tab; $('tab-' + name).hidden = i !== tab; });
  [...$('nav').children].forEach((b, i) => b.classList.toggle('active', i === tab));

  const d = diff();
  const parts = [];
  if (d.add) parts.push(L.dapp(d.add));
  if (d.rem) parts.push(L.drem(d.rem));
  if (d.fl) parts.push(L.dfl(d.fl));
  const detail = parts.join(' · ');
  if (loading) $('savebar').hidden = true;
  else if (busy) showSave(L.sbSaving, detail, L.saveApps, true, false);
  else if (saveError) showSave(L.sbErrTitle, saveError, L.saveApps, false, true);
  else if (dirty) showSave(L.sbUnsavedTitle, detail || L.sbSyncHint, L.saveApps, false, false);
  else if (needsReboot) showSave(L.sbSavedTitle, L.sbSavedDetail, L.rebootBtn, false, false);
  else $('savebar').hidden = true;

  for (const k of FLAGS) {
    const sw = $('sw-' + k);
    if (sw) sw.checked = !!hardFlags[k];
    const chip = $('chip-' + k);
    if (chip) chip.hidden = loading || !!hardFlags[k] === !!savedFlags[k];
  }
}

function skeleton() {
  const widths = ['62%', '48%', '70%', '55%', '40%', '66%'];
  $('apps').innerHTML = widths.map(w => `<div class="skel"><div class="box"></div><div class="bar" style="width:${w}"></div></div>`).join('');
}
function appRow(name) {
  const row = document.createElement('div');
  row.className = 'approw' + (selected.has(name) ? ' sel' : '');
  const chk = document.createElement('span');
  chk.className = 'check';
  chk.innerHTML = CHECK;
  const pkg = document.createElement('span');
  pkg.className = 'pkg';
  pkg.textContent = name;
  row.append(chk, pkg);
  row.addEventListener('click', () => {
    if (busy) return;
    if (selected.has(name)) selected.delete(name); else selected.add(name);
    row.classList.toggle('sel', selected.has(name));
    markDirty();
  });
  return row;
}
function renderApps() {
  const host = $('apps');
  if (loading) { skeleton(); return; }
  const query = $('search').value.trim().toLowerCase();
  const visible = packages.filter(n => n.toLowerCase().includes(query))
    .sort((a, b) => (selected.has(b) ? 1 : 0) - (selected.has(a) ? 1 : 0));
  host.textContent = '';
  $('search-clear').hidden = !$('search').value;
  if (!visible.length) {
    const empty = document.createElement('div');
    empty.className = 'empty';
    empty.textContent = packages.length ? L.emptyNoMatch : L.emptyNone;
    host.append(empty);
    return;
  }
  const frag = document.createDocumentFragment();
  for (const name of visible) frag.append(appRow(name));
  host.append(frag);
}
function buildFlags() {
  $('flags').innerHTML = FLAGS.map(k =>
    `<div class="swrow"><div class="swtext"><div class="swlabel">${L.flags[k]}</div><span class="chip" id="chip-${k}" hidden>${L.chipUnsaved}</span></div><label class="switch"><input type="checkbox" id="sw-${k}"><span class="slider"></span></label></div>`
  ).join('');
  for (const k of FLAGS) $('sw-' + k).addEventListener('change', () => { hardFlags[k] = $('sw-' + k).checked; markDirty(); });
}

function markDirty() {
  dirty = true; retry = false; savedScope = undefined; needsReboot = false; saveError = '';
  updateChrome();
}

function requestRefresh() {
  if (loading || busy) return;
  if (dirty) openDialog('discard'); else load();
}
async function load() {
  busy = true; loading = true; saveError = '';
  setPullLoading(true); updateChrome(); renderApps();
  try {
    const bundle = await run('bundle', 'hma');
    const list = section(bundle, 'LIST');
    const text = section(bundle, 'TARGETS');
    const next = JSON.parse(section(bundle, 'HMA') || 'null');
    if (!next || next.configVersion !== 93 || !next.scope || typeof next.scope !== 'object' || Array.isArray(next.scope)) throw new Error(L.hmaBad);
    const hard = section(bundle, 'HARD');
    for (const k of HARD_KEYS) hardFlags[k] = new RegExp('(^|\\n)' + k + '=1').test(hard);
    savedFlags = { ...hardFlags };
    $('adb-toggle').checked = section(bundle, 'ADB').trim() === '1';
    $('notify-toggle').checked = section(bundle, 'NOTIFY').trim() === '1';
    const names = list.split('\n').map(v => v.trim()).filter(v => /^[a-zA-Z0-9_.]+$/.test(v)).sort();
    const targetLines = text.split('\n');
    const targets = new Set(targetLines.map(line => line.trim().replace(/[!?]$/, '')).filter(name => names.includes(name)));
    const whitelisted = new Set(names.filter(name => next.scope[name]?.useWhitelist === true));
    hma = next; packages = names; lines = targetLines;
    original = new Set([...targets, ...whitelisted]);
    selected = new Set(original);
    retry = false; savedScope = undefined; needsReboot = false;
    dirty = names.some(name => targets.has(name) !== whitelisted.has(name));
  } catch (error) {
    packages = []; selected = new Set(); original = new Set();
    toast(error.message, false);
  } finally {
    loading = false; busy = false;
    setPullLoading(false); updateChrome(); renderApps();
  }
}
async function persist() {
  if (busy || !dirty) return;
  busy = true; saveError = '';
  updateChrome();
  try {
    const kept = lines.filter(line => !packages.includes(line.trim().replace(/[!?]$/, '')) || selected.has(line.trim().replace(/[!?]$/, '')));
    const existing = new Set(kept.map(line => line.trim().replace(/[!?]$/, '')));
    const added = [...selected].filter(name => !existing.has(name)).sort();
    const next = [...kept, ...added].join('\n').replace(/\n*$/, '\n');
    const scope = { ...hma.scope };
    for (const name of packages) {
      if (selected.has(name)) scope[name] = { ...scope[name], useWhitelist: true, excludeSystemApps: true };
      else if (scope[name]?.useWhitelist === true) delete scope[name];
    }
    const encoded = value => btoa(unescape(encodeURIComponent(value)));
    await run(`save ${encoded(HARD_KEYS.map(k => `${k}=${hardFlags[k] ? 1 : 0}`).join('\n') + '\n')}`, 'hard');
    if (!retry) {
      await run(`save ${encoded(JSON.stringify({ ...hma, scope }))}`, 'hma');
      savedScope = scope;
    }
    try { await run(`save ${encoded(next)}`); }
    catch (error) {
      retry = true;
      saveError = L.tsFailPre + error.message + L.tsFailPost;
      return;
    }
    hma.scope = savedScope; savedScope = undefined;
    lines = next.split('\n');
    original = new Set(selected);
    savedFlags = { ...hardFlags };
    retry = false; dirty = false; needsReboot = true;
  } catch (error) {
    saveError = error.message;
  } finally {
    busy = false; updateChrome();
  }
}
async function startReboot() {
  closeDialog();
  $('reboot').hidden = false;
  clearTimeout(rebootGuard);
  rebootGuard = setTimeout(() => { $('reboot').hidden = true; toast(L.rbFail, false); }, 12000);
  try { await run('reboot', 'hard'); }
  catch (error) { /* device going down can drop the callback */ }
}

function openDialog(kind) {
  dialogKind = kind;
  const d = kind === 'reboot'
    ? { title: L.dgRebootT, body: L.dgRebootB, confirm: L.dgRebootC }
    : { title: L.dgDiscardT, body: L.dgDiscardB, confirm: L.dgDiscardC };
  $('dlg-title').textContent = d.title;
  $('dlg-body').textContent = d.body;
  $('dlg-confirm').textContent = d.confirm;
  $('dialog').hidden = false;
}
function closeDialog() { dialogKind = null; $('dialog').hidden = true; }

function setTab(i) {
  tab = i;
  scrollTo(0, 0);
  updateChrome();
  if (i === 0) renderApps();
}

// keybox — pick any .xml via the system file picker, send its contents to set-keybox
function setKbText() {
  const el = $('kb-box-text');
  el.className = kbPick ? 'val' : 'ph';
  el.textContent = kbPick || L.kbPickPh;
}
async function readB64(file) {
  const bytes = new Uint8Array(await file.arrayBuffer());
  let s = ''; const C = 0x8000;
  for (let i = 0; i < bytes.length; i += C) s += String.fromCharCode.apply(null, bytes.subarray(i, i + C));
  return btoa(s);
}
async function setKeybox() {
  if (!kbFile) return toast(L.kbPickFirst, false);
  $('kb-set').style.opacity = '.5';
  try {
    await run('set-keybox ' + await readB64(kbFile));
    kbSet = kbPick;
    $('kb-setline').textContent = L.kbUsing(kbSet);
    $('kb-setline').hidden = false;
    toast(L.kbSetOk, true, kbSet);
  } catch (error) { toast(error.message, false); }
  finally { $('kb-set').style.opacity = ''; }
}

// patch
function onPatch() {
  const el = $('patch');
  const digits = el.value.replace(/\D/g, '').slice(0, 8);
  el.value = digits.slice(0, 4) + (digits.length > 4 ? '-' + digits.slice(4, 6) : '') + (digits.length > 6 ? '-' + digits.slice(6, 8) : '');
  el.classList.remove('err');
  $('patch-err').hidden = true;
}
async function fetchPatch() {
  $('patch-fetch').style.opacity = '.5';
  try {
    $('patch').value = (await run('patch')).trim();
    $('patch').classList.remove('err');
    $('patch-err').hidden = true;
    toast(L.patchFetchOkPre + SAV + L.patchFetchOkPost, true, '', true);
  } catch (error) { toast(error.message, false); }
  finally { $('patch-fetch').style.opacity = ''; }
}
async function applyPatch() {
  const date = $('patch').value.trim();
  if (!/^20\d{2}-(0[1-9]|1[0-2])-0[15]$/.test(date)) {
    $('patch').classList.add('err');
    $('patch-err').textContent = L.patchBad;
    $('patch-err').hidden = false;
    $('patch-ok').hidden = true;
    return;
  }
  $('patch-apply').style.opacity = '.5';
  try {
    await run(`set-patch ${date}`);
    $('patch-ok').textContent = L.patchSetLine(date);
    $('patch-ok').hidden = false;
    toast(L.patchSetOk, true, date);
  } catch (error) { toast(error.message, false); }
  finally { $('patch-apply').style.opacity = ''; }
}

async function toggleSys(id, action, label) {
  const el = $(id);
  const on = el.checked;
  el.disabled = true;
  try { await run(`${action} ${on ? 1 : 0}`, 'hard'); toast(on ? L.on(label) : L.off(label)); }
  catch (error) { el.checked = !on; toast(error.message, false); }
  finally { el.disabled = false; }
}

// pull to refresh
function setPull(h, animate) {
  const el = $('pull');
  el.classList.toggle('drag', !animate);
  el.style.height = h + 'px';
  el.style.opacity = Math.min(h / 40, 1);
  curPull = h;
  $('pull-pill').textContent = h >= 64 ? L.pullRelease : L.pullIdle;
}
function setPullLoading(on) {
  const el = $('pull');
  el.classList.remove('drag');
  if (on) { el.style.height = '44px'; el.style.opacity = '1'; $('pull-pill').textContent = L.pullLoading; }
  else { el.style.height = '0'; el.style.opacity = '0'; }
}

function applyLang() {
  document.documentElement.lang = LANG;
  for (const el of document.querySelectorAll('[data-i18n]')) el.textContent = L[el.dataset.i18n];
  $('search').placeholder = L.searchPh;
  $('pull-pill').textContent = L.pullIdle;
  $('kb-hint').innerHTML = L.kbHintPre + EXT + L.kbHintPost;
  $('patch-hint').innerHTML = L.patchHintPre + REF + L.patchHintPost;
  $('kb-open').title = L.kbOpenTitle; $('kb-open').setAttribute('aria-label', L.kbOpenTitle);
  $('kb-set').title = L.kbSetBtn; $('kb-set').setAttribute('aria-label', L.kbSetBtn);
  $('patch-fetch').title = L.patchFetchTitle; $('patch-fetch').setAttribute('aria-label', L.patchFetchTitle);
  $('patch-apply').title = L.patchApplyBtn; $('patch-apply').setAttribute('aria-label', L.patchApplyBtn);
  [...$('nav').children].forEach((b, i) => b.textContent = L.nav[i]);
  setKbText();
}

// wiring
applyLang();
buildFlags();
$('search').addEventListener('input', renderApps);
$('search-clear').addEventListener('click', () => { $('search').value = ''; renderApps(); });
[...$('nav').children].forEach((b, i) => b.addEventListener('click', () => setTab(i)));
$('save-btn').addEventListener('click', () => { if (!dirty && needsReboot && !busy) openDialog('reboot'); else persist(); });
$('adb-toggle').addEventListener('change', () => toggleSys('adb-toggle', 'adbset', L.adbName));
$('notify-toggle').addEventListener('change', () => toggleSys('notify-toggle', 'notifyset', L.notifName));
$('kb-box').addEventListener('click', () => $('kb-file').click());
$('kb-file').addEventListener('change', e => { const f = e.target.files && e.target.files[0]; if (f) { kbFile = f; kbPick = f.name; setKbText(); } });
$('kb-open').addEventListener('click', async () => { try { await run('open-keybox'); toast(L.kbOpenOk, true, L.kbOpenDetail); } catch (error) { toast(error.message, false); } });
$('kb-set').addEventListener('click', setKeybox);
$('patch').addEventListener('input', onPatch);
$('patch-fetch').addEventListener('click', fetchPatch);
$('patch-apply').addEventListener('click', applyPatch);
$('dlg-cancel').addEventListener('click', closeDialog);
$('dialog').addEventListener('click', e => { if (e.target === $('dialog')) closeDialog(); });
$('dlg-confirm').addEventListener('click', () => { if (dialogKind === 'reboot') startReboot(); else { closeDialog(); load(); } });

let pullStartY = null;
addEventListener('touchstart', e => { pullStartY = (scrollY <= 0 && !loading && !busy && !dialogKind) ? e.touches[0].clientY : null; }, { passive: true });
addEventListener('touchmove', e => { if (pullStartY == null) return; const dy = e.touches[0].clientY - pullStartY; if (dy > 0) setPull(Math.min(dy * 0.5, 96), false); }, { passive: true });
addEventListener('touchend', () => { if (pullStartY == null) return; const go = curPull >= 64; pullStartY = null; setPull(0, true); if (go) requestRefresh(); }, { passive: true });

setTab(0);
load();
