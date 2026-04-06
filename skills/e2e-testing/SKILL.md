---
name: e2e-testing
description: Playwright E2E testing patterns — Page Object Model, configuration, CI/CD integration, flaky test strategies, and artifact management for web and mobile web apps.
metadata:
  tags: e2e, playwright, testing, ci-cd, automation, web
  origin: ECC (adapted for Antigravity)
---

## When to Use

- Writing E2E tests for a web application
- Setting up Playwright in a new project
- Fixing flaky tests
- Integrating E2E into a CI/CD pipeline
- Reviewing E2E test structure

---

## Project Structure

```
tests/
├── e2e/
│   ├── auth/
│   │   ├── login.spec.ts
│   │   ├── logout.spec.ts
│   │   └── register.spec.ts
│   ├── features/
│   │   ├── browse.spec.ts
│   │   └── create.spec.ts
│   └── api/
│       └── endpoints.spec.ts
├── fixtures/
│   ├── auth.ts
│   └── data.ts
└── playwright.config.ts
```

---

## Page Object Model (POM)

Encapsulate page interactions into classes — keeps tests readable and DRY:

```typescript
import { Page, Locator } from '@playwright/test'

export class ItemsPage {
  readonly page: Page
  readonly searchInput: Locator
  readonly itemCards: Locator
  readonly createButton: Locator

  constructor(page: Page) {
    this.page = page
    this.searchInput = page.locator('[data-testid="search-input"]')
    this.itemCards = page.locator('[data-testid="item-card"]')
    this.createButton = page.locator('[data-testid="create-btn"]')
  }

  async goto() {
    await this.page.goto('/items')
    await this.page.waitForLoadState('networkidle')
  }

  async search(query: string) {
    await this.searchInput.fill(query)
    await this.page.waitForResponse(resp => resp.url().includes('/api/search'))
    await this.page.waitForLoadState('networkidle')
  }

  async getItemCount() {
    return this.itemCards.count()
  }
}
```

---

## Test Structure

```typescript
import { test, expect } from '@playwright/test'
import { ItemsPage } from '../../pages/ItemsPage'

test.describe('Item Search', () => {
  let itemsPage: ItemsPage

  test.beforeEach(async ({ page }) => {
    itemsPage = new ItemsPage(page)
    await itemsPage.goto()
  })

  test('should filter results by keyword', async ({ page }) => {
    await itemsPage.search('widget')

    const count = await itemsPage.getItemCount()
    expect(count).toBeGreaterThan(0)
    await expect(itemsPage.itemCards.first()).toContainText(/widget/i)
  })

  test('should show empty state for no results', async ({ page }) => {
    await itemsPage.search('xyznonexistent99999')

    await expect(page.locator('[data-testid="no-results"]')).toBeVisible()
    expect(await itemsPage.getItemCount()).toBe(0)
  })
})
```

---

## Playwright Configuration

```typescript
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,       // Fail if .only() left in code
  retries: process.env.CI ? 2 : 0,   // Retry on CI for flaky resilience
  workers: process.env.CI ? 1 : undefined,
  reporter: [
    ['html', { outputFolder: 'playwright-report' }],
    ['junit', { outputFile: 'playwright-results.xml' }],
  ],
  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 10_000,
    navigationTimeout: 30_000,
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
    { name: 'mobile-chrome', use: { ...devices['Pixel 5'] } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
})
```

---

## Fixing Flaky Tests

### Race Conditions
```typescript
// BAD — assumes element is instantly ready
await page.click('[data-testid="button"]')

// GOOD — auto-wait via locator
await page.locator('[data-testid="button"]').click()
```

### Network Timing
```typescript
// BAD — arbitrary sleep
await page.waitForTimeout(5000)

// GOOD — wait for a specific condition
await page.waitForResponse(resp => resp.url().includes('/api/data'))
```

### Animation Timing
```typescript
// BAD — click during animation
await page.click('[data-testid="menu-item"]')

// GOOD — wait for visible and stable
await page.locator('[data-testid="menu-item"]').waitFor({ state: 'visible' })
await page.waitForLoadState('networkidle')
await page.locator('[data-testid="menu-item"]').click()
```

### Quarantine Flaky Tests
```typescript
test('flaky: complex flow', async ({ page }) => {
  test.fixme(true, 'Flaky - Issue #123 - investigating')
  // test body
})
```

Identify flakiness:
```bash
npx playwright test tests/search.spec.ts --repeat-each=10
```

---

## CI/CD Integration (GitHub Actions)

```yaml
name: E2E Tests
on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
      - run: npm ci
      - run: npx playwright install --with-deps
      - run: npx playwright test
        env:
          BASE_URL: ${{ vars.STAGING_URL }}
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: playwright-report/
          retention-days: 30
```

---

## Test Selectors Priority

Use this selector priority — `data-testid` attributes are the most stable:

```
1. data-testid="..."    → Most stable, explicit testing attribute
2. role + text          → page.getByRole('button', { name: 'Submit' })
3. text content         → page.getByText('Welcome back')
4. CSS class            → Fragile — avoid for critical selectors
5. XPath               → Last resort only
```

---

## Artifacts in Tests

```typescript
// Screenshots
await page.screenshot({ path: 'artifacts/after-login.png' })
await page.screenshot({ path: 'artifacts/full-page.png', fullPage: true })

// Element-scoped
await page.locator('[data-testid="chart"]').screenshot({ path: 'artifacts/chart.png' })
```

---

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| `waitForTimeout(5000)` | Wait for specific network/DOM event |
| Hardcoded test data assumed to exist | Use fixtures or set up data in `beforeEach` |
| No Page Object Model | Extract selectors and actions into page classes |
| `.only()` left in committed tests | `forbidOnly: !!process.env.CI` in config |
| No `data-testid` attributes | Add to all interactive elements |
