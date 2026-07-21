# Guoguo Redesign

This repository contains the Guoguo UI redesign work.

## Guoguo Glass Tab tweak

`GuoguoGlassTab/` builds a reversible jailbreak tweak for bundle ID
`com.example.dongmangongheguo`.

It provides:

- a four-item floating ultra-thin-material tab capsule;
- system-blue selection and neutral iOS dark colors;
- suppression of the injected FLEX overlay;
- a reversible theme-archive replacement that restores the original on uninstall;
- rootful and rootless `.deb` artifacts from GitHub Actions.

The tweak preserves the existing Flutter screens and forwards tab touches to the
original app rather than replacing its application logic.

Build artifacts are produced by the `Build Guoguo Glass Tab Deb` workflow.
