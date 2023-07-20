FROM mcr.microsoft.com/windows/nanoserver:ltsc2022

RUN winget install --disable-interactivity --accept-package-agreements --accept-source-agreements --id stedolan.jq
