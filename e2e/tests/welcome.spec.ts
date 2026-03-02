import { test, expect } from '@microsoft/tui-test';
import * as path from 'path';
import * as fs from 'fs';

const tuiaBinary = path.join(import.meta.dirname, '..', '..', 'zig-out', 'bin', 'tuia');

test.use({ 
  program: { 
    file: fs.existsSync(tuiaBinary) ? tuiaBinary : 'tuia',
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
