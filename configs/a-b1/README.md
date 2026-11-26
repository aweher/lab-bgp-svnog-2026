# configs/a-b1

Configuración del nodo `a-b1` — AS20, borde hacia ISP-A (AS10).

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd ospfd ospf6d bfdd pbrd`;
  `bgpd_options` lleva `-M rpki` para la validación de origen.

## Uso

```bash
./lab.sh recargar a-b1
./lab.sh vty a-b1 "show bgp ipv4 unicast"
./lab.sh vty a-b1 "show rpki prefix-table"
```

## Temas que ilustra

Doble peer (IPv4/IPv6), autenticación, BFD, roles, política multihomed, RTBH,
RPKI y FlowSpec (lado cliente). Detalle en `../../docs/nodos/a-b1.md`.
