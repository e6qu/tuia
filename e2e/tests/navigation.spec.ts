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

## The End

Thank you for using TUIA!
`;

test.use({ shell: 'bash' });

test('should display welcome screen when no file provided', async ({ terminal }) => {
  await terminal.spawn(getTuiaBinary(), []);
  await expect(terminal.getByText('Welcome to tuia!', { full: true })).toBeVisible();
  terminal.write('q');
  await terminal.waitForExit();
});

test('should display first slide of presentation', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('welcome', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath]);
  await expect(terminal.getByText('Welcome to TUIA', { full: true })).toBeVisible();
  await expect(terminal.getByText('This is the first slide.')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('should navigate to next slide with j key', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('navigation', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath]);
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('j');
  await expect(terminal.getByText('Second Slide')).toBeVisible();
  await expect(terminal.getByText('Point one')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('should navigate to next slide with arrow down', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('arrow-nav', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath]);
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.sendKey('ArrowDown');
  await expect(terminal.getByText('Second Slide')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('should navigate to previous slide with k key', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('prev-nav', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath]);
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('j');
  await expect(terminal.getByText('Second Slide')).toBeVisible();
  
  terminal.write('k');
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('should jump to first slide with g', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('first-slide', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath]);
  terminal.write('G');
  await expect(terminal.getByText('The End')).toBeVisible();
  
  terminal.write('g');
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('should jump to last slide with G', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('last-slide', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath]);
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('G');
  await expect(terminal.getByText('The End')).toBeVisible();
  await expect(terminal.getByText('Thank you for using TUIA!')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});

test('should show help with ? key', async ({ terminal }) => {
  cleanupFixtures();
  const filePath = createTestPresentation('help', samplePresentation);
  
  await terminal.spawn(getTuiaBinary(), [filePath]);
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('?');
  await expect(terminal.getByText('Help', { full: true })).toBeVisible();
  
  terminal.write('q');
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
  cleanupFixtures();
});
