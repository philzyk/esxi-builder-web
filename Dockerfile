# Use multi-stage builds for architecture-specific images
# Use a base image for Windows Server Core
FROM mcr.microsoft.com/windows/servercore:ltsc2022 AS base

# Set architecture-specific variables
ARG PYTHON_VERSION=3.7.9

# Install PowerShell, Python, and PowerCLI
RUN powershell -Command \
    # Install Windows features
    Install-WindowsFeature -Name Web-Server, Web-WebServer, Net-Framework-Features, Net-Framework-Core, NET-Framework-4.8-Features; \
    # Install Chocolatey (Package manager)
    Set-ExecutionPolicy Bypass -Scope Process -Force; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; \
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')); \
    # Install Python 3.7.9
    choco install python --version=$env:PYTHON_VERSION -y; \
    # Install PowerShell Core
    choco install pwsh -y; \
    # Clean up temporary files
    Remove-Item -Recurse -Force C:\Temp\*

# Set environment variables for Python
ENV PYTHON_HOME="C:\Users\ContainerUser\AppData\Local\Programs\Python\Python37"
ENV PATH="$PYTHON_HOME;${PYTHON_HOME}\Scripts;${PATH}"

# Install necessary Python packages
RUN powershell -Command \
    # Install the required Python packages using pip
    Start-Process -FilePath "$PYTHON_HOME\Scripts\pip3.7.exe" -ArgumentList "install", "six", "psutil", "lxml", "pyopenssl" -NoNewWindow -Wait

# Install PowerCLI
RUN powershell -Command \
    # Install PowerCLI module
    Install-Module -Name VMware.PowerCLI -AllowClobber -Scope AllUsers -Force -SkipPublisherCheck; \
    # Configure PowerCLI for running without user prompt
    Set-PowerCLIConfiguration -Scope User -InvalidCertificateAction Ignore -Confirm:$false; \
    # Clean up the PowerShell session
    Remove-Module VMware.PowerCLI

# Set environment variables for PowerShell
ENV PSModulePath="C:\Program Files\PowerShell\Modules;$env:PSModulePath"
ENV PATH="C:\Program Files\PowerShell\7;$env:PATH"

# Verify Python and PowerShell installation
RUN python --version && pwsh --version

# Set default shell to PowerShell Core
SHELL ["pwsh", "-Command"]

# Set working directory
WORKDIR /app

# Optional: Copy your project files into the container
COPY . /app

# Expose any required ports (e.g., for web apps or APIs)
EXPOSE 80

# Set the command to run when the container starts
CMD ["pwsh"]