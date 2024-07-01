const express = require('express');
const router = express.Router();
const { Configuration, PlaidEnvironments, PlaidApi } = require("plaid");
const userServices = require('../services/userServices');
const { getItemById, saveTransactions, saveCursor, getAccountsByItemId } = require('../db/database.js');
const { processTransactions } = require('../services/budgetServices.js')
const accountTypes = ["checking", "savings", "credit card"];

// Set up the Plaid client
const plaidConfig = new Configuration({
  basePath: PlaidEnvironments[process.env.PLAID_ENV],
  baseOptions: {
    headers: {
      "PLAID-CLIENT-ID": process.env.PLAID_CLIENT_ID,
      "PLAID-SECRET": process.env.PLAID_SECRET,
      "Plaid-Version": "2020-09-14",
    },
  },
});
  
const plaidClient = new PlaidApi(plaidConfig);
  
/**
 * Generates a Link token to be used by the client.
 */
router.post("/generate_link_token", async (req, res, next) => {
  try {
    const userId = String(req.body.userId);

    // Determine the base URL based on the environment
    const baseUrl = process.env.VERCEL_URL ? `https://${process.env.VERCEL_URL}` : 'https://e7c2-75-223-247-250.ngrok-free.app';

    const createTokenResponse = await plaidClient.linkTokenCreate({
      user: {
        client_user_id: userId,
      },
      client_name: "Flex",
      country_codes: ["US"],
      language: "en",
      products: ["transactions"],
      webhook: `${baseUrl}/plaid/transactions_webhook`,
      redirect_uri: "https://rob-harrell.github.io/flex/",
    });
    // The redirect_uri above should match a Redirect URI in your Dashboard, or this request
    // will fail.
    const data = createTokenResponse.data;
    console.log("createTokenResponse", data);
    res.json({ expiration: data.expiration, linkToken: data.link_token });
  } catch (error) {
    console.log(
      "Running into an error! Note that if you have an error when creating a " +
        "link token, it's frequently because you have the wrong client_id " +
        "or secret for the environment, or you forgot to copy over your " +
        ".env.template file to.env."
    );
    next(error);
  }
});

/**
 * Swap the public token for an access token, so we can access account info
 * in the future. Then store the access token in the database.
 */
router.post("/swap_public_token", async (req, res, next) => {
  try {
    const result = await plaidClient.itemPublicTokenExchange({
      public_token: req.body.public_token,
    });
    const data = result.data;
    const userId = req.body.userId;
    const accessToken = data.access_token;

    const itemData = {
      user_id: userId,
      access_token: accessToken,
      plaid_item_id: data.item_id,
      is_active: true,
    };

    let newItem = await userServices.createItemRecord(itemData);

    // Call the getPlaidInfo function to add institution data and create accounts
    await userServices.getPlaidAccountInfo(newItem.id, accessToken, plaidClient);

    // Trigger initial sync of transactions
    const initialCursor = '';
    await syncTransactions(accessToken, initialCursor);

    res.status(200).json({ success: true });
  } catch (error) {
    next(error);
  }
});

//Listens to update events for accounts
router.post("/transactions_webhook", async (req, res) => {
  const { webhook_code, item_id } = req.body;

  // Check if the webhook event is for sync updates available
  if (webhook_code === "SYNC_UPDATES_AVAILABLE") {
    console.log(`Received SYNC_UPDATES_AVAILABLE webhook at ${new Date().toISOString()}`);
    console.log("Webhook body:", req.body);

    try {
      // Look up the item in the database
      const item = await getItemById(item_id);
      if (!item) {
        console.error(`Item with ID ${item_id} not found.`);
        return res.status(404).send('Item not found');
      }
    
      // Check if the cursor is null
      if (item.cursor === null) {
        // Get accounts by item ID
        const accounts = await getAccountsByItemId(item_id);

        // Filter accounts with specific account types (assuming accountTypes is defined)
        const filteredAccounts = accounts.filter(account => accountTypes.includes(account.sub_type.toLowerCase()));

        // Call syncTransactions with null cursor
        const transactionsResponse = await syncTransactions(item.access_token, null);
    
        // Process the added transactions
        const processedTransactions = await processTransactions(transactionsResponse.added);
    
        // Save the processed transactions to the database
        await saveTransactions(item_id, processedTransactions);
    
        // Save the new cursor if provided
        if (transactionsResponse.next_cursor) {
          await saveCursor(item_id, transactionsResponse.next_cursor);
        }
    
        console.log('Transactions synced and processed successfully.');
      } else {
        // If the cursor is not null, the process has already occurred
        console.log('Process has already occurred, no action needed.');
      }
    } catch (error) {
      console.error('Error processing transactions', error);
      return res.status(500).send('Internal Server Error');
    }

  } else {
    console.log(`Received webhook: ${webhook_code} at ${new Date().toISOString()} for item: ${item_id}`);
  }

  // Respond to the webhook immediately to acknowledge receipt
  res.status(200).send("Webhook received");
});

//Function to get the latest transactions from Plaid
async function syncTransactions(accessToken, initialCursor) {
  let added = [];
  let modified = [];
  let removed = [];
  let cursor = initialCursor;
  let originalCursor = initialCursor;

  while (true) {
    const options = {
      access_token: accessToken,
      cursor: cursor,
    };

    try {
      const response = await plaidClient.transactionsSync(options);
      if (response && response.data) {
        added = added.concat(response.data.added || []);
        modified = modified.concat(response.data.modified || []);
        removed = removed.concat(response.data.removed || []);
        cursor = response.data.next_cursor;
        if (response.data.has_more) {
          originalCursor = cursor;
        } else {
          break;
        }
      } else {
        console.error('Error in syncTransactions: No response or data');
        return null;
      }
    } catch (error) {
      console.error('Error in syncTransactions', error);
      cursor = originalCursor; // Restart the loop with the original cursor
    }
  }

  return {
    added: added,
    removed: removed,
    modified: modified,
    next_cursor: cursor,
  };
}

module.exports = {
  router,
  syncTransactions,
};