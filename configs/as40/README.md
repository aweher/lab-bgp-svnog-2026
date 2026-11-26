# configs/as40

Configuración del nodo `as40` — "Internet" (AS40), tránsito de AS10, AS30, AS41 y AS50.

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd`.

## Uso

```bash
./lab.sh recargar as40
./lab.sh vty as40 "show bgp summary"
```

## Temas que ilustra

Configuración mínima de eBGP (sin políticas, `no bgp ebgp-requires-policy`), multipath y
BGP sin numerar con next-hop IPv6 para IPv4 (RFC 8950). Detalle en
`../../docs/nodos/as40.md`.
