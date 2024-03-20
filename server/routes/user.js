const express = require('express');
const router = express.Router();
const { getUserData, getBankAccounts, createUser, updateUser } = require("../services/userServices");

router.get('/get_user_data', async (req, res, next) => {
  try {
    const userInfo = await getUserData(req.query.userId);
    res.json(userInfo);
  } catch (error) {
    next(error);
  }
});

// Create user endpoint
router.post('/', async (req, res, next) => {
  try {
    const user = await createUser(req.body);
    const userInfo = await getUserData(user.id);
    res.status(201).json(userInfo);
  } catch (error) {
    next(error);
  }
});

// Update user endpoint
router.put('/:id', async (req, res, next) => {
  try {
    const user = await updateUser(req.body);
    const userInfo = await getUserData(user.id);
    res.status(201).json(userInfo);
  } catch (error) {
    next(error);
  }
});

module.exports = router;