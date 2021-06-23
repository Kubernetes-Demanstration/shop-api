
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
# store connectionstring
ARG StoreConnection
# Identity connectionstring
ARG IdentityConnection
WORKDIR /source

# copy csproj and restore as distinct layers
COPY API/*.csproj API/
COPY Core/*.csproj Core/
COPY Infrastructure/*.csproj Infrastructure/
RUN dotnet restore API/API.csproj

# copy and build app and libraries
COPY API/ API/
COPY Infrastructure/ Infrastructure/
COPY Core/ Core/
WORKDIR /source/API
RUN dotnet build -c release --no-restore

# db migration
WORKDIR /source

RUN dotnet ef database update  --connection $StoreConnection --project Infrastructure --startup-project API --context StoreContext

RUN dotnet ef database update  --connection $IdentityConnection --project Infrastructure --startup-project API --context AppIdentityDbContext


# test stage -- exposes optional entrypoint
# target entrypoint with: docker build --target test
# FROM build AS test
# WORKDIR /source/tests
# COPY ERP-API.Test/ .
# ENTRYPOINT ["dotnet", "test", "--logger:trx"]




FROM build AS publish
RUN dotnet publish -c release --no-build -o /app

# final stage/image

FROM mcr.microsoft.com/dotnet/aspnet:5.0
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "API.dll"]