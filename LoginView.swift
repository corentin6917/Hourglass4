import SwiftUI
import FirebaseAuth

struct SimpleLoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?

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
                Auth.auth().signIn(withEmail: email, password: password) { result, error in
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                    } else {
                        self.errorMessage = nil
                    }
                }
            }) {
                Text("Se connecter")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }
}

#Preview {
    SimpleLoginView()
}
