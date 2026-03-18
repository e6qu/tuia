# Definition of Done

> The Definition of Done (DoD) defines the exit criteria for all tasks in the TUIA project.

## Universal Definition of Done

A task is considered **Done** only when **ALL** of the following conditions are met.

---

## 1. Code Complete

### 1.1 Implementation Finished
- [ ] All requirements from the task description implemented
- [ ] No TODO comments left in code (or documented as follow-up issues)
- [ ] Dead code removed
- [ ] Debug print statements removed (or converted to proper logging)

### 1.2 Error Handling
- [ ] All error paths handled explicitly
- [ ] Meaningful error messages
- [ ] No silent failures
- [ ] Resource cleanup in all paths (try using `errdefer`)

### 1.3 Edge Cases
- [ ] Empty inputs handled
- [ ] Maximum size inputs handled
- [ ] Invalid inputs handled gracefully
- [ ] Boundary conditions tested

---

## 2. Testing Complete

### 2.1 Unit Tests
- [ ] Tests written for all public functions
- [ ] Tests cover happy path
- [ ] Tests cover error conditions
- [ ] Tests cover edge cases
- [ ] All tests pass (`zig build test`)

### 2.2 Integration Tests
- [ ] End-to-end scenario tested
- [ ] Feature works with other components
- [ ] No regressions in existing tests

### 2.3 Coverage
- [ ] Line coverage ≥ 80% for modified code
- [ ] Branch coverage measured (aim for 70%+)

### 2.4 Manual Testing
- [ ] Feature tested manually in terminal
- [ ] Cross-platform check (if applicable)
- [ ] Performance verified acceptable

---

## 3. Quality Checks

### 3.1 Static Analysis
- [ ] `zig fmt --check` passes
- [ ] `zig build` produces no warnings
- [ ] No clippy-equivalent warnings
- [ ] Static analysis tools pass (if available)

### 3.2 Memory Safety
- [ ] GeneralPurposeAllocator leak detection passes
- [ ] No use-after-free patterns
- [ ] No memory leaks in long-running scenarios
- [ ] Valgrind clean (for C interop components)

### 3.3 Code Review
- [ ] PR reviewed by at least one team member
- [ ] All review comments addressed
- [ ] Reviewer approval obtained

---

## 4. Documentation Complete

### 4.1 Code Documentation
- [ ] All public APIs have doc comments
- [ ] Complex algorithms explained
- [ ] Non-obvious code has explanatory comments

### 4.2 User Documentation (if user-facing)
- [ ] README updated (if applicable)
- [ ] User guide updated (if applicable)
- [ ] Help text updated (if applicable)
- [ ] Example added (for new features)

### 4.3 Architecture Documentation
- [ ] ADR created for significant decisions
- [ ] Architecture diagrams updated (if applicable)
- [ ] API documentation generated

### 4.4 CHANGELOG
- [ ] Entry added under "Unreleased"
- [ ] Follows Keep a Changelog format
- [ ] User-facing changes described

---

## 5. Integration Complete

### 5.1 Version Control
- [ ] Code committed to feature branch
- [ ] Commit messages follow conventional commits
- [ ] Branch rebased on latest main
- [ ] Merge conflicts resolved

### 5.2 CI/CD
- [ ] All CI checks pass
- [ ] Build succeeds on all target platforms
- [ ] Tests pass in CI
- [ ] No new warnings in CI

### 5.3 Merge
- [ ] PR merged to main
- [ ] Branch deleted after merge
- [ ] Main branch still green

---

## Task-Type Specific Additions

### Parser Tasks

Additional DoD items:
- [ ] Golden file tests pass (or updated with ZIG_UPDATE_GOLDEN=1)
- [ ] Parser handles all examples in `tests/fixtures/`
- [ ] Error messages include line/column numbers
- [ ] Fuzz test passes (if fuzzing available)

### Renderer Tasks

Additional DoD items:
- [ ] Visual output verified against expected
- [ ] Terminal state restored after render
- [ ] No flickering during updates
- [ ] Performance benchmarked (regression < 10%)

### Widget Tasks

Additional DoD items:
- [ ] Widget respects all constraint combinations
- [ ] Widget handles focus (if interactive)
- [ ] Widget accessible via keyboard (if interactive)
- [ ] Widget looks correct in all built-in themes

### Feature Tasks

Additional DoD items:
- [ ] Feature flag works (can be disabled at compile time)
- [ ] Security review passed (if security-related)
- [ ] Performance impact measured and documented
- [ ] User documentation includes usage examples

### Bug Fix Tasks

Additional DoD items:
- [ ] Root cause documented in commit message
- [ ] Regression test added
- [ ] Fix verified against reported issue
- [ ] No workaround needed after fix

---

## Sign-Off Process

### Developer Sign-Off

```
I certify that this task meets the Definition of Done:

- [ ] Code complete
- [ ] Testing complete  
- [ ] Quality checks passed
- [ ] Documentation complete
- [ ] Integration complete

Signed-off-by: Developer Name <email@example.com>
```

### Reviewer Sign-Off

```
I have reviewed this work and confirm it meets the Definition of Done:

- [ ] Code review passed
- [ ] Acceptance criteria met
- [ ] Quality standards met

Approved-by: Reviewer Name <email@example.com>
```

---

## Done vs Closed

| State | Meaning | Who Changes |
|-------|---------|-------------|
| **In Progress** | Actively being worked on | Developer |
| **Ready for Review** | Developer believes DoD met | Developer |
| **In Review** | Undergoing code review | Reviewer |
| **Changes Requested** | Review found issues | Reviewer |
| **Done** | DoD fully met, merged to main | Reviewer |
| **Closed** | Task complete, no further work | Project Manager |

---

## Exceptions

Exceptions to the DoD must be:
1. Documented in the task description
2. Approved by tech lead
3. Recorded with justification

Example exception format:
```markdown
## DoD Exception
- **Criteria:** AC-TEST-002 (Coverage)
- **Reason:** This is a thin wrapper around external library;
  testing would only test the library, not our code
- **Approved by:** Tech Lead
- **Date:** 2026-03-01
```

---

## DoD Evolution

This DoD may be updated as the project matures. Proposed changes:
1. Must be PR'd like any other change
2. Must be reviewed by team
3. Apply only to tasks started after merge

---

*Version: 1.0*  
*Last Updated: 2026-03-01*  
*Applies to: All TUIA tasks from Milestone 1 onwards*
