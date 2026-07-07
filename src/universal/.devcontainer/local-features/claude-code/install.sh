#!/usr/bin/env bash
set -e

echo "(*) Installing Claude Code..."

pnpm --allow-build=@anthropic-ai/claude-code add -g @anthropic-ai/claude-code

echo "Done!"
