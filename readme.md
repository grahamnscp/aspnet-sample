# ASP.NET Docker Multistage

A simple example of a multistage build Dockerfile for an ASP.NET application. The interesting thing here is the use of a Publish Profile, which requires the installation of WebBuildTools.



## Building the image

Navigate to the solution directory in Powershell. Then:

```
docker image build -t aspnet-sample .
```

## Run the container and browse the app

Start the container:
```
docker run -d -p 8080:80 aspnet-sample
```

Open browser:
```
http://localhost:8080
```
