
## Preamble
- Read `~/.claude/CLAUDE.md` (global) and `./CLAUDE.md` (project) for guidelines and context, if not already.
- When unsure what to do, choose the most fundamentally right action instead of asking for clarification.
- **Do not push or commit anything unless explicitly told to do so.**

---

# JavaScript project context (tupakkatapa house style)

Distilled from `~/Workspace/local/tupakkatapa/molesk` (the canonical JS+Nix project). Assumes the Nix layer described in `/tt:context:nix`. Shell scripts in the project follow `/tt:context:shell`. Per-project `./CLAUDE.md` may override anything here.

## Philosophy
- **Yarn, not npm or pnpm.** `yarn.lock` is the source of truth; pairs cleanly with `pkgs.mkYarnPackage` for Nix packaging. Lock file commits with every dependency change.
- **CommonJS is fine.** No reflex migration to ESM unless the project surface needs it. Server-side Node tooling is still CJS-friendly; mixing ESM and CJS without reason is debt.
- **Linter is pedantic.** `oxlint --deny pedantic --deny complexity` runs in pre-commit. High standards by default; exceptions documented.
- **No `// eslint-disable` / `// oxlint-disable` / `// @ts-ignore` without a justifying comment** on the line above naming the rule and the reason. Matches the global rule in `~/.claude/CLAUDE.md`.
- **ESLint stays as a devDep for editor integration only.** No `eslint.config.js` in the repo; enforcement is `oxlint` via pre-commit. `eslint`, `@eslint/js`, `globals` ship as devDeps so that editor LSP works.

## package.json — real shape

The minimum that molesk ships (no `description`, `main`, `private`, `license`, `engines`, `scripts`):

```json
{
  "name": "<name>",
  "version": "0.1.0",
  "bin": "app.js",
  "dependencies": {
    "express": "^4",
    "ejs": "^3"
  },
  "devDependencies": {
    "@eslint/js": "^9",
    "eslint": "^9",
    "globals": "^15",
    "prettier": "^3"
  }
}
```

Notes:
- `"bin": "app.js"` is a **string**, not an object. molesk relies on `name` becoming the bin name.
- `"private": true` is added only when the project must not be published to npm (rarely needed; Nix packaging is the distribution path).
- `engines` is added when a project needs a specific Node major (rare; nixpkgs version is the binding).
- `scripts` are added when a developer needs `yarn start` or similar; molesk uses `node app.js` directly and relies on the devshell + pre-commit for everything else.

## Linter & formatter

- **`oxlint`** (Rust-based, fast) for linting:
  - `oxlint --deny pedantic --deny complexity` in pre-commit.
  - File pattern: `\.(js|ts|jsx|tsx)$`.
  - No `oxlintrc.json` unless overriding defaults; the CLI flags are the source of truth.
- **`prettier`** for formatting, run via `treefmt-nix`:
  ```nix
  treefmt.config.programs.prettier.enable = true;
  ```
  No `.prettierrc`; defaults are intentional (2-space indent, double quotes, semicolons, trailing comma — match Prettier 3 defaults).
- **`eslint`** is a devDependency for editor integration only.

## Pre-commit hooks for JS

Added to the `pre-commit.settings.hooks` block from `/tt:context:nix`. **Verified verbatim** against `molesk/flake.nix`:

```nix
pre-commit.settings.hooks = {
  treefmt = { /* from /tt:context:nix */ };
  pedantic-oxlint = {
    enable = true;
    entry = "oxlint --deny pedantic --deny complexity";
    files = "\\.(js|ts|jsx|tsx)$";
    pass_filenames = false;
  };
  playwright = {
    enable = true;
    entry = "${inputs'.playwright.packages.playwright-test}/bin/playwright test";
    pass_filenames = false;
    files = "\\.(js|ts|jsx|tsx|html|css|md|json)$";
  };
};
```

Notes:
- Hook name is `pedantic-oxlint`, not `oxlint`.
- `pass_filenames = false` — oxlint scans the whole tree, not a filtered list.
- `playwright` entry uses the pinned flake input (`inputs'.playwright.packages.playwright-test`), not `pkgs.playwright-test`. See the input pinning below.
- If the test surface is expensive, gate `playwright` to a `pre-push` stage instead of `pre-commit` per-project.

## Playwright via `playwright-web-flake`

Playwright browser binaries are large and version-pinned. Use the dedicated flake input rather than nixpkgs:

```nix
inputs.playwright.url = "github:pietdevries94/playwright-web-flake/1.55.0";
# (no `.inputs.nixpkgs.follows = "nixpkgs"` — playwright-web-flake pins its own)
```

Then in `perSystem` consume via `inputs'`:

```nix
perSystem = { self', inputs', pkgs, config, ... }: {
  devShells.default = pkgs.mkShell {
    packages = with pkgs; [
      yarn yarn2nix nodejs oxlint pre-commit
      inputs'.playwright.packages.playwright-test
    ];
    env = {
      PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
      PLAYWRIGHT_BROWSERS_PATH = "${inputs'.playwright.packages.playwright-driver.browsers}";
      PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
    };
    shellHook = config.pre-commit.installationScript;
  };
};
```

Without those env vars, `yarn test` re-downloads ~400 MB on every fresh shell.

## Packaging — real idiom

molesk's `package.nix` is intentionally minimal:

```nix
{ pkgs }:
pkgs.mkYarnPackage {
  name = "<name>";
  version = "0.1.0";
  src = ./.;
  packageJSON = ./package.json;
  yarnLock = ./yarn.lock;
}
```

Notes:
- `name` and `version` are hardcoded here, not derived from `package.json` via `lib.importJSON`. The pattern is acceptable when the project rebuilds the derivation on every release anyway (and `version` lives in two places: `package.json` and `package.nix`). For projects where drift matters, derive from `package.json`:

  ```nix
  let pkg = lib.importJSON ./package.json;
  in pkgs.mkYarnPackage {
    name = pkg.name;
    version = pkg.version;
    ...
  }
  ```

Prefer the derived form for new projects; tolerate the hardcoded form when matching molesk's existing style.

## Style expectations

- **CommonJS by default.** `require()` / `module.exports`. ESM only when a dependency demands it (then commit to ESM across the file).
- **Async via Promises + `async`/`await` at the boundary; helper wrappers for the middle.** For Express, the `asyncHandler` pattern (HOF that wraps and routes errors to `next`) avoids unhandled-rejection surprises:
  ```js
  const asyncHandler = fn => (req, res, next) =>
    Promise.resolve(fn(req, res, next)).catch(next);
  ```
- **Centralised error handling.** A `setupErrorHandlers(app)` function in `lib/errors.js` attaches the final error middleware. Routes throw; the middleware decides the response shape.
- **No `console.log` in shipped paths.** Use a logger (pino, bunyan) configured at the entry point. Quick scripts can `console.log`.
- **No global state.** Modules export functions or factories; state lives in objects passed explicitly.
- **EJS for views** unless the project needs a richer templating story.
- **Express middleware composition** for HTTP: rate limiting, helmet, body parsing, async handlers, then routes, then the error handler.

## Project layout

```
.
├── package.json
├── yarn.lock
├── package.nix
├── module.nix              (NixOS service module, when applicable)
├── flake.nix
├── flake.lock
├── app.js                  (CLI / server entry)
├── lib/
│   ├── errors.js
│   ├── helpers.js          (asyncHandler, html-escape, path-safe joins)
│   └── <module>.js
├── views/                  (EJS templates)
├── public/                 (static assets)
├── scripts/                (build / one-off scripts)
├── tests/
│   ├── content.spec.js
│   ├── responsive.spec.js
│   ├── accessibility.spec.js
│   ├── error-handling.spec.js
│   └── theme.spec.js
├── playwright.config.js
├── docs/
│   └── plans/              ( /tt:plan output )
└── README.md
```

## Playwright config — real shape

Verbatim shape from `molesk/playwright.config.js`:

```js
const { defineConfig, devices } = require("@playwright/test");

module.exports = defineConfig({
  testDir: "./tests",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: "line",
  use: {
    baseURL: "http://localhost:8080",
    trace: "on-first-retry",
  },
  projects: [
    { name: "chromium",        use: { ...devices["Desktop Chrome"] } },
    { name: "mobile-chromium", use: { ...devices["Pixel 5"], hasTouch: true } },
    // Firefox and WebKit disabled for NixOS compatibility
  ],
  webServer: {
    command: "node app.js",
    url: "http://localhost:8080",
    reuseExistingServer: !process.env.CI,
    timeout: 10000,
  },
});
```

Notes:
- `defineConfig` from `@playwright/test`, not a bare module export.
- `fullyParallel: true` + `workers: process.env.CI ? 1 : undefined` — single worker in CI for determinism, parallel locally.
- `baseURL` set; tests use relative URLs via the `page.goto("/foo")` idiom.
- Firefox/WebKit commented out, not deleted — documents the intentional NixOS limitation.

## NixOS module (when shipping a service)

`module.nix` provides a NixOS systemd service with:
- Options DSL — see `/tt:context:nix` (`mkEnableOption`, typed `mkOption`).
- Hardening defaults: `NoNewPrivileges`, `ProtectSystem = "strict"`, `ProtectHome = true`, dedicated user/group.
- Config injection via `escapeShellArg` into the wrapped binary.
- Firewall rule opening only when the user opts in.

## CHANGELOG

`Keep a Changelog` + SemVer. Versions match `package.json`. See `/tt:actions:bump`.

## Gotchas
- `node_modules` is large and slow; never check it in. `.gitignore` covers it (see `/tt:context:nix` baseline).
- `yarn install --frozen-lockfile` in CI / Nix; `yarn install` (writes lock) only locally.
- Playwright browser env vars are essential; without them, `yarn test` reaches out to download.
- ESM/CJS interop subtleties at the dependency boundary — pin awkward dependencies, or wrap them in a CJS shim, rather than migrate the whole file.
