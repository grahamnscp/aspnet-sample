# escape=`
# =========================================================================
# BUILD IMAGE
# =========================================================================
FROM microsoft/dotnet-framework:4.7.2-sdk AS builder

# This installs the WebBuildTools for proper building of ASP.NET projects
RUN Invoke-WebRequest -Uri "https://download.visualstudio.microsoft.com/download/pr/12210059/e64d79b40219aea618ce2fe10ebd5f0d/vs_BuildTools.exe" `
		-OutFile vs_BuildTools.exe; `
	Start-Process -FilePath "vs_BuildTools.exe" `
		-ArgumentList '--add', 'Microsoft.VisualStudio.Workload.WebBuildTools', '--quiet', '--norestart', '--nocache' `
		-Wait `
		-NoNewWindow; `
	Remove-Item -Force vs_buildtools.exe; `
    Remove-Item -Force -Recurse ${env:ProgramFiles(x86)}'/Microsoft Visual Studio/Installer'; `
    Remove-Item -Force -Recurse ${Env:TEMP}/*

WORKDIR /AppBuild
COPY . .

# Restore the NuGet packages
RUN nuget restore 

# Build the solution
RUN msbuild /t:Clean,Build /p:DeployOnBuild=true /p:PublishProfile=Docker

# =========================================================================
# APP IMAGE
# =========================================================================
FROM microsoft/aspnet
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Remove-Website 'Default Web Site';

# Create a directory for the app
ENV app_path="C:\MyApp"
RUN New-Item -Path $env:app_path -Type Directory -Force; 

# Copy the files from the build image to the app directory
COPY --from=builder "\AppBuild\WebApp\bin\Release\Docker" ${app_path}

# Create a Website in IIS
RUN New-Website -Name 'MyApp' -PhysicalPath $env:app_path -Port 80; 

# Add IIS_IUSRS to the directory's ACL.
RUN $acl = Get-Acl $env:app_path; `
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule('IIS_IUSRS','ReadAndExecute', 'ContainerInherit, ObjectInherit', 'None', 'Allow'); `
    $acl.AddAccessRule($rule); `
    Set-Acl -Path $env:app_path -ACLObject $acl

EXPOSE 80