"use strict";
require("dotenv").config();
const express = require("express");
const bodyParser = require("body-parser");

const APP_PORT = process.env.APP_PORT || 8000;

const app = express();
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(express.static("public"));
app.use('/assets', express.static('assets'));

// Import your route modules
const userRoutes = require('./routes/user');
const accountsRoutes = require('./routes/accounts');
const plaidRoutes = require('./routes/plaid');
const budgetRoutes = require('./routes/budget');
const twilioRoutes = require('./routes/twilio');

//Session token validation
const { validateSessionToken } = require('./services/userServices');

// Use the routes as middleware
app.use('/user', checkSessionToken, userRoutes);
app.use('/accounts', checkSessionToken, accountsRoutes);
app.use('/plaid', checkSessionToken, plaidRoutes.router);
app.use('/budget', checkSessionToken, budgetRoutes);
app.use('/twilio', twilioRoutes);

const server = app.listen(APP_PORT, function () {
  console.log(`Server is up and running at http://localhost:${APP_PORT}/`);
});

const errorHandler = function (err, req, res, next) {
  console.error(`Your error:`);
  console.error(err);
  if (err.response?.data != null) {
    res.status(500).send(err.response.data);
  } else {
    res.status(500).send({
      error_code: "OTHER_ERROR",
      error_message: "I got some other message on the server.",
    });
  }
};
app.use(errorHandler);

async function checkSessionToken(req, res, next) {
  console.log('Received a request');
  
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No session token provided' });
  }

  const sessionToken = authHeader.replace('Bearer ', '');

  const isValid = await validateSessionToken(sessionToken);
  if (!isValid) {
    return res.status(401).json({ message: 'Invalid session token' });
  }

  next();
}
