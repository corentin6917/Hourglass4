import SwiftUI
import FirebaseAuth
import Default

struct SimpleLoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Connexion")
                .font(.largeTitle)
                .bold()

            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            SecureField("Mot de passe", text: $password)
                .textContentType(.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }

            Button(action: {
                signIn()
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text("Se connecter")
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(isLoading)
        }
        .padding()
    }

    private func signIn() {
        isLoading = true
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        Auth.auth().signIn(withEmail: trimmedEmail, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                return
            }

            Task {
                try? await UserManager.shared.ensureCurrentUserProfile()
            }

            // Après connexion réussie, récupérer le username depuis Data Connect
            Task {
                do {
                    let users = try await FirebaseDataConnectHelper.shared.getUserByEmail(email: trimmedEmail)
                    if let user = users.first {
                        // Sauvegarder le username dans UserDefaults
                        FindFriendViewModelV2.saveCurrentUsername(user.username)
                    }
                    await MainActor.run {
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.errorMessage = "Connexion réussie mais impossible de récupérer le profil: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }
    }
}

#Preview {
    SimpleLoginView()
}
