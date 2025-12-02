import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseDataConnect
import Default

// Script temporaire pour nettoyer la base de données

@main
struct CleanupScript {
    static func main() async {
        print("🧹 Nettoyage de la base de données...")

        // Configurer Firebase
        FirebaseApp.configure()

        do {
            // Se connecter avec un compte admin temporaire
            print("📋 Récupération de la liste des utilisateurs...")
            let helper = FirebaseDataConnectHelper.shared

            // Lister tous les utilisateurs
            let result = try await helper.connector.listAllUsersQuery.execute()
            let users = result.data.users

            print("✅ Trouvé \(users.count) utilisateurs:")
            for user in users {
                print("  - \(user.username) (\(user.email))")
            }

            // Supprimer chaque utilisateur
            print("\n🗑️  Suppression des utilisateurs...")
            for user in users {
                do {
                    let _ = try await helper.connector.deleteUserByUsernameMutation.execute(
                        username: user.username
                    )
                    print("  ✅ Supprimé: \(user.username)")
                } catch {
                    print("  ❌ Erreur lors de la suppression de \(user.username): \(error)")
                }
            }

            print("\n✨ Nettoyage terminé!")

        } catch {
            print("❌ Erreur: \(error)")
        }

        exit(0)
    }
}
