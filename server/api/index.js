"use strict";
require("dotenv").config();
const express = require("express");
const bodyParser = require("body-parser");

const app = express();
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(express.static("public"));
app.use('/assets', express.static('assets'));

// Add the logging middleware here
app.use((req, res, next) => {
  console.log(`Received a ${req.method} request at ${req.path}`);
  next();
});

// Import your route modules
const userRoutes = require('../routes/user');
const accountsRoutes = require('../routes/accounts');
const plaidRoutes = require('../routes/plaid');
const budgetRoutes = require('../routes/budget');
const twilioRoutes = require('../routes/twilio');

//Session token validation
const { validateSessionToken } = require('../services/userServices');

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

// Use the routes as middleware
app.use('/user', checkSessionToken, userRoutes);
app.use('/accounts', checkSessionToken, accountsRoutes);
app.use('/plaid', checkSessionToken, plaidRoutes.router);
app.use('/budget', checkSessionToken, budgetRoutes);
app.use('/twilio', twilioRoutes);

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

// Export the app object
module.exports = app;