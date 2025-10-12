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

## Conversation Start Checklist (Mandatory for Agent Mode)

At the beginning of every conversation or when entering "agent mode":
- [ ] Reference this file and confirm Plan → Approval → Execute workflow.
- [ ] Acknowledge precedence: Local submodule rules first, then root.
- [ ] Flag any contradictions with core prompt behavior.
- [ ] Require explicit user approval for non-trivial actions.

Failure to complete this checklist may result in workflow violations.

## � Plan → Approval → Execute Workflow (Mandatory)

Effective immediately (per maintainer request), all non-trivial actions MUST follow this explicit workflow:

1. Plan: Provide a concise, enumerated plan of intended actions (file reads, searches, edits, test runs, builds). Each step should map to a clear outcome.
2. Await Approval: Do NOT execute tools, create, edit, or delete files until the user explicitly approves (e.g., "approved", "go", "proceed step 1", or selective step approvals). If the user approves only a subset, proceed only with those steps and re-present an updated plan for the remainder.
3. Execute: After approval, carry out actions, batching related read-only steps where possible, then report deltas (what changed vs. the plan) before continuing.

### Scope & Definitions
- Trivial Q&A (purely explanatory answers, no code changes or repo-impacting suggestions) may skip the approval phase.
- "Non-trivial" includes: modifying any repository file, generating patches, creating/deleting files or directories, running build/test/lint commands, or performing multi-step investigative searches whose output might bias subsequent changes.
- If ambiguity exists (e.g., user asks a question that might imply edits), default to presenting a plan first.
- Always summarize what you intend to do before doing it; do not assume implicit approval.
- If a user asks a question, any question, or the prompt includes a question mark (?), do not perform any action other than answering the question.
- Assume a question mark (?) indicates an instruction to "do not modify code" and simply answer the question or address the query.

### Exceptions
- Explicit user override: If the user states "skip plan" / "no plan" / "do it now", you may proceed directly, but still summarize what you did afterward.
- Emergency fix: When immediately reverting a clearly broken earlier automated change in the same session (e.g., introduced syntax error blocking further assistance). Provide a one-line emergency plan, perform the minimal revert, then re-enter normal workflow.

### Partial Approvals & Iteration
- If the user approves only certain steps, execute those and then re-present a trimmed plan for the remaining pending steps.
- If execution reveals new necessary steps (dependency, failing test, contradiction), pause and present an updated micro-plan for those additions before continuing.

### Artifact Reporting
After executing approved steps:
- List: Files created/edited/deleted (paths + 1-line purpose).
- Validation: Summaries of build/lint/test (PASS/FAIL + brief failure cause if any) when those steps were part of the plan.
- Requirements Coverage: Map approved steps → completion status.
- Self-Audit: Confirm workflow adherence (e.g., "Plan presented: Yes; Approval obtained: Yes; No proactive defaults to core prompt").

### Conflict With Previous Guidance
This workflow supersedes earlier proactive-execution language in local or submodule instructions. Other documents encouraging immediate action are now subordinate to this root policy unless explicitly overridden again by the maintainer.

---

## Agent Mode Operations (Mandatory Enforcement)

When operating in "agent mode" or autonomous assistance:
- Strictly adhere to Plan → Approval → Execute; no exceptions for efficiency.
- Reference the Conversation Start Checklist at mode entry.
- If core prompt urges proactive action, override with these instructions and flag the contradiction.
- Halt all tool usage until user approval; summarize potential actions but do not execute.
- Post-execution, include a workflow compliance summary in responses.

This ensures agent mode does not bypass safety protocols.

---
## Submodule Precedence & Mapping

This parent repo contains 17 submodules (separate projects/builds). Each may have its own Copilot rules. Use these precedence and mapping rules:

Instruction precedence:
1) Prefer the submodule-local `.github/copilot-instructions.md` if present, else use root `.github/copilot-instructions.md`.
2) Include submodule `docs/build/**` .html or .md files as references.
4) On conflicts, ask for clarificcation from the user.

Submodules by tech:
- Python: sck-core-api, sck-core-cli, sck-core-codecommit, sck-core-component, sck-core-db, sck-core-deployspec, sck-core-execute, sck-core-framework, sck-core-invoker, sck-core-organization, sck-core-report, sck-core-runner
- Docker: sck-core-docker, sck-core-docker-base, sck-core-docker-server
- Docs (Sphinx): sck-core-docs
- UI (Node/React): sck-core-ui

### Runtime Deployment Matrix
Most core Python modules are still deployed as AWS Lambda functions. Two exceptions are explicitly containerized services:

| Package               | Module            | Runtime | Notes                               |
|-----------------------|-------------------|---------|-------------------------------------|
| sck-core-framework    | core_framework    | Library | Library only (imported by Lambdas)  |
| sck-core-framework    | core_logging      | Library | Structured logging                  |
| sck-core-framework    | core_helper       | Library | AWS helpers (S3, Lambda, SNS, etc.) |
| sck-core-framework    | core_renderer     | Library | Jinja2 rendering helpers            |
| sck-core-db           | core_db           | Library | DB helpers (DynamoDB)                  |
| sck-core-execute      | core_execute      | Lambda  | Action execution engine             |
| sck-core-report       | core_report       | Lambda  | Status reporting                    |
| sck-core-runner       | core_runner       | Lambda  | Orchestration launcher              |
| sck-core-deployspec   | core_deployspec   | Lambda  | Spec generation/compilation              |
| sck-core-component    | core_component    | Lambda  | Artefact & template management      |
| sck-core-invoker      | core_invoker      | Lambda  | Cross-Lambda orchestration          |
| sck-core-organization | core_organization | Lambda  | Org / accounts management           |
| sck-core-api          | core_api          | Lambda  | API Gateway + FastAPI dev adapter   |
| sck-core-codecommit   | core_codecommit   | Lambda  | Event listener trigger.  Calls API  |
| sck-core-cli          | core_cli          | Program | Long-lived automation / interactive CLI service image |
| sck-core-ai           | core_ai           | Program | AI / MCP / Langflow service (non-Lambda) |

Rules in later sections that state "All Python runs in AWS Lambda" apply to Lambda-designated modules above and NOT to `sck-core-ai` or `sck-core-cli`. Those two may use asynchronous patterns and maintain process-local state appropriate for long-lived containers. When adding new modules, declare their runtime here first.

UI canonical rules:
- sck-core-ui/.github/copilot-instructions.md (auth/session, UI style, portfolio model, backend code style excerpts)
- Use components from sck-core-ui/src/components/ui/* and follow sck-core-ui/docs/ui-style-guide.md
- Auth/session: sck-core-ui/docs/auth-session-and-storage.md
- Portfolio model: sck-core-ui/docs/portfolio-model.md

When editing outside sck-core-ui but affecting UI or API envelopes used by UI, open the UI docs and align.

## Contradiction Detection (Template)
When an instruction appears to conflict with documented rules, or when workflow violations occur (e.g., bypassing Plan → Approval → Execute):
- Warn with the exact quote and the specific rule + source file.
- Offer options: adjust the prompt to align with the rule, or update the source document if the rule has changed.
- Provide a concrete example of the aligned approach.

Example response format:
1) Warning format: "Your instruction '<quoted instruction>' conflicts with <rule summary> in <source file>."
2) Options format: "Modify prompt to align with <rule summary>, or update <source file>."
3) Example: "Prompt suggests attaching Authorization to S3 presigned PUT, but backend-code-style.md and UI auth docs prohibit it. Omit Authorization for presigned S3 calls."
4) Workflow violation example: "Proceeding with file edits without approval conflicts with Plan → Approval → Execute in copilot-instructions.md. Present plan first."

### Challenge Inefficient or Non-Best-Practice Approaches
When a user requests implementation in a way that is inefficient, overly complex, or violates established best practices:
- Challenge the approach politely but directly, explaining why it's problematic.
- Suggest the more efficient/best-practice alternative with clear reasoning.
- Provide concrete examples comparing the approaches.
- If the user insists on the inefficient approach, implement it but note the concern.

Example response format:
1) Challenge: "Parsing package info from filenames is more complex and error-prone than reading from pyproject.toml."
2) Alternative: "Use TOML parsing instead - it's simpler, more reliable, and uses the single source of truth."
3) Comparison: "TOML: 2 simple regex patterns vs Filename: Complex regex handling multiple formats and edge cases."
4) Implementation note: If proceeding with inefficient approach, add comment: "# Note: This approach is less efficient than TOML parsing but implemented as requested."

## Multi-Tenant Model (OAuth client_id vs tenant client)
Authoritative clarifications for all suggestions involving auth, scoping, or resource filtering:

Terminology:
- client_id: OAuth SPA application identifier (one per deployed UI domain / installation). Exactly one active per browser session.
- client (tenant): A tenant slug within the namespace of a single client_id. Not globally unique; only unique per client_id (e.g. `client_id_1` and `client_id_2` can access the same `client` tenant).

the "clients` database model is 'global' and includes all fields needed to identify and authorize a tenant under a specific client_id.

Example client records (conceptual):
| client_id (hash key)  | client (range key)        | name           | ... |
|------------|-------------|----------------|-----|
| spa_1      | client_a    | Client A       | ... |
| spa_1      | client_b    | Client B       | ... |  
| spa_2      | client_a    | Client A       | ... |
| spa_2      | client_c    | Client C       | ... !

'client_a' is the SAME tenant under both 'spa_1' and 'spa_2'.

Example client records (actual):
| client (hash key) | client_id (field) | name          | ... |
|-------------------|-------------------|---------------|-----|
| client_a          | spa_1             | Client A      | ... |
| client_b          | spa_1             | Client B      | ... |
| client_c          | spa_2             | Client C      | ... |

In the current model, 'client' is the hash key so spa's will not be able to share the same client slug. This is a known limitation and will be addressed in future versions.

Session & Context Rules:
- A session (and access token) is bound to exactly one client_id and one client (tenant) at a time.
- A user may be authorized for multiple tenant clients under that active client_id (an allow-list of slugs).
- Switching the active tenant (client slug) happens inside the same SPA and may refresh/rotate the session token and access token, but does not change client_id.
- Switching to a different client_id implies a completely separate SPA deployment (different domain) and requires a new auth flow (new session and tokens).

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

### Import and YAML Parsing Policy (Global)
- Do not wrap imports in try/except or use conditional imports. Imports must be unconditional and fail fast; if a dependency is needed, add it to the project.

### YAML Parsing (Mandatory)
- For YAML parsing, use core_framework yaml helpsers, for example:
  - `import core_framework as util`
  - `yaml_data = util.from_yaml(yaml_string)`
  - `yaml_data = util.load_yaml_file(file_path)`
  - `with open(file_path, 'r') as f: yaml_data = util.read_yaml(f)`
  - `yaml_string = util.to_yaml(data_dict)`
  - `util.write_yaml_file(file_path, data_dict)`
  - `with open(file_path, 'w') as f: util.write_yaml(data_dict, f)`

- When reading YAML files, !include is supported and will recursively inline the included file content. Use relative paths from the including file.
- Dates in YAML are ALWAYS converted to datetime objects from ISO 8601 strings. And when writing YAML, datetime objects are converted back to ISO 8601 strings.
- All AWS tags !Ref, !Sub, !GetAtt, etc. are read, however, when written, the Fn::Func form is used (e.g. Fn::Sub instead of !Sub).

### JSON Parsing (Mandatory)
- For JSON parsing, use core_framework json helpers, for example:
  - `import core_framework as util`
  - `json_data = util.from_json(json_string)`
  - `json_data = util.load_json_file(file_path)`
  - `with open(file_path, 'r') as f: json_data = util.read_json(f)`
  - `json_string = util.to_json(data_dict)`
  - `util.write_json_file(file_path, data_dict)`
  - `with open(file_path, 'w') as f: util.write_json(data_dict, f)`

- Dates in JSON are ALWAYS converted to datetime objects from ISO 8601 strings. And when writing JSON, datetime objects are converted back to ISO 8601 strings.

### Build & Test Commands (Mandatory)

```powershell
# Root monorepo - builds all 17 submodules in dependency order
.\build-all.ps1

# Individual Python submodule (from submodule directory)
..\build.ps1      # uv venv, install deps, build package
..\flakeit.ps1    # Black formatting + flake8 linting  
..\pytest.ps1     # Run tests with coverage
```

### UV Command Formulation (Mandatory)
- Always prefer uv for Python tooling and package management in commands:
  - pip → `uv pip <args>`
  - python → `uv python <args>`
  - python -m <module> → `uv run -m <module> <args>`
  - CLI tools (pytest/black/flake8/mypy/etc.) → `uv run <tool> <args>`
- Applies equally on Windows PowerShell and POSIX shells.
- Combine with terminal safety rules: use the existing terminal and do not attempt to activate environments—uv will resolve the project environment.

### Python Runtime Model (Lambda Modules)
- **Lambda-only scope**: Applies to modules labeled "Lambda" in the runtime matrix (excludes `sck-core-ai`, `sck-core-cli`).
- **Synchronous handlers**: Keep Lambda entrypoints synchronous; wrap concurrency with threads if needed.
- **No async def in handlers**: Avoid `async def` Lambda entrypoints (event loop cold start overhead & legacy design).
- **ProxyEvent pattern**: Use `ProxyEvent.model_validate(event)` for API Gateway integration (auto-decodes base64, parses JSON).
- **Standard imports**: `import core_framework as util`, `import core_logging as log`, `import core_helper.aws as aws`.

### Python Runtime Model (Containerized Modules: sck-core-ai, sck-core-cli)
- **Long-lived processes**: May use async (FastAPI, MCP) or sync depending on performance characteristics.
- **State**: Keep only ephemeral in-memory caches (idempotency, embeddings handles); no persistent state outside approved stores (S3, DynamoDB, vector DB).
- **Shutdown semantics**: Implement graceful shutdown hooks if adding background workers.
- **Logging**: Same `core_logging` API; ensure container log lines remain structured for aggregation.

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
- **invoker**: Orchestrates execution requests calls deployspec, and or component as needed and then runner to start the step function
- **runner**: Executes Step Functions workflows  
- **execute**: Runs ActionResources workflows (in parallel or sequence) (e..g. deploy cloudformation stacks, run scripts)
- **deployspec**: Converts a deployment spec YAML into ActionResources
- **component**: Generates CloudFormation templates and manages artefacts is S3/Filesystem

### API Response Standards

**Non-OAuth endpoints:**

```json
  { 
    "status": "success", 
    "code": 200, 
    "data": {...}, 
    "metadata": {...},
    "message": "...", 
    "errors": [...], 
    "links": {...} 
  }
```

**OAuth endpoints:** Follow RFC 6749

### Build Dependencies
- **Python 3.12** (latest AWS lambda runtime), 
- **uv** All packages are uv with hatchling build engine 
- **Core framework dependency order**: `sck-core-framework` must build first (base for all others)

### Core Modules Overview
- **Modules**: 
  - Use `core_framework`, `core_logging`, `core_db`, `core_api`.
  - core_framework: tools for configuration values, environment variables, framework data models, constants, yaml/json helpers.
  - core_logging: structured logging, log levels, correlation IDs. PRN identity and object formatter outputs
  - core_helper.aws: AWS helpers (S3, Lambda, SNS, SQS, STS, IAM).
    - Avoid `boto3`/`botocore` directly; use `core_helper.aws`.
  - core_helper.magic: MagicS3Bucket.  Tools that allow AWS interface into local storage volumes or S3. when core_framework.util.is_use_S3() is 'false' the filesystem will be used.  When is_use_S3() is 'true' S3 will be used. (S3 mode can be `true` even when core_framework.util.is_local_mode() is `true`).
     When is_local_mode() is `true` the CLI calls the lambda handlers directly rather than AWS lambda_client.invoke().
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

```powershell
.\build-all.ps1  -New -Dev
```

OR

```bash
./build-all.sh  --new --dev
```

### Development Workflow (Per Module)
```powershell
# Standard build/test/lint cycle (run in any sck-core-* directory)
..\build.ps1      # uv install, dynamic versioning, build dist
..\flakeit.ps1    # Black formatting + flake8 linting 
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

## ✅ Validated Model & Type Hint Guarantees (Added for AI Service & API Consistency)

The codebase deliberately relies on Pydantic model validation and upstream request normalization so that endpoint implementations do NOT need to re-check types already enforced. Future suggestions must honor these guarantees and avoid adding redundant defensive patterns:

### Runtime Guarantees at API Endpoint Boundary
1. `body` parameter passed into service endpoint handlers is either a `dict` (already parsed JSON) or `str` (The body was NOT JSON) or `None` – never any other type.
2. `security` / `security_context` (when present) is an `EnhancedSecurityContext` with a fully validated `jwt_payload` (`JwtPayload`). Its attributes (`cid`, `cnm`, `sub`, etc.) are safe for direct attribute access (no `getattr()` probes required).
3. AI upstream responses are validated exactly once when converted into contract models (e.g., `TemplateGenerateResponse`). Cached copies originate from already validated instances.
4. Envelope responses (`SuccessResponse`, `ErrorResponse`) take Python dicts or Pydantic models and handle `.model_dump()` internally—no need to manually coerce again.
5. ALL Python developers STRICTLY obey all type-hints.  If a parameter is type-hinted as `Optional[Dict[str, Any]]`, do NOT add runtime checks for `isinstance(body, dict)` or `body is not None`—treat it as a dict or None per the contract.  If not optional, treat it as always present and of the correct type.

### Idempotency & Caching Rules
1. Idempotent cache entries are stored only after a successful, validated model result is transformed to a dict; retrieving from cache does not require re-validation unless the schema version changes.
2. The idempotency key structure: `ai-idem:<scope...>:<operation>:<hash|explicit>` where scope segments are derived from validated JWT claims (client_id=cid, tenant=cnm, user=sub) based on `CORE_AI_IDEMPOTENCY_SCOPE` (`client|tenant|user`).
3. Do NOT introduce additional hashing layers or entropy that would reduce deterministic reuse; only add new scope components if driven by a versioning or security requirement.

### Style Requirements for Future Edits
1. Prefer direct attribute access for validated objects (`payload.cid`, not `getattr(payload, 'cid', None)`).
2. Avoid re-running model validation on cached data unless a migration boundary is introduced. If a migration is needed, add an explicit version field in the stored dict (e.g., `_schema_version`).
3. Do not wrap already-validated Pydantic models in additional schema containers solely for namespacing—compose at the response envelope level instead.
4. Avoid re-checking `isinstance(body, dict)`—treat `body` as a dict (or `None`) per handler contract.
5. Logging should not duplicate success metadata already captured (e.g., correlation ID); only add deltas (cache hit/miss, latency tiers, idempotent key).

### When Additional Validation IS Appropriate
1. New external integration (new upstream service) before first conversion to internal contract model.
2. Schema version upgrade where cached entries might have the previous shape.
3. Unsafe user-provided dynamic plugin/module references (not currently part of the AI contract set).

### Anti-Patterns to Reject in Reviews / Suggestions
| Anti-Pattern | Why Reject | Correct Approach |
|--------------|-----------|------------------|
| Using `getattr()` on `security.jwt_payload` | Payload already validated | Direct attribute access (`security.jwt_payload.cid`) |
| Re-validating cached dict with same model | Wasted CPU | Trust cached dict; only validate on initial creation |
| Recomputing JSON canonical form multiple times in one handler | Inefficient | Compute once for idempotency key generation |
| Wrapping response model in another Pydantic model for no reason | Adds noise | Return model or dict inside standard envelope |
| Adding generic `try/except Exception` around code already raising typed errors | Masks root cause | Allow typed exceptions to propagate to existing error handling |

### Extension Guidance
If future features require altering idempotency scope (e.g., workflow grouping, region or feature flags), extend `build_idempotency_key` with an extra, explicit segment; do not splice into existing segments to preserve backward compatibility of keys.

---
This section exists to keep future automated or human contributors from reintroducing defensive boilerplate the framework already centralizes. Any suggestion conflicting with these guarantees should be flagged as a contradiction with this "Validated Model & Type Hint Guarantees" section.

## User Confirmation Prompts (Templates)

To ensure adherence, use these templates in responses requiring approval:

- Plan Presentation: "Per the Plan → Approval → Execute workflow, here is the plan: [enumerated steps]. Awaiting approval."
- Approval Request: "Awaiting your approval to proceed (e.g., 'approved' or 'proceed with step 1')."
- Post-Execution Summary: "Executed approved steps. Deltas: [summary]. Workflow adhered: Yes."
