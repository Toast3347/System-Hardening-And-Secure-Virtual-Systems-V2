# syntax=docker/dockerfile:1.7
# =============================================================================
# Hardened multi-stage build for ComicRealmBE.
#   - Build stage uses the full SDK image (discarded).
#   - Runtime stage uses Microsoft's distroless chiseled ASP.NET image:
#       * no shell, no package manager, no curl/wget,
#       * runs as the non-root `app` user (uid 64198) by default,
#       * contains only the .NET runtime + ICU/tzdata.
#   - No apt-get, no extra packages, no HEALTHCHECK with shell tools
#     (Kubernetes/compose handle liveness/readiness probes).
# =============================================================================

# ---------- build ----------
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["ComicRealmBE.csproj", "./"]
RUN dotnet restore "ComicRealmBE.csproj"

COPY . .
RUN dotnet publish "ComicRealmBE.csproj" \
        -c $BUILD_CONFIGURATION \
        -o /app/publish \
        /p:UseAppHost=false

# ---------- runtime (distroless / chiseled, non-root) ----------
FROM mcr.microsoft.com/dotnet/aspnet:10.0-noble-chiseled AS final
WORKDIR /app
COPY --from=build --chown=app:app /app/publish .

# `app` is uid 64198 in the chiseled image — set explicitly for clarity.
USER app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_EnableDiagnostics=0
ENTRYPOINT ["dotnet", "ComicRealmBE.dll"]
