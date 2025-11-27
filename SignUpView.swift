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
            ScrollView {
                VStack(spacing: 16) {
                    Text("Créer un compte")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 24)

                    // Email
                    TextField("Adresse e-mail", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    // Nom d'utilisateur avec vérification
                    VStack(alignment: .leading, spacing: 4) {
                        ZStack(alignment: .trailing) {
                            TextField("Nom d'utilisateur", text: $username)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .padding(.trailing, 40)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                                .onChange(of: username) { oldValue, newValue in
                                    checkUsernameAvailability()
                                }

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

                    // Nom d'affichage
                    TextField("Nom d'affichage (optionnel)", text: $displayName)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    // Sexe
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sexe")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Picker("Sexe", selection: $gender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.displayName).tag(gender)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Date de naissance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date de naissance (minimum 13 ans)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        DatePicker("", selection: $birthDate, in: minimumBirthDate...maximumBirthDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                    }

                    // Mot de passe
                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField("Mot de passe", text: $password)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Mot de passe", text: $password)
                                    .textContentType(.newPassword)
                            }
                        }
                        .padding()
                        .padding(.trailing, 40)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                        Button(action: {
                            showPassword.toggle()
                        }) {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                    }

                    // Confirmer mot de passe
                    ZStack(alignment: .trailing) {
                        Group {
                            if showConfirmPassword {
                                TextField("Confirmer le mot de passe", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            } else {
                                SecureField("Confirmer le mot de passe", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                        }
                        .padding()
                        .padding(.trailing, 40)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                        Button(action: {
                            showConfirmPassword.toggle()
                        }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    if let infoMessage = infoMessage {
                        Text(infoMessage)
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button(action: signUp) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        } else {
                            Text("Créer le compte")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                    .disabled(isLoading || usernameAvailable == false)

                    Button("Retour") {
                        dismiss()
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
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

            // Créer le profil dans Firestore
            Task {
                do {
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
