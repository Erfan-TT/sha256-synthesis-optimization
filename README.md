# SHA-256 ASIC Synthesis and Power Optimization

An RTL-to-gate synthesis study of a SHA-256 hardware core targeting a 65 nm standard-cell library. The project compares a baseline implementation with clock-gating and multi-threshold-voltage (Multi-VT) optimizations, with timing, area, and power evaluated using Synopsys Design Compiler and PrimeTime.

This repository was prepared from my final project for **Synthesis and Optimization of Digital Systems** at Politecnico di Torino, taught by Valentino Peluso and Andrea Calimera.

> The optimization study starts from the open-source Secworks SHA-256 RTL. My work focuses on the synthesis flow, constraints, clock-gating and Multi-VT configurations, reporting, and PPA analysis.

## Key results

All implementations target a **2.0 ns clock period (500 MHz)** and meet timing with approximately zero slack.

| Configuration | Area (um^2) | Dynamic power (uW) | Leakage power (uW) | Timing slack (ns) |
|---|---:|---:|---:|---:|
| Baseline | 38,381.33 | 5.930 | 0.013650 | 0.000203 |
| Clock gating | 28,276.83 | 4.437 | 0.008637 | 0.000000 |
| Clock gating + Multi-VT | 31,294.98 | 4.852 | 0.002180 | 0.000000 |

Highlights:

- Clock-gated synthesis reduced area by **26.3%** and dynamic power by **25.2%** relative to the baseline.
- Multi-VT mapping reduced leakage by **74.8%** relative to clock gating alone, and by **84.0%** relative to the baseline.
- The Multi-VT implementation mapped **82.32%** of cells to HVT, **7.15%** to SVT, and **10.53%** to LVT while preserving timing.
- The leakage improvement came with a tradeoff: compared with clock gating alone, Multi-VT increased area by **10.7%** and dynamic power by **9.4%**.

Power is shown in uW here for readability; the source report records it in mW. The clock-gating experiment also changes the synthesis command from `compile` to `compile_ultra -gate_clock`, so its PPA improvement reflects the combined effect of clock gating and the more aggressive compile strategy.

## Repository structure

```text
.
|-- rtl/sha256_core/
|   |-- src/                 # SHA-224/SHA-256 RTL
|   |-- tb/                  # Self-checking testbench
|   `-- sdc/                 # 2.0 ns timing constraints
|-- flows/
|   |-- baseline/            # Baseline LVT synthesis and analysis
|   |-- clock_gating/        # Clock-gated LVT flow
|   |-- clock_gating_multi_vt/ # Clock gating with LVT/SVT/HVT mapping
|   `-- analysis/            # Custom endpoint-based VT path report
|-- scripts/simulate.do      # Questa/ModelSim activity-generation flow
|-- results/summary.csv      # Final PPA metrics
|-- docs/REPORT.pdf          # Final project report
`-- .github/workflows/       # Open-source RTL regression
```

## RTL verification

The self-checking testbench covers standard SHA-256 single-block and double-block vectors plus an interface/issue test.

With Icarus Verilog installed:

```bash
make sim
```

The same regression runs automatically in GitHub Actions. A successful run ends with:

```text
*** All 03 test cases completed successfully
```

## Reproducing the ASIC experiments

The synthesis experiments require licensed Synopsys tools and the ST 65 nm Liberty databases. Those technology files are intentionally not included.

1. Place the required `CORE65LP{LVT,SVT,HVT}_nom_1.20V_25C.db` files in `tech/STcmos65/`.
2. Generate switching activity with Questa/ModelSim:

   ```bash
   vsim -c -do scripts/simulate.do
   ```

3. Run one of the synthesis configurations from the repository root:

   ```bash
   dc_shell -f flows/baseline/synthesis.tcl
   dc_shell -f flows/clock_gating/synthesis.tcl
   dc_shell -f flows/clock_gating_multi_vt/synthesis.tcl
   ```

4. Run the matching PrimeTime analysis, for example:

   ```bash
   pt_shell -f flows/clock_gating_multi_vt/pt_analysis.tcl
   ```

See [flows/README.md](flows/README.md) for experiment details and output expectations.

## Report

The complete methodology, measured results, and interpretation are available in [docs/REPORT.pdf](docs/REPORT.pdf). The PDF and LaTeX source are preserved unchanged from the submitted project.

## Attribution

- **Project work and analysis:** Erfan Taheri (Group 21)
- **Course:** Synthesis and Optimization of Digital Systems, Politecnico di Torino
- **Instructors:** Valentino Peluso and Andrea Calimera
- **SHA-256 RTL and testbench:** Joachim Strombergson / [Secworks SHA-256](https://github.com/secworks/sha256), under the BSD 2-Clause terms reproduced in the source headers
- **Course flow templates:** Valentino Peluso / Politecnico di Torino DAUIN EDA Group; original notices are retained

See [NOTICE.md](NOTICE.md) for additional provenance and licensing notes.
