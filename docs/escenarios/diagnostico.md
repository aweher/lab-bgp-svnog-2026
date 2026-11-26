# Diagnóstico: las 7 fallas

`./lab.sh romper <n>` introduce una falla. La consigna es encontrarla con comandos `show`
y corregirla. `./lab.sh arreglar` vuelve todo a la configuración original.

| Falla | Síntoma inicial | Causa raíz |
|---|---|---|
| 1 | La sesión entre `as60` e ISP-A no levanta | ASN remoto incorrecto |
| 2 | La sesión entre `as30` y `a-b2` no levanta | Autenticación (MD5) |
| 3 | `as50` perdió las rutas IPv4 de su tránsito | Familia no activada |
| 4 | `as50` tiene la sesión arriba y no recibe ni anuncia | Falta la política (RFC 8212) |
| 5 | `a-rr` y `a-b2` dejaron de usar las rutas por `a-b1` | Next-hop inaccesible |
| 6 | Internet dejó de ver `60.0.0.0/16` | `network` sin ruta exacta |
| 7 | La sesión entre `as30` y el route server no levanta | TTL security de un solo lado |

## Pistas y soluciones

1. **ASN remoto incorrecto.** `show bgp neighbors 10.0.6.1` en `as10` muestra
   `OPEN Message Error/Bad Peer AS`. En `as60` el vecino quedó con `remote-as 11`.
   Arreglo: `neighbor 10.0.6.2 remote-as 10`.

2. **Autenticación.** La sesión queda en `Connect` o `Active` y no hay ninguna
   notificación: los segmentos TCP con MD5 incorrecto se descartan en silencio. Las
   contraseñas no coinciden. Arreglo: alinear el `password` de `as30` y `a-b2`.

3. **Familia no activada.** `show bgp summary` en `as50` muestra `NoNeg` en IPv4 mientras
   IPv6 sigue funcionando. En `as40` falta `neighbor 10.0.5.1 activate` en IPv4.

4. **Falta la política.** `show bgp ipv4 unicast summary` en `as50` muestra `(Policy)`.
   Sin un filtro de entrada, la RFC 8212 impide aceptar rutas. Arreglo: volver a poner
   `route-map transito-in in`.

5. **Next-hop inaccesible.** `show bgp ipv4 unicast 110.0.0.0/16` en `a-rr` muestra
   `inaccessible`. En `a-b1` falta `next-hop-self` hacia el route reflector.

6. **`network` sin ruta exacta.** `show bgp ipv4 unicast 60.0.0.0/16` en `as60` muestra
   que no hay mejor camino. Falta la ruta estática `ip route 60.0.0.0/16 Null0 250` que
   sostiene el anuncio.

7. **TTL security de un solo lado.** El route server espera paquetes con TTL 255 y `as30`
   volvió a enviarlos con TTL 1. Falta `ttl-security hops 1` en `as30`.

## Flujo sugerido

```bash
./lab.sh romper 3
./lab.sh estado                    # ¿qué sesión se ve rara?
./lab.sh vty as50 "show bgp summary"
./lab.sh arreglar
```
