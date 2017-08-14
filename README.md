# Docker swarm dynamic ingress proxy playground
### What is it?
Problem: You have multiple https services in your swarm which should be available from outside on port 443.

Usual solution would be something like [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy) or [docker/dockercloud-haproxy](https://github.com/docker/dockercloud-haproxy) which require SSL termination on proxy side. So you have to install certificates from all your https services to proxy and keep them updated. Each update means restart = drop all traffic on the floor

But for https we could sniff SNI ClientHello and do [SSL passthrough](http://www.haproxy.com/blog/enhanced-ssl-load-balancing-with-server-name-indication-sni-tls-extension/) proxying without SSL termiation on proxy side. Examples:
 - [fabiolb/fabio](https://github.com/fabiolb/fabio/wiki/Features#tcpsni-proxy-support) needs consul
 - [autopilotpattern](https://github.com/autopilotpattern/hello-world) needs consul
 - [vfarcic/docker-flow-proxy](https://github.com/vfarcic/docker-flow-proxy) seems like support SNI for haproxy but requires docker-flow-swarm-listener
 - [dlundquist/sniproxy](https://github.com/dlundquist/sniproxy) just add docker-gen here

This project inspired by [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy) and based on [jwilder/docker-gen](https://github.com/jwilder/docker-gen) and [haproxy](https://www.haproxy.com/doc/aloha/8.0/deployment_guides/tls_layouts.html#ssl-tls-passthrough) to have:
 - Dynamic proxy reconfiguration by events in swarm
 - No need to install certificates to proxy
 - Stickie session support based on SSL session ID
 - No restart needed, live update

**Note:** Drawback for passtrough mode is that backends would see proxy IP instead of client IP for each request. In SSL termination mode it is the same, but proxy can add header like `X-Forwarded-For` as it is re-encrypts the traffic. For passtrough mode the only way to preserve client IP is [DSR](https://www.haproxy.com/blog/layer-4-load-balancing-direct-server-return-mode/) or [NAT](http://www.haproxy.com/blog/layer-4-load-balancing-nat-mode/) which both require backend reconfiguration

### Labels
Domains are assigned for services via `proxy.virtualhost` label.    
If container has only one exposed port!=443, it would be used as http. To use it as https add it to label `proxy.https.port`.  
If container has multiple exposed ports!=80/443 you need to specify which of them to use via labels `proxy.http.port` and `proxy.https.port`  
If container use only https port there would be automatic `302 redirect http>https` on port 80 for this virtualhost

### Playground
This repo includes playground with one proxy container
 - `haproxy` binds to docker host localhost:443 and :80

and 2 example app containers:
 - `app1`, `app2` which listens on both :80 and :443 (self-signed cert for name like `appN.local`) App is just a plain nginx which echoes the request, uri and container name. It is not bind to host and located in separate network which only can communicate with haproxy container

On first start build would happen automatically:
```
docker-compose up -d
```

 - Test via browser  
  Add to your `/etc/hosts` line:  
 `127.0.0.2 app1.local app2.local`  
 and open https://app1.local in Browser. SSL certificate error for unknown issuer is ok in this case as `snakeoil` is used in example app.

 - Test via curl  
 On Linux host you can do requests without touching `/etc/hosts` like that:
 ```bash
  # curl -ik --resolve app1.local:443:127.0.0.1 --resolve app2.local:443:127.0.0.1  https://app2.local/url?a=b
  HTTP/1.1 200 OK
  Server: nginx/1.10.3
  Date: Sat, 12 Aug 2017 17:09:55 GMT
  Content-Type: application/octet-stream
  Content-Length: 85
  Connection: keep-alive
  Content-Type: text/plain

  Hello from app2!
  Uri: app2.local/url?a=b
  Client: 172.19.0.4
  Container: 68f4e5b61ab1
 ```
**Note:** Unfortunately last method would not work on OSX as [using -k disables SNI](https://curl.haxx.se/libcurl/c/CURLOPT_SSL_VERIFYHOST.html#LIMITATIONS), so use Browser.

 - Haproxy web is available at http://localhost:8081

 Now try to scale containers and watch haproxy reconfigures automatically:
 ```
 docker-compose scale app1=5
 ```
