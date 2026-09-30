#!/usr/bin/env bash
set -e

SCHEMA_FILE=".ai/SUPABASE_SCHEMA.md"
TMP_SCHEMA="/tmp/live_schema.sql"

echo "[INFO] Fetching latest live Supabase schema..."

# 1. If Supabase CLI is linked, dump schema directly
if npx supabase db dump --schema-only -f "$TMP_SCHEMA" >/dev/null 2>&1; then
    cat << 'HEADER' > "$SCHEMA_FILE"
# The Vault: Supabase Master Schema & Storage Policies
> Auto-generated via Supabase CLI. Do not manually edit.

HEADER
    cat "$TMP_SCHEMA" >> "$SCHEMA_FILE"
    rm -f "$TMP_SCHEMA"
    echo "[SUCCESS] .ai/SUPABASE_SCHEMA.md updated from live Supabase instance."
else
    echo "[WARN] Supabase CLI link not active or offline. Keeping existing schema file."
fi
