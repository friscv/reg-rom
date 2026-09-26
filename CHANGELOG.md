# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.2] - 2026-09-26

### Changed

- Changed license from Apache 2.0 to Solderpad 2.1.
- Transferred to the FRISC-V org.

## [0.1.1] - 2026-08-15

### Fixed

- Drive `reg_rsp_o` from a single process. Verilator 5.020 rejects a struct
  written from both an `always_ff` and a continuous assignment, so 0.1.0 does
  not lint there.

## [0.1.0] - 2026-08-15

### Added

- Add `reg_rom`, a register bus read-only memory initialised from a parameter.
- Add `reg_rom_pkg` with default register bus types so the module elaborates standalone.
- Add a testbench and a regression over several word counts.
- Add CI.
