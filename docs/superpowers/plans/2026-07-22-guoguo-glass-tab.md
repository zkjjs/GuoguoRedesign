# Guoguo Glass Tab Tweak Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an uninstallable jailbreak `.deb` that preserves Guoguo's Flutter behavior while replacing its visible bottom navigation with an Apple-style floating glass capsule and suppressing FLEX.

**Architecture:** A Logos tweak loads only into `com.example.dongmangongheguo`, hooks `FlutterViewController`, and installs a non-interactive UIKit overlay aligned with the original Flutter tab hit zones. A small pure Objective-C geometry module drives layout and selection calculations so those behaviors can be tested on Linux before iOS compilation.

**Tech Stack:** Theos, Logos, Objective-C, UIKit, GitHub Actions macOS runner, shell/static tests.

## Global Constraints

- Target Bundle ID: `com.example.dongmangongheguo`.
- Minimum supported iOS: 15.0; primary device: iOS 16.0.2.
- Preserve the four exact labels: `发现`, `频道`, `任务`, `我的`.
- Use neutral system dark materials and `systemBlueColor`; no pink, purple, gold, gradients, or colored glow.
- Do not modify user data or the installed app bundle.
- The overlay must not intercept touches.

---

### Task 1: Testable Layout Contract

**Files:**
- Create: `GuoguoGlassTab/Layout/GTLayout.h`
- Create: `GuoguoGlassTab/Layout/GTLayout.c`
- Create: `GuoguoGlassTab/Tests/test_layout.c`
- Create: `GuoguoGlassTab/Tests/run-tests.sh`

**Interfaces:**
- Produces: `GTRect GTContainerRect(double width, double height, double safeBottom)` and `int GTTabIndexForX(double x, double width)`.

- [ ] **Step 1: Write tests for 428×926 and compact widths**
- [ ] **Step 2: Run `GuoguoGlassTab/Tests/run-tests.sh` and verify it fails because layout functions are missing**
- [ ] **Step 3: Implement the minimum geometry module**
- [ ] **Step 4: Re-run tests and verify all assertions pass**

### Task 2: Native Glass Overlay

**Files:**
- Create: `GuoguoGlassTab/GTGlassTabView.h`
- Create: `GuoguoGlassTab/GTGlassTabView.m`
- Create: `GuoguoGlassTab/Tweak.xm`
- Create: `GuoguoGlassTab/Makefile`
- Create: `GuoguoGlassTab/control`
- Create: `GuoguoGlassTab/GuoguoGlassTab.plist`

**Interfaces:**
- Consumes: `GTContainerRect`, `GTTabIndexForX`.
- Produces: `-[GTGlassTabView setSelectedIndex:animated:]` and Flutter controller lifecycle hooks.

- [ ] **Step 1: Add static tests asserting non-interactive overlay, exact labels, dark blur, and system blue**
- [ ] **Step 2: Run tests and verify they fail before the source exists**
- [ ] **Step 3: Implement a four-item `UIVisualEffectView` capsule with SF Symbols and accessibility labels**
- [ ] **Step 4: Hook Flutter layout/touch lifecycle, align overlay with existing hit zones, and hide FLEX windows**
- [ ] **Step 5: Re-run all tests**

### Task 3: Reproducible `.deb` Build

**Files:**
- Create: `.github/workflows/build-guoguo-glass-tab.yml`
- Create: `GuoguoGlassTab/Tests/test_package.sh`
- Modify: `README.md`

**Interfaces:**
- Produces: GitHub Actions artifacts containing rootful and rootless `.deb` files.

- [ ] **Step 1: Add a package test that checks Bundle ID filter, package metadata, and artifact upload globs**
- [ ] **Step 2: Verify the package test fails before workflow metadata exists**
- [ ] **Step 3: Add macOS workflow to install Theos, build rootful/rootless packages, and upload artifacts**
- [ ] **Step 4: Run local tests and YAML syntax checks**
- [ ] **Step 5: Push to GitHub and inspect the fresh Actions result**

## Self-review

- Spec coverage: FLEX suppression, floating material, four tabs, touch passthrough, rotation, package schemes, and uninstall behavior are each mapped to a task.
- Placeholder scan: no TBD/TODO placeholders are present.
- Type consistency: the geometry and view interfaces use the same names across tasks.

