---
title: Build Scala applicationn using Jenkins pipelines inside Docker
---

Recently I run into the need to run Jenkins pipelines locally to produce a proof of concept. And so I
decided to run it in Docker as it should be easier and cleaner. However this text could also be applicable
when running Jenkins hosts inside a container for other reasons, like using a cloud deployment infrastructure.

Soon I realised that I was going to need Docker inside the Jenkins container in order to build the
Docker images I wanted as artifacts for my application. Due to my lack of knowledge in both Jenkins
and Docker I was in for a bumpy ride and many hours of frustration.

The aim of this post if to summarise my findings and the approach I took so it can serve as a guide
for the future or for other people that may find the same problem.

**Disclaimer:** I am, by no means an expert, I have tried my best to make this guide clear and accurate, but
please use any commands or code here with caution as you should do with any unknown code from the internet.

## Preamble: Have a Docker installation working on your environment

I won't cover this here, suffice to say that you should have Docker installed and some familiarity
with the common commands.

## First act: Install Jenkins with Docker

`docker pull jenkins:2.46.3-alpine`

This downloads the Jenkins image we plan to use, `alpine` means it will use the Linux Alpine distribution
which is more lightweight and meets my needs.

`docker run -d -u root --name jenkins-mapped -p 8089:8080 -p 50000:50000 -v ~/jenkins-root:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock jenkins:2.46.3-alpine`

What are we really doing here?

- Docker run creates and starts a new container from the specified Docker image
- -u root
- --name jenkins-mapped: Gives the name `jenkins-mapped` to the instance, if you don't specify this Docker
will come up with funny names for you.
- -p 8089:8080 -p 50000:50000: Maps the ports 8089 from your actual machine to the port 8080 on the container (web) and the same for port 50000 (slave management). I had to map it to 8089 as 8080 was already being used, but adjust this to your needs.
- -v ~/jenkins-root:/var/jenkins_home: Maps `~/jenkins-root` from your machine to `/var/jenkins_home` on the container. This will create a volume where Jenkins will store some of it's configuration so it's persisted when you realise that something is not quire right in your image and you have to create it again.
- -v /var/run/docker.sock:/var/run/docker.sock: Maps the `docker.sock` file from your machine to the container



## First Recess: Why do we map `/var/run/docker.sock`

For what we are concerned right now, Docker is composed of two components, a daemon, which is doing all the
heavy lifting and a client, which will interpret your commands and communicate with the daemon.

The daemon can be configured to receive connections on different methods, the default is via `/var/run/docker.sock`,
but it also supports communication via tcp and fd (more on
[reference](https://docs.docker.com/engine/reference/commandline/dockerd/#extended-description))

The fact that we are sharing as a volume the socket means that any Docker client inside the container
will be able to access Docker running on the host machine. It is worth noting that this is an unsecure approach,
as the container can gain root access on the host machine, if there are security concerns, there are other options
[Secure Docker daemon](https://docs.docker.com/engine/security/https/).

### Docker within Docker

There is another approach which could work, run an image which contains both the Docker daemon and Jenkins,
however this is easier said than done, if you want to explore this approach
[this Docker image](https://hub.docker.com/_/docker/) can be a good place to start.

## First act: Configure plugins

For this example we will need `sbt plugin` and `Docker Plugin` apart from the default plugins.

On Jenkins, go to `Manage Jenkins` -> Manage Plugins

Then go to the `Available` tab, search for both plugins and install them (no need to restart).

### Configure Docker as cloud (I believe this step is only required if you want your workers to run on Docker)

Go to `Manage Jenkins` -> `Configure System` and at the bottom add a new Docker cloud,
make sure it is set up as follows:

<img src="/images/posts/docker/docker-cloud.png" alt="Docker Cloud config" class="img-80" />

### Configure tools

Go to `Manage Jenkins` -> `Global Tool Configuration` and Set Docker and Sbt installations as follows:

<img src="/images/posts/docker/docker-tool.png" alt="Docker Tool config" class="img-80" />
<img src="/images/posts/docker/sbt-tool.png" alt="Sbt Tool config" class="img-80" />


## Second act: Create the Jenkins job

Go to the Jenkins root and click on `New Item`, give it any name you like and select the `Pipeline` type of project.

I would recommend to store the `Jenkinsfile` that configures the pipeline along with the code as this is, in my opinion,
one of the big benefit of using pipelines in the pipelines on the first place. To do that set it up as follows:
<img src="/images/posts/docker/pipeline-config.png" alt="Pipeline config" class="img-80" />

It's also worth mentioning that the [Pipeline syntax](http://localhost:8089/job/pipe/pipeline-syntax/) link at the bottom provides somewhat good documentation on
the actions you can access from the pipeline, especially regarding the [Global Variables Reference](http://localhost:8089/job/pipe/pipeline-syntax/globals).

## Third act: Get to know your pipeline

Before you go any further you should understand how Jenkins works and how
[Pipelines work](https://jenkins.io/doc/pipeline/tour/hello-world/) to save yourself the headache.

I have created a very simple pipeline that uses sbt and docker as tools, I won't get into much
detail as some of it is specific for my application, but it is important to mention that when using
[Sbt Native Packager's Docker plugin](http://www.scala-sbt.org/sbt-native-packager/formats/docker.html)
you should only perform the operation `docker:stage` which will create a `Dockerfile`. This will in turn
be used by the configured Docker tool.

Also, don't forget to wrap the calls to the docker tool with `script` of Jenkins will complaint.


``` groovy
pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                echo "Compiling..."
                sh "${tool name: 'sbt', type: 'org.jvnet.hudson.plugins.SbtPluginBuilder$SbtInstallation'}/bin/sbt compile"
            }
        }
        stage('Unit Test') {
            steps {
                echo "Testing..."
                sh "${tool name: 'sbt', type: 'org.jvnet.hudson.plugins.SbtPluginBuilder$SbtInstallation'}/bin/sbt coverage 'test-only * -- -F 4'"
                sh "${tool name: 'sbt', type: 'org.jvnet.hudson.plugins.SbtPluginBuilder$SbtInstallation'}/bin/sbt coverageReport"
                sh "${tool name: 'sbt', type: 'org.jvnet.hudson.plugins.SbtPluginBuilder$SbtInstallation'}/bin/sbt scalastyle || true"
            }
        }
        stage('Docker Publish') {
            steps {
                // Generate Jenkinsfile and prepare the artifact files.
                sh "${tool name: 'sbt', type: 'org.jvnet.hudson.plugins.SbtPluginBuilder$SbtInstallation'}/bin/sbt docker:stage"

                // Run the Docker tool to build the image
                script {
                    docker.withTool('docker') {
                        docker.build('my-app:latest', 'target/docker/stage')
                    }
                }
            }
        }
        ... Other Steps ...
    }
}

```

## Ending

profit from your efforts and see it going green.

<img src="/images/posts/docker/pipeline-run.png" alt="Pipeline running" class="img-80" />

Admittedly, my pipeline still requires a lot of work, but it can build my Scala code,
pass a bunch of Unit Tests and create a Docker image. With very little effort I should
be able to upload this image and from there my idea would be to deploy it on a CI host
and run further automated testing on it.

I am hopeful that this will someday make my and my colleagues days easier.

**Please leave any comments if you have suggestions or if I'm doing something terribly wrong.**