#!/bin/bash
env > .envrc
echo CMD="/usr/local/bin/launch-bitcoin.sh" >> .envrc

. /entrypoint.sh
