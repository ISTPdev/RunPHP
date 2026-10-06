# Agent Instructions

## Philosophy
- Prefer simple procedural code.
- Avoid dependencies unless clearly justified.
- Keep the executable portable.
- Don't introduce abstractions for hypothetical future requirements.
- Preserve existing CLI behavior unless explicitly asked otherwise.

## Workflow
- Propose focused changes.
- Don't refactor unrelated code.
- Keep changes easy to review.
- Update CHANGELOG.md for user-visible changes.


## Syntax

### C-Style Syntax
- Put opening braces on the same line as the associated declaration or statement; keep closing braces on their own line.
- Always use braces for control-flow bodies, including single-statement bodies.
- Prefer concise syntax where readable, but do not omit braces or abbreviate delimiters.
