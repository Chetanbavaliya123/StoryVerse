const fs = require('fs');
const path = require('path');

function walk(dir) {
  let results = [];
  const list = fs.readdirSync(dir);
  list.forEach(function(file) {
    file = path.join(dir, file);
    const stat = fs.statSync(file);
    if (stat && stat.isDirectory()) {
      results = results.concat(walk(file));
    } else {
      if (file.endsWith('.dart')) results.push(file);
    }
  });
  return results;
}

const files = walk('lib');
let converted = 0;
files.forEach(file => {
  const buffer = fs.readFileSync(file);
  // check for UTF-16 LE BOM (FF FE) or UTF-16 BE BOM (FE FF)
  let isUtf16 = false;
  if (buffer.length >= 2 && buffer[0] === 0xFF && buffer[1] === 0xFE) {
    isUtf16 = true;
  } else if (buffer.length > 4) {
    // Check if every other byte is 0 (UTF-16 LE without BOM)
    let zeroCount = 0;
    for (let i = 1; i < Math.min(buffer.length, 40); i += 2) {
      if (buffer[i] === 0) zeroCount++;
    }
    if (zeroCount > 10) isUtf16 = true;
  }
  
  if (isUtf16) {
    try {
      // Node's utf16le handles both BOM and no-BOM (assumes LE)
      let text = buffer.toString('utf16le');
      // Strip BOM if present
      if (text.charCodeAt(0) === 0xFEFF) {
        text = text.substring(1);
      }
      
      console.log('Converting', file);
      fs.writeFileSync(file, text, 'utf8');
      converted++;
    } catch (e) {
      console.log('Error converting', file, e);
    }
  }
});
console.log('Converted', converted, 'files.');
