# Do Next

> Upcoming work for TUIA

---

## 🐛 Bug Hunt Phase 10: Open Bug Fixes (Priority 1) ✅

After completing automated security checks, we fixed 2 of 5 remaining bugs:

### HIGH-4: Memory Leak in FrontMatter.parseWithContent()
**Status:** ✅ Verified (No fix needed) | **Component:** Parser  
- [x] Analyze FrontMatter.parseWithContent() error paths
- [x] Verify errdefer protection exists (line 40)
- [x] Confirm no memory leak with valgrind

### MED-2: HTTP Keep-Alive Handling
**Status:** ✅ Fixed | **Component:** Remote Control  
- [x] Review RemoteServer connection handling
- [x] Implement proper connection shutdown using posix.shutdown

### Low Priority Parser Issues
- [x] LOW-1: Hard line breaks support ✅ Fixed
- [x] LOW-2: Escape sequences processing (`\*`, `\``, `\\`) ✅ Fixed
- [x] LOW-3: Horizontal rules variations (`***`, `___`) ✅ Fixed

---

## 🔒 Security & Automated Quality Checks (Priority 1) ✅ COMPLETED

Following the bug hunt phases 1-9, we implemented comprehensive automated checks to prevent bugs at CI time, not just through code review.

### Phase 1: SAST Implementation (Week 1) ✅

**Goal:** Catch bugs automatically before they reach production

#### 1.1 Semgrep Rules Setup ✅
- [x] Create `.semgrep/` directory with rules
- [x] Implement `bounds-check.yaml` - Detect array access without bounds check
- [x] Implement `integer-safety.yaml` - Detect unsigned subtraction without zero check
- [x] Implement `division-safety.yaml` - Detect division without zero check
- [x] Implement `memory-safety.yaml` - Detect missing errdefer, freeing literals
- [x] Implement `null-safety.yaml` - Detect optional unwrapping without check
- [x] Test rules against known bugs (should have caught them)
- [x] Add Semgrep CI job to PR workflow
- [x] Configure GitHub Security tab integration (SARIF output)

**Deliverable:** `.semgrep/*.yaml` + CI integration

#### 1.2 Custom Zig Lint Tool ✅
- [x] Create `tools/ziglint.zig` using Zig's AST parser
- [x] Implement AST walker to detect bug patterns
- [x] Add bounds check detection
- [x] Add integer safety detection  
- [x] Add memory safety detection
- [x] Add string literal free detection
- [x] Add configurable severity levels
- [x] Integrate into build.zig
- [x] Add CI job to run on all PRs

**Deliverable:** `tools/ziglint.zig` + build integration ✅

### Phase 2: Type Safety & Compile-Time Checks (Week 2)

#### 2.1 Compile-Time Assertions
- [ ] Add `comptime` safety checks to critical modules
- [ ] Create `SafeArray` wrapper type with compile-time bounds
- [ ] Create `SafeDiv` wrapper for division operations
- [ ] Create `SafeSub` wrapper for unsigned subtraction
- [ ] Document compile-time safety patterns

**Deliverable:** `src/infra/safety.zig` with safe wrapper types

#### 2.2 Build Script Safety Checks
- [ ] Add `safety-check` step to build.zig
- [ ] Implement source code pattern scanning
- [ ] Block build on critical safety violations
- [ ] Generate safety report

**Deliverable:** Build script enforcement

### Phase 3: Fuzzing Infrastructure (Week 3) ✅

#### 3.1 Parser Fuzzing ✅
- [x] Set up `libFuzzer` integration for Zig
- [x] Create `fuzz/parser_fuzz.zig` target
- [x] Implement structured input generation
- [x] Run fuzzer locally to verify setup
- [x] Add daily fuzzing CI job
- [x] Configure crash artifact upload

**Deliverable:** `fuzz/` directory + CI job ✅

#### 3.2 Widget Fuzzing
- [ ] Create `fuzz/widget_fuzz.zig` for rendering
- [ ] Fuzz with random element combinations
- [ ] Test all widget types
- [ ] Check for crashes and memory leaks

**Deliverable:** Widget fuzzing target

### Phase 4: Memory Safety Tools (Week 4)

#### 4.1 Valgrind Integration
- [ ] Create valgrind suppression file for known issues
- [ ] Add valgrind CI job for Linux builds
- [ ] Configure leak detection settings
- [ ] Set up weekly full memory audit

**Deliverable:** `.valgrind/` + CI integration

#### 4.2 Address Sanitizer
- [ ] Add `-Dsanitize=address` build option
- [ ] Test with ASan on CI
- [ ] Document ASan usage for developers

**Deliverable:** ASan build configuration

### Phase 5: Security Scanning (Week 5)

#### 5.1 Dependency Scanning
- [ ] Configure Trivy for dependency scanning
- [ ] Add Trivy to PR workflow
- [ ] Set up vulnerability notifications
- [ ] Create dependency update automation

**Deliverable:** Trivy integration

#### 5.2 Secret Detection
- [ ] Add TruffleHog to CI pipeline
- [ ] Configure secret patterns
- [ ] Set up secret rotation if found

**Deliverable:** Secret scanning CI job

#### 5.3 CodeQL Analysis
- [ ] Enable CodeQL for Zig (if available)
- [ ] Configure custom queries for Zig patterns
- [ ] Integrate with GitHub Security tab

**Deliverable:** CodeQL configuration

### Phase 6: CI/CD Integration (Week 6) ✅

#### 6.1 Unified Security Workflow ✅
- [x] Create single security workflow file
- [x] Run all checks in parallel
- [x] Generate unified security report
- [x] Block PR merge on failures

**Deliverable:** `.github/workflows/security.yml` ✅

#### 6.2 Quality Gates
- [ ] Set up branch protection rules
- [ ] Require all checks to pass
- [ ] Require code review approval
- [ ] Require security scan approval for critical files

**Deliverable:** GitHub branch protection

#### 6.3 Metrics Dashboard
- [ ] Track bugs caught by each tool
- [ ] Measure time to fix
- [ ] Report security score
- [ ] Monthly security review

**Deliverable:** Security metrics dashboard

---

## 🛡️ Code Quality & Standards (Priority 2)

### Documentation
- [ ] Complete `docs/CODING_STANDARDS.md` with examples
- [ ] Add "Common Pitfalls" section to DEVELOPMENT.md
- [ ] Create code review checklist template
- [ ] Document all automated checks

### Training
- [ ] Create onboarding guide for new developers
- [ ] Document bug patterns and solutions
- [ ] Add safety examples to codebase

---

## 🚀 Feature Enhancements (Future Versions)

### Version 1.1.0
- [ ] PDF export improvements
- [ ] Additional themes
- [ ] Performance optimizations
- [ ] **Security:** Complete all automated checks (Priority)

### Version 1.2.0
- [ ] Plugin system exploration
- [ ] Advanced transitions
- [ ] Remote control enhancements

---

## 📋 Maintenance Tasks

### Ongoing
- [ ] Monitor GitHub Issues for bug reports
- [ ] Keep dependencies updated (libvaxis, etc.)
- [ ] Review and merge community PRs
- [ ] **Weekly:** Review security scan results
- [ ] **Daily:** Check fuzz testing results

### Documentation
- [ ] Keep BUGS.md updated
- [ ] Update USER_GUIDE.md with new features
- [ ] Maintain API documentation
- [ ] Document security practices

---

## 🐛 Bug Tracking

Current open bugs (see BUGS.md):
- **None!** All known bugs have been fixed.

**Status:** Bug hunt complete. 0 open bugs.

---

## 🎯 Success Criteria

| Metric | Target | Timeline |
|--------|--------|----------|
| Zero critical bugs in production | 0 | Ongoing |
| SAST coverage | 100% of new code | Week 1 |
| Custom lint rules | 10+ patterns | Week 2 |
| Fuzz testing | Daily runs | Week 3 |
| Memory leak detection | CI integrated | Week 4 |
| Security scans | All PRs | Week 5 |
| Test coverage maintained | >80% | Ongoing |
| Bugs caught by automation | >50% of total | Month 2 |

---

## 📊 Implementation Timeline

```
Week 1: SAST (Semgrep rules)
Week 2: Custom linter + Type safety
Week 3: Fuzzing infrastructure
Week 4: Memory safety tools
Week 5: Security scanning
Week 6: CI/CD integration + Metrics
```

**Total Duration:** 6 weeks for comprehensive automated checks

---

## 🔗 Related Documents

- [BUGS.md](BUGS.md) - Bug tracking
- [PLAN.md](PLAN.md) - Detailed plan with prevention measures
- [docs/CODING_STANDARDS.md](docs/CODING_STANDARDS.md) - Coding standards
- [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) - Development guide

---

*Last updated: 2026-03-03*  
*Next review: After Phase 10 bug fixes*
