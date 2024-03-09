const express = require('express');
const router = express.Router();
const { getUserRecord } = require("../user_utils");
const { getUserData, getBankAccounts } = require("../services/userServices");

router.get('/get_user_info', async (req, res, next) => {
  try {
    const currentUser = await getUserRecord();
    console.log("currentUser", currentUser);
    res.json({
      userId: currentUser["userId"],
      userStatus: currentUser["userStatus"],
    });
  } catch (error) {
    next(error);
  }
});

router.get('/get_user_data', async (req, res, next) => {
  try {
    const userInfo = await getUserData(req.query.userId);
    res.json(userInfo);
  } catch (error) {
    next(error);
  }
});

module.exports = router;