# Docs

Contains the documentation for both

* user-guide - those who use the consumables and are deploying infrastructure
* developer-guide - those who develop consumables or anyone wanting to know more about how core-automation works.
* api-guide - instructions for using the RESTful API (Or, JSON API Rather... do we need RESTful?)

## Building the Docs
The documentation contains instructions on how to build the documentation!

### Set-up

It is assumed that you have checked-out and cloned the multi-cloud-deployoment-toolkit.

```ps1
git clone https://github.com/jbarwick/multi-cloud-deployment-toolkit
```

Change the current working folder to the **multi-cloud-deployment-toolkit\core-docs** folder

```ps1
cd multi-cloud-deployment-toolkit
cd core-docs
```

Prepare the python environment by executing the prepare.ps1 script.  The script will assume you have access to a pypi repository alredy configured with python and pip

```ps1
prepare.ps1
```

If you are on linux, then you can run **prepare.sh** bash script

### Building the Documentation

Building the documentation is simple.  All you need to do is run the builder.

* Build User's Guide

Execute in the powershell console:

```ps1
core-docs user
```

Build the Developer's Guide
```ps1
core-docs developer
```

Build both of them at the same time
```ps1
core-docs all
```

The users-guide and developer guid will be in the folder **`build`** in your current working folder

You can then navigate to the **`build\user-guide`** or **`build\developer-guide`** folder and run **`index.html`**

## Publishing to and S3 bucket

You may have infrastructure already deployed to share this documentation on a URL pointing to either an S3 bucket or CloudFront distribution.  (This script is for AWS, but feel free pubish on Azure or GCP as you desire)

Modify the publish.ps1 script to specify your folder

```ps1
# Buld all the documeentation
core-docs all

$USER_GUIDE_BUCKET = "core-automation-docs/user-guide"
$DEVELOPER_GUIDE_BUCKET = "core-automation-docs/developer-guide"

# Copy the contents of the build/user-guide directory to the S3 bucket
aws s3 cp build/user-guide/ s3://$USER_GUIDE_BUCKET/ --recursive

# Copy the contents of the build/developer-guide directory to the S3 bucket
aws s3 cp build/developer-guide/ s3://$DEVELOPER_GUIDE_BUCKET/ --recursive
```

The above script is in the file **`publish.ps1`** and can be easily executed on a build job in your CD pipeline (GitHub Actions or Bitbucket Pipeline)

An example of how to create the bucket is provided in the script **`create-bucket.psq`**

```text
Note:  We highly recommend you create in index.html page that will allow the users to choose
the developer guide or the user's guide and have that index.html file in your S3 bucket.  Make relevent
changes if you are going to have a different bucket for each guide and/or CloudFront origin paths
```
