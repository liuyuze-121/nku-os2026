# 功能模块一：Trap 上下文恢复与 Trap 入口功能
*`RESTORE_ALL`*
````markdown
[PROMPT]
**任务**：修改 `kern/trap/trapentry.S` 的 `RESTORE_ALL`，从当前 trapframe 恢复 Trap 返回前的 CPU 状态；只改宏体，不改 `SAVE_ALL`、trapframe 布局、`trap()` 签名和 `__trapret/sret`。

**操作要求**：直接修改真实文件，只补 `RESTORE_ALL`；临时寄存器只在宏内使用。

**输出要求**：严格按下面布局实现，不引入无关功能。

[RELY]
// RV64: LOAD=ld, STORE=sd, REGBYTES=8
// trapframe 偏移：0 zero, 1 ra, 2 sp, 3 gp, 4 tp,
// 5-7 t0-t2, 8-9 s0-s1, 10-17 a0-a7,
// 18-27 s2-s11, 28-31 t3-t6,
// 32 status, 33 epc, 34 badvaddr, 35 cause
// SAVE_ALL 将原 sp 存到偏移 2；sret 使用 sepc/sstatus。
// trap() 可能修改 tf->epc。

[GUARANTEE]
```asm
.macro RESTORE_ALL
    ...
.endm
```

[SPECIFICATION]
**Pre-Condition**：`sp` 指向 `SAVE_ALL` 建立的 36 字 trapframe。

**Post-Condition**：除 `x0` 外通用寄存器全部恢复；`sstatus`、`sepc`、`sbadaddr`、`scause` 从偏移 32-35 回写；`sp` 恢复为偏移 2 的值；trapframe 不被改写。

**Cases**：
- 正常返回：恢复后 `sret` 回到原执行流。
- `tf->epc` 被修改：恢复后的 `sepc` 必须使用新值。
- 恢复 `sp` 前完成所有基于 `sp` 的加载，之后不再使用旧基址。

**Requirements**：与 `SAVE_ALL` 偏移严格对应；`x0` 保持 0；CSR 在 `sret` 前恢复。
````
*`__alltraps`*
````markdown
[PROMPT]
**任务**：修改 `kern/trap/trapentry.S` 的 `__alltraps`，在 `SAVE_ALL` 后把 trapframe 传给 `trap()`，返回后进入 `__trapret`。

**操作要求**：只改 `SAVE_ALL` 后的调用部分，不改 `SAVE_ALL`、`RESTORE_ALL`、`__trapret` 和 `sret`。

**输出要求**：直接修改文件，遵循 RISC-V 调用约定。

[RELY]
void trap(struct trapframe *tf);
// SAVE_ALL 后 sp 指向 trapframe；a0 是第一个参数；
// ra 已保存在偏移 1；__trapret 紧跟其后。

[GUARANTEE]
```asm
.globl __alltraps
__alltraps:
    SAVE_ALL
    ...
```

[SPECIFICATION]
**Pre-Condition**：通过 `stvec` 进入，`SAVE_ALL` 已完成，`sp` 指向完整 trapframe。

**Post-Condition**：以 `sp` 作为第一个参数调用 `trap()`；返回后 `sp` 不变并进入 `__trapret`；trapframe 不被修改。

**Cases**：
- 正常返回：`trap()` 收到有效 trapframe，处理后继续 `RESTORE_ALL`。
- `tf->epc` 被修改：返回后仍指向原 trapframe，后续恢复读取新值。

**Requirements**：第一个参数用 `a0`；调用前后保持 trapframe 地址不变；入口四字节对齐。

````

---

# 功能模块二：中断与异常处理功能

````markdown
[PROMPT]
**任务**：修改 `kern/trap/trap.c`，实现 `interrupt_handler()` 和 `exception_handler()`，处理时钟中断、其他中断、断点、非法指令和未知异常。

**操作要求**：只补两个函数，不改已有函数签名；可增加 `static` 辅助函数和内部宏；使用 `sbi_shutdown()` 时包含 `<sbi.h>`。

**输出要求**：直接修改文件，处理结果必须能被 `tools/grade.sh` 识别。

[RELY]
#define TICK_NUM 100
#define IRQ_S_SOFT 1
#define IRQ_S_TIMER 5
#define IRQ_S_EXT 9
#define CAUSE_ILLEGAL_INSTRUCTION 0x2
#define CAUSE_BREAKPOINT 0x3

extern volatile size_t ticks;
void clock_set_next_event(void);
void sbi_shutdown(void);
void print_trapframe(struct trapframe *tf);

static void print_ticks(void);
// cause 最高位 1 为中断，否则为异常；中断号需去掉最高位。
// epc 是异常指令或被打断指令的地址。

[GUARANTEE]
```c
void interrupt_handler(struct trapframe *tf);
void exception_handler(struct trapframe *tf);
```

[SPECIFICATION]
## interrupt_handler

**Pre-Condition**：`tf` 有效，`tf->cause` 最高位为 1。

**Post-Condition**：时钟中断更新 `ticks` 并重设定时器；其他中断只输出提示；返回统一 Trap 路径。

**Cases**：
- `IRQ_S_TIMER`：`ticks++`，调用 `clock_set_next_event()`；每 `TICK_NUM` 次调用 `print_ticks()`；达到关机阈值后 `sbi_shutdown()`。
- `IRQ_S_SOFT`：输出 `Supervisor software interrupt`。
- `IRQ_S_EXT`：输出 `Supervisor external interrupt`。
- 其他：输出去掉最高位的原因码 `Unknown interrupt: cause N`，并调用 `print_trapframe(tf)`。

**Requirements**：每次时钟中断都重装；不重置 `ticks`；关机阈值对应 tick 数大于 `2 * TICK_NUM`，建议取 10 次统计输出。

## exception_handler

**Pre-Condition**：`tf` 有效，`tf->cause` 最高位为 0。

**Post-Condition**：非法指令和断点推进 `tf->epc`；其他异常只打印现场；不改 `tf->cause`。

**Cases**：
- `CAUSE_ILLEGAL_INSTRUCTION`：输出 `Illegal instruction at <地址>`，按指令长度推进 `tf->epc`。
- `CAUSE_BREAKPOINT`：输出 `Breakpoint at <地址>`，按指令长度推进 `tf->epc`。
- 其他：调用 `print_trapframe(tf)`，不修改 `tf->epc`。

**Requirements**：指令低两位为 `11` 时加 4，否则加 2；原因码 20 输出 `cause    0x00000014`；不直接执行 `sret`。

**验收输出**：`Breakpoint at`、`Illegal instruction at`、`Supervisor software interrupt`、`Unknown interrupt: cause 15`、`cause    0x00000014`、`100 ticks`、`ticks=200`。
````