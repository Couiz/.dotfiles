#!/bin/sh
# test-dotfiles.sh — diagnostic checks for dotfiles setup
# Run on any machine after install.sh to verify the environment.
# Works both inside and outside tmux.
# Usage: ./test-dotfiles.sh

errors=0
warnings=0

pass() { printf "  PASS: %s\n" "$1"; }
fail() { printf "  FAIL: %s\n" "$1"; errors=$((errors + 1)); }
warn() { printf "  WARN: %s\n" "$1"; warnings=$((warnings + 1)); }
skip() { printf "  SKIP: %s\n" "$1"; }

# ============================================================
# Test 1: Nerd Font glyphs (visual)
# ============================================================
printf "Test 1: Nerd Font / Powerline glyphs\n"
printf "  The line below should show three distinct icons (arrow, folder, branch):\n"
# U+E0B0 (Powerline arrow), U+F07B (folder), U+E0A0 (git branch) — octal UTF-8
printf "  \356\202\260  \357\201\273  \356\202\240\n"
printf "  If you see boxes, '?', or blank spaces, your terminal font\n"
printf "  is missing Nerd Font glyphs. Check your terminal profile's\n"
printf "  font setting (e.g. MesloLGS NF, Hack Nerd Font).\n\n"

# ============================================================
# Test 2: OSC 11 response leak (tmux bug detection)
# ============================================================
printf "Test 2: OSC 11 escape sequence leak\n"

# query tmux config — works both inside and outside tmux if a server is running
tmux_running=false
if tmux list-sessions > /dev/null 2>&1; then
    tmux_running=true
fi

if [ "$tmux_running" = true ] || [ -n "$TMUX" ]; then
    passthrough=$(tmux show-options -gv allow-passthrough 2>/dev/null)
    escape_time=$(tmux show-options -sv escape-time 2>/dev/null)
    tmux_version=$(tmux -V 2>/dev/null)

    printf "  tmux config: allow-passthrough=%s  escape-time=%s\n" \
        "${passthrough:-unknown}" "${escape_time:-unknown}"
    printf "  version: %s\n" "${tmux_version:-unknown}"

    if [ "$passthrough" = "on" ] || [ "$passthrough" = "all" ]; then
        # check mitigations: escape-time >= 30 and zle-line-init drain
        dotfiles_dir="$(cd "$(dirname "$0")" && pwd)"
        has_drain=false
        has_escape_time_fix=false
        if grep -q "__drain_leaked_responses" "$dotfiles_dir/.zshrc.server" 2>/dev/null; then
            has_drain=true
        fi
        if [ "${escape_time:-0}" -ge 30 ] 2>/dev/null; then
            has_escape_time_fix=true
        fi

        if [ "$has_escape_time_fix" = true ] && [ "$has_drain" = true ]; then
            pass "OSC 11 leak mitigated (escape-time=${escape_time}, zle drain active)"
        elif [ "$has_escape_time_fix" = true ]; then
            pass "OSC 11 leak mitigated (escape-time=${escape_time})"
        elif [ "$has_drain" = true ]; then
            warn "OSC 11 leak partially mitigated (zle drain active, but escape-time=${escape_time})"
            printf "        Set 'escape-time 30' in .tmux.conf for full mitigation.\n"
        else
            fail "OSC 11 response leak: allow-passthrough='${passthrough}' escape-time=${escape_time}"
            printf "        Known tmux bug (tmux/tmux#4634): tmux leaks DA/OSC\n"
            printf "        responses on client attach as visible text.\n"
            printf "        Fix: set 'escape-time 30' in .tmux.conf\n"
        fi
        printf "        Upstream: https://github.com/tmux/tmux/issues/4634\n"
    else
        pass "allow-passthrough is '${passthrough:-off}' (no leak risk)"
    fi
else
    skip "no tmux server running (start tmux and re-run to test)"
fi
printf "\n"

# ============================================================
# Test 3: OSC 52 clipboard (basic write test)
# ============================================================
printf "Test 3: OSC 52 clipboard\n"
if [ -z "$TMUX" ]; then
    skip "not inside tmux"
else
    # write a test string to clipboard via OSC 52
    printf '\033]52;c;%s\033\\' "$(printf 'dotfiles-test-ok' | base64)" > /dev/tty 2>/dev/null
    pass "OSC 52 write sent (paste in your terminal to verify content: 'dotfiles-test-ok')"
fi
printf "\n"

# ============================================================
# Test 4: Core tools availability
# ============================================================
printf "Test 4: Tool availability\n"
for tool in zsh tmux nvim git starship; do
    if command -v "$tool" > /dev/null 2>&1; then
        version=$("$tool" --version 2>/dev/null | head -1)
        pass "$tool ($version)"
    else
        case "$tool" in
            starship) warn "$tool not found (optional)" ;;
            *)        fail "$tool not found" ;;
        esac
    fi
done
printf "\n"

# ============================================================
# Test 5: Symlinks point to dotfiles repo
# ============================================================
printf "Test 5: Symlinks\n"
dotfiles_dir="$(cd "$(dirname "$0")" && pwd)"
check_link() {
    target="$1"
    expected="$2"
    if [ -L "$target" ]; then
        actual=$(readlink -f "$target" 2>/dev/null || readlink "$target")
        expected_resolved=$(readlink -f "$expected" 2>/dev/null || echo "$expected")
        if [ "$actual" = "$expected_resolved" ]; then
            pass "$target -> $expected"
        else
            fail "$target -> $actual (expected $expected)"
        fi
    elif [ -e "$target" ]; then
        warn "$target exists but is not a symlink"
    else
        warn "$target does not exist"
    fi
}
check_link "$HOME/.tmux.conf" "$dotfiles_dir/.tmux.conf"
check_link "$HOME/.config/nvim/init.lua" "$dotfiles_dir/.config/nvim/init.lua"
# zshrc could be .zshrc or .zshrc.server depending on install mode
if [ -L "$HOME/.zshrc" ]; then
    actual=$(readlink -f "$HOME/.zshrc" 2>/dev/null || readlink "$HOME/.zshrc")
    if printf '%s' "$actual" | grep -q "dotfiles"; then
        pass "$HOME/.zshrc -> $actual"
    else
        warn "$HOME/.zshrc -> $actual (not pointing to dotfiles)"
    fi
else
    warn "$HOME/.zshrc is not a symlink"
fi
printf "\n"

# ============================================================
# Summary
# ============================================================
printf "========================================\n"
if [ "$errors" -eq 0 ] && [ "$warnings" -eq 0 ]; then
    printf "All checks passed.\n"
elif [ "$errors" -eq 0 ]; then
    printf "%d warning(s), 0 failures.\n" "$warnings"
else
    printf "%d failure(s), %d warning(s).\n" "$errors" "$warnings"
fi
exit "$errors"
