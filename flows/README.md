# Synthesis flows

Each directory contains a matched Design Compiler synthesis script, PrimeTime analysis script, and tool setup files.

| Flow | Synthesis strategy | Target libraries |
|---|---|---|
| `baseline` | `compile` followed by incremental mapping | LVT |
| `clock_gating` | `compile_ultra -gate_clock` with 8-bit minimum bank width and fanout limited to 32 | LVT |
| `clock_gating_multi_vt` | Clock-gated `compile_ultra` with threshold-voltage groups enabled | LVT, SVT, HVT |

Run the tools from the repository root because the scripts use repository-relative paths. The synthesis scripts write the post-synthesis netlist and SDC under `saved/sha256_core/synthesis/`. PrimeTime reads activity from `saved/sha256_core/simulation/sha256_core.vcd` and writes timing/power reports in the current directory.

The technology databases are not redistributable and are excluded by `.gitignore`. Supply these files locally in `tech/STcmos65/`:

```text
CORE65LPLVT_nom_1.20V_25C.db
CORE65LPSVT_nom_1.20V_25C.db
CORE65LPHVT_nom_1.20V_25C.db
```

`analysis/custom_vt_report.tcl` defines `custom_vt_report min|max`, an endpoint-based PrimeTime report that counts LVT, SVT, and HVT cells on the worst path to each endpoint.
