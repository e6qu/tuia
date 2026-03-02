import { test, expect } from '@microsoft/tui-test';
import * as fs from 'fs';
import * as path from 'path';

const fixturesDir = path.join(process.cwd(), 'fixtures');

function createTestPresentation(name: string, content: string): string {
  if (!fs.existsSync(fixturesDir)) {
    fs.mkdirSync(fixturesDir, { recursive: true });
  }
  const filePath = path.join(fixturesDir, `${name}.md`);
  fs.writeFileSync(filePath, content, 'utf-8');
  return filePath;
}

function cleanupFixtures(): void {
  if (fs.existsSync(fixturesDir)) {
    fs.rmSync(fixturesDir, { recursive: true, force: true });
  }
}

function getTuiaBinary(): string {
  const possiblePaths = [
    path.join(process.cwd(), '..', 'zig-out', 'bin', 'tuia'),
    path.join(process.cwd(), '..', 'zig-out', 'bin', 'tuia.exe'),
  ];
  for (const p of possiblePaths) {
    if (fs.existsSync(p)) {
      return p;
    }
  }
  return 'tuia';
}

const samplePresentation = `# Welcome to TUIA

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

test.use({ shell: 'bash' });

test('first slide should match snapshot', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('snapshot1', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath], {
    cols: 80,
    rows: 24
  });
  
  await terminal.waitForTimeout(500);
  const screenshot = await terminal.screenshot();
  await expect(screenshot).toMatchSnapshot('first-slide.png');
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('second slide should match snapshot', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('snapshot2', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath], {
    cols: 80,
    rows: 24
  });
  
  terminal.write('j');
  await terminal.waitForTimeout(500);
  
  const screenshot = await terminal.screenshot();
  await expect(screenshot).toMatchSnapshot('second-slide.png');
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('code slide should match snapshot', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('snapshot3', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath], {
    cols: 80,
    rows: 24
  });
  
  terminal.write('j');
  terminal.write('j');
  await terminal.waitForTimeout(500);
  
  const screenshot = await terminal.screenshot();
  await expect(screenshot).toMatchSnapshot('code-slide.png');
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('help overlay should match snapshot', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('snapshot-help', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath], {
    cols: 80,
    rows: 24
  });
  
  terminal.write('?');
  await terminal.waitForTimeout(500);
  
  const screenshot = await terminal.screenshot();
  await expect(screenshot).toMatchSnapshot('help-overlay.png');
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('last slide should match snapshot', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('snapshot-last', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath], {
    cols: 80,
    rows: 24
  });
  
  terminal.write('G');
  await terminal.waitForTimeout(500);
  
  const screenshot = await terminal.screenshot();
  await expect(screenshot).toMatchSnapshot('last-slide.png');
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('text content snapshot', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('text-snapshot', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath], {
    cols: 80,
    rows: 24
  });
  
  await terminal.waitForTimeout(500);
  
  const content = await terminal.getTextContent();
  expect(content).toMatchSnapshot('first-slide-text.txt');
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});
