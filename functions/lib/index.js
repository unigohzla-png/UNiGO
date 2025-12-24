"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.notifyCourseAnnouncement = void 0;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-functions/v2/firestore");
const firebase_functions_1 = require("firebase-functions");
(0, firebase_functions_1.setGlobalOptions)({ maxInstances: 10 });
admin.initializeApp();
const db = admin.firestore();
/**
 * Push notification when an announcement is created:
 * courses/{courseId}/announcements/{announcementId}
 *
 * Targets: users where enrolledCourses contains courseKey (courseCode or courseId)
 * Tokens: users/{uid}/fcmTokens/{tokenDoc} -> { token: string }
 */
exports.notifyCourseAnnouncement = (0, firestore_1.onDocumentCreated)("courses/{courseId}/announcements/{announcementId}", async (event) => {
    var _a, _b, _c, _d, _e, _f;
    const courseId = event.params.courseId;
    const announcementId = event.params.announcementId;
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    // ✅ Adjust these fields to match your announcement doc
    const notifTitle = (_a = data.title) !== null && _a !== void 0 ? _a : "New announcement";
    const notifBody = (_d = (_c = (_b = data.body) !== null && _b !== void 0 ? _b : data.message) !== null && _c !== void 0 ? _c : data.text) !== null && _d !== void 0 ? _d : "Open UniGO to view.";
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
        const c = courseDoc.data();
        const maybeCode = (_e = c === null || c === void 0 ? void 0 : c.code) !== null && _e !== void 0 ? _e : c === null || c === void 0 ? void 0 : c.courseCode;
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
    const tokens = [];
    for (const userDoc of usersSnap.docs) {
        const tokSnap = await db
            .collection("users")
            .doc(userDoc.id)
            .collection("fcmTokens")
            .get();
        for (const t of tokSnap.docs) {
            const token = (_f = t.data()) === null || _f === void 0 ? void 0 : _f.token;
            if (typeof token === "string" && token.length > 0)
                tokens.push(token);
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
        console.log(`[notifyCourseAnnouncement] Sent chunk: success=${resp.successCount} failure=${resp.failureCount}`);
    }
});
//# sourceMappingURL=index.js.map