import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { setGlobalOptions } from "firebase-functions";

setGlobalOptions({ maxInstances: 10 });

admin.initializeApp();
const db = admin.firestore();

/**
 * Push notification when an announcement is created:
 * courses/{courseId}/announcements/{announcementId}
 *
 * Targets: users where enrolledCourses contains courseKey (courseCode or courseId)
 * Tokens: users/{uid}/fcmTokens/{tokenDoc} -> { token: string }
 */
export const notifyCourseAnnouncement = onDocumentCreated(
  "courses/{courseId}/announcements/{announcementId}",
  async (event) => {
    const courseId = event.params.courseId;
    const announcementId = event.params.announcementId;

    const snap = event.data;
    if (!snap) return;

    const data = snap.data() as any;

    // ✅ Adjust these fields to match your announcement doc
    const notifTitle: string = data.title ?? "New announcement";
    const notifBody: string =
      data.body ?? data.message ?? data.text ?? "Open UniGO to view.";

    /**
     * IMPORTANT:
     * If your users.enrolledCourses stores course codes like "1901101",
     * then your course doc should contain { code: "1901101" } or { courseCode: "1901101" }.
     * If your users.enrolledCourses stores the course doc id, then we can just use courseId.
     */
    let courseKey = courseId;

    // Try reading course doc for a code if available
    const courseDoc = await db.collection("courses").doc(courseId).get();
    if (courseDoc.exists) {
      const c = courseDoc.data() as any;
      const maybeCode = c?.code ?? c?.courseCode;
      if (typeof maybeCode === "string" && maybeCode.trim().length > 0) {
        courseKey = maybeCode.trim();
      }
    }

    // 1) Find enrolled students
    const usersSnap = await db
      .collection("users")
      .where("enrolledCourses", "array-contains", courseKey)
      .get();

    if (usersSnap.empty) {
      console.log("[notifyCourseAnnouncement] No enrolled users for:", courseKey);
      return;
    }

    // 2) Collect tokens
    const tokens: string[] = [];
    for (const userDoc of usersSnap.docs) {
      const tokSnap = await db
        .collection("users")
        .doc(userDoc.id)
        .collection("fcmTokens")
        .get();

      for (const t of tokSnap.docs) {
        const token = (t.data() as any)?.token;
        if (typeof token === "string" && token.length > 0) tokens.push(token);
      }
    }

    if (tokens.length === 0) {
      console.log("[notifyCourseAnnouncement] No tokens found.");
      return;
    }

    // 3) Send in chunks of 500
    for (let i = 0; i < tokens.length; i += 500) {
      const chunk = tokens.slice(i, i + 500);

      const resp = await admin.messaging().sendEachForMulticast({
        tokens: chunk,
        notification: {
          title: notifTitle,
          body: notifBody,
        },
        data: {
          kind: "announcement",
          courseKey,
          courseId,
          announcementId,
        },
        android: {
          priority: "high",
        },
      });

      console.log(
        `[notifyCourseAnnouncement] Sent chunk: success=${resp.successCount} failure=${resp.failureCount}`
      );
    }
  }
);
