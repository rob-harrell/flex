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
const transactionsRoutes = require('./routes/transactions');
const budgetRoutes = require('./routes/budget');
const webhookRoutes = require('./routes/webhook');

// Use the routes as middleware
app.use('/user', userRoutes);
app.use('/accounts', accountsRoutes);
app.use('/plaid', plaidRoutes);
app.use('/transactions', transactionsRoutes);
app.use('/budget', budgetRoutes);
app.use('/webhook', webhookRoutes);

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
