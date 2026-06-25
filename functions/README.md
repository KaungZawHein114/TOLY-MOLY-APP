# TOLY MOLY — AI Task Scoper (Firebase + OpenAI)

These Cloud Functions are the **secure backend** for the AI features in the
Task Posting flow. The OpenAI API key lives only here (in Firebase's encrypted
secret store) and **never** ships inside the Flutter app.

The app already works **without** any of this: if Firebase isn't set up, or the
internet/OpenAI is down, every AI button silently falls back to the built-in
offline mock. Doing the steps below is what makes the AI **live** for your demo.

---

## What you get

| Function | Used by | Returns |
|---|---|---|
| `suggestCategory` | Screen 1 – "Suggest Category" button | `{ category }` (always one of the app's categories) |
| `rewriteDescription` | Screen 5 – "AI will write" button | `{ description }` (professional Burmese) |
| `analyzePrice` | Screen 6 – price input | `{ low, high, currency }` (MMK range) |
| `evaluateTask` | Review page – Attractiveness Score | `{ score, strengths, weaknesses, missing }` |

Model: **gpt-4o-mini** (cheap + fast; change `MODEL` in `index.js` to swap).

---

## One-time prerequisites

1. **Node.js 20** installed → check: `node --version` (should print v20.x).
2. **Firebase CLI** installed:
   ```bash
   npm install -g firebase-tools
   firebase login
   ```
3. **Blaze (pay-as-you-go) plan** on your Firebase project.
   Cloud Functions can only call an external API (OpenAI) on the Blaze plan.
   It still has a generous free tier — a demo costs effectively nothing.
   Enable it in the Firebase Console → ⚙ → *Usage and billing* → *Modify plan*.
4. An **OpenAI API key** from https://platform.openai.com/api-keys.

---

## Deploy the functions (run from the project root: `C:\TOLY MOLY APP`)

```bash
# 1. Point the CLI at your existing Firebase project
firebase use --add
#    → pick your project, give it an alias like "default"

# 2. Install the function dependencies
cd functions
npm install
cd ..

# 3. Store your OpenAI key as a secret (you'll be prompted to paste it)
firebase functions:secrets:set OPENAI_API_KEY

# 4. Deploy all four functions
firebase deploy --only functions
```

A successful deploy prints four function URLs. They live in region
**us-central1** by default — which is what the Flutter app expects, so no change
needed. (If you ever move them to another region, set it on the Flutter side
with `FirebaseFunctions.instanceFor(region: '<region>')`.)

---

## Connect the Flutter app to Firebase

From the project root:

```bash
# Installs the native Firebase config (google-services.json / plist) and
# generates lib/firebase_options.dart
dart pub global activate flutterfire_cli
flutterfire configure
```

The app's `main.dart` already calls `Firebase.initializeApp()` defensively, so
it keeps running even before this step. **Recommended:** after running
`flutterfire configure`, switch `main.dart` to the generated options (there's a
commented snippet in `main.dart` showing the exact two lines) for the most
reliable init across devices.

That's it — the AI is now live. `lib/core/utils/ai_service.dart` flips to the
live path automatically (`AiConfig.useLiveAi` is already `true`).

---

## Test it

**Backend only (no app), using the local emulator:**
```bash
cd functions
npm run serve          # starts the functions emulator
```
Then in another terminal, call a function (replace PROJECT_ID):
```bash
curl -X POST http://127.0.0.1:5001/PROJECT_ID/us-central1/suggestCategory \
  -H "Content-Type: application/json" \
  -d '{"data":{"title":"ပန်ကာ တပ်ဆင်ရန်","categories":["Plumber","Electrician","Cleaner"]}}'
```
Expected: `{"result":{"category":"Electrician"}}`.
> Note: secrets aren't loaded in the emulator by default. For a real OpenAI call
> while emulating, create `functions/.env` with `OPENAI_API_KEY=sk-...`
> (already git-ignored). Otherwise test against the deployed function.

**In the app (end-to-end):**
1. `flutter run` on a device/emulator **with internet**.
2. Post a Task →
   - Screen 1: type a title, tap **"AI ဖြင့် အမျိုးအစား ရှာမည်"** → a category is suggested (tap to apply).
   - Screen 5: tap **"AI က ရေးပေးမည်"** → the description is rewritten.
   - Screen 6: see the **AI recommended price range**; type a budget → low/ok/high feedback.
   - Review page: see the **Task Attractiveness Score** with strengths/weaknesses/missing.
3. To prove the fallback: turn off wifi and repeat — everything still works, now
   showing a small **"အော့ဖ်လိုင်း"** (offline) badge on the AI cards.

**Watch server logs while testing:**
```bash
firebase functions:log
```

---

## Cost & safety notes

- Key is server-side only (Firebase secret) — never in the app bundle.
- gpt-4o-mini + short prompts ≈ a tiny fraction of a cent per call.
- All four functions validate input and the app ignores any malformed response
  (falls back to mock), so a bad/empty model reply can't crash the demo.
