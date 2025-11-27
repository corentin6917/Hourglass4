import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var showPassword: Bool = false
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case email, password }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Connexion")
                    .font(.largeTitle)
                    .bold()

                VStack(alignment: .leading, spacing: 8) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .email)
                        .padding(12)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField("Mot de passe", text: $password)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                            } else {
                                SecureField("Mot de passe", text: $password)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                            }
                        }
                        .padding(12)
                        .padding(.trailing, 40)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                    }
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                } else if let infoMessage = infoMessage {
                    Text(infoMessage)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                Button(action: signIn) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Se connecter")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.isEmpty || password.isEmpty)

                Button("Mot de passe oublié ?") {
                    resetPassword()
                }
                .disabled(isLoading || email.isEmpty)

                HStack(spacing: 8) {
                    Text("Pas de compte ?")
                    NavigationLink("Créer un compte") {
                        SignUpView()
                    }
                }
                .font(.footnote)
                .padding(.top, 4)

                Spacer()
            }
            .padding()
        }
    }

    private func signIn() {
        errorMessage = nil
        infoMessage = nil
        isLoading = true

        // Nettoyer l'email comme dans SignUpView
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        Auth.auth().signIn(withEmail: cleanEmail, password: password) { _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = mapAuthError(error)
                    let nsError = error as NSError
                    if AuthErrorCode(_bridgedNSError: nsError)?.code == .wrongPassword {
                        password = ""
                        focusedField = .password
                    }
                }
                // En cas de succès, RootView détectera l'état et basculera automatiquement.
            }
        }
    }

    private func resetPassword() {
        errorMessage = nil
        infoMessage = nil
        guard !email.isEmpty else {
            errorMessage = "Saisis ton email pour réinitialiser le mot de passe."
            return
        }
        isLoading = true
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        Auth.auth().sendPasswordReset(withEmail: cleanEmail) { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = mapAuthError(error)
                } else {
                    infoMessage = "Un email de réinitialisation a été envoyé si un compte existe pour cet email."
                }
            }
        }
    }

    private func mapAuthError(_ error: Error) -> String {
        let nsError = error as NSError
        if let code = AuthErrorCode(_bridgedNSError: nsError)?.code {
            switch code {
            case .userNotFound:
                return "Aucun compte n'existe pour cet email."
            case .wrongPassword:
                return "Mot de passe incorrect."
            case .invalidEmail:
                return "Adresse email invalide."
            case .tooManyRequests:
                return "Trop de tentatives. Réessaie plus tard."
            case .networkError:
                return "Problème de réseau. Vérifie ta connexion."
            default:
                break
            }
        }
        return nsError.localizedDescription
    }
}

#Preview {
    LoginView()
}
