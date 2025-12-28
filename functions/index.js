/**
 * Firebase Cloud Functions pour Hourglass 4
 *
 * Fonction principale: Suppression automatique des photos de victoires après 48h
 */

const {onSchedule} = require("firebase-functions/v2/scheduler");
const {onDocumentDeleted} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {getStorage} = require("firebase-admin/storage");

admin.initializeApp();

/**
 * Fonction schedulée qui s'exécute tous les jours à 22h
 * Supprime les victoires expirées (> 48h) et leurs photos
 *
 * Photos supprimées entre 48h et 72h après création (selon l'heure de validation)
 * Coût estimé: ~$0.004/mois (30 exécutions par mois)
 */
exports.cleanupExpiredVictories = onSchedule({
  schedule: "0 22 * * *",  // Tous les jours à 22h (heure de Paris)
  timeZone: "Europe/Paris",
  region: "europe-west1",
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

/**
 * Fonction déclenchée automatiquement quand une victoire est supprimée
 * Supprime tous les commentaires associés
 *
 * Coût: Gratuit (déclenché automatiquement, pas de schedule)
 */
exports.deleteVictoryComments = onDocumentDeleted({
  document: "victories/{victoryId}",
  region: "europe-west1",
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
