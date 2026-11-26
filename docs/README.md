# Documentación del laboratorio

El `README.md` de la raíz es la referencia canónica: topología, requisitos, inicio rápido,
escenarios y diagnóstico. Acá está la documentación desglosada por **nodo** y por
**escenario/tema**, pensada para recorrer el laboratorio junto con la presentación.

## Nodos

Cada router FRR tiene su propia página con rol, vecinos, políticas y comandos para
inspeccionarlo:

- [a-rr](nodos/a-rr.md) — route reflector y red de clientes de AS20
- [a-b1](nodos/a-b1.md) — borde de AS20 hacia ISP-A
- [a-b2](nodos/a-b2.md) — borde de AS20 hacia ISP-B y el IXP
- [as10](nodos/as10.md) — ISP-A
- [as30](nodos/as30.md) — ISP-B
- [as40](nodos/as40.md) — "Internet"
- [as41](nodos/as41.md) — red remota (enlace sin numerar)
- [as50](nodos/as50.md) — red de contenido
- [as60](nodos/as60.md) — cliente multihomed
- [as66](nodos/as66.md) — cliente de ISP-A (origen del secuestro)
- [rs](nodos/rs.md) — route server del IXP
- [infraestructura](nodos/infraestructura.md) — `fort`, `rpki-repo`, `ixp-sw` y `mitig`

## Escenarios y temas

Cada escenario se activa con `./lab.sh escenario <nombre> on|off`:

- [secuestro](escenarios/secuestro.md) — AS66 anuncia un prefijo de AS50
- [fuga](escenarios/fuga.md) — route leak de AS60 hacia ISP-B
- [roles](escenarios/roles.md) — BGP Roles (RFC 9234) corta la fuga
- [rtbh](escenarios/rtbh.md) — blackhole remoto hacia la IP atacada
- [gshut](escenarios/gshut.md) — graceful shutdown del enlace con ISP-A
- [flaps](escenarios/flaps.md) — dampening en ISP-A
- [diagnostico](escenarios/diagnostico.md) — las 7 fallas de `./lab.sh romper`

## Configuración

Dentro de cada `configs/<nodo>/` hay un `README.md` breve con los archivos del nodo y
cómo re-aplicarlos. La fuente de verdad de cada router es `configs/<nodo>/frr.conf`.
