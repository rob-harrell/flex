// Import necessary modules or libraries
const db = require('../db/database.js'); 
const { syncTransactions } = require('../routes/plaid');
const fs = require('fs');
const path = require('path');

// Construct the path to the MerchantNameLogoMappings.json file
const merchantFilePath = path.join(process.cwd(), 'MerchantNameLogoMappings.json');

// Read the MerchantNameLogoMappings.json file
const merchant_mappings_array = JSON.parse(fs.readFileSync(merchantFilePath, 'utf8'));

const merchant_mappings = merchant_mappings_array.reduce((acc, item) => {
    for (const keyword of item.keywords) {
        acc[keyword] = {
            name: item.name,
            logo: item.logo
        };
    }
    return acc;
}, {});

// Construct the path to the DefaultBudgetPreferences.json file
const categoryFilePath = path.join(process.cwd(), 'DefaultBudgetPreferences.json');

// Read the DefaultBudgetPreferences.json file
const category_mappings_array = JSON.parse(fs.readFileSync(categoryFilePath, 'utf8'));

const category_mappings = category_mappings_array.reduce((acc, item) => {
    const key = `${item.category}_${item.subCategory}`;
    acc[key] = {
        productCategory: item.productCategory,
        budgetCategory: item.budgetCategory
    };
    return acc;
}, {});


// Function to get transactions for a user
exports.getNewTransactionsForUser = async (req, res, next) => {
    console.log('Getting transactions for user')
    try {
        // Get the user ID from the request parameters
        const userId = req.params.id;

        // Get all items for the user from the database
        const items = await db.getItemsForUser(userId);

        // Get all accounts for the user from the database
        const accounts = await db.getUserAccounts(userId);

        // Filter the accounts to only include checking, savings, and credit card accounts
        const accountTypes = ["checking", "savings", "credit card"];
        const filteredAccounts = accounts.filter(account => accountTypes.includes(account.sub_type.toLowerCase()));

        // Create a set of the Plaid account IDs for the filtered accounts
        const filteredAccountIds = new Set(filteredAccounts.map(account => account.plaid_account_id));

        // Create a mapping from Plaid account ID to internal account ID
        const accountIdMapping = {};
        for (let account of filteredAccounts) {
            accountIdMapping[account.plaid_account_id] = account.id;
        }

        let allAdded = [];
        let allModified = [];
        let allRemoved = [];

        // Iterate over each item
        for (let currentItem of items) {        
            // Fetch transactions from Plaid
            const response = await syncTransactions(
                currentItem.access_token,
                currentItem.transaction_cursor || null
            );
        
            // Filter the transactions by account ID
            response.added = response.added.filter(transaction => filteredAccountIds.has(transaction.account_id));
            response.modified = response.modified.filter(transaction => filteredAccountIds.has(transaction.account_id));
            response.removed = response.removed.filter(transaction => filteredAccountIds.has(transaction.account_id));
        
            // Add internal account ID to each transaction and remove payment meta
            response.added = processTransactions(response.added, accountIdMapping);
            response.modified = processTransactions(response.modified, accountIdMapping);
        
            // Save transactions and cursor to the database
            let savedTransactions = await db.saveTransactions(userId, currentItem.id, response.added, response.modified, response.removed);
            
            await db.saveCursor(currentItem.id, response.next_cursor);
        
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
        //console.log(`Processing ${transactions.length} transactions. First transaction:`, transactions);
        // Keep both account_id (Plaid) and internal_account_id
        transaction.plaid_account_id = transaction.account_id;

        const internalAccountId = accountIdMapping[transaction.account_id];
        if (internalAccountId === undefined) {
            console.warn(`No internal account ID mapping found for Plaid account_id: ${transaction.account_id}`);
        }
        transaction.account_id = internalAccountId;

        // Clean merchant name
        if (!transaction.merchant_name) {
            const keywords = transaction.name.toLowerCase().split(' ');
            for (const keyword of keywords) {
                if (merchant_mappings[keyword]) {
                    transaction.merchant_name = merchant_mappings[keyword].name;
                    transaction.logo_url = merchant_mappings[keyword].logo;
                    break;
                }
            }
        }

        // Handle payment app transactions
        if (transaction.merchant_name === 'Venmo' || transaction.merchant_name === 'Zelle') {
            transaction.product_category = 'Payment apps';
            transaction.budget_category = transaction.amount < 0 ? 'Income' : 'Flex';
        } else {
            // Add product_category and budget_category fields
            const key = `${transaction.personal_finance_category.primary}_${transaction.personal_finance_category.detailed}`;
            if (category_mappings[key]) {
                transaction.product_category = category_mappings[key].productCategory;
                transaction.budget_category = category_mappings[key].budgetCategory;
            } else {
                // Handle case where category and subCategory are not found in the mapping
                transaction.product_category = 'Unknown';
                transaction.budget_category = 'Unknown';
            }
        }

        return transaction;
    });

    // Log the number of transactions that have undefined account_id
    const undefinedAccountIdCount = processedTransactions.filter(transaction => transaction.account_id === undefined).length;
    if (undefinedAccountIdCount > 0) {
        console.warn(`${undefinedAccountIdCount} transactions have undefined account_id`);
    }

    return processedTransactions;
}


exports.getTransactionHistoryForAccount = async (req, res, next) => {
    try {
        const transactions = await db.getTransactionHistoryForAccount(req.params.id); // Fetch transactions for the account id
        res.locals.data = transactions; // Store the transactions in res.locals.data
    } catch (error) {
        res.status(500).send({ message: 'Error fetching transaction history' });
    }
    next();
};

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