# Role Verification Setup

Aggregator/Transporter/Distributor accounts require verification before
their dashboard unlocks — either a pre-issued invite code, or admin
approval. Neither can be granted from inside the app itself (that's the
point — no client-side path can self-escalate to admin or "approved").
You bootstrap both directly in the Firebase Console.

## 1. Make yourself the first admin

Firebase Console → Firestore Database → Start collection:

- Collection ID: `admins`
- Document ID: **your Firebase Auth uid** (Console → Authentication → Users,
  copy the UID column for your account)
- Add any field, e.g. `createdAt: <timestamp>` — the document just needs
  to *exist*, its contents aren't read.

That's it — that account can now open **Settings → Admin → Access
Requests** in the app and approve/reject pending requests.

## 2. Issue an invite code (optional — the instant-activation path)

Firestore → Start collection:

- Collection ID: `role_invite_codes`
- Document ID: the code itself, e.g. `AGG-4F2K` (must be UPPERCASE — the
  app uppercases whatever a user types before checking, so the stored
  code needs to match)
- Fields:
  - `role` (string): `aggregator`, `transporter`, or `distributor`
  - `organizationLabel` (string): e.g. `"Kiambu Growers Cooperative"` —
    this becomes that account's org/vehicle name automatically once redeemed
  - `used` (boolean): `false`
  - `createdAt` (timestamp): now

Give that code to whoever you've already vetted offline. They enter it
under **"I have a code"** on the verification screen and get in instantly.

## 3. Or let people request access instead

No code needed — anyone selecting Aggregator/Transporter/Distributor can
tap **"Request access"**, fill in their organization/vehicle details, and
land on a **Pending Review** screen. It shows up in your **Access
Requests** queue in Settings; Approve/Reject updates their account live —
they don't need to refresh or re-open the app.

## Notes

- Dev quick-sign-in buttons (Farmer/Chef/Consumer/Aggregator/Transporter/
  Distributor on the login screen) bypass all of this — they're pre-marked
  `approved` in mock data so you can still demo every dashboard instantly
  without setting up Firestore docs first. Real accounts (Google/email
  sign-in) go through the actual flow described above.
- Farmer, Chef, and Grocery Shopper/Diner never need verification — only
  the three supply-chain roles that can receive *other people's* produce.
