# coe_to_verilog_init_interactive.py
# 這個版本會問你 .coe 檔案名稱，然後轉換成 Verilog initial block

import re
import os

def coe_to_verilog_init(coe_file_path, mem_name="memory"):
    """
    讀取 .coe 檔案，轉換成 Verilog initial begin 格式
    """
    hex_values = []
    
    if not os.path.exists(coe_file_path):
        print(f"錯誤：找不到檔案 {coe_file_path}")
        return None
    
    try:
        with open(coe_file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        in_vector = False
        for line in lines:
            line = line.strip()
            
            # 跳過註解、空行
            if not line or line.startswith(';') or line.startswith('//'):
                continue
                
            # 找到 vector 開始
            if 'memory_initialization_vector' in line:
                in_vector = True
                continue
                
            if in_vector:
                # 移除結尾的逗號、分號、空白
                cleaned = re.sub(r'[,\s;]+$', '', line)
                if cleaned:
                    # 確保是 8 位 hex（32-bit）
                    cleaned = cleaned.zfill(8)
                    hex_values.append(cleaned)
                
                # 遇到 ; 結束
                if ';' in line:
                    break
                    
        if not hex_values:
            print("錯誤：沒有找到有效的 memory_initialization_vector 內容")
            return None
            
        # 產生 Verilog 內容
        verilog_lines = ["initial begin"]
        for i, hex_val in enumerate(hex_values):
            verilog_lines.append(f"    {mem_name}[{i}] = 32'h{hex_val};")
        verilog_lines.append("end")
        
        output_content = "\n".join(verilog_lines)
        return output_content
        
    except Exception as e:
        print(f"讀取或處理時發生錯誤：{e}")
        return None

# 主程式：互動式詢問檔案名稱
if __name__ == "__main__":
    print("=== .coe 轉 Verilog initial block 工具 ===")
    print("請輸入你的 .coe 檔案完整名稱（含路徑，如果不在同資料夾）")
    print("範例：program.coe   或   C:/project/program.coe")
    print("輸入 q 或 quit 離開\n")
    
    while True:
        coe_filename = input("輸入 .coe 檔案名稱：").strip()
        
        if coe_filename.lower() in ['q', 'quit', 'exit']:
            print("結束程式")
            break
            
        if not coe_filename:
            print("請輸入檔案名稱！")
            continue
            
        # 自動補 .coe 副檔名（如果沒寫）
        if not coe_filename.lower().endswith('.coe'):
            coe_filename += '.coe'
            
        print(f"\n正在處理檔案：{coe_filename}\n")
        
        result = coe_to_verilog_init(coe_filename)
        
        if result:
            print("轉換成功！以下是 Verilog initial block 內容：\n")
            print(result)
            print("\n" + "="*60 + "\n")
            
            # 問是否儲存到檔案
            save = input("要儲存成檔案嗎？(y/n)：").strip().lower()
            if save == 'y':
                output_name = input("請輸入輸出檔案名稱（預設 imem_init.v）：").strip() or "imem_init.v"
                with open(output_name, 'w', encoding='utf-8') as f:
                    f.write(result + "\n")
                print(f"已儲存到 {output_name}")
            print("\n")
        else:
            print("轉換失敗，請檢查檔案內容或路徑。\n")
            
        again = input("要繼續轉換另一個檔案嗎？(y/n)：").strip().lower()
        if again != 'y':
            break

    print("感謝使用！")