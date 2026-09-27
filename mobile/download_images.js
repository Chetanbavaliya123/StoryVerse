const fs = require('fs');
const https = require('https');
const path = require('path');

async function downloadImage(url, dest) {
    return new Promise((resolve, reject) => {
        const file = fs.createWriteStream(dest);
        https.get(url, (response) => {
            if (response.statusCode === 302) {
                // handle redirect
                downloadImage(response.headers.location, dest).then(resolve).catch(reject);
                return;
            }
            response.pipe(file);
            file.on('finish', () => {
                file.close(resolve);
            });
        }).on('error', (err) => {
            fs.unlink(dest, () => reject(err));
        });
    });
}

async function main() {
    const storiesDir = path.join(__dirname, 'assets', 'images', 'stories');
    const adsDir = path.join(__dirname, 'assets', 'images', 'ads');

    // Create 25 story images (400x600)
    for (let i = 1; i <= 25; i++) {
        const id = i.toString().padStart(2, '0');
        const url = `https://picsum.photos/seed/sv${i}/400/600`;
        const dest = path.join(storiesDir, `story_${id}.jpg`);
        console.log(`Downloading ${dest}...`);
        await downloadImage(url, dest);
    }

    // Create 25 story banners (800x400)
    for (let i = 1; i <= 25; i++) {
        const id = i.toString().padStart(2, '0');
        const url = `https://picsum.photos/seed/svb${i}/800/400`;
        const dest = path.join(storiesDir, `story_${id}_banner.jpg`);
        console.log(`Downloading ${dest}...`);
        await downloadImage(url, dest);
    }

    // Create 6 ads (800x400)
    for (let i = 1; i <= 6; i++) {
        const id = i.toString().padStart(2, '0');
        const url = `https://picsum.photos/seed/ad${i}/800/400`;
        const dest = path.join(adsDir, `ad_${id}.jpg`);
        console.log(`Downloading ${dest}...`);
        await downloadImage(url, dest);
    }
}

main().then(() => console.log('Done')).catch(console.error);
