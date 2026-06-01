# syntax=docker/dockerfile:1.7
# =============================================================================
# Hardened multi-stage build for ComicRealmBE.
#   - Build stage uses the full SDK image (discarded).
#   - Runtime stage uses Microsoft's distroless chiseled ASP.NET image:
#       * no shell, no package manager, no curl/wget,
#       * runs as the non-root `app` user (uid 64198) by default,
#       * contains only the .NET runtime + ICU/tzdata.
#   - A statically-linked wget binary from busybox is copied in solely to
#     support the Docker HEALTHCHECK; it carries no runtime privileges.
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

# ---------- health-check tool ----------
# busybox is statically linked — no libc dependency — so it works inside
# the distroless chiseled runtime image where curl/wget are absent.
FROM busybox:stable AS busybox

# ---------- runtime (alpine, non-root) ----------
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS final
WORKDIR /app
COPY --from=build --chown=app:app /app/publish .

USER app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080 \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_EnableDiagnostics=0
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget -q --spider http://localhost:8080/health || exit 1
ENTRYPOINT ["dotnet", "ComicRealmBE.dll"]
