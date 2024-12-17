.. _database_schema:

Database Schema
===============
Documentation on the database schemas used in the application.

Each client has its own database table in DynamDB.

The two tables are named with AWS Organization Name (slug value) contatenated with "core-automation-items", and "core-automation-events".

Example:

* cient-core-automation-items
* client-core-automation-events

Items Table
-----------

The followint Schemas are in the Items table:


* :ref:`portfolio-schema`
* :ref:`app-schema`
* :ref:`branch-schema`
* :ref:`build-schema`
* :ref:`component-schema`

.. _portfolio-schema:

Portfolio Schema
~~~~~~~~~~~~~~~~

.. raw:: html

    <b>Table name:</b> {client}-core-automation-items<br/>
    <small><i><b>Note:</b> {client} is the AWS Organization Name (slug value)</i></small>

+--------------------+-----------+------------------------------------------+
| Attribute          | Type      | Description                              |
+====================+===========+==========================================+
| prn (hash)         | str       | Pipeline Reference Number                |
+--------------------+-----------+------------------------------------------+
| parent_prn (range) | str       | Parent Pipeline Reference Number         |
+--------------------+-----------+------------------------------------------+
| name               | str       | Name of the portfolio                    |
+--------------------+-----------+------------------------------------------+
| contact_email      | str       | Contact email address                    |
+--------------------+-----------+------------------------------------------+
| created_at         | timestamp | Timestamp when the portfolio was created |
+--------------------+-----------+------------------------------------------+
| updated_at         | timestamp | Timestamp when the portfolio was last    |
|                    |           | updated                                  |
+--------------------+-----------+------------------------------------------+


.. _app-schema:

App Schema
~~~~~~~~~~


.. raw:: html

    <b>Table name:</b> {client}-core-automation-items<br/>
    <small><i><b>Note:</b> {client} is the AWS Organization Name (slug value)</i></small>

+--------------------+-----------+------------------------------------------+
| Attribute          | Type      | Description                              |
+====================+===========+==========================================+
| prn (hash)         | str       | Pipeline Reference Number                |
+--------------------+-----------+------------------------------------------+
| parent_prn (range) | str       | Parent Pipeline Reference Number         |
+--------------------+-----------+------------------------------------------+
| name               | str       | Name of the app                          |
+--------------------+-----------+------------------------------------------+
| portfolio_prn      | str       | Example "prn:portfolio_name"             |
+--------------------+-----------+------------------------------------------+
| contact_email      | str       | Contact email address                    |
+--------------------+-----------+------------------------------------------+
| created_at         | timestamp | Timestamp when the app was created       |
+--------------------+-----------+------------------------------------------+
| updated_at         | timestamp | Timestamp when the app was last updated  |
+--------------------+-----------+------------------------------------------+

.. _branch-schema:

Branch Schema
~~~~~~~~~~~~~

Branches for the App deployment

+--------------------+-----------+---------------------------------------------------+
| Attribute          | Type      | Description                                       |
+====================+===========+===================================================+
| prn (hash)         | str       | Pipeline Reference Number                         |
+--------------------+-----------+---------------------------------------------------+
| parent_prn (range) | str       | Parent Pipeline Reference Number                  |
+--------------------+-----------+---------------------------------------------------+
| name               | str       | Name of the app                                   |
+--------------------+-----------+---------------------------------------------------+
| portfolio_prn      | str       | Example "prn:portfolio_name"                      |
+--------------------+-----------+---------------------------------------------------+
| app_prn            | str       | Example "prn:portfolio_name:app_name"             |
+--------------------+-----------+---------------------------------------------------+
| created_at         | timestamp | Timestamp when the portfolio was created          |
+--------------------+-----------+---------------------------------------------------+
| updated_at         | timestamp | Timestamp when the portfolio was last             |
|                    |           | updated                                           |
+--------------------+-----------+---------------------------------------------------+

.. _build-schema:

Build Schema
~~~~~~~~~~~~

.. raw:: html

    <b>Table name:</b> {client}-core-automation-items<br/>
    <small><i><b>Note:</b> {client} is the AWS Organization Name (slug value)</i></small>

+--------------------+-----------+---------------------------------------------------+
| Attribute          | Type      | Description                                       |
+====================+===========+===================================================+
| prn (hash)         | str       | Pipeline Reference Number                         |
+--------------------+-----------+---------------------------------------------------+
| parent_prn (range) | str       | Parent Pipeline Reference Number                  |
+--------------------+-----------+---------------------------------------------------+
| name               | str       | Name of the build                                 |
+--------------------+-----------+---------------------------------------------------+
| portfolio_prn      | str       | Example "prn:portfolio_name"                      |
+--------------------+-----------+---------------------------------------------------+
| app_prn            | str       | Example "prn:portfolio_name:app_name"             |
+--------------------+-----------+---------------------------------------------------+
| branch_prn         | str       | Example "prn:portfolio_name:app_name:branch_name" |
+--------------------+-----------+---------------------------------------------------+
| created_at         | timestamp | Timestamp when the build was created              |
+--------------------+-----------+---------------------------------------------------+
| updated_at         | timestamp | Timestamp when the build was last                 |
|                    |           | updated                                           |
+--------------------+-----------+---------------------------------------------------+

.. _component-schema:

Component Schema
~~~~~~~~~~~~~~~~

.. raw:: html

    <b>Table name:</b> {client}-core-automation-items<br/>
    <small><i><b>Note:</b> {client} is the AWS Organization Name (slug value)</i></small>

+--------------------+-----------+---------------------------------------------------+
| Attribute          | Type      | Description                                       |
+====================+===========+===================================================+
| prn (hash)         | str       | Pipeline Reference Number                         |
+--------------------+-----------+---------------------------------------------------+
| parent_prn (range) | str       | Parent Pipeline Reference Number                  |
+--------------------+-----------+---------------------------------------------------+
| portfolio_prn      | str       | Example "prn:portfolio_name"                      |
+--------------------+-----------+---------------------------------------------------+
| app_prn            | str       | Example "prn:portfolio_name:app_name"             |
+--------------------+-----------+---------------------------------------------------+
| branch_prn         | str       | Example "prn:portfolio_name:app_name:branch_name" |
+--------------------+-----------+---------------------------------------------------+
| build_prn          | str       | Example "prn:portfolio_name:app_name:branch_name" |
+--------------------+-----------+---------------------------------------------------+
| status             | enum      | Status of the component                           |
+--------------------+-----------+---------------------------------------------------+
| message            | string    | Message related to the component                  |
+--------------------+-----------+---------------------------------------------------+
| created_at         | timestamp | Timestamp when the component was created          |
+--------------------+-----------+---------------------------------------------------+
| updated_at         | timestamp | Timestamp when the component was last             |
|                    |           | updated                                           |
+--------------------+-----------+---------------------------------------------------+

Event Table
-----------

.. raw:: html

    <b>Table name:</b> {client}-core-automation-events<br/>
    <small><i><b>Note:</b> {client} is the AWS Organization Name (slug value)</i></small>

+--------------------+-----------+------------------------------------------+
| Attribute          | Type      | Description                              |
+====================+===========+==========================================+
| prn (hash)         | str       | Pipeline Reference Number                |
+--------------------+-----------+------------------------------------------+
| timestamp          | timestamp | Timestamp of the event                   |
+--------------------+-----------+------------------------------------------+
| status             | enum      | Status of the event                      |
+--------------------+-----------+------------------------------------------+
| message            | string    | Message related to the event             |
+--------------------+-----------+------------------------------------------+
| details            | string    | Additional details about the event       |
+--------------------+-----------+------------------------------------------+

