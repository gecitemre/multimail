# Professional Code Signing Guide for MultiMail

To distribute MultiMail as a standalone macOS app that runs on other Macs without Gatekeeper warnings, follow these steps exactly.

## 1. Prerequisites
- An active **Apple Developer Program** membership ($99/year) is required for "Developer ID" signing.
- A **Developer ID Application** certificate installed in your Keychain.

## 2. Project Configuration in Xcode

### A. Set Bundle Identifier
1. Select the **MultiMail** project in the navigator.
2. Select the **MultiMail** target.
3. In **General** > **Identity**, set a unique Bundle Identifier (e.g., `com.yourname.MultiMail`).

### B. Signing & Capabilities
1. Go to **Signing & Capabilities**.
2. **Team**: Select your developer team.
3. **App Sandbox**: 
   - While NOT required for non-App Store apps, if you keep it enabled, you MUST check:
     - **Outgoing Connections (Network)** -> Enabled.
     - **Hardware** > **Apple Events** -> Checked.
4. **Hardened Runtime** (MANDATORY for Notarization):
   - Click **+ Capability** if not present.
   - Under **Resource Access**, check **Apple Events**.
   - This allows the app to script Mail.app while the process is hardened.

### C. Info.plist Permissions
1. Go to **Info** tab.
2. Ensure `NSAppleEventsUsageDescription` is present.
   - Key: `Privacy - AppleEvents Sending Usage Description`
   - Value: `MultiMail needs to control Mail.app to send campaign emails.`

## 3. The Archiving & Export Process

### Step 1: Archive
1. In Xcode, set the run destination to **Any Mac (Apple Silicon, Intel)** or **My Mac**.
2. Go to **Product** > **Archive**.

### Step 2: Distribute for Notarization
1. When the Organizer window appears, select your archive and click **Distribute App**.
2. Select **Developer ID** (Standard for distribution outside App Store).
3. Select **Upload** (Highly recommended to Notarize with Apple).
   - This sends the app to Apple's automated scanner.
   - Once cleared (usually 2-5 mins), you will receive a notification.

### Step 3: Export
1. Once Notarized, click **Export** in the Organizer.
2. Xcode will attach the "ticket" to the app (stapling).
3. Save the `.app` to your Desktop.

## 4. Verification

To verify that the app is properly signed and notarized, run these commands in Terminal:

### Check Signature
```bash
codesign -dv --verbose=4 MultiMail.app
```
Expect: `Authority=Developer ID Application: Your Name (TEAM_ID)` and `runtime=true`.

### Check Gatekeeper Status
```bash
spctl --assess --type execute --verbose MultiMail.app
```
Expect: `accepted` and `source=Notarized Developer ID`.

## 5. Automation Permissions (User Experience)
When the user first clicks "Start Campaign":
1. macOS will show a prompt: `"MultiMail" wants access to control "Mail".`
2. The user must click **OK**.
3. If they click "Don't Allow", the app will fail with an AppleScript error. They can fix this in **System Settings** > **Privacy & Security** > **Automation**.

---
**Note on NO-SANDBOX Distribution**: If you prefer to disable the Sandbox entirely (since this is not for the App Store), ensure you still have **Hardened Runtime** enabled for Notarization compatibility.
