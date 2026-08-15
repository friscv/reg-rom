// Copyright 2026 Matej Jurasić
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0
//
// Matej Jurasić <matej.jurasic@cappig.dev>

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
logic done;

always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
        done            <= 1'b0;
        reg_rsp_o.rdata <= 32'h0;
    end else begin
        done            <= read && !done;
        reg_rsp_o.rdata <= mem[offset];
    end
end

// Writes are answered immediately, with an error
assign reg_rsp_o.ready = done || (reg_req_i.valid && reg_req_i.write);
assign reg_rsp_o.error = reg_req_i.valid && reg_req_i.write;

endmodule
