
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00003117          	auipc	sp,0x3
    80000004:	44013103          	ld	sp,1088(sp) # 80003440 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00003717          	auipc	a4,0x3
    80000054:	45070713          	addi	a4,a4,1104 # 800034a0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00001797          	auipc	a5,0x1
    80000066:	7de78793          	addi	a5,a5,2014 # 80001840 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fff2c9f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	8c278793          	addi	a5,a5,-1854 # 8000096e <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	f39ff0ef          	jal	ra,8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000ec:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000ee:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f0:	30200073          	mret
}
    800000f4:	60a2                	ld	ra,8(sp)
    800000f6:	6402                	ld	s0,0(sp)
    800000f8:	0141                	addi	sp,sp,16
    800000fa:	8082                	ret

00000000800000fc <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800000fc:	7179                	addi	sp,sp,-48
    800000fe:	f406                	sd	ra,40(sp)
    80000100:	f022                	sd	s0,32(sp)
    80000102:	ec26                	sd	s1,24(sp)
    80000104:	e84a                	sd	s2,16(sp)
    80000106:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000108:	c219                	beqz	a2,8000010e <printint+0x12>
    8000010a:	08054563          	bltz	a0,80000194 <printint+0x98>
    x = -xx;
  else
    x = xx;
    8000010e:	2501                	sext.w	a0,a0
    80000110:	4881                	li	a7,0
    80000112:	fd040693          	addi	a3,s0,-48

  i = 0;
    80000116:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    80000118:	2581                	sext.w	a1,a1
    8000011a:	00003617          	auipc	a2,0x3
    8000011e:	f0e60613          	addi	a2,a2,-242 # 80003028 <digits>
    80000122:	883a                	mv	a6,a4
    80000124:	2705                	addiw	a4,a4,1
    80000126:	02b577bb          	remuw	a5,a0,a1
    8000012a:	1782                	slli	a5,a5,0x20
    8000012c:	9381                	srli	a5,a5,0x20
    8000012e:	97b2                	add	a5,a5,a2
    80000130:	0007c783          	lbu	a5,0(a5)
    80000134:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    80000138:	0005079b          	sext.w	a5,a0
    8000013c:	02b5553b          	divuw	a0,a0,a1
    80000140:	0685                	addi	a3,a3,1
    80000142:	feb7f0e3          	bgeu	a5,a1,80000122 <printint+0x26>

  if(sign)
    80000146:	00088c63          	beqz	a7,8000015e <printint+0x62>
    buf[i++] = '-';
    8000014a:	fe070793          	addi	a5,a4,-32
    8000014e:	00878733          	add	a4,a5,s0
    80000152:	02d00793          	li	a5,45
    80000156:	fef70823          	sb	a5,-16(a4)
    8000015a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000015e:	02e05563          	blez	a4,80000188 <printint+0x8c>
    80000162:	fd040793          	addi	a5,s0,-48
    80000166:	00e784b3          	add	s1,a5,a4
    8000016a:	fff78913          	addi	s2,a5,-1
    8000016e:	993a                	add	s2,s2,a4
    80000170:	377d                	addiw	a4,a4,-1
    80000172:	1702                	slli	a4,a4,0x20
    80000174:	9301                	srli	a4,a4,0x20
    80000176:	40e90933          	sub	s2,s2,a4
    uartputc_sync(buf[i]);
    8000017a:	fff4c503          	lbu	a0,-1(s1)
    8000017e:	292000ef          	jal	ra,80000410 <uartputc_sync>
  while(--i >= 0)
    80000182:	14fd                	addi	s1,s1,-1
    80000184:	ff249be3          	bne	s1,s2,8000017a <printint+0x7e>
}
    80000188:	70a2                	ld	ra,40(sp)
    8000018a:	7402                	ld	s0,32(sp)
    8000018c:	64e2                	ld	s1,24(sp)
    8000018e:	6942                	ld	s2,16(sp)
    80000190:	6145                	addi	sp,sp,48
    80000192:	8082                	ret
    x = -xx;
    80000194:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000198:	4885                	li	a7,1
    x = -xx;
    8000019a:	bfa5                	j	80000112 <printint+0x16>

000000008000019c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000019c:	1101                	addi	sp,sp,-32
    8000019e:	ec06                	sd	ra,24(sp)
    800001a0:	e822                	sd	s0,16(sp)
    800001a2:	e426                	sd	s1,8(sp)
    800001a4:	1000                	addi	s0,sp,32
    800001a6:	84aa                	mv	s1,a0
  pr.locking = 0;
    800001a8:	0000b797          	auipc	a5,0xb
    800001ac:	4407a823          	sw	zero,1104(a5) # 8000b5f8 <pr+0x18>
  printf("panic: ");
    800001b0:	00003517          	auipc	a0,0x3
    800001b4:	e5050513          	addi	a0,a0,-432 # 80003000 <etext>
    800001b8:	022000ef          	jal	ra,800001da <printf>
  printf(s);
    800001bc:	8526                	mv	a0,s1
    800001be:	01c000ef          	jal	ra,800001da <printf>
  printf("\n");
    800001c2:	00003517          	auipc	a0,0x3
    800001c6:	22650513          	addi	a0,a0,550 # 800033e8 <digits+0x3c0>
    800001ca:	010000ef          	jal	ra,800001da <printf>
  panicked = 1; // freeze uart output from other CPUs
    800001ce:	4785                	li	a5,1
    800001d0:	00003717          	auipc	a4,0x3
    800001d4:	28f72823          	sw	a5,656(a4) # 80003460 <panicked>
  for(;;)
    800001d8:	a001                	j	800001d8 <panic+0x3c>

00000000800001da <printf>:
{
    800001da:	7131                	addi	sp,sp,-192
    800001dc:	fc86                	sd	ra,120(sp)
    800001de:	f8a2                	sd	s0,112(sp)
    800001e0:	f4a6                	sd	s1,104(sp)
    800001e2:	f0ca                	sd	s2,96(sp)
    800001e4:	ecce                	sd	s3,88(sp)
    800001e6:	e8d2                	sd	s4,80(sp)
    800001e8:	e4d6                	sd	s5,72(sp)
    800001ea:	e0da                	sd	s6,64(sp)
    800001ec:	fc5e                	sd	s7,56(sp)
    800001ee:	f862                	sd	s8,48(sp)
    800001f0:	f466                	sd	s9,40(sp)
    800001f2:	f06a                	sd	s10,32(sp)
    800001f4:	ec6e                	sd	s11,24(sp)
    800001f6:	0100                	addi	s0,sp,128
    800001f8:	8a2a                	mv	s4,a0
    800001fa:	e40c                	sd	a1,8(s0)
    800001fc:	e810                	sd	a2,16(s0)
    800001fe:	ec14                	sd	a3,24(s0)
    80000200:	f018                	sd	a4,32(s0)
    80000202:	f41c                	sd	a5,40(s0)
    80000204:	03043823          	sd	a6,48(s0)
    80000208:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    8000020c:	0000bd97          	auipc	s11,0xb
    80000210:	3ecdad83          	lw	s11,1004(s11) # 8000b5f8 <pr+0x18>
  if(locking)
    80000214:	020d9b63          	bnez	s11,8000024a <printf+0x70>
  if (fmt == 0)
    80000218:	040a0063          	beqz	s4,80000258 <printf+0x7e>
  va_start(ap, fmt);
    8000021c:	00840793          	addi	a5,s0,8
    80000220:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000224:	000a4503          	lbu	a0,0(s4)
    80000228:	12050763          	beqz	a0,80000356 <printf+0x17c>
    8000022c:	4981                	li	s3,0
    if(c != '%'){
    8000022e:	02500a93          	li	s5,37
    switch(c){
    80000232:	07000b93          	li	s7,112
  uartputc_sync('x');
    80000236:	4d41                	li	s10,16
    uartputc_sync(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000238:	00003b17          	auipc	s6,0x3
    8000023c:	df0b0b13          	addi	s6,s6,-528 # 80003028 <digits>
    switch(c){
    80000240:	07300c93          	li	s9,115
    80000244:	06400c13          	li	s8,100
    80000248:	a03d                	j	80000276 <printf+0x9c>
    acquire(&pr.lock);
    8000024a:	0000b517          	auipc	a0,0xb
    8000024e:	39650513          	addi	a0,a0,918 # 8000b5e0 <pr>
    80000252:	4a6000ef          	jal	ra,800006f8 <acquire>
    80000256:	b7c9                	j	80000218 <printf+0x3e>
    panic("null fmt");
    80000258:	00003517          	auipc	a0,0x3
    8000025c:	db850513          	addi	a0,a0,-584 # 80003010 <etext+0x10>
    80000260:	f3dff0ef          	jal	ra,8000019c <panic>
      uartputc_sync(c);
    80000264:	1ac000ef          	jal	ra,80000410 <uartputc_sync>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000268:	2985                	addiw	s3,s3,1
    8000026a:	013a07b3          	add	a5,s4,s3
    8000026e:	0007c503          	lbu	a0,0(a5)
    80000272:	0e050263          	beqz	a0,80000356 <printf+0x17c>
    if(c != '%'){
    80000276:	ff5517e3          	bne	a0,s5,80000264 <printf+0x8a>
    c = fmt[++i] & 0xff;
    8000027a:	2985                	addiw	s3,s3,1
    8000027c:	013a07b3          	add	a5,s4,s3
    80000280:	0007c783          	lbu	a5,0(a5)
    80000284:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000288:	c7f9                	beqz	a5,80000356 <printf+0x17c>
    switch(c){
    8000028a:	05778663          	beq	a5,s7,800002d6 <printf+0xfc>
    8000028e:	02fbf463          	bgeu	s7,a5,800002b6 <printf+0xdc>
    80000292:	07978e63          	beq	a5,s9,8000030e <printf+0x134>
    80000296:	07800713          	li	a4,120
    8000029a:	0ae79763          	bne	a5,a4,80000348 <printf+0x16e>
      printint(va_arg(ap, int), 16, 1);
    8000029e:	f8843783          	ld	a5,-120(s0)
    800002a2:	00878713          	addi	a4,a5,8
    800002a6:	f8e43423          	sd	a4,-120(s0)
    800002aa:	4605                	li	a2,1
    800002ac:	85ea                	mv	a1,s10
    800002ae:	4388                	lw	a0,0(a5)
    800002b0:	e4dff0ef          	jal	ra,800000fc <printint>
      break;
    800002b4:	bf55                	j	80000268 <printf+0x8e>
    switch(c){
    800002b6:	09578563          	beq	a5,s5,80000340 <printf+0x166>
    800002ba:	09879763          	bne	a5,s8,80000348 <printf+0x16e>
      printint(va_arg(ap, int), 10, 1);
    800002be:	f8843783          	ld	a5,-120(s0)
    800002c2:	00878713          	addi	a4,a5,8
    800002c6:	f8e43423          	sd	a4,-120(s0)
    800002ca:	4605                	li	a2,1
    800002cc:	45a9                	li	a1,10
    800002ce:	4388                	lw	a0,0(a5)
    800002d0:	e2dff0ef          	jal	ra,800000fc <printint>
      break;
    800002d4:	bf51                	j	80000268 <printf+0x8e>
      printptr(va_arg(ap, uint64));
    800002d6:	f8843783          	ld	a5,-120(s0)
    800002da:	00878713          	addi	a4,a5,8
    800002de:	f8e43423          	sd	a4,-120(s0)
    800002e2:	0007b903          	ld	s2,0(a5)
  uartputc_sync('0');
    800002e6:	03000513          	li	a0,48
    800002ea:	126000ef          	jal	ra,80000410 <uartputc_sync>
  uartputc_sync('x');
    800002ee:	07800513          	li	a0,120
    800002f2:	11e000ef          	jal	ra,80000410 <uartputc_sync>
    800002f6:	84ea                	mv	s1,s10
    uartputc_sync(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800002f8:	03c95793          	srli	a5,s2,0x3c
    800002fc:	97da                	add	a5,a5,s6
    800002fe:	0007c503          	lbu	a0,0(a5)
    80000302:	10e000ef          	jal	ra,80000410 <uartputc_sync>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000306:	0912                	slli	s2,s2,0x4
    80000308:	34fd                	addiw	s1,s1,-1
    8000030a:	f4fd                	bnez	s1,800002f8 <printf+0x11e>
    8000030c:	bfb1                	j	80000268 <printf+0x8e>
      if((s = va_arg(ap, char*)) == 0)
    8000030e:	f8843783          	ld	a5,-120(s0)
    80000312:	00878713          	addi	a4,a5,8
    80000316:	f8e43423          	sd	a4,-120(s0)
    8000031a:	6384                	ld	s1,0(a5)
    8000031c:	c899                	beqz	s1,80000332 <printf+0x158>
      for(; *s; s++)
    8000031e:	0004c503          	lbu	a0,0(s1)
    80000322:	d139                	beqz	a0,80000268 <printf+0x8e>
        uartputc_sync(*s);
    80000324:	0ec000ef          	jal	ra,80000410 <uartputc_sync>
      for(; *s; s++)
    80000328:	0485                	addi	s1,s1,1
    8000032a:	0004c503          	lbu	a0,0(s1)
    8000032e:	f97d                	bnez	a0,80000324 <printf+0x14a>
    80000330:	bf25                	j	80000268 <printf+0x8e>
        s = "(null)";
    80000332:	00003497          	auipc	s1,0x3
    80000336:	cd648493          	addi	s1,s1,-810 # 80003008 <etext+0x8>
      for(; *s; s++)
    8000033a:	02800513          	li	a0,40
    8000033e:	b7dd                	j	80000324 <printf+0x14a>
      uartputc_sync('%');
    80000340:	8556                	mv	a0,s5
    80000342:	0ce000ef          	jal	ra,80000410 <uartputc_sync>
      break;
    80000346:	b70d                	j	80000268 <printf+0x8e>
      uartputc_sync('%');
    80000348:	8556                	mv	a0,s5
    8000034a:	0c6000ef          	jal	ra,80000410 <uartputc_sync>
      uartputc_sync(c);
    8000034e:	8526                	mv	a0,s1
    80000350:	0c0000ef          	jal	ra,80000410 <uartputc_sync>
      break;
    80000354:	bf11                	j	80000268 <printf+0x8e>
  if(locking)
    80000356:	020d9163          	bnez	s11,80000378 <printf+0x19e>
}
    8000035a:	70e6                	ld	ra,120(sp)
    8000035c:	7446                	ld	s0,112(sp)
    8000035e:	74a6                	ld	s1,104(sp)
    80000360:	7906                	ld	s2,96(sp)
    80000362:	69e6                	ld	s3,88(sp)
    80000364:	6a46                	ld	s4,80(sp)
    80000366:	6aa6                	ld	s5,72(sp)
    80000368:	6b06                	ld	s6,64(sp)
    8000036a:	7be2                	ld	s7,56(sp)
    8000036c:	7c42                	ld	s8,48(sp)
    8000036e:	7ca2                	ld	s9,40(sp)
    80000370:	7d02                	ld	s10,32(sp)
    80000372:	6de2                	ld	s11,24(sp)
    80000374:	6129                	addi	sp,sp,192
    80000376:	8082                	ret
    release(&pr.lock);
    80000378:	0000b517          	auipc	a0,0xb
    8000037c:	26850513          	addi	a0,a0,616 # 8000b5e0 <pr>
    80000380:	410000ef          	jal	ra,80000790 <release>
}
    80000384:	bfd9                	j	8000035a <printf+0x180>

0000000080000386 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000386:	1101                	addi	sp,sp,-32
    80000388:	ec06                	sd	ra,24(sp)
    8000038a:	e822                	sd	s0,16(sp)
    8000038c:	e426                	sd	s1,8(sp)
    8000038e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000390:	0000b497          	auipc	s1,0xb
    80000394:	25048493          	addi	s1,s1,592 # 8000b5e0 <pr>
    80000398:	00003597          	auipc	a1,0x3
    8000039c:	c8858593          	addi	a1,a1,-888 # 80003020 <etext+0x20>
    800003a0:	8526                	mv	a0,s1
    800003a2:	2d6000ef          	jal	ra,80000678 <initlock>
  pr.locking = 1;
    800003a6:	4785                	li	a5,1
    800003a8:	cc9c                	sw	a5,24(s1)
}
    800003aa:	60e2                	ld	ra,24(sp)
    800003ac:	6442                	ld	s0,16(sp)
    800003ae:	64a2                	ld	s1,8(sp)
    800003b0:	6105                	addi	sp,sp,32
    800003b2:	8082                	ret

00000000800003b4 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800003b4:	1141                	addi	sp,sp,-16
    800003b6:	e406                	sd	ra,8(sp)
    800003b8:	e022                	sd	s0,0(sp)
    800003ba:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800003bc:	100007b7          	lui	a5,0x10000
    800003c0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800003c4:	f8000713          	li	a4,-128
    800003c8:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800003cc:	470d                	li	a4,3
    800003ce:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800003d2:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800003d6:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800003da:	469d                	li	a3,7
    800003dc:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800003e0:	00e780a3          	sb	a4,1(a5)
  
  printf("uartinit: IER=0x%x (should be 0x3)\n", ReadReg(IER));
    800003e4:	0017c583          	lbu	a1,1(a5)
    800003e8:	00003517          	auipc	a0,0x3
    800003ec:	c5850513          	addi	a0,a0,-936 # 80003040 <digits+0x18>
    800003f0:	debff0ef          	jal	ra,800001da <printf>

  initlock(&uart_tx_lock, "uart");
    800003f4:	00003597          	auipc	a1,0x3
    800003f8:	c7458593          	addi	a1,a1,-908 # 80003068 <digits+0x40>
    800003fc:	0000b517          	auipc	a0,0xb
    80000400:	20450513          	addi	a0,a0,516 # 8000b600 <uart_tx_lock>
    80000404:	274000ef          	jal	ra,80000678 <initlock>
}
    80000408:	60a2                	ld	ra,8(sp)
    8000040a:	6402                	ld	s0,0(sp)
    8000040c:	0141                	addi	sp,sp,16
    8000040e:	8082                	ret

0000000080000410 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000410:	1101                	addi	sp,sp,-32
    80000412:	ec06                	sd	ra,24(sp)
    80000414:	e822                	sd	s0,16(sp)
    80000416:	e426                	sd	s1,8(sp)
    80000418:	1000                	addi	s0,sp,32
    8000041a:	84aa                	mv	s1,a0
  push_off();
    8000041c:	29c000ef          	jal	ra,800006b8 <push_off>

  if(panicked){
    80000420:	00003797          	auipc	a5,0x3
    80000424:	0407a783          	lw	a5,64(a5) # 80003460 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000428:	10000737          	lui	a4,0x10000
  if(panicked){
    8000042c:	c391                	beqz	a5,80000430 <uartputc_sync+0x20>
    for(;;)
    8000042e:	a001                	j	8000042e <uartputc_sync+0x1e>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000430:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000434:	0207f793          	andi	a5,a5,32
    80000438:	dfe5                	beqz	a5,80000430 <uartputc_sync+0x20>
    ;
  WriteReg(THR, c);
    8000043a:	0ff4f513          	zext.b	a0,s1
    8000043e:	100007b7          	lui	a5,0x10000
    80000442:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000446:	2f6000ef          	jal	ra,8000073c <pop_off>
}
    8000044a:	60e2                	ld	ra,24(sp)
    8000044c:	6442                	ld	s0,16(sp)
    8000044e:	64a2                	ld	s1,8(sp)
    80000450:	6105                	addi	sp,sp,32
    80000452:	8082                	ret

0000000080000454 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000454:	00003797          	auipc	a5,0x3
    80000458:	0147b783          	ld	a5,20(a5) # 80003468 <uart_tx_r>
    8000045c:	00003717          	auipc	a4,0x3
    80000460:	01473703          	ld	a4,20(a4) # 80003470 <uart_tx_w>
    80000464:	06f70c63          	beq	a4,a5,800004dc <uartstart+0x88>
{
    80000468:	7139                	addi	sp,sp,-64
    8000046a:	fc06                	sd	ra,56(sp)
    8000046c:	f822                	sd	s0,48(sp)
    8000046e:	f426                	sd	s1,40(sp)
    80000470:	f04a                	sd	s2,32(sp)
    80000472:	ec4e                	sd	s3,24(sp)
    80000474:	e852                	sd	s4,16(sp)
    80000476:	e456                	sd	s5,8(sp)
    80000478:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      ReadReg(ISR);
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000047a:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000047e:	0000ba17          	auipc	s4,0xb
    80000482:	182a0a13          	addi	s4,s4,386 # 8000b600 <uart_tx_lock>
    uart_tx_r += 1;
    80000486:	00003497          	auipc	s1,0x3
    8000048a:	fe248493          	addi	s1,s1,-30 # 80003468 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000048e:	00003997          	auipc	s3,0x3
    80000492:	fe298993          	addi	s3,s3,-30 # 80003470 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000496:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000049a:	02077713          	andi	a4,a4,32
    8000049e:	c715                	beqz	a4,800004ca <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800004a0:	01f7f713          	andi	a4,a5,31
    800004a4:	9752                	add	a4,a4,s4
    800004a6:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    800004aa:	0785                	addi	a5,a5,1
    800004ac:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800004ae:	8526                	mv	a0,s1
    800004b0:	753000ef          	jal	ra,80001402 <wakeup>
    
    WriteReg(THR, c);
    800004b4:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800004b8:	609c                	ld	a5,0(s1)
    800004ba:	0009b703          	ld	a4,0(s3)
    800004be:	fcf71ce3          	bne	a4,a5,80000496 <uartstart+0x42>
      ReadReg(ISR);
    800004c2:	100007b7          	lui	a5,0x10000
    800004c6:	0027c783          	lbu	a5,2(a5) # 10000002 <_entry-0x6ffffffe>
  }
}
    800004ca:	70e2                	ld	ra,56(sp)
    800004cc:	7442                	ld	s0,48(sp)
    800004ce:	74a2                	ld	s1,40(sp)
    800004d0:	7902                	ld	s2,32(sp)
    800004d2:	69e2                	ld	s3,24(sp)
    800004d4:	6a42                	ld	s4,16(sp)
    800004d6:	6aa2                	ld	s5,8(sp)
    800004d8:	6121                	addi	sp,sp,64
    800004da:	8082                	ret
      ReadReg(ISR);
    800004dc:	100007b7          	lui	a5,0x10000
    800004e0:	0027c783          	lbu	a5,2(a5) # 10000002 <_entry-0x6ffffffe>
      return;
    800004e4:	8082                	ret

00000000800004e6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800004e6:	1141                	addi	sp,sp,-16
    800004e8:	e422                	sd	s0,8(sp)
    800004ea:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800004ec:	100007b7          	lui	a5,0x10000
    800004f0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800004f4:	8b85                	andi	a5,a5,1
    800004f6:	cb81                	beqz	a5,80000506 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800004f8:	100007b7          	lui	a5,0x10000
    800004fc:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000500:	6422                	ld	s0,8(sp)
    80000502:	0141                	addi	sp,sp,16
    80000504:	8082                	ret
    return -1;
    80000506:	557d                	li	a0,-1
    80000508:	bfe5                	j	80000500 <uartgetc+0x1a>

000000008000050a <uartintr>:
// arrived, or the uart is ready for more output, or
// both. called from devintr().

void
uartintr(void)
{
    8000050a:	1101                	addi	sp,sp,-32
    8000050c:	ec06                	sd	ra,24(sp)
    8000050e:	e822                	sd	s0,16(sp)
    80000510:	e426                	sd	s1,8(sp)
    80000512:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000514:	54fd                	li	s1,-1
    80000516:	a019                	j	8000051c <uartintr+0x12>
      break;
    uartputc_sync(c);
    80000518:	ef9ff0ef          	jal	ra,80000410 <uartputc_sync>
    int c = uartgetc();
    8000051c:	fcbff0ef          	jal	ra,800004e6 <uartgetc>
    if(c == -1)
    80000520:	fe951ce3          	bne	a0,s1,80000518 <uartintr+0xe>
    
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000524:	0000b497          	auipc	s1,0xb
    80000528:	0dc48493          	addi	s1,s1,220 # 8000b600 <uart_tx_lock>
    8000052c:	8526                	mv	a0,s1
    8000052e:	1ca000ef          	jal	ra,800006f8 <acquire>
  uartstart();
    80000532:	f23ff0ef          	jal	ra,80000454 <uartstart>
  release(&uart_tx_lock);
    80000536:	8526                	mv	a0,s1
    80000538:	258000ef          	jal	ra,80000790 <release>
}
    8000053c:	60e2                	ld	ra,24(sp)
    8000053e:	6442                	ld	s0,16(sp)
    80000540:	64a2                	ld	s1,8(sp)
    80000542:	6105                	addi	sp,sp,32
    80000544:	8082                	ret

0000000080000546 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000546:	1101                	addi	sp,sp,-32
    80000548:	ec06                	sd	ra,24(sp)
    8000054a:	e822                	sd	s0,16(sp)
    8000054c:	e426                	sd	s1,8(sp)
    8000054e:	e04a                	sd	s2,0(sp)
    80000550:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000552:	03451793          	slli	a5,a0,0x34
    80000556:	e7a9                	bnez	a5,800005a0 <kfree+0x5a>
    80000558:	84aa                	mv	s1,a0
    8000055a:	0000b797          	auipc	a5,0xb
    8000055e:	60678793          	addi	a5,a5,1542 # 8000bb60 <end>
    80000562:	02f56f63          	bltu	a0,a5,800005a0 <kfree+0x5a>
    80000566:	47c5                	li	a5,17
    80000568:	07ee                	slli	a5,a5,0x1b
    8000056a:	02f57b63          	bgeu	a0,a5,800005a0 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    8000056e:	6605                	lui	a2,0x1
    80000570:	4585                	li	a1,1
    80000572:	25a000ef          	jal	ra,800007cc <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000576:	0000b917          	auipc	s2,0xb
    8000057a:	0c290913          	addi	s2,s2,194 # 8000b638 <kmem>
    8000057e:	854a                	mv	a0,s2
    80000580:	178000ef          	jal	ra,800006f8 <acquire>
  r->next = kmem.freelist;
    80000584:	01893783          	ld	a5,24(s2)
    80000588:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    8000058a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    8000058e:	854a                	mv	a0,s2
    80000590:	200000ef          	jal	ra,80000790 <release>
}
    80000594:	60e2                	ld	ra,24(sp)
    80000596:	6442                	ld	s0,16(sp)
    80000598:	64a2                	ld	s1,8(sp)
    8000059a:	6902                	ld	s2,0(sp)
    8000059c:	6105                	addi	sp,sp,32
    8000059e:	8082                	ret
    panic("kfree");
    800005a0:	00003517          	auipc	a0,0x3
    800005a4:	ad050513          	addi	a0,a0,-1328 # 80003070 <digits+0x48>
    800005a8:	bf5ff0ef          	jal	ra,8000019c <panic>

00000000800005ac <freerange>:
{
    800005ac:	7179                	addi	sp,sp,-48
    800005ae:	f406                	sd	ra,40(sp)
    800005b0:	f022                	sd	s0,32(sp)
    800005b2:	ec26                	sd	s1,24(sp)
    800005b4:	e84a                	sd	s2,16(sp)
    800005b6:	e44e                	sd	s3,8(sp)
    800005b8:	e052                	sd	s4,0(sp)
    800005ba:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    800005bc:	6785                	lui	a5,0x1
    800005be:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    800005c2:	00e504b3          	add	s1,a0,a4
    800005c6:	777d                	lui	a4,0xfffff
    800005c8:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    800005ca:	94be                	add	s1,s1,a5
    800005cc:	0095ec63          	bltu	a1,s1,800005e4 <freerange+0x38>
    800005d0:	892e                	mv	s2,a1
    kfree(p);
    800005d2:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    800005d4:	6985                	lui	s3,0x1
    kfree(p);
    800005d6:	01448533          	add	a0,s1,s4
    800005da:	f6dff0ef          	jal	ra,80000546 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    800005de:	94ce                	add	s1,s1,s3
    800005e0:	fe997be3          	bgeu	s2,s1,800005d6 <freerange+0x2a>
}
    800005e4:	70a2                	ld	ra,40(sp)
    800005e6:	7402                	ld	s0,32(sp)
    800005e8:	64e2                	ld	s1,24(sp)
    800005ea:	6942                	ld	s2,16(sp)
    800005ec:	69a2                	ld	s3,8(sp)
    800005ee:	6a02                	ld	s4,0(sp)
    800005f0:	6145                	addi	sp,sp,48
    800005f2:	8082                	ret

00000000800005f4 <kinit>:
{
    800005f4:	1141                	addi	sp,sp,-16
    800005f6:	e406                	sd	ra,8(sp)
    800005f8:	e022                	sd	s0,0(sp)
    800005fa:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    800005fc:	00003597          	auipc	a1,0x3
    80000600:	a7c58593          	addi	a1,a1,-1412 # 80003078 <digits+0x50>
    80000604:	0000b517          	auipc	a0,0xb
    80000608:	03450513          	addi	a0,a0,52 # 8000b638 <kmem>
    8000060c:	06c000ef          	jal	ra,80000678 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000610:	45c5                	li	a1,17
    80000612:	05ee                	slli	a1,a1,0x1b
    80000614:	0000b517          	auipc	a0,0xb
    80000618:	54c50513          	addi	a0,a0,1356 # 8000bb60 <end>
    8000061c:	f91ff0ef          	jal	ra,800005ac <freerange>
}
    80000620:	60a2                	ld	ra,8(sp)
    80000622:	6402                	ld	s0,0(sp)
    80000624:	0141                	addi	sp,sp,16
    80000626:	8082                	ret

0000000080000628 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000628:	1101                	addi	sp,sp,-32
    8000062a:	ec06                	sd	ra,24(sp)
    8000062c:	e822                	sd	s0,16(sp)
    8000062e:	e426                	sd	s1,8(sp)
    80000630:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000632:	0000b497          	auipc	s1,0xb
    80000636:	00648493          	addi	s1,s1,6 # 8000b638 <kmem>
    8000063a:	8526                	mv	a0,s1
    8000063c:	0bc000ef          	jal	ra,800006f8 <acquire>
  r = kmem.freelist;
    80000640:	6c84                	ld	s1,24(s1)
  if(r)
    80000642:	c485                	beqz	s1,8000066a <kalloc+0x42>
    kmem.freelist = r->next;
    80000644:	609c                	ld	a5,0(s1)
    80000646:	0000b517          	auipc	a0,0xb
    8000064a:	ff250513          	addi	a0,a0,-14 # 8000b638 <kmem>
    8000064e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000650:	140000ef          	jal	ra,80000790 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000654:	6605                	lui	a2,0x1
    80000656:	4595                	li	a1,5
    80000658:	8526                	mv	a0,s1
    8000065a:	172000ef          	jal	ra,800007cc <memset>
  return (void*)r;
}
    8000065e:	8526                	mv	a0,s1
    80000660:	60e2                	ld	ra,24(sp)
    80000662:	6442                	ld	s0,16(sp)
    80000664:	64a2                	ld	s1,8(sp)
    80000666:	6105                	addi	sp,sp,32
    80000668:	8082                	ret
  release(&kmem.lock);
    8000066a:	0000b517          	auipc	a0,0xb
    8000066e:	fce50513          	addi	a0,a0,-50 # 8000b638 <kmem>
    80000672:	11e000ef          	jal	ra,80000790 <release>
  if(r)
    80000676:	b7e5                	j	8000065e <kalloc+0x36>

0000000080000678 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000678:	1141                	addi	sp,sp,-16
    8000067a:	e422                	sd	s0,8(sp)
    8000067c:	0800                	addi	s0,sp,16
  lk->name = name;
    8000067e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000680:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000684:	00053823          	sd	zero,16(a0)
}
    80000688:	6422                	ld	s0,8(sp)
    8000068a:	0141                	addi	sp,sp,16
    8000068c:	8082                	ret

000000008000068e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    8000068e:	411c                	lw	a5,0(a0)
    80000690:	e399                	bnez	a5,80000696 <holding+0x8>
    80000692:	4501                	li	a0,0
  return r;
}
    80000694:	8082                	ret
{
    80000696:	1101                	addi	sp,sp,-32
    80000698:	ec06                	sd	ra,24(sp)
    8000069a:	e822                	sd	s0,16(sp)
    8000069c:	e426                	sd	s1,8(sp)
    8000069e:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    800006a0:	6904                	ld	s1,16(a0)
    800006a2:	2cd000ef          	jal	ra,8000116e <mycpu>
    800006a6:	40a48533          	sub	a0,s1,a0
    800006aa:	00153513          	seqz	a0,a0
}
    800006ae:	60e2                	ld	ra,24(sp)
    800006b0:	6442                	ld	s0,16(sp)
    800006b2:	64a2                	ld	s1,8(sp)
    800006b4:	6105                	addi	sp,sp,32
    800006b6:	8082                	ret

00000000800006b8 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    800006b8:	1101                	addi	sp,sp,-32
    800006ba:	ec06                	sd	ra,24(sp)
    800006bc:	e822                	sd	s0,16(sp)
    800006be:	e426                	sd	s1,8(sp)
    800006c0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800006c2:	100024f3          	csrr	s1,sstatus
    800006c6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800006ca:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800006cc:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    800006d0:	29f000ef          	jal	ra,8000116e <mycpu>
    800006d4:	5d3c                	lw	a5,120(a0)
    800006d6:	cb99                	beqz	a5,800006ec <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    800006d8:	297000ef          	jal	ra,8000116e <mycpu>
    800006dc:	5d3c                	lw	a5,120(a0)
    800006de:	2785                	addiw	a5,a5,1
    800006e0:	dd3c                	sw	a5,120(a0)
}
    800006e2:	60e2                	ld	ra,24(sp)
    800006e4:	6442                	ld	s0,16(sp)
    800006e6:	64a2                	ld	s1,8(sp)
    800006e8:	6105                	addi	sp,sp,32
    800006ea:	8082                	ret
    mycpu()->intena = old;
    800006ec:	283000ef          	jal	ra,8000116e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    800006f0:	8085                	srli	s1,s1,0x1
    800006f2:	8885                	andi	s1,s1,1
    800006f4:	dd64                	sw	s1,124(a0)
    800006f6:	b7cd                	j	800006d8 <push_off+0x20>

00000000800006f8 <acquire>:
{
    800006f8:	1101                	addi	sp,sp,-32
    800006fa:	ec06                	sd	ra,24(sp)
    800006fc:	e822                	sd	s0,16(sp)
    800006fe:	e426                	sd	s1,8(sp)
    80000700:	1000                	addi	s0,sp,32
    80000702:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000704:	fb5ff0ef          	jal	ra,800006b8 <push_off>
  if(holding(lk))
    80000708:	8526                	mv	a0,s1
    8000070a:	f85ff0ef          	jal	ra,8000068e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    8000070e:	4705                	li	a4,1
  if(holding(lk))
    80000710:	e105                	bnez	a0,80000730 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000712:	87ba                	mv	a5,a4
    80000714:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000718:	2781                	sext.w	a5,a5
    8000071a:	ffe5                	bnez	a5,80000712 <acquire+0x1a>
  __sync_synchronize();
    8000071c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000720:	24f000ef          	jal	ra,8000116e <mycpu>
    80000724:	e888                	sd	a0,16(s1)
}
    80000726:	60e2                	ld	ra,24(sp)
    80000728:	6442                	ld	s0,16(sp)
    8000072a:	64a2                	ld	s1,8(sp)
    8000072c:	6105                	addi	sp,sp,32
    8000072e:	8082                	ret
    panic("acquire");
    80000730:	00003517          	auipc	a0,0x3
    80000734:	95050513          	addi	a0,a0,-1712 # 80003080 <digits+0x58>
    80000738:	a65ff0ef          	jal	ra,8000019c <panic>

000000008000073c <pop_off>:

void
pop_off(void)
{
    8000073c:	1141                	addi	sp,sp,-16
    8000073e:	e406                	sd	ra,8(sp)
    80000740:	e022                	sd	s0,0(sp)
    80000742:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000744:	22b000ef          	jal	ra,8000116e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000748:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000074c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000074e:	e78d                	bnez	a5,80000778 <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000750:	5d3c                	lw	a5,120(a0)
    80000752:	02f05963          	blez	a5,80000784 <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000756:	37fd                	addiw	a5,a5,-1
    80000758:	0007871b          	sext.w	a4,a5
    8000075c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    8000075e:	eb09                	bnez	a4,80000770 <pop_off+0x34>
    80000760:	5d7c                	lw	a5,124(a0)
    80000762:	c799                	beqz	a5,80000770 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000764:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000768:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000076c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000770:	60a2                	ld	ra,8(sp)
    80000772:	6402                	ld	s0,0(sp)
    80000774:	0141                	addi	sp,sp,16
    80000776:	8082                	ret
    panic("pop_off - interruptible");
    80000778:	00003517          	auipc	a0,0x3
    8000077c:	91050513          	addi	a0,a0,-1776 # 80003088 <digits+0x60>
    80000780:	a1dff0ef          	jal	ra,8000019c <panic>
    panic("pop_off");
    80000784:	00003517          	auipc	a0,0x3
    80000788:	91c50513          	addi	a0,a0,-1764 # 800030a0 <digits+0x78>
    8000078c:	a11ff0ef          	jal	ra,8000019c <panic>

0000000080000790 <release>:
{
    80000790:	1101                	addi	sp,sp,-32
    80000792:	ec06                	sd	ra,24(sp)
    80000794:	e822                	sd	s0,16(sp)
    80000796:	e426                	sd	s1,8(sp)
    80000798:	1000                	addi	s0,sp,32
    8000079a:	84aa                	mv	s1,a0
  if(!holding(lk))
    8000079c:	ef3ff0ef          	jal	ra,8000068e <holding>
    800007a0:	c105                	beqz	a0,800007c0 <release+0x30>
  lk->cpu = 0;
    800007a2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    800007a6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    800007aa:	0f50000f          	fence	iorw,ow
    800007ae:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    800007b2:	f8bff0ef          	jal	ra,8000073c <pop_off>
}
    800007b6:	60e2                	ld	ra,24(sp)
    800007b8:	6442                	ld	s0,16(sp)
    800007ba:	64a2                	ld	s1,8(sp)
    800007bc:	6105                	addi	sp,sp,32
    800007be:	8082                	ret
    panic("release");
    800007c0:	00003517          	auipc	a0,0x3
    800007c4:	8e850513          	addi	a0,a0,-1816 # 800030a8 <digits+0x80>
    800007c8:	9d5ff0ef          	jal	ra,8000019c <panic>

00000000800007cc <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    800007cc:	1141                	addi	sp,sp,-16
    800007ce:	e422                	sd	s0,8(sp)
    800007d0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    800007d2:	ca19                	beqz	a2,800007e8 <memset+0x1c>
    800007d4:	87aa                	mv	a5,a0
    800007d6:	1602                	slli	a2,a2,0x20
    800007d8:	9201                	srli	a2,a2,0x20
    800007da:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    800007de:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    800007e2:	0785                	addi	a5,a5,1
    800007e4:	fee79de3          	bne	a5,a4,800007de <memset+0x12>
  }
  return dst;
}
    800007e8:	6422                	ld	s0,8(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    800007ee:	1141                	addi	sp,sp,-16
    800007f0:	e422                	sd	s0,8(sp)
    800007f2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    800007f4:	ca05                	beqz	a2,80000824 <memcmp+0x36>
    800007f6:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    800007fa:	1682                	slli	a3,a3,0x20
    800007fc:	9281                	srli	a3,a3,0x20
    800007fe:	0685                	addi	a3,a3,1
    80000800:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000802:	00054783          	lbu	a5,0(a0)
    80000806:	0005c703          	lbu	a4,0(a1)
    8000080a:	00e79863          	bne	a5,a4,8000081a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    8000080e:	0505                	addi	a0,a0,1
    80000810:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000812:	fed518e3          	bne	a0,a3,80000802 <memcmp+0x14>
  }

  return 0;
    80000816:	4501                	li	a0,0
    80000818:	a019                	j	8000081e <memcmp+0x30>
      return *s1 - *s2;
    8000081a:	40e7853b          	subw	a0,a5,a4
}
    8000081e:	6422                	ld	s0,8(sp)
    80000820:	0141                	addi	sp,sp,16
    80000822:	8082                	ret
  return 0;
    80000824:	4501                	li	a0,0
    80000826:	bfe5                	j	8000081e <memcmp+0x30>

0000000080000828 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000828:	1141                	addi	sp,sp,-16
    8000082a:	e422                	sd	s0,8(sp)
    8000082c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    8000082e:	c205                	beqz	a2,8000084e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000830:	02a5e263          	bltu	a1,a0,80000854 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000834:	1602                	slli	a2,a2,0x20
    80000836:	9201                	srli	a2,a2,0x20
    80000838:	00c587b3          	add	a5,a1,a2
{
    8000083c:	872a                	mv	a4,a0
      *d++ = *s++;
    8000083e:	0585                	addi	a1,a1,1
    80000840:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7fff34a1>
    80000842:	fff5c683          	lbu	a3,-1(a1)
    80000846:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    8000084a:	fef59ae3          	bne	a1,a5,8000083e <memmove+0x16>

  return dst;
}
    8000084e:	6422                	ld	s0,8(sp)
    80000850:	0141                	addi	sp,sp,16
    80000852:	8082                	ret
  if(s < d && s + n > d){
    80000854:	02061693          	slli	a3,a2,0x20
    80000858:	9281                	srli	a3,a3,0x20
    8000085a:	00d58733          	add	a4,a1,a3
    8000085e:	fce57be3          	bgeu	a0,a4,80000834 <memmove+0xc>
    d += n;
    80000862:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000864:	fff6079b          	addiw	a5,a2,-1
    80000868:	1782                	slli	a5,a5,0x20
    8000086a:	9381                	srli	a5,a5,0x20
    8000086c:	fff7c793          	not	a5,a5
    80000870:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000872:	177d                	addi	a4,a4,-1
    80000874:	16fd                	addi	a3,a3,-1
    80000876:	00074603          	lbu	a2,0(a4)
    8000087a:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    8000087e:	fee79ae3          	bne	a5,a4,80000872 <memmove+0x4a>
    80000882:	b7f1                	j	8000084e <memmove+0x26>

0000000080000884 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000884:	1141                	addi	sp,sp,-16
    80000886:	e406                	sd	ra,8(sp)
    80000888:	e022                	sd	s0,0(sp)
    8000088a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    8000088c:	f9dff0ef          	jal	ra,80000828 <memmove>
}
    80000890:	60a2                	ld	ra,8(sp)
    80000892:	6402                	ld	s0,0(sp)
    80000894:	0141                	addi	sp,sp,16
    80000896:	8082                	ret

0000000080000898 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000898:	1141                	addi	sp,sp,-16
    8000089a:	e422                	sd	s0,8(sp)
    8000089c:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    8000089e:	ce11                	beqz	a2,800008ba <strncmp+0x22>
    800008a0:	00054783          	lbu	a5,0(a0)
    800008a4:	cf89                	beqz	a5,800008be <strncmp+0x26>
    800008a6:	0005c703          	lbu	a4,0(a1)
    800008aa:	00f71a63          	bne	a4,a5,800008be <strncmp+0x26>
    n--, p++, q++;
    800008ae:	367d                	addiw	a2,a2,-1
    800008b0:	0505                	addi	a0,a0,1
    800008b2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    800008b4:	f675                	bnez	a2,800008a0 <strncmp+0x8>
  if(n == 0)
    return 0;
    800008b6:	4501                	li	a0,0
    800008b8:	a809                	j	800008ca <strncmp+0x32>
    800008ba:	4501                	li	a0,0
    800008bc:	a039                	j	800008ca <strncmp+0x32>
  if(n == 0)
    800008be:	ca09                	beqz	a2,800008d0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800008c0:	00054503          	lbu	a0,0(a0)
    800008c4:	0005c783          	lbu	a5,0(a1)
    800008c8:	9d1d                	subw	a0,a0,a5
}
    800008ca:	6422                	ld	s0,8(sp)
    800008cc:	0141                	addi	sp,sp,16
    800008ce:	8082                	ret
    return 0;
    800008d0:	4501                	li	a0,0
    800008d2:	bfe5                	j	800008ca <strncmp+0x32>

00000000800008d4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800008d4:	1141                	addi	sp,sp,-16
    800008d6:	e422                	sd	s0,8(sp)
    800008d8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800008da:	872a                	mv	a4,a0
    800008dc:	8832                	mv	a6,a2
    800008de:	367d                	addiw	a2,a2,-1
    800008e0:	01005963          	blez	a6,800008f2 <strncpy+0x1e>
    800008e4:	0705                	addi	a4,a4,1
    800008e6:	0005c783          	lbu	a5,0(a1)
    800008ea:	fef70fa3          	sb	a5,-1(a4)
    800008ee:	0585                	addi	a1,a1,1
    800008f0:	f7f5                	bnez	a5,800008dc <strncpy+0x8>
    ;
  while(n-- > 0)
    800008f2:	86ba                	mv	a3,a4
    800008f4:	00c05c63          	blez	a2,8000090c <strncpy+0x38>
    *s++ = 0;
    800008f8:	0685                	addi	a3,a3,1
    800008fa:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    800008fe:	40d707bb          	subw	a5,a4,a3
    80000902:	37fd                	addiw	a5,a5,-1
    80000904:	010787bb          	addw	a5,a5,a6
    80000908:	fef048e3          	bgtz	a5,800008f8 <strncpy+0x24>
  return os;
}
    8000090c:	6422                	ld	s0,8(sp)
    8000090e:	0141                	addi	sp,sp,16
    80000910:	8082                	ret

0000000080000912 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000912:	1141                	addi	sp,sp,-16
    80000914:	e422                	sd	s0,8(sp)
    80000916:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000918:	02c05363          	blez	a2,8000093e <safestrcpy+0x2c>
    8000091c:	fff6069b          	addiw	a3,a2,-1
    80000920:	1682                	slli	a3,a3,0x20
    80000922:	9281                	srli	a3,a3,0x20
    80000924:	96ae                	add	a3,a3,a1
    80000926:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000928:	00d58963          	beq	a1,a3,8000093a <safestrcpy+0x28>
    8000092c:	0585                	addi	a1,a1,1
    8000092e:	0785                	addi	a5,a5,1
    80000930:	fff5c703          	lbu	a4,-1(a1)
    80000934:	fee78fa3          	sb	a4,-1(a5)
    80000938:	fb65                	bnez	a4,80000928 <safestrcpy+0x16>
    ;
  *s = 0;
    8000093a:	00078023          	sb	zero,0(a5)
  return os;
}
    8000093e:	6422                	ld	s0,8(sp)
    80000940:	0141                	addi	sp,sp,16
    80000942:	8082                	ret

0000000080000944 <strlen>:

int
strlen(const char *s)
{
    80000944:	1141                	addi	sp,sp,-16
    80000946:	e422                	sd	s0,8(sp)
    80000948:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000094a:	00054783          	lbu	a5,0(a0)
    8000094e:	cf91                	beqz	a5,8000096a <strlen+0x26>
    80000950:	0505                	addi	a0,a0,1
    80000952:	87aa                	mv	a5,a0
    80000954:	4685                	li	a3,1
    80000956:	9e89                	subw	a3,a3,a0
    80000958:	00f6853b          	addw	a0,a3,a5
    8000095c:	0785                	addi	a5,a5,1
    8000095e:	fff7c703          	lbu	a4,-1(a5)
    80000962:	fb7d                	bnez	a4,80000958 <strlen+0x14>
    ;
  return n;
}
    80000964:	6422                	ld	s0,8(sp)
    80000966:	0141                	addi	sp,sp,16
    80000968:	8082                	ret
  for(n = 0; s[n]; n++)
    8000096a:	4501                	li	a0,0
    8000096c:	bfe5                	j	80000964 <strlen+0x20>

000000008000096e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    8000096e:	1141                	addi	sp,sp,-16
    80000970:	e406                	sd	ra,8(sp)
    80000972:	e022                	sd	s0,0(sp)
    80000974:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000976:	7e8000ef          	jal	ra,8000115e <cpuid>
    plicinithart();  // ask PLIC for device interrupts
    __sync_synchronize();
    started = 1;
    userinit();      // first user process
  } else {
    while(started == 0)
    8000097a:	00003717          	auipc	a4,0x3
    8000097e:	afe70713          	addi	a4,a4,-1282 # 80003478 <started>
  if(cpuid() == 0){
    80000982:	c515                	beqz	a0,800009ae <main+0x40>
    while(started == 0)
    80000984:	431c                	lw	a5,0(a4)
    80000986:	2781                	sext.w	a5,a5
    80000988:	dff5                	beqz	a5,80000984 <main+0x16>
      ;
    __sync_synchronize();
    8000098a:	0ff0000f          	fence
    printf("cpu %d is booting!\n", cpuid()); 
    8000098e:	7d0000ef          	jal	ra,8000115e <cpuid>
    80000992:	85aa                	mv	a1,a0
    80000994:	00002517          	auipc	a0,0x2
    80000998:	71c50513          	addi	a0,a0,1820 # 800030b0 <digits+0x88>
    8000099c:	83fff0ef          	jal	ra,800001da <printf>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800009a0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800009a4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800009a8:	10079073          	csrw	sstatus,a5
  }

  intr_on();
  while (1); 
    800009ac:	a001                	j	800009ac <main+0x3e>
    printfinit();
    800009ae:	9d9ff0ef          	jal	ra,80000386 <printfinit>
    printf("cpu %d is booting!\n", cpuid()); 
    800009b2:	7ac000ef          	jal	ra,8000115e <cpuid>
    800009b6:	85aa                	mv	a1,a0
    800009b8:	00002517          	auipc	a0,0x2
    800009bc:	6f850513          	addi	a0,a0,1784 # 800030b0 <digits+0x88>
    800009c0:	81bff0ef          	jal	ra,800001da <printf>
    kinit();         // physical page allocator
    800009c4:	c31ff0ef          	jal	ra,800005f4 <kinit>
    uartinit();
    800009c8:	9edff0ef          	jal	ra,800003b4 <uartinit>
    kvminit();       // create kernel page table
    800009cc:	29e000ef          	jal	ra,80000c6a <kvminit>
    kvminithart();   // turn on paging
    800009d0:	02c000ef          	jal	ra,800009fc <kvminithart>
    procinit();      // process table
    800009d4:	742000ef          	jal	ra,80001116 <procinit>
    trapinit();      // trap vectors
    800009d8:	2f3000ef          	jal	ra,800014ca <trapinit>
    trapinithart();  // install kernel trap vector
    800009dc:	313000ef          	jal	ra,800014ee <trapinithart>
    plicinit();      // set up interrupt controller
    800009e0:	68b000ef          	jal	ra,8000186a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800009e4:	69d000ef          	jal	ra,80001880 <plicinithart>
    __sync_synchronize();
    800009e8:	0ff0000f          	fence
    started = 1;
    800009ec:	4785                	li	a5,1
    800009ee:	00003717          	auipc	a4,0x3
    800009f2:	a8f72523          	sw	a5,-1398(a4) # 80003478 <started>
    userinit();      // first user process
    800009f6:	049000ef          	jal	ra,8000123e <userinit>
    800009fa:	b75d                	j	800009a0 <main+0x32>

00000000800009fc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800009fc:	1141                	addi	sp,sp,-16
    800009fe:	e422                	sd	s0,8(sp)
    80000a00:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000a02:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000a06:	00003797          	auipc	a5,0x3
    80000a0a:	a7a7b783          	ld	a5,-1414(a5) # 80003480 <kernel_pagetable>
    80000a0e:	83b1                	srli	a5,a5,0xc
    80000a10:	577d                	li	a4,-1
    80000a12:	177e                	slli	a4,a4,0x3f
    80000a14:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000a16:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000a1a:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000a1e:	6422                	ld	s0,8(sp)
    80000a20:	0141                	addi	sp,sp,16
    80000a22:	8082                	ret

0000000080000a24 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000a24:	7139                	addi	sp,sp,-64
    80000a26:	fc06                	sd	ra,56(sp)
    80000a28:	f822                	sd	s0,48(sp)
    80000a2a:	f426                	sd	s1,40(sp)
    80000a2c:	f04a                	sd	s2,32(sp)
    80000a2e:	ec4e                	sd	s3,24(sp)
    80000a30:	e852                	sd	s4,16(sp)
    80000a32:	e456                	sd	s5,8(sp)
    80000a34:	e05a                	sd	s6,0(sp)
    80000a36:	0080                	addi	s0,sp,64
    80000a38:	84aa                	mv	s1,a0
    80000a3a:	89ae                	mv	s3,a1
    80000a3c:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000a3e:	57fd                	li	a5,-1
    80000a40:	83e9                	srli	a5,a5,0x1a
    80000a42:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000a44:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000a46:	02b7fc63          	bgeu	a5,a1,80000a7e <walk+0x5a>
    panic("walk");
    80000a4a:	00002517          	auipc	a0,0x2
    80000a4e:	67e50513          	addi	a0,a0,1662 # 800030c8 <digits+0xa0>
    80000a52:	f4aff0ef          	jal	ra,8000019c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000a56:	060a8263          	beqz	s5,80000aba <walk+0x96>
    80000a5a:	bcfff0ef          	jal	ra,80000628 <kalloc>
    80000a5e:	84aa                	mv	s1,a0
    80000a60:	c139                	beqz	a0,80000aa6 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000a62:	6605                	lui	a2,0x1
    80000a64:	4581                	li	a1,0
    80000a66:	d67ff0ef          	jal	ra,800007cc <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000a6a:	00c4d793          	srli	a5,s1,0xc
    80000a6e:	07aa                	slli	a5,a5,0xa
    80000a70:	0017e793          	ori	a5,a5,1
    80000a74:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000a78:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fff3497>
    80000a7a:	036a0063          	beq	s4,s6,80000a9a <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000a7e:	0149d933          	srl	s2,s3,s4
    80000a82:	1ff97913          	andi	s2,s2,511
    80000a86:	090e                	slli	s2,s2,0x3
    80000a88:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000a8a:	00093483          	ld	s1,0(s2)
    80000a8e:	0014f793          	andi	a5,s1,1
    80000a92:	d3f1                	beqz	a5,80000a56 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000a94:	80a9                	srli	s1,s1,0xa
    80000a96:	04b2                	slli	s1,s1,0xc
    80000a98:	b7c5                	j	80000a78 <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000a9a:	00c9d513          	srli	a0,s3,0xc
    80000a9e:	1ff57513          	andi	a0,a0,511
    80000aa2:	050e                	slli	a0,a0,0x3
    80000aa4:	9526                	add	a0,a0,s1
}
    80000aa6:	70e2                	ld	ra,56(sp)
    80000aa8:	7442                	ld	s0,48(sp)
    80000aaa:	74a2                	ld	s1,40(sp)
    80000aac:	7902                	ld	s2,32(sp)
    80000aae:	69e2                	ld	s3,24(sp)
    80000ab0:	6a42                	ld	s4,16(sp)
    80000ab2:	6aa2                	ld	s5,8(sp)
    80000ab4:	6b02                	ld	s6,0(sp)
    80000ab6:	6121                	addi	sp,sp,64
    80000ab8:	8082                	ret
        return 0;
    80000aba:	4501                	li	a0,0
    80000abc:	b7ed                	j	80000aa6 <walk+0x82>

0000000080000abe <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000abe:	57fd                	li	a5,-1
    80000ac0:	83e9                	srli	a5,a5,0x1a
    80000ac2:	00b7f463          	bgeu	a5,a1,80000aca <walkaddr+0xc>
    return 0;
    80000ac6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000ac8:	8082                	ret
{
    80000aca:	1141                	addi	sp,sp,-16
    80000acc:	e406                	sd	ra,8(sp)
    80000ace:	e022                	sd	s0,0(sp)
    80000ad0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000ad2:	4601                	li	a2,0
    80000ad4:	f51ff0ef          	jal	ra,80000a24 <walk>
  if(pte == 0)
    80000ad8:	c105                	beqz	a0,80000af8 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000ada:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000adc:	0117f693          	andi	a3,a5,17
    80000ae0:	4745                	li	a4,17
    return 0;
    80000ae2:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000ae4:	00e68663          	beq	a3,a4,80000af0 <walkaddr+0x32>
}
    80000ae8:	60a2                	ld	ra,8(sp)
    80000aea:	6402                	ld	s0,0(sp)
    80000aec:	0141                	addi	sp,sp,16
    80000aee:	8082                	ret
  pa = PTE2PA(*pte);
    80000af0:	83a9                	srli	a5,a5,0xa
    80000af2:	00c79513          	slli	a0,a5,0xc
  return pa;
    80000af6:	bfcd                	j	80000ae8 <walkaddr+0x2a>
    return 0;
    80000af8:	4501                	li	a0,0
    80000afa:	b7fd                	j	80000ae8 <walkaddr+0x2a>

0000000080000afc <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80000afc:	715d                	addi	sp,sp,-80
    80000afe:	e486                	sd	ra,72(sp)
    80000b00:	e0a2                	sd	s0,64(sp)
    80000b02:	fc26                	sd	s1,56(sp)
    80000b04:	f84a                	sd	s2,48(sp)
    80000b06:	f44e                	sd	s3,40(sp)
    80000b08:	f052                	sd	s4,32(sp)
    80000b0a:	ec56                	sd	s5,24(sp)
    80000b0c:	e85a                	sd	s6,16(sp)
    80000b0e:	e45e                	sd	s7,8(sp)
    80000b10:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80000b12:	c629                	beqz	a2,80000b5c <mappages+0x60>
    80000b14:	8aaa                	mv	s5,a0
    80000b16:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80000b18:	777d                	lui	a4,0xfffff
    80000b1a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80000b1e:	fff58993          	addi	s3,a1,-1
    80000b22:	99b2                	add	s3,s3,a2
    80000b24:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80000b28:	893e                	mv	s2,a5
    80000b2a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80000b2e:	6b85                	lui	s7,0x1
    80000b30:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80000b34:	4605                	li	a2,1
    80000b36:	85ca                	mv	a1,s2
    80000b38:	8556                	mv	a0,s5
    80000b3a:	eebff0ef          	jal	ra,80000a24 <walk>
    80000b3e:	c91d                	beqz	a0,80000b74 <mappages+0x78>
    if(*pte & PTE_V)
    80000b40:	611c                	ld	a5,0(a0)
    80000b42:	8b85                	andi	a5,a5,1
    80000b44:	e395                	bnez	a5,80000b68 <mappages+0x6c>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80000b46:	80b1                	srli	s1,s1,0xc
    80000b48:	04aa                	slli	s1,s1,0xa
    80000b4a:	0164e4b3          	or	s1,s1,s6
    80000b4e:	0014e493          	ori	s1,s1,1
    80000b52:	e104                	sd	s1,0(a0)
    if(a == last)
    80000b54:	03390c63          	beq	s2,s3,80000b8c <mappages+0x90>
    a += PGSIZE;
    80000b58:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80000b5a:	bfd9                	j	80000b30 <mappages+0x34>
    panic("mappages: size");
    80000b5c:	00002517          	auipc	a0,0x2
    80000b60:	57450513          	addi	a0,a0,1396 # 800030d0 <digits+0xa8>
    80000b64:	e38ff0ef          	jal	ra,8000019c <panic>
      panic("mappages: remap");
    80000b68:	00002517          	auipc	a0,0x2
    80000b6c:	57850513          	addi	a0,a0,1400 # 800030e0 <digits+0xb8>
    80000b70:	e2cff0ef          	jal	ra,8000019c <panic>
      return -1;
    80000b74:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80000b76:	60a6                	ld	ra,72(sp)
    80000b78:	6406                	ld	s0,64(sp)
    80000b7a:	74e2                	ld	s1,56(sp)
    80000b7c:	7942                	ld	s2,48(sp)
    80000b7e:	79a2                	ld	s3,40(sp)
    80000b80:	7a02                	ld	s4,32(sp)
    80000b82:	6ae2                	ld	s5,24(sp)
    80000b84:	6b42                	ld	s6,16(sp)
    80000b86:	6ba2                	ld	s7,8(sp)
    80000b88:	6161                	addi	sp,sp,80
    80000b8a:	8082                	ret
  return 0;
    80000b8c:	4501                	li	a0,0
    80000b8e:	b7e5                	j	80000b76 <mappages+0x7a>

0000000080000b90 <kvmmap>:
{
    80000b90:	1141                	addi	sp,sp,-16
    80000b92:	e406                	sd	ra,8(sp)
    80000b94:	e022                	sd	s0,0(sp)
    80000b96:	0800                	addi	s0,sp,16
    80000b98:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80000b9a:	86b2                	mv	a3,a2
    80000b9c:	863e                	mv	a2,a5
    80000b9e:	f5fff0ef          	jal	ra,80000afc <mappages>
    80000ba2:	e509                	bnez	a0,80000bac <kvmmap+0x1c>
}
    80000ba4:	60a2                	ld	ra,8(sp)
    80000ba6:	6402                	ld	s0,0(sp)
    80000ba8:	0141                	addi	sp,sp,16
    80000baa:	8082                	ret
    panic("kvmmap");
    80000bac:	00002517          	auipc	a0,0x2
    80000bb0:	54450513          	addi	a0,a0,1348 # 800030f0 <digits+0xc8>
    80000bb4:	de8ff0ef          	jal	ra,8000019c <panic>

0000000080000bb8 <kvmmake>:
{
    80000bb8:	1101                	addi	sp,sp,-32
    80000bba:	ec06                	sd	ra,24(sp)
    80000bbc:	e822                	sd	s0,16(sp)
    80000bbe:	e426                	sd	s1,8(sp)
    80000bc0:	e04a                	sd	s2,0(sp)
    80000bc2:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80000bc4:	a65ff0ef          	jal	ra,80000628 <kalloc>
    80000bc8:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80000bca:	6605                	lui	a2,0x1
    80000bcc:	4581                	li	a1,0
    80000bce:	bffff0ef          	jal	ra,800007cc <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80000bd2:	4719                	li	a4,6
    80000bd4:	6685                	lui	a3,0x1
    80000bd6:	10000637          	lui	a2,0x10000
    80000bda:	100005b7          	lui	a1,0x10000
    80000bde:	8526                	mv	a0,s1
    80000be0:	fb1ff0ef          	jal	ra,80000b90 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80000be4:	4719                	li	a4,6
    80000be6:	6685                	lui	a3,0x1
    80000be8:	10001637          	lui	a2,0x10001
    80000bec:	100015b7          	lui	a1,0x10001
    80000bf0:	8526                	mv	a0,s1
    80000bf2:	f9fff0ef          	jal	ra,80000b90 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80000bf6:	4719                	li	a4,6
    80000bf8:	004006b7          	lui	a3,0x400
    80000bfc:	0c000637          	lui	a2,0xc000
    80000c00:	0c0005b7          	lui	a1,0xc000
    80000c04:	8526                	mv	a0,s1
    80000c06:	f8bff0ef          	jal	ra,80000b90 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80000c0a:	00002917          	auipc	s2,0x2
    80000c0e:	3f690913          	addi	s2,s2,1014 # 80003000 <etext>
    80000c12:	4729                	li	a4,10
    80000c14:	80002697          	auipc	a3,0x80002
    80000c18:	3ec68693          	addi	a3,a3,1004 # 3000 <_entry-0x7fffd000>
    80000c1c:	4605                	li	a2,1
    80000c1e:	067e                	slli	a2,a2,0x1f
    80000c20:	85b2                	mv	a1,a2
    80000c22:	8526                	mv	a0,s1
    80000c24:	f6dff0ef          	jal	ra,80000b90 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80000c28:	4719                	li	a4,6
    80000c2a:	46c5                	li	a3,17
    80000c2c:	06ee                	slli	a3,a3,0x1b
    80000c2e:	412686b3          	sub	a3,a3,s2
    80000c32:	864a                	mv	a2,s2
    80000c34:	85ca                	mv	a1,s2
    80000c36:	8526                	mv	a0,s1
    80000c38:	f59ff0ef          	jal	ra,80000b90 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80000c3c:	4729                	li	a4,10
    80000c3e:	6685                	lui	a3,0x1
    80000c40:	00001617          	auipc	a2,0x1
    80000c44:	3c060613          	addi	a2,a2,960 # 80002000 <_trampoline>
    80000c48:	040005b7          	lui	a1,0x4000
    80000c4c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80000c4e:	05b2                	slli	a1,a1,0xc
    80000c50:	8526                	mv	a0,s1
    80000c52:	f3fff0ef          	jal	ra,80000b90 <kvmmap>
  proc_mapstacks(kpgtbl);
    80000c56:	8526                	mv	a0,s1
    80000c58:	482000ef          	jal	ra,800010da <proc_mapstacks>
}
    80000c5c:	8526                	mv	a0,s1
    80000c5e:	60e2                	ld	ra,24(sp)
    80000c60:	6442                	ld	s0,16(sp)
    80000c62:	64a2                	ld	s1,8(sp)
    80000c64:	6902                	ld	s2,0(sp)
    80000c66:	6105                	addi	sp,sp,32
    80000c68:	8082                	ret

0000000080000c6a <kvminit>:
{
    80000c6a:	1141                	addi	sp,sp,-16
    80000c6c:	e406                	sd	ra,8(sp)
    80000c6e:	e022                	sd	s0,0(sp)
    80000c70:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80000c72:	f47ff0ef          	jal	ra,80000bb8 <kvmmake>
    80000c76:	00003797          	auipc	a5,0x3
    80000c7a:	80a7b523          	sd	a0,-2038(a5) # 80003480 <kernel_pagetable>
}
    80000c7e:	60a2                	ld	ra,8(sp)
    80000c80:	6402                	ld	s0,0(sp)
    80000c82:	0141                	addi	sp,sp,16
    80000c84:	8082                	ret

0000000080000c86 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80000c86:	715d                	addi	sp,sp,-80
    80000c88:	e486                	sd	ra,72(sp)
    80000c8a:	e0a2                	sd	s0,64(sp)
    80000c8c:	fc26                	sd	s1,56(sp)
    80000c8e:	f84a                	sd	s2,48(sp)
    80000c90:	f44e                	sd	s3,40(sp)
    80000c92:	f052                	sd	s4,32(sp)
    80000c94:	ec56                	sd	s5,24(sp)
    80000c96:	e85a                	sd	s6,16(sp)
    80000c98:	e45e                	sd	s7,8(sp)
    80000c9a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80000c9c:	03459793          	slli	a5,a1,0x34
    80000ca0:	e795                	bnez	a5,80000ccc <uvmunmap+0x46>
    80000ca2:	8a2a                	mv	s4,a0
    80000ca4:	892e                	mv	s2,a1
    80000ca6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80000ca8:	0632                	slli	a2,a2,0xc
    80000caa:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80000cae:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80000cb0:	6b05                	lui	s6,0x1
    80000cb2:	0535ea63          	bltu	a1,s3,80000d06 <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80000cb6:	60a6                	ld	ra,72(sp)
    80000cb8:	6406                	ld	s0,64(sp)
    80000cba:	74e2                	ld	s1,56(sp)
    80000cbc:	7942                	ld	s2,48(sp)
    80000cbe:	79a2                	ld	s3,40(sp)
    80000cc0:	7a02                	ld	s4,32(sp)
    80000cc2:	6ae2                	ld	s5,24(sp)
    80000cc4:	6b42                	ld	s6,16(sp)
    80000cc6:	6ba2                	ld	s7,8(sp)
    80000cc8:	6161                	addi	sp,sp,80
    80000cca:	8082                	ret
    panic("uvmunmap: not aligned");
    80000ccc:	00002517          	auipc	a0,0x2
    80000cd0:	42c50513          	addi	a0,a0,1068 # 800030f8 <digits+0xd0>
    80000cd4:	cc8ff0ef          	jal	ra,8000019c <panic>
      panic("uvmunmap: walk");
    80000cd8:	00002517          	auipc	a0,0x2
    80000cdc:	43850513          	addi	a0,a0,1080 # 80003110 <digits+0xe8>
    80000ce0:	cbcff0ef          	jal	ra,8000019c <panic>
      panic("uvmunmap: not mapped");
    80000ce4:	00002517          	auipc	a0,0x2
    80000ce8:	43c50513          	addi	a0,a0,1084 # 80003120 <digits+0xf8>
    80000cec:	cb0ff0ef          	jal	ra,8000019c <panic>
      panic("uvmunmap: not a leaf");
    80000cf0:	00002517          	auipc	a0,0x2
    80000cf4:	44850513          	addi	a0,a0,1096 # 80003138 <digits+0x110>
    80000cf8:	ca4ff0ef          	jal	ra,8000019c <panic>
    *pte = 0;
    80000cfc:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80000d00:	995a                	add	s2,s2,s6
    80000d02:	fb397ae3          	bgeu	s2,s3,80000cb6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80000d06:	4601                	li	a2,0
    80000d08:	85ca                	mv	a1,s2
    80000d0a:	8552                	mv	a0,s4
    80000d0c:	d19ff0ef          	jal	ra,80000a24 <walk>
    80000d10:	84aa                	mv	s1,a0
    80000d12:	d179                	beqz	a0,80000cd8 <uvmunmap+0x52>
    if((*pte & PTE_V) == 0)
    80000d14:	6108                	ld	a0,0(a0)
    80000d16:	00157793          	andi	a5,a0,1
    80000d1a:	d7e9                	beqz	a5,80000ce4 <uvmunmap+0x5e>
    if(PTE_FLAGS(*pte) == PTE_V)
    80000d1c:	3ff57793          	andi	a5,a0,1023
    80000d20:	fd7788e3          	beq	a5,s7,80000cf0 <uvmunmap+0x6a>
    if(do_free){
    80000d24:	fc0a8ce3          	beqz	s5,80000cfc <uvmunmap+0x76>
      uint64 pa = PTE2PA(*pte);
    80000d28:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80000d2a:	0532                	slli	a0,a0,0xc
    80000d2c:	81bff0ef          	jal	ra,80000546 <kfree>
    80000d30:	b7f1                	j	80000cfc <uvmunmap+0x76>

0000000080000d32 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80000d32:	1101                	addi	sp,sp,-32
    80000d34:	ec06                	sd	ra,24(sp)
    80000d36:	e822                	sd	s0,16(sp)
    80000d38:	e426                	sd	s1,8(sp)
    80000d3a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80000d3c:	8edff0ef          	jal	ra,80000628 <kalloc>
    80000d40:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80000d42:	c509                	beqz	a0,80000d4c <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80000d44:	6605                	lui	a2,0x1
    80000d46:	4581                	li	a1,0
    80000d48:	a85ff0ef          	jal	ra,800007cc <memset>
  return pagetable;
}
    80000d4c:	8526                	mv	a0,s1
    80000d4e:	60e2                	ld	ra,24(sp)
    80000d50:	6442                	ld	s0,16(sp)
    80000d52:	64a2                	ld	s1,8(sp)
    80000d54:	6105                	addi	sp,sp,32
    80000d56:	8082                	ret

0000000080000d58 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80000d58:	7179                	addi	sp,sp,-48
    80000d5a:	f406                	sd	ra,40(sp)
    80000d5c:	f022                	sd	s0,32(sp)
    80000d5e:	ec26                	sd	s1,24(sp)
    80000d60:	e84a                	sd	s2,16(sp)
    80000d62:	e44e                	sd	s3,8(sp)
    80000d64:	e052                	sd	s4,0(sp)
    80000d66:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80000d68:	6785                	lui	a5,0x1
    80000d6a:	04f67063          	bgeu	a2,a5,80000daa <uvmfirst+0x52>
    80000d6e:	8a2a                	mv	s4,a0
    80000d70:	89ae                	mv	s3,a1
    80000d72:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80000d74:	8b5ff0ef          	jal	ra,80000628 <kalloc>
    80000d78:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80000d7a:	6605                	lui	a2,0x1
    80000d7c:	4581                	li	a1,0
    80000d7e:	a4fff0ef          	jal	ra,800007cc <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80000d82:	4779                	li	a4,30
    80000d84:	86ca                	mv	a3,s2
    80000d86:	6605                	lui	a2,0x1
    80000d88:	4581                	li	a1,0
    80000d8a:	8552                	mv	a0,s4
    80000d8c:	d71ff0ef          	jal	ra,80000afc <mappages>
  memmove(mem, src, sz);
    80000d90:	8626                	mv	a2,s1
    80000d92:	85ce                	mv	a1,s3
    80000d94:	854a                	mv	a0,s2
    80000d96:	a93ff0ef          	jal	ra,80000828 <memmove>
}
    80000d9a:	70a2                	ld	ra,40(sp)
    80000d9c:	7402                	ld	s0,32(sp)
    80000d9e:	64e2                	ld	s1,24(sp)
    80000da0:	6942                	ld	s2,16(sp)
    80000da2:	69a2                	ld	s3,8(sp)
    80000da4:	6a02                	ld	s4,0(sp)
    80000da6:	6145                	addi	sp,sp,48
    80000da8:	8082                	ret
    panic("uvmfirst: more than a page");
    80000daa:	00002517          	auipc	a0,0x2
    80000dae:	3a650513          	addi	a0,a0,934 # 80003150 <digits+0x128>
    80000db2:	beaff0ef          	jal	ra,8000019c <panic>

0000000080000db6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80000db6:	7179                	addi	sp,sp,-48
    80000db8:	f406                	sd	ra,40(sp)
    80000dba:	f022                	sd	s0,32(sp)
    80000dbc:	ec26                	sd	s1,24(sp)
    80000dbe:	e84a                	sd	s2,16(sp)
    80000dc0:	e44e                	sd	s3,8(sp)
    80000dc2:	e052                	sd	s4,0(sp)
    80000dc4:	1800                	addi	s0,sp,48
    80000dc6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80000dc8:	84aa                	mv	s1,a0
    80000dca:	6905                	lui	s2,0x1
    80000dcc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000dce:	4985                	li	s3,1
    80000dd0:	a819                	j	80000de6 <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80000dd2:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80000dd4:	00c79513          	slli	a0,a5,0xc
    80000dd8:	fdfff0ef          	jal	ra,80000db6 <freewalk>
      pagetable[i] = 0;
    80000ddc:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80000de0:	04a1                	addi	s1,s1,8
    80000de2:	01248f63          	beq	s1,s2,80000e00 <freewalk+0x4a>
    pte_t pte = pagetable[i];
    80000de6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80000de8:	00f7f713          	andi	a4,a5,15
    80000dec:	ff3703e3          	beq	a4,s3,80000dd2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80000df0:	8b85                	andi	a5,a5,1
    80000df2:	d7fd                	beqz	a5,80000de0 <freewalk+0x2a>
      panic("freewalk: leaf");
    80000df4:	00002517          	auipc	a0,0x2
    80000df8:	37c50513          	addi	a0,a0,892 # 80003170 <digits+0x148>
    80000dfc:	ba0ff0ef          	jal	ra,8000019c <panic>
    }
  }
  kfree((void*)pagetable);
    80000e00:	8552                	mv	a0,s4
    80000e02:	f44ff0ef          	jal	ra,80000546 <kfree>
}
    80000e06:	70a2                	ld	ra,40(sp)
    80000e08:	7402                	ld	s0,32(sp)
    80000e0a:	64e2                	ld	s1,24(sp)
    80000e0c:	6942                	ld	s2,16(sp)
    80000e0e:	69a2                	ld	s3,8(sp)
    80000e10:	6a02                	ld	s4,0(sp)
    80000e12:	6145                	addi	sp,sp,48
    80000e14:	8082                	ret

0000000080000e16 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80000e16:	1101                	addi	sp,sp,-32
    80000e18:	ec06                	sd	ra,24(sp)
    80000e1a:	e822                	sd	s0,16(sp)
    80000e1c:	e426                	sd	s1,8(sp)
    80000e1e:	1000                	addi	s0,sp,32
    80000e20:	84aa                	mv	s1,a0
  if(sz > 0)
    80000e22:	e989                	bnez	a1,80000e34 <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80000e24:	8526                	mv	a0,s1
    80000e26:	f91ff0ef          	jal	ra,80000db6 <freewalk>
}
    80000e2a:	60e2                	ld	ra,24(sp)
    80000e2c:	6442                	ld	s0,16(sp)
    80000e2e:	64a2                	ld	s1,8(sp)
    80000e30:	6105                	addi	sp,sp,32
    80000e32:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80000e34:	6785                	lui	a5,0x1
    80000e36:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80000e38:	95be                	add	a1,a1,a5
    80000e3a:	4685                	li	a3,1
    80000e3c:	00c5d613          	srli	a2,a1,0xc
    80000e40:	4581                	li	a1,0
    80000e42:	e45ff0ef          	jal	ra,80000c86 <uvmunmap>
    80000e46:	bff9                	j	80000e24 <uvmfree+0xe>

0000000080000e48 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80000e48:	c65d                	beqz	a2,80000ef6 <uvmcopy+0xae>
{
    80000e4a:	715d                	addi	sp,sp,-80
    80000e4c:	e486                	sd	ra,72(sp)
    80000e4e:	e0a2                	sd	s0,64(sp)
    80000e50:	fc26                	sd	s1,56(sp)
    80000e52:	f84a                	sd	s2,48(sp)
    80000e54:	f44e                	sd	s3,40(sp)
    80000e56:	f052                	sd	s4,32(sp)
    80000e58:	ec56                	sd	s5,24(sp)
    80000e5a:	e85a                	sd	s6,16(sp)
    80000e5c:	e45e                	sd	s7,8(sp)
    80000e5e:	0880                	addi	s0,sp,80
    80000e60:	8b2a                	mv	s6,a0
    80000e62:	8aae                	mv	s5,a1
    80000e64:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80000e66:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80000e68:	4601                	li	a2,0
    80000e6a:	85ce                	mv	a1,s3
    80000e6c:	855a                	mv	a0,s6
    80000e6e:	bb7ff0ef          	jal	ra,80000a24 <walk>
    80000e72:	c121                	beqz	a0,80000eb2 <uvmcopy+0x6a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80000e74:	6118                	ld	a4,0(a0)
    80000e76:	00177793          	andi	a5,a4,1
    80000e7a:	c3b1                	beqz	a5,80000ebe <uvmcopy+0x76>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80000e7c:	00a75593          	srli	a1,a4,0xa
    80000e80:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80000e84:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80000e88:	fa0ff0ef          	jal	ra,80000628 <kalloc>
    80000e8c:	892a                	mv	s2,a0
    80000e8e:	c129                	beqz	a0,80000ed0 <uvmcopy+0x88>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80000e90:	6605                	lui	a2,0x1
    80000e92:	85de                	mv	a1,s7
    80000e94:	995ff0ef          	jal	ra,80000828 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80000e98:	8726                	mv	a4,s1
    80000e9a:	86ca                	mv	a3,s2
    80000e9c:	6605                	lui	a2,0x1
    80000e9e:	85ce                	mv	a1,s3
    80000ea0:	8556                	mv	a0,s5
    80000ea2:	c5bff0ef          	jal	ra,80000afc <mappages>
    80000ea6:	e115                	bnez	a0,80000eca <uvmcopy+0x82>
  for(i = 0; i < sz; i += PGSIZE){
    80000ea8:	6785                	lui	a5,0x1
    80000eaa:	99be                	add	s3,s3,a5
    80000eac:	fb49eee3          	bltu	s3,s4,80000e68 <uvmcopy+0x20>
    80000eb0:	a805                	j	80000ee0 <uvmcopy+0x98>
      panic("uvmcopy: pte should exist");
    80000eb2:	00002517          	auipc	a0,0x2
    80000eb6:	2ce50513          	addi	a0,a0,718 # 80003180 <digits+0x158>
    80000eba:	ae2ff0ef          	jal	ra,8000019c <panic>
      panic("uvmcopy: page not present");
    80000ebe:	00002517          	auipc	a0,0x2
    80000ec2:	2e250513          	addi	a0,a0,738 # 800031a0 <digits+0x178>
    80000ec6:	ad6ff0ef          	jal	ra,8000019c <panic>
      kfree(mem);
    80000eca:	854a                	mv	a0,s2
    80000ecc:	e7aff0ef          	jal	ra,80000546 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80000ed0:	4685                	li	a3,1
    80000ed2:	00c9d613          	srli	a2,s3,0xc
    80000ed6:	4581                	li	a1,0
    80000ed8:	8556                	mv	a0,s5
    80000eda:	dadff0ef          	jal	ra,80000c86 <uvmunmap>
  return -1;
    80000ede:	557d                	li	a0,-1
}
    80000ee0:	60a6                	ld	ra,72(sp)
    80000ee2:	6406                	ld	s0,64(sp)
    80000ee4:	74e2                	ld	s1,56(sp)
    80000ee6:	7942                	ld	s2,48(sp)
    80000ee8:	79a2                	ld	s3,40(sp)
    80000eea:	7a02                	ld	s4,32(sp)
    80000eec:	6ae2                	ld	s5,24(sp)
    80000eee:	6b42                	ld	s6,16(sp)
    80000ef0:	6ba2                	ld	s7,8(sp)
    80000ef2:	6161                	addi	sp,sp,80
    80000ef4:	8082                	ret
  return 0;
    80000ef6:	4501                	li	a0,0
}
    80000ef8:	8082                	ret

0000000080000efa <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80000efa:	1141                	addi	sp,sp,-16
    80000efc:	e406                	sd	ra,8(sp)
    80000efe:	e022                	sd	s0,0(sp)
    80000f00:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80000f02:	4601                	li	a2,0
    80000f04:	b21ff0ef          	jal	ra,80000a24 <walk>
  if(pte == 0)
    80000f08:	c901                	beqz	a0,80000f18 <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80000f0a:	611c                	ld	a5,0(a0)
    80000f0c:	9bbd                	andi	a5,a5,-17
    80000f0e:	e11c                	sd	a5,0(a0)
}
    80000f10:	60a2                	ld	ra,8(sp)
    80000f12:	6402                	ld	s0,0(sp)
    80000f14:	0141                	addi	sp,sp,16
    80000f16:	8082                	ret
    panic("uvmclear");
    80000f18:	00002517          	auipc	a0,0x2
    80000f1c:	2a850513          	addi	a0,a0,680 # 800031c0 <digits+0x198>
    80000f20:	a7cff0ef          	jal	ra,8000019c <panic>

0000000080000f24 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80000f24:	c2bd                	beqz	a3,80000f8a <copyout+0x66>
{
    80000f26:	715d                	addi	sp,sp,-80
    80000f28:	e486                	sd	ra,72(sp)
    80000f2a:	e0a2                	sd	s0,64(sp)
    80000f2c:	fc26                	sd	s1,56(sp)
    80000f2e:	f84a                	sd	s2,48(sp)
    80000f30:	f44e                	sd	s3,40(sp)
    80000f32:	f052                	sd	s4,32(sp)
    80000f34:	ec56                	sd	s5,24(sp)
    80000f36:	e85a                	sd	s6,16(sp)
    80000f38:	e45e                	sd	s7,8(sp)
    80000f3a:	e062                	sd	s8,0(sp)
    80000f3c:	0880                	addi	s0,sp,80
    80000f3e:	8b2a                	mv	s6,a0
    80000f40:	8c2e                	mv	s8,a1
    80000f42:	8a32                	mv	s4,a2
    80000f44:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80000f46:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80000f48:	6a85                	lui	s5,0x1
    80000f4a:	a005                	j	80000f6a <copyout+0x46>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80000f4c:	9562                	add	a0,a0,s8
    80000f4e:	0004861b          	sext.w	a2,s1
    80000f52:	85d2                	mv	a1,s4
    80000f54:	41250533          	sub	a0,a0,s2
    80000f58:	8d1ff0ef          	jal	ra,80000828 <memmove>

    len -= n;
    80000f5c:	409989b3          	sub	s3,s3,s1
    src += n;
    80000f60:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80000f62:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80000f66:	02098063          	beqz	s3,80000f86 <copyout+0x62>
    va0 = PGROUNDDOWN(dstva);
    80000f6a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80000f6e:	85ca                	mv	a1,s2
    80000f70:	855a                	mv	a0,s6
    80000f72:	b4dff0ef          	jal	ra,80000abe <walkaddr>
    if(pa0 == 0)
    80000f76:	cd01                	beqz	a0,80000f8e <copyout+0x6a>
    n = PGSIZE - (dstva - va0);
    80000f78:	418904b3          	sub	s1,s2,s8
    80000f7c:	94d6                	add	s1,s1,s5
    80000f7e:	fc99f7e3          	bgeu	s3,s1,80000f4c <copyout+0x28>
    80000f82:	84ce                	mv	s1,s3
    80000f84:	b7e1                	j	80000f4c <copyout+0x28>
  }
  return 0;
    80000f86:	4501                	li	a0,0
    80000f88:	a021                	j	80000f90 <copyout+0x6c>
    80000f8a:	4501                	li	a0,0
}
    80000f8c:	8082                	ret
      return -1;
    80000f8e:	557d                	li	a0,-1
}
    80000f90:	60a6                	ld	ra,72(sp)
    80000f92:	6406                	ld	s0,64(sp)
    80000f94:	74e2                	ld	s1,56(sp)
    80000f96:	7942                	ld	s2,48(sp)
    80000f98:	79a2                	ld	s3,40(sp)
    80000f9a:	7a02                	ld	s4,32(sp)
    80000f9c:	6ae2                	ld	s5,24(sp)
    80000f9e:	6b42                	ld	s6,16(sp)
    80000fa0:	6ba2                	ld	s7,8(sp)
    80000fa2:	6c02                	ld	s8,0(sp)
    80000fa4:	6161                	addi	sp,sp,80
    80000fa6:	8082                	ret

0000000080000fa8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80000fa8:	c6a5                	beqz	a3,80001010 <copyin+0x68>
{
    80000faa:	715d                	addi	sp,sp,-80
    80000fac:	e486                	sd	ra,72(sp)
    80000fae:	e0a2                	sd	s0,64(sp)
    80000fb0:	fc26                	sd	s1,56(sp)
    80000fb2:	f84a                	sd	s2,48(sp)
    80000fb4:	f44e                	sd	s3,40(sp)
    80000fb6:	f052                	sd	s4,32(sp)
    80000fb8:	ec56                	sd	s5,24(sp)
    80000fba:	e85a                	sd	s6,16(sp)
    80000fbc:	e45e                	sd	s7,8(sp)
    80000fbe:	e062                	sd	s8,0(sp)
    80000fc0:	0880                	addi	s0,sp,80
    80000fc2:	8b2a                	mv	s6,a0
    80000fc4:	8a2e                	mv	s4,a1
    80000fc6:	8c32                	mv	s8,a2
    80000fc8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80000fca:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80000fcc:	6a85                	lui	s5,0x1
    80000fce:	a00d                	j	80000ff0 <copyin+0x48>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80000fd0:	018505b3          	add	a1,a0,s8
    80000fd4:	0004861b          	sext.w	a2,s1
    80000fd8:	412585b3          	sub	a1,a1,s2
    80000fdc:	8552                	mv	a0,s4
    80000fde:	84bff0ef          	jal	ra,80000828 <memmove>

    len -= n;
    80000fe2:	409989b3          	sub	s3,s3,s1
    dst += n;
    80000fe6:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80000fe8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80000fec:	02098063          	beqz	s3,8000100c <copyin+0x64>
    va0 = PGROUNDDOWN(srcva);
    80000ff0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80000ff4:	85ca                	mv	a1,s2
    80000ff6:	855a                	mv	a0,s6
    80000ff8:	ac7ff0ef          	jal	ra,80000abe <walkaddr>
    if(pa0 == 0)
    80000ffc:	cd01                	beqz	a0,80001014 <copyin+0x6c>
    n = PGSIZE - (srcva - va0);
    80000ffe:	418904b3          	sub	s1,s2,s8
    80001002:	94d6                	add	s1,s1,s5
    80001004:	fc99f6e3          	bgeu	s3,s1,80000fd0 <copyin+0x28>
    80001008:	84ce                	mv	s1,s3
    8000100a:	b7d9                	j	80000fd0 <copyin+0x28>
  }
  return 0;
    8000100c:	4501                	li	a0,0
    8000100e:	a021                	j	80001016 <copyin+0x6e>
    80001010:	4501                	li	a0,0
}
    80001012:	8082                	ret
      return -1;
    80001014:	557d                	li	a0,-1
}
    80001016:	60a6                	ld	ra,72(sp)
    80001018:	6406                	ld	s0,64(sp)
    8000101a:	74e2                	ld	s1,56(sp)
    8000101c:	7942                	ld	s2,48(sp)
    8000101e:	79a2                	ld	s3,40(sp)
    80001020:	7a02                	ld	s4,32(sp)
    80001022:	6ae2                	ld	s5,24(sp)
    80001024:	6b42                	ld	s6,16(sp)
    80001026:	6ba2                	ld	s7,8(sp)
    80001028:	6c02                	ld	s8,0(sp)
    8000102a:	6161                	addi	sp,sp,80
    8000102c:	8082                	ret

000000008000102e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000102e:	c2cd                	beqz	a3,800010d0 <copyinstr+0xa2>
{
    80001030:	715d                	addi	sp,sp,-80
    80001032:	e486                	sd	ra,72(sp)
    80001034:	e0a2                	sd	s0,64(sp)
    80001036:	fc26                	sd	s1,56(sp)
    80001038:	f84a                	sd	s2,48(sp)
    8000103a:	f44e                	sd	s3,40(sp)
    8000103c:	f052                	sd	s4,32(sp)
    8000103e:	ec56                	sd	s5,24(sp)
    80001040:	e85a                	sd	s6,16(sp)
    80001042:	e45e                	sd	s7,8(sp)
    80001044:	0880                	addi	s0,sp,80
    80001046:	8a2a                	mv	s4,a0
    80001048:	8b2e                	mv	s6,a1
    8000104a:	8bb2                	mv	s7,a2
    8000104c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000104e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001050:	6985                	lui	s3,0x1
    80001052:	a02d                	j	8000107c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001054:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001058:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000105a:	37fd                	addiw	a5,a5,-1
    8000105c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001060:	60a6                	ld	ra,72(sp)
    80001062:	6406                	ld	s0,64(sp)
    80001064:	74e2                	ld	s1,56(sp)
    80001066:	7942                	ld	s2,48(sp)
    80001068:	79a2                	ld	s3,40(sp)
    8000106a:	7a02                	ld	s4,32(sp)
    8000106c:	6ae2                	ld	s5,24(sp)
    8000106e:	6b42                	ld	s6,16(sp)
    80001070:	6ba2                	ld	s7,8(sp)
    80001072:	6161                	addi	sp,sp,80
    80001074:	8082                	ret
    srcva = va0 + PGSIZE;
    80001076:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000107a:	c4b9                	beqz	s1,800010c8 <copyinstr+0x9a>
    va0 = PGROUNDDOWN(srcva);
    8000107c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001080:	85ca                	mv	a1,s2
    80001082:	8552                	mv	a0,s4
    80001084:	a3bff0ef          	jal	ra,80000abe <walkaddr>
    if(pa0 == 0)
    80001088:	c131                	beqz	a0,800010cc <copyinstr+0x9e>
    n = PGSIZE - (srcva - va0);
    8000108a:	417906b3          	sub	a3,s2,s7
    8000108e:	96ce                	add	a3,a3,s3
    80001090:	00d4f363          	bgeu	s1,a3,80001096 <copyinstr+0x68>
    80001094:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001096:	955e                	add	a0,a0,s7
    80001098:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000109c:	dee9                	beqz	a3,80001076 <copyinstr+0x48>
    8000109e:	87da                	mv	a5,s6
      if(*p == '\0'){
    800010a0:	41650633          	sub	a2,a0,s6
    800010a4:	fff48593          	addi	a1,s1,-1
    800010a8:	95da                	add	a1,a1,s6
    while(n > 0){
    800010aa:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    800010ac:	00f60733          	add	a4,a2,a5
    800010b0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fff34a0>
    800010b4:	d345                	beqz	a4,80001054 <copyinstr+0x26>
        *dst = *p;
    800010b6:	00e78023          	sb	a4,0(a5)
      --max;
    800010ba:	40f584b3          	sub	s1,a1,a5
      dst++;
    800010be:	0785                	addi	a5,a5,1
    while(n > 0){
    800010c0:	fed796e3          	bne	a5,a3,800010ac <copyinstr+0x7e>
      dst++;
    800010c4:	8b3e                	mv	s6,a5
    800010c6:	bf45                	j	80001076 <copyinstr+0x48>
    800010c8:	4781                	li	a5,0
    800010ca:	bf41                	j	8000105a <copyinstr+0x2c>
      return -1;
    800010cc:	557d                	li	a0,-1
    800010ce:	bf49                	j	80001060 <copyinstr+0x32>
  int got_null = 0;
    800010d0:	4781                	li	a5,0
  if(got_null){
    800010d2:	37fd                	addiw	a5,a5,-1
    800010d4:	0007851b          	sext.w	a0,a5
}
    800010d8:	8082                	ret

00000000800010da <proc_mapstacks>:
// Map it high in memory, followed by an invalid
// guard page.

void
proc_mapstacks(pagetable_t kpgtbl)
{
    800010da:	1101                	addi	sp,sp,-32
    800010dc:	ec06                	sd	ra,24(sp)
    800010de:	e822                	sd	s0,16(sp)
    800010e0:	e426                	sd	s1,8(sp)
    800010e2:	1000                	addi	s0,sp,32
    800010e4:	84aa                	mv	s1,a0
  //struct proc *p;
  
  //for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    800010e6:	d42ff0ef          	jal	ra,80000628 <kalloc>
    if(pa == 0)
    800010ea:	c105                	beqz	a0,8000110a <proc_mapstacks+0x30>
    800010ec:	862a                	mv	a2,a0
      panic("kalloc");
    uint64 va = KSTACK(0);
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800010ee:	4719                	li	a4,6
    800010f0:	6685                	lui	a3,0x1
    800010f2:	040005b7          	lui	a1,0x4000
    800010f6:	15f5                	addi	a1,a1,-3 # 3fffffd <_entry-0x7c000003>
    800010f8:	05b2                	slli	a1,a1,0xc
    800010fa:	8526                	mv	a0,s1
    800010fc:	a95ff0ef          	jal	ra,80000b90 <kvmmap>
  //}
}
    80001100:	60e2                	ld	ra,24(sp)
    80001102:	6442                	ld	s0,16(sp)
    80001104:	64a2                	ld	s1,8(sp)
    80001106:	6105                	addi	sp,sp,32
    80001108:	8082                	ret
      panic("kalloc");
    8000110a:	00002517          	auipc	a0,0x2
    8000110e:	0c650513          	addi	a0,a0,198 # 800031d0 <digits+0x1a8>
    80001112:	88aff0ef          	jal	ra,8000019c <panic>

0000000080001116 <procinit>:

// initialize the proc table.

void
procinit(void)
{
    80001116:	1101                	addi	sp,sp,-32
    80001118:	ec06                	sd	ra,24(sp)
    8000111a:	e822                	sd	s0,16(sp)
    8000111c:	e426                	sd	s1,8(sp)
    8000111e:	1000                	addi	s0,sp,32
    // 初始化 pid_lock 和 wait_lock
    initlock(&pid_lock, "nextpid");
    80001120:	0000a497          	auipc	s1,0xa
    80001124:	53848493          	addi	s1,s1,1336 # 8000b658 <pid_lock>
    80001128:	00002597          	auipc	a1,0x2
    8000112c:	0b058593          	addi	a1,a1,176 # 800031d8 <digits+0x1b0>
    80001130:	8526                	mv	a0,s1
    80001132:	d46ff0ef          	jal	ra,80000678 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001136:	00002597          	auipc	a1,0x2
    8000113a:	0aa58593          	addi	a1,a1,170 # 800031e0 <digits+0x1b8>
    8000113e:	0000a517          	auipc	a0,0xa
    80001142:	53250513          	addi	a0,a0,1330 # 8000b670 <wait_lock>
    80001146:	d32ff0ef          	jal	ra,80000678 <initlock>

    // 设置进程状态为未使用
    //p->state = UNUSED;

    // 为进程分配内核栈地址
    p->kstack = KSTACK(0); 
    8000114a:	040007b7          	lui	a5,0x4000
    8000114e:	17f5                	addi	a5,a5,-3 # 3fffffd <_entry-0x7c000003>
    80001150:	07b2                	slli	a5,a5,0xc
    80001152:	e4bc                	sd	a5,72(s1)
}
    80001154:	60e2                	ld	ra,24(sp)
    80001156:	6442                	ld	s0,16(sp)
    80001158:	64a2                	ld	s1,8(sp)
    8000115a:	6105                	addi	sp,sp,32
    8000115c:	8082                	ret

000000008000115e <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000115e:	1141                	addi	sp,sp,-16
    80001160:	e422                	sd	s0,8(sp)
    80001162:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001164:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001166:	2501                	sext.w	a0,a0
    80001168:	6422                	ld	s0,8(sp)
    8000116a:	0141                	addi	sp,sp,16
    8000116c:	8082                	ret

000000008000116e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    8000116e:	1141                	addi	sp,sp,-16
    80001170:	e422                	sd	s0,8(sp)
    80001172:	0800                	addi	s0,sp,16
    80001174:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001176:	2781                	sext.w	a5,a5
    80001178:	079e                	slli	a5,a5,0x7
  return c;
}
    8000117a:	0000a517          	auipc	a0,0xa
    8000117e:	5ce50513          	addi	a0,a0,1486 # 8000b748 <cpus>
    80001182:	953e                	add	a0,a0,a5
    80001184:	6422                	ld	s0,8(sp)
    80001186:	0141                	addi	sp,sp,16
    80001188:	8082                	ret

000000008000118a <myproc>:

// Return the current struct proc *, or zero if none.

struct proc*
myproc(void)
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	1000                	addi	s0,sp,32
  push_off();
    80001194:	d24ff0ef          	jal	ra,800006b8 <push_off>
    80001198:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000119a:	2781                	sext.w	a5,a5
    8000119c:	079e                	slli	a5,a5,0x7
    8000119e:	0000a717          	auipc	a4,0xa
    800011a2:	4ba70713          	addi	a4,a4,1210 # 8000b658 <pid_lock>
    800011a6:	97ba                	add	a5,a5,a4
    800011a8:	7be4                	ld	s1,240(a5)
  pop_off();
    800011aa:	d92ff0ef          	jal	ra,8000073c <pop_off>
  return p;
}
    800011ae:	8526                	mv	a0,s1
    800011b0:	60e2                	ld	ra,24(sp)
    800011b2:	6442                	ld	s0,16(sp)
    800011b4:	64a2                	ld	s1,8(sp)
    800011b6:	6105                	addi	sp,sp,32
    800011b8:	8082                	ret

00000000800011ba <proc_pagetable>:

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
    800011ba:	1101                	addi	sp,sp,-32
    800011bc:	ec06                	sd	ra,24(sp)
    800011be:	e822                	sd	s0,16(sp)
    800011c0:	e426                	sd	s1,8(sp)
    800011c2:	e04a                	sd	s2,0(sp)
    800011c4:	1000                	addi	s0,sp,32
    800011c6:	892a                	mv	s2,a0
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
    800011c8:	b6bff0ef          	jal	ra,80000d32 <uvmcreate>
    800011cc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011ce:	cd05                	beqz	a0,80001206 <proc_pagetable+0x4c>

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800011d0:	4729                	li	a4,10
    800011d2:	00001697          	auipc	a3,0x1
    800011d6:	e2e68693          	addi	a3,a3,-466 # 80002000 <_trampoline>
    800011da:	6605                	lui	a2,0x1
    800011dc:	040005b7          	lui	a1,0x4000
    800011e0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800011e2:	05b2                	slli	a1,a1,0xc
    800011e4:	919ff0ef          	jal	ra,80000afc <mappages>
    800011e8:	02054663          	bltz	a0,80001214 <proc_pagetable+0x5a>
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800011ec:	4719                	li	a4,6
    800011ee:	03093683          	ld	a3,48(s2) # 1030 <_entry-0x7fffefd0>
    800011f2:	6605                	lui	a2,0x1
    800011f4:	020005b7          	lui	a1,0x2000
    800011f8:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    800011fa:	05b6                	slli	a1,a1,0xd
    800011fc:	8526                	mv	a0,s1
    800011fe:	8ffff0ef          	jal	ra,80000afc <mappages>
    80001202:	00054f63          	bltz	a0,80001220 <proc_pagetable+0x66>
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}
    80001206:	8526                	mv	a0,s1
    80001208:	60e2                	ld	ra,24(sp)
    8000120a:	6442                	ld	s0,16(sp)
    8000120c:	64a2                	ld	s1,8(sp)
    8000120e:	6902                	ld	s2,0(sp)
    80001210:	6105                	addi	sp,sp,32
    80001212:	8082                	ret
    uvmfree(pagetable, 0);
    80001214:	4581                	li	a1,0
    80001216:	8526                	mv	a0,s1
    80001218:	bffff0ef          	jal	ra,80000e16 <uvmfree>
    return 0;
    8000121c:	4481                	li	s1,0
    8000121e:	b7e5                	j	80001206 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001220:	4681                	li	a3,0
    80001222:	4605                	li	a2,1
    80001224:	040005b7          	lui	a1,0x4000
    80001228:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000122a:	05b2                	slli	a1,a1,0xc
    8000122c:	8526                	mv	a0,s1
    8000122e:	a59ff0ef          	jal	ra,80000c86 <uvmunmap>
    uvmfree(pagetable, 0);
    80001232:	4581                	li	a1,0
    80001234:	8526                	mv	a0,s1
    80001236:	be1ff0ef          	jal	ra,80000e16 <uvmfree>
    return 0;
    8000123a:	4481                	li	s1,0
    8000123c:	b7e9                	j	80001206 <proc_pagetable+0x4c>

000000008000123e <userinit>:
};

// Set up first user process.
void
userinit(void)
{
    8000123e:	7179                	addi	sp,sp,-48
    80001240:	f406                	sd	ra,40(sp)
    80001242:	f022                	sd	s0,32(sp)
    80001244:	ec26                	sd	s1,24(sp)
    80001246:	e84a                	sd	s2,16(sp)
    80001248:	e44e                	sd	s3,8(sp)
    8000124a:	e052                	sd	s4,0(sp)
    8000124c:	1800                	addi	s0,sp,48
   p->pid=1;
    8000124e:	0000a917          	auipc	s2,0xa
    80001252:	40a90913          	addi	s2,s2,1034 # 8000b658 <pid_lock>
    80001256:	4785                	li	a5,1
    80001258:	02f92c23          	sw	a5,56(s2)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000125c:	bccff0ef          	jal	ra,80000628 <kalloc>
    80001260:	84aa                	mv	s1,a0
    80001262:	06a93023          	sd	a0,96(s2)
    80001266:	c921                	beqz	a0,800012b6 <userinit+0x78>
  p->pagetable = proc_pagetable(p);
    80001268:	0000a517          	auipc	a0,0xa
    8000126c:	42050513          	addi	a0,a0,1056 # 8000b688 <proc>
    80001270:	f4bff0ef          	jal	ra,800011ba <proc_pagetable>
    80001274:	84aa                	mv	s1,a0
    80001276:	0000a797          	auipc	a5,0xa
    8000127a:	42a7bd23          	sd	a0,1082(a5) # 8000b6b0 <proc+0x28>
  if(p->pagetable == 0){
    8000127e:	10050763          	beqz	a0,8000138c <userinit+0x14e>
  memset(&p->context, 0, sizeof(p->context));
    80001282:	0000a497          	auipc	s1,0xa
    80001286:	3d648493          	addi	s1,s1,982 # 8000b658 <pid_lock>
    8000128a:	07000613          	li	a2,112
    8000128e:	4581                	li	a1,0
    80001290:	0000a517          	auipc	a0,0xa
    80001294:	43050513          	addi	a0,a0,1072 # 8000b6c0 <proc+0x38>
    80001298:	d34ff0ef          	jal	ra,800007cc <memset>
  p->context.ra = (uint64)usertrapret;
    8000129c:	00000797          	auipc	a5,0x0
    800012a0:	26a78793          	addi	a5,a5,618 # 80001506 <usertrapret>
    800012a4:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    800012a6:	64bc                	ld	a5,72(s1)
    800012a8:	6705                	lui	a4,0x1
    800012aa:	97ba                	add	a5,a5,a4
    800012ac:	f8bc                	sd	a5,112(s1)
  return p;
    800012ae:	0000a497          	auipc	s1,0xa
    800012b2:	3da48493          	addi	s1,s1,986 # 8000b688 <proc>
  struct proc *p;

  p = allocproc();
  initproc = p;
    800012b6:	00002797          	auipc	a5,0x2
    800012ba:	1c97b923          	sd	s1,466(a5) # 80003488 <initproc>
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    800012be:	03800613          	li	a2,56
    800012c2:	00002597          	auipc	a1,0x2
    800012c6:	13e58593          	addi	a1,a1,318 # 80003400 <initcode>
    800012ca:	7488                	ld	a0,40(s1)
    800012cc:	a8dff0ef          	jal	ra,80000d58 <uvmfirst>
  p->sz = PGSIZE;
    800012d0:	6785                	lui	a5,0x1
    800012d2:	f09c                	sd	a5,32(s1)

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
    800012d4:	789c                	ld	a5,48(s1)
    800012d6:	0007bc23          	sd	zero,24(a5) # 1018 <_entry-0x7fffefe8>

  safestrcpy(p->name, "initcode", sizeof(p->name));
    800012da:	4641                	li	a2,16
    800012dc:	00002597          	auipc	a1,0x2
    800012e0:	f1458593          	addi	a1,a1,-236 # 800031f0 <digits+0x1c8>
    800012e4:	0b048513          	addi	a0,s1,176
    800012e8:	e2aff0ef          	jal	ra,80000912 <safestrcpy>
    800012ec:	6985                	lui	s3,0x1

  // 创建全局数据区（2个页）
  for(int i = 1; i <= 2; i++) {
    800012ee:	6a0d                	lui	s4,0x3
    char *data_mem = kalloc();
    800012f0:	b38ff0ef          	jal	ra,80000628 <kalloc>
    800012f4:	892a                	mv	s2,a0
    if (data_mem == 0) {
    800012f6:	c155                	beqz	a0,8000139a <userinit+0x15c>
      panic("kalloc for global data failed");
    }
    memset(data_mem, 0, PGSIZE);  // 初始化为0
    800012f8:	6605                	lui	a2,0x1
    800012fa:	4581                	li	a1,0
    800012fc:	cd0ff0ef          	jal	ra,800007cc <memset>
    uint64 data_va = i * PGSIZE;
    if (mappages(p->pagetable, data_va, PGSIZE, (uint64)data_mem, PTE_R | PTE_W | PTE_U) != 0) {
    80001300:	4759                	li	a4,22
    80001302:	86ca                	mv	a3,s2
    80001304:	6605                	lui	a2,0x1
    80001306:	85ce                	mv	a1,s3
    80001308:	7488                	ld	a0,40(s1)
    8000130a:	ff2ff0ef          	jal	ra,80000afc <mappages>
    8000130e:	ed41                	bnez	a0,800013a6 <userinit+0x168>
      kfree(data_mem);
      panic("mappages for global data failed");
    }
    p->sz += PGSIZE;
    80001310:	6705                	lui	a4,0x1
    80001312:	709c                	ld	a5,32(s1)
    80001314:	97ba                	add	a5,a5,a4
    80001316:	f09c                	sd	a5,32(s1)
  for(int i = 1; i <= 2; i++) {
    80001318:	99ba                	add	s3,s3,a4
    8000131a:	fd499be3          	bne	s3,s4,800012f0 <userinit+0xb2>
  }

  // 创建用户栈（1个页）
  char *stack_mem = kalloc();
    8000131e:	b0aff0ef          	jal	ra,80000628 <kalloc>
    80001322:	892a                	mv	s2,a0
  if (stack_mem == 0) {
    80001324:	c951                	beqz	a0,800013b8 <userinit+0x17a>
    panic("kalloc for user stack failed");
  }
  memset(stack_mem, 0, PGSIZE);
    80001326:	6605                	lui	a2,0x1
    80001328:	4581                	li	a1,0
    8000132a:	ca2ff0ef          	jal	ra,800007cc <memset>
  uint64 stack_va = 3 * PGSIZE;  // 第3页
  if (mappages(p->pagetable, stack_va, PGSIZE, (uint64)stack_mem, PTE_R | PTE_W | PTE_U) != 0) {
    8000132e:	4759                	li	a4,22
    80001330:	86ca                	mv	a3,s2
    80001332:	6605                	lui	a2,0x1
    80001334:	658d                	lui	a1,0x3
    80001336:	7488                	ld	a0,40(s1)
    80001338:	fc4ff0ef          	jal	ra,80000afc <mappages>
    8000133c:	e541                	bnez	a0,800013c4 <userinit+0x186>
    kfree(stack_mem);
    panic("mappages for user stack failed");
  }
  p->sz += PGSIZE;
    8000133e:	709c                	ld	a5,32(s1)
    80001340:	6705                	lui	a4,0x1
    80001342:	97ba                	add	a5,a5,a4
    80001344:	f09c                	sd	a5,32(s1)

  // 设置用户态的栈顶指针（第4页的起始地址）
  p->trapframe->sp = 4 * PGSIZE;
    80001346:	789c                	ld	a5,48(s1)
    80001348:	6711                	lui	a4,0x4
    8000134a:	fb98                	sd	a4,48(a5)
    8000134c:	8792                	mv	a5,tp
  int id = r_tp();
    8000134e:	2781                	sext.w	a5,a5

  // 设置当前 CPU 的 proc 指针指向首进程
  struct cpu *c = mycpu();
  c->proc = p;
    80001350:	079e                	slli	a5,a5,0x7
    80001352:	0000a717          	auipc	a4,0xa
    80001356:	30670713          	addi	a4,a4,774 # 8000b658 <pid_lock>
    8000135a:	973e                	add	a4,a4,a5
    8000135c:	fb64                	sd	s1,240(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000135e:	10002773          	csrr	a4,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001362:	00276713          	ori	a4,a4,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001366:	10071073          	csrw	sstatus,a4
  struct context *old_context = &c->context;
  // 获取首进程的上下文
  struct context *new_context = &p->context;

  // 调用 swtch() 进行上下文切换
  swtch(old_context, new_context);
    8000136a:	03848593          	addi	a1,s1,56
    8000136e:	0000a517          	auipc	a0,0xa
    80001372:	3e250513          	addi	a0,a0,994 # 8000b750 <cpus+0x8>
    80001376:	953e                	add	a0,a0,a5
    80001378:	0e8000ef          	jal	ra,80001460 <swtch>
}
    8000137c:	70a2                	ld	ra,40(sp)
    8000137e:	7402                	ld	s0,32(sp)
    80001380:	64e2                	ld	s1,24(sp)
    80001382:	6942                	ld	s2,16(sp)
    80001384:	69a2                	ld	s3,8(sp)
    80001386:	6a02                	ld	s4,0(sp)
    80001388:	6145                	addi	sp,sp,48
    8000138a:	8082                	ret
    kfree((void*)p->trapframe);
    8000138c:	06093503          	ld	a0,96(s2)
    80001390:	9b6ff0ef          	jal	ra,80000546 <kfree>
    p->trapframe=0;
    80001394:	06093023          	sd	zero,96(s2)
    return 0;
    80001398:	bf39                	j	800012b6 <userinit+0x78>
      panic("kalloc for global data failed");
    8000139a:	00002517          	auipc	a0,0x2
    8000139e:	e6650513          	addi	a0,a0,-410 # 80003200 <digits+0x1d8>
    800013a2:	dfbfe0ef          	jal	ra,8000019c <panic>
      kfree(data_mem);
    800013a6:	854a                	mv	a0,s2
    800013a8:	99eff0ef          	jal	ra,80000546 <kfree>
      panic("mappages for global data failed");
    800013ac:	00002517          	auipc	a0,0x2
    800013b0:	e7450513          	addi	a0,a0,-396 # 80003220 <digits+0x1f8>
    800013b4:	de9fe0ef          	jal	ra,8000019c <panic>
    panic("kalloc for user stack failed");
    800013b8:	00002517          	auipc	a0,0x2
    800013bc:	e8850513          	addi	a0,a0,-376 # 80003240 <digits+0x218>
    800013c0:	dddfe0ef          	jal	ra,8000019c <panic>
    kfree(stack_mem);
    800013c4:	854a                	mv	a0,s2
    800013c6:	980ff0ef          	jal	ra,80000546 <kfree>
    panic("mappages for user stack failed");
    800013ca:	00002517          	auipc	a0,0x2
    800013ce:	e9650513          	addi	a0,a0,-362 # 80003260 <digits+0x238>
    800013d2:	dcbfe0ef          	jal	ra,8000019c <panic>

00000000800013d6 <forkret>:

// // A fork child's very first scheduling by scheduler()
// // will swtch to forkret.
void
forkret(void)
{
    800013d6:	1141                	addi	sp,sp,-16
    800013d8:	e406                	sd	ra,8(sp)
    800013da:	e022                	sd	s0,0(sp)
    800013dc:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  //release(&myproc()->lock);

  if (first) {
    800013de:	00002797          	auipc	a5,0x2
    800013e2:	0127a783          	lw	a5,18(a5) # 800033f0 <first.0>
    800013e6:	e799                	bnez	a5,800013f4 <forkret+0x1e>
    first = 0;
    // ensure other cores see first=0.
    __sync_synchronize();
  }

  usertrapret();
    800013e8:	11e000ef          	jal	ra,80001506 <usertrapret>
}
    800013ec:	60a2                	ld	ra,8(sp)
    800013ee:	6402                	ld	s0,0(sp)
    800013f0:	0141                	addi	sp,sp,16
    800013f2:	8082                	ret
    first = 0;
    800013f4:	00002797          	auipc	a5,0x2
    800013f8:	fe07ae23          	sw	zero,-4(a5) # 800033f0 <first.0>
    __sync_synchronize();
    800013fc:	0ff0000f          	fence
    80001400:	b7e5                	j	800013e8 <forkret+0x12>

0000000080001402 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80001402:	1141                	addi	sp,sp,-16
    80001404:	e406                	sd	ra,8(sp)
    80001406:	e022                	sd	s0,0(sp)
    80001408:	0800                	addi	s0,sp,16
  struct proc *p=&proc;

  //for(p = proc; p < &proc[NPROC]; p++) {
    if(p != myproc()){
    8000140a:	d81ff0ef          	jal	ra,8000118a <myproc>
      //   p->state = RUNNABLE;
      // }
      //release(&p->lock);
    }
  //}
}
    8000140e:	60a2                	ld	ra,8(sp)
    80001410:	6402                	ld	s0,0(sp)
    80001412:	0141                	addi	sp,sp,16
    80001414:	8082                	ret

0000000080001416 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80001416:	7179                	addi	sp,sp,-48
    80001418:	f406                	sd	ra,40(sp)
    8000141a:	f022                	sd	s0,32(sp)
    8000141c:	ec26                	sd	s1,24(sp)
    8000141e:	e84a                	sd	s2,16(sp)
    80001420:	e44e                	sd	s3,8(sp)
    80001422:	e052                	sd	s4,0(sp)
    80001424:	1800                	addi	s0,sp,48
    80001426:	84aa                	mv	s1,a0
    80001428:	892e                	mv	s2,a1
    8000142a:	89b2                	mv	s3,a2
    8000142c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000142e:	d5dff0ef          	jal	ra,8000118a <myproc>
  if(user_dst){
    80001432:	cc99                	beqz	s1,80001450 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80001434:	86d2                	mv	a3,s4
    80001436:	864e                	mv	a2,s3
    80001438:	85ca                	mv	a1,s2
    8000143a:	7508                	ld	a0,40(a0)
    8000143c:	ae9ff0ef          	jal	ra,80000f24 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80001440:	70a2                	ld	ra,40(sp)
    80001442:	7402                	ld	s0,32(sp)
    80001444:	64e2                	ld	s1,24(sp)
    80001446:	6942                	ld	s2,16(sp)
    80001448:	69a2                	ld	s3,8(sp)
    8000144a:	6a02                	ld	s4,0(sp)
    8000144c:	6145                	addi	sp,sp,48
    8000144e:	8082                	ret
    memmove((char *)dst, src, len);
    80001450:	000a061b          	sext.w	a2,s4
    80001454:	85ce                	mv	a1,s3
    80001456:	854a                	mv	a0,s2
    80001458:	bd0ff0ef          	jal	ra,80000828 <memmove>
    return 0;
    8000145c:	8526                	mv	a0,s1
    8000145e:	b7cd                	j	80001440 <either_copyout+0x2a>

0000000080001460 <swtch>:
    80001460:	00153023          	sd	ra,0(a0)
    80001464:	00253423          	sd	sp,8(a0)
    80001468:	e900                	sd	s0,16(a0)
    8000146a:	ed04                	sd	s1,24(a0)
    8000146c:	03253023          	sd	s2,32(a0)
    80001470:	03353423          	sd	s3,40(a0)
    80001474:	03453823          	sd	s4,48(a0)
    80001478:	03553c23          	sd	s5,56(a0)
    8000147c:	05653023          	sd	s6,64(a0)
    80001480:	05753423          	sd	s7,72(a0)
    80001484:	05853823          	sd	s8,80(a0)
    80001488:	05953c23          	sd	s9,88(a0)
    8000148c:	07a53023          	sd	s10,96(a0)
    80001490:	07b53423          	sd	s11,104(a0)
    80001494:	0005b083          	ld	ra,0(a1) # 3000 <_entry-0x7fffd000>
    80001498:	0085b103          	ld	sp,8(a1)
    8000149c:	6980                	ld	s0,16(a1)
    8000149e:	6d84                	ld	s1,24(a1)
    800014a0:	0205b903          	ld	s2,32(a1)
    800014a4:	0285b983          	ld	s3,40(a1)
    800014a8:	0305ba03          	ld	s4,48(a1)
    800014ac:	0385ba83          	ld	s5,56(a1)
    800014b0:	0405bb03          	ld	s6,64(a1)
    800014b4:	0485bb83          	ld	s7,72(a1)
    800014b8:	0505bc03          	ld	s8,80(a1)
    800014bc:	0585bc83          	ld	s9,88(a1)
    800014c0:	0605bd03          	ld	s10,96(a1)
    800014c4:	0685bd83          	ld	s11,104(a1)
    800014c8:	8082                	ret

00000000800014ca <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800014ca:	1141                	addi	sp,sp,-16
    800014cc:	e406                	sd	ra,8(sp)
    800014ce:	e022                	sd	s0,0(sp)
    800014d0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800014d2:	00002597          	auipc	a1,0x2
    800014d6:	dae58593          	addi	a1,a1,-594 # 80003280 <digits+0x258>
    800014da:	0000a517          	auipc	a0,0xa
    800014de:	66e50513          	addi	a0,a0,1646 # 8000bb48 <tickslock>
    800014e2:	996ff0ef          	jal	ra,80000678 <initlock>
}
    800014e6:	60a2                	ld	ra,8(sp)
    800014e8:	6402                	ld	s0,0(sp)
    800014ea:	0141                	addi	sp,sp,16
    800014ec:	8082                	ret

00000000800014ee <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800014ee:	1141                	addi	sp,sp,-16
    800014f0:	e422                	sd	s0,8(sp)
    800014f2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800014f4:	00000797          	auipc	a5,0x0
    800014f8:	2bc78793          	addi	a5,a5,700 # 800017b0 <kernelvec>
    800014fc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80001500:	6422                	ld	s0,8(sp)
    80001502:	0141                	addi	sp,sp,16
    80001504:	8082                	ret

0000000080001506 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80001506:	1141                	addi	sp,sp,-16
    80001508:	e406                	sd	ra,8(sp)
    8000150a:	e022                	sd	s0,0(sp)
    8000150c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000150e:	c7dff0ef          	jal	ra,8000118a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001512:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001516:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001518:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000151c:	00001697          	auipc	a3,0x1
    80001520:	ae468693          	addi	a3,a3,-1308 # 80002000 <_trampoline>
    80001524:	00001717          	auipc	a4,0x1
    80001528:	adc70713          	addi	a4,a4,-1316 # 80002000 <_trampoline>
    8000152c:	8f15                	sub	a4,a4,a3
    8000152e:	040007b7          	lui	a5,0x4000
    80001532:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80001534:	07b2                	slli	a5,a5,0xc
    80001536:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80001538:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000153c:	7918                	ld	a4,48(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000153e:	18002673          	csrr	a2,satp
    80001542:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80001544:	7910                	ld	a2,48(a0)
    80001546:	6d18                	ld	a4,24(a0)
    80001548:	6585                	lui	a1,0x1
    8000154a:	972e                	add	a4,a4,a1
    8000154c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000154e:	7918                	ld	a4,48(a0)
    80001550:	00000617          	auipc	a2,0x0
    80001554:	12260613          	addi	a2,a2,290 # 80001672 <usertrap>
    80001558:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000155a:	7918                	ld	a4,48(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000155c:	8612                	mv	a2,tp
    8000155e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001560:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80001564:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80001568:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000156c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80001570:	7918                	ld	a4,48(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80001572:	6f18                	ld	a4,24(a4)
    80001574:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80001578:	7508                	ld	a0,40(a0)
    8000157a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000157c:	00001717          	auipc	a4,0x1
    80001580:	b2070713          	addi	a4,a4,-1248 # 8000209c <userret>
    80001584:	8f15                	sub	a4,a4,a3
    80001586:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001588:	577d                	li	a4,-1
    8000158a:	177e                	slli	a4,a4,0x3f
    8000158c:	8d59                	or	a0,a0,a4
    8000158e:	9782                	jalr	a5
}
    80001590:	60a2                	ld	ra,8(sp)
    80001592:	6402                	ld	s0,0(sp)
    80001594:	0141                	addi	sp,sp,16
    80001596:	8082                	ret

0000000080001598 <clockintr>:
}
 // 新增：定时器中断计数器
 uint timer_interrupt_count = 0; 
void
clockintr()
{
    80001598:	1141                	addi	sp,sp,-16
    8000159a:	e406                	sd	ra,8(sp)
    8000159c:	e022                	sd	s0,0(sp)
    8000159e:	0800                	addi	s0,sp,16
  acquire(&tickslock);
    800015a0:	0000a517          	auipc	a0,0xa
    800015a4:	5a850513          	addi	a0,a0,1448 # 8000bb48 <tickslock>
    800015a8:	950ff0ef          	jal	ra,800006f8 <acquire>
  ticks++;
    800015ac:	00002717          	auipc	a4,0x2
    800015b0:	ee870713          	addi	a4,a4,-280 # 80003494 <ticks>
    800015b4:	431c                	lw	a5,0(a4)
    800015b6:	2785                	addiw	a5,a5,1
    800015b8:	c31c                	sw	a5,0(a4)
 
  // 新增：处理定时器中断计数
  timer_interrupt_count++;
    800015ba:	00002717          	auipc	a4,0x2
    800015be:	ed670713          	addi	a4,a4,-298 # 80003490 <timer_interrupt_count>
    800015c2:	431c                	lw	a5,0(a4)
    800015c4:	2785                	addiw	a5,a5,1
    800015c6:	c31c                	sw	a5,0(a4)
  if (timer_interrupt_count % 30 == 0) {
    800015c8:	4779                	li	a4,30
    800015ca:	02e7f7bb          	remuw	a5,a5,a4
    800015ce:	cb99                	beqz	a5,800015e4 <clockintr+0x4c>
    printf("T");
  }
 // wakeup(&ticks);
  release(&tickslock);
    800015d0:	0000a517          	auipc	a0,0xa
    800015d4:	57850513          	addi	a0,a0,1400 # 8000bb48 <tickslock>
    800015d8:	9b8ff0ef          	jal	ra,80000790 <release>
}
    800015dc:	60a2                	ld	ra,8(sp)
    800015de:	6402                	ld	s0,0(sp)
    800015e0:	0141                	addi	sp,sp,16
    800015e2:	8082                	ret
    printf("T");
    800015e4:	00002517          	auipc	a0,0x2
    800015e8:	ca450513          	addi	a0,a0,-860 # 80003288 <digits+0x260>
    800015ec:	beffe0ef          	jal	ra,800001da <printf>
    800015f0:	b7c5                	j	800015d0 <clockintr+0x38>

00000000800015f2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800015f2:	1101                	addi	sp,sp,-32
    800015f4:	ec06                	sd	ra,24(sp)
    800015f6:	e822                	sd	s0,16(sp)
    800015f8:	e426                	sd	s1,8(sp)
    800015fa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800015fc:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80001600:	00074d63          	bltz	a4,8000161a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80001604:	57fd                	li	a5,-1
    80001606:	17fe                	slli	a5,a5,0x3f
    80001608:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000160a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000160c:	04f70663          	beq	a4,a5,80001658 <devintr+0x66>
  }
}
    80001610:	60e2                	ld	ra,24(sp)
    80001612:	6442                	ld	s0,16(sp)
    80001614:	64a2                	ld	s1,8(sp)
    80001616:	6105                	addi	sp,sp,32
    80001618:	8082                	ret
     (scause & 0xff) == 9){
    8000161a:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000161e:	46a5                	li	a3,9
    80001620:	fed792e3          	bne	a5,a3,80001604 <devintr+0x12>
    int irq = plic_claim();
    80001624:	2a4000ef          	jal	ra,800018c8 <plic_claim>
    80001628:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000162a:	47a9                	li	a5,10
    8000162c:	00f50f63          	beq	a0,a5,8000164a <devintr+0x58>
    } else if(irq == VIRTIO0_IRQ){
    80001630:	4785                	li	a5,1
    80001632:	00f50e63          	beq	a0,a5,8000164e <devintr+0x5c>
    return 1;
    80001636:	4505                	li	a0,1
    } else if(irq){
    80001638:	dce1                	beqz	s1,80001610 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000163a:	85a6                	mv	a1,s1
    8000163c:	00002517          	auipc	a0,0x2
    80001640:	c5450513          	addi	a0,a0,-940 # 80003290 <digits+0x268>
    80001644:	b97fe0ef          	jal	ra,800001da <printf>
    80001648:	a019                	j	8000164e <devintr+0x5c>
      uartintr();
    8000164a:	ec1fe0ef          	jal	ra,8000050a <uartintr>
      plic_complete(irq);
    8000164e:	8526                	mv	a0,s1
    80001650:	298000ef          	jal	ra,800018e8 <plic_complete>
    return 1;
    80001654:	4505                	li	a0,1
    80001656:	bf6d                	j	80001610 <devintr+0x1e>
    if(cpuid() == 0){
    80001658:	b07ff0ef          	jal	ra,8000115e <cpuid>
    8000165c:	c901                	beqz	a0,8000166c <devintr+0x7a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000165e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80001662:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80001664:	14479073          	csrw	sip,a5
    return 2;
    80001668:	4509                	li	a0,2
    8000166a:	b75d                	j	80001610 <devintr+0x1e>
      clockintr();
    8000166c:	f2dff0ef          	jal	ra,80001598 <clockintr>
    80001670:	b7fd                	j	8000165e <devintr+0x6c>

0000000080001672 <usertrap>:
{
    80001672:	1101                	addi	sp,sp,-32
    80001674:	ec06                	sd	ra,24(sp)
    80001676:	e822                	sd	s0,16(sp)
    80001678:	e426                	sd	s1,8(sp)
    8000167a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000167c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80001680:	1007f793          	andi	a5,a5,256
    80001684:	ef8d                	bnez	a5,800016be <usertrap+0x4c>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80001686:	00000797          	auipc	a5,0x0
    8000168a:	12a78793          	addi	a5,a5,298 # 800017b0 <kernelvec>
    8000168e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80001692:	af9ff0ef          	jal	ra,8000118a <myproc>
    80001696:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80001698:	791c                	ld	a5,48(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000169a:	14102773          	csrr	a4,sepc
    8000169e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800016a0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800016a4:	47a1                	li	a5,8
    800016a6:	02f70263          	beq	a4,a5,800016ca <usertrap+0x58>
  } else if((which_dev = devintr()) != 0){
    800016aa:	f49ff0ef          	jal	ra,800015f2 <devintr>
    800016ae:	c131                	beqz	a0,800016f2 <usertrap+0x80>
  usertrapret();
    800016b0:	e57ff0ef          	jal	ra,80001506 <usertrapret>
}
    800016b4:	60e2                	ld	ra,24(sp)
    800016b6:	6442                	ld	s0,16(sp)
    800016b8:	64a2                	ld	s1,8(sp)
    800016ba:	6105                	addi	sp,sp,32
    800016bc:	8082                	ret
    panic("usertrap: not from user mode");
    800016be:	00002517          	auipc	a0,0x2
    800016c2:	bf250513          	addi	a0,a0,-1038 # 800032b0 <digits+0x288>
    800016c6:	ad7fe0ef          	jal	ra,8000019c <panic>
    printf("get a syscall from proc %d\n", myproc()->pid); 
    800016ca:	ac1ff0ef          	jal	ra,8000118a <myproc>
    800016ce:	450c                	lw	a1,8(a0)
    800016d0:	00002517          	auipc	a0,0x2
    800016d4:	c0050513          	addi	a0,a0,-1024 # 800032d0 <digits+0x2a8>
    800016d8:	b03fe0ef          	jal	ra,800001da <printf>
    p->trapframe->epc += 4; 
    800016dc:	7898                	ld	a4,48(s1)
    800016de:	6f1c                	ld	a5,24(a4)
    800016e0:	0791                	addi	a5,a5,4
    800016e2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800016e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800016e8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800016ec:	10079073          	csrw	sstatus,a5
}
    800016f0:	b7c1                	j	800016b0 <usertrap+0x3e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800016f2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800016f6:	4490                	lw	a2,8(s1)
    800016f8:	00002517          	auipc	a0,0x2
    800016fc:	bf850513          	addi	a0,a0,-1032 # 800032f0 <digits+0x2c8>
    80001700:	adbfe0ef          	jal	ra,800001da <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80001704:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001708:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000170c:	00002517          	auipc	a0,0x2
    80001710:	c1450513          	addi	a0,a0,-1004 # 80003320 <digits+0x2f8>
    80001714:	ac7fe0ef          	jal	ra,800001da <printf>
    printf("            epc=%p sp=%p\n", p->trapframe->epc, p->trapframe->sp);
    80001718:	789c                	ld	a5,48(s1)
    8000171a:	7b90                	ld	a2,48(a5)
    8000171c:	6f8c                	ld	a1,24(a5)
    8000171e:	00002517          	auipc	a0,0x2
    80001722:	c2250513          	addi	a0,a0,-990 # 80003340 <digits+0x318>
    80001726:	ab5fe0ef          	jal	ra,800001da <printf>
    8000172a:	b759                	j	800016b0 <usertrap+0x3e>

000000008000172c <kerneltrap>:
{
    8000172c:	7179                	addi	sp,sp,-48
    8000172e:	f406                	sd	ra,40(sp)
    80001730:	f022                	sd	s0,32(sp)
    80001732:	ec26                	sd	s1,24(sp)
    80001734:	e84a                	sd	s2,16(sp)
    80001736:	e44e                	sd	s3,8(sp)
    80001738:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000173a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000173e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80001742:	142029f3          	csrr	s3,scause
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001746:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000174a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000174c:	ef99                	bnez	a5,8000176a <kerneltrap+0x3e>
  if((which_dev = devintr()) == 0){
    8000174e:	ea5ff0ef          	jal	ra,800015f2 <devintr>
    80001752:	c115                	beqz	a0,80001776 <kerneltrap+0x4a>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80001754:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001758:	10049073          	csrw	sstatus,s1
}
    8000175c:	70a2                	ld	ra,40(sp)
    8000175e:	7402                	ld	s0,32(sp)
    80001760:	64e2                	ld	s1,24(sp)
    80001762:	6942                	ld	s2,16(sp)
    80001764:	69a2                	ld	s3,8(sp)
    80001766:	6145                	addi	sp,sp,48
    80001768:	8082                	ret
    panic("kerneltrap: interrupts enabled");
    8000176a:	00002517          	auipc	a0,0x2
    8000176e:	bf650513          	addi	a0,a0,-1034 # 80003360 <digits+0x338>
    80001772:	a2bfe0ef          	jal	ra,8000019c <panic>
    printf("scause %p\n", scause);
    80001776:	85ce                	mv	a1,s3
    80001778:	00002517          	auipc	a0,0x2
    8000177c:	c0850513          	addi	a0,a0,-1016 # 80003380 <digits+0x358>
    80001780:	a5bfe0ef          	jal	ra,800001da <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80001784:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001788:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000178c:	00002517          	auipc	a0,0x2
    80001790:	c0450513          	addi	a0,a0,-1020 # 80003390 <digits+0x368>
    80001794:	a47fe0ef          	jal	ra,800001da <printf>
    panic("kerneltrap");
    80001798:	00002517          	auipc	a0,0x2
    8000179c:	c1050513          	addi	a0,a0,-1008 # 800033a8 <digits+0x380>
    800017a0:	9fdfe0ef          	jal	ra,8000019c <panic>
	...

00000000800017b0 <kernelvec>:
    800017b0:	7111                	addi	sp,sp,-256
    800017b2:	e006                	sd	ra,0(sp)
    800017b4:	e40a                	sd	sp,8(sp)
    800017b6:	e80e                	sd	gp,16(sp)
    800017b8:	ec12                	sd	tp,24(sp)
    800017ba:	f016                	sd	t0,32(sp)
    800017bc:	f41a                	sd	t1,40(sp)
    800017be:	f81e                	sd	t2,48(sp)
    800017c0:	fc22                	sd	s0,56(sp)
    800017c2:	e0a6                	sd	s1,64(sp)
    800017c4:	e4aa                	sd	a0,72(sp)
    800017c6:	e8ae                	sd	a1,80(sp)
    800017c8:	ecb2                	sd	a2,88(sp)
    800017ca:	f0b6                	sd	a3,96(sp)
    800017cc:	f4ba                	sd	a4,104(sp)
    800017ce:	f8be                	sd	a5,112(sp)
    800017d0:	fcc2                	sd	a6,120(sp)
    800017d2:	e146                	sd	a7,128(sp)
    800017d4:	e54a                	sd	s2,136(sp)
    800017d6:	e94e                	sd	s3,144(sp)
    800017d8:	ed52                	sd	s4,152(sp)
    800017da:	f156                	sd	s5,160(sp)
    800017dc:	f55a                	sd	s6,168(sp)
    800017de:	f95e                	sd	s7,176(sp)
    800017e0:	fd62                	sd	s8,184(sp)
    800017e2:	e1e6                	sd	s9,192(sp)
    800017e4:	e5ea                	sd	s10,200(sp)
    800017e6:	e9ee                	sd	s11,208(sp)
    800017e8:	edf2                	sd	t3,216(sp)
    800017ea:	f1f6                	sd	t4,224(sp)
    800017ec:	f5fa                	sd	t5,232(sp)
    800017ee:	f9fe                	sd	t6,240(sp)
    800017f0:	f3dff0ef          	jal	ra,8000172c <kerneltrap>
    800017f4:	6082                	ld	ra,0(sp)
    800017f6:	6122                	ld	sp,8(sp)
    800017f8:	61c2                	ld	gp,16(sp)
    800017fa:	7282                	ld	t0,32(sp)
    800017fc:	7322                	ld	t1,40(sp)
    800017fe:	73c2                	ld	t2,48(sp)
    80001800:	7462                	ld	s0,56(sp)
    80001802:	6486                	ld	s1,64(sp)
    80001804:	6526                	ld	a0,72(sp)
    80001806:	65c6                	ld	a1,80(sp)
    80001808:	6666                	ld	a2,88(sp)
    8000180a:	7686                	ld	a3,96(sp)
    8000180c:	7726                	ld	a4,104(sp)
    8000180e:	77c6                	ld	a5,112(sp)
    80001810:	7866                	ld	a6,120(sp)
    80001812:	688a                	ld	a7,128(sp)
    80001814:	692a                	ld	s2,136(sp)
    80001816:	69ca                	ld	s3,144(sp)
    80001818:	6a6a                	ld	s4,152(sp)
    8000181a:	7a8a                	ld	s5,160(sp)
    8000181c:	7b2a                	ld	s6,168(sp)
    8000181e:	7bca                	ld	s7,176(sp)
    80001820:	7c6a                	ld	s8,184(sp)
    80001822:	6c8e                	ld	s9,192(sp)
    80001824:	6d2e                	ld	s10,200(sp)
    80001826:	6dce                	ld	s11,208(sp)
    80001828:	6e6e                	ld	t3,216(sp)
    8000182a:	7e8e                	ld	t4,224(sp)
    8000182c:	7f2e                	ld	t5,232(sp)
    8000182e:	7fce                	ld	t6,240(sp)
    80001830:	6111                	addi	sp,sp,256
    80001832:	10200073          	sret
    80001836:	00000013          	nop
    8000183a:	00000013          	nop
    8000183e:	0001                	nop

0000000080001840 <timervec>:
    80001840:	34051573          	csrrw	a0,mscratch,a0
    80001844:	e10c                	sd	a1,0(a0)
    80001846:	e510                	sd	a2,8(a0)
    80001848:	e914                	sd	a3,16(a0)
    8000184a:	6d0c                	ld	a1,24(a0)
    8000184c:	7110                	ld	a2,32(a0)
    8000184e:	6194                	ld	a3,0(a1)
    80001850:	96b2                	add	a3,a3,a2
    80001852:	e194                	sd	a3,0(a1)
    80001854:	4589                	li	a1,2
    80001856:	14459073          	csrw	sip,a1
    8000185a:	6914                	ld	a3,16(a0)
    8000185c:	6510                	ld	a2,8(a0)
    8000185e:	610c                	ld	a1,0(a0)
    80001860:	34051573          	csrrw	a0,mscratch,a0
    80001864:	30200073          	mret
	...

000000008000186a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000186a:	1141                	addi	sp,sp,-16
    8000186c:	e422                	sd	s0,8(sp)
    8000186e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80001870:	0c0007b7          	lui	a5,0xc000
    80001874:	4705                	li	a4,1
    80001876:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80001878:	c3d8                	sw	a4,4(a5)
}
    8000187a:	6422                	ld	s0,8(sp)
    8000187c:	0141                	addi	sp,sp,16
    8000187e:	8082                	ret

0000000080001880 <plicinithart>:

void
plicinithart(void)
{
    80001880:	1141                	addi	sp,sp,-16
    80001882:	e406                	sd	ra,8(sp)
    80001884:	e022                	sd	s0,0(sp)
    80001886:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80001888:	8d7ff0ef          	jal	ra,8000115e <cpuid>
    8000188c:	85aa                	mv	a1,a0
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    8000188e:	0085179b          	slliw	a5,a0,0x8
    80001892:	0c002737          	lui	a4,0xc002
    80001896:	08070713          	addi	a4,a4,128 # c002080 <_entry-0x73ffdf80>
    8000189a:	97ba                	add	a5,a5,a4
    8000189c:	40200713          	li	a4,1026
    800018a0:	c398                	sw	a4,0(a5)

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800018a2:	00d5169b          	slliw	a3,a0,0xd
    800018a6:	0c201737          	lui	a4,0xc201
    800018aa:	9736                	add	a4,a4,a3
    800018ac:	00072023          	sw	zero,0(a4) # c201000 <_entry-0x73dff000>
  
  printf("plicinithart: hart %d, enable=0x%x, UART0_IRQ=%d\n", 
    800018b0:	46a9                	li	a3,10
    800018b2:	4390                	lw	a2,0(a5)
    800018b4:	00002517          	auipc	a0,0x2
    800018b8:	b0450513          	addi	a0,a0,-1276 # 800033b8 <digits+0x390>
    800018bc:	91ffe0ef          	jal	ra,800001da <printf>
         hart, *(uint32*)PLIC_SENABLE(hart), UART0_IRQ);
}
    800018c0:	60a2                	ld	ra,8(sp)
    800018c2:	6402                	ld	s0,0(sp)
    800018c4:	0141                	addi	sp,sp,16
    800018c6:	8082                	ret

00000000800018c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800018c8:	1141                	addi	sp,sp,-16
    800018ca:	e406                	sd	ra,8(sp)
    800018cc:	e022                	sd	s0,0(sp)
    800018ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800018d0:	88fff0ef          	jal	ra,8000115e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800018d4:	00d5151b          	slliw	a0,a0,0xd
    800018d8:	0c2017b7          	lui	a5,0xc201
    800018dc:	97aa                	add	a5,a5,a0
  return irq;
}
    800018de:	43c8                	lw	a0,4(a5)
    800018e0:	60a2                	ld	ra,8(sp)
    800018e2:	6402                	ld	s0,0(sp)
    800018e4:	0141                	addi	sp,sp,16
    800018e6:	8082                	ret

00000000800018e8 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800018e8:	1101                	addi	sp,sp,-32
    800018ea:	ec06                	sd	ra,24(sp)
    800018ec:	e822                	sd	s0,16(sp)
    800018ee:	e426                	sd	s1,8(sp)
    800018f0:	1000                	addi	s0,sp,32
    800018f2:	84aa                	mv	s1,a0
  int hart = cpuid();
    800018f4:	86bff0ef          	jal	ra,8000115e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800018f8:	00d5151b          	slliw	a0,a0,0xd
    800018fc:	0c2017b7          	lui	a5,0xc201
    80001900:	97aa                	add	a5,a5,a0
    80001902:	c3c4                	sw	s1,4(a5)
}
    80001904:	60e2                	ld	ra,24(sp)
    80001906:	6442                	ld	s0,16(sp)
    80001908:	64a2                	ld	s1,8(sp)
    8000190a:	6105                	addi	sp,sp,32
    8000190c:	8082                	ret
	...

0000000080002000 <_trampoline>:
    80002000:	14051073          	csrw	sscratch,a0
    80002004:	02000537          	lui	a0,0x2000
    80002008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000200a:	0536                	slli	a0,a0,0xd
    8000200c:	02153423          	sd	ra,40(a0)
    80002010:	02253823          	sd	sp,48(a0)
    80002014:	02353c23          	sd	gp,56(a0)
    80002018:	04453023          	sd	tp,64(a0)
    8000201c:	04553423          	sd	t0,72(a0)
    80002020:	04653823          	sd	t1,80(a0)
    80002024:	04753c23          	sd	t2,88(a0)
    80002028:	f120                	sd	s0,96(a0)
    8000202a:	f524                	sd	s1,104(a0)
    8000202c:	fd2c                	sd	a1,120(a0)
    8000202e:	e150                	sd	a2,128(a0)
    80002030:	e554                	sd	a3,136(a0)
    80002032:	e958                	sd	a4,144(a0)
    80002034:	ed5c                	sd	a5,152(a0)
    80002036:	0b053023          	sd	a6,160(a0)
    8000203a:	0b153423          	sd	a7,168(a0)
    8000203e:	0b253823          	sd	s2,176(a0)
    80002042:	0b353c23          	sd	s3,184(a0)
    80002046:	0d453023          	sd	s4,192(a0)
    8000204a:	0d553423          	sd	s5,200(a0)
    8000204e:	0d653823          	sd	s6,208(a0)
    80002052:	0d753c23          	sd	s7,216(a0)
    80002056:	0f853023          	sd	s8,224(a0)
    8000205a:	0f953423          	sd	s9,232(a0)
    8000205e:	0fa53823          	sd	s10,240(a0)
    80002062:	0fb53c23          	sd	s11,248(a0)
    80002066:	11c53023          	sd	t3,256(a0)
    8000206a:	11d53423          	sd	t4,264(a0)
    8000206e:	11e53823          	sd	t5,272(a0)
    80002072:	11f53c23          	sd	t6,280(a0)
    80002076:	140022f3          	csrr	t0,sscratch
    8000207a:	06553823          	sd	t0,112(a0)
    8000207e:	00853103          	ld	sp,8(a0)
    80002082:	02053203          	ld	tp,32(a0)
    80002086:	01053283          	ld	t0,16(a0)
    8000208a:	00053303          	ld	t1,0(a0)
    8000208e:	12000073          	sfence.vma
    80002092:	18031073          	csrw	satp,t1
    80002096:	12000073          	sfence.vma
    8000209a:	8282                	jr	t0

000000008000209c <userret>:
    8000209c:	12000073          	sfence.vma
    800020a0:	18051073          	csrw	satp,a0
    800020a4:	12000073          	sfence.vma
    800020a8:	02000537          	lui	a0,0x2000
    800020ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800020ae:	0536                	slli	a0,a0,0xd
    800020b0:	02853083          	ld	ra,40(a0)
    800020b4:	03053103          	ld	sp,48(a0)
    800020b8:	03853183          	ld	gp,56(a0)
    800020bc:	04053203          	ld	tp,64(a0)
    800020c0:	04853283          	ld	t0,72(a0)
    800020c4:	05053303          	ld	t1,80(a0)
    800020c8:	05853383          	ld	t2,88(a0)
    800020cc:	7120                	ld	s0,96(a0)
    800020ce:	7524                	ld	s1,104(a0)
    800020d0:	7d2c                	ld	a1,120(a0)
    800020d2:	6150                	ld	a2,128(a0)
    800020d4:	6554                	ld	a3,136(a0)
    800020d6:	6958                	ld	a4,144(a0)
    800020d8:	6d5c                	ld	a5,152(a0)
    800020da:	0a053803          	ld	a6,160(a0)
    800020de:	0a853883          	ld	a7,168(a0)
    800020e2:	0b053903          	ld	s2,176(a0)
    800020e6:	0b853983          	ld	s3,184(a0)
    800020ea:	0c053a03          	ld	s4,192(a0)
    800020ee:	0c853a83          	ld	s5,200(a0)
    800020f2:	0d053b03          	ld	s6,208(a0)
    800020f6:	0d853b83          	ld	s7,216(a0)
    800020fa:	0e053c03          	ld	s8,224(a0)
    800020fe:	0e853c83          	ld	s9,232(a0)
    80002102:	0f053d03          	ld	s10,240(a0)
    80002106:	0f853d83          	ld	s11,248(a0)
    8000210a:	10053e03          	ld	t3,256(a0)
    8000210e:	10853e83          	ld	t4,264(a0)
    80002112:	11053f03          	ld	t5,272(a0)
    80002116:	11853f83          	ld	t6,280(a0)
    8000211a:	7928                	ld	a0,112(a0)
    8000211c:	10200073          	sret
	...
