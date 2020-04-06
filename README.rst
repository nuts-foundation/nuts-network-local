Local nuts network
##################

Setup for running Nuts locally

.. _nuts-consent-local-development-docker:

Running with docker-compose
***************************

This repo contains a set of properties, keys, config and other files for setting
up a local development environment. This is all connected together with a single
``docker-compose.yml`` file. You'll need to have docker and java installed.

For more extensive instructions, see the getting started guide in the docs:
https://nuts-documentation.readthedocs.io/en/add-sso-rfc/pages/getting_started/local_network.html#setup-a-local-nuts-network .

In order to set up the network, a few script are included. To bootstrap the Corda
nodes and gernerate the network event run:

.. code-block:: shell

    $ ./boostrap-corda.sh
    $ ./setup-network-registry.sh

To start the full network

.. code-block:: shell

    $ ./start-network.sh

Corda logs can be viewed inside ``nodes/NODE/logs`` since ``nodes/NODE`` is mounted in the container.

All of the Nuts docker images are build directly from code on Docker Hub. To get the latest development images, use:

.. code-block:: shell

    docker-compose pull

.. note::

    Local development runs without a discovery service.

.. note::

    Running everything at a single machine can be a bit demanding since you're virtually running 3 nodes instead of 1. If things go too slow, give docker some more resources.

Data
****

All changes made to consent is persisted and available between restarts. All required data is stored under ``./nodes/*``.

Example consent request that can be send to the bundy node (``localhost:11323/api/consent``)

.. code-block:: json


    {
        "subject": "urn:oid:2.16.840.1.113883.2.4.6.3:999999990",
        "custodian": "urn:oid:2.16.840.1.113883.2.4.6.1:00000000",
        "actor": "urn:oid:2.16.840.1.113883.2.4.6.1:00000001",
        "performer": "urn:oid:2.16.840.1.113883.2.4.6.1:00000007",
        "records": [{
            "consentProof": {
                "contentType": "text/plain",
                "data": "cGRmIGRvY3VtZW50IHdpdGggc2lnbmF0dXJl"
            },
            "period": {
                  "start": "2019-07-03T12:00:00+02:02",
                  "end": "2020-07-01T12:00:00+02:00"
            }
        }]
    }

