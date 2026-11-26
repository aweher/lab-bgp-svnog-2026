# configs/as66

Configuración del nodo `as66` — cliente de ISP-A (AS66), origen del secuestro de prefijos.

## Archivos

- `frr.conf` — fuente de verdad. Encabezado con nodo, ASN y temas.
- `daemons` — demonios activos: `zebra mgmtd staticd bgpd`.

## Uso

```bash
./lab.sh recargar as66
./lab.sh vty as66 "show bgp ipv4 unicast"
./lab.sh escenario secuestro on          # agrega network 50.0.1.0/24
```

## Temas que ilustra

El secuestro de `50.0.1.0/24` (red de AS50). La ruta `50.0.1.0/24 Null0` ya está naileada;
el escenario solo agrega el `network`. Detalle en `../../docs/nodos/as66.md`.
