import * as fs from 'fs';
import * as path from 'path';

/**
 * Create a temporary markdown presentation file for testing
 */
export function createTestPresentation(name: string, content: string): string {
  const fixturesDir = path.join(process.cwd(), 'fixtures');
  if (!fs.existsSync(fixturesDir)) {
    fs.mkdirSync(fixturesDir, { recursive: true });
  }
  
  const filePath = path.join(fixturesDir, `${name}.md`);
  fs.writeFileSync(filePath, content, 'utf-8');
  return filePath;
}

/**
 * Clean up test fixtures
 */
export function cleanupFixtures(): void {
  const fixturesDir = path.join(process.cwd(), 'fixtures');
  if (fs.existsSync(fixturesDir)) {
    fs.rmSync(fixturesDir, { recursive: true, force: true });
  }
}

/**
 * Sample presentation content for tests
 */
export const samplePresentation = `# Welcome to TUIA

This is the first slide.

---

## Second Slide

- Point one
- Point two
- Point three

---

## Code Example

\`\`\`zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello!\\n", .{});
}
\`\`\`

---

## The End

Thank you for using TUIA!
`;

/**
 * Minimal presentation for quick tests
 */
export const minimalPresentation = `# Slide 1

Content 1

---

# Slide 2

Content 2
`;

/**
 * Get the path to the tuia binary
 */
export function getTuiaBinary(): string {
  // Try to find the binary in common locations
  const possiblePaths = [
    path.join(process.cwd(), '..', 'zig-out', 'bin', 'tuia'),
    path.join(process.cwd(), '..', 'zig-out', 'bin', 'tuia.exe'),
    '/usr/local/bin/tuia',
    '/usr/bin/tuia',
  ];
  
  for (const p of possiblePaths) {
    if (fs.existsSync(p)) {
      return p;
    }
  }
  
  // Fallback to assuming it's in PATH
  return 'tuia';
}
