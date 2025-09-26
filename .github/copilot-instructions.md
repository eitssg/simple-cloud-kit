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

## Technical Architecture & Development Patterns

### Core Development Workflows
```powershell
# Root monorepo - builds all 17 submodules in dependency order
.\build-all.ps1

# Individual Python submodule (from submodule directory)
..\build.ps1      # Poetry venv, install deps, build package
..\flakeit.ps1    # Black formatting + flake8 linting  
..\pytest.ps1     # Run tests with coverage
```

### Python Runtime Model (Critical - All Lambda)
- **All Python runs in AWS Lambda** - synchronous handlers only
- **NO async def/await** in Lambda code - use threads for concurrency if needed
- **ProxyEvent pattern**: Use `ProxyEvent(**event)` for API Gateway integration (auto-decodes base64, parses JSON)
- **Standard imports**: `import core_framework as util`, `import core_logging as log`, `import core_helper.aws as aws`

### S3 Architecture Pattern
**Three bucket prefixes with lifecycle management:**
- `packages/`: Input files (Jinja2 templates, deployment packages)
- `files/`: Pre-compilation resources and post-compilation files  
- `artefacts/`: Post-compilation CloudFormation templates

**S3 Code Pattern:**
```python
from core_helper.magic import MagicS3Bucket
bucket = MagicS3Bucket(bucket_name=util.get_bucket_name(), region=util.get_bucket_region())
bucket.put_object(Key=key, Filename=filename, Body=stream)
# For presigned URLs, use boto3 client directly (MagicS3Bucket doesn't implement generate_presigned_url)
```

### Lambda Execution Chain
**Core automation workflow:**
```
CLI/UI → core-invoker → core-runner → [core-deployspec, core-component]
```
- **invoker**: Orchestrates execution requests
- **runner**: Executes Step Functions workflows  
- **deployspec**: Manages deployment specifications
- **component**: Handles component artifacts and metadata

### API Response Standards
**Non-OAuth endpoints:**
```json
{ "status": "success", "code": 200, "data": {...}, "metadata": {...}, "message": "...", "errors": [...], "links": {...} }
```
**OAuth endpoints:** Follow RFC 6749

### Build Dependencies
- **Python 3.12** (development), **Python 3.11** (AWS Lambda runtime limit)
- **Poetry** for all Python packages with `poetry-dynamic-versioning`
- **Core framework dependency order**: `sck-core-framework` must build first (base for all others)

### Core Modules Overview
- **Modules**: 
   - Use `core_framework`, `core_logging`, `core_db`, `core_api`.
     - core_framework: tools for configuration values, environment variables, framework data models, constants, yaml/json helpers.
     - core_logging: structured logging, log levels, correlation IDs. PRN identity and object formatter outputs
     - core_helper.aws: AWS helpers (S3, Lambda, SNS, SQS, STS, IAM).
       - Avoid `boto3`/`botocore` directly; use `core_helper.aws`.
     - core_helper.magic: MagicS3Bucket.  Tools that allow AWS interface into local storage volumes or S3/Lambda based on core_framework.util.is_local_mode()
     - core_renderer: Jinja2 filters and template rendering helpers.
     - core_db: Database interface and models, DynamoDB/PynamoDB helpers. 
     - core_execute: Lambda step-function. Defines Actions, ActionResources, and ActionSpec and the Action script library for running code within lambda step functions.  
     - core_report: Pulls status from Action context and responds with a run status for hooks into CI/CD
     - core_runner: Lambda function for kicking off core_execute step functions.  In local mode, calls core_execute directly and wraps execute in local thread for step-function simulation.
     - core_deployspec: Lambda function generates, Compiles, Jinja2 transforms ActionsReources into a list of ActoinResources/ActionSpecs for core_execute. In local mode, reads/writes from local filesystem paths via MagicS3Bucket.
     - core_component: Lambda function for managing components (packages, files, artefacts) in S3 and DynamoDB.  Compiles Core-Automation component resources into a CloudFormation template and provides ActionResources for core_execute. In local mode, stores/retrieves from local filesystem paths via MagicS3Bucket.
     - core_invoker: Lambda function for invoking other lambda functions with retries and error handling. In local mode, calls core_runner, core_deployspec, core_component directly.
     - core_organization: Lambda function for managing AWS Organizations, SCPs, and Accounts.
     - core_codecommit: Lambda function for listening to AWS CodeCommit events (to kick off Core Automation pipeline).
     - core_api: AWS API Gateway (remote operation) and FastAPI (local dev). Full API and execution of business logic.  In local mode, calls core_invoker directly and implements FastAPI interface.

## Development Environment Setup

### Initial Setup (Developer Onboarding)
```bash
# 1. Create Python virtual environment (in root or any submodule)
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
# OR
.\.venv\Scripts\Activate.ps1  # Windows PowerShell

# 2. Install Poetry and dynamic versioning
pip install poetry poetry-dynamic-versioning

# 3. Switch to develop mode (for local development)
python ./prebuild.py  # Sets develop=true in all pyproject.toml files

# 4. Build all submodules
./build-all.ps1  # Windows
# OR  
source ./build-all.sh  # Linux/Mac
```

### Development Workflow (Per Module)
```powershell
# Standard build/test/lint cycle (run in any sck-core-* directory)
..\build.ps1      # Poetry install, dynamic versioning, build dist
..\flakeit.ps1    # Black formatting + flake8 linting (E9,F63,F7,F82 only)
..\pytest.ps1     # Run tests with coverage, auto-creates .env
..\publish.ps1    # Publish to Nexus repository (requires NEXUS_* env vars)
```

### UI Development Specifics
```bash
cd sck-core-ui
yarn install      # Install dependencies
yarn dev          # Vite dev server (:8080)
yarn build        # Production build
yarn type-check   # TypeScript validation
```

### Testing Environment Auto-Setup
Each module's `pytest.ps1`/`pytest.sh` automatically creates `.env` with:
```env
LOCAL_MODE=True
CLIENT=test-client
DYNAMODB_HOST=http://localhost:8000
VOLUME=P:\core  # Windows: P:\core, Linux: $HOME/core
LOG_DIR=P:\core\logs
CONSOLE=interactive
LOG_LEVEL=DEBUG
```

## Common Contradiction Patterns to Flag
- **Auth violations**: Storing tokens in localStorage, missing Authorization headers for /api calls, adding Authorization to S3 presigned URLs
- **Lambda violations**: Using async def/await in Lambda handlers, long-running synchronous operations
- **S3 violations**: Direct boto3 client usage instead of MagicS3Bucket for bucket operations
- **API violations**: Non-envelope responses for /api endpoints, incorrect OAuth response format
- **Build violations**: Missing poetry-dynamic-versioning calls, incorrect dependency order (framework must be first)
