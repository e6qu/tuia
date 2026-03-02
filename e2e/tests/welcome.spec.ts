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
  // Wait a bit for the terminal to render
  await terminal.waitForTimeout(1000);
  
  // Take a screenshot for debugging
  await expect(terminal).toMatchSnapshot('welcome-screen.png');
  
  terminal.write('q');
  await terminal.waitForExit();
});
