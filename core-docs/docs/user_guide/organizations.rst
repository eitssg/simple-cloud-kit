Organizations
=============

AWS Organizations ore fundamental to Core Automation.  An AWS Organization is required to deploy infrastructure.

The AWS Organization is the CLIENT.  Throughout the documentation, the CLIENT is a term used to specify which
AWS Organization to use when deploying infrastrcture.

You will use the core automation command line to configure the CLIENT for your AWS Organization.

.. code-block:: text

    core --client myorg configure

    # or

    export CLIENT=myorg

    core configure

Since the CLIENT and AWS_PROFILE are synonymous, we strongly recommend you setup an AWS_PROFILE for each CLIENT.

.. code-block:: text

        PS C:\Users\user&gt; aws --profile abc configure
        AWS Access Key ID [\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*GJW3]:
        AWS Secret Access Key [\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*\*qUe4]:
        Default region name [ap-southeast-1]:
        Default output format [json]:
        PS C:\Users\user&gt;

Then you will be able to use the --client or --aws-profile commandline options to select your Organization.

Configuration
-------------

When configuring the client there be a series of questions that are asked about the organization. It is
assumed that you have the appropriate permissions to create the necessary resources in the AWS Organization
in the Billing Account.

Running the core configure command will being with a set of defaults and as you begin to use core automation
more and become familier with your options, you may reconfigure the CLIENT at any time.


.. code-block:: text

    export AWS_PROFILE=myorg

    core configure

    Welcome to the Core Automation Configuration Wizard:

    User: aws_username
    UserArn: arn:aws:iam::123456789012:user/aws_username
    Account: 123456789012
    Region: ap-southeast-1

    Please enter the following information:

    Client Name [myorg]: myorg
    Organization ID [o-123456789012]: o-123456789012
    Organization Name [MyOrg]: MyOrg
    Organization Account [123456789012]: 123456789012
    Audit Account [123456789012]: 123456789012
    Master Region [ap-southeast-1]: ap-southeast-1
    Docs Bucket [myorg-core-automation-docs]: myorg-core-automation-docs
    Client Region [ap-southeast-1]: ap-southeast-1
    Automation Bucket [myorg-core-automation]: myorg-core-automation
    Bucket Region [ap-southeast-1]: ap-southeast-1
    Automation Account [123456789012]: 123456789012
    Security Account [123456789012]: 123456789012
    UI Bucket [myorg-core-automation-ui]: myorg-core-automation-ui
    Scope Prefix []:

.. note::

    The above default values will be derrived automatically by the configuration wizard.  You may change them
    as you see fit.  When you want to use Multi-Account-Landing-Zones, you will need to reconfigure.

The configuration wizard will create a file in the **~/.core** directory called **config.json** at the same
time this data will be stored in the DynamoDB table **core-automation-clients**.

.. rubric:: Attributes

**organization_id**

The ID for the organization.  Derrived by scanning for the AWS Organziation that is enabled in the account.
that the AWS_PROFILE is set to.  The Organization must be created manually in the AWS Console.  There is no
API that is available to create an AWS Organization.

**organization_name**

This will default to the AWS_PROFILE name.  You may change it.  This will then be the CLIENT paramter that
is used to identify resources by org.

**organization_account**

This is the AWS Account Number (e.g. 123456789012) that is the root account for the organization.  This is
the Billing Account or the Root Account and is where Control-Tower, Organizations, AWS SSO, and identity
Center are setup.

**client_region**

When running local resources in the Organization Account (most resources will be global), specify the region
that you want to use.  This is the region that the CLI will use to deploy resources.  Mose likely you will
use us-east-1 for the Organization Accoun if the resource is not global as this is required for several AWS services.

**audit_account**

Many organizations require centralized Logging.  This account is used to store logs for all accounts in the
Landing Zones.  You will want to setup a "Zone" for logging and is where you would deploy the CloudWatch
Dashboards, Logs, or ELK Stack. (Grafana, Prometheus, Loki, etc.)

Please note that this account is automationcally created by Control Tower and the default value is derrived
from the Control-Tower service.

    **Note**: Control-Tower logging consists of VPC Flow-Logs and CloudTrail.  This is primarily an **infrastrcture**
    service.  If you wish to use a separate account for **Applicaation Logging** ELK Stacks and CloudWatch Logs and
    Dashboards, use a separate AWS account for the **audit_account**.

**security_account**

This is the account where security tools are deployed.  This is where the Security Hub, GuardDuty, and other
SIEM systems are located for centralized monitoring.

This account is automatically created by Control Tower and the default value is derrived from the Control-Tower service.

If your SOC or Security Operations Center is in a different account, update the value for the security account.  And,
your SOC may need to additionally access the Control-Tower security account.

**automation_account**

Defaults to the Billing Account or Organization account. If your infrastructure Automation team has its own
AWS account, update the value for the automation account. This the account where infrastructure package, files,
and artefacts are stored as well as the DynamoDB tables for the core automation.

**master_region** = UnicodeAttribute(null=True)

This is the AWS Region where automation tools are deployed such as the DynamoDB tables.

**automation_bucket**

This is the bucekt name for the core automation.  This is where the core automation stores its files, packages, and artefacts.

Defaults to **core-autoamtion**.  Unless you know, don't change this value.

**bucket_region**

This is the region for the S3 buckets that are used by the core automation.  This is the region
where the core automation stores its files, packages, and artefactsa and table data.  This is the same
as the **master_region** unless you have a specific reason to change it.

**docs_bucket**

This is the bucket name for the core automation documentation (This manual you are reading).

The default value is **core-automaton-docs** and is a public S3 bucket behind a CloudFront resource.

**ui_bucket**

Core Automation has a web interface that is used to manage the automation tools.  This is the bucket where the
web interface is stored.  The default value is **core-automation-ui**.  This will  use the **master_region**

**scope_prefix** = UnicodeAttribute(null=True)


.. note::
    If you have not setup Core-Automation with the *core engine init* command, you will need to do this FIRST or
    else this command will fail to operate.


.. warning::
    If you are developing core-automation you can configure infrastructure to be deployed to a
    development Organization.

    It is highly recommended that you do not deploy branches of core-automation to production.
    Always deploy the **master** branch to production.

    The **CLIENT** environment variable or **--client** parameter is used to specify
    which AWS Organizaton to use.

    Create a different organization for Developing core automation

    .. code-block:: bash

        # Deploy core-automation and then deploy application infrastructure

        core --client dev-org configure
        core --client dev-org engine deploy
        core --client dev-org run package upload compile deploy -p demo -a canary -b mybranch -n 1

        # or

        export CLIENT=dev-org

        core configure
        core engine deploy
        core run package upload compile deploy -p demo -a canary -b mybranch -n 1

See the developers guide :ref:`developer-guide` for more information on how to enhance or customize core-automation
