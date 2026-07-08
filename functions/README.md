# NIT NoticeBoard - Push Notification Cloud Functions

This directory contains a Firebase Cloud Function that automatically sends
push notifications to **every registered user** (students, admins, and super
admins) whenever a new notice document is created in Firestore.

## How it works

- `notifyOnNewNotice` (Firestore trigger on `notices/{noticeId}` create):
  1. Reads the newly created notice title.
  2. Reads all valid FCM tokens from `users/{uid}.fcmToken`.
  3. Sends a multicast push notification:
     - Title: `NIT NoticeBoard`
     - Body: `New Notice:\n{Notice Title}\n\nTap to view the notice.`
  4. Invalid/expired tokens are automatically cleared from user documents.

No Firebase server keys are exposed to the Flutter app. All sending is done
securely here using the Firebase Admin SDK.

## Deployment

From the project root:

```bash
# 1. Install dependencies
cd functions
npm install

# 2. Return to root and deploy only the functions
cd ..
firebase deploy --only functions
```

> Requires the Firebase CLI (`npm install -g firebase-tools`) and the
> `nit-notice-board` Firebase project selected (`firebase use nit-notice-board`).

## Requirements for the client app

The Flutter app (already implemented) stores each user's FCM token in
`users/{uid}/fcmToken` after sign-in / on token refresh. As long as users
have a valid token, they will receive the push notifications.