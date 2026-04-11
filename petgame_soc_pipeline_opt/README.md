# PetGame SoC (pipeline_lut_opt 版)

此資料夾把 `pipeline_lut_opt` 改成可上板的 SoC 版本，對應你的遊戲框架。

## 重點檔案
- `PetGame_SoC.v`：Top level
- `pipeline.v`：已加入 buttons/timer/display 介面
- `Data_Mem.v`：新增 memory-mapped IO (0x8000 / 0x8004 / 0x9000)
- `Display_Engine.v`：SSD1306 SPI 顯示（讀取 Picture_ROM 顯示 32x32 圖片）
- `Basys3_PetGame.xdc`：Basys3 約束檔

## 位址映射
- `0x0000 ~ 0x7FFF`：內部資料記憶體
- `0x8000`：按鈕 (buttons[2:0])
- `0x8004`：Timer
- `0x9000`：顯示介面 (bit31 = busy, write = cmd)

## SoC 每一步在做什麼（總流程）
1. **IF/ID/EX/MEM/WB pipeline 執行指令**
   - Pipeline core 取得指令、執行算術、讀寫記憶體。
2. **MEM 階段做記憶體映射解碼**
   - 位址 < `0x8000` → 內部 RAM
   - 位址 = `0x8000` → 讀按鈕
   - 位址 = `0x8004` → 讀 Timer
   - 位址 = `0x9000` → 顯示輸出/忙碌讀取
3. **Display_Engine 接收到 `0x9000` 的寫入**
   - `display_we=1`，`display_cmd` 送出
   - `display_cmd` 格式：`[PetID<<8 | ExpID]`
4. **Display_Engine 讀取 Picture_ROM**
   - PetID/ExpID 對應一張 32x32 圖片
   - SSD1306 以 1-bit 亮度方式顯示
5. **Timer 持續累加**
   - CPU 用 `lw 0x8004` 取得時間基準
6. **Buttons 讀取輸入**
   - CPU 用 `lw 0x8000` 讀按鈕狀態

## Display_Engine State Diagram
Figma 連結：  
[Display Engine State Diagram](https://www.figma.com/online-whiteboard/create-diagram/e2e52799-1e9e-4b80-9301-de29ae7fc94b?utm_source=other&utm_content=edit_in_figjam&oai_id=&request_id=29f82aec-ad19-4474-95ed-742f5a8badf6)

## 上板操作流程（一步一步）
1. **組好 OLED 與 Basys3**
   - 預設使用 SSD1306 128x64，連接到 Pmod JA：
     - `screen_sclk` -> JA1 (J1)
     - `screen_mosi` -> JA2 (L2)
     - `screen_dc`   -> JA3 (J2)
     - `screen_cs`   -> JA4 (G2)
2. **產生 machine code**
   - 用你提供的 Python assembler 轉 `PetGame.asm` 成 TXT/COE
   - 注意：此 assembler 不支援 `.text/.globl` 等指令，已移除
3. **更新指令記憶體**
   - 把生成的 machine code 貼進 `Inst_Mem.v`
4. **建立 Vivado 專案**
   - Top 設為 `PetGame_SoC`
   - 加入 `Basys3_PetGame.xdc`
5. **綜合/實作/燒錄**
   - 產生 bitstream 後下載到板子
6. **操作遊戲**
   - 按鈕功能：
     - `buttons[0]` (BTNU): 餵食
     - `buttons[1]` (BTNL): 互動
     - `buttons[2]` (BTNR): 切換寵物
   - 顯示內容（四象限）：
     - Pet0: 左上全亮
     - Pet1: 右上全亮
     - Pet2: 左下全亮
     - Pet3: 右下全亮
   - LED 顯示：`leds[3]` 會反映 `display_busy`

## 圖片 ROM 導入方式
1. 使用工具產生初始化檔：
   - `tools/img_to_rgb565_rom.py`
2. 產生的 `initial begin ... end` 貼到：
   - `Picture_ROM.v` 內的註解區塊
3. 確保 `Picture_ROM.v` 被加入 Vivado sources
4. `Picture_ROM.v` 內已直接內嵌初始化資料（不需要額外 .mem 檔）
4. 目前已內建一張小貓圖（pet0_exp0），其他 pet 顯示為全黑

### ROM 預設規格
- 4 隻寵物 × 3 表情
- 32×32 (1024 pixels)
- RGB565 (顯示時轉成 1-bit)
- ROM 深度 = 12288 entries

## 待完成
1. **Display_Engine 真正 SPI 實作**
   - 初始化序列 SSD1306
   - SPI 時序/分頻（SCLK 頻率）
   - 像素資料串流（RGB565 16-bit）
   - busy 訊號正確拉高/拉低
2. **圖片資產準備與 ROM 建立**
   - 準備 4×3 張圖片（pet0..pet3, exp0..exp2）
   - 用 `tools/img_to_rgb565_rom.py` 產生 init
   - 把 init 貼進 `Picture_ROM.v`
3. **指令記憶體更新**
   - 將 `PetGame.asm` 編譯成 machine code
   - 更新 `Inst_Mem.v`
4. **按鈕去彈跳 / 同步**
   - Debounce + one‑pulse（避免按住連發）
5. **硬體約束確認**
   - Basys3 XDC pin 對應（若換 Pmod 需要更新）
   - 顯示器額外腳位（RST/BL）若有需補上
6. **時序與上板驗證**
   - Vivado timing (WNS/TNS)
   - 真板操作流程確認
7. **（可選）Display busy 檢查**
   - ASM 端若顯示忙碌，可延遲寫入

## PetGame.asm 說明（中文）
位置：`petgame_soc_pipeline_opt/PetGame.asm`

### 暫存器分配
- `x10`：當前寵物索引 (0~3)
- `x20`：按鈕輸入值
- `x21`：上次 Timer 值（用於計時差）
- `x30`：IO 基底 (0x8000)
- `t0~t6`：運算用暫存
- `a0`：表情代碼（0:開心, 1:餓, 2:難過）

### 資料結構
- 寵物資料起始位址：`0x4000`
- 每隻寵物占 8 bytes：
  - `+0`：飽食度 (Satiety)
  - `+4`：心情值 (Happiness)

### 程式流程分段
1. 初始化寵物數值
   - 把 4 隻寵物的 Sat/Hap 都設為 100
   - 寫在 `0x4000, 0x4008, 0x4010, ...`
2. 主迴圈 `_main_loop`
   - 讀 Timer，判斷是否過了一段時間
   - 若時間到，呼叫 `_decrease_stats` 把數值減 1
3. 按鈕輸入處理
   - `bit0` 餵食：呼叫 `_feed_pet`
   - `bit1` 互動：呼叫 `_play_pet`
   - `bit2` 切換寵物：呼叫 `_switch_pet`
4. 更新表情 `_update_expression`
   - Sat < 30 -> 顯示「餓」
   - Hap < 30 -> 顯示「難過」
   - 否則顯示「開心」
5. 螢幕輸出 `_display_out`
   - 寫入 `0x9000`
   - 格式：`[PetID << 8] | ExpID`

### 各副程式功能
1. `_decrease_stats`
   - 取出當前寵物 Sat/Hap
   - 各自 `-1`，並在 0 以下強制變回 0
2. `_feed_pet`
   - Sat `+10`，超過 100 就設為 100
3. `_play_pet`
   - Hap `+10`，超過 100 就設為 100
4. `_switch_pet`
   - 索引 +1，超過 3 就回到 0
5. `_update_expression`
   - 根據 Sat/Hap 決定表情代碼
6. `_display_out`
   - 把表情代碼與寵物索引組合成 16-bit 指令，寫到 `0x9000`

### IO 位址說明
- `0x8000`：按鈕輸入（讀取）
- `0x8004`：Timer（讀取）
- `0x9000`：Display 命令（寫入）/ busy 狀態（讀取 bit31）
