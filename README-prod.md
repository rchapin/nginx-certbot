1. Determine the uid:gid for the nginxcertbot user. Since we are going to use docker's userns-remap feature we need to first determine what the first available uid and gid is by looking at any existing entries in ```/etc/subuid``` and ```/etc/subgid```. For example, let's assume that the following entries exist in both files:
```
rchapin:100000:65536
```

In this case, the next uid/gid number that we will use is **165537**.

1. Copy the ```env-vars.tmpl``` to ```env-vars.sh``` and set all of the variables.  ```NXCB_ID``` should be set to the uid that you derived in the previous step.

1. Add an ```nginxcertbot``` user to the host so that we can run the docker containers as non-root users.

    1. Generate the uid and gids, create the new group and user and add it to the docker group
    ```
    groupadd -g $NXCB_ID -r $NXCB_USERNAME && useradd -r -g $NXCB_USERNAME -u $NXCB_ID $NXCB_USERNAME && usermod -a -G docker $NXCB_USERNAME
    ```

    1. Generate and add the sub ids to their respective files.
    ```
    last_id=$(( ID + 65536 ))
    usermod --add-subuids "$NXCB_ID"-"$last_id" "$NXCB_USERNAME"
    usermod --add-subgids "$NXCB_ID"-"$last_id" "$NXCB_USERNAME"
    ```

1. Create and/or add an entry to the ```/etc/docker/daemon.json``` docker config file and restart the docker daemon.  The following entry enables us to map the uids and gids of the users in the docker container to that of the host.
```
{
  "userns-remap": "nginxcertbot"
}
```

1. Restart the docker daemon. At this point a subdirectory in /var/lib/docker will be created that is the name of the first userid in the set of subuid and subgid created for the nginxcertbot user defined in ```daemon.json```.  In this case it will be ```/var/lib/docker/165537.165537```.  It should have the following permissions:
```
drwxrwx--- 13 nginxcertbot nginxcertbot  167 Dec 26 11:39 165537.165537
```

1.  Create named volumes for the nginx container and the certbot container.  The volumes will be created in the nginxcertbot users sub directory in ```/var/lib/docker/165537.165537```.
```
docker volume create --name nginx
docker volume create --name nginx-www
docker volume create --name certbot-conf
docker volume create --name certbot-www
```

1. Generate an expanded instance of the docker-compose.tmpl file
```
envsubst < docker-compose.tmpl > docker-compose.yml
```

1. Copy the ```/data/nginx/app.conf``` to the nginx volume **TODO: parameterize this file somehow** set ownership to nginxcertbot user


1. Run the following command as root such that the command is run as the nginx user in the root of the repo dir.
```
sudo -u nginxcertbot ./init-letsencrypt.sh
```
