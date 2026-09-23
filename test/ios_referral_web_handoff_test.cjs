const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const html = fs.readFileSync('web/index.html', 'utf8');
const script = html.match(/<script>\s*([\s\S]*?)<\/script>/)[1];
function page({ua = 'iPhone', path = '/register', query = '?referralCode=A%2BB%26%2525', copy} = {}) {
  const redirects = [], children = [], writes = [];
  const window = { navigator: {userAgent: ua, clipboard: {writeText(text) {
    writes.push(text); return copy ? copy(text) : Promise.resolve();
  }}}, location: {pathname: path, search: query, hash: '',
    replace(url) {redirects.push(url)}, assign(url) {redirects.push(url)}}};
  const document = {body: {appendChild(child) {children.push(child)}},
    createElement(tag) {return {tag, style: {}, setAttribute() {}, append(...items) {this.children = items}}}};
  vm.runInNewContext(script, {window, document, URLSearchParams});
  return {redirects, children, writes};
}
test('iOS waits for user gesture and successful copy before App Store', async () => {
  let complete;
  const p = page({copy: () => new Promise(resolve => complete = resolve)});
  assert.equal(p.redirects.length, 0);
  assert.equal(p.writes.length, 0);
  const button = p.children[0].children[2];
  const clicked = button.onclick();
  assert.equal(p.redirects.length, 0);
  assert.equal(p.writes[0], 'https://filmytell.com/register?referralCode=A%2BB%26%2525');
  complete(); await clicked;
  assert.match(p.redirects[0], /apps.apple.com/);
});
test('copy denied stays on page with retry and explicit fallback', async () => {
  const p = page({copy: () => Promise.reject(new Error('denied'))});
  await p.children[0].children[2].onclick();
  assert.equal(p.redirects.length, 0);
  assert.equal(p.children[0].children[2].disabled, false);
  assert.match(p.children[0].children[3].textContent, /Could not copy/);
});
test('normal iOS launch and content links do not offer referral handoff', () => {
  const p = page({path: '/movie/6', query: ''});
  assert.equal(p.children.length, 0);
  assert.equal(p.redirects.length, 0);
});
test('empty referral preserves store fallback', () => {
  assert.match(page({query: ''}).redirects[0], /apps.apple.com/);
});
test('Android retains its existing Play Store referrer', () => {
  const p = page({ua: 'Android'});
  assert.match(p.redirects[0], /play.google.com/);
  assert.equal(p.writes.length, 0);
});
