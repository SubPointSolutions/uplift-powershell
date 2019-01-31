FROM mcr.microsoft.com/powershell:centos-7

# https://dotnet.microsoft.com/download/linux-package-manager/ubuntu16-04/sdk-current
RUN rpm -Uvh https://packages.microsoft.com/config/rhel/7/packages-microsoft-prod.rpm

RUN yum install -y dotnet-sdk-2.2

RUN pwsh -c "Install-Module -Name InvokeBuild -Force" 
RUN pwsh -c "Install-Module -Name Pester -Force" 

RUN yum install -y wget tar \
    && yum clean all
    
RUN wget http://nodejs.org/dist/v10.2.1/node-v10.2.1-linux-x64.tar.gz 
RUN tar --strip-components 1 -xzvf node-v* -C /usr/local

RUN node --version \
    && npm install http-server -g

WORKDIR /app