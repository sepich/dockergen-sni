FROM debian:stretch
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
  echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
  apt-get update && apt-get install -y --no-install-recommends wget haproxy ca-certificates curl

ENV DOCKER_GEN_VERSION 0.7.3
RUN wget https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && tar -C /usr/local/bin -xvzf docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz \
 && rm /docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz

WORKDIR /app
COPY entrypoint.sh .
COPY haproxy.tmpl .
EXPOSE 80 443
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["docker-gen", "-watch", "-only-exposed", "-keep-blank-lines", "-notify-output", "-notify", "service haproxy reload", "/app/haproxy.tmpl", "/etc/haproxy/haproxy.cfg", "-wait", "2s:10s"]
