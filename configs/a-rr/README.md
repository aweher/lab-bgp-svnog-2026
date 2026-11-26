# configs/a-rr

Configuración del nodo `a-rr` — AS20, route reflector y red de clientes.

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd ospfd ospf6d`.

## Uso

```bash
./lab.sh recargar a-rr                    # re-aplica frr.conf (frr-reload.py)
./lab.sh vty a-rr                         # vtysh interactivo
./lab.sh vty a-rr "show bgp ipv4 unicast"
```

## Temas que ilustra

OSPF como IGP, iBGP desde loopback, route reflector, cluster-id, peer groups,
update groups y multipath iBGP. Detalle en `../../docs/nodos/a-rr.md`.
