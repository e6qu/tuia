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

test('should start and quit', async ({ terminal }) => {
  // Basic smoke test - just verify the app starts and can be quit
  terminal.write('q');
});
