import Flutter
import UIKit
import LocalAuthentication

public class SwiftDidChangeAuthlocalPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "did_change_authlocal", binaryMessenger: registrar.messenger())
        let instance = SwiftDidChangeAuthlocalPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "didChangeBiometric":
                self.didChangeBiometric(result: result)
            case "createBiometricState":
                self.createBiometricState(result: result)
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    private func createBiometricState(result: @escaping FlutterResult) {
        let context = LAContext()
        LAContext.savedBiometricsPolicyState = context.evaluatedPolicyDomainState
        return result(true)
    }

    private func didChangeBiometric(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?
        
       // Check if biometrics can be evaluated
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError, laError.code == .biometryLockout {
                // Handle temporary lockout differently if desired
                return result(FlutterError(code: "BIOMETRICS_LOCKED", message: "Biometrics is temporarily locked", details: laError.localizedDescription))
            } else {
                // Handle other biometric errors
                return result(FlutterError(code: "BIOMETRICS_UNAVAILABLE", message: "Biometrics is not available", details: error?.localizedDescription))
            }
        }

        // Check if biometrics have changed
        if LAContext.biometricsChanged() {
            return result(500)  // Biometric data has changed
        } else {
            return result(200)  // Biometric data has not changed
        }
    }
}

extension LAContext {
    static var savedBiometricsPolicyState: Data? {
        get {
            UserDefaults.standard.data(forKey: "BiometricsPolicyState")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "BiometricsPolicyState")
        }
    }

    static func biometricsChanged() -> Bool {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        // If there is no saved policy state yet, save it
        if let domainState = context.evaluatedPolicyDomainState {
            if LAContext.savedBiometricsPolicyState == nil {
                LAContext.savedBiometricsPolicyState = domainState
                return false
            }

            if domainState != LAContext.savedBiometricsPolicyState {
                // Biometric data has changed
                return true
            }
        }

        return false
    }
}
