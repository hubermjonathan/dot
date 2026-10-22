link instructions.md ~/.claude/CLAUDE.md
link claude/settings.json ~/.claude/settings.json
link claude/scripts ~/.claude/scripts
link hooks ~/.agents/hooks
formula jq node qrencode
check plugin-marketplace 'test -d ~/.claude/plugins/marketplaces/hubermjonathan'
check technical-writing-skill 'ls ~/.claude/plugins/cache/hubermjonathan/communication/*/skills/technical-writing/SKILL.md >/dev/null 2>&1'
post_link install-claude 'command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash'
post_link create-agents-local-md 'mkdir -p ~/.agents && touch ~/.agents/AGENTS.local.md'
post_link add-blue-bubbles-mcp "claude mcp get blue-bubbles >/dev/null 2>&1 || claude mcp add --scope user --transport http blue-bubbles http://macbook:8723/mcp --header 'Authorization: Bearer \${BLUE_BUBBLES_TOKEN}'" 'claude mcp get blue-bubbles'
