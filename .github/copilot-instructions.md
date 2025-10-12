# Simple Cloud Kit (SCK) - AI Development Guide

## Architecture Overview

SCK is an AWS-native cloud automation platform using a **monorepo with git submodules**. The system follows a **separation of duties** model with different "personas" (hats) for enterprise teams.

### Core Components (Lambda-first)
- **sck-core-framework**: Base utilities (`core_framework`, `core_logging`, `core_helper`) - foundation for all Python modules
- **sck-core-api**: Dual FastAPI/Lambda API with OAuth 2.0 server (dev: FastAPI, prod: API Gateway + Lambda)
- **sck-core-ui**: React/TypeScript UI with Redux store (Vite build, strict auth patterns)
- **sck-core-db**: DynamoDB helpers and data models
- **Core Lambda Services**: `invoker` → `runner` → `deployspec`/`component` (orchestrated execution chain)

### Key Architectural Decisions
1. **All Python runs in AWS Lambda** - synchronous handlers only, no `async def`/`await` in Lambda code
2. **S3 bucket prefixes**: `packages/` (input), `files/` (pre-compilation), `artefacts/` (post-compilation)
3. **Jinja2 CloudFormation templating** with deployment pipeline: package → compile → deploy
4. **Two-token auth**: session cookie for `/auth/**`, bearer token for `/api/**` (Redux memory only)

## Development Workflows

### Python Module Development (all submodules except UI)
```powershell
# In any sck-core-* folder:
..\build.ps1      # Poetry venv, dependencies, build
..\flakeit.ps1    # Black formatting + flake8 linting
..\pytest.ps1     # Run tests with coverage
```

### Monorepo Build (from root)
```powershell
.\build-all.ps1   # Builds all Python modules in dependency order
```

### UI Development
```bash
cd sck-core-ui
yarn dev          # Vite dev server on :8080
yarn build        # Production build
```

## Critical Patterns

### Python Module Structure (follow exactly)
```python
import core_framework as util
import core_logging as log
import core_helper.aws as aws
from core_helper.magic import MagicS3Bucket

# S3 operations - always use MagicS3Bucket for bucket ops
bucket = MagicS3Bucket(bucket_name=util.get_bucket_name(), region=util.get_bucket_region())
bucket.put_object(Key=key, Filename=filename)

# Lambda handlers use ProxyEvent for AWS Gateway integration
from core_api.proxy import ProxyEvent
def handler(event, context):
    input_data = ProxyEvent(**event)  # Auto-decodes base64, parses JSON
    data = input_data.body  # Always a dict
```

### API Response Envelopes (non-OAuth)
```python
# All /api/v1/** endpoints return:
{ "status": "success", "code": 200, "data": {...}, "metadata": {...}, "message": "..." }
# OAuth endpoints follow RFC 6749
```

### UI Auth Requirements (STRICT)
- **Access tokens**: Redux memory only, never persisted
- **Refresh tokens**: `sessionStorage` only, key `refresh_token`
- **All /api calls**: MUST include `Authorization: Bearer <token>` header
- **S3 presigned URLs**: Never include Authorization headers (S3 rejects them)

### Lambda Execution Chain
```
CLI/UI → core-invoker → core-runner → [core-deployspec, core-component]
```

## Package Dependencies
Each submodule is independent but follows shared patterns:
- **Python 3.12** (AWS Lambda max: python3.11 in production)
- **Poetry** for dependency management with `poetry-dynamic-versioning`
- **Core framework first**: All modules depend on `sck-core-framework`

## Contradiction Detection Protocol
Each submodule has `.github/copilot-instructions.md` with local precedence. If suggestions conflict:
1. **Check local submodule rules first**
2. **Fallback to this root guidance**  
3. **Cross-reference UI docs** (`sck-core-ui/docs/*.md`) for auth/API patterns

**Example conflicts to flag:**
- Storing tokens in localStorage (violates auth policy)
- Using `async def` in Lambda handlers (violates runtime model)
- Direct S3 client usage (should use MagicS3Bucket wrapper)
- Non-envelope API responses (violates API contract)

## Essential File Locations
- **Build scripts**: Root `build*.ps1`, each module sources `../build-module.ps1`
- **Backend patterns**: `sck-core-ui/docs/backend-code-style.md`
- **Auth contracts**: `sck-core-ui/docs/auth-session-and-storage.md`
- **UI conventions**: `sck-core-ui/docs/ui-style-guide.md`
- **CloudFormation templates**: `sck-core-api/platform/components/*.yaml.j2`

## Quick Start Commands
```powershell
# Full monorepo build
.\build-all.ps1

# Single module (in submodule directory)
..\build.ps1 && ..\flakeit.ps1 && ..\pytest.ps1

# UI development
cd sck-core-ui && yarn dev

# Docker local environment  
cd sck-core-docker && docker-compose up
```

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
