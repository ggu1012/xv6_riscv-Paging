
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	be478793          	addi	a5,a5,-1052 # 80005c40 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e0278793          	addi	a5,a5,-510 # 80000ea8 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	af2080e7          	jalr	-1294(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	334080e7          	jalr	820(ra) # 8000245a <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	796080e7          	jalr	1942(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b64080e7          	jalr	-1180(ra) # 80000cb2 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7159                	addi	sp,sp,-112
    80000170:	f486                	sd	ra,104(sp)
    80000172:	f0a2                	sd	s0,96(sp)
    80000174:	eca6                	sd	s1,88(sp)
    80000176:	e8ca                	sd	s2,80(sp)
    80000178:	e4ce                	sd	s3,72(sp)
    8000017a:	e0d2                	sd	s4,64(sp)
    8000017c:	fc56                	sd	s5,56(sp)
    8000017e:	f85a                	sd	s6,48(sp)
    80000180:	f45e                	sd	s7,40(sp)
    80000182:	f062                	sd	s8,32(sp)
    80000184:	ec66                	sd	s9,24(sp)
    80000186:	e86a                	sd	s10,16(sp)
    80000188:	1880                	addi	s0,sp,112
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000194:	00011517          	auipc	a0,0x11
    80000198:	69c50513          	addi	a0,a0,1692 # 80011830 <cons>
    8000019c:	00001097          	auipc	ra,0x1
    800001a0:	a62080e7          	jalr	-1438(ra) # 80000bfe <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a4:	00011497          	auipc	s1,0x11
    800001a8:	68c48493          	addi	s1,s1,1676 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ac:	00011917          	auipc	s2,0x11
    800001b0:	71c90913          	addi	s2,s2,1820 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b4:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b6:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b8:	4ca9                	li	s9,10
  while(n > 0){
    800001ba:	07305863          	blez	s3,8000022a <consoleread+0xbc>
    while(cons.r == cons.w){
    800001be:	0984a783          	lw	a5,152(s1)
    800001c2:	09c4a703          	lw	a4,156(s1)
    800001c6:	02f71463          	bne	a4,a5,800001ee <consoleread+0x80>
      if(myproc()->killed){
    800001ca:	00001097          	auipc	ra,0x1
    800001ce:	7f0080e7          	jalr	2032(ra) # 800019ba <myproc>
    800001d2:	591c                	lw	a5,48(a0)
    800001d4:	e7b5                	bnez	a5,80000240 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d6:	85a6                	mv	a1,s1
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	fd0080e7          	jalr	-48(ra) # 800021aa <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fef700e3          	beq	a4,a5,800001ca <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000204:	077d0563          	beq	s10,s7,8000026e <consoleread+0x100>
    cbuf = c;
    80000208:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f9f40613          	addi	a2,s0,-97
    80000212:	85d2                	mv	a1,s4
    80000214:	8556                	mv	a0,s5
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	1ee080e7          	jalr	494(ra) # 80002404 <either_copyout>
    8000021e:	01850663          	beq	a0,s8,8000022a <consoleread+0xbc>
    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000226:	f99d1ae3          	bne	s10,s9,800001ba <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	60650513          	addi	a0,a0,1542 # 80011830 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a80080e7          	jalr	-1408(ra) # 80000cb2 <release>

  return target - n;
    8000023a:	413b053b          	subw	a0,s6,s3
    8000023e:	a811                	j	80000252 <consoleread+0xe4>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	5f050513          	addi	a0,a0,1520 # 80011830 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a6a080e7          	jalr	-1430(ra) # 80000cb2 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70a6                	ld	ra,104(sp)
    80000254:	7406                	ld	s0,96(sp)
    80000256:	64e6                	ld	s1,88(sp)
    80000258:	6946                	ld	s2,80(sp)
    8000025a:	69a6                	ld	s3,72(sp)
    8000025c:	6a06                	ld	s4,64(sp)
    8000025e:	7ae2                	ld	s5,56(sp)
    80000260:	7b42                	ld	s6,48(sp)
    80000262:	7ba2                	ld	s7,40(sp)
    80000264:	7c02                	ld	s8,32(sp)
    80000266:	6ce2                	ld	s9,24(sp)
    80000268:	6d42                	ld	s10,16(sp)
    8000026a:	6165                	addi	sp,sp,112
    8000026c:	8082                	ret
      if(n < target){
    8000026e:	0009871b          	sext.w	a4,s3
    80000272:	fb677ce3          	bgeu	a4,s6,8000022a <consoleread+0xbc>
        cons.r--;
    80000276:	00011717          	auipc	a4,0x11
    8000027a:	64f72923          	sw	a5,1618(a4) # 800118c8 <cons+0x98>
    8000027e:	b775                	j	8000022a <consoleread+0xbc>

0000000080000280 <consputc>:
{
    80000280:	1141                	addi	sp,sp,-16
    80000282:	e406                	sd	ra,8(sp)
    80000284:	e022                	sd	s0,0(sp)
    80000286:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000288:	10000793          	li	a5,256
    8000028c:	00f50a63          	beq	a0,a5,800002a0 <consputc+0x20>
    uartputc_sync(c);
    80000290:	00000097          	auipc	ra,0x0
    80000294:	55e080e7          	jalr	1374(ra) # 800007ee <uartputc_sync>
}
    80000298:	60a2                	ld	ra,8(sp)
    8000029a:	6402                	ld	s0,0(sp)
    8000029c:	0141                	addi	sp,sp,16
    8000029e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a0:	4521                	li	a0,8
    800002a2:	00000097          	auipc	ra,0x0
    800002a6:	54c080e7          	jalr	1356(ra) # 800007ee <uartputc_sync>
    800002aa:	02000513          	li	a0,32
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	540080e7          	jalr	1344(ra) # 800007ee <uartputc_sync>
    800002b6:	4521                	li	a0,8
    800002b8:	00000097          	auipc	ra,0x0
    800002bc:	536080e7          	jalr	1334(ra) # 800007ee <uartputc_sync>
    800002c0:	bfe1                	j	80000298 <consputc+0x18>

00000000800002c2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c2:	1101                	addi	sp,sp,-32
    800002c4:	ec06                	sd	ra,24(sp)
    800002c6:	e822                	sd	s0,16(sp)
    800002c8:	e426                	sd	s1,8(sp)
    800002ca:	e04a                	sd	s2,0(sp)
    800002cc:	1000                	addi	s0,sp,32
    800002ce:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d0:	00011517          	auipc	a0,0x11
    800002d4:	56050513          	addi	a0,a0,1376 # 80011830 <cons>
    800002d8:	00001097          	auipc	ra,0x1
    800002dc:	926080e7          	jalr	-1754(ra) # 80000bfe <acquire>

  switch(c){
    800002e0:	47d5                	li	a5,21
    800002e2:	0af48663          	beq	s1,a5,8000038e <consoleintr+0xcc>
    800002e6:	0297ca63          	blt	a5,s1,8000031a <consoleintr+0x58>
    800002ea:	47a1                	li	a5,8
    800002ec:	0ef48763          	beq	s1,a5,800003da <consoleintr+0x118>
    800002f0:	47c1                	li	a5,16
    800002f2:	10f49a63          	bne	s1,a5,80000406 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f6:	00002097          	auipc	ra,0x2
    800002fa:	1ba080e7          	jalr	442(ra) # 800024b0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fe:	00011517          	auipc	a0,0x11
    80000302:	53250513          	addi	a0,a0,1330 # 80011830 <cons>
    80000306:	00001097          	auipc	ra,0x1
    8000030a:	9ac080e7          	jalr	-1620(ra) # 80000cb2 <release>
}
    8000030e:	60e2                	ld	ra,24(sp)
    80000310:	6442                	ld	s0,16(sp)
    80000312:	64a2                	ld	s1,8(sp)
    80000314:	6902                	ld	s2,0(sp)
    80000316:	6105                	addi	sp,sp,32
    80000318:	8082                	ret
  switch(c){
    8000031a:	07f00793          	li	a5,127
    8000031e:	0af48e63          	beq	s1,a5,800003da <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000322:	00011717          	auipc	a4,0x11
    80000326:	50e70713          	addi	a4,a4,1294 # 80011830 <cons>
    8000032a:	0a072783          	lw	a5,160(a4)
    8000032e:	09872703          	lw	a4,152(a4)
    80000332:	9f99                	subw	a5,a5,a4
    80000334:	07f00713          	li	a4,127
    80000338:	fcf763e3          	bltu	a4,a5,800002fe <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033c:	47b5                	li	a5,13
    8000033e:	0cf48763          	beq	s1,a5,8000040c <consoleintr+0x14a>
      consputc(c);
    80000342:	8526                	mv	a0,s1
    80000344:	00000097          	auipc	ra,0x0
    80000348:	f3c080e7          	jalr	-196(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034c:	00011797          	auipc	a5,0x11
    80000350:	4e478793          	addi	a5,a5,1252 # 80011830 <cons>
    80000354:	0a07a703          	lw	a4,160(a5)
    80000358:	0017069b          	addiw	a3,a4,1
    8000035c:	0006861b          	sext.w	a2,a3
    80000360:	0ad7a023          	sw	a3,160(a5)
    80000364:	07f77713          	andi	a4,a4,127
    80000368:	97ba                	add	a5,a5,a4
    8000036a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036e:	47a9                	li	a5,10
    80000370:	0cf48563          	beq	s1,a5,8000043a <consoleintr+0x178>
    80000374:	4791                	li	a5,4
    80000376:	0cf48263          	beq	s1,a5,8000043a <consoleintr+0x178>
    8000037a:	00011797          	auipc	a5,0x11
    8000037e:	54e7a783          	lw	a5,1358(a5) # 800118c8 <cons+0x98>
    80000382:	0807879b          	addiw	a5,a5,128
    80000386:	f6f61ce3          	bne	a2,a5,800002fe <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000038a:	863e                	mv	a2,a5
    8000038c:	a07d                	j	8000043a <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038e:	00011717          	auipc	a4,0x11
    80000392:	4a270713          	addi	a4,a4,1186 # 80011830 <cons>
    80000396:	0a072783          	lw	a5,160(a4)
    8000039a:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039e:	00011497          	auipc	s1,0x11
    800003a2:	49248493          	addi	s1,s1,1170 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a6:	4929                	li	s2,10
    800003a8:	f4f70be3          	beq	a4,a5,800002fe <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	37fd                	addiw	a5,a5,-1
    800003ae:	07f7f713          	andi	a4,a5,127
    800003b2:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b4:	01874703          	lbu	a4,24(a4)
    800003b8:	f52703e3          	beq	a4,s2,800002fe <consoleintr+0x3c>
      cons.e--;
    800003bc:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c0:	10000513          	li	a0,256
    800003c4:	00000097          	auipc	ra,0x0
    800003c8:	ebc080e7          	jalr	-324(ra) # 80000280 <consputc>
    while(cons.e != cons.w &&
    800003cc:	0a04a783          	lw	a5,160(s1)
    800003d0:	09c4a703          	lw	a4,156(s1)
    800003d4:	fcf71ce3          	bne	a4,a5,800003ac <consoleintr+0xea>
    800003d8:	b71d                	j	800002fe <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003da:	00011717          	auipc	a4,0x11
    800003de:	45670713          	addi	a4,a4,1110 # 80011830 <cons>
    800003e2:	0a072783          	lw	a5,160(a4)
    800003e6:	09c72703          	lw	a4,156(a4)
    800003ea:	f0f70ae3          	beq	a4,a5,800002fe <consoleintr+0x3c>
      cons.e--;
    800003ee:	37fd                	addiw	a5,a5,-1
    800003f0:	00011717          	auipc	a4,0x11
    800003f4:	4ef72023          	sw	a5,1248(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f8:	10000513          	li	a0,256
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e84080e7          	jalr	-380(ra) # 80000280 <consputc>
    80000404:	bded                	j	800002fe <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000406:	ee048ce3          	beqz	s1,800002fe <consoleintr+0x3c>
    8000040a:	bf21                	j	80000322 <consoleintr+0x60>
      consputc(c);
    8000040c:	4529                	li	a0,10
    8000040e:	00000097          	auipc	ra,0x0
    80000412:	e72080e7          	jalr	-398(ra) # 80000280 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000416:	00011797          	auipc	a5,0x11
    8000041a:	41a78793          	addi	a5,a5,1050 # 80011830 <cons>
    8000041e:	0a07a703          	lw	a4,160(a5)
    80000422:	0017069b          	addiw	a3,a4,1
    80000426:	0006861b          	sext.w	a2,a3
    8000042a:	0ad7a023          	sw	a3,160(a5)
    8000042e:	07f77713          	andi	a4,a4,127
    80000432:	97ba                	add	a5,a5,a4
    80000434:	4729                	li	a4,10
    80000436:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043a:	00011797          	auipc	a5,0x11
    8000043e:	48c7a923          	sw	a2,1170(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000442:	00011517          	auipc	a0,0x11
    80000446:	48650513          	addi	a0,a0,1158 # 800118c8 <cons+0x98>
    8000044a:	00002097          	auipc	ra,0x2
    8000044e:	ee0080e7          	jalr	-288(ra) # 8000232a <wakeup>
    80000452:	b575                	j	800002fe <consoleintr+0x3c>

0000000080000454 <consoleinit>:

void
consoleinit(void)
{
    80000454:	1141                	addi	sp,sp,-16
    80000456:	e406                	sd	ra,8(sp)
    80000458:	e022                	sd	s0,0(sp)
    8000045a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045c:	00008597          	auipc	a1,0x8
    80000460:	bb458593          	addi	a1,a1,-1100 # 80008010 <etext+0x10>
    80000464:	00011517          	auipc	a0,0x11
    80000468:	3cc50513          	addi	a0,a0,972 # 80011830 <cons>
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	702080e7          	jalr	1794(ra) # 80000b6e <initlock>

  uartinit();
    80000474:	00000097          	auipc	ra,0x0
    80000478:	32a080e7          	jalr	810(ra) # 8000079e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047c:	00021797          	auipc	a5,0x21
    80000480:	53478793          	addi	a5,a5,1332 # 800219b0 <devsw>
    80000484:	00000717          	auipc	a4,0x0
    80000488:	cea70713          	addi	a4,a4,-790 # 8000016e <consoleread>
    8000048c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048e:	00000717          	auipc	a4,0x0
    80000492:	c5e70713          	addi	a4,a4,-930 # 800000ec <consolewrite>
    80000496:	ef98                	sd	a4,24(a5)
}
    80000498:	60a2                	ld	ra,8(sp)
    8000049a:	6402                	ld	s0,0(sp)
    8000049c:	0141                	addi	sp,sp,16
    8000049e:	8082                	ret

00000000800004a0 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a0:	7179                	addi	sp,sp,-48
    800004a2:	f406                	sd	ra,40(sp)
    800004a4:	f022                	sd	s0,32(sp)
    800004a6:	ec26                	sd	s1,24(sp)
    800004a8:	e84a                	sd	s2,16(sp)
    800004aa:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ac:	c219                	beqz	a2,800004b2 <printint+0x12>
    800004ae:	08054663          	bltz	a0,8000053a <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b2:	2501                	sext.w	a0,a0
    800004b4:	4881                	li	a7,0
    800004b6:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ba:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004bc:	2581                	sext.w	a1,a1
    800004be:	00008617          	auipc	a2,0x8
    800004c2:	b8260613          	addi	a2,a2,-1150 # 80008040 <digits>
    800004c6:	883a                	mv	a6,a4
    800004c8:	2705                	addiw	a4,a4,1
    800004ca:	02b577bb          	remuw	a5,a0,a1
    800004ce:	1782                	slli	a5,a5,0x20
    800004d0:	9381                	srli	a5,a5,0x20
    800004d2:	97b2                	add	a5,a5,a2
    800004d4:	0007c783          	lbu	a5,0(a5)
    800004d8:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004dc:	0005079b          	sext.w	a5,a0
    800004e0:	02b5553b          	divuw	a0,a0,a1
    800004e4:	0685                	addi	a3,a3,1
    800004e6:	feb7f0e3          	bgeu	a5,a1,800004c6 <printint+0x26>

  if(sign)
    800004ea:	00088b63          	beqz	a7,80000500 <printint+0x60>
    buf[i++] = '-';
    800004ee:	fe040793          	addi	a5,s0,-32
    800004f2:	973e                	add	a4,a4,a5
    800004f4:	02d00793          	li	a5,45
    800004f8:	fef70823          	sb	a5,-16(a4)
    800004fc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000500:	02e05763          	blez	a4,8000052e <printint+0x8e>
    80000504:	fd040793          	addi	a5,s0,-48
    80000508:	00e784b3          	add	s1,a5,a4
    8000050c:	fff78913          	addi	s2,a5,-1
    80000510:	993a                	add	s2,s2,a4
    80000512:	377d                	addiw	a4,a4,-1
    80000514:	1702                	slli	a4,a4,0x20
    80000516:	9301                	srli	a4,a4,0x20
    80000518:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051c:	fff4c503          	lbu	a0,-1(s1)
    80000520:	00000097          	auipc	ra,0x0
    80000524:	d60080e7          	jalr	-672(ra) # 80000280 <consputc>
  while(--i >= 0)
    80000528:	14fd                	addi	s1,s1,-1
    8000052a:	ff2499e3          	bne	s1,s2,8000051c <printint+0x7c>
}
    8000052e:	70a2                	ld	ra,40(sp)
    80000530:	7402                	ld	s0,32(sp)
    80000532:	64e2                	ld	s1,24(sp)
    80000534:	6942                	ld	s2,16(sp)
    80000536:	6145                	addi	sp,sp,48
    80000538:	8082                	ret
    x = -xx;
    8000053a:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053e:	4885                	li	a7,1
    x = -xx;
    80000540:	bf9d                	j	800004b6 <printint+0x16>

0000000080000542 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000542:	1101                	addi	sp,sp,-32
    80000544:	ec06                	sd	ra,24(sp)
    80000546:	e822                	sd	s0,16(sp)
    80000548:	e426                	sd	s1,8(sp)
    8000054a:	1000                	addi	s0,sp,32
    8000054c:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054e:	00011797          	auipc	a5,0x11
    80000552:	3a07a123          	sw	zero,930(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000556:	00008517          	auipc	a0,0x8
    8000055a:	ac250513          	addi	a0,a0,-1342 # 80008018 <etext+0x18>
    8000055e:	00000097          	auipc	ra,0x0
    80000562:	02e080e7          	jalr	46(ra) # 8000058c <printf>
  printf(s);
    80000566:	8526                	mv	a0,s1
    80000568:	00000097          	auipc	ra,0x0
    8000056c:	024080e7          	jalr	36(ra) # 8000058c <printf>
  printf("\n");
    80000570:	00008517          	auipc	a0,0x8
    80000574:	b7850513          	addi	a0,a0,-1160 # 800080e8 <digits+0xa8>
    80000578:	00000097          	auipc	ra,0x0
    8000057c:	014080e7          	jalr	20(ra) # 8000058c <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000580:	4785                	li	a5,1
    80000582:	00009717          	auipc	a4,0x9
    80000586:	a6f72f23          	sw	a5,-1410(a4) # 80009000 <panicked>
  for(;;)
    8000058a:	a001                	j	8000058a <panic+0x48>

000000008000058c <printf>:
{
    8000058c:	7131                	addi	sp,sp,-192
    8000058e:	fc86                	sd	ra,120(sp)
    80000590:	f8a2                	sd	s0,112(sp)
    80000592:	f4a6                	sd	s1,104(sp)
    80000594:	f0ca                	sd	s2,96(sp)
    80000596:	ecce                	sd	s3,88(sp)
    80000598:	e8d2                	sd	s4,80(sp)
    8000059a:	e4d6                	sd	s5,72(sp)
    8000059c:	e0da                	sd	s6,64(sp)
    8000059e:	fc5e                	sd	s7,56(sp)
    800005a0:	f862                	sd	s8,48(sp)
    800005a2:	f466                	sd	s9,40(sp)
    800005a4:	f06a                	sd	s10,32(sp)
    800005a6:	ec6e                	sd	s11,24(sp)
    800005a8:	0100                	addi	s0,sp,128
    800005aa:	8a2a                	mv	s4,a0
    800005ac:	e40c                	sd	a1,8(s0)
    800005ae:	e810                	sd	a2,16(s0)
    800005b0:	ec14                	sd	a3,24(s0)
    800005b2:	f018                	sd	a4,32(s0)
    800005b4:	f41c                	sd	a5,40(s0)
    800005b6:	03043823          	sd	a6,48(s0)
    800005ba:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005be:	00011d97          	auipc	s11,0x11
    800005c2:	332dad83          	lw	s11,818(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c6:	020d9b63          	bnez	s11,800005fc <printf+0x70>
  if (fmt == 0)
    800005ca:	040a0263          	beqz	s4,8000060e <printf+0x82>
  va_start(ap, fmt);
    800005ce:	00840793          	addi	a5,s0,8
    800005d2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d6:	000a4503          	lbu	a0,0(s4)
    800005da:	14050f63          	beqz	a0,80000738 <printf+0x1ac>
    800005de:	4981                	li	s3,0
    if(c != '%'){
    800005e0:	02500a93          	li	s5,37
    switch(c){
    800005e4:	07000b93          	li	s7,112
  consputc('x');
    800005e8:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ea:	00008b17          	auipc	s6,0x8
    800005ee:	a56b0b13          	addi	s6,s6,-1450 # 80008040 <digits>
    switch(c){
    800005f2:	07300c93          	li	s9,115
    800005f6:	06400c13          	li	s8,100
    800005fa:	a82d                	j	80000634 <printf+0xa8>
    acquire(&pr.lock);
    800005fc:	00011517          	auipc	a0,0x11
    80000600:	2dc50513          	addi	a0,a0,732 # 800118d8 <pr>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	5fa080e7          	jalr	1530(ra) # 80000bfe <acquire>
    8000060c:	bf7d                	j	800005ca <printf+0x3e>
    panic("null fmt");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a1a50513          	addi	a0,a0,-1510 # 80008028 <etext+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	f2c080e7          	jalr	-212(ra) # 80000542 <panic>
      consputc(c);
    8000061e:	00000097          	auipc	ra,0x0
    80000622:	c62080e7          	jalr	-926(ra) # 80000280 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000626:	2985                	addiw	s3,s3,1
    80000628:	013a07b3          	add	a5,s4,s3
    8000062c:	0007c503          	lbu	a0,0(a5)
    80000630:	10050463          	beqz	a0,80000738 <printf+0x1ac>
    if(c != '%'){
    80000634:	ff5515e3          	bne	a0,s5,8000061e <printf+0x92>
    c = fmt[++i] & 0xff;
    80000638:	2985                	addiw	s3,s3,1
    8000063a:	013a07b3          	add	a5,s4,s3
    8000063e:	0007c783          	lbu	a5,0(a5)
    80000642:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000646:	cbed                	beqz	a5,80000738 <printf+0x1ac>
    switch(c){
    80000648:	05778a63          	beq	a5,s7,8000069c <printf+0x110>
    8000064c:	02fbf663          	bgeu	s7,a5,80000678 <printf+0xec>
    80000650:	09978863          	beq	a5,s9,800006e0 <printf+0x154>
    80000654:	07800713          	li	a4,120
    80000658:	0ce79563          	bne	a5,a4,80000722 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065c:	f8843783          	ld	a5,-120(s0)
    80000660:	00878713          	addi	a4,a5,8
    80000664:	f8e43423          	sd	a4,-120(s0)
    80000668:	4605                	li	a2,1
    8000066a:	85ea                	mv	a1,s10
    8000066c:	4388                	lw	a0,0(a5)
    8000066e:	00000097          	auipc	ra,0x0
    80000672:	e32080e7          	jalr	-462(ra) # 800004a0 <printint>
      break;
    80000676:	bf45                	j	80000626 <printf+0x9a>
    switch(c){
    80000678:	09578f63          	beq	a5,s5,80000716 <printf+0x18a>
    8000067c:	0b879363          	bne	a5,s8,80000722 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000680:	f8843783          	ld	a5,-120(s0)
    80000684:	00878713          	addi	a4,a5,8
    80000688:	f8e43423          	sd	a4,-120(s0)
    8000068c:	4605                	li	a2,1
    8000068e:	45a9                	li	a1,10
    80000690:	4388                	lw	a0,0(a5)
    80000692:	00000097          	auipc	ra,0x0
    80000696:	e0e080e7          	jalr	-498(ra) # 800004a0 <printint>
      break;
    8000069a:	b771                	j	80000626 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069c:	f8843783          	ld	a5,-120(s0)
    800006a0:	00878713          	addi	a4,a5,8
    800006a4:	f8e43423          	sd	a4,-120(s0)
    800006a8:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006ac:	03000513          	li	a0,48
    800006b0:	00000097          	auipc	ra,0x0
    800006b4:	bd0080e7          	jalr	-1072(ra) # 80000280 <consputc>
  consputc('x');
    800006b8:	07800513          	li	a0,120
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bc4080e7          	jalr	-1084(ra) # 80000280 <consputc>
    800006c4:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c6:	03c95793          	srli	a5,s2,0x3c
    800006ca:	97da                	add	a5,a5,s6
    800006cc:	0007c503          	lbu	a0,0(a5)
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bb0080e7          	jalr	-1104(ra) # 80000280 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d8:	0912                	slli	s2,s2,0x4
    800006da:	34fd                	addiw	s1,s1,-1
    800006dc:	f4ed                	bnez	s1,800006c6 <printf+0x13a>
    800006de:	b7a1                	j	80000626 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	6384                	ld	s1,0(a5)
    800006ee:	cc89                	beqz	s1,80000708 <printf+0x17c>
      for(; *s; s++)
    800006f0:	0004c503          	lbu	a0,0(s1)
    800006f4:	d90d                	beqz	a0,80000626 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b8a080e7          	jalr	-1142(ra) # 80000280 <consputc>
      for(; *s; s++)
    800006fe:	0485                	addi	s1,s1,1
    80000700:	0004c503          	lbu	a0,0(s1)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x16a>
    80000706:	b705                	j	80000626 <printf+0x9a>
        s = "(null)";
    80000708:	00008497          	auipc	s1,0x8
    8000070c:	91848493          	addi	s1,s1,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x16a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b68080e7          	jalr	-1176(ra) # 80000280 <consputc>
      break;
    80000720:	b719                	j	80000626 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b5c080e7          	jalr	-1188(ra) # 80000280 <consputc>
      consputc(c);
    8000072c:	8526                	mv	a0,s1
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b52080e7          	jalr	-1198(ra) # 80000280 <consputc>
      break;
    80000736:	bdc5                	j	80000626 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1ce>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	550080e7          	jalr	1360(ra) # 80000cb2 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b0>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	3e6080e7          	jalr	998(ra) # 80000b6e <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079e:	1141                	addi	sp,sp,-16
    800007a0:	e406                	sd	ra,8(sp)
    800007a2:	e022                	sd	s0,0(sp)
    800007a4:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a6:	100007b7          	lui	a5,0x10000
    800007aa:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ae:	f8000713          	li	a4,-128
    800007b2:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b6:	470d                	li	a4,3
    800007b8:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007bc:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c0:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c4:	469d                	li	a3,7
    800007c6:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ca:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ce:	00008597          	auipc	a1,0x8
    800007d2:	88a58593          	addi	a1,a1,-1910 # 80008058 <digits+0x18>
    800007d6:	00011517          	auipc	a0,0x11
    800007da:	12250513          	addi	a0,a0,290 # 800118f8 <uart_tx_lock>
    800007de:	00000097          	auipc	ra,0x0
    800007e2:	390080e7          	jalr	912(ra) # 80000b6e <initlock>
}
    800007e6:	60a2                	ld	ra,8(sp)
    800007e8:	6402                	ld	s0,0(sp)
    800007ea:	0141                	addi	sp,sp,16
    800007ec:	8082                	ret

00000000800007ee <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ee:	1101                	addi	sp,sp,-32
    800007f0:	ec06                	sd	ra,24(sp)
    800007f2:	e822                	sd	s0,16(sp)
    800007f4:	e426                	sd	s1,8(sp)
    800007f6:	1000                	addi	s0,sp,32
    800007f8:	84aa                	mv	s1,a0
  push_off();
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	3b8080e7          	jalr	952(ra) # 80000bb2 <push_off>

  if(panicked){
    80000802:	00008797          	auipc	a5,0x8
    80000806:	7fe7a783          	lw	a5,2046(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080e:	c391                	beqz	a5,80000812 <uartputc_sync+0x24>
    for(;;)
    80000810:	a001                	j	80000810 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000816:	0207f793          	andi	a5,a5,32
    8000081a:	dfe5                	beqz	a5,80000812 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081c:	0ff4f513          	andi	a0,s1,255
    80000820:	100007b7          	lui	a5,0x10000
    80000824:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000828:	00000097          	auipc	ra,0x0
    8000082c:	42a080e7          	jalr	1066(ra) # 80000c52 <pop_off>
}
    80000830:	60e2                	ld	ra,24(sp)
    80000832:	6442                	ld	s0,16(sp)
    80000834:	64a2                	ld	s1,8(sp)
    80000836:	6105                	addi	sp,sp,32
    80000838:	8082                	ret

000000008000083a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7ca7a783          	lw	a5,1994(a5) # 80009004 <uart_tx_r>
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c672703          	lw	a4,1990(a4) # 80009008 <uart_tx_w>
    8000084a:	08f70063          	beq	a4,a5,800008ca <uartstart+0x90>
{
    8000084e:	7139                	addi	sp,sp,-64
    80000850:	fc06                	sd	ra,56(sp)
    80000852:	f822                	sd	s0,48(sp)
    80000854:	f426                	sd	s1,40(sp)
    80000856:	f04a                	sd	s2,32(sp)
    80000858:	ec4e                	sd	s3,24(sp)
    8000085a:	e852                	sd	s4,16(sp)
    8000085c:	e456                	sd	s5,8(sp)
    8000085e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000860:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000864:	00011a97          	auipc	s5,0x11
    80000868:	094a8a93          	addi	s5,s5,148 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086c:	00008497          	auipc	s1,0x8
    80000870:	79848493          	addi	s1,s1,1944 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000874:	00008a17          	auipc	s4,0x8
    80000878:	794a0a13          	addi	s4,s4,1940 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000880:	02077713          	andi	a4,a4,32
    80000884:	cb15                	beqz	a4,800008b8 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000886:	00fa8733          	add	a4,s5,a5
    8000088a:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088e:	2785                	addiw	a5,a5,1
    80000890:	41f7d71b          	sraiw	a4,a5,0x1f
    80000894:	01b7571b          	srliw	a4,a4,0x1b
    80000898:	9fb9                	addw	a5,a5,a4
    8000089a:	8bfd                	andi	a5,a5,31
    8000089c:	9f99                	subw	a5,a5,a4
    8000089e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	a88080e7          	jalr	-1400(ra) # 8000232a <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	409c                	lw	a5,0(s1)
    800008b0:	000a2703          	lw	a4,0(s4)
    800008b4:	fcf714e3          	bne	a4,a5,8000087c <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	01a50513          	addi	a0,a0,26 # 800118f8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	318080e7          	jalr	792(ra) # 80000bfe <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008fa:	00008697          	auipc	a3,0x8
    800008fe:	70e6a683          	lw	a3,1806(a3) # 80009008 <uart_tx_w>
    80000902:	0016879b          	addiw	a5,a3,1
    80000906:	41f7d71b          	sraiw	a4,a5,0x1f
    8000090a:	01b7571b          	srliw	a4,a4,0x1b
    8000090e:	9fb9                	addw	a5,a5,a4
    80000910:	8bfd                	andi	a5,a5,31
    80000912:	9f99                	subw	a5,a5,a4
    80000914:	00008717          	auipc	a4,0x8
    80000918:	6f072703          	lw	a4,1776(a4) # 80009004 <uart_tx_r>
    8000091c:	04f71363          	bne	a4,a5,80000962 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000920:	00011a17          	auipc	s4,0x11
    80000924:	fd8a0a13          	addi	s4,s4,-40 # 800118f8 <uart_tx_lock>
    80000928:	00008917          	auipc	s2,0x8
    8000092c:	6dc90913          	addi	s2,s2,1756 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000930:	00008997          	auipc	s3,0x8
    80000934:	6d898993          	addi	s3,s3,1752 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000938:	85d2                	mv	a1,s4
    8000093a:	854a                	mv	a0,s2
    8000093c:	00002097          	auipc	ra,0x2
    80000940:	86e080e7          	jalr	-1938(ra) # 800021aa <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	0009a683          	lw	a3,0(s3)
    80000948:	0016879b          	addiw	a5,a3,1
    8000094c:	41f7d71b          	sraiw	a4,a5,0x1f
    80000950:	01b7571b          	srliw	a4,a4,0x1b
    80000954:	9fb9                	addw	a5,a5,a4
    80000956:	8bfd                	andi	a5,a5,31
    80000958:	9f99                	subw	a5,a5,a4
    8000095a:	00092703          	lw	a4,0(s2)
    8000095e:	fcf70de3          	beq	a4,a5,80000938 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000962:	00011917          	auipc	s2,0x11
    80000966:	f9690913          	addi	s2,s2,-106 # 800118f8 <uart_tx_lock>
    8000096a:	96ca                	add	a3,a3,s2
    8000096c:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000970:	00008717          	auipc	a4,0x8
    80000974:	68f72c23          	sw	a5,1688(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000978:	00000097          	auipc	ra,0x0
    8000097c:	ec2080e7          	jalr	-318(ra) # 8000083a <uartstart>
      release(&uart_tx_lock);
    80000980:	854a                	mv	a0,s2
    80000982:	00000097          	auipc	ra,0x0
    80000986:	330080e7          	jalr	816(ra) # 80000cb2 <release>
}
    8000098a:	70a2                	ld	ra,40(sp)
    8000098c:	7402                	ld	s0,32(sp)
    8000098e:	64e2                	ld	s1,24(sp)
    80000990:	6942                	ld	s2,16(sp)
    80000992:	69a2                	ld	s3,8(sp)
    80000994:	6a02                	ld	s4,0(sp)
    80000996:	6145                	addi	sp,sp,48
    80000998:	8082                	ret

000000008000099a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000099a:	1141                	addi	sp,sp,-16
    8000099c:	e422                	sd	s0,8(sp)
    8000099e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009a0:	100007b7          	lui	a5,0x10000
    800009a4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a8:	8b85                	andi	a5,a5,1
    800009aa:	cb91                	beqz	a5,800009be <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ac:	100007b7          	lui	a5,0x10000
    800009b0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b8:	6422                	ld	s0,8(sp)
    800009ba:	0141                	addi	sp,sp,16
    800009bc:	8082                	ret
    return -1;
    800009be:	557d                	li	a0,-1
    800009c0:	bfe5                	j	800009b8 <uartgetc+0x1e>

00000000800009c2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c2:	1101                	addi	sp,sp,-32
    800009c4:	ec06                	sd	ra,24(sp)
    800009c6:	e822                	sd	s0,16(sp)
    800009c8:	e426                	sd	s1,8(sp)
    800009ca:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009cc:	54fd                	li	s1,-1
    800009ce:	a029                	j	800009d8 <uartintr+0x16>
      break;
    consoleintr(c);
    800009d0:	00000097          	auipc	ra,0x0
    800009d4:	8f2080e7          	jalr	-1806(ra) # 800002c2 <consoleintr>
    int c = uartgetc();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	fc2080e7          	jalr	-62(ra) # 8000099a <uartgetc>
    if(c == -1)
    800009e0:	fe9518e3          	bne	a0,s1,800009d0 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e4:	00011497          	auipc	s1,0x11
    800009e8:	f1448493          	addi	s1,s1,-236 # 800118f8 <uart_tx_lock>
    800009ec:	8526                	mv	a0,s1
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	210080e7          	jalr	528(ra) # 80000bfe <acquire>
  uartstart();
    800009f6:	00000097          	auipc	ra,0x0
    800009fa:	e44080e7          	jalr	-444(ra) # 8000083a <uartstart>
  release(&uart_tx_lock);
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2b2080e7          	jalr	690(ra) # 80000cb2 <release>
}
    80000a08:	60e2                	ld	ra,24(sp)
    80000a0a:	6442                	ld	s0,16(sp)
    80000a0c:	64a2                	ld	s1,8(sp)
    80000a0e:	6105                	addi	sp,sp,32
    80000a10:	8082                	ret

0000000080000a12 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a12:	1101                	addi	sp,sp,-32
    80000a14:	ec06                	sd	ra,24(sp)
    80000a16:	e822                	sd	s0,16(sp)
    80000a18:	e426                	sd	s1,8(sp)
    80000a1a:	e04a                	sd	s2,0(sp)
    80000a1c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1e:	03451793          	slli	a5,a0,0x34
    80000a22:	ebb9                	bnez	a5,80000a78 <kfree+0x66>
    80000a24:	84aa                	mv	s1,a0
    80000a26:	00025797          	auipc	a5,0x25
    80000a2a:	5da78793          	addi	a5,a5,1498 # 80026000 <end>
    80000a2e:	04f56563          	bltu	a0,a5,80000a78 <kfree+0x66>
    80000a32:	47c5                	li	a5,17
    80000a34:	07ee                	slli	a5,a5,0x1b
    80000a36:	04f57163          	bgeu	a0,a5,80000a78 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3a:	6605                	lui	a2,0x1
    80000a3c:	4585                	li	a1,1
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	2bc080e7          	jalr	700(ra) # 80000cfa <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00011917          	auipc	s2,0x11
    80000a4a:	eea90913          	addi	s2,s2,-278 # 80011930 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	1ae080e7          	jalr	430(ra) # 80000bfe <acquire>
  r->next = kmem.freelist;
    80000a58:	01893783          	ld	a5,24(s2)
    80000a5c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a62:	854a                	mv	a0,s2
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	24e080e7          	jalr	590(ra) # 80000cb2 <release>
}
    80000a6c:	60e2                	ld	ra,24(sp)
    80000a6e:	6442                	ld	s0,16(sp)
    80000a70:	64a2                	ld	s1,8(sp)
    80000a72:	6902                	ld	s2,0(sp)
    80000a74:	6105                	addi	sp,sp,32
    80000a76:	8082                	ret
    panic("kfree");
    80000a78:	00007517          	auipc	a0,0x7
    80000a7c:	5e850513          	addi	a0,a0,1512 # 80008060 <digits+0x20>
    80000a80:	00000097          	auipc	ra,0x0
    80000a84:	ac2080e7          	jalr	-1342(ra) # 80000542 <panic>

0000000080000a88 <freerange>:
{
    80000a88:	7179                	addi	sp,sp,-48
    80000a8a:	f406                	sd	ra,40(sp)
    80000a8c:	f022                	sd	s0,32(sp)
    80000a8e:	ec26                	sd	s1,24(sp)
    80000a90:	e84a                	sd	s2,16(sp)
    80000a92:	e44e                	sd	s3,8(sp)
    80000a94:	e052                	sd	s4,0(sp)
    80000a96:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a98:	6785                	lui	a5,0x1
    80000a9a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9e:	94aa                	add	s1,s1,a0
    80000aa0:	757d                	lui	a0,0xfffff
    80000aa2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	94be                	add	s1,s1,a5
    80000aa6:	0095ee63          	bltu	a1,s1,80000ac2 <freerange+0x3a>
    80000aaa:	892e                	mv	s2,a1
    kfree(p);
    80000aac:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aae:	6985                	lui	s3,0x1
    kfree(p);
    80000ab0:	01448533          	add	a0,s1,s4
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	f5e080e7          	jalr	-162(ra) # 80000a12 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000abc:	94ce                	add	s1,s1,s3
    80000abe:	fe9979e3          	bgeu	s2,s1,80000ab0 <freerange+0x28>
}
    80000ac2:	70a2                	ld	ra,40(sp)
    80000ac4:	7402                	ld	s0,32(sp)
    80000ac6:	64e2                	ld	s1,24(sp)
    80000ac8:	6942                	ld	s2,16(sp)
    80000aca:	69a2                	ld	s3,8(sp)
    80000acc:	6a02                	ld	s4,0(sp)
    80000ace:	6145                	addi	sp,sp,48
    80000ad0:	8082                	ret

0000000080000ad2 <kinit>:
{
    80000ad2:	1141                	addi	sp,sp,-16
    80000ad4:	e406                	sd	ra,8(sp)
    80000ad6:	e022                	sd	s0,0(sp)
    80000ad8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ada:	00007597          	auipc	a1,0x7
    80000ade:	58e58593          	addi	a1,a1,1422 # 80008068 <digits+0x28>
    80000ae2:	00011517          	auipc	a0,0x11
    80000ae6:	e4e50513          	addi	a0,a0,-434 # 80011930 <kmem>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	084080e7          	jalr	132(ra) # 80000b6e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af2:	45c5                	li	a1,17
    80000af4:	05ee                	slli	a1,a1,0x1b
    80000af6:	00025517          	auipc	a0,0x25
    80000afa:	50a50513          	addi	a0,a0,1290 # 80026000 <end>
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f8a080e7          	jalr	-118(ra) # 80000a88 <freerange>
}
    80000b06:	60a2                	ld	ra,8(sp)
    80000b08:	6402                	ld	s0,0(sp)
    80000b0a:	0141                	addi	sp,sp,16
    80000b0c:	8082                	ret

0000000080000b0e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0e:	1101                	addi	sp,sp,-32
    80000b10:	ec06                	sd	ra,24(sp)
    80000b12:	e822                	sd	s0,16(sp)
    80000b14:	e426                	sd	s1,8(sp)
    80000b16:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b18:	00011497          	auipc	s1,0x11
    80000b1c:	e1848493          	addi	s1,s1,-488 # 80011930 <kmem>
    80000b20:	8526                	mv	a0,s1
    80000b22:	00000097          	auipc	ra,0x0
    80000b26:	0dc080e7          	jalr	220(ra) # 80000bfe <acquire>
  r = kmem.freelist;
    80000b2a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2c:	c885                	beqz	s1,80000b5c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2e:	609c                	ld	a5,0(s1)
    80000b30:	00011517          	auipc	a0,0x11
    80000b34:	e0050513          	addi	a0,a0,-512 # 80011930 <kmem>
    80000b38:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	178080e7          	jalr	376(ra) # 80000cb2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b42:	6605                	lui	a2,0x1
    80000b44:	4595                	li	a1,5
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	1b2080e7          	jalr	434(ra) # 80000cfa <memset>
  return (void*)r;
}
    80000b50:	8526                	mv	a0,s1
    80000b52:	60e2                	ld	ra,24(sp)
    80000b54:	6442                	ld	s0,16(sp)
    80000b56:	64a2                	ld	s1,8(sp)
    80000b58:	6105                	addi	sp,sp,32
    80000b5a:	8082                	ret
  release(&kmem.lock);
    80000b5c:	00011517          	auipc	a0,0x11
    80000b60:	dd450513          	addi	a0,a0,-556 # 80011930 <kmem>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	14e080e7          	jalr	334(ra) # 80000cb2 <release>
  if(r)
    80000b6c:	b7d5                	j	80000b50 <kalloc+0x42>

0000000080000b6e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6e:	1141                	addi	sp,sp,-16
    80000b70:	e422                	sd	s0,8(sp)
    80000b72:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b74:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b76:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b7a:	00053823          	sd	zero,16(a0)
}
    80000b7e:	6422                	ld	s0,8(sp)
    80000b80:	0141                	addi	sp,sp,16
    80000b82:	8082                	ret

0000000080000b84 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b84:	411c                	lw	a5,0(a0)
    80000b86:	e399                	bnez	a5,80000b8c <holding+0x8>
    80000b88:	4501                	li	a0,0
  return r;
}
    80000b8a:	8082                	ret
{
    80000b8c:	1101                	addi	sp,sp,-32
    80000b8e:	ec06                	sd	ra,24(sp)
    80000b90:	e822                	sd	s0,16(sp)
    80000b92:	e426                	sd	s1,8(sp)
    80000b94:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	6904                	ld	s1,16(a0)
    80000b98:	00001097          	auipc	ra,0x1
    80000b9c:	e06080e7          	jalr	-506(ra) # 8000199e <mycpu>
    80000ba0:	40a48533          	sub	a0,s1,a0
    80000ba4:	00153513          	seqz	a0,a0
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret

0000000080000bb2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb2:	1101                	addi	sp,sp,-32
    80000bb4:	ec06                	sd	ra,24(sp)
    80000bb6:	e822                	sd	s0,16(sp)
    80000bb8:	e426                	sd	s1,8(sp)
    80000bba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bbc:	100024f3          	csrr	s1,sstatus
    80000bc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bca:	00001097          	auipc	ra,0x1
    80000bce:	dd4080e7          	jalr	-556(ra) # 8000199e <mycpu>
    80000bd2:	5d3c                	lw	a5,120(a0)
    80000bd4:	cf89                	beqz	a5,80000bee <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	dc8080e7          	jalr	-568(ra) # 8000199e <mycpu>
    80000bde:	5d3c                	lw	a5,120(a0)
    80000be0:	2785                	addiw	a5,a5,1
    80000be2:	dd3c                	sw	a5,120(a0)
}
    80000be4:	60e2                	ld	ra,24(sp)
    80000be6:	6442                	ld	s0,16(sp)
    80000be8:	64a2                	ld	s1,8(sp)
    80000bea:	6105                	addi	sp,sp,32
    80000bec:	8082                	ret
    mycpu()->intena = old;
    80000bee:	00001097          	auipc	ra,0x1
    80000bf2:	db0080e7          	jalr	-592(ra) # 8000199e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf6:	8085                	srli	s1,s1,0x1
    80000bf8:	8885                	andi	s1,s1,1
    80000bfa:	dd64                	sw	s1,124(a0)
    80000bfc:	bfe9                	j	80000bd6 <push_off+0x24>

0000000080000bfe <acquire>:
{
    80000bfe:	1101                	addi	sp,sp,-32
    80000c00:	ec06                	sd	ra,24(sp)
    80000c02:	e822                	sd	s0,16(sp)
    80000c04:	e426                	sd	s1,8(sp)
    80000c06:	1000                	addi	s0,sp,32
    80000c08:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c0a:	00000097          	auipc	ra,0x0
    80000c0e:	fa8080e7          	jalr	-88(ra) # 80000bb2 <push_off>
  if(holding(lk))
    80000c12:	8526                	mv	a0,s1
    80000c14:	00000097          	auipc	ra,0x0
    80000c18:	f70080e7          	jalr	-144(ra) # 80000b84 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1c:	4705                	li	a4,1
  if(holding(lk))
    80000c1e:	e115                	bnez	a0,80000c42 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c20:	87ba                	mv	a5,a4
    80000c22:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c26:	2781                	sext.w	a5,a5
    80000c28:	ffe5                	bnez	a5,80000c20 <acquire+0x22>
  __sync_synchronize();
    80000c2a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	d70080e7          	jalr	-656(ra) # 8000199e <mycpu>
    80000c36:	e888                	sd	a0,16(s1)
}
    80000c38:	60e2                	ld	ra,24(sp)
    80000c3a:	6442                	ld	s0,16(sp)
    80000c3c:	64a2                	ld	s1,8(sp)
    80000c3e:	6105                	addi	sp,sp,32
    80000c40:	8082                	ret
    panic("acquire");
    80000c42:	00007517          	auipc	a0,0x7
    80000c46:	42e50513          	addi	a0,a0,1070 # 80008070 <digits+0x30>
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	8f8080e7          	jalr	-1800(ra) # 80000542 <panic>

0000000080000c52 <pop_off>:

void
pop_off(void)
{
    80000c52:	1141                	addi	sp,sp,-16
    80000c54:	e406                	sd	ra,8(sp)
    80000c56:	e022                	sd	s0,0(sp)
    80000c58:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c5a:	00001097          	auipc	ra,0x1
    80000c5e:	d44080e7          	jalr	-700(ra) # 8000199e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c62:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c66:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c68:	e78d                	bnez	a5,80000c92 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c6a:	5d3c                	lw	a5,120(a0)
    80000c6c:	02f05b63          	blez	a5,80000ca2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c70:	37fd                	addiw	a5,a5,-1
    80000c72:	0007871b          	sext.w	a4,a5
    80000c76:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c78:	eb09                	bnez	a4,80000c8a <pop_off+0x38>
    80000c7a:	5d7c                	lw	a5,124(a0)
    80000c7c:	c799                	beqz	a5,80000c8a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c86:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c8a:	60a2                	ld	ra,8(sp)
    80000c8c:	6402                	ld	s0,0(sp)
    80000c8e:	0141                	addi	sp,sp,16
    80000c90:	8082                	ret
    panic("pop_off - interruptible");
    80000c92:	00007517          	auipc	a0,0x7
    80000c96:	3e650513          	addi	a0,a0,998 # 80008078 <digits+0x38>
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	8a8080e7          	jalr	-1880(ra) # 80000542 <panic>
    panic("pop_off");
    80000ca2:	00007517          	auipc	a0,0x7
    80000ca6:	3ee50513          	addi	a0,a0,1006 # 80008090 <digits+0x50>
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	898080e7          	jalr	-1896(ra) # 80000542 <panic>

0000000080000cb2 <release>:
{
    80000cb2:	1101                	addi	sp,sp,-32
    80000cb4:	ec06                	sd	ra,24(sp)
    80000cb6:	e822                	sd	s0,16(sp)
    80000cb8:	e426                	sd	s1,8(sp)
    80000cba:	1000                	addi	s0,sp,32
    80000cbc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	ec6080e7          	jalr	-314(ra) # 80000b84 <holding>
    80000cc6:	c115                	beqz	a0,80000cea <release+0x38>
  lk->cpu = 0;
    80000cc8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ccc:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cd0:	0f50000f          	fence	iorw,ow
    80000cd4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	f7a080e7          	jalr	-134(ra) # 80000c52 <pop_off>
}
    80000ce0:	60e2                	ld	ra,24(sp)
    80000ce2:	6442                	ld	s0,16(sp)
    80000ce4:	64a2                	ld	s1,8(sp)
    80000ce6:	6105                	addi	sp,sp,32
    80000ce8:	8082                	ret
    panic("release");
    80000cea:	00007517          	auipc	a0,0x7
    80000cee:	3ae50513          	addi	a0,a0,942 # 80008098 <digits+0x58>
    80000cf2:	00000097          	auipc	ra,0x0
    80000cf6:	850080e7          	jalr	-1968(ra) # 80000542 <panic>

0000000080000cfa <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cfa:	1141                	addi	sp,sp,-16
    80000cfc:	e422                	sd	s0,8(sp)
    80000cfe:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d00:	ca19                	beqz	a2,80000d16 <memset+0x1c>
    80000d02:	87aa                	mv	a5,a0
    80000d04:	1602                	slli	a2,a2,0x20
    80000d06:	9201                	srli	a2,a2,0x20
    80000d08:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d10:	0785                	addi	a5,a5,1
    80000d12:	fee79de3          	bne	a5,a4,80000d0c <memset+0x12>
  }
  return dst;
}
    80000d16:	6422                	ld	s0,8(sp)
    80000d18:	0141                	addi	sp,sp,16
    80000d1a:	8082                	ret

0000000080000d1c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1c:	1141                	addi	sp,sp,-16
    80000d1e:	e422                	sd	s0,8(sp)
    80000d20:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d22:	ca05                	beqz	a2,80000d52 <memcmp+0x36>
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	1682                	slli	a3,a3,0x20
    80000d2a:	9281                	srli	a3,a3,0x20
    80000d2c:	0685                	addi	a3,a3,1
    80000d2e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d30:	00054783          	lbu	a5,0(a0)
    80000d34:	0005c703          	lbu	a4,0(a1)
    80000d38:	00e79863          	bne	a5,a4,80000d48 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3c:	0505                	addi	a0,a0,1
    80000d3e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d40:	fed518e3          	bne	a0,a3,80000d30 <memcmp+0x14>
  }

  return 0;
    80000d44:	4501                	li	a0,0
    80000d46:	a019                	j	80000d4c <memcmp+0x30>
      return *s1 - *s2;
    80000d48:	40e7853b          	subw	a0,a5,a4
}
    80000d4c:	6422                	ld	s0,8(sp)
    80000d4e:	0141                	addi	sp,sp,16
    80000d50:	8082                	ret
  return 0;
    80000d52:	4501                	li	a0,0
    80000d54:	bfe5                	j	80000d4c <memcmp+0x30>

0000000080000d56 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5c:	02a5e563          	bltu	a1,a0,80000d86 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6069b          	addiw	a3,a2,-1
    80000d64:	ce11                	beqz	a2,80000d80 <memmove+0x2a>
    80000d66:	1682                	slli	a3,a3,0x20
    80000d68:	9281                	srli	a3,a3,0x20
    80000d6a:	0685                	addi	a3,a3,1
    80000d6c:	96ae                	add	a3,a3,a1
    80000d6e:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d70:	0585                	addi	a1,a1,1
    80000d72:	0785                	addi	a5,a5,1
    80000d74:	fff5c703          	lbu	a4,-1(a1)
    80000d78:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7c:	fed59ae3          	bne	a1,a3,80000d70 <memmove+0x1a>

  return dst;
}
    80000d80:	6422                	ld	s0,8(sp)
    80000d82:	0141                	addi	sp,sp,16
    80000d84:	8082                	ret
  if(s < d && s + n > d){
    80000d86:	02061713          	slli	a4,a2,0x20
    80000d8a:	9301                	srli	a4,a4,0x20
    80000d8c:	00e587b3          	add	a5,a1,a4
    80000d90:	fcf578e3          	bgeu	a0,a5,80000d60 <memmove+0xa>
    d += n;
    80000d94:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d96:	fff6069b          	addiw	a3,a2,-1
    80000d9a:	d27d                	beqz	a2,80000d80 <memmove+0x2a>
    80000d9c:	02069613          	slli	a2,a3,0x20
    80000da0:	9201                	srli	a2,a2,0x20
    80000da2:	fff64613          	not	a2,a2
    80000da6:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da8:	17fd                	addi	a5,a5,-1
    80000daa:	177d                	addi	a4,a4,-1
    80000dac:	0007c683          	lbu	a3,0(a5)
    80000db0:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db4:	fef61ae3          	bne	a2,a5,80000da8 <memmove+0x52>
    80000db8:	b7e1                	j	80000d80 <memmove+0x2a>

0000000080000dba <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dba:	1141                	addi	sp,sp,-16
    80000dbc:	e406                	sd	ra,8(sp)
    80000dbe:	e022                	sd	s0,0(sp)
    80000dc0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc2:	00000097          	auipc	ra,0x0
    80000dc6:	f94080e7          	jalr	-108(ra) # 80000d56 <memmove>
}
    80000dca:	60a2                	ld	ra,8(sp)
    80000dcc:	6402                	ld	s0,0(sp)
    80000dce:	0141                	addi	sp,sp,16
    80000dd0:	8082                	ret

0000000080000dd2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd8:	ce11                	beqz	a2,80000df4 <strncmp+0x22>
    80000dda:	00054783          	lbu	a5,0(a0)
    80000dde:	cf89                	beqz	a5,80000df8 <strncmp+0x26>
    80000de0:	0005c703          	lbu	a4,0(a1)
    80000de4:	00f71a63          	bne	a4,a5,80000df8 <strncmp+0x26>
    n--, p++, q++;
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	0505                	addi	a0,a0,1
    80000dec:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dee:	f675                	bnez	a2,80000dda <strncmp+0x8>
  if(n == 0)
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	a809                	j	80000e04 <strncmp+0x32>
    80000df4:	4501                	li	a0,0
    80000df6:	a039                	j	80000e04 <strncmp+0x32>
  if(n == 0)
    80000df8:	ca09                	beqz	a2,80000e0a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dfa:	00054503          	lbu	a0,0(a0)
    80000dfe:	0005c783          	lbu	a5,0(a1)
    80000e02:	9d1d                	subw	a0,a0,a5
}
    80000e04:	6422                	ld	s0,8(sp)
    80000e06:	0141                	addi	sp,sp,16
    80000e08:	8082                	ret
    return 0;
    80000e0a:	4501                	li	a0,0
    80000e0c:	bfe5                	j	80000e04 <strncmp+0x32>

0000000080000e0e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0e:	1141                	addi	sp,sp,-16
    80000e10:	e422                	sd	s0,8(sp)
    80000e12:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e14:	872a                	mv	a4,a0
    80000e16:	8832                	mv	a6,a2
    80000e18:	367d                	addiw	a2,a2,-1
    80000e1a:	01005963          	blez	a6,80000e2c <strncpy+0x1e>
    80000e1e:	0705                	addi	a4,a4,1
    80000e20:	0005c783          	lbu	a5,0(a1)
    80000e24:	fef70fa3          	sb	a5,-1(a4)
    80000e28:	0585                	addi	a1,a1,1
    80000e2a:	f7f5                	bnez	a5,80000e16 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2c:	86ba                	mv	a3,a4
    80000e2e:	00c05c63          	blez	a2,80000e46 <strncpy+0x38>
    *s++ = 0;
    80000e32:	0685                	addi	a3,a3,1
    80000e34:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e38:	fff6c793          	not	a5,a3
    80000e3c:	9fb9                	addw	a5,a5,a4
    80000e3e:	010787bb          	addw	a5,a5,a6
    80000e42:	fef048e3          	bgtz	a5,80000e32 <strncpy+0x24>
  return os;
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret

0000000080000e4c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4c:	1141                	addi	sp,sp,-16
    80000e4e:	e422                	sd	s0,8(sp)
    80000e50:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e52:	02c05363          	blez	a2,80000e78 <safestrcpy+0x2c>
    80000e56:	fff6069b          	addiw	a3,a2,-1
    80000e5a:	1682                	slli	a3,a3,0x20
    80000e5c:	9281                	srli	a3,a3,0x20
    80000e5e:	96ae                	add	a3,a3,a1
    80000e60:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e62:	00d58963          	beq	a1,a3,80000e74 <safestrcpy+0x28>
    80000e66:	0585                	addi	a1,a1,1
    80000e68:	0785                	addi	a5,a5,1
    80000e6a:	fff5c703          	lbu	a4,-1(a1)
    80000e6e:	fee78fa3          	sb	a4,-1(a5)
    80000e72:	fb65                	bnez	a4,80000e62 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e74:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e78:	6422                	ld	s0,8(sp)
    80000e7a:	0141                	addi	sp,sp,16
    80000e7c:	8082                	ret

0000000080000e7e <strlen>:

int
strlen(const char *s)
{
    80000e7e:	1141                	addi	sp,sp,-16
    80000e80:	e422                	sd	s0,8(sp)
    80000e82:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e84:	00054783          	lbu	a5,0(a0)
    80000e88:	cf91                	beqz	a5,80000ea4 <strlen+0x26>
    80000e8a:	0505                	addi	a0,a0,1
    80000e8c:	87aa                	mv	a5,a0
    80000e8e:	4685                	li	a3,1
    80000e90:	9e89                	subw	a3,a3,a0
    80000e92:	00f6853b          	addw	a0,a3,a5
    80000e96:	0785                	addi	a5,a5,1
    80000e98:	fff7c703          	lbu	a4,-1(a5)
    80000e9c:	fb7d                	bnez	a4,80000e92 <strlen+0x14>
    ;
  return n;
}
    80000e9e:	6422                	ld	s0,8(sp)
    80000ea0:	0141                	addi	sp,sp,16
    80000ea2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea4:	4501                	li	a0,0
    80000ea6:	bfe5                	j	80000e9e <strlen+0x20>

0000000080000ea8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e406                	sd	ra,8(sp)
    80000eac:	e022                	sd	s0,0(sp)
    80000eae:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eb0:	00001097          	auipc	ra,0x1
    80000eb4:	ade080e7          	jalr	-1314(ra) # 8000198e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb8:	00008717          	auipc	a4,0x8
    80000ebc:	15470713          	addi	a4,a4,340 # 8000900c <started>
  if(cpuid() == 0){
    80000ec0:	c139                	beqz	a0,80000f06 <main+0x5e>
    while(started == 0)
    80000ec2:	431c                	lw	a5,0(a4)
    80000ec4:	2781                	sext.w	a5,a5
    80000ec6:	dff5                	beqz	a5,80000ec2 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec8:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ecc:	00001097          	auipc	ra,0x1
    80000ed0:	ac2080e7          	jalr	-1342(ra) # 8000198e <cpuid>
    80000ed4:	85aa                	mv	a1,a0
    80000ed6:	00007517          	auipc	a0,0x7
    80000eda:	20250513          	addi	a0,a0,514 # 800080d8 <digits+0x98>
    80000ede:	fffff097          	auipc	ra,0xfffff
    80000ee2:	6ae080e7          	jalr	1710(ra) # 8000058c <printf>
    kvminithart();    // turn on paging
    80000ee6:	00000097          	auipc	ra,0x0
    80000eea:	0c8080e7          	jalr	200(ra) # 80000fae <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eee:	00001097          	auipc	ra,0x1
    80000ef2:	704080e7          	jalr	1796(ra) # 800025f2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef6:	00005097          	auipc	ra,0x5
    80000efa:	d8a080e7          	jalr	-630(ra) # 80005c80 <plicinithart>
  }

  scheduler();        
    80000efe:	00001097          	auipc	ra,0x1
    80000f02:	ff0080e7          	jalr	-16(ra) # 80001eee <scheduler>
    consoleinit();
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	54e080e7          	jalr	1358(ra) # 80000454 <consoleinit>
    printfinit();
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	85e080e7          	jalr	-1954(ra) # 8000076c <printfinit>
    printf("\n");
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	1d250513          	addi	a0,a0,466 # 800080e8 <digits+0xa8>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66e080e7          	jalr	1646(ra) # 8000058c <printf>
    printf("EEE3535 Operating Systems: booting xv6-riscv kernel\n");
    80000f26:	00007517          	auipc	a0,0x7
    80000f2a:	17a50513          	addi	a0,a0,378 # 800080a0 <digits+0x60>
    80000f2e:	fffff097          	auipc	ra,0xfffff
    80000f32:	65e080e7          	jalr	1630(ra) # 8000058c <printf>
    kinit();         // physical page allocator
    80000f36:	00000097          	auipc	ra,0x0
    80000f3a:	b9c080e7          	jalr	-1124(ra) # 80000ad2 <kinit>
    kvminit();       // create kernel page table
    80000f3e:	00000097          	auipc	ra,0x0
    80000f42:	2a0080e7          	jalr	672(ra) # 800011de <kvminit>
    kvminithart();   // turn on paging
    80000f46:	00000097          	auipc	ra,0x0
    80000f4a:	068080e7          	jalr	104(ra) # 80000fae <kvminithart>
    procinit();      // process table
    80000f4e:	00001097          	auipc	ra,0x1
    80000f52:	970080e7          	jalr	-1680(ra) # 800018be <procinit>
    trapinit();      // trap vectors
    80000f56:	00001097          	auipc	ra,0x1
    80000f5a:	674080e7          	jalr	1652(ra) # 800025ca <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5e:	00001097          	auipc	ra,0x1
    80000f62:	694080e7          	jalr	1684(ra) # 800025f2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	d04080e7          	jalr	-764(ra) # 80005c6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	d12080e7          	jalr	-750(ra) # 80005c80 <plicinithart>
    binit();         // buffer cache
    80000f76:	00002097          	auipc	ra,0x2
    80000f7a:	ebc080e7          	jalr	-324(ra) # 80002e32 <binit>
    iinit();         // inode cache
    80000f7e:	00002097          	auipc	ra,0x2
    80000f82:	54e080e7          	jalr	1358(ra) # 800034cc <iinit>
    fileinit();      // file table
    80000f86:	00003097          	auipc	ra,0x3
    80000f8a:	4ec080e7          	jalr	1260(ra) # 80004472 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8e:	00005097          	auipc	ra,0x5
    80000f92:	dfa080e7          	jalr	-518(ra) # 80005d88 <virtio_disk_init>
    userinit();      // first user process
    80000f96:	00001097          	auipc	ra,0x1
    80000f9a:	cee080e7          	jalr	-786(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f9e:	0ff0000f          	fence
    started = 1;
    80000fa2:	4785                	li	a5,1
    80000fa4:	00008717          	auipc	a4,0x8
    80000fa8:	06f72423          	sw	a5,104(a4) # 8000900c <started>
    80000fac:	bf89                	j	80000efe <main+0x56>

0000000080000fae <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fae:	1141                	addi	sp,sp,-16
    80000fb0:	e422                	sd	s0,8(sp)
    80000fb2:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	05c7b783          	ld	a5,92(a5) # 80009010 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0f850513          	addi	a0,a0,248 # 800080f0 <digits+0xb0>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	542080e7          	jalr	1346(ra) # 80000542 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if (*pte & PTE_V) {
        pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
        if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	b02080e7          	jalr	-1278(ra) # 80000b0e <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
            return 0;
        memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cde080e7          	jalr	-802(ra) # 80000cfa <memset>
        *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if (*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
        pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
            return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if (pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
      return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010ba:	1101                	addi	sp,sp,-32
    800010bc:	ec06                	sd	ra,24(sp)
    800010be:	e822                	sd	s0,16(sp)
    800010c0:	e426                	sd	s1,8(sp)
    800010c2:	1000                	addi	s0,sp,32
    800010c4:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010c6:	1552                	slli	a0,a0,0x34
    800010c8:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010cc:	4601                	li	a2,0
    800010ce:	00008517          	auipc	a0,0x8
    800010d2:	f4253503          	ld	a0,-190(a0) # 80009010 <kernel_pagetable>
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	efc080e7          	jalr	-260(ra) # 80000fd2 <walk>
  if(pte == 0)
    800010de:	cd09                	beqz	a0,800010f8 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010e0:	6108                	ld	a0,0(a0)
    800010e2:	00157793          	andi	a5,a0,1
    800010e6:	c38d                	beqz	a5,80001108 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010e8:	8129                	srli	a0,a0,0xa
    800010ea:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010ec:	9526                	add	a0,a0,s1
    800010ee:	60e2                	ld	ra,24(sp)
    800010f0:	6442                	ld	s0,16(sp)
    800010f2:	64a2                	ld	s1,8(sp)
    800010f4:	6105                	addi	sp,sp,32
    800010f6:	8082                	ret
    panic("kvmpa");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	00050513          	mv	a0,a0
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	442080e7          	jalr	1090(ra) # 80000542 <panic>
    panic("kvmpa");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	ff050513          	addi	a0,a0,-16 # 800080f8 <digits+0xb8>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	432080e7          	jalr	1074(ra) # 80000542 <panic>

0000000080001118 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001118:	715d                	addi	sp,sp,-80
    8000111a:	e486                	sd	ra,72(sp)
    8000111c:	e0a2                	sd	s0,64(sp)
    8000111e:	fc26                	sd	s1,56(sp)
    80001120:	f84a                	sd	s2,48(sp)
    80001122:	f44e                	sd	s3,40(sp)
    80001124:	f052                	sd	s4,32(sp)
    80001126:	ec56                	sd	s5,24(sp)
    80001128:	e85a                	sd	s6,16(sp)
    8000112a:	e45e                	sd	s7,8(sp)
    8000112c:	0880                	addi	s0,sp,80
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	167d                	addi	a2,a2,-1
    8000113a:	00b609b3          	add	s3,a2,a1
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	e7e080e7          	jalr	-386(ra) # 80000fd2 <walk>
    8000115c:	c51d                	beqz	a0,8000118a <mappages+0x72>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	andi	a5,a5,1
    80001162:	ef81                	bnez	a5,8000117a <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srli	s1,s1,0xc
    80001166:	04aa                	slli	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	ori	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	03390863          	beq	s2,s3,800011a2 <mappages+0x8a>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x32>
      panic("remap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f8650513          	addi	a0,a0,-122 # 80008100 <digits+0xc0>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c0080e7          	jalr	960(ra) # 80000542 <panic>
      return -1;
    8000118a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000118c:	60a6                	ld	ra,72(sp)
    8000118e:	6406                	ld	s0,64(sp)
    80001190:	74e2                	ld	s1,56(sp)
    80001192:	7942                	ld	s2,48(sp)
    80001194:	79a2                	ld	s3,40(sp)
    80001196:	7a02                	ld	s4,32(sp)
    80001198:	6ae2                	ld	s5,24(sp)
    8000119a:	6b42                	ld	s6,16(sp)
    8000119c:	6ba2                	ld	s7,8(sp)
    8000119e:	6161                	addi	sp,sp,80
    800011a0:	8082                	ret
  return 0;
    800011a2:	4501                	li	a0,0
    800011a4:	b7e5                	j	8000118c <mappages+0x74>

00000000800011a6 <kvmmap>:
{
    800011a6:	1141                	addi	sp,sp,-16
    800011a8:	e406                	sd	ra,8(sp)
    800011aa:	e022                	sd	s0,0(sp)
    800011ac:	0800                	addi	s0,sp,16
    800011ae:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011b0:	86ae                	mv	a3,a1
    800011b2:	85aa                	mv	a1,a0
    800011b4:	00008517          	auipc	a0,0x8
    800011b8:	e5c53503          	ld	a0,-420(a0) # 80009010 <kernel_pagetable>
    800011bc:	00000097          	auipc	ra,0x0
    800011c0:	f5c080e7          	jalr	-164(ra) # 80001118 <mappages>
    800011c4:	e509                	bnez	a0,800011ce <kvmmap+0x28>
}
    800011c6:	60a2                	ld	ra,8(sp)
    800011c8:	6402                	ld	s0,0(sp)
    800011ca:	0141                	addi	sp,sp,16
    800011cc:	8082                	ret
    panic("kvmmap");
    800011ce:	00007517          	auipc	a0,0x7
    800011d2:	f3a50513          	addi	a0,a0,-198 # 80008108 <digits+0xc8>
    800011d6:	fffff097          	auipc	ra,0xfffff
    800011da:	36c080e7          	jalr	876(ra) # 80000542 <panic>

00000000800011de <kvminit>:
{
    800011de:	1101                	addi	sp,sp,-32
    800011e0:	ec06                	sd	ra,24(sp)
    800011e2:	e822                	sd	s0,16(sp)
    800011e4:	e426                	sd	s1,8(sp)
    800011e6:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	926080e7          	jalr	-1754(ra) # 80000b0e <kalloc>
    800011f0:	00008797          	auipc	a5,0x8
    800011f4:	e2a7b023          	sd	a0,-480(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800011f8:	6605                	lui	a2,0x1
    800011fa:	4581                	li	a1,0
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	afe080e7          	jalr	-1282(ra) # 80000cfa <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001204:	4699                	li	a3,6
    80001206:	6605                	lui	a2,0x1
    80001208:	100005b7          	lui	a1,0x10000
    8000120c:	10000537          	lui	a0,0x10000
    80001210:	00000097          	auipc	ra,0x0
    80001214:	f96080e7          	jalr	-106(ra) # 800011a6 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001218:	4699                	li	a3,6
    8000121a:	6605                	lui	a2,0x1
    8000121c:	100015b7          	lui	a1,0x10001
    80001220:	10001537          	lui	a0,0x10001
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f82080e7          	jalr	-126(ra) # 800011a6 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000122c:	4699                	li	a3,6
    8000122e:	6641                	lui	a2,0x10
    80001230:	020005b7          	lui	a1,0x2000
    80001234:	02000537          	lui	a0,0x2000
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	f6e080e7          	jalr	-146(ra) # 800011a6 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001240:	4699                	li	a3,6
    80001242:	00400637          	lui	a2,0x400
    80001246:	0c0005b7          	lui	a1,0xc000
    8000124a:	0c000537          	lui	a0,0xc000
    8000124e:	00000097          	auipc	ra,0x0
    80001252:	f58080e7          	jalr	-168(ra) # 800011a6 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001256:	00007497          	auipc	s1,0x7
    8000125a:	daa48493          	addi	s1,s1,-598 # 80008000 <etext>
    8000125e:	46a9                	li	a3,10
    80001260:	80007617          	auipc	a2,0x80007
    80001264:	da060613          	addi	a2,a2,-608 # 8000 <_entry-0x7fff8000>
    80001268:	4585                	li	a1,1
    8000126a:	05fe                	slli	a1,a1,0x1f
    8000126c:	852e                	mv	a0,a1
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f38080e7          	jalr	-200(ra) # 800011a6 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001276:	4699                	li	a3,6
    80001278:	4645                	li	a2,17
    8000127a:	066e                	slli	a2,a2,0x1b
    8000127c:	8e05                	sub	a2,a2,s1
    8000127e:	85a6                	mv	a1,s1
    80001280:	8526                	mv	a0,s1
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f24080e7          	jalr	-220(ra) # 800011a6 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000128a:	46a9                	li	a3,10
    8000128c:	6605                	lui	a2,0x1
    8000128e:	00006597          	auipc	a1,0x6
    80001292:	d7258593          	addi	a1,a1,-654 # 80007000 <_trampoline>
    80001296:	04000537          	lui	a0,0x4000
    8000129a:	157d                	addi	a0,a0,-1
    8000129c:	0532                	slli	a0,a0,0xc
    8000129e:	00000097          	auipc	ra,0x0
    800012a2:	f08080e7          	jalr	-248(ra) # 800011a6 <kvmmap>
}
    800012a6:	60e2                	ld	ra,24(sp)
    800012a8:	6442                	ld	s0,16(sp)
    800012aa:	64a2                	ld	s1,8(sp)
    800012ac:	6105                	addi	sp,sp,32
    800012ae:	8082                	ret

00000000800012b0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012b0:	715d                	addi	sp,sp,-80
    800012b2:	e486                	sd	ra,72(sp)
    800012b4:	e0a2                	sd	s0,64(sp)
    800012b6:	fc26                	sd	s1,56(sp)
    800012b8:	f84a                	sd	s2,48(sp)
    800012ba:	f44e                	sd	s3,40(sp)
    800012bc:	f052                	sd	s4,32(sp)
    800012be:	ec56                	sd	s5,24(sp)
    800012c0:	e85a                	sd	s6,16(sp)
    800012c2:	e45e                	sd	s7,8(sp)
    800012c4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c6:	03459793          	slli	a5,a1,0x34
    800012ca:	e795                	bnez	a5,800012f6 <uvmunmap+0x46>
    800012cc:	8a2a                	mv	s4,a0
    800012ce:	892e                	mv	s2,a1
    800012d0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d2:	0632                	slli	a2,a2,0xc
    800012d4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012da:	6b05                	lui	s6,0x1
    800012dc:	0735e263          	bltu	a1,s3,80001340 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012e0:	60a6                	ld	ra,72(sp)
    800012e2:	6406                	ld	s0,64(sp)
    800012e4:	74e2                	ld	s1,56(sp)
    800012e6:	7942                	ld	s2,48(sp)
    800012e8:	79a2                	ld	s3,40(sp)
    800012ea:	7a02                	ld	s4,32(sp)
    800012ec:	6ae2                	ld	s5,24(sp)
    800012ee:	6b42                	ld	s6,16(sp)
    800012f0:	6ba2                	ld	s7,8(sp)
    800012f2:	6161                	addi	sp,sp,80
    800012f4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e1a50513          	addi	a0,a0,-486 # 80008110 <digits+0xd0>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	244080e7          	jalr	580(ra) # 80000542 <panic>
      panic("uvmunmap: walk");
    80001306:	00007517          	auipc	a0,0x7
    8000130a:	e2250513          	addi	a0,a0,-478 # 80008128 <digits+0xe8>
    8000130e:	fffff097          	auipc	ra,0xfffff
    80001312:	234080e7          	jalr	564(ra) # 80000542 <panic>
      panic("uvmunmap: not mapped");
    80001316:	00007517          	auipc	a0,0x7
    8000131a:	e2250513          	addi	a0,a0,-478 # 80008138 <digits+0xf8>
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	224080e7          	jalr	548(ra) # 80000542 <panic>
      panic("uvmunmap: not a leaf");
    80001326:	00007517          	auipc	a0,0x7
    8000132a:	e2a50513          	addi	a0,a0,-470 # 80008150 <digits+0x110>
    8000132e:	fffff097          	auipc	ra,0xfffff
    80001332:	214080e7          	jalr	532(ra) # 80000542 <panic>
    *pte = 0;
    80001336:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133a:	995a                	add	s2,s2,s6
    8000133c:	fb3972e3          	bgeu	s2,s3,800012e0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001340:	4601                	li	a2,0
    80001342:	85ca                	mv	a1,s2
    80001344:	8552                	mv	a0,s4
    80001346:	00000097          	auipc	ra,0x0
    8000134a:	c8c080e7          	jalr	-884(ra) # 80000fd2 <walk>
    8000134e:	84aa                	mv	s1,a0
    80001350:	d95d                	beqz	a0,80001306 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001352:	6108                	ld	a0,0(a0)
    80001354:	00157793          	andi	a5,a0,1
    80001358:	dfdd                	beqz	a5,80001316 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000135a:	3ff57793          	andi	a5,a0,1023
    8000135e:	fd7784e3          	beq	a5,s7,80001326 <uvmunmap+0x76>
    if(do_free){
    80001362:	fc0a8ae3          	beqz	s5,80001336 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001366:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001368:	0532                	slli	a0,a0,0xc
    8000136a:	fffff097          	auipc	ra,0xfffff
    8000136e:	6a8080e7          	jalr	1704(ra) # 80000a12 <kfree>
    80001372:	b7d1                	j	80001336 <uvmunmap+0x86>

0000000080001374 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001374:	1101                	addi	sp,sp,-32
    80001376:	ec06                	sd	ra,24(sp)
    80001378:	e822                	sd	s0,16(sp)
    8000137a:	e426                	sd	s1,8(sp)
    8000137c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000137e:	fffff097          	auipc	ra,0xfffff
    80001382:	790080e7          	jalr	1936(ra) # 80000b0e <kalloc>
    80001386:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001388:	c519                	beqz	a0,80001396 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000138a:	6605                	lui	a2,0x1
    8000138c:	4581                	li	a1,0
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	96c080e7          	jalr	-1684(ra) # 80000cfa <memset>
  return pagetable;
}
    80001396:	8526                	mv	a0,s1
    80001398:	60e2                	ld	ra,24(sp)
    8000139a:	6442                	ld	s0,16(sp)
    8000139c:	64a2                	ld	s1,8(sp)
    8000139e:	6105                	addi	sp,sp,32
    800013a0:	8082                	ret

00000000800013a2 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013a2:	7179                	addi	sp,sp,-48
    800013a4:	f406                	sd	ra,40(sp)
    800013a6:	f022                	sd	s0,32(sp)
    800013a8:	ec26                	sd	s1,24(sp)
    800013aa:	e84a                	sd	s2,16(sp)
    800013ac:	e44e                	sd	s3,8(sp)
    800013ae:	e052                	sd	s4,0(sp)
    800013b0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013b2:	6785                	lui	a5,0x1
    800013b4:	04f67863          	bgeu	a2,a5,80001404 <uvminit+0x62>
    800013b8:	8a2a                	mv	s4,a0
    800013ba:	89ae                	mv	s3,a1
    800013bc:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013be:	fffff097          	auipc	ra,0xfffff
    800013c2:	750080e7          	jalr	1872(ra) # 80000b0e <kalloc>
    800013c6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c8:	6605                	lui	a2,0x1
    800013ca:	4581                	li	a1,0
    800013cc:	00000097          	auipc	ra,0x0
    800013d0:	92e080e7          	jalr	-1746(ra) # 80000cfa <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013d4:	4779                	li	a4,30
    800013d6:	86ca                	mv	a3,s2
    800013d8:	6605                	lui	a2,0x1
    800013da:	4581                	li	a1,0
    800013dc:	8552                	mv	a0,s4
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	d3a080e7          	jalr	-710(ra) # 80001118 <mappages>
  memmove(mem, src, sz);
    800013e6:	8626                	mv	a2,s1
    800013e8:	85ce                	mv	a1,s3
    800013ea:	854a                	mv	a0,s2
    800013ec:	00000097          	auipc	ra,0x0
    800013f0:	96a080e7          	jalr	-1686(ra) # 80000d56 <memmove>
}
    800013f4:	70a2                	ld	ra,40(sp)
    800013f6:	7402                	ld	s0,32(sp)
    800013f8:	64e2                	ld	s1,24(sp)
    800013fa:	6942                	ld	s2,16(sp)
    800013fc:	69a2                	ld	s3,8(sp)
    800013fe:	6a02                	ld	s4,0(sp)
    80001400:	6145                	addi	sp,sp,48
    80001402:	8082                	ret
    panic("inituvm: more than a page");
    80001404:	00007517          	auipc	a0,0x7
    80001408:	d6450513          	addi	a0,a0,-668 # 80008168 <digits+0x128>
    8000140c:	fffff097          	auipc	ra,0xfffff
    80001410:	136080e7          	jalr	310(ra) # 80000542 <panic>

0000000080001414 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001414:	1101                	addi	sp,sp,-32
    80001416:	ec06                	sd	ra,24(sp)
    80001418:	e822                	sd	s0,16(sp)
    8000141a:	e426                	sd	s1,8(sp)
    8000141c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000141e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001420:	00b67d63          	bgeu	a2,a1,8000143a <uvmdealloc+0x26>
    80001424:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001426:	6785                	lui	a5,0x1
    80001428:	17fd                	addi	a5,a5,-1
    8000142a:	00f60733          	add	a4,a2,a5
    8000142e:	767d                	lui	a2,0xfffff
    80001430:	8f71                	and	a4,a4,a2
    80001432:	97ae                	add	a5,a5,a1
    80001434:	8ff1                	and	a5,a5,a2
    80001436:	00f76863          	bltu	a4,a5,80001446 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000143a:	8526                	mv	a0,s1
    8000143c:	60e2                	ld	ra,24(sp)
    8000143e:	6442                	ld	s0,16(sp)
    80001440:	64a2                	ld	s1,8(sp)
    80001442:	6105                	addi	sp,sp,32
    80001444:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001446:	8f99                	sub	a5,a5,a4
    80001448:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000144a:	4685                	li	a3,1
    8000144c:	0007861b          	sext.w	a2,a5
    80001450:	85ba                	mv	a1,a4
    80001452:	00000097          	auipc	ra,0x0
    80001456:	e5e080e7          	jalr	-418(ra) # 800012b0 <uvmunmap>
    8000145a:	b7c5                	j	8000143a <uvmdealloc+0x26>

000000008000145c <uvmalloc>:
  if(newsz < oldsz)
    8000145c:	0ab66163          	bltu	a2,a1,800014fe <uvmalloc+0xa2>
{
    80001460:	7139                	addi	sp,sp,-64
    80001462:	fc06                	sd	ra,56(sp)
    80001464:	f822                	sd	s0,48(sp)
    80001466:	f426                	sd	s1,40(sp)
    80001468:	f04a                	sd	s2,32(sp)
    8000146a:	ec4e                	sd	s3,24(sp)
    8000146c:	e852                	sd	s4,16(sp)
    8000146e:	e456                	sd	s5,8(sp)
    80001470:	0080                	addi	s0,sp,64
    80001472:	8aaa                	mv	s5,a0
    80001474:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001476:	6985                	lui	s3,0x1
    80001478:	19fd                	addi	s3,s3,-1
    8000147a:	95ce                	add	a1,a1,s3
    8000147c:	79fd                	lui	s3,0xfffff
    8000147e:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	08c9f063          	bgeu	s3,a2,80001502 <uvmalloc+0xa6>
    80001486:	894e                	mv	s2,s3
    mem = kalloc();
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	686080e7          	jalr	1670(ra) # 80000b0e <kalloc>
    80001490:	84aa                	mv	s1,a0
    if(mem == 0){
    80001492:	c51d                	beqz	a0,800014c0 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001494:	6605                	lui	a2,0x1
    80001496:	4581                	li	a1,0
    80001498:	00000097          	auipc	ra,0x0
    8000149c:	862080e7          	jalr	-1950(ra) # 80000cfa <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014a0:	4779                	li	a4,30
    800014a2:	86a6                	mv	a3,s1
    800014a4:	6605                	lui	a2,0x1
    800014a6:	85ca                	mv	a1,s2
    800014a8:	8556                	mv	a0,s5
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	c6e080e7          	jalr	-914(ra) # 80001118 <mappages>
    800014b2:	e905                	bnez	a0,800014e2 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b4:	6785                	lui	a5,0x1
    800014b6:	993e                	add	s2,s2,a5
    800014b8:	fd4968e3          	bltu	s2,s4,80001488 <uvmalloc+0x2c>
  return newsz;
    800014bc:	8552                	mv	a0,s4
    800014be:	a809                	j	800014d0 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014c0:	864e                	mv	a2,s3
    800014c2:	85ca                	mv	a1,s2
    800014c4:	8556                	mv	a0,s5
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	f4e080e7          	jalr	-178(ra) # 80001414 <uvmdealloc>
      return 0;
    800014ce:	4501                	li	a0,0
}
    800014d0:	70e2                	ld	ra,56(sp)
    800014d2:	7442                	ld	s0,48(sp)
    800014d4:	74a2                	ld	s1,40(sp)
    800014d6:	7902                	ld	s2,32(sp)
    800014d8:	69e2                	ld	s3,24(sp)
    800014da:	6a42                	ld	s4,16(sp)
    800014dc:	6aa2                	ld	s5,8(sp)
    800014de:	6121                	addi	sp,sp,64
    800014e0:	8082                	ret
      kfree(mem);
    800014e2:	8526                	mv	a0,s1
    800014e4:	fffff097          	auipc	ra,0xfffff
    800014e8:	52e080e7          	jalr	1326(ra) # 80000a12 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ec:	864e                	mv	a2,s3
    800014ee:	85ca                	mv	a1,s2
    800014f0:	8556                	mv	a0,s5
    800014f2:	00000097          	auipc	ra,0x0
    800014f6:	f22080e7          	jalr	-222(ra) # 80001414 <uvmdealloc>
      return 0;
    800014fa:	4501                	li	a0,0
    800014fc:	bfd1                	j	800014d0 <uvmalloc+0x74>
    return oldsz;
    800014fe:	852e                	mv	a0,a1
}
    80001500:	8082                	ret
  return newsz;
    80001502:	8532                	mv	a0,a2
    80001504:	b7f1                	j	800014d0 <uvmalloc+0x74>

0000000080001506 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001506:	7179                	addi	sp,sp,-48
    80001508:	f406                	sd	ra,40(sp)
    8000150a:	f022                	sd	s0,32(sp)
    8000150c:	ec26                	sd	s1,24(sp)
    8000150e:	e84a                	sd	s2,16(sp)
    80001510:	e44e                	sd	s3,8(sp)
    80001512:	e052                	sd	s4,0(sp)
    80001514:	1800                	addi	s0,sp,48
    80001516:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001518:	84aa                	mv	s1,a0
    8000151a:	6905                	lui	s2,0x1
    8000151c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151e:	4985                	li	s3,1
    80001520:	a821                	j	80001538 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001522:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001524:	0532                	slli	a0,a0,0xc
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	fe0080e7          	jalr	-32(ra) # 80001506 <freewalk>
      pagetable[i] = 0;
    8000152e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001532:	04a1                	addi	s1,s1,8
    80001534:	03248163          	beq	s1,s2,80001556 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001538:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000153a:	00f57793          	andi	a5,a0,15
    8000153e:	ff3782e3          	beq	a5,s3,80001522 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001542:	8905                	andi	a0,a0,1
    80001544:	d57d                	beqz	a0,80001532 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001546:	00007517          	auipc	a0,0x7
    8000154a:	c4250513          	addi	a0,a0,-958 # 80008188 <digits+0x148>
    8000154e:	fffff097          	auipc	ra,0xfffff
    80001552:	ff4080e7          	jalr	-12(ra) # 80000542 <panic>
    }
  }
  kfree((void*)pagetable);
    80001556:	8552                	mv	a0,s4
    80001558:	fffff097          	auipc	ra,0xfffff
    8000155c:	4ba080e7          	jalr	1210(ra) # 80000a12 <kfree>
}
    80001560:	70a2                	ld	ra,40(sp)
    80001562:	7402                	ld	s0,32(sp)
    80001564:	64e2                	ld	s1,24(sp)
    80001566:	6942                	ld	s2,16(sp)
    80001568:	69a2                	ld	s3,8(sp)
    8000156a:	6a02                	ld	s4,0(sp)
    8000156c:	6145                	addi	sp,sp,48
    8000156e:	8082                	ret

0000000080001570 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001570:	1101                	addi	sp,sp,-32
    80001572:	ec06                	sd	ra,24(sp)
    80001574:	e822                	sd	s0,16(sp)
    80001576:	e426                	sd	s1,8(sp)
    80001578:	1000                	addi	s0,sp,32
    8000157a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000157c:	e999                	bnez	a1,80001592 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000157e:	8526                	mv	a0,s1
    80001580:	00000097          	auipc	ra,0x0
    80001584:	f86080e7          	jalr	-122(ra) # 80001506 <freewalk>
}
    80001588:	60e2                	ld	ra,24(sp)
    8000158a:	6442                	ld	s0,16(sp)
    8000158c:	64a2                	ld	s1,8(sp)
    8000158e:	6105                	addi	sp,sp,32
    80001590:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001592:	6605                	lui	a2,0x1
    80001594:	167d                	addi	a2,a2,-1
    80001596:	962e                	add	a2,a2,a1
    80001598:	4685                	li	a3,1
    8000159a:	8231                	srli	a2,a2,0xc
    8000159c:	4581                	li	a1,0
    8000159e:	00000097          	auipc	ra,0x0
    800015a2:	d12080e7          	jalr	-750(ra) # 800012b0 <uvmunmap>
    800015a6:	bfe1                	j	8000157e <uvmfree+0xe>

00000000800015a8 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015a8:	c679                	beqz	a2,80001676 <uvmcopy+0xce>
{
    800015aa:	715d                	addi	sp,sp,-80
    800015ac:	e486                	sd	ra,72(sp)
    800015ae:	e0a2                	sd	s0,64(sp)
    800015b0:	fc26                	sd	s1,56(sp)
    800015b2:	f84a                	sd	s2,48(sp)
    800015b4:	f44e                	sd	s3,40(sp)
    800015b6:	f052                	sd	s4,32(sp)
    800015b8:	ec56                	sd	s5,24(sp)
    800015ba:	e85a                	sd	s6,16(sp)
    800015bc:	e45e                	sd	s7,8(sp)
    800015be:	0880                	addi	s0,sp,80
    800015c0:	8b2a                	mv	s6,a0
    800015c2:	8aae                	mv	s5,a1
    800015c4:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015c6:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015c8:	4601                	li	a2,0
    800015ca:	85ce                	mv	a1,s3
    800015cc:	855a                	mv	a0,s6
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	a04080e7          	jalr	-1532(ra) # 80000fd2 <walk>
    800015d6:	c531                	beqz	a0,80001622 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015d8:	6118                	ld	a4,0(a0)
    800015da:	00177793          	andi	a5,a4,1
    800015de:	cbb1                	beqz	a5,80001632 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015e0:	00a75593          	srli	a1,a4,0xa
    800015e4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ec:	fffff097          	auipc	ra,0xfffff
    800015f0:	522080e7          	jalr	1314(ra) # 80000b0e <kalloc>
    800015f4:	892a                	mv	s2,a0
    800015f6:	c939                	beqz	a0,8000164c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f8:	6605                	lui	a2,0x1
    800015fa:	85de                	mv	a1,s7
    800015fc:	fffff097          	auipc	ra,0xfffff
    80001600:	75a080e7          	jalr	1882(ra) # 80000d56 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001604:	8726                	mv	a4,s1
    80001606:	86ca                	mv	a3,s2
    80001608:	6605                	lui	a2,0x1
    8000160a:	85ce                	mv	a1,s3
    8000160c:	8556                	mv	a0,s5
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	b0a080e7          	jalr	-1270(ra) # 80001118 <mappages>
    80001616:	e515                	bnez	a0,80001642 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001618:	6785                	lui	a5,0x1
    8000161a:	99be                	add	s3,s3,a5
    8000161c:	fb49e6e3          	bltu	s3,s4,800015c8 <uvmcopy+0x20>
    80001620:	a081                	j	80001660 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001622:	00007517          	auipc	a0,0x7
    80001626:	b7650513          	addi	a0,a0,-1162 # 80008198 <digits+0x158>
    8000162a:	fffff097          	auipc	ra,0xfffff
    8000162e:	f18080e7          	jalr	-232(ra) # 80000542 <panic>
      panic("uvmcopy: page not present");
    80001632:	00007517          	auipc	a0,0x7
    80001636:	b8650513          	addi	a0,a0,-1146 # 800081b8 <digits+0x178>
    8000163a:	fffff097          	auipc	ra,0xfffff
    8000163e:	f08080e7          	jalr	-248(ra) # 80000542 <panic>
      kfree(mem);
    80001642:	854a                	mv	a0,s2
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	3ce080e7          	jalr	974(ra) # 80000a12 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000164c:	4685                	li	a3,1
    8000164e:	00c9d613          	srli	a2,s3,0xc
    80001652:	4581                	li	a1,0
    80001654:	8556                	mv	a0,s5
    80001656:	00000097          	auipc	ra,0x0
    8000165a:	c5a080e7          	jalr	-934(ra) # 800012b0 <uvmunmap>
  return -1;
    8000165e:	557d                	li	a0,-1
}
    80001660:	60a6                	ld	ra,72(sp)
    80001662:	6406                	ld	s0,64(sp)
    80001664:	74e2                	ld	s1,56(sp)
    80001666:	7942                	ld	s2,48(sp)
    80001668:	79a2                	ld	s3,40(sp)
    8000166a:	7a02                	ld	s4,32(sp)
    8000166c:	6ae2                	ld	s5,24(sp)
    8000166e:	6b42                	ld	s6,16(sp)
    80001670:	6ba2                	ld	s7,8(sp)
    80001672:	6161                	addi	sp,sp,80
    80001674:	8082                	ret
  return 0;
    80001676:	4501                	li	a0,0
}
    80001678:	8082                	ret

000000008000167a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000167a:	1141                	addi	sp,sp,-16
    8000167c:	e406                	sd	ra,8(sp)
    8000167e:	e022                	sd	s0,0(sp)
    80001680:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001682:	4601                	li	a2,0
    80001684:	00000097          	auipc	ra,0x0
    80001688:	94e080e7          	jalr	-1714(ra) # 80000fd2 <walk>
  if(pte == 0)
    8000168c:	c901                	beqz	a0,8000169c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000168e:	611c                	ld	a5,0(a0)
    80001690:	9bbd                	andi	a5,a5,-17
    80001692:	e11c                	sd	a5,0(a0)
}
    80001694:	60a2                	ld	ra,8(sp)
    80001696:	6402                	ld	s0,0(sp)
    80001698:	0141                	addi	sp,sp,16
    8000169a:	8082                	ret
    panic("uvmclear");
    8000169c:	00007517          	auipc	a0,0x7
    800016a0:	b3c50513          	addi	a0,a0,-1220 # 800081d8 <digits+0x198>
    800016a4:	fffff097          	auipc	ra,0xfffff
    800016a8:	e9e080e7          	jalr	-354(ra) # 80000542 <panic>

00000000800016ac <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ac:	c6bd                	beqz	a3,8000171a <copyout+0x6e>
{
    800016ae:	715d                	addi	sp,sp,-80
    800016b0:	e486                	sd	ra,72(sp)
    800016b2:	e0a2                	sd	s0,64(sp)
    800016b4:	fc26                	sd	s1,56(sp)
    800016b6:	f84a                	sd	s2,48(sp)
    800016b8:	f44e                	sd	s3,40(sp)
    800016ba:	f052                	sd	s4,32(sp)
    800016bc:	ec56                	sd	s5,24(sp)
    800016be:	e85a                	sd	s6,16(sp)
    800016c0:	e45e                	sd	s7,8(sp)
    800016c2:	e062                	sd	s8,0(sp)
    800016c4:	0880                	addi	s0,sp,80
    800016c6:	8b2a                	mv	s6,a0
    800016c8:	8c2e                	mv	s8,a1
    800016ca:	8a32                	mv	s4,a2
    800016cc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016ce:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016d0:	6a85                	lui	s5,0x1
    800016d2:	a015                	j	800016f6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016d4:	9562                	add	a0,a0,s8
    800016d6:	0004861b          	sext.w	a2,s1
    800016da:	85d2                	mv	a1,s4
    800016dc:	41250533          	sub	a0,a0,s2
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	676080e7          	jalr	1654(ra) # 80000d56 <memmove>

    len -= n;
    800016e8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ec:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ee:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016f2:	02098263          	beqz	s3,80001716 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016fa:	85ca                	mv	a1,s2
    800016fc:	855a                	mv	a0,s6
    800016fe:	00000097          	auipc	ra,0x0
    80001702:	97a080e7          	jalr	-1670(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    80001706:	cd01                	beqz	a0,8000171e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001708:	418904b3          	sub	s1,s2,s8
    8000170c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000170e:	fc99f3e3          	bgeu	s3,s1,800016d4 <copyout+0x28>
    80001712:	84ce                	mv	s1,s3
    80001714:	b7c1                	j	800016d4 <copyout+0x28>
  }
  return 0;
    80001716:	4501                	li	a0,0
    80001718:	a021                	j	80001720 <copyout+0x74>
    8000171a:	4501                	li	a0,0
}
    8000171c:	8082                	ret
      return -1;
    8000171e:	557d                	li	a0,-1
}
    80001720:	60a6                	ld	ra,72(sp)
    80001722:	6406                	ld	s0,64(sp)
    80001724:	74e2                	ld	s1,56(sp)
    80001726:	7942                	ld	s2,48(sp)
    80001728:	79a2                	ld	s3,40(sp)
    8000172a:	7a02                	ld	s4,32(sp)
    8000172c:	6ae2                	ld	s5,24(sp)
    8000172e:	6b42                	ld	s6,16(sp)
    80001730:	6ba2                	ld	s7,8(sp)
    80001732:	6c02                	ld	s8,0(sp)
    80001734:	6161                	addi	sp,sp,80
    80001736:	8082                	ret

0000000080001738 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001738:	caa5                	beqz	a3,800017a8 <copyin+0x70>
{
    8000173a:	715d                	addi	sp,sp,-80
    8000173c:	e486                	sd	ra,72(sp)
    8000173e:	e0a2                	sd	s0,64(sp)
    80001740:	fc26                	sd	s1,56(sp)
    80001742:	f84a                	sd	s2,48(sp)
    80001744:	f44e                	sd	s3,40(sp)
    80001746:	f052                	sd	s4,32(sp)
    80001748:	ec56                	sd	s5,24(sp)
    8000174a:	e85a                	sd	s6,16(sp)
    8000174c:	e45e                	sd	s7,8(sp)
    8000174e:	e062                	sd	s8,0(sp)
    80001750:	0880                	addi	s0,sp,80
    80001752:	8b2a                	mv	s6,a0
    80001754:	8a2e                	mv	s4,a1
    80001756:	8c32                	mv	s8,a2
    80001758:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000175a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000175c:	6a85                	lui	s5,0x1
    8000175e:	a01d                	j	80001784 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001760:	018505b3          	add	a1,a0,s8
    80001764:	0004861b          	sext.w	a2,s1
    80001768:	412585b3          	sub	a1,a1,s2
    8000176c:	8552                	mv	a0,s4
    8000176e:	fffff097          	auipc	ra,0xfffff
    80001772:	5e8080e7          	jalr	1512(ra) # 80000d56 <memmove>

    len -= n;
    80001776:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000177a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000177c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001780:	02098263          	beqz	s3,800017a4 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001784:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001788:	85ca                	mv	a1,s2
    8000178a:	855a                	mv	a0,s6
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	8ec080e7          	jalr	-1812(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    80001794:	cd01                	beqz	a0,800017ac <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001796:	418904b3          	sub	s1,s2,s8
    8000179a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000179c:	fc99f2e3          	bgeu	s3,s1,80001760 <copyin+0x28>
    800017a0:	84ce                	mv	s1,s3
    800017a2:	bf7d                	j	80001760 <copyin+0x28>
  }
  return 0;
    800017a4:	4501                	li	a0,0
    800017a6:	a021                	j	800017ae <copyin+0x76>
    800017a8:	4501                	li	a0,0
}
    800017aa:	8082                	ret
      return -1;
    800017ac:	557d                	li	a0,-1
}
    800017ae:	60a6                	ld	ra,72(sp)
    800017b0:	6406                	ld	s0,64(sp)
    800017b2:	74e2                	ld	s1,56(sp)
    800017b4:	7942                	ld	s2,48(sp)
    800017b6:	79a2                	ld	s3,40(sp)
    800017b8:	7a02                	ld	s4,32(sp)
    800017ba:	6ae2                	ld	s5,24(sp)
    800017bc:	6b42                	ld	s6,16(sp)
    800017be:	6ba2                	ld	s7,8(sp)
    800017c0:	6c02                	ld	s8,0(sp)
    800017c2:	6161                	addi	sp,sp,80
    800017c4:	8082                	ret

00000000800017c6 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017c6:	c6c5                	beqz	a3,8000186e <copyinstr+0xa8>
{
    800017c8:	715d                	addi	sp,sp,-80
    800017ca:	e486                	sd	ra,72(sp)
    800017cc:	e0a2                	sd	s0,64(sp)
    800017ce:	fc26                	sd	s1,56(sp)
    800017d0:	f84a                	sd	s2,48(sp)
    800017d2:	f44e                	sd	s3,40(sp)
    800017d4:	f052                	sd	s4,32(sp)
    800017d6:	ec56                	sd	s5,24(sp)
    800017d8:	e85a                	sd	s6,16(sp)
    800017da:	e45e                	sd	s7,8(sp)
    800017dc:	0880                	addi	s0,sp,80
    800017de:	8a2a                	mv	s4,a0
    800017e0:	8b2e                	mv	s6,a1
    800017e2:	8bb2                	mv	s7,a2
    800017e4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017e6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e8:	6985                	lui	s3,0x1
    800017ea:	a035                	j	80001816 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ec:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017f0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017f2:	0017b793          	seqz	a5,a5
    800017f6:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017fa:	60a6                	ld	ra,72(sp)
    800017fc:	6406                	ld	s0,64(sp)
    800017fe:	74e2                	ld	s1,56(sp)
    80001800:	7942                	ld	s2,48(sp)
    80001802:	79a2                	ld	s3,40(sp)
    80001804:	7a02                	ld	s4,32(sp)
    80001806:	6ae2                	ld	s5,24(sp)
    80001808:	6b42                	ld	s6,16(sp)
    8000180a:	6ba2                	ld	s7,8(sp)
    8000180c:	6161                	addi	sp,sp,80
    8000180e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001810:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001814:	c8a9                	beqz	s1,80001866 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001816:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000181a:	85ca                	mv	a1,s2
    8000181c:	8552                	mv	a0,s4
    8000181e:	00000097          	auipc	ra,0x0
    80001822:	85a080e7          	jalr	-1958(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    80001826:	c131                	beqz	a0,8000186a <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001828:	41790833          	sub	a6,s2,s7
    8000182c:	984e                	add	a6,a6,s3
    if(n > max)
    8000182e:	0104f363          	bgeu	s1,a6,80001834 <copyinstr+0x6e>
    80001832:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001834:	955e                	add	a0,a0,s7
    80001836:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000183a:	fc080be3          	beqz	a6,80001810 <copyinstr+0x4a>
    8000183e:	985a                	add	a6,a6,s6
    80001840:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001842:	41650633          	sub	a2,a0,s6
    80001846:	14fd                	addi	s1,s1,-1
    80001848:	9b26                	add	s6,s6,s1
    8000184a:	00f60733          	add	a4,a2,a5
    8000184e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001852:	df49                	beqz	a4,800017ec <copyinstr+0x26>
        *dst = *p;
    80001854:	00e78023          	sb	a4,0(a5)
      --max;
    80001858:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000185c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000185e:	ff0796e3          	bne	a5,a6,8000184a <copyinstr+0x84>
      dst++;
    80001862:	8b42                	mv	s6,a6
    80001864:	b775                	j	80001810 <copyinstr+0x4a>
    80001866:	4781                	li	a5,0
    80001868:	b769                	j	800017f2 <copyinstr+0x2c>
      return -1;
    8000186a:	557d                	li	a0,-1
    8000186c:	b779                	j	800017fa <copyinstr+0x34>
  int got_null = 0;
    8000186e:	4781                	li	a5,0
  if(got_null){
    80001870:	0017b793          	seqz	a5,a5
    80001874:	40f00533          	neg	a0,a5
}
    80001878:	8082                	ret

000000008000187a <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000187a:	1101                	addi	sp,sp,-32
    8000187c:	ec06                	sd	ra,24(sp)
    8000187e:	e822                	sd	s0,16(sp)
    80001880:	e426                	sd	s1,8(sp)
    80001882:	1000                	addi	s0,sp,32
    80001884:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001886:	fffff097          	auipc	ra,0xfffff
    8000188a:	2fe080e7          	jalr	766(ra) # 80000b84 <holding>
    8000188e:	c909                	beqz	a0,800018a0 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001890:	749c                	ld	a5,40(s1)
    80001892:	00978f63          	beq	a5,s1,800018b0 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001896:	60e2                	ld	ra,24(sp)
    80001898:	6442                	ld	s0,16(sp)
    8000189a:	64a2                	ld	s1,8(sp)
    8000189c:	6105                	addi	sp,sp,32
    8000189e:	8082                	ret
    panic("wakeup1");
    800018a0:	00007517          	auipc	a0,0x7
    800018a4:	94850513          	addi	a0,a0,-1720 # 800081e8 <digits+0x1a8>
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	c9a080e7          	jalr	-870(ra) # 80000542 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018b0:	4c98                	lw	a4,24(s1)
    800018b2:	4785                	li	a5,1
    800018b4:	fef711e3          	bne	a4,a5,80001896 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018b8:	4789                	li	a5,2
    800018ba:	cc9c                	sw	a5,24(s1)
}
    800018bc:	bfe9                	j	80001896 <wakeup1+0x1c>

00000000800018be <procinit>:
{
    800018be:	715d                	addi	sp,sp,-80
    800018c0:	e486                	sd	ra,72(sp)
    800018c2:	e0a2                	sd	s0,64(sp)
    800018c4:	fc26                	sd	s1,56(sp)
    800018c6:	f84a                	sd	s2,48(sp)
    800018c8:	f44e                	sd	s3,40(sp)
    800018ca:	f052                	sd	s4,32(sp)
    800018cc:	ec56                	sd	s5,24(sp)
    800018ce:	e85a                	sd	s6,16(sp)
    800018d0:	e45e                	sd	s7,8(sp)
    800018d2:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800018d4:	00007597          	auipc	a1,0x7
    800018d8:	91c58593          	addi	a1,a1,-1764 # 800081f0 <digits+0x1b0>
    800018dc:	00010517          	auipc	a0,0x10
    800018e0:	07450513          	addi	a0,a0,116 # 80011950 <pid_lock>
    800018e4:	fffff097          	auipc	ra,0xfffff
    800018e8:	28a080e7          	jalr	650(ra) # 80000b6e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ec:	00010917          	auipc	s2,0x10
    800018f0:	47c90913          	addi	s2,s2,1148 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800018f4:	00007b97          	auipc	s7,0x7
    800018f8:	904b8b93          	addi	s7,s7,-1788 # 800081f8 <digits+0x1b8>
      uint64 va = KSTACK((int) (p - proc));
    800018fc:	8b4a                	mv	s6,s2
    800018fe:	00006a97          	auipc	s5,0x6
    80001902:	702a8a93          	addi	s5,s5,1794 # 80008000 <etext>
    80001906:	040009b7          	lui	s3,0x4000
    8000190a:	19fd                	addi	s3,s3,-1
    8000190c:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000190e:	00016a17          	auipc	s4,0x16
    80001912:	e5aa0a13          	addi	s4,s4,-422 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001916:	85de                	mv	a1,s7
    80001918:	854a                	mv	a0,s2
    8000191a:	fffff097          	auipc	ra,0xfffff
    8000191e:	254080e7          	jalr	596(ra) # 80000b6e <initlock>
      char *pa = kalloc();
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	1ec080e7          	jalr	492(ra) # 80000b0e <kalloc>
    8000192a:	85aa                	mv	a1,a0
      if(pa == 0)
    8000192c:	c929                	beqz	a0,8000197e <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    8000192e:	416904b3          	sub	s1,s2,s6
    80001932:	848d                	srai	s1,s1,0x3
    80001934:	000ab783          	ld	a5,0(s5)
    80001938:	02f484b3          	mul	s1,s1,a5
    8000193c:	2485                	addiw	s1,s1,1
    8000193e:	00d4949b          	slliw	s1,s1,0xd
    80001942:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001946:	4699                	li	a3,6
    80001948:	6605                	lui	a2,0x1
    8000194a:	8526                	mv	a0,s1
    8000194c:	00000097          	auipc	ra,0x0
    80001950:	85a080e7          	jalr	-1958(ra) # 800011a6 <kvmmap>
      p->kstack = va;
    80001954:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001958:	16890913          	addi	s2,s2,360
    8000195c:	fb491de3          	bne	s2,s4,80001916 <procinit+0x58>
  kvminithart();
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	64e080e7          	jalr	1614(ra) # 80000fae <kvminithart>
}
    80001968:	60a6                	ld	ra,72(sp)
    8000196a:	6406                	ld	s0,64(sp)
    8000196c:	74e2                	ld	s1,56(sp)
    8000196e:	7942                	ld	s2,48(sp)
    80001970:	79a2                	ld	s3,40(sp)
    80001972:	7a02                	ld	s4,32(sp)
    80001974:	6ae2                	ld	s5,24(sp)
    80001976:	6b42                	ld	s6,16(sp)
    80001978:	6ba2                	ld	s7,8(sp)
    8000197a:	6161                	addi	sp,sp,80
    8000197c:	8082                	ret
        panic("kalloc");
    8000197e:	00007517          	auipc	a0,0x7
    80001982:	88250513          	addi	a0,a0,-1918 # 80008200 <digits+0x1c0>
    80001986:	fffff097          	auipc	ra,0xfffff
    8000198a:	bbc080e7          	jalr	-1092(ra) # 80000542 <panic>

000000008000198e <cpuid>:
{
    8000198e:	1141                	addi	sp,sp,-16
    80001990:	e422                	sd	s0,8(sp)
    80001992:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001994:	8512                	mv	a0,tp
}
    80001996:	2501                	sext.w	a0,a0
    80001998:	6422                	ld	s0,8(sp)
    8000199a:	0141                	addi	sp,sp,16
    8000199c:	8082                	ret

000000008000199e <mycpu>:
mycpu(void) {
    8000199e:	1141                	addi	sp,sp,-16
    800019a0:	e422                	sd	s0,8(sp)
    800019a2:	0800                	addi	s0,sp,16
    800019a4:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019a6:	2781                	sext.w	a5,a5
    800019a8:	079e                	slli	a5,a5,0x7
}
    800019aa:	00010517          	auipc	a0,0x10
    800019ae:	fbe50513          	addi	a0,a0,-66 # 80011968 <cpus>
    800019b2:	953e                	add	a0,a0,a5
    800019b4:	6422                	ld	s0,8(sp)
    800019b6:	0141                	addi	sp,sp,16
    800019b8:	8082                	ret

00000000800019ba <myproc>:
myproc(void) {
    800019ba:	1101                	addi	sp,sp,-32
    800019bc:	ec06                	sd	ra,24(sp)
    800019be:	e822                	sd	s0,16(sp)
    800019c0:	e426                	sd	s1,8(sp)
    800019c2:	1000                	addi	s0,sp,32
  push_off();
    800019c4:	fffff097          	auipc	ra,0xfffff
    800019c8:	1ee080e7          	jalr	494(ra) # 80000bb2 <push_off>
    800019cc:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019ce:	2781                	sext.w	a5,a5
    800019d0:	079e                	slli	a5,a5,0x7
    800019d2:	00010717          	auipc	a4,0x10
    800019d6:	f7e70713          	addi	a4,a4,-130 # 80011950 <pid_lock>
    800019da:	97ba                	add	a5,a5,a4
    800019dc:	6f84                	ld	s1,24(a5)
  pop_off();
    800019de:	fffff097          	auipc	ra,0xfffff
    800019e2:	274080e7          	jalr	628(ra) # 80000c52 <pop_off>
}
    800019e6:	8526                	mv	a0,s1
    800019e8:	60e2                	ld	ra,24(sp)
    800019ea:	6442                	ld	s0,16(sp)
    800019ec:	64a2                	ld	s1,8(sp)
    800019ee:	6105                	addi	sp,sp,32
    800019f0:	8082                	ret

00000000800019f2 <forkret>:
{
    800019f2:	1141                	addi	sp,sp,-16
    800019f4:	e406                	sd	ra,8(sp)
    800019f6:	e022                	sd	s0,0(sp)
    800019f8:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    800019fa:	00000097          	auipc	ra,0x0
    800019fe:	fc0080e7          	jalr	-64(ra) # 800019ba <myproc>
    80001a02:	fffff097          	auipc	ra,0xfffff
    80001a06:	2b0080e7          	jalr	688(ra) # 80000cb2 <release>
  if (first) {
    80001a0a:	00007797          	auipc	a5,0x7
    80001a0e:	e467a783          	lw	a5,-442(a5) # 80008850 <first.1>
    80001a12:	eb89                	bnez	a5,80001a24 <forkret+0x32>
  usertrapret();
    80001a14:	00001097          	auipc	ra,0x1
    80001a18:	bf6080e7          	jalr	-1034(ra) # 8000260a <usertrapret>
}
    80001a1c:	60a2                	ld	ra,8(sp)
    80001a1e:	6402                	ld	s0,0(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret
    first = 0;
    80001a24:	00007797          	auipc	a5,0x7
    80001a28:	e207a623          	sw	zero,-468(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a2c:	4505                	li	a0,1
    80001a2e:	00002097          	auipc	ra,0x2
    80001a32:	a1e080e7          	jalr	-1506(ra) # 8000344c <fsinit>
    80001a36:	bff9                	j	80001a14 <forkret+0x22>

0000000080001a38 <allocpid>:
allocpid() {
    80001a38:	1101                	addi	sp,sp,-32
    80001a3a:	ec06                	sd	ra,24(sp)
    80001a3c:	e822                	sd	s0,16(sp)
    80001a3e:	e426                	sd	s1,8(sp)
    80001a40:	e04a                	sd	s2,0(sp)
    80001a42:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a44:	00010917          	auipc	s2,0x10
    80001a48:	f0c90913          	addi	s2,s2,-244 # 80011950 <pid_lock>
    80001a4c:	854a                	mv	a0,s2
    80001a4e:	fffff097          	auipc	ra,0xfffff
    80001a52:	1b0080e7          	jalr	432(ra) # 80000bfe <acquire>
  pid = nextpid;
    80001a56:	00007797          	auipc	a5,0x7
    80001a5a:	dfe78793          	addi	a5,a5,-514 # 80008854 <nextpid>
    80001a5e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a60:	0014871b          	addiw	a4,s1,1
    80001a64:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a66:	854a                	mv	a0,s2
    80001a68:	fffff097          	auipc	ra,0xfffff
    80001a6c:	24a080e7          	jalr	586(ra) # 80000cb2 <release>
}
    80001a70:	8526                	mv	a0,s1
    80001a72:	60e2                	ld	ra,24(sp)
    80001a74:	6442                	ld	s0,16(sp)
    80001a76:	64a2                	ld	s1,8(sp)
    80001a78:	6902                	ld	s2,0(sp)
    80001a7a:	6105                	addi	sp,sp,32
    80001a7c:	8082                	ret

0000000080001a7e <proc_pagetable>:
{
    80001a7e:	1101                	addi	sp,sp,-32
    80001a80:	ec06                	sd	ra,24(sp)
    80001a82:	e822                	sd	s0,16(sp)
    80001a84:	e426                	sd	s1,8(sp)
    80001a86:	e04a                	sd	s2,0(sp)
    80001a88:	1000                	addi	s0,sp,32
    80001a8a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a8c:	00000097          	auipc	ra,0x0
    80001a90:	8e8080e7          	jalr	-1816(ra) # 80001374 <uvmcreate>
    80001a94:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a96:	c121                	beqz	a0,80001ad6 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a98:	4729                	li	a4,10
    80001a9a:	00005697          	auipc	a3,0x5
    80001a9e:	56668693          	addi	a3,a3,1382 # 80007000 <_trampoline>
    80001aa2:	6605                	lui	a2,0x1
    80001aa4:	040005b7          	lui	a1,0x4000
    80001aa8:	15fd                	addi	a1,a1,-1
    80001aaa:	05b2                	slli	a1,a1,0xc
    80001aac:	fffff097          	auipc	ra,0xfffff
    80001ab0:	66c080e7          	jalr	1644(ra) # 80001118 <mappages>
    80001ab4:	02054863          	bltz	a0,80001ae4 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab8:	4719                	li	a4,6
    80001aba:	05893683          	ld	a3,88(s2)
    80001abe:	6605                	lui	a2,0x1
    80001ac0:	020005b7          	lui	a1,0x2000
    80001ac4:	15fd                	addi	a1,a1,-1
    80001ac6:	05b6                	slli	a1,a1,0xd
    80001ac8:	8526                	mv	a0,s1
    80001aca:	fffff097          	auipc	ra,0xfffff
    80001ace:	64e080e7          	jalr	1614(ra) # 80001118 <mappages>
    80001ad2:	02054163          	bltz	a0,80001af4 <proc_pagetable+0x76>
}
    80001ad6:	8526                	mv	a0,s1
    80001ad8:	60e2                	ld	ra,24(sp)
    80001ada:	6442                	ld	s0,16(sp)
    80001adc:	64a2                	ld	s1,8(sp)
    80001ade:	6902                	ld	s2,0(sp)
    80001ae0:	6105                	addi	sp,sp,32
    80001ae2:	8082                	ret
    uvmfree(pagetable, 0);
    80001ae4:	4581                	li	a1,0
    80001ae6:	8526                	mv	a0,s1
    80001ae8:	00000097          	auipc	ra,0x0
    80001aec:	a88080e7          	jalr	-1400(ra) # 80001570 <uvmfree>
    return 0;
    80001af0:	4481                	li	s1,0
    80001af2:	b7d5                	j	80001ad6 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001af4:	4681                	li	a3,0
    80001af6:	4605                	li	a2,1
    80001af8:	040005b7          	lui	a1,0x4000
    80001afc:	15fd                	addi	a1,a1,-1
    80001afe:	05b2                	slli	a1,a1,0xc
    80001b00:	8526                	mv	a0,s1
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	7ae080e7          	jalr	1966(ra) # 800012b0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b0a:	4581                	li	a1,0
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	00000097          	auipc	ra,0x0
    80001b12:	a62080e7          	jalr	-1438(ra) # 80001570 <uvmfree>
    return 0;
    80001b16:	4481                	li	s1,0
    80001b18:	bf7d                	j	80001ad6 <proc_pagetable+0x58>

0000000080001b1a <proc_freepagetable>:
{
    80001b1a:	1101                	addi	sp,sp,-32
    80001b1c:	ec06                	sd	ra,24(sp)
    80001b1e:	e822                	sd	s0,16(sp)
    80001b20:	e426                	sd	s1,8(sp)
    80001b22:	e04a                	sd	s2,0(sp)
    80001b24:	1000                	addi	s0,sp,32
    80001b26:	84aa                	mv	s1,a0
    80001b28:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b2a:	4681                	li	a3,0
    80001b2c:	4605                	li	a2,1
    80001b2e:	040005b7          	lui	a1,0x4000
    80001b32:	15fd                	addi	a1,a1,-1
    80001b34:	05b2                	slli	a1,a1,0xc
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	77a080e7          	jalr	1914(ra) # 800012b0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b3e:	4681                	li	a3,0
    80001b40:	4605                	li	a2,1
    80001b42:	020005b7          	lui	a1,0x2000
    80001b46:	15fd                	addi	a1,a1,-1
    80001b48:	05b6                	slli	a1,a1,0xd
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	764080e7          	jalr	1892(ra) # 800012b0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b54:	85ca                	mv	a1,s2
    80001b56:	8526                	mv	a0,s1
    80001b58:	00000097          	auipc	ra,0x0
    80001b5c:	a18080e7          	jalr	-1512(ra) # 80001570 <uvmfree>
}
    80001b60:	60e2                	ld	ra,24(sp)
    80001b62:	6442                	ld	s0,16(sp)
    80001b64:	64a2                	ld	s1,8(sp)
    80001b66:	6902                	ld	s2,0(sp)
    80001b68:	6105                	addi	sp,sp,32
    80001b6a:	8082                	ret

0000000080001b6c <freeproc>:
{
    80001b6c:	1101                	addi	sp,sp,-32
    80001b6e:	ec06                	sd	ra,24(sp)
    80001b70:	e822                	sd	s0,16(sp)
    80001b72:	e426                	sd	s1,8(sp)
    80001b74:	1000                	addi	s0,sp,32
    80001b76:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b78:	6d28                	ld	a0,88(a0)
    80001b7a:	c509                	beqz	a0,80001b84 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	e96080e7          	jalr	-362(ra) # 80000a12 <kfree>
  p->trapframe = 0;
    80001b84:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b88:	68a8                	ld	a0,80(s1)
    80001b8a:	c511                	beqz	a0,80001b96 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b8c:	64ac                	ld	a1,72(s1)
    80001b8e:	00000097          	auipc	ra,0x0
    80001b92:	f8c080e7          	jalr	-116(ra) # 80001b1a <proc_freepagetable>
  p->pagetable = 0;
    80001b96:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b9a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b9e:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001ba2:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001ba6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001baa:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bae:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bb2:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bb6:	0004ac23          	sw	zero,24(s1)
}
    80001bba:	60e2                	ld	ra,24(sp)
    80001bbc:	6442                	ld	s0,16(sp)
    80001bbe:	64a2                	ld	s1,8(sp)
    80001bc0:	6105                	addi	sp,sp,32
    80001bc2:	8082                	ret

0000000080001bc4 <allocproc>:
{
    80001bc4:	1101                	addi	sp,sp,-32
    80001bc6:	ec06                	sd	ra,24(sp)
    80001bc8:	e822                	sd	s0,16(sp)
    80001bca:	e426                	sd	s1,8(sp)
    80001bcc:	e04a                	sd	s2,0(sp)
    80001bce:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd0:	00010497          	auipc	s1,0x10
    80001bd4:	19848493          	addi	s1,s1,408 # 80011d68 <proc>
    80001bd8:	00016917          	auipc	s2,0x16
    80001bdc:	b9090913          	addi	s2,s2,-1136 # 80017768 <tickslock>
    acquire(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	01c080e7          	jalr	28(ra) # 80000bfe <acquire>
    if(p->state == UNUSED) {
    80001bea:	4c9c                	lw	a5,24(s1)
    80001bec:	cf81                	beqz	a5,80001c04 <allocproc+0x40>
      release(&p->lock);
    80001bee:	8526                	mv	a0,s1
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	0c2080e7          	jalr	194(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf8:	16848493          	addi	s1,s1,360
    80001bfc:	ff2492e3          	bne	s1,s2,80001be0 <allocproc+0x1c>
  return 0;
    80001c00:	4481                	li	s1,0
    80001c02:	a0b9                	j	80001c50 <allocproc+0x8c>
  p->pid = allocpid();
    80001c04:	00000097          	auipc	ra,0x0
    80001c08:	e34080e7          	jalr	-460(ra) # 80001a38 <allocpid>
    80001c0c:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	f00080e7          	jalr	-256(ra) # 80000b0e <kalloc>
    80001c16:	892a                	mv	s2,a0
    80001c18:	eca8                	sd	a0,88(s1)
    80001c1a:	c131                	beqz	a0,80001c5e <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	e60080e7          	jalr	-416(ra) # 80001a7e <proc_pagetable>
    80001c26:	892a                	mv	s2,a0
    80001c28:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c2a:	c129                	beqz	a0,80001c6c <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c2c:	07000613          	li	a2,112
    80001c30:	4581                	li	a1,0
    80001c32:	06048513          	addi	a0,s1,96
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	0c4080e7          	jalr	196(ra) # 80000cfa <memset>
  p->context.ra = (uint64)forkret;
    80001c3e:	00000797          	auipc	a5,0x0
    80001c42:	db478793          	addi	a5,a5,-588 # 800019f2 <forkret>
    80001c46:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c48:	60bc                	ld	a5,64(s1)
    80001c4a:	6705                	lui	a4,0x1
    80001c4c:	97ba                	add	a5,a5,a4
    80001c4e:	f4bc                	sd	a5,104(s1)
}
    80001c50:	8526                	mv	a0,s1
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6902                	ld	s2,0(sp)
    80001c5a:	6105                	addi	sp,sp,32
    80001c5c:	8082                	ret
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	052080e7          	jalr	82(ra) # 80000cb2 <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	b7dd                	j	80001c50 <allocproc+0x8c>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	efe080e7          	jalr	-258(ra) # 80001b6c <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	03a080e7          	jalr	58(ra) # 80000cb2 <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7f9                	j	80001c50 <allocproc+0x8c>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f36080e7          	jalr	-202(ra) # 80001bc4 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	38a7b023          	sd	a0,896(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bbc58593          	addi	a1,a1,-1092 # 80008860 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6f4080e7          	jalr	1780(ra) # 800013a2 <uvminit>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	54258593          	addi	a1,a1,1346 # 80008208 <digits+0x1c8>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	17a080e7          	jalr	378(ra) # 80000e4c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53e50513          	addi	a0,a0,1342 # 80008218 <digits+0x1d8>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	192080e7          	jalr	402(ra) # 80003e74 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	4789                	li	a5,2
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	fbe080e7          	jalr	-66(ra) # 80000cb2 <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	ca6080e7          	jalr	-858(ra) # 800019ba <myproc>
    80001d1c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
    80001d20:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d24:	00904f63          	bgtz	s1,80001d42 <growproc+0x3c>
  } else if(n < 0){
    80001d28:	0204cc63          	bltz	s1,80001d60 <growproc+0x5a>
  p->sz = sz;
    80001d2c:	1602                	slli	a2,a2,0x20
    80001d2e:	9201                	srli	a2,a2,0x20
    80001d30:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d34:	4501                	li	a0,0
}
    80001d36:	60e2                	ld	ra,24(sp)
    80001d38:	6442                	ld	s0,16(sp)
    80001d3a:	64a2                	ld	s1,8(sp)
    80001d3c:	6902                	ld	s2,0(sp)
    80001d3e:	6105                	addi	sp,sp,32
    80001d40:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d42:	9e25                	addw	a2,a2,s1
    80001d44:	1602                	slli	a2,a2,0x20
    80001d46:	9201                	srli	a2,a2,0x20
    80001d48:	1582                	slli	a1,a1,0x20
    80001d4a:	9181                	srli	a1,a1,0x20
    80001d4c:	6928                	ld	a0,80(a0)
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	70e080e7          	jalr	1806(ra) # 8000145c <uvmalloc>
    80001d56:	0005061b          	sext.w	a2,a0
    80001d5a:	fa69                	bnez	a2,80001d2c <growproc+0x26>
      return -1;
    80001d5c:	557d                	li	a0,-1
    80001d5e:	bfe1                	j	80001d36 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d60:	9e25                	addw	a2,a2,s1
    80001d62:	1602                	slli	a2,a2,0x20
    80001d64:	9201                	srli	a2,a2,0x20
    80001d66:	1582                	slli	a1,a1,0x20
    80001d68:	9181                	srli	a1,a1,0x20
    80001d6a:	6928                	ld	a0,80(a0)
    80001d6c:	fffff097          	auipc	ra,0xfffff
    80001d70:	6a8080e7          	jalr	1704(ra) # 80001414 <uvmdealloc>
    80001d74:	0005061b          	sext.w	a2,a0
    80001d78:	bf55                	j	80001d2c <growproc+0x26>

0000000080001d7a <fork>:
{
    80001d7a:	7139                	addi	sp,sp,-64
    80001d7c:	fc06                	sd	ra,56(sp)
    80001d7e:	f822                	sd	s0,48(sp)
    80001d80:	f426                	sd	s1,40(sp)
    80001d82:	f04a                	sd	s2,32(sp)
    80001d84:	ec4e                	sd	s3,24(sp)
    80001d86:	e852                	sd	s4,16(sp)
    80001d88:	e456                	sd	s5,8(sp)
    80001d8a:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	c2e080e7          	jalr	-978(ra) # 800019ba <myproc>
    80001d94:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e2e080e7          	jalr	-466(ra) # 80001bc4 <allocproc>
    80001d9e:	c17d                	beqz	a0,80001e84 <fork+0x10a>
    80001da0:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da2:	048ab603          	ld	a2,72(s5)
    80001da6:	692c                	ld	a1,80(a0)
    80001da8:	050ab503          	ld	a0,80(s5)
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	7fc080e7          	jalr	2044(ra) # 800015a8 <uvmcopy>
    80001db4:	04054a63          	bltz	a0,80001e08 <fork+0x8e>
  np->sz = p->sz;
    80001db8:	048ab783          	ld	a5,72(s5)
    80001dbc:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001dc0:	035a3023          	sd	s5,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001dc4:	058ab683          	ld	a3,88(s5)
    80001dc8:	87b6                	mv	a5,a3
    80001dca:	058a3703          	ld	a4,88(s4)
    80001dce:	12068693          	addi	a3,a3,288
    80001dd2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd6:	6788                	ld	a0,8(a5)
    80001dd8:	6b8c                	ld	a1,16(a5)
    80001dda:	6f90                	ld	a2,24(a5)
    80001ddc:	01073023          	sd	a6,0(a4)
    80001de0:	e708                	sd	a0,8(a4)
    80001de2:	eb0c                	sd	a1,16(a4)
    80001de4:	ef10                	sd	a2,24(a4)
    80001de6:	02078793          	addi	a5,a5,32
    80001dea:	02070713          	addi	a4,a4,32
    80001dee:	fed792e3          	bne	a5,a3,80001dd2 <fork+0x58>
  np->trapframe->a0 = 0;
    80001df2:	058a3783          	ld	a5,88(s4)
    80001df6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dfa:	0d0a8493          	addi	s1,s5,208
    80001dfe:	0d0a0913          	addi	s2,s4,208
    80001e02:	150a8993          	addi	s3,s5,336
    80001e06:	a00d                	j	80001e28 <fork+0xae>
    freeproc(np);
    80001e08:	8552                	mv	a0,s4
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	d62080e7          	jalr	-670(ra) # 80001b6c <freeproc>
    release(&np->lock);
    80001e12:	8552                	mv	a0,s4
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	e9e080e7          	jalr	-354(ra) # 80000cb2 <release>
    return -1;
    80001e1c:	54fd                	li	s1,-1
    80001e1e:	a889                	j	80001e70 <fork+0xf6>
  for(i = 0; i < NOFILE; i++)
    80001e20:	04a1                	addi	s1,s1,8
    80001e22:	0921                	addi	s2,s2,8
    80001e24:	01348b63          	beq	s1,s3,80001e3a <fork+0xc0>
    if(p->ofile[i])
    80001e28:	6088                	ld	a0,0(s1)
    80001e2a:	d97d                	beqz	a0,80001e20 <fork+0xa6>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e2c:	00002097          	auipc	ra,0x2
    80001e30:	6d8080e7          	jalr	1752(ra) # 80004504 <filedup>
    80001e34:	00a93023          	sd	a0,0(s2)
    80001e38:	b7e5                	j	80001e20 <fork+0xa6>
  np->cwd = idup(p->cwd);
    80001e3a:	150ab503          	ld	a0,336(s5)
    80001e3e:	00002097          	auipc	ra,0x2
    80001e42:	848080e7          	jalr	-1976(ra) # 80003686 <idup>
    80001e46:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4a:	4641                	li	a2,16
    80001e4c:	158a8593          	addi	a1,s5,344
    80001e50:	158a0513          	addi	a0,s4,344
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	ff8080e7          	jalr	-8(ra) # 80000e4c <safestrcpy>
  pid = np->pid;
    80001e5c:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80001e60:	4789                	li	a5,2
    80001e62:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e66:	8552                	mv	a0,s4
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e4a080e7          	jalr	-438(ra) # 80000cb2 <release>
}
    80001e70:	8526                	mv	a0,s1
    80001e72:	70e2                	ld	ra,56(sp)
    80001e74:	7442                	ld	s0,48(sp)
    80001e76:	74a2                	ld	s1,40(sp)
    80001e78:	7902                	ld	s2,32(sp)
    80001e7a:	69e2                	ld	s3,24(sp)
    80001e7c:	6a42                	ld	s4,16(sp)
    80001e7e:	6aa2                	ld	s5,8(sp)
    80001e80:	6121                	addi	sp,sp,64
    80001e82:	8082                	ret
    return -1;
    80001e84:	54fd                	li	s1,-1
    80001e86:	b7ed                	j	80001e70 <fork+0xf6>

0000000080001e88 <reparent>:
{
    80001e88:	7179                	addi	sp,sp,-48
    80001e8a:	f406                	sd	ra,40(sp)
    80001e8c:	f022                	sd	s0,32(sp)
    80001e8e:	ec26                	sd	s1,24(sp)
    80001e90:	e84a                	sd	s2,16(sp)
    80001e92:	e44e                	sd	s3,8(sp)
    80001e94:	e052                	sd	s4,0(sp)
    80001e96:	1800                	addi	s0,sp,48
    80001e98:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001e9a:	00010497          	auipc	s1,0x10
    80001e9e:	ece48493          	addi	s1,s1,-306 # 80011d68 <proc>
      pp->parent = initproc;
    80001ea2:	00007a17          	auipc	s4,0x7
    80001ea6:	176a0a13          	addi	s4,s4,374 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eaa:	00016997          	auipc	s3,0x16
    80001eae:	8be98993          	addi	s3,s3,-1858 # 80017768 <tickslock>
    80001eb2:	a029                	j	80001ebc <reparent+0x34>
    80001eb4:	16848493          	addi	s1,s1,360
    80001eb8:	03348363          	beq	s1,s3,80001ede <reparent+0x56>
    if(pp->parent == p){
    80001ebc:	709c                	ld	a5,32(s1)
    80001ebe:	ff279be3          	bne	a5,s2,80001eb4 <reparent+0x2c>
      acquire(&pp->lock);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	fffff097          	auipc	ra,0xfffff
    80001ec8:	d3a080e7          	jalr	-710(ra) # 80000bfe <acquire>
      pp->parent = initproc;
    80001ecc:	000a3783          	ld	a5,0(s4)
    80001ed0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001ed2:	8526                	mv	a0,s1
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	dde080e7          	jalr	-546(ra) # 80000cb2 <release>
    80001edc:	bfe1                	j	80001eb4 <reparent+0x2c>
}
    80001ede:	70a2                	ld	ra,40(sp)
    80001ee0:	7402                	ld	s0,32(sp)
    80001ee2:	64e2                	ld	s1,24(sp)
    80001ee4:	6942                	ld	s2,16(sp)
    80001ee6:	69a2                	ld	s3,8(sp)
    80001ee8:	6a02                	ld	s4,0(sp)
    80001eea:	6145                	addi	sp,sp,48
    80001eec:	8082                	ret

0000000080001eee <scheduler>:
{
    80001eee:	7139                	addi	sp,sp,-64
    80001ef0:	fc06                	sd	ra,56(sp)
    80001ef2:	f822                	sd	s0,48(sp)
    80001ef4:	f426                	sd	s1,40(sp)
    80001ef6:	f04a                	sd	s2,32(sp)
    80001ef8:	ec4e                	sd	s3,24(sp)
    80001efa:	e852                	sd	s4,16(sp)
    80001efc:	e456                	sd	s5,8(sp)
    80001efe:	e05a                	sd	s6,0(sp)
    80001f00:	0080                	addi	s0,sp,64
    80001f02:	8792                	mv	a5,tp
  int id = r_tp();
    80001f04:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f06:	00779a93          	slli	s5,a5,0x7
    80001f0a:	00010717          	auipc	a4,0x10
    80001f0e:	a4670713          	addi	a4,a4,-1466 # 80011950 <pid_lock>
    80001f12:	9756                	add	a4,a4,s5
    80001f14:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f18:	00010717          	auipc	a4,0x10
    80001f1c:	a5870713          	addi	a4,a4,-1448 # 80011970 <cpus+0x8>
    80001f20:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f22:	4989                	li	s3,2
        p->state = RUNNING;
    80001f24:	4b0d                	li	s6,3
        c->proc = p;
    80001f26:	079e                	slli	a5,a5,0x7
    80001f28:	00010a17          	auipc	s4,0x10
    80001f2c:	a28a0a13          	addi	s4,s4,-1496 # 80011950 <pid_lock>
    80001f30:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f32:	00016917          	auipc	s2,0x16
    80001f36:	83690913          	addi	s2,s2,-1994 # 80017768 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f42:	10079073          	csrw	sstatus,a5
    80001f46:	00010497          	auipc	s1,0x10
    80001f4a:	e2248493          	addi	s1,s1,-478 # 80011d68 <proc>
    80001f4e:	a811                	j	80001f62 <scheduler+0x74>
      release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d60080e7          	jalr	-672(ra) # 80000cb2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f5a:	16848493          	addi	s1,s1,360
    80001f5e:	fd248ee3          	beq	s1,s2,80001f3a <scheduler+0x4c>
      acquire(&p->lock);
    80001f62:	8526                	mv	a0,s1
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	c9a080e7          	jalr	-870(ra) # 80000bfe <acquire>
      if(p->state == RUNNABLE) {
    80001f6c:	4c9c                	lw	a5,24(s1)
    80001f6e:	ff3791e3          	bne	a5,s3,80001f50 <scheduler+0x62>
        p->state = RUNNING;
    80001f72:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f76:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f7a:	06048593          	addi	a1,s1,96
    80001f7e:	8556                	mv	a0,s5
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	5e0080e7          	jalr	1504(ra) # 80002560 <swtch>
        c->proc = 0;
    80001f88:	000a3c23          	sd	zero,24(s4)
    80001f8c:	b7d1                	j	80001f50 <scheduler+0x62>

0000000080001f8e <sched>:
{
    80001f8e:	7179                	addi	sp,sp,-48
    80001f90:	f406                	sd	ra,40(sp)
    80001f92:	f022                	sd	s0,32(sp)
    80001f94:	ec26                	sd	s1,24(sp)
    80001f96:	e84a                	sd	s2,16(sp)
    80001f98:	e44e                	sd	s3,8(sp)
    80001f9a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f9c:	00000097          	auipc	ra,0x0
    80001fa0:	a1e080e7          	jalr	-1506(ra) # 800019ba <myproc>
    80001fa4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	bde080e7          	jalr	-1058(ra) # 80000b84 <holding>
    80001fae:	c93d                	beqz	a0,80002024 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb0:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fb2:	2781                	sext.w	a5,a5
    80001fb4:	079e                	slli	a5,a5,0x7
    80001fb6:	00010717          	auipc	a4,0x10
    80001fba:	99a70713          	addi	a4,a4,-1638 # 80011950 <pid_lock>
    80001fbe:	97ba                	add	a5,a5,a4
    80001fc0:	0907a703          	lw	a4,144(a5)
    80001fc4:	4785                	li	a5,1
    80001fc6:	06f71763          	bne	a4,a5,80002034 <sched+0xa6>
  if(p->state == RUNNING)
    80001fca:	4c98                	lw	a4,24(s1)
    80001fcc:	478d                	li	a5,3
    80001fce:	06f70b63          	beq	a4,a5,80002044 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fd6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fd8:	efb5                	bnez	a5,80002054 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fda:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fdc:	00010917          	auipc	s2,0x10
    80001fe0:	97490913          	addi	s2,s2,-1676 # 80011950 <pid_lock>
    80001fe4:	2781                	sext.w	a5,a5
    80001fe6:	079e                	slli	a5,a5,0x7
    80001fe8:	97ca                	add	a5,a5,s2
    80001fea:	0947a983          	lw	s3,148(a5)
    80001fee:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ff0:	2781                	sext.w	a5,a5
    80001ff2:	079e                	slli	a5,a5,0x7
    80001ff4:	00010597          	auipc	a1,0x10
    80001ff8:	97c58593          	addi	a1,a1,-1668 # 80011970 <cpus+0x8>
    80001ffc:	95be                	add	a1,a1,a5
    80001ffe:	06048513          	addi	a0,s1,96
    80002002:	00000097          	auipc	ra,0x0
    80002006:	55e080e7          	jalr	1374(ra) # 80002560 <swtch>
    8000200a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	97ca                	add	a5,a5,s2
    80002012:	0937aa23          	sw	s3,148(a5)
}
    80002016:	70a2                	ld	ra,40(sp)
    80002018:	7402                	ld	s0,32(sp)
    8000201a:	64e2                	ld	s1,24(sp)
    8000201c:	6942                	ld	s2,16(sp)
    8000201e:	69a2                	ld	s3,8(sp)
    80002020:	6145                	addi	sp,sp,48
    80002022:	8082                	ret
    panic("sched p->lock");
    80002024:	00006517          	auipc	a0,0x6
    80002028:	1fc50513          	addi	a0,a0,508 # 80008220 <digits+0x1e0>
    8000202c:	ffffe097          	auipc	ra,0xffffe
    80002030:	516080e7          	jalr	1302(ra) # 80000542 <panic>
    panic("sched locks");
    80002034:	00006517          	auipc	a0,0x6
    80002038:	1fc50513          	addi	a0,a0,508 # 80008230 <digits+0x1f0>
    8000203c:	ffffe097          	auipc	ra,0xffffe
    80002040:	506080e7          	jalr	1286(ra) # 80000542 <panic>
    panic("sched running");
    80002044:	00006517          	auipc	a0,0x6
    80002048:	1fc50513          	addi	a0,a0,508 # 80008240 <digits+0x200>
    8000204c:	ffffe097          	auipc	ra,0xffffe
    80002050:	4f6080e7          	jalr	1270(ra) # 80000542 <panic>
    panic("sched interruptible");
    80002054:	00006517          	auipc	a0,0x6
    80002058:	1fc50513          	addi	a0,a0,508 # 80008250 <digits+0x210>
    8000205c:	ffffe097          	auipc	ra,0xffffe
    80002060:	4e6080e7          	jalr	1254(ra) # 80000542 <panic>

0000000080002064 <exit>:
{
    80002064:	7179                	addi	sp,sp,-48
    80002066:	f406                	sd	ra,40(sp)
    80002068:	f022                	sd	s0,32(sp)
    8000206a:	ec26                	sd	s1,24(sp)
    8000206c:	e84a                	sd	s2,16(sp)
    8000206e:	e44e                	sd	s3,8(sp)
    80002070:	e052                	sd	s4,0(sp)
    80002072:	1800                	addi	s0,sp,48
    80002074:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002076:	00000097          	auipc	ra,0x0
    8000207a:	944080e7          	jalr	-1724(ra) # 800019ba <myproc>
    8000207e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002080:	00007797          	auipc	a5,0x7
    80002084:	f987b783          	ld	a5,-104(a5) # 80009018 <initproc>
    80002088:	0d050493          	addi	s1,a0,208
    8000208c:	15050913          	addi	s2,a0,336
    80002090:	02a79363          	bne	a5,a0,800020b6 <exit+0x52>
    panic("init exiting");
    80002094:	00006517          	auipc	a0,0x6
    80002098:	1d450513          	addi	a0,a0,468 # 80008268 <digits+0x228>
    8000209c:	ffffe097          	auipc	ra,0xffffe
    800020a0:	4a6080e7          	jalr	1190(ra) # 80000542 <panic>
      fileclose(f);
    800020a4:	00002097          	auipc	ra,0x2
    800020a8:	4b2080e7          	jalr	1202(ra) # 80004556 <fileclose>
      p->ofile[fd] = 0;
    800020ac:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020b0:	04a1                	addi	s1,s1,8
    800020b2:	01248563          	beq	s1,s2,800020bc <exit+0x58>
    if(p->ofile[fd]){
    800020b6:	6088                	ld	a0,0(s1)
    800020b8:	f575                	bnez	a0,800020a4 <exit+0x40>
    800020ba:	bfdd                	j	800020b0 <exit+0x4c>
  begin_op();
    800020bc:	00002097          	auipc	ra,0x2
    800020c0:	fc8080e7          	jalr	-56(ra) # 80004084 <begin_op>
  iput(p->cwd);
    800020c4:	1509b503          	ld	a0,336(s3)
    800020c8:	00001097          	auipc	ra,0x1
    800020cc:	7b6080e7          	jalr	1974(ra) # 8000387e <iput>
  end_op();
    800020d0:	00002097          	auipc	ra,0x2
    800020d4:	034080e7          	jalr	52(ra) # 80004104 <end_op>
  p->cwd = 0;
    800020d8:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800020dc:	00007497          	auipc	s1,0x7
    800020e0:	f3c48493          	addi	s1,s1,-196 # 80009018 <initproc>
    800020e4:	6088                	ld	a0,0(s1)
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	b18080e7          	jalr	-1256(ra) # 80000bfe <acquire>
  wakeup1(initproc);
    800020ee:	6088                	ld	a0,0(s1)
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	78a080e7          	jalr	1930(ra) # 8000187a <wakeup1>
  release(&initproc->lock);
    800020f8:	6088                	ld	a0,0(s1)
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	bb8080e7          	jalr	-1096(ra) # 80000cb2 <release>
  acquire(&p->lock);
    80002102:	854e                	mv	a0,s3
    80002104:	fffff097          	auipc	ra,0xfffff
    80002108:	afa080e7          	jalr	-1286(ra) # 80000bfe <acquire>
  struct proc *original_parent = p->parent;
    8000210c:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002110:	854e                	mv	a0,s3
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	ba0080e7          	jalr	-1120(ra) # 80000cb2 <release>
  acquire(&original_parent->lock);
    8000211a:	8526                	mv	a0,s1
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	ae2080e7          	jalr	-1310(ra) # 80000bfe <acquire>
  acquire(&p->lock);
    80002124:	854e                	mv	a0,s3
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	ad8080e7          	jalr	-1320(ra) # 80000bfe <acquire>
  reparent(p);
    8000212e:	854e                	mv	a0,s3
    80002130:	00000097          	auipc	ra,0x0
    80002134:	d58080e7          	jalr	-680(ra) # 80001e88 <reparent>
  wakeup1(original_parent);
    80002138:	8526                	mv	a0,s1
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	740080e7          	jalr	1856(ra) # 8000187a <wakeup1>
  p->xstate = status;
    80002142:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002146:	4791                	li	a5,4
    80002148:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	b64080e7          	jalr	-1180(ra) # 80000cb2 <release>
  sched();
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	e38080e7          	jalr	-456(ra) # 80001f8e <sched>
  panic("zombie exit");
    8000215e:	00006517          	auipc	a0,0x6
    80002162:	11a50513          	addi	a0,a0,282 # 80008278 <digits+0x238>
    80002166:	ffffe097          	auipc	ra,0xffffe
    8000216a:	3dc080e7          	jalr	988(ra) # 80000542 <panic>

000000008000216e <yield>:
{
    8000216e:	1101                	addi	sp,sp,-32
    80002170:	ec06                	sd	ra,24(sp)
    80002172:	e822                	sd	s0,16(sp)
    80002174:	e426                	sd	s1,8(sp)
    80002176:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	842080e7          	jalr	-1982(ra) # 800019ba <myproc>
    80002180:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	a7c080e7          	jalr	-1412(ra) # 80000bfe <acquire>
  p->state = RUNNABLE;
    8000218a:	4789                	li	a5,2
    8000218c:	cc9c                	sw	a5,24(s1)
  sched();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	e00080e7          	jalr	-512(ra) # 80001f8e <sched>
  release(&p->lock);
    80002196:	8526                	mv	a0,s1
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	b1a080e7          	jalr	-1254(ra) # 80000cb2 <release>
}
    800021a0:	60e2                	ld	ra,24(sp)
    800021a2:	6442                	ld	s0,16(sp)
    800021a4:	64a2                	ld	s1,8(sp)
    800021a6:	6105                	addi	sp,sp,32
    800021a8:	8082                	ret

00000000800021aa <sleep>:
{
    800021aa:	7179                	addi	sp,sp,-48
    800021ac:	f406                	sd	ra,40(sp)
    800021ae:	f022                	sd	s0,32(sp)
    800021b0:	ec26                	sd	s1,24(sp)
    800021b2:	e84a                	sd	s2,16(sp)
    800021b4:	e44e                	sd	s3,8(sp)
    800021b6:	1800                	addi	s0,sp,48
    800021b8:	89aa                	mv	s3,a0
    800021ba:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	7fe080e7          	jalr	2046(ra) # 800019ba <myproc>
    800021c4:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800021c6:	05250663          	beq	a0,s2,80002212 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800021ca:	fffff097          	auipc	ra,0xfffff
    800021ce:	a34080e7          	jalr	-1484(ra) # 80000bfe <acquire>
    release(lk);
    800021d2:	854a                	mv	a0,s2
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	ade080e7          	jalr	-1314(ra) # 80000cb2 <release>
  p->chan = chan;
    800021dc:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800021e0:	4785                	li	a5,1
    800021e2:	cc9c                	sw	a5,24(s1)
  sched();
    800021e4:	00000097          	auipc	ra,0x0
    800021e8:	daa080e7          	jalr	-598(ra) # 80001f8e <sched>
  p->chan = 0;
    800021ec:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	ac0080e7          	jalr	-1344(ra) # 80000cb2 <release>
    acquire(lk);
    800021fa:	854a                	mv	a0,s2
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	a02080e7          	jalr	-1534(ra) # 80000bfe <acquire>
}
    80002204:	70a2                	ld	ra,40(sp)
    80002206:	7402                	ld	s0,32(sp)
    80002208:	64e2                	ld	s1,24(sp)
    8000220a:	6942                	ld	s2,16(sp)
    8000220c:	69a2                	ld	s3,8(sp)
    8000220e:	6145                	addi	sp,sp,48
    80002210:	8082                	ret
  p->chan = chan;
    80002212:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002216:	4785                	li	a5,1
    80002218:	cd1c                	sw	a5,24(a0)
  sched();
    8000221a:	00000097          	auipc	ra,0x0
    8000221e:	d74080e7          	jalr	-652(ra) # 80001f8e <sched>
  p->chan = 0;
    80002222:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002226:	bff9                	j	80002204 <sleep+0x5a>

0000000080002228 <wait>:
{
    80002228:	715d                	addi	sp,sp,-80
    8000222a:	e486                	sd	ra,72(sp)
    8000222c:	e0a2                	sd	s0,64(sp)
    8000222e:	fc26                	sd	s1,56(sp)
    80002230:	f84a                	sd	s2,48(sp)
    80002232:	f44e                	sd	s3,40(sp)
    80002234:	f052                	sd	s4,32(sp)
    80002236:	ec56                	sd	s5,24(sp)
    80002238:	e85a                	sd	s6,16(sp)
    8000223a:	e45e                	sd	s7,8(sp)
    8000223c:	0880                	addi	s0,sp,80
    8000223e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	77a080e7          	jalr	1914(ra) # 800019ba <myproc>
    80002248:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	9b4080e7          	jalr	-1612(ra) # 80000bfe <acquire>
    havekids = 0;
    80002252:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002254:	4a11                	li	s4,4
        havekids = 1;
    80002256:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002258:	00015997          	auipc	s3,0x15
    8000225c:	51098993          	addi	s3,s3,1296 # 80017768 <tickslock>
    havekids = 0;
    80002260:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002262:	00010497          	auipc	s1,0x10
    80002266:	b0648493          	addi	s1,s1,-1274 # 80011d68 <proc>
    8000226a:	a08d                	j	800022cc <wait+0xa4>
          pid = np->pid;
    8000226c:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002270:	000b0e63          	beqz	s6,8000228c <wait+0x64>
    80002274:	4691                	li	a3,4
    80002276:	03448613          	addi	a2,s1,52
    8000227a:	85da                	mv	a1,s6
    8000227c:	05093503          	ld	a0,80(s2)
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	42c080e7          	jalr	1068(ra) # 800016ac <copyout>
    80002288:	02054263          	bltz	a0,800022ac <wait+0x84>
          freeproc(np);
    8000228c:	8526                	mv	a0,s1
    8000228e:	00000097          	auipc	ra,0x0
    80002292:	8de080e7          	jalr	-1826(ra) # 80001b6c <freeproc>
          release(&np->lock);
    80002296:	8526                	mv	a0,s1
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	a1a080e7          	jalr	-1510(ra) # 80000cb2 <release>
          release(&p->lock);
    800022a0:	854a                	mv	a0,s2
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	a10080e7          	jalr	-1520(ra) # 80000cb2 <release>
          return pid;
    800022aa:	a8a9                	j	80002304 <wait+0xdc>
            release(&np->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	a04080e7          	jalr	-1532(ra) # 80000cb2 <release>
            release(&p->lock);
    800022b6:	854a                	mv	a0,s2
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	9fa080e7          	jalr	-1542(ra) # 80000cb2 <release>
            return -1;
    800022c0:	59fd                	li	s3,-1
    800022c2:	a089                	j	80002304 <wait+0xdc>
    for(np = proc; np < &proc[NPROC]; np++){
    800022c4:	16848493          	addi	s1,s1,360
    800022c8:	03348463          	beq	s1,s3,800022f0 <wait+0xc8>
      if(np->parent == p){
    800022cc:	709c                	ld	a5,32(s1)
    800022ce:	ff279be3          	bne	a5,s2,800022c4 <wait+0x9c>
        acquire(&np->lock);
    800022d2:	8526                	mv	a0,s1
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	92a080e7          	jalr	-1750(ra) # 80000bfe <acquire>
        if(np->state == ZOMBIE){
    800022dc:	4c9c                	lw	a5,24(s1)
    800022de:	f94787e3          	beq	a5,s4,8000226c <wait+0x44>
        release(&np->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	9ce080e7          	jalr	-1586(ra) # 80000cb2 <release>
        havekids = 1;
    800022ec:	8756                	mv	a4,s5
    800022ee:	bfd9                	j	800022c4 <wait+0x9c>
    if(!havekids || p->killed){
    800022f0:	c701                	beqz	a4,800022f8 <wait+0xd0>
    800022f2:	03092783          	lw	a5,48(s2)
    800022f6:	c39d                	beqz	a5,8000231c <wait+0xf4>
      release(&p->lock);
    800022f8:	854a                	mv	a0,s2
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	9b8080e7          	jalr	-1608(ra) # 80000cb2 <release>
      return -1;
    80002302:	59fd                	li	s3,-1
}
    80002304:	854e                	mv	a0,s3
    80002306:	60a6                	ld	ra,72(sp)
    80002308:	6406                	ld	s0,64(sp)
    8000230a:	74e2                	ld	s1,56(sp)
    8000230c:	7942                	ld	s2,48(sp)
    8000230e:	79a2                	ld	s3,40(sp)
    80002310:	7a02                	ld	s4,32(sp)
    80002312:	6ae2                	ld	s5,24(sp)
    80002314:	6b42                	ld	s6,16(sp)
    80002316:	6ba2                	ld	s7,8(sp)
    80002318:	6161                	addi	sp,sp,80
    8000231a:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000231c:	85ca                	mv	a1,s2
    8000231e:	854a                	mv	a0,s2
    80002320:	00000097          	auipc	ra,0x0
    80002324:	e8a080e7          	jalr	-374(ra) # 800021aa <sleep>
    havekids = 0;
    80002328:	bf25                	j	80002260 <wait+0x38>

000000008000232a <wakeup>:
{
    8000232a:	7139                	addi	sp,sp,-64
    8000232c:	fc06                	sd	ra,56(sp)
    8000232e:	f822                	sd	s0,48(sp)
    80002330:	f426                	sd	s1,40(sp)
    80002332:	f04a                	sd	s2,32(sp)
    80002334:	ec4e                	sd	s3,24(sp)
    80002336:	e852                	sd	s4,16(sp)
    80002338:	e456                	sd	s5,8(sp)
    8000233a:	0080                	addi	s0,sp,64
    8000233c:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000233e:	00010497          	auipc	s1,0x10
    80002342:	a2a48493          	addi	s1,s1,-1494 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002346:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002348:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000234a:	00015917          	auipc	s2,0x15
    8000234e:	41e90913          	addi	s2,s2,1054 # 80017768 <tickslock>
    80002352:	a811                	j	80002366 <wakeup+0x3c>
    release(&p->lock);
    80002354:	8526                	mv	a0,s1
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	95c080e7          	jalr	-1700(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000235e:	16848493          	addi	s1,s1,360
    80002362:	03248063          	beq	s1,s2,80002382 <wakeup+0x58>
    acquire(&p->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	896080e7          	jalr	-1898(ra) # 80000bfe <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002370:	4c9c                	lw	a5,24(s1)
    80002372:	ff3791e3          	bne	a5,s3,80002354 <wakeup+0x2a>
    80002376:	749c                	ld	a5,40(s1)
    80002378:	fd479ee3          	bne	a5,s4,80002354 <wakeup+0x2a>
      p->state = RUNNABLE;
    8000237c:	0154ac23          	sw	s5,24(s1)
    80002380:	bfd1                	j	80002354 <wakeup+0x2a>
}
    80002382:	70e2                	ld	ra,56(sp)
    80002384:	7442                	ld	s0,48(sp)
    80002386:	74a2                	ld	s1,40(sp)
    80002388:	7902                	ld	s2,32(sp)
    8000238a:	69e2                	ld	s3,24(sp)
    8000238c:	6a42                	ld	s4,16(sp)
    8000238e:	6aa2                	ld	s5,8(sp)
    80002390:	6121                	addi	sp,sp,64
    80002392:	8082                	ret

0000000080002394 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002394:	7179                	addi	sp,sp,-48
    80002396:	f406                	sd	ra,40(sp)
    80002398:	f022                	sd	s0,32(sp)
    8000239a:	ec26                	sd	s1,24(sp)
    8000239c:	e84a                	sd	s2,16(sp)
    8000239e:	e44e                	sd	s3,8(sp)
    800023a0:	1800                	addi	s0,sp,48
    800023a2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023a4:	00010497          	auipc	s1,0x10
    800023a8:	9c448493          	addi	s1,s1,-1596 # 80011d68 <proc>
    800023ac:	00015997          	auipc	s3,0x15
    800023b0:	3bc98993          	addi	s3,s3,956 # 80017768 <tickslock>
    acquire(&p->lock);
    800023b4:	8526                	mv	a0,s1
    800023b6:	fffff097          	auipc	ra,0xfffff
    800023ba:	848080e7          	jalr	-1976(ra) # 80000bfe <acquire>
    if(p->pid == pid){
    800023be:	5c9c                	lw	a5,56(s1)
    800023c0:	01278d63          	beq	a5,s2,800023da <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	8ec080e7          	jalr	-1812(ra) # 80000cb2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023ce:	16848493          	addi	s1,s1,360
    800023d2:	ff3491e3          	bne	s1,s3,800023b4 <kill+0x20>
  }
  return -1;
    800023d6:	557d                	li	a0,-1
    800023d8:	a821                	j	800023f0 <kill+0x5c>
      p->killed = 1;
    800023da:	4785                	li	a5,1
    800023dc:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800023de:	4c98                	lw	a4,24(s1)
    800023e0:	00f70f63          	beq	a4,a5,800023fe <kill+0x6a>
      release(&p->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	8cc080e7          	jalr	-1844(ra) # 80000cb2 <release>
      return 0;
    800023ee:	4501                	li	a0,0
}
    800023f0:	70a2                	ld	ra,40(sp)
    800023f2:	7402                	ld	s0,32(sp)
    800023f4:	64e2                	ld	s1,24(sp)
    800023f6:	6942                	ld	s2,16(sp)
    800023f8:	69a2                	ld	s3,8(sp)
    800023fa:	6145                	addi	sp,sp,48
    800023fc:	8082                	ret
        p->state = RUNNABLE;
    800023fe:	4789                	li	a5,2
    80002400:	cc9c                	sw	a5,24(s1)
    80002402:	b7cd                	j	800023e4 <kill+0x50>

0000000080002404 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002404:	7179                	addi	sp,sp,-48
    80002406:	f406                	sd	ra,40(sp)
    80002408:	f022                	sd	s0,32(sp)
    8000240a:	ec26                	sd	s1,24(sp)
    8000240c:	e84a                	sd	s2,16(sp)
    8000240e:	e44e                	sd	s3,8(sp)
    80002410:	e052                	sd	s4,0(sp)
    80002412:	1800                	addi	s0,sp,48
    80002414:	84aa                	mv	s1,a0
    80002416:	892e                	mv	s2,a1
    80002418:	89b2                	mv	s3,a2
    8000241a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	59e080e7          	jalr	1438(ra) # 800019ba <myproc>
  if(user_dst){
    80002424:	c08d                	beqz	s1,80002446 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002426:	86d2                	mv	a3,s4
    80002428:	864e                	mv	a2,s3
    8000242a:	85ca                	mv	a1,s2
    8000242c:	6928                	ld	a0,80(a0)
    8000242e:	fffff097          	auipc	ra,0xfffff
    80002432:	27e080e7          	jalr	638(ra) # 800016ac <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002436:	70a2                	ld	ra,40(sp)
    80002438:	7402                	ld	s0,32(sp)
    8000243a:	64e2                	ld	s1,24(sp)
    8000243c:	6942                	ld	s2,16(sp)
    8000243e:	69a2                	ld	s3,8(sp)
    80002440:	6a02                	ld	s4,0(sp)
    80002442:	6145                	addi	sp,sp,48
    80002444:	8082                	ret
    memmove((char *)dst, src, len);
    80002446:	000a061b          	sext.w	a2,s4
    8000244a:	85ce                	mv	a1,s3
    8000244c:	854a                	mv	a0,s2
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	908080e7          	jalr	-1784(ra) # 80000d56 <memmove>
    return 0;
    80002456:	8526                	mv	a0,s1
    80002458:	bff9                	j	80002436 <either_copyout+0x32>

000000008000245a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000245a:	7179                	addi	sp,sp,-48
    8000245c:	f406                	sd	ra,40(sp)
    8000245e:	f022                	sd	s0,32(sp)
    80002460:	ec26                	sd	s1,24(sp)
    80002462:	e84a                	sd	s2,16(sp)
    80002464:	e44e                	sd	s3,8(sp)
    80002466:	e052                	sd	s4,0(sp)
    80002468:	1800                	addi	s0,sp,48
    8000246a:	892a                	mv	s2,a0
    8000246c:	84ae                	mv	s1,a1
    8000246e:	89b2                	mv	s3,a2
    80002470:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002472:	fffff097          	auipc	ra,0xfffff
    80002476:	548080e7          	jalr	1352(ra) # 800019ba <myproc>
  if(user_src){
    8000247a:	c08d                	beqz	s1,8000249c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000247c:	86d2                	mv	a3,s4
    8000247e:	864e                	mv	a2,s3
    80002480:	85ca                	mv	a1,s2
    80002482:	6928                	ld	a0,80(a0)
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	2b4080e7          	jalr	692(ra) # 80001738 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000248c:	70a2                	ld	ra,40(sp)
    8000248e:	7402                	ld	s0,32(sp)
    80002490:	64e2                	ld	s1,24(sp)
    80002492:	6942                	ld	s2,16(sp)
    80002494:	69a2                	ld	s3,8(sp)
    80002496:	6a02                	ld	s4,0(sp)
    80002498:	6145                	addi	sp,sp,48
    8000249a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000249c:	000a061b          	sext.w	a2,s4
    800024a0:	85ce                	mv	a1,s3
    800024a2:	854a                	mv	a0,s2
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	8b2080e7          	jalr	-1870(ra) # 80000d56 <memmove>
    return 0;
    800024ac:	8526                	mv	a0,s1
    800024ae:	bff9                	j	8000248c <either_copyin+0x32>

00000000800024b0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024b0:	715d                	addi	sp,sp,-80
    800024b2:	e486                	sd	ra,72(sp)
    800024b4:	e0a2                	sd	s0,64(sp)
    800024b6:	fc26                	sd	s1,56(sp)
    800024b8:	f84a                	sd	s2,48(sp)
    800024ba:	f44e                	sd	s3,40(sp)
    800024bc:	f052                	sd	s4,32(sp)
    800024be:	ec56                	sd	s5,24(sp)
    800024c0:	e85a                	sd	s6,16(sp)
    800024c2:	e45e                	sd	s7,8(sp)
    800024c4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024c6:	00006517          	auipc	a0,0x6
    800024ca:	c2250513          	addi	a0,a0,-990 # 800080e8 <digits+0xa8>
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	0be080e7          	jalr	190(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800024d6:	00010497          	auipc	s1,0x10
    800024da:	9ea48493          	addi	s1,s1,-1558 # 80011ec0 <proc+0x158>
    800024de:	00015917          	auipc	s2,0x15
    800024e2:	3e290913          	addi	s2,s2,994 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800024e6:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800024e8:	00006997          	auipc	s3,0x6
    800024ec:	da098993          	addi	s3,s3,-608 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800024f0:	00006a97          	auipc	s5,0x6
    800024f4:	da0a8a93          	addi	s5,s5,-608 # 80008290 <digits+0x250>
    printf("\n");
    800024f8:	00006a17          	auipc	s4,0x6
    800024fc:	bf0a0a13          	addi	s4,s4,-1040 # 800080e8 <digits+0xa8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002500:	00006b97          	auipc	s7,0x6
    80002504:	dc8b8b93          	addi	s7,s7,-568 # 800082c8 <states.0>
    80002508:	a00d                	j	8000252a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000250a:	ee06a583          	lw	a1,-288(a3)
    8000250e:	8556                	mv	a0,s5
    80002510:	ffffe097          	auipc	ra,0xffffe
    80002514:	07c080e7          	jalr	124(ra) # 8000058c <printf>
    printf("\n");
    80002518:	8552                	mv	a0,s4
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	072080e7          	jalr	114(ra) # 8000058c <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002522:	16848493          	addi	s1,s1,360
    80002526:	03248263          	beq	s1,s2,8000254a <procdump+0x9a>
    if(p->state == UNUSED)
    8000252a:	86a6                	mv	a3,s1
    8000252c:	ec04a783          	lw	a5,-320(s1)
    80002530:	dbed                	beqz	a5,80002522 <procdump+0x72>
      state = "???";
    80002532:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002534:	fcfb6be3          	bltu	s6,a5,8000250a <procdump+0x5a>
    80002538:	02079713          	slli	a4,a5,0x20
    8000253c:	01d75793          	srli	a5,a4,0x1d
    80002540:	97de                	add	a5,a5,s7
    80002542:	6390                	ld	a2,0(a5)
    80002544:	f279                	bnez	a2,8000250a <procdump+0x5a>
      state = "???";
    80002546:	864e                	mv	a2,s3
    80002548:	b7c9                	j	8000250a <procdump+0x5a>
  }
}
    8000254a:	60a6                	ld	ra,72(sp)
    8000254c:	6406                	ld	s0,64(sp)
    8000254e:	74e2                	ld	s1,56(sp)
    80002550:	7942                	ld	s2,48(sp)
    80002552:	79a2                	ld	s3,40(sp)
    80002554:	7a02                	ld	s4,32(sp)
    80002556:	6ae2                	ld	s5,24(sp)
    80002558:	6b42                	ld	s6,16(sp)
    8000255a:	6ba2                	ld	s7,8(sp)
    8000255c:	6161                	addi	sp,sp,80
    8000255e:	8082                	ret

0000000080002560 <swtch>:
    80002560:	00153023          	sd	ra,0(a0)
    80002564:	00253423          	sd	sp,8(a0)
    80002568:	e900                	sd	s0,16(a0)
    8000256a:	ed04                	sd	s1,24(a0)
    8000256c:	03253023          	sd	s2,32(a0)
    80002570:	03353423          	sd	s3,40(a0)
    80002574:	03453823          	sd	s4,48(a0)
    80002578:	03553c23          	sd	s5,56(a0)
    8000257c:	05653023          	sd	s6,64(a0)
    80002580:	05753423          	sd	s7,72(a0)
    80002584:	05853823          	sd	s8,80(a0)
    80002588:	05953c23          	sd	s9,88(a0)
    8000258c:	07a53023          	sd	s10,96(a0)
    80002590:	07b53423          	sd	s11,104(a0)
    80002594:	0005b083          	ld	ra,0(a1)
    80002598:	0085b103          	ld	sp,8(a1)
    8000259c:	6980                	ld	s0,16(a1)
    8000259e:	6d84                	ld	s1,24(a1)
    800025a0:	0205b903          	ld	s2,32(a1)
    800025a4:	0285b983          	ld	s3,40(a1)
    800025a8:	0305ba03          	ld	s4,48(a1)
    800025ac:	0385ba83          	ld	s5,56(a1)
    800025b0:	0405bb03          	ld	s6,64(a1)
    800025b4:	0485bb83          	ld	s7,72(a1)
    800025b8:	0505bc03          	ld	s8,80(a1)
    800025bc:	0585bc83          	ld	s9,88(a1)
    800025c0:	0605bd03          	ld	s10,96(a1)
    800025c4:	0685bd83          	ld	s11,104(a1)
    800025c8:	8082                	ret

00000000800025ca <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025ca:	1141                	addi	sp,sp,-16
    800025cc:	e406                	sd	ra,8(sp)
    800025ce:	e022                	sd	s0,0(sp)
    800025d0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025d2:	00006597          	auipc	a1,0x6
    800025d6:	d1e58593          	addi	a1,a1,-738 # 800082f0 <states.0+0x28>
    800025da:	00015517          	auipc	a0,0x15
    800025de:	18e50513          	addi	a0,a0,398 # 80017768 <tickslock>
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	58c080e7          	jalr	1420(ra) # 80000b6e <initlock>
}
    800025ea:	60a2                	ld	ra,8(sp)
    800025ec:	6402                	ld	s0,0(sp)
    800025ee:	0141                	addi	sp,sp,16
    800025f0:	8082                	ret

00000000800025f2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800025f2:	1141                	addi	sp,sp,-16
    800025f4:	e422                	sd	s0,8(sp)
    800025f6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800025f8:	00003797          	auipc	a5,0x3
    800025fc:	5b878793          	addi	a5,a5,1464 # 80005bb0 <kernelvec>
    80002600:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002604:	6422                	ld	s0,8(sp)
    80002606:	0141                	addi	sp,sp,16
    80002608:	8082                	ret

000000008000260a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000260a:	1141                	addi	sp,sp,-16
    8000260c:	e406                	sd	ra,8(sp)
    8000260e:	e022                	sd	s0,0(sp)
    80002610:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002612:	fffff097          	auipc	ra,0xfffff
    80002616:	3a8080e7          	jalr	936(ra) # 800019ba <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000261a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000261e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002620:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002624:	00005617          	auipc	a2,0x5
    80002628:	9dc60613          	addi	a2,a2,-1572 # 80007000 <_trampoline>
    8000262c:	00005697          	auipc	a3,0x5
    80002630:	9d468693          	addi	a3,a3,-1580 # 80007000 <_trampoline>
    80002634:	8e91                	sub	a3,a3,a2
    80002636:	040007b7          	lui	a5,0x4000
    8000263a:	17fd                	addi	a5,a5,-1
    8000263c:	07b2                	slli	a5,a5,0xc
    8000263e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002640:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002644:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002646:	180026f3          	csrr	a3,satp
    8000264a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000264c:	6d38                	ld	a4,88(a0)
    8000264e:	6134                	ld	a3,64(a0)
    80002650:	6585                	lui	a1,0x1
    80002652:	96ae                	add	a3,a3,a1
    80002654:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002656:	6d38                	ld	a4,88(a0)
    80002658:	00000697          	auipc	a3,0x0
    8000265c:	13868693          	addi	a3,a3,312 # 80002790 <usertrap>
    80002660:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002662:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002664:	8692                	mv	a3,tp
    80002666:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002668:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000266c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002670:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002674:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002678:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000267a:	6f18                	ld	a4,24(a4)
    8000267c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002680:	692c                	ld	a1,80(a0)
    80002682:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002684:	00005717          	auipc	a4,0x5
    80002688:	a0c70713          	addi	a4,a4,-1524 # 80007090 <userret>
    8000268c:	8f11                	sub	a4,a4,a2
    8000268e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002690:	577d                	li	a4,-1
    80002692:	177e                	slli	a4,a4,0x3f
    80002694:	8dd9                	or	a1,a1,a4
    80002696:	02000537          	lui	a0,0x2000
    8000269a:	157d                	addi	a0,a0,-1
    8000269c:	0536                	slli	a0,a0,0xd
    8000269e:	9782                	jalr	a5
}
    800026a0:	60a2                	ld	ra,8(sp)
    800026a2:	6402                	ld	s0,0(sp)
    800026a4:	0141                	addi	sp,sp,16
    800026a6:	8082                	ret

00000000800026a8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026a8:	1101                	addi	sp,sp,-32
    800026aa:	ec06                	sd	ra,24(sp)
    800026ac:	e822                	sd	s0,16(sp)
    800026ae:	e426                	sd	s1,8(sp)
    800026b0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026b2:	00015497          	auipc	s1,0x15
    800026b6:	0b648493          	addi	s1,s1,182 # 80017768 <tickslock>
    800026ba:	8526                	mv	a0,s1
    800026bc:	ffffe097          	auipc	ra,0xffffe
    800026c0:	542080e7          	jalr	1346(ra) # 80000bfe <acquire>
  ticks++;
    800026c4:	00007517          	auipc	a0,0x7
    800026c8:	95c50513          	addi	a0,a0,-1700 # 80009020 <ticks>
    800026cc:	411c                	lw	a5,0(a0)
    800026ce:	2785                	addiw	a5,a5,1
    800026d0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026d2:	00000097          	auipc	ra,0x0
    800026d6:	c58080e7          	jalr	-936(ra) # 8000232a <wakeup>
  release(&tickslock);
    800026da:	8526                	mv	a0,s1
    800026dc:	ffffe097          	auipc	ra,0xffffe
    800026e0:	5d6080e7          	jalr	1494(ra) # 80000cb2 <release>
}
    800026e4:	60e2                	ld	ra,24(sp)
    800026e6:	6442                	ld	s0,16(sp)
    800026e8:	64a2                	ld	s1,8(sp)
    800026ea:	6105                	addi	sp,sp,32
    800026ec:	8082                	ret

00000000800026ee <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800026ee:	1101                	addi	sp,sp,-32
    800026f0:	ec06                	sd	ra,24(sp)
    800026f2:	e822                	sd	s0,16(sp)
    800026f4:	e426                	sd	s1,8(sp)
    800026f6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800026f8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800026fc:	00074d63          	bltz	a4,80002716 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002700:	57fd                	li	a5,-1
    80002702:	17fe                	slli	a5,a5,0x3f
    80002704:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002706:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002708:	06f70363          	beq	a4,a5,8000276e <devintr+0x80>
  }
}
    8000270c:	60e2                	ld	ra,24(sp)
    8000270e:	6442                	ld	s0,16(sp)
    80002710:	64a2                	ld	s1,8(sp)
    80002712:	6105                	addi	sp,sp,32
    80002714:	8082                	ret
     (scause & 0xff) == 9){
    80002716:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000271a:	46a5                	li	a3,9
    8000271c:	fed792e3          	bne	a5,a3,80002700 <devintr+0x12>
    int irq = plic_claim();
    80002720:	00003097          	auipc	ra,0x3
    80002724:	598080e7          	jalr	1432(ra) # 80005cb8 <plic_claim>
    80002728:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000272a:	47a9                	li	a5,10
    8000272c:	02f50763          	beq	a0,a5,8000275a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002730:	4785                	li	a5,1
    80002732:	02f50963          	beq	a0,a5,80002764 <devintr+0x76>
    return 1;
    80002736:	4505                	li	a0,1
    } else if(irq){
    80002738:	d8f1                	beqz	s1,8000270c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000273a:	85a6                	mv	a1,s1
    8000273c:	00006517          	auipc	a0,0x6
    80002740:	bbc50513          	addi	a0,a0,-1092 # 800082f8 <states.0+0x30>
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	e48080e7          	jalr	-440(ra) # 8000058c <printf>
      plic_complete(irq);
    8000274c:	8526                	mv	a0,s1
    8000274e:	00003097          	auipc	ra,0x3
    80002752:	58e080e7          	jalr	1422(ra) # 80005cdc <plic_complete>
    return 1;
    80002756:	4505                	li	a0,1
    80002758:	bf55                	j	8000270c <devintr+0x1e>
      uartintr();
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	268080e7          	jalr	616(ra) # 800009c2 <uartintr>
    80002762:	b7ed                	j	8000274c <devintr+0x5e>
      virtio_disk_intr();
    80002764:	00004097          	auipc	ra,0x4
    80002768:	9f2080e7          	jalr	-1550(ra) # 80006156 <virtio_disk_intr>
    8000276c:	b7c5                	j	8000274c <devintr+0x5e>
    if(cpuid() == 0){
    8000276e:	fffff097          	auipc	ra,0xfffff
    80002772:	220080e7          	jalr	544(ra) # 8000198e <cpuid>
    80002776:	c901                	beqz	a0,80002786 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002778:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000277c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000277e:	14479073          	csrw	sip,a5
    return 2;
    80002782:	4509                	li	a0,2
    80002784:	b761                	j	8000270c <devintr+0x1e>
      clockintr();
    80002786:	00000097          	auipc	ra,0x0
    8000278a:	f22080e7          	jalr	-222(ra) # 800026a8 <clockintr>
    8000278e:	b7ed                	j	80002778 <devintr+0x8a>

0000000080002790 <usertrap>:
{
    80002790:	1101                	addi	sp,sp,-32
    80002792:	ec06                	sd	ra,24(sp)
    80002794:	e822                	sd	s0,16(sp)
    80002796:	e426                	sd	s1,8(sp)
    80002798:	e04a                	sd	s2,0(sp)
    8000279a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000279c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027a0:	1007f793          	andi	a5,a5,256
    800027a4:	e3ad                	bnez	a5,80002806 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027a6:	00003797          	auipc	a5,0x3
    800027aa:	40a78793          	addi	a5,a5,1034 # 80005bb0 <kernelvec>
    800027ae:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	208080e7          	jalr	520(ra) # 800019ba <myproc>
    800027ba:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027bc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027be:	14102773          	csrr	a4,sepc
    800027c2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027c4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027c8:	47a1                	li	a5,8
    800027ca:	04f71c63          	bne	a4,a5,80002822 <usertrap+0x92>
    if(p->killed)
    800027ce:	591c                	lw	a5,48(a0)
    800027d0:	e3b9                	bnez	a5,80002816 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027d2:	6cb8                	ld	a4,88(s1)
    800027d4:	6f1c                	ld	a5,24(a4)
    800027d6:	0791                	addi	a5,a5,4
    800027d8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027da:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027de:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027e2:	10079073          	csrw	sstatus,a5
    syscall();
    800027e6:	00000097          	auipc	ra,0x0
    800027ea:	2e0080e7          	jalr	736(ra) # 80002ac6 <syscall>
  if(p->killed)
    800027ee:	589c                	lw	a5,48(s1)
    800027f0:	ebc1                	bnez	a5,80002880 <usertrap+0xf0>
  usertrapret();
    800027f2:	00000097          	auipc	ra,0x0
    800027f6:	e18080e7          	jalr	-488(ra) # 8000260a <usertrapret>
}
    800027fa:	60e2                	ld	ra,24(sp)
    800027fc:	6442                	ld	s0,16(sp)
    800027fe:	64a2                	ld	s1,8(sp)
    80002800:	6902                	ld	s2,0(sp)
    80002802:	6105                	addi	sp,sp,32
    80002804:	8082                	ret
    panic("usertrap: not from user mode");
    80002806:	00006517          	auipc	a0,0x6
    8000280a:	b1250513          	addi	a0,a0,-1262 # 80008318 <states.0+0x50>
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	d34080e7          	jalr	-716(ra) # 80000542 <panic>
      exit(-1);
    80002816:	557d                	li	a0,-1
    80002818:	00000097          	auipc	ra,0x0
    8000281c:	84c080e7          	jalr	-1972(ra) # 80002064 <exit>
    80002820:	bf4d                	j	800027d2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002822:	00000097          	auipc	ra,0x0
    80002826:	ecc080e7          	jalr	-308(ra) # 800026ee <devintr>
    8000282a:	892a                	mv	s2,a0
    8000282c:	c501                	beqz	a0,80002834 <usertrap+0xa4>
  if(p->killed)
    8000282e:	589c                	lw	a5,48(s1)
    80002830:	c3a1                	beqz	a5,80002870 <usertrap+0xe0>
    80002832:	a815                	j	80002866 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002834:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002838:	5c90                	lw	a2,56(s1)
    8000283a:	00006517          	auipc	a0,0x6
    8000283e:	afe50513          	addi	a0,a0,-1282 # 80008338 <states.0+0x70>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	d4a080e7          	jalr	-694(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000284a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000284e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002852:	00006517          	auipc	a0,0x6
    80002856:	b1650513          	addi	a0,a0,-1258 # 80008368 <states.0+0xa0>
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	d32080e7          	jalr	-718(ra) # 8000058c <printf>
    p->killed = 1;
    80002862:	4785                	li	a5,1
    80002864:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002866:	557d                	li	a0,-1
    80002868:	fffff097          	auipc	ra,0xfffff
    8000286c:	7fc080e7          	jalr	2044(ra) # 80002064 <exit>
  if(which_dev == 2)
    80002870:	4789                	li	a5,2
    80002872:	f8f910e3          	bne	s2,a5,800027f2 <usertrap+0x62>
    yield();
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	8f8080e7          	jalr	-1800(ra) # 8000216e <yield>
    8000287e:	bf95                	j	800027f2 <usertrap+0x62>
  int which_dev = 0;
    80002880:	4901                	li	s2,0
    80002882:	b7d5                	j	80002866 <usertrap+0xd6>

0000000080002884 <kerneltrap>:
{
    80002884:	7179                	addi	sp,sp,-48
    80002886:	f406                	sd	ra,40(sp)
    80002888:	f022                	sd	s0,32(sp)
    8000288a:	ec26                	sd	s1,24(sp)
    8000288c:	e84a                	sd	s2,16(sp)
    8000288e:	e44e                	sd	s3,8(sp)
    80002890:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002892:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002896:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000289a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000289e:	1004f793          	andi	a5,s1,256
    800028a2:	cb85                	beqz	a5,800028d2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028a8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028aa:	ef85                	bnez	a5,800028e2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	e42080e7          	jalr	-446(ra) # 800026ee <devintr>
    800028b4:	cd1d                	beqz	a0,800028f2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028b6:	4789                	li	a5,2
    800028b8:	06f50a63          	beq	a0,a5,8000292c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028bc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c0:	10049073          	csrw	sstatus,s1
}
    800028c4:	70a2                	ld	ra,40(sp)
    800028c6:	7402                	ld	s0,32(sp)
    800028c8:	64e2                	ld	s1,24(sp)
    800028ca:	6942                	ld	s2,16(sp)
    800028cc:	69a2                	ld	s3,8(sp)
    800028ce:	6145                	addi	sp,sp,48
    800028d0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028d2:	00006517          	auipc	a0,0x6
    800028d6:	ab650513          	addi	a0,a0,-1354 # 80008388 <states.0+0xc0>
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	c68080e7          	jalr	-920(ra) # 80000542 <panic>
    panic("kerneltrap: interrupts enabled");
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	ace50513          	addi	a0,a0,-1330 # 800083b0 <states.0+0xe8>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	c58080e7          	jalr	-936(ra) # 80000542 <panic>
    printf("scause %p\n", scause);
    800028f2:	85ce                	mv	a1,s3
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	adc50513          	addi	a0,a0,-1316 # 800083d0 <states.0+0x108>
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	c90080e7          	jalr	-880(ra) # 8000058c <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002904:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002908:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000290c:	00006517          	auipc	a0,0x6
    80002910:	ad450513          	addi	a0,a0,-1324 # 800083e0 <states.0+0x118>
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	c78080e7          	jalr	-904(ra) # 8000058c <printf>
    panic("kerneltrap");
    8000291c:	00006517          	auipc	a0,0x6
    80002920:	adc50513          	addi	a0,a0,-1316 # 800083f8 <states.0+0x130>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c1e080e7          	jalr	-994(ra) # 80000542 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000292c:	fffff097          	auipc	ra,0xfffff
    80002930:	08e080e7          	jalr	142(ra) # 800019ba <myproc>
    80002934:	d541                	beqz	a0,800028bc <kerneltrap+0x38>
    80002936:	fffff097          	auipc	ra,0xfffff
    8000293a:	084080e7          	jalr	132(ra) # 800019ba <myproc>
    8000293e:	4d18                	lw	a4,24(a0)
    80002940:	478d                	li	a5,3
    80002942:	f6f71de3          	bne	a4,a5,800028bc <kerneltrap+0x38>
    yield();
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	828080e7          	jalr	-2008(ra) # 8000216e <yield>
    8000294e:	b7bd                	j	800028bc <kerneltrap+0x38>

0000000080002950 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002950:	1101                	addi	sp,sp,-32
    80002952:	ec06                	sd	ra,24(sp)
    80002954:	e822                	sd	s0,16(sp)
    80002956:	e426                	sd	s1,8(sp)
    80002958:	1000                	addi	s0,sp,32
    8000295a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000295c:	fffff097          	auipc	ra,0xfffff
    80002960:	05e080e7          	jalr	94(ra) # 800019ba <myproc>
  switch (n) {
    80002964:	4795                	li	a5,5
    80002966:	0497e163          	bltu	a5,s1,800029a8 <argraw+0x58>
    8000296a:	048a                	slli	s1,s1,0x2
    8000296c:	00006717          	auipc	a4,0x6
    80002970:	ac470713          	addi	a4,a4,-1340 # 80008430 <states.0+0x168>
    80002974:	94ba                	add	s1,s1,a4
    80002976:	409c                	lw	a5,0(s1)
    80002978:	97ba                	add	a5,a5,a4
    8000297a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000297c:	6d3c                	ld	a5,88(a0)
    8000297e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002980:	60e2                	ld	ra,24(sp)
    80002982:	6442                	ld	s0,16(sp)
    80002984:	64a2                	ld	s1,8(sp)
    80002986:	6105                	addi	sp,sp,32
    80002988:	8082                	ret
    return p->trapframe->a1;
    8000298a:	6d3c                	ld	a5,88(a0)
    8000298c:	7fa8                	ld	a0,120(a5)
    8000298e:	bfcd                	j	80002980 <argraw+0x30>
    return p->trapframe->a2;
    80002990:	6d3c                	ld	a5,88(a0)
    80002992:	63c8                	ld	a0,128(a5)
    80002994:	b7f5                	j	80002980 <argraw+0x30>
    return p->trapframe->a3;
    80002996:	6d3c                	ld	a5,88(a0)
    80002998:	67c8                	ld	a0,136(a5)
    8000299a:	b7dd                	j	80002980 <argraw+0x30>
    return p->trapframe->a4;
    8000299c:	6d3c                	ld	a5,88(a0)
    8000299e:	6bc8                	ld	a0,144(a5)
    800029a0:	b7c5                	j	80002980 <argraw+0x30>
    return p->trapframe->a5;
    800029a2:	6d3c                	ld	a5,88(a0)
    800029a4:	6fc8                	ld	a0,152(a5)
    800029a6:	bfe9                	j	80002980 <argraw+0x30>
  panic("argraw");
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	a6050513          	addi	a0,a0,-1440 # 80008408 <states.0+0x140>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	b92080e7          	jalr	-1134(ra) # 80000542 <panic>

00000000800029b8 <fetchaddr>:
{
    800029b8:	1101                	addi	sp,sp,-32
    800029ba:	ec06                	sd	ra,24(sp)
    800029bc:	e822                	sd	s0,16(sp)
    800029be:	e426                	sd	s1,8(sp)
    800029c0:	e04a                	sd	s2,0(sp)
    800029c2:	1000                	addi	s0,sp,32
    800029c4:	84aa                	mv	s1,a0
    800029c6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029c8:	fffff097          	auipc	ra,0xfffff
    800029cc:	ff2080e7          	jalr	-14(ra) # 800019ba <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029d0:	653c                	ld	a5,72(a0)
    800029d2:	02f4f863          	bgeu	s1,a5,80002a02 <fetchaddr+0x4a>
    800029d6:	00848713          	addi	a4,s1,8
    800029da:	02e7e663          	bltu	a5,a4,80002a06 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800029de:	46a1                	li	a3,8
    800029e0:	8626                	mv	a2,s1
    800029e2:	85ca                	mv	a1,s2
    800029e4:	6928                	ld	a0,80(a0)
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	d52080e7          	jalr	-686(ra) # 80001738 <copyin>
    800029ee:	00a03533          	snez	a0,a0
    800029f2:	40a00533          	neg	a0,a0
}
    800029f6:	60e2                	ld	ra,24(sp)
    800029f8:	6442                	ld	s0,16(sp)
    800029fa:	64a2                	ld	s1,8(sp)
    800029fc:	6902                	ld	s2,0(sp)
    800029fe:	6105                	addi	sp,sp,32
    80002a00:	8082                	ret
    return -1;
    80002a02:	557d                	li	a0,-1
    80002a04:	bfcd                	j	800029f6 <fetchaddr+0x3e>
    80002a06:	557d                	li	a0,-1
    80002a08:	b7fd                	j	800029f6 <fetchaddr+0x3e>

0000000080002a0a <fetchstr>:
{
    80002a0a:	7179                	addi	sp,sp,-48
    80002a0c:	f406                	sd	ra,40(sp)
    80002a0e:	f022                	sd	s0,32(sp)
    80002a10:	ec26                	sd	s1,24(sp)
    80002a12:	e84a                	sd	s2,16(sp)
    80002a14:	e44e                	sd	s3,8(sp)
    80002a16:	1800                	addi	s0,sp,48
    80002a18:	892a                	mv	s2,a0
    80002a1a:	84ae                	mv	s1,a1
    80002a1c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	f9c080e7          	jalr	-100(ra) # 800019ba <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a26:	86ce                	mv	a3,s3
    80002a28:	864a                	mv	a2,s2
    80002a2a:	85a6                	mv	a1,s1
    80002a2c:	6928                	ld	a0,80(a0)
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	d98080e7          	jalr	-616(ra) # 800017c6 <copyinstr>
  if(err < 0)
    80002a36:	00054763          	bltz	a0,80002a44 <fetchstr+0x3a>
  return strlen(buf);
    80002a3a:	8526                	mv	a0,s1
    80002a3c:	ffffe097          	auipc	ra,0xffffe
    80002a40:	442080e7          	jalr	1090(ra) # 80000e7e <strlen>
}
    80002a44:	70a2                	ld	ra,40(sp)
    80002a46:	7402                	ld	s0,32(sp)
    80002a48:	64e2                	ld	s1,24(sp)
    80002a4a:	6942                	ld	s2,16(sp)
    80002a4c:	69a2                	ld	s3,8(sp)
    80002a4e:	6145                	addi	sp,sp,48
    80002a50:	8082                	ret

0000000080002a52 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a52:	1101                	addi	sp,sp,-32
    80002a54:	ec06                	sd	ra,24(sp)
    80002a56:	e822                	sd	s0,16(sp)
    80002a58:	e426                	sd	s1,8(sp)
    80002a5a:	1000                	addi	s0,sp,32
    80002a5c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a5e:	00000097          	auipc	ra,0x0
    80002a62:	ef2080e7          	jalr	-270(ra) # 80002950 <argraw>
    80002a66:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a68:	4501                	li	a0,0
    80002a6a:	60e2                	ld	ra,24(sp)
    80002a6c:	6442                	ld	s0,16(sp)
    80002a6e:	64a2                	ld	s1,8(sp)
    80002a70:	6105                	addi	sp,sp,32
    80002a72:	8082                	ret

0000000080002a74 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002a74:	1101                	addi	sp,sp,-32
    80002a76:	ec06                	sd	ra,24(sp)
    80002a78:	e822                	sd	s0,16(sp)
    80002a7a:	e426                	sd	s1,8(sp)
    80002a7c:	1000                	addi	s0,sp,32
    80002a7e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a80:	00000097          	auipc	ra,0x0
    80002a84:	ed0080e7          	jalr	-304(ra) # 80002950 <argraw>
    80002a88:	e088                	sd	a0,0(s1)
  return 0;
}
    80002a8a:	4501                	li	a0,0
    80002a8c:	60e2                	ld	ra,24(sp)
    80002a8e:	6442                	ld	s0,16(sp)
    80002a90:	64a2                	ld	s1,8(sp)
    80002a92:	6105                	addi	sp,sp,32
    80002a94:	8082                	ret

0000000080002a96 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002a96:	1101                	addi	sp,sp,-32
    80002a98:	ec06                	sd	ra,24(sp)
    80002a9a:	e822                	sd	s0,16(sp)
    80002a9c:	e426                	sd	s1,8(sp)
    80002a9e:	e04a                	sd	s2,0(sp)
    80002aa0:	1000                	addi	s0,sp,32
    80002aa2:	84ae                	mv	s1,a1
    80002aa4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	eaa080e7          	jalr	-342(ra) # 80002950 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002aae:	864a                	mv	a2,s2
    80002ab0:	85a6                	mv	a1,s1
    80002ab2:	00000097          	auipc	ra,0x0
    80002ab6:	f58080e7          	jalr	-168(ra) # 80002a0a <fetchstr>
}
    80002aba:	60e2                	ld	ra,24(sp)
    80002abc:	6442                	ld	s0,16(sp)
    80002abe:	64a2                	ld	s1,8(sp)
    80002ac0:	6902                	ld	s2,0(sp)
    80002ac2:	6105                	addi	sp,sp,32
    80002ac4:	8082                	ret

0000000080002ac6 <syscall>:
[SYS_pgcnt]   sys_pgcnt,
};

void
syscall(void)
{
    80002ac6:	1101                	addi	sp,sp,-32
    80002ac8:	ec06                	sd	ra,24(sp)
    80002aca:	e822                	sd	s0,16(sp)
    80002acc:	e426                	sd	s1,8(sp)
    80002ace:	e04a                	sd	s2,0(sp)
    80002ad0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	ee8080e7          	jalr	-280(ra) # 800019ba <myproc>
    80002ada:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002adc:	05853903          	ld	s2,88(a0)
    80002ae0:	0a893783          	ld	a5,168(s2)
    80002ae4:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ae8:	37fd                	addiw	a5,a5,-1
    80002aea:	475d                	li	a4,23
    80002aec:	00f76f63          	bltu	a4,a5,80002b0a <syscall+0x44>
    80002af0:	00369713          	slli	a4,a3,0x3
    80002af4:	00006797          	auipc	a5,0x6
    80002af8:	95478793          	addi	a5,a5,-1708 # 80008448 <syscalls>
    80002afc:	97ba                	add	a5,a5,a4
    80002afe:	639c                	ld	a5,0(a5)
    80002b00:	c789                	beqz	a5,80002b0a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b02:	9782                	jalr	a5
    80002b04:	06a93823          	sd	a0,112(s2)
    80002b08:	a839                	j	80002b26 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b0a:	15848613          	addi	a2,s1,344
    80002b0e:	5c8c                	lw	a1,56(s1)
    80002b10:	00006517          	auipc	a0,0x6
    80002b14:	90050513          	addi	a0,a0,-1792 # 80008410 <states.0+0x148>
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	a74080e7          	jalr	-1420(ra) # 8000058c <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b20:	6cbc                	ld	a5,88(s1)
    80002b22:	577d                	li	a4,-1
    80002b24:	fbb8                	sd	a4,112(a5)
  }
}
    80002b26:	60e2                	ld	ra,24(sp)
    80002b28:	6442                	ld	s0,16(sp)
    80002b2a:	64a2                	ld	s1,8(sp)
    80002b2c:	6902                	ld	s2,0(sp)
    80002b2e:	6105                	addi	sp,sp,32
    80002b30:	8082                	ret

0000000080002b32 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b32:	1101                	addi	sp,sp,-32
    80002b34:	ec06                	sd	ra,24(sp)
    80002b36:	e822                	sd	s0,16(sp)
    80002b38:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b3a:	fec40593          	addi	a1,s0,-20
    80002b3e:	4501                	li	a0,0
    80002b40:	00000097          	auipc	ra,0x0
    80002b44:	f12080e7          	jalr	-238(ra) # 80002a52 <argint>
    return -1;
    80002b48:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b4a:	00054963          	bltz	a0,80002b5c <sys_exit+0x2a>
  exit(n);
    80002b4e:	fec42503          	lw	a0,-20(s0)
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	512080e7          	jalr	1298(ra) # 80002064 <exit>
  return 0;  // not reached
    80002b5a:	4781                	li	a5,0
}
    80002b5c:	853e                	mv	a0,a5
    80002b5e:	60e2                	ld	ra,24(sp)
    80002b60:	6442                	ld	s0,16(sp)
    80002b62:	6105                	addi	sp,sp,32
    80002b64:	8082                	ret

0000000080002b66 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b66:	1141                	addi	sp,sp,-16
    80002b68:	e406                	sd	ra,8(sp)
    80002b6a:	e022                	sd	s0,0(sp)
    80002b6c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b6e:	fffff097          	auipc	ra,0xfffff
    80002b72:	e4c080e7          	jalr	-436(ra) # 800019ba <myproc>
}
    80002b76:	5d08                	lw	a0,56(a0)
    80002b78:	60a2                	ld	ra,8(sp)
    80002b7a:	6402                	ld	s0,0(sp)
    80002b7c:	0141                	addi	sp,sp,16
    80002b7e:	8082                	ret

0000000080002b80 <sys_fork>:

uint64
sys_fork(void)
{
    80002b80:	1141                	addi	sp,sp,-16
    80002b82:	e406                	sd	ra,8(sp)
    80002b84:	e022                	sd	s0,0(sp)
    80002b86:	0800                	addi	s0,sp,16
  return fork();
    80002b88:	fffff097          	auipc	ra,0xfffff
    80002b8c:	1f2080e7          	jalr	498(ra) # 80001d7a <fork>
}
    80002b90:	60a2                	ld	ra,8(sp)
    80002b92:	6402                	ld	s0,0(sp)
    80002b94:	0141                	addi	sp,sp,16
    80002b96:	8082                	ret

0000000080002b98 <sys_wait>:

uint64
sys_wait(void)
{
    80002b98:	1101                	addi	sp,sp,-32
    80002b9a:	ec06                	sd	ra,24(sp)
    80002b9c:	e822                	sd	s0,16(sp)
    80002b9e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ba0:	fe840593          	addi	a1,s0,-24
    80002ba4:	4501                	li	a0,0
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	ece080e7          	jalr	-306(ra) # 80002a74 <argaddr>
    80002bae:	87aa                	mv	a5,a0
    return -1;
    80002bb0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bb2:	0007c863          	bltz	a5,80002bc2 <sys_wait+0x2a>
  return wait(p);
    80002bb6:	fe843503          	ld	a0,-24(s0)
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	66e080e7          	jalr	1646(ra) # 80002228 <wait>
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	6105                	addi	sp,sp,32
    80002bc8:	8082                	ret

0000000080002bca <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bca:	7179                	addi	sp,sp,-48
    80002bcc:	f406                	sd	ra,40(sp)
    80002bce:	f022                	sd	s0,32(sp)
    80002bd0:	ec26                	sd	s1,24(sp)
    80002bd2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002bd4:	fdc40593          	addi	a1,s0,-36
    80002bd8:	4501                	li	a0,0
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	e78080e7          	jalr	-392(ra) # 80002a52 <argint>
    return -1;
    80002be2:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002be4:	00054f63          	bltz	a0,80002c02 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	dd2080e7          	jalr	-558(ra) # 800019ba <myproc>
    80002bf0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002bf2:	fdc42503          	lw	a0,-36(s0)
    80002bf6:	fffff097          	auipc	ra,0xfffff
    80002bfa:	110080e7          	jalr	272(ra) # 80001d06 <growproc>
    80002bfe:	00054863          	bltz	a0,80002c0e <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002c02:	8526                	mv	a0,s1
    80002c04:	70a2                	ld	ra,40(sp)
    80002c06:	7402                	ld	s0,32(sp)
    80002c08:	64e2                	ld	s1,24(sp)
    80002c0a:	6145                	addi	sp,sp,48
    80002c0c:	8082                	ret
    return -1;
    80002c0e:	54fd                	li	s1,-1
    80002c10:	bfcd                	j	80002c02 <sys_sbrk+0x38>

0000000080002c12 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c12:	7139                	addi	sp,sp,-64
    80002c14:	fc06                	sd	ra,56(sp)
    80002c16:	f822                	sd	s0,48(sp)
    80002c18:	f426                	sd	s1,40(sp)
    80002c1a:	f04a                	sd	s2,32(sp)
    80002c1c:	ec4e                	sd	s3,24(sp)
    80002c1e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c20:	fcc40593          	addi	a1,s0,-52
    80002c24:	4501                	li	a0,0
    80002c26:	00000097          	auipc	ra,0x0
    80002c2a:	e2c080e7          	jalr	-468(ra) # 80002a52 <argint>
    return -1;
    80002c2e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c30:	06054563          	bltz	a0,80002c9a <sys_sleep+0x88>
  acquire(&tickslock);
    80002c34:	00015517          	auipc	a0,0x15
    80002c38:	b3450513          	addi	a0,a0,-1228 # 80017768 <tickslock>
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	fc2080e7          	jalr	-62(ra) # 80000bfe <acquire>
  ticks0 = ticks;
    80002c44:	00006917          	auipc	s2,0x6
    80002c48:	3dc92903          	lw	s2,988(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002c4c:	fcc42783          	lw	a5,-52(s0)
    80002c50:	cf85                	beqz	a5,80002c88 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c52:	00015997          	auipc	s3,0x15
    80002c56:	b1698993          	addi	s3,s3,-1258 # 80017768 <tickslock>
    80002c5a:	00006497          	auipc	s1,0x6
    80002c5e:	3c648493          	addi	s1,s1,966 # 80009020 <ticks>
    if(myproc()->killed){
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	d58080e7          	jalr	-680(ra) # 800019ba <myproc>
    80002c6a:	591c                	lw	a5,48(a0)
    80002c6c:	ef9d                	bnez	a5,80002caa <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c6e:	85ce                	mv	a1,s3
    80002c70:	8526                	mv	a0,s1
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	538080e7          	jalr	1336(ra) # 800021aa <sleep>
  while(ticks - ticks0 < n){
    80002c7a:	409c                	lw	a5,0(s1)
    80002c7c:	412787bb          	subw	a5,a5,s2
    80002c80:	fcc42703          	lw	a4,-52(s0)
    80002c84:	fce7efe3          	bltu	a5,a4,80002c62 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002c88:	00015517          	auipc	a0,0x15
    80002c8c:	ae050513          	addi	a0,a0,-1312 # 80017768 <tickslock>
    80002c90:	ffffe097          	auipc	ra,0xffffe
    80002c94:	022080e7          	jalr	34(ra) # 80000cb2 <release>
  return 0;
    80002c98:	4781                	li	a5,0
}
    80002c9a:	853e                	mv	a0,a5
    80002c9c:	70e2                	ld	ra,56(sp)
    80002c9e:	7442                	ld	s0,48(sp)
    80002ca0:	74a2                	ld	s1,40(sp)
    80002ca2:	7902                	ld	s2,32(sp)
    80002ca4:	69e2                	ld	s3,24(sp)
    80002ca6:	6121                	addi	sp,sp,64
    80002ca8:	8082                	ret
      release(&tickslock);
    80002caa:	00015517          	auipc	a0,0x15
    80002cae:	abe50513          	addi	a0,a0,-1346 # 80017768 <tickslock>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	000080e7          	jalr	ra # 80000cb2 <release>
      return -1;
    80002cba:	57fd                	li	a5,-1
    80002cbc:	bff9                	j	80002c9a <sys_sleep+0x88>

0000000080002cbe <sys_kill>:

uint64
sys_kill(void)
{
    80002cbe:	1101                	addi	sp,sp,-32
    80002cc0:	ec06                	sd	ra,24(sp)
    80002cc2:	e822                	sd	s0,16(sp)
    80002cc4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cc6:	fec40593          	addi	a1,s0,-20
    80002cca:	4501                	li	a0,0
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	d86080e7          	jalr	-634(ra) # 80002a52 <argint>
    80002cd4:	87aa                	mv	a5,a0
    return -1;
    80002cd6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002cd8:	0007c863          	bltz	a5,80002ce8 <sys_kill+0x2a>
  return kill(pid);
    80002cdc:	fec42503          	lw	a0,-20(s0)
    80002ce0:	fffff097          	auipc	ra,0xfffff
    80002ce4:	6b4080e7          	jalr	1716(ra) # 80002394 <kill>
}
    80002ce8:	60e2                	ld	ra,24(sp)
    80002cea:	6442                	ld	s0,16(sp)
    80002cec:	6105                	addi	sp,sp,32
    80002cee:	8082                	ret

0000000080002cf0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002cf0:	1101                	addi	sp,sp,-32
    80002cf2:	ec06                	sd	ra,24(sp)
    80002cf4:	e822                	sd	s0,16(sp)
    80002cf6:	e426                	sd	s1,8(sp)
    80002cf8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002cfa:	00015517          	auipc	a0,0x15
    80002cfe:	a6e50513          	addi	a0,a0,-1426 # 80017768 <tickslock>
    80002d02:	ffffe097          	auipc	ra,0xffffe
    80002d06:	efc080e7          	jalr	-260(ra) # 80000bfe <acquire>
  xticks = ticks;
    80002d0a:	00006497          	auipc	s1,0x6
    80002d0e:	3164a483          	lw	s1,790(s1) # 80009020 <ticks>
  release(&tickslock);
    80002d12:	00015517          	auipc	a0,0x15
    80002d16:	a5650513          	addi	a0,a0,-1450 # 80017768 <tickslock>
    80002d1a:	ffffe097          	auipc	ra,0xffffe
    80002d1e:	f98080e7          	jalr	-104(ra) # 80000cb2 <release>
  return xticks;
}
    80002d22:	02049513          	slli	a0,s1,0x20
    80002d26:	9101                	srli	a0,a0,0x20
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <sys_phyaddr>:

// Return the physical address of a virtual address.
uint64
sys_phyaddr(void)
{   
    80002d32:	7179                	addi	sp,sp,-48
    80002d34:	f406                	sd	ra,40(sp)
    80002d36:	f022                	sd	s0,32(sp)
    80002d38:	ec26                	sd	s1,24(sp)
    80002d3a:	1800                	addi	s0,sp,48
    // Get the process info to get the pagetable.
    struct proc* p = myproc();
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	c7e080e7          	jalr	-898(ra) # 800019ba <myproc>
    80002d44:	84aa                	mv	s1,a0

    // Retrieve Virtual Address by fetching argument.
    uint64 va;
    argaddr(0, &va);
    80002d46:	fd840593          	addi	a1,s0,-40
    80002d4a:	4501                	li	a0,0
    80002d4c:	00000097          	auipc	ra,0x0
    80002d50:	d28080e7          	jalr	-728(ra) # 80002a74 <argaddr>

    // walkaddr to translate VPN to PFN, PTE_FLAGS(va) extracts 12-bit offset from VA.
    //  ---------------------------------------------------------------------
    // |          VPN -> PFN [63:12]             |      OFFSET [11:0]        |
    //  ---------------------------------------------------------------------
    uint64 pa = walkaddr(p->pagetable, va) | PTE_FLAGS(va);
    80002d54:	fd843583          	ld	a1,-40(s0)
    80002d58:	68a8                	ld	a0,80(s1)
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	31e080e7          	jalr	798(ra) # 80001078 <walkaddr>
    80002d62:	fd843783          	ld	a5,-40(s0)
    80002d66:	3ff7f793          	andi	a5,a5,1023
    return pa;
}
    80002d6a:	8d5d                	or	a0,a0,a5
    80002d6c:	70a2                	ld	ra,40(sp)
    80002d6e:	7402                	ld	s0,32(sp)
    80002d70:	64e2                	ld	s1,24(sp)
    80002d72:	6145                	addi	sp,sp,48
    80002d74:	8082                	ret

0000000080002d76 <sys_ptidx>:

// Return the page table (or directory) index of a virtual address
// at the specified page table level.
uint64
sys_ptidx(void)
{
    80002d76:	1101                	addi	sp,sp,-32
    80002d78:	ec06                	sd	ra,24(sp)
    80002d7a:	e822                	sd	s0,16(sp)
    80002d7c:	1000                	addi	s0,sp,32
    uint64 va;      // Input argument. virtual address
    uint64 lvl_in;  // Input argument. level.

    argaddr(0, &va);
    80002d7e:	fe840593          	addi	a1,s0,-24
    80002d82:	4501                	li	a0,0
    80002d84:	00000097          	auipc	ra,0x0
    80002d88:	cf0080e7          	jalr	-784(ra) # 80002a74 <argaddr>
    argaddr(1, &lvl_in);
    80002d8c:	fe040593          	addi	a1,s0,-32
    80002d90:	4505                	li	a0,1
    80002d92:	00000097          	auipc	ra,0x0
    80002d96:	ce2080e7          	jalr	-798(ra) # 80002a74 <argaddr>

    // PX(level, va) macro extracts the bit number field
    // that contains L-level page offset.    
  return PX(lvl_in, va);
    80002d9a:	fe043783          	ld	a5,-32(s0)
    80002d9e:	0037951b          	slliw	a0,a5,0x3
    80002da2:	9d3d                	addw	a0,a0,a5
    80002da4:	2531                	addiw	a0,a0,12
    80002da6:	fe843783          	ld	a5,-24(s0)
    80002daa:	00a7d533          	srl	a0,a5,a0
}
    80002dae:	1ff57513          	andi	a0,a0,511
    80002db2:	60e2                	ld	ra,24(sp)
    80002db4:	6442                	ld	s0,16(sp)
    80002db6:	6105                	addi	sp,sp,32
    80002db8:	8082                	ret

0000000080002dba <sys_pgcnt>:

// Count the total number pages allocated by a process.
uint64
sys_pgcnt(void)
{
    80002dba:	7179                	addi	sp,sp,-48
    80002dbc:	f406                	sd	ra,40(sp)
    80002dbe:	f022                	sd	s0,32(sp)
    80002dc0:	ec26                	sd	s1,24(sp)
    80002dc2:	e84a                	sd	s2,16(sp)
    80002dc4:	e44e                	sd	s3,8(sp)
    80002dc6:	1800                	addi	s0,sp,48
    80002dc8:	4981                	li	s3,0
    int count = 0; // Count the pages
    80002dca:	4481                	li	s1,0
    80002dcc:	6905                	lui	s2,0x1
    80002dce:	a80d                	j	80002e00 <sys_pgcnt+0x46>
                pagetable = (pagetable_t)PTE2PA(*L2_pte);
                pte_t* L1_pte = &pagetable[L1];
                // If allocated page is found, go L0 level and walk the page
                if (*L1_pte & PTE_V) {
                    count++;  // allocated page found!
                    for (int L0 = 0; L0 < 512; L0++) {
    80002dd0:	07a1                	addi	a5,a5,8
    80002dd2:	00d78763          	beq	a5,a3,80002de0 <sys_pgcnt+0x26>
                        // Get Page table base for L0
                        pagetable = (pagetable_t)PTE2PA(*L1_pte);
                        pte_t* L0_pte = &pagetable[L0];
                        if (*L0_pte & PTE_V)
    80002dd6:	6398                	ld	a4,0(a5)
    80002dd8:	8b05                	andi	a4,a4,1
    80002dda:	db7d                	beqz	a4,80002dd0 <sys_pgcnt+0x16>
                            count++; // allocated page found!
    80002ddc:	2485                	addiw	s1,s1,1
    80002dde:	bfcd                	j	80002dd0 <sys_pgcnt+0x16>
            for (int L1 = 0; L1 < 512; L1++) {
    80002de0:	0621                	addi	a2,a2,8
    80002de2:	00b60c63          	beq	a2,a1,80002dfa <sys_pgcnt+0x40>
                if (*L1_pte & PTE_V) {
    80002de6:	621c                	ld	a5,0(a2)
    80002de8:	0017f713          	andi	a4,a5,1
    80002dec:	db75                	beqz	a4,80002de0 <sys_pgcnt+0x26>
                    count++;  // allocated page found!
    80002dee:	2485                	addiw	s1,s1,1
                        pagetable = (pagetable_t)PTE2PA(*L1_pte);
    80002df0:	83a9                	srli	a5,a5,0xa
    80002df2:	07b2                	slli	a5,a5,0xc
    80002df4:	012786b3          	add	a3,a5,s2
    80002df8:	bff9                	j	80002dd6 <sys_pgcnt+0x1c>
    for (int L2 = 0; L2 < 512; L2++)
    80002dfa:	09a1                	addi	s3,s3,8
    80002dfc:	03298363          	beq	s3,s2,80002e22 <sys_pgcnt+0x68>
        pagetable_t pagetable = myproc()->pagetable;
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	bba080e7          	jalr	-1094(ra) # 800019ba <myproc>
        if(*L2_pte & PTE_V)
    80002e08:	693c                	ld	a5,80(a0)
    80002e0a:	97ce                	add	a5,a5,s3
    80002e0c:	639c                	ld	a5,0(a5)
    80002e0e:	0017f713          	andi	a4,a5,1
    80002e12:	d765                	beqz	a4,80002dfa <sys_pgcnt+0x40>
            count++;  // allocated page found!
    80002e14:	2485                	addiw	s1,s1,1
                pagetable = (pagetable_t)PTE2PA(*L2_pte);
    80002e16:	83a9                	srli	a5,a5,0xa
    80002e18:	00c79613          	slli	a2,a5,0xc
    80002e1c:	012605b3          	add	a1,a2,s2
    80002e20:	b7d9                	j	80002de6 <sys_pgcnt+0x2c>
            }
        }
    }

    return count;
}
    80002e22:	8526                	mv	a0,s1
    80002e24:	70a2                	ld	ra,40(sp)
    80002e26:	7402                	ld	s0,32(sp)
    80002e28:	64e2                	ld	s1,24(sp)
    80002e2a:	6942                	ld	s2,16(sp)
    80002e2c:	69a2                	ld	s3,8(sp)
    80002e2e:	6145                	addi	sp,sp,48
    80002e30:	8082                	ret

0000000080002e32 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e32:	7179                	addi	sp,sp,-48
    80002e34:	f406                	sd	ra,40(sp)
    80002e36:	f022                	sd	s0,32(sp)
    80002e38:	ec26                	sd	s1,24(sp)
    80002e3a:	e84a                	sd	s2,16(sp)
    80002e3c:	e44e                	sd	s3,8(sp)
    80002e3e:	e052                	sd	s4,0(sp)
    80002e40:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e42:	00005597          	auipc	a1,0x5
    80002e46:	6ce58593          	addi	a1,a1,1742 # 80008510 <syscalls+0xc8>
    80002e4a:	00015517          	auipc	a0,0x15
    80002e4e:	93650513          	addi	a0,a0,-1738 # 80017780 <bcache>
    80002e52:	ffffe097          	auipc	ra,0xffffe
    80002e56:	d1c080e7          	jalr	-740(ra) # 80000b6e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e5a:	0001d797          	auipc	a5,0x1d
    80002e5e:	92678793          	addi	a5,a5,-1754 # 8001f780 <bcache+0x8000>
    80002e62:	0001d717          	auipc	a4,0x1d
    80002e66:	b8670713          	addi	a4,a4,-1146 # 8001f9e8 <bcache+0x8268>
    80002e6a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e6e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e72:	00015497          	auipc	s1,0x15
    80002e76:	92648493          	addi	s1,s1,-1754 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002e7a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e7c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e7e:	00005a17          	auipc	s4,0x5
    80002e82:	69aa0a13          	addi	s4,s4,1690 # 80008518 <syscalls+0xd0>
    b->next = bcache.head.next;
    80002e86:	2b893783          	ld	a5,696(s2) # 12b8 <_entry-0x7fffed48>
    80002e8a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e8c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e90:	85d2                	mv	a1,s4
    80002e92:	01048513          	addi	a0,s1,16
    80002e96:	00001097          	auipc	ra,0x1
    80002e9a:	4b2080e7          	jalr	1202(ra) # 80004348 <initsleeplock>
    bcache.head.next->prev = b;
    80002e9e:	2b893783          	ld	a5,696(s2)
    80002ea2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002ea4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ea8:	45848493          	addi	s1,s1,1112
    80002eac:	fd349de3          	bne	s1,s3,80002e86 <binit+0x54>
  }
}
    80002eb0:	70a2                	ld	ra,40(sp)
    80002eb2:	7402                	ld	s0,32(sp)
    80002eb4:	64e2                	ld	s1,24(sp)
    80002eb6:	6942                	ld	s2,16(sp)
    80002eb8:	69a2                	ld	s3,8(sp)
    80002eba:	6a02                	ld	s4,0(sp)
    80002ebc:	6145                	addi	sp,sp,48
    80002ebe:	8082                	ret

0000000080002ec0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002ec0:	7179                	addi	sp,sp,-48
    80002ec2:	f406                	sd	ra,40(sp)
    80002ec4:	f022                	sd	s0,32(sp)
    80002ec6:	ec26                	sd	s1,24(sp)
    80002ec8:	e84a                	sd	s2,16(sp)
    80002eca:	e44e                	sd	s3,8(sp)
    80002ecc:	1800                	addi	s0,sp,48
    80002ece:	892a                	mv	s2,a0
    80002ed0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ed2:	00015517          	auipc	a0,0x15
    80002ed6:	8ae50513          	addi	a0,a0,-1874 # 80017780 <bcache>
    80002eda:	ffffe097          	auipc	ra,0xffffe
    80002ede:	d24080e7          	jalr	-732(ra) # 80000bfe <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ee2:	0001d497          	auipc	s1,0x1d
    80002ee6:	b564b483          	ld	s1,-1194(s1) # 8001fa38 <bcache+0x82b8>
    80002eea:	0001d797          	auipc	a5,0x1d
    80002eee:	afe78793          	addi	a5,a5,-1282 # 8001f9e8 <bcache+0x8268>
    80002ef2:	02f48f63          	beq	s1,a5,80002f30 <bread+0x70>
    80002ef6:	873e                	mv	a4,a5
    80002ef8:	a021                	j	80002f00 <bread+0x40>
    80002efa:	68a4                	ld	s1,80(s1)
    80002efc:	02e48a63          	beq	s1,a4,80002f30 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f00:	449c                	lw	a5,8(s1)
    80002f02:	ff279ce3          	bne	a5,s2,80002efa <bread+0x3a>
    80002f06:	44dc                	lw	a5,12(s1)
    80002f08:	ff3799e3          	bne	a5,s3,80002efa <bread+0x3a>
      b->refcnt++;
    80002f0c:	40bc                	lw	a5,64(s1)
    80002f0e:	2785                	addiw	a5,a5,1
    80002f10:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f12:	00015517          	auipc	a0,0x15
    80002f16:	86e50513          	addi	a0,a0,-1938 # 80017780 <bcache>
    80002f1a:	ffffe097          	auipc	ra,0xffffe
    80002f1e:	d98080e7          	jalr	-616(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    80002f22:	01048513          	addi	a0,s1,16
    80002f26:	00001097          	auipc	ra,0x1
    80002f2a:	45c080e7          	jalr	1116(ra) # 80004382 <acquiresleep>
      return b;
    80002f2e:	a8b9                	j	80002f8c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f30:	0001d497          	auipc	s1,0x1d
    80002f34:	b004b483          	ld	s1,-1280(s1) # 8001fa30 <bcache+0x82b0>
    80002f38:	0001d797          	auipc	a5,0x1d
    80002f3c:	ab078793          	addi	a5,a5,-1360 # 8001f9e8 <bcache+0x8268>
    80002f40:	00f48863          	beq	s1,a5,80002f50 <bread+0x90>
    80002f44:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f46:	40bc                	lw	a5,64(s1)
    80002f48:	cf81                	beqz	a5,80002f60 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f4a:	64a4                	ld	s1,72(s1)
    80002f4c:	fee49de3          	bne	s1,a4,80002f46 <bread+0x86>
  panic("bget: no buffers");
    80002f50:	00005517          	auipc	a0,0x5
    80002f54:	5d050513          	addi	a0,a0,1488 # 80008520 <syscalls+0xd8>
    80002f58:	ffffd097          	auipc	ra,0xffffd
    80002f5c:	5ea080e7          	jalr	1514(ra) # 80000542 <panic>
      b->dev = dev;
    80002f60:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f64:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f68:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f6c:	4785                	li	a5,1
    80002f6e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f70:	00015517          	auipc	a0,0x15
    80002f74:	81050513          	addi	a0,a0,-2032 # 80017780 <bcache>
    80002f78:	ffffe097          	auipc	ra,0xffffe
    80002f7c:	d3a080e7          	jalr	-710(ra) # 80000cb2 <release>
      acquiresleep(&b->lock);
    80002f80:	01048513          	addi	a0,s1,16
    80002f84:	00001097          	auipc	ra,0x1
    80002f88:	3fe080e7          	jalr	1022(ra) # 80004382 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f8c:	409c                	lw	a5,0(s1)
    80002f8e:	cb89                	beqz	a5,80002fa0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f90:	8526                	mv	a0,s1
    80002f92:	70a2                	ld	ra,40(sp)
    80002f94:	7402                	ld	s0,32(sp)
    80002f96:	64e2                	ld	s1,24(sp)
    80002f98:	6942                	ld	s2,16(sp)
    80002f9a:	69a2                	ld	s3,8(sp)
    80002f9c:	6145                	addi	sp,sp,48
    80002f9e:	8082                	ret
    virtio_disk_rw(b, 0);
    80002fa0:	4581                	li	a1,0
    80002fa2:	8526                	mv	a0,s1
    80002fa4:	00003097          	auipc	ra,0x3
    80002fa8:	f28080e7          	jalr	-216(ra) # 80005ecc <virtio_disk_rw>
    b->valid = 1;
    80002fac:	4785                	li	a5,1
    80002fae:	c09c                	sw	a5,0(s1)
  return b;
    80002fb0:	b7c5                	j	80002f90 <bread+0xd0>

0000000080002fb2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002fb2:	1101                	addi	sp,sp,-32
    80002fb4:	ec06                	sd	ra,24(sp)
    80002fb6:	e822                	sd	s0,16(sp)
    80002fb8:	e426                	sd	s1,8(sp)
    80002fba:	1000                	addi	s0,sp,32
    80002fbc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fbe:	0541                	addi	a0,a0,16
    80002fc0:	00001097          	auipc	ra,0x1
    80002fc4:	45c080e7          	jalr	1116(ra) # 8000441c <holdingsleep>
    80002fc8:	cd01                	beqz	a0,80002fe0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002fca:	4585                	li	a1,1
    80002fcc:	8526                	mv	a0,s1
    80002fce:	00003097          	auipc	ra,0x3
    80002fd2:	efe080e7          	jalr	-258(ra) # 80005ecc <virtio_disk_rw>
}
    80002fd6:	60e2                	ld	ra,24(sp)
    80002fd8:	6442                	ld	s0,16(sp)
    80002fda:	64a2                	ld	s1,8(sp)
    80002fdc:	6105                	addi	sp,sp,32
    80002fde:	8082                	ret
    panic("bwrite");
    80002fe0:	00005517          	auipc	a0,0x5
    80002fe4:	55850513          	addi	a0,a0,1368 # 80008538 <syscalls+0xf0>
    80002fe8:	ffffd097          	auipc	ra,0xffffd
    80002fec:	55a080e7          	jalr	1370(ra) # 80000542 <panic>

0000000080002ff0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002ff0:	1101                	addi	sp,sp,-32
    80002ff2:	ec06                	sd	ra,24(sp)
    80002ff4:	e822                	sd	s0,16(sp)
    80002ff6:	e426                	sd	s1,8(sp)
    80002ff8:	e04a                	sd	s2,0(sp)
    80002ffa:	1000                	addi	s0,sp,32
    80002ffc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002ffe:	01050913          	addi	s2,a0,16
    80003002:	854a                	mv	a0,s2
    80003004:	00001097          	auipc	ra,0x1
    80003008:	418080e7          	jalr	1048(ra) # 8000441c <holdingsleep>
    8000300c:	c92d                	beqz	a0,8000307e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000300e:	854a                	mv	a0,s2
    80003010:	00001097          	auipc	ra,0x1
    80003014:	3c8080e7          	jalr	968(ra) # 800043d8 <releasesleep>

  acquire(&bcache.lock);
    80003018:	00014517          	auipc	a0,0x14
    8000301c:	76850513          	addi	a0,a0,1896 # 80017780 <bcache>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	bde080e7          	jalr	-1058(ra) # 80000bfe <acquire>
  b->refcnt--;
    80003028:	40bc                	lw	a5,64(s1)
    8000302a:	37fd                	addiw	a5,a5,-1
    8000302c:	0007871b          	sext.w	a4,a5
    80003030:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003032:	eb05                	bnez	a4,80003062 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003034:	68bc                	ld	a5,80(s1)
    80003036:	64b8                	ld	a4,72(s1)
    80003038:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000303a:	64bc                	ld	a5,72(s1)
    8000303c:	68b8                	ld	a4,80(s1)
    8000303e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003040:	0001c797          	auipc	a5,0x1c
    80003044:	74078793          	addi	a5,a5,1856 # 8001f780 <bcache+0x8000>
    80003048:	2b87b703          	ld	a4,696(a5)
    8000304c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000304e:	0001d717          	auipc	a4,0x1d
    80003052:	99a70713          	addi	a4,a4,-1638 # 8001f9e8 <bcache+0x8268>
    80003056:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003058:	2b87b703          	ld	a4,696(a5)
    8000305c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000305e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003062:	00014517          	auipc	a0,0x14
    80003066:	71e50513          	addi	a0,a0,1822 # 80017780 <bcache>
    8000306a:	ffffe097          	auipc	ra,0xffffe
    8000306e:	c48080e7          	jalr	-952(ra) # 80000cb2 <release>
}
    80003072:	60e2                	ld	ra,24(sp)
    80003074:	6442                	ld	s0,16(sp)
    80003076:	64a2                	ld	s1,8(sp)
    80003078:	6902                	ld	s2,0(sp)
    8000307a:	6105                	addi	sp,sp,32
    8000307c:	8082                	ret
    panic("brelse");
    8000307e:	00005517          	auipc	a0,0x5
    80003082:	4c250513          	addi	a0,a0,1218 # 80008540 <syscalls+0xf8>
    80003086:	ffffd097          	auipc	ra,0xffffd
    8000308a:	4bc080e7          	jalr	1212(ra) # 80000542 <panic>

000000008000308e <bpin>:

void
bpin(struct buf *b) {
    8000308e:	1101                	addi	sp,sp,-32
    80003090:	ec06                	sd	ra,24(sp)
    80003092:	e822                	sd	s0,16(sp)
    80003094:	e426                	sd	s1,8(sp)
    80003096:	1000                	addi	s0,sp,32
    80003098:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000309a:	00014517          	auipc	a0,0x14
    8000309e:	6e650513          	addi	a0,a0,1766 # 80017780 <bcache>
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	b5c080e7          	jalr	-1188(ra) # 80000bfe <acquire>
  b->refcnt++;
    800030aa:	40bc                	lw	a5,64(s1)
    800030ac:	2785                	addiw	a5,a5,1
    800030ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030b0:	00014517          	auipc	a0,0x14
    800030b4:	6d050513          	addi	a0,a0,1744 # 80017780 <bcache>
    800030b8:	ffffe097          	auipc	ra,0xffffe
    800030bc:	bfa080e7          	jalr	-1030(ra) # 80000cb2 <release>
}
    800030c0:	60e2                	ld	ra,24(sp)
    800030c2:	6442                	ld	s0,16(sp)
    800030c4:	64a2                	ld	s1,8(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret

00000000800030ca <bunpin>:

void
bunpin(struct buf *b) {
    800030ca:	1101                	addi	sp,sp,-32
    800030cc:	ec06                	sd	ra,24(sp)
    800030ce:	e822                	sd	s0,16(sp)
    800030d0:	e426                	sd	s1,8(sp)
    800030d2:	1000                	addi	s0,sp,32
    800030d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030d6:	00014517          	auipc	a0,0x14
    800030da:	6aa50513          	addi	a0,a0,1706 # 80017780 <bcache>
    800030de:	ffffe097          	auipc	ra,0xffffe
    800030e2:	b20080e7          	jalr	-1248(ra) # 80000bfe <acquire>
  b->refcnt--;
    800030e6:	40bc                	lw	a5,64(s1)
    800030e8:	37fd                	addiw	a5,a5,-1
    800030ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800030ec:	00014517          	auipc	a0,0x14
    800030f0:	69450513          	addi	a0,a0,1684 # 80017780 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	bbe080e7          	jalr	-1090(ra) # 80000cb2 <release>
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret

0000000080003106 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	e426                	sd	s1,8(sp)
    8000310e:	e04a                	sd	s2,0(sp)
    80003110:	1000                	addi	s0,sp,32
    80003112:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003114:	00d5d59b          	srliw	a1,a1,0xd
    80003118:	0001d797          	auipc	a5,0x1d
    8000311c:	d447a783          	lw	a5,-700(a5) # 8001fe5c <sb+0x1c>
    80003120:	9dbd                	addw	a1,a1,a5
    80003122:	00000097          	auipc	ra,0x0
    80003126:	d9e080e7          	jalr	-610(ra) # 80002ec0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000312a:	0074f713          	andi	a4,s1,7
    8000312e:	4785                	li	a5,1
    80003130:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003134:	14ce                	slli	s1,s1,0x33
    80003136:	90d9                	srli	s1,s1,0x36
    80003138:	00950733          	add	a4,a0,s1
    8000313c:	05874703          	lbu	a4,88(a4)
    80003140:	00e7f6b3          	and	a3,a5,a4
    80003144:	c69d                	beqz	a3,80003172 <bfree+0x6c>
    80003146:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003148:	94aa                	add	s1,s1,a0
    8000314a:	fff7c793          	not	a5,a5
    8000314e:	8ff9                	and	a5,a5,a4
    80003150:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003154:	00001097          	auipc	ra,0x1
    80003158:	106080e7          	jalr	262(ra) # 8000425a <log_write>
  brelse(bp);
    8000315c:	854a                	mv	a0,s2
    8000315e:	00000097          	auipc	ra,0x0
    80003162:	e92080e7          	jalr	-366(ra) # 80002ff0 <brelse>
}
    80003166:	60e2                	ld	ra,24(sp)
    80003168:	6442                	ld	s0,16(sp)
    8000316a:	64a2                	ld	s1,8(sp)
    8000316c:	6902                	ld	s2,0(sp)
    8000316e:	6105                	addi	sp,sp,32
    80003170:	8082                	ret
    panic("freeing free block");
    80003172:	00005517          	auipc	a0,0x5
    80003176:	3d650513          	addi	a0,a0,982 # 80008548 <syscalls+0x100>
    8000317a:	ffffd097          	auipc	ra,0xffffd
    8000317e:	3c8080e7          	jalr	968(ra) # 80000542 <panic>

0000000080003182 <balloc>:
{
    80003182:	711d                	addi	sp,sp,-96
    80003184:	ec86                	sd	ra,88(sp)
    80003186:	e8a2                	sd	s0,80(sp)
    80003188:	e4a6                	sd	s1,72(sp)
    8000318a:	e0ca                	sd	s2,64(sp)
    8000318c:	fc4e                	sd	s3,56(sp)
    8000318e:	f852                	sd	s4,48(sp)
    80003190:	f456                	sd	s5,40(sp)
    80003192:	f05a                	sd	s6,32(sp)
    80003194:	ec5e                	sd	s7,24(sp)
    80003196:	e862                	sd	s8,16(sp)
    80003198:	e466                	sd	s9,8(sp)
    8000319a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000319c:	0001d797          	auipc	a5,0x1d
    800031a0:	ca87a783          	lw	a5,-856(a5) # 8001fe44 <sb+0x4>
    800031a4:	cbd1                	beqz	a5,80003238 <balloc+0xb6>
    800031a6:	8baa                	mv	s7,a0
    800031a8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800031aa:	0001db17          	auipc	s6,0x1d
    800031ae:	c96b0b13          	addi	s6,s6,-874 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800031b4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800031b8:	6c89                	lui	s9,0x2
    800031ba:	a831                	j	800031d6 <balloc+0x54>
    brelse(bp);
    800031bc:	854a                	mv	a0,s2
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	e32080e7          	jalr	-462(ra) # 80002ff0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800031c6:	015c87bb          	addw	a5,s9,s5
    800031ca:	00078a9b          	sext.w	s5,a5
    800031ce:	004b2703          	lw	a4,4(s6)
    800031d2:	06eaf363          	bgeu	s5,a4,80003238 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800031d6:	41fad79b          	sraiw	a5,s5,0x1f
    800031da:	0137d79b          	srliw	a5,a5,0x13
    800031de:	015787bb          	addw	a5,a5,s5
    800031e2:	40d7d79b          	sraiw	a5,a5,0xd
    800031e6:	01cb2583          	lw	a1,28(s6)
    800031ea:	9dbd                	addw	a1,a1,a5
    800031ec:	855e                	mv	a0,s7
    800031ee:	00000097          	auipc	ra,0x0
    800031f2:	cd2080e7          	jalr	-814(ra) # 80002ec0 <bread>
    800031f6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031f8:	004b2503          	lw	a0,4(s6)
    800031fc:	000a849b          	sext.w	s1,s5
    80003200:	8662                	mv	a2,s8
    80003202:	faa4fde3          	bgeu	s1,a0,800031bc <balloc+0x3a>
      m = 1 << (bi % 8);
    80003206:	41f6579b          	sraiw	a5,a2,0x1f
    8000320a:	01d7d69b          	srliw	a3,a5,0x1d
    8000320e:	00c6873b          	addw	a4,a3,a2
    80003212:	00777793          	andi	a5,a4,7
    80003216:	9f95                	subw	a5,a5,a3
    80003218:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000321c:	4037571b          	sraiw	a4,a4,0x3
    80003220:	00e906b3          	add	a3,s2,a4
    80003224:	0586c683          	lbu	a3,88(a3)
    80003228:	00d7f5b3          	and	a1,a5,a3
    8000322c:	cd91                	beqz	a1,80003248 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322e:	2605                	addiw	a2,a2,1
    80003230:	2485                	addiw	s1,s1,1
    80003232:	fd4618e3          	bne	a2,s4,80003202 <balloc+0x80>
    80003236:	b759                	j	800031bc <balloc+0x3a>
  panic("balloc: out of blocks");
    80003238:	00005517          	auipc	a0,0x5
    8000323c:	32850513          	addi	a0,a0,808 # 80008560 <syscalls+0x118>
    80003240:	ffffd097          	auipc	ra,0xffffd
    80003244:	302080e7          	jalr	770(ra) # 80000542 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003248:	974a                	add	a4,a4,s2
    8000324a:	8fd5                	or	a5,a5,a3
    8000324c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003250:	854a                	mv	a0,s2
    80003252:	00001097          	auipc	ra,0x1
    80003256:	008080e7          	jalr	8(ra) # 8000425a <log_write>
        brelse(bp);
    8000325a:	854a                	mv	a0,s2
    8000325c:	00000097          	auipc	ra,0x0
    80003260:	d94080e7          	jalr	-620(ra) # 80002ff0 <brelse>
  bp = bread(dev, bno);
    80003264:	85a6                	mv	a1,s1
    80003266:	855e                	mv	a0,s7
    80003268:	00000097          	auipc	ra,0x0
    8000326c:	c58080e7          	jalr	-936(ra) # 80002ec0 <bread>
    80003270:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003272:	40000613          	li	a2,1024
    80003276:	4581                	li	a1,0
    80003278:	05850513          	addi	a0,a0,88
    8000327c:	ffffe097          	auipc	ra,0xffffe
    80003280:	a7e080e7          	jalr	-1410(ra) # 80000cfa <memset>
  log_write(bp);
    80003284:	854a                	mv	a0,s2
    80003286:	00001097          	auipc	ra,0x1
    8000328a:	fd4080e7          	jalr	-44(ra) # 8000425a <log_write>
  brelse(bp);
    8000328e:	854a                	mv	a0,s2
    80003290:	00000097          	auipc	ra,0x0
    80003294:	d60080e7          	jalr	-672(ra) # 80002ff0 <brelse>
}
    80003298:	8526                	mv	a0,s1
    8000329a:	60e6                	ld	ra,88(sp)
    8000329c:	6446                	ld	s0,80(sp)
    8000329e:	64a6                	ld	s1,72(sp)
    800032a0:	6906                	ld	s2,64(sp)
    800032a2:	79e2                	ld	s3,56(sp)
    800032a4:	7a42                	ld	s4,48(sp)
    800032a6:	7aa2                	ld	s5,40(sp)
    800032a8:	7b02                	ld	s6,32(sp)
    800032aa:	6be2                	ld	s7,24(sp)
    800032ac:	6c42                	ld	s8,16(sp)
    800032ae:	6ca2                	ld	s9,8(sp)
    800032b0:	6125                	addi	sp,sp,96
    800032b2:	8082                	ret

00000000800032b4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800032b4:	7179                	addi	sp,sp,-48
    800032b6:	f406                	sd	ra,40(sp)
    800032b8:	f022                	sd	s0,32(sp)
    800032ba:	ec26                	sd	s1,24(sp)
    800032bc:	e84a                	sd	s2,16(sp)
    800032be:	e44e                	sd	s3,8(sp)
    800032c0:	e052                	sd	s4,0(sp)
    800032c2:	1800                	addi	s0,sp,48
    800032c4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800032c6:	47ad                	li	a5,11
    800032c8:	04b7fe63          	bgeu	a5,a1,80003324 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800032cc:	ff45849b          	addiw	s1,a1,-12
    800032d0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800032d4:	0ff00793          	li	a5,255
    800032d8:	0ae7e463          	bltu	a5,a4,80003380 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032dc:	08052583          	lw	a1,128(a0)
    800032e0:	c5b5                	beqz	a1,8000334c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800032e2:	00092503          	lw	a0,0(s2)
    800032e6:	00000097          	auipc	ra,0x0
    800032ea:	bda080e7          	jalr	-1062(ra) # 80002ec0 <bread>
    800032ee:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032f0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032f4:	02049713          	slli	a4,s1,0x20
    800032f8:	01e75593          	srli	a1,a4,0x1e
    800032fc:	00b784b3          	add	s1,a5,a1
    80003300:	0004a983          	lw	s3,0(s1)
    80003304:	04098e63          	beqz	s3,80003360 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003308:	8552                	mv	a0,s4
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	ce6080e7          	jalr	-794(ra) # 80002ff0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003312:	854e                	mv	a0,s3
    80003314:	70a2                	ld	ra,40(sp)
    80003316:	7402                	ld	s0,32(sp)
    80003318:	64e2                	ld	s1,24(sp)
    8000331a:	6942                	ld	s2,16(sp)
    8000331c:	69a2                	ld	s3,8(sp)
    8000331e:	6a02                	ld	s4,0(sp)
    80003320:	6145                	addi	sp,sp,48
    80003322:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003324:	02059793          	slli	a5,a1,0x20
    80003328:	01e7d593          	srli	a1,a5,0x1e
    8000332c:	00b504b3          	add	s1,a0,a1
    80003330:	0504a983          	lw	s3,80(s1)
    80003334:	fc099fe3          	bnez	s3,80003312 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003338:	4108                	lw	a0,0(a0)
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	e48080e7          	jalr	-440(ra) # 80003182 <balloc>
    80003342:	0005099b          	sext.w	s3,a0
    80003346:	0534a823          	sw	s3,80(s1)
    8000334a:	b7e1                	j	80003312 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000334c:	4108                	lw	a0,0(a0)
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	e34080e7          	jalr	-460(ra) # 80003182 <balloc>
    80003356:	0005059b          	sext.w	a1,a0
    8000335a:	08b92023          	sw	a1,128(s2)
    8000335e:	b751                	j	800032e2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003360:	00092503          	lw	a0,0(s2)
    80003364:	00000097          	auipc	ra,0x0
    80003368:	e1e080e7          	jalr	-482(ra) # 80003182 <balloc>
    8000336c:	0005099b          	sext.w	s3,a0
    80003370:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003374:	8552                	mv	a0,s4
    80003376:	00001097          	auipc	ra,0x1
    8000337a:	ee4080e7          	jalr	-284(ra) # 8000425a <log_write>
    8000337e:	b769                	j	80003308 <bmap+0x54>
  panic("bmap: out of range");
    80003380:	00005517          	auipc	a0,0x5
    80003384:	1f850513          	addi	a0,a0,504 # 80008578 <syscalls+0x130>
    80003388:	ffffd097          	auipc	ra,0xffffd
    8000338c:	1ba080e7          	jalr	442(ra) # 80000542 <panic>

0000000080003390 <iget>:
{
    80003390:	7179                	addi	sp,sp,-48
    80003392:	f406                	sd	ra,40(sp)
    80003394:	f022                	sd	s0,32(sp)
    80003396:	ec26                	sd	s1,24(sp)
    80003398:	e84a                	sd	s2,16(sp)
    8000339a:	e44e                	sd	s3,8(sp)
    8000339c:	e052                	sd	s4,0(sp)
    8000339e:	1800                	addi	s0,sp,48
    800033a0:	89aa                	mv	s3,a0
    800033a2:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800033a4:	0001d517          	auipc	a0,0x1d
    800033a8:	abc50513          	addi	a0,a0,-1348 # 8001fe60 <icache>
    800033ac:	ffffe097          	auipc	ra,0xffffe
    800033b0:	852080e7          	jalr	-1966(ra) # 80000bfe <acquire>
  empty = 0;
    800033b4:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033b6:	0001d497          	auipc	s1,0x1d
    800033ba:	ac248493          	addi	s1,s1,-1342 # 8001fe78 <icache+0x18>
    800033be:	0001e697          	auipc	a3,0x1e
    800033c2:	54a68693          	addi	a3,a3,1354 # 80021908 <log>
    800033c6:	a039                	j	800033d4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033c8:	02090b63          	beqz	s2,800033fe <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033cc:	08848493          	addi	s1,s1,136
    800033d0:	02d48a63          	beq	s1,a3,80003404 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033d4:	449c                	lw	a5,8(s1)
    800033d6:	fef059e3          	blez	a5,800033c8 <iget+0x38>
    800033da:	4098                	lw	a4,0(s1)
    800033dc:	ff3716e3          	bne	a4,s3,800033c8 <iget+0x38>
    800033e0:	40d8                	lw	a4,4(s1)
    800033e2:	ff4713e3          	bne	a4,s4,800033c8 <iget+0x38>
      ip->ref++;
    800033e6:	2785                	addiw	a5,a5,1
    800033e8:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800033ea:	0001d517          	auipc	a0,0x1d
    800033ee:	a7650513          	addi	a0,a0,-1418 # 8001fe60 <icache>
    800033f2:	ffffe097          	auipc	ra,0xffffe
    800033f6:	8c0080e7          	jalr	-1856(ra) # 80000cb2 <release>
      return ip;
    800033fa:	8926                	mv	s2,s1
    800033fc:	a03d                	j	8000342a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033fe:	f7f9                	bnez	a5,800033cc <iget+0x3c>
    80003400:	8926                	mv	s2,s1
    80003402:	b7e9                	j	800033cc <iget+0x3c>
  if(empty == 0)
    80003404:	02090c63          	beqz	s2,8000343c <iget+0xac>
  ip->dev = dev;
    80003408:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000340c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003410:	4785                	li	a5,1
    80003412:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003416:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000341a:	0001d517          	auipc	a0,0x1d
    8000341e:	a4650513          	addi	a0,a0,-1466 # 8001fe60 <icache>
    80003422:	ffffe097          	auipc	ra,0xffffe
    80003426:	890080e7          	jalr	-1904(ra) # 80000cb2 <release>
}
    8000342a:	854a                	mv	a0,s2
    8000342c:	70a2                	ld	ra,40(sp)
    8000342e:	7402                	ld	s0,32(sp)
    80003430:	64e2                	ld	s1,24(sp)
    80003432:	6942                	ld	s2,16(sp)
    80003434:	69a2                	ld	s3,8(sp)
    80003436:	6a02                	ld	s4,0(sp)
    80003438:	6145                	addi	sp,sp,48
    8000343a:	8082                	ret
    panic("iget: no inodes");
    8000343c:	00005517          	auipc	a0,0x5
    80003440:	15450513          	addi	a0,a0,340 # 80008590 <syscalls+0x148>
    80003444:	ffffd097          	auipc	ra,0xffffd
    80003448:	0fe080e7          	jalr	254(ra) # 80000542 <panic>

000000008000344c <fsinit>:
fsinit(int dev) {
    8000344c:	7179                	addi	sp,sp,-48
    8000344e:	f406                	sd	ra,40(sp)
    80003450:	f022                	sd	s0,32(sp)
    80003452:	ec26                	sd	s1,24(sp)
    80003454:	e84a                	sd	s2,16(sp)
    80003456:	e44e                	sd	s3,8(sp)
    80003458:	1800                	addi	s0,sp,48
    8000345a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000345c:	4585                	li	a1,1
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	a62080e7          	jalr	-1438(ra) # 80002ec0 <bread>
    80003466:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003468:	0001d997          	auipc	s3,0x1d
    8000346c:	9d898993          	addi	s3,s3,-1576 # 8001fe40 <sb>
    80003470:	02000613          	li	a2,32
    80003474:	05850593          	addi	a1,a0,88
    80003478:	854e                	mv	a0,s3
    8000347a:	ffffe097          	auipc	ra,0xffffe
    8000347e:	8dc080e7          	jalr	-1828(ra) # 80000d56 <memmove>
  brelse(bp);
    80003482:	8526                	mv	a0,s1
    80003484:	00000097          	auipc	ra,0x0
    80003488:	b6c080e7          	jalr	-1172(ra) # 80002ff0 <brelse>
  if(sb.magic != FSMAGIC)
    8000348c:	0009a703          	lw	a4,0(s3)
    80003490:	102037b7          	lui	a5,0x10203
    80003494:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003498:	02f71263          	bne	a4,a5,800034bc <fsinit+0x70>
  initlog(dev, &sb);
    8000349c:	0001d597          	auipc	a1,0x1d
    800034a0:	9a458593          	addi	a1,a1,-1628 # 8001fe40 <sb>
    800034a4:	854a                	mv	a0,s2
    800034a6:	00001097          	auipc	ra,0x1
    800034aa:	b3a080e7          	jalr	-1222(ra) # 80003fe0 <initlog>
}
    800034ae:	70a2                	ld	ra,40(sp)
    800034b0:	7402                	ld	s0,32(sp)
    800034b2:	64e2                	ld	s1,24(sp)
    800034b4:	6942                	ld	s2,16(sp)
    800034b6:	69a2                	ld	s3,8(sp)
    800034b8:	6145                	addi	sp,sp,48
    800034ba:	8082                	ret
    panic("invalid file system");
    800034bc:	00005517          	auipc	a0,0x5
    800034c0:	0e450513          	addi	a0,a0,228 # 800085a0 <syscalls+0x158>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	07e080e7          	jalr	126(ra) # 80000542 <panic>

00000000800034cc <iinit>:
{
    800034cc:	7179                	addi	sp,sp,-48
    800034ce:	f406                	sd	ra,40(sp)
    800034d0:	f022                	sd	s0,32(sp)
    800034d2:	ec26                	sd	s1,24(sp)
    800034d4:	e84a                	sd	s2,16(sp)
    800034d6:	e44e                	sd	s3,8(sp)
    800034d8:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800034da:	00005597          	auipc	a1,0x5
    800034de:	0de58593          	addi	a1,a1,222 # 800085b8 <syscalls+0x170>
    800034e2:	0001d517          	auipc	a0,0x1d
    800034e6:	97e50513          	addi	a0,a0,-1666 # 8001fe60 <icache>
    800034ea:	ffffd097          	auipc	ra,0xffffd
    800034ee:	684080e7          	jalr	1668(ra) # 80000b6e <initlock>
  for(i = 0; i < NINODE; i++) {
    800034f2:	0001d497          	auipc	s1,0x1d
    800034f6:	99648493          	addi	s1,s1,-1642 # 8001fe88 <icache+0x28>
    800034fa:	0001e997          	auipc	s3,0x1e
    800034fe:	41e98993          	addi	s3,s3,1054 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003502:	00005917          	auipc	s2,0x5
    80003506:	0be90913          	addi	s2,s2,190 # 800085c0 <syscalls+0x178>
    8000350a:	85ca                	mv	a1,s2
    8000350c:	8526                	mv	a0,s1
    8000350e:	00001097          	auipc	ra,0x1
    80003512:	e3a080e7          	jalr	-454(ra) # 80004348 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003516:	08848493          	addi	s1,s1,136
    8000351a:	ff3498e3          	bne	s1,s3,8000350a <iinit+0x3e>
}
    8000351e:	70a2                	ld	ra,40(sp)
    80003520:	7402                	ld	s0,32(sp)
    80003522:	64e2                	ld	s1,24(sp)
    80003524:	6942                	ld	s2,16(sp)
    80003526:	69a2                	ld	s3,8(sp)
    80003528:	6145                	addi	sp,sp,48
    8000352a:	8082                	ret

000000008000352c <ialloc>:
{
    8000352c:	715d                	addi	sp,sp,-80
    8000352e:	e486                	sd	ra,72(sp)
    80003530:	e0a2                	sd	s0,64(sp)
    80003532:	fc26                	sd	s1,56(sp)
    80003534:	f84a                	sd	s2,48(sp)
    80003536:	f44e                	sd	s3,40(sp)
    80003538:	f052                	sd	s4,32(sp)
    8000353a:	ec56                	sd	s5,24(sp)
    8000353c:	e85a                	sd	s6,16(sp)
    8000353e:	e45e                	sd	s7,8(sp)
    80003540:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003542:	0001d717          	auipc	a4,0x1d
    80003546:	90a72703          	lw	a4,-1782(a4) # 8001fe4c <sb+0xc>
    8000354a:	4785                	li	a5,1
    8000354c:	04e7fa63          	bgeu	a5,a4,800035a0 <ialloc+0x74>
    80003550:	8aaa                	mv	s5,a0
    80003552:	8bae                	mv	s7,a1
    80003554:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003556:	0001da17          	auipc	s4,0x1d
    8000355a:	8eaa0a13          	addi	s4,s4,-1814 # 8001fe40 <sb>
    8000355e:	00048b1b          	sext.w	s6,s1
    80003562:	0044d793          	srli	a5,s1,0x4
    80003566:	018a2583          	lw	a1,24(s4)
    8000356a:	9dbd                	addw	a1,a1,a5
    8000356c:	8556                	mv	a0,s5
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	952080e7          	jalr	-1710(ra) # 80002ec0 <bread>
    80003576:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003578:	05850993          	addi	s3,a0,88
    8000357c:	00f4f793          	andi	a5,s1,15
    80003580:	079a                	slli	a5,a5,0x6
    80003582:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003584:	00099783          	lh	a5,0(s3)
    80003588:	c785                	beqz	a5,800035b0 <ialloc+0x84>
    brelse(bp);
    8000358a:	00000097          	auipc	ra,0x0
    8000358e:	a66080e7          	jalr	-1434(ra) # 80002ff0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003592:	0485                	addi	s1,s1,1
    80003594:	00ca2703          	lw	a4,12(s4)
    80003598:	0004879b          	sext.w	a5,s1
    8000359c:	fce7e1e3          	bltu	a5,a4,8000355e <ialloc+0x32>
  panic("ialloc: no inodes");
    800035a0:	00005517          	auipc	a0,0x5
    800035a4:	02850513          	addi	a0,a0,40 # 800085c8 <syscalls+0x180>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	f9a080e7          	jalr	-102(ra) # 80000542 <panic>
      memset(dip, 0, sizeof(*dip));
    800035b0:	04000613          	li	a2,64
    800035b4:	4581                	li	a1,0
    800035b6:	854e                	mv	a0,s3
    800035b8:	ffffd097          	auipc	ra,0xffffd
    800035bc:	742080e7          	jalr	1858(ra) # 80000cfa <memset>
      dip->type = type;
    800035c0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035c4:	854a                	mv	a0,s2
    800035c6:	00001097          	auipc	ra,0x1
    800035ca:	c94080e7          	jalr	-876(ra) # 8000425a <log_write>
      brelse(bp);
    800035ce:	854a                	mv	a0,s2
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	a20080e7          	jalr	-1504(ra) # 80002ff0 <brelse>
      return iget(dev, inum);
    800035d8:	85da                	mv	a1,s6
    800035da:	8556                	mv	a0,s5
    800035dc:	00000097          	auipc	ra,0x0
    800035e0:	db4080e7          	jalr	-588(ra) # 80003390 <iget>
}
    800035e4:	60a6                	ld	ra,72(sp)
    800035e6:	6406                	ld	s0,64(sp)
    800035e8:	74e2                	ld	s1,56(sp)
    800035ea:	7942                	ld	s2,48(sp)
    800035ec:	79a2                	ld	s3,40(sp)
    800035ee:	7a02                	ld	s4,32(sp)
    800035f0:	6ae2                	ld	s5,24(sp)
    800035f2:	6b42                	ld	s6,16(sp)
    800035f4:	6ba2                	ld	s7,8(sp)
    800035f6:	6161                	addi	sp,sp,80
    800035f8:	8082                	ret

00000000800035fa <iupdate>:
{
    800035fa:	1101                	addi	sp,sp,-32
    800035fc:	ec06                	sd	ra,24(sp)
    800035fe:	e822                	sd	s0,16(sp)
    80003600:	e426                	sd	s1,8(sp)
    80003602:	e04a                	sd	s2,0(sp)
    80003604:	1000                	addi	s0,sp,32
    80003606:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003608:	415c                	lw	a5,4(a0)
    8000360a:	0047d79b          	srliw	a5,a5,0x4
    8000360e:	0001d597          	auipc	a1,0x1d
    80003612:	84a5a583          	lw	a1,-1974(a1) # 8001fe58 <sb+0x18>
    80003616:	9dbd                	addw	a1,a1,a5
    80003618:	4108                	lw	a0,0(a0)
    8000361a:	00000097          	auipc	ra,0x0
    8000361e:	8a6080e7          	jalr	-1882(ra) # 80002ec0 <bread>
    80003622:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003624:	05850793          	addi	a5,a0,88
    80003628:	40c8                	lw	a0,4(s1)
    8000362a:	893d                	andi	a0,a0,15
    8000362c:	051a                	slli	a0,a0,0x6
    8000362e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003630:	04449703          	lh	a4,68(s1)
    80003634:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003638:	04649703          	lh	a4,70(s1)
    8000363c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003640:	04849703          	lh	a4,72(s1)
    80003644:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003648:	04a49703          	lh	a4,74(s1)
    8000364c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003650:	44f8                	lw	a4,76(s1)
    80003652:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003654:	03400613          	li	a2,52
    80003658:	05048593          	addi	a1,s1,80
    8000365c:	0531                	addi	a0,a0,12
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	6f8080e7          	jalr	1784(ra) # 80000d56 <memmove>
  log_write(bp);
    80003666:	854a                	mv	a0,s2
    80003668:	00001097          	auipc	ra,0x1
    8000366c:	bf2080e7          	jalr	-1038(ra) # 8000425a <log_write>
  brelse(bp);
    80003670:	854a                	mv	a0,s2
    80003672:	00000097          	auipc	ra,0x0
    80003676:	97e080e7          	jalr	-1666(ra) # 80002ff0 <brelse>
}
    8000367a:	60e2                	ld	ra,24(sp)
    8000367c:	6442                	ld	s0,16(sp)
    8000367e:	64a2                	ld	s1,8(sp)
    80003680:	6902                	ld	s2,0(sp)
    80003682:	6105                	addi	sp,sp,32
    80003684:	8082                	ret

0000000080003686 <idup>:
{
    80003686:	1101                	addi	sp,sp,-32
    80003688:	ec06                	sd	ra,24(sp)
    8000368a:	e822                	sd	s0,16(sp)
    8000368c:	e426                	sd	s1,8(sp)
    8000368e:	1000                	addi	s0,sp,32
    80003690:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003692:	0001c517          	auipc	a0,0x1c
    80003696:	7ce50513          	addi	a0,a0,1998 # 8001fe60 <icache>
    8000369a:	ffffd097          	auipc	ra,0xffffd
    8000369e:	564080e7          	jalr	1380(ra) # 80000bfe <acquire>
  ip->ref++;
    800036a2:	449c                	lw	a5,8(s1)
    800036a4:	2785                	addiw	a5,a5,1
    800036a6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800036a8:	0001c517          	auipc	a0,0x1c
    800036ac:	7b850513          	addi	a0,a0,1976 # 8001fe60 <icache>
    800036b0:	ffffd097          	auipc	ra,0xffffd
    800036b4:	602080e7          	jalr	1538(ra) # 80000cb2 <release>
}
    800036b8:	8526                	mv	a0,s1
    800036ba:	60e2                	ld	ra,24(sp)
    800036bc:	6442                	ld	s0,16(sp)
    800036be:	64a2                	ld	s1,8(sp)
    800036c0:	6105                	addi	sp,sp,32
    800036c2:	8082                	ret

00000000800036c4 <ilock>:
{
    800036c4:	1101                	addi	sp,sp,-32
    800036c6:	ec06                	sd	ra,24(sp)
    800036c8:	e822                	sd	s0,16(sp)
    800036ca:	e426                	sd	s1,8(sp)
    800036cc:	e04a                	sd	s2,0(sp)
    800036ce:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036d0:	c115                	beqz	a0,800036f4 <ilock+0x30>
    800036d2:	84aa                	mv	s1,a0
    800036d4:	451c                	lw	a5,8(a0)
    800036d6:	00f05f63          	blez	a5,800036f4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036da:	0541                	addi	a0,a0,16
    800036dc:	00001097          	auipc	ra,0x1
    800036e0:	ca6080e7          	jalr	-858(ra) # 80004382 <acquiresleep>
  if(ip->valid == 0){
    800036e4:	40bc                	lw	a5,64(s1)
    800036e6:	cf99                	beqz	a5,80003704 <ilock+0x40>
}
    800036e8:	60e2                	ld	ra,24(sp)
    800036ea:	6442                	ld	s0,16(sp)
    800036ec:	64a2                	ld	s1,8(sp)
    800036ee:	6902                	ld	s2,0(sp)
    800036f0:	6105                	addi	sp,sp,32
    800036f2:	8082                	ret
    panic("ilock");
    800036f4:	00005517          	auipc	a0,0x5
    800036f8:	eec50513          	addi	a0,a0,-276 # 800085e0 <syscalls+0x198>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	e46080e7          	jalr	-442(ra) # 80000542 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003704:	40dc                	lw	a5,4(s1)
    80003706:	0047d79b          	srliw	a5,a5,0x4
    8000370a:	0001c597          	auipc	a1,0x1c
    8000370e:	74e5a583          	lw	a1,1870(a1) # 8001fe58 <sb+0x18>
    80003712:	9dbd                	addw	a1,a1,a5
    80003714:	4088                	lw	a0,0(s1)
    80003716:	fffff097          	auipc	ra,0xfffff
    8000371a:	7aa080e7          	jalr	1962(ra) # 80002ec0 <bread>
    8000371e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003720:	05850593          	addi	a1,a0,88
    80003724:	40dc                	lw	a5,4(s1)
    80003726:	8bbd                	andi	a5,a5,15
    80003728:	079a                	slli	a5,a5,0x6
    8000372a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000372c:	00059783          	lh	a5,0(a1)
    80003730:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003734:	00259783          	lh	a5,2(a1)
    80003738:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000373c:	00459783          	lh	a5,4(a1)
    80003740:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003744:	00659783          	lh	a5,6(a1)
    80003748:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000374c:	459c                	lw	a5,8(a1)
    8000374e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003750:	03400613          	li	a2,52
    80003754:	05b1                	addi	a1,a1,12
    80003756:	05048513          	addi	a0,s1,80
    8000375a:	ffffd097          	auipc	ra,0xffffd
    8000375e:	5fc080e7          	jalr	1532(ra) # 80000d56 <memmove>
    brelse(bp);
    80003762:	854a                	mv	a0,s2
    80003764:	00000097          	auipc	ra,0x0
    80003768:	88c080e7          	jalr	-1908(ra) # 80002ff0 <brelse>
    ip->valid = 1;
    8000376c:	4785                	li	a5,1
    8000376e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003770:	04449783          	lh	a5,68(s1)
    80003774:	fbb5                	bnez	a5,800036e8 <ilock+0x24>
      panic("ilock: no type");
    80003776:	00005517          	auipc	a0,0x5
    8000377a:	e7250513          	addi	a0,a0,-398 # 800085e8 <syscalls+0x1a0>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	dc4080e7          	jalr	-572(ra) # 80000542 <panic>

0000000080003786 <iunlock>:
{
    80003786:	1101                	addi	sp,sp,-32
    80003788:	ec06                	sd	ra,24(sp)
    8000378a:	e822                	sd	s0,16(sp)
    8000378c:	e426                	sd	s1,8(sp)
    8000378e:	e04a                	sd	s2,0(sp)
    80003790:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003792:	c905                	beqz	a0,800037c2 <iunlock+0x3c>
    80003794:	84aa                	mv	s1,a0
    80003796:	01050913          	addi	s2,a0,16
    8000379a:	854a                	mv	a0,s2
    8000379c:	00001097          	auipc	ra,0x1
    800037a0:	c80080e7          	jalr	-896(ra) # 8000441c <holdingsleep>
    800037a4:	cd19                	beqz	a0,800037c2 <iunlock+0x3c>
    800037a6:	449c                	lw	a5,8(s1)
    800037a8:	00f05d63          	blez	a5,800037c2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800037ac:	854a                	mv	a0,s2
    800037ae:	00001097          	auipc	ra,0x1
    800037b2:	c2a080e7          	jalr	-982(ra) # 800043d8 <releasesleep>
}
    800037b6:	60e2                	ld	ra,24(sp)
    800037b8:	6442                	ld	s0,16(sp)
    800037ba:	64a2                	ld	s1,8(sp)
    800037bc:	6902                	ld	s2,0(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret
    panic("iunlock");
    800037c2:	00005517          	auipc	a0,0x5
    800037c6:	e3650513          	addi	a0,a0,-458 # 800085f8 <syscalls+0x1b0>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	d78080e7          	jalr	-648(ra) # 80000542 <panic>

00000000800037d2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037d2:	7179                	addi	sp,sp,-48
    800037d4:	f406                	sd	ra,40(sp)
    800037d6:	f022                	sd	s0,32(sp)
    800037d8:	ec26                	sd	s1,24(sp)
    800037da:	e84a                	sd	s2,16(sp)
    800037dc:	e44e                	sd	s3,8(sp)
    800037de:	e052                	sd	s4,0(sp)
    800037e0:	1800                	addi	s0,sp,48
    800037e2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037e4:	05050493          	addi	s1,a0,80
    800037e8:	08050913          	addi	s2,a0,128
    800037ec:	a021                	j	800037f4 <itrunc+0x22>
    800037ee:	0491                	addi	s1,s1,4
    800037f0:	01248d63          	beq	s1,s2,8000380a <itrunc+0x38>
    if(ip->addrs[i]){
    800037f4:	408c                	lw	a1,0(s1)
    800037f6:	dde5                	beqz	a1,800037ee <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800037f8:	0009a503          	lw	a0,0(s3)
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	90a080e7          	jalr	-1782(ra) # 80003106 <bfree>
      ip->addrs[i] = 0;
    80003804:	0004a023          	sw	zero,0(s1)
    80003808:	b7dd                	j	800037ee <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000380a:	0809a583          	lw	a1,128(s3)
    8000380e:	e185                	bnez	a1,8000382e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003810:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003814:	854e                	mv	a0,s3
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	de4080e7          	jalr	-540(ra) # 800035fa <iupdate>
}
    8000381e:	70a2                	ld	ra,40(sp)
    80003820:	7402                	ld	s0,32(sp)
    80003822:	64e2                	ld	s1,24(sp)
    80003824:	6942                	ld	s2,16(sp)
    80003826:	69a2                	ld	s3,8(sp)
    80003828:	6a02                	ld	s4,0(sp)
    8000382a:	6145                	addi	sp,sp,48
    8000382c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000382e:	0009a503          	lw	a0,0(s3)
    80003832:	fffff097          	auipc	ra,0xfffff
    80003836:	68e080e7          	jalr	1678(ra) # 80002ec0 <bread>
    8000383a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000383c:	05850493          	addi	s1,a0,88
    80003840:	45850913          	addi	s2,a0,1112
    80003844:	a021                	j	8000384c <itrunc+0x7a>
    80003846:	0491                	addi	s1,s1,4
    80003848:	01248b63          	beq	s1,s2,8000385e <itrunc+0x8c>
      if(a[j])
    8000384c:	408c                	lw	a1,0(s1)
    8000384e:	dde5                	beqz	a1,80003846 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003850:	0009a503          	lw	a0,0(s3)
    80003854:	00000097          	auipc	ra,0x0
    80003858:	8b2080e7          	jalr	-1870(ra) # 80003106 <bfree>
    8000385c:	b7ed                	j	80003846 <itrunc+0x74>
    brelse(bp);
    8000385e:	8552                	mv	a0,s4
    80003860:	fffff097          	auipc	ra,0xfffff
    80003864:	790080e7          	jalr	1936(ra) # 80002ff0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003868:	0809a583          	lw	a1,128(s3)
    8000386c:	0009a503          	lw	a0,0(s3)
    80003870:	00000097          	auipc	ra,0x0
    80003874:	896080e7          	jalr	-1898(ra) # 80003106 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003878:	0809a023          	sw	zero,128(s3)
    8000387c:	bf51                	j	80003810 <itrunc+0x3e>

000000008000387e <iput>:
{
    8000387e:	1101                	addi	sp,sp,-32
    80003880:	ec06                	sd	ra,24(sp)
    80003882:	e822                	sd	s0,16(sp)
    80003884:	e426                	sd	s1,8(sp)
    80003886:	e04a                	sd	s2,0(sp)
    80003888:	1000                	addi	s0,sp,32
    8000388a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000388c:	0001c517          	auipc	a0,0x1c
    80003890:	5d450513          	addi	a0,a0,1492 # 8001fe60 <icache>
    80003894:	ffffd097          	auipc	ra,0xffffd
    80003898:	36a080e7          	jalr	874(ra) # 80000bfe <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000389c:	4498                	lw	a4,8(s1)
    8000389e:	4785                	li	a5,1
    800038a0:	02f70363          	beq	a4,a5,800038c6 <iput+0x48>
  ip->ref--;
    800038a4:	449c                	lw	a5,8(s1)
    800038a6:	37fd                	addiw	a5,a5,-1
    800038a8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038aa:	0001c517          	auipc	a0,0x1c
    800038ae:	5b650513          	addi	a0,a0,1462 # 8001fe60 <icache>
    800038b2:	ffffd097          	auipc	ra,0xffffd
    800038b6:	400080e7          	jalr	1024(ra) # 80000cb2 <release>
}
    800038ba:	60e2                	ld	ra,24(sp)
    800038bc:	6442                	ld	s0,16(sp)
    800038be:	64a2                	ld	s1,8(sp)
    800038c0:	6902                	ld	s2,0(sp)
    800038c2:	6105                	addi	sp,sp,32
    800038c4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800038c6:	40bc                	lw	a5,64(s1)
    800038c8:	dff1                	beqz	a5,800038a4 <iput+0x26>
    800038ca:	04a49783          	lh	a5,74(s1)
    800038ce:	fbf9                	bnez	a5,800038a4 <iput+0x26>
    acquiresleep(&ip->lock);
    800038d0:	01048913          	addi	s2,s1,16
    800038d4:	854a                	mv	a0,s2
    800038d6:	00001097          	auipc	ra,0x1
    800038da:	aac080e7          	jalr	-1364(ra) # 80004382 <acquiresleep>
    release(&icache.lock);
    800038de:	0001c517          	auipc	a0,0x1c
    800038e2:	58250513          	addi	a0,a0,1410 # 8001fe60 <icache>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	3cc080e7          	jalr	972(ra) # 80000cb2 <release>
    itrunc(ip);
    800038ee:	8526                	mv	a0,s1
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	ee2080e7          	jalr	-286(ra) # 800037d2 <itrunc>
    ip->type = 0;
    800038f8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800038fc:	8526                	mv	a0,s1
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	cfc080e7          	jalr	-772(ra) # 800035fa <iupdate>
    ip->valid = 0;
    80003906:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000390a:	854a                	mv	a0,s2
    8000390c:	00001097          	auipc	ra,0x1
    80003910:	acc080e7          	jalr	-1332(ra) # 800043d8 <releasesleep>
    acquire(&icache.lock);
    80003914:	0001c517          	auipc	a0,0x1c
    80003918:	54c50513          	addi	a0,a0,1356 # 8001fe60 <icache>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	2e2080e7          	jalr	738(ra) # 80000bfe <acquire>
    80003924:	b741                	j	800038a4 <iput+0x26>

0000000080003926 <iunlockput>:
{
    80003926:	1101                	addi	sp,sp,-32
    80003928:	ec06                	sd	ra,24(sp)
    8000392a:	e822                	sd	s0,16(sp)
    8000392c:	e426                	sd	s1,8(sp)
    8000392e:	1000                	addi	s0,sp,32
    80003930:	84aa                	mv	s1,a0
  iunlock(ip);
    80003932:	00000097          	auipc	ra,0x0
    80003936:	e54080e7          	jalr	-428(ra) # 80003786 <iunlock>
  iput(ip);
    8000393a:	8526                	mv	a0,s1
    8000393c:	00000097          	auipc	ra,0x0
    80003940:	f42080e7          	jalr	-190(ra) # 8000387e <iput>
}
    80003944:	60e2                	ld	ra,24(sp)
    80003946:	6442                	ld	s0,16(sp)
    80003948:	64a2                	ld	s1,8(sp)
    8000394a:	6105                	addi	sp,sp,32
    8000394c:	8082                	ret

000000008000394e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000394e:	1141                	addi	sp,sp,-16
    80003950:	e422                	sd	s0,8(sp)
    80003952:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003954:	411c                	lw	a5,0(a0)
    80003956:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003958:	415c                	lw	a5,4(a0)
    8000395a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000395c:	04451783          	lh	a5,68(a0)
    80003960:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003964:	04a51783          	lh	a5,74(a0)
    80003968:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000396c:	04c56783          	lwu	a5,76(a0)
    80003970:	e99c                	sd	a5,16(a1)
}
    80003972:	6422                	ld	s0,8(sp)
    80003974:	0141                	addi	sp,sp,16
    80003976:	8082                	ret

0000000080003978 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003978:	457c                	lw	a5,76(a0)
    8000397a:	0ed7e863          	bltu	a5,a3,80003a6a <readi+0xf2>
{
    8000397e:	7159                	addi	sp,sp,-112
    80003980:	f486                	sd	ra,104(sp)
    80003982:	f0a2                	sd	s0,96(sp)
    80003984:	eca6                	sd	s1,88(sp)
    80003986:	e8ca                	sd	s2,80(sp)
    80003988:	e4ce                	sd	s3,72(sp)
    8000398a:	e0d2                	sd	s4,64(sp)
    8000398c:	fc56                	sd	s5,56(sp)
    8000398e:	f85a                	sd	s6,48(sp)
    80003990:	f45e                	sd	s7,40(sp)
    80003992:	f062                	sd	s8,32(sp)
    80003994:	ec66                	sd	s9,24(sp)
    80003996:	e86a                	sd	s10,16(sp)
    80003998:	e46e                	sd	s11,8(sp)
    8000399a:	1880                	addi	s0,sp,112
    8000399c:	8baa                	mv	s7,a0
    8000399e:	8c2e                	mv	s8,a1
    800039a0:	8ab2                	mv	s5,a2
    800039a2:	84b6                	mv	s1,a3
    800039a4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800039a6:	9f35                	addw	a4,a4,a3
    return 0;
    800039a8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800039aa:	08d76f63          	bltu	a4,a3,80003a48 <readi+0xd0>
  if(off + n > ip->size)
    800039ae:	00e7f463          	bgeu	a5,a4,800039b6 <readi+0x3e>
    n = ip->size - off;
    800039b2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039b6:	0a0b0863          	beqz	s6,80003a66 <readi+0xee>
    800039ba:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800039bc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800039c0:	5cfd                	li	s9,-1
    800039c2:	a82d                	j	800039fc <readi+0x84>
    800039c4:	020a1d93          	slli	s11,s4,0x20
    800039c8:	020ddd93          	srli	s11,s11,0x20
    800039cc:	05890793          	addi	a5,s2,88
    800039d0:	86ee                	mv	a3,s11
    800039d2:	963e                	add	a2,a2,a5
    800039d4:	85d6                	mv	a1,s5
    800039d6:	8562                	mv	a0,s8
    800039d8:	fffff097          	auipc	ra,0xfffff
    800039dc:	a2c080e7          	jalr	-1492(ra) # 80002404 <either_copyout>
    800039e0:	05950d63          	beq	a0,s9,80003a3a <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    800039e4:	854a                	mv	a0,s2
    800039e6:	fffff097          	auipc	ra,0xfffff
    800039ea:	60a080e7          	jalr	1546(ra) # 80002ff0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039ee:	013a09bb          	addw	s3,s4,s3
    800039f2:	009a04bb          	addw	s1,s4,s1
    800039f6:	9aee                	add	s5,s5,s11
    800039f8:	0569f663          	bgeu	s3,s6,80003a44 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800039fc:	000ba903          	lw	s2,0(s7)
    80003a00:	00a4d59b          	srliw	a1,s1,0xa
    80003a04:	855e                	mv	a0,s7
    80003a06:	00000097          	auipc	ra,0x0
    80003a0a:	8ae080e7          	jalr	-1874(ra) # 800032b4 <bmap>
    80003a0e:	0005059b          	sext.w	a1,a0
    80003a12:	854a                	mv	a0,s2
    80003a14:	fffff097          	auipc	ra,0xfffff
    80003a18:	4ac080e7          	jalr	1196(ra) # 80002ec0 <bread>
    80003a1c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a1e:	3ff4f613          	andi	a2,s1,1023
    80003a22:	40cd07bb          	subw	a5,s10,a2
    80003a26:	413b073b          	subw	a4,s6,s3
    80003a2a:	8a3e                	mv	s4,a5
    80003a2c:	2781                	sext.w	a5,a5
    80003a2e:	0007069b          	sext.w	a3,a4
    80003a32:	f8f6f9e3          	bgeu	a3,a5,800039c4 <readi+0x4c>
    80003a36:	8a3a                	mv	s4,a4
    80003a38:	b771                	j	800039c4 <readi+0x4c>
      brelse(bp);
    80003a3a:	854a                	mv	a0,s2
    80003a3c:	fffff097          	auipc	ra,0xfffff
    80003a40:	5b4080e7          	jalr	1460(ra) # 80002ff0 <brelse>
  }
  return tot;
    80003a44:	0009851b          	sext.w	a0,s3
}
    80003a48:	70a6                	ld	ra,104(sp)
    80003a4a:	7406                	ld	s0,96(sp)
    80003a4c:	64e6                	ld	s1,88(sp)
    80003a4e:	6946                	ld	s2,80(sp)
    80003a50:	69a6                	ld	s3,72(sp)
    80003a52:	6a06                	ld	s4,64(sp)
    80003a54:	7ae2                	ld	s5,56(sp)
    80003a56:	7b42                	ld	s6,48(sp)
    80003a58:	7ba2                	ld	s7,40(sp)
    80003a5a:	7c02                	ld	s8,32(sp)
    80003a5c:	6ce2                	ld	s9,24(sp)
    80003a5e:	6d42                	ld	s10,16(sp)
    80003a60:	6da2                	ld	s11,8(sp)
    80003a62:	6165                	addi	sp,sp,112
    80003a64:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a66:	89da                	mv	s3,s6
    80003a68:	bff1                	j	80003a44 <readi+0xcc>
    return 0;
    80003a6a:	4501                	li	a0,0
}
    80003a6c:	8082                	ret

0000000080003a6e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a6e:	457c                	lw	a5,76(a0)
    80003a70:	10d7e663          	bltu	a5,a3,80003b7c <writei+0x10e>
{
    80003a74:	7159                	addi	sp,sp,-112
    80003a76:	f486                	sd	ra,104(sp)
    80003a78:	f0a2                	sd	s0,96(sp)
    80003a7a:	eca6                	sd	s1,88(sp)
    80003a7c:	e8ca                	sd	s2,80(sp)
    80003a7e:	e4ce                	sd	s3,72(sp)
    80003a80:	e0d2                	sd	s4,64(sp)
    80003a82:	fc56                	sd	s5,56(sp)
    80003a84:	f85a                	sd	s6,48(sp)
    80003a86:	f45e                	sd	s7,40(sp)
    80003a88:	f062                	sd	s8,32(sp)
    80003a8a:	ec66                	sd	s9,24(sp)
    80003a8c:	e86a                	sd	s10,16(sp)
    80003a8e:	e46e                	sd	s11,8(sp)
    80003a90:	1880                	addi	s0,sp,112
    80003a92:	8baa                	mv	s7,a0
    80003a94:	8c2e                	mv	s8,a1
    80003a96:	8ab2                	mv	s5,a2
    80003a98:	8936                	mv	s2,a3
    80003a9a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a9c:	00e687bb          	addw	a5,a3,a4
    80003aa0:	0ed7e063          	bltu	a5,a3,80003b80 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003aa4:	00043737          	lui	a4,0x43
    80003aa8:	0cf76e63          	bltu	a4,a5,80003b84 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aac:	0a0b0763          	beqz	s6,80003b5a <writei+0xec>
    80003ab0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ab6:	5cfd                	li	s9,-1
    80003ab8:	a091                	j	80003afc <writei+0x8e>
    80003aba:	02099d93          	slli	s11,s3,0x20
    80003abe:	020ddd93          	srli	s11,s11,0x20
    80003ac2:	05848793          	addi	a5,s1,88
    80003ac6:	86ee                	mv	a3,s11
    80003ac8:	8656                	mv	a2,s5
    80003aca:	85e2                	mv	a1,s8
    80003acc:	953e                	add	a0,a0,a5
    80003ace:	fffff097          	auipc	ra,0xfffff
    80003ad2:	98c080e7          	jalr	-1652(ra) # 8000245a <either_copyin>
    80003ad6:	07950263          	beq	a0,s9,80003b3a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ada:	8526                	mv	a0,s1
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	77e080e7          	jalr	1918(ra) # 8000425a <log_write>
    brelse(bp);
    80003ae4:	8526                	mv	a0,s1
    80003ae6:	fffff097          	auipc	ra,0xfffff
    80003aea:	50a080e7          	jalr	1290(ra) # 80002ff0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003aee:	01498a3b          	addw	s4,s3,s4
    80003af2:	0129893b          	addw	s2,s3,s2
    80003af6:	9aee                	add	s5,s5,s11
    80003af8:	056a7663          	bgeu	s4,s6,80003b44 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003afc:	000ba483          	lw	s1,0(s7)
    80003b00:	00a9559b          	srliw	a1,s2,0xa
    80003b04:	855e                	mv	a0,s7
    80003b06:	fffff097          	auipc	ra,0xfffff
    80003b0a:	7ae080e7          	jalr	1966(ra) # 800032b4 <bmap>
    80003b0e:	0005059b          	sext.w	a1,a0
    80003b12:	8526                	mv	a0,s1
    80003b14:	fffff097          	auipc	ra,0xfffff
    80003b18:	3ac080e7          	jalr	940(ra) # 80002ec0 <bread>
    80003b1c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b1e:	3ff97513          	andi	a0,s2,1023
    80003b22:	40ad07bb          	subw	a5,s10,a0
    80003b26:	414b073b          	subw	a4,s6,s4
    80003b2a:	89be                	mv	s3,a5
    80003b2c:	2781                	sext.w	a5,a5
    80003b2e:	0007069b          	sext.w	a3,a4
    80003b32:	f8f6f4e3          	bgeu	a3,a5,80003aba <writei+0x4c>
    80003b36:	89ba                	mv	s3,a4
    80003b38:	b749                	j	80003aba <writei+0x4c>
      brelse(bp);
    80003b3a:	8526                	mv	a0,s1
    80003b3c:	fffff097          	auipc	ra,0xfffff
    80003b40:	4b4080e7          	jalr	1204(ra) # 80002ff0 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003b44:	04cba783          	lw	a5,76(s7)
    80003b48:	0127f463          	bgeu	a5,s2,80003b50 <writei+0xe2>
      ip->size = off;
    80003b4c:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003b50:	855e                	mv	a0,s7
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	aa8080e7          	jalr	-1368(ra) # 800035fa <iupdate>
  }

  return n;
    80003b5a:	000b051b          	sext.w	a0,s6
}
    80003b5e:	70a6                	ld	ra,104(sp)
    80003b60:	7406                	ld	s0,96(sp)
    80003b62:	64e6                	ld	s1,88(sp)
    80003b64:	6946                	ld	s2,80(sp)
    80003b66:	69a6                	ld	s3,72(sp)
    80003b68:	6a06                	ld	s4,64(sp)
    80003b6a:	7ae2                	ld	s5,56(sp)
    80003b6c:	7b42                	ld	s6,48(sp)
    80003b6e:	7ba2                	ld	s7,40(sp)
    80003b70:	7c02                	ld	s8,32(sp)
    80003b72:	6ce2                	ld	s9,24(sp)
    80003b74:	6d42                	ld	s10,16(sp)
    80003b76:	6da2                	ld	s11,8(sp)
    80003b78:	6165                	addi	sp,sp,112
    80003b7a:	8082                	ret
    return -1;
    80003b7c:	557d                	li	a0,-1
}
    80003b7e:	8082                	ret
    return -1;
    80003b80:	557d                	li	a0,-1
    80003b82:	bff1                	j	80003b5e <writei+0xf0>
    return -1;
    80003b84:	557d                	li	a0,-1
    80003b86:	bfe1                	j	80003b5e <writei+0xf0>

0000000080003b88 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003b88:	1141                	addi	sp,sp,-16
    80003b8a:	e406                	sd	ra,8(sp)
    80003b8c:	e022                	sd	s0,0(sp)
    80003b8e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003b90:	4639                	li	a2,14
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	240080e7          	jalr	576(ra) # 80000dd2 <strncmp>
}
    80003b9a:	60a2                	ld	ra,8(sp)
    80003b9c:	6402                	ld	s0,0(sp)
    80003b9e:	0141                	addi	sp,sp,16
    80003ba0:	8082                	ret

0000000080003ba2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ba2:	7139                	addi	sp,sp,-64
    80003ba4:	fc06                	sd	ra,56(sp)
    80003ba6:	f822                	sd	s0,48(sp)
    80003ba8:	f426                	sd	s1,40(sp)
    80003baa:	f04a                	sd	s2,32(sp)
    80003bac:	ec4e                	sd	s3,24(sp)
    80003bae:	e852                	sd	s4,16(sp)
    80003bb0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003bb2:	04451703          	lh	a4,68(a0)
    80003bb6:	4785                	li	a5,1
    80003bb8:	00f71a63          	bne	a4,a5,80003bcc <dirlookup+0x2a>
    80003bbc:	892a                	mv	s2,a0
    80003bbe:	89ae                	mv	s3,a1
    80003bc0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc2:	457c                	lw	a5,76(a0)
    80003bc4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003bc6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bc8:	e79d                	bnez	a5,80003bf6 <dirlookup+0x54>
    80003bca:	a8a5                	j	80003c42 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003bcc:	00005517          	auipc	a0,0x5
    80003bd0:	a3450513          	addi	a0,a0,-1484 # 80008600 <syscalls+0x1b8>
    80003bd4:	ffffd097          	auipc	ra,0xffffd
    80003bd8:	96e080e7          	jalr	-1682(ra) # 80000542 <panic>
      panic("dirlookup read");
    80003bdc:	00005517          	auipc	a0,0x5
    80003be0:	a3c50513          	addi	a0,a0,-1476 # 80008618 <syscalls+0x1d0>
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	95e080e7          	jalr	-1698(ra) # 80000542 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003bec:	24c1                	addiw	s1,s1,16
    80003bee:	04c92783          	lw	a5,76(s2)
    80003bf2:	04f4f763          	bgeu	s1,a5,80003c40 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003bf6:	4741                	li	a4,16
    80003bf8:	86a6                	mv	a3,s1
    80003bfa:	fc040613          	addi	a2,s0,-64
    80003bfe:	4581                	li	a1,0
    80003c00:	854a                	mv	a0,s2
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	d76080e7          	jalr	-650(ra) # 80003978 <readi>
    80003c0a:	47c1                	li	a5,16
    80003c0c:	fcf518e3          	bne	a0,a5,80003bdc <dirlookup+0x3a>
    if(de.inum == 0)
    80003c10:	fc045783          	lhu	a5,-64(s0)
    80003c14:	dfe1                	beqz	a5,80003bec <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c16:	fc240593          	addi	a1,s0,-62
    80003c1a:	854e                	mv	a0,s3
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	f6c080e7          	jalr	-148(ra) # 80003b88 <namecmp>
    80003c24:	f561                	bnez	a0,80003bec <dirlookup+0x4a>
      if(poff)
    80003c26:	000a0463          	beqz	s4,80003c2e <dirlookup+0x8c>
        *poff = off;
    80003c2a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c2e:	fc045583          	lhu	a1,-64(s0)
    80003c32:	00092503          	lw	a0,0(s2)
    80003c36:	fffff097          	auipc	ra,0xfffff
    80003c3a:	75a080e7          	jalr	1882(ra) # 80003390 <iget>
    80003c3e:	a011                	j	80003c42 <dirlookup+0xa0>
  return 0;
    80003c40:	4501                	li	a0,0
}
    80003c42:	70e2                	ld	ra,56(sp)
    80003c44:	7442                	ld	s0,48(sp)
    80003c46:	74a2                	ld	s1,40(sp)
    80003c48:	7902                	ld	s2,32(sp)
    80003c4a:	69e2                	ld	s3,24(sp)
    80003c4c:	6a42                	ld	s4,16(sp)
    80003c4e:	6121                	addi	sp,sp,64
    80003c50:	8082                	ret

0000000080003c52 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003c52:	711d                	addi	sp,sp,-96
    80003c54:	ec86                	sd	ra,88(sp)
    80003c56:	e8a2                	sd	s0,80(sp)
    80003c58:	e4a6                	sd	s1,72(sp)
    80003c5a:	e0ca                	sd	s2,64(sp)
    80003c5c:	fc4e                	sd	s3,56(sp)
    80003c5e:	f852                	sd	s4,48(sp)
    80003c60:	f456                	sd	s5,40(sp)
    80003c62:	f05a                	sd	s6,32(sp)
    80003c64:	ec5e                	sd	s7,24(sp)
    80003c66:	e862                	sd	s8,16(sp)
    80003c68:	e466                	sd	s9,8(sp)
    80003c6a:	1080                	addi	s0,sp,96
    80003c6c:	84aa                	mv	s1,a0
    80003c6e:	8aae                	mv	s5,a1
    80003c70:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003c72:	00054703          	lbu	a4,0(a0)
    80003c76:	02f00793          	li	a5,47
    80003c7a:	02f70363          	beq	a4,a5,80003ca0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003c7e:	ffffe097          	auipc	ra,0xffffe
    80003c82:	d3c080e7          	jalr	-708(ra) # 800019ba <myproc>
    80003c86:	15053503          	ld	a0,336(a0)
    80003c8a:	00000097          	auipc	ra,0x0
    80003c8e:	9fc080e7          	jalr	-1540(ra) # 80003686 <idup>
    80003c92:	89aa                	mv	s3,a0
  while(*path == '/')
    80003c94:	02f00913          	li	s2,47
  len = path - s;
    80003c98:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003c9a:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003c9c:	4b85                	li	s7,1
    80003c9e:	a865                	j	80003d56 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ca0:	4585                	li	a1,1
    80003ca2:	4505                	li	a0,1
    80003ca4:	fffff097          	auipc	ra,0xfffff
    80003ca8:	6ec080e7          	jalr	1772(ra) # 80003390 <iget>
    80003cac:	89aa                	mv	s3,a0
    80003cae:	b7dd                	j	80003c94 <namex+0x42>
      iunlockput(ip);
    80003cb0:	854e                	mv	a0,s3
    80003cb2:	00000097          	auipc	ra,0x0
    80003cb6:	c74080e7          	jalr	-908(ra) # 80003926 <iunlockput>
      return 0;
    80003cba:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003cbc:	854e                	mv	a0,s3
    80003cbe:	60e6                	ld	ra,88(sp)
    80003cc0:	6446                	ld	s0,80(sp)
    80003cc2:	64a6                	ld	s1,72(sp)
    80003cc4:	6906                	ld	s2,64(sp)
    80003cc6:	79e2                	ld	s3,56(sp)
    80003cc8:	7a42                	ld	s4,48(sp)
    80003cca:	7aa2                	ld	s5,40(sp)
    80003ccc:	7b02                	ld	s6,32(sp)
    80003cce:	6be2                	ld	s7,24(sp)
    80003cd0:	6c42                	ld	s8,16(sp)
    80003cd2:	6ca2                	ld	s9,8(sp)
    80003cd4:	6125                	addi	sp,sp,96
    80003cd6:	8082                	ret
      iunlock(ip);
    80003cd8:	854e                	mv	a0,s3
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	aac080e7          	jalr	-1364(ra) # 80003786 <iunlock>
      return ip;
    80003ce2:	bfe9                	j	80003cbc <namex+0x6a>
      iunlockput(ip);
    80003ce4:	854e                	mv	a0,s3
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	c40080e7          	jalr	-960(ra) # 80003926 <iunlockput>
      return 0;
    80003cee:	89e6                	mv	s3,s9
    80003cf0:	b7f1                	j	80003cbc <namex+0x6a>
  len = path - s;
    80003cf2:	40b48633          	sub	a2,s1,a1
    80003cf6:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003cfa:	099c5463          	bge	s8,s9,80003d82 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003cfe:	4639                	li	a2,14
    80003d00:	8552                	mv	a0,s4
    80003d02:	ffffd097          	auipc	ra,0xffffd
    80003d06:	054080e7          	jalr	84(ra) # 80000d56 <memmove>
  while(*path == '/')
    80003d0a:	0004c783          	lbu	a5,0(s1)
    80003d0e:	01279763          	bne	a5,s2,80003d1c <namex+0xca>
    path++;
    80003d12:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d14:	0004c783          	lbu	a5,0(s1)
    80003d18:	ff278de3          	beq	a5,s2,80003d12 <namex+0xc0>
    ilock(ip);
    80003d1c:	854e                	mv	a0,s3
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	9a6080e7          	jalr	-1626(ra) # 800036c4 <ilock>
    if(ip->type != T_DIR){
    80003d26:	04499783          	lh	a5,68(s3)
    80003d2a:	f97793e3          	bne	a5,s7,80003cb0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003d2e:	000a8563          	beqz	s5,80003d38 <namex+0xe6>
    80003d32:	0004c783          	lbu	a5,0(s1)
    80003d36:	d3cd                	beqz	a5,80003cd8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003d38:	865a                	mv	a2,s6
    80003d3a:	85d2                	mv	a1,s4
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	e64080e7          	jalr	-412(ra) # 80003ba2 <dirlookup>
    80003d46:	8caa                	mv	s9,a0
    80003d48:	dd51                	beqz	a0,80003ce4 <namex+0x92>
    iunlockput(ip);
    80003d4a:	854e                	mv	a0,s3
    80003d4c:	00000097          	auipc	ra,0x0
    80003d50:	bda080e7          	jalr	-1062(ra) # 80003926 <iunlockput>
    ip = next;
    80003d54:	89e6                	mv	s3,s9
  while(*path == '/')
    80003d56:	0004c783          	lbu	a5,0(s1)
    80003d5a:	05279763          	bne	a5,s2,80003da8 <namex+0x156>
    path++;
    80003d5e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d60:	0004c783          	lbu	a5,0(s1)
    80003d64:	ff278de3          	beq	a5,s2,80003d5e <namex+0x10c>
  if(*path == 0)
    80003d68:	c79d                	beqz	a5,80003d96 <namex+0x144>
    path++;
    80003d6a:	85a6                	mv	a1,s1
  len = path - s;
    80003d6c:	8cda                	mv	s9,s6
    80003d6e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003d70:	01278963          	beq	a5,s2,80003d82 <namex+0x130>
    80003d74:	dfbd                	beqz	a5,80003cf2 <namex+0xa0>
    path++;
    80003d76:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003d78:	0004c783          	lbu	a5,0(s1)
    80003d7c:	ff279ce3          	bne	a5,s2,80003d74 <namex+0x122>
    80003d80:	bf8d                	j	80003cf2 <namex+0xa0>
    memmove(name, s, len);
    80003d82:	2601                	sext.w	a2,a2
    80003d84:	8552                	mv	a0,s4
    80003d86:	ffffd097          	auipc	ra,0xffffd
    80003d8a:	fd0080e7          	jalr	-48(ra) # 80000d56 <memmove>
    name[len] = 0;
    80003d8e:	9cd2                	add	s9,s9,s4
    80003d90:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003d94:	bf9d                	j	80003d0a <namex+0xb8>
  if(nameiparent){
    80003d96:	f20a83e3          	beqz	s5,80003cbc <namex+0x6a>
    iput(ip);
    80003d9a:	854e                	mv	a0,s3
    80003d9c:	00000097          	auipc	ra,0x0
    80003da0:	ae2080e7          	jalr	-1310(ra) # 8000387e <iput>
    return 0;
    80003da4:	4981                	li	s3,0
    80003da6:	bf19                	j	80003cbc <namex+0x6a>
  if(*path == 0)
    80003da8:	d7fd                	beqz	a5,80003d96 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003daa:	0004c783          	lbu	a5,0(s1)
    80003dae:	85a6                	mv	a1,s1
    80003db0:	b7d1                	j	80003d74 <namex+0x122>

0000000080003db2 <dirlink>:
{
    80003db2:	7139                	addi	sp,sp,-64
    80003db4:	fc06                	sd	ra,56(sp)
    80003db6:	f822                	sd	s0,48(sp)
    80003db8:	f426                	sd	s1,40(sp)
    80003dba:	f04a                	sd	s2,32(sp)
    80003dbc:	ec4e                	sd	s3,24(sp)
    80003dbe:	e852                	sd	s4,16(sp)
    80003dc0:	0080                	addi	s0,sp,64
    80003dc2:	892a                	mv	s2,a0
    80003dc4:	8a2e                	mv	s4,a1
    80003dc6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003dc8:	4601                	li	a2,0
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	dd8080e7          	jalr	-552(ra) # 80003ba2 <dirlookup>
    80003dd2:	e93d                	bnez	a0,80003e48 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd4:	04c92483          	lw	s1,76(s2)
    80003dd8:	c49d                	beqz	s1,80003e06 <dirlink+0x54>
    80003dda:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ddc:	4741                	li	a4,16
    80003dde:	86a6                	mv	a3,s1
    80003de0:	fc040613          	addi	a2,s0,-64
    80003de4:	4581                	li	a1,0
    80003de6:	854a                	mv	a0,s2
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	b90080e7          	jalr	-1136(ra) # 80003978 <readi>
    80003df0:	47c1                	li	a5,16
    80003df2:	06f51163          	bne	a0,a5,80003e54 <dirlink+0xa2>
    if(de.inum == 0)
    80003df6:	fc045783          	lhu	a5,-64(s0)
    80003dfa:	c791                	beqz	a5,80003e06 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfc:	24c1                	addiw	s1,s1,16
    80003dfe:	04c92783          	lw	a5,76(s2)
    80003e02:	fcf4ede3          	bltu	s1,a5,80003ddc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e06:	4639                	li	a2,14
    80003e08:	85d2                	mv	a1,s4
    80003e0a:	fc240513          	addi	a0,s0,-62
    80003e0e:	ffffd097          	auipc	ra,0xffffd
    80003e12:	000080e7          	jalr	ra # 80000e0e <strncpy>
  de.inum = inum;
    80003e16:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e1a:	4741                	li	a4,16
    80003e1c:	86a6                	mv	a3,s1
    80003e1e:	fc040613          	addi	a2,s0,-64
    80003e22:	4581                	li	a1,0
    80003e24:	854a                	mv	a0,s2
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	c48080e7          	jalr	-952(ra) # 80003a6e <writei>
    80003e2e:	872a                	mv	a4,a0
    80003e30:	47c1                	li	a5,16
  return 0;
    80003e32:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e34:	02f71863          	bne	a4,a5,80003e64 <dirlink+0xb2>
}
    80003e38:	70e2                	ld	ra,56(sp)
    80003e3a:	7442                	ld	s0,48(sp)
    80003e3c:	74a2                	ld	s1,40(sp)
    80003e3e:	7902                	ld	s2,32(sp)
    80003e40:	69e2                	ld	s3,24(sp)
    80003e42:	6a42                	ld	s4,16(sp)
    80003e44:	6121                	addi	sp,sp,64
    80003e46:	8082                	ret
    iput(ip);
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	a36080e7          	jalr	-1482(ra) # 8000387e <iput>
    return -1;
    80003e50:	557d                	li	a0,-1
    80003e52:	b7dd                	j	80003e38 <dirlink+0x86>
      panic("dirlink read");
    80003e54:	00004517          	auipc	a0,0x4
    80003e58:	7d450513          	addi	a0,a0,2004 # 80008628 <syscalls+0x1e0>
    80003e5c:	ffffc097          	auipc	ra,0xffffc
    80003e60:	6e6080e7          	jalr	1766(ra) # 80000542 <panic>
    panic("dirlink");
    80003e64:	00005517          	auipc	a0,0x5
    80003e68:	8e450513          	addi	a0,a0,-1820 # 80008748 <syscalls+0x300>
    80003e6c:	ffffc097          	auipc	ra,0xffffc
    80003e70:	6d6080e7          	jalr	1750(ra) # 80000542 <panic>

0000000080003e74 <namei>:

struct inode*
namei(char *path)
{
    80003e74:	1101                	addi	sp,sp,-32
    80003e76:	ec06                	sd	ra,24(sp)
    80003e78:	e822                	sd	s0,16(sp)
    80003e7a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003e7c:	fe040613          	addi	a2,s0,-32
    80003e80:	4581                	li	a1,0
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	dd0080e7          	jalr	-560(ra) # 80003c52 <namex>
}
    80003e8a:	60e2                	ld	ra,24(sp)
    80003e8c:	6442                	ld	s0,16(sp)
    80003e8e:	6105                	addi	sp,sp,32
    80003e90:	8082                	ret

0000000080003e92 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003e92:	1141                	addi	sp,sp,-16
    80003e94:	e406                	sd	ra,8(sp)
    80003e96:	e022                	sd	s0,0(sp)
    80003e98:	0800                	addi	s0,sp,16
    80003e9a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003e9c:	4585                	li	a1,1
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	db4080e7          	jalr	-588(ra) # 80003c52 <namex>
}
    80003ea6:	60a2                	ld	ra,8(sp)
    80003ea8:	6402                	ld	s0,0(sp)
    80003eaa:	0141                	addi	sp,sp,16
    80003eac:	8082                	ret

0000000080003eae <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003eae:	1101                	addi	sp,sp,-32
    80003eb0:	ec06                	sd	ra,24(sp)
    80003eb2:	e822                	sd	s0,16(sp)
    80003eb4:	e426                	sd	s1,8(sp)
    80003eb6:	e04a                	sd	s2,0(sp)
    80003eb8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003eba:	0001e917          	auipc	s2,0x1e
    80003ebe:	a4e90913          	addi	s2,s2,-1458 # 80021908 <log>
    80003ec2:	01892583          	lw	a1,24(s2)
    80003ec6:	02892503          	lw	a0,40(s2)
    80003eca:	fffff097          	auipc	ra,0xfffff
    80003ece:	ff6080e7          	jalr	-10(ra) # 80002ec0 <bread>
    80003ed2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ed4:	02c92683          	lw	a3,44(s2)
    80003ed8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003eda:	02d05863          	blez	a3,80003f0a <write_head+0x5c>
    80003ede:	0001e797          	auipc	a5,0x1e
    80003ee2:	a5a78793          	addi	a5,a5,-1446 # 80021938 <log+0x30>
    80003ee6:	05c50713          	addi	a4,a0,92
    80003eea:	36fd                	addiw	a3,a3,-1
    80003eec:	02069613          	slli	a2,a3,0x20
    80003ef0:	01e65693          	srli	a3,a2,0x1e
    80003ef4:	0001e617          	auipc	a2,0x1e
    80003ef8:	a4860613          	addi	a2,a2,-1464 # 8002193c <log+0x34>
    80003efc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003efe:	4390                	lw	a2,0(a5)
    80003f00:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f02:	0791                	addi	a5,a5,4
    80003f04:	0711                	addi	a4,a4,4
    80003f06:	fed79ce3          	bne	a5,a3,80003efe <write_head+0x50>
  }
  bwrite(buf);
    80003f0a:	8526                	mv	a0,s1
    80003f0c:	fffff097          	auipc	ra,0xfffff
    80003f10:	0a6080e7          	jalr	166(ra) # 80002fb2 <bwrite>
  brelse(buf);
    80003f14:	8526                	mv	a0,s1
    80003f16:	fffff097          	auipc	ra,0xfffff
    80003f1a:	0da080e7          	jalr	218(ra) # 80002ff0 <brelse>
}
    80003f1e:	60e2                	ld	ra,24(sp)
    80003f20:	6442                	ld	s0,16(sp)
    80003f22:	64a2                	ld	s1,8(sp)
    80003f24:	6902                	ld	s2,0(sp)
    80003f26:	6105                	addi	sp,sp,32
    80003f28:	8082                	ret

0000000080003f2a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f2a:	0001e797          	auipc	a5,0x1e
    80003f2e:	a0a7a783          	lw	a5,-1526(a5) # 80021934 <log+0x2c>
    80003f32:	0af05663          	blez	a5,80003fde <install_trans+0xb4>
{
    80003f36:	7139                	addi	sp,sp,-64
    80003f38:	fc06                	sd	ra,56(sp)
    80003f3a:	f822                	sd	s0,48(sp)
    80003f3c:	f426                	sd	s1,40(sp)
    80003f3e:	f04a                	sd	s2,32(sp)
    80003f40:	ec4e                	sd	s3,24(sp)
    80003f42:	e852                	sd	s4,16(sp)
    80003f44:	e456                	sd	s5,8(sp)
    80003f46:	0080                	addi	s0,sp,64
    80003f48:	0001ea97          	auipc	s5,0x1e
    80003f4c:	9f0a8a93          	addi	s5,s5,-1552 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f50:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003f52:	0001e997          	auipc	s3,0x1e
    80003f56:	9b698993          	addi	s3,s3,-1610 # 80021908 <log>
    80003f5a:	0189a583          	lw	a1,24(s3)
    80003f5e:	014585bb          	addw	a1,a1,s4
    80003f62:	2585                	addiw	a1,a1,1
    80003f64:	0289a503          	lw	a0,40(s3)
    80003f68:	fffff097          	auipc	ra,0xfffff
    80003f6c:	f58080e7          	jalr	-168(ra) # 80002ec0 <bread>
    80003f70:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003f72:	000aa583          	lw	a1,0(s5)
    80003f76:	0289a503          	lw	a0,40(s3)
    80003f7a:	fffff097          	auipc	ra,0xfffff
    80003f7e:	f46080e7          	jalr	-186(ra) # 80002ec0 <bread>
    80003f82:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003f84:	40000613          	li	a2,1024
    80003f88:	05890593          	addi	a1,s2,88
    80003f8c:	05850513          	addi	a0,a0,88
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	dc6080e7          	jalr	-570(ra) # 80000d56 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003f98:	8526                	mv	a0,s1
    80003f9a:	fffff097          	auipc	ra,0xfffff
    80003f9e:	018080e7          	jalr	24(ra) # 80002fb2 <bwrite>
    bunpin(dbuf);
    80003fa2:	8526                	mv	a0,s1
    80003fa4:	fffff097          	auipc	ra,0xfffff
    80003fa8:	126080e7          	jalr	294(ra) # 800030ca <bunpin>
    brelse(lbuf);
    80003fac:	854a                	mv	a0,s2
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	042080e7          	jalr	66(ra) # 80002ff0 <brelse>
    brelse(dbuf);
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	038080e7          	jalr	56(ra) # 80002ff0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc0:	2a05                	addiw	s4,s4,1
    80003fc2:	0a91                	addi	s5,s5,4
    80003fc4:	02c9a783          	lw	a5,44(s3)
    80003fc8:	f8fa49e3          	blt	s4,a5,80003f5a <install_trans+0x30>
}
    80003fcc:	70e2                	ld	ra,56(sp)
    80003fce:	7442                	ld	s0,48(sp)
    80003fd0:	74a2                	ld	s1,40(sp)
    80003fd2:	7902                	ld	s2,32(sp)
    80003fd4:	69e2                	ld	s3,24(sp)
    80003fd6:	6a42                	ld	s4,16(sp)
    80003fd8:	6aa2                	ld	s5,8(sp)
    80003fda:	6121                	addi	sp,sp,64
    80003fdc:	8082                	ret
    80003fde:	8082                	ret

0000000080003fe0 <initlog>:
{
    80003fe0:	7179                	addi	sp,sp,-48
    80003fe2:	f406                	sd	ra,40(sp)
    80003fe4:	f022                	sd	s0,32(sp)
    80003fe6:	ec26                	sd	s1,24(sp)
    80003fe8:	e84a                	sd	s2,16(sp)
    80003fea:	e44e                	sd	s3,8(sp)
    80003fec:	1800                	addi	s0,sp,48
    80003fee:	892a                	mv	s2,a0
    80003ff0:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003ff2:	0001e497          	auipc	s1,0x1e
    80003ff6:	91648493          	addi	s1,s1,-1770 # 80021908 <log>
    80003ffa:	00004597          	auipc	a1,0x4
    80003ffe:	63e58593          	addi	a1,a1,1598 # 80008638 <syscalls+0x1f0>
    80004002:	8526                	mv	a0,s1
    80004004:	ffffd097          	auipc	ra,0xffffd
    80004008:	b6a080e7          	jalr	-1174(ra) # 80000b6e <initlock>
  log.start = sb->logstart;
    8000400c:	0149a583          	lw	a1,20(s3)
    80004010:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004012:	0109a783          	lw	a5,16(s3)
    80004016:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004018:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000401c:	854a                	mv	a0,s2
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	ea2080e7          	jalr	-350(ra) # 80002ec0 <bread>
  log.lh.n = lh->n;
    80004026:	4d34                	lw	a3,88(a0)
    80004028:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000402a:	02d05663          	blez	a3,80004056 <initlog+0x76>
    8000402e:	05c50793          	addi	a5,a0,92
    80004032:	0001e717          	auipc	a4,0x1e
    80004036:	90670713          	addi	a4,a4,-1786 # 80021938 <log+0x30>
    8000403a:	36fd                	addiw	a3,a3,-1
    8000403c:	02069613          	slli	a2,a3,0x20
    80004040:	01e65693          	srli	a3,a2,0x1e
    80004044:	06050613          	addi	a2,a0,96
    80004048:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000404a:	4390                	lw	a2,0(a5)
    8000404c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000404e:	0791                	addi	a5,a5,4
    80004050:	0711                	addi	a4,a4,4
    80004052:	fed79ce3          	bne	a5,a3,8000404a <initlog+0x6a>
  brelse(buf);
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	f9a080e7          	jalr	-102(ra) # 80002ff0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	ecc080e7          	jalr	-308(ra) # 80003f2a <install_trans>
  log.lh.n = 0;
    80004066:	0001e797          	auipc	a5,0x1e
    8000406a:	8c07a723          	sw	zero,-1842(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    8000406e:	00000097          	auipc	ra,0x0
    80004072:	e40080e7          	jalr	-448(ra) # 80003eae <write_head>
}
    80004076:	70a2                	ld	ra,40(sp)
    80004078:	7402                	ld	s0,32(sp)
    8000407a:	64e2                	ld	s1,24(sp)
    8000407c:	6942                	ld	s2,16(sp)
    8000407e:	69a2                	ld	s3,8(sp)
    80004080:	6145                	addi	sp,sp,48
    80004082:	8082                	ret

0000000080004084 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004084:	1101                	addi	sp,sp,-32
    80004086:	ec06                	sd	ra,24(sp)
    80004088:	e822                	sd	s0,16(sp)
    8000408a:	e426                	sd	s1,8(sp)
    8000408c:	e04a                	sd	s2,0(sp)
    8000408e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004090:	0001e517          	auipc	a0,0x1e
    80004094:	87850513          	addi	a0,a0,-1928 # 80021908 <log>
    80004098:	ffffd097          	auipc	ra,0xffffd
    8000409c:	b66080e7          	jalr	-1178(ra) # 80000bfe <acquire>
  while(1){
    if(log.committing){
    800040a0:	0001e497          	auipc	s1,0x1e
    800040a4:	86848493          	addi	s1,s1,-1944 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040a8:	4979                	li	s2,30
    800040aa:	a039                	j	800040b8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040ac:	85a6                	mv	a1,s1
    800040ae:	8526                	mv	a0,s1
    800040b0:	ffffe097          	auipc	ra,0xffffe
    800040b4:	0fa080e7          	jalr	250(ra) # 800021aa <sleep>
    if(log.committing){
    800040b8:	50dc                	lw	a5,36(s1)
    800040ba:	fbed                	bnez	a5,800040ac <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040bc:	509c                	lw	a5,32(s1)
    800040be:	0017871b          	addiw	a4,a5,1
    800040c2:	0007069b          	sext.w	a3,a4
    800040c6:	0027179b          	slliw	a5,a4,0x2
    800040ca:	9fb9                	addw	a5,a5,a4
    800040cc:	0017979b          	slliw	a5,a5,0x1
    800040d0:	54d8                	lw	a4,44(s1)
    800040d2:	9fb9                	addw	a5,a5,a4
    800040d4:	00f95963          	bge	s2,a5,800040e6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800040d8:	85a6                	mv	a1,s1
    800040da:	8526                	mv	a0,s1
    800040dc:	ffffe097          	auipc	ra,0xffffe
    800040e0:	0ce080e7          	jalr	206(ra) # 800021aa <sleep>
    800040e4:	bfd1                	j	800040b8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800040e6:	0001e517          	auipc	a0,0x1e
    800040ea:	82250513          	addi	a0,a0,-2014 # 80021908 <log>
    800040ee:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800040f0:	ffffd097          	auipc	ra,0xffffd
    800040f4:	bc2080e7          	jalr	-1086(ra) # 80000cb2 <release>
      break;
    }
  }
}
    800040f8:	60e2                	ld	ra,24(sp)
    800040fa:	6442                	ld	s0,16(sp)
    800040fc:	64a2                	ld	s1,8(sp)
    800040fe:	6902                	ld	s2,0(sp)
    80004100:	6105                	addi	sp,sp,32
    80004102:	8082                	ret

0000000080004104 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004104:	7139                	addi	sp,sp,-64
    80004106:	fc06                	sd	ra,56(sp)
    80004108:	f822                	sd	s0,48(sp)
    8000410a:	f426                	sd	s1,40(sp)
    8000410c:	f04a                	sd	s2,32(sp)
    8000410e:	ec4e                	sd	s3,24(sp)
    80004110:	e852                	sd	s4,16(sp)
    80004112:	e456                	sd	s5,8(sp)
    80004114:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004116:	0001d497          	auipc	s1,0x1d
    8000411a:	7f248493          	addi	s1,s1,2034 # 80021908 <log>
    8000411e:	8526                	mv	a0,s1
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	ade080e7          	jalr	-1314(ra) # 80000bfe <acquire>
  log.outstanding -= 1;
    80004128:	509c                	lw	a5,32(s1)
    8000412a:	37fd                	addiw	a5,a5,-1
    8000412c:	0007891b          	sext.w	s2,a5
    80004130:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004132:	50dc                	lw	a5,36(s1)
    80004134:	e7b9                	bnez	a5,80004182 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004136:	04091e63          	bnez	s2,80004192 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000413a:	0001d497          	auipc	s1,0x1d
    8000413e:	7ce48493          	addi	s1,s1,1998 # 80021908 <log>
    80004142:	4785                	li	a5,1
    80004144:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004146:	8526                	mv	a0,s1
    80004148:	ffffd097          	auipc	ra,0xffffd
    8000414c:	b6a080e7          	jalr	-1174(ra) # 80000cb2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004150:	54dc                	lw	a5,44(s1)
    80004152:	06f04763          	bgtz	a5,800041c0 <end_op+0xbc>
    acquire(&log.lock);
    80004156:	0001d497          	auipc	s1,0x1d
    8000415a:	7b248493          	addi	s1,s1,1970 # 80021908 <log>
    8000415e:	8526                	mv	a0,s1
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	a9e080e7          	jalr	-1378(ra) # 80000bfe <acquire>
    log.committing = 0;
    80004168:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000416c:	8526                	mv	a0,s1
    8000416e:	ffffe097          	auipc	ra,0xffffe
    80004172:	1bc080e7          	jalr	444(ra) # 8000232a <wakeup>
    release(&log.lock);
    80004176:	8526                	mv	a0,s1
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	b3a080e7          	jalr	-1222(ra) # 80000cb2 <release>
}
    80004180:	a03d                	j	800041ae <end_op+0xaa>
    panic("log.committing");
    80004182:	00004517          	auipc	a0,0x4
    80004186:	4be50513          	addi	a0,a0,1214 # 80008640 <syscalls+0x1f8>
    8000418a:	ffffc097          	auipc	ra,0xffffc
    8000418e:	3b8080e7          	jalr	952(ra) # 80000542 <panic>
    wakeup(&log);
    80004192:	0001d497          	auipc	s1,0x1d
    80004196:	77648493          	addi	s1,s1,1910 # 80021908 <log>
    8000419a:	8526                	mv	a0,s1
    8000419c:	ffffe097          	auipc	ra,0xffffe
    800041a0:	18e080e7          	jalr	398(ra) # 8000232a <wakeup>
  release(&log.lock);
    800041a4:	8526                	mv	a0,s1
    800041a6:	ffffd097          	auipc	ra,0xffffd
    800041aa:	b0c080e7          	jalr	-1268(ra) # 80000cb2 <release>
}
    800041ae:	70e2                	ld	ra,56(sp)
    800041b0:	7442                	ld	s0,48(sp)
    800041b2:	74a2                	ld	s1,40(sp)
    800041b4:	7902                	ld	s2,32(sp)
    800041b6:	69e2                	ld	s3,24(sp)
    800041b8:	6a42                	ld	s4,16(sp)
    800041ba:	6aa2                	ld	s5,8(sp)
    800041bc:	6121                	addi	sp,sp,64
    800041be:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800041c0:	0001da97          	auipc	s5,0x1d
    800041c4:	778a8a93          	addi	s5,s5,1912 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800041c8:	0001da17          	auipc	s4,0x1d
    800041cc:	740a0a13          	addi	s4,s4,1856 # 80021908 <log>
    800041d0:	018a2583          	lw	a1,24(s4)
    800041d4:	012585bb          	addw	a1,a1,s2
    800041d8:	2585                	addiw	a1,a1,1
    800041da:	028a2503          	lw	a0,40(s4)
    800041de:	fffff097          	auipc	ra,0xfffff
    800041e2:	ce2080e7          	jalr	-798(ra) # 80002ec0 <bread>
    800041e6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800041e8:	000aa583          	lw	a1,0(s5)
    800041ec:	028a2503          	lw	a0,40(s4)
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	cd0080e7          	jalr	-816(ra) # 80002ec0 <bread>
    800041f8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800041fa:	40000613          	li	a2,1024
    800041fe:	05850593          	addi	a1,a0,88
    80004202:	05848513          	addi	a0,s1,88
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	b50080e7          	jalr	-1200(ra) # 80000d56 <memmove>
    bwrite(to);  // write the log
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	da2080e7          	jalr	-606(ra) # 80002fb2 <bwrite>
    brelse(from);
    80004218:	854e                	mv	a0,s3
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	dd6080e7          	jalr	-554(ra) # 80002ff0 <brelse>
    brelse(to);
    80004222:	8526                	mv	a0,s1
    80004224:	fffff097          	auipc	ra,0xfffff
    80004228:	dcc080e7          	jalr	-564(ra) # 80002ff0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000422c:	2905                	addiw	s2,s2,1
    8000422e:	0a91                	addi	s5,s5,4
    80004230:	02ca2783          	lw	a5,44(s4)
    80004234:	f8f94ee3          	blt	s2,a5,800041d0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004238:	00000097          	auipc	ra,0x0
    8000423c:	c76080e7          	jalr	-906(ra) # 80003eae <write_head>
    install_trans(); // Now install writes to home locations
    80004240:	00000097          	auipc	ra,0x0
    80004244:	cea080e7          	jalr	-790(ra) # 80003f2a <install_trans>
    log.lh.n = 0;
    80004248:	0001d797          	auipc	a5,0x1d
    8000424c:	6e07a623          	sw	zero,1772(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004250:	00000097          	auipc	ra,0x0
    80004254:	c5e080e7          	jalr	-930(ra) # 80003eae <write_head>
    80004258:	bdfd                	j	80004156 <end_op+0x52>

000000008000425a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000425a:	1101                	addi	sp,sp,-32
    8000425c:	ec06                	sd	ra,24(sp)
    8000425e:	e822                	sd	s0,16(sp)
    80004260:	e426                	sd	s1,8(sp)
    80004262:	e04a                	sd	s2,0(sp)
    80004264:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004266:	0001d717          	auipc	a4,0x1d
    8000426a:	6ce72703          	lw	a4,1742(a4) # 80021934 <log+0x2c>
    8000426e:	47f5                	li	a5,29
    80004270:	08e7c063          	blt	a5,a4,800042f0 <log_write+0x96>
    80004274:	84aa                	mv	s1,a0
    80004276:	0001d797          	auipc	a5,0x1d
    8000427a:	6ae7a783          	lw	a5,1710(a5) # 80021924 <log+0x1c>
    8000427e:	37fd                	addiw	a5,a5,-1
    80004280:	06f75863          	bge	a4,a5,800042f0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004284:	0001d797          	auipc	a5,0x1d
    80004288:	6a47a783          	lw	a5,1700(a5) # 80021928 <log+0x20>
    8000428c:	06f05a63          	blez	a5,80004300 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004290:	0001d917          	auipc	s2,0x1d
    80004294:	67890913          	addi	s2,s2,1656 # 80021908 <log>
    80004298:	854a                	mv	a0,s2
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	964080e7          	jalr	-1692(ra) # 80000bfe <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800042a2:	02c92603          	lw	a2,44(s2)
    800042a6:	06c05563          	blez	a2,80004310 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042aa:	44cc                	lw	a1,12(s1)
    800042ac:	0001d717          	auipc	a4,0x1d
    800042b0:	68c70713          	addi	a4,a4,1676 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042b4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800042b6:	4314                	lw	a3,0(a4)
    800042b8:	04b68d63          	beq	a3,a1,80004312 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800042bc:	2785                	addiw	a5,a5,1
    800042be:	0711                	addi	a4,a4,4
    800042c0:	fec79be3          	bne	a5,a2,800042b6 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800042c4:	0621                	addi	a2,a2,8
    800042c6:	060a                	slli	a2,a2,0x2
    800042c8:	0001d797          	auipc	a5,0x1d
    800042cc:	64078793          	addi	a5,a5,1600 # 80021908 <log>
    800042d0:	963e                	add	a2,a2,a5
    800042d2:	44dc                	lw	a5,12(s1)
    800042d4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800042d6:	8526                	mv	a0,s1
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	db6080e7          	jalr	-586(ra) # 8000308e <bpin>
    log.lh.n++;
    800042e0:	0001d717          	auipc	a4,0x1d
    800042e4:	62870713          	addi	a4,a4,1576 # 80021908 <log>
    800042e8:	575c                	lw	a5,44(a4)
    800042ea:	2785                	addiw	a5,a5,1
    800042ec:	d75c                	sw	a5,44(a4)
    800042ee:	a83d                	j	8000432c <log_write+0xd2>
    panic("too big a transaction");
    800042f0:	00004517          	auipc	a0,0x4
    800042f4:	36050513          	addi	a0,a0,864 # 80008650 <syscalls+0x208>
    800042f8:	ffffc097          	auipc	ra,0xffffc
    800042fc:	24a080e7          	jalr	586(ra) # 80000542 <panic>
    panic("log_write outside of trans");
    80004300:	00004517          	auipc	a0,0x4
    80004304:	36850513          	addi	a0,a0,872 # 80008668 <syscalls+0x220>
    80004308:	ffffc097          	auipc	ra,0xffffc
    8000430c:	23a080e7          	jalr	570(ra) # 80000542 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004310:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004312:	00878713          	addi	a4,a5,8
    80004316:	00271693          	slli	a3,a4,0x2
    8000431a:	0001d717          	auipc	a4,0x1d
    8000431e:	5ee70713          	addi	a4,a4,1518 # 80021908 <log>
    80004322:	9736                	add	a4,a4,a3
    80004324:	44d4                	lw	a3,12(s1)
    80004326:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004328:	faf607e3          	beq	a2,a5,800042d6 <log_write+0x7c>
  }
  release(&log.lock);
    8000432c:	0001d517          	auipc	a0,0x1d
    80004330:	5dc50513          	addi	a0,a0,1500 # 80021908 <log>
    80004334:	ffffd097          	auipc	ra,0xffffd
    80004338:	97e080e7          	jalr	-1666(ra) # 80000cb2 <release>
}
    8000433c:	60e2                	ld	ra,24(sp)
    8000433e:	6442                	ld	s0,16(sp)
    80004340:	64a2                	ld	s1,8(sp)
    80004342:	6902                	ld	s2,0(sp)
    80004344:	6105                	addi	sp,sp,32
    80004346:	8082                	ret

0000000080004348 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004348:	1101                	addi	sp,sp,-32
    8000434a:	ec06                	sd	ra,24(sp)
    8000434c:	e822                	sd	s0,16(sp)
    8000434e:	e426                	sd	s1,8(sp)
    80004350:	e04a                	sd	s2,0(sp)
    80004352:	1000                	addi	s0,sp,32
    80004354:	84aa                	mv	s1,a0
    80004356:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004358:	00004597          	auipc	a1,0x4
    8000435c:	33058593          	addi	a1,a1,816 # 80008688 <syscalls+0x240>
    80004360:	0521                	addi	a0,a0,8
    80004362:	ffffd097          	auipc	ra,0xffffd
    80004366:	80c080e7          	jalr	-2036(ra) # 80000b6e <initlock>
  lk->name = name;
    8000436a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000436e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004372:	0204a423          	sw	zero,40(s1)
}
    80004376:	60e2                	ld	ra,24(sp)
    80004378:	6442                	ld	s0,16(sp)
    8000437a:	64a2                	ld	s1,8(sp)
    8000437c:	6902                	ld	s2,0(sp)
    8000437e:	6105                	addi	sp,sp,32
    80004380:	8082                	ret

0000000080004382 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004382:	1101                	addi	sp,sp,-32
    80004384:	ec06                	sd	ra,24(sp)
    80004386:	e822                	sd	s0,16(sp)
    80004388:	e426                	sd	s1,8(sp)
    8000438a:	e04a                	sd	s2,0(sp)
    8000438c:	1000                	addi	s0,sp,32
    8000438e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004390:	00850913          	addi	s2,a0,8
    80004394:	854a                	mv	a0,s2
    80004396:	ffffd097          	auipc	ra,0xffffd
    8000439a:	868080e7          	jalr	-1944(ra) # 80000bfe <acquire>
  while (lk->locked) {
    8000439e:	409c                	lw	a5,0(s1)
    800043a0:	cb89                	beqz	a5,800043b2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043a2:	85ca                	mv	a1,s2
    800043a4:	8526                	mv	a0,s1
    800043a6:	ffffe097          	auipc	ra,0xffffe
    800043aa:	e04080e7          	jalr	-508(ra) # 800021aa <sleep>
  while (lk->locked) {
    800043ae:	409c                	lw	a5,0(s1)
    800043b0:	fbed                	bnez	a5,800043a2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043b2:	4785                	li	a5,1
    800043b4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043b6:	ffffd097          	auipc	ra,0xffffd
    800043ba:	604080e7          	jalr	1540(ra) # 800019ba <myproc>
    800043be:	5d1c                	lw	a5,56(a0)
    800043c0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800043c2:	854a                	mv	a0,s2
    800043c4:	ffffd097          	auipc	ra,0xffffd
    800043c8:	8ee080e7          	jalr	-1810(ra) # 80000cb2 <release>
}
    800043cc:	60e2                	ld	ra,24(sp)
    800043ce:	6442                	ld	s0,16(sp)
    800043d0:	64a2                	ld	s1,8(sp)
    800043d2:	6902                	ld	s2,0(sp)
    800043d4:	6105                	addi	sp,sp,32
    800043d6:	8082                	ret

00000000800043d8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800043d8:	1101                	addi	sp,sp,-32
    800043da:	ec06                	sd	ra,24(sp)
    800043dc:	e822                	sd	s0,16(sp)
    800043de:	e426                	sd	s1,8(sp)
    800043e0:	e04a                	sd	s2,0(sp)
    800043e2:	1000                	addi	s0,sp,32
    800043e4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043e6:	00850913          	addi	s2,a0,8
    800043ea:	854a                	mv	a0,s2
    800043ec:	ffffd097          	auipc	ra,0xffffd
    800043f0:	812080e7          	jalr	-2030(ra) # 80000bfe <acquire>
  lk->locked = 0;
    800043f4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043f8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffe097          	auipc	ra,0xffffe
    80004402:	f2c080e7          	jalr	-212(ra) # 8000232a <wakeup>
  release(&lk->lk);
    80004406:	854a                	mv	a0,s2
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	8aa080e7          	jalr	-1878(ra) # 80000cb2 <release>
}
    80004410:	60e2                	ld	ra,24(sp)
    80004412:	6442                	ld	s0,16(sp)
    80004414:	64a2                	ld	s1,8(sp)
    80004416:	6902                	ld	s2,0(sp)
    80004418:	6105                	addi	sp,sp,32
    8000441a:	8082                	ret

000000008000441c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000441c:	7179                	addi	sp,sp,-48
    8000441e:	f406                	sd	ra,40(sp)
    80004420:	f022                	sd	s0,32(sp)
    80004422:	ec26                	sd	s1,24(sp)
    80004424:	e84a                	sd	s2,16(sp)
    80004426:	e44e                	sd	s3,8(sp)
    80004428:	1800                	addi	s0,sp,48
    8000442a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000442c:	00850913          	addi	s2,a0,8
    80004430:	854a                	mv	a0,s2
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	7cc080e7          	jalr	1996(ra) # 80000bfe <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000443a:	409c                	lw	a5,0(s1)
    8000443c:	ef99                	bnez	a5,8000445a <holdingsleep+0x3e>
    8000443e:	4481                	li	s1,0
  release(&lk->lk);
    80004440:	854a                	mv	a0,s2
    80004442:	ffffd097          	auipc	ra,0xffffd
    80004446:	870080e7          	jalr	-1936(ra) # 80000cb2 <release>
  return r;
}
    8000444a:	8526                	mv	a0,s1
    8000444c:	70a2                	ld	ra,40(sp)
    8000444e:	7402                	ld	s0,32(sp)
    80004450:	64e2                	ld	s1,24(sp)
    80004452:	6942                	ld	s2,16(sp)
    80004454:	69a2                	ld	s3,8(sp)
    80004456:	6145                	addi	sp,sp,48
    80004458:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000445a:	0284a983          	lw	s3,40(s1)
    8000445e:	ffffd097          	auipc	ra,0xffffd
    80004462:	55c080e7          	jalr	1372(ra) # 800019ba <myproc>
    80004466:	5d04                	lw	s1,56(a0)
    80004468:	413484b3          	sub	s1,s1,s3
    8000446c:	0014b493          	seqz	s1,s1
    80004470:	bfc1                	j	80004440 <holdingsleep+0x24>

0000000080004472 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004472:	1141                	addi	sp,sp,-16
    80004474:	e406                	sd	ra,8(sp)
    80004476:	e022                	sd	s0,0(sp)
    80004478:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000447a:	00004597          	auipc	a1,0x4
    8000447e:	21e58593          	addi	a1,a1,542 # 80008698 <syscalls+0x250>
    80004482:	0001d517          	auipc	a0,0x1d
    80004486:	5ce50513          	addi	a0,a0,1486 # 80021a50 <ftable>
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	6e4080e7          	jalr	1764(ra) # 80000b6e <initlock>
}
    80004492:	60a2                	ld	ra,8(sp)
    80004494:	6402                	ld	s0,0(sp)
    80004496:	0141                	addi	sp,sp,16
    80004498:	8082                	ret

000000008000449a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000449a:	1101                	addi	sp,sp,-32
    8000449c:	ec06                	sd	ra,24(sp)
    8000449e:	e822                	sd	s0,16(sp)
    800044a0:	e426                	sd	s1,8(sp)
    800044a2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044a4:	0001d517          	auipc	a0,0x1d
    800044a8:	5ac50513          	addi	a0,a0,1452 # 80021a50 <ftable>
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	752080e7          	jalr	1874(ra) # 80000bfe <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044b4:	0001d497          	auipc	s1,0x1d
    800044b8:	5b448493          	addi	s1,s1,1460 # 80021a68 <ftable+0x18>
    800044bc:	0001e717          	auipc	a4,0x1e
    800044c0:	54c70713          	addi	a4,a4,1356 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800044c4:	40dc                	lw	a5,4(s1)
    800044c6:	cf99                	beqz	a5,800044e4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044c8:	02848493          	addi	s1,s1,40
    800044cc:	fee49ce3          	bne	s1,a4,800044c4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800044d0:	0001d517          	auipc	a0,0x1d
    800044d4:	58050513          	addi	a0,a0,1408 # 80021a50 <ftable>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	7da080e7          	jalr	2010(ra) # 80000cb2 <release>
  return 0;
    800044e0:	4481                	li	s1,0
    800044e2:	a819                	j	800044f8 <filealloc+0x5e>
      f->ref = 1;
    800044e4:	4785                	li	a5,1
    800044e6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800044e8:	0001d517          	auipc	a0,0x1d
    800044ec:	56850513          	addi	a0,a0,1384 # 80021a50 <ftable>
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	7c2080e7          	jalr	1986(ra) # 80000cb2 <release>
}
    800044f8:	8526                	mv	a0,s1
    800044fa:	60e2                	ld	ra,24(sp)
    800044fc:	6442                	ld	s0,16(sp)
    800044fe:	64a2                	ld	s1,8(sp)
    80004500:	6105                	addi	sp,sp,32
    80004502:	8082                	ret

0000000080004504 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004504:	1101                	addi	sp,sp,-32
    80004506:	ec06                	sd	ra,24(sp)
    80004508:	e822                	sd	s0,16(sp)
    8000450a:	e426                	sd	s1,8(sp)
    8000450c:	1000                	addi	s0,sp,32
    8000450e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004510:	0001d517          	auipc	a0,0x1d
    80004514:	54050513          	addi	a0,a0,1344 # 80021a50 <ftable>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	6e6080e7          	jalr	1766(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    80004520:	40dc                	lw	a5,4(s1)
    80004522:	02f05263          	blez	a5,80004546 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004526:	2785                	addiw	a5,a5,1
    80004528:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000452a:	0001d517          	auipc	a0,0x1d
    8000452e:	52650513          	addi	a0,a0,1318 # 80021a50 <ftable>
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	780080e7          	jalr	1920(ra) # 80000cb2 <release>
  return f;
}
    8000453a:	8526                	mv	a0,s1
    8000453c:	60e2                	ld	ra,24(sp)
    8000453e:	6442                	ld	s0,16(sp)
    80004540:	64a2                	ld	s1,8(sp)
    80004542:	6105                	addi	sp,sp,32
    80004544:	8082                	ret
    panic("filedup");
    80004546:	00004517          	auipc	a0,0x4
    8000454a:	15a50513          	addi	a0,a0,346 # 800086a0 <syscalls+0x258>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	ff4080e7          	jalr	-12(ra) # 80000542 <panic>

0000000080004556 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004556:	7139                	addi	sp,sp,-64
    80004558:	fc06                	sd	ra,56(sp)
    8000455a:	f822                	sd	s0,48(sp)
    8000455c:	f426                	sd	s1,40(sp)
    8000455e:	f04a                	sd	s2,32(sp)
    80004560:	ec4e                	sd	s3,24(sp)
    80004562:	e852                	sd	s4,16(sp)
    80004564:	e456                	sd	s5,8(sp)
    80004566:	0080                	addi	s0,sp,64
    80004568:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000456a:	0001d517          	auipc	a0,0x1d
    8000456e:	4e650513          	addi	a0,a0,1254 # 80021a50 <ftable>
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	68c080e7          	jalr	1676(ra) # 80000bfe <acquire>
  if(f->ref < 1)
    8000457a:	40dc                	lw	a5,4(s1)
    8000457c:	06f05163          	blez	a5,800045de <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004580:	37fd                	addiw	a5,a5,-1
    80004582:	0007871b          	sext.w	a4,a5
    80004586:	c0dc                	sw	a5,4(s1)
    80004588:	06e04363          	bgtz	a4,800045ee <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000458c:	0004a903          	lw	s2,0(s1)
    80004590:	0094ca83          	lbu	s5,9(s1)
    80004594:	0104ba03          	ld	s4,16(s1)
    80004598:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000459c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045a0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045a4:	0001d517          	auipc	a0,0x1d
    800045a8:	4ac50513          	addi	a0,a0,1196 # 80021a50 <ftable>
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	706080e7          	jalr	1798(ra) # 80000cb2 <release>

  if(ff.type == FD_PIPE){
    800045b4:	4785                	li	a5,1
    800045b6:	04f90d63          	beq	s2,a5,80004610 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045ba:	3979                	addiw	s2,s2,-2
    800045bc:	4785                	li	a5,1
    800045be:	0527e063          	bltu	a5,s2,800045fe <fileclose+0xa8>
    begin_op();
    800045c2:	00000097          	auipc	ra,0x0
    800045c6:	ac2080e7          	jalr	-1342(ra) # 80004084 <begin_op>
    iput(ff.ip);
    800045ca:	854e                	mv	a0,s3
    800045cc:	fffff097          	auipc	ra,0xfffff
    800045d0:	2b2080e7          	jalr	690(ra) # 8000387e <iput>
    end_op();
    800045d4:	00000097          	auipc	ra,0x0
    800045d8:	b30080e7          	jalr	-1232(ra) # 80004104 <end_op>
    800045dc:	a00d                	j	800045fe <fileclose+0xa8>
    panic("fileclose");
    800045de:	00004517          	auipc	a0,0x4
    800045e2:	0ca50513          	addi	a0,a0,202 # 800086a8 <syscalls+0x260>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	f5c080e7          	jalr	-164(ra) # 80000542 <panic>
    release(&ftable.lock);
    800045ee:	0001d517          	auipc	a0,0x1d
    800045f2:	46250513          	addi	a0,a0,1122 # 80021a50 <ftable>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	6bc080e7          	jalr	1724(ra) # 80000cb2 <release>
  }
}
    800045fe:	70e2                	ld	ra,56(sp)
    80004600:	7442                	ld	s0,48(sp)
    80004602:	74a2                	ld	s1,40(sp)
    80004604:	7902                	ld	s2,32(sp)
    80004606:	69e2                	ld	s3,24(sp)
    80004608:	6a42                	ld	s4,16(sp)
    8000460a:	6aa2                	ld	s5,8(sp)
    8000460c:	6121                	addi	sp,sp,64
    8000460e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004610:	85d6                	mv	a1,s5
    80004612:	8552                	mv	a0,s4
    80004614:	00000097          	auipc	ra,0x0
    80004618:	372080e7          	jalr	882(ra) # 80004986 <pipeclose>
    8000461c:	b7cd                	j	800045fe <fileclose+0xa8>

000000008000461e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000461e:	715d                	addi	sp,sp,-80
    80004620:	e486                	sd	ra,72(sp)
    80004622:	e0a2                	sd	s0,64(sp)
    80004624:	fc26                	sd	s1,56(sp)
    80004626:	f84a                	sd	s2,48(sp)
    80004628:	f44e                	sd	s3,40(sp)
    8000462a:	0880                	addi	s0,sp,80
    8000462c:	84aa                	mv	s1,a0
    8000462e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004630:	ffffd097          	auipc	ra,0xffffd
    80004634:	38a080e7          	jalr	906(ra) # 800019ba <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004638:	409c                	lw	a5,0(s1)
    8000463a:	37f9                	addiw	a5,a5,-2
    8000463c:	4705                	li	a4,1
    8000463e:	04f76763          	bltu	a4,a5,8000468c <filestat+0x6e>
    80004642:	892a                	mv	s2,a0
    ilock(f->ip);
    80004644:	6c88                	ld	a0,24(s1)
    80004646:	fffff097          	auipc	ra,0xfffff
    8000464a:	07e080e7          	jalr	126(ra) # 800036c4 <ilock>
    stati(f->ip, &st);
    8000464e:	fb840593          	addi	a1,s0,-72
    80004652:	6c88                	ld	a0,24(s1)
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	2fa080e7          	jalr	762(ra) # 8000394e <stati>
    iunlock(f->ip);
    8000465c:	6c88                	ld	a0,24(s1)
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	128080e7          	jalr	296(ra) # 80003786 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004666:	46e1                	li	a3,24
    80004668:	fb840613          	addi	a2,s0,-72
    8000466c:	85ce                	mv	a1,s3
    8000466e:	05093503          	ld	a0,80(s2)
    80004672:	ffffd097          	auipc	ra,0xffffd
    80004676:	03a080e7          	jalr	58(ra) # 800016ac <copyout>
    8000467a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000467e:	60a6                	ld	ra,72(sp)
    80004680:	6406                	ld	s0,64(sp)
    80004682:	74e2                	ld	s1,56(sp)
    80004684:	7942                	ld	s2,48(sp)
    80004686:	79a2                	ld	s3,40(sp)
    80004688:	6161                	addi	sp,sp,80
    8000468a:	8082                	ret
  return -1;
    8000468c:	557d                	li	a0,-1
    8000468e:	bfc5                	j	8000467e <filestat+0x60>

0000000080004690 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004690:	7179                	addi	sp,sp,-48
    80004692:	f406                	sd	ra,40(sp)
    80004694:	f022                	sd	s0,32(sp)
    80004696:	ec26                	sd	s1,24(sp)
    80004698:	e84a                	sd	s2,16(sp)
    8000469a:	e44e                	sd	s3,8(sp)
    8000469c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000469e:	00854783          	lbu	a5,8(a0)
    800046a2:	c3d5                	beqz	a5,80004746 <fileread+0xb6>
    800046a4:	84aa                	mv	s1,a0
    800046a6:	89ae                	mv	s3,a1
    800046a8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046aa:	411c                	lw	a5,0(a0)
    800046ac:	4705                	li	a4,1
    800046ae:	04e78963          	beq	a5,a4,80004700 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046b2:	470d                	li	a4,3
    800046b4:	04e78d63          	beq	a5,a4,8000470e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046b8:	4709                	li	a4,2
    800046ba:	06e79e63          	bne	a5,a4,80004736 <fileread+0xa6>
    ilock(f->ip);
    800046be:	6d08                	ld	a0,24(a0)
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	004080e7          	jalr	4(ra) # 800036c4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800046c8:	874a                	mv	a4,s2
    800046ca:	5094                	lw	a3,32(s1)
    800046cc:	864e                	mv	a2,s3
    800046ce:	4585                	li	a1,1
    800046d0:	6c88                	ld	a0,24(s1)
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	2a6080e7          	jalr	678(ra) # 80003978 <readi>
    800046da:	892a                	mv	s2,a0
    800046dc:	00a05563          	blez	a0,800046e6 <fileread+0x56>
      f->off += r;
    800046e0:	509c                	lw	a5,32(s1)
    800046e2:	9fa9                	addw	a5,a5,a0
    800046e4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800046e6:	6c88                	ld	a0,24(s1)
    800046e8:	fffff097          	auipc	ra,0xfffff
    800046ec:	09e080e7          	jalr	158(ra) # 80003786 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800046f0:	854a                	mv	a0,s2
    800046f2:	70a2                	ld	ra,40(sp)
    800046f4:	7402                	ld	s0,32(sp)
    800046f6:	64e2                	ld	s1,24(sp)
    800046f8:	6942                	ld	s2,16(sp)
    800046fa:	69a2                	ld	s3,8(sp)
    800046fc:	6145                	addi	sp,sp,48
    800046fe:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004700:	6908                	ld	a0,16(a0)
    80004702:	00000097          	auipc	ra,0x0
    80004706:	3f4080e7          	jalr	1012(ra) # 80004af6 <piperead>
    8000470a:	892a                	mv	s2,a0
    8000470c:	b7d5                	j	800046f0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000470e:	02451783          	lh	a5,36(a0)
    80004712:	03079693          	slli	a3,a5,0x30
    80004716:	92c1                	srli	a3,a3,0x30
    80004718:	4725                	li	a4,9
    8000471a:	02d76863          	bltu	a4,a3,8000474a <fileread+0xba>
    8000471e:	0792                	slli	a5,a5,0x4
    80004720:	0001d717          	auipc	a4,0x1d
    80004724:	29070713          	addi	a4,a4,656 # 800219b0 <devsw>
    80004728:	97ba                	add	a5,a5,a4
    8000472a:	639c                	ld	a5,0(a5)
    8000472c:	c38d                	beqz	a5,8000474e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000472e:	4505                	li	a0,1
    80004730:	9782                	jalr	a5
    80004732:	892a                	mv	s2,a0
    80004734:	bf75                	j	800046f0 <fileread+0x60>
    panic("fileread");
    80004736:	00004517          	auipc	a0,0x4
    8000473a:	f8250513          	addi	a0,a0,-126 # 800086b8 <syscalls+0x270>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	e04080e7          	jalr	-508(ra) # 80000542 <panic>
    return -1;
    80004746:	597d                	li	s2,-1
    80004748:	b765                	j	800046f0 <fileread+0x60>
      return -1;
    8000474a:	597d                	li	s2,-1
    8000474c:	b755                	j	800046f0 <fileread+0x60>
    8000474e:	597d                	li	s2,-1
    80004750:	b745                	j	800046f0 <fileread+0x60>

0000000080004752 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004752:	00954783          	lbu	a5,9(a0)
    80004756:	14078563          	beqz	a5,800048a0 <filewrite+0x14e>
{
    8000475a:	715d                	addi	sp,sp,-80
    8000475c:	e486                	sd	ra,72(sp)
    8000475e:	e0a2                	sd	s0,64(sp)
    80004760:	fc26                	sd	s1,56(sp)
    80004762:	f84a                	sd	s2,48(sp)
    80004764:	f44e                	sd	s3,40(sp)
    80004766:	f052                	sd	s4,32(sp)
    80004768:	ec56                	sd	s5,24(sp)
    8000476a:	e85a                	sd	s6,16(sp)
    8000476c:	e45e                	sd	s7,8(sp)
    8000476e:	e062                	sd	s8,0(sp)
    80004770:	0880                	addi	s0,sp,80
    80004772:	892a                	mv	s2,a0
    80004774:	8aae                	mv	s5,a1
    80004776:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004778:	411c                	lw	a5,0(a0)
    8000477a:	4705                	li	a4,1
    8000477c:	02e78263          	beq	a5,a4,800047a0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004780:	470d                	li	a4,3
    80004782:	02e78563          	beq	a5,a4,800047ac <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004786:	4709                	li	a4,2
    80004788:	10e79463          	bne	a5,a4,80004890 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000478c:	0ec05e63          	blez	a2,80004888 <filewrite+0x136>
    int i = 0;
    80004790:	4981                	li	s3,0
    80004792:	6b05                	lui	s6,0x1
    80004794:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004798:	6b85                	lui	s7,0x1
    8000479a:	c00b8b9b          	addiw	s7,s7,-1024
    8000479e:	a851                	j	80004832 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047a0:	6908                	ld	a0,16(a0)
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	254080e7          	jalr	596(ra) # 800049f6 <pipewrite>
    800047aa:	a85d                	j	80004860 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047ac:	02451783          	lh	a5,36(a0)
    800047b0:	03079693          	slli	a3,a5,0x30
    800047b4:	92c1                	srli	a3,a3,0x30
    800047b6:	4725                	li	a4,9
    800047b8:	0ed76663          	bltu	a4,a3,800048a4 <filewrite+0x152>
    800047bc:	0792                	slli	a5,a5,0x4
    800047be:	0001d717          	auipc	a4,0x1d
    800047c2:	1f270713          	addi	a4,a4,498 # 800219b0 <devsw>
    800047c6:	97ba                	add	a5,a5,a4
    800047c8:	679c                	ld	a5,8(a5)
    800047ca:	cff9                	beqz	a5,800048a8 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800047cc:	4505                	li	a0,1
    800047ce:	9782                	jalr	a5
    800047d0:	a841                	j	80004860 <filewrite+0x10e>
    800047d2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800047d6:	00000097          	auipc	ra,0x0
    800047da:	8ae080e7          	jalr	-1874(ra) # 80004084 <begin_op>
      ilock(f->ip);
    800047de:	01893503          	ld	a0,24(s2)
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	ee2080e7          	jalr	-286(ra) # 800036c4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800047ea:	8762                	mv	a4,s8
    800047ec:	02092683          	lw	a3,32(s2)
    800047f0:	01598633          	add	a2,s3,s5
    800047f4:	4585                	li	a1,1
    800047f6:	01893503          	ld	a0,24(s2)
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	274080e7          	jalr	628(ra) # 80003a6e <writei>
    80004802:	84aa                	mv	s1,a0
    80004804:	02a05f63          	blez	a0,80004842 <filewrite+0xf0>
        f->off += r;
    80004808:	02092783          	lw	a5,32(s2)
    8000480c:	9fa9                	addw	a5,a5,a0
    8000480e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004812:	01893503          	ld	a0,24(s2)
    80004816:	fffff097          	auipc	ra,0xfffff
    8000481a:	f70080e7          	jalr	-144(ra) # 80003786 <iunlock>
      end_op();
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	8e6080e7          	jalr	-1818(ra) # 80004104 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004826:	049c1963          	bne	s8,s1,80004878 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000482a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000482e:	0349d663          	bge	s3,s4,8000485a <filewrite+0x108>
      int n1 = n - i;
    80004832:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004836:	84be                	mv	s1,a5
    80004838:	2781                	sext.w	a5,a5
    8000483a:	f8fb5ce3          	bge	s6,a5,800047d2 <filewrite+0x80>
    8000483e:	84de                	mv	s1,s7
    80004840:	bf49                	j	800047d2 <filewrite+0x80>
      iunlock(f->ip);
    80004842:	01893503          	ld	a0,24(s2)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	f40080e7          	jalr	-192(ra) # 80003786 <iunlock>
      end_op();
    8000484e:	00000097          	auipc	ra,0x0
    80004852:	8b6080e7          	jalr	-1866(ra) # 80004104 <end_op>
      if(r < 0)
    80004856:	fc04d8e3          	bgez	s1,80004826 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000485a:	8552                	mv	a0,s4
    8000485c:	033a1863          	bne	s4,s3,8000488c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004860:	60a6                	ld	ra,72(sp)
    80004862:	6406                	ld	s0,64(sp)
    80004864:	74e2                	ld	s1,56(sp)
    80004866:	7942                	ld	s2,48(sp)
    80004868:	79a2                	ld	s3,40(sp)
    8000486a:	7a02                	ld	s4,32(sp)
    8000486c:	6ae2                	ld	s5,24(sp)
    8000486e:	6b42                	ld	s6,16(sp)
    80004870:	6ba2                	ld	s7,8(sp)
    80004872:	6c02                	ld	s8,0(sp)
    80004874:	6161                	addi	sp,sp,80
    80004876:	8082                	ret
        panic("short filewrite");
    80004878:	00004517          	auipc	a0,0x4
    8000487c:	e5050513          	addi	a0,a0,-432 # 800086c8 <syscalls+0x280>
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	cc2080e7          	jalr	-830(ra) # 80000542 <panic>
    int i = 0;
    80004888:	4981                	li	s3,0
    8000488a:	bfc1                	j	8000485a <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000488c:	557d                	li	a0,-1
    8000488e:	bfc9                	j	80004860 <filewrite+0x10e>
    panic("filewrite");
    80004890:	00004517          	auipc	a0,0x4
    80004894:	e4850513          	addi	a0,a0,-440 # 800086d8 <syscalls+0x290>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	caa080e7          	jalr	-854(ra) # 80000542 <panic>
    return -1;
    800048a0:	557d                	li	a0,-1
}
    800048a2:	8082                	ret
      return -1;
    800048a4:	557d                	li	a0,-1
    800048a6:	bf6d                	j	80004860 <filewrite+0x10e>
    800048a8:	557d                	li	a0,-1
    800048aa:	bf5d                	j	80004860 <filewrite+0x10e>

00000000800048ac <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048ac:	7179                	addi	sp,sp,-48
    800048ae:	f406                	sd	ra,40(sp)
    800048b0:	f022                	sd	s0,32(sp)
    800048b2:	ec26                	sd	s1,24(sp)
    800048b4:	e84a                	sd	s2,16(sp)
    800048b6:	e44e                	sd	s3,8(sp)
    800048b8:	e052                	sd	s4,0(sp)
    800048ba:	1800                	addi	s0,sp,48
    800048bc:	84aa                	mv	s1,a0
    800048be:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048c0:	0005b023          	sd	zero,0(a1)
    800048c4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048c8:	00000097          	auipc	ra,0x0
    800048cc:	bd2080e7          	jalr	-1070(ra) # 8000449a <filealloc>
    800048d0:	e088                	sd	a0,0(s1)
    800048d2:	c551                	beqz	a0,8000495e <pipealloc+0xb2>
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	bc6080e7          	jalr	-1082(ra) # 8000449a <filealloc>
    800048dc:	00aa3023          	sd	a0,0(s4)
    800048e0:	c92d                	beqz	a0,80004952 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	22c080e7          	jalr	556(ra) # 80000b0e <kalloc>
    800048ea:	892a                	mv	s2,a0
    800048ec:	c125                	beqz	a0,8000494c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800048ee:	4985                	li	s3,1
    800048f0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800048f4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800048f8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800048fc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004900:	00004597          	auipc	a1,0x4
    80004904:	de858593          	addi	a1,a1,-536 # 800086e8 <syscalls+0x2a0>
    80004908:	ffffc097          	auipc	ra,0xffffc
    8000490c:	266080e7          	jalr	614(ra) # 80000b6e <initlock>
  (*f0)->type = FD_PIPE;
    80004910:	609c                	ld	a5,0(s1)
    80004912:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004916:	609c                	ld	a5,0(s1)
    80004918:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000491c:	609c                	ld	a5,0(s1)
    8000491e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004922:	609c                	ld	a5,0(s1)
    80004924:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004928:	000a3783          	ld	a5,0(s4)
    8000492c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004930:	000a3783          	ld	a5,0(s4)
    80004934:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004938:	000a3783          	ld	a5,0(s4)
    8000493c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004940:	000a3783          	ld	a5,0(s4)
    80004944:	0127b823          	sd	s2,16(a5)
  return 0;
    80004948:	4501                	li	a0,0
    8000494a:	a025                	j	80004972 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000494c:	6088                	ld	a0,0(s1)
    8000494e:	e501                	bnez	a0,80004956 <pipealloc+0xaa>
    80004950:	a039                	j	8000495e <pipealloc+0xb2>
    80004952:	6088                	ld	a0,0(s1)
    80004954:	c51d                	beqz	a0,80004982 <pipealloc+0xd6>
    fileclose(*f0);
    80004956:	00000097          	auipc	ra,0x0
    8000495a:	c00080e7          	jalr	-1024(ra) # 80004556 <fileclose>
  if(*f1)
    8000495e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004962:	557d                	li	a0,-1
  if(*f1)
    80004964:	c799                	beqz	a5,80004972 <pipealloc+0xc6>
    fileclose(*f1);
    80004966:	853e                	mv	a0,a5
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	bee080e7          	jalr	-1042(ra) # 80004556 <fileclose>
  return -1;
    80004970:	557d                	li	a0,-1
}
    80004972:	70a2                	ld	ra,40(sp)
    80004974:	7402                	ld	s0,32(sp)
    80004976:	64e2                	ld	s1,24(sp)
    80004978:	6942                	ld	s2,16(sp)
    8000497a:	69a2                	ld	s3,8(sp)
    8000497c:	6a02                	ld	s4,0(sp)
    8000497e:	6145                	addi	sp,sp,48
    80004980:	8082                	ret
  return -1;
    80004982:	557d                	li	a0,-1
    80004984:	b7fd                	j	80004972 <pipealloc+0xc6>

0000000080004986 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004986:	1101                	addi	sp,sp,-32
    80004988:	ec06                	sd	ra,24(sp)
    8000498a:	e822                	sd	s0,16(sp)
    8000498c:	e426                	sd	s1,8(sp)
    8000498e:	e04a                	sd	s2,0(sp)
    80004990:	1000                	addi	s0,sp,32
    80004992:	84aa                	mv	s1,a0
    80004994:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	268080e7          	jalr	616(ra) # 80000bfe <acquire>
  if(writable){
    8000499e:	02090d63          	beqz	s2,800049d8 <pipeclose+0x52>
    pi->writeopen = 0;
    800049a2:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049a6:	21848513          	addi	a0,s1,536
    800049aa:	ffffe097          	auipc	ra,0xffffe
    800049ae:	980080e7          	jalr	-1664(ra) # 8000232a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049b2:	2204b783          	ld	a5,544(s1)
    800049b6:	eb95                	bnez	a5,800049ea <pipeclose+0x64>
    release(&pi->lock);
    800049b8:	8526                	mv	a0,s1
    800049ba:	ffffc097          	auipc	ra,0xffffc
    800049be:	2f8080e7          	jalr	760(ra) # 80000cb2 <release>
    kfree((char*)pi);
    800049c2:	8526                	mv	a0,s1
    800049c4:	ffffc097          	auipc	ra,0xffffc
    800049c8:	04e080e7          	jalr	78(ra) # 80000a12 <kfree>
  } else
    release(&pi->lock);
}
    800049cc:	60e2                	ld	ra,24(sp)
    800049ce:	6442                	ld	s0,16(sp)
    800049d0:	64a2                	ld	s1,8(sp)
    800049d2:	6902                	ld	s2,0(sp)
    800049d4:	6105                	addi	sp,sp,32
    800049d6:	8082                	ret
    pi->readopen = 0;
    800049d8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049dc:	21c48513          	addi	a0,s1,540
    800049e0:	ffffe097          	auipc	ra,0xffffe
    800049e4:	94a080e7          	jalr	-1718(ra) # 8000232a <wakeup>
    800049e8:	b7e9                	j	800049b2 <pipeclose+0x2c>
    release(&pi->lock);
    800049ea:	8526                	mv	a0,s1
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	2c6080e7          	jalr	710(ra) # 80000cb2 <release>
}
    800049f4:	bfe1                	j	800049cc <pipeclose+0x46>

00000000800049f6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800049f6:	711d                	addi	sp,sp,-96
    800049f8:	ec86                	sd	ra,88(sp)
    800049fa:	e8a2                	sd	s0,80(sp)
    800049fc:	e4a6                	sd	s1,72(sp)
    800049fe:	e0ca                	sd	s2,64(sp)
    80004a00:	fc4e                	sd	s3,56(sp)
    80004a02:	f852                	sd	s4,48(sp)
    80004a04:	f456                	sd	s5,40(sp)
    80004a06:	f05a                	sd	s6,32(sp)
    80004a08:	ec5e                	sd	s7,24(sp)
    80004a0a:	e862                	sd	s8,16(sp)
    80004a0c:	1080                	addi	s0,sp,96
    80004a0e:	84aa                	mv	s1,a0
    80004a10:	8b2e                	mv	s6,a1
    80004a12:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a14:	ffffd097          	auipc	ra,0xffffd
    80004a18:	fa6080e7          	jalr	-90(ra) # 800019ba <myproc>
    80004a1c:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a1e:	8526                	mv	a0,s1
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	1de080e7          	jalr	478(ra) # 80000bfe <acquire>
  for(i = 0; i < n; i++){
    80004a28:	09505763          	blez	s5,80004ab6 <pipewrite+0xc0>
    80004a2c:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004a2e:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a32:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a36:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a38:	2184a783          	lw	a5,536(s1)
    80004a3c:	21c4a703          	lw	a4,540(s1)
    80004a40:	2007879b          	addiw	a5,a5,512
    80004a44:	02f71b63          	bne	a4,a5,80004a7a <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004a48:	2204a783          	lw	a5,544(s1)
    80004a4c:	c3d1                	beqz	a5,80004ad0 <pipewrite+0xda>
    80004a4e:	03092783          	lw	a5,48(s2)
    80004a52:	efbd                	bnez	a5,80004ad0 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004a54:	8552                	mv	a0,s4
    80004a56:	ffffe097          	auipc	ra,0xffffe
    80004a5a:	8d4080e7          	jalr	-1836(ra) # 8000232a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a5e:	85a6                	mv	a1,s1
    80004a60:	854e                	mv	a0,s3
    80004a62:	ffffd097          	auipc	ra,0xffffd
    80004a66:	748080e7          	jalr	1864(ra) # 800021aa <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004a6a:	2184a783          	lw	a5,536(s1)
    80004a6e:	21c4a703          	lw	a4,540(s1)
    80004a72:	2007879b          	addiw	a5,a5,512
    80004a76:	fcf709e3          	beq	a4,a5,80004a48 <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a7a:	4685                	li	a3,1
    80004a7c:	865a                	mv	a2,s6
    80004a7e:	faf40593          	addi	a1,s0,-81
    80004a82:	05093503          	ld	a0,80(s2)
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	cb2080e7          	jalr	-846(ra) # 80001738 <copyin>
    80004a8e:	03850563          	beq	a0,s8,80004ab8 <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004a92:	21c4a783          	lw	a5,540(s1)
    80004a96:	0017871b          	addiw	a4,a5,1
    80004a9a:	20e4ae23          	sw	a4,540(s1)
    80004a9e:	1ff7f793          	andi	a5,a5,511
    80004aa2:	97a6                	add	a5,a5,s1
    80004aa4:	faf44703          	lbu	a4,-81(s0)
    80004aa8:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004aac:	2b85                	addiw	s7,s7,1
    80004aae:	0b05                	addi	s6,s6,1
    80004ab0:	f97a94e3          	bne	s5,s7,80004a38 <pipewrite+0x42>
    80004ab4:	a011                	j	80004ab8 <pipewrite+0xc2>
    80004ab6:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004ab8:	21848513          	addi	a0,s1,536
    80004abc:	ffffe097          	auipc	ra,0xffffe
    80004ac0:	86e080e7          	jalr	-1938(ra) # 8000232a <wakeup>
  release(&pi->lock);
    80004ac4:	8526                	mv	a0,s1
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	1ec080e7          	jalr	492(ra) # 80000cb2 <release>
  return i;
    80004ace:	a039                	j	80004adc <pipewrite+0xe6>
        release(&pi->lock);
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	1e0080e7          	jalr	480(ra) # 80000cb2 <release>
        return -1;
    80004ada:	5bfd                	li	s7,-1
}
    80004adc:	855e                	mv	a0,s7
    80004ade:	60e6                	ld	ra,88(sp)
    80004ae0:	6446                	ld	s0,80(sp)
    80004ae2:	64a6                	ld	s1,72(sp)
    80004ae4:	6906                	ld	s2,64(sp)
    80004ae6:	79e2                	ld	s3,56(sp)
    80004ae8:	7a42                	ld	s4,48(sp)
    80004aea:	7aa2                	ld	s5,40(sp)
    80004aec:	7b02                	ld	s6,32(sp)
    80004aee:	6be2                	ld	s7,24(sp)
    80004af0:	6c42                	ld	s8,16(sp)
    80004af2:	6125                	addi	sp,sp,96
    80004af4:	8082                	ret

0000000080004af6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004af6:	715d                	addi	sp,sp,-80
    80004af8:	e486                	sd	ra,72(sp)
    80004afa:	e0a2                	sd	s0,64(sp)
    80004afc:	fc26                	sd	s1,56(sp)
    80004afe:	f84a                	sd	s2,48(sp)
    80004b00:	f44e                	sd	s3,40(sp)
    80004b02:	f052                	sd	s4,32(sp)
    80004b04:	ec56                	sd	s5,24(sp)
    80004b06:	e85a                	sd	s6,16(sp)
    80004b08:	0880                	addi	s0,sp,80
    80004b0a:	84aa                	mv	s1,a0
    80004b0c:	892e                	mv	s2,a1
    80004b0e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b10:	ffffd097          	auipc	ra,0xffffd
    80004b14:	eaa080e7          	jalr	-342(ra) # 800019ba <myproc>
    80004b18:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	0e2080e7          	jalr	226(ra) # 80000bfe <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b24:	2184a703          	lw	a4,536(s1)
    80004b28:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b2c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b30:	02f71463          	bne	a4,a5,80004b58 <piperead+0x62>
    80004b34:	2244a783          	lw	a5,548(s1)
    80004b38:	c385                	beqz	a5,80004b58 <piperead+0x62>
    if(pr->killed){
    80004b3a:	030a2783          	lw	a5,48(s4)
    80004b3e:	ebc1                	bnez	a5,80004bce <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b40:	85a6                	mv	a1,s1
    80004b42:	854e                	mv	a0,s3
    80004b44:	ffffd097          	auipc	ra,0xffffd
    80004b48:	666080e7          	jalr	1638(ra) # 800021aa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b4c:	2184a703          	lw	a4,536(s1)
    80004b50:	21c4a783          	lw	a5,540(s1)
    80004b54:	fef700e3          	beq	a4,a5,80004b34 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b58:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b5a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b5c:	05505363          	blez	s5,80004ba2 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004b60:	2184a783          	lw	a5,536(s1)
    80004b64:	21c4a703          	lw	a4,540(s1)
    80004b68:	02f70d63          	beq	a4,a5,80004ba2 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b6c:	0017871b          	addiw	a4,a5,1
    80004b70:	20e4ac23          	sw	a4,536(s1)
    80004b74:	1ff7f793          	andi	a5,a5,511
    80004b78:	97a6                	add	a5,a5,s1
    80004b7a:	0187c783          	lbu	a5,24(a5)
    80004b7e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b82:	4685                	li	a3,1
    80004b84:	fbf40613          	addi	a2,s0,-65
    80004b88:	85ca                	mv	a1,s2
    80004b8a:	050a3503          	ld	a0,80(s4)
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	b1e080e7          	jalr	-1250(ra) # 800016ac <copyout>
    80004b96:	01650663          	beq	a0,s6,80004ba2 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b9a:	2985                	addiw	s3,s3,1
    80004b9c:	0905                	addi	s2,s2,1
    80004b9e:	fd3a91e3          	bne	s5,s3,80004b60 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ba2:	21c48513          	addi	a0,s1,540
    80004ba6:	ffffd097          	auipc	ra,0xffffd
    80004baa:	784080e7          	jalr	1924(ra) # 8000232a <wakeup>
  release(&pi->lock);
    80004bae:	8526                	mv	a0,s1
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	102080e7          	jalr	258(ra) # 80000cb2 <release>
  return i;
}
    80004bb8:	854e                	mv	a0,s3
    80004bba:	60a6                	ld	ra,72(sp)
    80004bbc:	6406                	ld	s0,64(sp)
    80004bbe:	74e2                	ld	s1,56(sp)
    80004bc0:	7942                	ld	s2,48(sp)
    80004bc2:	79a2                	ld	s3,40(sp)
    80004bc4:	7a02                	ld	s4,32(sp)
    80004bc6:	6ae2                	ld	s5,24(sp)
    80004bc8:	6b42                	ld	s6,16(sp)
    80004bca:	6161                	addi	sp,sp,80
    80004bcc:	8082                	ret
      release(&pi->lock);
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	0e2080e7          	jalr	226(ra) # 80000cb2 <release>
      return -1;
    80004bd8:	59fd                	li	s3,-1
    80004bda:	bff9                	j	80004bb8 <piperead+0xc2>

0000000080004bdc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004bdc:	de010113          	addi	sp,sp,-544
    80004be0:	20113c23          	sd	ra,536(sp)
    80004be4:	20813823          	sd	s0,528(sp)
    80004be8:	20913423          	sd	s1,520(sp)
    80004bec:	21213023          	sd	s2,512(sp)
    80004bf0:	ffce                	sd	s3,504(sp)
    80004bf2:	fbd2                	sd	s4,496(sp)
    80004bf4:	f7d6                	sd	s5,488(sp)
    80004bf6:	f3da                	sd	s6,480(sp)
    80004bf8:	efde                	sd	s7,472(sp)
    80004bfa:	ebe2                	sd	s8,464(sp)
    80004bfc:	e7e6                	sd	s9,456(sp)
    80004bfe:	e3ea                	sd	s10,448(sp)
    80004c00:	ff6e                	sd	s11,440(sp)
    80004c02:	1400                	addi	s0,sp,544
    80004c04:	892a                	mv	s2,a0
    80004c06:	dea43423          	sd	a0,-536(s0)
    80004c0a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	dac080e7          	jalr	-596(ra) # 800019ba <myproc>
    80004c16:	84aa                	mv	s1,a0

  begin_op();
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	46c080e7          	jalr	1132(ra) # 80004084 <begin_op>

  if((ip = namei(path)) == 0){
    80004c20:	854a                	mv	a0,s2
    80004c22:	fffff097          	auipc	ra,0xfffff
    80004c26:	252080e7          	jalr	594(ra) # 80003e74 <namei>
    80004c2a:	c93d                	beqz	a0,80004ca0 <exec+0xc4>
    80004c2c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c2e:	fffff097          	auipc	ra,0xfffff
    80004c32:	a96080e7          	jalr	-1386(ra) # 800036c4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c36:	04000713          	li	a4,64
    80004c3a:	4681                	li	a3,0
    80004c3c:	e4840613          	addi	a2,s0,-440
    80004c40:	4581                	li	a1,0
    80004c42:	8556                	mv	a0,s5
    80004c44:	fffff097          	auipc	ra,0xfffff
    80004c48:	d34080e7          	jalr	-716(ra) # 80003978 <readi>
    80004c4c:	04000793          	li	a5,64
    80004c50:	00f51a63          	bne	a0,a5,80004c64 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004c54:	e4842703          	lw	a4,-440(s0)
    80004c58:	464c47b7          	lui	a5,0x464c4
    80004c5c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c60:	04f70663          	beq	a4,a5,80004cac <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c64:	8556                	mv	a0,s5
    80004c66:	fffff097          	auipc	ra,0xfffff
    80004c6a:	cc0080e7          	jalr	-832(ra) # 80003926 <iunlockput>
    end_op();
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	496080e7          	jalr	1174(ra) # 80004104 <end_op>
  }
  return -1;
    80004c76:	557d                	li	a0,-1
}
    80004c78:	21813083          	ld	ra,536(sp)
    80004c7c:	21013403          	ld	s0,528(sp)
    80004c80:	20813483          	ld	s1,520(sp)
    80004c84:	20013903          	ld	s2,512(sp)
    80004c88:	79fe                	ld	s3,504(sp)
    80004c8a:	7a5e                	ld	s4,496(sp)
    80004c8c:	7abe                	ld	s5,488(sp)
    80004c8e:	7b1e                	ld	s6,480(sp)
    80004c90:	6bfe                	ld	s7,472(sp)
    80004c92:	6c5e                	ld	s8,464(sp)
    80004c94:	6cbe                	ld	s9,456(sp)
    80004c96:	6d1e                	ld	s10,448(sp)
    80004c98:	7dfa                	ld	s11,440(sp)
    80004c9a:	22010113          	addi	sp,sp,544
    80004c9e:	8082                	ret
    end_op();
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	464080e7          	jalr	1124(ra) # 80004104 <end_op>
    return -1;
    80004ca8:	557d                	li	a0,-1
    80004caa:	b7f9                	j	80004c78 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	dd0080e7          	jalr	-560(ra) # 80001a7e <proc_pagetable>
    80004cb6:	8b2a                	mv	s6,a0
    80004cb8:	d555                	beqz	a0,80004c64 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cba:	e6842783          	lw	a5,-408(s0)
    80004cbe:	e8045703          	lhu	a4,-384(s0)
    80004cc2:	c735                	beqz	a4,80004d2e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004cc4:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cc6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004cca:	6a05                	lui	s4,0x1
    80004ccc:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004cd0:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004cd4:	6d85                	lui	s11,0x1
    80004cd6:	7d7d                	lui	s10,0xfffff
    80004cd8:	ac1d                	j	80004f0e <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004cda:	00004517          	auipc	a0,0x4
    80004cde:	a1650513          	addi	a0,a0,-1514 # 800086f0 <syscalls+0x2a8>
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	860080e7          	jalr	-1952(ra) # 80000542 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004cea:	874a                	mv	a4,s2
    80004cec:	009c86bb          	addw	a3,s9,s1
    80004cf0:	4581                	li	a1,0
    80004cf2:	8556                	mv	a0,s5
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	c84080e7          	jalr	-892(ra) # 80003978 <readi>
    80004cfc:	2501                	sext.w	a0,a0
    80004cfe:	1aa91863          	bne	s2,a0,80004eae <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004d02:	009d84bb          	addw	s1,s11,s1
    80004d06:	013d09bb          	addw	s3,s10,s3
    80004d0a:	1f74f263          	bgeu	s1,s7,80004eee <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004d0e:	02049593          	slli	a1,s1,0x20
    80004d12:	9181                	srli	a1,a1,0x20
    80004d14:	95e2                	add	a1,a1,s8
    80004d16:	855a                	mv	a0,s6
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	360080e7          	jalr	864(ra) # 80001078 <walkaddr>
    80004d20:	862a                	mv	a2,a0
    if(pa == 0)
    80004d22:	dd45                	beqz	a0,80004cda <exec+0xfe>
      n = PGSIZE;
    80004d24:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004d26:	fd49f2e3          	bgeu	s3,s4,80004cea <exec+0x10e>
      n = sz - i;
    80004d2a:	894e                	mv	s2,s3
    80004d2c:	bf7d                	j	80004cea <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d2e:	4481                	li	s1,0
  iunlockput(ip);
    80004d30:	8556                	mv	a0,s5
    80004d32:	fffff097          	auipc	ra,0xfffff
    80004d36:	bf4080e7          	jalr	-1036(ra) # 80003926 <iunlockput>
  end_op();
    80004d3a:	fffff097          	auipc	ra,0xfffff
    80004d3e:	3ca080e7          	jalr	970(ra) # 80004104 <end_op>
  p = myproc();
    80004d42:	ffffd097          	auipc	ra,0xffffd
    80004d46:	c78080e7          	jalr	-904(ra) # 800019ba <myproc>
    80004d4a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004d4c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004d50:	6785                	lui	a5,0x1
    80004d52:	17fd                	addi	a5,a5,-1
    80004d54:	94be                	add	s1,s1,a5
    80004d56:	77fd                	lui	a5,0xfffff
    80004d58:	8fe5                	and	a5,a5,s1
    80004d5a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d5e:	6609                	lui	a2,0x2
    80004d60:	963e                	add	a2,a2,a5
    80004d62:	85be                	mv	a1,a5
    80004d64:	855a                	mv	a0,s6
    80004d66:	ffffc097          	auipc	ra,0xffffc
    80004d6a:	6f6080e7          	jalr	1782(ra) # 8000145c <uvmalloc>
    80004d6e:	8c2a                	mv	s8,a0
  ip = 0;
    80004d70:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004d72:	12050e63          	beqz	a0,80004eae <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004d76:	75f9                	lui	a1,0xffffe
    80004d78:	95aa                	add	a1,a1,a0
    80004d7a:	855a                	mv	a0,s6
    80004d7c:	ffffd097          	auipc	ra,0xffffd
    80004d80:	8fe080e7          	jalr	-1794(ra) # 8000167a <uvmclear>
  stackbase = sp - PGSIZE;
    80004d84:	7afd                	lui	s5,0xfffff
    80004d86:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d88:	df043783          	ld	a5,-528(s0)
    80004d8c:	6388                	ld	a0,0(a5)
    80004d8e:	c925                	beqz	a0,80004dfe <exec+0x222>
    80004d90:	e8840993          	addi	s3,s0,-376
    80004d94:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004d98:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004d9a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004d9c:	ffffc097          	auipc	ra,0xffffc
    80004da0:	0e2080e7          	jalr	226(ra) # 80000e7e <strlen>
    80004da4:	0015079b          	addiw	a5,a0,1
    80004da8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004dac:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004db0:	13596363          	bltu	s2,s5,80004ed6 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004db4:	df043d83          	ld	s11,-528(s0)
    80004db8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004dbc:	8552                	mv	a0,s4
    80004dbe:	ffffc097          	auipc	ra,0xffffc
    80004dc2:	0c0080e7          	jalr	192(ra) # 80000e7e <strlen>
    80004dc6:	0015069b          	addiw	a3,a0,1
    80004dca:	8652                	mv	a2,s4
    80004dcc:	85ca                	mv	a1,s2
    80004dce:	855a                	mv	a0,s6
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	8dc080e7          	jalr	-1828(ra) # 800016ac <copyout>
    80004dd8:	10054363          	bltz	a0,80004ede <exec+0x302>
    ustack[argc] = sp;
    80004ddc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004de0:	0485                	addi	s1,s1,1
    80004de2:	008d8793          	addi	a5,s11,8
    80004de6:	def43823          	sd	a5,-528(s0)
    80004dea:	008db503          	ld	a0,8(s11)
    80004dee:	c911                	beqz	a0,80004e02 <exec+0x226>
    if(argc >= MAXARG)
    80004df0:	09a1                	addi	s3,s3,8
    80004df2:	fb3c95e3          	bne	s9,s3,80004d9c <exec+0x1c0>
  sz = sz1;
    80004df6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004dfa:	4a81                	li	s5,0
    80004dfc:	a84d                	j	80004eae <exec+0x2d2>
  sp = sz;
    80004dfe:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e00:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e02:	00349793          	slli	a5,s1,0x3
    80004e06:	f9040713          	addi	a4,s0,-112
    80004e0a:	97ba                	add	a5,a5,a4
    80004e0c:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004e10:	00148693          	addi	a3,s1,1
    80004e14:	068e                	slli	a3,a3,0x3
    80004e16:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e1a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e1e:	01597663          	bgeu	s2,s5,80004e2a <exec+0x24e>
  sz = sz1;
    80004e22:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004e26:	4a81                	li	s5,0
    80004e28:	a059                	j	80004eae <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004e2a:	e8840613          	addi	a2,s0,-376
    80004e2e:	85ca                	mv	a1,s2
    80004e30:	855a                	mv	a0,s6
    80004e32:	ffffd097          	auipc	ra,0xffffd
    80004e36:	87a080e7          	jalr	-1926(ra) # 800016ac <copyout>
    80004e3a:	0a054663          	bltz	a0,80004ee6 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004e3e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004e42:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004e46:	de843783          	ld	a5,-536(s0)
    80004e4a:	0007c703          	lbu	a4,0(a5)
    80004e4e:	cf11                	beqz	a4,80004e6a <exec+0x28e>
    80004e50:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004e52:	02f00693          	li	a3,47
    80004e56:	a039                	j	80004e64 <exec+0x288>
      last = s+1;
    80004e58:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004e5c:	0785                	addi	a5,a5,1
    80004e5e:	fff7c703          	lbu	a4,-1(a5)
    80004e62:	c701                	beqz	a4,80004e6a <exec+0x28e>
    if(*s == '/')
    80004e64:	fed71ce3          	bne	a4,a3,80004e5c <exec+0x280>
    80004e68:	bfc5                	j	80004e58 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004e6a:	4641                	li	a2,16
    80004e6c:	de843583          	ld	a1,-536(s0)
    80004e70:	158b8513          	addi	a0,s7,344
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	fd8080e7          	jalr	-40(ra) # 80000e4c <safestrcpy>
  oldpagetable = p->pagetable;
    80004e7c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004e80:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004e84:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004e88:	058bb783          	ld	a5,88(s7)
    80004e8c:	e6043703          	ld	a4,-416(s0)
    80004e90:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004e92:	058bb783          	ld	a5,88(s7)
    80004e96:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004e9a:	85ea                	mv	a1,s10
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	c7e080e7          	jalr	-898(ra) # 80001b1a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ea4:	0004851b          	sext.w	a0,s1
    80004ea8:	bbc1                	j	80004c78 <exec+0x9c>
    80004eaa:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004eae:	df843583          	ld	a1,-520(s0)
    80004eb2:	855a                	mv	a0,s6
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	c66080e7          	jalr	-922(ra) # 80001b1a <proc_freepagetable>
  if(ip){
    80004ebc:	da0a94e3          	bnez	s5,80004c64 <exec+0x88>
  return -1;
    80004ec0:	557d                	li	a0,-1
    80004ec2:	bb5d                	j	80004c78 <exec+0x9c>
    80004ec4:	de943c23          	sd	s1,-520(s0)
    80004ec8:	b7dd                	j	80004eae <exec+0x2d2>
    80004eca:	de943c23          	sd	s1,-520(s0)
    80004ece:	b7c5                	j	80004eae <exec+0x2d2>
    80004ed0:	de943c23          	sd	s1,-520(s0)
    80004ed4:	bfe9                	j	80004eae <exec+0x2d2>
  sz = sz1;
    80004ed6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eda:	4a81                	li	s5,0
    80004edc:	bfc9                	j	80004eae <exec+0x2d2>
  sz = sz1;
    80004ede:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ee2:	4a81                	li	s5,0
    80004ee4:	b7e9                	j	80004eae <exec+0x2d2>
  sz = sz1;
    80004ee6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eea:	4a81                	li	s5,0
    80004eec:	b7c9                	j	80004eae <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004eee:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ef2:	e0843783          	ld	a5,-504(s0)
    80004ef6:	0017869b          	addiw	a3,a5,1
    80004efa:	e0d43423          	sd	a3,-504(s0)
    80004efe:	e0043783          	ld	a5,-512(s0)
    80004f02:	0387879b          	addiw	a5,a5,56
    80004f06:	e8045703          	lhu	a4,-384(s0)
    80004f0a:	e2e6d3e3          	bge	a3,a4,80004d30 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f0e:	2781                	sext.w	a5,a5
    80004f10:	e0f43023          	sd	a5,-512(s0)
    80004f14:	03800713          	li	a4,56
    80004f18:	86be                	mv	a3,a5
    80004f1a:	e1040613          	addi	a2,s0,-496
    80004f1e:	4581                	li	a1,0
    80004f20:	8556                	mv	a0,s5
    80004f22:	fffff097          	auipc	ra,0xfffff
    80004f26:	a56080e7          	jalr	-1450(ra) # 80003978 <readi>
    80004f2a:	03800793          	li	a5,56
    80004f2e:	f6f51ee3          	bne	a0,a5,80004eaa <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004f32:	e1042783          	lw	a5,-496(s0)
    80004f36:	4705                	li	a4,1
    80004f38:	fae79de3          	bne	a5,a4,80004ef2 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004f3c:	e3843603          	ld	a2,-456(s0)
    80004f40:	e3043783          	ld	a5,-464(s0)
    80004f44:	f8f660e3          	bltu	a2,a5,80004ec4 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004f48:	e2043783          	ld	a5,-480(s0)
    80004f4c:	963e                	add	a2,a2,a5
    80004f4e:	f6f66ee3          	bltu	a2,a5,80004eca <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f52:	85a6                	mv	a1,s1
    80004f54:	855a                	mv	a0,s6
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	506080e7          	jalr	1286(ra) # 8000145c <uvmalloc>
    80004f5e:	dea43c23          	sd	a0,-520(s0)
    80004f62:	d53d                	beqz	a0,80004ed0 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80004f64:	e2043c03          	ld	s8,-480(s0)
    80004f68:	de043783          	ld	a5,-544(s0)
    80004f6c:	00fc77b3          	and	a5,s8,a5
    80004f70:	ff9d                	bnez	a5,80004eae <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004f72:	e1842c83          	lw	s9,-488(s0)
    80004f76:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004f7a:	f60b8ae3          	beqz	s7,80004eee <exec+0x312>
    80004f7e:	89de                	mv	s3,s7
    80004f80:	4481                	li	s1,0
    80004f82:	b371                	j	80004d0e <exec+0x132>

0000000080004f84 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004f84:	7179                	addi	sp,sp,-48
    80004f86:	f406                	sd	ra,40(sp)
    80004f88:	f022                	sd	s0,32(sp)
    80004f8a:	ec26                	sd	s1,24(sp)
    80004f8c:	e84a                	sd	s2,16(sp)
    80004f8e:	1800                	addi	s0,sp,48
    80004f90:	892e                	mv	s2,a1
    80004f92:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004f94:	fdc40593          	addi	a1,s0,-36
    80004f98:	ffffe097          	auipc	ra,0xffffe
    80004f9c:	aba080e7          	jalr	-1350(ra) # 80002a52 <argint>
    80004fa0:	04054063          	bltz	a0,80004fe0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004fa4:	fdc42703          	lw	a4,-36(s0)
    80004fa8:	47bd                	li	a5,15
    80004faa:	02e7ed63          	bltu	a5,a4,80004fe4 <argfd+0x60>
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	a0c080e7          	jalr	-1524(ra) # 800019ba <myproc>
    80004fb6:	fdc42703          	lw	a4,-36(s0)
    80004fba:	01a70793          	addi	a5,a4,26
    80004fbe:	078e                	slli	a5,a5,0x3
    80004fc0:	953e                	add	a0,a0,a5
    80004fc2:	611c                	ld	a5,0(a0)
    80004fc4:	c395                	beqz	a5,80004fe8 <argfd+0x64>
    return -1;
  if(pfd)
    80004fc6:	00090463          	beqz	s2,80004fce <argfd+0x4a>
    *pfd = fd;
    80004fca:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004fce:	4501                	li	a0,0
  if(pf)
    80004fd0:	c091                	beqz	s1,80004fd4 <argfd+0x50>
    *pf = f;
    80004fd2:	e09c                	sd	a5,0(s1)
}
    80004fd4:	70a2                	ld	ra,40(sp)
    80004fd6:	7402                	ld	s0,32(sp)
    80004fd8:	64e2                	ld	s1,24(sp)
    80004fda:	6942                	ld	s2,16(sp)
    80004fdc:	6145                	addi	sp,sp,48
    80004fde:	8082                	ret
    return -1;
    80004fe0:	557d                	li	a0,-1
    80004fe2:	bfcd                	j	80004fd4 <argfd+0x50>
    return -1;
    80004fe4:	557d                	li	a0,-1
    80004fe6:	b7fd                	j	80004fd4 <argfd+0x50>
    80004fe8:	557d                	li	a0,-1
    80004fea:	b7ed                	j	80004fd4 <argfd+0x50>

0000000080004fec <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004fec:	1101                	addi	sp,sp,-32
    80004fee:	ec06                	sd	ra,24(sp)
    80004ff0:	e822                	sd	s0,16(sp)
    80004ff2:	e426                	sd	s1,8(sp)
    80004ff4:	1000                	addi	s0,sp,32
    80004ff6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004ff8:	ffffd097          	auipc	ra,0xffffd
    80004ffc:	9c2080e7          	jalr	-1598(ra) # 800019ba <myproc>
    80005000:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005002:	0d050793          	addi	a5,a0,208
    80005006:	4501                	li	a0,0
    80005008:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000500a:	6398                	ld	a4,0(a5)
    8000500c:	cb19                	beqz	a4,80005022 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000500e:	2505                	addiw	a0,a0,1
    80005010:	07a1                	addi	a5,a5,8
    80005012:	fed51ce3          	bne	a0,a3,8000500a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005016:	557d                	li	a0,-1
}
    80005018:	60e2                	ld	ra,24(sp)
    8000501a:	6442                	ld	s0,16(sp)
    8000501c:	64a2                	ld	s1,8(sp)
    8000501e:	6105                	addi	sp,sp,32
    80005020:	8082                	ret
      p->ofile[fd] = f;
    80005022:	01a50793          	addi	a5,a0,26
    80005026:	078e                	slli	a5,a5,0x3
    80005028:	963e                	add	a2,a2,a5
    8000502a:	e204                	sd	s1,0(a2)
      return fd;
    8000502c:	b7f5                	j	80005018 <fdalloc+0x2c>

000000008000502e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000502e:	715d                	addi	sp,sp,-80
    80005030:	e486                	sd	ra,72(sp)
    80005032:	e0a2                	sd	s0,64(sp)
    80005034:	fc26                	sd	s1,56(sp)
    80005036:	f84a                	sd	s2,48(sp)
    80005038:	f44e                	sd	s3,40(sp)
    8000503a:	f052                	sd	s4,32(sp)
    8000503c:	ec56                	sd	s5,24(sp)
    8000503e:	0880                	addi	s0,sp,80
    80005040:	89ae                	mv	s3,a1
    80005042:	8ab2                	mv	s5,a2
    80005044:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005046:	fb040593          	addi	a1,s0,-80
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	e48080e7          	jalr	-440(ra) # 80003e92 <nameiparent>
    80005052:	892a                	mv	s2,a0
    80005054:	12050e63          	beqz	a0,80005190 <create+0x162>
    return 0;

  ilock(dp);
    80005058:	ffffe097          	auipc	ra,0xffffe
    8000505c:	66c080e7          	jalr	1644(ra) # 800036c4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005060:	4601                	li	a2,0
    80005062:	fb040593          	addi	a1,s0,-80
    80005066:	854a                	mv	a0,s2
    80005068:	fffff097          	auipc	ra,0xfffff
    8000506c:	b3a080e7          	jalr	-1222(ra) # 80003ba2 <dirlookup>
    80005070:	84aa                	mv	s1,a0
    80005072:	c921                	beqz	a0,800050c2 <create+0x94>
    iunlockput(dp);
    80005074:	854a                	mv	a0,s2
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	8b0080e7          	jalr	-1872(ra) # 80003926 <iunlockput>
    ilock(ip);
    8000507e:	8526                	mv	a0,s1
    80005080:	ffffe097          	auipc	ra,0xffffe
    80005084:	644080e7          	jalr	1604(ra) # 800036c4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005088:	2981                	sext.w	s3,s3
    8000508a:	4789                	li	a5,2
    8000508c:	02f99463          	bne	s3,a5,800050b4 <create+0x86>
    80005090:	0444d783          	lhu	a5,68(s1)
    80005094:	37f9                	addiw	a5,a5,-2
    80005096:	17c2                	slli	a5,a5,0x30
    80005098:	93c1                	srli	a5,a5,0x30
    8000509a:	4705                	li	a4,1
    8000509c:	00f76c63          	bltu	a4,a5,800050b4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800050a0:	8526                	mv	a0,s1
    800050a2:	60a6                	ld	ra,72(sp)
    800050a4:	6406                	ld	s0,64(sp)
    800050a6:	74e2                	ld	s1,56(sp)
    800050a8:	7942                	ld	s2,48(sp)
    800050aa:	79a2                	ld	s3,40(sp)
    800050ac:	7a02                	ld	s4,32(sp)
    800050ae:	6ae2                	ld	s5,24(sp)
    800050b0:	6161                	addi	sp,sp,80
    800050b2:	8082                	ret
    iunlockput(ip);
    800050b4:	8526                	mv	a0,s1
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	870080e7          	jalr	-1936(ra) # 80003926 <iunlockput>
    return 0;
    800050be:	4481                	li	s1,0
    800050c0:	b7c5                	j	800050a0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800050c2:	85ce                	mv	a1,s3
    800050c4:	00092503          	lw	a0,0(s2)
    800050c8:	ffffe097          	auipc	ra,0xffffe
    800050cc:	464080e7          	jalr	1124(ra) # 8000352c <ialloc>
    800050d0:	84aa                	mv	s1,a0
    800050d2:	c521                	beqz	a0,8000511a <create+0xec>
  ilock(ip);
    800050d4:	ffffe097          	auipc	ra,0xffffe
    800050d8:	5f0080e7          	jalr	1520(ra) # 800036c4 <ilock>
  ip->major = major;
    800050dc:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800050e0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800050e4:	4a05                	li	s4,1
    800050e6:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800050ea:	8526                	mv	a0,s1
    800050ec:	ffffe097          	auipc	ra,0xffffe
    800050f0:	50e080e7          	jalr	1294(ra) # 800035fa <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800050f4:	2981                	sext.w	s3,s3
    800050f6:	03498a63          	beq	s3,s4,8000512a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800050fa:	40d0                	lw	a2,4(s1)
    800050fc:	fb040593          	addi	a1,s0,-80
    80005100:	854a                	mv	a0,s2
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	cb0080e7          	jalr	-848(ra) # 80003db2 <dirlink>
    8000510a:	06054b63          	bltz	a0,80005180 <create+0x152>
  iunlockput(dp);
    8000510e:	854a                	mv	a0,s2
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	816080e7          	jalr	-2026(ra) # 80003926 <iunlockput>
  return ip;
    80005118:	b761                	j	800050a0 <create+0x72>
    panic("create: ialloc");
    8000511a:	00003517          	auipc	a0,0x3
    8000511e:	5f650513          	addi	a0,a0,1526 # 80008710 <syscalls+0x2c8>
    80005122:	ffffb097          	auipc	ra,0xffffb
    80005126:	420080e7          	jalr	1056(ra) # 80000542 <panic>
    dp->nlink++;  // for ".."
    8000512a:	04a95783          	lhu	a5,74(s2)
    8000512e:	2785                	addiw	a5,a5,1
    80005130:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005134:	854a                	mv	a0,s2
    80005136:	ffffe097          	auipc	ra,0xffffe
    8000513a:	4c4080e7          	jalr	1220(ra) # 800035fa <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000513e:	40d0                	lw	a2,4(s1)
    80005140:	00003597          	auipc	a1,0x3
    80005144:	5e058593          	addi	a1,a1,1504 # 80008720 <syscalls+0x2d8>
    80005148:	8526                	mv	a0,s1
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	c68080e7          	jalr	-920(ra) # 80003db2 <dirlink>
    80005152:	00054f63          	bltz	a0,80005170 <create+0x142>
    80005156:	00492603          	lw	a2,4(s2)
    8000515a:	00003597          	auipc	a1,0x3
    8000515e:	5ce58593          	addi	a1,a1,1486 # 80008728 <syscalls+0x2e0>
    80005162:	8526                	mv	a0,s1
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	c4e080e7          	jalr	-946(ra) # 80003db2 <dirlink>
    8000516c:	f80557e3          	bgez	a0,800050fa <create+0xcc>
      panic("create dots");
    80005170:	00003517          	auipc	a0,0x3
    80005174:	5c050513          	addi	a0,a0,1472 # 80008730 <syscalls+0x2e8>
    80005178:	ffffb097          	auipc	ra,0xffffb
    8000517c:	3ca080e7          	jalr	970(ra) # 80000542 <panic>
    panic("create: dirlink");
    80005180:	00003517          	auipc	a0,0x3
    80005184:	5c050513          	addi	a0,a0,1472 # 80008740 <syscalls+0x2f8>
    80005188:	ffffb097          	auipc	ra,0xffffb
    8000518c:	3ba080e7          	jalr	954(ra) # 80000542 <panic>
    return 0;
    80005190:	84aa                	mv	s1,a0
    80005192:	b739                	j	800050a0 <create+0x72>

0000000080005194 <sys_dup>:
{
    80005194:	7179                	addi	sp,sp,-48
    80005196:	f406                	sd	ra,40(sp)
    80005198:	f022                	sd	s0,32(sp)
    8000519a:	ec26                	sd	s1,24(sp)
    8000519c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000519e:	fd840613          	addi	a2,s0,-40
    800051a2:	4581                	li	a1,0
    800051a4:	4501                	li	a0,0
    800051a6:	00000097          	auipc	ra,0x0
    800051aa:	dde080e7          	jalr	-546(ra) # 80004f84 <argfd>
    return -1;
    800051ae:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800051b0:	02054363          	bltz	a0,800051d6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800051b4:	fd843503          	ld	a0,-40(s0)
    800051b8:	00000097          	auipc	ra,0x0
    800051bc:	e34080e7          	jalr	-460(ra) # 80004fec <fdalloc>
    800051c0:	84aa                	mv	s1,a0
    return -1;
    800051c2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800051c4:	00054963          	bltz	a0,800051d6 <sys_dup+0x42>
  filedup(f);
    800051c8:	fd843503          	ld	a0,-40(s0)
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	338080e7          	jalr	824(ra) # 80004504 <filedup>
  return fd;
    800051d4:	87a6                	mv	a5,s1
}
    800051d6:	853e                	mv	a0,a5
    800051d8:	70a2                	ld	ra,40(sp)
    800051da:	7402                	ld	s0,32(sp)
    800051dc:	64e2                	ld	s1,24(sp)
    800051de:	6145                	addi	sp,sp,48
    800051e0:	8082                	ret

00000000800051e2 <sys_read>:
{
    800051e2:	7179                	addi	sp,sp,-48
    800051e4:	f406                	sd	ra,40(sp)
    800051e6:	f022                	sd	s0,32(sp)
    800051e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051ea:	fe840613          	addi	a2,s0,-24
    800051ee:	4581                	li	a1,0
    800051f0:	4501                	li	a0,0
    800051f2:	00000097          	auipc	ra,0x0
    800051f6:	d92080e7          	jalr	-622(ra) # 80004f84 <argfd>
    return -1;
    800051fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800051fc:	04054163          	bltz	a0,8000523e <sys_read+0x5c>
    80005200:	fe440593          	addi	a1,s0,-28
    80005204:	4509                	li	a0,2
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	84c080e7          	jalr	-1972(ra) # 80002a52 <argint>
    return -1;
    8000520e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005210:	02054763          	bltz	a0,8000523e <sys_read+0x5c>
    80005214:	fd840593          	addi	a1,s0,-40
    80005218:	4505                	li	a0,1
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	85a080e7          	jalr	-1958(ra) # 80002a74 <argaddr>
    return -1;
    80005222:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005224:	00054d63          	bltz	a0,8000523e <sys_read+0x5c>
  return fileread(f, p, n);
    80005228:	fe442603          	lw	a2,-28(s0)
    8000522c:	fd843583          	ld	a1,-40(s0)
    80005230:	fe843503          	ld	a0,-24(s0)
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	45c080e7          	jalr	1116(ra) # 80004690 <fileread>
    8000523c:	87aa                	mv	a5,a0
}
    8000523e:	853e                	mv	a0,a5
    80005240:	70a2                	ld	ra,40(sp)
    80005242:	7402                	ld	s0,32(sp)
    80005244:	6145                	addi	sp,sp,48
    80005246:	8082                	ret

0000000080005248 <sys_write>:
{
    80005248:	7179                	addi	sp,sp,-48
    8000524a:	f406                	sd	ra,40(sp)
    8000524c:	f022                	sd	s0,32(sp)
    8000524e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005250:	fe840613          	addi	a2,s0,-24
    80005254:	4581                	li	a1,0
    80005256:	4501                	li	a0,0
    80005258:	00000097          	auipc	ra,0x0
    8000525c:	d2c080e7          	jalr	-724(ra) # 80004f84 <argfd>
    return -1;
    80005260:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005262:	04054163          	bltz	a0,800052a4 <sys_write+0x5c>
    80005266:	fe440593          	addi	a1,s0,-28
    8000526a:	4509                	li	a0,2
    8000526c:	ffffd097          	auipc	ra,0xffffd
    80005270:	7e6080e7          	jalr	2022(ra) # 80002a52 <argint>
    return -1;
    80005274:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005276:	02054763          	bltz	a0,800052a4 <sys_write+0x5c>
    8000527a:	fd840593          	addi	a1,s0,-40
    8000527e:	4505                	li	a0,1
    80005280:	ffffd097          	auipc	ra,0xffffd
    80005284:	7f4080e7          	jalr	2036(ra) # 80002a74 <argaddr>
    return -1;
    80005288:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000528a:	00054d63          	bltz	a0,800052a4 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000528e:	fe442603          	lw	a2,-28(s0)
    80005292:	fd843583          	ld	a1,-40(s0)
    80005296:	fe843503          	ld	a0,-24(s0)
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	4b8080e7          	jalr	1208(ra) # 80004752 <filewrite>
    800052a2:	87aa                	mv	a5,a0
}
    800052a4:	853e                	mv	a0,a5
    800052a6:	70a2                	ld	ra,40(sp)
    800052a8:	7402                	ld	s0,32(sp)
    800052aa:	6145                	addi	sp,sp,48
    800052ac:	8082                	ret

00000000800052ae <sys_close>:
{
    800052ae:	1101                	addi	sp,sp,-32
    800052b0:	ec06                	sd	ra,24(sp)
    800052b2:	e822                	sd	s0,16(sp)
    800052b4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800052b6:	fe040613          	addi	a2,s0,-32
    800052ba:	fec40593          	addi	a1,s0,-20
    800052be:	4501                	li	a0,0
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	cc4080e7          	jalr	-828(ra) # 80004f84 <argfd>
    return -1;
    800052c8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800052ca:	02054463          	bltz	a0,800052f2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800052ce:	ffffc097          	auipc	ra,0xffffc
    800052d2:	6ec080e7          	jalr	1772(ra) # 800019ba <myproc>
    800052d6:	fec42783          	lw	a5,-20(s0)
    800052da:	07e9                	addi	a5,a5,26
    800052dc:	078e                	slli	a5,a5,0x3
    800052de:	97aa                	add	a5,a5,a0
    800052e0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800052e4:	fe043503          	ld	a0,-32(s0)
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	26e080e7          	jalr	622(ra) # 80004556 <fileclose>
  return 0;
    800052f0:	4781                	li	a5,0
}
    800052f2:	853e                	mv	a0,a5
    800052f4:	60e2                	ld	ra,24(sp)
    800052f6:	6442                	ld	s0,16(sp)
    800052f8:	6105                	addi	sp,sp,32
    800052fa:	8082                	ret

00000000800052fc <sys_fstat>:
{
    800052fc:	1101                	addi	sp,sp,-32
    800052fe:	ec06                	sd	ra,24(sp)
    80005300:	e822                	sd	s0,16(sp)
    80005302:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005304:	fe840613          	addi	a2,s0,-24
    80005308:	4581                	li	a1,0
    8000530a:	4501                	li	a0,0
    8000530c:	00000097          	auipc	ra,0x0
    80005310:	c78080e7          	jalr	-904(ra) # 80004f84 <argfd>
    return -1;
    80005314:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005316:	02054563          	bltz	a0,80005340 <sys_fstat+0x44>
    8000531a:	fe040593          	addi	a1,s0,-32
    8000531e:	4505                	li	a0,1
    80005320:	ffffd097          	auipc	ra,0xffffd
    80005324:	754080e7          	jalr	1876(ra) # 80002a74 <argaddr>
    return -1;
    80005328:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000532a:	00054b63          	bltz	a0,80005340 <sys_fstat+0x44>
  return filestat(f, st);
    8000532e:	fe043583          	ld	a1,-32(s0)
    80005332:	fe843503          	ld	a0,-24(s0)
    80005336:	fffff097          	auipc	ra,0xfffff
    8000533a:	2e8080e7          	jalr	744(ra) # 8000461e <filestat>
    8000533e:	87aa                	mv	a5,a0
}
    80005340:	853e                	mv	a0,a5
    80005342:	60e2                	ld	ra,24(sp)
    80005344:	6442                	ld	s0,16(sp)
    80005346:	6105                	addi	sp,sp,32
    80005348:	8082                	ret

000000008000534a <sys_link>:
{
    8000534a:	7169                	addi	sp,sp,-304
    8000534c:	f606                	sd	ra,296(sp)
    8000534e:	f222                	sd	s0,288(sp)
    80005350:	ee26                	sd	s1,280(sp)
    80005352:	ea4a                	sd	s2,272(sp)
    80005354:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005356:	08000613          	li	a2,128
    8000535a:	ed040593          	addi	a1,s0,-304
    8000535e:	4501                	li	a0,0
    80005360:	ffffd097          	auipc	ra,0xffffd
    80005364:	736080e7          	jalr	1846(ra) # 80002a96 <argstr>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000536a:	10054e63          	bltz	a0,80005486 <sys_link+0x13c>
    8000536e:	08000613          	li	a2,128
    80005372:	f5040593          	addi	a1,s0,-176
    80005376:	4505                	li	a0,1
    80005378:	ffffd097          	auipc	ra,0xffffd
    8000537c:	71e080e7          	jalr	1822(ra) # 80002a96 <argstr>
    return -1;
    80005380:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005382:	10054263          	bltz	a0,80005486 <sys_link+0x13c>
  begin_op();
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	cfe080e7          	jalr	-770(ra) # 80004084 <begin_op>
  if((ip = namei(old)) == 0){
    8000538e:	ed040513          	addi	a0,s0,-304
    80005392:	fffff097          	auipc	ra,0xfffff
    80005396:	ae2080e7          	jalr	-1310(ra) # 80003e74 <namei>
    8000539a:	84aa                	mv	s1,a0
    8000539c:	c551                	beqz	a0,80005428 <sys_link+0xde>
  ilock(ip);
    8000539e:	ffffe097          	auipc	ra,0xffffe
    800053a2:	326080e7          	jalr	806(ra) # 800036c4 <ilock>
  if(ip->type == T_DIR){
    800053a6:	04449703          	lh	a4,68(s1)
    800053aa:	4785                	li	a5,1
    800053ac:	08f70463          	beq	a4,a5,80005434 <sys_link+0xea>
  ip->nlink++;
    800053b0:	04a4d783          	lhu	a5,74(s1)
    800053b4:	2785                	addiw	a5,a5,1
    800053b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053ba:	8526                	mv	a0,s1
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	23e080e7          	jalr	574(ra) # 800035fa <iupdate>
  iunlock(ip);
    800053c4:	8526                	mv	a0,s1
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	3c0080e7          	jalr	960(ra) # 80003786 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800053ce:	fd040593          	addi	a1,s0,-48
    800053d2:	f5040513          	addi	a0,s0,-176
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	abc080e7          	jalr	-1348(ra) # 80003e92 <nameiparent>
    800053de:	892a                	mv	s2,a0
    800053e0:	c935                	beqz	a0,80005454 <sys_link+0x10a>
  ilock(dp);
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	2e2080e7          	jalr	738(ra) # 800036c4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800053ea:	00092703          	lw	a4,0(s2)
    800053ee:	409c                	lw	a5,0(s1)
    800053f0:	04f71d63          	bne	a4,a5,8000544a <sys_link+0x100>
    800053f4:	40d0                	lw	a2,4(s1)
    800053f6:	fd040593          	addi	a1,s0,-48
    800053fa:	854a                	mv	a0,s2
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	9b6080e7          	jalr	-1610(ra) # 80003db2 <dirlink>
    80005404:	04054363          	bltz	a0,8000544a <sys_link+0x100>
  iunlockput(dp);
    80005408:	854a                	mv	a0,s2
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	51c080e7          	jalr	1308(ra) # 80003926 <iunlockput>
  iput(ip);
    80005412:	8526                	mv	a0,s1
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	46a080e7          	jalr	1130(ra) # 8000387e <iput>
  end_op();
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	ce8080e7          	jalr	-792(ra) # 80004104 <end_op>
  return 0;
    80005424:	4781                	li	a5,0
    80005426:	a085                	j	80005486 <sys_link+0x13c>
    end_op();
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	cdc080e7          	jalr	-804(ra) # 80004104 <end_op>
    return -1;
    80005430:	57fd                	li	a5,-1
    80005432:	a891                	j	80005486 <sys_link+0x13c>
    iunlockput(ip);
    80005434:	8526                	mv	a0,s1
    80005436:	ffffe097          	auipc	ra,0xffffe
    8000543a:	4f0080e7          	jalr	1264(ra) # 80003926 <iunlockput>
    end_op();
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	cc6080e7          	jalr	-826(ra) # 80004104 <end_op>
    return -1;
    80005446:	57fd                	li	a5,-1
    80005448:	a83d                	j	80005486 <sys_link+0x13c>
    iunlockput(dp);
    8000544a:	854a                	mv	a0,s2
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	4da080e7          	jalr	1242(ra) # 80003926 <iunlockput>
  ilock(ip);
    80005454:	8526                	mv	a0,s1
    80005456:	ffffe097          	auipc	ra,0xffffe
    8000545a:	26e080e7          	jalr	622(ra) # 800036c4 <ilock>
  ip->nlink--;
    8000545e:	04a4d783          	lhu	a5,74(s1)
    80005462:	37fd                	addiw	a5,a5,-1
    80005464:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005468:	8526                	mv	a0,s1
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	190080e7          	jalr	400(ra) # 800035fa <iupdate>
  iunlockput(ip);
    80005472:	8526                	mv	a0,s1
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	4b2080e7          	jalr	1202(ra) # 80003926 <iunlockput>
  end_op();
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	c88080e7          	jalr	-888(ra) # 80004104 <end_op>
  return -1;
    80005484:	57fd                	li	a5,-1
}
    80005486:	853e                	mv	a0,a5
    80005488:	70b2                	ld	ra,296(sp)
    8000548a:	7412                	ld	s0,288(sp)
    8000548c:	64f2                	ld	s1,280(sp)
    8000548e:	6952                	ld	s2,272(sp)
    80005490:	6155                	addi	sp,sp,304
    80005492:	8082                	ret

0000000080005494 <sys_unlink>:
{
    80005494:	7151                	addi	sp,sp,-240
    80005496:	f586                	sd	ra,232(sp)
    80005498:	f1a2                	sd	s0,224(sp)
    8000549a:	eda6                	sd	s1,216(sp)
    8000549c:	e9ca                	sd	s2,208(sp)
    8000549e:	e5ce                	sd	s3,200(sp)
    800054a0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800054a2:	08000613          	li	a2,128
    800054a6:	f3040593          	addi	a1,s0,-208
    800054aa:	4501                	li	a0,0
    800054ac:	ffffd097          	auipc	ra,0xffffd
    800054b0:	5ea080e7          	jalr	1514(ra) # 80002a96 <argstr>
    800054b4:	18054163          	bltz	a0,80005636 <sys_unlink+0x1a2>
  begin_op();
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	bcc080e7          	jalr	-1076(ra) # 80004084 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800054c0:	fb040593          	addi	a1,s0,-80
    800054c4:	f3040513          	addi	a0,s0,-208
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	9ca080e7          	jalr	-1590(ra) # 80003e92 <nameiparent>
    800054d0:	84aa                	mv	s1,a0
    800054d2:	c979                	beqz	a0,800055a8 <sys_unlink+0x114>
  ilock(dp);
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	1f0080e7          	jalr	496(ra) # 800036c4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800054dc:	00003597          	auipc	a1,0x3
    800054e0:	24458593          	addi	a1,a1,580 # 80008720 <syscalls+0x2d8>
    800054e4:	fb040513          	addi	a0,s0,-80
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	6a0080e7          	jalr	1696(ra) # 80003b88 <namecmp>
    800054f0:	14050a63          	beqz	a0,80005644 <sys_unlink+0x1b0>
    800054f4:	00003597          	auipc	a1,0x3
    800054f8:	23458593          	addi	a1,a1,564 # 80008728 <syscalls+0x2e0>
    800054fc:	fb040513          	addi	a0,s0,-80
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	688080e7          	jalr	1672(ra) # 80003b88 <namecmp>
    80005508:	12050e63          	beqz	a0,80005644 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000550c:	f2c40613          	addi	a2,s0,-212
    80005510:	fb040593          	addi	a1,s0,-80
    80005514:	8526                	mv	a0,s1
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	68c080e7          	jalr	1676(ra) # 80003ba2 <dirlookup>
    8000551e:	892a                	mv	s2,a0
    80005520:	12050263          	beqz	a0,80005644 <sys_unlink+0x1b0>
  ilock(ip);
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	1a0080e7          	jalr	416(ra) # 800036c4 <ilock>
  if(ip->nlink < 1)
    8000552c:	04a91783          	lh	a5,74(s2)
    80005530:	08f05263          	blez	a5,800055b4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005534:	04491703          	lh	a4,68(s2)
    80005538:	4785                	li	a5,1
    8000553a:	08f70563          	beq	a4,a5,800055c4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000553e:	4641                	li	a2,16
    80005540:	4581                	li	a1,0
    80005542:	fc040513          	addi	a0,s0,-64
    80005546:	ffffb097          	auipc	ra,0xffffb
    8000554a:	7b4080e7          	jalr	1972(ra) # 80000cfa <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000554e:	4741                	li	a4,16
    80005550:	f2c42683          	lw	a3,-212(s0)
    80005554:	fc040613          	addi	a2,s0,-64
    80005558:	4581                	li	a1,0
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	512080e7          	jalr	1298(ra) # 80003a6e <writei>
    80005564:	47c1                	li	a5,16
    80005566:	0af51563          	bne	a0,a5,80005610 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000556a:	04491703          	lh	a4,68(s2)
    8000556e:	4785                	li	a5,1
    80005570:	0af70863          	beq	a4,a5,80005620 <sys_unlink+0x18c>
  iunlockput(dp);
    80005574:	8526                	mv	a0,s1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	3b0080e7          	jalr	944(ra) # 80003926 <iunlockput>
  ip->nlink--;
    8000557e:	04a95783          	lhu	a5,74(s2)
    80005582:	37fd                	addiw	a5,a5,-1
    80005584:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005588:	854a                	mv	a0,s2
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	070080e7          	jalr	112(ra) # 800035fa <iupdate>
  iunlockput(ip);
    80005592:	854a                	mv	a0,s2
    80005594:	ffffe097          	auipc	ra,0xffffe
    80005598:	392080e7          	jalr	914(ra) # 80003926 <iunlockput>
  end_op();
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	b68080e7          	jalr	-1176(ra) # 80004104 <end_op>
  return 0;
    800055a4:	4501                	li	a0,0
    800055a6:	a84d                	j	80005658 <sys_unlink+0x1c4>
    end_op();
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	b5c080e7          	jalr	-1188(ra) # 80004104 <end_op>
    return -1;
    800055b0:	557d                	li	a0,-1
    800055b2:	a05d                	j	80005658 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800055b4:	00003517          	auipc	a0,0x3
    800055b8:	19c50513          	addi	a0,a0,412 # 80008750 <syscalls+0x308>
    800055bc:	ffffb097          	auipc	ra,0xffffb
    800055c0:	f86080e7          	jalr	-122(ra) # 80000542 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055c4:	04c92703          	lw	a4,76(s2)
    800055c8:	02000793          	li	a5,32
    800055cc:	f6e7f9e3          	bgeu	a5,a4,8000553e <sys_unlink+0xaa>
    800055d0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055d4:	4741                	li	a4,16
    800055d6:	86ce                	mv	a3,s3
    800055d8:	f1840613          	addi	a2,s0,-232
    800055dc:	4581                	li	a1,0
    800055de:	854a                	mv	a0,s2
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	398080e7          	jalr	920(ra) # 80003978 <readi>
    800055e8:	47c1                	li	a5,16
    800055ea:	00f51b63          	bne	a0,a5,80005600 <sys_unlink+0x16c>
    if(de.inum != 0)
    800055ee:	f1845783          	lhu	a5,-232(s0)
    800055f2:	e7a1                	bnez	a5,8000563a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800055f4:	29c1                	addiw	s3,s3,16
    800055f6:	04c92783          	lw	a5,76(s2)
    800055fa:	fcf9ede3          	bltu	s3,a5,800055d4 <sys_unlink+0x140>
    800055fe:	b781                	j	8000553e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005600:	00003517          	auipc	a0,0x3
    80005604:	16850513          	addi	a0,a0,360 # 80008768 <syscalls+0x320>
    80005608:	ffffb097          	auipc	ra,0xffffb
    8000560c:	f3a080e7          	jalr	-198(ra) # 80000542 <panic>
    panic("unlink: writei");
    80005610:	00003517          	auipc	a0,0x3
    80005614:	17050513          	addi	a0,a0,368 # 80008780 <syscalls+0x338>
    80005618:	ffffb097          	auipc	ra,0xffffb
    8000561c:	f2a080e7          	jalr	-214(ra) # 80000542 <panic>
    dp->nlink--;
    80005620:	04a4d783          	lhu	a5,74(s1)
    80005624:	37fd                	addiw	a5,a5,-1
    80005626:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	fce080e7          	jalr	-50(ra) # 800035fa <iupdate>
    80005634:	b781                	j	80005574 <sys_unlink+0xe0>
    return -1;
    80005636:	557d                	li	a0,-1
    80005638:	a005                	j	80005658 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000563a:	854a                	mv	a0,s2
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	2ea080e7          	jalr	746(ra) # 80003926 <iunlockput>
  iunlockput(dp);
    80005644:	8526                	mv	a0,s1
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	2e0080e7          	jalr	736(ra) # 80003926 <iunlockput>
  end_op();
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	ab6080e7          	jalr	-1354(ra) # 80004104 <end_op>
  return -1;
    80005656:	557d                	li	a0,-1
}
    80005658:	70ae                	ld	ra,232(sp)
    8000565a:	740e                	ld	s0,224(sp)
    8000565c:	64ee                	ld	s1,216(sp)
    8000565e:	694e                	ld	s2,208(sp)
    80005660:	69ae                	ld	s3,200(sp)
    80005662:	616d                	addi	sp,sp,240
    80005664:	8082                	ret

0000000080005666 <sys_open>:

uint64
sys_open(void)
{
    80005666:	7131                	addi	sp,sp,-192
    80005668:	fd06                	sd	ra,184(sp)
    8000566a:	f922                	sd	s0,176(sp)
    8000566c:	f526                	sd	s1,168(sp)
    8000566e:	f14a                	sd	s2,160(sp)
    80005670:	ed4e                	sd	s3,152(sp)
    80005672:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005674:	08000613          	li	a2,128
    80005678:	f5040593          	addi	a1,s0,-176
    8000567c:	4501                	li	a0,0
    8000567e:	ffffd097          	auipc	ra,0xffffd
    80005682:	418080e7          	jalr	1048(ra) # 80002a96 <argstr>
    return -1;
    80005686:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005688:	0c054163          	bltz	a0,8000574a <sys_open+0xe4>
    8000568c:	f4c40593          	addi	a1,s0,-180
    80005690:	4505                	li	a0,1
    80005692:	ffffd097          	auipc	ra,0xffffd
    80005696:	3c0080e7          	jalr	960(ra) # 80002a52 <argint>
    8000569a:	0a054863          	bltz	a0,8000574a <sys_open+0xe4>

  begin_op();
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	9e6080e7          	jalr	-1562(ra) # 80004084 <begin_op>

  if(omode & O_CREATE){
    800056a6:	f4c42783          	lw	a5,-180(s0)
    800056aa:	2007f793          	andi	a5,a5,512
    800056ae:	cbdd                	beqz	a5,80005764 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800056b0:	4681                	li	a3,0
    800056b2:	4601                	li	a2,0
    800056b4:	4589                	li	a1,2
    800056b6:	f5040513          	addi	a0,s0,-176
    800056ba:	00000097          	auipc	ra,0x0
    800056be:	974080e7          	jalr	-1676(ra) # 8000502e <create>
    800056c2:	892a                	mv	s2,a0
    if(ip == 0){
    800056c4:	c959                	beqz	a0,8000575a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800056c6:	04491703          	lh	a4,68(s2)
    800056ca:	478d                	li	a5,3
    800056cc:	00f71763          	bne	a4,a5,800056da <sys_open+0x74>
    800056d0:	04695703          	lhu	a4,70(s2)
    800056d4:	47a5                	li	a5,9
    800056d6:	0ce7ec63          	bltu	a5,a4,800057ae <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	dc0080e7          	jalr	-576(ra) # 8000449a <filealloc>
    800056e2:	89aa                	mv	s3,a0
    800056e4:	10050263          	beqz	a0,800057e8 <sys_open+0x182>
    800056e8:	00000097          	auipc	ra,0x0
    800056ec:	904080e7          	jalr	-1788(ra) # 80004fec <fdalloc>
    800056f0:	84aa                	mv	s1,a0
    800056f2:	0e054663          	bltz	a0,800057de <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800056f6:	04491703          	lh	a4,68(s2)
    800056fa:	478d                	li	a5,3
    800056fc:	0cf70463          	beq	a4,a5,800057c4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005700:	4789                	li	a5,2
    80005702:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005706:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000570a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000570e:	f4c42783          	lw	a5,-180(s0)
    80005712:	0017c713          	xori	a4,a5,1
    80005716:	8b05                	andi	a4,a4,1
    80005718:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000571c:	0037f713          	andi	a4,a5,3
    80005720:	00e03733          	snez	a4,a4
    80005724:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005728:	4007f793          	andi	a5,a5,1024
    8000572c:	c791                	beqz	a5,80005738 <sys_open+0xd2>
    8000572e:	04491703          	lh	a4,68(s2)
    80005732:	4789                	li	a5,2
    80005734:	08f70f63          	beq	a4,a5,800057d2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005738:	854a                	mv	a0,s2
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	04c080e7          	jalr	76(ra) # 80003786 <iunlock>
  end_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	9c2080e7          	jalr	-1598(ra) # 80004104 <end_op>

  return fd;
}
    8000574a:	8526                	mv	a0,s1
    8000574c:	70ea                	ld	ra,184(sp)
    8000574e:	744a                	ld	s0,176(sp)
    80005750:	74aa                	ld	s1,168(sp)
    80005752:	790a                	ld	s2,160(sp)
    80005754:	69ea                	ld	s3,152(sp)
    80005756:	6129                	addi	sp,sp,192
    80005758:	8082                	ret
      end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	9aa080e7          	jalr	-1622(ra) # 80004104 <end_op>
      return -1;
    80005762:	b7e5                	j	8000574a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005764:	f5040513          	addi	a0,s0,-176
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	70c080e7          	jalr	1804(ra) # 80003e74 <namei>
    80005770:	892a                	mv	s2,a0
    80005772:	c905                	beqz	a0,800057a2 <sys_open+0x13c>
    ilock(ip);
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	f50080e7          	jalr	-176(ra) # 800036c4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000577c:	04491703          	lh	a4,68(s2)
    80005780:	4785                	li	a5,1
    80005782:	f4f712e3          	bne	a4,a5,800056c6 <sys_open+0x60>
    80005786:	f4c42783          	lw	a5,-180(s0)
    8000578a:	dba1                	beqz	a5,800056da <sys_open+0x74>
      iunlockput(ip);
    8000578c:	854a                	mv	a0,s2
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	198080e7          	jalr	408(ra) # 80003926 <iunlockput>
      end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	96e080e7          	jalr	-1682(ra) # 80004104 <end_op>
      return -1;
    8000579e:	54fd                	li	s1,-1
    800057a0:	b76d                	j	8000574a <sys_open+0xe4>
      end_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	962080e7          	jalr	-1694(ra) # 80004104 <end_op>
      return -1;
    800057aa:	54fd                	li	s1,-1
    800057ac:	bf79                	j	8000574a <sys_open+0xe4>
    iunlockput(ip);
    800057ae:	854a                	mv	a0,s2
    800057b0:	ffffe097          	auipc	ra,0xffffe
    800057b4:	176080e7          	jalr	374(ra) # 80003926 <iunlockput>
    end_op();
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	94c080e7          	jalr	-1716(ra) # 80004104 <end_op>
    return -1;
    800057c0:	54fd                	li	s1,-1
    800057c2:	b761                	j	8000574a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800057c4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800057c8:	04691783          	lh	a5,70(s2)
    800057cc:	02f99223          	sh	a5,36(s3)
    800057d0:	bf2d                	j	8000570a <sys_open+0xa4>
    itrunc(ip);
    800057d2:	854a                	mv	a0,s2
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	ffe080e7          	jalr	-2(ra) # 800037d2 <itrunc>
    800057dc:	bfb1                	j	80005738 <sys_open+0xd2>
      fileclose(f);
    800057de:	854e                	mv	a0,s3
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	d76080e7          	jalr	-650(ra) # 80004556 <fileclose>
    iunlockput(ip);
    800057e8:	854a                	mv	a0,s2
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	13c080e7          	jalr	316(ra) # 80003926 <iunlockput>
    end_op();
    800057f2:	fffff097          	auipc	ra,0xfffff
    800057f6:	912080e7          	jalr	-1774(ra) # 80004104 <end_op>
    return -1;
    800057fa:	54fd                	li	s1,-1
    800057fc:	b7b9                	j	8000574a <sys_open+0xe4>

00000000800057fe <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800057fe:	7175                	addi	sp,sp,-144
    80005800:	e506                	sd	ra,136(sp)
    80005802:	e122                	sd	s0,128(sp)
    80005804:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	87e080e7          	jalr	-1922(ra) # 80004084 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000580e:	08000613          	li	a2,128
    80005812:	f7040593          	addi	a1,s0,-144
    80005816:	4501                	li	a0,0
    80005818:	ffffd097          	auipc	ra,0xffffd
    8000581c:	27e080e7          	jalr	638(ra) # 80002a96 <argstr>
    80005820:	02054963          	bltz	a0,80005852 <sys_mkdir+0x54>
    80005824:	4681                	li	a3,0
    80005826:	4601                	li	a2,0
    80005828:	4585                	li	a1,1
    8000582a:	f7040513          	addi	a0,s0,-144
    8000582e:	00000097          	auipc	ra,0x0
    80005832:	800080e7          	jalr	-2048(ra) # 8000502e <create>
    80005836:	cd11                	beqz	a0,80005852 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	0ee080e7          	jalr	238(ra) # 80003926 <iunlockput>
  end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	8c4080e7          	jalr	-1852(ra) # 80004104 <end_op>
  return 0;
    80005848:	4501                	li	a0,0
}
    8000584a:	60aa                	ld	ra,136(sp)
    8000584c:	640a                	ld	s0,128(sp)
    8000584e:	6149                	addi	sp,sp,144
    80005850:	8082                	ret
    end_op();
    80005852:	fffff097          	auipc	ra,0xfffff
    80005856:	8b2080e7          	jalr	-1870(ra) # 80004104 <end_op>
    return -1;
    8000585a:	557d                	li	a0,-1
    8000585c:	b7fd                	j	8000584a <sys_mkdir+0x4c>

000000008000585e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000585e:	7135                	addi	sp,sp,-160
    80005860:	ed06                	sd	ra,152(sp)
    80005862:	e922                	sd	s0,144(sp)
    80005864:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	81e080e7          	jalr	-2018(ra) # 80004084 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000586e:	08000613          	li	a2,128
    80005872:	f7040593          	addi	a1,s0,-144
    80005876:	4501                	li	a0,0
    80005878:	ffffd097          	auipc	ra,0xffffd
    8000587c:	21e080e7          	jalr	542(ra) # 80002a96 <argstr>
    80005880:	04054a63          	bltz	a0,800058d4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005884:	f6c40593          	addi	a1,s0,-148
    80005888:	4505                	li	a0,1
    8000588a:	ffffd097          	auipc	ra,0xffffd
    8000588e:	1c8080e7          	jalr	456(ra) # 80002a52 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005892:	04054163          	bltz	a0,800058d4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005896:	f6840593          	addi	a1,s0,-152
    8000589a:	4509                	li	a0,2
    8000589c:	ffffd097          	auipc	ra,0xffffd
    800058a0:	1b6080e7          	jalr	438(ra) # 80002a52 <argint>
     argint(1, &major) < 0 ||
    800058a4:	02054863          	bltz	a0,800058d4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800058a8:	f6841683          	lh	a3,-152(s0)
    800058ac:	f6c41603          	lh	a2,-148(s0)
    800058b0:	458d                	li	a1,3
    800058b2:	f7040513          	addi	a0,s0,-144
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	778080e7          	jalr	1912(ra) # 8000502e <create>
     argint(2, &minor) < 0 ||
    800058be:	c919                	beqz	a0,800058d4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	066080e7          	jalr	102(ra) # 80003926 <iunlockput>
  end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	83c080e7          	jalr	-1988(ra) # 80004104 <end_op>
  return 0;
    800058d0:	4501                	li	a0,0
    800058d2:	a031                	j	800058de <sys_mknod+0x80>
    end_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	830080e7          	jalr	-2000(ra) # 80004104 <end_op>
    return -1;
    800058dc:	557d                	li	a0,-1
}
    800058de:	60ea                	ld	ra,152(sp)
    800058e0:	644a                	ld	s0,144(sp)
    800058e2:	610d                	addi	sp,sp,160
    800058e4:	8082                	ret

00000000800058e6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800058e6:	7135                	addi	sp,sp,-160
    800058e8:	ed06                	sd	ra,152(sp)
    800058ea:	e922                	sd	s0,144(sp)
    800058ec:	e526                	sd	s1,136(sp)
    800058ee:	e14a                	sd	s2,128(sp)
    800058f0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800058f2:	ffffc097          	auipc	ra,0xffffc
    800058f6:	0c8080e7          	jalr	200(ra) # 800019ba <myproc>
    800058fa:	892a                	mv	s2,a0
  
  begin_op();
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	788080e7          	jalr	1928(ra) # 80004084 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005904:	08000613          	li	a2,128
    80005908:	f6040593          	addi	a1,s0,-160
    8000590c:	4501                	li	a0,0
    8000590e:	ffffd097          	auipc	ra,0xffffd
    80005912:	188080e7          	jalr	392(ra) # 80002a96 <argstr>
    80005916:	04054b63          	bltz	a0,8000596c <sys_chdir+0x86>
    8000591a:	f6040513          	addi	a0,s0,-160
    8000591e:	ffffe097          	auipc	ra,0xffffe
    80005922:	556080e7          	jalr	1366(ra) # 80003e74 <namei>
    80005926:	84aa                	mv	s1,a0
    80005928:	c131                	beqz	a0,8000596c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	d9a080e7          	jalr	-614(ra) # 800036c4 <ilock>
  if(ip->type != T_DIR){
    80005932:	04449703          	lh	a4,68(s1)
    80005936:	4785                	li	a5,1
    80005938:	04f71063          	bne	a4,a5,80005978 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000593c:	8526                	mv	a0,s1
    8000593e:	ffffe097          	auipc	ra,0xffffe
    80005942:	e48080e7          	jalr	-440(ra) # 80003786 <iunlock>
  iput(p->cwd);
    80005946:	15093503          	ld	a0,336(s2)
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	f34080e7          	jalr	-204(ra) # 8000387e <iput>
  end_op();
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	7b2080e7          	jalr	1970(ra) # 80004104 <end_op>
  p->cwd = ip;
    8000595a:	14993823          	sd	s1,336(s2)
  return 0;
    8000595e:	4501                	li	a0,0
}
    80005960:	60ea                	ld	ra,152(sp)
    80005962:	644a                	ld	s0,144(sp)
    80005964:	64aa                	ld	s1,136(sp)
    80005966:	690a                	ld	s2,128(sp)
    80005968:	610d                	addi	sp,sp,160
    8000596a:	8082                	ret
    end_op();
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	798080e7          	jalr	1944(ra) # 80004104 <end_op>
    return -1;
    80005974:	557d                	li	a0,-1
    80005976:	b7ed                	j	80005960 <sys_chdir+0x7a>
    iunlockput(ip);
    80005978:	8526                	mv	a0,s1
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	fac080e7          	jalr	-84(ra) # 80003926 <iunlockput>
    end_op();
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	782080e7          	jalr	1922(ra) # 80004104 <end_op>
    return -1;
    8000598a:	557d                	li	a0,-1
    8000598c:	bfd1                	j	80005960 <sys_chdir+0x7a>

000000008000598e <sys_exec>:

uint64
sys_exec(void)
{
    8000598e:	7145                	addi	sp,sp,-464
    80005990:	e786                	sd	ra,456(sp)
    80005992:	e3a2                	sd	s0,448(sp)
    80005994:	ff26                	sd	s1,440(sp)
    80005996:	fb4a                	sd	s2,432(sp)
    80005998:	f74e                	sd	s3,424(sp)
    8000599a:	f352                	sd	s4,416(sp)
    8000599c:	ef56                	sd	s5,408(sp)
    8000599e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059a0:	08000613          	li	a2,128
    800059a4:	f4040593          	addi	a1,s0,-192
    800059a8:	4501                	li	a0,0
    800059aa:	ffffd097          	auipc	ra,0xffffd
    800059ae:	0ec080e7          	jalr	236(ra) # 80002a96 <argstr>
    return -1;
    800059b2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800059b4:	0c054a63          	bltz	a0,80005a88 <sys_exec+0xfa>
    800059b8:	e3840593          	addi	a1,s0,-456
    800059bc:	4505                	li	a0,1
    800059be:	ffffd097          	auipc	ra,0xffffd
    800059c2:	0b6080e7          	jalr	182(ra) # 80002a74 <argaddr>
    800059c6:	0c054163          	bltz	a0,80005a88 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800059ca:	10000613          	li	a2,256
    800059ce:	4581                	li	a1,0
    800059d0:	e4040513          	addi	a0,s0,-448
    800059d4:	ffffb097          	auipc	ra,0xffffb
    800059d8:	326080e7          	jalr	806(ra) # 80000cfa <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800059dc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800059e0:	89a6                	mv	s3,s1
    800059e2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800059e4:	02000a13          	li	s4,32
    800059e8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800059ec:	00391793          	slli	a5,s2,0x3
    800059f0:	e3040593          	addi	a1,s0,-464
    800059f4:	e3843503          	ld	a0,-456(s0)
    800059f8:	953e                	add	a0,a0,a5
    800059fa:	ffffd097          	auipc	ra,0xffffd
    800059fe:	fbe080e7          	jalr	-66(ra) # 800029b8 <fetchaddr>
    80005a02:	02054a63          	bltz	a0,80005a36 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a06:	e3043783          	ld	a5,-464(s0)
    80005a0a:	c3b9                	beqz	a5,80005a50 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a0c:	ffffb097          	auipc	ra,0xffffb
    80005a10:	102080e7          	jalr	258(ra) # 80000b0e <kalloc>
    80005a14:	85aa                	mv	a1,a0
    80005a16:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a1a:	cd11                	beqz	a0,80005a36 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a1c:	6605                	lui	a2,0x1
    80005a1e:	e3043503          	ld	a0,-464(s0)
    80005a22:	ffffd097          	auipc	ra,0xffffd
    80005a26:	fe8080e7          	jalr	-24(ra) # 80002a0a <fetchstr>
    80005a2a:	00054663          	bltz	a0,80005a36 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005a2e:	0905                	addi	s2,s2,1
    80005a30:	09a1                	addi	s3,s3,8
    80005a32:	fb491be3          	bne	s2,s4,800059e8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a36:	10048913          	addi	s2,s1,256
    80005a3a:	6088                	ld	a0,0(s1)
    80005a3c:	c529                	beqz	a0,80005a86 <sys_exec+0xf8>
    kfree(argv[i]);
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	fd4080e7          	jalr	-44(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a46:	04a1                	addi	s1,s1,8
    80005a48:	ff2499e3          	bne	s1,s2,80005a3a <sys_exec+0xac>
  return -1;
    80005a4c:	597d                	li	s2,-1
    80005a4e:	a82d                	j	80005a88 <sys_exec+0xfa>
      argv[i] = 0;
    80005a50:	0a8e                	slli	s5,s5,0x3
    80005a52:	fc040793          	addi	a5,s0,-64
    80005a56:	9abe                	add	s5,s5,a5
    80005a58:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005a5c:	e4040593          	addi	a1,s0,-448
    80005a60:	f4040513          	addi	a0,s0,-192
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	178080e7          	jalr	376(ra) # 80004bdc <exec>
    80005a6c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a6e:	10048993          	addi	s3,s1,256
    80005a72:	6088                	ld	a0,0(s1)
    80005a74:	c911                	beqz	a0,80005a88 <sys_exec+0xfa>
    kfree(argv[i]);
    80005a76:	ffffb097          	auipc	ra,0xffffb
    80005a7a:	f9c080e7          	jalr	-100(ra) # 80000a12 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005a7e:	04a1                	addi	s1,s1,8
    80005a80:	ff3499e3          	bne	s1,s3,80005a72 <sys_exec+0xe4>
    80005a84:	a011                	j	80005a88 <sys_exec+0xfa>
  return -1;
    80005a86:	597d                	li	s2,-1
}
    80005a88:	854a                	mv	a0,s2
    80005a8a:	60be                	ld	ra,456(sp)
    80005a8c:	641e                	ld	s0,448(sp)
    80005a8e:	74fa                	ld	s1,440(sp)
    80005a90:	795a                	ld	s2,432(sp)
    80005a92:	79ba                	ld	s3,424(sp)
    80005a94:	7a1a                	ld	s4,416(sp)
    80005a96:	6afa                	ld	s5,408(sp)
    80005a98:	6179                	addi	sp,sp,464
    80005a9a:	8082                	ret

0000000080005a9c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005a9c:	7139                	addi	sp,sp,-64
    80005a9e:	fc06                	sd	ra,56(sp)
    80005aa0:	f822                	sd	s0,48(sp)
    80005aa2:	f426                	sd	s1,40(sp)
    80005aa4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005aa6:	ffffc097          	auipc	ra,0xffffc
    80005aaa:	f14080e7          	jalr	-236(ra) # 800019ba <myproc>
    80005aae:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005ab0:	fd840593          	addi	a1,s0,-40
    80005ab4:	4501                	li	a0,0
    80005ab6:	ffffd097          	auipc	ra,0xffffd
    80005aba:	fbe080e7          	jalr	-66(ra) # 80002a74 <argaddr>
    return -1;
    80005abe:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ac0:	0e054063          	bltz	a0,80005ba0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005ac4:	fc840593          	addi	a1,s0,-56
    80005ac8:	fd040513          	addi	a0,s0,-48
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	de0080e7          	jalr	-544(ra) # 800048ac <pipealloc>
    return -1;
    80005ad4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ad6:	0c054563          	bltz	a0,80005ba0 <sys_pipe+0x104>
  fd0 = -1;
    80005ada:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ade:	fd043503          	ld	a0,-48(s0)
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	50a080e7          	jalr	1290(ra) # 80004fec <fdalloc>
    80005aea:	fca42223          	sw	a0,-60(s0)
    80005aee:	08054c63          	bltz	a0,80005b86 <sys_pipe+0xea>
    80005af2:	fc843503          	ld	a0,-56(s0)
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	4f6080e7          	jalr	1270(ra) # 80004fec <fdalloc>
    80005afe:	fca42023          	sw	a0,-64(s0)
    80005b02:	06054863          	bltz	a0,80005b72 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b06:	4691                	li	a3,4
    80005b08:	fc440613          	addi	a2,s0,-60
    80005b0c:	fd843583          	ld	a1,-40(s0)
    80005b10:	68a8                	ld	a0,80(s1)
    80005b12:	ffffc097          	auipc	ra,0xffffc
    80005b16:	b9a080e7          	jalr	-1126(ra) # 800016ac <copyout>
    80005b1a:	02054063          	bltz	a0,80005b3a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b1e:	4691                	li	a3,4
    80005b20:	fc040613          	addi	a2,s0,-64
    80005b24:	fd843583          	ld	a1,-40(s0)
    80005b28:	0591                	addi	a1,a1,4
    80005b2a:	68a8                	ld	a0,80(s1)
    80005b2c:	ffffc097          	auipc	ra,0xffffc
    80005b30:	b80080e7          	jalr	-1152(ra) # 800016ac <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005b34:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b36:	06055563          	bgez	a0,80005ba0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005b3a:	fc442783          	lw	a5,-60(s0)
    80005b3e:	07e9                	addi	a5,a5,26
    80005b40:	078e                	slli	a5,a5,0x3
    80005b42:	97a6                	add	a5,a5,s1
    80005b44:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005b48:	fc042503          	lw	a0,-64(s0)
    80005b4c:	0569                	addi	a0,a0,26
    80005b4e:	050e                	slli	a0,a0,0x3
    80005b50:	9526                	add	a0,a0,s1
    80005b52:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b56:	fd043503          	ld	a0,-48(s0)
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	9fc080e7          	jalr	-1540(ra) # 80004556 <fileclose>
    fileclose(wf);
    80005b62:	fc843503          	ld	a0,-56(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	9f0080e7          	jalr	-1552(ra) # 80004556 <fileclose>
    return -1;
    80005b6e:	57fd                	li	a5,-1
    80005b70:	a805                	j	80005ba0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005b72:	fc442783          	lw	a5,-60(s0)
    80005b76:	0007c863          	bltz	a5,80005b86 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005b7a:	01a78513          	addi	a0,a5,26
    80005b7e:	050e                	slli	a0,a0,0x3
    80005b80:	9526                	add	a0,a0,s1
    80005b82:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005b86:	fd043503          	ld	a0,-48(s0)
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	9cc080e7          	jalr	-1588(ra) # 80004556 <fileclose>
    fileclose(wf);
    80005b92:	fc843503          	ld	a0,-56(s0)
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	9c0080e7          	jalr	-1600(ra) # 80004556 <fileclose>
    return -1;
    80005b9e:	57fd                	li	a5,-1
}
    80005ba0:	853e                	mv	a0,a5
    80005ba2:	70e2                	ld	ra,56(sp)
    80005ba4:	7442                	ld	s0,48(sp)
    80005ba6:	74a2                	ld	s1,40(sp)
    80005ba8:	6121                	addi	sp,sp,64
    80005baa:	8082                	ret
    80005bac:	0000                	unimp
	...

0000000080005bb0 <kernelvec>:
    80005bb0:	7111                	addi	sp,sp,-256
    80005bb2:	e006                	sd	ra,0(sp)
    80005bb4:	e40a                	sd	sp,8(sp)
    80005bb6:	e80e                	sd	gp,16(sp)
    80005bb8:	ec12                	sd	tp,24(sp)
    80005bba:	f016                	sd	t0,32(sp)
    80005bbc:	f41a                	sd	t1,40(sp)
    80005bbe:	f81e                	sd	t2,48(sp)
    80005bc0:	fc22                	sd	s0,56(sp)
    80005bc2:	e0a6                	sd	s1,64(sp)
    80005bc4:	e4aa                	sd	a0,72(sp)
    80005bc6:	e8ae                	sd	a1,80(sp)
    80005bc8:	ecb2                	sd	a2,88(sp)
    80005bca:	f0b6                	sd	a3,96(sp)
    80005bcc:	f4ba                	sd	a4,104(sp)
    80005bce:	f8be                	sd	a5,112(sp)
    80005bd0:	fcc2                	sd	a6,120(sp)
    80005bd2:	e146                	sd	a7,128(sp)
    80005bd4:	e54a                	sd	s2,136(sp)
    80005bd6:	e94e                	sd	s3,144(sp)
    80005bd8:	ed52                	sd	s4,152(sp)
    80005bda:	f156                	sd	s5,160(sp)
    80005bdc:	f55a                	sd	s6,168(sp)
    80005bde:	f95e                	sd	s7,176(sp)
    80005be0:	fd62                	sd	s8,184(sp)
    80005be2:	e1e6                	sd	s9,192(sp)
    80005be4:	e5ea                	sd	s10,200(sp)
    80005be6:	e9ee                	sd	s11,208(sp)
    80005be8:	edf2                	sd	t3,216(sp)
    80005bea:	f1f6                	sd	t4,224(sp)
    80005bec:	f5fa                	sd	t5,232(sp)
    80005bee:	f9fe                	sd	t6,240(sp)
    80005bf0:	c95fc0ef          	jal	ra,80002884 <kerneltrap>
    80005bf4:	6082                	ld	ra,0(sp)
    80005bf6:	6122                	ld	sp,8(sp)
    80005bf8:	61c2                	ld	gp,16(sp)
    80005bfa:	7282                	ld	t0,32(sp)
    80005bfc:	7322                	ld	t1,40(sp)
    80005bfe:	73c2                	ld	t2,48(sp)
    80005c00:	7462                	ld	s0,56(sp)
    80005c02:	6486                	ld	s1,64(sp)
    80005c04:	6526                	ld	a0,72(sp)
    80005c06:	65c6                	ld	a1,80(sp)
    80005c08:	6666                	ld	a2,88(sp)
    80005c0a:	7686                	ld	a3,96(sp)
    80005c0c:	7726                	ld	a4,104(sp)
    80005c0e:	77c6                	ld	a5,112(sp)
    80005c10:	7866                	ld	a6,120(sp)
    80005c12:	688a                	ld	a7,128(sp)
    80005c14:	692a                	ld	s2,136(sp)
    80005c16:	69ca                	ld	s3,144(sp)
    80005c18:	6a6a                	ld	s4,152(sp)
    80005c1a:	7a8a                	ld	s5,160(sp)
    80005c1c:	7b2a                	ld	s6,168(sp)
    80005c1e:	7bca                	ld	s7,176(sp)
    80005c20:	7c6a                	ld	s8,184(sp)
    80005c22:	6c8e                	ld	s9,192(sp)
    80005c24:	6d2e                	ld	s10,200(sp)
    80005c26:	6dce                	ld	s11,208(sp)
    80005c28:	6e6e                	ld	t3,216(sp)
    80005c2a:	7e8e                	ld	t4,224(sp)
    80005c2c:	7f2e                	ld	t5,232(sp)
    80005c2e:	7fce                	ld	t6,240(sp)
    80005c30:	6111                	addi	sp,sp,256
    80005c32:	10200073          	sret
    80005c36:	00000013          	nop
    80005c3a:	00000013          	nop
    80005c3e:	0001                	nop

0000000080005c40 <timervec>:
    80005c40:	34051573          	csrrw	a0,mscratch,a0
    80005c44:	e10c                	sd	a1,0(a0)
    80005c46:	e510                	sd	a2,8(a0)
    80005c48:	e914                	sd	a3,16(a0)
    80005c4a:	710c                	ld	a1,32(a0)
    80005c4c:	7510                	ld	a2,40(a0)
    80005c4e:	6194                	ld	a3,0(a1)
    80005c50:	96b2                	add	a3,a3,a2
    80005c52:	e194                	sd	a3,0(a1)
    80005c54:	4589                	li	a1,2
    80005c56:	14459073          	csrw	sip,a1
    80005c5a:	6914                	ld	a3,16(a0)
    80005c5c:	6510                	ld	a2,8(a0)
    80005c5e:	610c                	ld	a1,0(a0)
    80005c60:	34051573          	csrrw	a0,mscratch,a0
    80005c64:	30200073          	mret
	...

0000000080005c6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005c6a:	1141                	addi	sp,sp,-16
    80005c6c:	e422                	sd	s0,8(sp)
    80005c6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005c70:	0c0007b7          	lui	a5,0xc000
    80005c74:	4705                	li	a4,1
    80005c76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005c78:	c3d8                	sw	a4,4(a5)
}
    80005c7a:	6422                	ld	s0,8(sp)
    80005c7c:	0141                	addi	sp,sp,16
    80005c7e:	8082                	ret

0000000080005c80 <plicinithart>:

void
plicinithart(void)
{
    80005c80:	1141                	addi	sp,sp,-16
    80005c82:	e406                	sd	ra,8(sp)
    80005c84:	e022                	sd	s0,0(sp)
    80005c86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005c88:	ffffc097          	auipc	ra,0xffffc
    80005c8c:	d06080e7          	jalr	-762(ra) # 8000198e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005c90:	0085171b          	slliw	a4,a0,0x8
    80005c94:	0c0027b7          	lui	a5,0xc002
    80005c98:	97ba                	add	a5,a5,a4
    80005c9a:	40200713          	li	a4,1026
    80005c9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ca2:	00d5151b          	slliw	a0,a0,0xd
    80005ca6:	0c2017b7          	lui	a5,0xc201
    80005caa:	953e                	add	a0,a0,a5
    80005cac:	00052023          	sw	zero,0(a0)
}
    80005cb0:	60a2                	ld	ra,8(sp)
    80005cb2:	6402                	ld	s0,0(sp)
    80005cb4:	0141                	addi	sp,sp,16
    80005cb6:	8082                	ret

0000000080005cb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005cb8:	1141                	addi	sp,sp,-16
    80005cba:	e406                	sd	ra,8(sp)
    80005cbc:	e022                	sd	s0,0(sp)
    80005cbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cc0:	ffffc097          	auipc	ra,0xffffc
    80005cc4:	cce080e7          	jalr	-818(ra) # 8000198e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005cc8:	00d5179b          	slliw	a5,a0,0xd
    80005ccc:	0c201537          	lui	a0,0xc201
    80005cd0:	953e                	add	a0,a0,a5
  return irq;
}
    80005cd2:	4148                	lw	a0,4(a0)
    80005cd4:	60a2                	ld	ra,8(sp)
    80005cd6:	6402                	ld	s0,0(sp)
    80005cd8:	0141                	addi	sp,sp,16
    80005cda:	8082                	ret

0000000080005cdc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005cdc:	1101                	addi	sp,sp,-32
    80005cde:	ec06                	sd	ra,24(sp)
    80005ce0:	e822                	sd	s0,16(sp)
    80005ce2:	e426                	sd	s1,8(sp)
    80005ce4:	1000                	addi	s0,sp,32
    80005ce6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ce8:	ffffc097          	auipc	ra,0xffffc
    80005cec:	ca6080e7          	jalr	-858(ra) # 8000198e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005cf0:	00d5151b          	slliw	a0,a0,0xd
    80005cf4:	0c2017b7          	lui	a5,0xc201
    80005cf8:	97aa                	add	a5,a5,a0
    80005cfa:	c3c4                	sw	s1,4(a5)
}
    80005cfc:	60e2                	ld	ra,24(sp)
    80005cfe:	6442                	ld	s0,16(sp)
    80005d00:	64a2                	ld	s1,8(sp)
    80005d02:	6105                	addi	sp,sp,32
    80005d04:	8082                	ret

0000000080005d06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d06:	1141                	addi	sp,sp,-16
    80005d08:	e406                	sd	ra,8(sp)
    80005d0a:	e022                	sd	s0,0(sp)
    80005d0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d0e:	479d                	li	a5,7
    80005d10:	04a7cc63          	blt	a5,a0,80005d68 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d14:	0001d797          	auipc	a5,0x1d
    80005d18:	2ec78793          	addi	a5,a5,748 # 80023000 <disk>
    80005d1c:	00a78733          	add	a4,a5,a0
    80005d20:	6789                	lui	a5,0x2
    80005d22:	97ba                	add	a5,a5,a4
    80005d24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005d28:	eba1                	bnez	a5,80005d78 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005d2a:	00451713          	slli	a4,a0,0x4
    80005d2e:	0001f797          	auipc	a5,0x1f
    80005d32:	2d27b783          	ld	a5,722(a5) # 80025000 <disk+0x2000>
    80005d36:	97ba                	add	a5,a5,a4
    80005d38:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005d3c:	0001d797          	auipc	a5,0x1d
    80005d40:	2c478793          	addi	a5,a5,708 # 80023000 <disk>
    80005d44:	97aa                	add	a5,a5,a0
    80005d46:	6509                	lui	a0,0x2
    80005d48:	953e                	add	a0,a0,a5
    80005d4a:	4785                	li	a5,1
    80005d4c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005d50:	0001f517          	auipc	a0,0x1f
    80005d54:	2c850513          	addi	a0,a0,712 # 80025018 <disk+0x2018>
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	5d2080e7          	jalr	1490(ra) # 8000232a <wakeup>
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret
    panic("virtio_disk_intr 1");
    80005d68:	00003517          	auipc	a0,0x3
    80005d6c:	a2850513          	addi	a0,a0,-1496 # 80008790 <syscalls+0x348>
    80005d70:	ffffa097          	auipc	ra,0xffffa
    80005d74:	7d2080e7          	jalr	2002(ra) # 80000542 <panic>
    panic("virtio_disk_intr 2");
    80005d78:	00003517          	auipc	a0,0x3
    80005d7c:	a3050513          	addi	a0,a0,-1488 # 800087a8 <syscalls+0x360>
    80005d80:	ffffa097          	auipc	ra,0xffffa
    80005d84:	7c2080e7          	jalr	1986(ra) # 80000542 <panic>

0000000080005d88 <virtio_disk_init>:
{
    80005d88:	1101                	addi	sp,sp,-32
    80005d8a:	ec06                	sd	ra,24(sp)
    80005d8c:	e822                	sd	s0,16(sp)
    80005d8e:	e426                	sd	s1,8(sp)
    80005d90:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005d92:	00003597          	auipc	a1,0x3
    80005d96:	a2e58593          	addi	a1,a1,-1490 # 800087c0 <syscalls+0x378>
    80005d9a:	0001f517          	auipc	a0,0x1f
    80005d9e:	30e50513          	addi	a0,a0,782 # 800250a8 <disk+0x20a8>
    80005da2:	ffffb097          	auipc	ra,0xffffb
    80005da6:	dcc080e7          	jalr	-564(ra) # 80000b6e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005daa:	100017b7          	lui	a5,0x10001
    80005dae:	4398                	lw	a4,0(a5)
    80005db0:	2701                	sext.w	a4,a4
    80005db2:	747277b7          	lui	a5,0x74727
    80005db6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005dba:	0ef71163          	bne	a4,a5,80005e9c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dbe:	100017b7          	lui	a5,0x10001
    80005dc2:	43dc                	lw	a5,4(a5)
    80005dc4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005dc6:	4705                	li	a4,1
    80005dc8:	0ce79a63          	bne	a5,a4,80005e9c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005dcc:	100017b7          	lui	a5,0x10001
    80005dd0:	479c                	lw	a5,8(a5)
    80005dd2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005dd4:	4709                	li	a4,2
    80005dd6:	0ce79363          	bne	a5,a4,80005e9c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005dda:	100017b7          	lui	a5,0x10001
    80005dde:	47d8                	lw	a4,12(a5)
    80005de0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005de2:	554d47b7          	lui	a5,0x554d4
    80005de6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005dea:	0af71963          	bne	a4,a5,80005e9c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005dee:	100017b7          	lui	a5,0x10001
    80005df2:	4705                	li	a4,1
    80005df4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005df6:	470d                	li	a4,3
    80005df8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005dfa:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005dfc:	c7ffe737          	lui	a4,0xc7ffe
    80005e00:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e04:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e06:	2701                	sext.w	a4,a4
    80005e08:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e0a:	472d                	li	a4,11
    80005e0c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e0e:	473d                	li	a4,15
    80005e10:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e12:	6705                	lui	a4,0x1
    80005e14:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e16:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e1a:	5bdc                	lw	a5,52(a5)
    80005e1c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e1e:	c7d9                	beqz	a5,80005eac <virtio_disk_init+0x124>
  if(max < NUM)
    80005e20:	471d                	li	a4,7
    80005e22:	08f77d63          	bgeu	a4,a5,80005ebc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005e26:	100014b7          	lui	s1,0x10001
    80005e2a:	47a1                	li	a5,8
    80005e2c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005e2e:	6609                	lui	a2,0x2
    80005e30:	4581                	li	a1,0
    80005e32:	0001d517          	auipc	a0,0x1d
    80005e36:	1ce50513          	addi	a0,a0,462 # 80023000 <disk>
    80005e3a:	ffffb097          	auipc	ra,0xffffb
    80005e3e:	ec0080e7          	jalr	-320(ra) # 80000cfa <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005e42:	0001d717          	auipc	a4,0x1d
    80005e46:	1be70713          	addi	a4,a4,446 # 80023000 <disk>
    80005e4a:	00c75793          	srli	a5,a4,0xc
    80005e4e:	2781                	sext.w	a5,a5
    80005e50:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005e52:	0001f797          	auipc	a5,0x1f
    80005e56:	1ae78793          	addi	a5,a5,430 # 80025000 <disk+0x2000>
    80005e5a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005e5c:	0001d717          	auipc	a4,0x1d
    80005e60:	22470713          	addi	a4,a4,548 # 80023080 <disk+0x80>
    80005e64:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005e66:	0001e717          	auipc	a4,0x1e
    80005e6a:	19a70713          	addi	a4,a4,410 # 80024000 <disk+0x1000>
    80005e6e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005e70:	4705                	li	a4,1
    80005e72:	00e78c23          	sb	a4,24(a5)
    80005e76:	00e78ca3          	sb	a4,25(a5)
    80005e7a:	00e78d23          	sb	a4,26(a5)
    80005e7e:	00e78da3          	sb	a4,27(a5)
    80005e82:	00e78e23          	sb	a4,28(a5)
    80005e86:	00e78ea3          	sb	a4,29(a5)
    80005e8a:	00e78f23          	sb	a4,30(a5)
    80005e8e:	00e78fa3          	sb	a4,31(a5)
}
    80005e92:	60e2                	ld	ra,24(sp)
    80005e94:	6442                	ld	s0,16(sp)
    80005e96:	64a2                	ld	s1,8(sp)
    80005e98:	6105                	addi	sp,sp,32
    80005e9a:	8082                	ret
    panic("could not find virtio disk");
    80005e9c:	00003517          	auipc	a0,0x3
    80005ea0:	93450513          	addi	a0,a0,-1740 # 800087d0 <syscalls+0x388>
    80005ea4:	ffffa097          	auipc	ra,0xffffa
    80005ea8:	69e080e7          	jalr	1694(ra) # 80000542 <panic>
    panic("virtio disk has no queue 0");
    80005eac:	00003517          	auipc	a0,0x3
    80005eb0:	94450513          	addi	a0,a0,-1724 # 800087f0 <syscalls+0x3a8>
    80005eb4:	ffffa097          	auipc	ra,0xffffa
    80005eb8:	68e080e7          	jalr	1678(ra) # 80000542 <panic>
    panic("virtio disk max queue too short");
    80005ebc:	00003517          	auipc	a0,0x3
    80005ec0:	95450513          	addi	a0,a0,-1708 # 80008810 <syscalls+0x3c8>
    80005ec4:	ffffa097          	auipc	ra,0xffffa
    80005ec8:	67e080e7          	jalr	1662(ra) # 80000542 <panic>

0000000080005ecc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005ecc:	7175                	addi	sp,sp,-144
    80005ece:	e506                	sd	ra,136(sp)
    80005ed0:	e122                	sd	s0,128(sp)
    80005ed2:	fca6                	sd	s1,120(sp)
    80005ed4:	f8ca                	sd	s2,112(sp)
    80005ed6:	f4ce                	sd	s3,104(sp)
    80005ed8:	f0d2                	sd	s4,96(sp)
    80005eda:	ecd6                	sd	s5,88(sp)
    80005edc:	e8da                	sd	s6,80(sp)
    80005ede:	e4de                	sd	s7,72(sp)
    80005ee0:	e0e2                	sd	s8,64(sp)
    80005ee2:	fc66                	sd	s9,56(sp)
    80005ee4:	f86a                	sd	s10,48(sp)
    80005ee6:	f46e                	sd	s11,40(sp)
    80005ee8:	0900                	addi	s0,sp,144
    80005eea:	8aaa                	mv	s5,a0
    80005eec:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005eee:	00c52c83          	lw	s9,12(a0)
    80005ef2:	001c9c9b          	slliw	s9,s9,0x1
    80005ef6:	1c82                	slli	s9,s9,0x20
    80005ef8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005efc:	0001f517          	auipc	a0,0x1f
    80005f00:	1ac50513          	addi	a0,a0,428 # 800250a8 <disk+0x20a8>
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	cfa080e7          	jalr	-774(ra) # 80000bfe <acquire>
  for(int i = 0; i < 3; i++){
    80005f0c:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f0e:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005f10:	0001dc17          	auipc	s8,0x1d
    80005f14:	0f0c0c13          	addi	s8,s8,240 # 80023000 <disk>
    80005f18:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80005f1a:	4b0d                	li	s6,3
    80005f1c:	a0ad                	j	80005f86 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80005f1e:	00fc0733          	add	a4,s8,a5
    80005f22:	975e                	add	a4,a4,s7
    80005f24:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80005f28:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005f2a:	0207c563          	bltz	a5,80005f54 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005f2e:	2905                	addiw	s2,s2,1
    80005f30:	0611                	addi	a2,a2,4
    80005f32:	19690d63          	beq	s2,s6,800060cc <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80005f36:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005f38:	0001f717          	auipc	a4,0x1f
    80005f3c:	0e070713          	addi	a4,a4,224 # 80025018 <disk+0x2018>
    80005f40:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005f42:	00074683          	lbu	a3,0(a4)
    80005f46:	fee1                	bnez	a3,80005f1e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005f48:	2785                	addiw	a5,a5,1
    80005f4a:	0705                	addi	a4,a4,1
    80005f4c:	fe979be3          	bne	a5,s1,80005f42 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005f50:	57fd                	li	a5,-1
    80005f52:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005f54:	01205d63          	blez	s2,80005f6e <virtio_disk_rw+0xa2>
    80005f58:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80005f5a:	000a2503          	lw	a0,0(s4)
    80005f5e:	00000097          	auipc	ra,0x0
    80005f62:	da8080e7          	jalr	-600(ra) # 80005d06 <free_desc>
      for(int j = 0; j < i; j++)
    80005f66:	2d85                	addiw	s11,s11,1
    80005f68:	0a11                	addi	s4,s4,4
    80005f6a:	ffb918e3          	bne	s2,s11,80005f5a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005f6e:	0001f597          	auipc	a1,0x1f
    80005f72:	13a58593          	addi	a1,a1,314 # 800250a8 <disk+0x20a8>
    80005f76:	0001f517          	auipc	a0,0x1f
    80005f7a:	0a250513          	addi	a0,a0,162 # 80025018 <disk+0x2018>
    80005f7e:	ffffc097          	auipc	ra,0xffffc
    80005f82:	22c080e7          	jalr	556(ra) # 800021aa <sleep>
  for(int i = 0; i < 3; i++){
    80005f86:	f8040a13          	addi	s4,s0,-128
{
    80005f8a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80005f8c:	894e                	mv	s2,s3
    80005f8e:	b765                	j	80005f36 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80005f90:	0001f717          	auipc	a4,0x1f
    80005f94:	07073703          	ld	a4,112(a4) # 80025000 <disk+0x2000>
    80005f98:	973e                	add	a4,a4,a5
    80005f9a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005f9e:	0001d517          	auipc	a0,0x1d
    80005fa2:	06250513          	addi	a0,a0,98 # 80023000 <disk>
    80005fa6:	0001f717          	auipc	a4,0x1f
    80005faa:	05a70713          	addi	a4,a4,90 # 80025000 <disk+0x2000>
    80005fae:	6314                	ld	a3,0(a4)
    80005fb0:	96be                	add	a3,a3,a5
    80005fb2:	00c6d603          	lhu	a2,12(a3)
    80005fb6:	00166613          	ori	a2,a2,1
    80005fba:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80005fbe:	f8842683          	lw	a3,-120(s0)
    80005fc2:	6310                	ld	a2,0(a4)
    80005fc4:	97b2                	add	a5,a5,a2
    80005fc6:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    80005fca:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    80005fce:	0612                	slli	a2,a2,0x4
    80005fd0:	962a                	add	a2,a2,a0
    80005fd2:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005fd6:	00469793          	slli	a5,a3,0x4
    80005fda:	630c                	ld	a1,0(a4)
    80005fdc:	95be                	add	a1,a1,a5
    80005fde:	6689                	lui	a3,0x2
    80005fe0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    80005fe4:	96ca                	add	a3,a3,s2
    80005fe6:	96aa                	add	a3,a3,a0
    80005fe8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    80005fea:	6314                	ld	a3,0(a4)
    80005fec:	96be                	add	a3,a3,a5
    80005fee:	4585                	li	a1,1
    80005ff0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005ff2:	6314                	ld	a3,0(a4)
    80005ff4:	96be                	add	a3,a3,a5
    80005ff6:	4509                	li	a0,2
    80005ff8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80005ffc:	6314                	ld	a3,0(a4)
    80005ffe:	97b6                	add	a5,a5,a3
    80006000:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006004:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006008:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000600c:	6714                	ld	a3,8(a4)
    8000600e:	0026d783          	lhu	a5,2(a3)
    80006012:	8b9d                	andi	a5,a5,7
    80006014:	0789                	addi	a5,a5,2
    80006016:	0786                	slli	a5,a5,0x1
    80006018:	97b6                	add	a5,a5,a3
    8000601a:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    8000601e:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006022:	6718                	ld	a4,8(a4)
    80006024:	00275783          	lhu	a5,2(a4)
    80006028:	2785                	addiw	a5,a5,1
    8000602a:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006036:	004aa783          	lw	a5,4(s5)
    8000603a:	02b79163          	bne	a5,a1,8000605c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    8000603e:	0001f917          	auipc	s2,0x1f
    80006042:	06a90913          	addi	s2,s2,106 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006046:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006048:	85ca                	mv	a1,s2
    8000604a:	8556                	mv	a0,s5
    8000604c:	ffffc097          	auipc	ra,0xffffc
    80006050:	15e080e7          	jalr	350(ra) # 800021aa <sleep>
  while(b->disk == 1) {
    80006054:	004aa783          	lw	a5,4(s5)
    80006058:	fe9788e3          	beq	a5,s1,80006048 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000605c:	f8042483          	lw	s1,-128(s0)
    80006060:	20048793          	addi	a5,s1,512
    80006064:	00479713          	slli	a4,a5,0x4
    80006068:	0001d797          	auipc	a5,0x1d
    8000606c:	f9878793          	addi	a5,a5,-104 # 80023000 <disk>
    80006070:	97ba                	add	a5,a5,a4
    80006072:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006076:	0001f917          	auipc	s2,0x1f
    8000607a:	f8a90913          	addi	s2,s2,-118 # 80025000 <disk+0x2000>
    8000607e:	a019                	j	80006084 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006080:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006084:	8526                	mv	a0,s1
    80006086:	00000097          	auipc	ra,0x0
    8000608a:	c80080e7          	jalr	-896(ra) # 80005d06 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000608e:	0492                	slli	s1,s1,0x4
    80006090:	00093783          	ld	a5,0(s2)
    80006094:	94be                	add	s1,s1,a5
    80006096:	00c4d783          	lhu	a5,12(s1)
    8000609a:	8b85                	andi	a5,a5,1
    8000609c:	f3f5                	bnez	a5,80006080 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000609e:	0001f517          	auipc	a0,0x1f
    800060a2:	00a50513          	addi	a0,a0,10 # 800250a8 <disk+0x20a8>
    800060a6:	ffffb097          	auipc	ra,0xffffb
    800060aa:	c0c080e7          	jalr	-1012(ra) # 80000cb2 <release>
}
    800060ae:	60aa                	ld	ra,136(sp)
    800060b0:	640a                	ld	s0,128(sp)
    800060b2:	74e6                	ld	s1,120(sp)
    800060b4:	7946                	ld	s2,112(sp)
    800060b6:	79a6                	ld	s3,104(sp)
    800060b8:	7a06                	ld	s4,96(sp)
    800060ba:	6ae6                	ld	s5,88(sp)
    800060bc:	6b46                	ld	s6,80(sp)
    800060be:	6ba6                	ld	s7,72(sp)
    800060c0:	6c06                	ld	s8,64(sp)
    800060c2:	7ce2                	ld	s9,56(sp)
    800060c4:	7d42                	ld	s10,48(sp)
    800060c6:	7da2                	ld	s11,40(sp)
    800060c8:	6149                	addi	sp,sp,144
    800060ca:	8082                	ret
  if(write)
    800060cc:	01a037b3          	snez	a5,s10
    800060d0:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    800060d4:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    800060d8:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060dc:	f8042483          	lw	s1,-128(s0)
    800060e0:	00449913          	slli	s2,s1,0x4
    800060e4:	0001f997          	auipc	s3,0x1f
    800060e8:	f1c98993          	addi	s3,s3,-228 # 80025000 <disk+0x2000>
    800060ec:	0009ba03          	ld	s4,0(s3)
    800060f0:	9a4a                	add	s4,s4,s2
    800060f2:	f7040513          	addi	a0,s0,-144
    800060f6:	ffffb097          	auipc	ra,0xffffb
    800060fa:	fc4080e7          	jalr	-60(ra) # 800010ba <kvmpa>
    800060fe:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    80006102:	0009b783          	ld	a5,0(s3)
    80006106:	97ca                	add	a5,a5,s2
    80006108:	4741                	li	a4,16
    8000610a:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000610c:	0009b783          	ld	a5,0(s3)
    80006110:	97ca                	add	a5,a5,s2
    80006112:	4705                	li	a4,1
    80006114:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006118:	f8442783          	lw	a5,-124(s0)
    8000611c:	0009b703          	ld	a4,0(s3)
    80006120:	974a                	add	a4,a4,s2
    80006122:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006126:	0792                	slli	a5,a5,0x4
    80006128:	0009b703          	ld	a4,0(s3)
    8000612c:	973e                	add	a4,a4,a5
    8000612e:	058a8693          	addi	a3,s5,88
    80006132:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    80006134:	0009b703          	ld	a4,0(s3)
    80006138:	973e                	add	a4,a4,a5
    8000613a:	40000693          	li	a3,1024
    8000613e:	c714                	sw	a3,8(a4)
  if(write)
    80006140:	e40d18e3          	bnez	s10,80005f90 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006144:	0001f717          	auipc	a4,0x1f
    80006148:	ebc73703          	ld	a4,-324(a4) # 80025000 <disk+0x2000>
    8000614c:	973e                	add	a4,a4,a5
    8000614e:	4689                	li	a3,2
    80006150:	00d71623          	sh	a3,12(a4)
    80006154:	b5a9                	j	80005f9e <virtio_disk_rw+0xd2>

0000000080006156 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006156:	1101                	addi	sp,sp,-32
    80006158:	ec06                	sd	ra,24(sp)
    8000615a:	e822                	sd	s0,16(sp)
    8000615c:	e426                	sd	s1,8(sp)
    8000615e:	e04a                	sd	s2,0(sp)
    80006160:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006162:	0001f517          	auipc	a0,0x1f
    80006166:	f4650513          	addi	a0,a0,-186 # 800250a8 <disk+0x20a8>
    8000616a:	ffffb097          	auipc	ra,0xffffb
    8000616e:	a94080e7          	jalr	-1388(ra) # 80000bfe <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006172:	0001f717          	auipc	a4,0x1f
    80006176:	e8e70713          	addi	a4,a4,-370 # 80025000 <disk+0x2000>
    8000617a:	02075783          	lhu	a5,32(a4)
    8000617e:	6b18                	ld	a4,16(a4)
    80006180:	00275683          	lhu	a3,2(a4)
    80006184:	8ebd                	xor	a3,a3,a5
    80006186:	8a9d                	andi	a3,a3,7
    80006188:	cab9                	beqz	a3,800061de <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000618a:	0001d917          	auipc	s2,0x1d
    8000618e:	e7690913          	addi	s2,s2,-394 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006192:	0001f497          	auipc	s1,0x1f
    80006196:	e6e48493          	addi	s1,s1,-402 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000619a:	078e                	slli	a5,a5,0x3
    8000619c:	97ba                	add	a5,a5,a4
    8000619e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800061a0:	20078713          	addi	a4,a5,512
    800061a4:	0712                	slli	a4,a4,0x4
    800061a6:	974a                	add	a4,a4,s2
    800061a8:	03074703          	lbu	a4,48(a4)
    800061ac:	ef21                	bnez	a4,80006204 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800061ae:	20078793          	addi	a5,a5,512
    800061b2:	0792                	slli	a5,a5,0x4
    800061b4:	97ca                	add	a5,a5,s2
    800061b6:	7798                	ld	a4,40(a5)
    800061b8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800061bc:	7788                	ld	a0,40(a5)
    800061be:	ffffc097          	auipc	ra,0xffffc
    800061c2:	16c080e7          	jalr	364(ra) # 8000232a <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800061c6:	0204d783          	lhu	a5,32(s1)
    800061ca:	2785                	addiw	a5,a5,1
    800061cc:	8b9d                	andi	a5,a5,7
    800061ce:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800061d2:	6898                	ld	a4,16(s1)
    800061d4:	00275683          	lhu	a3,2(a4)
    800061d8:	8a9d                	andi	a3,a3,7
    800061da:	fcf690e3          	bne	a3,a5,8000619a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800061de:	10001737          	lui	a4,0x10001
    800061e2:	533c                	lw	a5,96(a4)
    800061e4:	8b8d                	andi	a5,a5,3
    800061e6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800061e8:	0001f517          	auipc	a0,0x1f
    800061ec:	ec050513          	addi	a0,a0,-320 # 800250a8 <disk+0x20a8>
    800061f0:	ffffb097          	auipc	ra,0xffffb
    800061f4:	ac2080e7          	jalr	-1342(ra) # 80000cb2 <release>
}
    800061f8:	60e2                	ld	ra,24(sp)
    800061fa:	6442                	ld	s0,16(sp)
    800061fc:	64a2                	ld	s1,8(sp)
    800061fe:	6902                	ld	s2,0(sp)
    80006200:	6105                	addi	sp,sp,32
    80006202:	8082                	ret
      panic("virtio_disk_intr status");
    80006204:	00002517          	auipc	a0,0x2
    80006208:	62c50513          	addi	a0,a0,1580 # 80008830 <syscalls+0x3e8>
    8000620c:	ffffa097          	auipc	ra,0xffffa
    80006210:	336080e7          	jalr	822(ra) # 80000542 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
