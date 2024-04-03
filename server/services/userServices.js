const { createUser: createDbUser, updateUser: updateDbUser, getUserRecord, getUserRecordByPhone, getUserAccounts, createItem, updateItem, getInstitutionByPlaidId, createInstitution, createAccount, invalidateSessionToken: invalidateDbSessionToken, getUserBySessionToken } = require("../db/database");
const { saveImage } = require('./institutionServices.js');

async function createUser(phoneNumber, sessionToken) {
  const user = await createDbUser(phoneNumber, sessionToken);
  return user;
}

async function updateUser(userData) {
  const user = await updateDbUser(userData);
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

async function getAuth(itemId, accessToken, plaidClient) {
  console.log('getAuth called with userId:', userId, 'itemId:', itemId, 'accessToken:', accessToken);
  // Use the access_token to get auth data
  const authResponse = await plaidClient.authGet({ access_token: accessToken });
  console.log('authResponse:', authResponse);

  const plaidInstitutionId = authResponse.data.item.institution_id; // get the institution_id from the auth response
  console.log('plaidInstitutionId:', plaidInstitutionId);

  // Check if the institution already exists in your database
  let institution = await getInstitutionByPlaidId(plaidInstitutionId);
  console.log('institution:', institution);

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
    console.log('institutionResponse:', institutionResponse);

    // Get the base64 logo data
    const base64Logo = institutionResponse.data.institution.logo;

    // Save the logo as an image file and get the file path
    const logoPath = await saveImage(base64Logo);
    console.log('logoPath:', logoPath);

    // Store the institution data in your database
    institution = await createInstitution({
      plaid_institution_id: plaidInstitutionId,
      institution_name: institutionResponse.data.institution.name,
      logo_path: logoPath, // store the path to the logo image file
    });
    console.log('newly created institution:', institution);
  }

  // Update the item with the institution_id
  console.log("updating item with institution id")
  await updateItem(itemId, { institution_id: institution.id });

  // Create the associated accounts
  console.log("creating accounts")
  const accounts = authResponse.data.accounts;
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
  console.log(accounts)
}

async function createItemRecord(itemData) {
  const item = await createItem(itemData);
  return item;
}

module.exports = { getUserData, getUserByPhone, getBankAccounts, createUser, updateUser, createItemRecord, getAuth, validateSessionToken, invalidateSessionToken };