import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct HTMLPreviewView: NSViewRepresentable {
    let html: String
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground") // Transparent background
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(html, baseURL: nil)
    }
}

struct ContentView: View {
    @StateObject private var engine = SenderEngine()
    @State private var isImporting = false
    @State private var showingPreview = false
    
    var body: some View {
        HSplitView {
            // Left Side: Contacts
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.accentColor)
                    Text("Contacts")
                        .font(.headline)
                    Text("(\(engine.contacts.count))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { isImporting = true }) {
                        Image(systemName: "plus")
                        Text("Import")
                    }
                    .buttonStyle(.bordered)
                    .fileImporter(isPresented: $isImporting, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
                        switch result {
                        case .success(let url):
                            engine.importContacts(from: url)
                        case .failure(let error):
                            engine.logs.append("Import failed: \(error.localizedDescription)")
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                List(engine.contacts) { contact in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(contact.name)
                                .font(.system(size: 13, weight: .semibold))
                            Text(contact.email)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        StatusIcon(status: contact.status)
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 280, maxWidth: 350)
            
            // Right Side: Editor & Controls
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Editor Group
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Compose Message")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            TextField("Subject", text: $engine.subject)
                                .textFieldStyle(.plain)
                                .font(.title3)
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color(NSColor.controlBackgroundColor)))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                            
                            HStack {
                                Text("HTML Body")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button(showingPreview ? "Hide Preview" : "Show Preview") {
                                    showingPreview.toggle()
                                }
                                .buttonStyle(.link)
                                .font(.caption)
                            }
                            
                            VStack(spacing: 0) {
                                TextEditor(text: $engine.bodyTemplate)
                                    .font(.system(.body, design: .monospaced))
                                    .frame(minHeight: 250)
                                    .padding(4)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .onChange(of: engine.bodyTemplate) { _ in } // Force update trigger
                                
                                if showingPreview {
                                    Divider()
                                    VStack(alignment: .leading) {
                                        Text("Preview (with sample name)")
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.top, 4)
                                            .foregroundColor(.accentColor)
                                        
                                        HTMLPreviewView(html: engine.bodyTemplate.replacingOccurrences(of: "{{name}}", with: engine.contacts.first?.name ?? "Recipient Name"))
                                            .frame(height: 200)
                                            .background(Color.white)
                                            .cornerRadius(4)
                                            .padding(8)
                                    }
                                    .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
                                }
                            }
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
                            
                            Text("Use {{name}} to insert recipient's name.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Settings & Controls
                        HStack(alignment: .top, spacing: 20) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Speed Settings")
                                    .font(.headline)
                                
                                HStack {
                                    Text("Delay:")
                                    TextField("Min", value: $engine.minDelay, formatter: NumberFormatter())
                                        .frame(width: 40)
                                        .textFieldStyle(.roundedBorder)
                                    Text("to")
                                    TextField("Max", value: $engine.maxDelay, formatter: NumberFormatter())
                                        .frame(width: 40)
                                        .textFieldStyle(.roundedBorder)
                                    Text("sec")
                                }
                                .font(.subheadline)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 10) {
                                Text("Campaign Control")
                                    .font(.headline)
                                
                                HStack(spacing: 12) {
                                    if engine.status == .sending {
                                        Button(action: { engine.pause() }) {
                                            Label("Pause", systemImage: "pause.fill")
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button(action: { engine.stop() }) {
                                            Label("Stop", systemImage: "stop.fill")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.red)
                                    } else if engine.status == .paused {
                                        Button(action: { engine.resume() }) {
                                            Label("Resume", systemImage: "play.fill")
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.green)
                                        
                                        Button(action: { engine.stop() }) {
                                            Label("Stop", systemImage: "stop.fill")
                                        }
                                        .buttonStyle(.bordered)
                                    } else {
                                        Button(action: { engine.start() }) {
                                            Label("Start Campaign", systemImage: "paperplane.fill")
                                                .padding(.horizontal, 10)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.large)
                                        .disabled(engine.contacts.isEmpty || engine.subject.isEmpty || engine.bodyTemplate.isEmpty)
                                        .onChange(of: engine.contacts) { _ in }
                                        .onChange(of: engine.subject) { _ in }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.accentColor.opacity(0.05)))
                        
                        // Progress & Logs
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Live Progress")
                                    .font(.headline)
                                Spacer()
                                Text("\(engine.currentProgress) / \(engine.contacts.count) Processed")
                                    .font(.caption)
                                    .monospacedDigit()
                            }
                            
                            ProgressView(value: Double(engine.currentProgress), total: Double(max(1, engine.contacts.count)))
                                .progressViewStyle(.linear)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Activity Log")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(engine.logs.reversed(), id: \.self) { log in
                                            Text(log)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundColor(.secondary)
                                                .padding(.horizontal, 4)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(height: 100)
                                .background(Color.black.opacity(0.03))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .frame(minWidth: 500)
        }
    }
}

struct StatusIcon: View {
    let status: Contact.DeliveryStatus
    
    var body: some View {
        switch status {
        case .pending:
            Circle()
                .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
                .frame(width: 14, height: 14)
        case .sent:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 16))
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
                .font(.system(size: 16))
        }
    }
}
