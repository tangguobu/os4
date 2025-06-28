#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "defs.h"

volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
  if(cpuid() == 0){
    printfinit();
    // printf("\n");
    printf("cpu %d is booting!\n", cpuid()); 
    kinit();         // physical page allocator
    uartinit();
    kvminit();       // create kernel page table
    kvminithart();   // turn on paging
    procinit();      // process table
    trapinit();      // trap vectors
    trapinithart();  // install kernel trap vector
    plicinit();      // set up interrupt controller
    plicinithart();  // ask PLIC for device interrupts
    __sync_synchronize();
    started = 1;
    userinit();      // first user process
  } else {
    while(started == 0)
      ;
    __sync_synchronize();
    printf("cpu %d is booting!\n", cpuid()); 
  }

  intr_on();
  while (1); 

}
