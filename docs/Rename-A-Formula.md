---
last_review_date: "1970-01-01"
---

# Renaming a Formula or Cask

## Renaming a Formula

Sometimes software and formulae need to be renamed. To rename a formula you need to:

1. Rename the formula file and its class to a new formula name. The new name must meet all the usual rules of formula naming. Fix any test failures that may occur due to the stricter requirements for new formulae compared to existing formulae (e.g. `brew audit --strict` must pass for that formula).

2. Create a pull request on the corresponding tap deleting the old formula file, adding the new formula file, and adding it to `formula_renames.json` with a commit message like `newack: renamed from ack`. Use the canonical name (e.g. `ack` instead of `user/repo/ack`).

A `formula_renames.json` example for a formula rename:

```json
{
  "ack": "newack"
}
```

## Renaming a Cask

To rename a cask, follow a similar process:

1. Rename the cask file to the new cask token. The new token must meet all the usual rules of cask naming.
2. Create a pull request on the corresponding tap deleting the old cask file, adding the new cask file, and adding it to `cask_renames.json` with a commit message like `new-token: renamed from old-token`.

A `cask_renames.json` example:

```json
{
  "old-token": "new-token"
}
```

## Important Rules

When editing `formula_renames.json` or `cask_renames.json`, follow these rules:

1. **Do not include `.rb` file extensions** - Use only the formula/cask token name
2. **Ensure the target exists** - The new name must be an existing formula/cask in the tap
3. **Avoid chained renames** - Don't create chains like `A → B` and `B → C`. Collapse chains to `A → C` directly as chained renames don't work automatically
4. **Check for conflicts** - The old name should not conflict with an existing formula/cask

These rules are validated by `brew audit` for tap maintainers.
