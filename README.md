# Laboratorio "BGP es Simple"

Laboratorio de BGP para acompañar la presentación **BGP es Simple** (@arielweher, CC BY-SA).
Levanta una pequeña Internet con 11 routers FRR, un IXP con route server y un validador
RPKI, y deja listos los escenarios que se ven en las diapositivas: políticas, comunidades,
secuestro de prefijos, route leak, blackhole, FlowSpec y diagnóstico de fallas.

Todo corre en contenedores sobre una sola máquina y no necesita Internet una vez
descargadas las imágenes.

## Requisitos

- Linux con Docker y unos 2 GB de RAM libres.
- IPv6 habilitado en el kernel (varias sesiones del laboratorio corren sobre IPv6).
- [containerlab](https://containerlab.dev/install/) reciente (la topología se validó con la 0.83). Si no está instalado,
  `lab.sh` lo ejecuta desde su imagen oficial (`ghcr.io/srl-labs/clab`).
- `python3` para las pruebas automáticas.

Imágenes que se usan:

| Imagen | Uso |
|---|---|
| `quay.io/frrouting/frr:10.7.1` | Los 11 routers y el switch del IXP |
| `nicmx/fort-validator:1.6.7` | Validador RPKI y repositorio rsync local |
| `ghcr.io/exa-networks/exabgp:latest` | Controlador que origina FlowSpec |

## Inicio rápido

```bash
./lab.sh up          # despliega los 15 contenedores
sleep 60             # las sesiones tardan cerca de un minuto en converger
./lab.sh verificar   # pruebas automáticas
./lab.sh estado      # sesiones BGP de todos los routers
./lab.sh vty a-b1    # consola de FRR del borde de AS20
./lab.sh down        # destruye el laboratorio
```

`./lab.sh ayuda` muestra todos los comandos. Un comando suelto se corre así:

```bash
./lab.sh vty as40 "show bgp ipv4 unicast"
```

## Topología

```
        +--------+            +--------+
        |  as41  |            |  as50  +---------------------+
        +---+----+            +---+----+                     |
            |                     |                          |
        +---+---------------------+----+                     |
        |             as40             |                     |
        |          "Internet"          |                     |
        +------+----------------+------+                     |
               |                |                            |
+--------+  +--+-----+      +---+----+                  +----+-----+
|  as66  +--+  as10  |      |  as30  +------------------+  ixp-sw  |
+--------+  | ISP-A  |      | ISP-B  |                  | LAN IXP  |
            +-+----+-+      +-+----+-+                  +--+----+--+
              |    |          |    |                       |    |
              |    |  +----+  |    |                       |  +-+--+
              |    +--+as60+--+    |                       |  | rs |
              |       +----+       |                       |  +----+
              |                    |                       |
          +---+----+          +----+---+                   |
          |  a-b1  +----------+  a-b2  +-------------------+
          +-+----+-+          +---+----+
            |    |                |
            |    +-------+--------+
            |            |
        +---+---+     +--+---+
        | mitig |     | a-rr |
        +-------+     +------+
```

| Nodo | ASN | Rol | Prefijos |
|---|---|---|---|
| `a-rr` | 20 | EmpresaA: route reflector y red de clientes | 20.0.0.0/21, 2001:db8:20::/48 |
| `a-b1` | 20 | EmpresaA: borde hacia ISP-A | |
| `a-b2` | 20 | EmpresaA: borde hacia ISP-B y el IXP | |
| `as10` | 10 | ISP-A, tránsito de AS20, AS60 y AS66 | 110.0.0.0/16, 2001:db8:10::/48 |
| `as30` | 30 | ISP-B, tránsito de AS20 y AS60, miembro del IXP | 30.0.0.0/16, 2001:db8:30::/48 |
| `as40` | 40 | "Internet", tránsito de AS10, AS30, AS41 y AS50 | 40.0.0.0/16, 2001:db8:40::/48 |
| `as41` | 41 | Red remota, enlace sin numerar | 41.0.0.0/16, 2001:db8:41::/48 |
| `as50` | 50 | Red de contenido: tránsito por AS40 y peering en el IXP | 50.0.0.0/16, 2001:db8:50::/48 |
| `as60` | 60 | Cliente multihomed de ISP-A e ISP-B | 60.0.0.0/16 |
| `as66` | 66 | Cliente de ISP-A, origen del secuestro | 66.0.0.0/16 |
| `rs` | 100 | Route server del IXP | |
| `ixp-sw` | | Switch del IXP (bridge Linux) | 192.168.0.0/24, 2001:db8:100::/64 |
| `fort` | | Validador RPKI (RTR en el puerto 3323) | 172.31.255.250 |
| `rpki-repo` | | Repositorio RPKI local (rsync) | 172.31.255.251 |
| `mitig` | 20 | Controlador de mitigación (ExaBGP) | |

Cada router tiene en su loopback la primera IP de su prefijo (`40.0.0.1`, `50.0.0.1`, etc.)
para hacer pruebas de ping y traceroute. En AS20: `20.0.0.1` y `20.0.4.1` son hosts de
prueba y `20.0.1.1` es la IP "atacada" de los escenarios de blackhole y FlowSpec.

Enlaces punto a punto:

| Enlace | IPv4 | IPv6 |
|---|---|---|
| a-b1 – as10 | 10.0.1.0/30 | 2001:db8:0:1::/64 |
| a-b2 – as30 | 10.0.2.0/30 | 2001:db8:0:2::/64 |
| as10 – as40 | 10.0.3.0/30 | 2001:db8:0:3::/64 |
| as30 – as40 | 10.0.4.0/30 | 2001:db8:0:4::/64 |
| as50 – as40 | 10.0.5.0/30 | 2001:db8:0:5::/64 |
| as60 – as10 | 10.0.6.0/30 | |
| as60 – as30 | 10.0.7.0/30 | |
| as66 – as10 | 10.0.8.0/30 | |
| as40 – as41 | sin direcciones | solo link-local |
| AS20 interno | 20.0.3.0/24 (loopbacks .1 a .3) | 2001:db8:20::/48 |

En cada enlace el primer nodo de la tabla usa la `.1` y el segundo la `.2`.
La configuración de cada router está en `configs/<nodo>/frr.conf`, comentada.

## Dónde ver cada tema de la presentación

| Tema | Dónde | Comando para empezar |
|---|---|---|
| eBGP básico, `network`, rutas "naileadas" a Null0 | todos; el más simple es `as40` | `show bgp summary` |
| RFC 8212: sin política no se anuncia nada | `as40` lo desactiva, el resto usa políticas | falla 4 |
| Originar por redistribución (ORIGIN incomplete) | `a-b2` redistribuye OSPF | `show bgp ipv4 unicast 20.0.4.0/22` en `a-rr` |
| iBGP desde loopback, `next-hop-self`, IGP | AS20 con OSPF y OSPFv3 | `show ip ospf neighbor` en `a-rr` |
| Route reflector, ORIGINATOR_ID, CLUSTER_LIST | `a-rr` | `show bgp ipv4 unicast 30.0.0.0/16` en `a-b1` |
| Peer groups y update groups | `a-rr`, `rs` | `show bgp ipv4 unicast update-groups` |
| Vecinos dinámicos (`bgp listen range`) | `as30` acepta a `as60` | `show bgp summary` en `as30` (marca `*`) |
| Full table o tabla parcial | `as60`: completa por ISP-A, default por ISP-B | `show bgp ipv4 unicast` en `as60` |
| Route server de IXP | `rs` | `show bgp ipv4 unicast` en `as30` |
| Multifamilia: doble peer | `a-b1`–`as10`, `a-b2`–`rs` | `show bgp summary` |
| Multifamilia: IPv6 sobre sesión IPv4 | `a-b2`–`as30`, `as30`–`rs` | `show bgp ipv6 unicast summary` |
| Multifamilia: IPv4 sobre sesión IPv6 | `as10`–`as40`, `as50`–`rs` | `show bgp ipv4 unicast summary` |
| IPv4 con next-hop IPv6 (RFC 8950), BGP sin numerar | `as40`–`as41` | `show bgp ipv4 unicast 41.0.0.0/16` en `as40` |
| Prefix-lists | todos | `show ip prefix-list` |
| AS-PATH ACL y expresiones regulares | `as50`, `a-b1`, `a-b2` | `show bgp ipv4 unicast regexp _30$` |
| Route-maps, `on-match goto` | `a-b1`, `a-b2` | `show route-map as10-in` |
| Local preference, prepend, MED | AS20 (política multihomed) | `show bgp ipv4 unicast` en `a-rr` |
| Comunidades clásicas y tabla de comunidades | `as10` (10:100, 10:300), AS20 (20:10, 20:30, 20:100) | `show bgp ipv4 unicast community 10:100` |
| Comunidades bien conocidas (`no-advertise`, `no-export`) | los /22 de AS20 | `show bgp ipv4 unicast 20.0.0.0/22` en `as10` |
| Large communities | `as30` (30:1:100, 30:1:200, 30:1:300) | `show bgp ipv4 unicast large-community 30:1:100` |
| Blackhole / RTBH | `a-b1` pide, `as10` descarta | escenario `rtbh` |
| Graceful shutdown | `a-b1` hacia `as10` | escenario `gshut` |
| Cambios de política sin cortar la sesión | cualquiera | `clear bgp ipv4 unicast 10.0.1.2 soft in` |
| `soft-reconfiguration inbound` | `as60` hacia ISP-A | `show bgp ipv4 unicast neighbors 10.0.6.2 received-routes` |
| Dampening | `as10` | escenario `flaps` |
| Multipath y `multipath-relax` | `as40` (eBGP), `a-rr` (iBGP) | `show ip route 20.0.0.0/21` en `as40` |
| Configuración de un IXP con peer groups | `rs` | `show running-config` en `rs` |
| Autenticación, `ttl-security`, `maximum-prefix` | `rs`, `as10`, `as30` | `show bgp neighbors 192.168.0.20` en `rs` |
| BFD | `a-b1`–`as10` | `show bfd peers` |
| RPKI: validación de origen | `a-b1`, `a-b2`, `as30`, `rs` validan; `as10` y `as40` no | `show rpki prefix-table` |
| BGP Roles y OTC (RFC 9234) | casi todas las sesiones eBGP | `show bgp ipv4 unicast 40.0.0.0/16` en `a-b1` |
| FlowSpec (lado cliente) | `mitig` origina, `a-b1` recibe | `show bgp ipv4 flowspec detail` |
| Diagnóstico de sesiones | fallas 1 a 7 | `./lab.sh romper 1` |

## Recorrido sugerido

### 1. Sesiones y tabla de rutas

```bash
./lab.sh vty as40 "show bgp summary"
./lab.sh vty as40 "show bgp ipv4 unicast"
./lab.sh vty as40 "show running-config"
```

`as40` tiene la configuración más corta: es el ejemplo de "eBGP básico" de la presentación.
Compararla con la de `a-b1`, que ya tiene filtros y políticas.

### 2. Atributos y selección de caminos

```bash
./lab.sh vty a-rr "show bgp ipv4 unicast"
./lab.sh vty a-rr "show bgp ipv4 unicast 50.0.0.0/16"
./lab.sh vty a-b1 "show bgp ipv4 unicast 30.0.0.0/16"
```

Para pensar: ¿por qué AS20 llega a AS50 por el IXP y no por sus proveedores? ¿Qué atributo
decide entre los dos caminos hacia `30.0.0.0/16` en `a-b1`? El motivo de cada elección
aparece entre paréntesis al lado de `best`.

### 3. iBGP y route reflector

```bash
./lab.sh vty a-rr "show bgp ipv4 unicast summary"
./lab.sh vty a-b1 "show bgp ipv4 unicast 30.0.0.0/16"     # ORIGINATOR_ID y CLUSTER_LIST
./lab.sh vty a-rr "show ip route 40.0.0.0/16"             # dos next-hops: multipath iBGP
```

`a-b1` y `a-b2` no tienen sesión entre ellos: todo lo que saben uno del otro pasa por `a-rr`.

### 4. El IXP

```bash
./lab.sh vty rs   "show bgp ipv4 unicast"
./lab.sh vty as30 "show bgp ipv4 unicast 20.0.0.0/21"
```

En `as30`, el camino aprendido del route server conserva el next-hop `192.168.0.20` y no
tiene el AS100 en el AS-PATH. Por eso los miembros necesitan `no bgp enforce-first-as`.
El route server usa `ttl-security hops 1`, así que cada miembro también debe configurarlo.

### 5. Multifamilia e IPv6

```bash
./lab.sh vty as50 "show bgp ipv4 unicast summary"          # IPv4 por una sesión IPv6
./lab.sh vty as40 "show bgp ipv4 unicast 41.0.0.0/16"      # next-hop IPv6 para IPv4
./lab.sh vty as40 "show ip route 41.0.0.0/16"
./lab.sh vty as40 "show bgp neighbors eth3" | grep -i -A3 "extended nexthop"
```

El enlace `as40`–`as41` no tiene ninguna dirección configurada: la sesión usa las
link-local y las rutas IPv4 viajan con next-hop IPv6 gracias a la capacidad de la RFC 8950.

### 6. RPKI

```bash
./lab.sh vty a-b1 "show rpki cache-connection"
./lab.sh vty a-b1 "show rpki prefix-table"
./lab.sh vty a-b1 "show bgp ipv4 unicast"                  # columna V / I / N
./lab.sh vty a-b1 "show rpki prefix 66.0.0.0/16"
```

`66.0.0.0/16` y `41.0.0.0/16` no tienen ROA: figuran como no encontradas y se aceptan igual.

## Escenarios

Cada escenario se activa y se desactiva con `./lab.sh escenario <nombre> on|off`.

### Secuestro de prefijo

```bash
./lab.sh escenario secuestro on
./lab.sh vty as40 "show bgp ipv4 unicast 50.0.1.0/24"      # lo acepta: no valida
./lab.sh vty as30 "show bgp ipv4 unicast 50.0.1.0/24"      # no está: lo descartó por inválido
docker exec bgp-as40 traceroute -n -s 40.0.0.1 50.0.1.1    # el tráfico termina en AS66
./lab.sh escenario secuestro off
```

AS66 anuncia `50.0.1.0/24`, un prefijo más específico de AS50. ISP-A lo acepta porque no
filtra a su cliente, y el secuestro llega hasta donde nadie valida. Los que validan origen
(`a-b1`, `as30`, `rs`) lo descartan.

### Route leak y BGP Roles

```bash
./lab.sh escenario fuga on
./lab.sh vty as30 "show bgp ipv4 unicast 110.0.0.0/16"     # ISP-B prefiere el camino 60 10
./lab.sh escenario roles on
./lab.sh vty as30 "show bgp ipv4 unicast 110.0.0.0/16"     # el camino por AS60 desapareció
./lab.sh vty as60 "show bgp ipv4 unicast neighbors 10.0.7.2 advertised-routes"
./lab.sh escenario roles off
./lab.sh escenario fuga off
```

En la fuga, AS60 aplica hacia ISP-B un filtro de salida que permite todo y le reanuncia lo
que aprendió de ISP-A. ISP-B lo prefiere porque viene de un cliente. La validación de
origen no ayuda: el origen es legítimo. Con roles configurados en los dos extremos, AS60
deja de reenviar a un proveedor las rutas marcadas con OTC, aunque el filtro siga mal.

### Blackhole (RTBH)

```bash
docker exec bgp-as66 ping -c 2 -I 66.0.0.1 20.0.1.1        # responde
./lab.sh escenario rtbh on
./lab.sh vty as10 "show bgp ipv4 unicast 20.0.1.1/32"      # comunidad blackhole
./lab.sh vty as10 "show ip route 20.0.1.1/32"              # instalada como descarte
docker exec bgp-as66 ping -c 2 -I 66.0.0.1 20.0.1.1        # ya no responde
docker exec bgp-as40 ping -c 2 -I 40.0.0.1 20.0.1.1        # ¿y desde AS40?
./lab.sh escenario rtbh off
```

AS20 solo le pidió el descarte a ISP-A. El tráfico que entra por ISP-B sigue llegando:
el blackhole hay que pedirlo a todos los proveedores. Además, el /32 es inválido para RPKI
(el ROA admite hasta /22), así que un proveedor que valida debe exceptuar estas rutas.

### Graceful shutdown

```bash
./lab.sh vty as10 "show bgp ipv4 unicast 20.0.0.0/21"
./lab.sh escenario gshut on
./lab.sh vty as10 "show bgp ipv4 unicast 20.0.0.0/21"      # local-preference 0
./lab.sh escenario gshut off
```

### Dampening

```bash
./lab.sh escenario flaps on
./lab.sh vty as10 "show bgp ipv4 unicast dampening dampened-paths"
./lab.sh vty as40 "show bgp ipv4 unicast 66.0.0.0/16"      # AS66 quedó sin tránsito
./lab.sh escenario flaps off
```

Con los valores por defecto, cuatro oscilaciones alcanzan para dejar el prefijo suprimido
más de media hora. Por eso la recomendación de seguir RIPE-580.

### FlowSpec

```bash
./lab.sh vty a-b1 "show bgp ipv4 flowspec summary"
./lab.sh vty a-b1 "show bgp ipv4 flowspec detail"
```

`mitig` anuncia desde el arranque una regla que descarta UDP con puerto de origen 123 hacia
`20.0.1.1`. La regla está en `configs/mitig/exabgp.conf`. FRR la recibe pero figura como no
instalada: la imagen de FRR no trae `ipset` ni `iptables`, que son los que la aplican.

## Diagnóstico

`./lab.sh romper <n>` introduce una falla. La consigna es encontrarla con comandos `show`
y corregirla. `./lab.sh arreglar` vuelve todo a la configuración original.

| Falla | Síntoma inicial |
|---|---|
| 1 | La sesión entre `as60` e ISP-A no levanta |
| 2 | La sesión entre `as30` y `a-b2` no levanta |
| 3 | `as50` perdió las rutas IPv4 de su tránsito |
| 4 | `as50` tiene la sesión de tránsito arriba y no recibe ni anuncia nada |
| 5 | `a-rr` y `a-b2` dejaron de usar las rutas que entran por `a-b1` |
| 6 | Internet dejó de ver `60.0.0.0/16` |
| 7 | La sesión entre `as30` y el route server no levanta |

<details>
<summary>Pistas y soluciones</summary>

1. **ASN remoto incorrecto.** `show bgp neighbors 10.0.6.1` en `as10` muestra
   `OPEN Message Error/Bad Peer AS`. En `as60` el vecino quedó con `remote-as 11`.
2. **Autenticación.** La sesión queda en `Connect` o `Active` y no hay ninguna notificación:
   los segmentos TCP con MD5 incorrecto se descartan en silencio. Las contraseñas no coinciden.
3. **Familia no activada.** `show bgp summary` en `as50` muestra `NoNeg` en IPv4 mientras
   IPv6 sigue funcionando. En `as40` falta `neighbor 10.0.5.1 activate` en IPv4.
4. **Falta la política.** `show bgp ipv4 unicast summary` en `as50` muestra `(Policy)`.
   Sin un filtro de entrada, la RFC 8212 impide aceptar rutas.
5. **Next-hop inaccesible.** `show bgp ipv4 unicast 110.0.0.0/16` en `a-rr` muestra
   `inaccessible`. En `a-b1` falta `next-hop-self` hacia el route reflector.
6. **`network` sin ruta exacta.** `show bgp ipv4 unicast 60.0.0.0/16` en `as60` muestra
   que no hay mejor camino. Falta la ruta estática a Null0 que sostiene el anuncio.
7. **TTL security de un solo lado.** El route server espera paquetes con TTL 255 y `as30`
   volvió a enviarlos con TTL 1. Falta `ttl-security hops 1` en `as30`.

</details>

## Cómo está armado el RPKI

FORT necesita al menos un ancla de confianza que valide bien. El laboratorio trae una
propia y vacía (`rpki/repo`, servida por rsync desde `rpki-repo`), y todos los ROA se cargan
desde `fort/slurm.json` como excepciones locales (SLURM, RFC 8416). Así el resultado no
depende de Internet ni del estado real del RPKI.

Para agregar o cambiar un ROA se edita `fort/slurm.json`. FORT lo relee en cada ciclo de
validación (60 segundos) y los routers lo reciben por RTR:

```bash
vi fort/slurm.json
docker logs --tail 5 bgp-fort
./lab.sh vty a-b1 "show rpki prefix-table"
```

El ancla de confianza vence a los diez años. Solo hace falta regenerarla si se cambia la
IP del repositorio: `./rpki/generar-ta.sh <ip>` (requiere `openssl`).

## Lo que este laboratorio no cubre

- **ASPA.** FRR 10.7 no implementa la verificación de AS-PATH con ASPA.
- **TCP-AO**, **control plane policing** y **BMP**: no están configurados.
- **bgpq4 e IRR.** Los filtros del laboratorio están escritos a mano. `bgpq4` consulta IRR
  reales, así que se puede probar aparte contra un as-set público.
- **Aplicación de FlowSpec en el plano de datos**: se ve la regla recibida, no el descarte.

## Estructura

```
bgplab.clab.yml     topología de containerlab
lab.sh              comandos de uso diario
configs/<nodo>/     frr.conf y daemons de cada router (+ README por nodo)
configs/mitig/      configuración de ExaBGP
docs/               documentación por nodo y por escenario
fort/               configuración de FORT y archivo SLURM con los ROA
rpki/               ancla de confianza del laboratorio y script para regenerarla
scripts/            pruebas automáticas
```
