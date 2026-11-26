# a-rr — Route reflector y red de clientes (AS20)

Nodo central de **EmpresaA** (AS20). No sale a Internet: junta lo que aprenden los dos
bordes (`a-b1` y `a-b2`) y se lo reparte. Es el ejemplo de **iBGP desde loopback, IGP,
route reflector y multipath iBGP**.

## Rol en la topología

- Loopback `20.0.3.1` = router-id y `update-source` de las sesiones iBGP.
- `20.0.0.1`, `20.0.1.1` y `20.0.4.1` son direcciones de servicio y de prueba en la loopback.
- Origina `20.0.4.0/22` (red de clientes) con `ip route 20.0.4.0/22 Null0` + redistribución
  estática en OSPF.

## IGP

OSPF (`router ospf`) y OSPFv3 (`router ospf6`) corren en el área 0 entre los tres nodos de
AS20 (`a-rr`, `a-b1`, `a-b2`). La loopback es pasiva; los enlaces internos son point-to-point.

## iBGP y route reflector

```text
neighbor iBGP-PG peer-group
neighbor iBGP-PG remote-as 20
neighbor iBGP-PG update-source lo
neighbor 20.0.3.2 peer-group iBGP-PG    # a-b1
neighbor 20.0.3.3 peer-group iBGP-PG    # a-b2
```

- `bgp cluster-id 20.0.3.1` explícito (por defecto ya es el router-id).
- `neighbor iBGP-PG route-reflector-client` en IPv4 e IPv6.
- `maximum-paths ibgp 2` + `bgp bestpath as-path multipath-relax`: instala los dos caminos
  iBGP equivalentes (uno por cada borde) cuando salen por proveedores distintos.

## Para inspeccionar

```bash
./lab.sh vty a-rr "show ip ospf neighbor"
./lab.sh vty a-rr "show bgp ipv4 unicast summary"
./lab.sh vty a-rr "show bgp ipv4 unicast 30.0.0.0/16"
./lab.sh vty a-rr "show ip route 40.0.0.0/16"        # dos next-hops: multipath iBGP
./lab.sh vty a-rr "show bgp ipv4 unicast update-groups"
```

Ver la configuración: `configs/a-rr/frr.conf`.
