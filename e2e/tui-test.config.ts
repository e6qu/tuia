import { defineConfig } from '@microsoft/tui-test';

export default defineConfig({
  // Test files pattern
  testMatch: 'tests/**/*.spec.ts',
  
  // Timeout for each test
  timeout: 30000,
  
  // Number of retries for flaky tests
  retries: 2,
  
  // Enable tracing for debugging
  trace: true,
  
  // Reporter configuration
  reporter: [
    ['list'],
    ['html', { outputFolder: 'test-results/html-report' }]
  ],
  
  // Snapshot configuration
  snapshotDir: 'snapshots',
  
  // Projects for different shells/platforms
  projects: [
    {
      name: 'bash',
      use: {
        shell: 'bash',
        cols: 80,
        rows: 24,
      }
    },
    {
      name: 'zsh',
      use: {
        shell: 'zsh',
        cols: 80,
        rows: 24,
      }
    }
  ]
});
