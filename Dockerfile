# This builds a docker image for that forces use of amd64 architecture to deploy the AWX operator since it does not support ARM
FROM --platform=linux/amd64 quay.io/fedora/fedora:35

ARG USERNAME=awx
ARG USERCOMMENT="AWX Deployment Account"
ARG USERID=1000
ARG GROUPID=1000
ARG OMF_INSTALLER="https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install"
ARG VIMRC_REPO="https://github.com/amix/vimrc.git"
ARG AWX_REPO="https://github.com/ansible/awx-operator.git"

# Upgrade packages and install new packages
RUN dnf upgrade -y
RUN python3 -m ensurepip --upgrade
RUN dnf install -y gcc make git fish wget util-linux util-linux-user which vim powerline powerline-fonts vim-powerline

# Install Kubectl
COPY kubernetes.repo /etc/yum.repos.d/kubernetes.repo
RUN dnf install -y kubectl

# Create user
RUN groupadd --gid ${GROUPID} $USERNAME
RUN useradd --comment "${USERCOMMENT}" --gid ${GROUPID} --uid ${USERID} -p $USERNAME -G wheel -s /usr/bin/fish -m $USERNAME

# Allow wheel to perform sudo actions with no password
RUN sed -e 's/^%wheel/#%wheel/g' -e 's/^# %wheel/%wheel/g' -i /etc/sudoers

# Set default user
USER $USERNAME:$USERNAME
SHELL ["/usr/bin/fish","-c"]

# Set workdir to user home
WORKDIR /home/$USERNAME

# Install Pypi packages for user
RUN mkdir -p /home/$USERNAME/.local/bin
RUN python3 -m pip install --upgrade pip
RUN set -U fish_user_paths /home/$USERNAME/.local/bin

# Create Fish Shell configs
RUN mkdir -p /home/$USERNAME/.config/fish
COPY .config/fish/. /home/$USERNAME/.config/fish/
RUN sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.config

# Install OMF and Themes
RUN wget $OMF_INSTALLER -P /tmp/
RUN chmod 755 /tmp/install
RUN /tmp/install --noninteractive --yes
RUN omf install bobthefish
RUN set -Ux theme_color_scheme solarized-dark

# Install VIM Configs
RUN git clone --depth=1 $VIMRC_REPO /home/$USERNAME/.vim_runtime
RUN /home/$USERNAME/.vim_runtime/install_awesome_vimrc.sh
COPY .vim_runtime/my_configs.vim /home/$USERNAME/.vim_runtime/my_configs.vim
RUN sudo chown $USERNAME:$USERNAME /home/$USERNAME/.vim_runtime/my_configs.vim

# Create a kube config folder
RUN mkdir /home/$USERNAME/.kube
RUN chmod 700 /home/$USERNAME/.kube
RUN sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/.kube

# Clone AWX Operator Repo
RUN git clone $AWX_REPO /home/$USERNAME/awx-operator

# Checkout the latest release
WORKDIR /home/$USERNAME/awx-operator
RUN git checkout (git describe --tags --abbrev=0) &> /dev/null

# Set the entrypoint to auto-call `make deploy`
ENTRYPOINT ["/usr/bin/make","deploy"]