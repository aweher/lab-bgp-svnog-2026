# Escenario: dampening (flaps)

AS66 hace oscilar su prefijo hasta que ISP-A lo penaliza.

```bash
./lab.sh escenario flaps on
./lab.sh vty as10 "show bgp ipv4 unicast dampening dampened-paths"
./lab.sh vty as40 "show bgp ipv4 unicast 66.0.0.0/16"      # AS66 quedo sin transito
./lab.sh escenario flaps off
```

## Qué pasa

El escenario quita y vuelve a anunciar `66.0.0.0/16` cuatro veces seguidas (con pausas de
2 s). ISP-A tiene `bgp dampening` activo y, con los valores por defecto, **cuatro
oscilaciones alcanzan** para dejar el prefijo suprimido más de media hora.

## Por qué importa

La recomendación es seguir **RIPE-580**: los valores por defecto de dampening son demasiado
agresivos para Internet y pueden dejar redes fuera de servicio por minutos u horas ante un
par de flaps.

## Para inspeccionar

```bash
./lab.sh vty as10 "show bgp ipv4 unicast dampening dampened-paths"
./lab.sh vty as10 "show bgp ipv4 unicast dampening flap-statistics"
```

Ver también: [as10](../nodos/as10.md).
