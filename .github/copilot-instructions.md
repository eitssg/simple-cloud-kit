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