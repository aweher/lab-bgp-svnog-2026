# configs/mitig

Configuración del controlador de mitigación `mitig` (ExaBGP), que origina FlowSpec.

## Archivos

- `exabgp.conf` — regla FlowSpec: descartar UDP con puerto de origen 123 (NTP) hacia
  `20.0.1.1`.

## Cómo se usa

`mitig` es vecino iBGP de `a-b1` (`20.0.3.21`) y anuncia la regla desde el arranque:

```bash
./lab.sh vty a-b1 "show bgp ipv4 flowspec summary"
./lab.sh vty a-b1 "show bgp ipv4 flowspec detail"
```

FRR recibe la regla pero la muestra como no instalada: la imagen de FRR no trae `ipset`
ni `iptables`, que son los que la aplican en el plano de datos.

Detalle en `../../docs/nodos/infraestructura.md`.
