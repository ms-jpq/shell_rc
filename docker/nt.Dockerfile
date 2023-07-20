FROM mcr.microsoft.com/windows/nanoserver:ltsc2022

RUN winget --disable-interactivity install --accept-package-agreements --accept-source-agreements --id stedolan.jq
