# Verification

These checks help confirm that records, targets and tax summaries behave consistently. Device screenshots also help compare the new interface with the approved design. A successful build alone does not prove that a screen works on a phone.

## Current redesign

Run the ledger checks with `sh Verification/verify_core.sh`. Run catalog, font and legacy-isolation checks with `python3 Verification/verify_shell.py`.

The physical-device suite checks first setup in four languages, entry creation, takeout tax, a no-spend day and a target edit. It also captures the core screens in light, dark and larger text. All financial fixtures are synthetic.

`python3 Verification/prepare_cycle2a_tests.py /private/tmp/wealthy-cycle2a-tests` creates a temporary test project. It keeps the same Wealthy application identifier; it does not create a second app. Run the `Wealthy` scheme on a paired compatible iPhone with Xcode. The workflow and screenshot tests use a DEBUG-only in-memory ledger and keep test preferences separate from normal preferences. The 50,000-record performance test uses a dedicated temporary disk store, also separate from the normal ledger. Do not uninstall the app to rerun these checks: earlier records and images must remain on the device.

Screenshots, completed checks and anything not verified are listed in the [latest report](../.ai/LAST_REPORT.md). The actual Apple Intelligence availability gate remains active during testing. There is no test bypass for it.

## Earlier functionality

Earlier app source is archived in `LegacyApp/` outside the app target. Its existing component checks continue to run with the same fixtures and assertions. [Historical verification guidance](LEGACY_CHECKS.md) describes those older checks; it does not describe features available in the redesigned app.

## Font sources

`subset_fonts.py` reproduces the bundled font subsets from the specified Google Fonts OFL sources after checking their SHA-256 hashes. It uses the official Japanese character table and includes Korean Hangul syllables and Spanish accents. Font tooling is needed only for this preparation step, not by the app.
