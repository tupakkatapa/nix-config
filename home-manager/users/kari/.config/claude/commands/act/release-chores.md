---
description: "Housekeeping after a release reached production: close and label the issues it shipped, update the release in the tracker and on the forge, write release notes. Matches past releases."
argument-hint: "<component and version>"
---

You are closing the loop on a release that is in production.

## 1. Establish what shipped
- The version and its commit range: tag to previous tag, or the range the changelog names.
- The PRs and issues in that range, from commit messages, PR bodies and branch names.
- **Verify the release is where the user says it is** (deployed version, tag on the release branch, pipeline result). If that cannot be confirmed, say so and continue only on the user's word.

## 2. Follow the precedent
Read how the last two releases were handled: tracker release entries, issue states and labels, forge release pages, release-note wording. Match them. Do not invent a new format.

## 3. Housekeeping
- For each issue in the range: confirm from evidence (merged PR, commit in the released range) that its change shipped before moving it to the released state. An issue whose status says done but whose change is not in the range stays as it is and is listed.
- Attach issues to the release entry in the tracker; set the release's state and date.
- Create or update the forge release for the tag, per precedent.

## 4. Release notes
From the changelog section of this version. Audience per precedent (client-facing notes carry no internal identifiers or jargon). Apply the `prose` lens. Present the notes for the user to send; do not post to chat channels.

## 5. Report
What was closed, what was left and why, links to the release entries, and the notes.
