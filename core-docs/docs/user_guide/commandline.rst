Using Core Automation
=====================

Core Automation provides a command line interface (CLI) to package, upload, compile, deploy, release, and teardown application infrastructure.

The CLI can be used by CI/CD pipelines to automate the deployment of application infrastructure in the cloud along with application
installers on SOE images.  This provides developers and operators with a standardised, repeatable, and secure way to deploy applications.

The command line also provides the tools you need to deploy your own CloudFromtion templates in an organized way.

**Getting help**

The CLI is hierarchy of commands:

.. code:: bash

    # Running core

    core [configure|run|deploy|engine|domain|organization|portfolio|app|zone]

    # Configuring core CLI
    core configure

    # Build and Deploy application infrastructure from Core-Automation Templates
    core run [package|upload|compile|deploy|release|teardown]
    core run package
    core run upload
    core run compile
    core run deploy
    core run release
    core run teardown

    # Deploy Cloudformation Templates
    core deploy

    # Examine Core internals and install/deploy updates on AWS
    core engine [init|info|deploy|net|teardown]
    core engine init
    core engine info
    core engine deploy
    core engine net
    core engine teardown

    # Manage Domain servers and Route53
    core domain

    # Manage AWS Organizations and SCP and setup new Clients
    core organization

    # Register and Modify Business Apps
    core portfolio

    # Register and Modify Deployment Units for Business Apps
    core app

    # Register and Modify Landing Zones Zones for Business Apps
    core zone

You can getdetailed help on any command by running:

.. code-block:: bash

    core --help

.. warning::

    The CLI requires that you have AWS CLI installed and at least 1 AWS account which will be
    used as the *Root Organization Account*.

Deploying Core Templates
------------------------

Assuming the following conditions:

1. We have a Business Application *portfolio* that is registered in our CMDB called **demo**.
2. The **demo** business applcation has an *app* deployment unit called **canary** that been configured
   to be deployed in a specific Landing Zone.
3. The **canary** app (a git repository) has a *branch* called **mybranch** that is ready to be deployed.
4. The **canary** app has a *build* version, git tag or commit ID of **v0.0.6-pre.204+32f57bd1**.

Run from the demo-canary repository directory as the core application expects the current folder
to be your project and there is a **platform** folder in the root of the project.  Also, your program
installation files (e.g. install.exe or install.msi) should be in a place that the *package* process
can find them.

.. code-block:: powershell

    cd C:\Users\myuser\Development\demo-canary
    core --client abc run package upload compile deploy -p demo -a canary -b mybranch -n "v0.0.6-pre.204+32f57bd1"

This command will do the following:

1. *package* the folder "<project folder>/platform/\*\*" into a zip file
2. *upload* the package.zip to the Core Automation S3 packages bucket s3://\*/core-automation/packages/\*
3. *compile* the Core Automation templates in the package.zip into CloudFormation templates.  This is done in Lambda.
   * Cloudformation templates are generated and uploaded to the artefacts folder s3://\*/core-automation/artefacts/\*
   * Your installaion programs "install.exe" or other files are uploaded to the files fileder s://\*/core-automation/files/\*
4. *deploy* the compiled CloudFormation templates to the AWS account specified in the Registry for the **canary** app.

For more information about how to build your CI/CD pipelines, see the :ref:`developer-guide`.

.. hint::

    When your "CLIENT" and your "AWS_PROFILE" are the same, you only need to specify one option
    in the command line parameter.  Optionally, you can set the AWS_PROFILE environment variable.
    and you will not need to specify the --client abc parameter.


Container Mode
--------------

If you would like to run core-automation completely inside a docker container, you can do so by adding the "--local" option
to the *core* command.

Example:

.. code-block:: bash

    # Deploy Core Templates from a container
    core --local run --help

    # Deploy CloudFormation Templates from a container
    core --local deploy --help

.. note::
    Everything will run locally within a container except DynamoDB.  Even if you
    specify **--local** parameter, the DynamoDB will still be accessed remotely on
    the **DYNAMODB_URL** endpoint sepcified in the environment variables.  You may also
    use the enviornment variable **LOCAL_MODE=True** to specify that you are running locally
    or inside a container.

Pacakges, Files, and Artefacts will be stored locally within the contianer volume in the repository **local** folder.
Of courese you can mount a shared volume to the container:

    /core-automation/local/packages/<client>/<portfolio>/<app>/<branch>/<build>/packages.zip
    /core-automation/local/artefacts/<client>/<portfolio>/<app>/<branch>/<build>/\*.yaml
    /core-automation/local/files/<client>/<portfolio>/<app>/<branch>/<build>/install.exe

If you wish to specify a different location for the shared files, use the **LOCAL_ROOT** environment variable.

.. code-block:: bash

    export LOCAL_MODE=true
    export LOCAL_ROOT=/mnt/core-automation/local

.. warning::
    This option will prevent Core from uploading artefacts to S3 and will NOT use lambda.
    However, the container **must** have access to the DynamoDB database.


