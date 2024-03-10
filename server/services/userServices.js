const { getUserRecord, getUserAccounts, createItem, updateItem, createAccount } = require("../db/database");

async function getUserData(userId) {
  const user = await getUserRecord(userId);
  return user;
}

async function getBankAccounts(userId) {
  const accounts = await getUserAccounts(userId);
  return accounts;
}

async function getAuth(itemId, accessToken, plaidClient) {
  // Use the access_token to get auth data
  const authResponse = await plaidClient.authGet({ access_token: accessToken });
  const bankName = authResponse.data.accounts[0].name; // get the bank name from the first account

  // Update the item with the bank name
  await updateItem(itemId, { bank_name: bankName });

  // Create the associated accounts
  const accounts = authResponse.data.accounts;
  for (let account of accounts) {
    const accountData = {
      item_id: itemId,
      name: account.name,
      masked_account_number: account.mask, // replace 'account.masked' with the correct property from Plaid's response
      plaid_account_id: account.account_id,
      // Add other account fields as needed
    };
    await createAccount(accountData);
  }
}

async function createItemRecord(itemData) {
  const item = await createItem(itemData);
  return item;
}

module.exports = { getUserData, getBankAccounts, createItemRecord, getAuth };