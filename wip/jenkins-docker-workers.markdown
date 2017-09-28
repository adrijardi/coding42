---
title: Jenkins Docker workers
---

## Create Dockerfile

```
FROM centos:latest
RUN yum install -y rpm-build openssh-server java-1.8.0-openjdk-devel git
```

## Create Docker network

```
docker network create -d bridge jenkins_net
```

## Launch Jenkins on that network

```
docker run -d -u root --name jenkins -p 8089:8080 -p 50000:50000 -v /jenkins-root:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock --net=jenkins_net --hostname=jenkins.local --env JAVA_OPTS="-Djenkins.slaves.DefaultJnlpSlaveReceiver.disableStrictVerification=true" jenkins:2.46.3-alpine
```

## Set the network on Docker Cloud config