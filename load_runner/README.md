# load_runner project (Basys3 + pipeline CPU + SSD1306 128x64)

Top module: `load_runner_top`

This folder contains a hardware-oriented port of Lode Runner style gameplay:
- Game logic is executed by your 5-stage CPU in `CPU/pipeline.v` (required core).
- Display output uses a 128x64 SSD1306 framebuffer engine in `Display_Engine_FB128.v`.
- Direction keys are mapped to Basys3 buttons (UP/DOWN/LEFT/RIGHT).

## Architecture
- CPU core: `CPU/pipeline.v`
- Program ROM: `CPU/Inst_Mem.v` (instructions generated from `LodeRunner_CPU.asm`)
- Data/MMIO: `CPU/Data_Mem.v`
- Board top: `load_runner_top.v`
- OLED driver: `Display_Engine_FB128.v`
- Constraints: `Basys3_load_runner_SSD1306_JA.xdc`

## MMIO map used by game
- `0x8000`: buttons `[3:0] = [UP, DOWN, LEFT, RIGHT]`
- `0x8004`: free-running timer input
- `0xA000..0xA3FF`: OLED framebuffer bytes (1024 bytes = 128 x 64 / 8)

## Basys3 pin mapping
- Buttons:
  - `buttons[0]` -> BTNU
  - `buttons[1]` -> BTND
  - `buttons[2]` -> BTNL
  - `buttons[3]` -> BTNR
- OLED (SSD1306, 7-pin SPI mode):
  - `screen_sclk`
  - `screen_mosi`
  - `screen_dc`
  - `screen_cs`
  - `screen_res` (hardware reset pin, newly added for stable startup)

## Build flow
1. Edit game source in `LodeRunner_CPU.asm` if needed.
2. In this folder, run:
   - `python3 tools/simple_rv32i_assembler.py`
3. The script updates `CPU/Inst_Mem.v` instruction table.
4. In Vivado, set top as `load_runner_top`.
5. Add all files under this folder to the project, and use:
   - `Basys3_load_runner_SSD1306_JA.xdc`
6. Synthesize, implement, generate bitstream, and program Basys3.

## Note about map/gameplay
- The gameplay/map logic in `LodeRunner_CPU.asm` is an RV32I implementation inspired by the upstream lode_runner style (platform, ladders, rope, coins, enemy, collision, respawn), adapted for framebuffer rendering at 128x64 horizontal mode.
