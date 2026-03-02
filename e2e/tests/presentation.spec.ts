import { test, expect } from '@microsoft/tui-test';
import * as path from 'path';

const tuiaBinary = process.env.TUIA_BINARY || 'tuia';
const fixturePath = path.join(process.cwd(), 'tests', 'fixtures', 'test-presentation.md');

test.use({ 
  program: { 
    file: tuiaBinary,
    args: [fixturePath]
  },
  shell: 'bash',
  cols: 80,
  rows: 24
});

test('should start with presentation file and quit', async ({ terminal }) => {
  // Basic smoke test - just verify the app starts with a file and can be quit
  terminal.write('q');
});
