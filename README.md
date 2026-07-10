# Sphere-ICPO

**Sphere-ICPO: A Spherical Vector-Based Improved Crested Porcupine Optimizer for UAV 3D Path Planning**

## Overview

Sphere-ICPO enhances the Crested Porcupine Optimizer (CPO) for UAV 3D path planning by integrating:

1. **Spherical Vector Encoding** (ρ, ψ, φ) — from the SPSO framework, directly encoding UAV kinematic constraints into the search space
2. **SOS Mutualism** — symbiotic organisms search cooperation replacing CPO's sight/sound defense strategies
3. **Adaptive Exploration Ratio** — nonlinear decay `a(t) = 2 × (0.7 × (1-t/T)^0.5 + 0.3)` for smooth explore→exploit transition
4. **Stagnation-Triggered Retreat** — periodic retreat activated only when convergence stalls, using cosine-geometric back-stepping

Built upon the [SPSO framework](https://github.com/duongpm/SPSO) (Phung & Ha, 2021).

## Results (Map4 — 7 threats, 150 particles)

| Algorithm | Mean Cost | Std |
|:--|:--|:--|
| SPSO (500 particles) | 4935 | 58 |
| CPO (150 particles) | 6089 | 252 |
| **Sphere-ICPO (150 particles)** | **5015** | **275** |

> Sphere-ICPO with **150 particles** nearly matches SPSO with **500 particles** (gap: 1.6%).

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
├── batch_final.m        ← Full comparison script
├── vault/               ← Obsidian knowledge base (experiments + daily logs)
└── results/             ← Experiment result .mat files
```

## License

MIT
