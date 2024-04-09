const pgp = require('pg-promise')();
const pgTypes = require('pg').types;
const { queryResultErrorCode } = pgp.errors;
const cs = new pgp.helpers.ColumnSet(['?id', 'firstname', 'lastname', 'phone', 'monthly_income', 'monthly_fixed_spend', 'birth_date', 'has_entered_user_details', 'has_completed_account_creation', 'has_completed_notification_selection', 'push_notifications_enabled', 'sms_notifications_enabled', 'has_edited_budget_preferences', 'has_completed_budget_customization'], {table: 'users'});
const csBudgetPreferences = new pgp.helpers.ColumnSet(['?id', 'user_id', 'category', 'sub_category', 'budget_category', 'created', 'updated', 'product_category', 'fixed_amount'], {table: 'budget_preferences'});


// Override default type parsing for integers and floats
pgTypes.setTypeParser(pgTypes.builtins.INT8, parseInt);
pgTypes.setTypeParser(pgTypes.builtins.FLOAT8, parseFloat);
pgTypes.setTypeParser(pgTypes.builtins.NUMERIC, parseFloat);
pgTypes.setTypeParser(pgTypes.builtins.TIMESTAMP, str => new Date(str));

const db = pgp('postgres://rob@localhost:5432/flex_db');

async function createUser(phoneNumber, sessionToken) {
  const user = await db.one(`
      INSERT INTO users(phone, session_token)
      VALUES($1, $2)
      RETURNING *
  `, [phoneNumber, sessionToken]);
  return user;
}

async function updateUser(userData) {
  userData.birth_date = new Date(userData.birth_date);
  const update = pgp.helpers.update(userData, cs) + ' WHERE id = ${id} RETURNING *';
  const user = await db.one(update, userData);
  return user;
}

async function getUserRecord(userId) {
  const user = await db.one('SELECT * FROM users WHERE id = $1', [userId]);
  return user;
}

async function getUserRecordByPhone(phoneNumber) {
  try {
    const user = await db.one('SELECT * FROM users WHERE phone = $1', [phoneNumber]);
    return user;
  } catch (error) {
    if (error.code === queryResultErrorCode.noData) {
      // No user with the provided phone number exists in the database
      return null;
    } else {
      // An actual error occurred
      throw error;
    }
  }
}

async function getUserAccounts(userId) {
    const accounts = await db.any(`
      SELECT 
        accounts.id as id, 
        accounts.name, 
        accounts.masked_account_number, 
        accounts.friendly_account_name,
        accounts.type,
        accounts.sub_type,
        institutions.institution_name as bank_name, 
        institutions.logo_path,
        items.is_active
      FROM items
      INNER JOIN accounts ON items.id = accounts.item_id
      INNER JOIN institutions ON items.institution_id = institutions.id
      WHERE items.user_id = $1
    `, [userId]);
    return accounts;
}

async function getUserBySessionToken(sessionToken) {
  const user = await db.oneOrNone('SELECT * FROM users WHERE session_token = $1', [sessionToken]);

  if (!user) {
    console.log("No user found with the provided session token");
  }

  return user;
}

async function invalidateSessionToken(sessionToken) {
  await db.none(`
    UPDATE users
    SET session_token = NULL
    WHERE session_token = $1
  `, [sessionToken]);
}

async function createItem(itemData) {
    const item = await db.one(`
      INSERT INTO items(user_id, access_token, plaid_item_id, institution_id, is_active)
      VALUES($1, $2, $3, $4, $5)
      RETURNING *
    `, [itemData.user_id, itemData.access_token, itemData.plaid_item_id, itemData.institution_id, itemData.is_active]);   
    return item;
}

async function getInstitutionByPlaidId(plaidInstitutionId) {
    try {
      const institution = await db.oneOrNone('SELECT * FROM institutions WHERE plaid_institution_id = $1', [plaidInstitutionId]);
      return institution;
    } catch (error) {
      console.error(`Error getting institution by Plaid ID: ${error}`);
      return null;
    }
}
  
async function createInstitution(institutionData) {
    try {
      const institution = await db.one(`
        INSERT INTO institutions(plaid_institution_id, institution_name, logo_path)
        VALUES($1, $2, $3)
        RETURNING *
      `, [institutionData.plaid_institution_id, institutionData.institution_name, institutionData.logo_path]);
           
      return institution;
    } catch (error) {
      console.error(`Error creating institution: ${error}`);
      return null;
    }
}

async function updateItem(itemId, data) {
    const item = await db.one(`
      UPDATE items
      SET institution_id = $1
      WHERE id = $2
      RETURNING *
    `, [data.institution_id, itemId]);
   
    return item;
}

async function createAccount(accountData) {
  const { item_id, name, masked_account_number, plaid_account_id, type, sub_type } = accountData;
  const account = await db.one(
    `INSERT INTO accounts(item_id, name, masked_account_number, plaid_account_id, type, sub_type)
     VALUES($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [item_id, name, masked_account_number, plaid_account_id, type, sub_type]
  );  
  return account;
}

async function getBudgetPreferences(userId) {
  const budgetPreferences = await db.any('SELECT * FROM budget_preferences WHERE user_id = $1', [userId]);
  console.log(`Getting budget preferences for user with ID ${userId}`);
  return budgetPreferences;
}

async function updateBudgetPreferences(userId, preferences) {
  console.log(`Updating budget preferences for user with ID ${userId}`);
  
  for (let preference of preferences) {
    const existingPreference = await db.oneOrNone('SELECT * FROM budget_preferences WHERE user_id = $1 AND category = $2 AND sub_category = $3', [userId, preference.category, preference.sub_category]);

    if (existingPreference) {
      preference.id = existingPreference.id;
      const update = pgp.helpers.update(preference, csBudgetPreferences) + ' WHERE id = ${id}';
      await db.none(update, preference);
    } else {
      await db.none('INSERT INTO budget_preferences(user_id, category, sub_category, budget_category, product_category, fixed_amount) VALUES($1, $2, $3, $4, $5, $6)', [userId, preference.category, preference.sub_category, preference.budget_category, preference.product_category, preference.fixed_amount]);
    }
  }
}
// Function to get all items for a user
async function getItemsForUser(userId) {
  console.log(typeof userId);
  try {
    const items = await db.any('SELECT * FROM items WHERE user_id = $1', [userId]);
    return items;
  } catch (error) {
    console.error('Error executing query', error);
  }
}

// Function to save transactions for a user's item
async function saveTransactions(userId, itemId, added, modified, removed) {
  // Start a transaction
  return await db.tx(async t => {
    let results = [];

    // Insert added transactions
    for (let transaction of added) {
      let category = transaction.category[0] || null;
      let sub_category = transaction.category.slice(1) || [];

      let result = await t.one(`
        INSERT INTO transactions (plaid_transaction_id, plaid_account_id, user_id, category, sub_category, date, authorized_date, name, amount, currency_code, is_removed, pending, payment_meta)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        RETURNING *
      `, [transaction.transaction_id, transaction.account_id, userId, category, sub_category, transaction.date, transaction.authorized_date, transaction.name, transaction.amount, transaction.iso_currency_code || '', false, transaction.pending, JSON.stringify(transaction.payment_meta)]);
      results.push(result);
    }

    // Update modified transactions
    for (let transaction of modified) {
      let category = transaction.category[0] || null;
      let sub_category = transaction.category.slice(1) || [];

      let result = await t.one(`
        UPDATE transactions
        SET category = $1, sub_category = $2, date = $3, authorized_date = $4, name = $5, amount = $6, currency_code = $7, pending = $8, payment_meta = $9, plaid_account_id = $10
        WHERE user_id = $11 AND plaid_transaction_id = $12
        RETURNING *
      `, [category, sub_category, transaction.date, transaction.authorized_date, transaction.name, transaction.amount, transaction.currency_code, transaction.pending, JSON.stringify(transaction.payment_meta), transaction.account_id, userId, transaction.transaction_id]);
      results.push(result);
    }

    // Mark removed transactions
    for (let transaction of removed) {
      let result = await t.one(`
        UPDATE transactions
        SET is_removed = true
        WHERE user_id = $1 AND plaid_transaction_id = $2
        RETURNING *
      `, [userId, transaction.transaction_id]);
      results.push(result);
    }

    return results;
  });
}

// Function to get internal account ID
async function getInternalAccountId(plaidAccountId) {
  const result = await db.query(`
    SELECT id
    FROM accounts
    WHERE plaid_account_id = $1
  `, [plaidAccountId]);

  // Check if an account was found
  if (result.length > 0) {
    // Return the internal account ID
    return result[0].id;
  } else {
    // No account was found, return null
    return null;
  }
};

// Function to save the cursor for a user's item
async function saveCursor(itemId, cursor) {
  await db.none(`
    UPDATE items
    SET plaid_cursor = $1
    WHERE id = $2
  `, [cursor, itemId]);
}
  
module.exports = { 
  getUserRecord, 
  getUserRecordByPhone, 
  getUserAccounts, 
  createItem, 
  updateUser, 
  createUser, 
  updateItem, 
  createAccount, 
  getInstitutionByPlaidId, 
  createInstitution, 
  invalidateSessionToken, 
  getUserBySessionToken,
  getBudgetPreferences,
  updateBudgetPreferences,
  getItemsForUser, 
  saveTransactions, 
  getInternalAccountId,
  saveCursor 
};