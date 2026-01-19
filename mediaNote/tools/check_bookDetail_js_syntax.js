const fs = require('fs');
const vm = require('vm');
const path = require('path');
const file = path.resolve(__dirname, '..', 'src', 'main', 'webapp', 'bookDetail.jsp');
const s = fs.readFileSync(file, 'utf8');
// Heuristic: find the last <script>...</script> block
const re = /<script[^>]*>([\s\S]*?)<\/script>/gi;
let match, last = null, idx = 0;
while ((match = re.exec(s)) !== null) {
  last = { code: match[1], index: match.index, matchIndex: ++idx };
}
if (!last) {
  console.error('No <script> block found in', file);
  process.exit(2);
}
console.log('Found script block number', last.matchIndex, 'at index', last.index);
const code = last.code;
try {
  // Try to compile it
  new vm.Script(code);
  console.log('JS: syntax OK (compiled)');
  process.exit(0);
} catch (err) {
  console.error('JS Syntax Error:', err && err.message);
  console.error(err.stack);
  process.exit(1);
}