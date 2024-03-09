const { getUserRecord, getUserAccounts } = require("../db/database");

async function getUserData(userId) {
  const user = await getUserRecord(userId);
  return user;
}

async function getBankAccounts(userId) {
  const accounts = await getUserAccounts(userId);
  return accounts;
}

module.exports = { getUserData, getBankAccounts };