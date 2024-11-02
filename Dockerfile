FROM jenkins/jenkins:lts-jdk17
# if we want to install via apt
USER root

# Update the image
RUN apt-get update 

# Set working directory
WORKDIR /opt

# Copy Oracle JDK 11 tarball, must be obtained from Oracle
COPY jdk-11.0.25_linux-x64_bin.tar.gz /opt/

# Extract JDK
RUN tar -xvzf jdk-11.0.25_linux-x64_bin.tar.gz

# Change owner 
RUN chown -R root:jenkins /opt/jdk-11.0.25

# Permission JDK
RUN chmod -R 750 /opt/jdk-11.0.25

# Create soft link to alais as /opt/jdk11
RUN ln -s /opt/jdk-11.0.25 /opt/jdk11

# Remove the tarball
RUN rm jdk-11.0.25_linux-x64_bin.tar.gz

# drop back to the regular jenkins user - good practice
USER jenkins

