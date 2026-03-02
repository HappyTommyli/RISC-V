    # Hazard test program (forwarding + load-use + control hazards)

    # Base address for data memory
    lui t0, 0x1      # t0 = 0x1000
    addi t0, t0, 0

    # Initialize memory values
    addi t1, zero, 10
    sw t1, 0(t0)
    addi t1, zero, 20
    sw t1, 4(t0)

    # EX/MEM forwarding (RAW)
    add t2, t1, t1   # t2 = 40
    add t3, t2, t1   # uses t2 from EX/MEM

    # MEM/WB forwarding (RAW with one gap)
    add t4, t2, t1   # t4 = 60
    add t5, t0, t0   # independent
    add t6, t4, t1   # uses t4 from MEM/WB

    # Load-use hazard (stall)
    lw  t7, 0(t0)
    add t8, t7, t1   # uses t7 immediately after load

    # Load -> Store data hazard (stall/forward)
    lw  t9, 4(t0)
    sw  t9, 8(t0)

    # Store data forwarding from ALU result
    add t10, t1, t1
    sw  t10, 12(t0)

    # Branch depends on previous result (forward to branch)
    add t11, t1, t1
    beq t11, zero, 8   # not taken
    addi t12, zero, 1

    # Taken branch (flush)
    addi t13, zero, 0
    beq t13, zero, 8
    addi t14, zero, 99  # should be flushed

    # JALR hazard (rs1 from immediately previous instruction)
    auipc t15, 0
    addi  t15, t15, 8
    jalr  zero, 0(t15)  # jump to itself (end loop)
