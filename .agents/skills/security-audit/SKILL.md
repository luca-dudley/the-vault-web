---
name: security-audit
description: Audits code and schemas for tenant data isolation, RLS coverage, and OWASP client risks.
---
# Security Audit Protocols

## 1. Multi-Tenant Isolation (Supabase / PostgreSQL)
- **RLS Verification**: Every table containing client data MUST have Row Level Security enabled (`ENABLE ROW LEVEL SECURITY`).
- **Tenant Scope**: Ensure policies check `organization_id = auth.jwt() ->> 'organization_id'`. Verify there are no permissive `USING (true)` rules on sensitive tenant tables.
- **RPC Exposure**: Check all PostgreSQL functions (`SECURITY DEFINER`). Ensure they explicitly validate `auth.uid()` and cannot be invoked from the browser console to bypass tenant boundaries.

## 2. Client-Side Secrets & Console Exposure
- **Key Check**: Only the Supabase `anon` public key and Paystack public key may exist in client JS (`/js/`).
- **Never In Frontend**: `service_role` keys, Resend API keys, and Paystack secret keys must remain strictly in `/supabase/functions/` backend environments.
- **DOM / Console Inspection**: Ensure sensitive user metadata or unmasked billing tokens are not attached to `window` globals or local storage where browser extensions can scrape them.

## 3. Webhook & Integration Integrity
- **Paystack Webhook**: Verify that `supabase/functions/paystack-webhook` checks the `x-paystack-signature` header against HMAC SHA512 using the secret key before updating subscription status.