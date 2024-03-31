const express = require('express');
const router = express.Router();
const { getUserData, getBankAccounts, createUser, updateUser, validateSessionToken, invalidateSessionToken } = require("../services/userServices");

// Middleware to check session token
router.use(async (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'No session token provided' });
  }

  const sessionToken = authHeader.replace('Bearer ', '');

  const isValid = await validateSessionToken(sessionToken);
  if (!isValid) {
    return res.status(401).json({ message: 'Invalid session token' });
  }

  next();
});

//Get user data endpoint
router.get('/get_user_data', async (req, res, next) => {
  try {
    const user = await getUserData(req.body.id);
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