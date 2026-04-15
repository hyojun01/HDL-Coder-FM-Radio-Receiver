# FM Radio Receiver - HDL Coder Practice

Simulink-based FM radio receiver designed for HDL code generation using MATLAB/Simulink and HDL Coder. This project is part of the [HDL Coder Evaluation Reference Guide](https://github.com/mathworks/HDL-Coder-Evaluation-Reference-Guide) practice exercises.

## Overview

This project implements an FM radio receiver as a Simulink model, progressively refined across multiple versions for HDL-readiness. The workflow demonstrates how to take a floating-point Simulink model through fixed-point conversion and optimization toward FPGA/ASIC deployment.

## Project Structure

| File | Description |
|------|-------------|
| `fm_radio_simulink_v1.slx` | Initial FM radio receiver Simulink model (baseline/reference) |
| `fm_radio_simulink_v3.slx` | Refined model iteration |
| `fm_radio_simulink_v4.slx` | Further optimized model iteration |
| `fm_radio_simulink_v5.slx` | Final HDL-ready model iteration |
| `fm_radio_test_bench_v1.mlx` | MATLAB Live Script test bench for v1 |
| `fm_radio_test_bench_v3.mlx` | MATLAB Live Script test bench for v3 |
| `fm_radio_test_bench_v4.mlx` | MATLAB Live Script test bench for v4 |
| `fm_radio_test_bench_v5.mlx` | MATLAB Live Script test bench for v5 |
| `compareData.m` | Utility function to compare reference and actual signals, computing error metrics and plotting results |
| `getLogged.m` | Utility function to extract logged signals from Simulink simulation output |
| `input.wav` | Input audio file (16-bit stereo PCM, 44100 Hz) |
| `output.wav` | Output audio file (16-bit mono PCM, 48000 Hz) |

## Requirements

- MATLAB (R2024a or later recommended)
- Simulink
- HDL Coder
- DSP System Toolbox (recommended)
- Fixed-Point Designer (recommended)

## Usage

1. Open MATLAB and navigate to this directory.
2. Open the desired model version (e.g., `fm_radio_simulink_v1.slx`).
3. Run the corresponding test bench Live Script (e.g., `fm_radio_test_bench_v1.mlx`) to simulate and verify the model.
4. Use `compareData.m` to compare outputs between model versions or against reference data.

## Utility Functions

### `compareData(reference, actual, figure_number, textstring)`
Compares two signals by computing the error vector, maximum absolute error, and percentage error. Generates overlay plots of reference, actual, and error signals.

### `getLogged(simout_obj, signal_name)`
Extracts a named logged signal from a Simulink simulation output object (`Simulink.SimulationOutput`).

## License

Copyright 2019-2025, The MathWorks, Inc.
