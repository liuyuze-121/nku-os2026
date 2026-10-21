//2411951
#include <pmm.h>
#include <list.h>
#include <stdio.h>
#include <buddy_pmm.h>

#define BUDDY_MAX_ORDER 16

static list_entry_t buddy_free_lists[BUDDY_MAX_ORDER + 1];
static size_t buddy_nr_free = 0;

/* 计算块页数对应的阶 */
static int
buddy_order(size_t size) {
    int order = 0;
    while (((size_t)1 << order) < size) {
        order++;
    }
    return order;
}

/* 按物理地址插入指定阶的空闲链表 */
static void
buddy_list_add(struct Page *base, int order) {
    list_entry_t *head = &buddy_free_lists[order];
    list_entry_t *le = head;

    while ((le = list_next(le)) != head) {
        struct Page *page = le2page(le, page_link);
        if (base < page) {
            break;
        }
    }
    list_add_before(le, &(base->page_link));
}

/* 取得与 base 配对的 Buddy */
static struct Page *
buddy_partner(struct Page *base, size_t size) {
    ppn_t ppn = page2ppn(base);
    ppn_t partner_ppn;

    if (ppn % (size << 1) == 0) {
        partner_ppn = ppn + size;
    } else {
        if (ppn < size) {
            return NULL;
        }
        partner_ppn = ppn - size;
    }

    if (partner_ppn < nbase || partner_ppn >= npage) {
        return NULL;
    }
    return &pages[partner_ppn - nbase];
}

/* 初始化各阶空闲链表 */
static void
buddy_init(void) {
    for (int i = 0; i <= BUDDY_MAX_ORDER; i++) {
        list_init(&buddy_free_lists[i]);
    }
    buddy_nr_free = 0;
}

/* 将连续保留页拆成按 2 的幂对齐的空闲块 */
static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);

    struct Page *end = base + n;
    for (struct Page *p = base; p < end; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }

    struct Page *p = base;
    size_t remaining = n;

    while (remaining > 0) {
        size_t size = 1;

        while (size * 2 <= remaining &&
               size * 2 <= ((size_t)1 << BUDDY_MAX_ORDER) &&
               page2ppn(p) % (size * 2) == 0) {
            size <<= 1;
        }

        p->property = size;
        SetPageProperty(p);
        buddy_list_add(p, buddy_order(size));
        buddy_nr_free += size;

        p += size;
        remaining -= size;
    }
}

/* 分配至少 n 页，返回 2 的幂大小的块 */
static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);

    if (n > buddy_nr_free) {
        return NULL;
    }

    size_t size = 1;
    int order = 0;

    while (size < n) {
        size <<= 1;
        order++;
        if (order > BUDDY_MAX_ORDER) {
            return NULL;
        }
    }

    int k = order;
    while (k <= BUDDY_MAX_ORDER &&
           list_empty(&buddy_free_lists[k])) {
        k++;
    }

    if (k > BUDDY_MAX_ORDER) {
        return NULL;
    }

    list_entry_t *le = list_next(&buddy_free_lists[k]);
    struct Page *block = le2page(le, page_link);
    list_del(&(block->page_link));

    /* 拆分大块，把右半部分放回低阶链表 */
    while (k > order) {
        k--;
        size_t half = (size_t)1 << k;
        struct Page *buddy = block + half;

        buddy->property = half;
        SetPageProperty(buddy);
        buddy_list_add(buddy, k);
    }

    block->property = size;
    ClearPageProperty(block);
    buddy_nr_free -= size;

    return block;
}

/* 释放块并逐层合并 Buddy */
static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(base != NULL && n > 0);

    size_t size = base->property;
    assert(size > 0 && (size & (size - 1)) == 0);
    assert(n <= size);
    assert(!PageProperty(base));

    for (struct Page *p = base; p < base + size; p++) {
        assert(!PageReserved(p));
        assert(!PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }

    base->property = size;
    SetPageProperty(base);
    buddy_list_add(base, buddy_order(size));
    buddy_nr_free += size;

    int order = buddy_order(size);

    while (order < BUDDY_MAX_ORDER) {
        struct Page *buddy = buddy_partner(base, size);

        if (buddy == NULL ||
            !PageProperty(buddy) ||
            buddy->property != size) {
            break;
        }

        list_del(&(base->page_link));
        list_del(&(buddy->page_link));

        struct Page *merged = (base < buddy) ? base : buddy;
        struct Page *other = (base < buddy) ? buddy : base;

        ClearPageProperty(other);
        other->property = 0;

        merged->property = size << 1;
        SetPageProperty(merged);
        base = merged;

        size <<= 1;
        order++;
        buddy_list_add(base, order);
    }
}

/* 返回当前空闲页数 */
static size_t
buddy_nr_free_pages(void) {
    return buddy_nr_free;
}

/* 检查所有阶的空闲链表和空闲页统计 */
static size_t
buddy_check_lists(void) {
    size_t total = 0;

    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        size_t size = (size_t)1 << order;
        list_entry_t *head = &buddy_free_lists[order];
        list_entry_t *le = head;

        while ((le = list_next(le)) != head) {
            struct Page *p = le2page(le, page_link);

            assert(PageProperty(p));
            assert(p->property == size);
            assert(page2ppn(p) % size == 0);
            assert(p >= pages);
            assert(p + size <= pages + (npage - nbase));

            total += size;
        }
    }

    assert(total == buddy_nr_free);
    assert(total == nr_free_pages());
    return total;
}

/* 查找包含指定页面的空闲块头 */
static struct Page *
buddy_find_free_head(struct Page *page) {
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        list_entry_t *head = &buddy_free_lists[order];
        list_entry_t *le = head;

        while ((le = list_next(le)) != head) {
            struct Page *block = le2page(le, page_link);
            if (page >= block && page < block + block->property) {
                return block;
            }
        }
    }
    return NULL;
}

/* 查找至少 min_size 页的空闲块 */
static struct Page *
buddy_find_free_block_min(size_t min_size) {
    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        size_t size = (size_t)1 << order;
        if (size < min_size) {
            continue;
        }

        list_entry_t *head = &buddy_free_lists[order];
        if (!list_empty(head)) {
            return le2page(list_next(head), page_link);
        }
    }
    return NULL;
}

/* 测试基本分配、非 2 的幂请求和相邻页判断 */
static void
buddy_check_alloc(void) {
    size_t before = buddy_check_lists();

    struct Page *p0 = alloc_pages(3);
    assert(p0 != NULL);
    assert(p0->property == 4);
    assert(!PageProperty(p0));
    assert(page2ppn(p0) % 4 == 0);

    for (struct Page *p = p0; p < p0 + 4; p++) {
        assert(!PageProperty(p));
    }

    assert(nr_free_pages() == before - 4);

    struct Page *p1 = alloc_pages(1);
    assert(p1 != NULL);
    assert(p1->property == 1);
    assert(!PageProperty(p1));

    /* 两个分配块不能重叠 */
    assert(p0 + 4 <= p1 || p1 + 1 <= p0);
    assert(nr_free_pages() == before - 5);

    free_pages(p0, 3);
    free_pages(p1, 1);
    assert(nr_free_pages() == before);
    buddy_check_lists();
}

/* 测试空间不足和较大请求 */
static void
buddy_check_limits(void) {
    size_t before = buddy_check_lists();

    struct Page *p = alloc_pages(5);
    assert(p != NULL);
    assert(p->property == 8);
    assert(page2ppn(p) % 8 == 0);
    assert(nr_free_pages() == before - 8);

    free_pages(p, 5);
    assert(nr_free_pages() == before);

    assert(alloc_pages(before + 1) == NULL);
    assert(nr_free_pages() == before);
    buddy_check_lists();
}

/* 测试当前最大的空闲块 */
static void
buddy_check_large(void) {
    size_t before = buddy_check_lists();
    size_t largest = 1;

    for (int order = 0; order <= BUDDY_MAX_ORDER; order++) {
        if (!list_empty(&buddy_free_lists[order])) {
            largest = (size_t)1 << order;
        }
    }

    struct Page *p = alloc_pages(largest);
    assert(p != NULL);
    assert(p->property == largest);
    assert(page2ppn(p) % largest == 0);

    free_pages(p, largest);
    assert(nr_free_pages() == before);
    buddy_check_lists();
}

/* 测试一对 Buddy 的释放和合并 */
static void
buddy_check_merge(void) {
    size_t before = buddy_check_lists();

    struct Page *big = buddy_find_free_block_min(2);
    assert(big != NULL);

    size_t big_size = big->property;
    size_t half = big_size >> 1;
    struct Page *other = big + half;

    /* 暂时把一个大空闲块拆成两个已分配块 */
    list_del(&(big->page_link));
    buddy_nr_free -= big_size;

    for (struct Page *p = big; p < big + big_size; p++) {
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }

    big->property = half;
    other->property = half;

    /* 先释放一半，再释放伙伴，第二次应触发合并 */
    free_pages(big, half);
    assert(nr_free_pages() == before - half);

    free_pages(other, half);
    assert(nr_free_pages() == before);

    struct Page *head1 = buddy_find_free_head(big);
    struct Page *head2 = buddy_find_free_head(other);

    assert(head1 != NULL);
    assert(head1 == head2);
    assert(head1->property >= (half << 1));

    buddy_check_lists();
}

/* 测试多轮分配和释放 */
static void
buddy_check_repeat(void) {
    size_t before = buddy_check_lists();

    for (int i = 0; i < 6; i++) {
        size_t request = (size_t)(i % 3) + 1;
        struct Page *p = alloc_pages(request);

        assert(p != NULL);
        free_pages(p, request);

        assert(nr_free_pages() == before);
        buddy_check_lists();
    }
}

static void
buddy_check(void) {
    size_t initial = buddy_check_lists();

    cprintf("buddy_check: begin, free pages = %lu\n",
            (unsigned long)initial);

    buddy_check_merge();
    buddy_check_alloc();
    buddy_check_limits();
    buddy_check_large();
    buddy_check_repeat();

    assert(nr_free_pages() == initial);
    buddy_check_lists();

    cprintf("buddy_check: PASS\n");
}

/* 注册 Buddy 管理器 */
const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
