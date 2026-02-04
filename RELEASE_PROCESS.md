# Release & Signing Manual for MultiMail

This document outlines the exact process to build, sign, and release MultiMail for clients. Follow these steps to ensure the app runs on other Macs without security warnings or "App is damaged" errors.

## 1. Prerequisites
- An active **Apple Developer Program** membership ($99/year).
- A **Developer ID Application** certificate installed in your Keychain (Xcode usually manages this).

## 2. One-Time Project Configuration
*Do this once before your first release.*

### A. Signing & Identity
1.  Select **MultiMail** project -> Targets -> **MultiMail**.
2.  **General** tab:
    - Set a unique **Bundle Identifier** (e.g., `com.yourcompany.MultiMail`).
3.  **Signing & Capabilities** tab:
    - **Team**: Select your paid Developer Team.
    - **App Sandbox**: ❌ **DELETE THIS**. (Click the 'X' button).
        - *Why? Sandbox blocks AppleScript automation by default. For internal utility apps, disabling it is safest.*
    - **Hardened Runtime**: ✅ **ADD THIS** (via "+ Capability").
        - **Resource Access** -> Check **Apple Events**.
        - *Why? Required for Notarization + Mail automation.*

### B. Info.plist
1.  Go to **Info** tab.
2.  Ensure this Key exists: `Privacy - AppleEvents Sending Usage Description`.
3.  Value: `MultiMail needs to control Mail.app to send your emails.`

---

## 3. The Release Build Process (Every Update)

### Step 1: Archive
1.  In Xcode, set destination to **Any Mac (Apple Silicon, Intel)**.
2.  Menu: **Product** -> **Archive**.
3.  Wait for the build to finish. The "Organizer" window will open.

### Step 2: Distribute (Notarization)
*This sends the app to Apple to prove it has no malware. Essential for client trust.*
1.  Select your new Archive.
2.  Click **Distribute App**.
3.  Method: **Developer ID** -> **Next**.
4.  Destination: **Upload** (Recommended) -> **Next**.
5.  Wait for Xcode to upload and process (2-5 minutes).
    - *You can close the window; Xcode will notify you when "Ready to Export".*

### Step 3: Export
1.  Once approved (green checkmark), select the Archive again.
2.  Click **Export**.
3.  Save the `MultiMail.app` to your desktop.

---

## 4. Verification (Optional but Smart)
Before sending to the client, verify the "staple" and signature.

open Terminal and run:
```bash
spctl --assess --type execute --verbose /path/to/MultiMail.app
```
**Success Output:** `source=Notarized Developer ID`
*If you see this, the app will launch on ANY Mac.*

---

## 5. Client Instructions / Usage Guide
*Copy-paste this to your client email.*

### How to Install
1.  Drag **MultiMail** into your **Applications** folder.
2.  Double-click to open.

### First Time Setup
1.  Configure your email account in the standard Apple **Mail** app first.
2.  Open **MultiMail**.
3.  Import your CSV (Name, Email).
4.  Write your message.
5.  Click **"Start Campaign"**.
6.  ⚠️ **Important:** You will see a popup: *"MultiMail" wants access to control "Mail".*
    - You **MUST click OK**.
    - If you click "Don't Allow", the app will not work. (Fix in *System Settings > Privacy > Automation*).

### Troubleshooting
- **"Application isn't running" Error**: The app tries to launch Mail automatically, but if it fails, simply open Mail.app manually and try again.
- **Button Disabled?**: Ensure you have imported contacts and typed a subject line.
