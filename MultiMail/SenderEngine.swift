import Foundation
import Combine

@MainActor
class SenderEngine: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var status: SendStatus = .idle
    @Published var currentProgress: Int = 0
    @Published var logs: [String] = []
    
    @Published var subject: String = ""
    @Published var senderEmail: String = ""
    @Published var bodyTemplate: String = ""
    @Published var minDelay: Double = 2.0
    @Published var maxDelay: Double = 5.0
    
    private var sendingTask: Task<Void, Never>?
    private var shouldStop = false
    private var isPaused = false
    
    func start() {
        guard status != .sending else { return }
        guard !contacts.isEmpty, !subject.isEmpty, !bodyTemplate.isEmpty else {
            logs.append("Error: Missing details to start sending.")
            return
        }
        
        status = .sending
        shouldStop = false
        isPaused = false
        
        sendingTask = Task {
            for index in contacts.indices {
                if shouldStop { break }
                
                while isPaused {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    if shouldStop { break }
                }
                if shouldStop { break }
                
                if contacts[index].status == .sent { continue }
                
                let contact = contacts[index]
                let personalizedBody = bodyTemplate.replacingOccurrences(of: "{{name}}", with: contact.name)
                
                do {
                    // Send with optional sender override
                    let from = senderEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : senderEmail
                    try await MailService.shared.sendEmail(recipient: contact.email, subject: subject, body: personalizedBody, sender: from)
                    contacts[index].status = .sent
                    logs.append("[\(Date())] Sent to: \(contact.email)")
                } catch {
                    contacts[index].status = .failed(error.localizedDescription)
                    logs.append("[\(Date())] Failed: \(contact.email) - \(error.localizedDescription)")
                }
                
                currentProgress = index + 1
                
                let delay = Double.random(in: minDelay...maxDelay)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            status = shouldStop ? .idle : .completed
            logs.append(shouldStop ? "Job Stopped." : "Job Completed.")
        }
    }
    
    func pause() {
        isPaused = true
        status = .paused
        logs.append("Paused.")
    }
    
    func resume() {
        isPaused = false
        status = .sending
        logs.append("Resuming...")
    }
    
    func stop() {
        shouldStop = true
        sendingTask?.cancel()
        status = .idle
        logs.append("Stopped.")
    }
    
    func importContacts(from url: URL) {
        // Gain access to the file if it's from a file picker
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        
        do {
            let newContacts = try CSVImporter.parseCSV(url: url)
            self.contacts = newContacts
            self.logs.append("Imported \(newContacts.count) contacts.")
            self.status = .idle
            self.currentProgress = 0
        } catch {
            self.logs.append("Error importing CSV: \(error.localizedDescription)")
        }
    }
}
