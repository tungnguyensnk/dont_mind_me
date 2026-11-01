const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const code = fs.readFileSync(__dirname + '/webroot/app.js', 'utf8');
const elements = new Map();
function element() {
  return {
    value: '', checked: false, disabled: false, hidden: false, innerHTML: '', textContent: '',
    placeholder: '', title: '', dataset: {}, children: [], style: {},
    classList: { add() {}, remove() {}, toggle() {}, contains() { return false; } },
    addEventListener(name, callback) { this[name] = callback; },
    setAttribute() {}, append(...items) { this.children.push(...items); },
    replaceChildren(...items) { this.children = items; },
  };
}
const document = {
  getElementById(id) { if (!elements.has(id)) elements.set(id, element()); return elements.get(id); },
  createElement: element, createDocumentFragment: element,
  querySelectorAll() { return []; }, documentElement: { dataset: {} },
};
const calls = [];
let rebooted = false;
let hma = { configVersion: 93, scope: { 'app.one': { useWhitelist: true }, 'unrelated.app': { useWhitelist: false } } };
let targets = '# keep\napp.two!\n';
let hard = ['spoof_system','spoof_fingerprint','spoof_utc','spoof_date','spoof_os_patch','spoof_vendor_patch'].map(k => k + '=1').join('\n') + '\n';
let adbState = 0, notifyState = 0;
const context = {
  document,
  navigator: { language: 'vi', languages: ['vi'] },
  window: { scrollY: 0, addEventListener() {}, scrollTo() {} },
  addEventListener() {}, scrollTo() {}, scrollY: 0,
  setTimeout, clearTimeout, setInterval, clearInterval,
  btoa: str => Buffer.from(str, 'binary').toString('base64'),
  atob: str => Buffer.from(str, 'base64').toString('binary'),
  unescape, escape, encodeURIComponent, decodeURIComponent,
  ksu: { exec(command, _, callback) {
    const service = command.includes('/hard-api.sh') ? 'hard' : command.includes('/tricky-api.sh') ? 'tricky' : 'hma';
    const action = command.split(' ').slice(-2);
    let output = '', error = 0;
    if (command.endsWith(' bundle')) output = '===LIST===\napp.one\napp.two\napp.three\n' +
      '===TARGETS===\n' + targets + '===HMA===\n' + JSON.stringify(hma) +
      '\n\n===HARD===\n' + hard + '\n===ADB===\n' + adbState + '\n===NOTIFY===\n' + notifyState + '\n';
    else if (action[0] === 'adbset') { adbState = Number(action[1]); output = 'ok'; }
    else if (action[0] === 'notifyset') { notifyState = Number(action[1]); output = 'ok'; }
    else if (command.endsWith(' reboot')) rebooted = true;
    else if (action[0] === 'save') {
      calls.push(service);
      if (service === 'hma') hma = JSON.parse(Buffer.from(action[1], 'base64').toString());
      else if (service === 'hard') hard = Buffer.from(action[1], 'base64').toString();
      else targets = Buffer.from(action[1], 'base64').toString();
    }
    setImmediate(() => context.window[callback](error, output, ''));
  } },
};
context.window.ksu = context.ksu;
vm.createContext(context);
vm.runInContext(code, context);
const tick = () => new Promise(resolve => setTimeout(resolve, 10));

(async () => {
  await tick();
  assert.equal(elements.get('count').textContent, '2 đã chọn', 'app.one + app.two selected');
  for (const k of ['spoof_system','spoof_os_patch','spoof_vendor_patch']) assert.equal(elements.get('sw-' + k).checked, true, k + ' on');
  assert.equal(elements.get('adb-toggle').checked, false, 'adb off');
  // adb toggle immediate
  elements.get('adb-toggle').checked = true; elements.get('adb-toggle').change();
  await tick();
  assert.equal(adbState, 1, 'adb enabled immediately');
  // sync + save (lists differ: app.one whitelisted but not target)
  assert.equal(elements.get('save-btn').disabled, false, 'differing lists need save');
  elements.get('save-btn').click();
  await tick();
  assert.deepEqual(calls, ['hard', 'hma', 'tricky'], 'saves hard, hma, tricky');
  assert.equal(elements.get('save-btn').textContent, 'Khởi động lại', 'save becomes restart');
  // toggle a spoof off, save again
  const sb = elements.get('sw-spoof_os_patch'); sb.checked = false; sb.change();
  assert.equal(elements.get('save-btn').disabled, false, 'toggle marks dirty');
  elements.get('save-btn').click();
  await tick();
  assert.equal(/spoof_os_patch=0/.test(hard), true, 'spoof_os_patch off written');
  assert.equal(/spoof_system=1/.test(hard), true, 'spoof_system stays on');
  // restart button opens a confirm dialog, then confirming reboots
  assert.equal(elements.get('save-btn').textContent, 'Khởi động lại');
  assert.equal(rebooted, false);
  elements.get('save-btn').click();
  assert.equal(elements.get('dialog').hidden, false, 'reboot asks for confirmation first');
  elements.get('dlg-confirm').click();
  await tick();
  assert.equal(rebooted, true, 'confirming restart reboots');
  console.log('dont_mind_me WebUI: app picker (HMA+Tricky), 6 spoof switches, adb toggle, save->confirm->restart OK');
})().catch(error => { console.error(error); process.exitCode = 1; });
