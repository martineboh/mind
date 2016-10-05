#!/bin/bash -e

# WARNING: You have to adapt the script for your installation. It contains hard-coded values for another installation.

# An example script to run the app in production. It uses data volumes under the $DATA_ROOT directory.
# By default /srv. It uses a MongoDB database, tozd/meteor-mongodb image which is automatically run as well.
# Moreover, the example uses tozd/docker-hosts for service discovery. Feel free to use Docker container linking instead.

NAME='council'
DATA_ROOT='/srv'
MONGODB_DATA="${DATA_ROOT}/${NAME}/mongodb/data"
MONGODB_LOG="${DATA_ROOT}/${NAME}/mongodb/log"

METEOR_LOG="${DATA_ROOT}/${NAME}/meteor/log"
METEOR_STORAGE="${DATA_ROOT}/${NAME}/meteor/storage"

export PEERDB_INSTANCES=2
export WORKER_INSTANCES=2

# This file is used by both peermind/peermind and tozd/meteor-mongodb images. The latter automatically creates the
# database and accounts with provided passwords. The file should look like:
#
# MONGODB_ADMIN_PWD='<pass>'
# MONGODB_CREATE_PWD='<pass>'
# MONGODB_OPLOGGER_PWD='<pass>'
#
# export MONGO_URL="mongodb://meteor:${MONGODB_CREATE_PWD}@council_mongodb/meteor"
# export MONGO_OPLOG_URL="mongodb://oplogger:${MONGODB_OPLOGGER_PWD}@council_mongodb/local?authSource=admin"
CONFIG="${DATA_ROOT}/${NAME}/run.config"

mkdir -p "$MONGODB_DATA"
mkdir -p "$MONGODB_LOG"
mkdir -p "$METEOR_LOG"
mkdir -p "$METEOR_STORAGE"

touch "$CONFIG"

if [ ! -s "$CONFIG" ]; then
  echo "Set MONGODB_CREATE_PWD, MONGODB_ADMIN_PWD, MONGODB_OPLOGGER_PWD and export MONGO_URL, MONGO_OPLOG_URL environment variables in '$CONFIG'."
  exit 1
fi

#docker stop "${NAME}_mongodb" || true
#sleep 1
#docker rm "${NAME}_mongodb" || true
#sleep 1
# Mounted volume "/srv/var/hosts:/etc/hosts:ro" is used by tozd/docker-hosts service discovery and can be removed.
#docker run --detach=true --restart=always --name "${NAME}_mongodb" --hostname "${NAME}_mongodb" \
# --volume /srv/var/hosts:/etc/hosts:ro --volume "${CONFIG}:/etc/service/mongod/run.config" \
# --volume "${MONGODB_LOG}:/var/log/mongod" --volume "${MONGODB_DATA}:/var/lib/mongodb" \
# tozd/meteor-mongodb:2.6

for I in $(seq 1 $PEERDB_INSTANCES); do
    mkdir -p "${DATA_ROOT}/${NAME}/peerdb$I/log"

    docker stop "${NAME}_peerdb$I" || true
    sleep 1
    docker rm "${NAME}_peerdb$I" || true
    sleep 1
    docker run --detach=true --restart=always --name "${NAME}_peerdb$I" --hostname "${NAME}_peerdb$I" \
      --env WORKER_INSTANCES=0 --env PEERDB_MIGRATIONS_DISABLED=1 --env PEERDB_INSTANCES --env PEERDB_INSTANCE="$((I-1))" \
      --env ROOT_URL=https://council.cloyne.org --env MAIL_URL=smtp://mail.cloyne.net --env STORAGE_DIRECTORY=/storage \
      --volume /srv/var/hosts:/etc/hosts:ro --volume "${CONFIG}:/etc/service/meteor/run.config" \
      --volume "${DATA_ROOT}/${NAME}/peerdb$I/log:/var/log/meteor" --volume "${METEOR_STORAGE}:/storage" \
      peermind/peermind
done

for I in $(seq 1 $WORKER_INSTANCES); do
    mkdir -p "${DATA_ROOT}/${NAME}/worker$I/log"

    docker stop "${NAME}_worker$I" || true
    sleep 1
    docker rm "${NAME}_worker$I" || true
    sleep 1
    docker run --detach=true --restart=always --name "${NAME}_worker$I" --hostname "${NAME}_worker$I" \
      --env WORKER_INSTANCES --env PEERDB_MIGRATIONS_DISABLED=1 --env PEERDB_INSTANCES=0 \
      --env ROOT_URL=https://council.cloyne.org --env MAIL_URL=smtp://mail.cloyne.net --env STORAGE_DIRECTORY=/storage \
      --volume /srv/var/hosts:/etc/hosts:ro --volume "${CONFIG}:/etc/service/meteor/run.config" \
      --volume "${DATA_ROOT}/${NAME}/worker$I/log:/var/log/meteor" --volume "${METEOR_STORAGE}:/storage" \
      peermind/peermind
done

docker stop "${NAME}_web" || true
sleep 1
docker rm "${NAME}_web" || true
sleep 1
# Mounted volume "/srv/var/hosts:/etc/hosts:ro" is used by tozd/docker-hosts service discovery and can be removed.
docker run --detach=true --restart=always --name "${NAME}_web" --hostname "${NAME}_web" \
 --env WORKER_INSTANCES=0 --env PEERDB_INSTANCES=0 \
 --env VIRTUAL_HOST=council.cloyne.org --env VIRTUAL_URL=/ --env VIRTUAL_LETSENCRYPT=true \
 --env ROOT_URL=https://council.cloyne.org --env MAIL_URL=smtp://mail.cloyne.net --env STORAGE_DIRECTORY=/storage \
 --volume /srv/var/hosts:/etc/hosts:ro --volume "${CONFIG}:/etc/service/meteor/run.config" \
 --volume "${METEOR_LOG}:/var/log/meteor" --volume "${METEOR_STORAGE}:/storage" \
 peermind/peermind
