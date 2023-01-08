## Start with the version of Kaniko that matches our defined version
ARG KANIKO_VERSION=latest
FROM gcr.io/kaniko-project/executor:${KANIKO_VERSION} as kaniko

# Our base image runtime image
FROM rockylinux:9-minimal

# Install the required packages
RUN microdnf -y update \
    && microdnf install -y curl unzip ca-certificates 
	
# Copy everything over we need from the Kaniko image
RUN mkdir -p /kaniko \
	&& chmod 777 /kaniko
COPY --from=kaniko /kaniko/* /kaniko/
COPY --from=kaniko /kaniko/.docker /kaniko/.docker

# Ensure the execute bits are set appropriatly
RUN chmod +x /kaniko/executor \
	&& chmod +x /kaniko/docker-credential-*

# Rather than use Kaniko's ca-certificate bundle, use the one provided by the ca-certificates package
RUN rm /kaniko/certs/ca-certificates.crt \
	&& ln -sf /etc/ssl/certs/ca-certificates.crt /kaniko/certs/ca-certificates.crt

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && rm -f awscliv2.zip && \
    ./aws/install && rm -rf ./aws

# Set the env vars like Kaniko does, but with our own PATH
ENV HOME /root
ENV USER root
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/kaniko
ENV SSL_CERT_DIR=/kaniko/ssl/certs
ENV DOCKER_CONFIG /kaniko/.docker/
ENV DOCKER_CREDENTIAL_GCR_CONFIG /kaniko/.config/gcloud/docker_credential_gcr_config.json

# Set the workspace and entrypoint like Kaniko does
WORKDIR /workspace
ENTRYPOINT ["/kaniko/executor"]
