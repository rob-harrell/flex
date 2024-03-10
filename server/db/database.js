const pgp = require('pg-promise')();
const pgTypes = require('pg').types;

// Override default type parsing for integers and floats
pgTypes.setTypeParser(pgTypes.builtins.INT8, parseInt);
pgTypes.setTypeParser(pgTypes.builtins.FLOAT8, parseFloat);
pgTypes.setTypeParser(pgTypes.builtins.NUMERIC, parseFloat);
pgTypes.setTypeParser(pgTypes.builtins.TIMESTAMP, str => new Date(str));

const db = pgp('postgres://rob@localhost:5432/flex_db');

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
        items.bank_name, 
        items.is_active,
        TO_CHAR(accounts.created, 'Mon DD YY') as created,
        TO_CHAR(accounts.updated, 'Mon DD YY') as updated
      FROM items
      INNER JOIN accounts ON items.id = accounts.item_id
      WHERE items.user_id = $1
    `, [userId]);
    return accounts;
}

async function createItem(itemData) {
    const item = await db.one(`
      INSERT INTO items(user_id, access_token, plaid_item_id, bank_name, is_active)
      VALUES($1, $2, $3, $4, $5)
      RETURNING *
    `, [itemData.user_id, itemData.access_token, itemData.plaid_item_id, itemData.bank_name, itemData.is_active]);
    
    console.log(`Successfully stored item with id: ${item.id}`);
    
    return item;
}

async function updateItem(itemId, data) {
    const item = await db.one(`
      UPDATE items
      SET bank_name = $1
      WHERE id = $2
      RETURNING *
    `, [data.bank_name, itemId]);
  
    console.log(`Successfully updated item with id: ${itemId}`);
  
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
  
    console.log(`Successfully created account with id: ${account.id}`);
  
    return account;
  }
  
  module.exports = { getUserRecord, getUserAccounts, createItem, updateItem, createAccount };