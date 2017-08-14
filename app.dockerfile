FROM debian:stretch
RUN echo "force-unsafe-io" > /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
  echo "Acquire::http {No-Cache=True;};" > /etc/apt/apt.conf.d/no-cache && \
  apt-get update && apt-get install -y --no-install-recommends nginx ssl-cert
COPY nginx.conf /etc/nginx/
EXPOSE 80 443
CMD ['nginx', '-g', 'daemon off;']
