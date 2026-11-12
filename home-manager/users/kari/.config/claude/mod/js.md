# JavaScript project context (tupakkatapa house style)

Conventions from `~/Workspace/tupakkatapa/molesk` (Node and Express server, the reference JS project) and `~/Workspace/tupakkatapa/kaloriina` (browser front end of a Rust server). Assumes the Nix layer in `~/.claude/tt/mod/nix.md`. Shell scripts follow `~/.claude/tt/mod/sh.md`. Per-project `./CLAUDE.md` may override anything here.

## Philosophy
- **Yarn when there are npm dependencies.** `yarn.lock` is the source of truth and feeds `fetchYarnDeps` (molesk). No npm, no pnpm. A front end without npm dependencies has no `package.json` (kaloriina: plain `.mjs` modules, vendored files under `web/vendor/`).
- **No build step.** No bundler or transpiler in either project.
- **Module system follows the runtime.** CommonJS in the Node server (`require`, `module.exports`, molesk); ES modules in the browser and its tests (`.mjs`, kaloriina). Do not mix in one tree.
- **Pedantic oxlint** in pre-commit and in `nix flake check`. Suppressions (`// oxlint-disable`, `// eslint-disable`) follow the global rule in `~/.claude/CLAUDE.md`.
- **ESLint is not run.** molesk keeps `eslint`, `@eslint/js` and `globals` as devDependencies only; it has no `eslint.config.js`.

## package.json

Shape of `molesk/package.json` (no `description`, `main`, `private`, `license`, `engines`, `scripts`):

```json
{
  "name": "<name>",
  "version": "0.1.0",
  "bin": "app.js",
  "dependencies": {
    "express": "^4.21.2"
  },
  "devDependencies": {
    "@axe-core/playwright": "^4.10.2",
    "prettier": "^3.4.2"
  }
}
```

`"bin"` is a string, so the binary takes the package name. `@playwright/test` is not a devDependency; it comes from Nix.

## Linter and formatter

- **oxlint**, default form from `molesk/flake.nix`: `lint = "${lib.getExe pkgs.oxlint} --deny pedantic --deny complexity";`, no config file.
- Exception: kaloriina uses `.oxlintrc.json` (categories `correctness`, `suspicious`, `pedantic` as errors, `complexity` capped at 20, per-rule comments) and runs `oxlint --deny-warnings web tests playwright.config.js`. Use a config file when rules need tuning; comment each relaxed rule.
- **prettier** through treefmt: `programs.prettier.enable = true;`, no `.prettierrc`. Exclude content and fixtures (`settings.formatter.prettier.excludes = [ "contents/**" "tests/fixtures/**" ];` in molesk).

## Pre-commit hooks

Added to the hooks block of `nix.md`. From `molesk/flake.nix` (`lint` as above):

```nix
pedantic-oxlint = {
  enable = true;
  entry = lint;
  always_run = true;
  pass_filenames = false;
};
playwright = {
  enable = true;
  entry = "${playwrightTest}";
  files = "^(app\\.js|lib/|public/|views/|tests/|playwright\\.config\\.js|package\\.json|yarn\\.lock)";
  pass_filenames = false;
};
```

- The lint command is one `let` binding used by the hook and by `checks.lint`.
- `files` for playwright lists what can change the result; content does not trigger it.
- kaloriina adds a `node-test` hook for unit tests and names its lint hook `oxlint`.

## Playwright

Default, from `molesk/flake.nix`: Playwright and its browsers come from nixpkgs.

```nix
playwrightEnv = {
  PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
  PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
};
playwrightTest = pkgs.writeShellScript "playwright-test" ''
  ${lib.toShellVars playwrightEnv}
  export ${lib.concatStringsSep " " (lib.attrNames playwrightEnv)}
  exec ${lib.getExe' pkgs.playwright-test "playwright"} test "$@"
'';
```

```nix
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    yarn
    nodejs
    oxlint
    pre-commit
    playwright-test
  ];
  env = playwrightEnv;
  shellHook = config.pre-commit.installationScript;
};
```

The wrapper script gives the hook the same environment outside the devshell. Exception: kaloriina pins `inputs.playwright.url = "github:pietdevries94/playwright-web-flake/1.55.0";` and uses `inputs'.playwright.packages.{playwright-test,playwright-driver.browsers}`; do this only when the project needs a Playwright version nixpkgs does not have.

Config, shortened from `molesk/playwright.config.js` (the second `webServer` entry and `launchOptions` are left out):

```js
const { defineConfig, devices } = require("@playwright/test");

const SITE_PORT = 18_080;
const node = JSON.stringify(process.execPath);

module.exports = defineConfig({
  testDir: "./tests",
  testMatch: "*.spec.js",
  fullyParallel: true,
  forbidOnly: Boolean(process.env.CI),
  reporter: "line",
  use: {
    baseURL: `http://127.0.0.1:${SITE_PORT}`,
    trace: "retain-on-failure",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "mobile-chromium", use: { ...devices["Pixel 5"], hasTouch: true } },
  ],
  webServer: [
    {
      command: `${node} app.js tests/fixtures/site -a 127.0.0.1 -p ${SITE_PORT}`,
      url: `http://127.0.0.1:${SITE_PORT}/favicon.ico`,
      reuseExistingServer: false,
      timeout: 10_000,
    },
  ],
});
```

- The server runs against fixtures on its own port and is never reused, so a dev server cannot leak into a run.
- Chromium only, desktop and mobile.
- No retries in molesk; kaloriina sets `retries: 0` with `failOnFlakyTests: true`.
- Block third-party hosts in tests (`--host-resolver-rules` in molesk's `launchOptions`).

## Unit tests

Node's built-in runner, no framework: `node --test 'tests/unit/*.test.js'` as `checks.unit` in molesk; `node --test tests/*.test.mjs` as hook and check in kaloriina. Browser specs are `tests/*.spec.js`; unit tests are `*.test.js` or `*.test.mjs`.

## Packaging

From `molesk/package.nix` (`meta` left out):

```nix
{ stdenv
, lib
, fetchYarnDeps
, yarnConfigHook
, yarnInstallHook
, nodejs
}:
let
  manifest = lib.importJSON ./package.json;
in
stdenv.mkDerivation {
  pname = manifest.name;
  inherit (manifest) version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./app.js
      ./lib
      ./views
      ./public
      ./package.json
      ./yarn.lock
    ];
  };

  offlineCache = fetchYarnDeps {
    yarnLock = ./yarn.lock;
    hash = "sha256-…";
  };

  nativeBuildInputs = [ yarnConfigHook yarnInstallHook nodejs ];

  # No build step: plain Node app served by app.js.
  dontBuild = true;
}
```

Update `offlineCache.hash` with every `yarn.lock` change.

## Style expectations (molesk)

- Wrap async Express handlers so errors reach `next` (`asyncHandler` in `lib/helpers.js`):
  ```js
  const asyncHandler = (fn) => (req, res, next) =>
    Promise.resolve(fn(req, res, next)).catch(next);
  ```
- One error middleware: `setupErrorHandlers(app, renderPage)` in `lib/errors.js`. Routes throw; the middleware decides the response.
- Logging is `console.error` for failures; `console.log` only for CLI output. No logger dependency.
- Rate limiting with `express-rate-limit`; EJS views in `views/`; static files in `public/`.
- No global state: modules export functions.

## Project layout (molesk)

```
package.json  yarn.lock  package.nix  module.nix  flake.nix  flake.lock
app.js                  CLI and server entry
lib/                    cli.js content.js errors.js helpers.js markdown.js
views/  public/
scripts/                development scripts
tests/*.spec.js         Playwright specs
tests/unit/*.test.js    node --test
tests/fixtures/
tests/module.nix        NixOS VM test
playwright.config.js
docs/plans/             ( /tt:plan output )
```

The NixOS module follows `nix.md` ("NixOS module style").

## Gotchas
- Without the three Playwright variables, Playwright tries to download browsers.
- `node_modules`, `/test-results/` and `/playwright-report/` stay ignored.
