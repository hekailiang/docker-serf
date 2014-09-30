#!/bin/bash

SERF_HOME=/usr/local/serf
SERF_BIN=$SERF_HOME/bin/serf
SERF_CONFIG_DIR=$SERF_HOME/etc
SERF_LOG_FILE=/var/log/serf.log
SERF_INIT_DIR=/usr/local/init

set -x

echo "Executing scripts from $SERF_INIT_DIR" | tee $SERF_LOG_FILE

for file in $SERF_INIT_DIR/*
do
    echo "Execute: $file" | tee -a $SERF_LOG_FILE
    /bin/bash $file | tee -a $SERF_LOG_FILE
done

# if SERF_JOIN_IP env variable set generate a config json for serf
[[ -n $SERF_JOIN_IP ]] && cat > $SERF_CONFIG_DIR/join.json <<EOF
{
  "retry_join" : ["$SERF_JOIN_IP"],
  "retry_interval" : "5s"
}
EOF

# by default only short hostname would be the nodename
# we need FQDN
# while loop for azure deployment
unset SERF_HOSTNAME
while [ -z "$SERF_HOSTNAME" ]; do
  SERF_HOSTNAME=$(hostname -f 2>/dev/null)
  sleep 5
done;
cat > $SERF_CONFIG_DIR/node.json <<EOF
{
  "node_name" : "$SERF_HOSTNAME",
  "bind" : "$SERF_HOSTNAME"
}
EOF

# if SERF_ADVERTISE_IP env variable set generate a advertise.json for serf to advertise the given IP
[[ -n $SERF_ADVERTISE_IP ]] && cat > $SERF_CONFIG_DIR/advertise.json <<EOF
{
  "advertise" : "$SERF_ADVERTISE_IP"
}
EOF

$SERF_BIN agent -config-dir $SERF_CONFIG_DIR $@ | tee -a $SERF_LOG_FILE
