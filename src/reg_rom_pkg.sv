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

package reg_rom_pkg;

    typedef struct packed {
        logic [31:0] addr;
        logic        write;
        logic [31:0] wdata;
        logic [3:0]  wstrb;
        logic        valid;
    } reg_rom_req_t;

    typedef struct packed {
        logic [31:0] rdata;
        logic        error;
        logic        ready;
    } reg_rom_rsp_t;

endpackage
