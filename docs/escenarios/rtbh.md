# Escenario: blackhole remoto (RTBH)

AS20 le pide a ISP-A que descarte el tráfico hacia la IP atacada `20.0.1.1`.

```bash
docker exec bgp-as66 ping -c 2 -I 66.0.0.1 20.0.1.1        # responde
./lab.sh escenario rtbh on
./lab.sh vty as10 "show bgp ipv4 unicast 20.0.1.1/32"      # comunidad blackhole
./lab.sh vty as10 "show ip route 20.0.1.1/32"              # instalada como descarte
docker exec bgp-as66 ping -c 2 -I 66.0.0.1 20.0.1.1        # ya no responde
docker exec bgp-as40 ping -c 2 -I 40.0.0.1 20.0.1.1        # ¿y desde AS40?
./lab.sh escenario rtbh off
```

## Qué pasa

1. `a-b1` origina `20.0.1.1/32` con la comunidad `65535:666 no-export`.
2. ISP-A (`as10`) la matchea con `route-map de-as20`, setea `next-hop 192.0.2.1` (una ruta
   estática a Null0) y la instala como descarte.
3. El tráfico de AS66 hacia `20.0.1.1` entra por ISP-A y muere ahí.

## Detalles importantes

- **El blackhole hay que pedirlo a todos los proveedores.** El tráfico que entra por ISP-B
  sigue llegando: AS20 solo le pidió el descarte a ISP-A.
- **El `/32` es inválido para RPKI** (el ROA de AS20 admite hasta `/22`). Un proveedor que
  valida debe **exceptuar** estas rutas de la validación de origen.

## Para inspeccionar

```bash
./lab.sh vty as10 "show ip route 192.0.2.1/32"             # el next-hop de descarte
```

Ver también: [as10](../nodos/as10.md), [a-b1](../nodos/a-b1.md).
