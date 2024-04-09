// Import necessary modules or libraries
const db = require('../db/database.js'); 
const { syncTransactions } = require('../routes/plaid');

// Function to get transactions for a user
exports.getTransactionsForUser = async (req, res, next) => {
    console.log('Getting transactions for user')
    try {
        // Get the user ID from the request parameters
        const userId = req.params.id;

        // Get all items for the user from the database
        const items = await db.getItemsForUser(userId);
        console.log('Items fetched for user', items);

        let allAdded = [];
        let allModified = [];
        let allRemoved = [];

        // Iterate over each item
        for (let currentItem of items) {
            let cursor = currentItem.transaction_cursor || null;
            let hasMore = true;
            let added = [];
            let modified = [];
            let removed = [];

            while (hasMore) {
                // Fetch transactions from Plaid
                const response = await syncTransactions(
                    currentItem.access_token,
                    cursor
                );
                console.log('Transactions fetched from Plaid');

                // Append new transactions to the list
                added = added.concat(response.added);
                modified = modified.concat(response.modified);
                removed = removed.concat(response.removed);

                // Update cursor and hasMore for the next iteration
                cursor = response.next_cursor;
                hasMore = response.has_more;
            }

            // Save transactions and cursor to the database
            let savedTransactions = await db.saveTransactions(userId, currentItem.id, added, modified, removed);
            await db.saveCursor(currentItem.id, cursor);

            // Append transactions to the total list
            allAdded = allAdded.concat(savedTransactions.filter(t => t.is_removed === false));
            allModified = allModified.concat(savedTransactions.filter(t => t.is_removed === false));
            allRemoved = allRemoved.concat(savedTransactions.filter(t => t.is_removed === true));

            // Get transactions with internal account IDs
            allAdded = await getTransactionsWithInternalAccountId(allAdded);
            allModified = await getTransactionsWithInternalAccountId(allModified);
            allRemoved = await getTransactionsWithInternalAccountId(allRemoved);
        }

        console.log('Transactions fetched from Plaid and saved to DB, now responding to client')
        // Return transactions to the client
        res.locals.data = {
            added: allAdded,
            modified: allModified,
            removed: allRemoved
        };
    } catch (error) {
        console.error('Error in getTransactionsForUser', error);
        res.locals.error = error;
    }
    next();
};

//Function to get transactions with internal account IDs
async function getTransactionsWithInternalAccountId(transactions) {
    // Create a new list for the modified transactions
    let modifiedTransactions = [];

    // Iterate over each transaction
    for (let transaction of transactions) {
        // Get the internal account ID for the transaction's Plaid account ID
        let accountId = await db.getInternalAccountId(transaction.plaid_account_id);

        // Replace the transaction's Plaid account ID with the internal account ID
        let modifiedTransaction = {...transaction, account_id: accountId};

        // Add the modified transaction to the new list
        modifiedTransactions.push(modifiedTransaction);
    }

    return modifiedTransactions;
}

// Function to get budget preferences for a user
exports.getBudgetPreferencesForUser = async (req, res, next) => {
    try {
        const preferences = await db.getBudgetPreferences(req.params.id);
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