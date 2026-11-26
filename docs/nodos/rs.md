# rs — Route server del IXP (AS100)

Route server del IXP. No reenvía tráfico: solo reparte rutas entre los miembros. Es el
ejemplo de los slides **"IXP básico"** e **"IXP con Peer Groups"**.

## Miembros

| Miembro | AS | Sesión |
|---|---|---|
| `192.168.0.20` / `2001:db8:100::20` (a-b2) | 20 | una por familia ("doble peer") |
| `192.168.0.30` (as30) | 30 | una IPv4 con las dos familias |
| `2001:db8:100::50` (as50) | 50 | una IPv6 con las dos familias |

## Peer group y características

```text
neighbor MiembrosDelIXP peer-group
neighbor MiembrosDelIXP password ixp-s3cr3t0
neighbor MiembrosDelIXP passive
neighbor MiembrosDelIXP ttl-security hops 1
neighbor MiembrosDelIXP local-role rs-server
```

En cada address-family:

- `route-server-client`: modo route server (no agrega su ASN al camino).
- `attribute-unchanged next-hop`: no toca el next-hop (el miembro debe tener ruta hacia él).
- `remove-private-AS`: quita ASN privados del camino.
- `send-community both`, `maximum-prefix 100`.
- `route-map miembros-in`: descarta `rpki invalid` y bogons (RFC 1918, default, `/25+`).

El route server **valida RPKI** (sesión RTR contra FORT) y usa `graceful-restart`.

## Para inspeccionar

```bash
./lab.sh vty rs "show running-config"
./lab.sh vty rs "show bgp ipv4 unicast summary"
./lab.sh vty as30 "show bgp ipv4 unicast 20.0.0.0/21"   # next-hop 192.168.0.20, sin AS100
```

Ver la configuración: `configs/rs/frr.conf`.
