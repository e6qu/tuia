# TUIA Agent Instructions

## Project Overview

TUIA is a terminal-based presentation tool built with Zig and a custom POSIX TUI layer.

## Key Technologies

- **Language**: Zig 0.15.2
- **TUI Framework**: Custom POSIX terminal layer (raw mode, ANSI rendering, input parsing)
- **Build System**: Zig build

## Important Rules

### PR Merge Policy
**DO NOT merge Pull Requests.** Once you create a PR and it passes CI, stop and wait for user approval before merging. The user will handle merging themselves.

### End of Phase Workflow
At the end of each phase/feature:

1. **Sync local main with origin/main:**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create a feature branch from origin/main:**
   ```bash
   git checkout -b feature/<phase-name>
   ```

3. **Commit all changes to the branch:**
   ```bash
   git add -A
   git commit -m "feat: description of changes"
   ```

4. **Push the branch to origin:**
   ```bash
   git push -u origin feature/<phase-name>
   ```

5. **Create a Pull Request:**
   ```bash
   gh pr create --title "feat: description" --body "Details" --base main --head feature/<phase-name>
   ```

6. **Wait for user approval before merging** (see PR Merge Policy above)

7. **After PR is merged, clean up:**
   ```bash
   git checkout main
   git pull origin main
   git branch -d feature/<phase-name>
   ```
