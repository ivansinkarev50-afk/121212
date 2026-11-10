# VANTA WALLET — GitHub build package

This repository builds the native SwiftUI iOS app on a GitHub-hosted macOS runner.

## Upload to GitHub

1. Create a new **private** repository on https://github.com/new.
2. Extract this ZIP on Windows.
3. Upload the contents of this folder to the repository root (not the containing folder).
4. Commit to the `main` branch.

## Build the IPA

1. Open the repository on GitHub.
2. Select **Actions**.
3. Open **Build VANTA WALLET IPA**.
4. Press **Run workflow** (or push to `main` to start automatically).
5. Wait for the workflow to finish.
6. Open the successful run and download the artifact named `VANTA-WALLET-unsigned-IPA`.
7. Extract the downloaded artifact ZIP. It contains `VANTA-WALLET-unsigned.ipa`.

## Install on your iPhone (free Apple ID)

The workflow intentionally produces an **unsigned IPA**. It does not contain a developer certificate or provisioning profile and cannot be installed by tapping it.

On Windows:
1. Install Sideloadly from https://sideloadly.io/.
2. Connect your iPhone by USB and trust the computer.
3. Open Sideloadly, select the unsigned IPA, and enter your Apple ID when prompted.
4. Start sideloading and complete any Apple two-factor authentication prompts.
5. If Apple requires it, create an app-specific password / use the sign-in flow presented by Sideloadly. Never share your Apple ID password with anyone.
6. With a free Apple ID, the app signing typically expires after 7 days; refresh/reinstall it through Sideloadly.

## Important

- This is a native SwiftUI app, not a web app.
- All portfolio balances, prices, and charts are DEMO data. No real crypto is held and no transactions are sent.
- The workflow compiles with the Swift 6 toolchain in Swift 5 language-compatibility mode to avoid strict-concurrency diagnostics in the initial build.
- GitHub Actions uses hosted macOS minutes; availability/quotas depend on your GitHub account.
- The workflow has not been run in this environment. If the build fails, open the Actions log and share the error so it can be fixed.
