const express = require('express');
const router = express.Router();
const { getUserData, getBankAccounts, createUser, updateUser, invalidateSessionToken } = require("../services/userServices");

// Middleware to check session token
router.use(async (req, res, next) => {
  const sessionToken = req.headers['session-token'];

  if (!sessionToken) {
    return res.status(401).json({ message: 'No session token provided' });
  }

  // Replace this with your actual session token validation logic
  const isValid = await validateSessionToken(sessionToken);
  if (!isValid) {
    return res.status(401).json({ message: 'Invalid session token' });
  }

  next();
});

router.get('/get_user_data', async (req, res, next) => {
  try {
    const userInfo = await getUserData(req.query.userId);
    res.json(userInfo);
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