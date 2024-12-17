Introduction
============

Welcome to the EITS User Guide. This guide will help you understand how to use the application effectively.

What is CORE?
-------------

Core is a suite of tools that provide automation and governance for deploying application infrastructure in the cloud.
Core is designed to provide a standardised, repeatable, and secure way to deploy applications in the cloud. Core is designed
to be used by both developers and operators to deploy applications in a secure and standardised manner.

**What does the pipeline do for me?**

The pipeline allows teams to **package**, **compile**, **deploy** (or **plan** and **apply**), **release**, and **teardown** application
infrastructure in the cloud in a secure, standard, and repeatable manner.

**Terms**

* **Package**
      The process of packaging your application code and configuration definitions into a deployable artifact.

      This includes all of the installation files necesary to install your application on a server.  Your package
      must include *install.exe* or *install.sh* files, configuration files, and any other files that are necessary
      to install your appication.  The package is then uploaded to the pipeline for deployment into the "packages" repository.

* **Compile**
      The process of compiling your application *infastructre* code into a deployable artifact.

      This includes generating CloudFormation Templates or other scripts that will be used to create an AWS "Appication"
      (a.k.a CloudFormation Stack).  When compilation completes your installation files are copyied to "The compiled
      artifact is then uploaded to the pipeline for deployment.

* **Deploy**
      The process of deploying your application infrastructure into the cloud.

      This includes creating the necessary resources in the cloud, installing your application, and configuring your
      application.  The deployment process is managed by the pipeline and is performed in a secure, standard, and repeatable
      manner.

      **plan** and **apply** can be used to *stage* the deployment so you can see what changes will be made before
      you apply the changes.

* **Release**
     The process of releasing your application to production.

     As Core manages all DNS services in the cloud, this process is simple:  It adjust DNS entries so that your
     new deployment becomes *active*.

* **Teardown**
     The process of tearing down your application infrastructure in the cloud.

     This includes removing all of the resources that were created during the deployment process.

.. note:: Core does NOT compile, test, build, or relaase your appication to production artefact repositories.
          In the SDLC, Core is used to deploy **application infrastructure** and will *install* your ready made
          application binaries on the destination infrastructure.

.. hint:: plan -> design -> build -> test -> release -> **deploy** -> operate -> monitor -> analyze

In the SDLC, a **release** means generating an *install.exe* or installation package and uploading that package to to your
artifact repository. Durning the Core **Package** phase, your artefact will be uploaded to the pipeline packages to prepar
for insallation on the destination infrastructure.  Core can also be used to *package* your development or test artefacts.

Deploy Infrastrcture
--------------------

Behind the scenes, the pipeline performs the necessary heavy lifting including:

* **Infrastrcture lifecycle** - Manages package, compile, deploy, release, teardown, rollback phases of
  application infrastructure deployment lifecycle.
* **Security** - deploys, manages, and enforces application security in line with best practices
* and company policies
* **Governance** - enforces change control and governance requirements
* **Compliance** - enforcing company compliance requirements
* **Data Persistence** - maintains component persistence between builds, when required
* **Logging** - provides logging of configuration and events
* **SOE Enforcement** - manages and enforces the use of SOE images

By performing this heavy lifting on behalf of application teams, using the pipeline results in:

* **Increased developer agility** - developers can focus on their application rather than connecting
  and managing the underlying infrastructure.
* **Increased operator agility** - operators use the pipeline to perform common tasks operations in a
  highly standardised application lifecycle.
* **Repeatability** - The pipeline enforces automation of application deployment, infrastructure as
  code, and configuration as code.
* **Recoverability** - By enforcing everything-as-code and enforcing best practice architecture
  patterns, application teams can be confident in their ability to restore data and systems in
  the event of a disaster.
* **Reduced risk** - Through a high degree of automation, the pipeline reduces the requirement for
  human intervention and the potential for human error during application deployment.
* **Stronger governance and compliance** - The pipeline transparently manages the governance and
  compliance aspects of deployment. Applications deployed through the pipeline are assured of complying
  with company requirements.

