import Foundation
import AppKit

enum MailError: Error, LocalizedError {
    case appleScriptError(String)
    case invalidDetails

    var errorDescription: String? {
        switch self {
        case .appleScriptError(let msg):
            return "AppleScript Error: \(msg)"
        case .invalidDetails:
            return "Invalid email details provided."
        }
    }
}

class MailService {
    static let shared = MailService()
    
    private init() {}
    
    /// Sends an email using Mail.app via AppleScript.
    func sendEmail(recipient: String, subject: String, body: String, sender: String? = nil) async throws {
        // 1. Ensure Mail is running using NSWorkspace (more reliable than AppleScript activate)
        guard let mailUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.mail") else {
            throw MailError.appleScriptError("Could not find Mail.app")
        }
        
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        
        // We calculate the path but we just want to ensure it's open. 
        // We wait for it to be running.
        if !NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == "com.apple.mail" }) {
            do {
                try await NSWorkspace.shared.openApplication(at: mailUrl, configuration: config)
                // Give it a moment to warm up
                try await Task.sleep(nanoseconds: 1_000_000_000)
            } catch {
                throw MailError.appleScriptError("Failed to launch Mail.app: \(error.localizedDescription)")
            }
        }

        guard !recipient.isEmpty, !subject.isEmpty else {
            throw MailError.invalidDetails
        }
        
        let escapedSubject = subject.appleScriptEscaped
        let escapedBody = body.appleScriptEscaped
        let escapedRecipient = recipient.appleScriptEscaped
        
        // Prepare sender assignment apple script part
        let senderProperty = sender != nil && !sender!.isEmpty ? "sender:\"\(sender!.appleScriptEscaped)\", " : ""
        
        // AppleScript to control Mail.app with HTML content support
        // We explicitly 'activate' to ensure the process is running and can receive commands.
        let scriptSource = """
        tell application "Mail"
            activate
            set theMessage to make new outgoing message with properties {\(senderProperty)subject:"\(escapedSubject)", visible:true}
            tell theMessage
                set html content to "\(escapedBody)"
                make new to recipient at end of to recipients with properties {address:"\(escapedRecipient)"}
            end tell
            send theMessage
        end tell
        """
        
        return try await withCheckedThrowingContinuation { continuation in
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: scriptSource) {
                let _ = scriptObject.executeAndReturnError(&error)
                if let error = error {
                    let errorMessage = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript Error"
                    continuation.resume(throwing: MailError.appleScriptError(errorMessage))
                } else {
                    continuation.resume(returning: ())
                }
            } else {
                continuation.resume(throwing: MailError.appleScriptError("Failed to initialize AppleScript"))
            }
        }
    }
}

fileprivate extension String {
    var appleScriptEscaped: String {
        return self.replacingOccurrences(of: "\\", with: "\\\\")
                   .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
