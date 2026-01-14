# SSM Explorer Subagent

Use this agent for codebase exploration without polluting main conversation context.

## Purpose

The explorer subagent runs in isolated context to:
- Search for files and patterns
- Understand code structure
- Find relevant implementations
- Answer "where is X?" and "how does Y work?" questions

Results are summarized back to the main conversation, keeping exploration noise separate.

## When to Use

Invoke this subagent when:
- Starting a new task and need to understand the codebase
- Looking for all occurrences of a pattern
- Investigating how a feature is implemented
- Need to read many files to answer a question

## How to Invoke

Use the Task tool with `subagent_type: "Explore"`:

```
Task tool parameters:
- subagent_type: "Explore"
- prompt: "Find all files that handle user authentication and summarize how auth works"
- description: "Explore auth implementation"
- model: "haiku" (optional - faster for simple exploration)
```

## Example Prompts

**Finding implementations:**
```
Find all files that implement the payment processing flow.
Summarize the key functions and their locations.
```

**Understanding patterns:**
```
How does error handling work in this codebase?
Find examples and document the pattern.
```

**Locating files:**
```
Find all configuration files and list what each one configures.
```

**Code archaeology:**
```
Trace the data flow from API endpoint /users to the database.
List each function involved and its file location.
```

## Best Practices

1. **Be specific** - Include what you're looking for and why
2. **Ask for summaries** - "Summarize the key findings" reduces noise
3. **Request file:line format** - Makes it easy to navigate to results
4. **Set thoroughness** - "quick" for simple searches, "very thorough" for comprehensive analysis

## Integration with SSM

After exploration:
1. Add relevant files to "Immediate Context" in active.md
2. Note key findings in task notes
3. Update TodoWrite with discovered work items

## Model Selection

| Exploration Type | Recommended Model |
|-----------------|-------------------|
| Simple file search | haiku (fast, cheap) |
| Pattern finding | haiku |
| Architecture understanding | sonnet |
| Complex code analysis | sonnet or opus |
