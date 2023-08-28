const express = require('express');
const multer = require('multer');
const AWS = require('aws-sdk');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();
const cors = require('cors');
const sharp = require('sharp'); // Import the sharp library

const app = express();
const upload = multer({ dest: 'uploads/' });
app.use(cors());

// Configure AWS SDK
AWS.config.update({
  region: process.env.AWS_REGION
});

const s3 = new AWS.S3();
const fs = require('fs');

app.get('/health', (req, res) => {
    res.status(200).json({ message: 'Server is healthy' });
  });
app.post('/upload', upload.single('image'), (req, res) => {
  const file = req.file;

  console.log('file:', file); // Check the file object

  if (!file) {
    res.status(400).send('No file received');
    return;
  }

  // Use sharp to resize the image to 500x500 pixels
  sharp(file.path)
    .resize(500, 500)
    .toFile(`${file.path}_resized`, (err, info) => {
      if (err) {
        console.error('Image Resize Error', err);
        res.status(500).send('Error resizing image');
        return;
      }

      const resizedImageStream = fs.createReadStream(`${file.path}_resized`);
      resizedImageStream.on('error', function (err) {
        console.error('Resized Image File Error', err);
      });

      const params = {
        Bucket: process.env.S3_BUCKET_NAME,
        Key: `${uuidv4()}-${file.originalname}`,
        Body: resizedImageStream
      };

      // Upload the resized image to S3
      s3.upload(params, (uploadErr, data) => {
        if (uploadErr) {
          console.error(uploadErr);
          res.status(500).send('Error uploading image');
        } else {
          console.log('Image uploaded successfully');
          res.status(200).send('Image uploaded');
        }

        // Clean up the temporary files
        fs.unlink(file.path, (err) => {
          if (err) console.log(err);
        });

        fs.unlink(`${file.path}_resized`, (err) => {
          if (err) console.log(err);
        });
      });
    });
});

const port = process.env.PORT || 5000;

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
