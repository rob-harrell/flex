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
    let phoneNumber = req.body.phone; // Get the phone number from the request body
    client.verify.v2.services(serviceSid)
        .verifications
        .create({to: phoneNumber, channel: 'sms'})
        .then(verification => {
            res.status(200).send({message: 'Verification code sent'});
        })
        .catch(error => {
            console.error(error);
            res.status(500).send({error: 'Failed to send verification code'});
        });
});


router.post('/verifyOTP', async (req, res) => {
    const phoneNumber = req.body.phone; // Get the phone number from the request body
    const code = req.body.code; // Get the verification code from the request body

    client.verify.v2.services(serviceSid)
        .verificationChecks
        .create({to: phoneNumber, code: code})
        .then(async verification_check => {
            console.log('OTP status:', verification_check.status); // Add this line
            if (verification_check.status === 'approved') {
                const sessionToken = uuid.v4();
                const user = await userServices.getUserByPhone(phoneNumber);
                if (user) {
                    res.status(200).send({ message: 'Verification code approved', isExistingUser: true, userId: user.id, sessionToken: sessionToken });
                } else {
                    const newUser = await userServices.createUser(phoneNumber, sessionToken);
                    if (newUser) {
                        res.status(200).send({ message: 'Verification code approved', isExistingUser: false, userId: newUser.id, sessionToken: sessionToken });
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