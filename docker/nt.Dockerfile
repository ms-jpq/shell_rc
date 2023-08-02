FROM mcr.microsoft.com/powershell:latest

WORKDIR /
COPY ./layers/nt/winget.ps1 ./
RUN .\winget.ps1
