# M1 Mac AWX Deployment Container

[![Build CI](https://github.com/scottharwell/m1-awx-operator-runner/actions/workflows/build.yml/badge.svg)](https://github.com/scottharwell/m1-awx-operator-runner/actions/workflows/build.yml)

**Problem**: You have an M1 Mac and you want to deploy Ansible AWX using the AWX operator.  But, the operator `make deploy` command doesn't work because the container images expect the host system to have an `amd64` architecture.

**Solution**: Use `kustomize` directly or this container that will do it for you!

This repo contains a Dockerfile that builds a Fedora-based container that includes the latest release tag from the AWX operator repository, the `kubectl` command, and a few other niceties to make it easy to just run the container to have the AWX Operator deployed for you.

**Note**: This container used to be based on the `make deploy` command, which was CPU architecture dependent.  However, it now uses `kustomize` which can run on amd64 or aarch64 CPUs natively.

## How-To

### Building the Container

In order to build this container, you can run the following to build locally and push to your container registry.

```bash
docker buildx build \
--platform linux/amd64,linux/arm64 \
-t $REGISTRY/m1-awx-operator-runner:latest \
--push .
```

### Running the Container

You may build this container yourself.  However, it is also [hosted](quay.io/scottharwell/m1-awx-operator-runner) for you to pull down on Docker hosts (Mac, Linux, Windows) on both `amd64` and `arm64` architectures.

When running the following `docker run` command, it will operate functionally the same as if you were running `kustomize` from the AWX Operator repo on your local machine.  The operator will be at the latest version as of the time that the container was last built, which occurs once per day.

Be sure that you properly mount your K8s config file so that the AWX operator will be able to deploy to your cluster.

```bash
docker run \
-it \
--rm \
--name awx-operator-runner \
--mount type=bind,source="$HOME/.kube/config",target=/home/awx/.kube/config \
quay.io/scottharwell/m1-awx-operator-runner:latest
```

If you want to enter the container and update the commit used from the AWX operator git repo or perform some other task, then you may run the following to be dropped into a Bash shell.  You only need to use this command if you want to perform some operation within the container itself.  The former command works as a one-liner.

```bash
docker run -it \
--rm \
--name awx-operator-runner \
--mount type=bind,source="$HOME/.kube/config",target=/home/awx/.kube/config \
--entrypoint /bin/bash \
quay.io/scottharwell/m1-awx-operator-runner:latest
```

You may then run either of the commands offered to deploy the latest version of the AWX operator; you only need to run one of them.