# Play Console forms: answers for DocNook

These answers match the app as built (no INTERNET permission, no analytics,
no accounts). Re-check them if a future version adds internet, ads or billing.

## Data safety (Policy → App content → Data safety)

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | Not shown once you answer "No" above |
| Do you provide a way for users to request that their data is deleted? | Not shown once you answer "No" above |

Why "No" is correct: Google defines "collect" as sending data off the device.
DocNook has no internet permission, so it cannot send anything. Files leave
the phone only when the user taps Share and picks another app, and Google
treats that as user-initiated sharing, not collection.

## Privacy policy (App content → Privacy policy)

Paste the URL of the Google Sites page made from `privacy_policy.html`.

## App access (App content → App access)

**All functionality is available without special access.** No login.

## Ads (App content → Ads)

**No, my app does not contain ads.**

## Content rating (App content → Content rating)

Category: **Utility, Productivity, Communication, or Other**. Answer **No** to
every question (violence, sexuality, language, controlled substances,
gambling, user-generated content sharing between users, location sharing,
digital purchases). Expected rating: Everyone / PEGI 3.

## Target audience (App content → Target audience and content)

Age groups: **18 and over** (simplest: avoids the Families policy review).
The app is not designed for children.

## News app / COVID / Financial features / Health

**No** to each.

## Government app

**No.**

## Permissions declaration: All files access (MANAGE_EXTERNAL_STORAGE)

Play shows this form after the first upload because the manifest declares
`MANAGE_EXTERNAL_STORAGE`.

- Core feature that needs it: **Document management / File viewer**
  (pick "Document management" if offered, otherwise "File manager").
- Describe the use (paste):

  > DocNook is an offline document reader and organizer. Its Library finds
  > every PDF, Word, Excel, PowerPoint, e-book, text and archive file on the
  > device so the user can open, search and organize them in one place
  > without choosing folders one by one. All files access is requested only
  > when the user taps "Find my documents" and is optional: without it,
  > users can still open files from other apps or grant access to single
  > folders through the system folder picker. File contents never leave the
  > device; the app has no internet permission.

- Video: record a 20–30 second screen recording: Home → Find my documents →
  the explanation screen → Allow → the Library filling with documents.
  Upload it to YouTube as **Unlisted** and paste the link (Play requires a
  link; unlisted videos are not public).

If Google rejects the declaration, tell Claude Code: the fallback is to ship
the Play build without `MANAGE_EXTERNAL_STORAGE` and rely on folder access
(the direct APK can keep it).

## Camera permission

No declaration form is needed. The camera is used only by DocNook's own
scanner when the phone has no Google document scanner.
