const express = require('express');
const router = express.Router();
const { getUserData, getBankAccounts, createUser, updateUser, validateSessionToken, invalidateSessionToken } = require("../services/userServices");

//Get user data endpoint
router.get('/get_user_data', async (req, res, next) => {
  try {
    const user = await getUserData(req.query.id);
    res.json(user);
  } catch (error) {
    next(error);
  }
});

// Update user endpoint
router.put('/:id', async (req, res, next) => {
  try {
    const user = await updateUser(req.body);
    res.status(201).json(user);
  } catch (error) {
    next(error);
  }
});

// Invalidate session token endpoint
router.post('/invalidate_session_token', async (req, res, next) => {
  try {
    await invalidateSessionToken(req.body.sessionToken);
    res.status(200).json({ message: 'Session token invalidated successfully' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;