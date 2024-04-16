const express = require('express');
const router = express.Router();
const { Configuration, PlaidEnvironments, PlaidApi } = require("plaid");
const userServices = require('../services/userServices');

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
    const createTokenResponse = await plaidClient.linkTokenCreate({
      user: {
        client_user_id: userId,
      },
      client_name: "Flex",
      country_codes: ["US"],
      language: "en",
      products: ["transactions"],
      webhook: "https://sample-webhook-uri.com",
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

    res.status(200).json({ success: true });
  } catch (error) {
    next(error);
  }
});

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
        added = added.concat(response.data.added);
        modified = modified.concat(response.data.modified);
        removed = removed.concat(response.data.removed);
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