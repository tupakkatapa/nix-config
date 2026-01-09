Run quality checks and fix any issues.

## Checks

```bash
pre-commit run --all-files
```

## Process

1. Run pre-commit hooks
2. If issues found:
   - Fix automatically fixable issues
   - Address manual fixes required
   - Re-run until clean
3. Report results

## On Failure

For each failure:
- Identify the root cause
- Apply the fix
- Verify the fix works
- Continue until all checks pass
