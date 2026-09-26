// Copyright 2026 FER, HPC Architecture and Application Research Center
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License");
// you may not use this file except in compliance with the License, or,
// at your option, the Apache License version 2.0.
// You may obtain a copy of the License at https://solderpad.org/licenses/SHL-2.1/
//
// Matej Jurasic <matej.jurasic@cappig.dev>

module reg_rom #(
    // Contents, one 32-bit word per entry, index 0 lives at BaseAddr
    parameter int unsigned NumWords = 1,
    parameter logic [31:0] Data [NumWords] = '{default: '0},
    // Address the first word answers to, reads below it wrap into the window
    parameter logic [31:0] BaseAddr = 32'h0,
    // Register interface
    parameter type reg_req_t = reg_rom_pkg::reg_rom_req_t,
    parameter type reg_rsp_t = reg_rom_pkg::reg_rom_rsp_t
) (
    input  logic clk_i,
    input  logic rst_ni,

    // A rom never reads wdata or wstrb
    /* verilator lint_off UNUSEDSIGNAL */
    input  reg_req_t reg_req_i,
    /* verilator lint_on UNUSEDSIGNAL */
    output reg_rsp_t reg_rsp_o
);

// The decoded window is the contents rounded up to the next power of two, so
// the offset is a plain bit slice rather than a modulo
localparam int unsigned Words   = 32'd1 << $clog2(NumWords);
localparam int unsigned OffsetW = (Words > 1) ? $clog2(Words) : 1;

logic [31:0] mem [Words];

for (genvar i = 0; i < Words; i++) begin : gen_mem
    if (i < NumWords) begin : gen_data
        assign mem[i] = Data[i];
    end else begin : gen_pad
        assign mem[i] = 32'h0;
    end
end

logic [OffsetW-1:0] offset;
assign offset = OffsetW'((reg_req_i.addr - BaseAddr) >> 2);

logic read;
assign read = reg_req_i.valid && !reg_req_i.write;

// The read is registered, so it answers on the cycle after the request lands
logic        done;
logic [31:0] rdata;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        done  <= 1'b0;
        rdata <= 32'h0;
    end else begin
        done  <= read && !done;
        rdata <= mem[offset];
    end
end

// One driver for the response, some tools reject a struct written from both an
// always_ff and a continuous assignment
always_comb begin
    reg_rsp_o       = '0;
    reg_rsp_o.rdata = rdata;
    // Writes are answered immediately, with an error
    reg_rsp_o.ready = done || (reg_req_i.valid && reg_req_i.write);
    reg_rsp_o.error = reg_req_i.valid && reg_req_i.write;
end

endmodule
