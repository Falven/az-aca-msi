# https://hub.docker.com/_/microsoft-dotnet
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /kv

# copy csproj and restore as distinct layers
COPY *.csproj .

# copy and publish app and libraries
COPY . .
RUN dotnet publish -c Release -o /app --use-current-runtime

# final stage/image
FROM mcr.microsoft.com/dotnet/runtime:7.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["tail", "-f", "/dev/null"]