#!/bin/bash

hostname=${1?"Hostname (CN) is required"}
keyfile=$2

set -e

function confirm (){
	local prompt=$1
	local default=$2
	local yn=
	if [ "$default" == "y" ] || [ "$(echo -n "${default}" | tr "[:upper:]" "[:lower:]" )" == "true" ]; then
		default="y"
		prompt="$prompt [Y/n] [default = Y]: "
	else
		prompt="$prompt [y/N] [default = N]: "
	fi
	
	echo -n "${prompt}"
	read -r yn
	
	if [ "x$yn" == "x" ]; then
		yn=$default
	fi	
	
	case $yn in
		[yY][eE][sS]|[yY]) 
			true
			;;
		*)
			false
			;;
	esac
}

while ! mkdir selfsigned.${hostname}.${i=0} > /dev/null 2>&1; do i=$(( i + 1 )); done
while ! mkdir -p tmp/selfsigned.${hostname}.${j=0} > /dev/null 2>&1; do j=$(( j + 1 )); done
output="selfsigned.${hostname}.$i"
tmpdir="tmp/selfsigned.${hostname}.${j=0}"

if [ "x$keyfile" == "x" ]; then
		keyfile=$output/node.key.pem
		openssl genrsa -out "$keyfile" 2048
		openssl rsa -in "$keyfile" -pubout -out "$output/node.pub.pem"
fi
openssl req -new -key "$keyfile" -out "$tmpdir/node.csr" -days 365 -subj "/C=IN/CN=$hostname"
openssl x509 -req -in "$tmpdir/node.csr" -signkey "$keyfile" -out $output/node.cer.pem -days 365 -sha256

if confirm "Encrypt the key?" "n"; then
	openssl pkcs8 -topk8 -in "$keyfile" -out "${keyfile/pem/p8.pem}"
else 
	openssl pkcs8 -topk8 -in "$keyfile" -out "${keyfile/pem/p8.pem}" -nocrypt
fi

cat $output/node.cer.pem "$keyfile" > $output/node.pem
cat $output/node.cer.pem "${keyfile/pem/p8.pem}" > $output/node.p8.pem
rm -rf tmp
echo "### files created in $output"
