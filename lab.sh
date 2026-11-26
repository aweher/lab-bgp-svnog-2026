#!/usr/bin/env bash
# Laboratorio "BGP es Simple": comandos de uso diario.
# Uso: ./lab.sh ayuda
set -uo pipefail
cd "$(dirname "$0")"
TOPO=bgplab.clab.yml
P=bgp-                                   # prefijo de los contenedores
ROUTERS="a-rr a-b1 a-b2 as10 as30 as40 as41 as50 as60 as66 rs"
CLAB_IMG=ghcr.io/srl-labs/clab:latest

SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
D="docker"; docker info >/dev/null 2>&1 || D="$SUDO docker"

clab() {
  if command -v containerlab >/dev/null 2>&1; then
    $SUDO containerlab "$@"
  else
    # Sin containerlab instalado: se usa su imagen oficial
    $D run --rm -t --privileged --network host --pid host \
      -v /var/run/docker.sock:/var/run/docker.sock -v /var/run/netns:/var/run/netns \
      -v /etc/hosts:/etc/hosts -v /var/lib/docker/containers:/var/lib/docker/containers \
      -v "$PWD":"$PWD" -w "$PWD" "$CLAB_IMG" containerlab "$@"
  fi
}
vty()  { local n=$1; shift; $D exec "$P$n" vtysh "$@"; }
cfg()  { local n=$1; shift; local a=(-c "configure terminal"); for c in "$@"; do a+=(-c "$c"); done; vty "$n" "${a[@]}" >/dev/null; }
recargar() { for n in "$@"; do $D exec "$P$n" /usr/lib/frr/frr-reload.py --reload /etc/frr/frr.conf >/dev/null 2>&1 && echo "  $n: configuracion original restaurada"; done; }

ayuda() { cat <<'TXT'
Uso: ./lab.sh <comando>

  up                      Despliega el laboratorio
  down                    Lo destruye
  estado                  Sesiones BGP de todos los routers
  verificar               Pruebas automaticas del laboratorio
  vty <nodo> [comando]    Consola de FRR (vtysh) o un comando suelto
                          ej: ./lab.sh vty a-b1 "show bgp ipv4 unicast"
  sh <nodo>               Shell del contenedor
  nodos                   Lista de nodos
  recargar <nodo...>      Vuelve un router a su configuracion del repositorio

  escenario <nombre> on|off
      secuestro   AS66 anuncia 50.0.1.0/24, un prefijo de AS50
      fuga        AS60 reanuncia a ISP-B lo que aprende de ISP-A (route leak)
      roles       Activa BGP Roles entre AS60 e ISP-B (corta la fuga)
      rtbh        AS20 pide a ISP-A descartar el trafico hacia 20.0.1.1
      gshut       AS20 saca de servicio el enlace con ISP-A sin cortar trafico
      flaps       AS66 hace oscilar su prefijo hasta que ISP-A lo penaliza
                  (off = ISP-A levanta la penalizacion)

  romper <1-7>            Introduce una falla para diagnosticar (ver README)
  arreglar                Deshace todas las fallas y escenarios
TXT
}

escenario() {
  local e=${1:-} s=${2:-}
  case "$e:$s" in
    secuestro:on)  cfg as66 "router bgp 66" "address-family ipv4 unicast" "network 50.0.1.0/24" ;;
    secuestro:off) cfg as66 "router bgp 66" "address-family ipv4 unicast" "no network 50.0.1.0/24" ;;
    fuga:on)       cfg as60 "router bgp 60" "neighbor 10.0.7.2 prefix-list todo out" ;;
    fuga:off)      cfg as60 "router bgp 60" "neighbor 10.0.7.2 prefix-list redes out" ;;
    roles:on)      cfg as60 "router bgp 60" "neighbor 10.0.7.2 local-role customer"
                   cfg as30 "router bgp 30" "neighbor CLIENTES-DIN local-role provider"
                   vty as60 -c "clear bgp 10.0.7.2" >/dev/null ;;   # el rol se negocia al abrir la sesion
    roles:off)     cfg as60 "router bgp 60" "no neighbor 10.0.7.2 local-role customer"
                   cfg as30 "router bgp 30" "no neighbor CLIENTES-DIN local-role provider"
                   vty as60 -c "clear bgp 10.0.7.2" >/dev/null ;;
    rtbh:on)       cfg a-b1 "ip route 20.0.1.1/32 Null0" "router bgp 20" "address-family ipv4 unicast" "network 20.0.1.1/32" ;;
    rtbh:off)      cfg a-b1 "no ip route 20.0.1.1/32 Null0" "router bgp 20" "address-family ipv4 unicast" "no network 20.0.1.1/32" ;;
    gshut:on)      cfg a-b1 "router bgp 20" "neighbor 10.0.1.2 graceful-shutdown" ;;
    gshut:off)     cfg a-b1 "router bgp 20" "no neighbor 10.0.1.2 graceful-shutdown" ;;
    flaps:on)      for i in 1 2 3 4; do
                     cfg as66 "router bgp 66" "address-family ipv4 unicast" "no network 66.0.0.0/16"; sleep 2
                     cfg as66 "router bgp 66" "address-family ipv4 unicast" "network 66.0.0.0/16"; sleep 2
                     echo "  oscilacion $i de 4"
                   done ;;
    flaps:off)     cfg as10 "router bgp 10" "address-family ipv4 unicast" "no bgp dampening" "bgp dampening" ;;
    *) echo "Escenario u opcion desconocidos. Ver ./lab.sh ayuda"; return 1 ;;
  esac
  echo "Escenario $e: $s"
}

romper() {
  case "${1:-}" in
    1) cfg as60 "router bgp 60" "no neighbor 10.0.6.2" "neighbor 10.0.6.2 remote-as 11" "neighbor 10.0.6.2 prefix-list todo in" "neighbor 10.0.6.2 prefix-list redes out" ;;
    2) cfg as30 "router bgp 30" "neighbor 10.0.2.1 password otr4cl4v3" ;;
    3) cfg as40 "router bgp 40" "address-family ipv4 unicast" "no neighbor 10.0.5.1 activate" ;;
    4) cfg as50 "router bgp 50" "address-family ipv4 unicast" "no neighbor 10.0.5.2 route-map transito-in in" ;;
    5) cfg a-b1 "router bgp 20" "address-family ipv4 unicast" "no neighbor 20.0.3.1 next-hop-self" ;;
    6) cfg as60 "no ip route 60.0.0.0/16 Null0 250" ;;
    7) cfg as30 "router bgp 30" "no neighbor 192.168.0.1 ttl-security hops 1" ;;
    *) echo "Uso: ./lab.sh romper <1-7>"; return 1 ;;
  esac
  echo "Falla $1 introducida. Pista y solucion en el README (seccion Diagnostico)."
}

case "${1:-ayuda}" in
  up)        clab deploy -t "$TOPO" && echo && echo "Listo. Esperar 60 segundos y correr: ./lab.sh verificar" ;;
  down)      clab destroy -t "$TOPO" --cleanup ;;
  estado)    for n in $ROUTERS; do echo "=== $n"; vty "$n" -c "show bgp summary" 2>&1 | grep -E '^\*?[0-9a-f:.]+ +4|^eth[0-9]+ +4|Summary' ; done ;;
  verificar) shift; python3 scripts/verificar.py "$@" ;;
  vty)       shift; n=${1:?falta el nodo}; shift
             if [ $# -eq 0 ]; then $D exec -it "$P$n" vtysh; else vty "$n" -c "$*"; fi ;;
  sh)        $D exec -it "$P${2:?falta el nodo}" sh ;;
  nodos)     echo "Routers FRR: $ROUTERS"; echo "Otros: ixp-sw fort rpki-repo mitig" ;;
  recargar)  shift; recargar "$@" ;;
  escenario) shift; escenario "$@" ;;
  romper)    shift; romper "$@" ;;
  arreglar)  recargar $ROUTERS
             # Sesiones cuyos parametros se negocian al abrir: se reinician para aplicar lo restaurado
             vty as60 -c "clear bgp 10.0.7.2" >/dev/null 2>&1; vty as60 -c "clear bgp 10.0.6.2" >/dev/null 2>&1
             vty as30 -c "clear bgp 192.168.0.1" >/dev/null 2>&1
             echo "Esperar 30 segundos y correr: ./lab.sh verificar" ;;
  *)         ayuda ;;
esac
