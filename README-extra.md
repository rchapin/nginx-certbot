1. Add an ```nginxcertbot``` user to the host so that we can run the docker containers as non-root users.  Add the new user to the docker group.
```
useradd -rM nginxcertbot
usermod -aG docker nginxcertbot
```

1. Create and/or add an entry to the ```/etc/docker/daemon.json``` docker config file and restart the docker daemon.  The following entry enables us to map the uids and gids of the users in the docker container to that of the host.
```
{
  "userns-remap": "nginxcertbot"
}
```

1. Create and/or add an entry for the nginx uid and gid into the ```/etc/subuid``` and ```/etc/subgid``` files.  Ensure that they do not overlapp any existing entries.  For example, if the existing files contain the following:
```
root@nginx01:/var/log# cat /etc/subuid
rchapin:100000:65536
root@nginx01:/var/log# cat /etc/subgid
rchapin:100000:65536
```

You must start the next range at 165537 or greater.  So, assuming that there is an entry similar to that above, add the following to both subuid and subgid files.
```
nginxcertbot:165537:231073
```

1. Restart the docker daemon. At this point a subdirectory in /var/lib/docker will be created that is the name of the first userid in the set of subuid and subgid created for the nginxcertbot user defined in ```daemon.json```.  In this case it will be ```/var/lib/docker/165537.165537```.

1.  Create named volumes for the nginx container and the certbot container.  The volumes will be created in the nginxcertbot users sub directory in ```/var/lib/docker/165537.165537```.
```
docker volume create --name nginx
docker volume create --name certbot-conf
docker volume create --name certbot-www
```
1. Grant the nginxcertbot user permissions to the aformentioned volumes
```
chgrp nginxcertbot /var/lib/docker/165537.165537
chmod 770 /var/lib/docker/165537.165537
chgrp nginxcertbot /var/lib/docker/165537.165537/volumes
chmod 770 /var/lib/docker/165537.165537/volumes
chgrp -R nginxcertbot /var/lib/docker/165537.165537/volumes/nginx /var/lib/docker/165537.165537/volumes/certbot-conf/ /var/lib/docker/165537.165537/volumes/certbot-www/
chmod -R g+w /var/lib/docker/165537.165537/volumes/nginx /var/lib/docker/165537.165537/volumes/certbot-conf/ /var/lib/docker/165537.165537/volumes/certbot-www/

root@nginx01:/var/lib/docker/165537.165537/volumes# chmod -R g+w nginx certbot-conf/ certbot-www/




```

1. Copy the ```/data/nginx/app.conf``` to the nginx volume **TODO: parameterize this file somehow**

1. Export the following env vars **TODO**

1. Run the following command as root such that the command is run as the nginx user in the root of the repo dir.
```
sudo -u nginxcertbot ./init-letsencrypt.sh

```
