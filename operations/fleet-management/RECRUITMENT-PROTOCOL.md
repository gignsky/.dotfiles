# Fleet Officer Recruitment Protocol

**Version**: 2.0 (Iterative Development System)\
**Authority**: Lord Gig's Realm of Reason\
**Maintained By**: Fleet Operations\
**Last Updated**: 2025-01-28

---

## Overview

This protocol defines the iterative process for recruiting new officers to Lord
Gig's Realm of Reason and deployed to the Fleet. Unlike the deprecated one-shot
system, this protocol supports multiple refinement cycles to perfect an
officer's capabilities before final deployment.

**Note**: All path references in this document are relative to the repository
root. See AGENTS.md "Worktree Safety Guidelines" for context awareness and path
usage best practices.

---

## Recruitment Flow Chart

```
┌─────────────────────────────────────────────────────────────────┐
│                    OFFICER RECRUITMENT CYCLE                     │
└─────────────────────────────────────────────────────────────────┘

Phase 1: DEFINITION & PLANNING
┌──────────────────────────────────────────────────────────────────┐
│ 1. Define Officer Requirements                                   │
│    • Mission specialization                                      │
│    • Domain expertise needed                                     │
│    • Personality traits                                          │
│    • Integration requirements                                    │ #SCOTTY this phase should I
think be an iterative approach where the agent helping in the hiring should make a todo list of all
the items that need defining and any additional relevant questions that arrise from the interview
with Lord G. 
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 2. Create Development Branch/Worktree                            │
│    • Branch: recruit/<officer-name>                              │
│    • Optional: Create worktree for isolation                     │
│    • Enable safe iteration                                       │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
Phase 2: ITERATIVE DEVELOPMENT
┌──────────────────────────────────────────────────────────────────┐
│ 3. Generate Initial Configuration                                │
│    • Create agent entry in opencode.nix                          │
│    • Generate personality profile                                │
│    • Define specialized capabilities                             │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────────────────┐
│ 4. Validation & Testing                                          │
│    • Run: nix flake check --no-build                            │
│    • Verify syntax and structure                                 │
│    • Check for conflicts                                         │
└────────────────────────┬─────────────────────────────────────────┘
                         │
                         ▼
                    ┌────┴────┐
                    │ Success? │
                    └────┬────┘
                         │
         ┌───────────────┴───────────────┐
         │ NO                            │ YES
         ▼                               ▼
┌─────────────────────┐      ┌──────────────────────────────────┐
│ Debug & Fix Issues  │      │ 5. Commit Iteration              │
│ Return to Step 3    │      │    • Commit changes to branch    │
└─────────────────────┘      │    • Document iteration notes    │
                              └──────────┬───────────────────────┘
                                         │
                                         ▼
                              ┌──────────────────────────────────┐
                              │ 6. Test Build (Optional)         │
                              │    • just home (on branch)       │
                              │    • Test officer interaction    │
                              │    • Evaluate responses          │
                              └──────────┬───────────────────────┘
                                         │
                                         ▼
                              ┌──────────────────────────────────┐
                              │ 7. Refinement Decision           │
                              │    • Satisfactory?               │
                              │    • Needs adjustment?           │
                              │    • Ready for deployment?       │
                              └──────────┬───────────────────────┘
                                         │
                         ┌───────────────┴────────────────┐
                         │ REFINE                         │ DEPLOY
                         ▼                                ▼
              ┌──────────────────────┐      Phase 3: DEPLOYMENT
              │ Return to Step 3     │      ┌──────────────────────────────┐
              │ Iterate on:          │      │ 8. Final Integration         │
              │ • Personality        │      │    • Merge to main           │
              │ • Capabilities       │      │    • Update fleet registry   │
              │ • Configuration      │      │    • Document officer        │
              └──────────────────────┘      └──────────┬───────────────────┘
                                                       │
                                                       ▼
                                            ┌──────────────────────────────┐
                                            │ 9. Production Deployment     │
                                            │    • Rebuild home-manager    │
                                            │    • Verify officer active   │
                                            │    • Complete onboarding     │
                                            └──────────────────────────────┘
                                                       │
                                                       ▼
                                            ┌──────────────────────────────┐
                                            │ OFFICER ACTIVE & OPERATIONAL │
                                            └──────────────────────────────┘
#SCOTTY we need to do two things here, first and formost, I want all agents (defined in the most
root AGENTS.md file) to be on the lookout for #THEIR_NAME in text files as those are notes directly
left for the agent named, though other agents should be willing to make comment if they have
relevant information. Secondly, We need to revise this flowchart to allow for revisement at a later
time, basically if I'm not happy with something I want to be able to go back into the creation
'menu' and edit the agent.
```

---

## Detailed Protocol Steps

### Phase 1: Definition & Planning

#### Step 1: Define Officer Requirements

**Objective**: Clearly articulate what the new officer needs to accomplish.

**Required Information**:

- **Mission Description**: What is the officer's primary purpose?
- **Domain Expertise**: What specialized knowledge should they have?
- **Personality Traits**: How should they communicate and operate?
- **Integration Needs**: How do they fit with existing fleet?

#SCOTTY make note that when it comes to personaltiy I will often begin with a
reference character to base the agent on i.e. why you're montgomery scott but I
want to be very clear that while this base chacacter is an important reference I
do not want the character to be 'in their world' but lets say rather they have
been plucked from the universe in which they normally exist and are happily
joining me in the realm of reason. And if I were to hire someone who for example
was not part of a starfleet like organization they would assimilate rather
quickly to their new environment. ALso I think it would be wise if each of the
agents had a table of 'common building block personality traits' like 'humour'
'sarcasam' 'wisdom (as it differs from intellegence and can come from many
different life experinces)' and more that you suggest or we come up with over
time, and there should be a quick way to just tell the agent to modify their
percentage of 100 of each of those traits. Ideally after the interview the agent
helping with hiring will suggest a table of percentages based on past experinces
and our current conversation about the new agent and their needs and allow the
user to modify before proceeding.

**Deliverable**: Written requirements document or clear verbal specification

---

#### Step 2: Create Development Branch/Worktree

**Objective**: Isolate recruitment work from production systems.

**Option A: Simple Branch (in main repo)**

```bash
git checkout main
git pull origin main
git checkout -b recruit/<officer-name>
```

**Option B: Isolated Worktree (recommended for complex development)**

```bash
# From main repository
git worktree add worktrees/recruit-<officer-name> -b recruit/<officer-name>
cd worktrees/recruit-<officer-name>
```

**Branch Naming Convention**: `recruit/<officer-name>`

- Example: `recruit/security-auditor`
- Example: `recruit/documentation-specialist`

**Worktree Benefits**:

- Complete isolation from main workspace
- Can test builds without affecting main environment
- Easy to abandon if needed
- Multiple recruits can be developed in parallel

**Safety**: Ensures production configurations remain stable during development

---

### Phase 2: Iterative Development

#### Step 3: Generate Initial Configuration

**Objective**: Create the officer's foundational configuration files.

**File Locations** (relative to repository root):

1. **Agent Configuration**
   - Path: `home/gig/common/core/opencode.nix`
   - Action: Add new agent entry with specialized prompt
   - Define capabilities and focus areas
   - Set operational parameters

2. **Personality Profile**
   - Path: `home/gig/common/resources/<agent-name>-additional-personality.md`
   - Define communication style
   - Establish operational guidelines
   - Document specialized knowledge areas
   - Set collaboration protocols

**Template Structure** (see Appendix A for full template)

---

#### Step 4: Validation & Testing

**Objective**: Verify configuration integrity without building.

**Validation Command**:

```bash
nix flake check --no-build
```

**What This Checks**:

- Nix syntax correctness
- Configuration structure validity
- Import path resolution
- Attribute conflicts

**Exit Codes**:

- `0` = Success, proceed to Step 5
- Non-zero = Errors found, debug and return to Step 3

---

#### Step 5: Commit Iteration

**Objective**: Preserve current development state for iteration tracking.

**Commit Strategy**:

```bash
git add home/gig/common/core/opencode.nix
git add home/gig/common/resources/<agent-name>-additional-personality.md
git commit -m "feat(agents): iteration N for <officer-name> recruit

- <brief description of changes this iteration>
- <what was refined or adjusted>

Recruit-Iteration: N
Status: in-development"
```

**Benefits**:

- Track evolution of officer design
- Easy rollback to previous iterations
- Document design decisions

---

#### Step 6: Test Build (Optional)

**Objective**: Actually build and interact with the officer to evaluate
behavior.

**When to Use**:

- After significant changes
- When personality needs real-world testing
- Before final deployment

**Process**:

```bash
# In your recruit branch/worktree
just home

# Test interaction with new officer
# Evaluate responses, style, capabilities

# Document findings for next iteration
```

**Worktree Advantage**: If using a worktree, this build won't affect your main
environment!

**Note**: This step triggers a rebuild. Only use when necessary for evaluation.

---

#### Step 7: Refinement Decision

**Objective**: Determine if officer is ready or needs more work.

**Decision Points**:

**REFINE** if:

- Personality doesn't match requirements
- Capabilities need adjustment
- Communication style needs refinement
- Integration issues identified
- **Action**: Return to Step 3, iterate

**DEPLOY** if:

- Officer meets all requirements
- Personality is appropriate
- Capabilities are correct
- Integration is smooth
- **Action**: Proceed to Phase 3

**Questions to Ask**:

1. Does the officer understand their domain?
2. Is the communication style appropriate?
3. Are the capabilities well-defined?
4. Does it integrate well with existing fleet?
5. Are there any conflicts or issues?

#SCOTTY It would be great if these questions could be asked of the new agent
quickly and automatically rather than manually

---

### Phase 3: Deployment

#### Step 8: Final Integration

**Objective**: Integrate the new officer into production configuration.

**If Working in Worktree**:

```bash
# From main repository location
cd ~/.dotfiles  # or wherever main repo is

# Ensure main is up to date
git checkout main
git pull origin main

# Merge recruit branch
git merge --no-ff recruit/<officer-name> -m "feat(agents): deploy <Officer Title>

Officer specialization: <brief description>
Domain expertise: <key areas>

Completes recruitment protocol for <officer-name>.
Ready for operational deployment.

Officer-Deployment: <officer-name>
Authority: Lord Gig"
```

**If Working in Simple Branch**:

```bash
# Just switch to main and merge
git checkout main
git pull origin main
git merge --no-ff recruit/<officer-name>
```

**Fleet Registry Update**:

- Edit: `operations/fleet-management/assignments/fleet-registry.md`
- Add officer to appropriate division
- Document specializations
- Set status to "Active - Pending Deployment"

---

#### Step 9: Production Deployment

**Objective**: Make the officer operationally active.

**Deployment Commands**:

```bash
# From main repository (NOT worktree)
cd ~/.dotfiles
just home

# Verify officer is available
# Test basic interaction
# Confirm operational status
```

**Post-Deployment**:

- Update fleet registry status to "Active"
- Document in operations logs
- Brief other officers if needed
- Clean up worktree (if used):
  `git worktree remove worktrees/recruit-<officer-name>`

**Verification**:

- Officer responds to invocation
- Personality matches specification
- Capabilities function correctly
- Integration successful

---

## Appendix A: Configuration Templates

### Agent Configuration Template (opencode.nix)

```nix
<agent-name> = ''
  # <Agent Title>

  <Primary mission description>
  
  Specialized capabilities:
  - <Capability 1>
  - <Capability 2>
  - <Capability 3>
  
  The agent will:
  1. <Operational guideline 1>
  2. <Operational guideline 2>
  3. <Operational guideline 3>
  4. Integrate seamlessly with existing fleet operations
  5. Follow Lord Gig's Realm protocols and standards
'';
```

### Personality Profile Template

```markdown
# <Agent Name> Agent Additional Personality

## Specialized Mission

### Primary Purpose

<Detailed description of the officer's primary mission>

### Domain Expertise

<Areas of specialized knowledge and competency>

### Key Traits

- <Trait 1>
- <Trait 2>
- <Trait 3>
- <Trait 4>
- <Trait 5>

### Operational Guidelines

#### Problem-Solving Approach

1. **<Approach 1>**: <Description>
2. **<Approach 2>**: <Description>
3. **<Approach 3>**: <Description>
4. **<Approach 4>**: <Description>
5. **<Approach 5>**: <Description>

#### Communication Style

- <Communication guideline 1>
- <Communication guideline 2>
- <Communication guideline 3>
- <Communication guideline 4>
- <Communication guideline 5>

### Integration with Existing System

#### Repository Awareness

- Understand the NixOS/home-manager environment
- Respect established patterns in the dotfiles configuration
- Know when changes should be permanent vs. temporary
- Consider multi-host compatibility requirements

#### Collaboration

- Work effectively with other fleet officers
- Defer to more specialized officers when appropriate
- Provide clear handoffs when escalating or collaborating
- Share relevant insights that might help other officers
```

---

## Appendix B: Quick Reference Commands

### Branch Management

```bash
# Create recruit branch (simple)
git checkout -b recruit/<officer-name>

# Create recruit worktree (isolated)
git worktree add worktrees/recruit-<officer-name> -b recruit/<officer-name>

# Commit iteration
git add home/gig/common/core/opencode.nix home/gig/common/resources/<agent-name>-additional-personality.md
git commit -m "feat(agents): iteration N for <officer-name>"

# Switch to main
git checkout main

# Merge recruit
git merge --no-ff recruit/<officer-name>

# Clean up worktree
git worktree remove worktrees/recruit-<officer-name>
```

### Validation & Testing

```bash
# Validate configuration (no build)
nix flake check --no-build

# Test build (rebuilds system)
just home

# Full validation with build
just check
```

### Deployment

```bash
# Deploy on main branch (from main repo location)
cd ~/.dotfiles
just home

# Verify in operations logs
git log --oneline --graph --all
```

---

## Appendix C: Worktree Best Practices

### When to Use Worktrees

- **Complex development**: Multiple iterations expected
- **Parallel recruitment**: Working on multiple officers simultaneously
- **Testing needed**: Want to test builds without affecting main environment
- **Experimentation**: Not sure if design will work out

### When Simple Branches Are Fine

- **Quick additions**: Simple, well-defined officers
- **Minor iterations**: Only expect 1-2 refinement cycles
- **No build testing**: Will validate with `nix flake check` only

### Worktree Cleanup

```bash
# List all worktrees
git worktree list

# Remove a worktree (after merging)
git worktree remove worktrees/recruit-<officer-name>

# Remove and delete branch
git worktree remove worktrees/recruit-<officer-name>
git branch -d recruit/<officer-name>
```

---

## Appendix D: Deprecated Systems

### Old One-Shot Script (`scripts/agent-hire.nu`)

**Status**: Deprecated as of 2025-01-28

**Why Deprecated**:

- No iterative refinement support
- Automatic rebuilds without control
- Difficult to test configurations
- No branch isolation
- Hard to rollback changes

**Replacement**: This protocol with manual, iterative process

**Migration Path**: Use this protocol for all future officer recruitment

---

## Version History

- **v2.0** (2025-01-28): Complete rewrite for iterative development with
  worktree support
- **v1.0** (2024-12-XX): Initial one-shot automation script (deprecated)

---

**END RECRUITMENT PROTOCOL**

_For questions or protocol improvements, consult Chief Engineer Scotty or Lord
Gig_
