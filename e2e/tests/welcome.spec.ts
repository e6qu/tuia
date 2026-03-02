import { test, expect } from '@microsoft/tui-test';

const tuiaBinary = process.env.TUIA_BINARY || 'tuia';

test.use({ 
  program: { 
    file: tuiaBinary,
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
