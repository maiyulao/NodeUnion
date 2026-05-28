# Privacy Policy

**Last updated:** May 28, 2026

This Privacy Policy describes how **NodeUnion** (the “App”) and its operators collect, use, store, and share information when you install or use the App on Android, Windows, macOS, or Linux.

NodeUnion is a cross-platform proxy client derived from [FlClash](https://github.com/chen08209/FlClash), built for proxy service providers (“operators”). Depending on how your build is distributed, the **operator** that ships the App to you may act as the data controller for operator-specific features (such as the provider portal and remote brand configuration). Technical support for the open-source fork is available on Telegram: [t.me/NodeUnion](https://t.me/NodeUnion).

If you do not agree with this policy, please do not use the App.

---

## 1. Summary

| Topic | What happens |
|-------|----------------|
| **Account with us** | The App does not require you to create an account with NodeUnion. |
| **Proxy traffic** | Network traffic is processed **on your device** by the embedded Clash.Meta (mihomo) core according to profiles and rules you configure or import. We do not operate a centralized proxy service as part of this App. |
| **Provider portal** | An in-app WebView may load your operator’s website URL from remote brand configuration. That site is controlled by your operator, not by us. |
| **Crash reporting (Android)** | Optional Firebase Crashlytics; **off by default** until you enable it in Settings. |
| **Advertising (Android / iOS)** | Optional Google AdMob, controlled remotely via brand configuration; may be disabled entirely. |
| **Backup** | Optional WebDAV or local file backup of your App data, initiated by you, to servers you choose. |

---

## 2. Information We Collect

### 2.1 Information you provide

- **Proxy profiles and rules:** Subscription URLs, YAML/JSON configuration, custom rules, DNS settings, policy groups, and related metadata you import, edit, or sync.
- **App preferences:** Language, theme, launch options, hotkeys, and other settings stored locally.
- **WebDAV credentials:** If you enable backup/restore, you may store server address, username, and password (or tokens) that you enter for **your** WebDAV service.
- **User-generated content:** Files you pick (e.g., configuration archives), images from the gallery if you choose a custom avatar, and QR codes you scan to import profiles.

We do not require your legal name, email, or phone number to use core proxy features.

### 2.2 Information collected automatically on your device

- **Device and environment:** Operating system, platform, app version, locale, screen characteristics, and similar technical identifiers used for compatibility and diagnostics.
- **Network state:** Connectivity status (e.g., online/offline, connection type) to manage proxy behavior and optional ads.
- **Traffic statistics:** Connection counts, speeds, and usage metrics shown in the dashboard are computed **locally** from the proxy core; they are not uploaded to us by default.
- **Logs:** Diagnostic logs you can view or export from the App; logging is under your control.
- **Installed applications (Android):** If you use per-app proxy or access-control features, the App may query installed package names on your device. This information stays on the device unless you explicitly back it up.

### 2.3 Information related to remote brand configuration

When your build includes compile-time brand configuration (`BRAND_CONFIG_URLS` and `BRAND_CONFIG_KEY`):

- The App fetches **encrypted** JSON from the configured CDN or static URLs, decrypts it on-device, and caches the result (provider display name, portal URL, optional ad unit IDs and display rules).
- The fetch reveals your IP address and request metadata to those hosting endpoints and any network path in between, as with any HTTPS request.

We do not receive this fetch on our own servers unless we also host your brand configuration file.

### 2.4 Information collected through third-party services

**Firebase (Android builds)**

- **Crashlytics (optional):** If you turn on “Crash Analysis” in Settings, crash stack traces, device model, OS version, and related diagnostic data may be sent to Google Firebase Crashlytics to improve stability. The in-app description states that this does not include personal sensitive data; collection can be disabled at any time in Settings.
- **Firebase Analytics:** The Android build may include Firebase Analytics as part of the Firebase SDK bundle. Analytics collection follows Google’s policies and your device settings.

**Google AdMob (Android and iOS, when enabled)**

- When brand configuration enables ads, the App may show banner, interstitial, native, or app-open ads. AdMob may collect advertising identifiers, IP address, device information, and interaction data per [Google’s Privacy Policy](https://policies.google.com/privacy) and [AdMob policies](https://support.google.com/admob/answer/6128543).
- Ad display frequency may be governed by remote cooldown rules in brand configuration.

**Operator websites (in-app WebView)**

- Pages loaded in the provider portal WebView may set cookies, local storage, or similar technologies under your operator’s privacy practices.
- Payment or login flows may open external apps (e.g., Alipay, WeChat) or the system browser at your confirmation.

---

## 3. How We Use Information

We use the information described above to:

- Provide, maintain, and improve proxy, DNS, routing, and dashboard features;
- Load operator branding and portal URLs from remote configuration;
- Show optional advertisements and enforce cooldown rules when enabled;
- Diagnose crashes and errors when you opt in to Crashlytics on Android;
- Perform backup and restore you request via WebDAV or files;
- Check for application updates when you enable automatic update checks;
- Comply with applicable law and protect the security of the App.

We do **not** sell your personal information. We do **not** use your proxied traffic content for advertising or profiling.

---

## 4. Local Processing and Your Responsibilities

- **Proxy operation:** The App implements a local VPN or system proxy (depending on platform) so that traffic is handled according to your configuration. You are responsible for complying with laws in your jurisdiction regarding VPN/proxy use, circumvention, and the services you access.
- **Configuration sources:** Subscription links and remote rule providers are chosen by you or your operator. Those third parties may log your IP address or account identifiers when you download configurations or connect to nodes.
- **No guarantee of anonymity:** Using a proxy client does not by itself guarantee anonymity or encryption end-to-end for all traffic; review your profiles, rules, and server providers carefully.

---

## 5. Storage, Retention, and Backup

- **Local storage:** Profiles, rules, preferences, brand configuration cache, and databases are stored on your device using mechanisms such as SQLite (Drift), `shared_preferences`, and application support directories.
- **Retention:** Data remains until you delete profiles, clear app data, uninstall the App, or overwrite backups you created.
- **WebDAV / files:** Backups you create are stored where you direct them (your WebDAV server or files you export). We do not retain copies on our servers.

---

## 6. Sharing and Disclosure

We may share information only in these situations:

- **With your direction:** Opening URLs in an external browser, launching payment apps, or uploading backups to your WebDAV server.
- **Service providers:** Google (Firebase, AdMob) as described above when those features are active.
- **Operator:** Your proxy provider may receive data you submit on their website or subscription system in the WebView or external browser.
- **Legal requirements:** If required by law, regulation, legal process, or to protect rights, safety, or security, we may disclose information we reasonably have access to (which, for most builds, is limited because data stays on your device).

We do not share your proxy configuration or traffic content with NodeUnion maintainers by default.

---

## 7. Permissions (Android)

The App may request or use permissions including:

| Permission | Purpose |
|------------|---------|
| Internet | Proxy, updates, brand config fetch, WebView, ads |
| Access / change network state | Manage connectivity and proxy tunnels |
| Foreground service | Keep proxy running in the background |
| Receive boot completed | Optional start at boot (if you enable it) |
| Post notifications | Show proxy status and alerts |
| Query all packages | Per-app proxy and access control (optional feature) |
| Camera | Scan QR codes to import profiles (when you use the scanner) |

You can revoke many permissions in system settings; some features may stop working if you do.

---

## 8. International Transfers

Third-party services (Google, your operator’s servers, CDN hosts for brand configuration, subscription providers, and proxy node operators) may process data in countries other than yours. Their transfer mechanisms are governed by their own terms and policies.

---

## 9. Security

We use industry-standard measures appropriate for a client application, including HTTPS for remote configuration fetch, AES-GCM for encrypted brand payloads, and local sandboxed storage. No method of transmission or storage is completely secure; you should protect your device, backups, and WebDAV credentials.

---

## 10. Children’s Privacy

The App is not directed at children under 13 (or the minimum age in your region). We do not knowingly collect personal information from children. If you believe a child has provided information through the App, contact your operator or us via the channels below.

---

## 11. Your Choices and Rights

Depending on your location, you may have rights to access, correct, delete, or restrict processing of personal information, or to object to certain processing.

Practical steps within the App:

- Disable **Crash Analysis** in Settings (Android);
- Disable ads by using a build or brand configuration with `ads.enabled` set to `false`;
- Clear app data or uninstall the App;
- Remove WebDAV bindings and delete remote backups you created;
- Reset advertising identifiers in your device’s system privacy settings (Android / iOS).

For requests directed at an **operator** (billing, account, portal data), contact that operator. For the open-source NodeUnion project, use [t.me/NodeUnion](https://t.me/NodeUnion).

---

## 12. Third-Party Links and Services

The App may link to FlClash, Clash.Meta, GitHub, Telegram, or other third-party resources. We are not responsible for the privacy practices of external sites or services you use through imported configurations, proxy nodes, or the operator WebView.

---

## 13. Open Source and Licenses

NodeUnion incorporates open-source components, including FlClash and Clash.Meta (mihomo), under their respective licenses. Redistribution or modification of the App may impose additional obligations under GPL and upstream terms. See the in-app About screen and project repository for attribution.

---

## 14. Changes to This Policy

We may update this Privacy Policy from time to time. The “Last updated” date at the top will change when we do. Material changes may be communicated through the repository, release notes, or operator channels. Continued use after changes take effect constitutes acceptance of the revised policy.

---

## 15. Contact

- **NodeUnion (project):** [https://t.me/NodeUnion](https://t.me/NodeUnion)
- **Operator:** If you obtained the App from a proxy provider, contact that provider for portal accounts, billing, and operator-hosted data.

---

*This document is provided for transparency and store compliance. It is not legal advice. Operators distributing customized builds should review this policy with counsel and adapt operator-specific contact details, data controller identity, and jurisdictional disclosures as needed.*
