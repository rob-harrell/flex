const { put } = require('@vercel/blob');
const { v4: uuidv4 } = require('uuid');
const path = require('path');

async function saveImage(base64String, type) {
  // Local development logo path
  const localLogoPath = path.join(__dirname, '../assets/institution_logos/default_logo.png');
  // Local development logo URL
  const localLogoUrl = `http://localhost:3000/assets/institution_logos/default_logo.png`;

  if (process.env.VERCEL) { // Check if running on Vercel
    try {
      const imgData = Buffer.from(base64String, 'base64');
      const filename = `${type}/${uuidv4()}.png`;

      // Upload the image data as a blob
      const blob = await put(filename, imgData, {
        access: 'public',
      });
      // Return the blob URL instead of the filename
      return blob.url;
    } catch (error) {
      console.error('Failed to save image:', error);
      throw error;
    }
  } else {
    // For local development, return the local logo URL
    console.log(`Using local logo URL for ${type}: ${localLogoUrl}`);
    return localLogoUrl;
  }
}

module.exports = { saveImage };