#!/bin/sh
# Runs bin/dot against a fixture repo and a temporary HOME. Nothing outside the temp dir changes.
ROOT=$(cd "$(dirname "$0")/.." && pwd)
T=$(cd "$(mktemp -d)" && pwd -P); trap 'rm -rf "$T"' EXIT
R=$T/dot
export HOME=$T/home PATH=$T/stub:$PATH
mkdir -p "$HOME" "$T/stub" "$R/bin" "$R/modules/alpha" "$R/modules/beta" "$R/modules/broken"
cp "$ROOT/bin/dot" "$R/bin/dot"
printf '#!/bin/sh\necho "brew $*${HOMEBREW_NO_INSTALL_UPGRADE:+ (no upgrade)}"\n' > "$T/stub/brew" && chmod +x "$T/stub/brew"
printf '#!/bin/sh\necho "gh $*" >> "%s/gh.log"; echo https://pr.test/1\n' "$T" > "$T/stub/gh" && chmod +x "$T/stub/gh"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
echo repo > "$R/modules/alpha/a.txt" && echo b > "$R/modules/beta/b.txt"
cat > "$R/modules/alpha/module.sh" <<'EOF'
link a.txt ~/a.txt
formula jq
cask rectangle
check has-x 'test -d ~/x\t'
post_link boom 'exit 3'
post_link say 'echo said'
provision auth 'echo authed' 'test -f ~/.authed'
EOF
echo 'link b.txt ~/b.txt' > "$R/modules/beta/module.sh"
printf 'link b.txt ~/broken.txt\nif then\n' > "$R/modules/broken/module.sh"
W=$HOME/Code/dot-work/modules/gamma
mkdir -p "$W" && echo g > "$W/g.txt"
cat > "$W/module.sh" <<'EOF'
link g.txt ~/g.txt
post_link copy 'cp g.txt ~/g-copy.txt' 'test -f g.txt'
EOF
dot() { "$R/bin/dot" "$@"; }
pass=0 fail=0
ok() { if eval "$2"; then pass=$((pass + 1)); else fail=$((fail + 1)); echo "FAIL: $1"; fi; }

ok "every repo module parses" '(for f in "$ROOT"/modules/*/module.sh; do sh -n "$f" || exit 1; done)'
ok "no command is a usage error" '! dot 2>/dev/null && ! dot bogus 2>/dev/null'

echo mine > "$HOME/a.txt"
out=$(dot link alpha beta 2>&1); code=$?
ok "link backs up a real file" '[ "$(cat "$HOME"/.dotfiles-backup/alpha/a.txt.*)" = mine ]'
ok "link creates the symlink" '[ "$(readlink "$HOME/a.txt")" = "$R/modules/alpha/a.txt" ]'
ok "a failed step fails the run, but later steps and modules still run" '[ $code = 1 ] && echo "$out" | grep -q said && [ -L "$HOME/b.txt" ]'
ok "step labels print once" '[ "$(echo "$out" | grep -c "^  say$")" = 1 ] && [ "$(echo "$out" | grep -c "✗")" = 1 ]'
ok "link with nothing to do exits 0" 'dot link beta >/dev/null'
ok "link covers dot-work's modules" 'dot link gamma >/dev/null && [ "$(readlink "$HOME/g.txt")" = "$W/g.txt" ]'
ok "steps and checks run from their module's folder" '[ -f "$HOME/g-copy.txt" ] && dot status gamma | grep -q "all healthy"'
ok "an unknown module fails" '! dot link typo >/dev/null && dot link typo | grep -q "no such module"'
rm "$HOME/b.txt"
ok "a broken module.sh fails, and later modules still run" '! dot link broken beta >/dev/null 2>&1 && [ ! -e "$HOME/broken.txt" ] && [ -L "$HOME/b.txt" ]'
rm -r "$R/modules/broken"
ok "install runs brew and provision" 'dot install alpha | grep -q "brew install --cask rectangle" && dot install alpha | grep -q authed'
ok "status reports a failing check" '! dot status alpha >/dev/null && dot status alpha | grep -qF "has-x: test -d ~/x\\t"'

printf 'alpha/has-x\nalpha/auth  # comment\n' > "$HOME/.dot-skips"
ok "skips drop steps and their checks" 'dot status alpha | grep -q "all healthy"'
rm "$HOME/b.txt" && echo local > "$HOME/b.txt"
ok "status diffs a real file" '! dot status beta >/dev/null && dot status beta | grep -q "^+local"'
ok "status sends no color codes into a pipe" '! dot status beta | grep -q "$(printf "\033")"'
ok "status honors its module argument" 'dot status alpha | grep -q "all healthy"'

dot link beta >/dev/null && echo beta >> "$HOME/.dot-skips"
mkdir -p "$HOME/Pictures" "$HOME/.t3/worktrees/dot/feat/modules/alpha" && echo wt > "$HOME/.t3/worktrees/dot/feat/modules/alpha/a.txt"
ln -s "$R/modules/alpha/a.txt" "$HOME/Pictures/old copy.txt"
ln -s "$HOME/gone/dot/modules/x" "$HOME/Pictures/dangling"
ln -s "$HOME/.t3/worktrees/dot/feat/modules/alpha/a.txt" "$HOME/Pictures/t3.txt"
ln -s "$HOME/gone/dot/node_modules/x" "$HOME/Pictures/npm"
ln -s "$W/g.txt" "$HOME/Pictures/work copy.txt"
o=$(dot status --orphans); code=$?
ok "orphans finds undeclared and dangling links" '[ $code = 1 ] && echo "$o" | grep -q "old copy.txt ->" && echo "$o" | grep -q dangling'
ok "orphans finds links into T3 Code worktrees" 'echo "$o" | grep -q t3.txt'
ok "orphans finds links into dot-work" 'echo "$o" | grep -q "work copy.txt ->"'
ok "orphans ignores a skipped module's links" '! echo "$o" | grep -q b.txt'
ok "orphans ignores links into a node_modules folder" '! echo "$o" | grep -q npm'
mkdir "$R/modules/broken" && echo 'if then' > "$R/modules/broken/module.sh"
ok "orphans fails on a broken module.sh" '! dot status --orphans >/dev/null 2>&1 && dot status --orphans 2>/dev/null | grep -q "does not parse"'
rm -r "$R/modules/broken"

mkdir "$R/modules/notes" && rm "$HOME/a.txt" "$HOME/g.txt"
o=$(dot status)
ok "status with no module checks every module, dot-work's too, and ignores a folder with no module.sh" 'echo "$o" | grep -q "a.txt is missing" && echo "$o" | grep -q "g.txt is missing" && ! echo "$o" | grep -q notes'
# Each checkout gets a bare origin, and $T/up and $T/up-work stand in for PRs merged on GitHub.
W=${W%/modules/gamma}
for r in "$R" "$W"; do
  git -C "$r" init -q -b main && git -C "$r" add -A && git -C "$r" commit -qm init && git clone -q --bare "$r" "$r.git" &&
    git -C "$r" remote add origin "$r.git" && git -C "$r" fetch -q
done
git clone -q "$R.git" "$T/up" && git clone -q "$W.git" "$T/up-work"
mkdir "$T/up/modules/delta" && echo d > "$T/up/modules/delta/d.txt" && printf 'link d.txt ~/d.txt\nformula tree\n' > "$T/up/modules/delta/module.sh"
git -C "$T/up" add -A && git -C "$T/up" commit -qm delta && git -C "$T/up" push -q origin main
mkdir "$T/up/modules/epsilon" && echo 'link e.txt ~/e.txt' > "$T/up/modules/epsilon/module.sh"
git -C "$T/up" add -A && git -C "$T/up" commit -qm epsilon && git -C "$T/up" push -q origin HEAD:jon/open-pr && git -C "$T/up" reset -q --hard HEAD~
echo h > "$T/up-work/modules/gamma/h.txt" && echo 'link h.txt ~/h.txt' >> "$T/up-work/modules/gamma/module.sh"
git -C "$T/up-work" add -A && git -C "$T/up-work" commit -qm h && git -C "$T/up-work" push -q origin main
echo local >> "$R/modules/alpha/a.txt"
o=$(dot pull 2>&1); code=$?
ok "pull fast-forwards main in dot and dot-work, and applies only the modules that changed" '[ $code = 0 ] && [ -L "$HOME/d.txt" ] && [ -L "$HOME/h.txt" ] && ! echo "$o" | grep -q said'
ok "pull installs new packages without upgrading" 'echo "$o" | grep -q "brew install tree (no upgrade)"'
ok "pull leaves open PRs and uncommitted changes alone" '[ ! -e "$R/modules/epsilon" ] && grep -q local "$R/modules/alpha/a.txt"'
git -C "$R" switch -q -c side
ok "pull fails for a checkout that isn't on main" '! dot pull >/dev/null && dot pull | grep -q "not on main"'
git -C "$R" switch -q main
echo up > "$T/up/modules/delta/d.txt" && git -C "$T/up" commit -qam up && git -C "$T/up" push -q origin main
echo mine > "$R/modules/delta/d.txt"
o=$(dot pull 2>&1); code=$?
ok "pull moves conflicting uncommitted changes to the stash and leaves main checked out" '[ $code = 1 ] && echo "$o" | grep -q "in the stash" && [ "$(cat "$R/modules/delta/d.txt")" = up ] && git -C "$R" stash list | grep -q autostash && [ -z "$(git -C "$R" ls-files -u)" ]'

head=$(git -C "$R" rev-parse HEAD) && echo local >> "$R/modules/alpha/a.txt" && echo new > "$R/modules/beta/new.txt"
o=$(dot push "alpha: keep the local edit"); code=$?
ok "push opens a PR from a new branch with every uncommitted change" '[ $code = 0 ] && grep -q "gh pr create --head jon/alpha-keep-the-local-edit --base main --title alpha: keep the local edit" "$T/gh.log" && git -C "$R.git" show jon/alpha-keep-the-local-edit:modules/alpha/a.txt | grep -q local && git -C "$R.git" show jon/alpha-keep-the-local-edit:modules/beta/new.txt >/dev/null'
ok "push leaves the checkout on main with its changes uncommitted" '[ "$(git -C "$R" rev-parse HEAD)" = "$head" ] && [ "$(git -C "$R" branch --show-current)" = main ] && git -C "$R" status --porcelain | grep -q "a.txt" && [ -z "$(git -C "$R" diff --cached)" ]'
ok "push skips a checkout with no changes" '[ "$(grep -c "pr create" "$T/gh.log")" = 1 ]'
echo "$pass passed, $fail failed"; [ $fail = 0 ]
