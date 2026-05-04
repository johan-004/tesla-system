<?php

return [
    'enabled' => env('PUSH_NOTIFICATIONS_ENABLED', true),
    'driver' => env('PUSH_DRIVER', 'fcm'),
    'fcm' => [
        'server_key' => env('FCM_SERVER_KEY'),
        'project_id' => env('FCM_PROJECT_ID'),
        'service_account_json' => env(
            'FCM_SERVICE_ACCOUNT_JSON',
            storage_path('app/firebase/firebase-admin.json')
        ),
        'oauth_token_uri' => env('FCM_OAUTH_TOKEN_URI', 'https://oauth2.googleapis.com/token'),
        'api_base' => env('FCM_API_BASE', 'https://fcm.googleapis.com'),
    ],
];
