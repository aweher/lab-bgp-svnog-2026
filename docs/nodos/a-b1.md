# a-b1 — Borde de AS20 hacia ISP-A (AS10)

Uno de los dos bordes de **EmpresaA**. Es el nodo con más temas por centímetro cuadrado:
es el ejemplo de **política multihomed** (el slide "ASN Multi Homed: ISP-A"), hace de
cliente de **RTBH**, valida **RPKI** y recibe **FlowSpec**.

## Vecinos

| Vecino | AS | Familia | Notas |
|---|---|---|---|
| `20.0.3.1` (a-rr) | 20 | IPv4+IPv6 | iBGP desde loopback, `next-hop-self` |
| `10.0.1.2` | 10 | IPv4 | eBGP, `password`, `bfd`, `local-role customer strict-mode` |
| `2001:db8:0:1::2` | 10 | IPv6 | "doble peer": una sesión por familia |
| `20.0.3.22` (mitig) | 20 | FlowSpec | iBGP hacia el controlador de mitigación |

## Política multihomed (hacia ISP-A)

- **Salida** `as10-out`:
  - `20.0.1.1/32` (la víctima) sale con la comunidad `65535:666 no-export` → RTBH.
  - Los `/22` de AS20 salen con `no-advertise` (no se propagan más allá de ISP-A).
  - El resto sale con `as-path prepend 20` (hace menos atractivo el camino por ISP-A).
- **Entrada** `as10-in`:
  - `match rpki invalid` → descarte (validación de origen).
  - Rutas con AS30 en el camino → `local-preference 90` (ISP-B es menos preferido).
  - Rutas con AS10 → `local-preference 150`.
  - Todo lo aceptado se marca con la comunidad `20:10` (origen ISP-A).

## RPKI y FlowSpec

- Sesión RTR contra FORT: `rpki cache tcp 172.31.255.250 3323`.
- FlowSpec: `address-family ipv4 flowspec`, `local-install eth1` (la regla del `mitig` se
  aplicaría en `eth1`, el enlace hacia ISP-A).

## Para inspeccionar

```bash
./lab.sh vty a-b1 "show bgp ipv4 unicast"
./lab.sh vty a-b1 "show rpki prefix-table"
./lab.sh vty a-b1 "show bfd peers"
./lab.sh vty a-b1 "show bgp ipv4 flowspec detail"
./lab.sh vty a-b1 "show route-map as10-in"
```

Ver la configuración: `configs/a-b1/frr.conf`.
