# Use multi-stage builds for architecture-specific images
FROM alpine:3.15 AS base

# Set non-interactive mode for container build
ENV DEBIAN_FRONTEND=noninteractive

# Dockerfile ARG variables for architecture
ARG TARGETARCH

# Install required packages (latest versions)
RUN apk --no-cache add \
    bash \
    curl \
    git \
    gcc \
    libc-dev \
    libffi-dev \
    linux-headers \
    musl-dev \
    openssl \
    python3 \
    py3-pip \
    sudo \
    whois \
    p7zip \
    less \
    make

# Configure en_US.UTF-8 Locale
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Define non-root user
ARG USERNAME=devops
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set up non-root user with sudo privilege
RUN addgroup -g $USER_GID $USERNAME && \
    adduser -D -u $USER_UID -G $USERNAME -s /usr/bin/pwsh $USERNAME && \
    echo "$USERNAME ALL=(root) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME

FROM base AS linux-amd64
ARG DOTNET_ARCH=x64
ARG PS_ARCH=x64

FROM base AS linux-arm64
ARG DOTNET_ARCH=arm64
ARG PS_ARCH=arm64

FROM linux-${TARGETARCH} AS msft-install

USER root

# Microsoft .NET Core 3.1 Runtime for VMware PowerCLI
ARG DOTNET_VERSION=3.1.32
ARG DOTNET_PACKAGE=dotnet-runtime-${DOTNET_VERSION}-linux-${DOTNET_ARCH}.tar.gz
ARG DOTNET_PACKAGE_URL=https://dotnetcli.azureedge.net/dotnet/Runtime/${DOTNET_VERSION}/${DOTNET_PACKAGE}
ENV DOTNET_ROOT=/opt/microsoft/dotnet/${DOTNET_VERSION}
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
ADD ${DOTNET_PACKAGE_URL} /tmp/${DOTNET_PACKAGE}
RUN mkdir -p ${DOTNET_ROOT} \
    && tar zxf /tmp/${DOTNET_PACKAGE} -C ${DOTNET_ROOT} \
    && rm /tmp/${DOTNET_PACKAGE}
    
ENTRYPOINT ["/bin/sh"]
# PowerShell Core 7.2 (LTS) - forcing to install exact version
ENV PS_MAJOR_VERSION=7.2.0
RUN echo "PowerShell Major Version: ${PS_MAJOR_VERSION}" \
&& PS_INSTALL_FOLDER=/opt/microsoft/powershell/${PS_MAJOR_VERSION} \
&& PS_PACKAGE=powershell-${PS_MAJOR_VERSION}-linux-${PS_ARCH}.tar.gz \
&& PS_PACKAGE_URL=https://github.com/PowerShell/PowerShell/releases/download/v${PS_MAJOR_VERSION}/${PS_PACKAGE} \
&& echo "PowerShell Package: ${PS_PACKAGE}" \
&& echo "PowerShell Package URL: ${PS_PACKAGE_URL}" \
&& curl -LO ${PS_PACKAGE_URL} \
&& mkdir -p ${PS_INSTALL_FOLDER} \
&& tar zxf ${PS_PACKAGE} -C ${PS_INSTALL_FOLDER} \
&& chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
&& ln -sf ${PS_INSTALL_FOLDER}/pwsh /bin/pwsh \
&& rm ${PS_PACKAGE} \
&& echo /bin/pwsh >> /etc/shells

RUN ls -lah /bin/pwsh \
    && ls -lah ${PS_INSTALL_FOLDER}/pwsh

# Check installed versions of .NET and PowerShell
RUN pwsh -Command "Write-Output \$PSVersionTable" \
    && /opt/microsoft/powershell/7.2.0/pwsh -Command "dotnet --list-runtimes" \
    && /opt/microsoft/powershell/7.2.0/pwsh -Command "\$DebugPreference='Continue'; Write-Output 'Debug preference set to Continue'"
    
FROM msft-install AS vmware-install-arm64

FROM msft-install AS vmware-install-amd64

FROM vmware-install-${TARGETARCH} AS vmware-install-common

# Add .NET to PATH
ENV DOTNET_ROOT=/opt/microsoft/dotnet/3.1.32
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools

ENTRYPOINT ["/bin/sh"]
# Install VMware PowerCLI 7.2
ARG POWERCLIURL=https://vdc-download.vmware.com/vmwb-repository/dcr-public/02830330-d306-4111-9360-be16afb1d284/c7b98bc2-fcce-44f0-8700-efed2b6275aa/VMware-PowerCLI-13.0.0-20829139.zip
ARG POWERCLI_PATH="/usr/local/share/powershell/Modules"
ADD ${POWERCLIURL} /tmp/VMware-PowerCLI-13.0.0-20829139.zip
RUN mkdir -p $POWERCLI_PATH \
    && pwsh -Command "Expand-Archive -Path /tmp/VMware-PowerCLI-13.0.0-20829139.zip -DestinationPath $POWERCLI_PATH" \
    && rm /tmp/VMware-PowerCLI-13.0.0-20829139.zip 

# Install Python libraries
RUN python3 -m pip install --no-cache-dir six psutil lxml pyopenssl

# Setting up and "import" VMware.PowerCLI to $USERNAME
ARG VMWARECEIP=false
RUN pwsh -Command "Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP \$${VMWARECEIP} -Confirm:\$false" \
    && pwsh -Command "Set-PowerCLIConfiguration -PythonPath /usr/bin/python3.7 -Scope User -Confirm:\$false"

# Installing ESXi-Customizer-PS from https://v-front.de
RUN git clone https://github.com/VFrontDe-Org/ESXi-Customizer-PS /home/$USERNAME/files/ESXi-Customizer-PS

# Clean up
USER root
RUN apk del --purge \
    gcc \
    libc-dev \
    libffi-dev \
    linux-headers \
    musl-dev \
    make \
    && rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Switch back to non-root user
USER $USERNAME

# Setting entrypoint to PowerShell
ENTRYPOINT ["pwsh"]
