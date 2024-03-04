const express = require('express');
const router = express.Router();
const { getUserRecord } = require("../user_utils");

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

module.exports = router;