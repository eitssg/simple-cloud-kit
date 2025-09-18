# Copilot Instructions (Root)

This parent repo contains 17 submodules (separate projects/builds). Each may have its own Copilot rules. Use these precedence and mapping rules:

Instruction precedence:
1) Prefer the submodule-local `.github/copilot-instructions.md` if present.
2) Include submodule `docs/**` conventions (style guides, API contracts).
3) If absent, fall back to these root instructions and closest related submodule docs.
4) On conflicts, prefer local (submodule) rules and surface a contradiction warning.

Submodules by tech:
- Python: sck-core-api, sck-core-cli, sck-core-codecommit, sck-core-component, sck-core-db, sck-core-deployspec, sck-core-execute, sck-core-framework, sck-core-invoker, sck-core-organization, sck-core-report, sck-core-runner
- Docker: sck-core-docker, sck-core-docker-base, sck-core-docker-server
- Docs (Sphinx): sck-core-docs
- UI (Node/React): sck-core-ui

UI canonical rules:
- sck-core-ui/.github/copilot-instructions.md (auth/session, UI style, portfolio model, backend code style excerpts)
- Use components from sck-core-ui/src/components/ui/* and follow sck-core-ui/docs/ui-style-guide.md
- Auth/session: sck-core-ui/docs/auth-session-and-storage.md
- Portfolio model: sck-core-ui/docs/portfolio-model.md

When editing outside sck-core-ui but affecting UI or API envelopes used by UI, open the UI docs and align.

## Contradiction Detection (Template)
When an instruction appears to conflict with documented rules:
- Warn with the exact quote and the specific rule + source file.
- Offer options: adjust the prompt to align with the rule, or update the source document if the rule has changed.
- Provide a concrete example of the aligned approach.

Example response format:
1) Warning: "Your instruction '[quote]' conflicts with [rule] in [source file]."
2) Options: "Modify prompt to align with [rule], or update [source file]."
3) Example: "Prompt suggests attaching Authorization to S3 presigned PUT, but backend-code-style.md and UI auth docs prohibit it. Omit Authorization for presigned S3 calls."

## Multi-Tenant Model (OAuth client_id vs tenant client)
Authoritative clarifications for all suggestions involving auth, scoping, or resource filtering:

Terminology:
- client_id: OAuth SPA application identifier (one per deployed UI domain / installation). Exactly one active per browser session.
- client (tenant): A tenant slug within the namespace of a single client_id. Not globally unique; only unique per client_id.

Session & Context Rules:
- A session (and access token) is bound to exactly one client_id at a time.
- A user may be authorized for multiple tenant clients under that active client_id (an allow-list of slugs).
- Switching the active tenant (client slug) happens inside the same SPA and may refresh/rotate the access token, but does not change client_id.
- Switching to a different client_id implies a completely separate SPA deployment (different domain) and requires a new auth flow (new session and tokens).
- Never assume a tenant slug uniquely identifies a tenant without qualifying by client_id.

Token Claims (expected):
- cid: active client_id (SPA id).
- cnm (or similar): currently selected tenant client slug.
- Optional (future): cacl (array) not embedded in token; instead store allowed tenant list server-side keyed by session/jti. Suggestions must not bloat tokens with large allow-lists.

Guidance for Suggestions:
- Always qualify tenant data operations with both client_id (implicit via token) and active tenant slug.
- Do not propose cross-client_id caching or reuse of tokens between domains.
- When generating queries or filters, assume server enforces tenant allow-list; UI should request only for the active tenant context.
- Avoid treating tenant slug as a security boundary across different client_ids; isolation is at client_id + tenant combo.

Contradiction Handling:
- If a prompt implies global uniqueness of tenant slugs or switching client_id inside the same session, issue a contradiction warning referencing this section.

Example (Correct): "Fetch portfolios for active tenant by calling /api/v1/registry/clients/{tenant}/portfolios with Authorization derived from the current client_id-bound access token."
Example (Incorrect → warn): "User can switch from spa_1 to spa_3 without re-auth; reuse the same access token."
