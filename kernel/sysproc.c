#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

// Return the physical address of a virtual address.
uint64
sys_phyaddr(void)
{   
    // Get the process info to get the pagetable.
    struct proc* p = myproc();

    // Retrieve Virtual Address by fetching argument.
    uint64 va;
    argaddr(0, &va);

    // walkaddr to translate VPN to PFN, PTE_FLAGS(va) extracts 12-bit offset from VA.
    //  ---------------------------------------------------------------------
    // |          VPN -> PFN [63:12]             |      OFFSET [11:0]        |
    //  ---------------------------------------------------------------------
    uint64 pa = walkaddr(p->pagetable, va) | PTE_FLAGS(va);
    return pa;
}

// Return the page table (or directory) index of a virtual address
// at the specified page table level.
uint64
sys_ptidx(void)
{
    uint64 va;      // Input argument. virtual address
    uint64 lvl_in;  // Input argument. level.

    argaddr(0, &va);
    argaddr(1, &lvl_in);

    // PX(level, va) macro extracts the bit number field
    // that contains L-level page offset.    
  return PX(lvl_in, va);
}

// Count the total number pages allocated by a process.
uint64
sys_pgcnt(void)
{
    int count = 0; // Count the pages

    // Finding allocated page is implemented with recursive job.
    // If allocated page is found in certain level, go to lower level
    // and do this job in that level.

    // Walk L2 page table and find the valid PTE
    for (int L2 = 0; L2 < 512; L2++)
    {
        pagetable_t pagetable = myproc()->pagetable;
        pte_t* L2_pte = &pagetable[L2]; // This line is inside the for-loop since it's overwritten in lower level.
        // If found, go L1 level and walk the page.
        if(*L2_pte & PTE_V)
        {
            count++;  // allocated page found!
            // Walk L1 page table and find the valid PTE
            for (int L1 = 0; L1 < 512; L1++) {
              // Get Page table base for L1
                pagetable = (pagetable_t)PTE2PA(*L2_pte);
                pte_t* L1_pte = &pagetable[L1];
                // If allocated page is found, go L0 level and walk the page
                if (*L1_pte & PTE_V) {
                    count++;  // allocated page found!
                    for (int L0 = 0; L0 < 512; L0++) {
                        // Get Page table base for L0
                        pagetable = (pagetable_t)PTE2PA(*L1_pte);
                        pte_t* L0_pte = &pagetable[L0];
                        if (*L0_pte & PTE_V)
                            count++; // allocated page found!
                    }
                }
            }
        }
    }

    return count;
}
