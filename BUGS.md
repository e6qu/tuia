# Bug Tracking

**Status:** All Known Bugs Fixed ✅  
**Open Bugs:** 0  
**Total Fixed:** 27 (17 Critical, 6 High, 4 Medium/Low)

---

## Recent Fixes (Phase 10-12)

| Bug | Component | Fix |
|-----|-----------|-----|
| LOW-1 | Parser | Hard line breaks (`<br>`, two spaces) |
| LOW-2 | Parser | Escape sequence processing |
| LOW-3 | Scanner | Horizontal rules (`***`, `___`) |
| MED-2 | Remote | HTTP Keep-Alive with posix.shutdown |

---

## Bug Hunt Summary

**Phase 1-9:** 17 critical bugs (use-after-free, buffer overflows, integer underflows, etc.)  
**Phase 10-12:** 10 additional bugs (escape sequences, line breaks, keep-alive)

**Prevention Measures:**
- Bounds checking on all array accesses
- Zero checks before division/subtraction
- `errdefer` pattern for cleanup
- Semgrep SAST rules
- Custom ziglint tool

---

*Last updated: 2026-03-04*
