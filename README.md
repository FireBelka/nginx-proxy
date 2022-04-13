# Nginx-proxy
Nginx-service with redirect to another web app with docker-compose  
Web-app taken from https://github.com/gabrielecirulli/2048    
Nginx OpenSSL sertification https://pentacent.medium.com/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71

# How it works
1) terraform apply (deploy azure vm with startup script init.sh)    
2) on every push to master build image, push to ACR, update image on vm with az vm run-command invoke

## bitbucket pipeline
```
pipelines:
  default:
      - step:
          name: Docker-compose build and push to ACR
          image: atlassian/default-image:2
          caches:
            - docker
          script:
            - docker login -u $DOCKER_USER -p $DOCKER_PASSWORD $DOCKER_LOGIN_SERVER
            - docker-compose -f docker-compose.yml build
            - docker-compose -f docker-compose.yml push
          services:
            - docker
      - step:
          name: exec docker-compose up
          image: mcr.microsoft.com/azure-cli
          script:
            - az login --service-principal -u $AZURE_APP_ID -p $AZURE_PASSWORD --tenant $AZURE_TENANT_ID
            - az vm run-command invoke -g nginx-proxy -n myVM1 --command-id RunShellScript --scripts "sudo docker-compose -f /home/azureuser/docker-compose.yml pull  && sudo docker-compose -f /home/azureuser/docker-compose.yml up "
```
## docker-compose for bitbucket pipelines
```
version: "3"
services:
  nginx-backend:
    build: ./web-app-2/
    container_name: nginx-backend
    restart: unless-stopped
    image: testregk8s.azurecr.io/nginx-backend
    domainname: abcdefg
    networks:
      - net-1
  nginx-proxy:
    build: ./nginx-proxy/
    container_name: nginx-proxy
    image: testregk8s.azurecr.io/nginx-proxy
    domainname: abcdefg
    ports:
      - 443:443
      - 80:80
    depends_on:
      - nginx-backend
    networks:
      - net-1
    volumes:
      - ./data/certbot/conf:/etc/letsencrypt
      - ./data/certbot/www:/var/www/certbot
  certbot:
    container_name: certbot
    image: certbot/certbot
    networks:
      - net-1
    volumes:
      - ./data/certbot/conf:/etc/letsencrypt
      - ./data/certbot/www:/var/www/certbot
volumes:
  certbot-conf:
  certbot-www:
networks:
  net-1:
    driver: bridge
```
##docker-compose for usage inside vm(removed build section)
```
version: "3"
services:
  nginx-backend:
    container_name: nginx-backend
    #restart: unless-stopped
    image: <ACR/registry-1>
    domainname: abcdefg
    networks:
      - net-1

  nginx-proxy:
    container_name: nginx-proxy
    #restart: unless-stopped
    image: <ACR/registry-1>
    domainname: abcdefg
    ports:
      - 443:443
      - 80:80
    depends_on:
      - nginx-backend
    networks:
      - net-1
    volumes:
      - ./data/certbot/conf:/etc/letsencrypt
      - ./data/certbot/www:/var/www/certbot


  certbot:
    container_name: certbot
    #restart: unless-stopped
    image: certbot/certbot
    networks:
      - net-1
    volumes:
      - ./data/certbot/conf:/etc/letsencrypt
      - ./data/certbot/www:/var/www/certbot

networks:
  net-1:
    driver: bridge
```

##nginx-proxy setup
```
server {
    listen 80;
    server_name nginx-proxy www.looks-like-a-bird.tk;
    location / {
        return 301 https://$host$request_uri;
    }
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
}

server {
    listen 443 ssl;
    server_name nginx-proxy www.looks-like-a-bird.tk;
    location / {
        proxy_pass http://nginx-backend:80;
    }
    ssl_certificate /etc/letsencrypt/live/www.looks-like-a-bird.tk/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/www.looks-like-a-bird.tk/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
}
```

#how make it working by hands
1) *locally* docker-compose build && docker-compose push(pre-image)   
2) *locally* terraform apply    
3) *locally* git commit && git push -> bitbucket pipeline runs
