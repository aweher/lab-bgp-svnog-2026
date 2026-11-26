# configs/as60

Configuración del nodo `as60` — cliente multihomed (AS60) de ISP-A e ISP-B.

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd`.

## Uso

```bash
./lab.sh recargar as60
./lab.sh vty as60 "show bgp ipv4 unicast neighbors 10.0.6.2 received-routes"
```

## Temas que ilustra

Configuración clásica sin address-family, tabla completa por un proveedor y solo default
por el otro, soft-reconfiguration inbound y el escenario de route leak. Detalle en
`../../docs/nodos/as60.md`.
