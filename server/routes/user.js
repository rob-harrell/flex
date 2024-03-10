const express = require('express');
const router = express.Router();
const { getUserData, getBankAccounts } = require("../services/userServices");

router.get('/get_user_data', async (req, res, next) => {
  try {
    const userInfo = await getUserData(req.query.userId);
    res.json(userInfo);
  } catch (error) {
    next(error);
  }
});

module.exports = router;