import SwiftUI
import FirebaseAuth

struct SignUpView: View {
    @State private var email = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var gender: Gender = .notSpecified
    @State private var birthDate = Date()
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var usernameAvailable: Bool? = nil
    @State private var isCheckingUsername = false

    @Environment(\.dismiss) private var dismiss

    // Date limite : minimum 13 ans
    private var maximumBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    }

    // Date minimum : maximum 120 ans
    private var minimumBirthDate: Date {
        Calendar.current.date(byAdding: .year, value: -120, to: Date()) ?? Date()
    }

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
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 34, weight: .light))
                .foregroundStyle(.orange)

            Text("Créer un compte")
                .font(.custom("AvenirNext-DemiBold", size: 22))
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

                    TextField("Adresse e-mail", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                .padding(14)
                .background(fieldBackground)

                VStack(alignment: .leading, spacing: 6) {
                    ZStack(alignment: .trailing) {
                        HStack(spacing: 10) {
                            Image(systemName: "at")
                                .foregroundStyle(.orange)

                            TextField("Nom d'utilisateur", text: $username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .onChange(of: username) { _, _ in
                                    checkUsernameAvailability()
                                }
                        }
                        .padding(14)
                        .padding(.trailing, 40)
                        .background(fieldBackground)

                        if isCheckingUsername {
                            ProgressView()
                                .padding(.trailing, 12)
                        } else if let available = usernameAvailable {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(available ? .green : .red)
                                .padding(.trailing, 12)
                        }
                    }

                    if let available = usernameAvailable, !available {
                        Text("Ce nom d'utilisateur est déjà pris")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.leading, 4)
                    }
                }

                HStack(spacing: 10) {
                    Image(systemName: "person")
                        .foregroundStyle(.orange)

                    TextField("Nom complet (optionnel)", text: $displayName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                }
                .padding(14)
                .background(fieldBackground)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Sexe")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("Sexe", selection: $gender) {
                    ForEach(Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                .pickerStyle(.segmented)
                .tint(.orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Date de naissance (minimum 13 ans)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                DatePicker("", selection: $birthDate, in: minimumBirthDate...maximumBirthDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(12)
                    .background(fieldBackground)
            }

            VStack(spacing: 12) {
                ZStack(alignment: .trailing) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .foregroundStyle(.orange)

                        Group {
                            if showPassword {
                                TextField("Mot de passe", text: $password)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Mot de passe", text: $password)
                                    .textContentType(.newPassword)
                            }
                        }
                    }
                    .padding(14)
                    .padding(.trailing, 40)
                    .background(fieldBackground)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 12)
                    }
                }

                ZStack(alignment: .trailing) {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.rotation")
                            .foregroundStyle(.orange)

                        Group {
                            if showConfirmPassword {
                                TextField("Confirmer le mot de passe", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Confirmer le mot de passe", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                        }
                    }
                    .padding(14)
                    .padding(.trailing, 40)
                    .background(fieldBackground)

                    Button {
                        showConfirmPassword.toggle()
                    } label: {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 12)
                    }
                }
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            if let infoMessage = infoMessage {
                Text(infoMessage)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }

            Button(action: signUp) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Créer le compte")
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
            .disabled(
                isLoading
                || email.isEmpty
                || username.isEmpty
                || password.isEmpty
                || confirmPassword.isEmpty
                || usernameAvailable == false
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 10)
        )
    }

    private var footerSection: some View {
        Button("Retour") {
            dismiss()
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
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

    private func checkUsernameAvailability() {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedUsername.count >= 3 else {
            usernameAvailable = nil
            return
        }

        isCheckingUsername = true
        usernameAvailable = nil

        Task {
            do {
                let available = try await UserManager.shared.isUsernameAvailable(trimmedUsername)
                await MainActor.run {
                    isCheckingUsername = false
                    usernameAvailable = available
                }
            } catch {
                await MainActor.run {
                    isCheckingUsername = false
                    usernameAvailable = nil
                }
            }
        }
    }

    private func signUp() {
        errorMessage = nil
        infoMessage = nil
        isLoading = true

        let e = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let u = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let d = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = password
        let cp = confirmPassword

        // Validations
        guard !e.isEmpty else {
            errorMessage = "L'adresse e-mail est obligatoire."
            isLoading = false
            return
        }
        guard !u.isEmpty else {
            errorMessage = "Le nom d'utilisateur est obligatoire."
            isLoading = false
            return
        }
        guard u.count >= 3 else {
            errorMessage = "Le nom d'utilisateur doit contenir au moins 3 caractères."
            isLoading = false
            return
        }
        guard usernameAvailable == true else {
            errorMessage = "Ce nom d'utilisateur n'est pas disponible."
            isLoading = false
            return
        }
        guard !p.isEmpty else {
            errorMessage = "Le mot de passe est obligatoire."
            isLoading = false
            return
        }
        guard p == cp else {
            errorMessage = "Les mots de passe ne correspondent pas."
            isLoading = false
            return
        }

        // Créer le compte Firebase Auth
        Auth.auth().createUser(withEmail: e, password: p) { result, error in
            if let error = error {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = mapAuthError(error)
                }
                return
            }

            guard let user = result?.user else {
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Une erreur inconnue est survenue."
                }
                return
            }

            // IMPORTANT: Créer le profil dans Data Connect
            Task {
                do {
                    // Créer le profil utilisateur dans Firestore (users/{uid})
                    try await UserManager.shared.createUserProfile(
                        uid: user.uid,
                        email: e,
                        username: u,
                        displayName: d.isEmpty ? nil : d,
                        gender: gender,
                        birthDate: birthDate
                    )

                    // Mettre à jour le displayName dans Firebase Auth si nécessaire
                    if !d.isEmpty {
                        let changeRequest = user.createProfileChangeRequest()
                        changeRequest.displayName = d
                        try? await changeRequest.commitChanges()
                    }

                    await MainActor.run {
                        // Sauvegarder le username pour l'utilisateur connecté
                        FindFriendViewModelV2.saveCurrentUsername(u)

                        isLoading = false
                        infoMessage = "Compte créé avec succès."
                        // L'utilisateur sera automatiquement connecté et redirigé par RootView
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Compte créé, mais erreur lors de la sauvegarde du profil: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private func mapAuthError(_ error: Error) -> String {
        guard let errCode = AuthErrorCode(_bridgedNSError: error as NSError) else {
            return "Erreur inconnue: \(error.localizedDescription)"
        }
        switch errCode.code {
        case .invalidEmail:
            return "L'adresse e-mail est invalide."
        case .emailAlreadyInUse:
            return "Cette adresse e-mail est déjà utilisée."
        case .weakPassword:
            return "Le mot de passe est trop faible. Il doit contenir au moins 6 caractères."
        case .networkError:
            return "Erreur réseau. Veuillez réessayer."
        case .userDisabled:
            return "Ce compte a été désactivé."
        default:
            return "Erreur inconnue: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SignUpView()
}
