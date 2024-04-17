const express = require('express');
const router = express.Router();
const budgetServices = require('../services/budgetServices'); // Updated path

// Get new transactions for user from plaid & store in DB
router.get('/get_new_transactions_for_user/:id', budgetServices.getNewTransactionsForUser, (req, res) => {
    res.send(res.locals.data);
});

//Get entire transaction history from DB for users switching devices
router.get('/get_transaction_history_for_account/:id', budgetServices.getTransactionHistoryForAccount, (req, res) => {
    res.send(res.locals.data);
});

// Get budget preferences for user
router.get('/get_budget_preferences_for_user/:id', budgetServices.getBudgetPreferencesForUser, (req, res) => {
    res.send(res.locals.data);
});

// Update budget preferences for user
router.post('/update_budget_preferences_for_user', budgetServices.updateBudgetPreferencesForUser, (req, res) => {
    res.send(res.locals.data);
});

module.exports = router;