# Permissions

- The "Registry" is a database of clients, zones, portfolios, apps
- Different people will be responsible for registry

## clients

Role: cloud admin
Actions:
- They setup AWS organazations and create aws accounts and talk to AWS
- Manages the AWS Management Account.  Billing, Account.
- Manages AWS SSO
- Manages Organization, Organizational Units, and OU Policy
- Clients CANNOT be created in the SPA UI.  Client's are created via external script

Roles: cloud user
Actions:
- Can administrate aws (create resources, stacks, etc) but cannot admin the billing information or billing account, organizational unit Cloud Users can edit client details.

Roles: all user
- Can only read / view (most) details.  The AWS "ReadOnly" role.

When we say 'new client', we will be running a script that deployes CloudFormation stack and a hook executer that will inject into the database the client details when the cloudformation stack execution is successful.

## zones

Roles: cloud admin, cloud user
Action:
- Defining Networks, The zone is the 'network' wehre apps will be deployed. 
- Establishing NACLs, Security Groups, Routes, Regions, Images, and all other AWS resources requried to deploy applications in the cloud

Roles: cloud admin, cloud user, zone admin
Actions:
- Register add/remove zones in the registry.  

Roles: cloud admin, cloud users, zone admin, zone user
Actions:
- Edit zone details in the registry

Roles: cloud admin, cloud users, zone admin, zone user, zone reader, app admin, app user
Actions:
- View zone details

(Portfolio admin/users cannot see zones unless they have specific zone permission)

## Portfolios

Roles: portfolio admin, cloud admin
Actions:
- register new portfolios (account namagers, project managers, owners of the CMDB.)

Roles: portfolio admin, approver admin, cloud admin
Actions:
- Manage the approvers list for portfolios

Roles: portfolio admin, portfolio user, portfolio reader, app admin, app user, cloud admin
Actions:
- View portfolio details

## Apps

Roles: app admin, portfolio admin, cloud admin
Action:
- Add/remove apps in the registry

Roles: app admin, app_user, cloud admin
- Edit apps in the regisry

Roles: app admin, app user, app reader, cloud admin
- View app datails

Apps (devops or infrastructure team) define 'where' the portfolioy deployment app will go.  And the App must be registered in Github, Gitlab, Bitbucket, or other Git repository (repsitory URL)..

Automtation between the Core App and the Git Repo:  sck-core-report is a receiving hook lambda function or HTTP gateway endpoint (hook or callback).
