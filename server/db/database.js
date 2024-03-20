const pgp = require('pg-promise')();
const pgTypes = require('pg').types;

// Override default type parsing for integers and floats
pgTypes.setTypeParser(pgTypes.builtins.INT8, parseInt);
pgTypes.setTypeParser(pgTypes.builtins.FLOAT8, parseFloat);
pgTypes.setTypeParser(pgTypes.builtins.NUMERIC, parseFloat);
pgTypes.setTypeParser(pgTypes.builtins.TIMESTAMP, str => new Date(str));

const db = pgp('postgres://rob@localhost:5432/flex_db');

async function createUser(userData) {
  const birthDate = new Date(userData.birthDate);
  const user = await db.one(`
    INSERT INTO users(firstname, lastname, phone, monthly_income, monthly_fixed_spend, birth_date, session_token)
    VALUES($1, $2, $3, $4, $5, $6, $7)
    RETURNING *
  `, [userData.firstName, userData.lastName, userData.phone, userData.monthlyIncome, userData.monthlyFixedSpend, birthDate, userData.sessionToken]);
  return user;
}

async function updateUser(userData) {
  const birthDate = new Date(userData.birthDate);
  const user = await db.one(`
    UPDATE users
    SET firstname = $1, lastname = $2, phone = $3, monthly_income = $4, monthly_fixed_spend = $5, birth_date = $6, session_token = $7
    WHERE id = $8
    RETURNING *
  `, [userData.firstName, userData.lastName, userData.phone, userData.monthlyIncome, userData.monthlyFixedSpend, birthDate, userData.sessionToken, userData.id]);
  return user;
}

async function getUserRecord(userId) {
  const user = await db.one('SELECT * FROM users WHERE id = $1', [userId]);
  return user;
}

async function getUserAccounts(userId) {
    const accounts = await db.any(`
      SELECT 
        accounts.id as id, 
        accounts.name, 
        accounts.masked_account_number, 
        accounts.friendly_account_name,
        institutions.institution_name as bank_name, 
        institutions.logo_path,
        items.is_active,
        TO_CHAR(accounts.created, 'Mon DD YY') as created,
        TO_CHAR(accounts.updated, 'Mon DD YY') as updated
      FROM items
      INNER JOIN accounts ON items.id = accounts.item_id
      INNER JOIN institutions ON items.institution_id = institutions.id
      WHERE items.user_id = $1
    `, [userId]);
    return accounts;
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
    const { item_id, name, masked_account_number, plaid_account_id } = accountData;
    const account = await db.one(
      `INSERT INTO accounts(item_id, name, masked_account_number, plaid_account_id)
       VALUES($1, $2, $3, $4)
       RETURNING *`,
      [item_id, name, masked_account_number, plaid_account_id]
    );  
    return account;
  }
  
  module.exports = { getUserRecord, getUserAccounts, createItem, updateUser, createUser, updateItem, createAccount, getInstitutionByPlaidId, createInstitution };