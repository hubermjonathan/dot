- only ever use lowercase for git naming, session conversation, doc writing, pr writing, etc
- unless otherwise asked, only ever use very very concise language that a swe intern could comprehend
- worktree names should follow the format `<1-5-word-kebab-task-desc>`
- branch names should follow the format `jon/<1-5-word-kebab-task-desc>` or `jon/<wt-name>` if on a worktree
- commits should use scoped commits in the format `<scope>: <description>`, keeping the total commit message to at most 50 chars, never use body or trailers
- never add yourself as a commit co-author
- never mark a pr description as created by claude
- pr titles should use scoped commits similar to commits, append the associated task ticket in (), omit if none available, do not count the ticket towards char count
- when commenting on prs, end your comment with "\- claude" on a new line
- when creating task tickets always link blocked/blocking tasks
- always use the .scratch dir at repo/project/folder root for writing md files, artifacts, etc

read and follow machine specific preferences here: @~/.claude/CLAUDE.local.md

