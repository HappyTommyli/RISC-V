# 圖片轉 ROM 工具（img_to_rgb565_rom.py）使用說明

此工具會將寵物圖片轉成 **RGB565**，並依照 PetID/ExpID 的順序輸出成 ROM 初始化檔。

## 1. 圖片命名規則
請使用以下任一命名方式：
- `pet{P}_exp{E}.png`（推薦）
- `p{P}_e{E}.png`

範例：
```
pet0_exp0.png
pet0_exp1.png
pet1_exp0.png
pet3_exp2.png
```

## 2. 圖片尺寸
預設尺寸為 **32×32**（對應 1024 pixels / 張）。
若圖片大小不同：
- 不加 `--resize`：會報錯
- 加 `--resize`：會自動縮放

## 3. ROM 排列規則
ROM 內容順序：
```
Pet0 Exp0
Pet0 Exp1
...
Pet0 ExpN
Pet1 Exp0
...
```

每張圖按 **row-major** 排列：
```
pixel_index = y * width + x
```

## 4. 使用方式（範例）
```bash
python3 img_to_rgb565_rom.py \
  --input ./images \
  --output ./picture_rom_init.v \
  --format verilog \
  --mem-name rom \
  --width 32 --height 32 \
  --pets 4 --exps 3 \
  --resize
```

### 參數說明
- `--input`：圖片資料夾
- `--output`：輸出檔案路徑
- `--format`：輸出格式（verilog / mem / coe）
- `--mem-name`：Verilog 記憶體陣列名稱
- `--width` `--height`：圖片尺寸
- `--pets`：寵物數量
- `--exps`：每隻寵物的表情數
- `--resize`：自動縮放圖片

## 5. 輸出檔說明
### (1) Verilog 格式
```verilog
initial begin
    rom[0] = 16'hf800;
    rom[1] = 16'h07e0;
    ...
end
```

### (2) .mem 格式
每行一個 16-bit hex
```
f800
07e0
001f
```

### (3) .coe 格式
可用於 BRAM 初始化

## 6. 依賴
此工具需要 Pillow：
```bash
pip install pillow
```

## 7. 常見問題
- **圖片缺少某些 Pet/Exp**：
  會出現 WARN，缺的會保持為 0。
- **尺寸不一致**：
  不加 `--resize` 會報錯。
