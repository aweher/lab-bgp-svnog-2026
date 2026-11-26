#!/usr/bin/env bash
# Genera el ancla de confianza (TA) RPKI del laboratorio: certificado raiz,
# CRL y manifiesto, sin ningun ROA. Los ROA del laboratorio se cargan por SLURM.
# Solo hace falta volver a correrlo si se cambia la IP del repositorio rsync.
set -euo pipefail
REPO_HOST="${1:-172.31.255.251}"
BASE="rsync://${REPO_HOST}/repo"
OUT="$(cd "$(dirname "$0")" && pwd)"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
cd "$W"
DAYS=3650
THIS_UPDATE=$(date -u -d '1 day ago' +%Y%m%d%H%M%SZ)
NEXT_UPDATE=$(date -u -d "+$((DAYS-1)) days" +%Y%m%d%H%M%SZ)

openssl genrsa -out ta.key 2048 2>/dev/null
openssl genrsa -out ee.key 2048 2>/dev/null

cat > ta.cnf <<CNF
[req]
distinguished_name = dn
prompt = no
[dn]
CN = bgplab-ta
[ta_ext]
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
certificatePolicies = critical,1.3.6.1.5.5.7.14.2
subjectInfoAccess = 1.3.6.1.5.5.7.48.5;URI:${BASE}/,1.3.6.1.5.5.7.48.10;URI:${BASE}/ta.mft
sbgp-ipAddrBlock = critical,IPv4:0.0.0.0/0,IPv6:::/0
sbgp-autonomousSysNum = critical,AS:0-4294967295
[ee_ext]
keyUsage = critical,digitalSignature
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
certificatePolicies = critical,1.3.6.1.5.5.7.14.2
crlDistributionPoints = URI:${BASE}/ta.crl
authorityInfoAccess = caIssuers;URI:${BASE}/ta.cer
subjectInfoAccess = 1.3.6.1.5.5.7.48.11;URI:${BASE}/ta.mft
sbgp-ipAddrBlock = critical,IPv4:inherit,IPv6:inherit
sbgp-autonomousSysNum = critical,AS:inherit
[ca]
default_ca = lab
[lab]
database = $W/index.txt
crlnumber = $W/crlnumber
default_md = sha256
authorityKeyIdentifier = keyid
[crl_ext]
authorityKeyIdentifier = keyid
CNF
: > index.txt; echo 01 > crlnumber

openssl req -new -x509 -key ta.key -config ta.cnf -extensions ta_ext -sha256 \
  -set_serial 1 -days $DAYS -outform DER -out ta.cer
openssl x509 -inform DER -in ta.cer -out ta.pem

openssl req -new -key ee.key -subj "/CN=bgplab-mft-ee" -out ee.csr
openssl x509 -req -in ee.csr -CA ta.pem -CAkey ta.key -set_serial 2 -sha256 \
  -days $DAYS -extfile ta.cnf -extensions ee_ext -out ee.pem 2>/dev/null

openssl ca -gencrl -config ta.cnf -cert ta.pem -keyfile ta.key -crlexts crl_ext \
  -crldays $DAYS -out ta.crl.pem 2>/dev/null
openssl crl -in ta.crl.pem -outform DER -out ta.crl

CRLHASH=$(openssl dgst -sha256 -r ta.crl | cut -d' ' -f1)
cat > mft.asn1 <<ASN
asn1 = SEQUENCE:mft
[mft]
num = INTEGER:1
this = GENERALIZEDTIME:$THIS_UPDATE
next = GENERALIZEDTIME:$NEXT_UPDATE
alg = OID:2.16.840.1.101.3.4.2.1
files = SEQUENCE:files
[files]
f1 = SEQUENCE:f1
[f1]
name = IA5STRING:ta.crl
hash = FORMAT:HEX,BITSTRING:$CRLHASH
ASN
openssl asn1parse -genconf mft.asn1 -noout -out mft.der
openssl cms -sign -in mft.der -binary -nodetach -signer ee.pem -inkey ee.key -keyid \
  -md sha256 -econtent_type 1.2.840.113549.1.9.16.1.26 -nosmimecap -outform DER -out ta.mft

mkdir -p "$OUT/repo"
cp ta.cer ta.crl ta.mft "$OUT/repo/"
{
  echo "${BASE}/ta.cer"
  echo
  openssl x509 -in ta.pem -pubkey -noout | grep -v '^-----'
} > "$OUT/bgplab.tal"
echo "TA generada en $OUT/repo y $OUT/bgplab.tal (repositorio: ${BASE})"
