# Escenario: graceful shutdown (gshut)

AS20 saca de servicio el enlace con ISP-A **sin cortar el tráfico**.

```bash
./lab.sh vty as10 "show bgp ipv4 unicast 20.0.0.0/21"
./lab.sh escenario gshut on
./lab.sh vty as10 "show bgp ipv4 unicast 20.0.0.0/21"      # local-preference 0
./lab.sh escenario gshut off
```

## Qué pasa

`a-b1` activa `neighbor 10.0.1.2 graceful-shutdown`, que envía la comunidad
**GRACEFUL_SHUTDOWN** (`65535:0`). ISP-A la interpreta y baja a `0` la local-preference de
esas rutas: el camino por ISP-B pasa a ser preferido y el tráfico se mueve solo, antes de
tirar la sesión o el enlace.

## Para inspeccionar

```bash
./lab.sh vty as10 "show bgp ipv4 unicast 20.0.0.0/21"      # el camino por ISP-B queda best
```

Ver también: [a-b1](../nodos/a-b1.md).
