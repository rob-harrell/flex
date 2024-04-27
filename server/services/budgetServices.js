// Import necessary modules or libraries
const db = require('../db/database.js'); 
const { syncTransactions } = require('../routes/plaid');

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
        if (transaction.name.toLowerCase() === 'venmo') {
            transaction.merchant_name = 'Venmo';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/venmo_logo.png'
        } else if (transaction.name.toLowerCase().includes('zelle')) {
            transaction.merchant_name = 'Zelle';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/zelle_logo.png'
        } else if (transaction.name.toLowerCase() === ('target')) {
            transaction.merchant_name = 'Target';
            transaction.logo_url = 'http://plaid-merchant-logos.plaid.com/target_997.png'
        } else if (transaction.merchant_name && transaction.merchant_name.toLowerCase() === ('potterybarn')) {
            transaction.merchant_name = 'Pottery Barn';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/pottery_barn_logo.png'
        } else if (transaction.merchant_name && transaction.merchant_name.toLowerCase() === ('barrysbootcamp')) {
            transaction.merchant_name = 'Barry\'s Bootcamp';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/barrys_bootcamp_logo.png'
        } else if (transaction.merchant_name && transaction.merchant_name.toLowerCase() === ('so cal gas paid')) {
            transaction.merchant_name = 'SoCal Gas';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/SoCalGas_logo.png'
        } else if (transaction.merchant_name && transaction.merchant_name.toLowerCase() === ('sofi')) {
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/sofi_logo.png'
        } else if (transaction.name.toLowerCase().includes ('snap inc direct dep')) {
            transaction.merchant_name = 'Snap Inc';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/snap_logo.png'
        } else if (transaction.name.toLowerCase().includes ('bank of america mortgage')) {
            transaction.merchant_name = 'Bank of America Mortgage';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/boa_logo.png'
        } else if (transaction.merchant_name && transaction.merchant_name.toLowerCase() === ('affirm')) {
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/affirm_logo.jpeg'
        } else if (transaction.merchant_name && transaction.merchant_name.toLowerCase() === ('agia insurance trans')) {
            transaction.merchant_name = 'Agia Insurance';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/agia_insurance_logo.jpeg'
        } else if (transaction.name.toLowerCase().includes ('name:gusto')) {
            transaction.merchant_name = 'Gusto';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/gusto_logo.png'
        } else if (transaction.merchant_name && transaction.merchant_name.toLowerCase() === ('bristol farms')) {
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/bristol_farms_logo.png'
        } else if (transaction.name.toLowerCase().includes ('so cal edison co-directpay')) {
            transaction.merchant_name = 'SoCal Edison';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/socal_edison_logo.png'
        } else if (transaction.merchant_name && transaction.merchant_name.toLowerCase() === ('amica')) {
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/amica_logo.png'
        } else if (transaction.merchant_name && transaction.merchant_name.toLowerCase().includes ('southwest airlines')) {
            transaction.merchant_name = 'Southwest Airlines';
            transaction.logo_url = 'http://localhost:8000/assets/merchant_logos/southwest_logo.png'
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