import { defineConfig } from '@microsoft/tui-test';

export default defineConfig({
  testMatch: 'tests/**/*.spec.ts',
  timeout: 60000,
  retries: 1,
  trace: true,
  reporter: 'list',
  snapshotDir: 'snapshots',
});
