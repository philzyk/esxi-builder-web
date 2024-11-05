FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build-x64
WORKDIR /app
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o out

# Build stage for arm64
FROM mcr.microsoft.com/dotnet/sdk:3.1 AS build-arm64
WORKDIR /app
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o out

# Runtime stage for x64
FROM mcr.microsoft.com/powershell:7.2-alpine-x64
WORKDIR /app
COPY --from=build-x64 /app/out .
ENTRYPOINT ["pwsh"]

# Runtime stage for arm64
FROM mcr.microsoft.com/powershell:7.2-alpine-arm64v8
WORKDIR /app
COPY --from=build-arm64 /app/out .
ENTRYPOINT ["pwsh"]
