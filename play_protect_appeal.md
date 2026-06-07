# Play Protect Appeal for TRACKit

## App Details
- **App Name:** TRACKit 
- **Package Name:** com.example.budgify (Replace if package name has changed)

## Reason for Appeal
We are submitting this appeal to prevent Google Play Protect from flagging the TRACKit application as potentially harmful. Play Protect is currently warning users that our app "can request access to sensitive data" and "increase the risk of identity theft or financial fraud." This is triggered by our app's request for SMS permissions (`RECEIVE_SMS` and `READ_SMS`).

## Justification for SMS Permissions

### Core Functionality
TRACKit is an automated personal finance and budget tracking application. Its primary, core functionality relies on automatically categorizing and tracking the user's daily expenses and income without requiring manual data entry for every transaction.

### How SMS is Used
In many regions, banks and credit card issuers send automated SMS alerts for every transaction (purchases, withdrawals, deposits). TRACKit requires the `RECEIVE_SMS` and `READ_SMS` permissions strictly to read these specific transactional messages from financial institutions. 

1. **Local Processing:** The app reads the SMS locally on the device to extract the transaction amount, merchant name, and date.
2. **No Data Exfiltration:** The SMS data is processed entirely on the user's device. We do not upload, share, or sell the user's personal SMS messages to external servers.
3. **Targeted Reading:** The app only parses messages from recognized financial institutions. Personal messages from standard contacts are ignored.

### Why This Cannot Be Handled Another Way
Without the ability to automatically parse bank SMS alerts, the app would require users to manually input every single transaction, which defeats the primary purpose of the automated expense tracker and severely degrades the user experience. There are no alternative APIs provided by most local banks to fetch real-time transaction data securely.

## Privacy and Security Assurances
- **Strict OTP Exclusion:** The application’s parsing logic explicitly filters out and rejects any SMS containing keywords like "OTP", "One Time Password", or "Verification Code". These messages are immediately discarded before any processing occurs.
- **100% Offline & No Internet Permission:** The application is completely offline by design. It **does not even request the `android.permission.INTERNET` permission** in its AndroidManifest.xml. This provides absolute proof that it is physically impossible for the app to exfiltrate data, contact external servers, or commit financial fraud remotely.
- **Local Sandbox Storage:** All SMS parsing and resulting transaction data are stored securely in a local SQLite database that is sandboxed by the Android Operating System, keeping it isolated from other apps.
- **Clear Privacy Policy:** We maintain a strict Privacy Policy that explicitly outlines our local-only processing model and the exact reasons SMS permissions are required.

We kindly request that Google Play Protect whitelists the TRACKit app. The requested permissions are strictly necessary for its automated expense tracking functionality, and the complete lack of internet permissions guarantees zero risk of data exfiltration or fraud.

