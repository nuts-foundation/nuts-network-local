.. _nuts-consent-local-development:

Nuts local network
##################

.. _nuts-consent-local-development-docker:

.. marker-for-readme

Running with docker
*******************

This repo contains a set of properties, keys, config and other files for setting up a local development environment. This is all connected together with a single ``docker-compose.yml`` file. You'll need to have docker and java installed.

First get the Corda network bootstrapper tool from https://repo1.maven.org/maven2/net/corda/corda-tools-network-bootstrapper/4.1/

Generate corda nodes:

.. code-block:: shell

    cd nodes && java -jar corda-tools-network-bootstrapper-4.1.jar --dir .

More info on how to bootstrap a corda network: https://docs.corda.net/network-bootstrapper.html

To start

.. code-block:: shell

    docker-compose up -d -V

``-d`` will run all containers detached. To view the logs:

.. code-block:: shell

    docker-compose logs -f

Corda logs can also be viewed inside ``nodes/NODE/logs`` since ``nodes/NODE`` is mounted in the container.

``-V`` will remount the volumes, this is needed when you change any of the properties files.

All of the Nuts docker images are build directly from code on Docker Hub. To get the latest development images, use:

.. code-block:: shell

    docker-compose pull

.. note::

    Local development runs without a discovery service.

.. note::

    Running everything at a single machine can be a bit demanding since you're virtually running 3 nodes isstead of 1. If things go too slow, give docker some more resources.
