Debug issue: $ARGUMENTS

## Analysis Phase

1. **Reproduce the Issue**
   - Understand the error/symptom
   - Identify reproduction steps
   - Gather error messages and stack traces

2. **Isolate the Problem**
   - Identify the failing code path
   - Check recent changes (`git log`, `git diff`)
   - Narrow down to specific component

3. **Root Cause Analysis**
   - Why is this happening?
   - What conditions trigger it?
   - What assumptions were violated?

## Solution Phase

### Quick Fix
- Minimal change to resolve the issue
- Risk assessment

### Proper Fix
- Best long-term solution
- Any refactoring needed

### Prevention
- How to prevent recurrence
- Tests to add

## Implementation

1. Apply the fix
2. Verify the fix works
3. Add tests if appropriate
4. Run pre-commit checks
