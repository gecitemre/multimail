# MultiMail - Bulk Email Utility for macOS

MultiMail is a SwiftUI-based macOS application that automates Apple Mail (Mail.app) to send personalized emails one by one.

## Features
- Import contacts via CSV (Name, Email columns required).
- Personalize emails using `{{name}}` placeholder.
- Send using standard Mail.app account (no SMTP credentials needed).
- Throttle sending with random delays to look human.
- Pause/Resume support.

## Project Setup

Since this is provided as source files, you need to create an Xcode project:

1. Open Xcode -> Create a new Xcode Project.
2. Select **macOS** -> **App**.
3. Name it `MultiMail`.
   - Interface: **SwiftUI**
   - Language: **Swift**
4. Delete the default `ContentView.swift` and `MultiMailApp.swift` (or rename yours).
5. Drag and drop all Swift files from the `MultiMail_Sources` folder into your new Xcode project under the main group.
   - `Models.swift`
   - `MailService.swift`
   - `CSVImporter.swift`
   - `SenderEngine.swift`
   - `ContentView.swift`
   - `MultiMailApp.swift` (Ensure this replaces the default App entry point)

## Permissions Configuration (Important)

For the app to control Mail.app, you must declare usage in `Info.plist`.

1. In Xcode, click on the Project Target -> **Info** tab.
2. Add a new Key: `Privacy - AppleEvents Sending Usage Description` (Key: `NSAppleEventsUsageDescription`).
3. Value: "MultiMail needs to control Mail.app to send your emails automatically."

## Hardened Runtime & Entitlements

If you plan to distribute this app (even outside the App Store), you **must** enabled Hardened Runtime and add the Apple Events entitlement.

1. Go to Project Target -> **Signing & Capabilities**.
2. If **Hardened Runtime** is not there, click "+ Capability" and add it.
3. Under **Hardened Runtime** -> **Resource Access**, check **Apple Events**.
   - This adds `com.apple.security.automation.apple-events` to your entitlements file.
   - *Without this, the app will crash or silently fail when trying to script Mail on other machines.*

## Building & Code Signing

To run on another Mac without Gatekeeper blocking it, you must sign it with a Developer ID.

### 1. Archive
- Product -> Archive.

### 2. Export & Sign
- In Organizer, click "Distribute App".
- Select method: **Developer ID** (for direct distribution).
- Select **Upload** (to send to Apple for Notarization) or **Export** (if you just want to sign locally, though Gatekeeper requires Notarization for full acceptance).
- If you just want to sign it locally without Notarization (for internal use on machines where you can bypass Gatekeeper warnings once):
  - Export as "Copy App".
  
### Manual Verification
To verify the signature of your built `.app`:

```bash
codesign -dv --verbose=4 /path/to/MultiMail.app
```

Check for `Authority=Developer ID Application: Your Name (TeamID)`.

## Troubleshooting

- **"User sent valid data but..." Error**: This usually means permissions were denied. Go to System Settings -> Privacy & Security -> Automation and ensure MultiMail is checked under Mail.
- **CSV Not Importing**: Make sure your CSV has headers `Name, Email`.

## Limits
- This app acts as a remote control for Mail.app. Mail.app must be running (it will launch automatically).
- Do not touch Mail.app while sending to avoid interfering with window focus (though the script is designed to be background-friendly where possible).
