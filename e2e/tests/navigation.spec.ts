import { test, expect } from '@microsoft/tui-test';
import { createTestPresentation, cleanupFixtures, samplePresentation, getTuiaBinary } from './fixtures.js';

test.describe('TUIA Navigation', () => {
  const tuiaBinary = getTuiaBinary();
  
  test.beforeAll(() => {
    cleanupFixtures();
  });
  
  test.afterAll(() => {
    cleanupFixtures();
  });

  test('should display welcome screen when no file provided', async ({ terminal }) => {
    await terminal.spawn(tuiaBinary, []);
    
    // Wait for welcome message
    await expect(terminal.getByText('Welcome to tuia!', { full: true })).toBeVisible();
    
    // Press q to quit
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('should display first slide of presentation', async ({ terminal }) => {
    const filePath = createTestPresentation('welcome', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath]);
    
    // Wait for first slide content
    await expect(terminal.getByText('Welcome to TUIA', { full: true })).toBeVisible();
    await expect(terminal.getByText('This is the first slide.')).toBeVisible();
    
    // Clean up and quit
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('should navigate to next slide with j key', async ({ terminal }) => {
    const filePath = createTestPresentation('navigation', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath]);
    
    // Wait for first slide
    await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
    
    // Press j to go to next slide
    terminal.write('j');
    
    // Wait for second slide
    await expect(terminal.getByText('Second Slide')).toBeVisible();
    await expect(terminal.getByText('Point one')).toBeVisible();
    
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('should navigate to next slide with arrow down', async ({ terminal }) => {
    const filePath = createTestPresentation('arrow-nav', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath]);
    
    await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
    
    // Press arrow down
    terminal.sendKey('ArrowDown');
    
    await expect(terminal.getByText('Second Slide')).toBeVisible();
    
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('should navigate to previous slide with k key', async ({ terminal }) => {
    const filePath = createTestPresentation('prev-nav', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath]);
    
    // Go to second slide first
    await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
    terminal.write('j');
    await expect(terminal.getByText('Second Slide')).toBeVisible();
    
    // Go back to first slide
    terminal.write('k');
    await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
    
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('should jump to first slide with g', async ({ terminal }) => {
    const filePath = createTestPresentation('first-slide', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath]);
    
    // Go to last slide
    terminal.write('G');
    await expect(terminal.getByText('The End')).toBeVisible();
    
    // Jump to first slide
    terminal.write('g');
    await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
    
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('should jump to last slide with G', async ({ terminal }) => {
    const filePath = createTestPresentation('last-slide', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath]);
    
    await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
    
    // Jump to last slide
    terminal.write('G');
    await expect(terminal.getByText('The End')).toBeVisible();
    await expect(terminal.getByText('Thank you for using TUIA!')).toBeVisible();
    
    terminal.write('q');
    await terminal.waitForExit();
  });

  test('should show help with ? key', async ({ terminal }) => {
    const filePath = createTestPresentation('help', samplePresentation);
    
    await terminal.spawn(tuiaBinary, [filePath]);
    
    await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
    
    // Open help
    terminal.write('?');
    await expect(terminal.getByText('Help', { full: true })).toBeVisible();
    
    // Close help
    terminal.write('q');
    await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
    
    terminal.write('q');
    await terminal.waitForExit();
  });
});
