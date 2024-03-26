const express = require('express');
const router = express.Router();
const twilio = require('twilio');
const userServices = require('../services/userServices');
const uuid = require('uuid');

require('dotenv').config();

// Load the environment variables
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

const client = twilio(accountSid, authToken);

router.post('/sendOTP', (req, res) => {
    let phoneNumber = req.body.phoneNumber; // Get the phone number from the request body
    // Add the country code if it's not already included
    if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+1' + phoneNumber; // Assuming it's a US number
    }

    client.verify.v2.services(serviceSid)
        .verifications
        .create({to: phoneNumber, channel: 'sms'})
        .then(verification => {
            console.log(verification.sid);
            res.status(200).send({message: 'Verification code sent'});
        })
        .catch(error => {
            console.error(error);
            res.status(500).send({error: 'Failed to send verification code'});
        });
});


router.post('/verifyOTP', async (req, res) => {
    const phoneNumber = req.body.phoneNumber; // Get the phone number from the request body
    const code = req.body.code; // Get the verification code from the request body

    client.verify.v2.services(serviceSid)
        .verificationChecks
        .create({to: phoneNumber, code: code})
        .then(async verification_check => {
            if (verification_check.status === 'approved') {
                // Generate a new session token
                const sessionToken = uuid.v4();

                // Check if user exists in the database
                const user = await userServices.getUserData(phoneNumber);
                if (user) {
                    // If user exists, return isExistingUser = true, the user ID, and the session token
                    res.status(200).send({ message: 'Verification code approved', isExistingUser: true, userId: user._id, sessionToken: sessionToken });
                } else {
                    // If user does not exist, create a new user and return isExistingUser = false, the user ID, and the session token
                    const newUser = await userServices.createUser(phoneNumber, sessionToken);
                    if (newUser) {
                        res.status(200).send({ message: 'Verification code approved', isExistingUser: false, userId: newUser._id, sessionToken: sessionToken });
                    } else {
                        res.status(500).send({ error: 'Failed to create user' });
                    }
                }
            } else {
                res.status(400).send({error: 'Invalid verification code'});
            }
        })
        .catch(error => {
            console.error(error);
            res.status(500).send({error: 'Failed to verify code'});
        });
});

module.exports = router;