#!/bin/sh
set -e

if [ $(echo "$1" | cut -c1) = "-" ]; then
	echo "$0: assuming arguments for litecoind"
	set -- litecoind "$@"
fi

# Allow the container to be started with `--user`, if running as root drop privileges
if [ "$1" = 'litecoind' -a "$(id -u)" = '0' ]; then
	# Set perms on data
	echo "$0: detected litecoind"
	mkdir -p "$DATADIR"
	chmod 700 "$DATADIR"
	chown -R litecoin "$DATADIR"
	exec gosu litecoin "$0" "$@" -datadir=$DATADIR
fi

if [ "$1" = 'litecoin-cli' -a "$(id -u)" = '0' ] || [ "$1" = 'litecoin-tx' -a "$(id -u)" = '0' ]; then
	echo "$0: detected litecoin-cli or litecoint-tx"
	exec gosu litecoin "$0" "$@" -datadir=$DATADIR
fi

# If not root (i.e. docker run --user $USER ...), then run as invoked
echo "$0: running exec"
exec "$@"
