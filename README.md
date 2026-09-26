# Register Bus ROM

A read-only memory whose contents are fixed at elaboration. It plugs into a
[generic register interface](https://github.com/pulp-platform/register_interface),
which may be adapted to various protocols including AMBA APB and AXI 4/Lite (see
repository for adapter IPs).

The contents are an unpacked array parameter, so there is no memory file to
load and no initialisation sequence. Synthesis sees constants.

## Behaviour

`Data[i]` answers at `BaseAddr + 4*i`. Accesses are decoded at word
granularity, so the two low address bits are ignored.

Reads are registered: `ready` stays low for a cycle and the data arrives on the
next. Writes are answered immediately with `error` and change nothing, so
`wdata` and `wstrb` are unused.

The decoded window is `NumWords` rounded up to the next power of two, which
makes the offset a bit slice rather than a modulo. Indices from `NumWords` to
the end of the window read as zero, and an address past the window wraps back
into it. Keeping requests inside the device is the interconnect's job.

## Parameters

| Parameter   | Default                      | Notes                                            |
| ----------- | ---------------------------- | ------------------------------------------------ |
| `NumWords`  | 1                            | need not be a power of two                       |
| `Data`      | all zero                     | `logic [31:0] [NumWords]`, index 0 at `BaseAddr` |
| `BaseAddr`  | `32'h0`                      | address the first word answers to                |
| `reg_req_t` | `reg_rom_pkg::reg_rom_req_t` | register bus request type                        |
| `reg_rsp_t` | `reg_rom_pkg::reg_rom_rsp_t` | register bus response type                       |

`reg_rom_pkg` provides default types matching `REG_BUS_TYPEDEF_ALL` from
`register_interface`, so the module elaborates on its own; override
`reg_req_t`/`reg_rsp_t` to use your own.

## Use

```systemverilog
localparam logic [31:0] Contents [3] = '{32'hdead_0000, 32'hdead_0001, 32'hdead_0002};

reg_rom #(
    .NumWords  ( 3             ),
    .Data      ( Contents      ),
    .BaseAddr  ( 32'h0020_0000 ),
    .reg_req_t ( my_reg_req_t  ),
    .reg_rsp_t ( my_reg_rsp_t  )
) i_rom (
    .clk_i,
    .rst_ni,
    .reg_req_i ( reg_req ),
    .reg_rsp_o ( reg_rsp )
);
```

`rst_ni` is asynchronous and active low.

## Simulation

Requires [Verilator](https://verilator.org) 5. The module has no dependencies,
so linting and the testbench need nothing else.

```sh
make lint          # lint the RTL at -Wall
make sim           # build and run the testbench
make regression    # re-run the testbench for word counts 1, 2, 5, 8
```

The regression sweeps either side of a power of two, covering both the zero
padding and the wrapping.

`make sources.f` and `make ide` generate file lists for integration and for the
[slang language server](https://github.com/hudson-trading/slang-server). Those
two need [Bender](https://github.com/pulp-platform/bender).

## License

Solderpad Hardware License 2.1, see [`LICENSE`](LICENSE).
