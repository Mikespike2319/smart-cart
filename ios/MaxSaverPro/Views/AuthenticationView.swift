import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var fullName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Smart Cart")
                    .font(.largeTitle)
                    .bold()
                
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.title2)
                
                VStack(spacing: 15) {
                    if isSignUp {
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding(.horizontal)
                
                Button(action: performAuthentication) {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: { isSignUp.toggle() }) {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .foregroundColor(.blue)
                }
                
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
    }
    
    private func performAuthentication() {
        // TODO: Implement actual authentication
        // For now, just simulate successful login
        appState.isAuthenticated = true
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppState())
} 