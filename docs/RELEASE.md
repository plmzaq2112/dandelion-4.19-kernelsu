# Release process

## Build & verify

```bash
O=out bash build-tools/make_boot.sh        # on the bakasu branch
```

- record the sha256 of `out/boot-< kernelrelease >.img`
- rename the release artifact following the established convention:
  `boot-4.19.325-dandelion-ksu-35002-vN.img` (+ `.sha256`)
- licensee naming stays stable: `<kernel-release>-<ksu-version>-vN`

## Publish (GitHub Releases)

1. create release tag `vN`; attach:
   - boot image + `.sha256`
   - KernelSU Manager APK + `.sha256` — **official tiann release only**,
     no re-signed builds; keep `apk/` checksum on `main` in sync
2. release notes discipline:
   - UTF-8 only (younger terminals flying GBK have produced mojibake before —
     write the notes in a UTF-8 file and pass `--notes-file`)
   - **do not start the notes body with an `# H1`** — the release page already
     renders the release title above it; a leading H1 duplicates the version
     heading (all six historical releases had this, cleaned 2026-10-27)
   - mention the metamodule caveat for module users (TESTING.md footnote)
   - never claim root hiding / susfs features — this line ships none
3. keep **all** previous release images — each one is a rollback target

## Post-publish housekeeping

- XDA thread: **never** embed versions in the thread title; link to the
  Releases page for updates
- update `apk/` checksum file if the manager pairing changed
- update the local ledger (commits.md): commit hash, build / flash / test status
- archive the superseded image + report into the local versioned archive
