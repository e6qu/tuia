import { defineConfig } from '@microsoft/tui-test';

export default defineConfig({
  testMatch: 'tests/**/*.spec.ts',
  timeout: 30000,
  retries: 2,
  trace: true,
  reporter: 'list',
  snapshotDir: 'snapshots',
});
