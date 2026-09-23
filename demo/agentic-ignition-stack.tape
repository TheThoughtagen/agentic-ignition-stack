Output artifacts/agentic-ignition-stack-demo.mp4
Output artifacts/agentic-ignition-stack-demo.gif

Require docker
Require jq
Require claude
Require npm

Set Shell "bash"
Set FontFamily "Menlo"
Set FontSize 16
Set Width 1440
Set Height 900
Set Padding 24
Set Margin 16
Set MarginFill "#111827"
Set BorderRadius 12
Set WindowBar "Colorful"
Set TypingSpeed 18ms
Set Framerate 30
Set PlaybackSpeed 1.1
Set Theme "Catppuccin Mocha"

Hide
Type "export PS1='$ '" Enter
Type "cd $(git rev-parse --show-toplevel)" Enter
Type "mkdir -p artifacts" Enter
Type "rm -rf /tmp/agentic-ignition-demo-claude" Enter
Type "export CLAUDE_CONFIG_DIR=/tmp/agentic-ignition-demo-claude" Enter
Show

Type "clear" Enter
Type "echo; echo '  AGENTIC IGNITION STACK'; echo '  Ignition 8.3.9 + Git + Claude + Playwright'; echo" Enter
Sleep 2s

Type "docker compose --env-file .env ps" Enter
Sleep 3s

Type "./scripts/demo-status.sh" Enter
Sleep 6s

Type "clear" Enter
Type "echo; echo '  BUNDLED CLAUDE PLUGIN'; echo" Enter
Type "find plugins/ignition -maxdepth 2 -type d | sort" Enter
Sleep 3s

Type "claude plugin marketplace add $PWD" Enter
Sleep 5s
Type "claude plugin install ignition@agentic-ignition-stack" Enter
Sleep 5s
Type "claude plugin details ignition@agentic-ignition-stack" Enter
Sleep 7s

Type "clear" Enter
Type "echo; echo '  END-TO-END GATEWAY VALIDATION'; echo" Enter
Type "./scripts/run-git-module-ui-test.sh" Enter
Sleep 10s

Type "echo; echo '  Gateway UI + /data/git/projects verified with Playwright.'; echo '  github.com/TheThoughtagen/agentic-ignition-stack'; echo" Enter
Sleep 5s
