FROM debian:bookworm-slim

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && apt-get install -y -q
RUN apt-get update && apt-get install --no-install-recommends -y gpg curl dialog apt-utils ca-certificates

ENV HOME=/home/ciuser
ENV XDG_CONFIG_HOME=/home/ciuser/.config
ENV HELM_CONFIG_HOME=/home/ciuser/.config
ENV HELM_HOME=/home/ciuser/.config/helm

# Install kubectl as per official docs
RUN curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
RUN echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
RUN apt-get update && apt-get install -y kubectl

# Install helm
RUN curl --insecure https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null \
    && apt-get install apt-transport-https --yes \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list

RUN apt-get update && apt-get install --no-install-recommends -y helm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# set a different user, as the GitLab CI does not allow starting images with the default root user
RUN addgroup --gid 1001 ciuser \
    && useradd --uid 1001 --gid 1001 --shell /bin/bash --create-home ciuser

WORKDIR /home/ciuser

RUN mkdir -p  /home/ciuser/.config
RUN mkdir -p /home/ciuser/.config/helm
RUN chmod -R 700 /home/ciuser
RUN chown -R 1001:1001 /home/ciuser

USER 1001