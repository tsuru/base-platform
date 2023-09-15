base-platform
=============

[![tsuru/base-platform](http://dockeri.co/image/tsuru/base-platform)](https://hub.docker.com/r/tsuru/base-platform/)

Base Docker image for tsuru platforms. It creates the required structure for
tsuru platforms:

- create the ubuntu user
- create the /home/application directory
- properly set paths permissions
- install deploy-agent
- place the base deploy script in the path ``/var/lib/tsuru/base/deploy``

The image also provides the script that does the following steps:

1. Downloads the archive provided by the tsuru API
1. Extracts it in the ``/home/application/current`` directory
1. Install operating system dependencies
1. Handle default Procfiles (stored in the directory ``/var/lib/tsuru/default``)

It's possible to build platforms that do not use this image, but you need to
ensure that deploy-agent is installed, and that you provide a deploy script
that does everything that the base deploy script does.

You may also invoke the install and deploy scripts manually, as the buildpack
platform does:
https://github.com/tsuru/platforms/blob/master/buildpack/Dockerfile.
