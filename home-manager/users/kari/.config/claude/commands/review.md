Perform strict code review of current changes.

## Review Scope

Analyze: `git diff` (staged and unstaged changes)

## Review Checklist

### Code Quality
- [ ] Code is clear and readable
- [ ] Functions do one thing well
- [ ] No unnecessary complexity
- [ ] Follows existing patterns

### Correctness
- [ ] Logic is correct
- [ ] Edge cases handled
- [ ] Error handling appropriate
- [ ] No regressions introduced

### Security
- [ ] No exposed secrets
- [ ] Input validation present
- [ ] No injection vulnerabilities
- [ ] Safe data handling

### Compliance with CLAUDE.md
- [ ] Follows project guidelines
- [ ] Matches existing patterns
- [ ] No magic values
- [ ] Data-driven implementation

## Output

For each issue found:
1. **Location**: file:line
2. **Severity**: Critical / Warning / Suggestion
3. **Issue**: What's wrong
4. **Fix**: How to resolve

Address critical issues immediately.
