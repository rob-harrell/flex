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
    const userId = req.body.userId;
    const createTokenResponse = await plaidClient.linkTokenCreate({
      user: {
        client_user_id: userId,
      },
      client_name: "Flex",
      country_codes: ["US"],
      language: "en",
      products: ["auth"],
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
    console.log("publicTokenExchange data", data);

    const userId = req.body.userId;
    const accessToken = data.access_token;

    const itemData = {
      user_id: userId,
      access_token: accessToken,
      plaid_item_id: data.item_id,
      is_active: true,
    };

    const newItem = await userServices.createItemRecord(itemData);

    // Call the getAuth function
    await userServices.getAuth(newItem.id, accessToken, plaidClient);

    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

router.post("/get_auth", async (req, res, next) => {
  try {
    const accessToken = req.body.access_token;
    const itemId = req.body.item_id;

    // Call the getAuth function from userServices
    await userServices.getAuth(itemId, accessToken);

    res.json({ success: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;