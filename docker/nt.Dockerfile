FROM mcr.microsoft.com/windows/nanoserver:ltsc2022

RUN winget install --accept-package-agreements --accept-source-agreements --id stedolan.jq
