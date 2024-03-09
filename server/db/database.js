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

module.exports = { getUserRecord, getUserAccounts };