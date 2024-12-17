Registry Database
=================

Clients Table
-------------
Organizatons in AWS are represented in the registry database as a ``Client``.

.. raw:: html

    <b>Table name:</b> core-automation-clients<br/>

+--------------------+-----------+---------------------------------------------+
| Attribute          | Type      | Description                                 |
+====================+===========+=============================================+
| client (hash)      | str       | The 'slug' identifier of the organization   |
+--------------------+-----------+---------------------------------------------+
| more...            |           |                                             |
+--------------------+-----------+---------------------------------------------+


Portfolios Table
----------------
A portfolio is a Business Application.  It defines the owners and stackeholders for the deployments
of applicatin infrastructure.

.. raw:: html

    <b>Table name:</b> core-automation-portfolios<br/>

+--------------------+-----------+---------------------------------------------+
| Attribute          | Type      | Description                                 |
+====================+===========+=============================================+
| client (hash)      | str       | The 'slug' identifier of the organization   |
+--------------------+-----------+---------------------------------------------+
| portfolio (range)  | str       | The 'slug' identifier of the portfolio or   |
|                    |           | Buisness Application (bizApp)               |
+--------------------+-----------+---------------------------------------------+
| more...            |           |                                             |
+--------------------+-----------+---------------------------------------------+

Apps Table
----------
The app Registry is a lists of deployments within a specific portfolio.  A deployment is targeted
at a specific zone

.. raw:: html

    <b>Table name:</b> core-automation-apps<br/>

+-------------------------+-----------+---------------------------------------------+
| Attribute               | Type      | Description                                 |
+=========================+===========+=============================================+
| ClientPortfolio (hash)  | str       | The f"{client}:{portfolo}" string           |
+-------------------------+-----------+---------------------------------------------+
| AppRegEx (range)        | str       | A regular expresstion matching the the      |
|                         |           | string f"{app}-{branch}-{build}"            |
|                         |           |                                             |
|                         |           | Example: "^(.+)-(.+)-(.+)$"                 |
+-------------------------+-----------+---------------------------------------------+
| Zone                    | str       | The Zone where this app is to be deployed   |
+-------------------------+-----------+---------------------------------------------+
| Region                  | str       | The region name sepcified in the Zone       |
|                         |           | definition                                  |
+-------------------------+-----------+---------------------------------------------+
| Tags                    | map       | A set of name/value mappings that are to be |
|                         |           | applied to the resource tags                |
+-------------------------+-----------+---------------------------------------------+

Zones Table
-----------
The zone Registry is a list of locations including AWS Account and Region(s) that are used to
contain App Deployments.

.. raw:: html

    <b>Table name:</b> core-automation-zones<br/>

+------------------------+--------------+----------------------------------------------+
| Attribute              | Type         | Description                                  |
+========================+==============+==============================================+
| ClientPortfolio (hash) | str          | The f"{client}:{portfolo}" string            |
+------------------------+--------------+----------------------------------------------+
| Zone (range)           | str          | A name or label identifying a landing zon e  |
|                        |              | for the application deployments              |
+------------------------+--------------+----------------------------------------------+
| AccountFacts           | AccountFacts |                                              |
+------------------------+--------------+----------------------------------------------+
| RegionFacts            | map          | A map of regionfacts:                        |
|                        |              |                                              |
|                        |              | e.g. regionFacts: Dict[str, RegionFacts]     |
|                        |              | = {"sin": {"AwsRegion": "ap-southeast-1"}}   |
+------------------------+--------------+----------------------------------------------+

AccountFacts
~~~~~~~~~~~~
The AccountFacts is a set of attributes that are used to define the AWS Account that is used in the Zone

+-------------------------+--------------+---------------------------------------------+
| Attribute               | Type         | Description                                 |
+=========================+==============+=============================================+
| AwsAccountId            | str          |                                             |
+-------------------------+--------------+---------------------------------------------+
| AccountName             | str          |                                             |
+-------------------------+--------------+---------------------------------------------+
| Kms                     | KmsFacts     |                                             |
+-------------------------+--------------+---------------------------------------------+
| more ...                |              |                                             |
+-------------------------+--------------+---------------------------------------------+

RegionFacts
~~~~~~~~~~~~
The RegionFacts is a set of attributes that are used to define the AWS Region that is used in the Zone

+-------------------------+--------------+---------------------------------------------+
| Attribute               | Type         | Description                                 |
+=========================+==============+=============================================+
| AwsRegion               | str          | AWS Region Code.  e.g. us-east-1            |
+-------------------------+--------------+---------------------------------------------+

KmsFacts
~~~~~~~~
+-------------------------+--------------+---------------------------------------------+
| Attribute               | Type         | Description                                 |
+=========================+==============+=============================================+
| KmsKey                  | str          | KmsKey used to encrypt resources            |
+-------------------------+--------------+---------------------------------------------+
