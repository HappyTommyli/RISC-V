# load_runner project

Top module: `load_runner_top`

What is included:
- Full copy of CPU files from the original project in `CPU/`
- `pipeline.v` is used as the game core (instantiated by `load_runner_top`)
- 128x64 SSD1306 framebuffer engine: `Display_Engine_FB128.v`
- Basys3 constraint: `Basys3_load_runner_SSD1306_JA.xdc`

MMIO used by game program:
- `0x8000`: buttons `[UP,DOWN,LEFT,RIGHT]`
- `0x8004`: timer
- `0xA000..0xA3FF`: OLED framebuffer bytes (1024 bytes)

Game program source:
- `LodeRunner_CPU.asm`
- assembled into `CPU/Inst_Mem.v` by `tools/simple_rv32i_assembler.py`
