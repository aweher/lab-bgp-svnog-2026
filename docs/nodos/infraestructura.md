# Infraestructura: fort, rpki-repo, ixp-sw y mitig

Estos contenedores no son routers FRR, pero sostienen el laboratorio.

## fort — Validador RPKI (FORT)

- Imagen `nicmx/fort-validator:1.6.7`, IP de gestión `172.31.255.250`.
- Corre en modo `server`: expone RTR en el puerto **3323** (`0.0.0.0`).
- Configuración en `fort/fort.json` (tal, slurm, intervalos) y `fort/slurm.json`.
- El trust anchor (`rpki/bgplab.tal`) apunta al repo local por rsync.

Los **ROA no están en `rpki/repo`**: se cargan como **SLURM** (RFC 8416) en
`fort/slurm.json`. FORT los relee en cada ciclo de validación (60 s) y los entrega por RTR.

```bash
./lab.sh vty a-b1 "show rpki cache-connection"
./lab.sh vty a-b1 "show rpki prefix-table"
docker logs --tail 5 bgp-fort
```

## rpki-repo — Repositorio rsync

- IP de gestión `172.31.255.251`. Sirve `rpki/repo` con `rsync` (ver `rpki/rsyncd.conf`).
- Publica `ta.cer`, `ta.crl` y `ta.mft` (el ancla de confianza vacía).

## ixp-sw — Switch del IXP

Un contenedor que levanta un **bridge Linux** y mete en él las interfaces `eth1..eth4`.
Es la LAN del IXP (`192.168.0.0/24`, `2001:db8:100::/64`) que une a `rs`, `a-b2`, `as30`
y `as50`. No corre BGP.

## mitig — Controlador de mitigación (ExaBGP)

- Imagen `ghcr.io/exa-networks/exabgp:latest`, se engancha a `a-b1` por `20.0.3.20/30`.
- Origina una regla **FlowSpec** por iBGP: descartar UDP con puerto de origen 123 (NTP)
  hacia la IP atacada `20.0.1.1`. Ver `configs/mitig/exabgp.conf`.

FRR recibe la regla pero la muestra como no instalada: la imagen de FRR no trae `ipset` ni
`iptables`, que son los que la aplican en el plano de datos.
