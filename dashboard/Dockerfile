# Dooja backend (ASP.NET Core MVC dashboard + Web API)
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY src/Dooja.Web/Dooja.Web.csproj src/Dooja.Web/
RUN dotnet restore src/Dooja.Web/Dooja.Web.csproj
COPY src/ src/
RUN dotnet publish src/Dooja.Web/Dooja.Web.csproj -c Release -o /app/publish --no-restore /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
ENV ASPNETCORE_ENVIRONMENT=Production \
    DOTNET_RUNNING_IN_CONTAINER=true \
    Proxy__TrustForwardedHeaders=true
COPY --from=build /app/publish .
EXPOSE 10000
CMD ["sh", "-c", "ASPNETCORE_URLS=http://+:${PORT:-10000} exec dotnet Dooja.Web.dll"]
