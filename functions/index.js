const admin = require("firebase-admin");
admin.initializeApp();

const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");

const db = admin.firestore();

// ---------- helpers ----------
function chunk(arr, size) {
  const out = [];
  for (let i = 0; i < arr.length; i += size) out.push(arr.slice(i, i + size));
  return out;
}

async function sendToTokenRefs(tokenRefs, payload) {
  if (!tokenRefs.length) return;

  const groups = chunk(tokenRefs, 500);
  for (const group of groups) {
    const tokens = group.map((x) => x.token);

    const resp = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: payload.notification,
      data: payload.data, // strings only
    });

    // delete invalid tokens
    const toDelete = [];
    resp.responses.forEach((r, idx) => {
      if (!r.success) {
        const code = r.error?.code || "";
        if (
          code === "messaging/registration-token-not-registered" ||
          code === "messaging/invalid-registration-token"
        ) {
          toDelete.push(group[idx].ref.delete());
        }
      }
    });
    if (toDelete.length) await Promise.allSettled(toDelete);
  }
}

async function isAdminLike(uid) {
  const roleSnap = await db.collection("roles").doc(uid).get();
  if (!roleSnap.exists) return false;
  const r = roleSnap.data() || {};
  return (
    r.role === "admin" ||
    r.role === "superAdmin" ||
    r.admin === true ||
    r.level === "super" ||
    r.super_admin === true
  );
}

async function getAllTokensForUser(uid) {
  const snap = await db.collection("users").doc(uid).collection("fcmTokens").get();
  return snap.docs.map((d) => ({ token: d.id, ref: d.ref }));
}

async function getAllTokensForCourseStudents(courseCode) {
  const usersSnap = await db
    .collection("users")
    .where("enrolledCourses", "array-contains", courseCode)
    .get();

  const tokenRefs = [];
  for (const u of usersSnap.docs) {
    if (await isAdminLike(u.id)) continue;

    const t = await u.ref.collection("fcmTokens").get();
    t.docs.forEach((d) => tokenRefs.push({ token: d.id, ref: d.ref }));
  }
  return tokenRefs;
}

// Assumes users/{uid} has facultyId for students (recommended)
async function getAllTokensForFacultyStudents(facultyId) {
  const usersSnap = await db.collection("users").where("facultyId", "==", facultyId).get();

  const tokenRefs = [];
  for (const u of usersSnap.docs) {
    if (await isAdminLike(u.id)) continue;

    const t = await u.ref.collection("fcmTokens").get();
    t.docs.forEach((d) => tokenRefs.push({ token: d.id, ref: d.ref }));
  }
  return tokenRefs;
}

// ---------- 1) Immediate push when an admin/superAdmin creates an Event/Deadline (non-personal) ----------
exports.notifyCalendarItemCreated = onDocumentCreated("calendarEvents/{eventId}", async (event) => {
  const data = event.data?.data() || {};
  const scope = (data.scope || "global").toString(); // personal|course|global
  const type = (data.type || "Event").toString();    // Event|Deadline|Reminder
  const title = (data.title || "Untitled").toString();

  // We do NOT notify on personal reminders here (we notify via schedule)
  if (scope === "personal") return;

  // Only notify for Event/Deadline
  if (type !== "Event" && type !== "Deadline") return;

  const facultyId = (data.facultyId || "").toString();
  const courseCode = (data.courseCode || "").toString();

  let tokenRefs = [];

  if (scope === "course") {
    if (!courseCode) return;
    tokenRefs = await getAllTokensForCourseStudents(courseCode);
  } else {
    // global
    if (!facultyId) return;
    tokenRefs = await getAllTokensForFacultyStudents(facultyId);
  }

  const payload = {
    notification: {
      title: type === "Deadline" ? `New deadline: ${title}` : `New event: ${title}`,
      body: scope === "course" ? `Course ${courseCode}` : "Faculty-wide",
    },
    data: {
      type: "calendar_created",
      itemType: type,
      scope: scope,
      eventId: event.params.eventId.toString(),
      courseCode: courseCode,
      facultyId: facultyId,
    },
  };

  await sendToTokenRefs(tokenRefs, payload);
});

// ---------- 2) Scheduled reminders (daily) for tomorrow's items (Event/Deadline/Reminder) ----------
// Timezone: Jordan (Asia/Amman)
exports.sendTomorrowCalendarReminders = onSchedule(
  { schedule: "every 1 minutes", timeZone: "Asia/Amman" },
  async () => {
    const now = new Date();
    const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1); // tomorrow 00:00
    const end = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 2);   // next day 00:00

    const snap = await db
      .collection("calendarEvents")
      .where("date", ">=", admin.firestore.Timestamp.fromDate(start))
      .where("date", "<", admin.firestore.Timestamp.fromDate(end))
      .get();

    if (snap.empty) return;

    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const scope = (data.scope || "global").toString();
      const type = (data.type || "Event").toString();
      const title = (data.title || "Untitled").toString();

      const facultyId = (data.facultyId || "").toString();
      const courseCode = (data.courseCode || "").toString();
      const ownerId = (data.ownerId || "").toString();

      let tokenRefs = [];

      if (scope === "personal") {
        if (!ownerId) continue;
        tokenRefs = await getAllTokensForUser(ownerId);
      } else if (scope === "course") {
        if (!courseCode) continue;
        tokenRefs = await getAllTokensForCourseStudents(courseCode);
      } else {
        if (!facultyId) continue;
        tokenRefs = await getAllTokensForFacultyStudents(facultyId);
      }

      const payload = {
        notification: {
          title: `Tomorrow: ${title}`,
          body:
            scope === "personal"
              ? "Personal reminder"
              : scope === "course"
                ? `${type} • Course ${courseCode}`
                : `${type} • Faculty-wide`,
        },
        data: {
          type: "calendar_tomorrow",
          itemType: type,
          scope: scope,
          eventId: doc.id,
          courseCode: courseCode,
          facultyId: facultyId,
          ownerId: ownerId,
        },
      };

      await sendToTokenRefs(tokenRefs, payload);
    }
  }
);

// ---------- 3) Welcome email when a NEW student user doc is created ----------
exports.sendWelcomeEmailOnUserCreate = onDocumentCreated("users/{uid}", async (event) => {
  const uid = event.params.uid;
  const userData = event.data?.data() || {};

  // Skip admins/super admins
  if (await isAdminLike(uid)) return;

  const nationalId = (userData.nationalId || "").toString().trim();
  const loginEmail = (userData.loginEmail || "").toString().trim(); // ✅ generated app email
  if (!nationalId || !loginEmail) return;

  // Get the REAL email from civil registry
  let civilSnap = await db.collection("civilRegistry").doc(nationalId).get();

  // If your civil doc id is NOT nationalId, fallback query:
  if (!civilSnap.exists) {
    const q = await db.collection("civilRegistry").where("nationalId", "==", nationalId).limit(1).get();
    if (!q.empty) civilSnap = q.docs[0];
  }

  if (!civilSnap.exists) return;

  const civilEmail = (civilSnap.data()?.email || "").toString().trim(); // ✅ real email recipient
  if (!civilEmail) return;

  // Generate set-password link for the GENERATED login email account
  let resetLink;
  try {
    resetLink = await admin.auth().generatePasswordResetLink(loginEmail);
  } catch (e) {
    console.error("Failed to generate reset link:", e);
    return;
  }

  // Send email to REAL email, containing loginEmail + reset link
  await db.collection("mail").add({
    to: [civilEmail],
    message: {
      subject: "Welcome to UniGo 🎓",
      text:
        `Your UniGo account has been created.\n\n` +
        `UniGo Username (Login Email): ${loginEmail}\n` +
        `Set your password here: ${resetLink}\n\n` +
        `After setting the password, log in using the UniGo Username above.`,
      html:
        `<p>Your <b>UniGo</b> account has been created.</p>` +
        `<p><b>UniGo Username (Login Email):</b> ${loginEmail}</p>` +
        `<p><a href="${resetLink}">Click here to set your password</a></p>` +
        `<p>After setting the password, log in using the UniGo Username above.</p>`,
    },
  });
});

const { onRequest } = require("firebase-functions/v2/https");

exports.requestPasswordResetByNationalId = onRequest(
  { region: "us-central1" },
  async (req, res) => {
    // Basic CORS (safe for mobile; helps if you ever test on web)
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    if (req.method === "OPTIONS") return res.status(204).send("");

    try {
      const nationalId = (req.body?.nationalId || "").toString().trim();
      if (!nationalId) return res.status(400).json({ ok: false, error: "nationalId is required" });

      // Find civil registry record
      const civilSnap = await db
        .collection("civilRegistry")
        .where("nationalId", "==", nationalId)
        .limit(1)
        .get();

      if (civilSnap.empty) {
        return res.status(404).json({ ok: false, error: "No civil record found" });
      }

      const civilDoc = civilSnap.docs[0];
      const civil = civilDoc.data() || {};

      const toEmail = (civil.email || "").toString().trim();
      const linkedUid = (civil.linkedUid || "").toString().trim();

      if (!toEmail) {
        return res.status(400).json({ ok: false, error: "Civil record has no email field" });
      }
      if (!linkedUid) {
        return res.status(400).json({ ok: false, error: "Civil record is not linked to a UniGO account yet" });
      }

      // Get user's UniGO auth email
      const userSnap = await db.collection("users").doc(linkedUid).get();
      if (!userSnap.exists) {
        return res.status(404).json({ ok: false, error: "Linked UniGO user not found" });
      }
      const userData = userSnap.data() || {};
      const authEmail = (userData.email || "").toString().trim();
      const uniId = (userData.id || "").toString().trim();

      if (!authEmail) {
        return res.status(400).json({ ok: false, error: "UniGO user has no email field" });
      }

      // Generate Firebase reset link for the UniGO auth email
      const link = await admin.auth().generatePasswordResetLink(authEmail);

      // Queue email via Firestore 'mail' extension
      await db.collection("mail").add({
        to: [toEmail],
        message: {
          subject: "UniGO Password Reset",
          text:
            `Hello,\n\nA password reset was requested for your UniGO account.\n\n` +
            `UniGO Email (login): ${authEmail}\n` +
            (uniId ? `University ID: ${uniId}\n\n` : "\n") +
            `Reset link:\n${link}\n\nIf you didn't request this, ignore this email.`,
          html:
            `<p>Hello,</p>
             <p>A password reset was requested for your UniGO account.</p>
             <p><b>UniGO Email (login):</b> ${authEmail}<br/>
             ${uniId ? `<b>University ID:</b> ${uniId}<br/>` : ""}
             </p>
             <p><a href="${link}">Click here to reset your password</a></p>
             <p>If you didn't request this, ignore this email.</p>`,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        type: "password_reset",
        nationalId: nationalId,
        linkedUid: linkedUid,
      });

      return res.json({ ok: true });
    } catch (e) {
      console.error(e);
      return res.status(500).json({ ok: false, error: e.message || String(e) });
    }
  }
);

