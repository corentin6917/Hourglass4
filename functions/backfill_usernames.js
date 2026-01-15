const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();

async function backfill() {
  const usersSnap = await db.collection("users").get();

  let created = 0;
  let skipped = 0;
  let conflicts = 0;

  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const usernameRaw = (data.username || "").toString().trim();
    const usernameLower = (data.username_lower || usernameRaw.toLowerCase()).toString().trim();
    const uid = (data.uid || doc.id).toString();

    if (!usernameLower) {
      skipped += 1;
      continue;
    }

    const ref = db.collection("usernames").doc(usernameLower);
    const result = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) {
        tx.set(ref, {
          uid,
          username: usernameRaw,
          backfilledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return "created";
      }
      const owner = snap.get("uid");
      if (owner === uid) {
        tx.set(ref, {username: usernameRaw}, {merge: true});
        return "skipped";
      }
      return "conflict";
    });

    if (result === "created") created += 1;
    else if (result === "conflict") conflicts += 1;
    else skipped += 1;
  }

  console.log(`Backfill termine. created=${created} skipped=${skipped} conflicts=${conflicts}`);
}

backfill().catch((err) => {
  console.error("Backfill error:", err);
  process.exit(1);
});
