# Jenkins Docker Study
[Github](https://github.com/JeffKernsGitHub/Custom-Jenkins-Docker)

## Purpose

A customer was interested in Containerization so I performed this study to create and deploy Jenkins in a Docker container.

## Goals

### Scope

- Create a Docker Image based on the current Jenkins stable image and add the customer required Oracle JDK 11 which was required by the customer.

- Create a Docker Volume for the container to use that is detached from the container that allows Jenkins to be upgraded and reattached to it's Jenkins home.

- Deploy the developed container and have it work.

### Next Steps

Outside of this simple study and topics for other studies:

- [Kubernetes](https://kubernetes.io/) or image repositories were not used.

- No attempt was made to host using SSL/TLS. The focus was on containerization.

-  No hardening or image static analysis was performed.

## Tools Used
[VSCodium with Docker Extension](https://vscodium.com/)

[Docker Desktop (development), Docker Engine (Server)](https://www.docker.com/)

[Oracle VirtualBox to guest Fedora Server](https://www.virtualbox.org/)

[Fedora Server 41](https://fedoraproject.org/server/)

## Building
Used the VSCodium Docker extension to build the Dockerfile into an Image.

### Create Volume
Created the Docker Volume in Docker Desktop. Alternatively:
```bash
docker volume create jenkins-data
```

### Create Container
Created the container by running the Image from Docker Desktop with the following options:

- Mapped port 8080:8080

- Mapped /var/jenkins_home to the jenkins-data volume

- Gave the container a reasonable name: customjenkinsdocker:latest

Note: Server installation section provides a CLI example

I verified that the Volume populated and restarted the Container and verified that changes held.

## Packaging and Deployment

### Server Creation

In VirtualBox, created a Fedora Server 41 guest:

- 6G RAM

- 40G Disk

- Port forwarded host 2222 to guest 22

- Port forwarded host 8080 to guest 8080

 Updated dnf and installed the Docker Engine per current documentation.

### Export Volume and Container for transfer to another server 

I stopped the running container for these steps.
 
#### Backup Volume

##### Create Temporary Container with the Volume mounted

Docker Desktop terminal was used in this step.

Created a temporary container with the jenkins-data volume mounted.

This command created a Ubuntu container named sample-container with the jenkins-data volume mapped as /data. In hindsight, adding the --rm option may have been advised so it would have self-cleaned.

```bash
run -d --name sample-container -v jenkins-data:/data ubuntu
```

Created a tarball with the Volume's Contents

- it attaches to the created sample-container

- my home folder is mapped to a /backup-dir alias 

- a jenkins-data.tar.gz tarball was created in my home, not in a subdirectory

```bash
run --rm --volumes-from sample-container -v /home/jeffkerns:/backup-dir ubuntu tar cvzf /backup-dir/jenkins-data.tar.gz /data
```


##### Backup the Jenkins Container

Docker Desktop terminal was used in this step.

Listed all Containers 

```
docker ps -a
CONTAINER ID   IMAGE                        COMMAND                  CREATED       STATUS                        PORTS     NAMES
940d03cd0ea0   customjenkinsdocker:latest   "/usr/bin/tini -- /u…"   7 hours ago   Exited (143) 34 minutes ago             MyJenkins
```

Committed the Image to the Docker repository

```
jeffkerns@cyberdeck:~$ docker commit -p 940d03cd0ea0 jenkins-02nov2024
sha256:64821ea5b0c10bd054e800b5c068436856de235aecd61fb3856743a9ca13ff37
```

Exported the image to a tarball 

```bash
docker save -o  jenkins-02nov2024.tar jenkins-02nov2024
```

### Restore the container and volume tarballs on the Fedora Server

#### Copy the tarballs to the server

This step was performed in a local terminal.

```bash
scp -P 2222 jenkins-02nov2024.tar root@127.0.0.1:/root
scp -P 2222 jenkins-data.tar.gz root@127.0.0.1:/root
``` 


#### Restore the Volume

This step was performed shelled into the server.

First, I created a docker Volume on the server. Then, I extracted the tarball into the volume using essentially the reverse process of creating the backup.

```bash
docker volume create jenkins-data

docker run --rm -v jenkins-data:/data -v $(pwd):/backup-dir ubuntu tar xvzf /backup-dir/jenkins-data.tar.gz -C /
```

#### Restore the Container

This step was performed shelled into the server.

Created an Image from the tarball.

```
root@vbox:~# docker load -i ./jenkins-02nov2024.tar
ef5f5ddeb0a6: Loading layer  121.3MB/121.3MB
cc3c7877ef26: Loading layer  150.2MB/150.2MB
7d90e87f145f: Loading layer  16.91MB/16.91MB
efa5a096ee31: Loading layer  14.85kB/14.85kB
21f24d2ac7a0: Loading layer  3.584kB/3.584kB
d901670ea5a8: Loading layer  96.01MB/96.01MB
845bbff1e71e: Loading layer  3.584kB/3.584kB
fec682463a4b: Loading layer  6.947MB/6.947MB
492e45f46c62: Loading layer  89.27MB/89.27MB
9eb43d67e198: Loading layer  9.728kB/9.728kB
4da2a108d7ce: Loading layer  5.632kB/5.632kB
1da50c4fefa1: Loading layer  3.072kB/3.072kB
60e9d9430e3f: Loading layer  19.51MB/19.51MB
5f70bf18a086: Loading layer  1.024kB/1.024kB
1e6f4ed44200: Loading layer    169MB/169MB
56768139c5a3: Loading layer  283.5MB/283.5MB
3c534a91ace7: Loading layer  283.5MB/283.5MB
57507805a4d4: Loading layer  283.4MB/283.4MB
cedd87f5278c: Loading layer   2.56kB/2.56kB
e55f473afcc8: Loading layer   2.56kB/2.56kB
85e9a648cbf7: Loading layer  2.048kB/2.048kB
Loaded image: jenkins-02nov2024:latest
```

Viewed the installed images and deleted the temporary Ubuntu image.

```
root@vbox:~# docker images
REPOSITORY          TAG       IMAGE ID       CREATED          SIZE
jenkins-02nov2024   latest    64821ea5b0c1   31 minutes ago   1.51GB
ubuntu              latest    59ab366372d5   3 weeks ago      78.1MB

root@vbox:~# docker rmi 59ab366372d5
Untagged: ubuntu:latest
Untagged: ubuntu@sha256:99c35190e22d294cdace2783ac55effc69d32896daaa265f0bbedbcde4fbe3e5
Deleted: sha256:59ab366372d56772eb54e426183435e6b0642152cb449ec7ab52473af8ca6e3f
Deleted: sha256:a46a5fb872b554648d9d0262f302b2c1ded46eeb1ef4dc727ecc5274605937af
root@vbox:~# docker images
REPOSITORY          TAG       IMAGE ID       CREATED          SIZE
jenkins-02nov2024   latest    64821ea5b0c1   34 minutes ago   1.51GB

```

#### Started the Container and Tested



```
root@vbox:~# docker run \
  --name jenkins-docker \
  --rm \
  --detach \
  --volume jenkins-data:/var/jenkins_home \
  --publish 8080:8080 \
  jenkins-02nov2024:latest

5e0e64bf3ff7e20931cf45d4b8c19813683da7013dd3211189181d4252c9ace5

```

Logged into the server's Jenkins and verified that the Jenkins home and settings was retained. Success.



