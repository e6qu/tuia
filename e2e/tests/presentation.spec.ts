import { test, expect } from '@microsoft/tui-test';
import * as path from 'path';
import * as fs from 'fs';

const fixturePath = path.join(import.meta.dirname, 'fixtures', 'test-presentation.md');

test.use({ 
  program: { 
    file: path.join(import.meta.dirname, '..', '..', 'zig-out', 'bin', 'tuia'),
    args: [fixturePath]
  },
  shell: 'bash',
  cols: 80,
  rows: 24
});

test('should display first slide', async ({ terminal }) => {
  await expect(terminal.getByText('Welcome to TUIA', { full: true })).toBeVisible();
  await expect(terminal.getByText('This is the first slide.')).toBeVisible();
  terminal.write('q');
  await terminal.waitForExit();
});

test('should navigate to next slide with j', async ({ terminal }) => {
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('j');
  await expect(terminal.getByText('Second Slide')).toBeVisible();
  await expect(terminal.getByText('Point one')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
});

test('should navigate to previous slide with k', async ({ terminal }) => {
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  // Go to next slide
  terminal.write('j');
  await expect(terminal.getByText('Second Slide')).toBeVisible();
  
  // Go back
  terminal.write('k');
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
});

test('should jump to last slide with G', async ({ terminal }) => {
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('G');
  await expect(terminal.getByText('The End')).toBeVisible();
  await expect(terminal.getByText('Thank you for using TUIA!')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
});

test('should jump to first slide with g', async ({ terminal }) => {
  // Go to last slide first
  terminal.write('G');
  await expect(terminal.getByText('The End')).toBeVisible();
  
  // Jump to first
  terminal.write('g');
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
});

test('should show help with ? key', async ({ terminal }) => {
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('?');
  await expect(terminal.getByText('Help', { full: true })).toBeVisible();
  
  // Close help
  terminal.write('q');
  await expect(terminal.getByText('Welcome to TUIA')).toBeVisible();
  
  terminal.write('q');
  await terminal.waitForExit();
});
