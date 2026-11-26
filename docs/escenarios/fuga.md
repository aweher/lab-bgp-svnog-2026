# Escenario: route leak (fuga)

AS60, cliente multihomed, reanuncia a ISP-B todo lo que aprende de ISP-A.

```bash
./lab.sh escenario fuga on
./lab.sh vty as30 "show bgp ipv4 unicast 110.0.0.0/16"     # ISP-B prefiere el camino 60 10
./lab.sh escenario fuga off
```

## Qué pasa

1. AS60 aplica hacia ISP-B el filtro `todo out` (permite todo) en vez de `redes out`.
2. ISP-B recibe por AS60 las rutas de ISP-A (por ejemplo `110.0.0.0/16`) y las prefiere
   porque vienen **de un cliente** (`local-preference 200`).
3. El camino por AS60 (`60 10`) desplaza al camino legítimo directo por AS40.

## Por qué la validación de origen no ayuda

El origen es legítimo: `110.0.0.0/16` sí pertenece a AS10. RPKI lo marca `valid`, así que
los filtros `match rpki invalid` no lo detienen. Es un problema de **política**, no de
origen.

## Para pensar

- ¿Qué filtro debería tener AS60 hacia sus proveedores?
- ¿Qué herramienta detecta que una ruta "bajó" por un cliente que no debería?

Ver también: [roles](roles.md) (la solución con BGP Roles), [as60](../nodos/as60.md).
