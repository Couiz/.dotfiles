#!/bin/sh
# test-dotfiles.sh — diagnostic checks for dotfiles setup
# Run on any machine after install.sh to verify the environment.
# Usage: ./test-dotfiles.sh

errors=0
warnings=0

pass() { printf "  PASS: %s\n" "$1"; }
fail() { printf "  FAIL: %s\n" "$1"; errors=$((errors + 1)); }
warn() { printf "  WARN: %s\n" "$1"; warnings=$((warnings + 1)); }
skip() { printf "  SKIP: %s\n" "$1"; }

# ============================================================
# Test 1: Nerd Font glyphs
# ============================================================
printf "Test 1: Nerd Font / Powerline glyphs\n"
printf "  The line below should show three distinct icons (arrow, folder, branch):\n"
printf "  \xee\x82\xb0  \xef\x81\xbb  \xee\x82\xa0\n"
printf "  If you see boxes, '?', or blank spaces, your terminal font\n"
printf "  is missing Nerd Font glyphs. Check your terminal profile's\n"
printf "  font setting (e.g. MesloLGS NF, Hack Nerd Font).\n\n"

# ============================================================
# Test 2: OSC 11 response leak inside tmux
# ============================================================
printf "Test 2: OSC 11 escape sequence leak\n"
if [ -z "$TMUX" ]; then
    skip "not inside tmux (run this inside a tmux session to test)"
else
    # save tty settings, switch to raw mode briefly
    saved_tty=$(stty -g 2>/dev/null)
    if [ -z "$saved_tty" ]; then
        skip "cannot read tty settings"
    else
        # send OSC 11 query and try to read the response
        stty raw -echo min 0 time 3 2>/dev/null
        printf '\033]11;?\033\\' > /dev/tty
        response=$(dd bs=64 count=1 < /dev/tty 2>/dev/null)
        stty "$saved_tty" 2>/dev/null

        if printf '%s' "$response" | grep -q "rgb:"; then
            # response was consumed (good — terminal answered properly)
            pass "OSC 11 response received and consumed by this script"
            printf "        (no leak: response was captured before it hit the shell)\n"
        else
            warn "no OSC 11 response captured"
            printf "        This may be fine, or the response may arrive late and leak.\n"
            printf "        Open a NEW tmux pane and check if garbage text like\n"
            printf "        '^[]11;rgb:...' appears on the first prompt line.\n"
        fi

        # now test for a SECOND response (the passthrough leak)
        stty raw -echo min 0 time 3 2>/dev/null
        leaked=$(dd bs=64 count=1 < /dev/tty 2>/dev/null)
        stty "$saved_tty" 2>/dev/null

        if printf '%s' "$leaked" | grep -q "rgb:"; then
            fail "OSC 11 response leaked a second time (passthrough duplicate)"
            printf "        tmux is both answering natively and forwarding via passthrough.\n"
            printf "        The duplicate response leaks as visible text on the prompt.\n"
        fi
    fi
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
