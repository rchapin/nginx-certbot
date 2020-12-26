#!/bin/bash

set -e

export CERTBOT_CONF_PATH="/var/lib/docker/165537.165537/volumes/certbot-conf/_data"
export CERTBOT_WWW_PATH="/var/lib/docker/165537.165537/volumes/certbot-www/_data"
export DOMAINS="ryanchapin.com www.ryanchapin.com"

# Adding a valid email address is strongly recommended
export EMAIL=rchapin@nbinteractive.com

# Set to 1 if you're testing your setup to avoid hitting request limits
export STAGING=0

# export EMAIL=${EMAIL:-""}
# export STAGING=${STAGING:-0}

RSA_KEY_SIZE=4096

# ##############################################################################

# Build an array of the domains that we will add to the cert from the
# expected exported env var.
domains=()
for d in $DOMAINS
do
  domains+=($d)
done

if ! [ -x "$(command -v docker-compose)" ]; then
  echo 'Error: docker-compose is not installed.' >&2
  exit 1
fi

certbot_live_dir=$CERTBOT_CONF_PATH/live
if [ -d "$certbot_live_dir" ]; then
  read -p "Existing data found for $DOMAINS. Continue and replace existing certificate? (y/N) " decision
  if [ "$decision" != "Y" ] && [ "$decision" != "y" ]; then
    exit
  fi
fi

if [ ! -e "$CERTBOT_CONF_PATH/options-ssl-nginx.conf" ] || [ ! -e "$CERTBOT_CONF_PATH/ssl-dhparams.pem" ]; then
  echo "### Downloading recommended TLS parameters ..."
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf > "$CERTBOT_CONF_PATH/options-ssl-nginx.conf"
  curl -s https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem > "$CERTBOT_CONF_PATH/ssl-dhparams.pem"
  echo
fi

echo "### Creating dummy certificate for $domains ..."

domains_dir="$certbot_live_dir/$domains"
mkdir -p $domains_dir
# Path as seen from inside the docker container
path="/etc/letsencrypt/live/$domains"

docker-compose run --rm --entrypoint "\
  openssl req -x509 -nodes -newkey rsa:$RSA_KEY_SIZE -days 1\
    -keyout '$path/privkey.pem' \
    -out '$path/fullchain.pem' \
    -subj '/CN=localhost'" certbot
echo

echo "### Starting nginx ..."
docker-compose up --force-recreate -d nginx
echo

echo "### Deleting dummy certificate for $domains ..."
docker-compose run --rm --entrypoint "\
  rm -Rf /etc/letsencrypt/live/$domains && \
  rm -Rf /etc/letsencrypt/archive/$domains && \
  rm -Rf /etc/letsencrypt/renewal/$domains.conf" certbot
echo

echo "### Requesting Let's Encrypt certificate for $domains ..."
#Join $domains array to -d args
domain_args=""
for domain in "${domains[@]}"; do
  domain_args="$domain_args -d $domain"
done

# Select appropriate email arg
case "$EMAIL" in
  "") email_arg="--register-unsafely-without-email" ;;
  *) email_arg="--email $EMAIL" ;;
esac

# Enable staging mode if needed
if [ $STAGING != "0" ]; then staging_arg="--staging"; fi

docker-compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    $email_arg \
    $domain_args \
    --rsa-key-size $RSA_KEY_SIZE \
    --agree-tos \
    --force-renewal" certbot
echo

echo "### Reloading nginx ..."
docker-compose exec nginx nginx -s reload
