---
name: creating-subagents
description: Use when creating custom agent definitions in .claude/agents/, when user asks to create subagents, or when needing to give agents access to specific skills
---

# Creating Subagents

Custom subagents are defined as markdown files in `.claude/agents/` with YAML frontmatter.

## Required Structure

Every subagent MUST have YAML frontmatter:

```yaml
---
name: my-agent-name
description: Brief description of what this agent does
skills: skill-one, skill-two
---

# Agent Name

[Agent instructions here]
```

## Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase, hyphens only (e.g., `code-reviewer`) |
| `description` | Yes | What the agent does and when to use it |
| `skills` | No | Comma-separated skill names to INJECT into agent context |

## Critical: How Skills Work with Subagents

**Skills are INJECTED, not invoked.** The full content of each listed skill is loaded into the subagent's context at startup.

```yaml
# CORRECT - skills injected at startup
---
name: code-reviewer
description: Review code for quality
skills: pr-review, security-check
---
```

```yaml
# WRONG - missing skills field means NO skills available
---
name: code-reviewer
description: Review code for quality
---
# This agent cannot use any custom skills!
```

## Built-in vs Custom Agents

**Built-in agents (Explore, Plan, general-purpose) CANNOT access custom skills.**

Only custom subagents in `.claude/agents/` with an explicit `skills` field can use skills.

| Agent Type | Can Use Custom Skills? |
|------------|----------------------|
| Custom (`.claude/agents/`) with `skills` field | Yes - injected at startup |
| Custom without `skills` field | No |
| Built-in (Explore, Plan, general-purpose) | No - never |

## Directory Locations

| Location | Path | Scope |
|----------|------|-------|
| Project | `.claude/agents/` | Anyone in this repo |
| Personal | `~/.claude/agents/` | You, across all projects |

## Complete Example

```yaml
---
name: test-runner
description: Run tests and report results with detailed analysis
skills: systematic-debugging, verification-before-completion
---

# Test Runner

You run tests and analyze failures systematically.

## Process

1. Run test suite
2. If failures, use systematic-debugging skill
3. Report results using verification-before-completion patterns

## Output Format

- Test command executed
- Pass/fail summary
- Detailed failure analysis (if any)
```

## Keep Skills Minimal

**Each skill consumes context window.** Full skill content is injected at startup, leaving less room for:
- Codebase content
- Conversation history
- Tool outputs

**Prefer focused agents** with 1-3 skills over "super-agents" with many skills.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Missing YAML frontmatter | Add `---` block with name, description |
| Expecting to "invoke" skills | Skills are injected, not invoked - list in `skills` field |
| Trying to add skills to built-in agents | Create custom agent instead |
| Forgetting `skills` field | Add explicit `skills: skill-one, skill-two` |
| Too many skills (context bloat) | Keep to 1-3 focused skills per agent |
