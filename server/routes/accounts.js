const express = require('express');
const router = express.Router();
const { getBankAccounts } = require("../services/userServices");

router.get('/get_bank_accounts', async (req, res, next) => {
  try {
    console.log(req.query.id)
    const bankAccounts = await getBankAccounts(req.query.id);
    res.json(bankAccounts);
  } catch (error) {
    next(error);
  }
});

module.exports = router;