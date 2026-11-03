
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200054:	00006517          	auipc	a0,0x6
ffffffffc0200058:	fd450513          	addi	a0,a0,-44 # ffffffffc0206028 <free_area>
ffffffffc020005c:	00006617          	auipc	a2,0x6
ffffffffc0200060:	43c60613          	addi	a2,a2,1084 # ffffffffc0206498 <end>
int kern_init(void) {
ffffffffc0200064:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200066:	8e09                	sub	a2,a2,a0
ffffffffc0200068:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006a:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020006c:	665010ef          	jal	ra,ffffffffc0201ed0 <memset>
    dtb_init();
ffffffffc0200070:	40e000ef          	jal	ra,ffffffffc020047e <dtb_init>
    cons_init();  // init the console
ffffffffc0200074:	3fc000ef          	jal	ra,ffffffffc0200470 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	e7050513          	addi	a0,a0,-400 # ffffffffc0201ee8 <etext+0x6>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	0dc000ef          	jal	ra,ffffffffc0200160 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	7b2000ef          	jal	ra,ffffffffc020083a <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	634010ef          	jal	ra,ffffffffc02016c0 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	7aa000ef          	jal	ra,ffffffffc020083a <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	39a000ef          	jal	ra,ffffffffc020042e <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	796000ef          	jal	ra,ffffffffc020082e <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	3cc000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	0d5010ef          	jal	ra,ffffffffc02019a0 <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200100:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200102:	09f010ef          	jal	ra,ffffffffc02019a0 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010e:	a695                	j	ffffffffc0200472 <cons_putc>

ffffffffc0200110 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200126:	34c000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	336000ef          	jal	ra,ffffffffc0200472 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200154:	326000ef          	jal	ra,ffffffffc020047a <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015a:	60a2                	ld	ra,8(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200160:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200162:	00002517          	auipc	a0,0x2
ffffffffc0200166:	da650513          	addi	a0,a0,-602 # ffffffffc0201f08 <etext+0x26>
void print_kerninfo(void) {
ffffffffc020016a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016c:	f6dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200170:	00000597          	auipc	a1,0x0
ffffffffc0200174:	ee458593          	addi	a1,a1,-284 # ffffffffc0200054 <kern_init>
ffffffffc0200178:	00002517          	auipc	a0,0x2
ffffffffc020017c:	db050513          	addi	a0,a0,-592 # ffffffffc0201f28 <etext+0x46>
ffffffffc0200180:	f59ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200184:	00002597          	auipc	a1,0x2
ffffffffc0200188:	d5e58593          	addi	a1,a1,-674 # ffffffffc0201ee2 <etext>
ffffffffc020018c:	00002517          	auipc	a0,0x2
ffffffffc0200190:	dbc50513          	addi	a0,a0,-580 # ffffffffc0201f48 <etext+0x66>
ffffffffc0200194:	f45ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200198:	00006597          	auipc	a1,0x6
ffffffffc020019c:	e9058593          	addi	a1,a1,-368 # ffffffffc0206028 <free_area>
ffffffffc02001a0:	00002517          	auipc	a0,0x2
ffffffffc02001a4:	dc850513          	addi	a0,a0,-568 # ffffffffc0201f68 <etext+0x86>
ffffffffc02001a8:	f31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ac:	00006597          	auipc	a1,0x6
ffffffffc02001b0:	2ec58593          	addi	a1,a1,748 # ffffffffc0206498 <end>
ffffffffc02001b4:	00002517          	auipc	a0,0x2
ffffffffc02001b8:	dd450513          	addi	a0,a0,-556 # ffffffffc0201f88 <etext+0xa6>
ffffffffc02001bc:	f1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c0:	00006597          	auipc	a1,0x6
ffffffffc02001c4:	6d758593          	addi	a1,a1,1751 # ffffffffc0206897 <end+0x3ff>
ffffffffc02001c8:	00000797          	auipc	a5,0x0
ffffffffc02001cc:	e8c78793          	addi	a5,a5,-372 # ffffffffc0200054 <kern_init>
ffffffffc02001d0:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d4:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001d8:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001de:	95be                	add	a1,a1,a5
ffffffffc02001e0:	85a9                	srai	a1,a1,0xa
ffffffffc02001e2:	00002517          	auipc	a0,0x2
ffffffffc02001e6:	dc650513          	addi	a0,a0,-570 # ffffffffc0201fa8 <etext+0xc6>
}
ffffffffc02001ea:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ec:	b5f5                	j	ffffffffc02000d8 <cprintf>

ffffffffc02001ee <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ee:	1141                	addi	sp,sp,-16
    
    panic("Not Implemented!");
ffffffffc02001f0:	00002617          	auipc	a2,0x2
ffffffffc02001f4:	de860613          	addi	a2,a2,-536 # ffffffffc0201fd8 <etext+0xf6>
ffffffffc02001f8:	04e00593          	li	a1,78
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	df450513          	addi	a0,a0,-524 # ffffffffc0201ff0 <etext+0x10e>
void print_stackframe(void) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200206:	1cc000ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020020a <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020020a:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020c:	00002617          	auipc	a2,0x2
ffffffffc0200210:	dfc60613          	addi	a2,a2,-516 # ffffffffc0202008 <etext+0x126>
ffffffffc0200214:	00002597          	auipc	a1,0x2
ffffffffc0200218:	e1458593          	addi	a1,a1,-492 # ffffffffc0202028 <etext+0x146>
ffffffffc020021c:	00002517          	auipc	a0,0x2
ffffffffc0200220:	e1450513          	addi	a0,a0,-492 # ffffffffc0202030 <etext+0x14e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200224:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200226:	eb3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	e1660613          	addi	a2,a2,-490 # ffffffffc0202040 <etext+0x15e>
ffffffffc0200232:	00002597          	auipc	a1,0x2
ffffffffc0200236:	e3658593          	addi	a1,a1,-458 # ffffffffc0202068 <etext+0x186>
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	df650513          	addi	a0,a0,-522 # ffffffffc0202030 <etext+0x14e>
ffffffffc0200242:	e97ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200246:	00002617          	auipc	a2,0x2
ffffffffc020024a:	e3260613          	addi	a2,a2,-462 # ffffffffc0202078 <etext+0x196>
ffffffffc020024e:	00002597          	auipc	a1,0x2
ffffffffc0200252:	e4a58593          	addi	a1,a1,-438 # ffffffffc0202098 <etext+0x1b6>
ffffffffc0200256:	00002517          	auipc	a0,0x2
ffffffffc020025a:	dda50513          	addi	a0,a0,-550 # ffffffffc0202030 <etext+0x14e>
ffffffffc020025e:	e7bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020026a:	1141                	addi	sp,sp,-16
ffffffffc020026c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020026e:	ef3ff0ef          	jal	ra,ffffffffc0200160 <print_kerninfo>
    return 0;
}
ffffffffc0200272:	60a2                	ld	ra,8(sp)
ffffffffc0200274:	4501                	li	a0,0
ffffffffc0200276:	0141                	addi	sp,sp,16
ffffffffc0200278:	8082                	ret

ffffffffc020027a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027a:	1141                	addi	sp,sp,-16
ffffffffc020027c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020027e:	f71ff0ef          	jal	ra,ffffffffc02001ee <print_stackframe>
    return 0;
}
ffffffffc0200282:	60a2                	ld	ra,8(sp)
ffffffffc0200284:	4501                	li	a0,0
ffffffffc0200286:	0141                	addi	sp,sp,16
ffffffffc0200288:	8082                	ret

ffffffffc020028a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020028a:	7115                	addi	sp,sp,-224
ffffffffc020028c:	ed5e                	sd	s7,152(sp)
ffffffffc020028e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200290:	00002517          	auipc	a0,0x2
ffffffffc0200294:	e1850513          	addi	a0,a0,-488 # ffffffffc02020a8 <etext+0x1c6>
kmonitor(struct trapframe *tf) {
ffffffffc0200298:	ed86                	sd	ra,216(sp)
ffffffffc020029a:	e9a2                	sd	s0,208(sp)
ffffffffc020029c:	e5a6                	sd	s1,200(sp)
ffffffffc020029e:	e1ca                	sd	s2,192(sp)
ffffffffc02002a0:	fd4e                	sd	s3,184(sp)
ffffffffc02002a2:	f952                	sd	s4,176(sp)
ffffffffc02002a4:	f556                	sd	s5,168(sp)
ffffffffc02002a6:	f15a                	sd	s6,160(sp)
ffffffffc02002a8:	e962                	sd	s8,144(sp)
ffffffffc02002aa:	e566                	sd	s9,136(sp)
ffffffffc02002ac:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ae:	e2bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	e1e50513          	addi	a0,a0,-482 # ffffffffc02020d0 <etext+0x1ee>
ffffffffc02002ba:	e1fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc02002be:	000b8563          	beqz	s7,ffffffffc02002c8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c2:	855e                	mv	a0,s7
ffffffffc02002c4:	756000ef          	jal	ra,ffffffffc0200a1a <print_trapframe>
ffffffffc02002c8:	00002c17          	auipc	s8,0x2
ffffffffc02002cc:	e78c0c13          	addi	s8,s8,-392 # ffffffffc0202140 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d0:	00002917          	auipc	s2,0x2
ffffffffc02002d4:	e2890913          	addi	s2,s2,-472 # ffffffffc02020f8 <etext+0x216>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00002497          	auipc	s1,0x2
ffffffffc02002dc:	e2848493          	addi	s1,s1,-472 # ffffffffc0202100 <etext+0x21e>
        if (argc == MAXARGS - 1) {
ffffffffc02002e0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e2:	00002b17          	auipc	s6,0x2
ffffffffc02002e6:	e26b0b13          	addi	s6,s6,-474 # ffffffffc0202108 <etext+0x226>
        argv[argc ++] = buf;
ffffffffc02002ea:	00002a17          	auipc	s4,0x2
ffffffffc02002ee:	d3ea0a13          	addi	s4,s4,-706 # ffffffffc0202028 <etext+0x146>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002f4:	854a                	mv	a0,s2
ffffffffc02002f6:	22d010ef          	jal	ra,ffffffffc0201d22 <readline>
ffffffffc02002fa:	842a                	mv	s0,a0
ffffffffc02002fc:	dd65                	beqz	a0,ffffffffc02002f4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002fe:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200302:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200304:	e1bd                	bnez	a1,ffffffffc020036a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200306:	fe0c87e3          	beqz	s9,ffffffffc02002f4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	6582                	ld	a1,0(sp)
ffffffffc020030c:	00002d17          	auipc	s10,0x2
ffffffffc0200310:	e34d0d13          	addi	s10,s10,-460 # ffffffffc0202140 <commands>
        argv[argc ++] = buf;
ffffffffc0200314:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200316:	4401                	li	s0,0
ffffffffc0200318:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031a:	35d010ef          	jal	ra,ffffffffc0201e76 <strcmp>
ffffffffc020031e:	c919                	beqz	a0,ffffffffc0200334 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200320:	2405                	addiw	s0,s0,1
ffffffffc0200322:	0b540063          	beq	s0,s5,ffffffffc02003c2 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200326:	000d3503          	ld	a0,0(s10)
ffffffffc020032a:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032e:	349010ef          	jal	ra,ffffffffc0201e76 <strcmp>
ffffffffc0200332:	f57d                	bnez	a0,ffffffffc0200320 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200334:	00141793          	slli	a5,s0,0x1
ffffffffc0200338:	97a2                	add	a5,a5,s0
ffffffffc020033a:	078e                	slli	a5,a5,0x3
ffffffffc020033c:	97e2                	add	a5,a5,s8
ffffffffc020033e:	6b9c                	ld	a5,16(a5)
ffffffffc0200340:	865e                	mv	a2,s7
ffffffffc0200342:	002c                	addi	a1,sp,8
ffffffffc0200344:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200348:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020034a:	fa0555e3          	bgez	a0,ffffffffc02002f4 <kmonitor+0x6a>
}
ffffffffc020034e:	60ee                	ld	ra,216(sp)
ffffffffc0200350:	644e                	ld	s0,208(sp)
ffffffffc0200352:	64ae                	ld	s1,200(sp)
ffffffffc0200354:	690e                	ld	s2,192(sp)
ffffffffc0200356:	79ea                	ld	s3,184(sp)
ffffffffc0200358:	7a4a                	ld	s4,176(sp)
ffffffffc020035a:	7aaa                	ld	s5,168(sp)
ffffffffc020035c:	7b0a                	ld	s6,160(sp)
ffffffffc020035e:	6bea                	ld	s7,152(sp)
ffffffffc0200360:	6c4a                	ld	s8,144(sp)
ffffffffc0200362:	6caa                	ld	s9,136(sp)
ffffffffc0200364:	6d0a                	ld	s10,128(sp)
ffffffffc0200366:	612d                	addi	sp,sp,224
ffffffffc0200368:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020036a:	8526                	mv	a0,s1
ffffffffc020036c:	34f010ef          	jal	ra,ffffffffc0201eba <strchr>
ffffffffc0200370:	c901                	beqz	a0,ffffffffc0200380 <kmonitor+0xf6>
ffffffffc0200372:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200376:	00040023          	sb	zero,0(s0)
ffffffffc020037a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037c:	d5c9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc020037e:	b7f5                	j	ffffffffc020036a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200380:	00044783          	lbu	a5,0(s0)
ffffffffc0200384:	d3c9                	beqz	a5,ffffffffc0200306 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200386:	033c8963          	beq	s9,s3,ffffffffc02003b8 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020038a:	003c9793          	slli	a5,s9,0x3
ffffffffc020038e:	0118                	addi	a4,sp,128
ffffffffc0200390:	97ba                	add	a5,a5,a4
ffffffffc0200392:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200396:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020039a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039c:	e591                	bnez	a1,ffffffffc02003a8 <kmonitor+0x11e>
ffffffffc020039e:	b7b5                	j	ffffffffc020030a <kmonitor+0x80>
ffffffffc02003a0:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003a4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a6:	d1a5                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003a8:	8526                	mv	a0,s1
ffffffffc02003aa:	311010ef          	jal	ra,ffffffffc0201eba <strchr>
ffffffffc02003ae:	d96d                	beqz	a0,ffffffffc02003a0 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b0:	00044583          	lbu	a1,0(s0)
ffffffffc02003b4:	d9a9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003b6:	bf55                	j	ffffffffc020036a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b8:	45c1                	li	a1,16
ffffffffc02003ba:	855a                	mv	a0,s6
ffffffffc02003bc:	d1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02003c0:	b7e9                	j	ffffffffc020038a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c2:	6582                	ld	a1,0(sp)
ffffffffc02003c4:	00002517          	auipc	a0,0x2
ffffffffc02003c8:	d6450513          	addi	a0,a0,-668 # ffffffffc0202128 <etext+0x246>
ffffffffc02003cc:	d0dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc02003d0:	b715                	j	ffffffffc02002f4 <kmonitor+0x6a>

ffffffffc02003d2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003d2:	00006317          	auipc	t1,0x6
ffffffffc02003d6:	06e30313          	addi	t1,t1,110 # ffffffffc0206440 <is_panic>
ffffffffc02003da:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003de:	715d                	addi	sp,sp,-80
ffffffffc02003e0:	ec06                	sd	ra,24(sp)
ffffffffc02003e2:	e822                	sd	s0,16(sp)
ffffffffc02003e4:	f436                	sd	a3,40(sp)
ffffffffc02003e6:	f83a                	sd	a4,48(sp)
ffffffffc02003e8:	fc3e                	sd	a5,56(sp)
ffffffffc02003ea:	e0c2                	sd	a6,64(sp)
ffffffffc02003ec:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003ee:	020e1a63          	bnez	t3,ffffffffc0200422 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003f2:	4785                	li	a5,1
ffffffffc02003f4:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f8:	8432                	mv	s0,a2
ffffffffc02003fa:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fc:	862e                	mv	a2,a1
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	d8850513          	addi	a0,a0,-632 # ffffffffc0202188 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020040a:	ccfff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020040e:	65a2                	ld	a1,8(sp)
ffffffffc0200410:	8522                	mv	a0,s0
ffffffffc0200412:	ca7ff0ef          	jal	ra,ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc0200416:	00002517          	auipc	a0,0x2
ffffffffc020041a:	bba50513          	addi	a0,a0,-1094 # ffffffffc0201fd0 <etext+0xee>
ffffffffc020041e:	cbbff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200422:	412000ef          	jal	ra,ffffffffc0200834 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200426:	4501                	li	a0,0
ffffffffc0200428:	e63ff0ef          	jal	ra,ffffffffc020028a <kmonitor>
    while (1) {
ffffffffc020042c:	bfed                	j	ffffffffc0200426 <__panic+0x54>

ffffffffc020042e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042e:	1141                	addi	sp,sp,-16
ffffffffc0200430:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200432:	02000793          	li	a5,32
ffffffffc0200436:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	1ab010ef          	jal	ra,ffffffffc0201df0 <sbi_set_timer>
}
ffffffffc020044a:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020044c:	00006797          	auipc	a5,0x6
ffffffffc0200450:	fe07be23          	sd	zero,-4(a5) # ffffffffc0206448 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200454:	00002517          	auipc	a0,0x2
ffffffffc0200458:	d5450513          	addi	a0,a0,-684 # ffffffffc02021a8 <commands+0x68>
}
ffffffffc020045c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045e:	b9ad                	j	ffffffffc02000d8 <cprintf>

ffffffffc0200460 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200460:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	1850106f          	j	ffffffffc0201df0 <sbi_set_timer>

ffffffffc0200470 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200472:	0ff57513          	zext.b	a0,a0
ffffffffc0200476:	1610106f          	j	ffffffffc0201dd6 <sbi_console_putchar>

ffffffffc020047a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020047a:	1910106f          	j	ffffffffc0201e0a <sbi_console_getchar>

ffffffffc020047e <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020047e:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200480:	00002517          	auipc	a0,0x2
ffffffffc0200484:	d4850513          	addi	a0,a0,-696 # ffffffffc02021c8 <commands+0x88>
void dtb_init(void) {
ffffffffc0200488:	fc86                	sd	ra,120(sp)
ffffffffc020048a:	f8a2                	sd	s0,112(sp)
ffffffffc020048c:	e8d2                	sd	s4,80(sp)
ffffffffc020048e:	f4a6                	sd	s1,104(sp)
ffffffffc0200490:	f0ca                	sd	s2,96(sp)
ffffffffc0200492:	ecce                	sd	s3,88(sp)
ffffffffc0200494:	e4d6                	sd	s5,72(sp)
ffffffffc0200496:	e0da                	sd	s6,64(sp)
ffffffffc0200498:	fc5e                	sd	s7,56(sp)
ffffffffc020049a:	f862                	sd	s8,48(sp)
ffffffffc020049c:	f466                	sd	s9,40(sp)
ffffffffc020049e:	f06a                	sd	s10,32(sp)
ffffffffc02004a0:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc02004a2:	c37ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02004a6:	00006597          	auipc	a1,0x6
ffffffffc02004aa:	b5a5b583          	ld	a1,-1190(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc02004ae:	00002517          	auipc	a0,0x2
ffffffffc02004b2:	d2a50513          	addi	a0,a0,-726 # ffffffffc02021d8 <commands+0x98>
ffffffffc02004b6:	c23ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004ba:	00006417          	auipc	s0,0x6
ffffffffc02004be:	b4e40413          	addi	s0,s0,-1202 # ffffffffc0206008 <boot_dtb>
ffffffffc02004c2:	600c                	ld	a1,0(s0)
ffffffffc02004c4:	00002517          	auipc	a0,0x2
ffffffffc02004c8:	d2450513          	addi	a0,a0,-732 # ffffffffc02021e8 <commands+0xa8>
ffffffffc02004cc:	c0dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02004d0:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	d2c50513          	addi	a0,a0,-724 # ffffffffc0202200 <commands+0xc0>
    if (boot_dtb == 0) {
ffffffffc02004dc:	120a0463          	beqz	s4,ffffffffc0200604 <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02004e0:	57f5                	li	a5,-3
ffffffffc02004e2:	07fa                	slli	a5,a5,0x1e
ffffffffc02004e4:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02004e8:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ea:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004ee:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02004f4:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f8:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004fc:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200504:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200506:	8ec9                	or	a3,a3,a0
ffffffffc0200508:	0087979b          	slliw	a5,a5,0x8
ffffffffc020050c:	1b7d                	addi	s6,s6,-1
ffffffffc020050e:	0167f7b3          	and	a5,a5,s6
ffffffffc0200512:	8dd5                	or	a1,a1,a3
ffffffffc0200514:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200516:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020051a:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc020051c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a55>
ffffffffc0200520:	10f59163          	bne	a1,a5,ffffffffc0200622 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200524:	471c                	lw	a5,8(a4)
ffffffffc0200526:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200528:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020052e:	0086d51b          	srliw	a0,a3,0x8
ffffffffc0200532:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200536:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020053a:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020053e:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200542:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200546:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020054a:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020054e:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200552:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200554:	01146433          	or	s0,s0,a7
ffffffffc0200558:	0086969b          	slliw	a3,a3,0x8
ffffffffc020055c:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200560:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200562:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200566:	8c49                	or	s0,s0,a0
ffffffffc0200568:	0166f6b3          	and	a3,a3,s6
ffffffffc020056c:	00ca6a33          	or	s4,s4,a2
ffffffffc0200570:	0167f7b3          	and	a5,a5,s6
ffffffffc0200574:	8c55                	or	s0,s0,a3
ffffffffc0200576:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057a:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020057c:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020057e:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200580:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200584:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200586:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200588:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc020058c:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020058e:	00002917          	auipc	s2,0x2
ffffffffc0200592:	cc290913          	addi	s2,s2,-830 # ffffffffc0202250 <commands+0x110>
ffffffffc0200596:	49bd                	li	s3,15
        switch (token) {
ffffffffc0200598:	4d91                	li	s11,4
ffffffffc020059a:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc020059c:	00002497          	auipc	s1,0x2
ffffffffc02005a0:	cac48493          	addi	s1,s1,-852 # ffffffffc0202248 <commands+0x108>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02005a4:	000a2703          	lw	a4,0(s4)
ffffffffc02005a8:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ac:	0087569b          	srliw	a3,a4,0x8
ffffffffc02005b0:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b4:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b8:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005bc:	0107571b          	srliw	a4,a4,0x10
ffffffffc02005c0:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005c2:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005c6:	0087171b          	slliw	a4,a4,0x8
ffffffffc02005ca:	8fd5                	or	a5,a5,a3
ffffffffc02005cc:	00eb7733          	and	a4,s6,a4
ffffffffc02005d0:	8fd9                	or	a5,a5,a4
ffffffffc02005d2:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02005d4:	09778c63          	beq	a5,s7,ffffffffc020066c <dtb_init+0x1ee>
ffffffffc02005d8:	00fbea63          	bltu	s7,a5,ffffffffc02005ec <dtb_init+0x16e>
ffffffffc02005dc:	07a78663          	beq	a5,s10,ffffffffc0200648 <dtb_init+0x1ca>
ffffffffc02005e0:	4709                	li	a4,2
ffffffffc02005e2:	00e79763          	bne	a5,a4,ffffffffc02005f0 <dtb_init+0x172>
ffffffffc02005e6:	4c81                	li	s9,0
ffffffffc02005e8:	8a56                	mv	s4,s5
ffffffffc02005ea:	bf6d                	j	ffffffffc02005a4 <dtb_init+0x126>
ffffffffc02005ec:	ffb78ee3          	beq	a5,s11,ffffffffc02005e8 <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02005f0:	00002517          	auipc	a0,0x2
ffffffffc02005f4:	cd850513          	addi	a0,a0,-808 # ffffffffc02022c8 <commands+0x188>
ffffffffc02005f8:	ae1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02005fc:	00002517          	auipc	a0,0x2
ffffffffc0200600:	d0450513          	addi	a0,a0,-764 # ffffffffc0202300 <commands+0x1c0>
}
ffffffffc0200604:	7446                	ld	s0,112(sp)
ffffffffc0200606:	70e6                	ld	ra,120(sp)
ffffffffc0200608:	74a6                	ld	s1,104(sp)
ffffffffc020060a:	7906                	ld	s2,96(sp)
ffffffffc020060c:	69e6                	ld	s3,88(sp)
ffffffffc020060e:	6a46                	ld	s4,80(sp)
ffffffffc0200610:	6aa6                	ld	s5,72(sp)
ffffffffc0200612:	6b06                	ld	s6,64(sp)
ffffffffc0200614:	7be2                	ld	s7,56(sp)
ffffffffc0200616:	7c42                	ld	s8,48(sp)
ffffffffc0200618:	7ca2                	ld	s9,40(sp)
ffffffffc020061a:	7d02                	ld	s10,32(sp)
ffffffffc020061c:	6de2                	ld	s11,24(sp)
ffffffffc020061e:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc0200620:	bc65                	j	ffffffffc02000d8 <cprintf>
}
ffffffffc0200622:	7446                	ld	s0,112(sp)
ffffffffc0200624:	70e6                	ld	ra,120(sp)
ffffffffc0200626:	74a6                	ld	s1,104(sp)
ffffffffc0200628:	7906                	ld	s2,96(sp)
ffffffffc020062a:	69e6                	ld	s3,88(sp)
ffffffffc020062c:	6a46                	ld	s4,80(sp)
ffffffffc020062e:	6aa6                	ld	s5,72(sp)
ffffffffc0200630:	6b06                	ld	s6,64(sp)
ffffffffc0200632:	7be2                	ld	s7,56(sp)
ffffffffc0200634:	7c42                	ld	s8,48(sp)
ffffffffc0200636:	7ca2                	ld	s9,40(sp)
ffffffffc0200638:	7d02                	ld	s10,32(sp)
ffffffffc020063a:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020063c:	00002517          	auipc	a0,0x2
ffffffffc0200640:	be450513          	addi	a0,a0,-1052 # ffffffffc0202220 <commands+0xe0>
}
ffffffffc0200644:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200646:	bc49                	j	ffffffffc02000d8 <cprintf>
                int name_len = strlen(name);
ffffffffc0200648:	8556                	mv	a0,s5
ffffffffc020064a:	7f6010ef          	jal	ra,ffffffffc0201e40 <strlen>
ffffffffc020064e:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200650:	4619                	li	a2,6
ffffffffc0200652:	85a6                	mv	a1,s1
ffffffffc0200654:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc0200656:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200658:	03d010ef          	jal	ra,ffffffffc0201e94 <strncmp>
ffffffffc020065c:	e111                	bnez	a0,ffffffffc0200660 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc020065e:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200660:	0a91                	addi	s5,s5,4
ffffffffc0200662:	9ad2                	add	s5,s5,s4
ffffffffc0200664:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc0200668:	8a56                	mv	s4,s5
ffffffffc020066a:	bf2d                	j	ffffffffc02005a4 <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020066c:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200670:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200674:	0087d71b          	srliw	a4,a5,0x8
ffffffffc0200678:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200680:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200684:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200688:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020068c:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200690:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200694:	00eaeab3          	or	s5,s5,a4
ffffffffc0200698:	00fb77b3          	and	a5,s6,a5
ffffffffc020069c:	00faeab3          	or	s5,s5,a5
ffffffffc02006a0:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006a2:	000c9c63          	bnez	s9,ffffffffc02006ba <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02006a6:	1a82                	slli	s5,s5,0x20
ffffffffc02006a8:	00368793          	addi	a5,a3,3
ffffffffc02006ac:	020ada93          	srli	s5,s5,0x20
ffffffffc02006b0:	9abe                	add	s5,s5,a5
ffffffffc02006b2:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc02006b6:	8a56                	mv	s4,s5
ffffffffc02006b8:	b5f5                	j	ffffffffc02005a4 <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ba:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006be:	85ca                	mv	a1,s2
ffffffffc02006c0:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006c2:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006c6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ca:	0187971b          	slliw	a4,a5,0x18
ffffffffc02006ce:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006d2:	0107d79b          	srliw	a5,a5,0x10
ffffffffc02006d6:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006d8:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006dc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006e0:	8d59                	or	a0,a0,a4
ffffffffc02006e2:	00fb77b3          	and	a5,s6,a5
ffffffffc02006e6:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02006e8:	1502                	slli	a0,a0,0x20
ffffffffc02006ea:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02006ec:	9522                	add	a0,a0,s0
ffffffffc02006ee:	788010ef          	jal	ra,ffffffffc0201e76 <strcmp>
ffffffffc02006f2:	66a2                	ld	a3,8(sp)
ffffffffc02006f4:	f94d                	bnez	a0,ffffffffc02006a6 <dtb_init+0x228>
ffffffffc02006f6:	fb59f8e3          	bgeu	s3,s5,ffffffffc02006a6 <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02006fa:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02006fe:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200702:	00002517          	auipc	a0,0x2
ffffffffc0200706:	b5650513          	addi	a0,a0,-1194 # ffffffffc0202258 <commands+0x118>
           fdt32_to_cpu(x >> 32);
ffffffffc020070a:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020070e:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc0200712:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200716:	0187de1b          	srliw	t3,a5,0x18
ffffffffc020071a:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071e:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0187d693          	srli	a3,a5,0x18
ffffffffc020072a:	01861f1b          	slliw	t5,a2,0x18
ffffffffc020072e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200732:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0106561b          	srliw	a2,a2,0x10
ffffffffc020073a:	010f6f33          	or	t5,t5,a6
ffffffffc020073e:	0187529b          	srliw	t0,a4,0x18
ffffffffc0200742:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200746:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020074a:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020074e:	0186f6b3          	and	a3,a3,s8
ffffffffc0200752:	01859e1b          	slliw	t3,a1,0x18
ffffffffc0200756:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020075a:	0107581b          	srliw	a6,a4,0x10
ffffffffc020075e:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200762:	8361                	srli	a4,a4,0x18
ffffffffc0200764:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200768:	0105d59b          	srliw	a1,a1,0x10
ffffffffc020076c:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200770:	00cb7633          	and	a2,s6,a2
ffffffffc0200774:	0088181b          	slliw	a6,a6,0x8
ffffffffc0200778:	0085959b          	slliw	a1,a1,0x8
ffffffffc020077c:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200780:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200784:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200788:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020078c:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200790:	011b78b3          	and	a7,s6,a7
ffffffffc0200794:	005eeeb3          	or	t4,t4,t0
ffffffffc0200798:	00c6e733          	or	a4,a3,a2
ffffffffc020079c:	006c6c33          	or	s8,s8,t1
ffffffffc02007a0:	010b76b3          	and	a3,s6,a6
ffffffffc02007a4:	00bb7b33          	and	s6,s6,a1
ffffffffc02007a8:	01d7e7b3          	or	a5,a5,t4
ffffffffc02007ac:	016c6b33          	or	s6,s8,s6
ffffffffc02007b0:	01146433          	or	s0,s0,a7
ffffffffc02007b4:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02007b6:	1702                	slli	a4,a4,0x20
ffffffffc02007b8:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007ba:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007bc:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007be:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02007c0:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02007c4:	0167eb33          	or	s6,a5,s6
ffffffffc02007c8:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007ca:	90fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02007ce:	85a2                	mv	a1,s0
ffffffffc02007d0:	00002517          	auipc	a0,0x2
ffffffffc02007d4:	aa850513          	addi	a0,a0,-1368 # ffffffffc0202278 <commands+0x138>
ffffffffc02007d8:	901ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02007dc:	014b5613          	srli	a2,s6,0x14
ffffffffc02007e0:	85da                	mv	a1,s6
ffffffffc02007e2:	00002517          	auipc	a0,0x2
ffffffffc02007e6:	aae50513          	addi	a0,a0,-1362 # ffffffffc0202290 <commands+0x150>
ffffffffc02007ea:	8efff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02007ee:	008b05b3          	add	a1,s6,s0
ffffffffc02007f2:	15fd                	addi	a1,a1,-1
ffffffffc02007f4:	00002517          	auipc	a0,0x2
ffffffffc02007f8:	abc50513          	addi	a0,a0,-1348 # ffffffffc02022b0 <commands+0x170>
ffffffffc02007fc:	8ddff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200800:	00002517          	auipc	a0,0x2
ffffffffc0200804:	b0050513          	addi	a0,a0,-1280 # ffffffffc0202300 <commands+0x1c0>
        memory_base = mem_base;
ffffffffc0200808:	00006797          	auipc	a5,0x6
ffffffffc020080c:	c487b423          	sd	s0,-952(a5) # ffffffffc0206450 <memory_base>
        memory_size = mem_size;
ffffffffc0200810:	00006797          	auipc	a5,0x6
ffffffffc0200814:	c567b423          	sd	s6,-952(a5) # ffffffffc0206458 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200818:	b3f5                	j	ffffffffc0200604 <dtb_init+0x186>

ffffffffc020081a <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc020081a:	00006517          	auipc	a0,0x6
ffffffffc020081e:	c3653503          	ld	a0,-970(a0) # ffffffffc0206450 <memory_base>
ffffffffc0200822:	8082                	ret

ffffffffc0200824 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc0200824:	00006517          	auipc	a0,0x6
ffffffffc0200828:	c3453503          	ld	a0,-972(a0) # ffffffffc0206458 <memory_size>
ffffffffc020082c:	8082                	ret

ffffffffc020082e <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc020082e:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200832:	8082                	ret

ffffffffc0200834 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200834:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200838:	8082                	ret

ffffffffc020083a <idt_init>:
void idt_init(void) {

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020083a:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc020083e:	00000797          	auipc	a5,0x0
ffffffffc0200842:	37a78793          	addi	a5,a5,890 # ffffffffc0200bb8 <__alltraps>
ffffffffc0200846:	10579073          	csrw	stvec,a5
}
ffffffffc020084a:	8082                	ret

ffffffffc020084c <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020084c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc020084e:	1141                	addi	sp,sp,-16
ffffffffc0200850:	e022                	sd	s0,0(sp)
ffffffffc0200852:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200854:	00002517          	auipc	a0,0x2
ffffffffc0200858:	ac450513          	addi	a0,a0,-1340 # ffffffffc0202318 <commands+0x1d8>
void print_regs(struct pushregs *gpr) {
ffffffffc020085c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020085e:	87bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200862:	640c                	ld	a1,8(s0)
ffffffffc0200864:	00002517          	auipc	a0,0x2
ffffffffc0200868:	acc50513          	addi	a0,a0,-1332 # ffffffffc0202330 <commands+0x1f0>
ffffffffc020086c:	86dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200870:	680c                	ld	a1,16(s0)
ffffffffc0200872:	00002517          	auipc	a0,0x2
ffffffffc0200876:	ad650513          	addi	a0,a0,-1322 # ffffffffc0202348 <commands+0x208>
ffffffffc020087a:	85fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020087e:	6c0c                	ld	a1,24(s0)
ffffffffc0200880:	00002517          	auipc	a0,0x2
ffffffffc0200884:	ae050513          	addi	a0,a0,-1312 # ffffffffc0202360 <commands+0x220>
ffffffffc0200888:	851ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc020088c:	700c                	ld	a1,32(s0)
ffffffffc020088e:	00002517          	auipc	a0,0x2
ffffffffc0200892:	aea50513          	addi	a0,a0,-1302 # ffffffffc0202378 <commands+0x238>
ffffffffc0200896:	843ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020089a:	740c                	ld	a1,40(s0)
ffffffffc020089c:	00002517          	auipc	a0,0x2
ffffffffc02008a0:	af450513          	addi	a0,a0,-1292 # ffffffffc0202390 <commands+0x250>
ffffffffc02008a4:	835ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02008a8:	780c                	ld	a1,48(s0)
ffffffffc02008aa:	00002517          	auipc	a0,0x2
ffffffffc02008ae:	afe50513          	addi	a0,a0,-1282 # ffffffffc02023a8 <commands+0x268>
ffffffffc02008b2:	827ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02008b6:	7c0c                	ld	a1,56(s0)
ffffffffc02008b8:	00002517          	auipc	a0,0x2
ffffffffc02008bc:	b0850513          	addi	a0,a0,-1272 # ffffffffc02023c0 <commands+0x280>
ffffffffc02008c0:	819ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02008c4:	602c                	ld	a1,64(s0)
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	b1250513          	addi	a0,a0,-1262 # ffffffffc02023d8 <commands+0x298>
ffffffffc02008ce:	80bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02008d2:	642c                	ld	a1,72(s0)
ffffffffc02008d4:	00002517          	auipc	a0,0x2
ffffffffc02008d8:	b1c50513          	addi	a0,a0,-1252 # ffffffffc02023f0 <commands+0x2b0>
ffffffffc02008dc:	ffcff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02008e0:	682c                	ld	a1,80(s0)
ffffffffc02008e2:	00002517          	auipc	a0,0x2
ffffffffc02008e6:	b2650513          	addi	a0,a0,-1242 # ffffffffc0202408 <commands+0x2c8>
ffffffffc02008ea:	feeff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008ee:	6c2c                	ld	a1,88(s0)
ffffffffc02008f0:	00002517          	auipc	a0,0x2
ffffffffc02008f4:	b3050513          	addi	a0,a0,-1232 # ffffffffc0202420 <commands+0x2e0>
ffffffffc02008f8:	fe0ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008fc:	702c                	ld	a1,96(s0)
ffffffffc02008fe:	00002517          	auipc	a0,0x2
ffffffffc0200902:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0202438 <commands+0x2f8>
ffffffffc0200906:	fd2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020090a:	742c                	ld	a1,104(s0)
ffffffffc020090c:	00002517          	auipc	a0,0x2
ffffffffc0200910:	b4450513          	addi	a0,a0,-1212 # ffffffffc0202450 <commands+0x310>
ffffffffc0200914:	fc4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200918:	782c                	ld	a1,112(s0)
ffffffffc020091a:	00002517          	auipc	a0,0x2
ffffffffc020091e:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0202468 <commands+0x328>
ffffffffc0200922:	fb6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200926:	7c2c                	ld	a1,120(s0)
ffffffffc0200928:	00002517          	auipc	a0,0x2
ffffffffc020092c:	b5850513          	addi	a0,a0,-1192 # ffffffffc0202480 <commands+0x340>
ffffffffc0200930:	fa8ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200934:	604c                	ld	a1,128(s0)
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	b6250513          	addi	a0,a0,-1182 # ffffffffc0202498 <commands+0x358>
ffffffffc020093e:	f9aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200942:	644c                	ld	a1,136(s0)
ffffffffc0200944:	00002517          	auipc	a0,0x2
ffffffffc0200948:	b6c50513          	addi	a0,a0,-1172 # ffffffffc02024b0 <commands+0x370>
ffffffffc020094c:	f8cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200950:	684c                	ld	a1,144(s0)
ffffffffc0200952:	00002517          	auipc	a0,0x2
ffffffffc0200956:	b7650513          	addi	a0,a0,-1162 # ffffffffc02024c8 <commands+0x388>
ffffffffc020095a:	f7eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020095e:	6c4c                	ld	a1,152(s0)
ffffffffc0200960:	00002517          	auipc	a0,0x2
ffffffffc0200964:	b8050513          	addi	a0,a0,-1152 # ffffffffc02024e0 <commands+0x3a0>
ffffffffc0200968:	f70ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020096c:	704c                	ld	a1,160(s0)
ffffffffc020096e:	00002517          	auipc	a0,0x2
ffffffffc0200972:	b8a50513          	addi	a0,a0,-1142 # ffffffffc02024f8 <commands+0x3b8>
ffffffffc0200976:	f62ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020097a:	744c                	ld	a1,168(s0)
ffffffffc020097c:	00002517          	auipc	a0,0x2
ffffffffc0200980:	b9450513          	addi	a0,a0,-1132 # ffffffffc0202510 <commands+0x3d0>
ffffffffc0200984:	f54ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200988:	784c                	ld	a1,176(s0)
ffffffffc020098a:	00002517          	auipc	a0,0x2
ffffffffc020098e:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0202528 <commands+0x3e8>
ffffffffc0200992:	f46ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200996:	7c4c                	ld	a1,184(s0)
ffffffffc0200998:	00002517          	auipc	a0,0x2
ffffffffc020099c:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202540 <commands+0x400>
ffffffffc02009a0:	f38ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02009a4:	606c                	ld	a1,192(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202558 <commands+0x418>
ffffffffc02009ae:	f2aff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02009b2:	646c                	ld	a1,200(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0202570 <commands+0x430>
ffffffffc02009bc:	f1cff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02009c0:	686c                	ld	a1,208(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	bc650513          	addi	a0,a0,-1082 # ffffffffc0202588 <commands+0x448>
ffffffffc02009ca:	f0eff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02009ce:	6c6c                	ld	a1,216(s0)
ffffffffc02009d0:	00002517          	auipc	a0,0x2
ffffffffc02009d4:	bd050513          	addi	a0,a0,-1072 # ffffffffc02025a0 <commands+0x460>
ffffffffc02009d8:	f00ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02009dc:	706c                	ld	a1,224(s0)
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	bda50513          	addi	a0,a0,-1062 # ffffffffc02025b8 <commands+0x478>
ffffffffc02009e6:	ef2ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02009ea:	746c                	ld	a1,232(s0)
ffffffffc02009ec:	00002517          	auipc	a0,0x2
ffffffffc02009f0:	be450513          	addi	a0,a0,-1052 # ffffffffc02025d0 <commands+0x490>
ffffffffc02009f4:	ee4ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009f8:	786c                	ld	a1,240(s0)
ffffffffc02009fa:	00002517          	auipc	a0,0x2
ffffffffc02009fe:	bee50513          	addi	a0,a0,-1042 # ffffffffc02025e8 <commands+0x4a8>
ffffffffc0200a02:	ed6ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a06:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200a08:	6402                	ld	s0,0(sp)
ffffffffc0200a0a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a0c:	00002517          	auipc	a0,0x2
ffffffffc0200a10:	bf450513          	addi	a0,a0,-1036 # ffffffffc0202600 <commands+0x4c0>
}
ffffffffc0200a14:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200a16:	ec2ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a1a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a1a:	1141                	addi	sp,sp,-16
ffffffffc0200a1c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a1e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a20:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	bf650513          	addi	a0,a0,-1034 # ffffffffc0202618 <commands+0x4d8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200a2a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200a2c:	eacff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200a30:	8522                	mv	a0,s0
ffffffffc0200a32:	e1bff0ef          	jal	ra,ffffffffc020084c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200a36:	10043583          	ld	a1,256(s0)
ffffffffc0200a3a:	00002517          	auipc	a0,0x2
ffffffffc0200a3e:	bf650513          	addi	a0,a0,-1034 # ffffffffc0202630 <commands+0x4f0>
ffffffffc0200a42:	e96ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200a46:	10843583          	ld	a1,264(s0)
ffffffffc0200a4a:	00002517          	auipc	a0,0x2
ffffffffc0200a4e:	bfe50513          	addi	a0,a0,-1026 # ffffffffc0202648 <commands+0x508>
ffffffffc0200a52:	e86ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a56:	11043583          	ld	a1,272(s0)
ffffffffc0200a5a:	00002517          	auipc	a0,0x2
ffffffffc0200a5e:	c0650513          	addi	a0,a0,-1018 # ffffffffc0202660 <commands+0x520>
ffffffffc0200a62:	e76ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a66:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a6a:	6402                	ld	s0,0(sp)
ffffffffc0200a6c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a6e:	00002517          	auipc	a0,0x2
ffffffffc0200a72:	c0a50513          	addi	a0,a0,-1014 # ffffffffc0202678 <commands+0x538>
}
ffffffffc0200a76:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a78:	e60ff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc0200a7c <interrupt_handler>:
    uint16_t insn = *(volatile uint16_t *)epc;
    return (insn & 0x3) == 0x3 ? 4 : 2;
}

void interrupt_handler(struct trapframe *tf) {
    uintptr_t cause = tf->cause & ~((uintptr_t)1 << 63);
ffffffffc0200a7c:	11853583          	ld	a1,280(a0)
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a80:	1141                	addi	sp,sp,-16
ffffffffc0200a82:	e406                	sd	ra,8(sp)
    uintptr_t cause = tf->cause & ~((uintptr_t)1 << 63);
ffffffffc0200a84:	0586                	slli	a1,a1,0x1
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a86:	e022                	sd	s0,0(sp)

    switch (cause) {
ffffffffc0200a88:	4795                	li	a5,5
    uintptr_t cause = tf->cause & ~((uintptr_t)1 << 63);
ffffffffc0200a8a:	8185                	srli	a1,a1,0x1
    switch (cause) {
ffffffffc0200a8c:	02f58563          	beq	a1,a5,ffffffffc0200ab6 <interrupt_handler+0x3a>
ffffffffc0200a90:	47a5                	li	a5,9
ffffffffc0200a92:	04f58e63          	beq	a1,a5,ffffffffc0200aee <interrupt_handler+0x72>
ffffffffc0200a96:	4785                	li	a5,1
ffffffffc0200a98:	04f58263          	beq	a1,a5,ffffffffc0200adc <interrupt_handler+0x60>
        break;
    case IRQ_S_EXT:
        cprintf("Supervisor external interrupt\n");
        break;
    default:
        cprintf("Unknown interrupt: cause %d\n", (int)cause);
ffffffffc0200a9c:	842a                	mv	s0,a0
ffffffffc0200a9e:	2581                	sext.w	a1,a1
ffffffffc0200aa0:	00002517          	auipc	a0,0x2
ffffffffc0200aa4:	c4050513          	addi	a0,a0,-960 # ffffffffc02026e0 <commands+0x5a0>
ffffffffc0200aa8:	e30ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        print_trapframe(tf);
ffffffffc0200aac:	8522                	mv	a0,s0
        break;
    }
}
ffffffffc0200aae:	6402                	ld	s0,0(sp)
ffffffffc0200ab0:	60a2                	ld	ra,8(sp)
ffffffffc0200ab2:	0141                	addi	sp,sp,16
        print_trapframe(tf);
ffffffffc0200ab4:	b79d                	j	ffffffffc0200a1a <print_trapframe>
        ticks++;
ffffffffc0200ab6:	00006417          	auipc	s0,0x6
ffffffffc0200aba:	99240413          	addi	s0,s0,-1646 # ffffffffc0206448 <ticks>
ffffffffc0200abe:	601c                	ld	a5,0(s0)
ffffffffc0200ac0:	0785                	addi	a5,a5,1
ffffffffc0200ac2:	e01c                	sd	a5,0(s0)
        clock_set_next_event();
ffffffffc0200ac4:	99dff0ef          	jal	ra,ffffffffc0200460 <clock_set_next_event>
        if (ticks % TICK_NUM == 0) {
ffffffffc0200ac8:	601c                	ld	a5,0(s0)
ffffffffc0200aca:	06400713          	li	a4,100
ffffffffc0200ace:	02e7f7b3          	remu	a5,a5,a4
ffffffffc0200ad2:	c79d                	beqz	a5,ffffffffc0200b00 <interrupt_handler+0x84>
}
ffffffffc0200ad4:	60a2                	ld	ra,8(sp)
ffffffffc0200ad6:	6402                	ld	s0,0(sp)
ffffffffc0200ad8:	0141                	addi	sp,sp,16
ffffffffc0200ada:	8082                	ret
ffffffffc0200adc:	6402                	ld	s0,0(sp)
ffffffffc0200ade:	60a2                	ld	ra,8(sp)
        cprintf("Supervisor software interrupt\n");
ffffffffc0200ae0:	00002517          	auipc	a0,0x2
ffffffffc0200ae4:	bc050513          	addi	a0,a0,-1088 # ffffffffc02026a0 <commands+0x560>
}
ffffffffc0200ae8:	0141                	addi	sp,sp,16
        cprintf("Supervisor external interrupt\n");
ffffffffc0200aea:	deeff06f          	j	ffffffffc02000d8 <cprintf>
}
ffffffffc0200aee:	6402                	ld	s0,0(sp)
ffffffffc0200af0:	60a2                	ld	ra,8(sp)
        cprintf("Supervisor external interrupt\n");
ffffffffc0200af2:	00002517          	auipc	a0,0x2
ffffffffc0200af6:	bce50513          	addi	a0,a0,-1074 # ffffffffc02026c0 <commands+0x580>
}
ffffffffc0200afa:	0141                	addi	sp,sp,16
        cprintf("Supervisor external interrupt\n");
ffffffffc0200afc:	ddcff06f          	j	ffffffffc02000d8 <cprintf>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200b00:	06400593          	li	a1,100
ffffffffc0200b04:	00002517          	auipc	a0,0x2
ffffffffc0200b08:	b8c50513          	addi	a0,a0,-1140 # ffffffffc0202690 <commands+0x550>
ffffffffc0200b0c:	dccff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
            if (ticks / TICK_NUM >= SHUTDOWN_AFTER) {
ffffffffc0200b10:	6018                	ld	a4,0(s0)
ffffffffc0200b12:	3e700793          	li	a5,999
ffffffffc0200b16:	fae7ffe3          	bgeu	a5,a4,ffffffffc0200ad4 <interrupt_handler+0x58>
}
ffffffffc0200b1a:	6402                	ld	s0,0(sp)
ffffffffc0200b1c:	60a2                	ld	ra,8(sp)
ffffffffc0200b1e:	0141                	addi	sp,sp,16
                sbi_shutdown();
ffffffffc0200b20:	3060106f          	j	ffffffffc0201e26 <sbi_shutdown>

ffffffffc0200b24 <exception_handler>:

void exception_handler(struct trapframe *tf) {
ffffffffc0200b24:	1101                	addi	sp,sp,-32
ffffffffc0200b26:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200b28:	11853483          	ld	s1,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200b2c:	e822                	sd	s0,16(sp)
ffffffffc0200b2e:	ec06                	sd	ra,24(sp)
    switch (tf->cause) {
ffffffffc0200b30:	4789                	li	a5,2
void exception_handler(struct trapframe *tf) {
ffffffffc0200b32:	842a                	mv	s0,a0
    switch (tf->cause) {
ffffffffc0200b34:	00f48a63          	beq	s1,a5,ffffffffc0200b48 <exception_handler+0x24>
ffffffffc0200b38:	478d                	li	a5,3
ffffffffc0200b3a:	04f48063          	beq	s1,a5,ffffffffc0200b7a <exception_handler+0x56>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200b3e:	6442                	ld	s0,16(sp)
ffffffffc0200b40:	60e2                	ld	ra,24(sp)
ffffffffc0200b42:	64a2                	ld	s1,8(sp)
ffffffffc0200b44:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200b46:	bdd1                	j	ffffffffc0200a1a <print_trapframe>
        cprintf("Illegal instruction at 0x%016lx\n", tf->epc);
ffffffffc0200b48:	10853583          	ld	a1,264(a0)
ffffffffc0200b4c:	00002517          	auipc	a0,0x2
ffffffffc0200b50:	bb450513          	addi	a0,a0,-1100 # ffffffffc0202700 <commands+0x5c0>
ffffffffc0200b54:	d84ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        tf->epc += instruction_length(tf->epc);
ffffffffc0200b58:	10843783          	ld	a5,264(s0)
    return (insn & 0x3) == 0x3 ? 4 : 2;
ffffffffc0200b5c:	468d                	li	a3,3
    uint16_t insn = *(volatile uint16_t *)epc;
ffffffffc0200b5e:	0007d703          	lhu	a4,0(a5)
    return (insn & 0x3) == 0x3 ? 4 : 2;
ffffffffc0200b62:	8b0d                	andi	a4,a4,3
ffffffffc0200b64:	00d71363          	bne	a4,a3,ffffffffc0200b6a <exception_handler+0x46>
ffffffffc0200b68:	4491                	li	s1,4
        tf->epc += instruction_length(tf->epc);
ffffffffc0200b6a:	97a6                	add	a5,a5,s1
}
ffffffffc0200b6c:	60e2                	ld	ra,24(sp)
        tf->epc += instruction_length(tf->epc);
ffffffffc0200b6e:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200b72:	6442                	ld	s0,16(sp)
ffffffffc0200b74:	64a2                	ld	s1,8(sp)
ffffffffc0200b76:	6105                	addi	sp,sp,32
ffffffffc0200b78:	8082                	ret
        cprintf("Breakpoint at 0x%016lx\n", tf->epc);
ffffffffc0200b7a:	10853583          	ld	a1,264(a0)
ffffffffc0200b7e:	00002517          	auipc	a0,0x2
ffffffffc0200b82:	baa50513          	addi	a0,a0,-1110 # ffffffffc0202728 <commands+0x5e8>
ffffffffc0200b86:	d52ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
        tf->epc += instruction_length(tf->epc);
ffffffffc0200b8a:	10843783          	ld	a5,264(s0)
    return (insn & 0x3) == 0x3 ? 4 : 2;
ffffffffc0200b8e:	4691                	li	a3,4
    uint16_t insn = *(volatile uint16_t *)epc;
ffffffffc0200b90:	0007d703          	lhu	a4,0(a5)
    return (insn & 0x3) == 0x3 ? 4 : 2;
ffffffffc0200b94:	8b0d                	andi	a4,a4,3
ffffffffc0200b96:	00970363          	beq	a4,s1,ffffffffc0200b9c <exception_handler+0x78>
ffffffffc0200b9a:	4689                	li	a3,2
        tf->epc += instruction_length(tf->epc);
ffffffffc0200b9c:	97b6                	add	a5,a5,a3
}
ffffffffc0200b9e:	60e2                	ld	ra,24(sp)
        tf->epc += instruction_length(tf->epc);
ffffffffc0200ba0:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200ba4:	6442                	ld	s0,16(sp)
ffffffffc0200ba6:	64a2                	ld	s1,8(sp)
ffffffffc0200ba8:	6105                	addi	sp,sp,32
ffffffffc0200baa:	8082                	ret

ffffffffc0200bac <trap>:


static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200bac:	11853783          	ld	a5,280(a0)
ffffffffc0200bb0:	0007c363          	bltz	a5,ffffffffc0200bb6 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200bb4:	bf85                	j	ffffffffc0200b24 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200bb6:	b5d9                	j	ffffffffc0200a7c <interrupt_handler>

ffffffffc0200bb8 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200bb8:	14011073          	csrw	sscratch,sp
ffffffffc0200bbc:	712d                	addi	sp,sp,-288
ffffffffc0200bbe:	e002                	sd	zero,0(sp)
ffffffffc0200bc0:	e406                	sd	ra,8(sp)
ffffffffc0200bc2:	ec0e                	sd	gp,24(sp)
ffffffffc0200bc4:	f012                	sd	tp,32(sp)
ffffffffc0200bc6:	f416                	sd	t0,40(sp)
ffffffffc0200bc8:	f81a                	sd	t1,48(sp)
ffffffffc0200bca:	fc1e                	sd	t2,56(sp)
ffffffffc0200bcc:	e0a2                	sd	s0,64(sp)
ffffffffc0200bce:	e4a6                	sd	s1,72(sp)
ffffffffc0200bd0:	e8aa                	sd	a0,80(sp)
ffffffffc0200bd2:	ecae                	sd	a1,88(sp)
ffffffffc0200bd4:	f0b2                	sd	a2,96(sp)
ffffffffc0200bd6:	f4b6                	sd	a3,104(sp)
ffffffffc0200bd8:	f8ba                	sd	a4,112(sp)
ffffffffc0200bda:	fcbe                	sd	a5,120(sp)
ffffffffc0200bdc:	e142                	sd	a6,128(sp)
ffffffffc0200bde:	e546                	sd	a7,136(sp)
ffffffffc0200be0:	e94a                	sd	s2,144(sp)
ffffffffc0200be2:	ed4e                	sd	s3,152(sp)
ffffffffc0200be4:	f152                	sd	s4,160(sp)
ffffffffc0200be6:	f556                	sd	s5,168(sp)
ffffffffc0200be8:	f95a                	sd	s6,176(sp)
ffffffffc0200bea:	fd5e                	sd	s7,184(sp)
ffffffffc0200bec:	e1e2                	sd	s8,192(sp)
ffffffffc0200bee:	e5e6                	sd	s9,200(sp)
ffffffffc0200bf0:	e9ea                	sd	s10,208(sp)
ffffffffc0200bf2:	edee                	sd	s11,216(sp)
ffffffffc0200bf4:	f1f2                	sd	t3,224(sp)
ffffffffc0200bf6:	f5f6                	sd	t4,232(sp)
ffffffffc0200bf8:	f9fa                	sd	t5,240(sp)
ffffffffc0200bfa:	fdfe                	sd	t6,248(sp)
ffffffffc0200bfc:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200c00:	100024f3          	csrr	s1,sstatus
ffffffffc0200c04:	14102973          	csrr	s2,sepc
ffffffffc0200c08:	143029f3          	csrr	s3,stval
ffffffffc0200c0c:	14202a73          	csrr	s4,scause
ffffffffc0200c10:	e822                	sd	s0,16(sp)
ffffffffc0200c12:	e226                	sd	s1,256(sp)
ffffffffc0200c14:	e64a                	sd	s2,264(sp)
ffffffffc0200c16:	ea4e                	sd	s3,272(sp)
ffffffffc0200c18:	ee52                	sd	s4,280(sp)

    #lab3 function1 2411334
    mv a0, sp
ffffffffc0200c1a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200c1c:	f91ff0ef          	jal	ra,ffffffffc0200bac <trap>

ffffffffc0200c20 <__trapret>:

    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200c20:	6492                	ld	s1,256(sp)
ffffffffc0200c22:	10049073          	csrw	sstatus,s1
ffffffffc0200c26:	6932                	ld	s2,264(sp)
ffffffffc0200c28:	14191073          	csrw	sepc,s2
ffffffffc0200c2c:	69d2                	ld	s3,272(sp)
ffffffffc0200c2e:	14399073          	csrw	stval,s3
ffffffffc0200c32:	6a72                	ld	s4,280(sp)
ffffffffc0200c34:	142a1073          	csrw	scause,s4
ffffffffc0200c38:	60a2                	ld	ra,8(sp)
ffffffffc0200c3a:	61e2                	ld	gp,24(sp)
ffffffffc0200c3c:	7202                	ld	tp,32(sp)
ffffffffc0200c3e:	72a2                	ld	t0,40(sp)
ffffffffc0200c40:	7342                	ld	t1,48(sp)
ffffffffc0200c42:	73e2                	ld	t2,56(sp)
ffffffffc0200c44:	6406                	ld	s0,64(sp)
ffffffffc0200c46:	64a6                	ld	s1,72(sp)
ffffffffc0200c48:	6546                	ld	a0,80(sp)
ffffffffc0200c4a:	65e6                	ld	a1,88(sp)
ffffffffc0200c4c:	7606                	ld	a2,96(sp)
ffffffffc0200c4e:	76a6                	ld	a3,104(sp)
ffffffffc0200c50:	7746                	ld	a4,112(sp)
ffffffffc0200c52:	77e6                	ld	a5,120(sp)
ffffffffc0200c54:	680a                	ld	a6,128(sp)
ffffffffc0200c56:	68aa                	ld	a7,136(sp)
ffffffffc0200c58:	694a                	ld	s2,144(sp)
ffffffffc0200c5a:	69ea                	ld	s3,152(sp)
ffffffffc0200c5c:	7a0a                	ld	s4,160(sp)
ffffffffc0200c5e:	7aaa                	ld	s5,168(sp)
ffffffffc0200c60:	7b4a                	ld	s6,176(sp)
ffffffffc0200c62:	7bea                	ld	s7,184(sp)
ffffffffc0200c64:	6c0e                	ld	s8,192(sp)
ffffffffc0200c66:	6cae                	ld	s9,200(sp)
ffffffffc0200c68:	6d4e                	ld	s10,208(sp)
ffffffffc0200c6a:	6dee                	ld	s11,216(sp)
ffffffffc0200c6c:	7e0e                	ld	t3,224(sp)
ffffffffc0200c6e:	7eae                	ld	t4,232(sp)
ffffffffc0200c70:	7f4e                	ld	t5,240(sp)
ffffffffc0200c72:	7fee                	ld	t6,248(sp)
ffffffffc0200c74:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c76:	10200073          	sret

ffffffffc0200c7a <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c7a:	00005797          	auipc	a5,0x5
ffffffffc0200c7e:	3ae78793          	addi	a5,a5,942 # ffffffffc0206028 <free_area>
ffffffffc0200c82:	e79c                	sd	a5,8(a5)
ffffffffc0200c84:	e39c                	sd	a5,0(a5)

/* 初始化空闲链表 */
static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c86:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c8a:	8082                	ret

ffffffffc0200c8c <best_fit_nr_free_pages>:

/* 返回空闲页总数 */
static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c8c:	00005517          	auipc	a0,0x5
ffffffffc0200c90:	3ac56503          	lwu	a0,940(a0) # ffffffffc0206038 <free_area+0x10>
ffffffffc0200c94:	8082                	ret

ffffffffc0200c96 <best_fit_check>:
    free_page(p1);
    free_page(p2);
}

static void
best_fit_check(void) {
ffffffffc0200c96:	715d                	addi	sp,sp,-80
ffffffffc0200c98:	e0a2                	sd	s0,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c9a:	00005417          	auipc	s0,0x5
ffffffffc0200c9e:	38e40413          	addi	s0,s0,910 # ffffffffc0206028 <free_area>
ffffffffc0200ca2:	641c                	ld	a5,8(s0)
ffffffffc0200ca4:	e486                	sd	ra,72(sp)
ffffffffc0200ca6:	fc26                	sd	s1,56(sp)
ffffffffc0200ca8:	f84a                	sd	s2,48(sp)
ffffffffc0200caa:	f44e                	sd	s3,40(sp)
ffffffffc0200cac:	f052                	sd	s4,32(sp)
ffffffffc0200cae:	ec56                	sd	s5,24(sp)
ffffffffc0200cb0:	e85a                	sd	s6,16(sp)
ffffffffc0200cb2:	e45e                	sd	s7,8(sp)
ffffffffc0200cb4:	e062                	sd	s8,0(sp)
    int score = 0, sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cb6:	26878b63          	beq	a5,s0,ffffffffc0200f2c <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200cba:	4481                	li	s1,0
ffffffffc0200cbc:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200cbe:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200cc2:	8b09                	andi	a4,a4,2
ffffffffc0200cc4:	26070863          	beqz	a4,ffffffffc0200f34 <best_fit_check+0x29e>
        count++, total += p->property;
ffffffffc0200cc8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200ccc:	679c                	ld	a5,8(a5)
ffffffffc0200cce:	2905                	addiw	s2,s2,1
ffffffffc0200cd0:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200cd2:	fe8796e3          	bne	a5,s0,ffffffffc0200cbe <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200cd6:	89a6                	mv	s3,s1
ffffffffc0200cd8:	1af000ef          	jal	ra,ffffffffc0201686 <nr_free_pages>
ffffffffc0200cdc:	33351c63          	bne	a0,s3,ffffffffc0201014 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ce0:	4505                	li	a0,1
ffffffffc0200ce2:	127000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200ce6:	8a2a                	mv	s4,a0
ffffffffc0200ce8:	36050663          	beqz	a0,ffffffffc0201054 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200cec:	4505                	li	a0,1
ffffffffc0200cee:	11b000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200cf2:	89aa                	mv	s3,a0
ffffffffc0200cf4:	34050063          	beqz	a0,ffffffffc0201034 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200cf8:	4505                	li	a0,1
ffffffffc0200cfa:	10f000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200cfe:	8aaa                	mv	s5,a0
ffffffffc0200d00:	2c050a63          	beqz	a0,ffffffffc0200fd4 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d04:	253a0863          	beq	s4,s3,ffffffffc0200f54 <best_fit_check+0x2be>
ffffffffc0200d08:	24aa0663          	beq	s4,a0,ffffffffc0200f54 <best_fit_check+0x2be>
ffffffffc0200d0c:	24a98463          	beq	s3,a0,ffffffffc0200f54 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200d10:	000a2783          	lw	a5,0(s4)
ffffffffc0200d14:	26079063          	bnez	a5,ffffffffc0200f74 <best_fit_check+0x2de>
ffffffffc0200d18:	0009a783          	lw	a5,0(s3)
ffffffffc0200d1c:	24079c63          	bnez	a5,ffffffffc0200f74 <best_fit_check+0x2de>
ffffffffc0200d20:	411c                	lw	a5,0(a0)
ffffffffc0200d22:	24079963          	bnez	a5,ffffffffc0200f74 <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d26:	00005797          	auipc	a5,0x5
ffffffffc0200d2a:	7427b783          	ld	a5,1858(a5) # ffffffffc0206468 <pages>
ffffffffc0200d2e:	40fa0733          	sub	a4,s4,a5
ffffffffc0200d32:	870d                	srai	a4,a4,0x3
ffffffffc0200d34:	00002597          	auipc	a1,0x2
ffffffffc0200d38:	1645b583          	ld	a1,356(a1) # ffffffffc0202e98 <error_string+0x38>
ffffffffc0200d3c:	02b70733          	mul	a4,a4,a1
ffffffffc0200d40:	00002617          	auipc	a2,0x2
ffffffffc0200d44:	16863603          	ld	a2,360(a2) # ffffffffc0202ea8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200d48:	00005697          	auipc	a3,0x5
ffffffffc0200d4c:	7186b683          	ld	a3,1816(a3) # ffffffffc0206460 <npage>
ffffffffc0200d50:	06b2                	slli	a3,a3,0xc
ffffffffc0200d52:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d54:	0732                	slli	a4,a4,0xc
ffffffffc0200d56:	22d77f63          	bgeu	a4,a3,ffffffffc0200f94 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d5a:	40f98733          	sub	a4,s3,a5
ffffffffc0200d5e:	870d                	srai	a4,a4,0x3
ffffffffc0200d60:	02b70733          	mul	a4,a4,a1
ffffffffc0200d64:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d66:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d68:	3ed77663          	bgeu	a4,a3,ffffffffc0201154 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d6c:	40f507b3          	sub	a5,a0,a5
ffffffffc0200d70:	878d                	srai	a5,a5,0x3
ffffffffc0200d72:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d76:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d78:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d7a:	3ad7fd63          	bgeu	a5,a3,ffffffffc0201134 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200d7e:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d80:	00043c03          	ld	s8,0(s0)
ffffffffc0200d84:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200d88:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200d8c:	e400                	sd	s0,8(s0)
ffffffffc0200d8e:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200d90:	00005797          	auipc	a5,0x5
ffffffffc0200d94:	2a07a423          	sw	zero,680(a5) # ffffffffc0206038 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d98:	071000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200d9c:	36051c63          	bnez	a0,ffffffffc0201114 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200da0:	4585                	li	a1,1
ffffffffc0200da2:	8552                	mv	a0,s4
ffffffffc0200da4:	0a3000ef          	jal	ra,ffffffffc0201646 <free_pages>
    free_page(p1);
ffffffffc0200da8:	4585                	li	a1,1
ffffffffc0200daa:	854e                	mv	a0,s3
ffffffffc0200dac:	09b000ef          	jal	ra,ffffffffc0201646 <free_pages>
    free_page(p2);
ffffffffc0200db0:	4585                	li	a1,1
ffffffffc0200db2:	8556                	mv	a0,s5
ffffffffc0200db4:	093000ef          	jal	ra,ffffffffc0201646 <free_pages>
    assert(nr_free == 3);
ffffffffc0200db8:	4818                	lw	a4,16(s0)
ffffffffc0200dba:	478d                	li	a5,3
ffffffffc0200dbc:	32f71c63          	bne	a4,a5,ffffffffc02010f4 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200dc0:	4505                	li	a0,1
ffffffffc0200dc2:	047000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200dc6:	89aa                	mv	s3,a0
ffffffffc0200dc8:	30050663          	beqz	a0,ffffffffc02010d4 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200dcc:	4505                	li	a0,1
ffffffffc0200dce:	03b000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200dd2:	8aaa                	mv	s5,a0
ffffffffc0200dd4:	2e050063          	beqz	a0,ffffffffc02010b4 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200dd8:	4505                	li	a0,1
ffffffffc0200dda:	02f000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200dde:	8a2a                	mv	s4,a0
ffffffffc0200de0:	2a050a63          	beqz	a0,ffffffffc0201094 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200de4:	4505                	li	a0,1
ffffffffc0200de6:	023000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200dea:	28051563          	bnez	a0,ffffffffc0201074 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200dee:	4585                	li	a1,1
ffffffffc0200df0:	854e                	mv	a0,s3
ffffffffc0200df2:	055000ef          	jal	ra,ffffffffc0201646 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200df6:	641c                	ld	a5,8(s0)
ffffffffc0200df8:	1a878e63          	beq	a5,s0,ffffffffc0200fb4 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200dfc:	4505                	li	a0,1
ffffffffc0200dfe:	00b000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200e02:	52a99963          	bne	s3,a0,ffffffffc0201334 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200e06:	4505                	li	a0,1
ffffffffc0200e08:	001000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200e0c:	50051463          	bnez	a0,ffffffffc0201314 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200e10:	481c                	lw	a5,16(s0)
ffffffffc0200e12:	4e079163          	bnez	a5,ffffffffc02012f4 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200e16:	854e                	mv	a0,s3
ffffffffc0200e18:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200e1a:	01843023          	sd	s8,0(s0)
ffffffffc0200e1e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200e22:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200e26:	021000ef          	jal	ra,ffffffffc0201646 <free_pages>
    free_page(p1);
ffffffffc0200e2a:	4585                	li	a1,1
ffffffffc0200e2c:	8556                	mv	a0,s5
ffffffffc0200e2e:	019000ef          	jal	ra,ffffffffc0201646 <free_pages>
    free_page(p2);
ffffffffc0200e32:	4585                	li	a1,1
ffffffffc0200e34:	8552                	mv	a0,s4
ffffffffc0200e36:	011000ef          	jal	ra,ffffffffc0201646 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200e3a:	4515                	li	a0,5
ffffffffc0200e3c:	7cc000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200e40:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e42:	48050963          	beqz	a0,ffffffffc02012d4 <best_fit_check+0x63e>
ffffffffc0200e46:	651c                	ld	a5,8(a0)
ffffffffc0200e48:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200e4a:	8b85                	andi	a5,a5,1
ffffffffc0200e4c:	46079463          	bnez	a5,ffffffffc02012b4 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200e50:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e52:	00043a83          	ld	s5,0(s0)
ffffffffc0200e56:	00843a03          	ld	s4,8(s0)
ffffffffc0200e5a:	e000                	sd	s0,0(s0)
ffffffffc0200e5c:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200e5e:	7aa000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200e62:	42051963          	bnez	a0,ffffffffc0201294 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200e66:	4589                	li	a1,2
ffffffffc0200e68:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200e6c:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200e70:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200e74:	00005797          	auipc	a5,0x5
ffffffffc0200e78:	1c07a223          	sw	zero,452(a5) # ffffffffc0206038 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200e7c:	7ca000ef          	jal	ra,ffffffffc0201646 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200e80:	8562                	mv	a0,s8
ffffffffc0200e82:	4585                	li	a1,1
ffffffffc0200e84:	7c2000ef          	jal	ra,ffffffffc0201646 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e88:	4511                	li	a0,4
ffffffffc0200e8a:	77e000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200e8e:	3e051363          	bnez	a0,ffffffffc0201274 <best_fit_check+0x5de>
ffffffffc0200e92:	0309b783          	ld	a5,48(s3)
ffffffffc0200e96:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200e98:	8b85                	andi	a5,a5,1
ffffffffc0200e9a:	3a078d63          	beqz	a5,ffffffffc0201254 <best_fit_check+0x5be>
ffffffffc0200e9e:	0389a703          	lw	a4,56(s3)
ffffffffc0200ea2:	4789                	li	a5,2
ffffffffc0200ea4:	3af71863          	bne	a4,a5,ffffffffc0201254 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200ea8:	4505                	li	a0,1
ffffffffc0200eaa:	75e000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200eae:	8baa                	mv	s7,a0
ffffffffc0200eb0:	38050263          	beqz	a0,ffffffffc0201234 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);
ffffffffc0200eb4:	4509                	li	a0,2
ffffffffc0200eb6:	752000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200eba:	34050d63          	beqz	a0,ffffffffc0201214 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200ebe:	337c1b63          	bne	s8,s7,ffffffffc02011f4 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200ec2:	854e                	mv	a0,s3
ffffffffc0200ec4:	4595                	li	a1,5
ffffffffc0200ec6:	780000ef          	jal	ra,ffffffffc0201646 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200eca:	4515                	li	a0,5
ffffffffc0200ecc:	73c000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200ed0:	89aa                	mv	s3,a0
ffffffffc0200ed2:	30050163          	beqz	a0,ffffffffc02011d4 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200ed6:	4505                	li	a0,1
ffffffffc0200ed8:	730000ef          	jal	ra,ffffffffc0201608 <alloc_pages>
ffffffffc0200edc:	2c051c63          	bnez	a0,ffffffffc02011b4 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200ee0:	481c                	lw	a5,16(s0)
ffffffffc0200ee2:	2a079963          	bnez	a5,ffffffffc0201194 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200ee6:	4595                	li	a1,5
ffffffffc0200ee8:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200eea:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200eee:	01543023          	sd	s5,0(s0)
ffffffffc0200ef2:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200ef6:	750000ef          	jal	ra,ffffffffc0201646 <free_pages>
    return listelm->next;
ffffffffc0200efa:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200efc:	00878963          	beq	a5,s0,ffffffffc0200f0e <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0200f00:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200f04:	679c                	ld	a5,8(a5)
ffffffffc0200f06:	397d                	addiw	s2,s2,-1
ffffffffc0200f08:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f0a:	fe879be3          	bne	a5,s0,ffffffffc0200f00 <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200f0e:	26091363          	bnez	s2,ffffffffc0201174 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200f12:	e0ed                	bnez	s1,ffffffffc0200ff4 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n", score, sumscore);
    #endif
}
ffffffffc0200f14:	60a6                	ld	ra,72(sp)
ffffffffc0200f16:	6406                	ld	s0,64(sp)
ffffffffc0200f18:	74e2                	ld	s1,56(sp)
ffffffffc0200f1a:	7942                	ld	s2,48(sp)
ffffffffc0200f1c:	79a2                	ld	s3,40(sp)
ffffffffc0200f1e:	7a02                	ld	s4,32(sp)
ffffffffc0200f20:	6ae2                	ld	s5,24(sp)
ffffffffc0200f22:	6b42                	ld	s6,16(sp)
ffffffffc0200f24:	6ba2                	ld	s7,8(sp)
ffffffffc0200f26:	6c02                	ld	s8,0(sp)
ffffffffc0200f28:	6161                	addi	sp,sp,80
ffffffffc0200f2a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200f2c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200f2e:	4481                	li	s1,0
ffffffffc0200f30:	4901                	li	s2,0
ffffffffc0200f32:	b35d                	j	ffffffffc0200cd8 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200f34:	00002697          	auipc	a3,0x2
ffffffffc0200f38:	80c68693          	addi	a3,a3,-2036 # ffffffffc0202740 <commands+0x600>
ffffffffc0200f3c:	00002617          	auipc	a2,0x2
ffffffffc0200f40:	81460613          	addi	a2,a2,-2028 # ffffffffc0202750 <commands+0x610>
ffffffffc0200f44:	0d800593          	li	a1,216
ffffffffc0200f48:	00002517          	auipc	a0,0x2
ffffffffc0200f4c:	82050513          	addi	a0,a0,-2016 # ffffffffc0202768 <commands+0x628>
ffffffffc0200f50:	c82ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f54:	00002697          	auipc	a3,0x2
ffffffffc0200f58:	8ac68693          	addi	a3,a3,-1876 # ffffffffc0202800 <commands+0x6c0>
ffffffffc0200f5c:	00001617          	auipc	a2,0x1
ffffffffc0200f60:	7f460613          	addi	a2,a2,2036 # ffffffffc0202750 <commands+0x610>
ffffffffc0200f64:	0a600593          	li	a1,166
ffffffffc0200f68:	00002517          	auipc	a0,0x2
ffffffffc0200f6c:	80050513          	addi	a0,a0,-2048 # ffffffffc0202768 <commands+0x628>
ffffffffc0200f70:	c62ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f74:	00002697          	auipc	a3,0x2
ffffffffc0200f78:	8b468693          	addi	a3,a3,-1868 # ffffffffc0202828 <commands+0x6e8>
ffffffffc0200f7c:	00001617          	auipc	a2,0x1
ffffffffc0200f80:	7d460613          	addi	a2,a2,2004 # ffffffffc0202750 <commands+0x610>
ffffffffc0200f84:	0a700593          	li	a1,167
ffffffffc0200f88:	00001517          	auipc	a0,0x1
ffffffffc0200f8c:	7e050513          	addi	a0,a0,2016 # ffffffffc0202768 <commands+0x628>
ffffffffc0200f90:	c42ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f94:	00002697          	auipc	a3,0x2
ffffffffc0200f98:	8d468693          	addi	a3,a3,-1836 # ffffffffc0202868 <commands+0x728>
ffffffffc0200f9c:	00001617          	auipc	a2,0x1
ffffffffc0200fa0:	7b460613          	addi	a2,a2,1972 # ffffffffc0202750 <commands+0x610>
ffffffffc0200fa4:	0a900593          	li	a1,169
ffffffffc0200fa8:	00001517          	auipc	a0,0x1
ffffffffc0200fac:	7c050513          	addi	a0,a0,1984 # ffffffffc0202768 <commands+0x628>
ffffffffc0200fb0:	c22ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200fb4:	00002697          	auipc	a3,0x2
ffffffffc0200fb8:	93c68693          	addi	a3,a3,-1732 # ffffffffc02028f0 <commands+0x7b0>
ffffffffc0200fbc:	00001617          	auipc	a2,0x1
ffffffffc0200fc0:	79460613          	addi	a2,a2,1940 # ffffffffc0202750 <commands+0x610>
ffffffffc0200fc4:	0c200593          	li	a1,194
ffffffffc0200fc8:	00001517          	auipc	a0,0x1
ffffffffc0200fcc:	7a050513          	addi	a0,a0,1952 # ffffffffc0202768 <commands+0x628>
ffffffffc0200fd0:	c02ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fd4:	00002697          	auipc	a3,0x2
ffffffffc0200fd8:	80c68693          	addi	a3,a3,-2036 # ffffffffc02027e0 <commands+0x6a0>
ffffffffc0200fdc:	00001617          	auipc	a2,0x1
ffffffffc0200fe0:	77460613          	addi	a2,a2,1908 # ffffffffc0202750 <commands+0x610>
ffffffffc0200fe4:	0a400593          	li	a1,164
ffffffffc0200fe8:	00001517          	auipc	a0,0x1
ffffffffc0200fec:	78050513          	addi	a0,a0,1920 # ffffffffc0202768 <commands+0x628>
ffffffffc0200ff0:	be2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == 0);
ffffffffc0200ff4:	00002697          	auipc	a3,0x2
ffffffffc0200ff8:	a2c68693          	addi	a3,a3,-1492 # ffffffffc0202a20 <commands+0x8e0>
ffffffffc0200ffc:	00001617          	auipc	a2,0x1
ffffffffc0201000:	75460613          	addi	a2,a2,1876 # ffffffffc0202750 <commands+0x610>
ffffffffc0201004:	11a00593          	li	a1,282
ffffffffc0201008:	00001517          	auipc	a0,0x1
ffffffffc020100c:	76050513          	addi	a0,a0,1888 # ffffffffc0202768 <commands+0x628>
ffffffffc0201010:	bc2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201014:	00001697          	auipc	a3,0x1
ffffffffc0201018:	76c68693          	addi	a3,a3,1900 # ffffffffc0202780 <commands+0x640>
ffffffffc020101c:	00001617          	auipc	a2,0x1
ffffffffc0201020:	73460613          	addi	a2,a2,1844 # ffffffffc0202750 <commands+0x610>
ffffffffc0201024:	0db00593          	li	a1,219
ffffffffc0201028:	00001517          	auipc	a0,0x1
ffffffffc020102c:	74050513          	addi	a0,a0,1856 # ffffffffc0202768 <commands+0x628>
ffffffffc0201030:	ba2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201034:	00001697          	auipc	a3,0x1
ffffffffc0201038:	78c68693          	addi	a3,a3,1932 # ffffffffc02027c0 <commands+0x680>
ffffffffc020103c:	00001617          	auipc	a2,0x1
ffffffffc0201040:	71460613          	addi	a2,a2,1812 # ffffffffc0202750 <commands+0x610>
ffffffffc0201044:	0a300593          	li	a1,163
ffffffffc0201048:	00001517          	auipc	a0,0x1
ffffffffc020104c:	72050513          	addi	a0,a0,1824 # ffffffffc0202768 <commands+0x628>
ffffffffc0201050:	b82ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201054:	00001697          	auipc	a3,0x1
ffffffffc0201058:	74c68693          	addi	a3,a3,1868 # ffffffffc02027a0 <commands+0x660>
ffffffffc020105c:	00001617          	auipc	a2,0x1
ffffffffc0201060:	6f460613          	addi	a2,a2,1780 # ffffffffc0202750 <commands+0x610>
ffffffffc0201064:	0a200593          	li	a1,162
ffffffffc0201068:	00001517          	auipc	a0,0x1
ffffffffc020106c:	70050513          	addi	a0,a0,1792 # ffffffffc0202768 <commands+0x628>
ffffffffc0201070:	b62ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201074:	00002697          	auipc	a3,0x2
ffffffffc0201078:	85468693          	addi	a3,a3,-1964 # ffffffffc02028c8 <commands+0x788>
ffffffffc020107c:	00001617          	auipc	a2,0x1
ffffffffc0201080:	6d460613          	addi	a2,a2,1748 # ffffffffc0202750 <commands+0x610>
ffffffffc0201084:	0bf00593          	li	a1,191
ffffffffc0201088:	00001517          	auipc	a0,0x1
ffffffffc020108c:	6e050513          	addi	a0,a0,1760 # ffffffffc0202768 <commands+0x628>
ffffffffc0201090:	b42ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201094:	00001697          	auipc	a3,0x1
ffffffffc0201098:	74c68693          	addi	a3,a3,1868 # ffffffffc02027e0 <commands+0x6a0>
ffffffffc020109c:	00001617          	auipc	a2,0x1
ffffffffc02010a0:	6b460613          	addi	a2,a2,1716 # ffffffffc0202750 <commands+0x610>
ffffffffc02010a4:	0bd00593          	li	a1,189
ffffffffc02010a8:	00001517          	auipc	a0,0x1
ffffffffc02010ac:	6c050513          	addi	a0,a0,1728 # ffffffffc0202768 <commands+0x628>
ffffffffc02010b0:	b22ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010b4:	00001697          	auipc	a3,0x1
ffffffffc02010b8:	70c68693          	addi	a3,a3,1804 # ffffffffc02027c0 <commands+0x680>
ffffffffc02010bc:	00001617          	auipc	a2,0x1
ffffffffc02010c0:	69460613          	addi	a2,a2,1684 # ffffffffc0202750 <commands+0x610>
ffffffffc02010c4:	0bc00593          	li	a1,188
ffffffffc02010c8:	00001517          	auipc	a0,0x1
ffffffffc02010cc:	6a050513          	addi	a0,a0,1696 # ffffffffc0202768 <commands+0x628>
ffffffffc02010d0:	b02ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02010d4:	00001697          	auipc	a3,0x1
ffffffffc02010d8:	6cc68693          	addi	a3,a3,1740 # ffffffffc02027a0 <commands+0x660>
ffffffffc02010dc:	00001617          	auipc	a2,0x1
ffffffffc02010e0:	67460613          	addi	a2,a2,1652 # ffffffffc0202750 <commands+0x610>
ffffffffc02010e4:	0bb00593          	li	a1,187
ffffffffc02010e8:	00001517          	auipc	a0,0x1
ffffffffc02010ec:	68050513          	addi	a0,a0,1664 # ffffffffc0202768 <commands+0x628>
ffffffffc02010f0:	ae2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 3);
ffffffffc02010f4:	00001697          	auipc	a3,0x1
ffffffffc02010f8:	7ec68693          	addi	a3,a3,2028 # ffffffffc02028e0 <commands+0x7a0>
ffffffffc02010fc:	00001617          	auipc	a2,0x1
ffffffffc0201100:	65460613          	addi	a2,a2,1620 # ffffffffc0202750 <commands+0x610>
ffffffffc0201104:	0b900593          	li	a1,185
ffffffffc0201108:	00001517          	auipc	a0,0x1
ffffffffc020110c:	66050513          	addi	a0,a0,1632 # ffffffffc0202768 <commands+0x628>
ffffffffc0201110:	ac2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201114:	00001697          	auipc	a3,0x1
ffffffffc0201118:	7b468693          	addi	a3,a3,1972 # ffffffffc02028c8 <commands+0x788>
ffffffffc020111c:	00001617          	auipc	a2,0x1
ffffffffc0201120:	63460613          	addi	a2,a2,1588 # ffffffffc0202750 <commands+0x610>
ffffffffc0201124:	0b400593          	li	a1,180
ffffffffc0201128:	00001517          	auipc	a0,0x1
ffffffffc020112c:	64050513          	addi	a0,a0,1600 # ffffffffc0202768 <commands+0x628>
ffffffffc0201130:	aa2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201134:	00001697          	auipc	a3,0x1
ffffffffc0201138:	77468693          	addi	a3,a3,1908 # ffffffffc02028a8 <commands+0x768>
ffffffffc020113c:	00001617          	auipc	a2,0x1
ffffffffc0201140:	61460613          	addi	a2,a2,1556 # ffffffffc0202750 <commands+0x610>
ffffffffc0201144:	0ab00593          	li	a1,171
ffffffffc0201148:	00001517          	auipc	a0,0x1
ffffffffc020114c:	62050513          	addi	a0,a0,1568 # ffffffffc0202768 <commands+0x628>
ffffffffc0201150:	a82ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201154:	00001697          	auipc	a3,0x1
ffffffffc0201158:	73468693          	addi	a3,a3,1844 # ffffffffc0202888 <commands+0x748>
ffffffffc020115c:	00001617          	auipc	a2,0x1
ffffffffc0201160:	5f460613          	addi	a2,a2,1524 # ffffffffc0202750 <commands+0x610>
ffffffffc0201164:	0aa00593          	li	a1,170
ffffffffc0201168:	00001517          	auipc	a0,0x1
ffffffffc020116c:	60050513          	addi	a0,a0,1536 # ffffffffc0202768 <commands+0x628>
ffffffffc0201170:	a62ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(count == 0);
ffffffffc0201174:	00002697          	auipc	a3,0x2
ffffffffc0201178:	89c68693          	addi	a3,a3,-1892 # ffffffffc0202a10 <commands+0x8d0>
ffffffffc020117c:	00001617          	auipc	a2,0x1
ffffffffc0201180:	5d460613          	addi	a2,a2,1492 # ffffffffc0202750 <commands+0x610>
ffffffffc0201184:	11900593          	li	a1,281
ffffffffc0201188:	00001517          	auipc	a0,0x1
ffffffffc020118c:	5e050513          	addi	a0,a0,1504 # ffffffffc0202768 <commands+0x628>
ffffffffc0201190:	a42ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc0201194:	00001697          	auipc	a3,0x1
ffffffffc0201198:	79468693          	addi	a3,a3,1940 # ffffffffc0202928 <commands+0x7e8>
ffffffffc020119c:	00001617          	auipc	a2,0x1
ffffffffc02011a0:	5b460613          	addi	a2,a2,1460 # ffffffffc0202750 <commands+0x610>
ffffffffc02011a4:	10e00593          	li	a1,270
ffffffffc02011a8:	00001517          	auipc	a0,0x1
ffffffffc02011ac:	5c050513          	addi	a0,a0,1472 # ffffffffc0202768 <commands+0x628>
ffffffffc02011b0:	a22ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011b4:	00001697          	auipc	a3,0x1
ffffffffc02011b8:	71468693          	addi	a3,a3,1812 # ffffffffc02028c8 <commands+0x788>
ffffffffc02011bc:	00001617          	auipc	a2,0x1
ffffffffc02011c0:	59460613          	addi	a2,a2,1428 # ffffffffc0202750 <commands+0x610>
ffffffffc02011c4:	10800593          	li	a1,264
ffffffffc02011c8:	00001517          	auipc	a0,0x1
ffffffffc02011cc:	5a050513          	addi	a0,a0,1440 # ffffffffc0202768 <commands+0x628>
ffffffffc02011d0:	a02ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02011d4:	00002697          	auipc	a3,0x2
ffffffffc02011d8:	81c68693          	addi	a3,a3,-2020 # ffffffffc02029f0 <commands+0x8b0>
ffffffffc02011dc:	00001617          	auipc	a2,0x1
ffffffffc02011e0:	57460613          	addi	a2,a2,1396 # ffffffffc0202750 <commands+0x610>
ffffffffc02011e4:	10700593          	li	a1,263
ffffffffc02011e8:	00001517          	auipc	a0,0x1
ffffffffc02011ec:	58050513          	addi	a0,a0,1408 # ffffffffc0202768 <commands+0x628>
ffffffffc02011f0:	9e2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc02011f4:	00001697          	auipc	a3,0x1
ffffffffc02011f8:	7ec68693          	addi	a3,a3,2028 # ffffffffc02029e0 <commands+0x8a0>
ffffffffc02011fc:	00001617          	auipc	a2,0x1
ffffffffc0201200:	55460613          	addi	a2,a2,1364 # ffffffffc0202750 <commands+0x610>
ffffffffc0201204:	0ff00593          	li	a1,255
ffffffffc0201208:	00001517          	auipc	a0,0x1
ffffffffc020120c:	56050513          	addi	a0,a0,1376 # ffffffffc0202768 <commands+0x628>
ffffffffc0201210:	9c2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_pages(2) != NULL);
ffffffffc0201214:	00001697          	auipc	a3,0x1
ffffffffc0201218:	7b468693          	addi	a3,a3,1972 # ffffffffc02029c8 <commands+0x888>
ffffffffc020121c:	00001617          	auipc	a2,0x1
ffffffffc0201220:	53460613          	addi	a2,a2,1332 # ffffffffc0202750 <commands+0x610>
ffffffffc0201224:	0fe00593          	li	a1,254
ffffffffc0201228:	00001517          	auipc	a0,0x1
ffffffffc020122c:	54050513          	addi	a0,a0,1344 # ffffffffc0202768 <commands+0x628>
ffffffffc0201230:	9a2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201234:	00001697          	auipc	a3,0x1
ffffffffc0201238:	77468693          	addi	a3,a3,1908 # ffffffffc02029a8 <commands+0x868>
ffffffffc020123c:	00001617          	auipc	a2,0x1
ffffffffc0201240:	51460613          	addi	a2,a2,1300 # ffffffffc0202750 <commands+0x610>
ffffffffc0201244:	0fd00593          	li	a1,253
ffffffffc0201248:	00001517          	auipc	a0,0x1
ffffffffc020124c:	52050513          	addi	a0,a0,1312 # ffffffffc0202768 <commands+0x628>
ffffffffc0201250:	982ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201254:	00001697          	auipc	a3,0x1
ffffffffc0201258:	72468693          	addi	a3,a3,1828 # ffffffffc0202978 <commands+0x838>
ffffffffc020125c:	00001617          	auipc	a2,0x1
ffffffffc0201260:	4f460613          	addi	a2,a2,1268 # ffffffffc0202750 <commands+0x610>
ffffffffc0201264:	0fb00593          	li	a1,251
ffffffffc0201268:	00001517          	auipc	a0,0x1
ffffffffc020126c:	50050513          	addi	a0,a0,1280 # ffffffffc0202768 <commands+0x628>
ffffffffc0201270:	962ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201274:	00001697          	auipc	a3,0x1
ffffffffc0201278:	6ec68693          	addi	a3,a3,1772 # ffffffffc0202960 <commands+0x820>
ffffffffc020127c:	00001617          	auipc	a2,0x1
ffffffffc0201280:	4d460613          	addi	a2,a2,1236 # ffffffffc0202750 <commands+0x610>
ffffffffc0201284:	0fa00593          	li	a1,250
ffffffffc0201288:	00001517          	auipc	a0,0x1
ffffffffc020128c:	4e050513          	addi	a0,a0,1248 # ffffffffc0202768 <commands+0x628>
ffffffffc0201290:	942ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201294:	00001697          	auipc	a3,0x1
ffffffffc0201298:	63468693          	addi	a3,a3,1588 # ffffffffc02028c8 <commands+0x788>
ffffffffc020129c:	00001617          	auipc	a2,0x1
ffffffffc02012a0:	4b460613          	addi	a2,a2,1204 # ffffffffc0202750 <commands+0x610>
ffffffffc02012a4:	0ee00593          	li	a1,238
ffffffffc02012a8:	00001517          	auipc	a0,0x1
ffffffffc02012ac:	4c050513          	addi	a0,a0,1216 # ffffffffc0202768 <commands+0x628>
ffffffffc02012b0:	922ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!PageProperty(p0));
ffffffffc02012b4:	00001697          	auipc	a3,0x1
ffffffffc02012b8:	69468693          	addi	a3,a3,1684 # ffffffffc0202948 <commands+0x808>
ffffffffc02012bc:	00001617          	auipc	a2,0x1
ffffffffc02012c0:	49460613          	addi	a2,a2,1172 # ffffffffc0202750 <commands+0x610>
ffffffffc02012c4:	0e500593          	li	a1,229
ffffffffc02012c8:	00001517          	auipc	a0,0x1
ffffffffc02012cc:	4a050513          	addi	a0,a0,1184 # ffffffffc0202768 <commands+0x628>
ffffffffc02012d0:	902ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != NULL);
ffffffffc02012d4:	00001697          	auipc	a3,0x1
ffffffffc02012d8:	66468693          	addi	a3,a3,1636 # ffffffffc0202938 <commands+0x7f8>
ffffffffc02012dc:	00001617          	auipc	a2,0x1
ffffffffc02012e0:	47460613          	addi	a2,a2,1140 # ffffffffc0202750 <commands+0x610>
ffffffffc02012e4:	0e400593          	li	a1,228
ffffffffc02012e8:	00001517          	auipc	a0,0x1
ffffffffc02012ec:	48050513          	addi	a0,a0,1152 # ffffffffc0202768 <commands+0x628>
ffffffffc02012f0:	8e2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc02012f4:	00001697          	auipc	a3,0x1
ffffffffc02012f8:	63468693          	addi	a3,a3,1588 # ffffffffc0202928 <commands+0x7e8>
ffffffffc02012fc:	00001617          	auipc	a2,0x1
ffffffffc0201300:	45460613          	addi	a2,a2,1108 # ffffffffc0202750 <commands+0x610>
ffffffffc0201304:	0c800593          	li	a1,200
ffffffffc0201308:	00001517          	auipc	a0,0x1
ffffffffc020130c:	46050513          	addi	a0,a0,1120 # ffffffffc0202768 <commands+0x628>
ffffffffc0201310:	8c2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201314:	00001697          	auipc	a3,0x1
ffffffffc0201318:	5b468693          	addi	a3,a3,1460 # ffffffffc02028c8 <commands+0x788>
ffffffffc020131c:	00001617          	auipc	a2,0x1
ffffffffc0201320:	43460613          	addi	a2,a2,1076 # ffffffffc0202750 <commands+0x610>
ffffffffc0201324:	0c600593          	li	a1,198
ffffffffc0201328:	00001517          	auipc	a0,0x1
ffffffffc020132c:	44050513          	addi	a0,a0,1088 # ffffffffc0202768 <commands+0x628>
ffffffffc0201330:	8a2ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201334:	00001697          	auipc	a3,0x1
ffffffffc0201338:	5d468693          	addi	a3,a3,1492 # ffffffffc0202908 <commands+0x7c8>
ffffffffc020133c:	00001617          	auipc	a2,0x1
ffffffffc0201340:	41460613          	addi	a2,a2,1044 # ffffffffc0202750 <commands+0x610>
ffffffffc0201344:	0c500593          	li	a1,197
ffffffffc0201348:	00001517          	auipc	a0,0x1
ffffffffc020134c:	42050513          	addi	a0,a0,1056 # ffffffffc0202768 <commands+0x628>
ffffffffc0201350:	882ff0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201354 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201354:	1141                	addi	sp,sp,-16
ffffffffc0201356:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201358:	10058863          	beqz	a1,ffffffffc0201468 <best_fit_free_pages+0x114>
    for (; p != base + n; p++) {
ffffffffc020135c:	00259693          	slli	a3,a1,0x2
ffffffffc0201360:	96ae                	add	a3,a3,a1
ffffffffc0201362:	068e                	slli	a3,a3,0x3
ffffffffc0201364:	96aa                	add	a3,a3,a0
ffffffffc0201366:	87aa                	mv	a5,a0
ffffffffc0201368:	02d50063          	beq	a0,a3,ffffffffc0201388 <best_fit_free_pages+0x34>
ffffffffc020136c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020136e:	8b05                	andi	a4,a4,1
ffffffffc0201370:	ef61                	bnez	a4,ffffffffc0201448 <best_fit_free_pages+0xf4>
ffffffffc0201372:	6798                	ld	a4,8(a5)
ffffffffc0201374:	8b09                	andi	a4,a4,2
ffffffffc0201376:	eb69                	bnez	a4,ffffffffc0201448 <best_fit_free_pages+0xf4>
        p->flags = 0;
ffffffffc0201378:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020137c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc0201380:	02878793          	addi	a5,a5,40
ffffffffc0201384:	fed794e3          	bne	a5,a3,ffffffffc020136c <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0201388:	2581                	sext.w	a1,a1
ffffffffc020138a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020138c:	00850313          	addi	t1,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201390:	4789                	li	a5,2
ffffffffc0201392:	40f3302f          	amoor.d	zero,a5,(t1)
    nr_free += n;
ffffffffc0201396:	00005717          	auipc	a4,0x5
ffffffffc020139a:	c9270713          	addi	a4,a4,-878 # ffffffffc0206028 <free_area>
ffffffffc020139e:	4b10                	lw	a2,16(a4)
    list_entry_t *le = &free_list;
ffffffffc02013a0:	86ba                	mv	a3,a4
ffffffffc02013a2:	87ba                	mv	a5,a4
    nr_free += n;
ffffffffc02013a4:	9db1                	addw	a1,a1,a2
ffffffffc02013a6:	cb0c                	sw	a1,16(a4)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02013a8:	a029                	j	ffffffffc02013b2 <best_fit_free_pages+0x5e>
        struct Page *page = le2page(le, page_link);
ffffffffc02013aa:	fe878713          	addi	a4,a5,-24
        if (base < page) {
ffffffffc02013ae:	00e56563          	bltu	a0,a4,ffffffffc02013b8 <best_fit_free_pages+0x64>
ffffffffc02013b2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02013b4:	fed79be3          	bne	a5,a3,ffffffffc02013aa <best_fit_free_pages+0x56>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02013b8:	6398                	ld	a4,0(a5)
    list_add_before(le, &(base->page_link));
ffffffffc02013ba:	01850613          	addi	a2,a0,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02013be:	e390                	sd	a2,0(a5)
ffffffffc02013c0:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02013c2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02013c4:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc02013c6:	02d70063          	beq	a4,a3,ffffffffc02013e6 <best_fit_free_pages+0x92>
        if (p + p->property == base) {
ffffffffc02013ca:	ff872883          	lw	a7,-8(a4)
        p = le2page(le, page_link);
ffffffffc02013ce:	fe870813          	addi	a6,a4,-24
        if (p + p->property == base) {
ffffffffc02013d2:	02089593          	slli	a1,a7,0x20
ffffffffc02013d6:	9181                	srli	a1,a1,0x20
ffffffffc02013d8:	00259613          	slli	a2,a1,0x2
ffffffffc02013dc:	962e                	add	a2,a2,a1
ffffffffc02013de:	060e                	slli	a2,a2,0x3
ffffffffc02013e0:	9642                	add	a2,a2,a6
ffffffffc02013e2:	04c50463          	beq	a0,a2,ffffffffc020142a <best_fit_free_pages+0xd6>
    if (le != &free_list) {
ffffffffc02013e6:	00d78f63          	beq	a5,a3,ffffffffc0201404 <best_fit_free_pages+0xb0>
        if (base + base->property == p) {
ffffffffc02013ea:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02013ec:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02013f0:	02059613          	slli	a2,a1,0x20
ffffffffc02013f4:	9201                	srli	a2,a2,0x20
ffffffffc02013f6:	00261713          	slli	a4,a2,0x2
ffffffffc02013fa:	9732                	add	a4,a4,a2
ffffffffc02013fc:	070e                	slli	a4,a4,0x3
ffffffffc02013fe:	972a                	add	a4,a4,a0
ffffffffc0201400:	00e68563          	beq	a3,a4,ffffffffc020140a <best_fit_free_pages+0xb6>
}
ffffffffc0201404:	60a2                	ld	ra,8(sp)
ffffffffc0201406:	0141                	addi	sp,sp,16
ffffffffc0201408:	8082                	ret
            base->property += p->property;
ffffffffc020140a:	ff87a703          	lw	a4,-8(a5)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020140e:	ff078693          	addi	a3,a5,-16
ffffffffc0201412:	9db9                	addw	a1,a1,a4
ffffffffc0201414:	c90c                	sw	a1,16(a0)
ffffffffc0201416:	5775                	li	a4,-3
ffffffffc0201418:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020141c:	6398                	ld	a4,0(a5)
ffffffffc020141e:	679c                	ld	a5,8(a5)
}
ffffffffc0201420:	60a2                	ld	ra,8(sp)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201422:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201424:	e398                	sd	a4,0(a5)
ffffffffc0201426:	0141                	addi	sp,sp,16
ffffffffc0201428:	8082                	ret
            p->property += base->property;
ffffffffc020142a:	491c                	lw	a5,16(a0)
ffffffffc020142c:	011788bb          	addw	a7,a5,a7
ffffffffc0201430:	ff172c23          	sw	a7,-8(a4)
ffffffffc0201434:	57f5                	li	a5,-3
ffffffffc0201436:	60f3302f          	amoand.d	zero,a5,(t1)
    __list_del(listelm->prev, listelm->next);
ffffffffc020143a:	6d0c                	ld	a1,24(a0)
ffffffffc020143c:	7110                	ld	a2,32(a0)
            base = p;
ffffffffc020143e:	8542                	mv	a0,a6
    prev->next = next;
ffffffffc0201440:	e590                	sd	a2,8(a1)
    return listelm->next;
ffffffffc0201442:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0201444:	e20c                	sd	a1,0(a2)
ffffffffc0201446:	b745                	j	ffffffffc02013e6 <best_fit_free_pages+0x92>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201448:	00001697          	auipc	a3,0x1
ffffffffc020144c:	5f068693          	addi	a3,a3,1520 # ffffffffc0202a38 <commands+0x8f8>
ffffffffc0201450:	00001617          	auipc	a2,0x1
ffffffffc0201454:	30060613          	addi	a2,a2,768 # ffffffffc0202750 <commands+0x610>
ffffffffc0201458:	06700593          	li	a1,103
ffffffffc020145c:	00001517          	auipc	a0,0x1
ffffffffc0201460:	30c50513          	addi	a0,a0,780 # ffffffffc0202768 <commands+0x628>
ffffffffc0201464:	f6ffe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc0201468:	00001697          	auipc	a3,0x1
ffffffffc020146c:	5c868693          	addi	a3,a3,1480 # ffffffffc0202a30 <commands+0x8f0>
ffffffffc0201470:	00001617          	auipc	a2,0x1
ffffffffc0201474:	2e060613          	addi	a2,a2,736 # ffffffffc0202750 <commands+0x610>
ffffffffc0201478:	06300593          	li	a1,99
ffffffffc020147c:	00001517          	auipc	a0,0x1
ffffffffc0201480:	2ec50513          	addi	a0,a0,748 # ffffffffc0202768 <commands+0x628>
ffffffffc0201484:	f4ffe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201488 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0201488:	c545                	beqz	a0,ffffffffc0201530 <best_fit_alloc_pages+0xa8>
    if (n > nr_free) {
ffffffffc020148a:	00005597          	auipc	a1,0x5
ffffffffc020148e:	b9e58593          	addi	a1,a1,-1122 # ffffffffc0206028 <free_area>
ffffffffc0201492:	0105a883          	lw	a7,16(a1)
ffffffffc0201496:	86aa                	mv	a3,a0
ffffffffc0201498:	02089793          	slli	a5,a7,0x20
ffffffffc020149c:	9381                	srli	a5,a5,0x20
ffffffffc020149e:	08a7e763          	bltu	a5,a0,ffffffffc020152c <best_fit_alloc_pages+0xa4>
    return listelm->next;
ffffffffc02014a2:	659c                	ld	a5,8(a1)
    struct Page *best = NULL;
ffffffffc02014a4:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc02014a6:	08b78263          	beq	a5,a1,ffffffffc020152a <best_fit_alloc_pages+0xa2>
        if (p->property >= n &&
ffffffffc02014aa:	ff87a703          	lw	a4,-8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02014ae:	fe878813          	addi	a6,a5,-24
        if (p->property >= n &&
ffffffffc02014b2:	02071613          	slli	a2,a4,0x20
ffffffffc02014b6:	9201                	srli	a2,a2,0x20
ffffffffc02014b8:	00d66763          	bltu	a2,a3,ffffffffc02014c6 <best_fit_alloc_pages+0x3e>
ffffffffc02014bc:	c501                	beqz	a0,ffffffffc02014c4 <best_fit_alloc_pages+0x3c>
            (best == NULL || p->property < best->property)) {
ffffffffc02014be:	4910                	lw	a2,16(a0)
ffffffffc02014c0:	00c77363          	bgeu	a4,a2,ffffffffc02014c6 <best_fit_alloc_pages+0x3e>
            best = p;
ffffffffc02014c4:	8542                	mv	a0,a6
ffffffffc02014c6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02014c8:	feb791e3          	bne	a5,a1,ffffffffc02014aa <best_fit_alloc_pages+0x22>
    if (best == NULL) {
ffffffffc02014cc:	cd39                	beqz	a0,ffffffffc020152a <best_fit_alloc_pages+0xa2>
    __list_del(listelm->prev, listelm->next);
ffffffffc02014ce:	711c                	ld	a5,32(a0)
    return listelm->prev;
ffffffffc02014d0:	6d18                	ld	a4,24(a0)
    size_t old_size = best->property;
ffffffffc02014d2:	4910                	lw	a2,16(a0)
        tail->property = old_size - n;
ffffffffc02014d4:	0006881b          	sext.w	a6,a3
    prev->next = next;
ffffffffc02014d8:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02014da:	e398                	sd	a4,0(a5)
    size_t old_size = best->property;
ffffffffc02014dc:	02061793          	slli	a5,a2,0x20
ffffffffc02014e0:	9381                	srli	a5,a5,0x20
    if (old_size > n) {
ffffffffc02014e2:	02f6f863          	bgeu	a3,a5,ffffffffc0201512 <best_fit_alloc_pages+0x8a>
        struct Page *tail = best + n;
ffffffffc02014e6:	00269793          	slli	a5,a3,0x2
ffffffffc02014ea:	97b6                	add	a5,a5,a3
ffffffffc02014ec:	078e                	slli	a5,a5,0x3
ffffffffc02014ee:	97aa                	add	a5,a5,a0
        tail->property = old_size - n;
ffffffffc02014f0:	4106063b          	subw	a2,a2,a6
ffffffffc02014f4:	cb90                	sw	a2,16(a5)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014f6:	4689                	li	a3,2
ffffffffc02014f8:	00878613          	addi	a2,a5,8
ffffffffc02014fc:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201500:	6714                	ld	a3,8(a4)
        list_add(prev, &(tail->page_link));
ffffffffc0201502:	01878613          	addi	a2,a5,24
    nr_free -= n;
ffffffffc0201506:	0105a883          	lw	a7,16(a1)
    prev->next = next->prev = elm;
ffffffffc020150a:	e290                	sd	a2,0(a3)
ffffffffc020150c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020150e:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0201510:	ef98                	sd	a4,24(a5)
ffffffffc0201512:	410888bb          	subw	a7,a7,a6
ffffffffc0201516:	0115a823          	sw	a7,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020151a:	57f5                	li	a5,-3
ffffffffc020151c:	00850713          	addi	a4,a0,8
ffffffffc0201520:	60f7302f          	amoand.d	zero,a5,(a4)
    best->property = 0;
ffffffffc0201524:	00052823          	sw	zero,16(a0)
    return best;
ffffffffc0201528:	8082                	ret
}
ffffffffc020152a:	8082                	ret
        return NULL;
ffffffffc020152c:	4501                	li	a0,0
ffffffffc020152e:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0201530:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0201532:	00001697          	auipc	a3,0x1
ffffffffc0201536:	4fe68693          	addi	a3,a3,1278 # ffffffffc0202a30 <commands+0x8f0>
ffffffffc020153a:	00001617          	auipc	a2,0x1
ffffffffc020153e:	21660613          	addi	a2,a2,534 # ffffffffc0202750 <commands+0x610>
ffffffffc0201542:	03700593          	li	a1,55
ffffffffc0201546:	00001517          	auipc	a0,0x1
ffffffffc020154a:	22250513          	addi	a0,a0,546 # ffffffffc0202768 <commands+0x628>
best_fit_alloc_pages(size_t n) {
ffffffffc020154e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201550:	e83fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201554 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0201554:	1141                	addi	sp,sp,-16
ffffffffc0201556:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201558:	c9c1                	beqz	a1,ffffffffc02015e8 <best_fit_init_memmap+0x94>
    for (; p != base + n; p++) {
ffffffffc020155a:	00259693          	slli	a3,a1,0x2
ffffffffc020155e:	96ae                	add	a3,a3,a1
ffffffffc0201560:	068e                	slli	a3,a3,0x3
ffffffffc0201562:	96aa                	add	a3,a3,a0
ffffffffc0201564:	87aa                	mv	a5,a0
ffffffffc0201566:	00a68f63          	beq	a3,a0,ffffffffc0201584 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020156a:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020156c:	8b05                	andi	a4,a4,1
ffffffffc020156e:	cf29                	beqz	a4,ffffffffc02015c8 <best_fit_init_memmap+0x74>
        p->flags = p->property = 0;
ffffffffc0201570:	0007a823          	sw	zero,16(a5)
ffffffffc0201574:	0007b423          	sd	zero,8(a5)
ffffffffc0201578:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++) {
ffffffffc020157c:	02878793          	addi	a5,a5,40
ffffffffc0201580:	fef695e3          	bne	a3,a5,ffffffffc020156a <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc0201584:	2581                	sext.w	a1,a1
ffffffffc0201586:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201588:	4789                	li	a5,2
ffffffffc020158a:	00850713          	addi	a4,a0,8
ffffffffc020158e:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201592:	00005717          	auipc	a4,0x5
ffffffffc0201596:	a9670713          	addi	a4,a4,-1386 # ffffffffc0206028 <free_area>
ffffffffc020159a:	4b10                	lw	a2,16(a4)
    list_entry_t *le = &free_list;
ffffffffc020159c:	86ba                	mv	a3,a4
ffffffffc020159e:	87ba                	mv	a5,a4
    nr_free += n;
ffffffffc02015a0:	9db1                	addw	a1,a1,a2
ffffffffc02015a2:	cb0c                	sw	a1,16(a4)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02015a4:	a029                	j	ffffffffc02015ae <best_fit_init_memmap+0x5a>
        struct Page *page = le2page(le, page_link);
ffffffffc02015a6:	fe878713          	addi	a4,a5,-24
        if (base < page) {
ffffffffc02015aa:	00e56563          	bltu	a0,a4,ffffffffc02015b4 <best_fit_init_memmap+0x60>
    return listelm->next;
ffffffffc02015ae:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02015b0:	fed79be3          	bne	a5,a3,ffffffffc02015a6 <best_fit_init_memmap+0x52>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02015b4:	6398                	ld	a4,0(a5)
    list_add_before(le, &(base->page_link));
ffffffffc02015b6:	01850693          	addi	a3,a0,24
    prev->next = next->prev = elm;
ffffffffc02015ba:	e394                	sd	a3,0(a5)
}
ffffffffc02015bc:	60a2                	ld	ra,8(sp)
ffffffffc02015be:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc02015c0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02015c2:	ed18                	sd	a4,24(a0)
ffffffffc02015c4:	0141                	addi	sp,sp,16
ffffffffc02015c6:	8082                	ret
        assert(PageReserved(p));
ffffffffc02015c8:	00001697          	auipc	a3,0x1
ffffffffc02015cc:	49868693          	addi	a3,a3,1176 # ffffffffc0202a60 <commands+0x920>
ffffffffc02015d0:	00001617          	auipc	a2,0x1
ffffffffc02015d4:	18060613          	addi	a2,a2,384 # ffffffffc0202750 <commands+0x610>
ffffffffc02015d8:	02900593          	li	a1,41
ffffffffc02015dc:	00001517          	auipc	a0,0x1
ffffffffc02015e0:	18c50513          	addi	a0,a0,396 # ffffffffc0202768 <commands+0x628>
ffffffffc02015e4:	deffe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc02015e8:	00001697          	auipc	a3,0x1
ffffffffc02015ec:	44868693          	addi	a3,a3,1096 # ffffffffc0202a30 <commands+0x8f0>
ffffffffc02015f0:	00001617          	auipc	a2,0x1
ffffffffc02015f4:	16060613          	addi	a2,a2,352 # ffffffffc0202750 <commands+0x610>
ffffffffc02015f8:	02500593          	li	a1,37
ffffffffc02015fc:	00001517          	auipc	a0,0x1
ffffffffc0201600:	16c50513          	addi	a0,a0,364 # ffffffffc0202768 <commands+0x628>
ffffffffc0201604:	dcffe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201608 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201608:	100027f3          	csrr	a5,sstatus
ffffffffc020160c:	8b89                	andi	a5,a5,2
ffffffffc020160e:	e799                	bnez	a5,ffffffffc020161c <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201610:	00005797          	auipc	a5,0x5
ffffffffc0201614:	e607b783          	ld	a5,-416(a5) # ffffffffc0206470 <pmm_manager>
ffffffffc0201618:	6f9c                	ld	a5,24(a5)
ffffffffc020161a:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020161c:	1141                	addi	sp,sp,-16
ffffffffc020161e:	e406                	sd	ra,8(sp)
ffffffffc0201620:	e022                	sd	s0,0(sp)
ffffffffc0201622:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201624:	a10ff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201628:	00005797          	auipc	a5,0x5
ffffffffc020162c:	e487b783          	ld	a5,-440(a5) # ffffffffc0206470 <pmm_manager>
ffffffffc0201630:	6f9c                	ld	a5,24(a5)
ffffffffc0201632:	8522                	mv	a0,s0
ffffffffc0201634:	9782                	jalr	a5
ffffffffc0201636:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201638:	9f6ff0ef          	jal	ra,ffffffffc020082e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc020163c:	60a2                	ld	ra,8(sp)
ffffffffc020163e:	8522                	mv	a0,s0
ffffffffc0201640:	6402                	ld	s0,0(sp)
ffffffffc0201642:	0141                	addi	sp,sp,16
ffffffffc0201644:	8082                	ret

ffffffffc0201646 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201646:	100027f3          	csrr	a5,sstatus
ffffffffc020164a:	8b89                	andi	a5,a5,2
ffffffffc020164c:	e799                	bnez	a5,ffffffffc020165a <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020164e:	00005797          	auipc	a5,0x5
ffffffffc0201652:	e227b783          	ld	a5,-478(a5) # ffffffffc0206470 <pmm_manager>
ffffffffc0201656:	739c                	ld	a5,32(a5)
ffffffffc0201658:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020165a:	1101                	addi	sp,sp,-32
ffffffffc020165c:	ec06                	sd	ra,24(sp)
ffffffffc020165e:	e822                	sd	s0,16(sp)
ffffffffc0201660:	e426                	sd	s1,8(sp)
ffffffffc0201662:	842a                	mv	s0,a0
ffffffffc0201664:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201666:	9ceff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020166a:	00005797          	auipc	a5,0x5
ffffffffc020166e:	e067b783          	ld	a5,-506(a5) # ffffffffc0206470 <pmm_manager>
ffffffffc0201672:	739c                	ld	a5,32(a5)
ffffffffc0201674:	85a6                	mv	a1,s1
ffffffffc0201676:	8522                	mv	a0,s0
ffffffffc0201678:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020167a:	6442                	ld	s0,16(sp)
ffffffffc020167c:	60e2                	ld	ra,24(sp)
ffffffffc020167e:	64a2                	ld	s1,8(sp)
ffffffffc0201680:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201682:	9acff06f          	j	ffffffffc020082e <intr_enable>

ffffffffc0201686 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201686:	100027f3          	csrr	a5,sstatus
ffffffffc020168a:	8b89                	andi	a5,a5,2
ffffffffc020168c:	e799                	bnez	a5,ffffffffc020169a <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020168e:	00005797          	auipc	a5,0x5
ffffffffc0201692:	de27b783          	ld	a5,-542(a5) # ffffffffc0206470 <pmm_manager>
ffffffffc0201696:	779c                	ld	a5,40(a5)
ffffffffc0201698:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc020169a:	1141                	addi	sp,sp,-16
ffffffffc020169c:	e406                	sd	ra,8(sp)
ffffffffc020169e:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02016a0:	994ff0ef          	jal	ra,ffffffffc0200834 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02016a4:	00005797          	auipc	a5,0x5
ffffffffc02016a8:	dcc7b783          	ld	a5,-564(a5) # ffffffffc0206470 <pmm_manager>
ffffffffc02016ac:	779c                	ld	a5,40(a5)
ffffffffc02016ae:	9782                	jalr	a5
ffffffffc02016b0:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02016b2:	97cff0ef          	jal	ra,ffffffffc020082e <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02016b6:	60a2                	ld	ra,8(sp)
ffffffffc02016b8:	8522                	mv	a0,s0
ffffffffc02016ba:	6402                	ld	s0,0(sp)
ffffffffc02016bc:	0141                	addi	sp,sp,16
ffffffffc02016be:	8082                	ret

ffffffffc02016c0 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02016c0:	00001797          	auipc	a5,0x1
ffffffffc02016c4:	3c878793          	addi	a5,a5,968 # ffffffffc0202a88 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02016c8:	638c                	ld	a1,0(a5)
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
            mem_end - mem_base, mem_base, mem_end - 1);
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02016ca:	7179                	addi	sp,sp,-48
ffffffffc02016cc:	f022                	sd	s0,32(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02016ce:	00001517          	auipc	a0,0x1
ffffffffc02016d2:	3f250513          	addi	a0,a0,1010 # ffffffffc0202ac0 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02016d6:	00005417          	auipc	s0,0x5
ffffffffc02016da:	d9a40413          	addi	s0,s0,-614 # ffffffffc0206470 <pmm_manager>
void pmm_init(void) {
ffffffffc02016de:	f406                	sd	ra,40(sp)
ffffffffc02016e0:	e44e                	sd	s3,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02016e2:	e01c                	sd	a5,0(s0)
void pmm_init(void) {
ffffffffc02016e4:	ec26                	sd	s1,24(sp)
ffffffffc02016e6:	e84a                	sd	s2,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02016e8:	9f1fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc02016ec:	601c                	ld	a5,0(s0)
ffffffffc02016ee:	679c                	ld	a5,8(a5)
ffffffffc02016f0:	9782                	jalr	a5
    uint64_t mem_base = get_memory_base();
ffffffffc02016f2:	928ff0ef          	jal	ra,ffffffffc020081a <get_memory_base>
ffffffffc02016f6:	89aa                	mv	s3,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02016f8:	92cff0ef          	jal	ra,ffffffffc0200824 <get_memory_size>
    if (mem_base == 0 || mem_size == 0 ||
ffffffffc02016fc:	800007b7          	lui	a5,0x80000
ffffffffc0201700:	97ce                	add	a5,a5,s3
ffffffffc0201702:	08000737          	lui	a4,0x8000
ffffffffc0201706:	18e7f163          	bgeu	a5,a4,ffffffffc0201888 <pmm_init+0x1c8>
ffffffffc020170a:	16050f63          	beqz	a0,ffffffffc0201888 <pmm_init+0x1c8>
    if (mem_size > PHYSICAL_MEMORY_END - mem_base) {
ffffffffc020170e:	44c5                	li	s1,17
ffffffffc0201710:	04ee                	slli	s1,s1,0x1b
ffffffffc0201712:	413487b3          	sub	a5,s1,s3
ffffffffc0201716:	12a7e463          	bltu	a5,a0,ffffffffc020183e <pmm_init+0x17e>
        mem_end = mem_base + mem_size;
ffffffffc020171a:	00a984b3          	add	s1,s3,a0
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020171e:	5775                	li	a4,-3
    npage = PPN(mem_end);
ffffffffc0201720:	00c4d793          	srli	a5,s1,0xc
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201724:	077a                	slli	a4,a4,0x1e
ffffffffc0201726:	00005917          	auipc	s2,0x5
ffffffffc020172a:	d6290913          	addi	s2,s2,-670 # ffffffffc0206488 <va_pa_offset>
    npage = PPN(mem_end);
ffffffffc020172e:	00005517          	auipc	a0,0x5
ffffffffc0201732:	d3250513          	addi	a0,a0,-718 # ffffffffc0206460 <npage>
    if (npage <= nbase) {
ffffffffc0201736:	000806b7          	lui	a3,0x80
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020173a:	00e93023          	sd	a4,0(s2)
    npage = PPN(mem_end);
ffffffffc020173e:	e11c                	sd	a5,0(a0)
    desc_count = npage - nbase;
ffffffffc0201740:	40d78733          	sub	a4,a5,a3
    if (npage <= nbase) {
ffffffffc0201744:	18d78663          	beq	a5,a3,ffffffffc02018d0 <pmm_init+0x210>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0201748:	00006797          	auipc	a5,0x6
ffffffffc020174c:	d4f78793          	addi	a5,a5,-689 # ffffffffc0207497 <end+0xfff>
ffffffffc0201750:	76fd                	lui	a3,0xfffff
ffffffffc0201752:	8ff5                	and	a5,a5,a3
ffffffffc0201754:	00005897          	auipc	a7,0x5
ffffffffc0201758:	d1488893          	addi	a7,a7,-748 # ffffffffc0206468 <pages>
ffffffffc020175c:	00f8b023          	sd	a5,0(a7)
    pages_pa = PADDR((uintptr_t)pages);
ffffffffc0201760:	c0200637          	lui	a2,0xc0200
ffffffffc0201764:	18c7e263          	bltu	a5,a2,ffffffffc02018e8 <pmm_init+0x228>
    pages_end_pa = PADDR((uintptr_t)pages + desc_count * sizeof(struct Page));
ffffffffc0201768:	00271813          	slli	a6,a4,0x2
ffffffffc020176c:	983a                	add	a6,a6,a4
ffffffffc020176e:	080e                	slli	a6,a6,0x3
    pages_pa = PADDR((uintptr_t)pages);
ffffffffc0201770:	470d                	li	a4,3
ffffffffc0201772:	077a                	slli	a4,a4,0x1e
    pages_end_pa = PADDR((uintptr_t)pages + desc_count * sizeof(struct Page));
ffffffffc0201774:	010786b3          	add	a3,a5,a6
    pages_pa = PADDR((uintptr_t)pages);
ffffffffc0201778:	00e785b3          	add	a1,a5,a4
    pages_end_pa = PADDR((uintptr_t)pages + desc_count * sizeof(struct Page));
ffffffffc020177c:	12c6ee63          	bltu	a3,a2,ffffffffc02018b8 <pmm_init+0x1f8>
ffffffffc0201780:	9736                	add	a4,a4,a3
    if (pages_pa >= mem_end || pages_end_pa > mem_end) {
ffffffffc0201782:	1095ff63          	bgeu	a1,s1,ffffffffc02018a0 <pmm_init+0x1e0>
ffffffffc0201786:	10e4ed63          	bltu	s1,a4,ffffffffc02018a0 <pmm_init+0x1e0>
ffffffffc020178a:	4305                	li	t1,1
    for (p = pages; p < pages + desc_count; p++) {
ffffffffc020178c:	873e                	mv	a4,a5
ffffffffc020178e:	02d7f463          	bgeu	a5,a3,ffffffffc02017b6 <pmm_init+0xf6>
        p->flags = 0;
ffffffffc0201792:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0201796:	0007a823          	sw	zero,16(a5)
ffffffffc020179a:	0007a023          	sw	zero,0(a5)
ffffffffc020179e:	00878713          	addi	a4,a5,8
ffffffffc02017a2:	4067302f          	amoor.d	zero,t1,(a4)
    for (p = pages; p < pages + desc_count; p++) {
ffffffffc02017a6:	0008b703          	ld	a4,0(a7)
ffffffffc02017aa:	02878793          	addi	a5,a5,40
ffffffffc02017ae:	010705b3          	add	a1,a4,a6
ffffffffc02017b2:	feb7e0e3          	bltu	a5,a1,ffffffffc0201792 <pmm_init+0xd2>
    free_start_pa = ROUNDUP(pages_end_pa, PGSIZE);
ffffffffc02017b6:	00001617          	auipc	a2,0x1
ffffffffc02017ba:	6ea63603          	ld	a2,1770(a2) # ffffffffc0202ea0 <error_string+0x40>
ffffffffc02017be:	77fd                	lui	a5,0xfffff
ffffffffc02017c0:	96b2                	add	a3,a3,a2
ffffffffc02017c2:	8efd                	and	a3,a3,a5
    free_end_pa = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02017c4:	8fe5                	and	a5,a5,s1
    if (free_start_pa < free_end_pa) {
ffffffffc02017c6:	08f6ed63          	bltu	a3,a5,ffffffffc0201860 <pmm_init+0x1a0>
    cprintf("physical memory map:\n");
ffffffffc02017ca:	00001517          	auipc	a0,0x1
ffffffffc02017ce:	3de50513          	addi	a0,a0,990 # ffffffffc0202ba8 <best_fit_pmm_manager+0x120>
ffffffffc02017d2:	907fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
ffffffffc02017d6:	413485b3          	sub	a1,s1,s3
ffffffffc02017da:	fff48693          	addi	a3,s1,-1
ffffffffc02017de:	864e                	mv	a2,s3
ffffffffc02017e0:	00001517          	auipc	a0,0x1
ffffffffc02017e4:	3e050513          	addi	a0,a0,992 # ffffffffc0202bc0 <best_fit_pmm_manager+0x138>
ffffffffc02017e8:	8f1fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02017ec:	601c                	ld	a5,0(s0)
ffffffffc02017ee:	7b9c                	ld	a5,48(a5)
ffffffffc02017f0:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02017f2:	00001517          	auipc	a0,0x1
ffffffffc02017f6:	3fe50513          	addi	a0,a0,1022 # ffffffffc0202bf0 <best_fit_pmm_manager+0x168>
ffffffffc02017fa:	8dffe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02017fe:	00004597          	auipc	a1,0x4
ffffffffc0201802:	80258593          	addi	a1,a1,-2046 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201806:	00005797          	auipc	a5,0x5
ffffffffc020180a:	c6b7bd23          	sd	a1,-902(a5) # ffffffffc0206480 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020180e:	c02007b7          	lui	a5,0xc0200
ffffffffc0201812:	0ef5e863          	bltu	a1,a5,ffffffffc0201902 <pmm_init+0x242>
ffffffffc0201816:	00093603          	ld	a2,0(s2)
}
ffffffffc020181a:	7402                	ld	s0,32(sp)
ffffffffc020181c:	70a2                	ld	ra,40(sp)
ffffffffc020181e:	64e2                	ld	s1,24(sp)
ffffffffc0201820:	6942                	ld	s2,16(sp)
ffffffffc0201822:	69a2                	ld	s3,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201824:	40c58633          	sub	a2,a1,a2
ffffffffc0201828:	00005797          	auipc	a5,0x5
ffffffffc020182c:	c4c7b823          	sd	a2,-944(a5) # ffffffffc0206478 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201830:	00001517          	auipc	a0,0x1
ffffffffc0201834:	3e050513          	addi	a0,a0,992 # ffffffffc0202c10 <best_fit_pmm_manager+0x188>
}
ffffffffc0201838:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020183a:	89ffe06f          	j	ffffffffc02000d8 <cprintf>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020183e:	57f5                	li	a5,-3
ffffffffc0201840:	07fa                	slli	a5,a5,0x1e
ffffffffc0201842:	00005917          	auipc	s2,0x5
ffffffffc0201846:	c4690913          	addi	s2,s2,-954 # ffffffffc0206488 <va_pa_offset>
    npage = PPN(mem_end);
ffffffffc020184a:	00005517          	auipc	a0,0x5
ffffffffc020184e:	c1650513          	addi	a0,a0,-1002 # ffffffffc0206460 <npage>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201852:	00f93023          	sd	a5,0(s2)
    npage = PPN(mem_end);
ffffffffc0201856:	000887b7          	lui	a5,0x88
ffffffffc020185a:	e11c                	sd	a5,0(a0)
ffffffffc020185c:	6721                	lui	a4,0x8
ffffffffc020185e:	b5ed                	j	ffffffffc0201748 <pmm_init+0x88>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201860:	6110                	ld	a2,0(a0)
        free_pages = (free_end_pa - free_start_pa) / PGSIZE;
ffffffffc0201862:	8f95                	sub	a5,a5,a3
ffffffffc0201864:	82b1                	srli	a3,a3,0xc
ffffffffc0201866:	00c7d593          	srli	a1,a5,0xc
ffffffffc020186a:	0ac6f963          	bgeu	a3,a2,ffffffffc020191c <pmm_init+0x25c>
    pmm_manager->init_memmap(base, n);
ffffffffc020186e:	601c                	ld	a5,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201870:	fff80637          	lui	a2,0xfff80
ffffffffc0201874:	96b2                	add	a3,a3,a2
ffffffffc0201876:	00269513          	slli	a0,a3,0x2
ffffffffc020187a:	96aa                	add	a3,a3,a0
ffffffffc020187c:	6b9c                	ld	a5,16(a5)
ffffffffc020187e:	00369513          	slli	a0,a3,0x3
ffffffffc0201882:	953a                	add	a0,a0,a4
ffffffffc0201884:	9782                	jalr	a5
}
ffffffffc0201886:	b791                	j	ffffffffc02017ca <pmm_init+0x10a>
        panic("page_init: invalid memory range");
ffffffffc0201888:	00001617          	auipc	a2,0x1
ffffffffc020188c:	25060613          	addi	a2,a2,592 # ffffffffc0202ad8 <best_fit_pmm_manager+0x50>
ffffffffc0201890:	06700593          	li	a1,103
ffffffffc0201894:	00001517          	auipc	a0,0x1
ffffffffc0201898:	26450513          	addi	a0,a0,612 # ffffffffc0202af8 <best_fit_pmm_manager+0x70>
ffffffffc020189c:	b37fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
        panic("page_init: page descriptors do not fit");
ffffffffc02018a0:	00001617          	auipc	a2,0x1
ffffffffc02018a4:	2b060613          	addi	a2,a2,688 # ffffffffc0202b50 <best_fit_pmm_manager+0xc8>
ffffffffc02018a8:	08000593          	li	a1,128
ffffffffc02018ac:	00001517          	auipc	a0,0x1
ffffffffc02018b0:	24c50513          	addi	a0,a0,588 # ffffffffc0202af8 <best_fit_pmm_manager+0x70>
ffffffffc02018b4:	b1ffe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    pages_end_pa = PADDR((uintptr_t)pages + desc_count * sizeof(struct Page));
ffffffffc02018b8:	00001617          	auipc	a2,0x1
ffffffffc02018bc:	27060613          	addi	a2,a2,624 # ffffffffc0202b28 <best_fit_pmm_manager+0xa0>
ffffffffc02018c0:	07d00593          	li	a1,125
ffffffffc02018c4:	00001517          	auipc	a0,0x1
ffffffffc02018c8:	23450513          	addi	a0,a0,564 # ffffffffc0202af8 <best_fit_pmm_manager+0x70>
ffffffffc02018cc:	b07fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
        panic("page_init: invalid page range");
ffffffffc02018d0:	00001617          	auipc	a2,0x1
ffffffffc02018d4:	23860613          	addi	a2,a2,568 # ffffffffc0202b08 <best_fit_pmm_manager+0x80>
ffffffffc02018d8:	07500593          	li	a1,117
ffffffffc02018dc:	00001517          	auipc	a0,0x1
ffffffffc02018e0:	21c50513          	addi	a0,a0,540 # ffffffffc0202af8 <best_fit_pmm_manager+0x70>
ffffffffc02018e4:	aeffe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    pages_pa = PADDR((uintptr_t)pages);
ffffffffc02018e8:	86be                	mv	a3,a5
ffffffffc02018ea:	00001617          	auipc	a2,0x1
ffffffffc02018ee:	23e60613          	addi	a2,a2,574 # ffffffffc0202b28 <best_fit_pmm_manager+0xa0>
ffffffffc02018f2:	07c00593          	li	a1,124
ffffffffc02018f6:	00001517          	auipc	a0,0x1
ffffffffc02018fa:	20250513          	addi	a0,a0,514 # ffffffffc0202af8 <best_fit_pmm_manager+0x70>
ffffffffc02018fe:	ad5fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201902:	86ae                	mv	a3,a1
ffffffffc0201904:	00001617          	auipc	a2,0x1
ffffffffc0201908:	22460613          	addi	a2,a2,548 # ffffffffc0202b28 <best_fit_pmm_manager+0xa0>
ffffffffc020190c:	0ac00593          	li	a1,172
ffffffffc0201910:	00001517          	auipc	a0,0x1
ffffffffc0201914:	1e850513          	addi	a0,a0,488 # ffffffffc0202af8 <best_fit_pmm_manager+0x70>
ffffffffc0201918:	abbfe0ef          	jal	ra,ffffffffc02003d2 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020191c:	00001617          	auipc	a2,0x1
ffffffffc0201920:	25c60613          	addi	a2,a2,604 # ffffffffc0202b78 <best_fit_pmm_manager+0xf0>
ffffffffc0201924:	06b00593          	li	a1,107
ffffffffc0201928:	00001517          	auipc	a0,0x1
ffffffffc020192c:	27050513          	addi	a0,a0,624 # ffffffffc0202b98 <best_fit_pmm_manager+0x110>
ffffffffc0201930:	aa3fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201934 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201934:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201938:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020193a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020193e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201940:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201944:	f022                	sd	s0,32(sp)
ffffffffc0201946:	ec26                	sd	s1,24(sp)
ffffffffc0201948:	e84a                	sd	s2,16(sp)
ffffffffc020194a:	f406                	sd	ra,40(sp)
ffffffffc020194c:	e44e                	sd	s3,8(sp)
ffffffffc020194e:	84aa                	mv	s1,a0
ffffffffc0201950:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201952:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201956:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201958:	03067e63          	bgeu	a2,a6,ffffffffc0201994 <printnum+0x60>
ffffffffc020195c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020195e:	00805763          	blez	s0,ffffffffc020196c <printnum+0x38>
ffffffffc0201962:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201964:	85ca                	mv	a1,s2
ffffffffc0201966:	854e                	mv	a0,s3
ffffffffc0201968:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020196a:	fc65                	bnez	s0,ffffffffc0201962 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020196c:	1a02                	slli	s4,s4,0x20
ffffffffc020196e:	00001797          	auipc	a5,0x1
ffffffffc0201972:	2e278793          	addi	a5,a5,738 # ffffffffc0202c50 <best_fit_pmm_manager+0x1c8>
ffffffffc0201976:	020a5a13          	srli	s4,s4,0x20
ffffffffc020197a:	9a3e                	add	s4,s4,a5
}
ffffffffc020197c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020197e:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201982:	70a2                	ld	ra,40(sp)
ffffffffc0201984:	69a2                	ld	s3,8(sp)
ffffffffc0201986:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201988:	85ca                	mv	a1,s2
ffffffffc020198a:	87a6                	mv	a5,s1
}
ffffffffc020198c:	6942                	ld	s2,16(sp)
ffffffffc020198e:	64e2                	ld	s1,24(sp)
ffffffffc0201990:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201992:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201994:	03065633          	divu	a2,a2,a6
ffffffffc0201998:	8722                	mv	a4,s0
ffffffffc020199a:	f9bff0ef          	jal	ra,ffffffffc0201934 <printnum>
ffffffffc020199e:	b7f9                	j	ffffffffc020196c <printnum+0x38>

ffffffffc02019a0 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02019a0:	7119                	addi	sp,sp,-128
ffffffffc02019a2:	f4a6                	sd	s1,104(sp)
ffffffffc02019a4:	f0ca                	sd	s2,96(sp)
ffffffffc02019a6:	ecce                	sd	s3,88(sp)
ffffffffc02019a8:	e8d2                	sd	s4,80(sp)
ffffffffc02019aa:	e4d6                	sd	s5,72(sp)
ffffffffc02019ac:	e0da                	sd	s6,64(sp)
ffffffffc02019ae:	fc5e                	sd	s7,56(sp)
ffffffffc02019b0:	f06a                	sd	s10,32(sp)
ffffffffc02019b2:	fc86                	sd	ra,120(sp)
ffffffffc02019b4:	f8a2                	sd	s0,112(sp)
ffffffffc02019b6:	f862                	sd	s8,48(sp)
ffffffffc02019b8:	f466                	sd	s9,40(sp)
ffffffffc02019ba:	ec6e                	sd	s11,24(sp)
ffffffffc02019bc:	892a                	mv	s2,a0
ffffffffc02019be:	84ae                	mv	s1,a1
ffffffffc02019c0:	8d32                	mv	s10,a2
ffffffffc02019c2:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019c4:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02019c8:	5b7d                	li	s6,-1
ffffffffc02019ca:	00001a97          	auipc	s5,0x1
ffffffffc02019ce:	2baa8a93          	addi	s5,s5,698 # ffffffffc0202c84 <best_fit_pmm_manager+0x1fc>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02019d2:	00001b97          	auipc	s7,0x1
ffffffffc02019d6:	48eb8b93          	addi	s7,s7,1166 # ffffffffc0202e60 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019da:	000d4503          	lbu	a0,0(s10)
ffffffffc02019de:	001d0413          	addi	s0,s10,1
ffffffffc02019e2:	01350a63          	beq	a0,s3,ffffffffc02019f6 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02019e6:	c121                	beqz	a0,ffffffffc0201a26 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02019e8:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019ea:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02019ec:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02019ee:	fff44503          	lbu	a0,-1(s0)
ffffffffc02019f2:	ff351ae3          	bne	a0,s3,ffffffffc02019e6 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02019f6:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02019fa:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02019fe:	4c81                	li	s9,0
ffffffffc0201a00:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201a02:	5c7d                	li	s8,-1
ffffffffc0201a04:	5dfd                	li	s11,-1
ffffffffc0201a06:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a0a:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a0c:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a10:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a14:	00140d13          	addi	s10,s0,1
ffffffffc0201a18:	04b56263          	bltu	a0,a1,ffffffffc0201a5c <vprintfmt+0xbc>
ffffffffc0201a1c:	058a                	slli	a1,a1,0x2
ffffffffc0201a1e:	95d6                	add	a1,a1,s5
ffffffffc0201a20:	4194                	lw	a3,0(a1)
ffffffffc0201a22:	96d6                	add	a3,a3,s5
ffffffffc0201a24:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a26:	70e6                	ld	ra,120(sp)
ffffffffc0201a28:	7446                	ld	s0,112(sp)
ffffffffc0201a2a:	74a6                	ld	s1,104(sp)
ffffffffc0201a2c:	7906                	ld	s2,96(sp)
ffffffffc0201a2e:	69e6                	ld	s3,88(sp)
ffffffffc0201a30:	6a46                	ld	s4,80(sp)
ffffffffc0201a32:	6aa6                	ld	s5,72(sp)
ffffffffc0201a34:	6b06                	ld	s6,64(sp)
ffffffffc0201a36:	7be2                	ld	s7,56(sp)
ffffffffc0201a38:	7c42                	ld	s8,48(sp)
ffffffffc0201a3a:	7ca2                	ld	s9,40(sp)
ffffffffc0201a3c:	7d02                	ld	s10,32(sp)
ffffffffc0201a3e:	6de2                	ld	s11,24(sp)
ffffffffc0201a40:	6109                	addi	sp,sp,128
ffffffffc0201a42:	8082                	ret
            padc = '0';
ffffffffc0201a44:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201a46:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a4a:	846a                	mv	s0,s10
ffffffffc0201a4c:	00140d13          	addi	s10,s0,1
ffffffffc0201a50:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201a54:	0ff5f593          	zext.b	a1,a1
ffffffffc0201a58:	fcb572e3          	bgeu	a0,a1,ffffffffc0201a1c <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201a5c:	85a6                	mv	a1,s1
ffffffffc0201a5e:	02500513          	li	a0,37
ffffffffc0201a62:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201a64:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201a68:	8d22                	mv	s10,s0
ffffffffc0201a6a:	f73788e3          	beq	a5,s3,ffffffffc02019da <vprintfmt+0x3a>
ffffffffc0201a6e:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201a72:	1d7d                	addi	s10,s10,-1
ffffffffc0201a74:	ff379de3          	bne	a5,s3,ffffffffc0201a6e <vprintfmt+0xce>
ffffffffc0201a78:	b78d                	j	ffffffffc02019da <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201a7a:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201a7e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a82:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201a84:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201a88:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201a8c:	02d86463          	bltu	a6,a3,ffffffffc0201ab4 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201a90:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201a94:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201a98:	0186873b          	addw	a4,a3,s8
ffffffffc0201a9c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201aa0:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201aa2:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201aa6:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201aa8:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201aac:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201ab0:	fed870e3          	bgeu	a6,a3,ffffffffc0201a90 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201ab4:	f40ddce3          	bgez	s11,ffffffffc0201a0c <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201ab8:	8de2                	mv	s11,s8
ffffffffc0201aba:	5c7d                	li	s8,-1
ffffffffc0201abc:	bf81                	j	ffffffffc0201a0c <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201abe:	fffdc693          	not	a3,s11
ffffffffc0201ac2:	96fd                	srai	a3,a3,0x3f
ffffffffc0201ac4:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ac8:	00144603          	lbu	a2,1(s0)
ffffffffc0201acc:	2d81                	sext.w	s11,s11
ffffffffc0201ace:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201ad0:	bf35                	j	ffffffffc0201a0c <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201ad2:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ad6:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201ada:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201adc:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201ade:	bfd9                	j	ffffffffc0201ab4 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201ae0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201ae2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201ae6:	01174463          	blt	a4,a7,ffffffffc0201aee <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201aea:	1a088e63          	beqz	a7,ffffffffc0201ca6 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201aee:	000a3603          	ld	a2,0(s4)
ffffffffc0201af2:	46c1                	li	a3,16
ffffffffc0201af4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201af6:	2781                	sext.w	a5,a5
ffffffffc0201af8:	876e                	mv	a4,s11
ffffffffc0201afa:	85a6                	mv	a1,s1
ffffffffc0201afc:	854a                	mv	a0,s2
ffffffffc0201afe:	e37ff0ef          	jal	ra,ffffffffc0201934 <printnum>
            break;
ffffffffc0201b02:	bde1                	j	ffffffffc02019da <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b04:	000a2503          	lw	a0,0(s4)
ffffffffc0201b08:	85a6                	mv	a1,s1
ffffffffc0201b0a:	0a21                	addi	s4,s4,8
ffffffffc0201b0c:	9902                	jalr	s2
            break;
ffffffffc0201b0e:	b5f1                	j	ffffffffc02019da <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b10:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b12:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b16:	01174463          	blt	a4,a7,ffffffffc0201b1e <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201b1a:	18088163          	beqz	a7,ffffffffc0201c9c <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201b1e:	000a3603          	ld	a2,0(s4)
ffffffffc0201b22:	46a9                	li	a3,10
ffffffffc0201b24:	8a2e                	mv	s4,a1
ffffffffc0201b26:	bfc1                	j	ffffffffc0201af6 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b28:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201b2c:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b2e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b30:	bdf1                	j	ffffffffc0201a0c <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201b32:	85a6                	mv	a1,s1
ffffffffc0201b34:	02500513          	li	a0,37
ffffffffc0201b38:	9902                	jalr	s2
            break;
ffffffffc0201b3a:	b545                	j	ffffffffc02019da <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b3c:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201b40:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b42:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201b44:	b5e1                	j	ffffffffc0201a0c <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201b46:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201b48:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201b4c:	01174463          	blt	a4,a7,ffffffffc0201b54 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201b50:	14088163          	beqz	a7,ffffffffc0201c92 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201b54:	000a3603          	ld	a2,0(s4)
ffffffffc0201b58:	46a1                	li	a3,8
ffffffffc0201b5a:	8a2e                	mv	s4,a1
ffffffffc0201b5c:	bf69                	j	ffffffffc0201af6 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201b5e:	03000513          	li	a0,48
ffffffffc0201b62:	85a6                	mv	a1,s1
ffffffffc0201b64:	e03e                	sd	a5,0(sp)
ffffffffc0201b66:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201b68:	85a6                	mv	a1,s1
ffffffffc0201b6a:	07800513          	li	a0,120
ffffffffc0201b6e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b70:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201b72:	6782                	ld	a5,0(sp)
ffffffffc0201b74:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201b76:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201b7a:	bfb5                	j	ffffffffc0201af6 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201b7c:	000a3403          	ld	s0,0(s4)
ffffffffc0201b80:	008a0713          	addi	a4,s4,8
ffffffffc0201b84:	e03a                	sd	a4,0(sp)
ffffffffc0201b86:	14040263          	beqz	s0,ffffffffc0201cca <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201b8a:	0fb05763          	blez	s11,ffffffffc0201c78 <vprintfmt+0x2d8>
ffffffffc0201b8e:	02d00693          	li	a3,45
ffffffffc0201b92:	0cd79163          	bne	a5,a3,ffffffffc0201c54 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201b96:	00044783          	lbu	a5,0(s0)
ffffffffc0201b9a:	0007851b          	sext.w	a0,a5
ffffffffc0201b9e:	cf85                	beqz	a5,ffffffffc0201bd6 <vprintfmt+0x236>
ffffffffc0201ba0:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201ba4:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201ba8:	000c4563          	bltz	s8,ffffffffc0201bb2 <vprintfmt+0x212>
ffffffffc0201bac:	3c7d                	addiw	s8,s8,-1
ffffffffc0201bae:	036c0263          	beq	s8,s6,ffffffffc0201bd2 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201bb2:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bb4:	0e0c8e63          	beqz	s9,ffffffffc0201cb0 <vprintfmt+0x310>
ffffffffc0201bb8:	3781                	addiw	a5,a5,-32
ffffffffc0201bba:	0ef47b63          	bgeu	s0,a5,ffffffffc0201cb0 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201bbe:	03f00513          	li	a0,63
ffffffffc0201bc2:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bc4:	000a4783          	lbu	a5,0(s4)
ffffffffc0201bc8:	3dfd                	addiw	s11,s11,-1
ffffffffc0201bca:	0a05                	addi	s4,s4,1
ffffffffc0201bcc:	0007851b          	sext.w	a0,a5
ffffffffc0201bd0:	ffe1                	bnez	a5,ffffffffc0201ba8 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201bd2:	01b05963          	blez	s11,ffffffffc0201be4 <vprintfmt+0x244>
ffffffffc0201bd6:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201bd8:	85a6                	mv	a1,s1
ffffffffc0201bda:	02000513          	li	a0,32
ffffffffc0201bde:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201be0:	fe0d9be3          	bnez	s11,ffffffffc0201bd6 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201be4:	6a02                	ld	s4,0(sp)
ffffffffc0201be6:	bbd5                	j	ffffffffc02019da <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201be8:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201bea:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201bee:	01174463          	blt	a4,a7,ffffffffc0201bf6 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201bf2:	08088d63          	beqz	a7,ffffffffc0201c8c <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201bf6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201bfa:	0a044d63          	bltz	s0,ffffffffc0201cb4 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201bfe:	8622                	mv	a2,s0
ffffffffc0201c00:	8a66                	mv	s4,s9
ffffffffc0201c02:	46a9                	li	a3,10
ffffffffc0201c04:	bdcd                	j	ffffffffc0201af6 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201c06:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c0a:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201c0c:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201c0e:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201c12:	8fb5                	xor	a5,a5,a3
ffffffffc0201c14:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201c18:	02d74163          	blt	a4,a3,ffffffffc0201c3a <vprintfmt+0x29a>
ffffffffc0201c1c:	00369793          	slli	a5,a3,0x3
ffffffffc0201c20:	97de                	add	a5,a5,s7
ffffffffc0201c22:	639c                	ld	a5,0(a5)
ffffffffc0201c24:	cb99                	beqz	a5,ffffffffc0201c3a <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201c26:	86be                	mv	a3,a5
ffffffffc0201c28:	00001617          	auipc	a2,0x1
ffffffffc0201c2c:	05860613          	addi	a2,a2,88 # ffffffffc0202c80 <best_fit_pmm_manager+0x1f8>
ffffffffc0201c30:	85a6                	mv	a1,s1
ffffffffc0201c32:	854a                	mv	a0,s2
ffffffffc0201c34:	0ce000ef          	jal	ra,ffffffffc0201d02 <printfmt>
ffffffffc0201c38:	b34d                	j	ffffffffc02019da <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201c3a:	00001617          	auipc	a2,0x1
ffffffffc0201c3e:	03660613          	addi	a2,a2,54 # ffffffffc0202c70 <best_fit_pmm_manager+0x1e8>
ffffffffc0201c42:	85a6                	mv	a1,s1
ffffffffc0201c44:	854a                	mv	a0,s2
ffffffffc0201c46:	0bc000ef          	jal	ra,ffffffffc0201d02 <printfmt>
ffffffffc0201c4a:	bb41                	j	ffffffffc02019da <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201c4c:	00001417          	auipc	s0,0x1
ffffffffc0201c50:	01c40413          	addi	s0,s0,28 # ffffffffc0202c68 <best_fit_pmm_manager+0x1e0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c54:	85e2                	mv	a1,s8
ffffffffc0201c56:	8522                	mv	a0,s0
ffffffffc0201c58:	e43e                	sd	a5,8(sp)
ffffffffc0201c5a:	200000ef          	jal	ra,ffffffffc0201e5a <strnlen>
ffffffffc0201c5e:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201c62:	01b05b63          	blez	s11,ffffffffc0201c78 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201c66:	67a2                	ld	a5,8(sp)
ffffffffc0201c68:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c6c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201c6e:	85a6                	mv	a1,s1
ffffffffc0201c70:	8552                	mv	a0,s4
ffffffffc0201c72:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201c74:	fe0d9ce3          	bnez	s11,ffffffffc0201c6c <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201c78:	00044783          	lbu	a5,0(s0)
ffffffffc0201c7c:	00140a13          	addi	s4,s0,1
ffffffffc0201c80:	0007851b          	sext.w	a0,a5
ffffffffc0201c84:	d3a5                	beqz	a5,ffffffffc0201be4 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201c86:	05e00413          	li	s0,94
ffffffffc0201c8a:	bf39                	j	ffffffffc0201ba8 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201c8c:	000a2403          	lw	s0,0(s4)
ffffffffc0201c90:	b7ad                	j	ffffffffc0201bfa <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201c92:	000a6603          	lwu	a2,0(s4)
ffffffffc0201c96:	46a1                	li	a3,8
ffffffffc0201c98:	8a2e                	mv	s4,a1
ffffffffc0201c9a:	bdb1                	j	ffffffffc0201af6 <vprintfmt+0x156>
ffffffffc0201c9c:	000a6603          	lwu	a2,0(s4)
ffffffffc0201ca0:	46a9                	li	a3,10
ffffffffc0201ca2:	8a2e                	mv	s4,a1
ffffffffc0201ca4:	bd89                	j	ffffffffc0201af6 <vprintfmt+0x156>
ffffffffc0201ca6:	000a6603          	lwu	a2,0(s4)
ffffffffc0201caa:	46c1                	li	a3,16
ffffffffc0201cac:	8a2e                	mv	s4,a1
ffffffffc0201cae:	b5a1                	j	ffffffffc0201af6 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201cb0:	9902                	jalr	s2
ffffffffc0201cb2:	bf09                	j	ffffffffc0201bc4 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201cb4:	85a6                	mv	a1,s1
ffffffffc0201cb6:	02d00513          	li	a0,45
ffffffffc0201cba:	e03e                	sd	a5,0(sp)
ffffffffc0201cbc:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201cbe:	6782                	ld	a5,0(sp)
ffffffffc0201cc0:	8a66                	mv	s4,s9
ffffffffc0201cc2:	40800633          	neg	a2,s0
ffffffffc0201cc6:	46a9                	li	a3,10
ffffffffc0201cc8:	b53d                	j	ffffffffc0201af6 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201cca:	03b05163          	blez	s11,ffffffffc0201cec <vprintfmt+0x34c>
ffffffffc0201cce:	02d00693          	li	a3,45
ffffffffc0201cd2:	f6d79de3          	bne	a5,a3,ffffffffc0201c4c <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201cd6:	00001417          	auipc	s0,0x1
ffffffffc0201cda:	f9240413          	addi	s0,s0,-110 # ffffffffc0202c68 <best_fit_pmm_manager+0x1e0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cde:	02800793          	li	a5,40
ffffffffc0201ce2:	02800513          	li	a0,40
ffffffffc0201ce6:	00140a13          	addi	s4,s0,1
ffffffffc0201cea:	bd6d                	j	ffffffffc0201ba4 <vprintfmt+0x204>
ffffffffc0201cec:	00001a17          	auipc	s4,0x1
ffffffffc0201cf0:	f7da0a13          	addi	s4,s4,-131 # ffffffffc0202c69 <best_fit_pmm_manager+0x1e1>
ffffffffc0201cf4:	02800513          	li	a0,40
ffffffffc0201cf8:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cfc:	05e00413          	li	s0,94
ffffffffc0201d00:	b565                	j	ffffffffc0201ba8 <vprintfmt+0x208>

ffffffffc0201d02 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d02:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d04:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d08:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d0a:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d0c:	ec06                	sd	ra,24(sp)
ffffffffc0201d0e:	f83a                	sd	a4,48(sp)
ffffffffc0201d10:	fc3e                	sd	a5,56(sp)
ffffffffc0201d12:	e0c2                	sd	a6,64(sp)
ffffffffc0201d14:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d16:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d18:	c89ff0ef          	jal	ra,ffffffffc02019a0 <vprintfmt>
}
ffffffffc0201d1c:	60e2                	ld	ra,24(sp)
ffffffffc0201d1e:	6161                	addi	sp,sp,80
ffffffffc0201d20:	8082                	ret

ffffffffc0201d22 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d22:	715d                	addi	sp,sp,-80
ffffffffc0201d24:	e486                	sd	ra,72(sp)
ffffffffc0201d26:	e0a6                	sd	s1,64(sp)
ffffffffc0201d28:	fc4a                	sd	s2,56(sp)
ffffffffc0201d2a:	f84e                	sd	s3,48(sp)
ffffffffc0201d2c:	f452                	sd	s4,40(sp)
ffffffffc0201d2e:	f056                	sd	s5,32(sp)
ffffffffc0201d30:	ec5a                	sd	s6,24(sp)
ffffffffc0201d32:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201d34:	c901                	beqz	a0,ffffffffc0201d44 <readline+0x22>
ffffffffc0201d36:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201d38:	00001517          	auipc	a0,0x1
ffffffffc0201d3c:	f4850513          	addi	a0,a0,-184 # ffffffffc0202c80 <best_fit_pmm_manager+0x1f8>
ffffffffc0201d40:	b98fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
readline(const char *prompt) {
ffffffffc0201d44:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d46:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201d48:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201d4a:	4aa9                	li	s5,10
ffffffffc0201d4c:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201d4e:	00004b97          	auipc	s7,0x4
ffffffffc0201d52:	2f2b8b93          	addi	s7,s7,754 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d56:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201d5a:	bf6fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201d5e:	00054a63          	bltz	a0,ffffffffc0201d72 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d62:	00a95a63          	bge	s2,a0,ffffffffc0201d76 <readline+0x54>
ffffffffc0201d66:	029a5263          	bge	s4,s1,ffffffffc0201d8a <readline+0x68>
        c = getchar();
ffffffffc0201d6a:	be6fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201d6e:	fe055ae3          	bgez	a0,ffffffffc0201d62 <readline+0x40>
            return NULL;
ffffffffc0201d72:	4501                	li	a0,0
ffffffffc0201d74:	a091                	j	ffffffffc0201db8 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201d76:	03351463          	bne	a0,s3,ffffffffc0201d9e <readline+0x7c>
ffffffffc0201d7a:	e8a9                	bnez	s1,ffffffffc0201dcc <readline+0xaa>
        c = getchar();
ffffffffc0201d7c:	bd4fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc0201d80:	fe0549e3          	bltz	a0,ffffffffc0201d72 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201d84:	fea959e3          	bge	s2,a0,ffffffffc0201d76 <readline+0x54>
ffffffffc0201d88:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201d8a:	e42a                	sd	a0,8(sp)
ffffffffc0201d8c:	b82fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i ++] = c;
ffffffffc0201d90:	6522                	ld	a0,8(sp)
ffffffffc0201d92:	009b87b3          	add	a5,s7,s1
ffffffffc0201d96:	2485                	addiw	s1,s1,1
ffffffffc0201d98:	00a78023          	sb	a0,0(a5)
ffffffffc0201d9c:	bf7d                	j	ffffffffc0201d5a <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201d9e:	01550463          	beq	a0,s5,ffffffffc0201da6 <readline+0x84>
ffffffffc0201da2:	fb651ce3          	bne	a0,s6,ffffffffc0201d5a <readline+0x38>
            cputchar(c);
ffffffffc0201da6:	b68fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i] = '\0';
ffffffffc0201daa:	00004517          	auipc	a0,0x4
ffffffffc0201dae:	29650513          	addi	a0,a0,662 # ffffffffc0206040 <buf>
ffffffffc0201db2:	94aa                	add	s1,s1,a0
ffffffffc0201db4:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201db8:	60a6                	ld	ra,72(sp)
ffffffffc0201dba:	6486                	ld	s1,64(sp)
ffffffffc0201dbc:	7962                	ld	s2,56(sp)
ffffffffc0201dbe:	79c2                	ld	s3,48(sp)
ffffffffc0201dc0:	7a22                	ld	s4,40(sp)
ffffffffc0201dc2:	7a82                	ld	s5,32(sp)
ffffffffc0201dc4:	6b62                	ld	s6,24(sp)
ffffffffc0201dc6:	6bc2                	ld	s7,16(sp)
ffffffffc0201dc8:	6161                	addi	sp,sp,80
ffffffffc0201dca:	8082                	ret
            cputchar(c);
ffffffffc0201dcc:	4521                	li	a0,8
ffffffffc0201dce:	b40fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            i --;
ffffffffc0201dd2:	34fd                	addiw	s1,s1,-1
ffffffffc0201dd4:	b759                	j	ffffffffc0201d5a <readline+0x38>

ffffffffc0201dd6 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201dd6:	4781                	li	a5,0
ffffffffc0201dd8:	00004717          	auipc	a4,0x4
ffffffffc0201ddc:	24073703          	ld	a4,576(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201de0:	88ba                	mv	a7,a4
ffffffffc0201de2:	852a                	mv	a0,a0
ffffffffc0201de4:	85be                	mv	a1,a5
ffffffffc0201de6:	863e                	mv	a2,a5
ffffffffc0201de8:	00000073          	ecall
ffffffffc0201dec:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201dee:	8082                	ret

ffffffffc0201df0 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201df0:	4781                	li	a5,0
ffffffffc0201df2:	00004717          	auipc	a4,0x4
ffffffffc0201df6:	69e73703          	ld	a4,1694(a4) # ffffffffc0206490 <SBI_SET_TIMER>
ffffffffc0201dfa:	88ba                	mv	a7,a4
ffffffffc0201dfc:	852a                	mv	a0,a0
ffffffffc0201dfe:	85be                	mv	a1,a5
ffffffffc0201e00:	863e                	mv	a2,a5
ffffffffc0201e02:	00000073          	ecall
ffffffffc0201e06:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201e08:	8082                	ret

ffffffffc0201e0a <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201e0a:	4501                	li	a0,0
ffffffffc0201e0c:	00004797          	auipc	a5,0x4
ffffffffc0201e10:	2047b783          	ld	a5,516(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc0201e14:	88be                	mv	a7,a5
ffffffffc0201e16:	852a                	mv	a0,a0
ffffffffc0201e18:	85aa                	mv	a1,a0
ffffffffc0201e1a:	862a                	mv	a2,a0
ffffffffc0201e1c:	00000073          	ecall
ffffffffc0201e20:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
}
ffffffffc0201e22:	2501                	sext.w	a0,a0
ffffffffc0201e24:	8082                	ret

ffffffffc0201e26 <sbi_shutdown>:
    __asm__ volatile (
ffffffffc0201e26:	4781                	li	a5,0
ffffffffc0201e28:	00004717          	auipc	a4,0x4
ffffffffc0201e2c:	1f873703          	ld	a4,504(a4) # ffffffffc0206020 <SBI_SHUTDOWN>
ffffffffc0201e30:	88ba                	mv	a7,a4
ffffffffc0201e32:	853e                	mv	a0,a5
ffffffffc0201e34:	85be                	mv	a1,a5
ffffffffc0201e36:	863e                	mv	a2,a5
ffffffffc0201e38:	00000073          	ecall
ffffffffc0201e3c:	87aa                	mv	a5,a0

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e3e:	8082                	ret

ffffffffc0201e40 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201e40:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201e44:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201e46:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201e48:	cb81                	beqz	a5,ffffffffc0201e58 <strlen+0x18>
        cnt ++;
ffffffffc0201e4a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201e4c:	00a707b3          	add	a5,a4,a0
ffffffffc0201e50:	0007c783          	lbu	a5,0(a5)
ffffffffc0201e54:	fbfd                	bnez	a5,ffffffffc0201e4a <strlen+0xa>
ffffffffc0201e56:	8082                	ret
    }
    return cnt;
}
ffffffffc0201e58:	8082                	ret

ffffffffc0201e5a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201e5a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e5c:	e589                	bnez	a1,ffffffffc0201e66 <strnlen+0xc>
ffffffffc0201e5e:	a811                	j	ffffffffc0201e72 <strnlen+0x18>
        cnt ++;
ffffffffc0201e60:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201e62:	00f58863          	beq	a1,a5,ffffffffc0201e72 <strnlen+0x18>
ffffffffc0201e66:	00f50733          	add	a4,a0,a5
ffffffffc0201e6a:	00074703          	lbu	a4,0(a4)
ffffffffc0201e6e:	fb6d                	bnez	a4,ffffffffc0201e60 <strnlen+0x6>
ffffffffc0201e70:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201e72:	852e                	mv	a0,a1
ffffffffc0201e74:	8082                	ret

ffffffffc0201e76 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e76:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e7a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e7e:	cb89                	beqz	a5,ffffffffc0201e90 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201e80:	0505                	addi	a0,a0,1
ffffffffc0201e82:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201e84:	fee789e3          	beq	a5,a4,ffffffffc0201e76 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201e88:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201e8c:	9d19                	subw	a0,a0,a4
ffffffffc0201e8e:	8082                	ret
ffffffffc0201e90:	4501                	li	a0,0
ffffffffc0201e92:	bfed                	j	ffffffffc0201e8c <strcmp+0x16>

ffffffffc0201e94 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e94:	c20d                	beqz	a2,ffffffffc0201eb6 <strncmp+0x22>
ffffffffc0201e96:	962e                	add	a2,a2,a1
ffffffffc0201e98:	a031                	j	ffffffffc0201ea4 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0201e9a:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201e9c:	00e79a63          	bne	a5,a4,ffffffffc0201eb0 <strncmp+0x1c>
ffffffffc0201ea0:	00b60b63          	beq	a2,a1,ffffffffc0201eb6 <strncmp+0x22>
ffffffffc0201ea4:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0201ea8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201eaa:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0201eae:	f7f5                	bnez	a5,ffffffffc0201e9a <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eb0:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0201eb4:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201eb6:	4501                	li	a0,0
ffffffffc0201eb8:	8082                	ret

ffffffffc0201eba <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201eba:	00054783          	lbu	a5,0(a0)
ffffffffc0201ebe:	c799                	beqz	a5,ffffffffc0201ecc <strchr+0x12>
        if (*s == c) {
ffffffffc0201ec0:	00f58763          	beq	a1,a5,ffffffffc0201ece <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201ec4:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201ec8:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201eca:	fbfd                	bnez	a5,ffffffffc0201ec0 <strchr+0x6>
    }
    return NULL;
ffffffffc0201ecc:	4501                	li	a0,0
}
ffffffffc0201ece:	8082                	ret

ffffffffc0201ed0 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201ed0:	ca01                	beqz	a2,ffffffffc0201ee0 <memset+0x10>
ffffffffc0201ed2:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201ed4:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201ed6:	0785                	addi	a5,a5,1
ffffffffc0201ed8:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201edc:	fec79de3          	bne	a5,a2,ffffffffc0201ed6 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201ee0:	8082                	ret
