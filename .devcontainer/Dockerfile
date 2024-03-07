FROM mcr.microsoft.com/devcontainers/universal:2-linux

ARG BICEP_VERSION=latest

# Install Bicep [requires elevated permissions]
 RUN curl -Lo /tmp/bicep https://github.com/Azure/bicep/releases/${BICEP_VERSION}/download/bicep-linux-x64 \
    && chmod +x /tmp/bicep \
    && mv /tmp/bicep /usr/local/bin/bicep

# Install mosquitto client
RUN apt-get update && apt-get install mosquitto-clients -y

# Install Inotifytools
RUN apt-get update && apt-get install inotify-tools -y

# Install NSS-myhostname
RUN apt-get update && sudo apt-get install libnss-myhostname

# Install Step CLI
RUN wget https://dl.smallstep.com/gh-release/cli/docs-cli-install/v0.23.4/step-cli_0.23.4_amd64.deb && \
    sudo dpkg -i step-cli_0.23.4_amd64.deb && \
    rm ./step-cli_0.23.4_amd64.deb

# Install mqttui
RUN wget https://github.com/EdJoPaTo/mqttui/releases/download/v0.19.0/mqttui-v0.19.0-x86_64-unknown-linux-gnu.deb && \
    sudo apt-get install ./mqttui-v0.19.0-x86_64-unknown-linux-gnu.deb && \
    rm -rf ./mqttui-v0.19.0-x86_64-unknown-linux-gnu.deb
