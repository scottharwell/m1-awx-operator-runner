# M1 Mac AWX Deployment Container

**Problem**: You have an M1 Mac and you want to deploy Ansible AWX using the AWX operator.  But, the operator `make deploy` command doesn't work because the container images expect the host system to be an amd64 machine.

**Solution**: This container and a few Docker flags!

This repo contains a Dockerfile that builds a Fedora-based container that includes the latest release checkout from the AWX operator repository, the `kubectl` command, and a few other niceties to make it easy to just run `make deploy` as the AWX operator instructions direct you to if your machine was amd64-based.

## How-To

### Building the Container

In order to build this container, you can run the following to build locally and push to your container registry.

```bash
docker buildx build \
--platform linux/amd64 \
-t $REGISTRY/m1-awx-operator-runner:latest \
--push .
```

### Running the Container

Once the container is built, then you can just run the container when you want to run the latest updates to AWX.  The operator will be at the latest version as of the time that it was built.  If the versions are off, then you can build a new container instance, or just run `git pull` from the repository in the container and then checkout the newest release.

Be sure that you properly mount your K8s config file so that the AWX Operator will be able to deploy to your cluster.

```fish
docker run -it \
--rm \
--name awx-operator-runner \
--platform=linux/amd64 \
--mount type=bind,source="$HOME/.kube/config",target=/home/awx/.kube/config \
docker-registry.gso.harwell.me/scottharwell/m1-awx-operator-runner
```

The container will start with the following message:

> Welcome to the AWX deployment container!
> 
> Ensure that your kubeconfig file is either created first in ~/.kube or that you mapped a local config to ~/.kube/config when instantiating this container.
> 
> Type `bash -c 'make deploy'` or `deploy_awx` (a fish shell alias for the former command) to attempt to deploy the version of the AWX Operator currently checked out.

You may then run either of the commands offered to deploy the latest version of the AWX operator; you only need to run one of them.