# a-b2 — Borde de AS20 hacia ISP-B y el IXP

El otro borde de **EmpresaA**. Ilustra el slide "ASN Multi Homed: ISP-B", la
**redistribución de OSPF a BGP** y el lado del **miembro de IXP** (slide "IXP").

## Vecinos

| Vecino | AS | Familia | Notas |
|---|---|---|---|
| `20.0.3.1` (a-rr) | 20 | IPv4+IPv6 | iBGP desde loopback, `next-hop-self` |
| `10.0.2.2` | 30 | IPv4+IPv6 | una sola sesión IPv4 con las dos familias |
| `192.168.0.1` (rs) | 100 | IPv4 | IXP, `ttl-security hops 1`, `local-role rs-client` |
| `2001:db8:100::1` (rs) | 100 | IPv6 | "doble peer" hacia el route server |

## Redistribución (ORIGIN incomplete)

```text
ip prefix-list advertise-v4 seq 5 permit 20.0.4.0/22
route-map ospf-redist permit 10
 match ip address prefix-list advertise-v4
...
redistribute ospf route-map ospf-redist
```

Solo `20.0.4.0/22` pasa de OSPF a BGP, y llega con `ORIGIN incomplete` (distinto del
`network`, que llega con `IGP`). Se ve comparando `20.0.4.0/22` con `20.0.0.0/21` en `a-rr`.

## Política

- **Hacia ISP-B** `as30-out`: prepend 20, `no-advertise` para los `/22`.
- **Desde ISP-B** `as30-in`: descarta `rpki invalid`; `local-preference 90` para rutas de
  AS10 y `150` para rutas de AS30; marca con `20:30`.
- **Hacia el IXP** `ixp-out`: solo el agregado `20.0.0.0/21`.
- **Desde el IXP** `ixp-in`: descarta `rpki invalid` y bogons (`10/8`, `172.16/12`,
  `192.168/16`, default); **rechaza las redes de AS30 por el IXP** (`as-path` `_30$`) para
  preferirlas por el enlace de tránsito; lo demás con `local-preference 200` y `20:100`.

`no bgp enforce-first-as` es imprescindible: el route server no agrega su ASN al camino.

## Para inspeccionar

```bash
./lab.sh vty a-b2 "show bgp ipv4 unicast summary"
./lab.sh vty a-b2 "show bgp ipv4 unicast 30.0.0.0/16"
./lab.sh vty a-rr "show bgp ipv4 unicast 20.0.4.0/22"   # ORIGIN incomplete
```

Ver la configuración: `configs/a-b2/frr.conf`.
