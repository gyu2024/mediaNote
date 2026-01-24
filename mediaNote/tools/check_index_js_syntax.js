const fs = require('fs');
const path = require('path');
const p = path.join(__dirname, '..', 'src', 'main', 'webapp', 'index.jsp');
try {
  const s = fs.readFileSync(p, 'utf8');
  const scriptStart = s.indexOf('<script');
  if (scriptStart === -1) { console.error('NO_SCRIPT_TAG'); process.exit(2); }
  const startTagEnd = s.indexOf('>', scriptStart);
  if (startTagEnd === -1) { console.error('NO_SCRIPT_CLOSE_TAG'); process.exit(2); }
  const end = s.indexOf('</script>', startTagEnd);
  if (end === -1) { console.error('NO_SCRIPT_END'); process.exit(2); }
  const script = s.substring(startTagEnd+1, end);
  // Try to compile
  try {
    new Function(script);
    console.log('PARSE_OK');
  } catch (e) {
    console.error('PARSE_ERROR');
    console.error(e && e.stack ? e.stack : String(e));
    process.exit(1);
  }
} catch (e) {
  console.error('READ_ERROR', e && e.stack ? e.stack : String(e));
  process.exit(2);
}
