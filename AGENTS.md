# AGENTS.md — lab-bgp-svnog-2026

Laboratorio de BGP en contenedores (containerlab + FRR + FORT + ExaBGP) para la charla
"BGP es Simple". **No es un repo de código**: no hay git, ni build/lint/typecheck, ni
manifests de dependencias. El README.md es la documentación canónica y está completa;
leelo antes de tocar nada.

## Cómo se usa el lab

Todo pasa por `./lab.sh` (ayuda: `./lab.sh ayuda`). Comandos clave:

```bash
./lab.sh up             # despliega los 15 contenedores
sleep 60                # las sesiones BGP tardan ~1 min en converger
./lab.sh verificar      # pruebas automáticas (scripts/verificar.py)
./lab.sh vty as10 "show bgp summary"   # vtysh en un nodo, comando suelto
./lab.sh estado         # resumen de sesiones de todos los routers
./lab.sh down           # destruye el lab
```

- Los contenedores se llaman `bgp-<nodo>` (`bgp-as10`, `bgp-a-b1`, …). 11 routers FRR,
  más `ixp-sw`, `fort`, `rpki-repo` y `mitig`.
- `./lab.sh vty <nodo>` (sin comando) abre vtysh interactivo; `./lab.sh sh <nodo>` abre
  un shell en el contenedor.
- Requisitos: Docker, IPv6 habilitado en el kernel, y containerlab (o el propio `lab.sh`
  lo corre desde `ghcr.io/srl-labs/clab`). Funciona 100% offline una vez bajadas las
  imágenes.

## Lo que un agente tiende a errar

- **Las "pruebas" no son unitarias**: `verificar` consulta el estado BGP en vivo de los
  contenedores. Necesitan el lab desplegado y convergido. `./lab.sh verificar --sin-ipv6`
  omite las pruebas de IPv6.
- **Config vs. estado corriendo**: `configs/<nodo>/frr.conf` es la fuente de verdad.
  `./lab.sh recargar <nodo>` re-aplica ese archivo con `frr-reload.py` (sin reiniciar el
  contenedor). `escenario …` y `romper <n>` cambian la config **en vivo** vía vtysh, no
  los archivos. `./lab.sh arreglar` restaura todos los routers desde `frr.conf`.
- **Sesiones que negocian al abrir**: algunos parámetros (BGP Roles/OTC, password) se
  negocian al establecerse la sesión. Tras un `recargar`/`arreglar` hay que hacer
  `clear bgp` en esas sesiones (lab.sh ya lo hace en `arreglar`).
- **RPKI**: los ROA no están en `rpki/repo`; se cargan como SLURM en `fort/slurm.json`.
  FORT los relee cada 60 s (ciclo de validación). El trust anchor (`rpki/`) solo se
  regenera si cambia la IP del repositorio: `./rpki/generar-ta.sh <ip>`.
- **Doble familia / no-numerado**: muchas sesiones son un peer por familia (IPv4 e IPv6
  por separado) o usan next-hop IPv6 para rutas IPv4 (RFC 8950). No asumir que un vecino
  = una sesión.

## Convenciones de configuración FRR

- Comentarios y documentación en español; cada `frr.conf` arranca con un encabezado que
  indica nodo, ASN y temas que ilustra. Mantener ese estilo al editar.
- `configs/<nodo>/daemons` activa los daemons por nodo (a-b1 usa zebra, mgmtd, staticd,
  bgpd, ospfd, ospf6d, bfdd, pbrd; `bgpd_options` lleva `-M rpki` para validación de
  origen). `configs/vtysh.conf` solo tiene `service integrated-vtysh-config`.
- Prefijos "naileados" con `ip route <pfx> Null0 250` para poder originarlos por
  `network`; `no bgp default ipv4-unicast` en todos los routers.

## Escenarios y diagnóstico

`./lab.sh escenario <nombre> on|off` activa/desactiva `secuestro`, `fuga`, `roles`,
`rtbh`, `gshut`, `flaps`. `./lab.sh romper <1-7>` introduce una falla para diagnosticar
(consigna + solución en la sección "Diagnóstico" del README). `./lab.sh arreglar` deshace
fallas y escenarios.
