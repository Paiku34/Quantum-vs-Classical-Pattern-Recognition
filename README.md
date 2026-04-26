# Quantum vs Classical Search: 3x3 Grid Pattern Recognition ⚛️🔍

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![Julia](https://img.shields.io/badge/Julia-1.9+-purple.svg)](https://julialang.org/downloads/)
[![Qiskit](https://img.shields.io/badge/Qiskit-IBM-blueviolet.svg)](https://qiskit.org/)

This repository contains the source code, experimental data, and theoretical models for a Master's degree project evaluating and comparing **Classical Search Algorithms** against **Grover's Quantum Algorithm** applied to a 3x3 grid pattern recognition problem.

The problem consists of searching for specific topological patterns—such as vertical lines, 2x2 squares, diagonals, and a full grid—within a 3x3 spatial grid. Given a grid of 9 independent binary cells, the search space explores $N = 2^9 = 512$ possible configurations.

## 🔬 Scientific Context & Objectives

The primary objective of this project is to benchmark classical algorithmic approaches against quantum alternatives, explicitly modeling real-world quantum hardware constraints. 

1. **Classical Baseline**: Establishing statistical baselines using brute-force, random, and memory-assisted sequential searches over 10,000 Monte Carlo simulations.
2. **Quantum Ideal & Noisy Regimes**: Implementing Grover's Algorithm to highlight theoretical quadratic speedup ($O(\sqrt{N})$), followed by the introduction of a realistic continuous **Depolarizing Noise Model**.
3. **Hardware Compilation Analysis**: Utilizing **IBM Qiskit** to compile the abstract quantum oracles into physical gate depths, allowing the rigorous calibration of the noise decay factor ($\tau$) and performance evaluation on simulated noisy hardware architectures (e.g., `FakeKolkata`).

## 📁 Repository Structure

```text
progettoquantum/
│
├── Classico/
│   ├── classico.py                      # Python simulations for classical search strategies
│   ├── confronto_media_tentativi.png    # Performance plot: Average attempts
│   └── confronto_tempo_esecuzione.png   # Performance plot: Execution time
│
├── Julia/
│   ├── quantum_savory/                  
│   │   ├── grover_quantumsavory.jl      # Julia script for Grover's search (ideal and noisy)
│   │   ├── quantum_savory_example.jl    # Base examples and tests
│   │   └── grover_quantumsavory.png     # Performance plot: Success rates under noise
│   └── QuantumSavory.jl/                # The QuantumSavory simulation framework sub-dependency
│
├── Qiskit/
│   ├── qiskit_nb.ipynb                  # Jupyter Notebook for IBM Qiskit compilation & hardware analysis
│   ├── noisless_vs_noise.png            # Noise impact comparisons
│   ├── fakekolkata.png                  # FakeKolkata backend topology & characteristics
│   └── *.png                            # Oracle visual structures (DIAGONAL, SQUARE, etc.)
│
├── quantum.pdf                          # Project Report / Presentation Document
└── README.md                            # Project documentation
```

## ⚙️ Implementations Overview

### 1. Classical Approach (`Classico/`)
Developed in **Python**, this module compares three distinct heuristic approaches:
- Pure Random Guessing
- Sequential Search (Memory-assisted)
- Brute-force Search

Evaluations are conducted over large statistical ensembles to accurately determine the average attempts required and the wall-clock execution times.

### 2. Quantum Simulation (`Julia/quantum_savory/`)
Powered by **Julia** and the [QuantumSavory.jl](https://github.com/QuantumSavory/QuantumSavory.jl) framework, this module simulates Grover's Algorithm. Crucially, it moves beyond idealized quantum computing by implementing a mathematical noise model calibrated to realistic gate error rates ($p \approx 0.01$).

### 3. Hardware Compilation & Error Analysis (`Qiskit/`)
A **Jupyter Notebook** environment using **IBM Qiskit**. This section is responsible for:
- Compiling complex multi-qubit oracles down to hardware-native basis gates.
- Calculating the *equivalent circuit depth* (e.g., noting that complex patterns like the `Square` oracle require over 6,000 physical gates).
- Evaluating structural degradation on specific topologies (e.g., `FakeKolkata`).

## 📊 Results & Observations

- **Classical Deficiencies**: Classical memoryless random guessing scales poorly. Structured searches improve determinism but scale linearly $O(N)$ with the search space.
- **Quantum Advantage vs. Noise Thresholds**: While Grover's algorithm theoretically guarantees rapid convergence, our simulations demonstrate that the extreme circuit depth required for complex oracles heavily subjects the state to decoherence and depolarizing errors. The success rate drops significantly for intricate topological patterns when realistic hardware noise is introduced.

## 🛠️ Setup & Execution

### Prerequisites

- **Python 3.8+** (for Classical and Qiskit modules)
  ```bash
  pip install numpy matplotlib jupyterlab qiskit qiskit-aer
  ```
- **Julia 1.9+** (for the QuantumSavory module)

### Running the Code

**1. Classical Simulation**
```bash
cd Classico
python classico.py
```

**2. Quantum Simulation**
```bash
cd Julia/quantum_savory
julia grover_quantumsavory.jl
```

**3. Qiskit Hardware Analysis**
```bash
cd Qiskit
jupyter notebook qiskit_nb.ipynb
```

## 📜 License & Acknowledgments

This project is licensed under the **MIT License**. It was developed as part of a Master's degree curriculum in Computer Engineering/Science. 

*Special thanks to the developers of the open-source frameworks utilized, particularly IBM Quantum and the Julia Quantum community.*
