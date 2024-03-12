const { getUserRecord, getUserAccounts, createItem, updateItem, getInstitutionByPlaidId, createInstitution, createAccount } = require("../db/database");
const { saveImage } = require('./institutionServices.js');

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

  const plaidInstitutionId = authResponse.data.item.institution_id; // get the institution_id from the auth response

  // Check if the institution already exists in your database
  let institution = await getInstitutionByPlaidId(plaidInstitutionId);

  if (!institution) {
    // If it doesn't exist, get the institution data from Plaid
    const institutionResponse = await plaidClient.institutionsGetById({ 
      institution_id: plaidInstitutionId,
      country_codes: ['US'],
      options: {
        include_optional_metadata: true,
      },
    });

    // Get the base64 logo data
    const base64Logo = institutionResponse.data.institution.logo;

    // Save the logo as an image file and get the file path
    const logoPath = await saveImage(base64Logo);

    // Store the institution data in your database
    institution = await createInstitution({
      plaid_institution_id: plaidInstitutionId,
      institution_name: institutionResponse.data.institution.name,
      logo_path: logoPath, // store the path to the logo image file
    });
  }

  // Update the item with the institution_id
  await updateItem(itemId, { institution_id: institution.id });

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

  // Return the institution id
  return institution.id;
}

async function createItemRecord(itemData) {
  const item = await createItem(itemData);
  return item;
}

module.exports = { getUserData, getBankAccounts, createItemRecord, getAuth };