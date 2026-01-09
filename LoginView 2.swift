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
            ZStack {
                LinearGradient(
                    colors: [
                        Color(uiColor: .systemGroupedBackground),
                        Color.orange.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                Circle()
                    .fill(Color.orange.opacity(0.08))
                    .frame(width: 260, height: 260)
                    .offset(x: 140, y: -220)

                Circle()
                    .fill(Color.orange.opacity(0.05))
                    .frame(width: 200, height: 200)
                    .offset(x: -160, y: 260)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                        formCard
                        footerSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            Image(systemName: "hourglass")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.orange)

            Text("Connexion")
                .font(.custom("AvenirNext-Medium", size: 18))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var formCard: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .foregroundStyle(.orange)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
                .padding(14)
                .background(fieldBackground)

                ZStack(alignment: .trailing) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .foregroundStyle(.orange)

                        Group {
                            if showPassword {
                                TextField("Mot de passe", text: $password)
                                    .textContentType(.password)
                            } else {
                                SecureField("Mot de passe", text: $password)
                                    .textContentType(.password)
                            }
                        }
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit { signIn() }
                    }
                    .padding(14)
                    .padding(.trailing, 36)
                    .background(fieldBackground)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 12)
                    }
                }
            }

            Button(action: signIn) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Se connecter")
                            .font(.custom("AvenirNext-DemiBold", size: 16))
                    }
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.orange, Color(red: 1.0, green: 0.6, blue: 0.0)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .orange.opacity(0.25), radius: 12, x: 0, y: 8)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)

            Button("Mot de passe oublié ?") {
                resetPassword()
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .disabled(isLoading || email.isEmpty)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            } else if let infoMessage = infoMessage {
                Text(infoMessage)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 10)
        )
    }

    private var footerSection: some View {
        HStack(spacing: 6) {
            Text("Pas de compte ?")
                .foregroundStyle(.secondary)
            NavigationLink("Créer un compte") {
                SignUpView()
            }
            .fontWeight(.semibold)
        }
        .font(.footnote)
        .padding(.top, 4)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(uiColor: .secondarySystemBackground))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
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
                } else {
                    Task {
                        try? await UserManager.shared.ensureCurrentUserProfile()
                        if let uid = Auth.auth().currentUser?.uid,
                           let profile = try? await UserManager.shared.getUserProfile(uid: uid) {
                            FindFriendViewModelV2.saveCurrentUsername(profile.username)
                        }
                    }
                    // En cas de succès, RootView détectera l'état et basculera automatiquement.
                }
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
