# Tetris for `pipeline_lut_opt`

這個資料夾提供你在 `pipeline_lut_opt` 上做俄羅斯方塊 Demo 的起始版本：

- `tetris_uart.c`：遊戲主程式（10x20 棋盤、7 種方塊、旋轉、碰撞、消行、分數）
- `mmio_timer_uart.v`：UART TX/RX + RX status + hardware timer 的 MMIO 模組

## MMIO Map

- `0x80000000`：UART TX（write, low 8-bit）
- `0x80000004`：UART RX（read, low 8-bit）
- `0x80000008`：UART RX status（read, bit0=1 代表有新資料）
- `0x8000000C`：timer（read）

## 控制鍵

- `A/D`：左右移動
- `W`：旋轉
- `S`：加速下降
- `Space`：直接到底（hard drop）
- `Q`：離開

## 整合到 `pipeline_lut_opt` 的建議步驟

1. 在 `Data_Memory` 中保留原本 RAM 行為。
2. 加入 MMIO 位址判斷：當 `alu_result` 落在上述 4 個位址時，轉給 `mmio_timer_uart`。
3. `mem_write && addr==0x80000000` 時，送出 `uart_tx_data` 與 `uart_tx_we`。
4. `mem_read` 時，若 `addr` 為 RX / RX_STATUS / TIMER，回傳對應 `rdata`。
5. 在 top-level 將 UART RX 模組輸入接到 `uart_rx_data/uart_rx_valid`，並在 `uart_rx_pop` 時清除 valid。

## 重力速度

`tetris_uart.c` 目前用：

- `#define GRAVITY_TICKS 1`

若你的 timer 每秒加 1，代表每秒掉一格。
若你的 timer 每個 clock cycle 加 1，建議改成 `5_780_000`（約 100ms/格，57.8MHz）。

## 備註

- 這版是 terminal ANSI 渲染版本，透過 UART 輸出到電腦終端（例如 PuTTY / minicom / screen）。
- 若終端不支援 ANSI 顏色，可把 `emit_cell()` 改成純文字字元輸出。
