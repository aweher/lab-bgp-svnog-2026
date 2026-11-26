# Escenario: secuestro de prefijo

AS66 anuncia `50.0.1.0/24`, un prefijo más específico de AS50 (la red de contenido).

```bash
./lab.sh escenario secuestro on
./lab.sh vty as40 "show bgp ipv4 unicast 50.0.1.0/24"      # lo acepta: no valida
./lab.sh vty as30 "show bgp ipv4 unicast 50.0.1.0/24"      # no esta: lo descarto por invalido
docker exec bgp-as40 traceroute -n -s 40.0.0.1 50.0.1.1    # el trafico termina en AS66
./lab.sh escenario secuestro off
```

## Qué pasa

1. AS66 anuncia `50.0.1.0/24` a su proveedor ISP-A.
2. ISP-A lo acepta porque **no filtra a su cliente** y **no valida RPKI**.
3. El prefijo robado se propaga hasta donde nadie lo descarte.
4. Los que validan origen (`a-b1`, `a-b2`, `as30`, `rs`) lo descartan por `invalid`.

## Por qué es "invalid" en RPKI

`50.0.0.0/16` pertenece a AS50 (hay ROA en el SLURM con `maxPrefixLength: 16`). El
anuncio de `50.0.1.0/24` viene de AS66 con un origen que no coincide: FORT lo marca
**invalid** y los routers que validan lo rechazan.

## Para pensar

- ¿Por qué `as40` (Internet) lo acepta y `as30` (ISP-B) no?
- ¿Qué pasa si ISP-A validara RPKI? (el escenario se desarma solo)

Ver también: [as66](../nodos/as66.md), [as10](../nodos/as10.md).
