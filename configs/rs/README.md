# configs/rs

Configuración del nodo `rs` — route server del IXP (AS100).

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd`; `-M rpki`.

## Uso

```bash
./lab.sh recargar rs
./lab.sh vty rs "show running-config"
```

## Temas que ilustra

Route server con peer groups: `route-server-client`, `attribute-unchanged next-hop`,
`remove-private-AS`, sesiones pasivas, ttl-security, maximum-prefix, RPKI y rol rs-server.
Detalle en `../../docs/nodos/rs.md`.
