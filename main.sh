# Install required packages to generate passwords using htpasswd

sudo yum install httpd-tools        [RHEL/CentOS]
sudo apt install apache2-utils      [Debian/Ubuntu]

create password files with below commands

htpasswd -c /home/osboxes/nginx1-auth.htpasswd  admin
htpasswd -c /home/osboxes/nginx2-auth.htpasswd  sysadmin
htpasswd -c /home/osboxes/glances-auth.htpasswd devopsadmin

# nginx.conf file

###############Start-of-Nginx-Config-file #########

events {}

http {
upstream backend_nginx1 {
    server nginx1;
}
upstream backend_nginx2 {
    server nginx2;
}

upstream backend_glances {
    server glances:61208;
}



server {
    listen 7070;
    server_name _;
    location / {
        #//turn on auth for this location
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/nginx1-auth.htpasswd;
        proxy_pass http://backend_nginx1;
    }
}

server {
    listen 8080;
    server_name _;
    location / {
        #//turn on auth for this location
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/nginx2-auth.htpasswd;
        proxy_pass http://backend_nginx2;
    }
}

server {
    listen 9090;
    server_name _;
    location / {
        #//turn on auth for this location
        auth_basic "Restricted";
        auth_basic_user_file /etc/nginx/glances-auth.htpasswd;
        proxy_pass http://backend_glances;
    }
}


}

###############End-of-Nginx-Config-file #########

## Now deploying backend docker containers to be served by front-end nginx load-balancer

sudo docker run -d  --name nginx1  nginx

sudo docker run -d  --name nginx2  nginx

## Glances container is a combination of top/htop for getting system/docker resources on console or on web browser.

sudo docker run -d --restart="always"  -e GLANCES_OPT="-w" -v /var/run/docker.sock:/var/run/docker.sock:ro --pid host --name glances docker.io/nicolargo/glances


# Deploying Front-end nginx load-balancer to serve backend services/containers

sudo docker run -d --name nginx-reverseProxy  -p 7070:7070 -p 8080:8080 -p 9090:9090 --link nginx1:nginx1 --link nginx2:nginx2 --link glances:glances -v /home/osboxes/nginx.conf:/etc/nginx/nginx.conf -v  /home/osboxes/nginx1-auth.htpasswd:/etc/nginx/nginx1-auth.htpasswd  -v /home/osboxes/nginx2-auth.htpasswd:/etc/nginx/nginx2-auth.htpasswd -v /home/osboxes/glances-auth.htpasswd:/etc/nginx/glances-auth.htpasswd  nginx


### Proxy pass on tcp port
## Nginx conf file

events {}

stream {
  upstream postgres {
    server pdb2:5432;
  }
  server {
    listen 5432;
    proxy_pass postgres;
  }
}



