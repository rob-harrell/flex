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

        // Get all accounts for the user from the database
        const accounts = await db.getUserAccounts(userId);
        console.log('Accounts fetched for user', accounts);

        // Filter the accounts to only include checking, savings, and credit card accounts
        const accountTypes = ["checking", "savings", "credit card"];
        const filteredAccounts = accounts.filter(account => accountTypes.includes(account.sub_type.toLowerCase()));
        console.log('Filtered accounts', filteredAccounts);

        // Create a set of the Plaid account IDs for the filtered accounts
        const filteredAccountIds = new Set(filteredAccounts.map(account => account.plaid_account_id));
        console.log('Filtered account IDs', [...filteredAccountIds]);

        // Create a mapping from Plaid account ID to internal account ID
        const accountIdMapping = {};
        for (let account of filteredAccounts) {
            accountIdMapping[account.plaid_account_id] = account.id;
        }
        console.log('Account ID mapping', accountIdMapping);

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

                // Filter the transactions by account ID

                console.log(`Fetched ${response.added.length} new transactions from Plaid`);
                console.log(`Fetched ${response.modified.length} modified transactions from Plaid`);
                console.log(`Fetched ${response.removed.length} removed transactions from Plaid`);

                response.added = response.added.filter(transaction => filteredAccountIds.has(transaction.account_id));
                response.modified = response.modified.filter(transaction => filteredAccountIds.has(transaction.account_id));
                response.removed = response.removed.filter(transaction => filteredAccountIds.has(transaction.account_id));

                console.log(`${response.added.length} new transactions after filtering`);
                console.log(`${response.modified.length} modified transactions after filtering`);
                console.log(`${response.removed.length} removed transactions after filtering`);

                // Add internal account ID to each transaction and remove payment meta
                response.added = processTransactions(response.added, accountIdMapping);
                response.modified = processTransactions(response.modified, accountIdMapping);
                response.removed = processTransactions(response.removed, accountIdMapping);

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
            allAdded = allAdded.concat(savedTransactions.added);
            allModified = allModified.concat(savedTransactions.modified);
            allRemoved = allRemoved.concat(savedTransactions.removed);
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
}

function processTransactions(transactions, accountIdMapping) {
    const processedTransactions = transactions.map(transaction => {
        // Keep both account_id (Plaid) and internal_account_id
        transaction.plaid_account_id = transaction.account_id;

        const internalAccountId = accountIdMapping[transaction.account_id];
        if (internalAccountId === undefined) {
            console.warn(`No internal account ID mapping found for Plaid account_id: ${transaction.account_id}`);
        }
        transaction.account_id = internalAccountId;
        
        return transaction;
    });

    // Log the number of transactions that have undefined account_id
    const undefinedAccountIdCount = processedTransactions.filter(transaction => transaction.account_id === undefined).length;
    if (undefinedAccountIdCount > 0) {
        console.warn(`${undefinedAccountIdCount} transactions have undefined account_id`);
    }

    return processedTransactions;
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