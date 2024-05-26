const { createUser: createDbUser, updateUser: updateDbUser, updateDBSessionToken, getUserRecord, getUserRecordByPhone, getUserAccounts, createItem, updateItem, getInstitutionByPlaidId, createInstitution, createAccount, invalidateSessionToken: invalidateDbSessionToken, getUserBySessionToken } = require("../db/database");
const { saveImage } = require('./imageServices.js');

async function createUser(phoneNumber, sessionToken) {
  const user = await createDbUser(phoneNumber, sessionToken);
  return user;
}

async function updateUser(userData) {
  const user = await updateDbUser(userData);
  return user;
}

async function updateSessionToken(userId, sessionToken) {
  const user = await updateDBSessionToken(userId, sessionToken);
  return user;
}

async function getUserData(userId) {
  const user = await getUserRecord(userId);
  return user;
}

async function getUserByPhone(phoneNumber) {
  const user = await getUserRecordByPhone(phoneNumber);
  if (!user) {
    // No user with the provided phone number exists in the database
    return null;
  }
  return user;
};

async function getBankAccounts(userId) {
  const accounts = await getUserAccounts(userId);
  return accounts;
}

async function validateSessionToken(sessionToken) {
  const user = await getUserBySessionToken(sessionToken);
  return user != null;
}

async function invalidateSessionToken(sessionToken) {
  console.log("called invalidateSessionToken on server");
  await invalidateDbSessionToken(sessionToken);
}

async function getPlaidAccountInfo(itemId, accessToken, plaidClient) {
  // Use the access_token to get item data
  const itemResponse = await plaidClient.itemGet({ access_token: accessToken });
  const plaidInstitutionId = itemResponse.data.item.institution_id; // get the institution_id from the item response

  // Check if the institution already exists in your database
  let institution = await getInstitutionByPlaidId(plaidInstitutionId);

  if (!institution) {
    // If it doesn't exist, get the institution data from Plaid
    console.log("new institution detected; getting info from plaid")
    const institutionResponse = await plaidClient.institutionsGetById({ 
      institution_id: plaidInstitutionId,
      country_codes: ['US'],
      options: {
        include_optional_metadata: true,
      },
    });

    // Get the base64 logo data
    const base64Logo = institutionResponse.data.institution.logo;

    // Save the logo as a blob and get the blob URL
    let logoUrl = null;
    if (base64Logo) {
      logoUrl = await saveImage(base64Logo, 'institution_logos');
      console.log('logoUrl:', logoUrl);
    } else {
      console.log('No logo available for this institution');
      // Use the default logo
      if (plaidInstitutionId === 'ins_56') {
        logoUrl = 'https://flex-wheat.vercel.app/assets/images/chase_logo.png';
      } else {
        logoUrl = 'https://flex-wheat.vercel.app/assets/images/default_logo.png';
      }
    }

    // Store the institution data in your database
    institution = await createInstitution({
      plaid_institution_id: plaidInstitutionId,
      institution_name: institutionResponse.data.institution.name,
      logo_url: logoUrl, // store the URL to the logo blob
    });
    console.log('newly created institution:', institution);
  }

  // Update the item with the institution_id
  console.log("updating item with institution id")
  await updateItem(itemId, { institution_id: institution.id });

  // Get the accounts data
  const accountsResponse = await plaidClient.accountsGet({ access_token: accessToken });
  const accounts = accountsResponse.data.accounts;

  // Store the accounts data in your database
  for (let account of accounts) {
    const accountData = {
      item_id: itemId,
      name: account.name,
      masked_account_number: account.mask, // replace 'account.masked' with the correct property from Plaid's response
      plaid_account_id: account.account_id,
      type: account.type,
      sub_type: account.subtype
    };
    await createAccount(accountData);
  }
}

async function createItemRecord(itemData) {
  const item = await createItem(itemData);
  return item;
}

module.exports = { getUserData, updateSessionToken, getUserByPhone, getBankAccounts, createUser, updateUser, createItemRecord, getPlaidAccountInfo, validateSessionToken, invalidateSessionToken };