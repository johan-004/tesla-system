<?php

return [
    'driver' => env('SMS_DRIVER', 'log'),
    'log_channel' => env('SMS_LOG_CHANNEL', 'stack'),
    'twilio' => [
        'sid' => env('TWILIO_ACCOUNT_SID'),
        'token' => env('TWILIO_AUTH_TOKEN'),
        'from' => env('TWILIO_FROM'),
    ],
];
