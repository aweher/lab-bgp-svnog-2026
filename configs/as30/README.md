# configs/as30

Configuración del nodo `as30` — ISP-B (AS30), tránsito de AS20 y AS60, miembro del IXP.

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd`; `-M rpki`.

## Uso

```bash
./lab.sh recargar as30
./lab.sh vty as30 "show bgp ipv4 unicast summary"   # vecino dinamico marcado con *
```

## Temas que ilustra

Large communities, RPKI en todas las entradas, vecinos dinámicos (`listen range`),
default-originate (tabla parcial), MED y sesiones IPv4 con las dos familias. Detalle en
`../../docs/nodos/as30.md`.
