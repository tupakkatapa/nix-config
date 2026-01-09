---
model: claude-sonnet-4-0
---

Test-Driven Development for: $ARGUMENTS

## Red Phase - Write Failing Tests

1. **Define Expected Behavior**
   - What should this code do?
   - What are the edge cases?
   - What errors should be handled?

2. **Write Tests First**
   - Tests must fail initially
   - One behavior per test
   - Clear, descriptive names

3. **Verify Failure**
   - Run tests to confirm they fail
   - Failure should be for the right reason (missing implementation, not test error)

## Green Phase - Make Tests Pass

1. **Minimal Implementation**
   - Write just enough code to pass tests
   - No extra features
   - No premature optimization

2. **Verify Success**
   - All tests pass
   - No tests were modified to pass

## Refactor Phase - Improve Code

1. **Clean Up**
   - Remove duplication
   - Improve naming
   - Simplify logic

2. **Maintain Green**
   - Tests must remain passing
   - Run tests after each change

## Cycle

Repeat for each new behavior:
1. RED: Write failing test
2. GREEN: Make it pass
3. REFACTOR: Clean up

Keep tests fast and isolated.
