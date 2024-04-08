// Import necessary modules or libraries
const db = require('../db/database.js'); 
const { plaidConfig } = require('../routes/plaid.js');

// Function to get transactions for a user
exports.getTransactionsForUser = async (req, res, next) => {
    try {
        // Get all items for the user from the database
        const items = await db.getItemsForUser(req.user.id);

        let allAdded = [];
        let allModified = [];
        let allRemoved = [];

        // Iterate over each item
        for (let item of items) {
            let cursor = item.cursor;
            let hasMore = true;
            let added = [];
            let modified = [];
            let removed = [];

            while (hasMore) {
                // Fetch transactions from Plaid
                const response = await plaidConfig.syncTransactions(
                    item.accessToken,
                    cursor
                );

                // Append new transactions to the list
                added = added.concat(response.data.added);
                modified = modified.concat(response.data.modified);
                removed = removed.concat(response.data.removed);

                // Update cursor and hasMore for the next iteration
                cursor = response.data.next_cursor;
                hasMore = response.data.has_more;
            }

            // Save transactions and cursor to the database
            await db.saveTransactions(req.user.id, item.id, added, modified, removed);
            await db.saveCursor(item.id, cursor);

            // Append transactions to the total list
            allAdded = allAdded.concat(added);
            allModified = allModified.concat(modified);
            allRemoved = allRemoved.concat(removed);
        }

        // Return transactions to the client
        res.locals.data = allAdded;
    } catch (error) {
        res.locals.error = error;
    }
    next();
};

// Function to get budget preferences for a user
exports.getBudgetPreferencesForUser = async (req, res, next) => {
    try {
        const preferences = await db.getBudgetPreferences(req.user.id);
        res.locals.data = preferences;
    } catch (error) {
        res.locals.error = error;
    }
    next();
};

// Function to update budget preferences for a user
exports.updateBudgetPreferencesForUser = async (req, res, next) => {
    try {
        await db.updateBudgetPreferences(req.user.id, req.body);
        res.locals.data = { message: 'Budget preferences updated successfully' };
    } catch (error) {
        res.locals.error = error;
    }
    next();
};