// Copyright 2026 FER, HPC Architecture and Application Research Center
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the "License");
// you may not use this file except in compliance with the License, or,
// at your option, the Apache License version 2.0.
// You may obtain a copy of the License at https://solderpad.org/licenses/SHL-2.1/
//
// Matej Jurasic <matej.jurasic@cappig.dev>

module reg_rom_tb #(
    // Deliberately not a power of two, so the padding is exercised
    parameter int unsigned NumWords = 5
);

localparam logic [31:0] BaseAddr = 32'h0020_0000;
// The rom rounds its window up to a power of two, only the slack reads as zero
localparam int unsigned Words    = 32'd1 << $clog2(NumWords);
localparam time         Period   = 10ns;

typedef logic [31:0] contents_t [NumWords];

function automatic logic [31:0] word(input int unsigned i);
    return 32'hc0de_0000 + 32'(i);
endfunction

function automatic contents_t contents();
    for (int unsigned i = 0; i < NumWords; i++) contents[i] = word(i);
endfunction

logic clk, rst_n;

// A caller supplies its own bus types, so drive the dut through one rather
// than through the defaults in reg_rom_pkg
typedef struct packed {
    logic [31:0] addr;
    logic        write;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        valid;
} tb_req_t;

typedef struct packed {
    logic [31:0] rdata;
    logic        error;
    logic        ready;
} tb_rsp_t;

tb_req_t req;
tb_rsp_t rsp;

reg_rom #(
    .NumWords  ( NumWords   ),
    .Data      ( contents() ),
    .BaseAddr  ( BaseAddr   ),
    .reg_req_t ( tb_req_t   ),
    .reg_rsp_t ( tb_rsp_t   )
) dut (
    .clk_i     ( clk   ),
    .rst_ni    ( rst_n ),
    .reg_req_i ( req   ),
    .reg_rsp_o ( rsp   )
);

initial begin
    clk = 1'b0;
    forever #(Period / 2) clk = ~clk;
end

int unsigned errors = 0;

task automatic expect_eq(input logic [31:0] got, exp, input string what);
    if (got !== exp) begin
        $error("%s: got %08x, expected %08x", what, got, exp);
        errors++;
    end
endtask

// Drive one request and return when the rom accepts it
task automatic access(input logic [31:0] addr, input logic write,
                      output logic [31:0] rdata, output logic error);
    @(negedge clk);
    req.addr  = addr;
    req.write = write;
    req.wdata = 32'hdead_beef;
    req.wstrb = 4'hf;
    req.valid = 1'b1;

    do @(posedge clk); while (!rsp.ready);

    rdata = rsp.rdata;
    error = rsp.error;

    @(negedge clk);
    req.valid = 1'b0;
endtask

initial begin
    logic [31:0] rdata;
    logic        error;

    req    = '0;
    rst_n  = 1'b0;
    repeat (3) @(posedge clk);
    rst_n  = 1'b1;
    @(posedge clk);

    // Every word reads back, at its own address
    for (int unsigned i = 0; i < NumWords; i++) begin
        access(BaseAddr + 32'(i * 4), 1'b0, rdata, error);
        expect_eq(rdata, word(i), $sformatf("word %0d", i));
        if (error) begin
            $error("word %0d: unexpected error", i);
            errors++;
        end
    end

    // Padding up to the power-of-two window reads as zero
    if (Words > NumWords) begin
        access(BaseAddr + 32'(NumWords * 4), 1'b0, rdata, error);
        expect_eq(rdata, 32'h0, "padding");
    end

    // Writes are refused and leave the contents alone
    access(BaseAddr, 1'b1, rdata, error);
    if (!error) begin
        $error("write was not refused");
        errors++;
    end

    access(BaseAddr, 1'b0, rdata, error);
    expect_eq(rdata, word(0), "word 0 after a write attempt");

    if (errors == 0) $display("reg_rom_tb: passed");
    else begin
        $display("reg_rom_tb: %0d errors", errors);
        $fatal(1, "failed");
    end

    $finish;
end

endmodule
