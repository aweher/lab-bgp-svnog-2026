# configs/as50

Configuración del nodo `as50` — red de contenido (AS50), tránsito por AS40 y peering en el IXP.

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd`.

## Uso

```bash
./lab.sh recargar as50
./lab.sh vty as50 "show bgp ipv4 unicast regexp _30$"
```

## Temas que ilustra

BGP multifamilia sobre IPv6, filter-list con AS-PATH ACL y regex, preferencia del IXP
sobre el tránsito y rol rs-client. Es la víctima del secuestro. Detalle en
`../../docs/nodos/as50.md`.
