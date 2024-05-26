const { put } = require('@vercel/blob');

async function saveImage(base64String, type) {
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
}

module.exports = { saveImage };