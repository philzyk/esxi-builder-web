# Use multi-stage builds for architecture-specific images
FROM alpine:3.17 AS base

# Set non-interactive mode for container build
ENV DEBIAN_FRONTEND=noninteractive

# Dockerfile ARG variables for architecture
ARG TARGETARCH

# Install required packages (latest versions)
RUN apk --no-cache add \
    #bash \
    #bash-completion \
    #curl \
    #git \
    #gcc \
    #libc-dev \
    #libffi-dev \
    #linux-headers \
    #musl-dev \
    #openssl \
    #python3 \
    #py3-pip \
    #sudo \
    #whois \
    #p7zip \
    #less \
    #make \
    #ca-certificates \
    #less \
    #ncurses-terminfo-base \
    #krb5-libs \
    #libgcc \
    #libintl \
    #libssl1.1 \
    #libstdc++ \
    #tzdata \
    #userspace-rcu \
    #zlib \
    #icu-libs \
    #libc6-compat \
    #libssl3 

    bash \
    bash-completion \
    curl \
    git \
    gcc \
    libc-dev \
    libffi-dev \
    linux-headers \
    musl-dev \
    python3 \
    py3-pip \
    sudo \
    whois \
    p7zip \
    less \
    make \
    ca-certificates \
    ncurses-terminfo-base \
    krb5-libs \
    libgcc \
    libintl \
    libssl1.1 \
    libstdc++ \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs \
    libc6-compat \
    libssl3

# Install glibc
RUN ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    ALPINE_GLIBC_PACKAGE_VERSION="2.35-r0" && \
    curl -Lo /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    curl -Lo /tmp/glibc-${ALPINE_GLIBC_PACKAGE_VERSION}.apk ${ALPINE_GLIBC_BASE_URL}/${ALPINE_GLIBC_PACKAGE_VERSION}/glibc-${ALPINE_GLIBC_PACKAGE_VERSION}.apk && \
    apk add --force-overwrite --no-cache /tmp/glibc-${ALPINE_GLIBC_PACKAGE_VERSION}.apk && \
    rm /tmp/glibc-${ALPINE_GLIBC_PACKAGE_VERSION}.apk

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
    adduser -D -u $USER_UID -G $USERNAME -s /bin/sh $USERNAME && \  # Use /bin/sh as a shell
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME && \
    echo /home/$USERNAME/pwsh >> /etc/shells && \  # Ensure pwsh is in the correct place after installation
    cat /etc/shells


USER $USERNAME
WORKDIR /home/$USERNAME

# Setting ARCH ARGs for linux-amd64 & linux-arm64
FROM base AS linux-amd64
ARG ARCH=x64
ARG UID_URL=e94c26b7-6ac0-46b9-81f1-e008ce8348cb/41d57ffacf3e151de8039ec3cd007a68

FROM base AS linux-arm64
ARG ARCH=arm64
ARG UID_URL=2672b266-880f-4ec1-ab89-bcd235c59193/d37f0755df26313e7a7bbf6dbcf9184e

# Install Microsoft .NET Core Runtime
FROM linux-${TARGETARCH} AS msft-install

# Microsoft .NET Core 3.1 Runtime для VMware PowerCLI
ARG USER_TMP=${WORKDIR}/tmp
ARG DOTNET_VERSION=3.1.32
ARG DOTNET_PACKAGE=aspnetcore-runtime-${DOTNET_VERSION}-linux-musl-${ARCH}.tar.gz
ARG DOTNET_PACKAGE_URL=https://download.visualstudio.microsoft.com/download/pr/${UID_URL}/aspnetcore-runtime-${DOTNET_VERSION}-linux-musl-${ARCH}.tar.gz
ENV DOTNET_ROOT=/home/${USERNAME}/dotnet/${DOTNET_VERSION}
ENV PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
RUN mkdir -p ${DOTNET_ROOT} \
    && curl -LO ${DOTNET_PACKAGE_URL} \
    && tar zxf ${DOTNET_PACKAGE} -C ${DOTNET_ROOT} \
    && rm ${DOTNET_PACKAGE}
    
# PowerShell Core 7.2 (LTS) - forcing to install exact version
# Set PowerShell version
ENV PS_VERSION=7.2
ENV PS_INSTALL_FOLDER=/home/${USERNAME}/powershell/${PS_VERSION}
ENV PATH="$PATH:$PS_INSTALL_FOLDER"
RUN PS_MAJOR_VERSION=$(curl -s "https://api.github.com/repos/PowerShell/PowerShell/releases" | grep '"tag_name": "v'${PS_VERSION} | head -1 | sed 's/.*"v\([0-9.]*\)".*/\1/') \
    && echo "PowerShell Major Version: ${PS_MAJOR_VERSION}" \
    && PS_INSTALL_FOLDER=/home/${USERNAME}/powershell/${PS_MAJOR_VERSION} \
    && PS_PACKAGE="powershell-${PS_MAJOR_VERSION}-linux-${ARCH}.tar.gz" \
    && PS_PACKAGE_URL="https://github.com/PowerShell/PowerShell/releases/download/v${PS_MAJOR_VERSION}/${PS_PACKAGE}" \
    && echo "PowerShell Package: ${PS_PACKAGE}" \
    && echo "PowerShell Package URL: ${PS_PACKAGE_URL}" \
    && curl -LO ${PS_PACKAGE_URL} \
    && mkdir -p ${PS_INSTALL_FOLDER} \
    && tar zxf ${PS_PACKAGE} -C ${PS_INSTALL_FOLDER} \
    && chmod a+x,o-w ${PS_INSTALL_FOLDER}/pwsh \
    && ln -sf ${PS_INSTALL_FOLDER}/pwsh /home/${USERNAME}/pwsh \
    && rm ${PS_PACKAGE}

# Check installed versions of .NET and PowerShell
RUN pwsh -Command "Write-Output \$PSVersionTable" \
    && pwsh -Command "dotnet --list-runtimes" \
    && pwsh -Command "\$DebugPreference='Continue'; Write-Output 'Debug preference set to Continue'"
    
FROM msft-install AS vmware-install-arm64

FROM msft-install AS vmware-install-amd64

FROM vmware-install-${TARGETARCH} AS vmware-install-common

# Install VMware PowerCLI 7.2
ARG POWERCLIURL=https://vdc-download.vmware.com/vmwb-repository/dcr-public/02830330-d306-4111-9360-be16afb1d284/c7b98bc2-fcce-44f0-8700-efed2b6275aa/VMware-PowerCLI-13.0.0-20829139.zip
ARG POWERCLI_PATH="/home/${USERNAME}/powershell/Modules"
ADD ${POWERCLIURL} /tmp/VMware-PowerCLI-13.0.0-20829139.zip
RUN mkdir -p $POWERCLI_PATH \
    && pwsh -Command "Expand-Archive -Path /tmp/VMware-PowerCLI-13.0.0-20829139.zip -DestinationPath $POWERCLI_PATH" \
    && rm /tmp/VMware-PowerCLI-13.0.0-20829139.zip 

# Install Python libraries
RUN python3 -m pip install --no-cache-dir six psutil lxml pyopenssl

USER $USERNAME
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
