#!/usr/bin/env python3
"""Pruebas automaticas del laboratorio "BGP es Simple".

Uso:  ./lab.sh verificar            todas las pruebas
      ./lab.sh verificar --sin-ipv6 omite las pruebas de IPv6
"""
import json
import subprocess
import sys

P = "bgp-"
SIN_V6 = "--sin-ipv6" in sys.argv
ok = fallas = 0


def docker(*args):
    cmd = ["docker", *args]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0 and "permission denied" in r.stderr.lower():
        r = subprocess.run(["sudo", *cmd], capture_output=True, text=True)
    return r


def vty(nodo, comando):
    return docker("exec", P + nodo, "vtysh", "-c", comando).stdout


def vjson(nodo, comando):
    try:
        return json.loads(vty(nodo, comando + " json"))
    except ValueError:
        return {}


def prueba(nombre, condicion, detalle=""):
    global ok, fallas
    if condicion:
        ok += 1
        print(f"  [ OK ]  {nombre}")
    else:
        fallas += 1
        print(f"  [FALLA] {nombre}" + (f"  ->  {detalle}" if detalle else ""))


def caminos(nodo, prefijo, af="ipv4"):
    return vjson(nodo, f"show bgp {af} unicast {prefijo}").get("paths", [])


def mejor(nodo, prefijo, af="ipv4"):
    for c in caminos(nodo, prefijo, af):
        if c.get("bestpath", {}).get("overall"):
            return c
    return {}


def aspath(c):
    return c.get("aspath", {}).get("string", "")


def sesiones(nodo, af):
    d = vjson(nodo, f"show bgp {af} unicast summary")
    return {k: v.get("state") for k, v in d.get("peers", {}).items()}


def titulo(t):
    print(f"\n{t}")


# ------------------------------------------------------------------ contenedores
titulo("Contenedores")
nodos = "a-rr a-b1 a-b2 as10 as30 as40 as41 as50 as60 as66 rs ixp-sw fort rpki-repo mitig".split()
arriba = docker("ps", "--format", "{{.Names}}").stdout.split()
faltan = [n for n in nodos if P + n not in arriba]
prueba("los 15 contenedores estan corriendo", not faltan, "faltan: " + " ".join(faltan))

# ------------------------------------------------------------------ sesiones
titulo("Sesiones BGP IPv4")
V4 = {
    "a-rr": ["20.0.3.2", "20.0.3.3"],
    "a-b1": ["20.0.3.1", "10.0.1.2"],
    "a-b2": ["20.0.3.1", "10.0.2.2", "192.168.0.1"],
    "as10": ["10.0.1.1", "10.0.6.1", "10.0.8.1"],
    "as30": ["10.0.2.1", "10.0.4.2", "10.0.7.1", "192.168.0.1"],
    "as40": ["10.0.4.1", "10.0.5.1"],
    "as60": ["10.0.6.2", "10.0.7.2"],
    "as66": ["10.0.8.2"],
    "rs": ["192.168.0.20", "192.168.0.30"],
}
for nodo, vecinos in V4.items():
    s = sesiones(nodo, "ipv4")
    malas = [v for v in vecinos if s.get(v) != "Established"]
    prueba(f"{nodo}: {len(vecinos)} sesiones establecidas", not malas, "sin establecer: " + " ".join(malas))

if not SIN_V6:
    titulo("Sesiones BGP sobre IPv6 y sin numerar")
    V6 = {
        "a-b1": ("ipv6", ["2001:db8:0:1::2"]),
        "a-b2": ("ipv6", ["2001:db8:100::1"]),
        "as10": ("ipv4", ["2001:db8:0:3::2"]),
        "as40": ("ipv4", ["2001:db8:0:3::1", "eth3"]),
        "as41": ("ipv4", ["eth1"]),
        "as50": ("ipv4", ["2001:db8:100::1"]),
        "rs": ("ipv6", ["2001:db8:100::20", "2001:db8:100::50"]),
    }
    for nodo, (af, vecinos) in V6.items():
        s = sesiones(nodo, af)
        malas = [v for v in vecinos if s.get(v) != "Established"]
        prueba(f"{nodo}: {' '.join(vecinos)}", not malas, "sin establecer: " + " ".join(malas))

# ------------------------------------------------------------------ IGP + iBGP
titulo("AS20: IGP, iBGP y route reflector")
ospf = vty("a-rr", "show ip ospf neighbor")
prueba("a-rr tiene 2 vecinos OSPF en Full", ospf.count("Full") == 2)
c = mejor("a-b1", "30.0.0.0/16")
prueba("a-b1 recibe 30.0.0.0/16 reflejada (ORIGINATOR_ID y CLUSTER_LIST)",
       "originatorId" in c and "clusterList" in c, "falta el atributo de reflexion")
multi = [x for x in caminos("a-rr", "40.0.0.0/16") if x.get("multipath") or x.get("bestpath", {}).get("overall")]
prueba("a-rr usa los dos bordes para 40.0.0.0/16 (multipath iBGP)", len(multi) == 2, f"{len(multi)} caminos en uso")
orig = {x.get("origin") for x in caminos("a-rr", "20.0.4.0/22")}
prueba("20.0.4.0/22 llega con ORIGIN IGP (network) e incomplete (redistribucion)",
       {"IGP", "incomplete"} <= orig, f"origenes vistos: {sorted(orig)}")

# ------------------------------------------------------------------ politicas
titulo("Politicas")
c = mejor("a-rr", "50.0.0.0/16")
prueba("AS20 prefiere el IXP para llegar a AS50 (local-preference 200)",
       c.get("locPrf") == 200 and aspath(c) == "50", f"locPrf={c.get('locPrf')} camino='{aspath(c)}'")
c = mejor("as40", "20.0.0.0/21")
prueba("AS20 sale con prepend hacia sus proveedores", aspath(c).endswith("20 20"), f"camino='{aspath(c)}'")
prueba("los /22 de AS20 no pasan de sus proveedores (no-advertise)", not caminos("as40", "20.0.0.0/22"))
rutas = vjson("as40", "show ip route 20.0.0.0/21").get("20.0.0.0/21", [{}])[0].get("nexthops", [])
prueba("AS40 reparte hacia 20.0.0.0/21 entre AS10 y AS30 (multipath-relax)", len(rutas) == 2, f"{len(rutas)} next-hops")
tabla = vjson("as60", "show bgp ipv4 unicast").get("routes", {})
via30 = [p for p, cs in tabla.items() for x in cs if x.get("peerId") == "10.0.7.2"]
prueba("AS60 recibe de ISP-B solamente la ruta por defecto", via30 == ["0.0.0.0/0"], f"recibe: {via30}")
c = [x for x in caminos("a-b2", "30.0.0.0/16") if aspath(x) == "30"]
prueba("ISP-B envia MED 30 a AS20", bool(c) and c[0].get("metric") == 30)
c = mejor("as10", "20.0.0.0/21")
com = c.get("community", {}).get("string", "")
prueba("ISP-A marca las rutas de clientes con la comunidad 10:100", "10:100" in com, f"comunidades: '{com}'")
c = mejor("as30", "20.0.0.0/21")
lc = c.get("largeCommunity", {}).get("string", "")
prueba("ISP-B marca las rutas de clientes con la large community 30:1:100", "30:1:100" in lc, f"large: '{lc}'")

# ------------------------------------------------------------------ IXP
titulo("IXP")
c = [x for x in caminos("as30", "20.0.0.0/21") if x.get("peer", {}).get("peerId") == "192.168.0.1"]
nh = c[0].get("nexthops", [{}])[0].get("ip") if c else None
prueba("el route server no cambia el next-hop (192.168.0.20)", nh == "192.168.0.20", f"next-hop={nh}")
prueba("el route server no agrega el AS100 al AS-PATH", bool(c) and "100" not in aspath(c[0]).split())
s = vjson("as30", "show bgp ipv4 unicast summary").get("peers", {})
prueba("ISP-B acepta a AS60 como vecino dinamico", s.get("10.0.7.1", {}).get("dynamicPeer") is True)

# ------------------------------------------------------------------ seguridad
titulo("Seguridad")
rtr = vty("a-b1", "show rpki cache-connection")
prueba("a-b1 esta conectado al validador FORT por RTR", "connected" in rtr.lower(), rtr.strip().splitlines()[-1] if rtr.strip() else "")
n4 = vty("a-b1", "show rpki prefix-count")
prueba("FORT entrega los ROA del archivo SLURM", "IPv4" in n4 and " 6" in n4, n4.strip().replace("\n", " "))
st = lambda p: mejor("a-b1", p).get("rpkiValidationState")
prueba("40.0.0.0/16 figura como valida", st("40.0.0.0/16") == "valid", str(st("40.0.0.0/16")))
prueba("66.0.0.0/16 (sin ROA) figura como no encontrada", st("66.0.0.0/16") == "not found", str(st("66.0.0.0/16")))
c = mejor("a-b1", "40.0.0.0/16")
prueba("las rutas de un proveedor llegan con el atributo OTC (BGP Roles)", "otc" in json.dumps(c).lower())
bfd = vjson("a-b1", "show bfd peers")
prueba("BFD arriba entre a-b1 e ISP-A", any(p.get("status") == "up" for p in bfd) if isinstance(bfd, list) else False)
fs = vty("a-b1", "show bgp ipv4 flowspec detail")
prueba("a-b1 recibe la regla FlowSpec del controlador", "20.0.1.1/32" in fs and "Source Port = 123" in fs)

# ------------------------------------------------------------------ datos
titulo("Plano de datos")
r = docker("exec", P + "as40", "ping", "-c", "2", "-W", "1", "-I", "40.0.0.1", "20.0.4.1")
prueba("ping de AS40 a la red de clientes de AS20 (20.0.4.1)", r.returncode == 0)
r = docker("exec", P + "as60", "ping", "-c", "2", "-W", "1", "-I", "60.0.0.1", "50.0.0.1")
prueba("ping de AS60 a AS50 (50.0.0.1)", r.returncode == 0)

if not SIN_V6:
    titulo("IPv6 y RFC 8950")
    c = mejor("as40", "41.0.0.0/16")
    nh = c.get("nexthops", [{}])[0]
    prueba("41.0.0.0/16 llega a AS40 con next-hop IPv6 (RFC 8950)", nh.get("afi") == "ipv6", f"next-hop={nh.get('ip')}")
    c = mejor("as40", "2001:db8:20::/48", "ipv6")
    prueba("AS40 conoce 2001:db8:20::/48", bool(c))
    c = [x for x in caminos("as50", "20.0.0.0/21") if aspath(x) == "20"]
    nh = c[0].get("nexthops", [{}])[0].get("ip") if c else None
    prueba("AS50 recibe IPv4 por su sesion IPv6 con el RS, con next-hop IPv4", nh == "192.168.0.20", f"next-hop={nh}")
    r = docker("exec", P + "as41", "ping", "-c", "2", "-W", "1", "-I", "41.0.0.1", "20.0.4.1")
    prueba("ping de AS41 a AS20 (IPv4 sobre enlace sin numerar)", r.returncode == 0)
    r = docker("exec", P + "as40", "ping", "-6", "-c", "2", "-W", "1", "-I", "2001:db8:40::1", "2001:db8:20::1")
    prueba("ping IPv6 de AS40 a AS20 (2001:db8:20::1)", r.returncode == 0)

print(f"\nResultado: {ok} pruebas correctas, {fallas} con falla.")
sys.exit(1 if fallas else 0)
