# Wealthy

Wealthy is an iPhone household budget app. Set a monthly target, record spending, and watch a small island grow as you stay within your daily allowance.

The redesign is in development and has not been released.

## What you can do

- Record and edit expenses and income by date and category.
- Track household spending and a separate child envelope.
- Set monthly and category targets, including or excluding fixed costs.
- Mark a day when you spent nothing.
- Review weekly and monthly results. An allowance is **not a bank balance**.
- Review Japanese consumption tax for JPY entries and an estimated difference for takeout meals.
- Use English, Japanese, Spanish or Korean, with light and dark appearance and larger text.

The app opens on the island. Swipe right for the voice page or left for information. Voice input is a clearly marked placeholder for a later development cycle. Receipt scanning, calendars, analysis and backup screens are also planned for later cycles.

## Before you start

You need iOS 26 or later and a compatible iPhone with Apple Intelligence enabled and ready. The app checks availability before opening its ledger.

Choose a language and currency, enter a monthly target, and decide whether to use a child envelope. Then add your first record. Forgotten days can be added within three days after the week and month end; results are recalculated from your records.

## Existing installations

This updates the same Wealthy app. The redesigned ledger starts empty. Earlier records and receipt images remain on the device, but this version does not open or migrate them. Keep the existing installation to retain those files.

## Build and verification

Open `Wealthy/Wealthy.xcodeproj` in Xcode and select the `Wealthy` scheme. Configure signing for your compatible iPhone.

See [verification guidance](Verification/README.md) and the [latest development report](.ai/LAST_REPORT.md) for completed checks and remaining limits. Passing builds and tests does not establish that every device or accessibility setting has been verified.

## Licenses

Bundled fonts use the SIL Open Font License. Their copyright notices and full license texts are available in Settings → Font licenses.

The application source remains all rights reserved. Redistribution of source code or binaries requires permission.
