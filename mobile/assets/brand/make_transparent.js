const fs = require('fs');
// 1x1 transparent PNG base64
const transparentPngBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
fs.writeFileSync('transparent.png', Buffer.from(transparentPngBase64, 'base64'));
console.log('Created transparent.png');
