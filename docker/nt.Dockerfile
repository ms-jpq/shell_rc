FROM mcr.microsoft.com/windows/servercore:ltsc2022

WORKDIR /
COPY ./layers/nt/winget.ps1 ./
ENV DOCKER=1
RUN powershell -File winget.ps1
