const express = require('express');
const router = express.Router();
const { Configuration, PlaidEnvironments, PlaidApi } = require("plaid");
const { getUserRecord, updateUserRecord } = require("../user_utils");
const {
  FIELD_ACCESS_TOKEN,
  FIELD_USER_ID,
  FIELD_USER_STATUS,
  FIELD_ITEM_ID,
} = require("../constants");

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
    const currentUser = await getUserRecord();
    const userId = currentUser[FIELD_USER_ID];
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
 * in the future
 */
router.post("/swap_public_token", async (req, res, next) => {
try {
    const result = await plaidClient.itemPublicTokenExchange({
    public_token: req.body.public_token,
    });
    const data = result.data;
    console.log("publicTokenExchange data", data);
    const updateData = {};
    updateData[FIELD_ACCESS_TOKEN] = data.access_token;
    updateData[FIELD_ITEM_ID] = data.item_id;
    updateData[FIELD_USER_STATUS] = "connected";
    await updateUserRecord(updateData);
    res.json({ success: true });
} catch (error) {
    next(error);
}
});

/**
 * Grabs auth info for the user and returns it as a big ol' JSON object
 */
router.get("/simple_auth", async (req, res, next) => {
try {
    const currentUser = await getUserRecord();
    const accessToken = currentUser[FIELD_ACCESS_TOKEN];
    const authResponse = await plaidClient.authGet({
    access_token: accessToken,
    });

    console.dir(authResponse.data, { depth: null });

    const accountMask = authResponse.data.accounts[0].mask;
    const accountName = authResponse.data.accounts[0].name;
    const accountId = authResponse.data.accounts[0].account_id;

    // Since I don't know if these two arrays are in the same order, let's
    // make sure we're fetching the right one

    const routingNumber = authResponse.data.numbers.ach.find(
    (e) => e.account_id === accountId
    ).routing;
    res.json({ routingNumber, accountMask, accountName });
} catch (error) {
    next(error);
}
});

module.exports = router;