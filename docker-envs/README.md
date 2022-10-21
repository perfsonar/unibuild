# Build developers Docker images of unibuild with different distros and CPU architectures.
## Requirements
This setup is using `docker compose` version 2.

## Usage
To create and publish your own Unibuild Docker images, simply run:
`build-dev-images`
See script or run with `-h` to list all options.

Multi architecture setup is currently only supported for Debian and Ubuntu images.

## Notes
### GitHub provided images
Docker images/packages provided through GitHub are built and published using the GitHub Actions.

### Why this script?
This script is needed when you want to play around with the Docker images and your own Unibuild environment.  Also if you want to use multi-architecture images you need to post those to a proper registry as the local Docker registry is not capabable of using tags for multi-architecture builds.
