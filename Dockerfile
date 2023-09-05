# syntax=docker/dockerfile:1.3-labs
FROM quay.io/fedora/fedora:38

ARG TARGETARCH
ARG USERNAME=awx
ARG USERCOMMENT="AWX Deployment Account"
ARG USERID=1000
ARG GROUPID=1000
ARG AWX_REPO="https://github.com/ansible/awx-operator.git"

# Upgrade packages and install new packages
RUN dnf upgrade -y
RUN python3 -m ensurepip --upgrade
RUN dnf install -y git wget util-linux util-linux-user which vim

# Install Kubectl
COPY kubernetes_${TARGETARCH}.repo /etc/yum.repos.d/kubernetes.repo
RUN dnf install -y kubectl
RUN cd /usr/bin && curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# Create user
RUN groupadd --gid ${GROUPID} $USERNAME
RUN useradd --comment "${USERCOMMENT}" --gid ${GROUPID} --uid ${USERID} -p $USERNAME -G wheel -s /bin/bash -m $USERNAME

# Allow wheel to perform sudo actions with no password
RUN sed -e 's/^%wheel/#%wheel/g' -e 's/^# %wheel/%wheel/g' -i /etc/sudoers

# Set default user
USER $USERNAME:$USERNAME
SHELL ["/bin/bash","-c"]

# Set workdir to user home
WORKDIR /home/$USERNAME

# Install Pypi packages for user
RUN mkdir -p /home/$USERNAME/.local/bin
RUN python3 -m pip install --upgrade pip
RUN echo "export PATH=\$PATH:/home/$USERNAME/.local/bin" >> /home/$USERNAME/.bash_profile

# Create a kube config folder
RUN mkdir /home/$USERNAME/.kube
RUN chmod 700 /home/$USERNAME/.kube
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

# Clone AWX Operator Repo
RUN git clone $AWX_REPO /home/$USERNAME/awx-operator

# Checkout the latest release
WORKDIR /home/$USERNAME/awx-operator
RUN <<EOF 
echo $(git describe --tags --abbrev=0) > .tag
git checkout $(cat .tag) &> /dev/null
echo "apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  # Find the latest tag here: https://github.com/ansible/awx-operator/releases
  - github.com/ansible/awx-operator/config/default?ref=$(cat .tag)

# Set the image tags to match the git version from above
images:
  - name: quay.io/ansible/awx-operator
    newTag: $(cat .tag)

# Specify a custom namespace in which to install AWX
namespace: awx" > kustomization.yaml
EOF
RUN kustomize build .

# Set user to non-root
USER 1000

# Set the entrypoint to auto-call `kubectl apply -f -`
ENTRYPOINT ["/usr/bin/kubectl","apply","-k","./"]