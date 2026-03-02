import { test, expect } from '@microsoft/tui-test';
import { createTestPresentation, cleanupFixtures, samplePresentation, getTuiaBinary } from './fixtures.js';

test.describe('TUIA Snapshot Testing', () => {
  const tuiaBinary = getTuiaBinary();
  
  test.beforeAll(() => {
    cleanupFixtures();
  });
  
  test.afterAll(() => {
    cleanupFixtures();
  });

  test('first slide should match snapshot', async ({ terminal }) => {
    const filePath = createTestPresentation('snapshot1', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath], {
      cols: 80,
      rows: 24
    });
    
    // Wait for render to stabilize
    await terminal.waitForTimeout(500);
    
    // Take screenshot and compare with snapshot
    const screenshot = await terminal.screenshot();
    await expect(screenshot).toMatchSnapshot('first-slide.png');
    
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('second slide should match snapshot', async ({ terminal }) => {
    const filePath = createTestPresentation('snapshot2', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath], {
      cols: 80,
      rows: 24
    });
    
    // Navigate to second slide
    terminal.write('j');
    await terminal.waitForTimeout(500);
    
    const screenshot = await terminal.screenshot();
    await expect(screenshot).toMatchSnapshot('second-slide.png');
    
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('code slide should match snapshot', async ({ terminal }) => {
    const filePath = createTestPresentation('snapshot3', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath], {
      cols: 80,
      rows: 24
    });
    
    // Navigate to code slide (slide 3)
    terminal.write('j');
    terminal.write('j');
    await terminal.waitForTimeout(500);
    
    const screenshot = await terminal.screenshot();
    await expect(screenshot).toMatchSnapshot('code-slide.png');
    
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('help overlay should match snapshot', async ({ terminal }) => {
    const filePath = createTestPresentation('snapshot-help', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath], {
      cols: 80,
      rows: 24
    });
    
    // Open help
    terminal.write('?');
    await terminal.waitForTimeout(500);
    
    const screenshot = await terminal.screenshot();
    await expect(screenshot).toMatchSnapshot('help-overlay.png');
    
    // Close help and quit
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('last slide should match snapshot', async ({ terminal }) => {
    const filePath = createTestPresentation('snapshot-last', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath], {
      cols: 80,
      rows: 24
    });
    
    // Jump to last slide
    terminal.write('G');
    await terminal.waitForTimeout(500);
    
    const screenshot = await terminal.screenshot();
    await expect(screenshot).toMatchSnapshot('last-slide.png');
    
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('text content snapshot', async ({ terminal }) => {
    const filePath = createTestPresentation('text-snapshot', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath], {
      cols: 80,
      rows: 24
    });
    
    await terminal.waitForTimeout(500);
    
    // Get text content instead of screenshot
    const content = await terminal.getTextContent();
    expect(content).toMatchSnapshot('first-slide-text.txt');
    
    terminal.write('q');
    await terminal.waitForExit();
  });
});
