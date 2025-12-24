const admin = require("firebase-admin");
admin.initializeApp();

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");

const db = admin.firestore();

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
      data: payload.data, // all strings
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

async function getAllTokensForUser(uid) {
  const snap = await db.collection("users").doc(uid).collection("fcmTokens").get();
  return snap.docs.map((d) => ({ token: d.id, ref: d.ref }));
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

async function getAllTokensForEnrolledStudents(courseCode) {
  const usersSnap = await db
    .collection("users")
    .where("enrolledCourses", "array-contains", courseCode)
    .get();

  const tokenRefs = [];

  for (const u of usersSnap.docs) {
    // ✅ skip admins/superAdmins
    if (await isAdminLike(u.id)) continue;

    const t = await u.ref.collection("fcmTokens").get();
    t.docs.forEach((d) => tokenRefs.push({ token: d.id, ref: d.ref }));
  }

  return tokenRefs;
}


// 1) Deadline created -> notify enrolled students
exports.notifyDeadlineCreated = onDocumentCreated("calendarEvents/{eventId}", async (event) => {
  const data = event.data?.data() || {};
  if (data.type !== "Deadline") return;
  if (data.scope !== "course") return;

  const courseCode = (data.courseCode || "").toString();
  if (!courseCode) return;

  const title = (data.title || "New Deadline").toString();

  let dateStr = "";
  if (data.date && typeof data.date.toDate === "function") {
    const d = data.date.toDate();
    dateStr = d.toISOString().slice(0, 10);
  }

const tokenRefs = await getAllTokensForEnrolledStudents(courseCode);

  const payload = {
    notification: {
      title: `Deadline: ${title}`,
      body: `${courseCode}${dateStr ? " • " + dateStr : ""}`,
    },
    data: {
      type: "deadline",
      courseCode: courseCode,
      eventId: event.params.eventId.toString(),
    },
  };

  await sendToTokenRefs(tokenRefs, payload);
});

// 2) Grade confirmed -> notify that student only
exports.notifyGradeConfirmed = onDocumentUpdated(
  "users/{uid}/courses/{courseId}/grades/{gradeId}",
  async (event) => {
    const before = event.data?.before?.data() || {};
    const after = event.data?.after?.data() || {};

    if (before.confirmed === true) return;
    if (after.confirmed !== true) return;

    const uid = event.params.uid.toString();
    const courseId = event.params.courseId.toString();

    const label = (after.title ?? after.type ?? "Your grade").toString();
    const score = (after.score ?? after.value ?? "").toString();

    const tokenRefs = await getAllTokensForUser(uid);

    const payload = {
      notification: {
        title: "Grade confirmed",
        body: `${courseId} • ${label}${score ? " = " + score : ""}`,
      },
      data: {
        type: "grade_confirmed",
        courseId,
        gradeId: event.params.gradeId.toString(),
      },
    };

    await sendToTokenRefs(tokenRefs, payload);
  }
);
