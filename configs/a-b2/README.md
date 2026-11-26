# configs/a-b2

Configuración del nodo `a-b2` — AS20, borde hacia ISP-B (AS30) y el IXP.

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd ospfd ospf6d`; `-M rpki`.

## Uso

```bash
./lab.sh recargar a-b2
./lab.sh vty a-b2 "show bgp ipv4 unicast summary"
```

## Temas que ilustra

Sesión IPv4 con las dos familias, redistribución de OSPF, política multihomed,
miembro de IXP, AS-PATH ACL, comunidades, RPKI y roles. Detalle en
`../../docs/nodos/a-b2.md`.
