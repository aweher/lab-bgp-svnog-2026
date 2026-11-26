# configs/as41

Configuración del nodo `as41` — red remota (AS41), cliente de AS40 por enlace sin numerar.

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd`.

## Uso

```bash
./lab.sh recargar as41
./lab.sh vty as41 "show bgp summary"
```

## Temas que ilustra

BGP sin numerar e IPv4 con next-hop IPv6 (RFC 8950). Sus prefijos no tienen ROA
("not found"). Detalle en `../../docs/nodos/as41.md`.
