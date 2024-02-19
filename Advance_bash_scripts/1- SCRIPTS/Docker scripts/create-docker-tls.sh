#!/bin/bash
#DOCKER_DAEMON_HOST_IP is the IP from which the connection can be made. 


STR=4096
DOCKER_DAEMON_HOSTNAME="proserv.sodexis.com"
DOCKER_DAEMON_HOST_IP1="192.99.182.92"
DOCKER_DAEMON_HOST_IP2="192.99.182.92"

#Change to your company details
COUNTRY=US
STATE=Florida
LOCALITY=Orlando
ORGANIZATION=Sodexis
ORGANIZATIONALUNIT=IT
EMAIL=admin@sodexis.com

echo " => Ensuring config directory exists..."

if [[ ! -d $HOME/.docker-cert ]]; then 
  mkdir -p "$HOME/.docker-cert"
  cd $HOME/.docker-cert
  rm -rf $HOME/.docker-cert/*.* >/dev/null 2>&1
else
  cd $HOME/.docker-cert
  rm -rf $HOME/.docker-cert/*.* >/dev/null 2>&1
fi

echo " => Generating CA key"
openssl genrsa -aes256 \
  -out ca-key.pem $STR

echo " => Generating CA certificate"
openssl req \
  -new \
  -key ca-key.pem \
  -x509 \
  -days 3650 \
  -nodes \
  -subj "/C=$COUNTRY/ST=$STATE/L=$LOCALITY/O=$ORGANIZATION/OU=$ORGANIZATIONALUNIT/CN=$DOCKER_DAEMON_HOSTNAME/emailAddress=$EMAIL" \
  -out ca.pem

echo " => Generating server key"
openssl genrsa \
  -out server-key.pem $STR

echo " => Generating server CSR"
openssl req \
  -subj "/CN=$DOCKER_DAEMON_HOSTNAME" \
  -sha256 \
  -new \
  -key server-key.pem \
  -out server.csr

echo " => Gnerating TLS Allow conenctions extfile.cnf"
echo subjectAltName = DNS:${DOCKER_DAEMON_HOSTNAME},IP:${DOCKER_DAEMON_HOST_IP1},IP:${DOCKER_DAEMON_HOST_IP2},IP:127.0.0.1 >> extfile.cnf


echo " => Creating Docker daemon key’s extended usage attributes to be used only for server authentication"
echo extendedKeyUsage = serverAuth >> extfile.cnf

echo " => Signing server CSR with CA"
openssl x509 \
  -req \
  -days 365 \
  -sha256 \
  -in server.csr \
  -CA ca.pem \
  -CAkey ca-key.pem \
  -CAcreateserial \
  -out server-cert.pem \
  -extfile extfile.cnf

echo " => Generating client key"
openssl genrsa \
  -out key.pem $STR

echo " => Generating client CSR"
openssl req \
  -subj '/CN=docker-client' \
  -new \
  -key key.pem \
  -out client.csr

echo " => Creating extended key usage"
echo extendedKeyUsage = clientAuth > extfile-client.cnf

echo " => Signing client CSR with CA"
openssl x509 \
  -req \
  -days 365 \
  -sha256 \
  -in client.csr \
  -CA ca.pem \
  -CAkey ca-key.pem \
  -CAcreateserial \
  -out cert.pem \
  -extfile extfile-client.cnf

chmod -v 0400 ca-key.pem key.pem server-key.pem
chmod -v 0444 ca.pem server-cert.pem cert.pem
rm -v client.csr server.csr extfile.cnf extfile-client.cnf

echo " => Done!"