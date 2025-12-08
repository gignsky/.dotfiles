# Commit Message Language Enhancement Guide

## Purpose
Eliminate overuse of generic terms like "final" in commit messages. Adopt more descriptive, varied language that better communicates the actual nature of changes.

## Problematic Patterns

### Overused Terms
- **"final"** - vague, doesn't indicate what makes it final
- **"update"** - generic, doesn't specify the type of change
- **"fix"** - too broad without context
- **"change"** - meaningless without specifics

### Better Alternatives

#### Instead of "final"
- **complete** - indicates task completion
- **conclude** - suggests ending a series
- **finalize** - when actually finalizing something specific
- **integrate** - when bringing components together
- **consolidate** - when combining multiple elements
- **establish** - when creating something permanent

#### Instead of generic "update"
- **enhance** - improvements to existing functionality
- **refactor** - code structure improvements
- **optimize** - performance improvements
- **expand** - adding new capabilities
- **modernize** - bringing up to current standards
- **streamline** - simplifying processes

#### Instead of vague "fix"
- **resolve** - addressing specific issues
- **repair** - restoring broken functionality
- **correct** - fixing errors or mistakes
- **address** - handling known problems
- **remedy** - solving identified issues

## Commit Message Templates

### Feature Implementation
```
feat: implement [specific feature]
feat: add [new capability]
feat: introduce [new system]
```

### Bug Resolution
```
fix: resolve [specific issue]
fix: correct [error description]
fix: repair [broken functionality]
```

### Improvements
```
enhance: improve [specific area]
optimize: streamline [process/system]
refactor: restructure [component]
```

### Documentation
```
docs: expand [documentation area]
docs: clarify [specific instructions]
docs: establish [new documentation]
```

### System Changes
```
config: modernize [configuration aspect]
build: optimize [build process]
style: standardize [formatting/style]
```

## Enforcement Strategy
1. **Manual Review**: Check commit messages during review
2. **Pre-commit Hook**: Consider automated checking (future implementation)
3. **Habit Formation**: Practice descriptive language in all commits
4. **Examples**: Maintain this guide with good/bad examples

---
**Established**: Stardate 2025-12-03  
**Chief Engineer Montgomery Scott**  
*Clear communication starts with precise language*
