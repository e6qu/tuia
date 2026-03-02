import { test, expect } from '@microsoft/tui-test';
import * as path from 'path';

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

import * as fs from 'fs';

test.use({ 
  program: { 
    file: getTuiaBinary(),
    args: []
  },
  shell: 'bash',
  cols: 80,
  rows: 24
});

test('should display welcome screen when no file provided', async ({ terminal }) => {
  await expect(terminal.getByText('Welcome to tuia!', { full: true })).toBeVisible();
  terminal.write('q');
  await terminal.waitForExit();
});
