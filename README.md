# Simple Cloud Kit

#### About

Exclusive Information Technology Service is pleased to offer a tool to be used by AWS Cloud Engineers within enterprise environments that will provide opinionated methodologies for how AWS Multi-Account Landing Zones should be implemented to maintain CIS (Critical Infocom Service) regulatory compliance and Best Practices.

We call this kit, the **Simple Cloud Kit**.  And will refer to it as **SCK**.

We will refer to the core services within the **SCK** as *core-automation* or in many cases simply <b>*core*</b>.



**Current Stage:** *development - incubation*

#### The Model

The model for the enterprise is based on the concept of *seperation of duties*.  Each task is conducted by a person having a *persona's* such that each of the teams responsible for governance of infrastructure services may operate the **Landing Zones** safely and in collaboration with other teams.

<div style="display: flex; align-items: center;">
  <img src="images/small-hat.jpg" alt="Description" style="margin-right: 10px;">
  <p>Persona's are **Hats**.  When you work on infastructure, you will need switch *hats* to perform duties with the <b>Simple Cloud Kit</b>.  By switching hats, it will begin to understand the structure of the service and command set.</p></div>

## Persona's

**Billing / Finance Team**
This team is responsible for the Accounting, Billing, and payments for AWS within the enterprise.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>AWS Organization Account</i>
</p>

Typical subsystems that this team will access are:

* Cost Explorer
* Billing Dashboards
* QuikSite Dashboards

**Identity Team**
This team is accountable for all Users *(i.e. human users)* that need to access internal infrastrcture.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>AWS Identity and Access Management Account</i>
</p>

The services are typically **Active Directory** services or **Kerberose** and includes all process of **PIAM** (Priviledged Identity/Access Management).  In many cases, this includes the SSL Certificate generation for both *server certificates* and *user certificates* and manages the *Certificate Authority* for the enterprise.

Typical subsystems that this team will access are:

* AWS SSO
* Azure Active Directory (Azure Cloud)
* Windows Active Directgory (On Premises)
* AWS Certificate Manager (e.g. Hashicorp Vault certificate managment)
* User Roles and Policy
* KMS (Optionally, if not managed by Logging or Security Teams)

**Domain Team**
Manages all names or domains.  You will need to understand both your internal  domain and external domain name requirements.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>AWS Network Account</i>
</p>

<u>External Domains</u>
This is your domain name as recognized by your external customers.  External
customers might access your services at "www.mycompany.com".  The Domain team
determines and provides names for use within landing zone external access points.

<u>Internal Domains</u>
The domain team issues internal domain names for your corporate LAN or Intranet.  It might be a subdomain for your primary domain.  Options are limitless.  But we can
imagine a subdomain such as "myservice.internal.mycompany.com" or "myservice.internal.mycompany.net".  Again, this is the descretion of the Domain Team.

Cloud Engineers must interact with the Domain Team to establish the paramters for
automation and infrastructure deployment. We must deploy infrastructure into the
proper **domain**.  The access to the *AWS Network Account** is to register internal domain names into the landing zone.

In your organization, the Domain Team may be responsible for administration of Windows Domain Controllers.  If so, then they needs to understand Route53 as these are Domain Controllers extinging their domain services. As domains are registered in the Domain Controllers, they must be regisgtered in the AWS Landing Zones Route53.

Domains and Subdomains registred in the AWS Landing Zones is managed completely by the
SCK internal services.

Typical Subsystems access by this team are:

* AWS Route53
* CloudWatch

**Firewall Team**
The firewall team will be responsible for addressing ingress control from the Internet to the landing zones as well as internal corporate systems that need connectivity to Cloud services.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>DMZ Account</i> and <i>Network Accounts</i>
</p>

This team will interact with services such as.
* AWS WAF
* Imperva
* Akamai
* AWS Network Firewall
* AWS Transit Gateway Rules (and Security Groups)

Their purpose is to grant or revoke access to services that have been deployed.  This team is typically capable of configuring the services.  They are **Users** and the automation must enable this team to perform the required business function.

**Monitoring / Audit / Logging Team**
This team is responsible for setting up and operating the logging services for all applications and infastructure.  They do not provide the metrics.  Instead, they provide the services that teams use to record their metrics.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>Audit and Logging Account</i>
</p>

In many cases, you may have a monitoring Command Center (COM)  (SOC) that needs to use these services as well to monitor alarms.

This team will provide the logging and compliance requirements for each
classification of services.

Typical subsystems that this team will use are:
* CloudWatch
* CloudWatch Logs
* Elastic Logstash Kibana stacks (ELK)
* Promethius / Grapfana
* Other logging platforms
* AWS KMS (Key Management Servicees)

As the Audit/Logging team requirs "Encryption At Rest", KMS keys are typically managed by this team.
This includes all KMS keys geneerated in automation serivces.  However, some organizations might
wish this to be managed byt eh Sucrity Team or the Identity team and the **SCK** can be configured to accomodate.

**Secuirty and Compliance Team**
The security and compliance team needs the ability to priovide SIAM solutions across
all infrastructure deployed in the enterprise.  This is how CIS and security compliance
is monitored and verified.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>AWS Secuirty Accounts</i>
</p>

The enterprise may operate a Security Operations Center or SOC that are tasked with
early and immediate response to security threats and vulnerabilities.  This is not *monitoring*, this is *security compliance*.  Intrusion events are managed here as
well as IDS and IPS system administration deployed across all accounts in the Landing
Zones.

Typical Systems that this team leverages are:
* AWS Config
* AWS Security Hub
* Splunk
* Prisma
* Exabeam
* WAF's (Bot detection and alerts, etc.)

**Network Infrastructure Team**
This team might be considered the **parent** team of the Cloud Operations Team.  The network infastructure team is the foundation of Landing Zones and provides the rule of engagement.  Cloud Operations cannot be implemented in the enterprise with Networks.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>AWS Network Accounts</i>
</p>

The Networks team provides governance of all **Landing Zone** deployments and
network expansion in the enterprise. Cloud Operations along with the Simple Cloud Kit
automation frameworks provides network expansion **a.k.a Landing Zones** allocating
CIDR space to new infrastructure and determining how network traffic traversed the Intranet enterprise network.

Typical services this team will leverage:
* AWS VPC Service
* Service Endpoints
* Routers, Gateways, NAT services, Internet Gatways
* Direct Connects (DX) DX Gateeway ad Connetivty
* VPN Services

**Application Support Team**
The application support team has several responsibilitie to ensure appication infrastructure and app;ication support services is deployed.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>AWS Automation Account</i> and <i>Shared Services Accounts</i>
</p>

The Application services teams are Delivery Support.  They manage several subsystems
to support application deployment.  This can include:

* OS "Golden Image" creation and support.  RedHat, Windows, OpenSUSE, Ubuntu, etc.
* Middleware Services such as Niginx, Tomcat, Apache, Weblogix, etc
* Database Management for Oracle DB, MySQL, PostgreSQL, DynamoDb, MongoDB, Couchbase, etc.
* Kubernetes Services.  EKS or OpenShift (OCP), for example.
* EFS, NDF or Block Storage Services

This team may be more than one sub-team.  It depends on the size of the organization
and the enterprise infrastructure support model.  This team may have 1 or more
Shared Services Zones depending on its security requirements

**DevSecOps Team**
The DevSecOps team manages all of the tools necessary to govern software development
with the entrprise.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>AWS Automation Account</i> <b>or</b> <i>DevSecOps Account</i> (only one, not both)
</p>

The DevSecOps team provides the tools and support for systems such as:
* CodeCommit, GitLab, GitHub, BitBucket
* CodeDeploy, GitLab Runnners, GitHub Runners, Bamboo, CircleCI
* Jira, Altera, ServiceNow, etc.
* Nexus, Artifactory Artefact Repositories
* Sonatype, Checkmarx, Sonar, Fortify
* EFS or NFS Services

This team may or may not be part of the Cloud Operations team as it depends on the organization requirements.  There is a "circular dependency" between CloudOps and DevOps as both need each other to bootstrap the environments.  The **SCK** implementation model atempts to address this.

**AWS Automation Team**
This is the **Cloud Engineering and Operations Team**.  The entire mandate for this team is to provide automation frameworks, operational guidelines, and expertiese to the above named infrastructure teams and to design the deployment templates for Cloud infastructure
deployment.

<p style="font-size: 0.8em">
<b>AWS Account Access:</b> <i>AWS Automation Account</i> and <i><b>ALL</b> AWS Accounts</i>
</p>

The automation team installs, configures, and operates the **Simple Cloud Kit**.  If there are customizations and new configuration parameters to define, the Cloud Engineering team makes those modifications and deploys new versions of the **SCK**.

Fundamentally, the **Cloud Entineering Team** is both *Accountable* and *Responsible* to deploy ALL infrstructure in the Cloud for ALL of the above teams.  In order to do this efficiently, it creates
robots (the **SCK**) to perform these tasks in an automated way:

Typical Systems Needed
* CloudFront
* Lambda
* DynamoDB
* S3
* More... or all...

## AWS Accounts for Landing Zones

There are 9 accouts to bootstrap in the AWS Multi-Account Landing Zones architecture which is
what the Simple Cloud Kit is designed for.

These accounts support the Persona's listed above and are:

**AWS Organization Account**
<div style="padding-left: 40px;font-size: 0.8em">
    <b><u>Noteable Services</u></b> <small>Manually created by the Organization</small>
    <ul>
        <li>AWS Organizations <small>Required by Simple Cloud Kit</small></li>
        <li>Control Tower <small>Required by Simple Cloud Kit</small></li>
        <li>AWS SSO</li>
        <li>Cost Explorer</li>
        <li>Billing Dashboards</li>
        <li>Organizatonal Units</li>
        <li>Service Control Policy</li>
    </ul>
</div>

**AWS Audit/Logging Account**
<div style="padding-left: 40px;font-size: 0.8em">
    <b><u>Audit/Log Services</u></b> <small>Automatically by Control Tower</small>
    <ul>
        <li>CloudWatch</li>
        <li>CloudWatch Logs</li>
        <li>Audit Logs</li>
        <li>CloudTrails</li>
        <li>VPC Flow Logs</li>
        <li>ELK Stacks (if not using ClowdWatch)</li>
    </ul>
</div>

**AWS Security/Compliance Account**
<div style="padding-left: 40px;font-size: 0.8em">
    <b><u>Security Services</u></b> <small>Automatically by Control Tower</small>
    <ul>
        <li>AWS Config</li>
        <li>Security Hub</li>
        <li>Splunk or other SIEM</li>
    </ul>
</div>

**AWS Identity Account**
<div style="padding-left: 40px;font-size: 0.8em">
    <b><u>Identity Services</u></b>
    <ul>
        <li>All IAM not in SSO (including service accounts)</li>
        <li>Identity Center. <small>Identity Center for SSO is in the Organization Account</small></li>
        <li>AWS Certificate Manager</li>
    </ul>
</div>

**AWS DMZ Account**
<div style="padding-left: 40px;font-size: 0.8em">
    <b><u>Ingress/Egress Services</u></b>
    <ul>
        <li>Internet Gateways</li>
        <li>AWS Ingress Firewall</li>
        <li>NLB Ingress Controller (Layer 4)</li>
        <li>VPC Endpoint Services (Layer 4)</li>
        <li>Application Load Balancer ALB</li>
        <li>CloudFront Distributions</li>
        <li>AWS Egress Network Firewall</li>
    </ul>
</div>

**AWS Networking Account**
<div style="padding-left: 40px;font-size: 0.8em">
    <b><u>Networking Services</u></b>
    <ul>
        <li>DNS Serviers/Route53</li>
        <li>Name Resolution Services</li>
        <li>AWS VPC Service Endpoints</li>
        <li>VPC's, Route Tables, VPN</li>
        <li>Transit Gateway Services</li>
        <li>Direct Connect</li>
    </ul>
</div>

**AWS Shared Services Account**
<div style="padding-left: 40px;font-size: 0.8em">
    <b><u>Application Services</u></b>
    <ul>
        <li>Multi-Tenant EKS Clusters</li>
        <li>Multi-Tenant OCP or OpenShift Services</li>
        <li>Operating System Image Rository</li>
        <li>Database Services (if not deployed in the Application Zone)</li>
        <li>more...</li>
    </ul>
</div>

**AWS DevSecOps Account**
<div style="padding-left: 40px;font-size: 0.8em">
    <b><u>Automation Services</u></b>
    <ul>
        <li>CodeCommit</li>
        <li>CodeDeloy (central, codedeploy will operate in each zone)</li>
        <li>GitLab, GitHub Entgerprise, Jira, Confluence, Bitbucket, Bamboo, Circle CI</li>
    </ul>
</div>

**AWS Automation Account**
<div style="padding-left: 40px;font-size: 0.8em">
    <b><u>Cloud Engineering Services</u></b>
    <ul>
        <li>Simple Cloud Kit <small>And all required subsystems</small></li>
        <li>A CMDB (Configuration Management Databse) or FACTS of all things deployed</li>
    </ul>
</div>

# What's Next

### Simple Cloud Kit

**STATE:** **_INCUBATION_**

As this project is currently in **_incubation_**, components of the arhitecture will be presented periodically and staged.  The Simple Cloud Kit is composed of the following components and will be in subdirectories within this repsitory.

You will be able to find this project at https://github.com/eitssg/simple-cloud-kit

The basic structure of the repsitory will be:

**Repository:** simple-cloud-kit
**Version:** 0.0.0-alpha

* **core-framework:** The basic shared model framework
* **core-deployment:** Deploys cloud service infrastucture and appls
* **core-compiler:** Compiles templates into CloudFormation "applications"
* **core-engine:** Runs in Lambda to perform mutiple steps of deploying multiple componets simialr to a stack-set
* **core-invoker:** Provides a security boundry establing and minimizing blast radius with RBAC controls
* **core-api:** An database of
* **core-docs:** a set of User Guides and API Guides for using Simple Cloud Kit
* **sck-mod-core:** Commandline Tools

### Simple Cloud Kit Dashboard

**STATE:** **_INCUBATION_**

In addition to the **Simple-Cloud-Kit**, the team is devloping a User Interface dashboad as a separate project that will leverage the **sck-mod-core** API as a REACT application.

We will call this the **Simple Cloud kit UI** or **SCK Dashboard**

You will be able to find this project at https://github.com/eitssg/simple-cloud-kit-ui

The basic structure of the repsitory will be:

**Repository:** simple-cloud-kit-ui
**Version:** 0.0.0-alpha

* **sck-web:** A Website dashboard that will use the

As refactoring and testing of each component is developed, it will be pushed to this repository for your consumption.

# Licensing

The Simple Cloud Kit (SCK) will be presented under the GPL-3.0 Licensing framework.

Why GPL?  Why not MIT?

GPL-3.0 was selected as the license of choice to ensure we as a community begin sharing code to create the **Holy Grail** of cloud deployment engines.  We need a huge amount
of feedback and requirements gathering.  And, procuding this under MIT would mean "the code is yours".  We want this code to belong to *The Community*.  Thus, GPL-3.0 is the
choice.

More about the GPL-3.0 license can be found here: https://www.gnu.org/licenses/gpl-3.0.en.html

We do hope you will be able to contribute to this project.

# Authors

This premise and format of this project has been developed of the years by Sourced Group which is now part of the Amdocs team.  I used to work for Sourced Group.

The foundation of the concepts came from a version of Core-Automation developed by Sourced Group in 2019. Their original code is unlicensed or MIT license (Freeware).

I assure you, this will be a _**COMPLETE REWRITE**_.  Although Core-Autmation and its methodologies was the inspiration, apart from terminology, there will be only a few simiarities in templates and structure as the idea is to confirm to Best Practices wich I learned by working with them.

As templates are Jinja2 and CloudFormation, there may be some copying of templates.  But the underlying main engines and Python is **from scratch**.

If there are any questions regarding this source code, please reach out to the primary maintainer:

James Barwick
email: <jbarwick@eits.com.sg>

# Contributing

Please contribute.  Please reach out to me if you would like to create a development branch that we can ultimately merge into the base.

All modules can be found on GitHub with the following links:

* https://github.com/eitssg/core-framework.git
* https://github.com/eitssg/core-db.git
* https://github.com/eitssg/core-execute.git
* https://github.com/eitssg/core-runner.git
* https://github.com/eitssg/core-component-compiler.git
* https://github.com/eitssg/core-deployspec-compier.git
* https://github.com/eitssg/core-invoker.git
* https://github.com/eitssg/core-api.git
* https://github.com/eitssg/core-cli.git
* https://github.com/eitssg/core-ui.git
* https://github.com/eitssg/core-docker.git
* https://github.com/eitssg/core-docs.git
* https://github.com/eitssg/simple-cloud-kit.git

PyPi Repositories can be found here:

* https://pypi.org/project/simple-cloud-kit

# Documentation

The idea on this project is to push documentation to GitHub type Wiki or perhaps I can geet a free Atlassian OSS Conluence site.  For all the details and goodies of implementing, using, and updating the core frameworks, see the online documentation:

TBD

...
(c) Copyright 2024. Exclusive Information Technology Service, c/o James Barwick
