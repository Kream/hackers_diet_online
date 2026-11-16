
- Temporary: libfaketime and curl added to the dev image for Phase 1 Step 1 corpus runs under a fixed clock. Remove both once the golden outputs are captured and the clock method is no longer needed.

- Temporary: validMailDomain in src/HackDiet.pl stubbed to always return 1 for Phase 1 Step 1 corpus runs under libfaketime (dig hangs). Mail is unused on dev. Restore the original after golden outputs are captured.
