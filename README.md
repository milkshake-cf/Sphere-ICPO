# Sphere-ICPO

**Sphere-ICPO: A Spherical Vector-Based Improved Crested Porcupine Optimizer for UAV 3D Path Planning**

## Overview

Sphere-ICPO enhances the Crested Porcupine Optimizer (CPO) for UAV 3D path planning by integrating:

1. **Spherical Vector Encoding** (ρ, ψ, φ) — from the SPSO framework, directly encoding UAV kinematic constraints into the search space
2. **SOS Mutualism** — symbiotic organisms search cooperation replacing CPO's sight/sound defense strategies
3. **Adaptive Exploration Ratio** — nonlinear decay `a(t) = 2 × (0.7 × (1-t/T)^0.5 + 0.3)` for smooth explore→exploit transition
4. **Stagnation-Triggered Retreat** — periodic retreat activated only when convergence stalls, using cosine-geometric back-stepping

Built upon the [SPSO framework](https://github.com/duongpm/SPSO) (Phung & Ha, 2021).

## Results (frozen 4-map benchmark, 500 particles)

All five algorithms use 500 particles, 200 iterations, and 30 independent runs.

| Map | SPSO | GWO | CPO | WOA | **Sphere-ICPO** |
|:--|--:|--:|--:|--:|--:|
| Map1 (4 threats) | 4705.02 | **4691.94** | 4775.28 | 5610.32 | 4692.80 |
| Map2 (5 threats) | 5060.89 | 5071.25 | 5169.57 | 5971.80 | **5058.35** |
| Map3 (6 threats) | 5260.68 | **5235.05** | 5551.59 | 6794.28 | 5358.42 |
| Map4 (7 threats) | 4909.26 | 4900.53 | 5073.04 | 5999.41 | **4896.46** |

After correcting per-particle retreat rollback, Sphere-ICPO and GWO tie for the best average rank (1.75) and each wins 2 of 4 maps by mean cost. The Friedman test detects an overall difference ($p=0.00948$). Four-map ablation identifies SOS as the final-accuracy core, the adaptive schedule as an anytime-efficiency contribution, and retreat as conditional.

## Quick Start

```matlab
model = CreateModel();
[GlobalBest, BestCost] = runICPO_SOSv4_mm(model, 150, 200);
```

## Project Structure

```
├── runICPO_SOSv4_mm.m   ← 🏆 Current best: Sphere-ICPO
├── runCPO_mm.m          ← CPO baseline
├── runSPSO_mm.m         ← SPSO baseline
├── run_experiment_suite.m ← resumable smoke/precheck/formal experiment pipeline
├── vault/               ← Obsidian knowledge base (experiments + daily logs)
└── results/             ← raw checkpoints, manifests, statistics, and figures
```

## License

MIT
