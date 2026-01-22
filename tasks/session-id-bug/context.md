# Context: session-id-bug

## Essential Files

| File | Est. Tokens | Reason |
|------|-------------|--------|
| .claude/hooks/session-start.sh | ~500 | Session ID logic |
| .claude/settings.json | ~300 | Hook registration |
| .claude/state/sessions/ | ~200 | Session state files |

## Do NOT Load

| File | Reason |
|------|--------|
| node_modules/* | Never |
| dist/* | Build output |
| tasks/**/handoffs/* | Old emergency handoffs |
