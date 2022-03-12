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

Once the container is built, then you can just run the container when you want to run the latest updates to AWX.  The container entry point is pre-configured to the latest release of the AWX operator.  So, when running the following `docker run` command, it will operate functionally the same as if you were running `make deploy` from the repo on your local machine.  The operator will be at the latest version as of the time that the container was last built.

Be sure that you properly mount your K8s config file so that the AWX operator will be able to deploy to your cluster.

```fish
docker run -it \
--rm \
--name awx-operator-runner \
--platform=linux/amd64 \
--mount type=bind,source="$HOME/.kube/config",target=/home/awx/.kube/config \
quay.io/scottharwell/m1-awx-operator-runner:latest
```

If you want to enter the container and update the commit used from the AWX operator git repo or perform some other task, then you may run the following to be dropped into a Fish shell.

```fish
docker run -it \
--rm \
--name awx-operator-runner \
--platform=linux/amd64 \
--mount type=bind,source="$HOME/.kube/config",target=/home/awx/.kube/config \
--entrypoint /usr/bin/fish \
quay.io/scottharwell/m1-awx-operator-runner:latest
```

The container will start with the following message:

> Welcome to the AWX deployment container!
> 
> Ensure that your kubeconfig file is either created first in ~/.kube or that you mapped a local config to ~/.kube/config when instantiating this container.
> 
> Type `bash -c 'make deploy'` or `deploy_awx` (a fish shell alias for the former command) to attempt to deploy the version of the AWX Operator currently checked out.

You may then run either of the commands offered to deploy the latest version of the AWX operator; you only need to run one of them.