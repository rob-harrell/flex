const fs = require('fs').promises;
const path = require('path');
const { v4: uuidv4 } = require('uuid');

async function saveImage(base64String) {
  try {
    const imgData = Buffer.from(base64String, 'base64');

    const filename = `${uuidv4()}.png`;

    const directory = path.join('./assets', 'institution_logos');

    const filePath = path.join(directory, filename);

    await fs.writeFile(filePath, imgData);

    return filename;  // return only the filename
  } catch (error) {
    console.error('Failed to save image:', error);
    throw error;

  }
}

module.exports = { saveImage };