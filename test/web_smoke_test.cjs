const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');
const baseUrl = process.env.CARELINK_WEB_URL || 'http://localhost:8093';

async function main() {
  const browser = await chromium.launch({ headless: true });
  const directory = path.resolve(__dirname, '../build/web-smoke');
  fs.mkdirSync(directory, { recursive: true });
  const errors = [];
  const context = await browser.newContext({ viewport: { width: 393, height: 844 } });
  const page = await context.newPage();
  page.on('pageerror', error => errors.push(error.message));
  async function capture(name) {
    await page.screenshot({ path: path.join(directory, `${name}.png`) });
  }
  try {
    await page.goto(baseUrl, { waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 90000 });
    const semantics = page.locator('flt-semantics-placeholder');
    if (await semantics.count()) await semantics.evaluate(element => element.click());
    await page.waitForTimeout(2000);
    await capture('splash-mobile');
    await page.mouse.click(196, 400);
    await page.waitForTimeout(1800);
    for (let step = 0; step < 3; step++) {
      await page.mouse.click(326, 764);
      await page.waitForTimeout(600);
    }
    await page.getByText('Get Started', { exact: true }).waitFor({ timeout: 15000 });
    await capture('welcome-mobile');
    await page.getByText('Log In', { exact: true }).click();
    await page.getByText('Welcome Back', { exact: true }).waitFor();
    await capture('login-mobile');
    await page.getByText('Forgot Password?', { exact: true }).click();
    await page.getByRole('textbox').first().click();
    await page.keyboard.type('not-an-email', { delay: 80 });
    await page.waitForTimeout(300);
    await page.getByText('Send Reset Link', { exact: true }).click();
    await page.getByText('Please enter a valid email', { exact: true }).last().waitFor();
    await capture('forgot-password-validation');
    await page.mouse.click(50, 44);
    await page.getByText('Create Account', { exact: true }).click();
    await page.mouse.wheel(0, 800);
    await page.getByText('Create Account', { exact: true }).last().click();
    await page.getByText('Please enter your full name', { exact: true }).last().waitFor();
    await capture('registration-validation');
    await page.setViewportSize({ width: 1280, height: 900 });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.waitForSelector('flt-glass-pane', { state: 'attached' });
    await page.waitForTimeout(1500);
    await capture('splash-desktop');
    assert.deepEqual(errors, [], 'Browser JavaScript errors');
    console.log('PASS: mobile onboarding, welcome/login navigation, invalid reset email, registration validation, desktop rendering. No live accounts created.');
  } catch (error) {
    await capture('failure');
    console.error(await page.locator('body').ariaSnapshot());
    throw error;
  } finally {
    await browser.close();
  }
}

main().catch(error => { console.error(error.message); process.exitCode = 1; });
