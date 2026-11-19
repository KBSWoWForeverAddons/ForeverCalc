---
name: release
description: >-
  Create a versioned git tag and push it to GitHub to trigger automated
  packaging, GitHub Release creation, and CurseForge deployment.
  Use when the user runs /release or asks to tag/publish a new release.
---

# Release ForeverCalc

Automates tagging and pushing a new release of **ForeverCalc** to GitHub, which triggers `.github/workflows/release.yml` (`BigWigsMods/packager@v2`) to package the addon (ignoring `.gitignore` and `.curseignore`), create a GitHub Release, and upload to CurseForge.

## Steps

1. **Check Repository State**:
   - Run `git status` to verify the working tree is clean. If there are uncommitted changes, ask the user whether to commit or stash them before releasing.
   - Run `git tag --sort=-v:refname` and `git log -n 10 --oneline` (or `git log <last-tag>..HEAD --oneline` if a previous tag exists) to inspect recent changes.
   - Read `ForeverCalc.toc` to check the current `## Version:` and whether `## X-Curse-Project-ID:` is uncommented and set.
     - If `## X-Curse-Project-ID:` is still commented out, warn the user that the GitHub Release will be created, but CurseForge auto-upload won't run until `## X-Curse-Project-ID:` is set in `ForeverCalc.toc` and `CF_API_KEY` is configured in GitHub repository secrets.

2. **Determine Target Version**:
   - If the user provided a version (e.g., `/release 1.2.1` or `/release v1.2.1`), strip any leading `v` for `ForeverCalc.toc` and use `v<version>` for the git tag.
   - If no version was provided, suggest the next semantic version based on the current `## Version:` and recent commits (e.g., patch bump for fixes, minor bump for features) and confirm with the user.

3. **Update Version Metadata & Changelog**:
   - Update `## Version: <version>` in `ForeverCalc.toc`.
   - If `README.md` mentions the version badge/text (e.g., ``(`v1.2.0`)``), update it to match `v<version>`.
   - Generate a clean, player-friendly changelog entry in `CHANGELOG.md` (creating the file if it does not exist) from all commits since the previous tag (`git log <last-tag>..HEAD --oneline`, or `git log --oneline` if no tag exists):
     - Prepend a new section `## [v<version>] - YYYY-MM-DD` at the top of `CHANGELOG.md` (below the `# Changelog` header).
     - Group changes under concise headings (**Added**, **Changed**, **Fixed** — omit any empty section) written clearly for WoW players, without raw commit hashes.
     - Note: `.github/workflows/release.yml` automatically passes `CHANGELOG.md` to `BigWigsMods/packager@v2` via `manual-changelog` in `.pkgmeta` for CurseForge and GitHub Releases.
   - Stage and commit the version bump and changelog:
     ```powershell
     git add ForeverCalc.toc README.md CHANGELOG.md
     git commit -m "Release v<version>"
     ```

4. **Tag and Push**:
   - Create an annotated tag and push both the current branch and the tag to `origin`:
     ```powershell
     git tag -a "v<version>" -m "Release v<version>"
     git push origin main --follow-tags
     ```

5. **Report Links**:
   - Provide clickable links to monitor the workflow and release:
     - GitHub Actions: `https://github.com/KBSWoWForeverAddons/ForeverCalc/actions`
     - GitHub Release: `https://github.com/KBSWoWForeverAddons/ForeverCalc/releases/tag/v<version>`
