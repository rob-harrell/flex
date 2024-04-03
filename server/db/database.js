const pgp = require('pg-promise')();
const pgTypes = require('pg').types;
const { queryResultErrorCode } = pgp.errors;
const cs = new pgp.helpers.ColumnSet(['?id', 'firstname', 'lastname', 'phone', 'monthly_income', 'monthly_fixed_spend', 'birth_date'], {table: 'users'});

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
    console.log("db call in progress for user:")
    console.log(userId)
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
    console.log("retrieved the following accounts:")
    console.log(accounts)
    return accounts;
}

async function getUserBySessionToken(sessionToken) {
  const user = await db.oneOrNone('SELECT * FROM users WHERE session_token = $1', [sessionToken]);

  if (user) {
    console.log("Session token for retrieved user:", user.session_token);
  } else {
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
  
module.exports = { getUserRecord, getUserRecordByPhone, getUserAccounts, createItem, updateUser, createUser, updateItem, createAccount, getInstitutionByPlaidId, createInstitution, invalidateSessionToken, getUserBySessionToken };