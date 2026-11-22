// wa-check (2026-11-22): read-only WhatsApp Cloud API health check (deployed as edge function "wa-check").
// Body: {token: <gold_cron_cfg.token>}. Returns secret presence, number status and token type — never the token itself. Sends nothing.
// Source of truth is the deployed function; see Supabase dashboard → Edge Functions → wa-check.
