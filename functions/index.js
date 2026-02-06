/**
 * Firebase Cloud Functions pour Hourglass 4
 *
 * Fonction principale: Suppression automatique des photos de victoires après 48h
 */

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentDeleted, onDocumentCreated} = require("firebase-functions/v2/firestore");
const {onCall, onRequest, HttpsError} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const {getStorage} = require("firebase-admin/storage");

admin.initializeApp();

const REGION = "europe-west1";
const BACKFILL_SECRET = "backfill-1a94a6e1-9f9a-4e4a-9d36-5f93b1d8f5d2";

exports.checkUsernameAvailability = onCall({region: REGION}, async (request) => {
  const raw = (request.data?.username || "").toString().trim();
  const normalized = raw.toLowerCase();

  if (normalized.length < 3) {
    return {available: false};
  }

  const doc = await admin.firestore()
    .collection("usernames")
    .doc(normalized)
    .get();

  return {available: !doc.exists};
});

exports.claimUsername = onCall({region: REGION}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Utilisateur non connecté.");
  }

  const raw = (request.data?.username || "").toString().trim();
  const normalized = raw.toLowerCase();
  const previousRaw = (request.data?.previousUsername || "").toString().trim();
  const previous = previousRaw.toLowerCase();

  if (normalized.length < 3) {
    throw new HttpsError("invalid-argument", "Nom d'utilisateur invalide.");
  }

  const uid = request.auth.uid;
  const db = admin.firestore();
  const desiredRef = db.collection("usernames").doc(normalized);
  const userRef = db.collection("users").doc(uid);
  const previousRef = previous && previous !== normalized
    ? db.collection("usernames").doc(previous)
    : null;

  try {
    const desiredSnap = await desiredRef.get();
    if (desiredSnap.exists) {
      const owner = desiredSnap.get("uid");
      if (owner !== uid) {
        throw new HttpsError("already-exists", "Nom d'utilisateur déjà pris.");
      }
      await desiredRef.set({
        username: raw,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, {merge: true});
    } else {
      await desiredRef.create({
        uid,
        username: raw,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    if (previousRef) {
      const previousSnap = await previousRef.get();
      if (previousSnap.exists && previousSnap.get("uid") === uid) {
        await previousRef.delete();
      }
    }

    await userRef.set({
      username: raw,
      username_lower: normalized,
      usernameLastChangedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError("internal", error?.message || "Erreur interne.");
  }

  return {username: raw, usernameLower: normalized};
});

exports.backfillUsernames = onCall({region: REGION}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Utilisateur non connecté.");
  }

  const allowedEmails = new Set([
    "soula.corentin@icloud.com",
    "soula.corentin@gmail.com",
  ]);

  const tokenEmail = (request.auth.token?.email || "").toLowerCase();
  const identityEmail = Array.isArray(request.auth.token?.firebase?.identities?.email)
    ? String(request.auth.token.firebase.identities.email[0] || "").toLowerCase()
    : "";
  const email = tokenEmail || identityEmail;
  if (!allowedEmails.has(email)) {
    throw new HttpsError("permission-denied", "Accès refusé.");
  }

  const db = admin.firestore();
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

  return {created, skipped, conflicts, total: usersSnap.size};
});

exports.backfillUsernamesHttp = onRequest(
  {region: REGION, invoker: "public"},
  async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method Not Allowed");
    return;
  }

  if (req.query.secret !== BACKFILL_SECRET) {
    res.status(403).send("Forbidden");
    return;
  }

  const db = admin.firestore();
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

  res.json({created, skipped, conflicts, total: usersSnap.size});
});

/**
 * Fonction schedulée qui s'exécute tous les jours à 21h
 * Supprime les victoires expirées (24h de visibilité)
 *
 * Le feed se rafraîchit à 21h : les photos de la veille disparaissent
 * Coût estimé: ~$0.004/mois (30 exécutions par mois)
 */
exports.cleanupExpiredVictories = onSchedule({
  schedule: "0 21 * * *",  // Tous les jours à 21h (heure de Paris)
  timeZone: "Europe/Paris",
  region: REGION,
}, async (event) => {
  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();

  console.log("🧹 Début du nettoyage des victoires expirées...");

  try {
    // Trouver toutes les victoires expirées (expiresAt < now)
    const expiredVictories = await db.collection("victories")
      .where("expiresAt", "<", now)
      .get();

    console.log(`📊 ${expiredVictories.size} victoires expirées trouvées`);

    if (expiredVictories.empty) {
      console.log("✅ Aucune victoire à nettoyer");
      return null;
    }

    // Supprimer chaque victoire et sa photo
    const deletePromises = expiredVictories.docs.map(async (doc) => {
      const victory = doc.data();
      const victoryId = doc.id;

      try {
        // 1. Supprimer la photo de Storage
        if (victory.photoURL) {
          await deletePhotoFromURL(victory.photoURL);
          console.log(`🗑️  Photo supprimée pour victoire ${victoryId}`);
        }

        // 2. Supprimer le document Firestore (qui déclenchera la suppression des commentaires)
        await doc.ref.delete();
        console.log(`✅ Victoire ${victoryId} supprimée`);

        return {success: true, victoryId};
      } catch (error) {
        console.error(`❌ Erreur pour victoire ${victoryId}:`, error);
        return {success: false, victoryId, error: error.message};
      }
    });

    const results = await Promise.all(deletePromises);
    const successCount = results.filter((r) => r.success).length;
    const failureCount = results.filter((r) => !r.success).length;

    console.log(`✅ Nettoyage terminé: ${successCount} réussites, ${failureCount} échecs`);

    return {
      totalProcessed: expiredVictories.size,
      successCount,
      failureCount,
    };
  } catch (error) {
    console.error("❌ Erreur globale du nettoyage:", error);
    throw error;
  }
});

exports.sendNotificationPush = onDocumentCreated(
  {document: "notifications/{notificationId}", region: REGION},
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const toUserId = data.toUserId;
    const fromUserId = data.fromUserId;
    const type = data.type || "mention";

    if (!toUserId || toUserId === fromUserId) return;

    const userSnap = await admin.firestore().collection("users").doc(toUserId).get();
    const tokens = userSnap.get("fcmTokens") || [];

    if (!Array.isArray(tokens) || tokens.length === 0) return;

    const fromName = data.fromDisplayName || data.fromUsername || "Quelqu'un";
    const title = "Hourglass";
    let body = `${fromName} t'a mentionné`;

    if (type === "comment") {
      body = `${fromName} a commenté ta victoire`;
    } else if (type === "boost") {
      body = `${fromName} t'a donné un grain`;
    } else if (type === "friend_request") {
      body = `${fromName} veut être ton complice`;
    }

    const message = {
      tokens,
      notification: {title, body},
      data: {
        type: String(type),
        victoryId: String(data.victoryId || ""),
        requestId: String(data.requestId || ""),
      },
    };

    const response = await admin.messaging().sendEachForMulticast(message);
    const invalidTokens = [];
    response.responses.forEach((result, index) => {
      if (result.error) {
        const code = result.error.code || "";
        if (code.includes("registration-token-not-registered") ||
            code.includes("invalid-registration-token")) {
          invalidTokens.push(tokens[index]);
        }
      }
    });

    if (invalidTokens.length > 0) {
      await admin.firestore().collection("users").doc(toUserId).updateData({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...invalidTokens),
      });
    }
  }
);

/**
 * Fonction déclenchée automatiquement quand une victoire est supprimée
 * Supprime tous les commentaires associés
 *
 * Coût: Gratuit (déclenché automatiquement, pas de schedule)
 */
exports.deleteVictoryComments = onDocumentDeleted({
  document: "victories/{victoryId}",
  region: REGION,
}, async (event) => {
  const victoryId = event.params.victoryId;
  const db = admin.firestore();

  console.log(`🗑️  Suppression des commentaires pour victoire ${victoryId}`);

  try {
    // Récupérer tous les commentaires de cette victoire
    const commentsSnapshot = await db.collection("victories")
      .doc(victoryId)
      .collection("comments")
      .get();

    if (commentsSnapshot.empty) {
      console.log(`✅ Aucun commentaire à supprimer pour ${victoryId}`);
      return null;
    }

    // Supprimer tous les commentaires en batch
    const batch = db.batch();
    commentsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`✅ ${commentsSnapshot.size} commentaires supprimés pour ${victoryId}`);

    return {deletedComments: commentsSnapshot.size};
  } catch (error) {
    console.error(`❌ Erreur suppression commentaires ${victoryId}:`, error);
    throw error;
  }
});

/**
 * Fonction utilitaire pour supprimer une photo depuis son URL
 */
async function deletePhotoFromURL(photoURL) {
  try {
    // Extraire le chemin du fichier depuis l'URL
    // Format: https://firebasestorage.googleapis.com/.../o/victories%2F{userId}%2F{timestamp}.jpg?...
    const decodedURL = decodeURIComponent(photoURL);
    const pathMatch = decodedURL.match(/\/o\/(.+?)\?/);

    if (!pathMatch || !pathMatch[1]) {
      console.warn("⚠️  Impossible d'extraire le chemin de l'URL:", photoURL);
      return;
    }

    const filePath = pathMatch[1];
    const bucket = getStorage().bucket();
    const file = bucket.file(filePath);

    // Vérifier si le fichier existe
    const [exists] = await file.exists();
    if (!exists) {
      console.warn(`⚠️  Fichier déjà supprimé: ${filePath}`);
      return;
    }

    // Supprimer le fichier
    await file.delete();
    console.log(`✅ Fichier supprimé: ${filePath}`);
  } catch (error) {
    console.error("❌ Erreur suppression photo:", error);
    // Ne pas throw pour ne pas bloquer la suppression de la victoire
  }
}
