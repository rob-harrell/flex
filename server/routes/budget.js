const express = require('express');
const router = express.Router();
const budgetServices = require('../services/budgetServices'); // Updated path

// Get transactions for user
router.get('/get_transactions_for_user/:id', budgetServices.getTransactionsForUser, (req, res) => {
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