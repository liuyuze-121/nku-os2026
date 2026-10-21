# 功能模块一任务一

````markdown

[PROMPT]
**任务**：：在 `kern/mm/pmm.c` 中实现 `static void page_init(void)`，根据设备树信息建立 Page 描述符数组，排除 OpenSBI、内核镜像和描述符数组占用的页面，并将剩余的连续完整空闲页交给当前 `pmm_manager`。

**操作要求**：必须修改实际文件，不要只输出代码。只在 `//lab2 function1 YOUR CODE` 附近补充 `page_init()`，必要时添加本文件内的 static 辅助函数。保留现有 `pmm_init()`、`init_memmap()` 和其他逻辑；不要修改测试文件、`default_pmm.c`、`best_fit_pmm.c`，不要切换管理器或重构无关代码。

**输出要求**：直接修改文件，以工程真实代码为准，不引入 Best-Fit、Buddy、SLUB 等功能。

[RELY]
- `PGSIZE = 4096`，`PGSHIFT = 12`，`PPN(addr) = addr >> 12`。
- `DRAM_BASE = 0x80000000`，`PHYSICAL_MEMORY_END = 0x88000000`，`PHYSICAL_MEMORY_OFFSET = 0xFFFFFFFF40000000`，`KERNBASE = 0xFFFFFFFFC0200000`。
- `nbase = DRAM_BASE / PGSIZE`。
- 已有全局变量：`struct Page *pages`、`size_t npage`、`uint64_t va_pa_offset`、`const struct pmm_manager *pmm_manager`。
- `struct Page` 包含 `ref`、`flags`、`property` 和 `page_link`；描述符大小必须使用 `sizeof(struct Page)`。
- 已有宏：`PageReserved`、`PageProperty`、`SetPageReserved`、`ClearPageProperty`、`ROUNDUP`、`ROUNDDOWN`。
- `PADDR(kva)` 将内核虚拟地址转换为物理地址，使用前必须保证 `va_pa_offset` 已设置。
- `page2pa(page)` 通过描述符下标计算物理地址；`pa2page(pa)` 通过物理页号取得描述符，并检查 `PPN(pa) < npage`。
- `init_memmap(struct Page *base, size_t n)` 调用当前管理器的初始化接口。
- `get_memory_base()` 和 `get_memory_size()` 提供设备树报告的内存范围和大小。
- `extern char end[]` 是内核镜像的虚拟结束地址。
- 正常 QEMU 下 `nbase = 0x80000`、`npage = 0x88000`，但实现必须由设备树推导。

[GUARANTEE]
必须实现：

```c
static void page_init(void);
```

可以在 `pmm.c` 内增加 static 辅助函数，但不得改变公开接口。

[SPECIFICATION]
## page_init

**Pre-Condition**：
- 由 `pmm_init()` 在 `init_pmm_manager()` 之后调用。
- `get_memory_base()` 和 `get_memory_size()` 已经可用。
- 当前管理器是已初始化的 First-Fit 管理器。

**Post-Condition**：
- `va_pa_offset == PHYSICAL_MEMORY_OFFSET`。
- 可管理内存末端为设备树范围与 `PHYSICAL_MEMORY_END` 的较小值；`npage` 是该末端对应的物理页号上界，且 `npage > nbase`。
- `pages` 非空，按 `PGSIZE` 对齐，并位于 `ROUNDUP(end, PGSIZE)` 或之后。
- Page 描述符数组覆盖 `[nbase, npage)`，数组长度为 `npage - nbase`。
- 注册空闲区前，所有描述符都为保留状态：`PageReserved` 为真、`PageProperty` 为假、`ref` 为 0。
- 内核尾部页面、描述符数组和 OpenSBI 占用页不得进入空闲区。
- 空闲区起点是描述符数组结束物理地址向上按页对齐的位置；终点是可管理内存末端向下按页对齐的位置。
- 只有完整页面可以注册。如果空闲区至少有一页，则通过 `init_memmap()` 注册；没有完整页面时不得调用 `init_memmap()`。
- 输出实际探测到的内存基址、大小或结束地址。

**Case 1：有效内存范围**：
正常设置 `va_pa_offset`、`npage`、`pages`，并将排除系统占用后的完整连续空闲页注册给当前管理器。

**Case 2：设备树信息无效**：
基址或大小为 0、结束地址不大于基址，或页号范围无效时，调用 `panic()` 终止初始化，不建立空闲区。

**Case 3：超过框架上界**：
将可管理范围限制到 `PHYSICAL_MEMORY_END` 以内，不得暴露上界之外的物理地址。

**Case 4：非页对齐末端**：
内存末端向下对齐，描述符数组末端向上对齐，只管理完整页面。

**Case 5：没有完整空闲页**：
不调用 `init_memmap()`，不把 0 个页面传给管理器，保留未空闲描述符的保留状态并返回。

**Requirements**：
- `npage` 是页号上界，不是空闲页数量。
- `pages` 是虚拟地址；描述符数组的物理位置必须使用 `PADDR(pages)` 计算。
- `PADDR()` 必须在设置 `va_pa_offset` 之后使用。
- `init_memmap()` 必须接收 `struct Page *`，不能传物理地址。
- 不直接操作 First-Fit 的内部空闲链表，统一通过现有包装函数注册空闲区。
- 不硬编码正常 QEMU 的地址来代替设备树探测，不修改测试代码，不伪造运行结果。
````

---

# 功能模块二任务二
````markdown
[PROMPT]
**任务**：在 `kern/mm/best_fit_pmm.c` 中实现 Best-Fit 连续物理内存管理器并注册 `best_fit_pmm_manager`；在 `kern/mm/pmm.c` 的 `init_pmm_manager()` 中将管理器切换为 `best_fit_pmm_manager`。

**操作要求**：必须修改实际文件。只在 `//lab2 function2-2 YOUR CODE` 附近补充实现，可添加 static 辅助函数；不得修改 `basic_check()`、`best_fit_check()` 和 `best_fit_pmm.h`。`pmm.c` 只修改管理器选择，不改变 `pmm_init()` 和 `page_init()`。

**输出要求**：直接修改文件，以真实工程代码为准，不引入 Buddy、SLUB 或其他无关功能。

[RELY]
- `struct Page`：`ref`、`flags`、`property`、`page_link`。
- `free_area_t`：`list_entry_t free_list`、`unsigned int nr_free`。
- 块头使用 `SetPageProperty()` 和 `PageProperty()`；`property` 表示空闲块页数。
- 保留页使用 `PageReserved()` 判断。
- 用 `le2page(le, page_link)` 从链表节点取得 `struct Page *`。
- 测试代码直接使用 `free_list` 和 `nr_free`，因此需要定义：
```c
static free_area_t free_area;
#define free_list (free_area.free_list)
#define nr_free   (free_area.nr_free)
```
- `struct pmm_manager` 包含 `init`、`init_memmap`、`alloc_pages`、`free_pages`、`nr_free_pages`、`check`。
- `basic_check()` 和 `best_fit_check()` 必须原样保留。
- 测试要求：释放大小为 2 的块 `p0+1` 和大小为 1 的块 `p0+4` 后，`alloc_pages(1)` 必须返回 `p0+4`，不能返回 `p0+1`。

[GUARANTEE]
```c
static void best_fit_init(void);
static void best_fit_init_memmap(struct Page *base, size_t n);
static struct Page *best_fit_alloc_pages(size_t n);
static void best_fit_free_pages(struct Page *base, size_t n);
static size_t best_fit_nr_free_pages(void);

const struct pmm_manager best_fit_pmm_manager;
```

并在 `pmm.c` 中设置：

```c
pmm_manager = &best_fit_pmm_manager;
```

[SPECIFICATION]
## best_fit_init

- 初始化空链表，`nr_free` 设为 0。

## best_fit_init_memmap

- 要求 `n > 0`，输入页面均为保留页。
- 清除这些页面的保留位和 `property`，将 `ref` 设为 0。
- `base->property = n`，设置 `base->PageProperty`，增加 `nr_free`，按地址插入空闲链表。

## best_fit_alloc_pages

- 遍历空闲链表，选择满足 `property >= n` 的最小空闲块。
- 大小相同时选择先遇到的块。
- 没有合适块时返回 `NULL`，不改变状态。
- 选中后删除块；若块更大，将剩余部分作为新的块头插入空闲链表。
- `nr_free` 减少 `n`，返回的块不再具有 `PageProperty`。

## best_fit_free_pages

- 要求 `n > 0`，输入页已分配且不是保留页。
- 清除这些页面的标志和 `ref`，将 `base` 设为大小为 `n` 的空闲块头。
- `nr_free` 增加 `n`，按地址插入链表。
- 与前一个空闲块物理相邻时合并，再与后一个空闲块合并。
- 合并后只保留一个块头，`property` 为合并后的总页数。

## best_fit_nr_free_pages

- 返回当前 `nr_free`。

## 管理器注册

- `best_fit_pmm_manager.name = "best_fit_pmm_manager"`。
- `init_memmap`、`alloc_pages`、`free_pages`、`nr_free_pages` 分别绑定上述函数。
- `check` 绑定已有的 `best_fit_check()`。

**Requirements**：
- 必须选择最小可满足块，不能采用 First-Fit。
- `PageProperty` 只能留在空闲块头。
- 释放时必须正确合并前后相邻块，`nr_free` 不能重复计数。
- 分配和释放失败时不能破坏空闲链表。
- 不修改测试函数和无关代码。
````

---


# 功能模块二任务三
## prompt1
````markdown
[PROMPT]
**任务**：从零实现一个 Buddy System 连续物理内存管理器，并接入现有 `pmm_manager`。新建 `kern/mm/buddy_pmm.c` 和 `kern/mm/buddy_pmm.h`，实现 Buddy 的初始化、连续页面分配、释放和空闲块合并；在 `kern/mm/pmm.c` 中引入管理器并将 `init_pmm_manager()` 切换为 `buddy_pmm_manager`。已有 `page_init()` 会通过 `init_memmap()` 提交可管理内存，本任务不重写 `page_init()`。

**操作要求**：必须修改实际文件。可以新增本模块的 static 函数、空闲链表数组和辅助宏；不得修改 `pmm.h` 的公开接口、`page_init()` 的逻辑或其他模块的测试。保留 `lab2` 注释，不改变 `pmm_init()` 的调用顺序。

**输出要求**：直接写入项目文件，使用现有 ucore 类型和接口，不引入 SLUB 或其他 lab 的功能。算法的时间复杂度不作要求。

[RELY]
- `struct pmm_manager` 必须实现：`init`、`init_memmap`、`alloc_pages`、`free_pages`、`nr_free_pages`、`check`。
- `struct Page` 包含 `ref`、`flags`、`property`、`page_link`。
- `PageReserved` 表示系统保留页；`PageProperty` 表示空闲块头；`property` 在本模块中表示块头对应的页数。
- `free_area_t` 包含 `free_list` 和 `nr_free`；可以用数组为每个 Buddy 阶维护一个空闲链表。
- `list_init`、`list_add`、`list_add_before`、`list_del`、`list_empty`、`list_next`、`le2page` 均可使用。
- `page2ppn(page)` 返回物理页号，`page2pa(page)` 返回物理地址；`nbase` 是 DRAM 起始页号，`npage` 是可管理页号上界。
- `init_memmap(base, n)` 接收的 `n` 个页面是连续的保留页，但 `n` 不保证是 2 的幂，起始页面也不保证按目标块大小对齐。
- `alloc_pages(n)` 可以返回大于等于 `n` 的连续页面；实现必须在返回块头记录实际块页数，供释放时使用。
- `pmm.c` 的 `init_pmm_manager()` 当前选择 `default_pmm_manager`，需要改为 `buddy_pmm_manager`。

[GUARANTEE]
必须实现：

```c
static void buddy_init(void);
static void buddy_init_memmap(struct Page *base, size_t n);
static struct Page *buddy_alloc_pages(size_t n);
static void buddy_free_pages(struct Page *base, size_t n);
static size_t buddy_nr_free_pages(void);

const struct pmm_manager buddy_pmm_manager;
```

并在 `buddy_pmm.h` 中声明 `extern const struct pmm_manager buddy_pmm_manager;`。

[SPECIFICATION]
## 内部状态

- order 0 表示 1 页，order k 表示 2 的 k 次方页。
- 最大阶数必须足以覆盖全部可管理物理页，不能使用过小的固定上限。
- 每个阶维护按物理地址升序排列的空闲块链表。
- 空闲块头满足 `PageProperty` 为真，`property` 为块页数，且物理页号按块页数对齐。
- `nr_free` 表示所有阶空闲页数之和，不是空闲块数量。

## buddy_init

- 初始化所有阶的空闲链表，`nr_free` 设为 0。

## buddy_init_memmap

- 要求 `n > 0`，输入页面初始为 `PageReserved`。
- 将输入连续区间拆成尽可能大的、物理页号对齐的 2 的幂块。
- 每个空闲块清除非空闲块的保留状态，块头设置 `PageProperty` 和 `property`，插入对应阶的空闲链表。
- 不能把不足一页的尾部或未对齐块错误地纳入空闲区。

## buddy_alloc_pages

- 将请求 `n` 向上取整到 2 的幂。
- 从满足大小要求的最高可用阶中选择块；必要时递归拆分大块，把伙伴块放回较低阶空闲链表。
- 返回块头，并在块头的 `property` 中保留实际分配块页数，同时清除该块头的空闲标志。
- 没有足够空间时返回 `NULL`，不改变空闲链表和 `nr_free`。
- 分配结果不能与保留页或其他已分配块重叠。

## buddy_free_pages

- `base` 必须是已分配块头，`n > 0`；以块头记录的实际块大小为准，不能假定 `n` 一定等于块大小。
- 将块重新插入对应阶的空闲链表，并尝试与同阶、物理相邻且满足 Buddy 配对关系的伙伴块合并。
- 只合并真正的 Buddy，禁止把普通相邻块误合并；合并后继续向更高阶传播。
- 正确维护 `PageProperty`、`property`、`PageReserved` 和 `nr_free`，不得重复计数或丢失页面。

## 管理器注册与接入

- `buddy_pmm_manager.name = "buddy_pmm_manager"`。
- 各函数指针绑定上述实现，`check` 暂绑定一个可调用的 `buddy_check()` 占位函数，后续测试任务再完善。
- 在 `pmm.c` 中包含 `buddy_pmm.h`，并设置：
```c
pmm_manager = &buddy_pmm_manager;
```
- 不修改 `pmm_init()` 的调用顺序和 `page_init()`。

**Requirements**：
- 所有块的大小必须是 2 的幂，块起始物理页号必须按块大小对齐。
- Buddy 分配和合并必须严格成对，不能把非伙伴块合并。
- `property` 表示块页数，`PageProperty` 只标记当前空闲链表中的块头。
- 不修改公开接口，不修改已有测试，不伪造运行结果。
````

## prompt2

````markdown

[PROMPT]
**任务**：为已经生成的 `kern/mm/buddy_pmm.c` 设计并实现 Buddy System 测试函数 `static void buddy_check(void)`，并将其注册为 `buddy_pmm_manager.check`。测试应验证初始化、按阶拆分、连续分配、无空间返回、释放后的 Buddy 合并以及边界情况。

**操作要求**：必须读取并依据当前 Buddy 实现，不要凭空假设内部函数名或状态布局。只添加测试函数、必要的只读辅助函数和 `.check` 绑定；不得修改 Buddy 分配算法、`pmm.h`、`page_init()` 或 lab2 原有测试。测试中可以使用 `assert`、`alloc_pages`、`free_pages`、`nr_free_pages`、`page2pa`、`PageProperty` 等现有接口。

**输出要求**：直接修改实际文件，测试应能通过 `pmm_manager->check()` 被调用并正常编译运行。不要修改默认评分流程；用 `make qemu` 或当前工程可用的运行方式观察测试输出。

[RELY]
- `buddy_pmm_manager` 已实现并完成初始化。
- `alloc_pages(n)` 返回至少 `n` 个连续页面，实际块大小记录在返回块头的 `property` 中。
- `free_pages(base, n)` 根据块头记录的实际块大小释放。
- 空闲块头满足 `PageProperty`，`property` 为块页数；`nr_free_pages()` 返回当前空闲页数。
- `page2ppn(page)` 可用于检查块起始页号和 Buddy 对齐关系。
- 测试函数由 `pmm_init()` 中的 `check_alloc_page()` 间接调用。

[GUARANTEE]
必须实现：

```c
static void buddy_check(void);
```

并在管理器中设置：

```c
.check = buddy_check,
```

允许在测试内部添加 static 的只读检查辅助函数；不得改变 Buddy 管理器的分配行为。

[SPECIFICATION]
## 测试覆盖

至少覆盖以下行为：

1. **初始化状态**
   - 各阶空闲块大小都是 2 的幂。
   - 每个空闲块起始页号按块大小对齐。
   - 所有空闲块页数之和等于 `nr_free_pages()`。

2. **基本分配**
   - 分配 1 页和多个页面，返回非空且互不重叠。
   - 请求非 2 的幂页数（例如 3、5）时，实际块大小向上取整为 2 的幂。
   - 返回值在可管理物理页范围内，且不是保留页。

3. **拆分与空间不足**
   - 分配会从更大的块中拆分出所需块。
   - 请求超过当前空闲页数时返回 `NULL`。
   - 失败前后 `nr_free_pages()` 和空闲区状态不被破坏。

4. **释放与合并**
   - 释放一个块后，空闲页数增加实际块大小。
   - 释放一对 Buddy 后，它们合并为更高阶块。
   - 合并后能够再次分配合并后的更大块。
   - 不能与非 Buddy 的相邻块或已分配页面错误合并。

5. **边界与稳定性**
   - 检查 order 0 和最大可用阶的分配路径。
   - 让块跨越 page number 的 2 的幂边界时，仍满足对齐要求。
   - 进行多轮分配、释放和重新分配，确认没有重复块、页面泄漏或 `nr_free` 错误。

## 测试后状态

- 测试应释放自己分配的页面，恢复测试前的空闲页数。
- 测试通过时输出清晰的成功信息；失败时使用 `assert` 或明确的错误输出。
- 不把测试临时状态留在 Buddy 管理器中，以免影响后续启动流程。

**Requirements**：
- 测试必须针对当前实现的实际分配约定编写，尤其是“请求 n 页可能返回更大的 2 的幂块”。
- 测试不能只检查 `alloc_page()` 是否非空，必须验证块大小、对齐、隔离和合并。
- 不修改现有 `basic_check()`、`best_fit_check()`、`page_init()` 或评分脚本。
- 测试通过后，报告应说明覆盖了哪些核心行为和边界情况，以及这些检查为什么能验证 Buddy 实现。
````