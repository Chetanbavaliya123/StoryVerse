const sharp = require('sharp');
const fs = require('fs');

async function convert() {
  await sharp('storyverse_icon.svg')
    .resize(1024, 1024)
    .png()
    .toFile('icon_1024.png');

  await sharp('storyverse_icon_fg.svg')
    .resize(1024, 1024)
    .png()
    .toFile('icon_fg_1024.png');

  console.log('Conversion complete!');
}

convert().catch(console.error);
