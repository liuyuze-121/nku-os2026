
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00007297          	auipc	t0,0x7
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0207000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00007297          	auipc	t0,0x7
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0207008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02062b7          	lui	t0,0xc0206
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
ffffffffc020003c:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	0d828293          	addi	t0,t0,216 # ffffffffc02000d8 <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004a:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc020004c:	00002517          	auipc	a0,0x2
ffffffffc0200050:	51c50513          	addi	a0,a0,1308 # ffffffffc0202568 <etext>
void print_kerninfo(void) {
ffffffffc0200054:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200056:	0fa000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005a:	00000597          	auipc	a1,0x0
ffffffffc020005e:	07e58593          	addi	a1,a1,126 # ffffffffc02000d8 <kern_init>
ffffffffc0200062:	00002517          	auipc	a0,0x2
ffffffffc0200066:	52650513          	addi	a0,a0,1318 # ffffffffc0202588 <etext+0x20>
ffffffffc020006a:	0e6000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc020006e:	00002597          	auipc	a1,0x2
ffffffffc0200072:	4fa58593          	addi	a1,a1,1274 # ffffffffc0202568 <etext>
ffffffffc0200076:	00002517          	auipc	a0,0x2
ffffffffc020007a:	53250513          	addi	a0,a0,1330 # ffffffffc02025a8 <etext+0x40>
ffffffffc020007e:	0d2000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200082:	00007597          	auipc	a1,0x7
ffffffffc0200086:	f9658593          	addi	a1,a1,-106 # ffffffffc0207018 <buddy_free_lists>
ffffffffc020008a:	00002517          	auipc	a0,0x2
ffffffffc020008e:	53e50513          	addi	a0,a0,1342 # ffffffffc02025c8 <etext+0x60>
ffffffffc0200092:	0be000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc0200096:	00009597          	auipc	a1,0x9
ffffffffc020009a:	ee658593          	addi	a1,a1,-282 # ffffffffc0208f7c <end>
ffffffffc020009e:	00002517          	auipc	a0,0x2
ffffffffc02000a2:	54a50513          	addi	a0,a0,1354 # ffffffffc02025e8 <etext+0x80>
ffffffffc02000a6:	0aa000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000aa:	00009597          	auipc	a1,0x9
ffffffffc02000ae:	2d158593          	addi	a1,a1,721 # ffffffffc020937b <end+0x3ff>
ffffffffc02000b2:	00000797          	auipc	a5,0x0
ffffffffc02000b6:	02678793          	addi	a5,a5,38 # ffffffffc02000d8 <kern_init>
ffffffffc02000ba:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000be:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c2:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c4:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000c8:	95be                	add	a1,a1,a5
ffffffffc02000ca:	85a9                	srai	a1,a1,0xa
ffffffffc02000cc:	00002517          	auipc	a0,0x2
ffffffffc02000d0:	53c50513          	addi	a0,a0,1340 # ffffffffc0202608 <etext+0xa0>
}
ffffffffc02000d4:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000d6:	a8ad                	j	ffffffffc0200150 <cprintf>

ffffffffc02000d8 <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000d8:	00007517          	auipc	a0,0x7
ffffffffc02000dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0207018 <buddy_free_lists>
ffffffffc02000e0:	00009617          	auipc	a2,0x9
ffffffffc02000e4:	e9c60613          	addi	a2,a2,-356 # ffffffffc0208f7c <end>
int kern_init(void) {
ffffffffc02000e8:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ea:	8e09                	sub	a2,a2,a0
ffffffffc02000ec:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000ee:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f0:	466020ef          	jal	ra,ffffffffc0202556 <memset>
    dtb_init();
ffffffffc02000f4:	130000ef          	jal	ra,ffffffffc0200224 <dtb_init>
    cons_init();  // init the console
ffffffffc02000f8:	122000ef          	jal	ra,ffffffffc020021a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc02000fc:	00002517          	auipc	a0,0x2
ffffffffc0200100:	53c50513          	addi	a0,a0,1340 # ffffffffc0202638 <etext+0xd0>
ffffffffc0200104:	082000ef          	jal	ra,ffffffffc0200186 <cputs>

    print_kerninfo();
ffffffffc0200108:	f43ff0ef          	jal	ra,ffffffffc020004a <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc020010c:	2d4010ef          	jal	ra,ffffffffc02013e0 <pmm_init>
    slub_init(); // init SLUB object allocator
ffffffffc0200110:	269010ef          	jal	ra,ffffffffc0201b78 <slub_init>

    /* do nothing */
    while (1)
ffffffffc0200114:	a001                	j	ffffffffc0200114 <kern_init+0x3c>

ffffffffc0200116 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200116:	1141                	addi	sp,sp,-16
ffffffffc0200118:	e022                	sd	s0,0(sp)
ffffffffc020011a:	e406                	sd	ra,8(sp)
ffffffffc020011c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011e:	0fe000ef          	jal	ra,ffffffffc020021c <cons_putc>
    (*cnt) ++;
ffffffffc0200122:	401c                	lw	a5,0(s0)
}
ffffffffc0200124:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200126:	2785                	addiw	a5,a5,1
ffffffffc0200128:	c01c                	sw	a5,0(s0)
}
ffffffffc020012a:	6402                	ld	s0,0(sp)
ffffffffc020012c:	0141                	addi	sp,sp,16
ffffffffc020012e:	8082                	ret

ffffffffc0200130 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200130:	1101                	addi	sp,sp,-32
ffffffffc0200132:	862a                	mv	a2,a0
ffffffffc0200134:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200136:	00000517          	auipc	a0,0x0
ffffffffc020013a:	fe050513          	addi	a0,a0,-32 # ffffffffc0200116 <cputch>
ffffffffc020013e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200140:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200142:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200144:	7fd010ef          	jal	ra,ffffffffc0202140 <vprintfmt>
    return cnt;
}
ffffffffc0200148:	60e2                	ld	ra,24(sp)
ffffffffc020014a:	4532                	lw	a0,12(sp)
ffffffffc020014c:	6105                	addi	sp,sp,32
ffffffffc020014e:	8082                	ret

ffffffffc0200150 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200150:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200152:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200156:	8e2a                	mv	t3,a0
ffffffffc0200158:	f42e                	sd	a1,40(sp)
ffffffffc020015a:	f832                	sd	a2,48(sp)
ffffffffc020015c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015e:	00000517          	auipc	a0,0x0
ffffffffc0200162:	fb850513          	addi	a0,a0,-72 # ffffffffc0200116 <cputch>
ffffffffc0200166:	004c                	addi	a1,sp,4
ffffffffc0200168:	869a                	mv	a3,t1
ffffffffc020016a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020016c:	ec06                	sd	ra,24(sp)
ffffffffc020016e:	e0ba                	sd	a4,64(sp)
ffffffffc0200170:	e4be                	sd	a5,72(sp)
ffffffffc0200172:	e8c2                	sd	a6,80(sp)
ffffffffc0200174:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200176:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200178:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020017a:	7c7010ef          	jal	ra,ffffffffc0202140 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017e:	60e2                	ld	ra,24(sp)
ffffffffc0200180:	4512                	lw	a0,4(sp)
ffffffffc0200182:	6125                	addi	sp,sp,96
ffffffffc0200184:	8082                	ret

ffffffffc0200186 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200186:	1101                	addi	sp,sp,-32
ffffffffc0200188:	e822                	sd	s0,16(sp)
ffffffffc020018a:	ec06                	sd	ra,24(sp)
ffffffffc020018c:	e426                	sd	s1,8(sp)
ffffffffc020018e:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200190:	00054503          	lbu	a0,0(a0)
ffffffffc0200194:	c51d                	beqz	a0,ffffffffc02001c2 <cputs+0x3c>
ffffffffc0200196:	0405                	addi	s0,s0,1
ffffffffc0200198:	4485                	li	s1,1
ffffffffc020019a:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020019c:	080000ef          	jal	ra,ffffffffc020021c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc02001a0:	00044503          	lbu	a0,0(s0)
ffffffffc02001a4:	008487bb          	addw	a5,s1,s0
ffffffffc02001a8:	0405                	addi	s0,s0,1
ffffffffc02001aa:	f96d                	bnez	a0,ffffffffc020019c <cputs+0x16>
    (*cnt) ++;
ffffffffc02001ac:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001b0:	4529                	li	a0,10
ffffffffc02001b2:	06a000ef          	jal	ra,ffffffffc020021c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b6:	60e2                	ld	ra,24(sp)
ffffffffc02001b8:	8522                	mv	a0,s0
ffffffffc02001ba:	6442                	ld	s0,16(sp)
ffffffffc02001bc:	64a2                	ld	s1,8(sp)
ffffffffc02001be:	6105                	addi	sp,sp,32
ffffffffc02001c0:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001c2:	4405                	li	s0,1
ffffffffc02001c4:	b7f5                	j	ffffffffc02001b0 <cputs+0x2a>

ffffffffc02001c6 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c6:	00009317          	auipc	t1,0x9
ffffffffc02001ca:	d6230313          	addi	t1,t1,-670 # ffffffffc0208f28 <is_panic>
ffffffffc02001ce:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d2:	715d                	addi	sp,sp,-80
ffffffffc02001d4:	ec06                	sd	ra,24(sp)
ffffffffc02001d6:	e822                	sd	s0,16(sp)
ffffffffc02001d8:	f436                	sd	a3,40(sp)
ffffffffc02001da:	f83a                	sd	a4,48(sp)
ffffffffc02001dc:	fc3e                	sd	a5,56(sp)
ffffffffc02001de:	e0c2                	sd	a6,64(sp)
ffffffffc02001e0:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e2:	000e0363          	beqz	t3,ffffffffc02001e8 <__panic+0x22>
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
ffffffffc02001e6:	a001                	j	ffffffffc02001e6 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e8:	4785                	li	a5,1
ffffffffc02001ea:	00f32023          	sw	a5,0(t1)
    va_start(ap, fmt);
ffffffffc02001ee:	8432                	mv	s0,a2
ffffffffc02001f0:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f2:	862e                	mv	a2,a1
ffffffffc02001f4:	85aa                	mv	a1,a0
ffffffffc02001f6:	00002517          	auipc	a0,0x2
ffffffffc02001fa:	46250513          	addi	a0,a0,1122 # ffffffffc0202658 <etext+0xf0>
    va_start(ap, fmt);
ffffffffc02001fe:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200200:	f51ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200204:	65a2                	ld	a1,8(sp)
ffffffffc0200206:	8522                	mv	a0,s0
ffffffffc0200208:	f29ff0ef          	jal	ra,ffffffffc0200130 <vcprintf>
    cprintf("\n");
ffffffffc020020c:	00002517          	auipc	a0,0x2
ffffffffc0200210:	42450513          	addi	a0,a0,1060 # ffffffffc0202630 <etext+0xc8>
ffffffffc0200214:	f3dff0ef          	jal	ra,ffffffffc0200150 <cprintf>
ffffffffc0200218:	b7f9                	j	ffffffffc02001e6 <__panic+0x20>

ffffffffc020021a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021a:	8082                	ret

ffffffffc020021c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020021c:	0ff57513          	zext.b	a0,a0
ffffffffc0200220:	2a20206f          	j	ffffffffc02024c2 <sbi_console_putchar>

ffffffffc0200224 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc0200224:	7119                	addi	sp,sp,-128
    cprintf("DTB Init\n");
ffffffffc0200226:	00002517          	auipc	a0,0x2
ffffffffc020022a:	45250513          	addi	a0,a0,1106 # ffffffffc0202678 <etext+0x110>
void dtb_init(void) {
ffffffffc020022e:	fc86                	sd	ra,120(sp)
ffffffffc0200230:	f8a2                	sd	s0,112(sp)
ffffffffc0200232:	e8d2                	sd	s4,80(sp)
ffffffffc0200234:	f4a6                	sd	s1,104(sp)
ffffffffc0200236:	f0ca                	sd	s2,96(sp)
ffffffffc0200238:	ecce                	sd	s3,88(sp)
ffffffffc020023a:	e4d6                	sd	s5,72(sp)
ffffffffc020023c:	e0da                	sd	s6,64(sp)
ffffffffc020023e:	fc5e                	sd	s7,56(sp)
ffffffffc0200240:	f862                	sd	s8,48(sp)
ffffffffc0200242:	f466                	sd	s9,40(sp)
ffffffffc0200244:	f06a                	sd	s10,32(sp)
ffffffffc0200246:	ec6e                	sd	s11,24(sp)
    cprintf("DTB Init\n");
ffffffffc0200248:	f09ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020024c:	00007597          	auipc	a1,0x7
ffffffffc0200250:	db45b583          	ld	a1,-588(a1) # ffffffffc0207000 <boot_hartid>
ffffffffc0200254:	00002517          	auipc	a0,0x2
ffffffffc0200258:	43450513          	addi	a0,a0,1076 # ffffffffc0202688 <etext+0x120>
ffffffffc020025c:	ef5ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc0200260:	00007417          	auipc	s0,0x7
ffffffffc0200264:	da840413          	addi	s0,s0,-600 # ffffffffc0207008 <boot_dtb>
ffffffffc0200268:	600c                	ld	a1,0(s0)
ffffffffc020026a:	00002517          	auipc	a0,0x2
ffffffffc020026e:	42e50513          	addi	a0,a0,1070 # ffffffffc0202698 <etext+0x130>
ffffffffc0200272:	edfff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200276:	00043a03          	ld	s4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020027a:	00002517          	auipc	a0,0x2
ffffffffc020027e:	43650513          	addi	a0,a0,1078 # ffffffffc02026b0 <etext+0x148>
    if (boot_dtb == 0) {
ffffffffc0200282:	120a0463          	beqz	s4,ffffffffc02003aa <dtb_init+0x186>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200286:	57f5                	li	a5,-3
ffffffffc0200288:	07fa                	slli	a5,a5,0x1e
ffffffffc020028a:	00fa0733          	add	a4,s4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc020028e:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200290:	00ff0637          	lui	a2,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200294:	6b41                	lui	s6,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200296:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020029a:	0187969b          	slliw	a3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020029e:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002a2:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002a6:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002aa:	8df1                	and	a1,a1,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ac:	8ec9                	or	a3,a3,a0
ffffffffc02002ae:	0087979b          	slliw	a5,a5,0x8
ffffffffc02002b2:	1b7d                	addi	s6,s6,-1
ffffffffc02002b4:	0167f7b3          	and	a5,a5,s6
ffffffffc02002b8:	8dd5                	or	a1,a1,a3
ffffffffc02002ba:	8ddd                	or	a1,a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc02002bc:	d00e07b7          	lui	a5,0xd00e0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002c0:	2581                	sext.w	a1,a1
    if (magic != 0xd00dfeed) {
ffffffffc02002c2:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed6f71>
ffffffffc02002c6:	10f59163          	bne	a1,a5,ffffffffc02003c8 <dtb_init+0x1a4>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc02002ca:	471c                	lw	a5,8(a4)
ffffffffc02002cc:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc02002ce:	4c81                	li	s9,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002d0:	0087d59b          	srliw	a1,a5,0x8
ffffffffc02002d4:	0086d51b          	srliw	a0,a3,0x8
ffffffffc02002d8:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002dc:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e0:	01879a1b          	slliw	s4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002e4:	0187d81b          	srliw	a6,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002e8:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002ec:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f0:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002f4:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002f8:	8d71                	and	a0,a0,a2
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fa:	01146433          	or	s0,s0,a7
ffffffffc02002fe:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200302:	010a6a33          	or	s4,s4,a6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200306:	8e6d                	and	a2,a2,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200308:	0087979b          	slliw	a5,a5,0x8
ffffffffc020030c:	8c49                	or	s0,s0,a0
ffffffffc020030e:	0166f6b3          	and	a3,a3,s6
ffffffffc0200312:	00ca6a33          	or	s4,s4,a2
ffffffffc0200316:	0167f7b3          	and	a5,a5,s6
ffffffffc020031a:	8c55                	or	s0,s0,a3
ffffffffc020031c:	00fa6a33          	or	s4,s4,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200320:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200322:	1a02                	slli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200324:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200326:	020a5a13          	srli	s4,s4,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020032a:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020032c:	9a3a                	add	s4,s4,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020032e:	00ff0c37          	lui	s8,0xff0
        switch (token) {
ffffffffc0200332:	4b8d                	li	s7,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200334:	00002917          	auipc	s2,0x2
ffffffffc0200338:	3cc90913          	addi	s2,s2,972 # ffffffffc0202700 <etext+0x198>
ffffffffc020033c:	49bd                	li	s3,15
        switch (token) {
ffffffffc020033e:	4d91                	li	s11,4
ffffffffc0200340:	4d05                	li	s10,1
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200342:	00002497          	auipc	s1,0x2
ffffffffc0200346:	3b648493          	addi	s1,s1,950 # ffffffffc02026f8 <etext+0x190>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc020034a:	000a2703          	lw	a4,0(s4)
ffffffffc020034e:	004a0a93          	addi	s5,s4,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200352:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200356:	0187179b          	slliw	a5,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035a:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035e:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200362:	0107571b          	srliw	a4,a4,0x10
ffffffffc0200366:	8fd1                	or	a5,a5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200368:	0186f6b3          	and	a3,a3,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020036c:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200370:	8fd5                	or	a5,a5,a3
ffffffffc0200372:	00eb7733          	and	a4,s6,a4
ffffffffc0200376:	8fd9                	or	a5,a5,a4
ffffffffc0200378:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc020037a:	09778c63          	beq	a5,s7,ffffffffc0200412 <dtb_init+0x1ee>
ffffffffc020037e:	00fbea63          	bltu	s7,a5,ffffffffc0200392 <dtb_init+0x16e>
ffffffffc0200382:	07a78663          	beq	a5,s10,ffffffffc02003ee <dtb_init+0x1ca>
ffffffffc0200386:	4709                	li	a4,2
ffffffffc0200388:	00e79763          	bne	a5,a4,ffffffffc0200396 <dtb_init+0x172>
ffffffffc020038c:	4c81                	li	s9,0
ffffffffc020038e:	8a56                	mv	s4,s5
ffffffffc0200390:	bf6d                	j	ffffffffc020034a <dtb_init+0x126>
ffffffffc0200392:	ffb78ee3          	beq	a5,s11,ffffffffc020038e <dtb_init+0x16a>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc0200396:	00002517          	auipc	a0,0x2
ffffffffc020039a:	3e250513          	addi	a0,a0,994 # ffffffffc0202778 <etext+0x210>
ffffffffc020039e:	db3ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003a2:	00002517          	auipc	a0,0x2
ffffffffc02003a6:	40e50513          	addi	a0,a0,1038 # ffffffffc02027b0 <etext+0x248>
}
ffffffffc02003aa:	7446                	ld	s0,112(sp)
ffffffffc02003ac:	70e6                	ld	ra,120(sp)
ffffffffc02003ae:	74a6                	ld	s1,104(sp)
ffffffffc02003b0:	7906                	ld	s2,96(sp)
ffffffffc02003b2:	69e6                	ld	s3,88(sp)
ffffffffc02003b4:	6a46                	ld	s4,80(sp)
ffffffffc02003b6:	6aa6                	ld	s5,72(sp)
ffffffffc02003b8:	6b06                	ld	s6,64(sp)
ffffffffc02003ba:	7be2                	ld	s7,56(sp)
ffffffffc02003bc:	7c42                	ld	s8,48(sp)
ffffffffc02003be:	7ca2                	ld	s9,40(sp)
ffffffffc02003c0:	7d02                	ld	s10,32(sp)
ffffffffc02003c2:	6de2                	ld	s11,24(sp)
ffffffffc02003c4:	6109                	addi	sp,sp,128
    cprintf("DTB init completed\n");
ffffffffc02003c6:	b369                	j	ffffffffc0200150 <cprintf>
}
ffffffffc02003c8:	7446                	ld	s0,112(sp)
ffffffffc02003ca:	70e6                	ld	ra,120(sp)
ffffffffc02003cc:	74a6                	ld	s1,104(sp)
ffffffffc02003ce:	7906                	ld	s2,96(sp)
ffffffffc02003d0:	69e6                	ld	s3,88(sp)
ffffffffc02003d2:	6a46                	ld	s4,80(sp)
ffffffffc02003d4:	6aa6                	ld	s5,72(sp)
ffffffffc02003d6:	6b06                	ld	s6,64(sp)
ffffffffc02003d8:	7be2                	ld	s7,56(sp)
ffffffffc02003da:	7c42                	ld	s8,48(sp)
ffffffffc02003dc:	7ca2                	ld	s9,40(sp)
ffffffffc02003de:	7d02                	ld	s10,32(sp)
ffffffffc02003e0:	6de2                	ld	s11,24(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003e2:	00002517          	auipc	a0,0x2
ffffffffc02003e6:	2ee50513          	addi	a0,a0,750 # ffffffffc02026d0 <etext+0x168>
}
ffffffffc02003ea:	6109                	addi	sp,sp,128
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02003ec:	b395                	j	ffffffffc0200150 <cprintf>
                int name_len = strlen(name);
ffffffffc02003ee:	8556                	mv	a0,s5
ffffffffc02003f0:	0ec020ef          	jal	ra,ffffffffc02024dc <strlen>
ffffffffc02003f4:	8a2a                	mv	s4,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003f6:	4619                	li	a2,6
ffffffffc02003f8:	85a6                	mv	a1,s1
ffffffffc02003fa:	8556                	mv	a0,s5
                int name_len = strlen(name);
ffffffffc02003fc:	2a01                	sext.w	s4,s4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02003fe:	132020ef          	jal	ra,ffffffffc0202530 <strncmp>
ffffffffc0200402:	e111                	bnez	a0,ffffffffc0200406 <dtb_init+0x1e2>
                    in_memory_node = 1;
ffffffffc0200404:	4c85                	li	s9,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200406:	0a91                	addi	s5,s5,4
ffffffffc0200408:	9ad2                	add	s5,s5,s4
ffffffffc020040a:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020040e:	8a56                	mv	s4,s5
ffffffffc0200410:	bf2d                	j	ffffffffc020034a <dtb_init+0x126>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200412:	004a2783          	lw	a5,4(s4)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200416:	00ca0693          	addi	a3,s4,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020041a:	0087d71b          	srliw	a4,a5,0x8
ffffffffc020041e:	01879a9b          	slliw	s5,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200422:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200426:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020042a:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020042e:	00caeab3          	or	s5,s5,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200432:	01877733          	and	a4,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200436:	0087979b          	slliw	a5,a5,0x8
ffffffffc020043a:	00eaeab3          	or	s5,s5,a4
ffffffffc020043e:	00fb77b3          	and	a5,s6,a5
ffffffffc0200442:	00faeab3          	or	s5,s5,a5
ffffffffc0200446:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200448:	000c9c63          	bnez	s9,ffffffffc0200460 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020044c:	1a82                	slli	s5,s5,0x20
ffffffffc020044e:	00368793          	addi	a5,a3,3
ffffffffc0200452:	020ada93          	srli	s5,s5,0x20
ffffffffc0200456:	9abe                	add	s5,s5,a5
ffffffffc0200458:	ffcafa93          	andi	s5,s5,-4
        switch (token) {
ffffffffc020045c:	8a56                	mv	s4,s5
ffffffffc020045e:	b5f5                	j	ffffffffc020034a <dtb_init+0x126>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200460:	008a2783          	lw	a5,8(s4)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200464:	85ca                	mv	a1,s2
ffffffffc0200466:	e436                	sd	a3,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200468:	0087d51b          	srliw	a0,a5,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020046c:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200470:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200474:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200478:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020047c:	8f51                	or	a4,a4,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020047e:	01857533          	and	a0,a0,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200482:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200486:	8d59                	or	a0,a0,a4
ffffffffc0200488:	00fb77b3          	and	a5,s6,a5
ffffffffc020048c:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020048e:	1502                	slli	a0,a0,0x20
ffffffffc0200490:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200492:	9522                	add	a0,a0,s0
ffffffffc0200494:	07e020ef          	jal	ra,ffffffffc0202512 <strcmp>
ffffffffc0200498:	66a2                	ld	a3,8(sp)
ffffffffc020049a:	f94d                	bnez	a0,ffffffffc020044c <dtb_init+0x228>
ffffffffc020049c:	fb59f8e3          	bgeu	s3,s5,ffffffffc020044c <dtb_init+0x228>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02004a0:	00ca3783          	ld	a5,12(s4)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02004a4:	014a3703          	ld	a4,20(s4)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02004a8:	00002517          	auipc	a0,0x2
ffffffffc02004ac:	26050513          	addi	a0,a0,608 # ffffffffc0202708 <etext+0x1a0>
           fdt32_to_cpu(x >> 32);
ffffffffc02004b0:	4207d613          	srai	a2,a5,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b4:	0087d31b          	srliw	t1,a5,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02004b8:	42075593          	srai	a1,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004bc:	0187de1b          	srliw	t3,a5,0x18
ffffffffc02004c0:	0186581b          	srliw	a6,a2,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c4:	0187941b          	slliw	s0,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c8:	0107d89b          	srliw	a7,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004cc:	0187d693          	srli	a3,a5,0x18
ffffffffc02004d0:	01861f1b          	slliw	t5,a2,0x18
ffffffffc02004d4:	0087579b          	srliw	a5,a4,0x8
ffffffffc02004d8:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004dc:	0106561b          	srliw	a2,a2,0x10
ffffffffc02004e0:	010f6f33          	or	t5,t5,a6
ffffffffc02004e4:	0187529b          	srliw	t0,a4,0x18
ffffffffc02004e8:	0185df9b          	srliw	t6,a1,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ec:	01837333          	and	t1,t1,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004f0:	01c46433          	or	s0,s0,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004f4:	0186f6b3          	and	a3,a3,s8
ffffffffc02004f8:	01859e1b          	slliw	t3,a1,0x18
ffffffffc02004fc:	01871e9b          	slliw	t4,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200500:	0107581b          	srliw	a6,a4,0x10
ffffffffc0200504:	0086161b          	slliw	a2,a2,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200508:	8361                	srli	a4,a4,0x18
ffffffffc020050a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020050e:	0105d59b          	srliw	a1,a1,0x10
ffffffffc0200512:	01e6e6b3          	or	a3,a3,t5
ffffffffc0200516:	00cb7633          	and	a2,s6,a2
ffffffffc020051a:	0088181b          	slliw	a6,a6,0x8
ffffffffc020051e:	0085959b          	slliw	a1,a1,0x8
ffffffffc0200522:	00646433          	or	s0,s0,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200526:	0187f7b3          	and	a5,a5,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020052a:	01fe6333          	or	t1,t3,t6
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020052e:	01877c33          	and	s8,a4,s8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200532:	0088989b          	slliw	a7,a7,0x8
ffffffffc0200536:	011b78b3          	and	a7,s6,a7
ffffffffc020053a:	005eeeb3          	or	t4,t4,t0
ffffffffc020053e:	00c6e733          	or	a4,a3,a2
ffffffffc0200542:	006c6c33          	or	s8,s8,t1
ffffffffc0200546:	010b76b3          	and	a3,s6,a6
ffffffffc020054a:	00bb7b33          	and	s6,s6,a1
ffffffffc020054e:	01d7e7b3          	or	a5,a5,t4
ffffffffc0200552:	016c6b33          	or	s6,s8,s6
ffffffffc0200556:	01146433          	or	s0,s0,a7
ffffffffc020055a:	8fd5                	or	a5,a5,a3
           fdt32_to_cpu(x >> 32);
ffffffffc020055c:	1702                	slli	a4,a4,0x20
ffffffffc020055e:	1b02                	slli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200560:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200562:	9301                	srli	a4,a4,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200564:	1402                	slli	s0,s0,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200566:	020b5b13          	srli	s6,s6,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020056a:	0167eb33          	or	s6,a5,s6
ffffffffc020056e:	8c59                	or	s0,s0,a4
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200570:	be1ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200574:	85a2                	mv	a1,s0
ffffffffc0200576:	00002517          	auipc	a0,0x2
ffffffffc020057a:	1b250513          	addi	a0,a0,434 # ffffffffc0202728 <etext+0x1c0>
ffffffffc020057e:	bd3ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200582:	014b5613          	srli	a2,s6,0x14
ffffffffc0200586:	85da                	mv	a1,s6
ffffffffc0200588:	00002517          	auipc	a0,0x2
ffffffffc020058c:	1b850513          	addi	a0,a0,440 # ffffffffc0202740 <etext+0x1d8>
ffffffffc0200590:	bc1ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200594:	008b05b3          	add	a1,s6,s0
ffffffffc0200598:	15fd                	addi	a1,a1,-1
ffffffffc020059a:	00002517          	auipc	a0,0x2
ffffffffc020059e:	1c650513          	addi	a0,a0,454 # ffffffffc0202760 <etext+0x1f8>
ffffffffc02005a2:	bafff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02005a6:	00002517          	auipc	a0,0x2
ffffffffc02005aa:	20a50513          	addi	a0,a0,522 # ffffffffc02027b0 <etext+0x248>
        memory_base = mem_base;
ffffffffc02005ae:	00009797          	auipc	a5,0x9
ffffffffc02005b2:	9887b123          	sd	s0,-1662(a5) # ffffffffc0208f30 <memory_base>
        memory_size = mem_size;
ffffffffc02005b6:	00009797          	auipc	a5,0x9
ffffffffc02005ba:	9967b123          	sd	s6,-1662(a5) # ffffffffc0208f38 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02005be:	b3f5                	j	ffffffffc02003aa <dtb_init+0x186>

ffffffffc02005c0 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02005c0:	00009517          	auipc	a0,0x9
ffffffffc02005c4:	97053503          	ld	a0,-1680(a0) # ffffffffc0208f30 <memory_base>
ffffffffc02005c8:	8082                	ret

ffffffffc02005ca <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02005ca:	00009517          	auipc	a0,0x9
ffffffffc02005ce:	96e53503          	ld	a0,-1682(a0) # ffffffffc0208f38 <memory_size>
ffffffffc02005d2:	8082                	ret

ffffffffc02005d4 <buddy_init>:
}

/* 初始化各阶空闲链表 */
static void
buddy_init(void) {
    for (int i = 0; i <= BUDDY_MAX_ORDER; i++) {
ffffffffc02005d4:	00007797          	auipc	a5,0x7
ffffffffc02005d8:	a4478793          	addi	a5,a5,-1468 # ffffffffc0207018 <buddy_free_lists>
ffffffffc02005dc:	00007717          	auipc	a4,0x7
ffffffffc02005e0:	b4c70713          	addi	a4,a4,-1204 # ffffffffc0207128 <slub_slabs>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc02005e4:	e79c                	sd	a5,8(a5)
ffffffffc02005e6:	e39c                	sd	a5,0(a5)
ffffffffc02005e8:	07c1                	addi	a5,a5,16
ffffffffc02005ea:	fee79de3          	bne	a5,a4,ffffffffc02005e4 <buddy_init+0x10>
        list_init(&buddy_free_lists[i]);
    }
    buddy_nr_free = 0;
ffffffffc02005ee:	00009797          	auipc	a5,0x9
ffffffffc02005f2:	9407b923          	sd	zero,-1710(a5) # ffffffffc0208f40 <buddy_nr_free>
}
ffffffffc02005f6:	8082                	ret

ffffffffc02005f8 <buddy_nr_free_pages>:

/* 返回当前空闲页数 */
static size_t
buddy_nr_free_pages(void) {
    return buddy_nr_free;
}
ffffffffc02005f8:	00009517          	auipc	a0,0x9
ffffffffc02005fc:	94853503          	ld	a0,-1720(a0) # ffffffffc0208f40 <buddy_nr_free>
ffffffffc0200600:	8082                	ret

ffffffffc0200602 <buddy_check_lists>:
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200602:	00003e17          	auipc	t3,0x3
ffffffffc0200606:	086e3e03          	ld	t3,134(t3) # ffffffffc0203688 <nbase>

            assert(PageProperty(p));
            assert(p->property == size);
            assert(page2ppn(p) % size == 0);
            assert(p >= pages);
            assert(p + size <= pages + (npage - nbase));
ffffffffc020060a:	00009797          	auipc	a5,0x9
ffffffffc020060e:	93e7b783          	ld	a5,-1730(a5) # ffffffffc0208f48 <npage>
ffffffffc0200612:	41c787b3          	sub	a5,a5,t3
ffffffffc0200616:	00279893          	slli	a7,a5,0x2
ffffffffc020061a:	98be                	add	a7,a7,a5
buddy_check_lists(void) {
ffffffffc020061c:	1141                	addi	sp,sp,-16
ffffffffc020061e:	00009597          	auipc	a1,0x9
ffffffffc0200622:	9325b583          	ld	a1,-1742(a1) # ffffffffc0208f50 <pages>
            assert(p + size <= pages + (npage - nbase));
ffffffffc0200626:	088e                	slli	a7,a7,0x3
buddy_check_lists(void) {
ffffffffc0200628:	e022                	sd	s0,0(sp)
ffffffffc020062a:	e406                	sd	ra,8(sp)
            assert(p + size <= pages + (npage - nbase));
ffffffffc020062c:	98ae                	add	a7,a7,a1
ffffffffc020062e:	00007517          	auipc	a0,0x7
ffffffffc0200632:	9ea50513          	addi	a0,a0,-1558 # ffffffffc0207018 <buddy_free_lists>
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200636:	4f01                	li	t5,0
    size_t total = 0;
ffffffffc0200638:	4401                	li	s0,0
        size_t size = (size_t)1 << order;
ffffffffc020063a:	4f85                	li	t6,1
            assert(p + size <= pages + (npage - nbase));
ffffffffc020063c:	02800293          	li	t0,40
ffffffffc0200640:	00003e97          	auipc	t4,0x3
ffffffffc0200644:	038ebe83          	ld	t4,56(t4) # ffffffffc0203678 <error_string+0x38>
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200648:	43c5                	li	t2,17
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020064a:	6518                	ld	a4,8(a0)
        size_t size = (size_t)1 << order;
ffffffffc020064c:	01ef9633          	sll	a2,t6,t5
        while ((le = list_next(le)) != head) {
ffffffffc0200650:	04e50263          	beq	a0,a4,ffffffffc0200694 <buddy_check_lists+0x92>
            assert(p + size <= pages + (npage - nbase));
ffffffffc0200654:	01e29333          	sll	t1,t0,t5
            assert(page2ppn(p) % size == 0);
ffffffffc0200658:	fff60813          	addi	a6,a2,-1 # feffff <kern_entry-0xffffffffbf210001>
            assert(PageProperty(p));
ffffffffc020065c:	ff073783          	ld	a5,-16(a4)
            struct Page *p = le2page(le, page_link);
ffffffffc0200660:	fe870693          	addi	a3,a4,-24
            assert(PageProperty(p));
ffffffffc0200664:	8b89                	andi	a5,a5,2
ffffffffc0200666:	cbad                	beqz	a5,ffffffffc02006d8 <buddy_check_lists+0xd6>
            assert(p->property == size);
ffffffffc0200668:	ff876783          	lwu	a5,-8(a4)
ffffffffc020066c:	08c79663          	bne	a5,a2,ffffffffc02006f8 <buddy_check_lists+0xf6>
ffffffffc0200670:	40b687b3          	sub	a5,a3,a1
ffffffffc0200674:	878d                	srai	a5,a5,0x3
ffffffffc0200676:	03d787b3          	mul	a5,a5,t4
ffffffffc020067a:	97f2                	add	a5,a5,t3
            assert(page2ppn(p) % size == 0);
ffffffffc020067c:	0107f7b3          	and	a5,a5,a6
ffffffffc0200680:	efc1                	bnez	a5,ffffffffc0200718 <buddy_check_lists+0x116>
            assert(p >= pages);
ffffffffc0200682:	0ab6eb63          	bltu	a3,a1,ffffffffc0200738 <buddy_check_lists+0x136>
            assert(p + size <= pages + (npage - nbase));
ffffffffc0200686:	969a                	add	a3,a3,t1
ffffffffc0200688:	02d8e863          	bltu	a7,a3,ffffffffc02006b8 <buddy_check_lists+0xb6>
ffffffffc020068c:	6718                	ld	a4,8(a4)

            total += size;
ffffffffc020068e:	9432                	add	s0,s0,a2
        while ((le = list_next(le)) != head) {
ffffffffc0200690:	fca716e3          	bne	a4,a0,ffffffffc020065c <buddy_check_lists+0x5a>
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200694:	2f05                	addiw	t5,t5,1
ffffffffc0200696:	0541                	addi	a0,a0,16
ffffffffc0200698:	fa7f19e3          	bne	t5,t2,ffffffffc020064a <buddy_check_lists+0x48>
        }
    }

    assert(total == buddy_nr_free);
ffffffffc020069c:	00009797          	auipc	a5,0x9
ffffffffc02006a0:	8a47b783          	ld	a5,-1884(a5) # ffffffffc0208f40 <buddy_nr_free>
ffffffffc02006a4:	0c879a63          	bne	a5,s0,ffffffffc0200778 <buddy_check_lists+0x176>
    assert(total == nr_free_pages());
ffffffffc02006a8:	52d000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc02006ac:	0a851663          	bne	a0,s0,ffffffffc0200758 <buddy_check_lists+0x156>
    return total;
}
ffffffffc02006b0:	60a2                	ld	ra,8(sp)
ffffffffc02006b2:	6402                	ld	s0,0(sp)
ffffffffc02006b4:	0141                	addi	sp,sp,16
ffffffffc02006b6:	8082                	ret
            assert(p + size <= pages + (npage - nbase));
ffffffffc02006b8:	00002697          	auipc	a3,0x2
ffffffffc02006bc:	19068693          	addi	a3,a3,400 # ffffffffc0202848 <etext+0x2e0>
ffffffffc02006c0:	00002617          	auipc	a2,0x2
ffffffffc02006c4:	11860613          	addi	a2,a2,280 # ffffffffc02027d8 <etext+0x270>
ffffffffc02006c8:	0e400593          	li	a1,228
ffffffffc02006cc:	00002517          	auipc	a0,0x2
ffffffffc02006d0:	12450513          	addi	a0,a0,292 # ffffffffc02027f0 <etext+0x288>
ffffffffc02006d4:	af3ff0ef          	jal	ra,ffffffffc02001c6 <__panic>
            assert(PageProperty(p));
ffffffffc02006d8:	00002697          	auipc	a3,0x2
ffffffffc02006dc:	0f068693          	addi	a3,a3,240 # ffffffffc02027c8 <etext+0x260>
ffffffffc02006e0:	00002617          	auipc	a2,0x2
ffffffffc02006e4:	0f860613          	addi	a2,a2,248 # ffffffffc02027d8 <etext+0x270>
ffffffffc02006e8:	0e000593          	li	a1,224
ffffffffc02006ec:	00002517          	auipc	a0,0x2
ffffffffc02006f0:	10450513          	addi	a0,a0,260 # ffffffffc02027f0 <etext+0x288>
ffffffffc02006f4:	ad3ff0ef          	jal	ra,ffffffffc02001c6 <__panic>
            assert(p->property == size);
ffffffffc02006f8:	00002697          	auipc	a3,0x2
ffffffffc02006fc:	11068693          	addi	a3,a3,272 # ffffffffc0202808 <etext+0x2a0>
ffffffffc0200700:	00002617          	auipc	a2,0x2
ffffffffc0200704:	0d860613          	addi	a2,a2,216 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200708:	0e100593          	li	a1,225
ffffffffc020070c:	00002517          	auipc	a0,0x2
ffffffffc0200710:	0e450513          	addi	a0,a0,228 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200714:	ab3ff0ef          	jal	ra,ffffffffc02001c6 <__panic>
            assert(page2ppn(p) % size == 0);
ffffffffc0200718:	00002697          	auipc	a3,0x2
ffffffffc020071c:	10868693          	addi	a3,a3,264 # ffffffffc0202820 <etext+0x2b8>
ffffffffc0200720:	00002617          	auipc	a2,0x2
ffffffffc0200724:	0b860613          	addi	a2,a2,184 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200728:	0e200593          	li	a1,226
ffffffffc020072c:	00002517          	auipc	a0,0x2
ffffffffc0200730:	0c450513          	addi	a0,a0,196 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200734:	a93ff0ef          	jal	ra,ffffffffc02001c6 <__panic>
            assert(p >= pages);
ffffffffc0200738:	00002697          	auipc	a3,0x2
ffffffffc020073c:	10068693          	addi	a3,a3,256 # ffffffffc0202838 <etext+0x2d0>
ffffffffc0200740:	00002617          	auipc	a2,0x2
ffffffffc0200744:	09860613          	addi	a2,a2,152 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200748:	0e300593          	li	a1,227
ffffffffc020074c:	00002517          	auipc	a0,0x2
ffffffffc0200750:	0a450513          	addi	a0,a0,164 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200754:	a73ff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200758:	00002697          	auipc	a3,0x2
ffffffffc020075c:	13068693          	addi	a3,a3,304 # ffffffffc0202888 <etext+0x320>
ffffffffc0200760:	00002617          	auipc	a2,0x2
ffffffffc0200764:	07860613          	addi	a2,a2,120 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200768:	0eb00593          	li	a1,235
ffffffffc020076c:	00002517          	auipc	a0,0x2
ffffffffc0200770:	08450513          	addi	a0,a0,132 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200774:	a53ff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(total == buddy_nr_free);
ffffffffc0200778:	00002697          	auipc	a3,0x2
ffffffffc020077c:	0f868693          	addi	a3,a3,248 # ffffffffc0202870 <etext+0x308>
ffffffffc0200780:	00002617          	auipc	a2,0x2
ffffffffc0200784:	05860613          	addi	a2,a2,88 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200788:	0ea00593          	li	a1,234
ffffffffc020078c:	00002517          	auipc	a0,0x2
ffffffffc0200790:	06450513          	addi	a0,a0,100 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200794:	a33ff0ef          	jal	ra,ffffffffc02001c6 <__panic>

ffffffffc0200798 <buddy_init_memmap>:
buddy_init_memmap(struct Page *base, size_t n) {
ffffffffc0200798:	1141                	addi	sp,sp,-16
ffffffffc020079a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020079c:	12058663          	beqz	a1,ffffffffc02008c8 <buddy_init_memmap+0x130>
    struct Page *end = base + n;
ffffffffc02007a0:	00259693          	slli	a3,a1,0x2
ffffffffc02007a4:	96ae                	add	a3,a3,a1
ffffffffc02007a6:	068e                	slli	a3,a3,0x3
ffffffffc02007a8:	96aa                	add	a3,a3,a0
    for (struct Page *p = base; p < end; p++) {
ffffffffc02007aa:	87aa                	mv	a5,a0
ffffffffc02007ac:	00d57f63          	bgeu	a0,a3,ffffffffc02007ca <buddy_init_memmap+0x32>
        assert(PageReserved(p));
ffffffffc02007b0:	6798                	ld	a4,8(a5)
ffffffffc02007b2:	8b05                	andi	a4,a4,1
ffffffffc02007b4:	cb75                	beqz	a4,ffffffffc02008a8 <buddy_init_memmap+0x110>
        p->flags = 0;
ffffffffc02007b6:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc02007ba:	0007a823          	sw	zero,16(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02007be:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p < end; p++) {
ffffffffc02007c2:	02878793          	addi	a5,a5,40
ffffffffc02007c6:	fed7e5e3          	bltu	a5,a3,ffffffffc02007b0 <buddy_init_memmap+0x18>
ffffffffc02007ca:	00008297          	auipc	t0,0x8
ffffffffc02007ce:	77628293          	addi	t0,t0,1910 # ffffffffc0208f40 <buddy_nr_free>
ffffffffc02007d2:	0002b303          	ld	t1,0(t0)
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02007d6:	00008f97          	auipc	t6,0x8
ffffffffc02007da:	77afbf83          	ld	t6,1914(t6) # ffffffffc0208f50 <pages>
ffffffffc02007de:	00003f17          	auipc	t5,0x3
ffffffffc02007e2:	eaaf3f03          	ld	t5,-342(t5) # ffffffffc0203688 <nbase>
ffffffffc02007e6:	00007e17          	auipc	t3,0x7
ffffffffc02007ea:	832e0e13          	addi	t3,t3,-1998 # ffffffffc0207018 <buddy_free_lists>
        while (size * 2 <= remaining &&
ffffffffc02007ee:	4885                	li	a7,1
ffffffffc02007f0:	00003e97          	auipc	t4,0x3
ffffffffc02007f4:	e88ebe83          	ld	t4,-376(t4) # ffffffffc0203678 <error_string+0x38>
        SetPageProperty(p);
ffffffffc02007f8:	651c                	ld	a5,8(a0)
ffffffffc02007fa:	0027e393          	ori	t2,a5,2
        while (size * 2 <= remaining &&
ffffffffc02007fe:	09158563          	beq	a1,a7,ffffffffc0200888 <buddy_init_memmap+0xf0>
ffffffffc0200802:	41f50633          	sub	a2,a0,t6
ffffffffc0200806:	860d                	srai	a2,a2,0x3
ffffffffc0200808:	03d60633          	mul	a2,a2,t4
               size * 2 <= ((size_t)1 << BUDDY_MAX_ORDER) &&
ffffffffc020080c:	4741                	li	a4,16
ffffffffc020080e:	4789                	li	a5,2
ffffffffc0200810:	967a                	add	a2,a2,t5
               page2ppn(p) % (size * 2) == 0) {
ffffffffc0200812:	00167693          	andi	a3,a2,1
               size * 2 <= ((size_t)1 << BUDDY_MAX_ORDER) &&
ffffffffc0200816:	c691                	beqz	a3,ffffffffc0200822 <buddy_init_memmap+0x8a>
ffffffffc0200818:	a041                	j	ffffffffc0200898 <buddy_init_memmap+0x100>
               page2ppn(p) % (size * 2) == 0) {
ffffffffc020081a:	02f67833          	remu	a6,a2,a5
               size * 2 <= ((size_t)1 << BUDDY_MAX_ORDER) &&
ffffffffc020081e:	00081863          	bnez	a6,ffffffffc020082e <buddy_init_memmap+0x96>
            size <<= 1;
ffffffffc0200822:	86be                	mv	a3,a5
        while (size * 2 <= remaining &&
ffffffffc0200824:	0786                	slli	a5,a5,0x1
ffffffffc0200826:	00f5e463          	bltu	a1,a5,ffffffffc020082e <buddy_init_memmap+0x96>
ffffffffc020082a:	377d                	addiw	a4,a4,-1
ffffffffc020082c:	f77d                	bnez	a4,ffffffffc020081a <buddy_init_memmap+0x82>
        p += size;
ffffffffc020082e:	00269813          	slli	a6,a3,0x2
ffffffffc0200832:	9836                	add	a6,a6,a3
        p->property = size;
ffffffffc0200834:	c914                	sw	a3,16(a0)
        SetPageProperty(p);
ffffffffc0200836:	00753423          	sd	t2,8(a0)
        p += size;
ffffffffc020083a:	080e                	slli	a6,a6,0x3
    while (((size_t)1 << order) < size) {
ffffffffc020083c:	04d8f463          	bgeu	a7,a3,ffffffffc0200884 <buddy_init_memmap+0xec>
    int order = 0;
ffffffffc0200840:	4781                	li	a5,0
        order++;
ffffffffc0200842:	2785                	addiw	a5,a5,1
    while (((size_t)1 << order) < size) {
ffffffffc0200844:	00f89733          	sll	a4,a7,a5
ffffffffc0200848:	fed76de3          	bltu	a4,a3,ffffffffc0200842 <buddy_init_memmap+0xaa>
    list_entry_t *head = &buddy_free_lists[order];
ffffffffc020084c:	0792                	slli	a5,a5,0x4
ffffffffc020084e:	00fe0733          	add	a4,t3,a5
    list_entry_t *le = head;
ffffffffc0200852:	87ba                	mv	a5,a4
    while ((le = list_next(le)) != head) {
ffffffffc0200854:	a029                	j	ffffffffc020085e <buddy_init_memmap+0xc6>
        struct Page *page = le2page(le, page_link);
ffffffffc0200856:	fe878613          	addi	a2,a5,-24
        if (base < page) {
ffffffffc020085a:	00c56563          	bltu	a0,a2,ffffffffc0200864 <buddy_init_memmap+0xcc>
ffffffffc020085e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != head) {
ffffffffc0200860:	fee79be3          	bne	a5,a4,ffffffffc0200856 <buddy_init_memmap+0xbe>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200864:	6398                	ld	a4,0(a5)
    list_add_before(le, &(base->page_link));
ffffffffc0200866:	01850613          	addi	a2,a0,24
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc020086a:	e390                	sd	a2,0(a5)
ffffffffc020086c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020086e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200870:	ed18                	sd	a4,24(a0)
        remaining -= size;
ffffffffc0200872:	8d95                	sub	a1,a1,a3
        buddy_nr_free += size;
ffffffffc0200874:	9336                	add	t1,t1,a3
        p += size;
ffffffffc0200876:	9542                	add	a0,a0,a6
    while (remaining > 0) {
ffffffffc0200878:	f1c1                	bnez	a1,ffffffffc02007f8 <buddy_init_memmap+0x60>
}
ffffffffc020087a:	60a2                	ld	ra,8(sp)
ffffffffc020087c:	0062b023          	sd	t1,0(t0)
ffffffffc0200880:	0141                	addi	sp,sp,16
ffffffffc0200882:	8082                	ret
    while (((size_t)1 << order) < size) {
ffffffffc0200884:	8772                	mv	a4,t3
ffffffffc0200886:	b7f1                	j	ffffffffc0200852 <buddy_init_memmap+0xba>
        p->property = size;
ffffffffc0200888:	c90c                	sw	a1,16(a0)
        SetPageProperty(p);
ffffffffc020088a:	00753423          	sd	t2,8(a0)
        size_t size = 1;
ffffffffc020088e:	4685                	li	a3,1
        SetPageProperty(p);
ffffffffc0200890:	8772                	mv	a4,t3
ffffffffc0200892:	02800813          	li	a6,40
ffffffffc0200896:	bf75                	j	ffffffffc0200852 <buddy_init_memmap+0xba>
        p->property = size;
ffffffffc0200898:	01152823          	sw	a7,16(a0)
        SetPageProperty(p);
ffffffffc020089c:	00753423          	sd	t2,8(a0)
ffffffffc02008a0:	8772                	mv	a4,t3
ffffffffc02008a2:	02800813          	li	a6,40
ffffffffc02008a6:	b775                	j	ffffffffc0200852 <buddy_init_memmap+0xba>
        assert(PageReserved(p));
ffffffffc02008a8:	00002697          	auipc	a3,0x2
ffffffffc02008ac:	00068693          	mv	a3,a3
ffffffffc02008b0:	00002617          	auipc	a2,0x2
ffffffffc02008b4:	f2860613          	addi	a2,a2,-216 # ffffffffc02027d8 <etext+0x270>
ffffffffc02008b8:	04900593          	li	a1,73
ffffffffc02008bc:	00002517          	auipc	a0,0x2
ffffffffc02008c0:	f3450513          	addi	a0,a0,-204 # ffffffffc02027f0 <etext+0x288>
ffffffffc02008c4:	903ff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(n > 0);
ffffffffc02008c8:	00002697          	auipc	a3,0x2
ffffffffc02008cc:	00068693          	mv	a3,a3
ffffffffc02008d0:	00002617          	auipc	a2,0x2
ffffffffc02008d4:	f0860613          	addi	a2,a2,-248 # ffffffffc02027d8 <etext+0x270>
ffffffffc02008d8:	04500593          	li	a1,69
ffffffffc02008dc:	00002517          	auipc	a0,0x2
ffffffffc02008e0:	f1450513          	addi	a0,a0,-236 # ffffffffc02027f0 <etext+0x288>
ffffffffc02008e4:	8e3ff0ef          	jal	ra,ffffffffc02001c6 <__panic>

ffffffffc02008e8 <buddy_alloc_pages>:
    assert(n > 0);
ffffffffc02008e8:	c571                	beqz	a0,ffffffffc02009b4 <buddy_alloc_pages+0xcc>
    if (n > buddy_nr_free) {
ffffffffc02008ea:	00008297          	auipc	t0,0x8
ffffffffc02008ee:	65628293          	addi	t0,t0,1622 # ffffffffc0208f40 <buddy_nr_free>
ffffffffc02008f2:	0002bf83          	ld	t6,0(t0)
ffffffffc02008f6:	00afeb63          	bltu	t6,a0,ffffffffc020090c <buddy_alloc_pages+0x24>
    int order = 0;
ffffffffc02008fa:	4581                	li	a1,0
    size_t size = 1;
ffffffffc02008fc:	4885                	li	a7,1
        if (order > BUDDY_MAX_ORDER) {
ffffffffc02008fe:	47c5                	li	a5,17
    while (size < n) {
ffffffffc0200900:	00a8f863          	bgeu	a7,a0,ffffffffc0200910 <buddy_alloc_pages+0x28>
        order++;
ffffffffc0200904:	2585                	addiw	a1,a1,1
        size <<= 1;
ffffffffc0200906:	0886                	slli	a7,a7,0x1
        if (order > BUDDY_MAX_ORDER) {
ffffffffc0200908:	fef59ce3          	bne	a1,a5,ffffffffc0200900 <buddy_alloc_pages+0x18>
        return NULL;
ffffffffc020090c:	4501                	li	a0,0
}
ffffffffc020090e:	8082                	ret
ffffffffc0200910:	00006617          	auipc	a2,0x6
ffffffffc0200914:	70860613          	addi	a2,a2,1800 # ffffffffc0207018 <buddy_free_lists>
ffffffffc0200918:	00459793          	slli	a5,a1,0x4
ffffffffc020091c:	97b2                	add	a5,a5,a2
    return list->next == list;
ffffffffc020091e:	0087b303          	ld	t1,8(a5)
    while (size < n) {
ffffffffc0200922:	882e                	mv	a6,a1
    while (k <= BUDDY_MAX_ORDER &&
ffffffffc0200924:	4745                	li	a4,17
ffffffffc0200926:	00f31a63          	bne	t1,a5,ffffffffc020093a <buddy_alloc_pages+0x52>
        k++;
ffffffffc020092a:	2805                	addiw	a6,a6,1
    while (k <= BUDDY_MAX_ORDER &&
ffffffffc020092c:	07c1                	addi	a5,a5,16
ffffffffc020092e:	fce80fe3          	beq	a6,a4,ffffffffc020090c <buddy_alloc_pages+0x24>
ffffffffc0200932:	0087b303          	ld	t1,8(a5)
ffffffffc0200936:	fef30ae3          	beq	t1,a5,ffffffffc020092a <buddy_alloc_pages+0x42>
    __list_del(listelm->prev, listelm->next);
ffffffffc020093a:	00033683          	ld	a3,0(t1)
ffffffffc020093e:	00833703          	ld	a4,8(t1)
ffffffffc0200942:	fff80793          	addi	a5,a6,-1
ffffffffc0200946:	0792                	slli	a5,a5,0x4
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200948:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020094a:	e314                	sd	a3,0(a4)
    struct Page *block = le2page(le, page_link);
ffffffffc020094c:	fe830513          	addi	a0,t1,-24
    while (k > order) {
ffffffffc0200950:	963e                	add	a2,a2,a5
        struct Page *buddy = block + half;
ffffffffc0200952:	02800f13          	li	t5,40
        size_t half = (size_t)1 << k;
ffffffffc0200956:	4e85                	li	t4,1
    while (k > order) {
ffffffffc0200958:	0505d263          	bge	a1,a6,ffffffffc020099c <buddy_alloc_pages+0xb4>
        k--;
ffffffffc020095c:	387d                	addiw	a6,a6,-1
        struct Page *buddy = block + half;
ffffffffc020095e:	010f1733          	sll	a4,t5,a6
ffffffffc0200962:	972a                	add	a4,a4,a0
        SetPageProperty(buddy);
ffffffffc0200964:	671c                	ld	a5,8(a4)
        size_t half = (size_t)1 << k;
ffffffffc0200966:	010e96b3          	sll	a3,t4,a6
        buddy->property = half;
ffffffffc020096a:	cb14                	sw	a3,16(a4)
        SetPageProperty(buddy);
ffffffffc020096c:	0027e793          	ori	a5,a5,2
ffffffffc0200970:	e71c                	sd	a5,8(a4)
    list_entry_t *le = head;
ffffffffc0200972:	87b2                	mv	a5,a2
    while ((le = list_next(le)) != head) {
ffffffffc0200974:	a029                	j	ffffffffc020097e <buddy_alloc_pages+0x96>
        struct Page *page = le2page(le, page_link);
ffffffffc0200976:	fe878693          	addi	a3,a5,-24
        if (base < page) {
ffffffffc020097a:	00d76563          	bltu	a4,a3,ffffffffc0200984 <buddy_alloc_pages+0x9c>
    return listelm->next;
ffffffffc020097e:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != head) {
ffffffffc0200980:	fec79be3          	bne	a5,a2,ffffffffc0200976 <buddy_alloc_pages+0x8e>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200984:	6394                	ld	a3,0(a5)
    list_add_before(le, &(base->page_link));
ffffffffc0200986:	01870e13          	addi	t3,a4,24
    prev->next = next->prev = elm;
ffffffffc020098a:	01c7b023          	sd	t3,0(a5)
ffffffffc020098e:	01c6b423          	sd	t3,8(a3) # ffffffffc02028d0 <etext+0x368>
    elm->next = next;
ffffffffc0200992:	f31c                	sd	a5,32(a4)
    elm->prev = prev;
ffffffffc0200994:	ef14                	sd	a3,24(a4)
    while (k > order) {
ffffffffc0200996:	1641                	addi	a2,a2,-16
ffffffffc0200998:	fd0592e3          	bne	a1,a6,ffffffffc020095c <buddy_alloc_pages+0x74>
    ClearPageProperty(block);
ffffffffc020099c:	ff033783          	ld	a5,-16(t1)
    buddy_nr_free -= size;
ffffffffc02009a0:	411f8fb3          	sub	t6,t6,a7
    block->property = size;
ffffffffc02009a4:	ff132c23          	sw	a7,-8(t1)
    ClearPageProperty(block);
ffffffffc02009a8:	9bf5                	andi	a5,a5,-3
ffffffffc02009aa:	fef33823          	sd	a5,-16(t1)
    buddy_nr_free -= size;
ffffffffc02009ae:	01f2b023          	sd	t6,0(t0)
    return block;
ffffffffc02009b2:	8082                	ret
buddy_alloc_pages(size_t n) {
ffffffffc02009b4:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02009b6:	00002697          	auipc	a3,0x2
ffffffffc02009ba:	f1268693          	addi	a3,a3,-238 # ffffffffc02028c8 <etext+0x360>
ffffffffc02009be:	00002617          	auipc	a2,0x2
ffffffffc02009c2:	e1a60613          	addi	a2,a2,-486 # ffffffffc02027d8 <etext+0x270>
ffffffffc02009c6:	06800593          	li	a1,104
ffffffffc02009ca:	00002517          	auipc	a0,0x2
ffffffffc02009ce:	e2650513          	addi	a0,a0,-474 # ffffffffc02027f0 <etext+0x288>
buddy_alloc_pages(size_t n) {
ffffffffc02009d2:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02009d4:	ff2ff0ef          	jal	ra,ffffffffc02001c6 <__panic>

ffffffffc02009d8 <buddy_free_pages>:
buddy_free_pages(struct Page *base, size_t n) {
ffffffffc02009d8:	1141                	addi	sp,sp,-16
ffffffffc02009da:	e406                	sd	ra,8(sp)
    assert(base != NULL && n > 0);
ffffffffc02009dc:	24050263          	beqz	a0,ffffffffc0200c20 <buddy_free_pages+0x248>
ffffffffc02009e0:	24058063          	beqz	a1,ffffffffc0200c20 <buddy_free_pages+0x248>
    size_t size = base->property;
ffffffffc02009e4:	01052883          	lw	a7,16(a0)
ffffffffc02009e8:	02089813          	slli	a6,a7,0x20
ffffffffc02009ec:	02085813          	srli	a6,a6,0x20
    assert(size > 0 && (size & (size - 1)) == 0);
ffffffffc02009f0:	26080863          	beqz	a6,ffffffffc0200c60 <buddy_free_pages+0x288>
ffffffffc02009f4:	fff80793          	addi	a5,a6,-1
ffffffffc02009f8:	0107f7b3          	and	a5,a5,a6
ffffffffc02009fc:	26079263          	bnez	a5,ffffffffc0200c60 <buddy_free_pages+0x288>
    assert(n <= size);
ffffffffc0200a00:	24b86063          	bltu	a6,a1,ffffffffc0200c40 <buddy_free_pages+0x268>
    assert(!PageProperty(base));
ffffffffc0200a04:	6518                	ld	a4,8(a0)
ffffffffc0200a06:	00277793          	andi	a5,a4,2
ffffffffc0200a0a:	1e079b63          	bnez	a5,ffffffffc0200c00 <buddy_free_pages+0x228>
    for (struct Page *p = base; p < base + size; p++) {
ffffffffc0200a0e:	00281613          	slli	a2,a6,0x2
ffffffffc0200a12:	9642                	add	a2,a2,a6
ffffffffc0200a14:	060e                	slli	a2,a2,0x3
ffffffffc0200a16:	962a                	add	a2,a2,a0
ffffffffc0200a18:	87aa                	mv	a5,a0
ffffffffc0200a1a:	00c56463          	bltu	a0,a2,ffffffffc0200a22 <buddy_free_pages+0x4a>
ffffffffc0200a1e:	a015                	j	ffffffffc0200a42 <buddy_free_pages+0x6a>
        assert(!PageReserved(p));
ffffffffc0200a20:	6798                	ld	a4,8(a5)
ffffffffc0200a22:	00177693          	andi	a3,a4,1
ffffffffc0200a26:	18069d63          	bnez	a3,ffffffffc0200bc0 <buddy_free_pages+0x1e8>
        assert(!PageProperty(p));
ffffffffc0200a2a:	8b09                	andi	a4,a4,2
ffffffffc0200a2c:	1a071a63          	bnez	a4,ffffffffc0200be0 <buddy_free_pages+0x208>
        p->flags = 0;
ffffffffc0200a30:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200a34:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = base; p < base + size; p++) {
ffffffffc0200a38:	02878793          	addi	a5,a5,40
ffffffffc0200a3c:	fec7e2e3          	bltu	a5,a2,ffffffffc0200a20 <buddy_free_pages+0x48>
    SetPageProperty(base);
ffffffffc0200a40:	6518                	ld	a4,8(a0)
ffffffffc0200a42:	00276713          	ori	a4,a4,2
    base->property = size;
ffffffffc0200a46:	01152823          	sw	a7,16(a0)
    SetPageProperty(base);
ffffffffc0200a4a:	e518                	sd	a4,8(a0)
    while (((size_t)1 << order) < size) {
ffffffffc0200a4c:	4785                	li	a5,1
ffffffffc0200a4e:	16f80363          	beq	a6,a5,ffffffffc0200bb4 <buddy_free_pages+0x1dc>
    int order = 0;
ffffffffc0200a52:	4781                	li	a5,0
    while (((size_t)1 << order) < size) {
ffffffffc0200a54:	4685                	li	a3,1
        order++;
ffffffffc0200a56:	2785                	addiw	a5,a5,1
    while (((size_t)1 << order) < size) {
ffffffffc0200a58:	00f69733          	sll	a4,a3,a5
ffffffffc0200a5c:	ff076de3          	bltu	a4,a6,ffffffffc0200a56 <buddy_free_pages+0x7e>
    list_entry_t *head = &buddy_free_lists[order];
ffffffffc0200a60:	00006617          	auipc	a2,0x6
ffffffffc0200a64:	5b860613          	addi	a2,a2,1464 # ffffffffc0207018 <buddy_free_lists>
ffffffffc0200a68:	0792                	slli	a5,a5,0x4
ffffffffc0200a6a:	00f60733          	add	a4,a2,a5
    list_entry_t *le = head;
ffffffffc0200a6e:	87ba                	mv	a5,a4
    while ((le = list_next(le)) != head) {
ffffffffc0200a70:	a029                	j	ffffffffc0200a7a <buddy_free_pages+0xa2>
        struct Page *page = le2page(le, page_link);
ffffffffc0200a72:	fe878693          	addi	a3,a5,-24
        if (base < page) {
ffffffffc0200a76:	00d56563          	bltu	a0,a3,ffffffffc0200a80 <buddy_free_pages+0xa8>
    return listelm->next;
ffffffffc0200a7a:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != head) {
ffffffffc0200a7c:	fee79be3          	bne	a5,a4,ffffffffc0200a72 <buddy_free_pages+0x9a>
    buddy_nr_free += size;
ffffffffc0200a80:	00008697          	auipc	a3,0x8
ffffffffc0200a84:	4c068693          	addi	a3,a3,1216 # ffffffffc0208f40 <buddy_nr_free>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200a88:	638c                	ld	a1,0(a5)
ffffffffc0200a8a:	6298                	ld	a4,0(a3)
    list_add_before(le, &(base->page_link));
ffffffffc0200a8c:	01850893          	addi	a7,a0,24
    prev->next = next->prev = elm;
ffffffffc0200a90:	0117b023          	sd	a7,0(a5)
ffffffffc0200a94:	0115b423          	sd	a7,8(a1)
    buddy_nr_free += size;
ffffffffc0200a98:	9742                	add	a4,a4,a6
    elm->next = next;
ffffffffc0200a9a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200a9c:	ed0c                	sd	a1,24(a0)
ffffffffc0200a9e:	e298                	sd	a4,0(a3)
    while (((size_t)1 << order) < size) {
ffffffffc0200aa0:	4785                	li	a5,1
    int order = 0;
ffffffffc0200aa2:	4881                	li	a7,0
    while (((size_t)1 << order) < size) {
ffffffffc0200aa4:	00f80b63          	beq	a6,a5,ffffffffc0200aba <buddy_free_pages+0xe2>
ffffffffc0200aa8:	4705                	li	a4,1
        order++;
ffffffffc0200aaa:	2885                	addiw	a7,a7,1
    while (((size_t)1 << order) < size) {
ffffffffc0200aac:	011717b3          	sll	a5,a4,a7
ffffffffc0200ab0:	ff07ede3          	bltu	a5,a6,ffffffffc0200aaa <buddy_free_pages+0xd2>
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200ab4:	47bd                	li	a5,15
ffffffffc0200ab6:	0f17cc63          	blt	a5,a7,ffffffffc0200bae <buddy_free_pages+0x1d6>
ffffffffc0200aba:	0018879b          	addiw	a5,a7,1
ffffffffc0200abe:	0792                	slli	a5,a5,0x4
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200ac0:	00008e17          	auipc	t3,0x8
ffffffffc0200ac4:	490e3e03          	ld	t3,1168(t3) # ffffffffc0208f50 <pages>
ffffffffc0200ac8:	963e                	add	a2,a2,a5
ffffffffc0200aca:	41c507b3          	sub	a5,a0,t3
ffffffffc0200ace:	00003e97          	auipc	t4,0x3
ffffffffc0200ad2:	baaebe83          	ld	t4,-1110(t4) # ffffffffc0203678 <error_string+0x38>
ffffffffc0200ad6:	878d                	srai	a5,a5,0x3
ffffffffc0200ad8:	03d787b3          	mul	a5,a5,t4
ffffffffc0200adc:	00003317          	auipc	t1,0x3
ffffffffc0200ae0:	bac33303          	ld	t1,-1108(t1) # ffffffffc0203688 <nbase>
ffffffffc0200ae4:	85c2                	mv	a1,a6
    if (ppn % (size << 1) == 0) {
ffffffffc0200ae6:	0806                	slli	a6,a6,0x1
    if (partner_ppn < nbase || partner_ppn >= npage) {
ffffffffc0200ae8:	00008f97          	auipc	t6,0x8
ffffffffc0200aec:	460fbf83          	ld	t6,1120(t6) # ffffffffc0208f48 <npage>
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200af0:	4f41                	li	t5,16
ffffffffc0200af2:	979a                	add	a5,a5,t1
    if (ppn % (size << 1) == 0) {
ffffffffc0200af4:	0307f733          	remu	a4,a5,a6
ffffffffc0200af8:	e755                	bnez	a4,ffffffffc0200ba4 <buddy_free_pages+0x1cc>
        partner_ppn = ppn + size;
ffffffffc0200afa:	97ae                	add	a5,a5,a1
    if (partner_ppn < nbase || partner_ppn >= npage) {
ffffffffc0200afc:	0a67e963          	bltu	a5,t1,ffffffffc0200bae <buddy_free_pages+0x1d6>
ffffffffc0200b00:	0bf7f763          	bgeu	a5,t6,ffffffffc0200bae <buddy_free_pages+0x1d6>
    return &pages[partner_ppn - nbase];
ffffffffc0200b04:	40678733          	sub	a4,a5,t1
ffffffffc0200b08:	00271793          	slli	a5,a4,0x2
ffffffffc0200b0c:	97ba                	add	a5,a5,a4
ffffffffc0200b0e:	078e                	slli	a5,a5,0x3
ffffffffc0200b10:	97f2                	add	a5,a5,t3
        if (buddy == NULL ||
ffffffffc0200b12:	cfd1                	beqz	a5,ffffffffc0200bae <buddy_free_pages+0x1d6>
            !PageProperty(buddy) ||
ffffffffc0200b14:	6798                	ld	a4,8(a5)
ffffffffc0200b16:	8b09                	andi	a4,a4,2
        if (buddy == NULL ||
ffffffffc0200b18:	cb59                	beqz	a4,ffffffffc0200bae <buddy_free_pages+0x1d6>
            buddy->property != size) {
ffffffffc0200b1a:	0107e703          	lwu	a4,16(a5)
            !PageProperty(buddy) ||
ffffffffc0200b1e:	08b71863          	bne	a4,a1,ffffffffc0200bae <buddy_free_pages+0x1d6>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b22:	01853283          	ld	t0,24(a0)
ffffffffc0200b26:	7118                	ld	a4,32(a0)
        struct Page *merged = (base < buddy) ? base : buddy;
ffffffffc0200b28:	86be                	mv	a3,a5
    prev->next = next;
ffffffffc0200b2a:	00e2b423          	sd	a4,8(t0)
    next->prev = prev;
ffffffffc0200b2e:	00573023          	sd	t0,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200b32:	0187b283          	ld	t0,24(a5)
ffffffffc0200b36:	7398                	ld	a4,32(a5)
    prev->next = next;
ffffffffc0200b38:	00e2b423          	sd	a4,8(t0)
    next->prev = prev;
ffffffffc0200b3c:	00573023          	sd	t0,0(a4)
ffffffffc0200b40:	00f57363          	bgeu	a0,a5,ffffffffc0200b46 <buddy_free_pages+0x16e>
ffffffffc0200b44:	86aa                	mv	a3,a0
        struct Page *other = (base < buddy) ? buddy : base;
ffffffffc0200b46:	00a7f363          	bgeu	a5,a0,ffffffffc0200b4c <buddy_free_pages+0x174>
ffffffffc0200b4a:	87aa                	mv	a5,a0
        ClearPageProperty(other);
ffffffffc0200b4c:	6798                	ld	a4,8(a5)
        other->property = 0;
ffffffffc0200b4e:	0007a823          	sw	zero,16(a5)
        merged->property = size << 1;
ffffffffc0200b52:	0015959b          	slliw	a1,a1,0x1
        ClearPageProperty(other);
ffffffffc0200b56:	9b75                	andi	a4,a4,-3
ffffffffc0200b58:	e798                	sd	a4,8(a5)
        SetPageProperty(merged);
ffffffffc0200b5a:	669c                	ld	a5,8(a3)
        merged->property = size << 1;
ffffffffc0200b5c:	ca8c                	sw	a1,16(a3)
        order++;
ffffffffc0200b5e:	2885                	addiw	a7,a7,1
        SetPageProperty(merged);
ffffffffc0200b60:	0027e793          	ori	a5,a5,2
ffffffffc0200b64:	e69c                	sd	a5,8(a3)
    list_entry_t *le = head;
ffffffffc0200b66:	87b2                	mv	a5,a2
    while ((le = list_next(le)) != head) {
ffffffffc0200b68:	a029                	j	ffffffffc0200b72 <buddy_free_pages+0x19a>
        struct Page *page = le2page(le, page_link);
ffffffffc0200b6a:	fe878713          	addi	a4,a5,-24
        if (base < page) {
ffffffffc0200b6e:	00e6e563          	bltu	a3,a4,ffffffffc0200b78 <buddy_free_pages+0x1a0>
    return listelm->next;
ffffffffc0200b72:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != head) {
ffffffffc0200b74:	fec79be3          	bne	a5,a2,ffffffffc0200b6a <buddy_free_pages+0x192>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200b78:	6398                	ld	a4,0(a5)
    list_add_before(le, &(base->page_link));
ffffffffc0200b7a:	01868593          	addi	a1,a3,24
    prev->next = next->prev = elm;
ffffffffc0200b7e:	e38c                	sd	a1,0(a5)
ffffffffc0200b80:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200b82:	f29c                	sd	a5,32(a3)
    elm->prev = prev;
ffffffffc0200b84:	ee98                	sd	a4,24(a3)
    while (order < BUDDY_MAX_ORDER) {
ffffffffc0200b86:	0641                	addi	a2,a2,16
ffffffffc0200b88:	03e88363          	beq	a7,t5,ffffffffc0200bae <buddy_free_pages+0x1d6>
ffffffffc0200b8c:	8536                	mv	a0,a3
ffffffffc0200b8e:	41c507b3          	sub	a5,a0,t3
ffffffffc0200b92:	878d                	srai	a5,a5,0x3
ffffffffc0200b94:	03d787b3          	mul	a5,a5,t4
ffffffffc0200b98:	85c2                	mv	a1,a6
    if (ppn % (size << 1) == 0) {
ffffffffc0200b9a:	0806                	slli	a6,a6,0x1
ffffffffc0200b9c:	979a                	add	a5,a5,t1
ffffffffc0200b9e:	0307f733          	remu	a4,a5,a6
ffffffffc0200ba2:	df21                	beqz	a4,ffffffffc0200afa <buddy_free_pages+0x122>
        if (ppn < size) {
ffffffffc0200ba4:	00b7e563          	bltu	a5,a1,ffffffffc0200bae <buddy_free_pages+0x1d6>
        partner_ppn = ppn - size;
ffffffffc0200ba8:	8f8d                	sub	a5,a5,a1
    if (partner_ppn < nbase || partner_ppn >= npage) {
ffffffffc0200baa:	f467fbe3          	bgeu	a5,t1,ffffffffc0200b00 <buddy_free_pages+0x128>
}
ffffffffc0200bae:	60a2                	ld	ra,8(sp)
ffffffffc0200bb0:	0141                	addi	sp,sp,16
ffffffffc0200bb2:	8082                	ret
    while (((size_t)1 << order) < size) {
ffffffffc0200bb4:	00006617          	auipc	a2,0x6
ffffffffc0200bb8:	46460613          	addi	a2,a2,1124 # ffffffffc0207018 <buddy_free_lists>
ffffffffc0200bbc:	8732                	mv	a4,a2
ffffffffc0200bbe:	bd45                	j	ffffffffc0200a6e <buddy_free_pages+0x96>
        assert(!PageReserved(p));
ffffffffc0200bc0:	00002697          	auipc	a3,0x2
ffffffffc0200bc4:	d6068693          	addi	a3,a3,-672 # ffffffffc0202920 <etext+0x3b8>
ffffffffc0200bc8:	00002617          	auipc	a2,0x2
ffffffffc0200bcc:	c1060613          	addi	a2,a2,-1008 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200bd0:	0a400593          	li	a1,164
ffffffffc0200bd4:	00002517          	auipc	a0,0x2
ffffffffc0200bd8:	c1c50513          	addi	a0,a0,-996 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200bdc:	deaff0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert(!PageProperty(p));
ffffffffc0200be0:	00002697          	auipc	a3,0x2
ffffffffc0200be4:	d5868693          	addi	a3,a3,-680 # ffffffffc0202938 <etext+0x3d0>
ffffffffc0200be8:	00002617          	auipc	a2,0x2
ffffffffc0200bec:	bf060613          	addi	a2,a2,-1040 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200bf0:	0a500593          	li	a1,165
ffffffffc0200bf4:	00002517          	auipc	a0,0x2
ffffffffc0200bf8:	bfc50513          	addi	a0,a0,-1028 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200bfc:	dcaff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(!PageProperty(base));
ffffffffc0200c00:	00002697          	auipc	a3,0x2
ffffffffc0200c04:	d0868693          	addi	a3,a3,-760 # ffffffffc0202908 <etext+0x3a0>
ffffffffc0200c08:	00002617          	auipc	a2,0x2
ffffffffc0200c0c:	bd060613          	addi	a2,a2,-1072 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200c10:	0a100593          	li	a1,161
ffffffffc0200c14:	00002517          	auipc	a0,0x2
ffffffffc0200c18:	bdc50513          	addi	a0,a0,-1060 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200c1c:	daaff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(base != NULL && n > 0);
ffffffffc0200c20:	00002697          	auipc	a3,0x2
ffffffffc0200c24:	c9868693          	addi	a3,a3,-872 # ffffffffc02028b8 <etext+0x350>
ffffffffc0200c28:	00002617          	auipc	a2,0x2
ffffffffc0200c2c:	bb060613          	addi	a2,a2,-1104 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200c30:	09c00593          	li	a1,156
ffffffffc0200c34:	00002517          	auipc	a0,0x2
ffffffffc0200c38:	bbc50513          	addi	a0,a0,-1092 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200c3c:	d8aff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(n <= size);
ffffffffc0200c40:	00002697          	auipc	a3,0x2
ffffffffc0200c44:	cb868693          	addi	a3,a3,-840 # ffffffffc02028f8 <etext+0x390>
ffffffffc0200c48:	00002617          	auipc	a2,0x2
ffffffffc0200c4c:	b9060613          	addi	a2,a2,-1136 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200c50:	0a000593          	li	a1,160
ffffffffc0200c54:	00002517          	auipc	a0,0x2
ffffffffc0200c58:	b9c50513          	addi	a0,a0,-1124 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200c5c:	d6aff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(size > 0 && (size & (size - 1)) == 0);
ffffffffc0200c60:	00002697          	auipc	a3,0x2
ffffffffc0200c64:	c7068693          	addi	a3,a3,-912 # ffffffffc02028d0 <etext+0x368>
ffffffffc0200c68:	00002617          	auipc	a2,0x2
ffffffffc0200c6c:	b7060613          	addi	a2,a2,-1168 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200c70:	09f00593          	li	a1,159
ffffffffc0200c74:	00002517          	auipc	a0,0x2
ffffffffc0200c78:	b7c50513          	addi	a0,a0,-1156 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200c7c:	d4aff0ef          	jal	ra,ffffffffc02001c6 <__panic>

ffffffffc0200c80 <buddy_check>:
        buddy_check_lists();
    }
}

static void
buddy_check(void) {
ffffffffc0200c80:	715d                	addi	sp,sp,-80
ffffffffc0200c82:	e486                	sd	ra,72(sp)
ffffffffc0200c84:	e0a2                	sd	s0,64(sp)
ffffffffc0200c86:	fc26                	sd	s1,56(sp)
ffffffffc0200c88:	ec56                	sd	s5,24(sp)
ffffffffc0200c8a:	f84a                	sd	s2,48(sp)
ffffffffc0200c8c:	f44e                	sd	s3,40(sp)
ffffffffc0200c8e:	f052                	sd	s4,32(sp)
ffffffffc0200c90:	e85a                	sd	s6,16(sp)
ffffffffc0200c92:	e45e                	sd	s7,8(sp)
ffffffffc0200c94:	e062                	sd	s8,0(sp)
    size_t initial = buddy_check_lists();
ffffffffc0200c96:	96dff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>

    cprintf("buddy_check: begin, free pages = %lu\n",
ffffffffc0200c9a:	85aa                	mv	a1,a0
    size_t initial = buddy_check_lists();
ffffffffc0200c9c:	842a                	mv	s0,a0
    cprintf("buddy_check: begin, free pages = %lu\n",
ffffffffc0200c9e:	00002517          	auipc	a0,0x2
ffffffffc0200ca2:	cb250513          	addi	a0,a0,-846 # ffffffffc0202950 <etext+0x3e8>
ffffffffc0200ca6:	caaff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    size_t before = buddy_check_lists();
ffffffffc0200caa:	959ff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
ffffffffc0200cae:	00006497          	auipc	s1,0x6
ffffffffc0200cb2:	36a48493          	addi	s1,s1,874 # ffffffffc0207018 <buddy_free_lists>
ffffffffc0200cb6:	8aaa                	mv	s5,a0
        if (size < min_size) {
ffffffffc0200cb8:	00006697          	auipc	a3,0x6
ffffffffc0200cbc:	46068693          	addi	a3,a3,1120 # ffffffffc0207118 <buddy_free_lists+0x100>
    size_t before = buddy_check_lists();
ffffffffc0200cc0:	87a6                	mv	a5,s1
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200cc2:	54d78d63          	beq	a5,a3,ffffffffc020121c <buddy_check+0x59c>
    return list->next == list;
ffffffffc0200cc6:	6f98                	ld	a4,24(a5)
        if (!list_empty(head)) {
ffffffffc0200cc8:	07c1                	addi	a5,a5,16
ffffffffc0200cca:	fef70ce3          	beq	a4,a5,ffffffffc0200cc2 <buddy_check+0x42>
    size_t big_size = big->property;
ffffffffc0200cce:	ff876a03          	lwu	s4,-8(a4)
    buddy_nr_free -= big_size;
ffffffffc0200cd2:	00008617          	auipc	a2,0x8
ffffffffc0200cd6:	26e60613          	addi	a2,a2,622 # ffffffffc0208f40 <buddy_nr_free>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200cda:	6308                	ld	a0,0(a4)
ffffffffc0200cdc:	670c                	ld	a1,8(a4)
ffffffffc0200cde:	621c                	ld	a5,0(a2)
    size_t half = big_size >> 1;
ffffffffc0200ce0:	001a5b13          	srli	s6,s4,0x1
    for (struct Page *p = big; p < big + big_size; p++) {
ffffffffc0200ce4:	002a1693          	slli	a3,s4,0x2
    struct Page *other = big + half;
ffffffffc0200ce8:	002b1913          	slli	s2,s6,0x2
    for (struct Page *p = big; p < big + big_size; p++) {
ffffffffc0200cec:	96d2                	add	a3,a3,s4
            return le2page(list_next(head), page_link);
ffffffffc0200cee:	fe870993          	addi	s3,a4,-24
    buddy_nr_free -= big_size;
ffffffffc0200cf2:	414787b3          	sub	a5,a5,s4
    struct Page *other = big + half;
ffffffffc0200cf6:	995a                	add	s2,s2,s6
    prev->next = next;
ffffffffc0200cf8:	e50c                	sd	a1,8(a0)
    for (struct Page *p = big; p < big + big_size; p++) {
ffffffffc0200cfa:	068e                	slli	a3,a3,0x3
    struct Page *other = big + half;
ffffffffc0200cfc:	090e                	slli	s2,s2,0x3
    buddy_nr_free -= big_size;
ffffffffc0200cfe:	e21c                	sd	a5,0(a2)
    next->prev = prev;
ffffffffc0200d00:	e188                	sd	a0,0(a1)
    for (struct Page *p = big; p < big + big_size; p++) {
ffffffffc0200d02:	96ce                	add	a3,a3,s3
    struct Page *other = big + half;
ffffffffc0200d04:	994e                	add	s2,s2,s3
    for (struct Page *p = big; p < big + big_size; p++) {
ffffffffc0200d06:	87ce                	mv	a5,s3
ffffffffc0200d08:	00d9fc63          	bgeu	s3,a3,ffffffffc0200d20 <buddy_check+0xa0>
        p->flags = 0;
ffffffffc0200d0c:	0007b423          	sd	zero,8(a5)
        p->property = 0;
ffffffffc0200d10:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d14:	0007a023          	sw	zero,0(a5)
    for (struct Page *p = big; p < big + big_size; p++) {
ffffffffc0200d18:	02878793          	addi	a5,a5,40
ffffffffc0200d1c:	fed7e8e3          	bltu	a5,a3,ffffffffc0200d0c <buddy_check+0x8c>
    big->property = half;
ffffffffc0200d20:	000b079b          	sext.w	a5,s6
ffffffffc0200d24:	fef72c23          	sw	a5,-8(a4)
    other->property = half;
ffffffffc0200d28:	00f92823          	sw	a5,16(s2)
    free_pages(big, half);
ffffffffc0200d2c:	85da                	mv	a1,s6
ffffffffc0200d2e:	854e                	mv	a0,s3
ffffffffc0200d30:	698000ef          	jal	ra,ffffffffc02013c8 <free_pages>
    assert(nr_free_pages() == before - half);
ffffffffc0200d34:	6a0000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200d38:	416a87b3          	sub	a5,s5,s6
ffffffffc0200d3c:	4cf51063          	bne	a0,a5,ffffffffc02011fc <buddy_check+0x57c>
    free_pages(other, half);
ffffffffc0200d40:	85da                	mv	a1,s6
ffffffffc0200d42:	854a                	mv	a0,s2
ffffffffc0200d44:	684000ef          	jal	ra,ffffffffc02013c8 <free_pages>
    assert(nr_free_pages() == before);
ffffffffc0200d48:	68c000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200d4c:	00006817          	auipc	a6,0x6
ffffffffc0200d50:	3dc80813          	addi	a6,a6,988 # ffffffffc0207128 <slub_slabs>
ffffffffc0200d54:	00006597          	auipc	a1,0x6
ffffffffc0200d58:	2c458593          	addi	a1,a1,708 # ffffffffc0207018 <buddy_free_lists>
ffffffffc0200d5c:	54aa9063          	bne	s5,a0,ffffffffc020129c <buddy_check+0x61c>
    return listelm->next;
ffffffffc0200d60:	659c                	ld	a5,8(a1)
        while ((le = list_next(le)) != head) {
ffffffffc0200d62:	02f58263          	beq	a1,a5,ffffffffc0200d86 <buddy_check+0x106>
            struct Page *block = le2page(le, page_link);
ffffffffc0200d66:	fe878693          	addi	a3,a5,-24
            if (page >= block && page < block + block->property) {
ffffffffc0200d6a:	00d9eb63          	bltu	s3,a3,ffffffffc0200d80 <buddy_check+0x100>
ffffffffc0200d6e:	ff87e603          	lwu	a2,-8(a5)
ffffffffc0200d72:	00261713          	slli	a4,a2,0x2
ffffffffc0200d76:	9732                	add	a4,a4,a2
ffffffffc0200d78:	070e                	slli	a4,a4,0x3
ffffffffc0200d7a:	9736                	add	a4,a4,a3
ffffffffc0200d7c:	00e9e963          	bltu	s3,a4,ffffffffc0200d8e <buddy_check+0x10e>
ffffffffc0200d80:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != head) {
ffffffffc0200d82:	feb792e3          	bne	a5,a1,ffffffffc0200d66 <buddy_check+0xe6>
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200d86:	05c1                	addi	a1,a1,16
ffffffffc0200d88:	fcb81ce3          	bne	a6,a1,ffffffffc0200d60 <buddy_check+0xe0>
    return NULL;
ffffffffc0200d8c:	4681                	li	a3,0
ffffffffc0200d8e:	00006517          	auipc	a0,0x6
ffffffffc0200d92:	28a50513          	addi	a0,a0,650 # ffffffffc0207018 <buddy_free_lists>
ffffffffc0200d96:	651c                	ld	a5,8(a0)
        while ((le = list_next(le)) != head) {
ffffffffc0200d98:	02f50263          	beq	a0,a5,ffffffffc0200dbc <buddy_check+0x13c>
            struct Page *block = le2page(le, page_link);
ffffffffc0200d9c:	fe878613          	addi	a2,a5,-24
            if (page >= block && page < block + block->property) {
ffffffffc0200da0:	00c96b63          	bltu	s2,a2,ffffffffc0200db6 <buddy_check+0x136>
ffffffffc0200da4:	ff87e583          	lwu	a1,-8(a5)
ffffffffc0200da8:	00259713          	slli	a4,a1,0x2
ffffffffc0200dac:	972e                	add	a4,a4,a1
ffffffffc0200dae:	070e                	slli	a4,a4,0x3
ffffffffc0200db0:	9732                	add	a4,a4,a2
ffffffffc0200db2:	02e96a63          	bltu	s2,a4,ffffffffc0200de6 <buddy_check+0x166>
ffffffffc0200db6:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != head) {
ffffffffc0200db8:	fea792e3          	bne	a5,a0,ffffffffc0200d9c <buddy_check+0x11c>
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200dbc:	0541                	addi	a0,a0,16
ffffffffc0200dbe:	fca81ce3          	bne	a6,a0,ffffffffc0200d96 <buddy_check+0x116>
    assert(head1 != NULL);
ffffffffc0200dc2:	50069d63          	bnez	a3,ffffffffc02012dc <buddy_check+0x65c>
ffffffffc0200dc6:	00002697          	auipc	a3,0x2
ffffffffc0200dca:	bfa68693          	addi	a3,a3,-1030 # ffffffffc02029c0 <etext+0x458>
ffffffffc0200dce:	00002617          	auipc	a2,0x2
ffffffffc0200dd2:	a0a60613          	addi	a2,a2,-1526 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200dd6:	17d00593          	li	a1,381
ffffffffc0200dda:	00002517          	auipc	a0,0x2
ffffffffc0200dde:	a1650513          	addi	a0,a0,-1514 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200de2:	be4ff0ef          	jal	ra,ffffffffc02001c6 <__panic>
ffffffffc0200de6:	d2e5                	beqz	a3,ffffffffc0200dc6 <buddy_check+0x146>
    assert(head1 == head2);
ffffffffc0200de8:	4ed61a63          	bne	a2,a3,ffffffffc02012dc <buddy_check+0x65c>
    assert(head1->property >= (half << 1));
ffffffffc0200dec:	0106e783          	lwu	a5,16(a3)
ffffffffc0200df0:	ffea7a13          	andi	s4,s4,-2
ffffffffc0200df4:	4d47e463          	bltu	a5,s4,ffffffffc02012bc <buddy_check+0x63c>
    buddy_check_lists();
ffffffffc0200df8:	80bff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
    size_t before = buddy_check_lists();
ffffffffc0200dfc:	807ff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
ffffffffc0200e00:	892a                	mv	s2,a0
    struct Page *p0 = alloc_pages(3);
ffffffffc0200e02:	450d                	li	a0,3
ffffffffc0200e04:	5b8000ef          	jal	ra,ffffffffc02013bc <alloc_pages>
ffffffffc0200e08:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200e0a:	38050963          	beqz	a0,ffffffffc020119c <buddy_check+0x51c>
    assert(p0->property == 4);
ffffffffc0200e0e:	4918                	lw	a4,16(a0)
ffffffffc0200e10:	4791                	li	a5,4
ffffffffc0200e12:	36f71563          	bne	a4,a5,ffffffffc020117c <buddy_check+0x4fc>
    assert(!PageProperty(p0));
ffffffffc0200e16:	651c                	ld	a5,8(a0)
ffffffffc0200e18:	8b89                	andi	a5,a5,2
ffffffffc0200e1a:	34079163          	bnez	a5,ffffffffc020115c <buddy_check+0x4dc>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e1e:	00008b17          	auipc	s6,0x8
ffffffffc0200e22:	132b0b13          	addi	s6,s6,306 # ffffffffc0208f50 <pages>
ffffffffc0200e26:	000b3783          	ld	a5,0(s6)
ffffffffc0200e2a:	00003a97          	auipc	s5,0x3
ffffffffc0200e2e:	84eaba83          	ld	s5,-1970(s5) # ffffffffc0203678 <error_string+0x38>
ffffffffc0200e32:	00003a17          	auipc	s4,0x3
ffffffffc0200e36:	856a3a03          	ld	s4,-1962(s4) # ffffffffc0203688 <nbase>
ffffffffc0200e3a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e3e:	878d                	srai	a5,a5,0x3
ffffffffc0200e40:	035787b3          	mul	a5,a5,s5
ffffffffc0200e44:	97d2                	add	a5,a5,s4
    assert(page2ppn(p0) % 4 == 0);
ffffffffc0200e46:	8b8d                	andi	a5,a5,3
ffffffffc0200e48:	2e079a63          	bnez	a5,ffffffffc020113c <buddy_check+0x4bc>
    for (struct Page *p = p0; p < p0 + 4; p++) {
ffffffffc0200e4c:	0a050c13          	addi	s8,a0,160
ffffffffc0200e50:	87aa                	mv	a5,a0
ffffffffc0200e52:	02878793          	addi	a5,a5,40
ffffffffc0200e56:	02fc0563          	beq	s8,a5,ffffffffc0200e80 <buddy_check+0x200>
        assert(!PageProperty(p));
ffffffffc0200e5a:	6798                	ld	a4,8(a5)
ffffffffc0200e5c:	8b09                	andi	a4,a4,2
ffffffffc0200e5e:	db75                	beqz	a4,ffffffffc0200e52 <buddy_check+0x1d2>
ffffffffc0200e60:	00002697          	auipc	a3,0x2
ffffffffc0200e64:	ad868693          	addi	a3,a3,-1320 # ffffffffc0202938 <etext+0x3d0>
ffffffffc0200e68:	00002617          	auipc	a2,0x2
ffffffffc0200e6c:	97060613          	addi	a2,a2,-1680 # ffffffffc02027d8 <etext+0x270>
ffffffffc0200e70:	11d00593          	li	a1,285
ffffffffc0200e74:	00002517          	auipc	a0,0x2
ffffffffc0200e78:	97c50513          	addi	a0,a0,-1668 # ffffffffc02027f0 <etext+0x288>
ffffffffc0200e7c:	b4aff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before - 4);
ffffffffc0200e80:	554000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200e84:	ffc90793          	addi	a5,s2,-4
ffffffffc0200e88:	28f51a63          	bne	a0,a5,ffffffffc020111c <buddy_check+0x49c>
    struct Page *p1 = alloc_pages(1);
ffffffffc0200e8c:	4505                	li	a0,1
ffffffffc0200e8e:	52e000ef          	jal	ra,ffffffffc02013bc <alloc_pages>
ffffffffc0200e92:	8baa                	mv	s7,a0
    assert(p1 != NULL);
ffffffffc0200e94:	26050463          	beqz	a0,ffffffffc02010fc <buddy_check+0x47c>
    assert(p1->property == 1);
ffffffffc0200e98:	4918                	lw	a4,16(a0)
ffffffffc0200e9a:	4785                	li	a5,1
ffffffffc0200e9c:	24f71063          	bne	a4,a5,ffffffffc02010dc <buddy_check+0x45c>
    assert(!PageProperty(p1));
ffffffffc0200ea0:	651c                	ld	a5,8(a0)
ffffffffc0200ea2:	8b89                	andi	a5,a5,2
ffffffffc0200ea4:	20079c63          	bnez	a5,ffffffffc02010bc <buddy_check+0x43c>
    assert(p0 + 4 <= p1 || p1 + 1 <= p0);
ffffffffc0200ea8:	01857663          	bgeu	a0,s8,ffffffffc0200eb4 <buddy_check+0x234>
ffffffffc0200eac:	02850793          	addi	a5,a0,40
ffffffffc0200eb0:	1ef9e663          	bltu	s3,a5,ffffffffc020109c <buddy_check+0x41c>
    assert(nr_free_pages() == before - 5);
ffffffffc0200eb4:	520000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200eb8:	ffb90793          	addi	a5,s2,-5
ffffffffc0200ebc:	1cf51063          	bne	a0,a5,ffffffffc020107c <buddy_check+0x3fc>
    free_pages(p0, 3);
ffffffffc0200ec0:	458d                	li	a1,3
ffffffffc0200ec2:	854e                	mv	a0,s3
ffffffffc0200ec4:	504000ef          	jal	ra,ffffffffc02013c8 <free_pages>
    free_pages(p1, 1);
ffffffffc0200ec8:	4585                	li	a1,1
ffffffffc0200eca:	855e                	mv	a0,s7
ffffffffc0200ecc:	4fc000ef          	jal	ra,ffffffffc02013c8 <free_pages>
    assert(nr_free_pages() == before);
ffffffffc0200ed0:	504000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200ed4:	18a91463          	bne	s2,a0,ffffffffc020105c <buddy_check+0x3dc>
    buddy_check_lists();
ffffffffc0200ed8:	f2aff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
    size_t before = buddy_check_lists();
ffffffffc0200edc:	f26ff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
ffffffffc0200ee0:	892a                	mv	s2,a0
    struct Page *p = alloc_pages(5);
ffffffffc0200ee2:	4515                	li	a0,5
ffffffffc0200ee4:	4d8000ef          	jal	ra,ffffffffc02013bc <alloc_pages>
ffffffffc0200ee8:	89aa                	mv	s3,a0
    assert(p != NULL);
ffffffffc0200eea:	2e050963          	beqz	a0,ffffffffc02011dc <buddy_check+0x55c>
    assert(p->property == 8);
ffffffffc0200eee:	4918                	lw	a4,16(a0)
ffffffffc0200ef0:	47a1                	li	a5,8
ffffffffc0200ef2:	2cf71563          	bne	a4,a5,ffffffffc02011bc <buddy_check+0x53c>
ffffffffc0200ef6:	000b3783          	ld	a5,0(s6)
ffffffffc0200efa:	40f507b3          	sub	a5,a0,a5
ffffffffc0200efe:	878d                	srai	a5,a5,0x3
ffffffffc0200f00:	035787b3          	mul	a5,a5,s5
ffffffffc0200f04:	97d2                	add	a5,a5,s4
    assert(page2ppn(p) % 8 == 0);
ffffffffc0200f06:	8b9d                	andi	a5,a5,7
ffffffffc0200f08:	34079a63          	bnez	a5,ffffffffc020125c <buddy_check+0x5dc>
    assert(nr_free_pages() == before - 8);
ffffffffc0200f0c:	4c8000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200f10:	ff890793          	addi	a5,s2,-8
ffffffffc0200f14:	32f51463          	bne	a0,a5,ffffffffc020123c <buddy_check+0x5bc>
    free_pages(p, 5);
ffffffffc0200f18:	4595                	li	a1,5
ffffffffc0200f1a:	854e                	mv	a0,s3
ffffffffc0200f1c:	4ac000ef          	jal	ra,ffffffffc02013c8 <free_pages>
    assert(nr_free_pages() == before);
ffffffffc0200f20:	4b4000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200f24:	46a91c63          	bne	s2,a0,ffffffffc020139c <buddy_check+0x71c>
    assert(alloc_pages(before + 1) == NULL);
ffffffffc0200f28:	00190513          	addi	a0,s2,1
ffffffffc0200f2c:	490000ef          	jal	ra,ffffffffc02013bc <alloc_pages>
ffffffffc0200f30:	44051663          	bnez	a0,ffffffffc020137c <buddy_check+0x6fc>
    assert(nr_free_pages() == before);
ffffffffc0200f34:	4a0000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200f38:	42a91263          	bne	s2,a0,ffffffffc020135c <buddy_check+0x6dc>
    buddy_check_lists();
ffffffffc0200f3c:	ec6ff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
    size_t before = buddy_check_lists();
ffffffffc0200f40:	ec2ff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
ffffffffc0200f44:	89aa                	mv	s3,a0
    size_t largest = 1;
ffffffffc0200f46:	4905                	li	s2,1
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200f48:	4781                	li	a5,0
            largest = (size_t)1 << order;
ffffffffc0200f4a:	4605                	li	a2,1
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200f4c:	46c5                	li	a3,17
        if (!list_empty(&buddy_free_lists[order])) {
ffffffffc0200f4e:	6498                	ld	a4,8(s1)
ffffffffc0200f50:	00970463          	beq	a4,s1,ffffffffc0200f58 <buddy_check+0x2d8>
            largest = (size_t)1 << order;
ffffffffc0200f54:	00f61933          	sll	s2,a2,a5
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
ffffffffc0200f58:	2785                	addiw	a5,a5,1
ffffffffc0200f5a:	04c1                	addi	s1,s1,16
ffffffffc0200f5c:	fed799e3          	bne	a5,a3,ffffffffc0200f4e <buddy_check+0x2ce>
    struct Page *p = alloc_pages(largest);
ffffffffc0200f60:	854a                	mv	a0,s2
ffffffffc0200f62:	45a000ef          	jal	ra,ffffffffc02013bc <alloc_pages>
    assert(p != NULL);
ffffffffc0200f66:	3c050b63          	beqz	a0,ffffffffc020133c <buddy_check+0x6bc>
    assert(p->property == largest);
ffffffffc0200f6a:	01056703          	lwu	a4,16(a0)
ffffffffc0200f6e:	3b271763          	bne	a4,s2,ffffffffc020131c <buddy_check+0x69c>
ffffffffc0200f72:	000b3703          	ld	a4,0(s6)
ffffffffc0200f76:	40e507b3          	sub	a5,a0,a4
ffffffffc0200f7a:	878d                	srai	a5,a5,0x3
ffffffffc0200f7c:	035787b3          	mul	a5,a5,s5
ffffffffc0200f80:	97d2                	add	a5,a5,s4
    assert(page2ppn(p) % largest == 0);
ffffffffc0200f82:	0327f7b3          	remu	a5,a5,s2
ffffffffc0200f86:	2e079b63          	bnez	a5,ffffffffc020127c <buddy_check+0x5fc>
    free_pages(p, largest);
ffffffffc0200f8a:	85ca                	mv	a1,s2
ffffffffc0200f8c:	43c000ef          	jal	ra,ffffffffc02013c8 <free_pages>
    assert(nr_free_pages() == before);
ffffffffc0200f90:	444000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200f94:	0aa99463          	bne	s3,a0,ffffffffc020103c <buddy_check+0x3bc>
    buddy_check_lists();
ffffffffc0200f98:	e6aff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
    size_t before = buddy_check_lists();
ffffffffc0200f9c:	e66ff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
ffffffffc0200fa0:	89aa                	mv	s3,a0
    for (int i = 0; i < 6; i++) {
ffffffffc0200fa2:	4901                	li	s2,0
        size_t request = (size_t)(i % 3) + 1;
ffffffffc0200fa4:	4a8d                	li	s5,3
    for (int i = 0; i < 6; i++) {
ffffffffc0200fa6:	4a19                	li	s4,6
        size_t request = (size_t)(i % 3) + 1;
ffffffffc0200fa8:	035964bb          	remw	s1,s2,s5
ffffffffc0200fac:	2485                	addiw	s1,s1,1
        struct Page *p = alloc_pages(request);
ffffffffc0200fae:	8526                	mv	a0,s1
ffffffffc0200fb0:	40c000ef          	jal	ra,ffffffffc02013bc <alloc_pages>
        assert(p != NULL);
ffffffffc0200fb4:	c525                	beqz	a0,ffffffffc020101c <buddy_check+0x39c>
        free_pages(p, request);
ffffffffc0200fb6:	85a6                	mv	a1,s1
ffffffffc0200fb8:	410000ef          	jal	ra,ffffffffc02013c8 <free_pages>
        assert(nr_free_pages() == before);
ffffffffc0200fbc:	418000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200fc0:	02a99e63          	bne	s3,a0,ffffffffc0200ffc <buddy_check+0x37c>
    for (int i = 0; i < 6; i++) {
ffffffffc0200fc4:	2905                	addiw	s2,s2,1
        buddy_check_lists();
ffffffffc0200fc6:	e3cff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>
    for (int i = 0; i < 6; i++) {
ffffffffc0200fca:	fd491fe3          	bne	s2,s4,ffffffffc0200fa8 <buddy_check+0x328>
    buddy_check_alloc();
    buddy_check_limits();
    buddy_check_large();
    buddy_check_repeat();

    assert(nr_free_pages() == initial);
ffffffffc0200fce:	406000ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0200fd2:	32851563          	bne	a0,s0,ffffffffc02012fc <buddy_check+0x67c>
    buddy_check_lists();
ffffffffc0200fd6:	e2cff0ef          	jal	ra,ffffffffc0200602 <buddy_check_lists>

    cprintf("buddy_check: PASS\n");
}
ffffffffc0200fda:	6406                	ld	s0,64(sp)
ffffffffc0200fdc:	60a6                	ld	ra,72(sp)
ffffffffc0200fde:	74e2                	ld	s1,56(sp)
ffffffffc0200fe0:	7942                	ld	s2,48(sp)
ffffffffc0200fe2:	79a2                	ld	s3,40(sp)
ffffffffc0200fe4:	7a02                	ld	s4,32(sp)
ffffffffc0200fe6:	6ae2                	ld	s5,24(sp)
ffffffffc0200fe8:	6b42                	ld	s6,16(sp)
ffffffffc0200fea:	6ba2                	ld	s7,8(sp)
ffffffffc0200fec:	6c02                	ld	s8,0(sp)
    cprintf("buddy_check: PASS\n");
ffffffffc0200fee:	00002517          	auipc	a0,0x2
ffffffffc0200ff2:	be250513          	addi	a0,a0,-1054 # ffffffffc0202bd0 <etext+0x668>
}
ffffffffc0200ff6:	6161                	addi	sp,sp,80
    cprintf("buddy_check: PASS\n");
ffffffffc0200ff8:	958ff06f          	j	ffffffffc0200150 <cprintf>
        assert(nr_free_pages() == before);
ffffffffc0200ffc:	00002697          	auipc	a3,0x2
ffffffffc0201000:	9a468693          	addi	a3,a3,-1628 # ffffffffc02029a0 <etext+0x438>
ffffffffc0201004:	00001617          	auipc	a2,0x1
ffffffffc0201008:	7d460613          	addi	a2,a2,2004 # ffffffffc02027d8 <etext+0x270>
ffffffffc020100c:	19000593          	li	a1,400
ffffffffc0201010:	00001517          	auipc	a0,0x1
ffffffffc0201014:	7e050513          	addi	a0,a0,2016 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201018:	9aeff0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert(p != NULL);
ffffffffc020101c:	00002697          	auipc	a3,0x2
ffffffffc0201020:	adc68693          	addi	a3,a3,-1316 # ffffffffc0202af8 <etext+0x590>
ffffffffc0201024:	00001617          	auipc	a2,0x1
ffffffffc0201028:	7b460613          	addi	a2,a2,1972 # ffffffffc02027d8 <etext+0x270>
ffffffffc020102c:	18d00593          	li	a1,397
ffffffffc0201030:	00001517          	auipc	a0,0x1
ffffffffc0201034:	7c050513          	addi	a0,a0,1984 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201038:	98eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc020103c:	00002697          	auipc	a3,0x2
ffffffffc0201040:	96468693          	addi	a3,a3,-1692 # ffffffffc02029a0 <etext+0x438>
ffffffffc0201044:	00001617          	auipc	a2,0x1
ffffffffc0201048:	79460613          	addi	a2,a2,1940 # ffffffffc02027d8 <etext+0x270>
ffffffffc020104c:	15600593          	li	a1,342
ffffffffc0201050:	00001517          	auipc	a0,0x1
ffffffffc0201054:	7a050513          	addi	a0,a0,1952 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201058:	96eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc020105c:	00002697          	auipc	a3,0x2
ffffffffc0201060:	94468693          	addi	a3,a3,-1724 # ffffffffc02029a0 <etext+0x438>
ffffffffc0201064:	00001617          	auipc	a2,0x1
ffffffffc0201068:	77460613          	addi	a2,a2,1908 # ffffffffc02027d8 <etext+0x270>
ffffffffc020106c:	12d00593          	li	a1,301
ffffffffc0201070:	00001517          	auipc	a0,0x1
ffffffffc0201074:	78050513          	addi	a0,a0,1920 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201078:	94eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before - 5);
ffffffffc020107c:	00002697          	auipc	a3,0x2
ffffffffc0201080:	a5c68693          	addi	a3,a3,-1444 # ffffffffc0202ad8 <etext+0x570>
ffffffffc0201084:	00001617          	auipc	a2,0x1
ffffffffc0201088:	75460613          	addi	a2,a2,1876 # ffffffffc02027d8 <etext+0x270>
ffffffffc020108c:	12900593          	li	a1,297
ffffffffc0201090:	00001517          	auipc	a0,0x1
ffffffffc0201094:	76050513          	addi	a0,a0,1888 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201098:	92eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p0 + 4 <= p1 || p1 + 1 <= p0);
ffffffffc020109c:	00002697          	auipc	a3,0x2
ffffffffc02010a0:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0202ab8 <etext+0x550>
ffffffffc02010a4:	00001617          	auipc	a2,0x1
ffffffffc02010a8:	73460613          	addi	a2,a2,1844 # ffffffffc02027d8 <etext+0x270>
ffffffffc02010ac:	12800593          	li	a1,296
ffffffffc02010b0:	00001517          	auipc	a0,0x1
ffffffffc02010b4:	74050513          	addi	a0,a0,1856 # ffffffffc02027f0 <etext+0x288>
ffffffffc02010b8:	90eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(!PageProperty(p1));
ffffffffc02010bc:	00002697          	auipc	a3,0x2
ffffffffc02010c0:	9e468693          	addi	a3,a3,-1564 # ffffffffc0202aa0 <etext+0x538>
ffffffffc02010c4:	00001617          	auipc	a2,0x1
ffffffffc02010c8:	71460613          	addi	a2,a2,1812 # ffffffffc02027d8 <etext+0x270>
ffffffffc02010cc:	12500593          	li	a1,293
ffffffffc02010d0:	00001517          	auipc	a0,0x1
ffffffffc02010d4:	72050513          	addi	a0,a0,1824 # ffffffffc02027f0 <etext+0x288>
ffffffffc02010d8:	8eeff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p1->property == 1);
ffffffffc02010dc:	00002697          	auipc	a3,0x2
ffffffffc02010e0:	9ac68693          	addi	a3,a3,-1620 # ffffffffc0202a88 <etext+0x520>
ffffffffc02010e4:	00001617          	auipc	a2,0x1
ffffffffc02010e8:	6f460613          	addi	a2,a2,1780 # ffffffffc02027d8 <etext+0x270>
ffffffffc02010ec:	12400593          	li	a1,292
ffffffffc02010f0:	00001517          	auipc	a0,0x1
ffffffffc02010f4:	70050513          	addi	a0,a0,1792 # ffffffffc02027f0 <etext+0x288>
ffffffffc02010f8:	8ceff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p1 != NULL);
ffffffffc02010fc:	00002697          	auipc	a3,0x2
ffffffffc0201100:	97c68693          	addi	a3,a3,-1668 # ffffffffc0202a78 <etext+0x510>
ffffffffc0201104:	00001617          	auipc	a2,0x1
ffffffffc0201108:	6d460613          	addi	a2,a2,1748 # ffffffffc02027d8 <etext+0x270>
ffffffffc020110c:	12300593          	li	a1,291
ffffffffc0201110:	00001517          	auipc	a0,0x1
ffffffffc0201114:	6e050513          	addi	a0,a0,1760 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201118:	8aeff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before - 4);
ffffffffc020111c:	00002697          	auipc	a3,0x2
ffffffffc0201120:	93c68693          	addi	a3,a3,-1732 # ffffffffc0202a58 <etext+0x4f0>
ffffffffc0201124:	00001617          	auipc	a2,0x1
ffffffffc0201128:	6b460613          	addi	a2,a2,1716 # ffffffffc02027d8 <etext+0x270>
ffffffffc020112c:	12000593          	li	a1,288
ffffffffc0201130:	00001517          	auipc	a0,0x1
ffffffffc0201134:	6c050513          	addi	a0,a0,1728 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201138:	88eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(page2ppn(p0) % 4 == 0);
ffffffffc020113c:	00002697          	auipc	a3,0x2
ffffffffc0201140:	90468693          	addi	a3,a3,-1788 # ffffffffc0202a40 <etext+0x4d8>
ffffffffc0201144:	00001617          	auipc	a2,0x1
ffffffffc0201148:	69460613          	addi	a2,a2,1684 # ffffffffc02027d8 <etext+0x270>
ffffffffc020114c:	11a00593          	li	a1,282
ffffffffc0201150:	00001517          	auipc	a0,0x1
ffffffffc0201154:	6a050513          	addi	a0,a0,1696 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201158:	86eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(!PageProperty(p0));
ffffffffc020115c:	00002697          	auipc	a3,0x2
ffffffffc0201160:	8cc68693          	addi	a3,a3,-1844 # ffffffffc0202a28 <etext+0x4c0>
ffffffffc0201164:	00001617          	auipc	a2,0x1
ffffffffc0201168:	67460613          	addi	a2,a2,1652 # ffffffffc02027d8 <etext+0x270>
ffffffffc020116c:	11900593          	li	a1,281
ffffffffc0201170:	00001517          	auipc	a0,0x1
ffffffffc0201174:	68050513          	addi	a0,a0,1664 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201178:	84eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p0->property == 4);
ffffffffc020117c:	00002697          	auipc	a3,0x2
ffffffffc0201180:	89468693          	addi	a3,a3,-1900 # ffffffffc0202a10 <etext+0x4a8>
ffffffffc0201184:	00001617          	auipc	a2,0x1
ffffffffc0201188:	65460613          	addi	a2,a2,1620 # ffffffffc02027d8 <etext+0x270>
ffffffffc020118c:	11800593          	li	a1,280
ffffffffc0201190:	00001517          	auipc	a0,0x1
ffffffffc0201194:	66050513          	addi	a0,a0,1632 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201198:	82eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p0 != NULL);
ffffffffc020119c:	00002697          	auipc	a3,0x2
ffffffffc02011a0:	86468693          	addi	a3,a3,-1948 # ffffffffc0202a00 <etext+0x498>
ffffffffc02011a4:	00001617          	auipc	a2,0x1
ffffffffc02011a8:	63460613          	addi	a2,a2,1588 # ffffffffc02027d8 <etext+0x270>
ffffffffc02011ac:	11700593          	li	a1,279
ffffffffc02011b0:	00001517          	auipc	a0,0x1
ffffffffc02011b4:	64050513          	addi	a0,a0,1600 # ffffffffc02027f0 <etext+0x288>
ffffffffc02011b8:	80eff0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p->property == 8);
ffffffffc02011bc:	00002697          	auipc	a3,0x2
ffffffffc02011c0:	94c68693          	addi	a3,a3,-1716 # ffffffffc0202b08 <etext+0x5a0>
ffffffffc02011c4:	00001617          	auipc	a2,0x1
ffffffffc02011c8:	61460613          	addi	a2,a2,1556 # ffffffffc02027d8 <etext+0x270>
ffffffffc02011cc:	13800593          	li	a1,312
ffffffffc02011d0:	00001517          	auipc	a0,0x1
ffffffffc02011d4:	62050513          	addi	a0,a0,1568 # ffffffffc02027f0 <etext+0x288>
ffffffffc02011d8:	feffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p != NULL);
ffffffffc02011dc:	00002697          	auipc	a3,0x2
ffffffffc02011e0:	91c68693          	addi	a3,a3,-1764 # ffffffffc0202af8 <etext+0x590>
ffffffffc02011e4:	00001617          	auipc	a2,0x1
ffffffffc02011e8:	5f460613          	addi	a2,a2,1524 # ffffffffc02027d8 <etext+0x270>
ffffffffc02011ec:	13700593          	li	a1,311
ffffffffc02011f0:	00001517          	auipc	a0,0x1
ffffffffc02011f4:	60050513          	addi	a0,a0,1536 # ffffffffc02027f0 <etext+0x288>
ffffffffc02011f8:	fcffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before - half);
ffffffffc02011fc:	00001697          	auipc	a3,0x1
ffffffffc0201200:	77c68693          	addi	a3,a3,1916 # ffffffffc0202978 <etext+0x410>
ffffffffc0201204:	00001617          	auipc	a2,0x1
ffffffffc0201208:	5d460613          	addi	a2,a2,1492 # ffffffffc02027d8 <etext+0x270>
ffffffffc020120c:	17500593          	li	a1,373
ffffffffc0201210:	00001517          	auipc	a0,0x1
ffffffffc0201214:	5e050513          	addi	a0,a0,1504 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201218:	faffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(big != NULL);
ffffffffc020121c:	00002697          	auipc	a3,0x2
ffffffffc0201220:	9cc68693          	addi	a3,a3,-1588 # ffffffffc0202be8 <etext+0x680>
ffffffffc0201224:	00001617          	auipc	a2,0x1
ffffffffc0201228:	5b460613          	addi	a2,a2,1460 # ffffffffc02027d8 <etext+0x270>
ffffffffc020122c:	16000593          	li	a1,352
ffffffffc0201230:	00001517          	auipc	a0,0x1
ffffffffc0201234:	5c050513          	addi	a0,a0,1472 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201238:	f8ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before - 8);
ffffffffc020123c:	00002697          	auipc	a3,0x2
ffffffffc0201240:	8fc68693          	addi	a3,a3,-1796 # ffffffffc0202b38 <etext+0x5d0>
ffffffffc0201244:	00001617          	auipc	a2,0x1
ffffffffc0201248:	59460613          	addi	a2,a2,1428 # ffffffffc02027d8 <etext+0x270>
ffffffffc020124c:	13a00593          	li	a1,314
ffffffffc0201250:	00001517          	auipc	a0,0x1
ffffffffc0201254:	5a050513          	addi	a0,a0,1440 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201258:	f6ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(page2ppn(p) % 8 == 0);
ffffffffc020125c:	00002697          	auipc	a3,0x2
ffffffffc0201260:	8c468693          	addi	a3,a3,-1852 # ffffffffc0202b20 <etext+0x5b8>
ffffffffc0201264:	00001617          	auipc	a2,0x1
ffffffffc0201268:	57460613          	addi	a2,a2,1396 # ffffffffc02027d8 <etext+0x270>
ffffffffc020126c:	13900593          	li	a1,313
ffffffffc0201270:	00001517          	auipc	a0,0x1
ffffffffc0201274:	58050513          	addi	a0,a0,1408 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201278:	f4ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(page2ppn(p) % largest == 0);
ffffffffc020127c:	00002697          	auipc	a3,0x2
ffffffffc0201280:	91468693          	addi	a3,a3,-1772 # ffffffffc0202b90 <etext+0x628>
ffffffffc0201284:	00001617          	auipc	a2,0x1
ffffffffc0201288:	55460613          	addi	a2,a2,1364 # ffffffffc02027d8 <etext+0x270>
ffffffffc020128c:	15300593          	li	a1,339
ffffffffc0201290:	00001517          	auipc	a0,0x1
ffffffffc0201294:	56050513          	addi	a0,a0,1376 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201298:	f2ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc020129c:	00001697          	auipc	a3,0x1
ffffffffc02012a0:	70468693          	addi	a3,a3,1796 # ffffffffc02029a0 <etext+0x438>
ffffffffc02012a4:	00001617          	auipc	a2,0x1
ffffffffc02012a8:	53460613          	addi	a2,a2,1332 # ffffffffc02027d8 <etext+0x270>
ffffffffc02012ac:	17800593          	li	a1,376
ffffffffc02012b0:	00001517          	auipc	a0,0x1
ffffffffc02012b4:	54050513          	addi	a0,a0,1344 # ffffffffc02027f0 <etext+0x288>
ffffffffc02012b8:	f0ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(head1->property >= (half << 1));
ffffffffc02012bc:	00001697          	auipc	a3,0x1
ffffffffc02012c0:	72468693          	addi	a3,a3,1828 # ffffffffc02029e0 <etext+0x478>
ffffffffc02012c4:	00001617          	auipc	a2,0x1
ffffffffc02012c8:	51460613          	addi	a2,a2,1300 # ffffffffc02027d8 <etext+0x270>
ffffffffc02012cc:	17f00593          	li	a1,383
ffffffffc02012d0:	00001517          	auipc	a0,0x1
ffffffffc02012d4:	52050513          	addi	a0,a0,1312 # ffffffffc02027f0 <etext+0x288>
ffffffffc02012d8:	eeffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(head1 == head2);
ffffffffc02012dc:	00001697          	auipc	a3,0x1
ffffffffc02012e0:	6f468693          	addi	a3,a3,1780 # ffffffffc02029d0 <etext+0x468>
ffffffffc02012e4:	00001617          	auipc	a2,0x1
ffffffffc02012e8:	4f460613          	addi	a2,a2,1268 # ffffffffc02027d8 <etext+0x270>
ffffffffc02012ec:	17e00593          	li	a1,382
ffffffffc02012f0:	00001517          	auipc	a0,0x1
ffffffffc02012f4:	50050513          	addi	a0,a0,1280 # ffffffffc02027f0 <etext+0x288>
ffffffffc02012f8:	ecffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == initial);
ffffffffc02012fc:	00002697          	auipc	a3,0x2
ffffffffc0201300:	8b468693          	addi	a3,a3,-1868 # ffffffffc0202bb0 <etext+0x648>
ffffffffc0201304:	00001617          	auipc	a2,0x1
ffffffffc0201308:	4d460613          	addi	a2,a2,1236 # ffffffffc02027d8 <etext+0x270>
ffffffffc020130c:	1a200593          	li	a1,418
ffffffffc0201310:	00001517          	auipc	a0,0x1
ffffffffc0201314:	4e050513          	addi	a0,a0,1248 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201318:	eaffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p->property == largest);
ffffffffc020131c:	00002697          	auipc	a3,0x2
ffffffffc0201320:	85c68693          	addi	a3,a3,-1956 # ffffffffc0202b78 <etext+0x610>
ffffffffc0201324:	00001617          	auipc	a2,0x1
ffffffffc0201328:	4b460613          	addi	a2,a2,1204 # ffffffffc02027d8 <etext+0x270>
ffffffffc020132c:	15200593          	li	a1,338
ffffffffc0201330:	00001517          	auipc	a0,0x1
ffffffffc0201334:	4c050513          	addi	a0,a0,1216 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201338:	e8ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p != NULL);
ffffffffc020133c:	00001697          	auipc	a3,0x1
ffffffffc0201340:	7bc68693          	addi	a3,a3,1980 # ffffffffc0202af8 <etext+0x590>
ffffffffc0201344:	00001617          	auipc	a2,0x1
ffffffffc0201348:	49460613          	addi	a2,a2,1172 # ffffffffc02027d8 <etext+0x270>
ffffffffc020134c:	15100593          	li	a1,337
ffffffffc0201350:	00001517          	auipc	a0,0x1
ffffffffc0201354:	4a050513          	addi	a0,a0,1184 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201358:	e6ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc020135c:	00001697          	auipc	a3,0x1
ffffffffc0201360:	64468693          	addi	a3,a3,1604 # ffffffffc02029a0 <etext+0x438>
ffffffffc0201364:	00001617          	auipc	a2,0x1
ffffffffc0201368:	47460613          	addi	a2,a2,1140 # ffffffffc02027d8 <etext+0x270>
ffffffffc020136c:	14000593          	li	a1,320
ffffffffc0201370:	00001517          	auipc	a0,0x1
ffffffffc0201374:	48050513          	addi	a0,a0,1152 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201378:	e4ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(alloc_pages(before + 1) == NULL);
ffffffffc020137c:	00001697          	auipc	a3,0x1
ffffffffc0201380:	7dc68693          	addi	a3,a3,2012 # ffffffffc0202b58 <etext+0x5f0>
ffffffffc0201384:	00001617          	auipc	a2,0x1
ffffffffc0201388:	45460613          	addi	a2,a2,1108 # ffffffffc02027d8 <etext+0x270>
ffffffffc020138c:	13f00593          	li	a1,319
ffffffffc0201390:	00001517          	auipc	a0,0x1
ffffffffc0201394:	46050513          	addi	a0,a0,1120 # ffffffffc02027f0 <etext+0x288>
ffffffffc0201398:	e2ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before);
ffffffffc020139c:	00001697          	auipc	a3,0x1
ffffffffc02013a0:	60468693          	addi	a3,a3,1540 # ffffffffc02029a0 <etext+0x438>
ffffffffc02013a4:	00001617          	auipc	a2,0x1
ffffffffc02013a8:	43460613          	addi	a2,a2,1076 # ffffffffc02027d8 <etext+0x270>
ffffffffc02013ac:	13d00593          	li	a1,317
ffffffffc02013b0:	00001517          	auipc	a0,0x1
ffffffffc02013b4:	44050513          	addi	a0,a0,1088 # ffffffffc02027f0 <etext+0x288>
ffffffffc02013b8:	e0ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>

ffffffffc02013bc <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc02013bc:	00008797          	auipc	a5,0x8
ffffffffc02013c0:	b9c7b783          	ld	a5,-1124(a5) # ffffffffc0208f58 <pmm_manager>
ffffffffc02013c4:	6f9c                	ld	a5,24(a5)
ffffffffc02013c6:	8782                	jr	a5

ffffffffc02013c8 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc02013c8:	00008797          	auipc	a5,0x8
ffffffffc02013cc:	b907b783          	ld	a5,-1136(a5) # ffffffffc0208f58 <pmm_manager>
ffffffffc02013d0:	739c                	ld	a5,32(a5)
ffffffffc02013d2:	8782                	jr	a5

ffffffffc02013d4 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc02013d4:	00008797          	auipc	a5,0x8
ffffffffc02013d8:	b847b783          	ld	a5,-1148(a5) # ffffffffc0208f58 <pmm_manager>
ffffffffc02013dc:	779c                	ld	a5,40(a5)
ffffffffc02013de:	8782                	jr	a5

ffffffffc02013e0 <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc02013e0:	00002797          	auipc	a5,0x2
ffffffffc02013e4:	83078793          	addi	a5,a5,-2000 # ffffffffc0202c10 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02013e8:	638c                	ld	a1,0(a5)
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
            mem_end - mem_base, mem_base, mem_end - 1);
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02013ea:	7179                	addi	sp,sp,-48
ffffffffc02013ec:	ec26                	sd	s1,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02013ee:	00002517          	auipc	a0,0x2
ffffffffc02013f2:	85a50513          	addi	a0,a0,-1958 # ffffffffc0202c48 <buddy_pmm_manager+0x38>
    pmm_manager = &buddy_pmm_manager;
ffffffffc02013f6:	00008497          	auipc	s1,0x8
ffffffffc02013fa:	b6248493          	addi	s1,s1,-1182 # ffffffffc0208f58 <pmm_manager>
void pmm_init(void) {
ffffffffc02013fe:	f406                	sd	ra,40(sp)
ffffffffc0201400:	e84a                	sd	s2,16(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0201402:	e09c                	sd	a5,0(s1)
void pmm_init(void) {
ffffffffc0201404:	f022                	sd	s0,32(sp)
ffffffffc0201406:	e44e                	sd	s3,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201408:	d49fe0ef          	jal	ra,ffffffffc0200150 <cprintf>
    pmm_manager->init();
ffffffffc020140c:	609c                	ld	a5,0(s1)
ffffffffc020140e:	679c                	ld	a5,8(a5)
ffffffffc0201410:	9782                	jalr	a5
    uint64_t mem_base = get_memory_base();
ffffffffc0201412:	9aeff0ef          	jal	ra,ffffffffc02005c0 <get_memory_base>
ffffffffc0201416:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc0201418:	9b2ff0ef          	jal	ra,ffffffffc02005ca <get_memory_size>
    if (mem_base == 0 || mem_size == 0 ||
ffffffffc020141c:	800007b7          	lui	a5,0x80000
ffffffffc0201420:	97ca                	add	a5,a5,s2
ffffffffc0201422:	08000737          	lui	a4,0x8000
ffffffffc0201426:	16e7f463          	bgeu	a5,a4,ffffffffc020158e <pmm_init+0x1ae>
ffffffffc020142a:	16050263          	beqz	a0,ffffffffc020158e <pmm_init+0x1ae>
    if (mem_size > PHYSICAL_MEMORY_END - mem_base) {
ffffffffc020142e:	4445                	li	s0,17
ffffffffc0201430:	046e                	slli	s0,s0,0x1b
ffffffffc0201432:	412407b3          	sub	a5,s0,s2
ffffffffc0201436:	10a7e763          	bltu	a5,a0,ffffffffc0201544 <pmm_init+0x164>
        mem_end = mem_base + mem_size;
ffffffffc020143a:	00a90433          	add	s0,s2,a0
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020143e:	57f5                	li	a5,-3
ffffffffc0201440:	07fa                	slli	a5,a5,0x1e
    npage = PPN(mem_end);
ffffffffc0201442:	00c45513          	srli	a0,s0,0xc
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201446:	00008997          	auipc	s3,0x8
ffffffffc020144a:	b2a98993          	addi	s3,s3,-1238 # ffffffffc0208f70 <va_pa_offset>
ffffffffc020144e:	00f9b023          	sd	a5,0(s3)
    if (npage <= nbase) {
ffffffffc0201452:	00080737          	lui	a4,0x80
    npage = PPN(mem_end);
ffffffffc0201456:	00008797          	auipc	a5,0x8
ffffffffc020145a:	aea7b923          	sd	a0,-1294(a5) # ffffffffc0208f48 <npage>
    desc_count = npage - nbase;
ffffffffc020145e:	40e507b3          	sub	a5,a0,a4
    if (npage <= nbase) {
ffffffffc0201462:	16e50b63          	beq	a0,a4,ffffffffc02015d8 <pmm_init+0x1f8>
    pages = (struct Page *)ROUNDUP((uintptr_t)end, PGSIZE);
ffffffffc0201466:	00009717          	auipc	a4,0x9
ffffffffc020146a:	b1570713          	addi	a4,a4,-1259 # ffffffffc0209f7b <end+0xfff>
ffffffffc020146e:	76fd                	lui	a3,0xfffff
ffffffffc0201470:	8ef9                	and	a3,a3,a4
ffffffffc0201472:	00008717          	auipc	a4,0x8
ffffffffc0201476:	acd73f23          	sd	a3,-1314(a4) # ffffffffc0208f50 <pages>
    pages_pa = PADDR((uintptr_t)pages);
ffffffffc020147a:	c0200637          	lui	a2,0xc0200
ffffffffc020147e:	16c6e963          	bltu	a3,a2,ffffffffc02015f0 <pmm_init+0x210>
    pages_end_pa = PADDR((uintptr_t)pages + desc_count * sizeof(struct Page));
ffffffffc0201482:	00279713          	slli	a4,a5,0x2
ffffffffc0201486:	973e                	add	a4,a4,a5
ffffffffc0201488:	070e                	slli	a4,a4,0x3
    pages_pa = PADDR((uintptr_t)pages);
ffffffffc020148a:	478d                	li	a5,3
ffffffffc020148c:	07fa                	slli	a5,a5,0x1e
    pages_end_pa = PADDR((uintptr_t)pages + desc_count * sizeof(struct Page));
ffffffffc020148e:	9736                	add	a4,a4,a3
    pages_pa = PADDR((uintptr_t)pages);
ffffffffc0201490:	00f685b3          	add	a1,a3,a5
    pages_end_pa = PADDR((uintptr_t)pages + desc_count * sizeof(struct Page));
ffffffffc0201494:	12c76563          	bltu	a4,a2,ffffffffc02015be <pmm_init+0x1de>
ffffffffc0201498:	97ba                	add	a5,a5,a4
    if (pages_pa >= mem_end || pages_end_pa > mem_end) {
ffffffffc020149a:	1085f663          	bgeu	a1,s0,ffffffffc02015a6 <pmm_init+0x1c6>
ffffffffc020149e:	10f46463          	bltu	s0,a5,ffffffffc02015a6 <pmm_init+0x1c6>
    for (p = pages; p < pages + desc_count; p++) {
ffffffffc02014a2:	87b6                	mv	a5,a3
        SetPageReserved(p);
ffffffffc02014a4:	4585                	li	a1,1
    for (p = pages; p < pages + desc_count; p++) {
ffffffffc02014a6:	00e6fb63          	bgeu	a3,a4,ffffffffc02014bc <pmm_init+0xdc>
        p->property = 0;
ffffffffc02014aa:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc02014ae:	0007a023          	sw	zero,0(a5)
        SetPageReserved(p);
ffffffffc02014b2:	e78c                	sd	a1,8(a5)
    for (p = pages; p < pages + desc_count; p++) {
ffffffffc02014b4:	02878793          	addi	a5,a5,40
ffffffffc02014b8:	fee7e9e3          	bltu	a5,a4,ffffffffc02014aa <pmm_init+0xca>
    free_start_pa = ROUNDUP(pages_end_pa, PGSIZE);
ffffffffc02014bc:	00002617          	auipc	a2,0x2
ffffffffc02014c0:	1c463603          	ld	a2,452(a2) # ffffffffc0203680 <error_string+0x40>
ffffffffc02014c4:	77fd                	lui	a5,0xfffff
ffffffffc02014c6:	9732                	add	a4,a4,a2
ffffffffc02014c8:	8f7d                	and	a4,a4,a5
    free_end_pa = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02014ca:	8fe1                	and	a5,a5,s0
    if (free_start_pa < free_end_pa) {
ffffffffc02014cc:	08f76e63          	bltu	a4,a5,ffffffffc0201568 <pmm_init+0x188>
    cprintf("physical memory map:\n");
ffffffffc02014d0:	00002517          	auipc	a0,0x2
ffffffffc02014d4:	86050513          	addi	a0,a0,-1952 # ffffffffc0202d30 <buddy_pmm_manager+0x120>
ffffffffc02014d8:	c79fe0ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n",
ffffffffc02014dc:	412405b3          	sub	a1,s0,s2
ffffffffc02014e0:	fff40693          	addi	a3,s0,-1
ffffffffc02014e4:	864a                	mv	a2,s2
ffffffffc02014e6:	00002517          	auipc	a0,0x2
ffffffffc02014ea:	86250513          	addi	a0,a0,-1950 # ffffffffc0202d48 <buddy_pmm_manager+0x138>
ffffffffc02014ee:	c63fe0ef          	jal	ra,ffffffffc0200150 <cprintf>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02014f2:	609c                	ld	a5,0(s1)
ffffffffc02014f4:	7b9c                	ld	a5,48(a5)
ffffffffc02014f6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02014f8:	00002517          	auipc	a0,0x2
ffffffffc02014fc:	88050513          	addi	a0,a0,-1920 # ffffffffc0202d78 <buddy_pmm_manager+0x168>
ffffffffc0201500:	c51fe0ef          	jal	ra,ffffffffc0200150 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201504:	00005597          	auipc	a1,0x5
ffffffffc0201508:	afc58593          	addi	a1,a1,-1284 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc020150c:	00008797          	auipc	a5,0x8
ffffffffc0201510:	a4b7be23          	sd	a1,-1444(a5) # ffffffffc0208f68 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201514:	c02007b7          	lui	a5,0xc0200
ffffffffc0201518:	0ef5e863          	bltu	a1,a5,ffffffffc0201608 <pmm_init+0x228>
ffffffffc020151c:	0009b603          	ld	a2,0(s3)
}
ffffffffc0201520:	7402                	ld	s0,32(sp)
ffffffffc0201522:	70a2                	ld	ra,40(sp)
ffffffffc0201524:	64e2                	ld	s1,24(sp)
ffffffffc0201526:	6942                	ld	s2,16(sp)
ffffffffc0201528:	69a2                	ld	s3,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc020152a:	40c58633          	sub	a2,a1,a2
ffffffffc020152e:	00008797          	auipc	a5,0x8
ffffffffc0201532:	a2c7b923          	sd	a2,-1486(a5) # ffffffffc0208f60 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201536:	00002517          	auipc	a0,0x2
ffffffffc020153a:	86250513          	addi	a0,a0,-1950 # ffffffffc0202d98 <buddy_pmm_manager+0x188>
}
ffffffffc020153e:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201540:	c11fe06f          	j	ffffffffc0200150 <cprintf>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201544:	57f5                	li	a5,-3
ffffffffc0201546:	07fa                	slli	a5,a5,0x1e
ffffffffc0201548:	00008997          	auipc	s3,0x8
ffffffffc020154c:	a2898993          	addi	s3,s3,-1496 # ffffffffc0208f70 <va_pa_offset>
ffffffffc0201550:	00f9b023          	sd	a5,0(s3)
    npage = PPN(mem_end);
ffffffffc0201554:	000887b7          	lui	a5,0x88
ffffffffc0201558:	00008717          	auipc	a4,0x8
ffffffffc020155c:	9ef73823          	sd	a5,-1552(a4) # ffffffffc0208f48 <npage>
ffffffffc0201560:	00088537          	lui	a0,0x88
ffffffffc0201564:	67a1                	lui	a5,0x8
ffffffffc0201566:	b701                	j	ffffffffc0201466 <pmm_init+0x86>
        free_pages = (free_end_pa - free_start_pa) / PGSIZE;
ffffffffc0201568:	8f99                	sub	a5,a5,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc020156a:	8331                	srli	a4,a4,0xc
ffffffffc020156c:	00c7d593          	srli	a1,a5,0xc
ffffffffc0201570:	0aa77963          	bgeu	a4,a0,ffffffffc0201622 <pmm_init+0x242>
    pmm_manager->init_memmap(base, n);
ffffffffc0201574:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201576:	fff80637          	lui	a2,0xfff80
ffffffffc020157a:	9732                	add	a4,a4,a2
ffffffffc020157c:	00271513          	slli	a0,a4,0x2
ffffffffc0201580:	972a                	add	a4,a4,a0
ffffffffc0201582:	6b9c                	ld	a5,16(a5)
ffffffffc0201584:	00371513          	slli	a0,a4,0x3
ffffffffc0201588:	9536                	add	a0,a0,a3
ffffffffc020158a:	9782                	jalr	a5
}
ffffffffc020158c:	b791                	j	ffffffffc02014d0 <pmm_init+0xf0>
        panic("page_init: invalid memory range");
ffffffffc020158e:	00001617          	auipc	a2,0x1
ffffffffc0201592:	6d260613          	addi	a2,a2,1746 # ffffffffc0202c60 <buddy_pmm_manager+0x50>
ffffffffc0201596:	05400593          	li	a1,84
ffffffffc020159a:	00001517          	auipc	a0,0x1
ffffffffc020159e:	6e650513          	addi	a0,a0,1766 # ffffffffc0202c80 <buddy_pmm_manager+0x70>
ffffffffc02015a2:	c25fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        panic("page_init: page descriptors do not fit");
ffffffffc02015a6:	00001617          	auipc	a2,0x1
ffffffffc02015aa:	73260613          	addi	a2,a2,1842 # ffffffffc0202cd8 <buddy_pmm_manager+0xc8>
ffffffffc02015ae:	06d00593          	li	a1,109
ffffffffc02015b2:	00001517          	auipc	a0,0x1
ffffffffc02015b6:	6ce50513          	addi	a0,a0,1742 # ffffffffc0202c80 <buddy_pmm_manager+0x70>
ffffffffc02015ba:	c0dfe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    pages_end_pa = PADDR((uintptr_t)pages + desc_count * sizeof(struct Page));
ffffffffc02015be:	86ba                	mv	a3,a4
ffffffffc02015c0:	00001617          	auipc	a2,0x1
ffffffffc02015c4:	6f060613          	addi	a2,a2,1776 # ffffffffc0202cb0 <buddy_pmm_manager+0xa0>
ffffffffc02015c8:	06a00593          	li	a1,106
ffffffffc02015cc:	00001517          	auipc	a0,0x1
ffffffffc02015d0:	6b450513          	addi	a0,a0,1716 # ffffffffc0202c80 <buddy_pmm_manager+0x70>
ffffffffc02015d4:	bf3fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        panic("page_init: invalid page range");
ffffffffc02015d8:	00001617          	auipc	a2,0x1
ffffffffc02015dc:	6b860613          	addi	a2,a2,1720 # ffffffffc0202c90 <buddy_pmm_manager+0x80>
ffffffffc02015e0:	06200593          	li	a1,98
ffffffffc02015e4:	00001517          	auipc	a0,0x1
ffffffffc02015e8:	69c50513          	addi	a0,a0,1692 # ffffffffc0202c80 <buddy_pmm_manager+0x70>
ffffffffc02015ec:	bdbfe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    pages_pa = PADDR((uintptr_t)pages);
ffffffffc02015f0:	00001617          	auipc	a2,0x1
ffffffffc02015f4:	6c060613          	addi	a2,a2,1728 # ffffffffc0202cb0 <buddy_pmm_manager+0xa0>
ffffffffc02015f8:	06900593          	li	a1,105
ffffffffc02015fc:	00001517          	auipc	a0,0x1
ffffffffc0201600:	68450513          	addi	a0,a0,1668 # ffffffffc0202c80 <buddy_pmm_manager+0x70>
ffffffffc0201604:	bc3fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201608:	86ae                	mv	a3,a1
ffffffffc020160a:	00001617          	auipc	a2,0x1
ffffffffc020160e:	6a660613          	addi	a2,a2,1702 # ffffffffc0202cb0 <buddy_pmm_manager+0xa0>
ffffffffc0201612:	09900593          	li	a1,153
ffffffffc0201616:	00001517          	auipc	a0,0x1
ffffffffc020161a:	66a50513          	addi	a0,a0,1642 # ffffffffc0202c80 <buddy_pmm_manager+0x70>
ffffffffc020161e:	ba9fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201622:	00001617          	auipc	a2,0x1
ffffffffc0201626:	6de60613          	addi	a2,a2,1758 # ffffffffc0202d00 <buddy_pmm_manager+0xf0>
ffffffffc020162a:	06a00593          	li	a1,106
ffffffffc020162e:	00001517          	auipc	a0,0x1
ffffffffc0201632:	6f250513          	addi	a0,a0,1778 # ffffffffc0202d20 <buddy_pmm_manager+0x110>
ffffffffc0201636:	b91fe0ef          	jal	ra,ffffffffc02001c6 <__panic>

ffffffffc020163a <slub_check_slab>:
}

/* 检查单个 slab 的对象链表和位图 */
static void
slub_check_slab(struct slub_slab *slab) {
    assert(slab->active);
ffffffffc020163a:	411c                	lw	a5,0(a0)
slub_check_slab(struct slub_slab *slab) {
ffffffffc020163c:	711d                	addi	sp,sp,-96
ffffffffc020163e:	ec86                	sd	ra,88(sp)
ffffffffc0201640:	e8a2                	sd	s0,80(sp)
ffffffffc0201642:	e4a6                	sd	s1,72(sp)
    assert(slab->active);
ffffffffc0201644:	2a078463          	beqz	a5,ffffffffc02018ec <slub_check_slab+0x2b2>
    assert(slab->object_size == slub_class_sizes[slab->class_index]);
ffffffffc0201648:	4158                	lw	a4,4(a0)
ffffffffc020164a:	6d1c                	ld	a5,24(a0)
ffffffffc020164c:	842a                	mv	s0,a0
ffffffffc020164e:	00371693          	slli	a3,a4,0x3
ffffffffc0201652:	00002717          	auipc	a4,0x2
ffffffffc0201656:	d8e70713          	addi	a4,a4,-626 # ffffffffc02033e0 <slub_class_sizes>
ffffffffc020165a:	9736                	add	a4,a4,a3
ffffffffc020165c:	6318                	ld	a4,0(a4)
ffffffffc020165e:	26e79763          	bne	a5,a4,ffffffffc02018cc <slub_check_slab+0x292>
    assert(slab->object_count == PGSIZE / slab->object_size);
ffffffffc0201662:	6485                	lui	s1,0x1
ffffffffc0201664:	02f4d7b3          	divu	a5,s1,a5
ffffffffc0201668:	7118                	ld	a4,32(a0)
ffffffffc020166a:	24f71163          	bne	a4,a5,ffffffffc02018ac <slub_check_slab+0x272>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020166e:	651c                	ld	a5,8(a0)
ffffffffc0201670:	00008697          	auipc	a3,0x8
ffffffffc0201674:	8e06b683          	ld	a3,-1824(a3) # ffffffffc0208f50 <pages>
ffffffffc0201678:	00002617          	auipc	a2,0x2
ffffffffc020167c:	01063603          	ld	a2,16(a2) # ffffffffc0203688 <nbase>
ffffffffc0201680:	8f95                	sub	a5,a5,a3
ffffffffc0201682:	878d                	srai	a5,a5,0x3
ffffffffc0201684:	00002697          	auipc	a3,0x2
ffffffffc0201688:	ff46b683          	ld	a3,-12(a3) # ffffffffc0203678 <error_string+0x38>
ffffffffc020168c:	02d787b3          	mul	a5,a5,a3
    assert(slab->start == (void *)(page2pa(slab->page) + va_pa_offset));
ffffffffc0201690:	6914                	ld	a3,16(a0)
ffffffffc0201692:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201694:	07b2                	slli	a5,a5,0xc
ffffffffc0201696:	00008617          	auipc	a2,0x8
ffffffffc020169a:	8da63603          	ld	a2,-1830(a2) # ffffffffc0208f70 <va_pa_offset>
ffffffffc020169e:	97b2                	add	a5,a5,a2
ffffffffc02016a0:	1ef69663          	bne	a3,a5,ffffffffc020188c <slub_check_slab+0x252>
    assert(slab->free_count <= slab->object_count);
ffffffffc02016a4:	751c                	ld	a5,40(a0)
ffffffffc02016a6:	1af76363          	bltu	a4,a5,ffffffffc020184c <slub_check_slab+0x212>

    uint64_t seen[SLUB_BITMAP_WORDS];
    memset(seen, 0, sizeof(seen));
ffffffffc02016aa:	04000613          	li	a2,64
ffffffffc02016ae:	4581                	li	a1,0
ffffffffc02016b0:	850a                	mv	a0,sp
ffffffffc02016b2:	6a5000ef          	jal	ra,ffffffffc0202556 <memset>

    size_t free_seen = 0;
    for (void *p = slab->free_list; p != NULL; p = *(void **)p) {
ffffffffc02016b6:	7810                	ld	a2,48(s0)
ffffffffc02016b8:	c279                	beqz	a2,ffffffffc020177e <slub_check_slab+0x144>
        uintptr_t offset = (uintptr_t)p - (uintptr_t)slab->start;
ffffffffc02016ba:	6808                	ld	a0,16(s0)
ffffffffc02016bc:	40a607b3          	sub	a5,a2,a0
        assert(offset < PGSIZE);
ffffffffc02016c0:	1697f663          	bgeu	a5,s1,ffffffffc020182c <slub_check_slab+0x1f2>
        assert(offset % slab->object_size == 0);
ffffffffc02016c4:	01843883          	ld	a7,24(s0)
ffffffffc02016c8:	0317f5b3          	remu	a1,a5,a7
ffffffffc02016cc:	14059063          	bnez	a1,ffffffffc020180c <slub_check_slab+0x1d2>

        size_t index = offset / slab->object_size;
        assert(index < slab->object_count);
ffffffffc02016d0:	02043803          	ld	a6,32(s0)

        uint64_t bit = 1ULL << (index % 64);
ffffffffc02016d4:	4e05                	li	t3,1
        assert(offset < PGSIZE);
ffffffffc02016d6:	6e85                	lui	t4,0x1
ffffffffc02016d8:	a809                	j	ffffffffc02016ea <slub_check_slab+0xb0>
        uintptr_t offset = (uintptr_t)p - (uintptr_t)slab->start;
ffffffffc02016da:	40a607b3          	sub	a5,a2,a0
        assert(offset < PGSIZE);
ffffffffc02016de:	15d7f763          	bgeu	a5,t4,ffffffffc020182c <slub_check_slab+0x1f2>
        assert(offset % slab->object_size == 0);
ffffffffc02016e2:	0317f733          	remu	a4,a5,a7
ffffffffc02016e6:	12071363          	bnez	a4,ffffffffc020180c <slub_check_slab+0x1d2>
        size_t index = offset / slab->object_size;
ffffffffc02016ea:	0317d7b3          	divu	a5,a5,a7
        assert(index < slab->object_count);
ffffffffc02016ee:	0f07ff63          	bgeu	a5,a6,ffffffffc02017ec <slub_check_slab+0x1b2>
        assert((slab->used_bitmap[index / 64] & bit) == 0);
ffffffffc02016f2:	0067d713          	srli	a4,a5,0x6
ffffffffc02016f6:	00670693          	addi	a3,a4,6
ffffffffc02016fa:	068e                	slli	a3,a3,0x3
ffffffffc02016fc:	96a2                	add	a3,a3,s0
ffffffffc02016fe:	6694                	ld	a3,8(a3)
        uint64_t bit = 1ULL << (index % 64);
ffffffffc0201700:	00fe17b3          	sll	a5,t3,a5
        assert((slab->used_bitmap[index / 64] & bit) == 0);
ffffffffc0201704:	8efd                	and	a3,a3,a5
ffffffffc0201706:	e2f9                	bnez	a3,ffffffffc02017cc <slub_check_slab+0x192>
        assert((seen[index / 64] & bit) == 0);
ffffffffc0201708:	0094                	addi	a3,sp,64
ffffffffc020170a:	070e                	slli	a4,a4,0x3
ffffffffc020170c:	9736                	add	a4,a4,a3
ffffffffc020170e:	fc073683          	ld	a3,-64(a4)
ffffffffc0201712:	00f6f333          	and	t1,a3,a5
ffffffffc0201716:	08031b63          	bnez	t1,ffffffffc02017ac <slub_check_slab+0x172>

        seen[index / 64] |= bit;
ffffffffc020171a:	8fd5                	or	a5,a5,a3
ffffffffc020171c:	fcf73023          	sd	a5,-64(a4)
        free_seen++;
ffffffffc0201720:	0585                	addi	a1,a1,1
        assert(free_seen <= slab->object_count);
ffffffffc0201722:	06b86563          	bltu	a6,a1,ffffffffc020178c <slub_check_slab+0x152>
    for (void *p = slab->free_list; p != NULL; p = *(void **)p) {
ffffffffc0201726:	6210                	ld	a2,0(a2)
ffffffffc0201728:	fa4d                	bnez	a2,ffffffffc02016da <slub_check_slab+0xa0>
    }

    assert(free_seen == slab->free_count);
ffffffffc020172a:	741c                	ld	a5,40(s0)
ffffffffc020172c:	02b79963          	bne	a5,a1,ffffffffc020175e <slub_check_slab+0x124>
slub_check_slab(struct slub_slab *slab) {
ffffffffc0201730:	4701                	li	a4,0
ffffffffc0201732:	4681                	li	a3,0

    size_t used = 0;
    for (size_t i = 0; i < slab->object_count; i++) {
        if (slab->used_bitmap[i / 64] & (1ULL << (i % 64))) {
ffffffffc0201734:	00675793          	srli	a5,a4,0x6
ffffffffc0201738:	0799                	addi	a5,a5,6
ffffffffc020173a:	078e                	slli	a5,a5,0x3
ffffffffc020173c:	97a2                	add	a5,a5,s0
ffffffffc020173e:	679c                	ld	a5,8(a5)
ffffffffc0201740:	00e7d7b3          	srl	a5,a5,a4
            used++;
ffffffffc0201744:	8b85                	andi	a5,a5,1
    for (size_t i = 0; i < slab->object_count; i++) {
ffffffffc0201746:	0705                	addi	a4,a4,1
            used++;
ffffffffc0201748:	96be                	add	a3,a3,a5
    for (size_t i = 0; i < slab->object_count; i++) {
ffffffffc020174a:	ff0765e3          	bltu	a4,a6,ffffffffc0201734 <slub_check_slab+0xfa>
        }
    }
    assert(used + slab->free_count == slab->object_count);
ffffffffc020174e:	96ae                	add	a3,a3,a1
ffffffffc0201750:	11069e63          	bne	a3,a6,ffffffffc020186c <slub_check_slab+0x232>
}
ffffffffc0201754:	60e6                	ld	ra,88(sp)
ffffffffc0201756:	6446                	ld	s0,80(sp)
ffffffffc0201758:	64a6                	ld	s1,72(sp)
ffffffffc020175a:	6125                	addi	sp,sp,96
ffffffffc020175c:	8082                	ret
    assert(free_seen == slab->free_count);
ffffffffc020175e:	00002697          	auipc	a3,0x2
ffffffffc0201762:	83a68693          	addi	a3,a3,-1990 # ffffffffc0202f98 <buddy_pmm_manager+0x388>
ffffffffc0201766:	00001617          	auipc	a2,0x1
ffffffffc020176a:	07260613          	addi	a2,a2,114 # ffffffffc02027d8 <etext+0x270>
ffffffffc020176e:	0da00593          	li	a1,218
ffffffffc0201772:	00001517          	auipc	a0,0x1
ffffffffc0201776:	67650513          	addi	a0,a0,1654 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc020177a:	a4dfe0ef          	jal	ra,ffffffffc02001c6 <__panic>
ffffffffc020177e:	740c                	ld	a1,40(s0)
ffffffffc0201780:	fdf9                	bnez	a1,ffffffffc020175e <slub_check_slab+0x124>
    for (size_t i = 0; i < slab->object_count; i++) {
ffffffffc0201782:	02043803          	ld	a6,32(s0)
ffffffffc0201786:	fc0807e3          	beqz	a6,ffffffffc0201754 <slub_check_slab+0x11a>
ffffffffc020178a:	b75d                	j	ffffffffc0201730 <slub_check_slab+0xf6>
        assert(free_seen <= slab->object_count);
ffffffffc020178c:	00001697          	auipc	a3,0x1
ffffffffc0201790:	7ec68693          	addi	a3,a3,2028 # ffffffffc0202f78 <buddy_pmm_manager+0x368>
ffffffffc0201794:	00001617          	auipc	a2,0x1
ffffffffc0201798:	04460613          	addi	a2,a2,68 # ffffffffc02027d8 <etext+0x270>
ffffffffc020179c:	0d700593          	li	a1,215
ffffffffc02017a0:	00001517          	auipc	a0,0x1
ffffffffc02017a4:	64850513          	addi	a0,a0,1608 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc02017a8:	a1ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert((seen[index / 64] & bit) == 0);
ffffffffc02017ac:	00001697          	auipc	a3,0x1
ffffffffc02017b0:	7ac68693          	addi	a3,a3,1964 # ffffffffc0202f58 <buddy_pmm_manager+0x348>
ffffffffc02017b4:	00001617          	auipc	a2,0x1
ffffffffc02017b8:	02460613          	addi	a2,a2,36 # ffffffffc02027d8 <etext+0x270>
ffffffffc02017bc:	0d300593          	li	a1,211
ffffffffc02017c0:	00001517          	auipc	a0,0x1
ffffffffc02017c4:	62850513          	addi	a0,a0,1576 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc02017c8:	9fffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert((slab->used_bitmap[index / 64] & bit) == 0);
ffffffffc02017cc:	00001697          	auipc	a3,0x1
ffffffffc02017d0:	75c68693          	addi	a3,a3,1884 # ffffffffc0202f28 <buddy_pmm_manager+0x318>
ffffffffc02017d4:	00001617          	auipc	a2,0x1
ffffffffc02017d8:	00460613          	addi	a2,a2,4 # ffffffffc02027d8 <etext+0x270>
ffffffffc02017dc:	0d200593          	li	a1,210
ffffffffc02017e0:	00001517          	auipc	a0,0x1
ffffffffc02017e4:	60850513          	addi	a0,a0,1544 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc02017e8:	9dffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert(index < slab->object_count);
ffffffffc02017ec:	00001697          	auipc	a3,0x1
ffffffffc02017f0:	71c68693          	addi	a3,a3,1820 # ffffffffc0202f08 <buddy_pmm_manager+0x2f8>
ffffffffc02017f4:	00001617          	auipc	a2,0x1
ffffffffc02017f8:	fe460613          	addi	a2,a2,-28 # ffffffffc02027d8 <etext+0x270>
ffffffffc02017fc:	0cf00593          	li	a1,207
ffffffffc0201800:	00001517          	auipc	a0,0x1
ffffffffc0201804:	5e850513          	addi	a0,a0,1512 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201808:	9bffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert(offset % slab->object_size == 0);
ffffffffc020180c:	00001697          	auipc	a3,0x1
ffffffffc0201810:	6dc68693          	addi	a3,a3,1756 # ffffffffc0202ee8 <buddy_pmm_manager+0x2d8>
ffffffffc0201814:	00001617          	auipc	a2,0x1
ffffffffc0201818:	fc460613          	addi	a2,a2,-60 # ffffffffc02027d8 <etext+0x270>
ffffffffc020181c:	0cc00593          	li	a1,204
ffffffffc0201820:	00001517          	auipc	a0,0x1
ffffffffc0201824:	5c850513          	addi	a0,a0,1480 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201828:	99ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert(offset < PGSIZE);
ffffffffc020182c:	00001697          	auipc	a3,0x1
ffffffffc0201830:	6ac68693          	addi	a3,a3,1708 # ffffffffc0202ed8 <buddy_pmm_manager+0x2c8>
ffffffffc0201834:	00001617          	auipc	a2,0x1
ffffffffc0201838:	fa460613          	addi	a2,a2,-92 # ffffffffc02027d8 <etext+0x270>
ffffffffc020183c:	0cb00593          	li	a1,203
ffffffffc0201840:	00001517          	auipc	a0,0x1
ffffffffc0201844:	5a850513          	addi	a0,a0,1448 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201848:	97ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(slab->free_count <= slab->object_count);
ffffffffc020184c:	00001697          	auipc	a3,0x1
ffffffffc0201850:	66468693          	addi	a3,a3,1636 # ffffffffc0202eb0 <buddy_pmm_manager+0x2a0>
ffffffffc0201854:	00001617          	auipc	a2,0x1
ffffffffc0201858:	f8460613          	addi	a2,a2,-124 # ffffffffc02027d8 <etext+0x270>
ffffffffc020185c:	0c300593          	li	a1,195
ffffffffc0201860:	00001517          	auipc	a0,0x1
ffffffffc0201864:	58850513          	addi	a0,a0,1416 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201868:	95ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(used + slab->free_count == slab->object_count);
ffffffffc020186c:	00001697          	auipc	a3,0x1
ffffffffc0201870:	74c68693          	addi	a3,a3,1868 # ffffffffc0202fb8 <buddy_pmm_manager+0x3a8>
ffffffffc0201874:	00001617          	auipc	a2,0x1
ffffffffc0201878:	f6460613          	addi	a2,a2,-156 # ffffffffc02027d8 <etext+0x270>
ffffffffc020187c:	0e200593          	li	a1,226
ffffffffc0201880:	00001517          	auipc	a0,0x1
ffffffffc0201884:	56850513          	addi	a0,a0,1384 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201888:	93ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(slab->start == (void *)(page2pa(slab->page) + va_pa_offset));
ffffffffc020188c:	00001697          	auipc	a3,0x1
ffffffffc0201890:	5e468693          	addi	a3,a3,1508 # ffffffffc0202e70 <buddy_pmm_manager+0x260>
ffffffffc0201894:	00001617          	auipc	a2,0x1
ffffffffc0201898:	f4460613          	addi	a2,a2,-188 # ffffffffc02027d8 <etext+0x270>
ffffffffc020189c:	0c200593          	li	a1,194
ffffffffc02018a0:	00001517          	auipc	a0,0x1
ffffffffc02018a4:	54850513          	addi	a0,a0,1352 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc02018a8:	91ffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(slab->object_count == PGSIZE / slab->object_size);
ffffffffc02018ac:	00001697          	auipc	a3,0x1
ffffffffc02018b0:	58c68693          	addi	a3,a3,1420 # ffffffffc0202e38 <buddy_pmm_manager+0x228>
ffffffffc02018b4:	00001617          	auipc	a2,0x1
ffffffffc02018b8:	f2460613          	addi	a2,a2,-220 # ffffffffc02027d8 <etext+0x270>
ffffffffc02018bc:	0c100593          	li	a1,193
ffffffffc02018c0:	00001517          	auipc	a0,0x1
ffffffffc02018c4:	52850513          	addi	a0,a0,1320 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc02018c8:	8fffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(slab->object_size == slub_class_sizes[slab->class_index]);
ffffffffc02018cc:	00001697          	auipc	a3,0x1
ffffffffc02018d0:	52c68693          	addi	a3,a3,1324 # ffffffffc0202df8 <buddy_pmm_manager+0x1e8>
ffffffffc02018d4:	00001617          	auipc	a2,0x1
ffffffffc02018d8:	f0460613          	addi	a2,a2,-252 # ffffffffc02027d8 <etext+0x270>
ffffffffc02018dc:	0c000593          	li	a1,192
ffffffffc02018e0:	00001517          	auipc	a0,0x1
ffffffffc02018e4:	50850513          	addi	a0,a0,1288 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc02018e8:	8dffe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(slab->active);
ffffffffc02018ec:	00001697          	auipc	a3,0x1
ffffffffc02018f0:	4ec68693          	addi	a3,a3,1260 # ffffffffc0202dd8 <buddy_pmm_manager+0x1c8>
ffffffffc02018f4:	00001617          	auipc	a2,0x1
ffffffffc02018f8:	ee460613          	addi	a2,a2,-284 # ffffffffc02027d8 <etext+0x270>
ffffffffc02018fc:	0bf00593          	li	a1,191
ffffffffc0201900:	00001517          	auipc	a0,0x1
ffffffffc0201904:	4e850513          	addi	a0,a0,1256 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201908:	8bffe0ef          	jal	ra,ffffffffc02001c6 <__panic>

ffffffffc020190c <slub_alloc.part.0>:
slub_alloc(size_t size) {
ffffffffc020190c:	7139                	addi	sp,sp,-64
ffffffffc020190e:	f822                	sd	s0,48(sp)
ffffffffc0201910:	f426                	sd	s1,40(sp)
ffffffffc0201912:	fc06                	sd	ra,56(sp)
ffffffffc0201914:	f04a                	sd	s2,32(sp)
ffffffffc0201916:	ec4e                	sd	s3,24(sp)
ffffffffc0201918:	e852                	sd	s4,16(sp)
ffffffffc020191a:	e456                	sd	s5,8(sp)
ffffffffc020191c:	e05a                	sd	s6,0(sp)
ffffffffc020191e:	44a1                	li	s1,8
ffffffffc0201920:	00002797          	auipc	a5,0x2
ffffffffc0201924:	ac878793          	addi	a5,a5,-1336 # ffffffffc02033e8 <slub_class_sizes+0x8>
    for (int i = 0; i < SLUB_CLASS_COUNT; i++) {
ffffffffc0201928:	4401                	li	s0,0
ffffffffc020192a:	4729                	li	a4,10
        if (size <= slub_class_sizes[i]) {
ffffffffc020192c:	00a4f963          	bgeu	s1,a0,ffffffffc020193e <slub_alloc.part.0+0x32>
    for (int i = 0; i < SLUB_CLASS_COUNT; i++) {
ffffffffc0201930:	2405                	addiw	s0,s0,1
ffffffffc0201932:	08e40263          	beq	s0,a4,ffffffffc02019b6 <slub_alloc.part.0+0xaa>
        if (size <= slub_class_sizes[i]) {
ffffffffc0201936:	6384                	ld	s1,0(a5)
ffffffffc0201938:	07a1                	addi	a5,a5,8
ffffffffc020193a:	fea4ebe3          	bltu	s1,a0,ffffffffc0201930 <slub_alloc.part.0+0x24>
ffffffffc020193e:	00005597          	auipc	a1,0x5
ffffffffc0201942:	7ea58593          	addi	a1,a1,2026 # ffffffffc0207128 <slub_slabs>
ffffffffc0201946:	8aae                	mv	s5,a1
ffffffffc0201948:	87ae                	mv	a5,a1
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc020194a:	4701                	li	a4,0
ffffffffc020194c:	04000613          	li	a2,64
ffffffffc0201950:	a031                	j	ffffffffc020195c <slub_alloc.part.0+0x50>
ffffffffc0201952:	2705                	addiw	a4,a4,1
ffffffffc0201954:	07878793          	addi	a5,a5,120
ffffffffc0201958:	06c70a63          	beq	a4,a2,ffffffffc02019cc <slub_alloc.part.0+0xc0>
        if (slab->active &&
ffffffffc020195c:	4394                	lw	a3,0(a5)
ffffffffc020195e:	daf5                	beqz	a3,ffffffffc0201952 <slub_alloc.part.0+0x46>
ffffffffc0201960:	43d4                	lw	a3,4(a5)
ffffffffc0201962:	fe8698e3          	bne	a3,s0,ffffffffc0201952 <slub_alloc.part.0+0x46>
            slab->class_index == class_index &&
ffffffffc0201966:	7794                	ld	a3,40(a5)
ffffffffc0201968:	d6ed                	beqz	a3,ffffffffc0201952 <slub_alloc.part.0+0x46>
        struct slub_slab *slab = &slub_slabs[i];
ffffffffc020196a:	00471913          	slli	s2,a4,0x4
ffffffffc020196e:	40e90933          	sub	s2,s2,a4
ffffffffc0201972:	090e                	slli	s2,s2,0x3
ffffffffc0201974:	9956                	add	s2,s2,s5
    if (slab == NULL || slab->free_list == NULL) {
ffffffffc0201976:	03093503          	ld	a0,48(s2)
ffffffffc020197a:	cd1d                	beqz	a0,ffffffffc02019b8 <slub_alloc.part.0+0xac>
    size_t index = ((uintptr_t)obj - (uintptr_t)slab->start) / slab->object_size;
ffffffffc020197c:	01093703          	ld	a4,16(s2)
ffffffffc0201980:	01893683          	ld	a3,24(s2)
    slab->free_count--;
ffffffffc0201984:	02893783          	ld	a5,40(s2)
    size_t index = ((uintptr_t)obj - (uintptr_t)slab->start) / slab->object_size;
ffffffffc0201988:	40e50733          	sub	a4,a0,a4
ffffffffc020198c:	02d75733          	divu	a4,a4,a3
    slab->free_count--;
ffffffffc0201990:	17fd                	addi	a5,a5,-1
    slab->free_list = *(void **)obj;
ffffffffc0201992:	6114                	ld	a3,0(a0)
    slab->free_count--;
ffffffffc0201994:	02f93423          	sd	a5,40(s2)
    slab->free_list = *(void **)obj;
ffffffffc0201998:	02d93823          	sd	a3,48(s2)
    slab->used_bitmap[index / 64] |= 1ULL << (index % 64);
ffffffffc020199c:	4685                	li	a3,1
ffffffffc020199e:	00675793          	srli	a5,a4,0x6
ffffffffc02019a2:	078e                	slli	a5,a5,0x3
ffffffffc02019a4:	993e                	add	s2,s2,a5
ffffffffc02019a6:	03893783          	ld	a5,56(s2)
ffffffffc02019aa:	00e69733          	sll	a4,a3,a4
ffffffffc02019ae:	8f5d                	or	a4,a4,a5
ffffffffc02019b0:	02e93c23          	sd	a4,56(s2)
    return obj;
ffffffffc02019b4:	a011                	j	ffffffffc02019b8 <slub_alloc.part.0+0xac>
        return NULL;
ffffffffc02019b6:	4501                	li	a0,0
}
ffffffffc02019b8:	70e2                	ld	ra,56(sp)
ffffffffc02019ba:	7442                	ld	s0,48(sp)
ffffffffc02019bc:	74a2                	ld	s1,40(sp)
ffffffffc02019be:	7902                	ld	s2,32(sp)
ffffffffc02019c0:	69e2                	ld	s3,24(sp)
ffffffffc02019c2:	6a42                	ld	s4,16(sp)
ffffffffc02019c4:	6aa2                	ld	s5,8(sp)
ffffffffc02019c6:	6b02                	ld	s6,0(sp)
ffffffffc02019c8:	6121                	addi	sp,sp,64
ffffffffc02019ca:	8082                	ret
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc02019cc:	4781                	li	a5,0
ffffffffc02019ce:	04000693          	li	a3,64
ffffffffc02019d2:	a021                	j	ffffffffc02019da <slub_alloc.part.0+0xce>
ffffffffc02019d4:	2785                	addiw	a5,a5,1
ffffffffc02019d6:	fed780e3          	beq	a5,a3,ffffffffc02019b6 <slub_alloc.part.0+0xaa>
        if (!slub_slabs[i].active) {
ffffffffc02019da:	4198                	lw	a4,0(a1)
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc02019dc:	07858593          	addi	a1,a1,120
        if (!slub_slabs[i].active) {
ffffffffc02019e0:	fb75                	bnez	a4,ffffffffc02019d4 <slub_alloc.part.0+0xc8>
            slab = &slub_slabs[i];
ffffffffc02019e2:	00479a13          	slli	s4,a5,0x4
ffffffffc02019e6:	40fa07b3          	sub	a5,s4,a5
    struct Page *page = alloc_pages(1);
ffffffffc02019ea:	4505                	li	a0,1
ffffffffc02019ec:	00379a13          	slli	s4,a5,0x3
ffffffffc02019f0:	9cdff0ef          	jal	ra,ffffffffc02013bc <alloc_pages>
ffffffffc02019f4:	872a                	mv	a4,a0
            slab = &slub_slabs[i];
ffffffffc02019f6:	014a8933          	add	s2,s5,s4
    if (page == NULL) {
ffffffffc02019fa:	dd55                	beqz	a0,ffffffffc02019b6 <slub_alloc.part.0+0xaa>
    size_t object_count = PGSIZE / object_size;
ffffffffc02019fc:	6b05                	lui	s6,0x1
ffffffffc02019fe:	029b59b3          	divu	s3,s6,s1
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201a02:	00007797          	auipc	a5,0x7
ffffffffc0201a06:	54e7b783          	ld	a5,1358(a5) # ffffffffc0208f50 <pages>
ffffffffc0201a0a:	40f507b3          	sub	a5,a0,a5
    slab->page = page;
ffffffffc0201a0e:	00e93423          	sd	a4,8(s2)
ffffffffc0201a12:	878d                	srai	a5,a5,0x3
ffffffffc0201a14:	00002717          	auipc	a4,0x2
ffffffffc0201a18:	c6473703          	ld	a4,-924(a4) # ffffffffc0203678 <error_string+0x38>
    slab->active = 1;
ffffffffc0201a1c:	4685                	li	a3,1
    memset(slab->used_bitmap, 0, sizeof(slab->used_bitmap));
ffffffffc0201a1e:	038a0a13          	addi	s4,s4,56
ffffffffc0201a22:	04000613          	li	a2,64
ffffffffc0201a26:	4581                	li	a1,0
ffffffffc0201a28:	014a8533          	add	a0,s5,s4
    slab->active = 1;
ffffffffc0201a2c:	00d92023          	sw	a3,0(s2)
    slab->class_index = class_index;
ffffffffc0201a30:	00892223          	sw	s0,4(s2)
    slab->object_size = object_size;
ffffffffc0201a34:	00993c23          	sd	s1,24(s2)
ffffffffc0201a38:	02e787b3          	mul	a5,a5,a4
ffffffffc0201a3c:	00002717          	auipc	a4,0x2
ffffffffc0201a40:	c4c73703          	ld	a4,-948(a4) # ffffffffc0203688 <nbase>
    slab->object_count = object_count;
ffffffffc0201a44:	03393023          	sd	s3,32(s2)
    slab->free_count = object_count;
ffffffffc0201a48:	03393423          	sd	s3,40(s2)
ffffffffc0201a4c:	97ba                	add	a5,a5,a4
    return page2ppn(page) << PGSHIFT;
ffffffffc0201a4e:	07b2                	slli	a5,a5,0xc
    slab->start = (void *)(page2pa(page) + va_pa_offset);
ffffffffc0201a50:	00007717          	auipc	a4,0x7
ffffffffc0201a54:	52073703          	ld	a4,1312(a4) # ffffffffc0208f70 <va_pa_offset>
ffffffffc0201a58:	97ba                	add	a5,a5,a4
ffffffffc0201a5a:	00f93823          	sd	a5,16(s2)
    slab->free_list = slab->start;
ffffffffc0201a5e:	02f93823          	sd	a5,48(s2)
    memset(slab->used_bitmap, 0, sizeof(slab->used_bitmap));
ffffffffc0201a62:	2f5000ef          	jal	ra,ffffffffc0202556 <memset>
    char *base = (char *)slab->start;
ffffffffc0201a66:	01093703          	ld	a4,16(s2)
    for (size_t i = 0; i < object_count; i++) {
ffffffffc0201a6a:	f09b66e3          	bltu	s6,s1,ffffffffc0201976 <slub_alloc.part.0+0x6a>
ffffffffc0201a6e:	4781                	li	a5,0
        void *next = (i + 1 < object_count)
ffffffffc0201a70:	0785                	addi	a5,a5,1
        *(void **)obj = next;
ffffffffc0201a72:	009706b3          	add	a3,a4,s1
                         : NULL;
ffffffffc0201a76:	0137f963          	bgeu	a5,s3,ffffffffc0201a88 <slub_alloc.part.0+0x17c>
        *(void **)obj = next;
ffffffffc0201a7a:	e314                	sd	a3,0(a4)
        void *next = (i + 1 < object_count)
ffffffffc0201a7c:	0785                	addi	a5,a5,1
    for (size_t i = 0; i < object_count; i++) {
ffffffffc0201a7e:	8736                	mv	a4,a3
        *(void **)obj = next;
ffffffffc0201a80:	009706b3          	add	a3,a4,s1
                         : NULL;
ffffffffc0201a84:	ff37ebe3          	bltu	a5,s3,ffffffffc0201a7a <slub_alloc.part.0+0x16e>
        *(void **)obj = next;
ffffffffc0201a88:	00073023          	sd	zero,0(a4)
    for (size_t i = 0; i < object_count; i++) {
ffffffffc0201a8c:	b5ed                	j	ffffffffc0201976 <slub_alloc.part.0+0x6a>

ffffffffc0201a8e <slub_free.part.0>:
slub_free(void *ptr) {
ffffffffc0201a8e:	1141                	addi	sp,sp,-16
ffffffffc0201a90:	00005617          	auipc	a2,0x5
ffffffffc0201a94:	69860613          	addi	a2,a2,1688 # ffffffffc0207128 <slub_slabs>
ffffffffc0201a98:	e406                	sd	ra,8(sp)
ffffffffc0201a9a:	8732                	mv	a4,a2
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201a9c:	4681                	li	a3,0
        uintptr_t end = start + PGSIZE;
ffffffffc0201a9e:	6885                	lui	a7,0x1
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201aa0:	04000593          	li	a1,64
        if (!slab->active) {
ffffffffc0201aa4:	431c                	lw	a5,0(a4)
ffffffffc0201aa6:	c7a5                	beqz	a5,ffffffffc0201b0e <slub_free.part.0+0x80>
        uintptr_t start = (uintptr_t)slab->start;
ffffffffc0201aa8:	6b1c                	ld	a5,16(a4)
        if (addr < start || addr >= end) {
ffffffffc0201aaa:	06f56263          	bltu	a0,a5,ffffffffc0201b0e <slub_free.part.0+0x80>
        uintptr_t end = start + PGSIZE;
ffffffffc0201aae:	01178833          	add	a6,a5,a7
        if (addr < start || addr >= end) {
ffffffffc0201ab2:	05057e63          	bgeu	a0,a6,ffffffffc0201b0e <slub_free.part.0+0x80>
        if (offset % slab->object_size != 0) {
ffffffffc0201ab6:	00469713          	slli	a4,a3,0x4
ffffffffc0201aba:	8f15                	sub	a4,a4,a3
ffffffffc0201abc:	00371693          	slli	a3,a4,0x3
ffffffffc0201ac0:	96b2                	add	a3,a3,a2
ffffffffc0201ac2:	6e8c                	ld	a1,24(a3)
        size_t offset = addr - start;
ffffffffc0201ac4:	40f507b3          	sub	a5,a0,a5
        if (offset % slab->object_size != 0) {
ffffffffc0201ac8:	02b7f833          	remu	a6,a5,a1
ffffffffc0201acc:	08081a63          	bnez	a6,ffffffffc0201b60 <slub_free.part.0+0xd2>
        size_t index = offset / slab->object_size;
ffffffffc0201ad0:	02b7d7b3          	divu	a5,a5,a1
        if (index >= slab->object_count) {
ffffffffc0201ad4:	728c                	ld	a1,32(a3)
ffffffffc0201ad6:	06b7f963          	bgeu	a5,a1,ffffffffc0201b48 <slub_free.part.0+0xba>
        uint64_t *word = &slab->used_bitmap[index / 64];
ffffffffc0201ada:	0067d593          	srli	a1,a5,0x6
        if ((*word & mask) == 0) {
ffffffffc0201ade:	972e                	add	a4,a4,a1
ffffffffc0201ae0:	0719                	addi	a4,a4,6
ffffffffc0201ae2:	070e                	slli	a4,a4,0x3
ffffffffc0201ae4:	9732                	add	a4,a4,a2
ffffffffc0201ae6:	670c                	ld	a1,8(a4)
        uint64_t mask = 1ULL << (index % 64);
ffffffffc0201ae8:	4605                	li	a2,1
ffffffffc0201aea:	00f617b3          	sll	a5,a2,a5
        if ((*word & mask) == 0) {
ffffffffc0201aee:	00b7f633          	and	a2,a5,a1
ffffffffc0201af2:	ce1d                	beqz	a2,ffffffffc0201b30 <slub_free.part.0+0xa2>
        *(void **)ptr = slab->free_list;
ffffffffc0201af4:	7a90                	ld	a2,48(a3)
        *word &= ~mask;
ffffffffc0201af6:	fff7c793          	not	a5,a5
ffffffffc0201afa:	8fed                	and	a5,a5,a1
ffffffffc0201afc:	e71c                	sd	a5,8(a4)
        *(void **)ptr = slab->free_list;
ffffffffc0201afe:	e110                	sd	a2,0(a0)
        slab->free_count++;
ffffffffc0201b00:	769c                	ld	a5,40(a3)
}
ffffffffc0201b02:	60a2                	ld	ra,8(sp)
        slab->free_list = ptr;
ffffffffc0201b04:	fa88                	sd	a0,48(a3)
        slab->free_count++;
ffffffffc0201b06:	0785                	addi	a5,a5,1
ffffffffc0201b08:	f69c                	sd	a5,40(a3)
}
ffffffffc0201b0a:	0141                	addi	sp,sp,16
ffffffffc0201b0c:	8082                	ret
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201b0e:	2685                	addiw	a3,a3,1
ffffffffc0201b10:	07870713          	addi	a4,a4,120
ffffffffc0201b14:	f8b698e3          	bne	a3,a1,ffffffffc0201aa4 <slub_free.part.0+0x16>
    panic("slub_free: pointer does not belong to SLUB");
ffffffffc0201b18:	00001617          	auipc	a2,0x1
ffffffffc0201b1c:	54060613          	addi	a2,a2,1344 # ffffffffc0203058 <buddy_pmm_manager+0x448>
ffffffffc0201b20:	0b900593          	li	a1,185
ffffffffc0201b24:	00001517          	auipc	a0,0x1
ffffffffc0201b28:	2c450513          	addi	a0,a0,708 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201b2c:	e9afe0ef          	jal	ra,ffffffffc02001c6 <__panic>
            panic("slub_free: double free or invalid object");
ffffffffc0201b30:	00001617          	auipc	a2,0x1
ffffffffc0201b34:	4f860613          	addi	a2,a2,1272 # ffffffffc0203028 <buddy_pmm_manager+0x418>
ffffffffc0201b38:	0af00593          	li	a1,175
ffffffffc0201b3c:	00001517          	auipc	a0,0x1
ffffffffc0201b40:	2ac50513          	addi	a0,a0,684 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201b44:	e82fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
            panic("slub_free: invalid object");
ffffffffc0201b48:	00001617          	auipc	a2,0x1
ffffffffc0201b4c:	4c060613          	addi	a2,a2,1216 # ffffffffc0203008 <buddy_pmm_manager+0x3f8>
ffffffffc0201b50:	0a900593          	li	a1,169
ffffffffc0201b54:	00001517          	auipc	a0,0x1
ffffffffc0201b58:	29450513          	addi	a0,a0,660 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201b5c:	e6afe0ef          	jal	ra,ffffffffc02001c6 <__panic>
            panic("slub_free: misaligned object");
ffffffffc0201b60:	00001617          	auipc	a2,0x1
ffffffffc0201b64:	48860613          	addi	a2,a2,1160 # ffffffffc0202fe8 <buddy_pmm_manager+0x3d8>
ffffffffc0201b68:	0a400593          	li	a1,164
ffffffffc0201b6c:	00001517          	auipc	a0,0x1
ffffffffc0201b70:	27c50513          	addi	a0,a0,636 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201b74:	e52fe0ef          	jal	ra,ffffffffc02001c6 <__panic>

ffffffffc0201b78 <slub_init>:
    memset(slub_slabs, 0, sizeof(slub_slabs));
ffffffffc0201b78:	6609                	lui	a2,0x2
slub_init(void) {
ffffffffc0201b7a:	7169                	addi	sp,sp,-304
    memset(slub_slabs, 0, sizeof(slub_slabs));
ffffffffc0201b7c:	e0060613          	addi	a2,a2,-512 # 1e00 <kern_entry-0xffffffffc01fe200>
ffffffffc0201b80:	4581                	li	a1,0
ffffffffc0201b82:	00005517          	auipc	a0,0x5
ffffffffc0201b86:	5a650513          	addi	a0,a0,1446 # ffffffffc0207128 <slub_slabs>
slub_init(void) {
ffffffffc0201b8a:	f606                	sd	ra,296(sp)
ffffffffc0201b8c:	f222                	sd	s0,288(sp)
ffffffffc0201b8e:	ee26                	sd	s1,280(sp)
ffffffffc0201b90:	ea4a                	sd	s2,272(sp)
ffffffffc0201b92:	e64e                	sd	s3,264(sp)
ffffffffc0201b94:	e252                	sd	s4,256(sp)
ffffffffc0201b96:	fdd6                	sd	s5,248(sp)
ffffffffc0201b98:	f9da                	sd	s6,240(sp)
ffffffffc0201b9a:	f5de                	sd	s7,232(sp)
ffffffffc0201b9c:	f1e2                	sd	s8,224(sp)
ffffffffc0201b9e:	ede6                	sd	s9,216(sp)
ffffffffc0201ba0:	e9ea                	sd	s10,208(sp)
    memset(slub_slabs, 0, sizeof(slub_slabs));
ffffffffc0201ba2:	1b5000ef          	jal	ra,ffffffffc0202556 <memset>
    slub_ready = 1;
ffffffffc0201ba6:	4785                	li	a5,1
ffffffffc0201ba8:	00007a17          	auipc	s4,0x7
ffffffffc0201bac:	3d0a0a13          	addi	s4,s4,976 # ffffffffc0208f78 <slub_ready>
    cprintf("SLUB initialized\n");
ffffffffc0201bb0:	00001517          	auipc	a0,0x1
ffffffffc0201bb4:	4d850513          	addi	a0,a0,1240 # ffffffffc0203088 <buddy_pmm_manager+0x478>
    slub_ready = 1;
ffffffffc0201bb8:	00fa2023          	sw	a5,0(s4)
    cprintf("SLUB initialized\n");
ffffffffc0201bbc:	d94fe0ef          	jal	ra,ffffffffc0200150 <cprintf>
    }
}

static void
slub_check(void) {
    size_t before_pages = nr_free_pages();
ffffffffc0201bc0:	815ff0ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0201bc4:	89aa                	mv	s3,a0
ffffffffc0201bc6:	00005917          	auipc	s2,0x5
ffffffffc0201bca:	56290913          	addi	s2,s2,1378 # ffffffffc0207128 <slub_slabs>

    cprintf("slub_check: begin\n");
ffffffffc0201bce:	00001517          	auipc	a0,0x1
ffffffffc0201bd2:	4d250513          	addi	a0,a0,1234 # ffffffffc02030a0 <buddy_pmm_manager+0x490>
ffffffffc0201bd6:	00007497          	auipc	s1,0x7
ffffffffc0201bda:	35248493          	addi	s1,s1,850 # ffffffffc0208f28 <is_panic>
ffffffffc0201bde:	d72fe0ef          	jal	ra,ffffffffc0200150 <cprintf>
ffffffffc0201be2:	844a                	mv	s0,s2
ffffffffc0201be4:	a029                	j	ffffffffc0201bee <slub_init+0x76>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201be6:	07840413          	addi	s0,s0,120
ffffffffc0201bea:	00940b63          	beq	s0,s1,ffffffffc0201c00 <slub_init+0x88>
        if (slub_slabs[i].active) {
ffffffffc0201bee:	401c                	lw	a5,0(s0)
ffffffffc0201bf0:	dbfd                	beqz	a5,ffffffffc0201be6 <slub_init+0x6e>
            slub_check_slab(&slub_slabs[i]);
ffffffffc0201bf2:	8522                	mv	a0,s0
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201bf4:	07840413          	addi	s0,s0,120
            slub_check_slab(&slub_slabs[i]);
ffffffffc0201bf8:	a43ff0ef          	jal	ra,ffffffffc020163a <slub_check_slab>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201bfc:	fe9419e3          	bne	s0,s1,ffffffffc0201bee <slub_init+0x76>
    if (!slub_ready || size == 0 || size > PGSIZE) {
ffffffffc0201c00:	000a2783          	lw	a5,0(s4)
ffffffffc0201c04:	28078863          	beqz	a5,ffffffffc0201e94 <slub_init+0x31c>
ffffffffc0201c08:	4505                	li	a0,1
ffffffffc0201c0a:	d03ff0ef          	jal	ra,ffffffffc020190c <slub_alloc.part.0>
ffffffffc0201c0e:	000a2783          	lw	a5,0(s4)
ffffffffc0201c12:	8aaa                	mv	s5,a0
ffffffffc0201c14:	28078063          	beqz	a5,ffffffffc0201e94 <slub_init+0x31c>
ffffffffc0201c18:	4521                	li	a0,8
ffffffffc0201c1a:	cf3ff0ef          	jal	ra,ffffffffc020190c <slub_alloc.part.0>
ffffffffc0201c1e:	000a2783          	lw	a5,0(s4)
ffffffffc0201c22:	842a                	mv	s0,a0
ffffffffc0201c24:	26078863          	beqz	a5,ffffffffc0201e94 <slub_init+0x31c>
ffffffffc0201c28:	04000513          	li	a0,64
ffffffffc0201c2c:	ce1ff0ef          	jal	ra,ffffffffc020190c <slub_alloc.part.0>
ffffffffc0201c30:	8b2a                	mv	s6,a0
    assert(p1 != NULL && p8 != NULL && p64 != NULL);
ffffffffc0201c32:	260a8163          	beqz	s5,ffffffffc0201e94 <slub_init+0x31c>
ffffffffc0201c36:	24040f63          	beqz	s0,ffffffffc0201e94 <slub_init+0x31c>
ffffffffc0201c3a:	24050d63          	beqz	a0,ffffffffc0201e94 <slub_init+0x31c>
    assert((uintptr_t)p1 % 8 == 0);
ffffffffc0201c3e:	007af793          	andi	a5,s5,7
ffffffffc0201c42:	40079963          	bnez	a5,ffffffffc0202054 <slub_init+0x4dc>
    assert((uintptr_t)p8 % 8 == 0);
ffffffffc0201c46:	00747793          	andi	a5,s0,7
ffffffffc0201c4a:	36079563          	bnez	a5,ffffffffc0201fb4 <slub_init+0x43c>
    assert((uintptr_t)p64 % 8 == 0);
ffffffffc0201c4e:	00757793          	andi	a5,a0,7
ffffffffc0201c52:	34079163          	bnez	a5,ffffffffc0201f94 <slub_init+0x41c>
    assert(p1 != p8 && p1 != p64 && p8 != p64);
ffffffffc0201c56:	308a8f63          	beq	s5,s0,ffffffffc0201f74 <slub_init+0x3fc>
ffffffffc0201c5a:	30aa8d63          	beq	s5,a0,ffffffffc0201f74 <slub_init+0x3fc>
ffffffffc0201c5e:	30a40b63          	beq	s0,a0,ffffffffc0201f74 <slub_init+0x3fc>
    memset(p1, 0xA1, 8);
ffffffffc0201c62:	4621                	li	a2,8
ffffffffc0201c64:	0a100593          	li	a1,161
ffffffffc0201c68:	8556                	mv	a0,s5
ffffffffc0201c6a:	0ed000ef          	jal	ra,ffffffffc0202556 <memset>
    memset(p8, 0xB2, 8);
ffffffffc0201c6e:	4621                	li	a2,8
ffffffffc0201c70:	0b200593          	li	a1,178
ffffffffc0201c74:	8522                	mv	a0,s0
ffffffffc0201c76:	0e1000ef          	jal	ra,ffffffffc0202556 <memset>
    memset(p64, 0xC3, 64);
ffffffffc0201c7a:	04000613          	li	a2,64
ffffffffc0201c7e:	0c300593          	li	a1,195
ffffffffc0201c82:	855a                	mv	a0,s6
ffffffffc0201c84:	0d3000ef          	jal	ra,ffffffffc0202556 <memset>
    assert(((unsigned char *)p1)[0] == 0xA1);
ffffffffc0201c88:	000ac783          	lbu	a5,0(s5)
ffffffffc0201c8c:	0a100713          	li	a4,161
ffffffffc0201c90:	2ce79263          	bne	a5,a4,ffffffffc0201f54 <slub_init+0x3dc>
    assert(((unsigned char *)p1)[7] == 0xA1);
ffffffffc0201c94:	007ac703          	lbu	a4,7(s5)
ffffffffc0201c98:	34f71e63          	bne	a4,a5,ffffffffc0201ff4 <slub_init+0x47c>
    assert(((unsigned char *)p8)[0] == 0xB2);
ffffffffc0201c9c:	00044783          	lbu	a5,0(s0)
ffffffffc0201ca0:	0b200713          	li	a4,178
ffffffffc0201ca4:	32e79863          	bne	a5,a4,ffffffffc0201fd4 <slub_init+0x45c>
    assert(((unsigned char *)p8)[7] == 0xB2);
ffffffffc0201ca8:	00744703          	lbu	a4,7(s0)
ffffffffc0201cac:	36f71463          	bne	a4,a5,ffffffffc0202014 <slub_init+0x49c>
    assert(((unsigned char *)p64)[0] == 0xC3);
ffffffffc0201cb0:	000b4783          	lbu	a5,0(s6) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0201cb4:	0c300713          	li	a4,195
ffffffffc0201cb8:	36e79e63          	bne	a5,a4,ffffffffc0202034 <slub_init+0x4bc>
    assert(((unsigned char *)p64)[63] == 0xC3);
ffffffffc0201cbc:	03fb4703          	lbu	a4,63(s6)
ffffffffc0201cc0:	3ef71a63          	bne	a4,a5,ffffffffc02020b4 <slub_init+0x53c>
    if (ptr == NULL) {
ffffffffc0201cc4:	8556                	mv	a0,s5
ffffffffc0201cc6:	dc9ff0ef          	jal	ra,ffffffffc0201a8e <slub_free.part.0>
ffffffffc0201cca:	8522                	mv	a0,s0
ffffffffc0201ccc:	dc3ff0ef          	jal	ra,ffffffffc0201a8e <slub_free.part.0>
ffffffffc0201cd0:	855a                	mv	a0,s6
ffffffffc0201cd2:	dbdff0ef          	jal	ra,ffffffffc0201a8e <slub_free.part.0>
    if (!slub_ready || size == 0 || size > PGSIZE) {
ffffffffc0201cd6:	000a2783          	lw	a5,0(s4)
ffffffffc0201cda:	1c078d63          	beqz	a5,ffffffffc0201eb4 <slub_init+0x33c>
ffffffffc0201cde:	4521                	li	a0,8
ffffffffc0201ce0:	c2dff0ef          	jal	ra,ffffffffc020190c <slub_alloc.part.0>
    assert(again != NULL);
ffffffffc0201ce4:	1c050863          	beqz	a0,ffffffffc0201eb4 <slub_init+0x33c>
    assert(again == p1 || again == p8);
ffffffffc0201ce8:	00aa8463          	beq	s5,a0,ffffffffc0201cf0 <slub_init+0x178>
ffffffffc0201cec:	3aa41463          	bne	s0,a0,ffffffffc0202094 <slub_init+0x51c>
    if (ptr == NULL) {
ffffffffc0201cf0:	d9fff0ef          	jal	ra,ffffffffc0201a8e <slub_free.part.0>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201cf4:	00005417          	auipc	s0,0x5
ffffffffc0201cf8:	43440413          	addi	s0,s0,1076 # ffffffffc0207128 <slub_slabs>
ffffffffc0201cfc:	a029                	j	ffffffffc0201d06 <slub_init+0x18e>
ffffffffc0201cfe:	07840413          	addi	s0,s0,120
ffffffffc0201d02:	00940b63          	beq	s0,s1,ffffffffc0201d18 <slub_init+0x1a0>
        if (slub_slabs[i].active) {
ffffffffc0201d06:	401c                	lw	a5,0(s0)
ffffffffc0201d08:	dbfd                	beqz	a5,ffffffffc0201cfe <slub_init+0x186>
            slub_check_slab(&slub_slabs[i]);
ffffffffc0201d0a:	8522                	mv	a0,s0
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201d0c:	07840413          	addi	s0,s0,120
            slub_check_slab(&slub_slabs[i]);
ffffffffc0201d10:	92bff0ef          	jal	ra,ffffffffc020163a <slub_check_slab>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201d14:	fe9419e3          	bne	s0,s1,ffffffffc0201d06 <slub_init+0x18e>
    const size_t requests[] = {
ffffffffc0201d18:	00001797          	auipc	a5,0x1
ffffffffc0201d1c:	66078793          	addi	a5,a5,1632 # ffffffffc0203378 <buddy_pmm_manager+0x768>
ffffffffc0201d20:	870a                	mv	a4,sp
ffffffffc0201d22:	00001817          	auipc	a6,0x1
ffffffffc0201d26:	6b680813          	addi	a6,a6,1718 # ffffffffc02033d8 <buddy_pmm_manager+0x7c8>
ffffffffc0201d2a:	6388                	ld	a0,0(a5)
ffffffffc0201d2c:	678c                	ld	a1,8(a5)
ffffffffc0201d2e:	6b90                	ld	a2,16(a5)
ffffffffc0201d30:	6f94                	ld	a3,24(a5)
ffffffffc0201d32:	e308                	sd	a0,0(a4)
ffffffffc0201d34:	e70c                	sd	a1,8(a4)
ffffffffc0201d36:	eb10                	sd	a2,16(a4)
ffffffffc0201d38:	ef14                	sd	a3,24(a4)
ffffffffc0201d3a:	02078793          	addi	a5,a5,32
ffffffffc0201d3e:	02070713          	addi	a4,a4,32
ffffffffc0201d42:	ff0794e3          	bne	a5,a6,ffffffffc0201d2a <slub_init+0x1b2>
ffffffffc0201d46:	639c                	ld	a5,0(a5)
ffffffffc0201d48:	8d0a                	mv	s10,sp
ffffffffc0201d4a:	10a0                	addi	s0,sp,104
ffffffffc0201d4c:	e31c                	sd	a5,0(a4)
ffffffffc0201d4e:	8b22                	mv	s6,s0
ffffffffc0201d50:	8c6a                	mv	s8,s10
ffffffffc0201d52:	04000a93          	li	s5,64
    if (!slub_ready || size == 0 || size > PGSIZE) {
ffffffffc0201d56:	6b85                	lui	s7,0x1
ffffffffc0201d58:	a815                	j	ffffffffc0201d8c <slub_init+0x214>
ffffffffc0201d5a:	fffc8793          	addi	a5,s9,-1
ffffffffc0201d5e:	0377fc63          	bgeu	a5,s7,ffffffffc0201d96 <slub_init+0x21e>
ffffffffc0201d62:	8566                	mv	a0,s9
ffffffffc0201d64:	ba9ff0ef          	jal	ra,ffffffffc020190c <slub_alloc.part.0>
        objects[i] = slub_alloc(requests[i]);
ffffffffc0201d68:	00ab3023          	sd	a0,0(s6)
        assert(objects[i] != NULL);
ffffffffc0201d6c:	c50d                	beqz	a0,ffffffffc0201d96 <slub_init+0x21e>
        assert((uintptr_t)objects[i] % 8 == 0);
ffffffffc0201d6e:	00757793          	andi	a5,a0,7
ffffffffc0201d72:	1a079163          	bnez	a5,ffffffffc0201f14 <slub_init+0x39c>
        memset(objects[i], (int)(0x40 + i), requests[i]);
ffffffffc0201d76:	85d6                	mv	a1,s5
ffffffffc0201d78:	8666                	mv	a2,s9
    for (size_t i = 0; i < count; i++) {
ffffffffc0201d7a:	2a85                	addiw	s5,s5,1
ffffffffc0201d7c:	0c21                	addi	s8,s8,8
        memset(objects[i], (int)(0x40 + i), requests[i]);
ffffffffc0201d7e:	7d8000ef          	jal	ra,ffffffffc0202556 <memset>
    for (size_t i = 0; i < count; i++) {
ffffffffc0201d82:	0ffafa93          	zext.b	s5,s5
ffffffffc0201d86:	0b21                	addi	s6,s6,8
ffffffffc0201d88:	028c0763          	beq	s8,s0,ffffffffc0201db6 <slub_init+0x23e>
    if (!slub_ready || size == 0 || size > PGSIZE) {
ffffffffc0201d8c:	000a2783          	lw	a5,0(s4)
        objects[i] = slub_alloc(requests[i]);
ffffffffc0201d90:	000c3c83          	ld	s9,0(s8) # ff0000 <kern_entry-0xffffffffbf210000>
    if (!slub_ready || size == 0 || size > PGSIZE) {
ffffffffc0201d94:	f3f9                	bnez	a5,ffffffffc0201d5a <slub_init+0x1e2>
        assert(objects[i] != NULL);
ffffffffc0201d96:	00001697          	auipc	a3,0x1
ffffffffc0201d9a:	4da68693          	addi	a3,a3,1242 # ffffffffc0203270 <buddy_pmm_manager+0x660>
ffffffffc0201d9e:	00001617          	auipc	a2,0x1
ffffffffc0201da2:	a3a60613          	addi	a2,a2,-1478 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201da6:	11d00593          	li	a1,285
ffffffffc0201daa:	00001517          	auipc	a0,0x1
ffffffffc0201dae:	03e50513          	addi	a0,a0,62 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201db2:	c14fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
ffffffffc0201db6:	86a2                	mv	a3,s0
ffffffffc0201db8:	04000793          	li	a5,64
    for (size_t i = 0; i < count; i++) {
ffffffffc0201dbc:	04d00593          	li	a1,77
        assert(((unsigned char *)objects[i])[0] == 0x40 + i);
ffffffffc0201dc0:	6298                	ld	a4,0(a3)
ffffffffc0201dc2:	00074603          	lbu	a2,0(a4)
ffffffffc0201dc6:	12f61763          	bne	a2,a5,ffffffffc0201ef4 <slub_init+0x37c>
        assert(((unsigned char *)objects[i])[requests[i] - 1] == 0x40 + i);
ffffffffc0201dca:	000d3603          	ld	a2,0(s10)
ffffffffc0201dce:	9732                	add	a4,a4,a2
ffffffffc0201dd0:	fff74703          	lbu	a4,-1(a4)
ffffffffc0201dd4:	16f71063          	bne	a4,a5,ffffffffc0201f34 <slub_init+0x3bc>
    for (size_t i = 0; i < count; i++) {
ffffffffc0201dd8:	0785                	addi	a5,a5,1
ffffffffc0201dda:	06a1                	addi	a3,a3,8
ffffffffc0201ddc:	0d21                	addi	s10,s10,8
ffffffffc0201dde:	feb791e3          	bne	a5,a1,ffffffffc0201dc0 <slub_init+0x248>
ffffffffc0201de2:	06840a13          	addi	s4,s0,104
        slub_free(objects[i]);
ffffffffc0201de6:	6008                	ld	a0,0(s0)
    if (ptr == NULL) {
ffffffffc0201de8:	c119                	beqz	a0,ffffffffc0201dee <slub_init+0x276>
ffffffffc0201dea:	ca5ff0ef          	jal	ra,ffffffffc0201a8e <slub_free.part.0>
    for (size_t i = 0; i < count; i++) {
ffffffffc0201dee:	0421                	addi	s0,s0,8
ffffffffc0201df0:	fe8a1be3          	bne	s4,s0,ffffffffc0201de6 <slub_init+0x26e>
ffffffffc0201df4:	00005417          	auipc	s0,0x5
ffffffffc0201df8:	33440413          	addi	s0,s0,820 # ffffffffc0207128 <slub_slabs>
ffffffffc0201dfc:	a029                	j	ffffffffc0201e06 <slub_init+0x28e>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201dfe:	07840413          	addi	s0,s0,120
ffffffffc0201e02:	00940b63          	beq	s0,s1,ffffffffc0201e18 <slub_init+0x2a0>
        if (slub_slabs[i].active) {
ffffffffc0201e06:	401c                	lw	a5,0(s0)
ffffffffc0201e08:	dbfd                	beqz	a5,ffffffffc0201dfe <slub_init+0x286>
            slub_check_slab(&slub_slabs[i]);
ffffffffc0201e0a:	8522                	mv	a0,s0
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201e0c:	07840413          	addi	s0,s0,120
            slub_check_slab(&slub_slabs[i]);
ffffffffc0201e10:	82bff0ef          	jal	ra,ffffffffc020163a <slub_check_slab>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201e14:	fe9419e3          	bne	s0,s1,ffffffffc0201e06 <slub_init+0x28e>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201e18:	00005417          	auipc	s0,0x5
ffffffffc0201e1c:	31040413          	addi	s0,s0,784 # ffffffffc0207128 <slub_slabs>
        if (!slab->active) {
ffffffffc0201e20:	401c                	lw	a5,0(s0)
ffffffffc0201e22:	cf99                	beqz	a5,ffffffffc0201e40 <slub_init+0x2c8>
        assert(slab->free_count == slab->object_count);
ffffffffc0201e24:	7418                	ld	a4,40(s0)
ffffffffc0201e26:	701c                	ld	a5,32(s0)
ffffffffc0201e28:	0af71663          	bne	a4,a5,ffffffffc0201ed4 <slub_init+0x35c>
        free_pages(slab->page, 1);
ffffffffc0201e2c:	6408                	ld	a0,8(s0)
ffffffffc0201e2e:	4585                	li	a1,1
ffffffffc0201e30:	d98ff0ef          	jal	ra,ffffffffc02013c8 <free_pages>
        memset(slab, 0, sizeof(*slab));
ffffffffc0201e34:	07800613          	li	a2,120
ffffffffc0201e38:	4581                	li	a1,0
ffffffffc0201e3a:	8522                	mv	a0,s0
ffffffffc0201e3c:	71a000ef          	jal	ra,ffffffffc0202556 <memset>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201e40:	07840413          	addi	s0,s0,120
ffffffffc0201e44:	fc941ee3          	bne	s0,s1,ffffffffc0201e20 <slub_init+0x2a8>
    slub_check_all();
    slub_check_basic();
    slub_check_sizes();
    slub_check_cleanup();

    assert(nr_free_pages() == before_pages);
ffffffffc0201e48:	d8cff0ef          	jal	ra,ffffffffc02013d4 <nr_free_pages>
ffffffffc0201e4c:	00a98763          	beq	s3,a0,ffffffffc0201e5a <slub_init+0x2e2>
ffffffffc0201e50:	a415                	j	ffffffffc0202074 <slub_init+0x4fc>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201e52:	07890913          	addi	s2,s2,120
ffffffffc0201e56:	00990c63          	beq	s2,s1,ffffffffc0201e6e <slub_init+0x2f6>
        if (slub_slabs[i].active) {
ffffffffc0201e5a:	00092783          	lw	a5,0(s2)
ffffffffc0201e5e:	dbf5                	beqz	a5,ffffffffc0201e52 <slub_init+0x2da>
            slub_check_slab(&slub_slabs[i]);
ffffffffc0201e60:	854a                	mv	a0,s2
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201e62:	07890913          	addi	s2,s2,120
            slub_check_slab(&slub_slabs[i]);
ffffffffc0201e66:	fd4ff0ef          	jal	ra,ffffffffc020163a <slub_check_slab>
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
ffffffffc0201e6a:	fe9918e3          	bne	s2,s1,ffffffffc0201e5a <slub_init+0x2e2>
}
ffffffffc0201e6e:	7412                	ld	s0,288(sp)
ffffffffc0201e70:	70b2                	ld	ra,296(sp)
ffffffffc0201e72:	64f2                	ld	s1,280(sp)
ffffffffc0201e74:	6952                	ld	s2,272(sp)
ffffffffc0201e76:	69b2                	ld	s3,264(sp)
ffffffffc0201e78:	6a12                	ld	s4,256(sp)
ffffffffc0201e7a:	7aee                	ld	s5,248(sp)
ffffffffc0201e7c:	7b4e                	ld	s6,240(sp)
ffffffffc0201e7e:	7bae                	ld	s7,232(sp)
ffffffffc0201e80:	7c0e                	ld	s8,224(sp)
ffffffffc0201e82:	6cee                	ld	s9,216(sp)
ffffffffc0201e84:	6d4e                	ld	s10,208(sp)
    slub_check_all();

    cprintf("slub_check: PASS\n");
ffffffffc0201e86:	00001517          	auipc	a0,0x1
ffffffffc0201e8a:	4da50513          	addi	a0,a0,1242 # ffffffffc0203360 <buddy_pmm_manager+0x750>
}
ffffffffc0201e8e:	6155                	addi	sp,sp,304
    cprintf("slub_check: PASS\n");
ffffffffc0201e90:	ac0fe06f          	j	ffffffffc0200150 <cprintf>
    assert(p1 != NULL && p8 != NULL && p64 != NULL);
ffffffffc0201e94:	00001697          	auipc	a3,0x1
ffffffffc0201e98:	22468693          	addi	a3,a3,548 # ffffffffc02030b8 <buddy_pmm_manager+0x4a8>
ffffffffc0201e9c:	00001617          	auipc	a2,0x1
ffffffffc0201ea0:	93c60613          	addi	a2,a2,-1732 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201ea4:	0f500593          	li	a1,245
ffffffffc0201ea8:	00001517          	auipc	a0,0x1
ffffffffc0201eac:	f4050513          	addi	a0,a0,-192 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201eb0:	b16fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(again != NULL);
ffffffffc0201eb4:	00001697          	auipc	a3,0x1
ffffffffc0201eb8:	38c68693          	addi	a3,a3,908 # ffffffffc0203240 <buddy_pmm_manager+0x630>
ffffffffc0201ebc:	00001617          	auipc	a2,0x1
ffffffffc0201ec0:	91c60613          	addi	a2,a2,-1764 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201ec4:	10b00593          	li	a1,267
ffffffffc0201ec8:	00001517          	auipc	a0,0x1
ffffffffc0201ecc:	f2050513          	addi	a0,a0,-224 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201ed0:	af6fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert(slab->free_count == slab->object_count);
ffffffffc0201ed4:	00001697          	auipc	a3,0x1
ffffffffc0201ed8:	44468693          	addi	a3,a3,1092 # ffffffffc0203318 <buddy_pmm_manager+0x708>
ffffffffc0201edc:	00001617          	auipc	a2,0x1
ffffffffc0201ee0:	8fc60613          	addi	a2,a2,-1796 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201ee4:	13900593          	li	a1,313
ffffffffc0201ee8:	00001517          	auipc	a0,0x1
ffffffffc0201eec:	f0050513          	addi	a0,a0,-256 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201ef0:	ad6fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert(((unsigned char *)objects[i])[0] == 0x40 + i);
ffffffffc0201ef4:	00001697          	auipc	a3,0x1
ffffffffc0201ef8:	3b468693          	addi	a3,a3,948 # ffffffffc02032a8 <buddy_pmm_manager+0x698>
ffffffffc0201efc:	00001617          	auipc	a2,0x1
ffffffffc0201f00:	8dc60613          	addi	a2,a2,-1828 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201f04:	12300593          	li	a1,291
ffffffffc0201f08:	00001517          	auipc	a0,0x1
ffffffffc0201f0c:	ee050513          	addi	a0,a0,-288 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201f10:	ab6fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert((uintptr_t)objects[i] % 8 == 0);
ffffffffc0201f14:	00001697          	auipc	a3,0x1
ffffffffc0201f18:	37468693          	addi	a3,a3,884 # ffffffffc0203288 <buddy_pmm_manager+0x678>
ffffffffc0201f1c:	00001617          	auipc	a2,0x1
ffffffffc0201f20:	8bc60613          	addi	a2,a2,-1860 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201f24:	11e00593          	li	a1,286
ffffffffc0201f28:	00001517          	auipc	a0,0x1
ffffffffc0201f2c:	ec050513          	addi	a0,a0,-320 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201f30:	a96fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
        assert(((unsigned char *)objects[i])[requests[i] - 1] == 0x40 + i);
ffffffffc0201f34:	00001697          	auipc	a3,0x1
ffffffffc0201f38:	3a468693          	addi	a3,a3,932 # ffffffffc02032d8 <buddy_pmm_manager+0x6c8>
ffffffffc0201f3c:	00001617          	auipc	a2,0x1
ffffffffc0201f40:	89c60613          	addi	a2,a2,-1892 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201f44:	12400593          	li	a1,292
ffffffffc0201f48:	00001517          	auipc	a0,0x1
ffffffffc0201f4c:	ea050513          	addi	a0,a0,-352 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201f50:	a76fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(((unsigned char *)p1)[0] == 0xA1);
ffffffffc0201f54:	00001697          	auipc	a3,0x1
ffffffffc0201f58:	1fc68693          	addi	a3,a3,508 # ffffffffc0203150 <buddy_pmm_manager+0x540>
ffffffffc0201f5c:	00001617          	auipc	a2,0x1
ffffffffc0201f60:	87c60613          	addi	a2,a2,-1924 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201f64:	0ff00593          	li	a1,255
ffffffffc0201f68:	00001517          	auipc	a0,0x1
ffffffffc0201f6c:	e8050513          	addi	a0,a0,-384 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201f70:	a56fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(p1 != p8 && p1 != p64 && p8 != p64);
ffffffffc0201f74:	00001697          	auipc	a3,0x1
ffffffffc0201f78:	1b468693          	addi	a3,a3,436 # ffffffffc0203128 <buddy_pmm_manager+0x518>
ffffffffc0201f7c:	00001617          	auipc	a2,0x1
ffffffffc0201f80:	85c60613          	addi	a2,a2,-1956 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201f84:	0f900593          	li	a1,249
ffffffffc0201f88:	00001517          	auipc	a0,0x1
ffffffffc0201f8c:	e6050513          	addi	a0,a0,-416 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201f90:	a36fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert((uintptr_t)p64 % 8 == 0);
ffffffffc0201f94:	00001697          	auipc	a3,0x1
ffffffffc0201f98:	17c68693          	addi	a3,a3,380 # ffffffffc0203110 <buddy_pmm_manager+0x500>
ffffffffc0201f9c:	00001617          	auipc	a2,0x1
ffffffffc0201fa0:	83c60613          	addi	a2,a2,-1988 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201fa4:	0f800593          	li	a1,248
ffffffffc0201fa8:	00001517          	auipc	a0,0x1
ffffffffc0201fac:	e4050513          	addi	a0,a0,-448 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201fb0:	a16fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert((uintptr_t)p8 % 8 == 0);
ffffffffc0201fb4:	00001697          	auipc	a3,0x1
ffffffffc0201fb8:	14468693          	addi	a3,a3,324 # ffffffffc02030f8 <buddy_pmm_manager+0x4e8>
ffffffffc0201fbc:	00001617          	auipc	a2,0x1
ffffffffc0201fc0:	81c60613          	addi	a2,a2,-2020 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201fc4:	0f700593          	li	a1,247
ffffffffc0201fc8:	00001517          	auipc	a0,0x1
ffffffffc0201fcc:	e2050513          	addi	a0,a0,-480 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201fd0:	9f6fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(((unsigned char *)p8)[0] == 0xB2);
ffffffffc0201fd4:	00001697          	auipc	a3,0x1
ffffffffc0201fd8:	1cc68693          	addi	a3,a3,460 # ffffffffc02031a0 <buddy_pmm_manager+0x590>
ffffffffc0201fdc:	00000617          	auipc	a2,0x0
ffffffffc0201fe0:	7fc60613          	addi	a2,a2,2044 # ffffffffc02027d8 <etext+0x270>
ffffffffc0201fe4:	10100593          	li	a1,257
ffffffffc0201fe8:	00001517          	auipc	a0,0x1
ffffffffc0201fec:	e0050513          	addi	a0,a0,-512 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0201ff0:	9d6fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(((unsigned char *)p1)[7] == 0xA1);
ffffffffc0201ff4:	00001697          	auipc	a3,0x1
ffffffffc0201ff8:	18468693          	addi	a3,a3,388 # ffffffffc0203178 <buddy_pmm_manager+0x568>
ffffffffc0201ffc:	00000617          	auipc	a2,0x0
ffffffffc0202000:	7dc60613          	addi	a2,a2,2012 # ffffffffc02027d8 <etext+0x270>
ffffffffc0202004:	10000593          	li	a1,256
ffffffffc0202008:	00001517          	auipc	a0,0x1
ffffffffc020200c:	de050513          	addi	a0,a0,-544 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0202010:	9b6fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(((unsigned char *)p8)[7] == 0xB2);
ffffffffc0202014:	00001697          	auipc	a3,0x1
ffffffffc0202018:	1b468693          	addi	a3,a3,436 # ffffffffc02031c8 <buddy_pmm_manager+0x5b8>
ffffffffc020201c:	00000617          	auipc	a2,0x0
ffffffffc0202020:	7bc60613          	addi	a2,a2,1980 # ffffffffc02027d8 <etext+0x270>
ffffffffc0202024:	10200593          	li	a1,258
ffffffffc0202028:	00001517          	auipc	a0,0x1
ffffffffc020202c:	dc050513          	addi	a0,a0,-576 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0202030:	996fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(((unsigned char *)p64)[0] == 0xC3);
ffffffffc0202034:	00001697          	auipc	a3,0x1
ffffffffc0202038:	1bc68693          	addi	a3,a3,444 # ffffffffc02031f0 <buddy_pmm_manager+0x5e0>
ffffffffc020203c:	00000617          	auipc	a2,0x0
ffffffffc0202040:	79c60613          	addi	a2,a2,1948 # ffffffffc02027d8 <etext+0x270>
ffffffffc0202044:	10300593          	li	a1,259
ffffffffc0202048:	00001517          	auipc	a0,0x1
ffffffffc020204c:	da050513          	addi	a0,a0,-608 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0202050:	976fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert((uintptr_t)p1 % 8 == 0);
ffffffffc0202054:	00001697          	auipc	a3,0x1
ffffffffc0202058:	08c68693          	addi	a3,a3,140 # ffffffffc02030e0 <buddy_pmm_manager+0x4d0>
ffffffffc020205c:	00000617          	auipc	a2,0x0
ffffffffc0202060:	77c60613          	addi	a2,a2,1916 # ffffffffc02027d8 <etext+0x270>
ffffffffc0202064:	0f600593          	li	a1,246
ffffffffc0202068:	00001517          	auipc	a0,0x1
ffffffffc020206c:	d8050513          	addi	a0,a0,-640 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0202070:	956fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(nr_free_pages() == before_pages);
ffffffffc0202074:	00001697          	auipc	a3,0x1
ffffffffc0202078:	2cc68693          	addi	a3,a3,716 # ffffffffc0203340 <buddy_pmm_manager+0x730>
ffffffffc020207c:	00000617          	auipc	a2,0x0
ffffffffc0202080:	75c60613          	addi	a2,a2,1884 # ffffffffc02027d8 <etext+0x270>
ffffffffc0202084:	14a00593          	li	a1,330
ffffffffc0202088:	00001517          	auipc	a0,0x1
ffffffffc020208c:	d6050513          	addi	a0,a0,-672 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc0202090:	936fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(again == p1 || again == p8);
ffffffffc0202094:	00001697          	auipc	a3,0x1
ffffffffc0202098:	1bc68693          	addi	a3,a3,444 # ffffffffc0203250 <buddy_pmm_manager+0x640>
ffffffffc020209c:	00000617          	auipc	a2,0x0
ffffffffc02020a0:	73c60613          	addi	a2,a2,1852 # ffffffffc02027d8 <etext+0x270>
ffffffffc02020a4:	10c00593          	li	a1,268
ffffffffc02020a8:	00001517          	auipc	a0,0x1
ffffffffc02020ac:	d4050513          	addi	a0,a0,-704 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc02020b0:	916fe0ef          	jal	ra,ffffffffc02001c6 <__panic>
    assert(((unsigned char *)p64)[63] == 0xC3);
ffffffffc02020b4:	00001697          	auipc	a3,0x1
ffffffffc02020b8:	16468693          	addi	a3,a3,356 # ffffffffc0203218 <buddy_pmm_manager+0x608>
ffffffffc02020bc:	00000617          	auipc	a2,0x0
ffffffffc02020c0:	71c60613          	addi	a2,a2,1820 # ffffffffc02027d8 <etext+0x270>
ffffffffc02020c4:	10400593          	li	a1,260
ffffffffc02020c8:	00001517          	auipc	a0,0x1
ffffffffc02020cc:	d2050513          	addi	a0,a0,-736 # ffffffffc0202de8 <buddy_pmm_manager+0x1d8>
ffffffffc02020d0:	8f6fe0ef          	jal	ra,ffffffffc02001c6 <__panic>

ffffffffc02020d4 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02020d4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02020d8:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02020da:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02020de:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02020e0:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02020e4:	f022                	sd	s0,32(sp)
ffffffffc02020e6:	ec26                	sd	s1,24(sp)
ffffffffc02020e8:	e84a                	sd	s2,16(sp)
ffffffffc02020ea:	f406                	sd	ra,40(sp)
ffffffffc02020ec:	e44e                	sd	s3,8(sp)
ffffffffc02020ee:	84aa                	mv	s1,a0
ffffffffc02020f0:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02020f2:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02020f6:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02020f8:	03067e63          	bgeu	a2,a6,ffffffffc0202134 <printnum+0x60>
ffffffffc02020fc:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02020fe:	00805763          	blez	s0,ffffffffc020210c <printnum+0x38>
ffffffffc0202102:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0202104:	85ca                	mv	a1,s2
ffffffffc0202106:	854e                	mv	a0,s3
ffffffffc0202108:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020210a:	fc65                	bnez	s0,ffffffffc0202102 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020210c:	1a02                	slli	s4,s4,0x20
ffffffffc020210e:	00001797          	auipc	a5,0x1
ffffffffc0202112:	32278793          	addi	a5,a5,802 # ffffffffc0203430 <slub_class_sizes+0x50>
ffffffffc0202116:	020a5a13          	srli	s4,s4,0x20
ffffffffc020211a:	9a3e                	add	s4,s4,a5
}
ffffffffc020211c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020211e:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0202122:	70a2                	ld	ra,40(sp)
ffffffffc0202124:	69a2                	ld	s3,8(sp)
ffffffffc0202126:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202128:	85ca                	mv	a1,s2
ffffffffc020212a:	87a6                	mv	a5,s1
}
ffffffffc020212c:	6942                	ld	s2,16(sp)
ffffffffc020212e:	64e2                	ld	s1,24(sp)
ffffffffc0202130:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0202132:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0202134:	03065633          	divu	a2,a2,a6
ffffffffc0202138:	8722                	mv	a4,s0
ffffffffc020213a:	f9bff0ef          	jal	ra,ffffffffc02020d4 <printnum>
ffffffffc020213e:	b7f9                	j	ffffffffc020210c <printnum+0x38>

ffffffffc0202140 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0202140:	7119                	addi	sp,sp,-128
ffffffffc0202142:	f4a6                	sd	s1,104(sp)
ffffffffc0202144:	f0ca                	sd	s2,96(sp)
ffffffffc0202146:	ecce                	sd	s3,88(sp)
ffffffffc0202148:	e8d2                	sd	s4,80(sp)
ffffffffc020214a:	e4d6                	sd	s5,72(sp)
ffffffffc020214c:	e0da                	sd	s6,64(sp)
ffffffffc020214e:	fc5e                	sd	s7,56(sp)
ffffffffc0202150:	f06a                	sd	s10,32(sp)
ffffffffc0202152:	fc86                	sd	ra,120(sp)
ffffffffc0202154:	f8a2                	sd	s0,112(sp)
ffffffffc0202156:	f862                	sd	s8,48(sp)
ffffffffc0202158:	f466                	sd	s9,40(sp)
ffffffffc020215a:	ec6e                	sd	s11,24(sp)
ffffffffc020215c:	892a                	mv	s2,a0
ffffffffc020215e:	84ae                	mv	s1,a1
ffffffffc0202160:	8d32                	mv	s10,a2
ffffffffc0202162:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0202164:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0202168:	5b7d                	li	s6,-1
ffffffffc020216a:	00001a97          	auipc	s5,0x1
ffffffffc020216e:	2faa8a93          	addi	s5,s5,762 # ffffffffc0203464 <slub_class_sizes+0x84>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0202172:	00001b97          	auipc	s7,0x1
ffffffffc0202176:	4ceb8b93          	addi	s7,s7,1230 # ffffffffc0203640 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020217a:	000d4503          	lbu	a0,0(s10)
ffffffffc020217e:	001d0413          	addi	s0,s10,1
ffffffffc0202182:	01350a63          	beq	a0,s3,ffffffffc0202196 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0202186:	c121                	beqz	a0,ffffffffc02021c6 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0202188:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020218a:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020218c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020218e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0202192:	ff351ae3          	bne	a0,s3,ffffffffc0202186 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202196:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020219a:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020219e:	4c81                	li	s9,0
ffffffffc02021a0:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02021a2:	5c7d                	li	s8,-1
ffffffffc02021a4:	5dfd                	li	s11,-1
ffffffffc02021a6:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02021aa:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02021ac:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02021b0:	0ff5f593          	zext.b	a1,a1
ffffffffc02021b4:	00140d13          	addi	s10,s0,1
ffffffffc02021b8:	04b56263          	bltu	a0,a1,ffffffffc02021fc <vprintfmt+0xbc>
ffffffffc02021bc:	058a                	slli	a1,a1,0x2
ffffffffc02021be:	95d6                	add	a1,a1,s5
ffffffffc02021c0:	4194                	lw	a3,0(a1)
ffffffffc02021c2:	96d6                	add	a3,a3,s5
ffffffffc02021c4:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02021c6:	70e6                	ld	ra,120(sp)
ffffffffc02021c8:	7446                	ld	s0,112(sp)
ffffffffc02021ca:	74a6                	ld	s1,104(sp)
ffffffffc02021cc:	7906                	ld	s2,96(sp)
ffffffffc02021ce:	69e6                	ld	s3,88(sp)
ffffffffc02021d0:	6a46                	ld	s4,80(sp)
ffffffffc02021d2:	6aa6                	ld	s5,72(sp)
ffffffffc02021d4:	6b06                	ld	s6,64(sp)
ffffffffc02021d6:	7be2                	ld	s7,56(sp)
ffffffffc02021d8:	7c42                	ld	s8,48(sp)
ffffffffc02021da:	7ca2                	ld	s9,40(sp)
ffffffffc02021dc:	7d02                	ld	s10,32(sp)
ffffffffc02021de:	6de2                	ld	s11,24(sp)
ffffffffc02021e0:	6109                	addi	sp,sp,128
ffffffffc02021e2:	8082                	ret
            padc = '0';
ffffffffc02021e4:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02021e6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02021ea:	846a                	mv	s0,s10
ffffffffc02021ec:	00140d13          	addi	s10,s0,1
ffffffffc02021f0:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02021f4:	0ff5f593          	zext.b	a1,a1
ffffffffc02021f8:	fcb572e3          	bgeu	a0,a1,ffffffffc02021bc <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02021fc:	85a6                	mv	a1,s1
ffffffffc02021fe:	02500513          	li	a0,37
ffffffffc0202202:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0202204:	fff44783          	lbu	a5,-1(s0)
ffffffffc0202208:	8d22                	mv	s10,s0
ffffffffc020220a:	f73788e3          	beq	a5,s3,ffffffffc020217a <vprintfmt+0x3a>
ffffffffc020220e:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0202212:	1d7d                	addi	s10,s10,-1
ffffffffc0202214:	ff379de3          	bne	a5,s3,ffffffffc020220e <vprintfmt+0xce>
ffffffffc0202218:	b78d                	j	ffffffffc020217a <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020221a:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020221e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202222:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0202224:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0202228:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020222c:	02d86463          	bltu	a6,a3,ffffffffc0202254 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0202230:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0202234:	002c169b          	slliw	a3,s8,0x2
ffffffffc0202238:	0186873b          	addw	a4,a3,s8
ffffffffc020223c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0202240:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0202242:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0202246:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0202248:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020224c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0202250:	fed870e3          	bgeu	a6,a3,ffffffffc0202230 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0202254:	f40ddce3          	bgez	s11,ffffffffc02021ac <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0202258:	8de2                	mv	s11,s8
ffffffffc020225a:	5c7d                	li	s8,-1
ffffffffc020225c:	bf81                	j	ffffffffc02021ac <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020225e:	fffdc693          	not	a3,s11
ffffffffc0202262:	96fd                	srai	a3,a3,0x3f
ffffffffc0202264:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202268:	00144603          	lbu	a2,1(s0)
ffffffffc020226c:	2d81                	sext.w	s11,s11
ffffffffc020226e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0202270:	bf35                	j	ffffffffc02021ac <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0202272:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0202276:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020227a:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020227c:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020227e:	bfd9                	j	ffffffffc0202254 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0202280:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0202282:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0202286:	01174463          	blt	a4,a7,ffffffffc020228e <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020228a:	1a088e63          	beqz	a7,ffffffffc0202446 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020228e:	000a3603          	ld	a2,0(s4)
ffffffffc0202292:	46c1                	li	a3,16
ffffffffc0202294:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0202296:	2781                	sext.w	a5,a5
ffffffffc0202298:	876e                	mv	a4,s11
ffffffffc020229a:	85a6                	mv	a1,s1
ffffffffc020229c:	854a                	mv	a0,s2
ffffffffc020229e:	e37ff0ef          	jal	ra,ffffffffc02020d4 <printnum>
            break;
ffffffffc02022a2:	bde1                	j	ffffffffc020217a <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02022a4:	000a2503          	lw	a0,0(s4)
ffffffffc02022a8:	85a6                	mv	a1,s1
ffffffffc02022aa:	0a21                	addi	s4,s4,8
ffffffffc02022ac:	9902                	jalr	s2
            break;
ffffffffc02022ae:	b5f1                	j	ffffffffc020217a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02022b0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02022b2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02022b6:	01174463          	blt	a4,a7,ffffffffc02022be <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02022ba:	18088163          	beqz	a7,ffffffffc020243c <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02022be:	000a3603          	ld	a2,0(s4)
ffffffffc02022c2:	46a9                	li	a3,10
ffffffffc02022c4:	8a2e                	mv	s4,a1
ffffffffc02022c6:	bfc1                	j	ffffffffc0202296 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02022c8:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02022cc:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02022ce:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02022d0:	bdf1                	j	ffffffffc02021ac <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02022d2:	85a6                	mv	a1,s1
ffffffffc02022d4:	02500513          	li	a0,37
ffffffffc02022d8:	9902                	jalr	s2
            break;
ffffffffc02022da:	b545                	j	ffffffffc020217a <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02022dc:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02022e0:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02022e2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02022e4:	b5e1                	j	ffffffffc02021ac <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02022e6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02022e8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02022ec:	01174463          	blt	a4,a7,ffffffffc02022f4 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02022f0:	14088163          	beqz	a7,ffffffffc0202432 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02022f4:	000a3603          	ld	a2,0(s4)
ffffffffc02022f8:	46a1                	li	a3,8
ffffffffc02022fa:	8a2e                	mv	s4,a1
ffffffffc02022fc:	bf69                	j	ffffffffc0202296 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02022fe:	03000513          	li	a0,48
ffffffffc0202302:	85a6                	mv	a1,s1
ffffffffc0202304:	e03e                	sd	a5,0(sp)
ffffffffc0202306:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0202308:	85a6                	mv	a1,s1
ffffffffc020230a:	07800513          	li	a0,120
ffffffffc020230e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202310:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0202312:	6782                	ld	a5,0(sp)
ffffffffc0202314:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0202316:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020231a:	bfb5                	j	ffffffffc0202296 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020231c:	000a3403          	ld	s0,0(s4)
ffffffffc0202320:	008a0713          	addi	a4,s4,8
ffffffffc0202324:	e03a                	sd	a4,0(sp)
ffffffffc0202326:	14040263          	beqz	s0,ffffffffc020246a <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020232a:	0fb05763          	blez	s11,ffffffffc0202418 <vprintfmt+0x2d8>
ffffffffc020232e:	02d00693          	li	a3,45
ffffffffc0202332:	0cd79163          	bne	a5,a3,ffffffffc02023f4 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202336:	00044783          	lbu	a5,0(s0)
ffffffffc020233a:	0007851b          	sext.w	a0,a5
ffffffffc020233e:	cf85                	beqz	a5,ffffffffc0202376 <vprintfmt+0x236>
ffffffffc0202340:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202344:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202348:	000c4563          	bltz	s8,ffffffffc0202352 <vprintfmt+0x212>
ffffffffc020234c:	3c7d                	addiw	s8,s8,-1
ffffffffc020234e:	036c0263          	beq	s8,s6,ffffffffc0202372 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0202352:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202354:	0e0c8e63          	beqz	s9,ffffffffc0202450 <vprintfmt+0x310>
ffffffffc0202358:	3781                	addiw	a5,a5,-32
ffffffffc020235a:	0ef47b63          	bgeu	s0,a5,ffffffffc0202450 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020235e:	03f00513          	li	a0,63
ffffffffc0202362:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202364:	000a4783          	lbu	a5,0(s4)
ffffffffc0202368:	3dfd                	addiw	s11,s11,-1
ffffffffc020236a:	0a05                	addi	s4,s4,1
ffffffffc020236c:	0007851b          	sext.w	a0,a5
ffffffffc0202370:	ffe1                	bnez	a5,ffffffffc0202348 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0202372:	01b05963          	blez	s11,ffffffffc0202384 <vprintfmt+0x244>
ffffffffc0202376:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0202378:	85a6                	mv	a1,s1
ffffffffc020237a:	02000513          	li	a0,32
ffffffffc020237e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0202380:	fe0d9be3          	bnez	s11,ffffffffc0202376 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0202384:	6a02                	ld	s4,0(sp)
ffffffffc0202386:	bbd5                	j	ffffffffc020217a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0202388:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020238a:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020238e:	01174463          	blt	a4,a7,ffffffffc0202396 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0202392:	08088d63          	beqz	a7,ffffffffc020242c <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0202396:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020239a:	0a044d63          	bltz	s0,ffffffffc0202454 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020239e:	8622                	mv	a2,s0
ffffffffc02023a0:	8a66                	mv	s4,s9
ffffffffc02023a2:	46a9                	li	a3,10
ffffffffc02023a4:	bdcd                	j	ffffffffc0202296 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02023a6:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02023aa:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02023ac:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02023ae:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02023b2:	8fb5                	xor	a5,a5,a3
ffffffffc02023b4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02023b8:	02d74163          	blt	a4,a3,ffffffffc02023da <vprintfmt+0x29a>
ffffffffc02023bc:	00369793          	slli	a5,a3,0x3
ffffffffc02023c0:	97de                	add	a5,a5,s7
ffffffffc02023c2:	639c                	ld	a5,0(a5)
ffffffffc02023c4:	cb99                	beqz	a5,ffffffffc02023da <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02023c6:	86be                	mv	a3,a5
ffffffffc02023c8:	00001617          	auipc	a2,0x1
ffffffffc02023cc:	09860613          	addi	a2,a2,152 # ffffffffc0203460 <slub_class_sizes+0x80>
ffffffffc02023d0:	85a6                	mv	a1,s1
ffffffffc02023d2:	854a                	mv	a0,s2
ffffffffc02023d4:	0ce000ef          	jal	ra,ffffffffc02024a2 <printfmt>
ffffffffc02023d8:	b34d                	j	ffffffffc020217a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02023da:	00001617          	auipc	a2,0x1
ffffffffc02023de:	07660613          	addi	a2,a2,118 # ffffffffc0203450 <slub_class_sizes+0x70>
ffffffffc02023e2:	85a6                	mv	a1,s1
ffffffffc02023e4:	854a                	mv	a0,s2
ffffffffc02023e6:	0bc000ef          	jal	ra,ffffffffc02024a2 <printfmt>
ffffffffc02023ea:	bb41                	j	ffffffffc020217a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02023ec:	00001417          	auipc	s0,0x1
ffffffffc02023f0:	05c40413          	addi	s0,s0,92 # ffffffffc0203448 <slub_class_sizes+0x68>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02023f4:	85e2                	mv	a1,s8
ffffffffc02023f6:	8522                	mv	a0,s0
ffffffffc02023f8:	e43e                	sd	a5,8(sp)
ffffffffc02023fa:	0fc000ef          	jal	ra,ffffffffc02024f6 <strnlen>
ffffffffc02023fe:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0202402:	01b05b63          	blez	s11,ffffffffc0202418 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0202406:	67a2                	ld	a5,8(sp)
ffffffffc0202408:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020240c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020240e:	85a6                	mv	a1,s1
ffffffffc0202410:	8552                	mv	a0,s4
ffffffffc0202412:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0202414:	fe0d9ce3          	bnez	s11,ffffffffc020240c <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0202418:	00044783          	lbu	a5,0(s0)
ffffffffc020241c:	00140a13          	addi	s4,s0,1
ffffffffc0202420:	0007851b          	sext.w	a0,a5
ffffffffc0202424:	d3a5                	beqz	a5,ffffffffc0202384 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0202426:	05e00413          	li	s0,94
ffffffffc020242a:	bf39                	j	ffffffffc0202348 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020242c:	000a2403          	lw	s0,0(s4)
ffffffffc0202430:	b7ad                	j	ffffffffc020239a <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0202432:	000a6603          	lwu	a2,0(s4)
ffffffffc0202436:	46a1                	li	a3,8
ffffffffc0202438:	8a2e                	mv	s4,a1
ffffffffc020243a:	bdb1                	j	ffffffffc0202296 <vprintfmt+0x156>
ffffffffc020243c:	000a6603          	lwu	a2,0(s4)
ffffffffc0202440:	46a9                	li	a3,10
ffffffffc0202442:	8a2e                	mv	s4,a1
ffffffffc0202444:	bd89                	j	ffffffffc0202296 <vprintfmt+0x156>
ffffffffc0202446:	000a6603          	lwu	a2,0(s4)
ffffffffc020244a:	46c1                	li	a3,16
ffffffffc020244c:	8a2e                	mv	s4,a1
ffffffffc020244e:	b5a1                	j	ffffffffc0202296 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0202450:	9902                	jalr	s2
ffffffffc0202452:	bf09                	j	ffffffffc0202364 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0202454:	85a6                	mv	a1,s1
ffffffffc0202456:	02d00513          	li	a0,45
ffffffffc020245a:	e03e                	sd	a5,0(sp)
ffffffffc020245c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020245e:	6782                	ld	a5,0(sp)
ffffffffc0202460:	8a66                	mv	s4,s9
ffffffffc0202462:	40800633          	neg	a2,s0
ffffffffc0202466:	46a9                	li	a3,10
ffffffffc0202468:	b53d                	j	ffffffffc0202296 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020246a:	03b05163          	blez	s11,ffffffffc020248c <vprintfmt+0x34c>
ffffffffc020246e:	02d00693          	li	a3,45
ffffffffc0202472:	f6d79de3          	bne	a5,a3,ffffffffc02023ec <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0202476:	00001417          	auipc	s0,0x1
ffffffffc020247a:	fd240413          	addi	s0,s0,-46 # ffffffffc0203448 <slub_class_sizes+0x68>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020247e:	02800793          	li	a5,40
ffffffffc0202482:	02800513          	li	a0,40
ffffffffc0202486:	00140a13          	addi	s4,s0,1
ffffffffc020248a:	bd6d                	j	ffffffffc0202344 <vprintfmt+0x204>
ffffffffc020248c:	00001a17          	auipc	s4,0x1
ffffffffc0202490:	fbda0a13          	addi	s4,s4,-67 # ffffffffc0203449 <slub_class_sizes+0x69>
ffffffffc0202494:	02800513          	li	a0,40
ffffffffc0202498:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020249c:	05e00413          	li	s0,94
ffffffffc02024a0:	b565                	j	ffffffffc0202348 <vprintfmt+0x208>

ffffffffc02024a2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02024a2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02024a4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02024a8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02024aa:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02024ac:	ec06                	sd	ra,24(sp)
ffffffffc02024ae:	f83a                	sd	a4,48(sp)
ffffffffc02024b0:	fc3e                	sd	a5,56(sp)
ffffffffc02024b2:	e0c2                	sd	a6,64(sp)
ffffffffc02024b4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02024b6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02024b8:	c89ff0ef          	jal	ra,ffffffffc0202140 <vprintfmt>
}
ffffffffc02024bc:	60e2                	ld	ra,24(sp)
ffffffffc02024be:	6161                	addi	sp,sp,80
ffffffffc02024c0:	8082                	ret

ffffffffc02024c2 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02024c2:	4781                	li	a5,0
ffffffffc02024c4:	00005717          	auipc	a4,0x5
ffffffffc02024c8:	b4c73703          	ld	a4,-1204(a4) # ffffffffc0207010 <SBI_CONSOLE_PUTCHAR>
ffffffffc02024cc:	88ba                	mv	a7,a4
ffffffffc02024ce:	852a                	mv	a0,a0
ffffffffc02024d0:	85be                	mv	a1,a5
ffffffffc02024d2:	863e                	mv	a2,a5
ffffffffc02024d4:	00000073          	ecall
ffffffffc02024d8:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02024da:	8082                	ret

ffffffffc02024dc <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc02024dc:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc02024e0:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc02024e2:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc02024e4:	cb81                	beqz	a5,ffffffffc02024f4 <strlen+0x18>
        cnt ++;
ffffffffc02024e6:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc02024e8:	00a707b3          	add	a5,a4,a0
ffffffffc02024ec:	0007c783          	lbu	a5,0(a5)
ffffffffc02024f0:	fbfd                	bnez	a5,ffffffffc02024e6 <strlen+0xa>
ffffffffc02024f2:	8082                	ret
    }
    return cnt;
}
ffffffffc02024f4:	8082                	ret

ffffffffc02024f6 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02024f6:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02024f8:	e589                	bnez	a1,ffffffffc0202502 <strnlen+0xc>
ffffffffc02024fa:	a811                	j	ffffffffc020250e <strnlen+0x18>
        cnt ++;
ffffffffc02024fc:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02024fe:	00f58863          	beq	a1,a5,ffffffffc020250e <strnlen+0x18>
ffffffffc0202502:	00f50733          	add	a4,a0,a5
ffffffffc0202506:	00074703          	lbu	a4,0(a4)
ffffffffc020250a:	fb6d                	bnez	a4,ffffffffc02024fc <strnlen+0x6>
ffffffffc020250c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020250e:	852e                	mv	a0,a1
ffffffffc0202510:	8082                	ret

ffffffffc0202512 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202512:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202516:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020251a:	cb89                	beqz	a5,ffffffffc020252c <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc020251c:	0505                	addi	a0,a0,1
ffffffffc020251e:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0202520:	fee789e3          	beq	a5,a4,ffffffffc0202512 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202524:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0202528:	9d19                	subw	a0,a0,a4
ffffffffc020252a:	8082                	ret
ffffffffc020252c:	4501                	li	a0,0
ffffffffc020252e:	bfed                	j	ffffffffc0202528 <strcmp+0x16>

ffffffffc0202530 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202530:	c20d                	beqz	a2,ffffffffc0202552 <strncmp+0x22>
ffffffffc0202532:	962e                	add	a2,a2,a1
ffffffffc0202534:	a031                	j	ffffffffc0202540 <strncmp+0x10>
        n --, s1 ++, s2 ++;
ffffffffc0202536:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202538:	00e79a63          	bne	a5,a4,ffffffffc020254c <strncmp+0x1c>
ffffffffc020253c:	00b60b63          	beq	a2,a1,ffffffffc0202552 <strncmp+0x22>
ffffffffc0202540:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc0202544:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0202546:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020254a:	f7f5                	bnez	a5,ffffffffc0202536 <strncmp+0x6>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020254c:	40e7853b          	subw	a0,a5,a4
}
ffffffffc0202550:	8082                	ret
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0202552:	4501                	li	a0,0
ffffffffc0202554:	8082                	ret

ffffffffc0202556 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0202556:	ca01                	beqz	a2,ffffffffc0202566 <memset+0x10>
ffffffffc0202558:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc020255a:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020255c:	0785                	addi	a5,a5,1
ffffffffc020255e:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0202562:	fec79de3          	bne	a5,a2,ffffffffc020255c <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0202566:	8082                	ret
