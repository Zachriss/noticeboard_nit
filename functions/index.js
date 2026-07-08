/**
 * NIT NoticeBoard - Firebase Cloud Functions
 *
 * Sends push notifications to every registered user whenever a new notice
 * document is created in Firestore. The FCM tokens are stored under
 * users/{uid}.fcmToken. No Firebase server keys are exposed to the client;
 * all sending logic happens securely here using the Admin SDK.
 */

import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";
import {setGlobalOptions} from "firebase-functions/v2";

// Initialize Admin SDK (uses the default service account in the deployed env).
initializeApp();
const db = getFirestore();
const messaging = getMessaging();

// Keep cold starts cheap and run in the same region as the project.
setGlobalOptions({region: "us-central1"});

/**
 * Triggered when a new notice document is created.
 * Sends "New Notice" push notifications to all users that have a valid
 * FCM token stored in their user document.
 */
export const notifyOnNewNotice = onDocumentCreated(
    {
      document: "notices/{noticeId}",
      retry: true,
    },
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) {
        console.warn("No snapshot data for new notice.");
        return;
      }

      const notice = snapshot.data();
      const noticeId = event.params.noticeId;
      const noticeTitle = notice && notice.title ? notice.title : "New Notice";

      console.log(`New notice created: ${noticeId} - "${noticeTitle}"`);

      // Gather all valid FCM tokens from the users collection.
      const tokens = await collectFcmTokens();

      if (tokens.length === 0) {
        console.log("No registered FCM tokens found. Skipping notification.");
        return;
      }

      const message = {
        notification: {
          title: "NIT NoticeBoard",
          body: `New Notice:\n${noticeTitle}\n\nTap to view the notice.`,
        },
        data: {
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
          relatedNoticeId: noticeId,
          noticeId: noticeId,
        },
        // Send to every token. `tokens` (plural) enables multicast delivery.
        tokens: tokens,
      };

      try {
        const response = await messaging.sendEachForMulticast(message);
        console.log(
            `Sent notification to ${response.successCount} devices, ` +
            `failed for ${response.failureCount}.`,
        );

        // Clean up tokens that are no longer valid so we don't keep retrying.
        if (response.failureCount > 0) {
          await removeInvalidTokens(tokens, response);
        }
      } catch (error) {
        console.error("Failed to send push notifications:", error);
        // Rethrow so the function retries according to the retry policy.
        throw error;
      }
    },
);

/**
 * Reads every user document (and anonymous student sessions) and returns a
 * list of non-empty FCM tokens. This ensures students who sign in
 * anonymously (tracked in `student_sessions`) are also notified.
 */
async function collectFcmTokens() {
  const tokens = new Set();

  // Registered users (admins, super admins, and signed-up students).
  const usersSnapshot = await db.collection("users").get();
  for (const doc of usersSnapshot.docs) {
    const token = doc.data().fcmToken;
    if (token && typeof token === "string" && token.trim().length > 0) {
      tokens.add(token.trim());
    }
  }

  // Anonymous student sessions.
  try {
    const sessionsSnapshot = await db.collection("student_sessions").get();
    for (const doc of sessionsSnapshot.docs) {
      const token = doc.data().fcmToken;
      if (token && typeof token === "string" && token.trim().length > 0) {
        tokens.add(token.trim());
      }
    }
  } catch (e) {
    console.warn("Failed to read student_sessions tokens:", e);
  }

  return Array.from(tokens);
}

/**
 * Removes FCM tokens that are invalid/expired (UNREGISTERED or invalid
 * registration token errors) from the corresponding user documents.
 */
async function removeInvalidTokens(tokens, response) {
  const invalidTokens = [];

  response.responses.forEach((resp, index) => {
    if (!resp.success) {
      const errorCode = resp.error && resp.error.code;
      if (
        errorCode === "messaging/registration-token-not-registered" ||
        errorCode === "messaging/invalid-registration-token"
      ) {
        if (tokens[index]) {
          invalidTokens.push(tokens[index]);
        }
      } else {
        console.warn(`Unhandled send failure (${errorCode}) for token index ${index}`);
      }
    }
  });

  for (const token of invalidTokens) {
    try {
      const userSnap = await db
          .collection("users")
          .where("fcmToken", "==", token)
          .limit(1)
          .get();
      for (const doc of userSnap.docs) {
        await doc.ref.update({fcmToken: ""});
        console.log(`Cleared invalid FCM token for user ${doc.id}`);
      }
    } catch (e) {
      console.warn("Failed to clear invalid token:", e);
    }
  }
}