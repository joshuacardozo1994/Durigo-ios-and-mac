//
//  View+Extensions.swift
//  Durigo
//
//  Created by Joshua Cardozo on 29/12/23.
//

import SwiftUI
import LocalAuthentication

struct BiometricLock: ViewModifier {
    @Environment(\.scenePhase) var scenePhase
    @State private var isUnlocked = false
    private func authenticateWithBiometrics() {
            let context = LAContext()

            var error: NSError?

            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Authenticate to unlock the screen"
                
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                    DispatchQueue.main.async {
                        if success {
                            isUnlocked = true
                        } else {
                            // Handle authentication failure
                            if let error = authenticationError as? LAError {
                                switch error.code {
                                case .userFallback:
                                    // User tapped "Enter Password"
                                    // You can provide an alternative method for authentication here.
                                    break
                                default:
                                    // Handle other authentication errors
                                    break
                                }
                            }
                        }
                    }
                }
            } else {
                // Device doesn't support biometric authentication or has no enrolled biometrics.
                // Handle accordingly.
            }
        }
    func body(content: Content) -> some View {
        VStack {
            if isUnlocked {
                content
            } else {
                VStack {
                    ContentUnavailableView("You do not have access to this screen", systemImage: "exclamationmark.triangle", description: Text("Please click unlock, to unlock the screen"))
                    Button(action: { authenticateWithBiometrics() }) {
                        Label("Unlock", systemImage: "lock.open.fill")
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .inactive {
                isUnlocked = false
            } else if newPhase == .background {
                isUnlocked = false
            }
        }
        .task {
            if !isUnlocked {
                authenticateWithBiometrics()
            }
        }
    }
}

extension View {
    func lockWithBiometric() -> some View {
        modifier(BiometricLock())
    }
}
