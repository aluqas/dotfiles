# Protocol for AI Agents

This repository follows a single-root, home-centric Nix architecture.

The core rule is:

**Modules Implement, Profiles Compose, Hosts Instantiate, Homes Own User Environment**

## 1. Interaction Protocol

- Build tools: never use raw `nixos-rebuild`.
  - Use `nh darwin switch . -H <host>` or the matching `devenv` script such as `switch-mac`.
  - Use `nix build --dry-run .#<target>` or the matching `devenv` script such as `build-mac` for dry-run checks.
  - Use `check` inside `devenv shell` for lint and flake validation.
- Paths: prefer relative paths or `$FLAKE_ROOT`.
- Secrets: do not output secret contents. Use `ragenix` / age-based wiring already present in the repo.

## 2. Assembly Model

- `flake.nix` declares inputs, `hostDefinitions`, deploy outputs, and templates.
- `lib/hosts.nix` is the central assembly point.
  - It constructs Darwin and NixOS systems.
  - It injects shared modules, Home Manager, Stylix, ragenix, and other common platform wiring.
  - It passes `inputs`, `hostVars`, `globalVars`, `paths`, and `saqulaLib` through `specialArgs`.
- `hosts/*/default.nix` provides host-specific last-mile configuration.
- `homeImports` from `flake.nix` determine how `profiles/home/*` and `hosts/*/home.nix` are attached to each user environment.

When deciding where to place logic, preserve this flow instead of bypassing it.

## 3. Placement Rules

### `flake.nix`

- Keep topology here: inputs, host definitions, deploy nodes, templates.
- Do not put host-specific behavior or large implementation logic here.

### `lib/*`

- Use `lib/*` for shared helper logic, shared constants, path helpers, key/secrets helpers, and host assembly support.
- Keep `lib/hosts.nix` focused on composition and wiring, not machine-specific policy.

### `modules/shared/*`

- Define shared option surfaces and types here.
- This layer should describe the contract used by platform-specific implementations.

### `modules/darwin/*` and `modules/nixos/*`

- Put reusable platform-specific implementations here.
- Keep modules small and purpose-specific.
- If a feature is reusable across hosts of the same platform, it belongs here first.

### `modules/home/*`

- Put reusable Home Manager implementations here.
- Shared editor, shell, CLI, agent, infra, and security behavior should be implemented here.

### `profiles/*`

- Use profiles to compose reusable bundles with plain `imports`.
- Profiles set defaults and policy.
- Do not reintroduce role frameworks or option-toggle namespaces as an abstraction layer.

### `hosts/*`

- Hosts should stay thin.
- Import hardware config, system profiles, and minimal machine-specific overrides.
- If behavior is shared by multiple machines, move it up into a profile or module.
- `vars.nix` is for host constants and machine facts, not general reusable logic.

### `secrets/*`

- Encrypted secret payloads live in `secrets/*.age`.
- Encryption policy lives in `secrets/secrets.nix`.
- Public key definitions live in `lib/keys.nix`.
- Secret helper definitions live in `lib/secrets.nix`.

### `ops/*`

- Put deploy wiring, bootstrap scripts, and environment docs here.
- `ops/lab` is an operational surface, not a second architecture root.

## 4. Cross-Cutting Systems

### Stylix

- Stylix is the shared theming system.
- The actual host wiring is injected from `lib/hosts.nix`.
- Shared theme policy belongs in `profiles/home/stylix/default.nix`.
- Theme assets belong under `profiles/home/stylix/*`.
- Do not duplicate theme policy in each host unless the override is truly machine-specific.

### Secrets

- Use the existing age / ragenix pipeline.
- Prefer helper-based secret definitions over ad hoc inline secret wiring.
- Consumers should usually declare which `config.age.secrets.*` they need, not reinvent file placement rules.

## 5. Review Checklist

Before submitting changes, ask:

1. Is this reusable implementation, composition policy, user environment, or host-specific last-mile config?
2. Am I using `profiles/home/*` for shared UX and `hosts/*/home.nix` for host-specific home config?
3. Did I keep assembly logic in `lib/hosts.nix` and not leak it into unrelated files?
4. Did I avoid introducing a new wrapper option when native HM/NixOS options are enough?
5. If the change touches theming or secrets, did I update the shared Stylix / secrets wiring rather than hardcoding per-host drift?
6. Did I run `fmt` or `check` inside `devenv shell` if the change needs validation?

## 6. Comment Policy

- Use Japanese for repository-owned comments and documentation unless English is required by upstream names, quoted text, or protocol-specific syntax.
- Prefer comments that explain intent, constraints, or non-obvious reasons.
- Avoid restating what the code already makes obvious.
- Keep inline comments short and local to the code they clarify.

## 7. Documentation Expectation

- Update `README.md` when the change affects how a human enters, builds, switches, or navigates the repo.
- Update `docs/ARCHITECTURE.md` when the change affects placement rules, shared assembly, or extension strategy.
- Update `secrets/README.md` when the change alters secret layout, key expectations, or operational recovery steps.
