//2411334
#include <pmm.h>
#include <slub.h>
#include <stdio.h>
#include <string.h>

#define SLUB_MAX_SLABS 64
#define SLUB_CLASS_COUNT 10
#define SLUB_BITMAP_WORDS (PGSIZE / 8 / 64)

static const size_t slub_class_sizes[SLUB_CLASS_COUNT] = {
    8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096
};

struct slub_slab {
    bool active;
    int class_index;
    struct Page *page;
    void *start;
    size_t object_size;
    size_t object_count;
    size_t free_count;
    void *free_list;
    uint64_t used_bitmap[SLUB_BITMAP_WORDS];
};

static struct slub_slab slub_slabs[SLUB_MAX_SLABS];
static bool slub_ready;

static void slub_check(void);

/* 选择能容纳请求的最小大小类 */
static int
slub_class_index(size_t size) {
    for (int i = 0; i < SLUB_CLASS_COUNT; i++) {
        if (size <= slub_class_sizes[i]) {
            return i;
        }
    }
    return -1;
}

/* 查找有空闲对象的同类 slab */
static struct slub_slab *
slub_find_slab(int class_index) {
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
        struct slub_slab *slab = &slub_slabs[i];
        if (slab->active &&
            slab->class_index == class_index &&
            slab->free_count > 0) {
            return slab;
        }
    }
    return NULL;
}

/* 创建新的单页 slab */
static struct slub_slab *
slub_new_slab(int class_index) {
    struct slub_slab *slab = NULL;

    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
        if (!slub_slabs[i].active) {
            slab = &slub_slabs[i];
            break;
        }
    }
    if (slab == NULL) {
        return NULL;
    }

    struct Page *page = alloc_pages(1);
    if (page == NULL) {
        return NULL;
    }

    size_t object_size = slub_class_sizes[class_index];
    size_t object_count = PGSIZE / object_size;

    slab->active = 1;
    slab->class_index = class_index;
    slab->page = page;
    slab->start = (void *)(page2pa(page) + va_pa_offset);
    slab->object_size = object_size;
    slab->object_count = object_count;
    slab->free_count = object_count;
    slab->free_list = slab->start;
    memset(slab->used_bitmap, 0, sizeof(slab->used_bitmap));

    /* 将对象串成单链表 */
    char *base = (char *)slab->start;
    for (size_t i = 0; i < object_count; i++) {
        void *obj = base + i * object_size;
        void *next = (i + 1 < object_count)
                         ? (void *)(base + (i + 1) * object_size)
                         : NULL;
        *(void **)obj = next;
    }

    return slab;
}

/* 初始化 SLUB 元数据 */
void
slub_init(void) {
    memset(slub_slabs, 0, sizeof(slub_slabs));
    slub_ready = 1;
    cprintf("SLUB initialized\n");
    slub_check();
}

/* 分配指定大小的对象 */
void *
slub_alloc(size_t size) {
    if (!slub_ready || size == 0 || size > PGSIZE) {
        return NULL;
    }

    int class_index = slub_class_index(size);
    if (class_index < 0) {
        return NULL;
    }

    struct slub_slab *slab = slub_find_slab(class_index);
    if (slab == NULL) {
        slab = slub_new_slab(class_index);
    }
    if (slab == NULL || slab->free_list == NULL) {
        return NULL;
    }

    void *obj = slab->free_list;
    slab->free_list = *(void **)obj;
    slab->free_count--;

    size_t index = ((uintptr_t)obj - (uintptr_t)slab->start) / slab->object_size;
    slab->used_bitmap[index / 64] |= 1ULL << (index % 64);

    return obj;
}

/* 释放对象并放回所属 slab */
void
slub_free(void *ptr) {
    if (ptr == NULL) {
        return;
    }

    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
        struct slub_slab *slab = &slub_slabs[i];
        if (!slab->active) {
            continue;
        }

        uintptr_t start = (uintptr_t)slab->start;
        uintptr_t addr = (uintptr_t)ptr;
        uintptr_t end = start + PGSIZE;

        if (addr < start || addr >= end) {
            continue;
        }

        size_t offset = addr - start;
        if (offset % slab->object_size != 0) {
            panic("slub_free: misaligned object");
        }

        size_t index = offset / slab->object_size;
        if (index >= slab->object_count) {
            panic("slub_free: invalid object");
        }

        uint64_t *word = &slab->used_bitmap[index / 64];
        uint64_t mask = 1ULL << (index % 64);
        if ((*word & mask) == 0) {
            panic("slub_free: double free or invalid object");
        }

        *word &= ~mask;
        *(void **)ptr = slab->free_list;
        slab->free_list = ptr;
        slab->free_count++;
        return;
    }

    panic("slub_free: pointer does not belong to SLUB");
}

/* 检查单个 slab 的对象链表和位图 */
static void
slub_check_slab(struct slub_slab *slab) {
    assert(slab->active);
    assert(slab->object_size == slub_class_sizes[slab->class_index]);
    assert(slab->object_count == PGSIZE / slab->object_size);
    assert(slab->start == (void *)(page2pa(slab->page) + va_pa_offset));
    assert(slab->free_count <= slab->object_count);

    uint64_t seen[SLUB_BITMAP_WORDS];
    memset(seen, 0, sizeof(seen));

    size_t free_seen = 0;
    for (void *p = slab->free_list; p != NULL; p = *(void **)p) {
        uintptr_t offset = (uintptr_t)p - (uintptr_t)slab->start;
        assert(offset < PGSIZE);
        assert(offset % slab->object_size == 0);

        size_t index = offset / slab->object_size;
        assert(index < slab->object_count);

        uint64_t bit = 1ULL << (index % 64);
        assert((slab->used_bitmap[index / 64] & bit) == 0);
        assert((seen[index / 64] & bit) == 0);

        seen[index / 64] |= bit;
        free_seen++;
        assert(free_seen <= slab->object_count);
    }

    assert(free_seen == slab->free_count);

    size_t used = 0;
    for (size_t i = 0; i < slab->object_count; i++) {
        if (slab->used_bitmap[i / 64] & (1ULL << (i % 64))) {
            used++;
        }
    }
    assert(used + slab->free_count == slab->object_count);
}

static void
slub_check_all(void) {
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
        if (slub_slabs[i].active) {
            slub_check_slab(&slub_slabs[i]);
        }
    }
}

/* 检查基本分配、对象隔离和复用 */
static void
slub_check_basic(void) {
    void *p1 = slub_alloc(1);
    void *p8 = slub_alloc(8);
    void *p64 = slub_alloc(64);

    assert(p1 != NULL && p8 != NULL && p64 != NULL);
    assert((uintptr_t)p1 % 8 == 0);
    assert((uintptr_t)p8 % 8 == 0);
    assert((uintptr_t)p64 % 8 == 0);
    assert(p1 != p8 && p1 != p64 && p8 != p64);

    memset(p1, 0xA1, 8);
    memset(p8, 0xB2, 8);
    memset(p64, 0xC3, 64);

    assert(((unsigned char *)p1)[0] == 0xA1);
    assert(((unsigned char *)p1)[7] == 0xA1);
    assert(((unsigned char *)p8)[0] == 0xB2);
    assert(((unsigned char *)p8)[7] == 0xB2);
    assert(((unsigned char *)p64)[0] == 0xC3);
    assert(((unsigned char *)p64)[63] == 0xC3);

    slub_free(p1);
    slub_free(p8);
    slub_free(p64);

    void *again = slub_alloc(8);
    assert(again != NULL);
    assert(again == p1 || again == p8);
    slub_free(again);

    slub_check_all();
}

/* 检查不同大小类和边界请求 */
static void
slub_check_sizes(void) {
    const size_t requests[] = {
        1, 7, 8, 9, 63, 64, 65, 255, 256, 257, 1024, 2048, 4096
    };
    const size_t count = sizeof(requests) / sizeof(requests[0]);
    void *objects[sizeof(requests) / sizeof(requests[0])];

    for (size_t i = 0; i < count; i++) {
        objects[i] = slub_alloc(requests[i]);
        assert(objects[i] != NULL);
        assert((uintptr_t)objects[i] % 8 == 0);
        memset(objects[i], (int)(0x40 + i), requests[i]);
    }

    for (size_t i = 0; i < count; i++) {
        assert(((unsigned char *)objects[i])[0] == 0x40 + i);
        assert(((unsigned char *)objects[i])[requests[i] - 1] == 0x40 + i);
    }

    for (size_t i = 0; i < count; i++) {
        slub_free(objects[i]);
    }

    assert(slub_alloc(0) == NULL);
    assert(slub_alloc(PGSIZE + 1) == NULL);
    slub_check_all();
}

/* 回收测试产生的空 slab 页面 */
static void
slub_check_cleanup(void) {
    for (int i = 0; i < SLUB_MAX_SLABS; i++) {
        struct slub_slab *slab = &slub_slabs[i];
        if (!slab->active) {
            continue;
        }

        assert(slab->free_count == slab->object_count);
        free_pages(slab->page, 1);
        memset(slab, 0, sizeof(*slab));
    }
}

static void
slub_check(void) {
    size_t before_pages = nr_free_pages();

    cprintf("slub_check: begin\n");

    slub_check_all();
    slub_check_basic();
    slub_check_sizes();
    slub_check_cleanup();

    assert(nr_free_pages() == before_pages);
    slub_check_all();

    cprintf("slub_check: PASS\n");
}
