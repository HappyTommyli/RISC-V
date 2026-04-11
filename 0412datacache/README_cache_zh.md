# Data Cache 整合總結

本次修改在原本五級管線 (5-stage pipeline) 上加入一個簡化版 **Direct-Mapped Data Cache**，以及基本的 hit/miss 統計機制，但暫時不改變整體 CPI（先不對 miss 產生 stall）。

## 1. Data_Cache：結構與行為

檔案位置：`Data_Mem-10.v` 中的 `Data_Cache` 模組。

### 結構

- Direct-mapped cache，64 lines，每 line 1 word (32-bit)。
- 位址切分（word address = `addr[31:2]`）：
  - `index = addr[2 + INDEX_BITS - 1 : 2]`，其中 `INDEX_BITS = 6` → 64 lines。
  - `tag   = addr[31 : 2 + INDEX_BITS]`。
- 每個 line 儲存：
  - `valid_array[0:63]`：有效位。
  - `tag_array[0:63]`：tag。
  - `data_array[0:63]`：32-bit 資料。

### 存取行為

#### Load（mem_read）

- 判斷 hit：`hit = valid_array[index] && (tag_array[index] == tag)`。
- hit：
  - 不對 Data_Memory 送 read（`dmem_read = mem_read && ~hit`）。
  - `rdata` 從 `data_array` 依 `funct3` 和 `addr[1:0]` 做 byte/halfword 選擇與 sign/zero extend（支援 LB/LH/LBU/LHU/LW）。
- miss：
  - 對 Data_Memory 發出 1 次讀取（`dmem_read = mem_read && ~hit`）。
  - `rdata` 直接使用 `dmem_rdata`，維持 1-cycle MEM latency。
  - 同時將 `dmem_rdata` 寫入 `data_array[index]`，並更新 `valid/tag`（read-allocate）。

#### Store（mem_write）

- 採 **write-through**：`dmem_write = mem_write`，`dmem_addr = addr`，`dmem_wdata = wdata`。
- 若該 line hit，依 `funct3` (SB/SH/SW) 更新 `data_array[index]`，行為與 Data_Memory 一致。
- write-miss：不配置新 line（no-write-allocate）。

#### Cache Stall

- 目前 `cache_stall` 固定為 0：
  ```verilog
  assign cache_stall = 1'b0;
  ```
- 不對 miss 進行 pipeline stall，因此 CPI 暫時不受 hit/miss 影響。

## 2. 與 MEM 階段及管線的整合

### MEM 階段（MEM-5.v）

- Data path：
  - Data_Memory 接收來自 Data_Cache 的 `dmem_*` 訊號。
  - MEM 對 WB 的輸出改為使用 cache 的 `rdata`：
    ```verilog
    assign mem_data       = cache_rdata;
    assign mem_alu_result = alu_result;
    assign mem_rd         = rd;
    assign mem_reg_write  = reg_write;
    assign mem_regout     = mem_reg;
    ```

- Data_Cache 直接接 EX/MEM 的 `alu_result`、`rs2_data` 和 `ex_mem_instruction`，作為 cache 的位址與寫入資料來源。

### Pipeline 中的 cache stall 支援（預留）

- 在 `pipeline-4.v` 中加入：
  ```verilog
  wire        cache_stall;
  wire        pipeline_stall;
  assign pipeline_stall = hazard_stall | cache_stall;
  ```
- IF stage 使用 `pipeline_stall` 控制 PC 與 IF/ID 暫存器；ID/EX、EX/MEM、MEM/WB 在 `cache_stall` 為 1 時會保持原值，以支援未來多 cycle miss 模型。
- 目前因為 `cache_stall` 恒為 0，這些 stall 邏輯不會被觸發。

## 3. Hit/Miss 計數器

在 `Data_Cache` 中加入以下計數器，用於統計 cache 行為（方便在模擬中觀察 hit rate）：

- `load_access_count`：所有 load 次數（mem_read 為 1）。
- `load_hit_count`：load hit 次數。
- `load_miss_count`：load miss 次數。
- `store_access_count`：store 次數（mem_write 為 1）。

計數規則：

```verilog
if (mem_read) begin
    load_access_count <= load_access_count + 32'd1;
    if (hit)
        load_hit_count  <= load_hit_count  + 32'd1;
    else
        load_miss_count <= load_miss_count + 32'd1;
end

if (mem_write) begin
    store_access_count <= store_access_count + 32'd1;
end
```

目前這些計數器僅存在於 `Data_Cache` 內部，可在模擬 waveform 中直接觀察，例如 `u_dcache.load_hit_count` 等；如需在軟體中讀取，可再額外做 memory-mapped 或 top-level 輸出。

## 4. 整體效果

- 功能面：
  - Data cache 具備基本的 direct-mapped 結構、read-allocate、write-through、寫入 hit 更新 cache line，且完整支援 byte/halfword/word 的 load/store 與 sign/zero extend，與原本純 Data_Memory 設計相容。

- 性能面：
  - 目前尚未引入 miss stall，`cache_stall` 恒為 0，因此 CPI 與「沒有 cache 但單 cycle memory」的版本相同，只是多了真實的命中率統計資訊，可用於分析不同程式的記憶體存取行為與未來優化的空間。
