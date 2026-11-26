# Escenario: BGP Roles (RFC 9234)

BGP Roles y **OTC** (Only-to-Customer) cortan el route leak sin arreglar el filtro.

```bash
./lab.sh escenario fuga on
./lab.sh escenario roles on
./lab.sh vty as30 "show bgp ipv4 unicast 110.0.0.0/16"     # el camino por AS60 desaparecio
./lab.sh vty as60 "show bgp ipv4 unicast neighbors 10.0.7.2 advertised-routes"
./lab.sh escenario roles off
./lab.sh escenario fuga off
```

## Cómo funciona

Cada extremo declara su rol; el rol se **negocia al abrir la sesión** (por eso `lab.sh` hace
`clear bgp` al activarlo/desactivarlo):

- AS60 declara `local-role customer` hacia ISP-B.
- ISP-B declara `local-role provider` hacia sus clientes dinámicos.

Con roles configurados, AS60 deja de reenviar a un **proveedor** las rutas que aprendió de
otro proveedor (van marcadas con OTC). Aunque el `prefix-list todo out` siga mal, el
leak se corta solo.

## Para inspeccionar

```bash
./lab.sh vty a-b1 "show bgp ipv4 unicast 40.0.0.0/16"      # atributo OTC
```

## Nota operativa

Al ser un parámetro que se negocia al establecerse la sesión, un `recargar`/`arreglar` no
lo re-aplica hasta que se hace `clear bgp` en esas sesiones (lab.sh ya lo hace en `arreglar`).

Ver también: [fuga](fuga.md).
