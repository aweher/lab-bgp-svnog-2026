# configs/as10

Configuración del nodo `as10` — ISP-A (AS10), tránsito de AS20, AS60 y AS66.

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd bfdd`; `-M rpki`.

## Uso

```bash
./lab.sh recargar as10
./lab.sh vty as10 "show bgp ipv4 unicast community 10:100"
```

## Temas que ilustra

Política de un ISP con comunidades clásicas, local-preference por tipo de vecino,
RTBH, maximum-prefix, BFD, dampening, roles y una sesión IPv6 con las dos familias
(hacia AS40). No valida RPKI ni filtra a AS66 a propósito. Detalle en
`../../docs/nodos/as10.md`.
