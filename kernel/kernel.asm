
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
    80000016:	06e000ef          	jal	ra,80000084 <start>

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
  int interval = 10000; // cycles; about 1ms in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	6709                	lui	a4,0x2
    8000003a:	71070713          	addi	a4,a4,1808 # 2710 <_entry-0x7fffd8f0>
    8000003e:	963a                	add	a2,a2,a4
    80000040:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000042:	0057979b          	slliw	a5,a5,0x5
    80000046:	078e                	slli	a5,a5,0x3
    80000048:	00009617          	auipc	a2,0x9
    8000004c:	fe860613          	addi	a2,a2,-24 # 80009030 <mscratch0>
    80000050:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000052:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000054:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000056:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005a:	00006797          	auipc	a5,0x6
    8000005e:	ea678793          	addi	a5,a5,-346 # 80005f00 <timervec>
    80000062:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000066:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006a:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000006e:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000072:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000076:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007a:	30479073          	csrw	mie,a5
}
    8000007e:	6422                	ld	s0,8(sp)
    80000080:	0141                	addi	sp,sp,16
    80000082:	8082                	ret

0000000080000084 <start>:
{
    80000084:	1141                	addi	sp,sp,-16
    80000086:	e406                	sd	ra,8(sp)
    80000088:	e022                	sd	s0,0(sp)
    8000008a:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008c:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000090:	7779                	lui	a4,0xffffe
    80000092:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000096:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000098:	6705                	lui	a4,0x1
    8000009a:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000009e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a0:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a4:	00001797          	auipc	a5,0x1
    800000a8:	e0278793          	addi	a5,a5,-510 # 80000ea6 <main>
    800000ac:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b0:	4781                	li	a5,0
    800000b2:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b6:	67c1                	lui	a5,0x10
    800000b8:	17fd                	addi	a5,a5,-1
    800000ba:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000be:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c2:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c6:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000ca:	10479073          	csrw	sie,a5
  timerinit();
    800000ce:	00000097          	auipc	ra,0x0
    800000d2:	f4e080e7          	jalr	-178(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d6:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000da:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000dc:	823e                	mv	tp,a5
  asm volatile("mret");
    800000de:	30200073          	mret
}
    800000e2:	60a2                	ld	ra,8(sp)
    800000e4:	6402                	ld	s0,0(sp)
    800000e6:	0141                	addi	sp,sp,16
    800000e8:	8082                	ret

00000000800000ea <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ea:	715d                	addi	sp,sp,-80
    800000ec:	e486                	sd	ra,72(sp)
    800000ee:	e0a2                	sd	s0,64(sp)
    800000f0:	fc26                	sd	s1,56(sp)
    800000f2:	f84a                	sd	s2,48(sp)
    800000f4:	f44e                	sd	s3,40(sp)
    800000f6:	f052                	sd	s4,32(sp)
    800000f8:	ec56                	sd	s5,24(sp)
    800000fa:	0880                	addi	s0,sp,80
    800000fc:	8a2a                	mv	s4,a0
    800000fe:	84ae                	mv	s1,a1
    80000100:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000102:	00011517          	auipc	a0,0x11
    80000106:	72e50513          	addi	a0,a0,1838 # 80011830 <cons>
    8000010a:	00001097          	auipc	ra,0x1
    8000010e:	af2080e7          	jalr	-1294(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80000112:	05305b63          	blez	s3,80000168 <consolewrite+0x7e>
    80000116:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000118:	5afd                	li	s5,-1
    8000011a:	4685                	li	a3,1
    8000011c:	8626                	mv	a2,s1
    8000011e:	85d2                	mv	a1,s4
    80000120:	fbf40513          	addi	a0,s0,-65
    80000124:	00002097          	auipc	ra,0x2
    80000128:	6d0080e7          	jalr	1744(ra) # 800027f4 <either_copyin>
    8000012c:	01550c63          	beq	a0,s5,80000144 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000130:	fbf44503          	lbu	a0,-65(s0)
    80000134:	00000097          	auipc	ra,0x0
    80000138:	796080e7          	jalr	1942(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    8000013c:	2905                	addiw	s2,s2,1
    8000013e:	0485                	addi	s1,s1,1
    80000140:	fd299de3          	bne	s3,s2,8000011a <consolewrite+0x30>
  }
  release(&cons.lock);
    80000144:	00011517          	auipc	a0,0x11
    80000148:	6ec50513          	addi	a0,a0,1772 # 80011830 <cons>
    8000014c:	00001097          	auipc	ra,0x1
    80000150:	b64080e7          	jalr	-1180(ra) # 80000cb0 <release>

  return i;
}
    80000154:	854a                	mv	a0,s2
    80000156:	60a6                	ld	ra,72(sp)
    80000158:	6406                	ld	s0,64(sp)
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	7942                	ld	s2,48(sp)
    8000015e:	79a2                	ld	s3,40(sp)
    80000160:	7a02                	ld	s4,32(sp)
    80000162:	6ae2                	ld	s5,24(sp)
    80000164:	6161                	addi	sp,sp,80
    80000166:	8082                	ret
  for(i = 0; i < n; i++){
    80000168:	4901                	li	s2,0
    8000016a:	bfe9                	j	80000144 <consolewrite+0x5a>

000000008000016c <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016c:	7159                	addi	sp,sp,-112
    8000016e:	f486                	sd	ra,104(sp)
    80000170:	f0a2                	sd	s0,96(sp)
    80000172:	eca6                	sd	s1,88(sp)
    80000174:	e8ca                	sd	s2,80(sp)
    80000176:	e4ce                	sd	s3,72(sp)
    80000178:	e0d2                	sd	s4,64(sp)
    8000017a:	fc56                	sd	s5,56(sp)
    8000017c:	f85a                	sd	s6,48(sp)
    8000017e:	f45e                	sd	s7,40(sp)
    80000180:	f062                	sd	s8,32(sp)
    80000182:	ec66                	sd	s9,24(sp)
    80000184:	e86a                	sd	s10,16(sp)
    80000186:	1880                	addi	s0,sp,112
    80000188:	8aaa                	mv	s5,a0
    8000018a:	8a2e                	mv	s4,a1
    8000018c:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000018e:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000192:	00011517          	auipc	a0,0x11
    80000196:	69e50513          	addi	a0,a0,1694 # 80011830 <cons>
    8000019a:	00001097          	auipc	ra,0x1
    8000019e:	a62080e7          	jalr	-1438(ra) # 80000bfc <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a2:	00011497          	auipc	s1,0x11
    800001a6:	68e48493          	addi	s1,s1,1678 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001aa:	00011917          	auipc	s2,0x11
    800001ae:	71e90913          	addi	s2,s2,1822 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b2:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b4:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b6:	4ca9                	li	s9,10
  while(n > 0){
    800001b8:	07305863          	blez	s3,80000228 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001bc:	0984a783          	lw	a5,152(s1)
    800001c0:	09c4a703          	lw	a4,156(s1)
    800001c4:	02f71463          	bne	a4,a5,800001ec <consoleread+0x80>
      if(myproc()->killed){
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	926080e7          	jalr	-1754(ra) # 80001aee <myproc>
    800001d0:	591c                	lw	a5,48(a0)
    800001d2:	e7b5                	bnez	a5,8000023e <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001d4:	85a6                	mv	a1,s1
    800001d6:	854a                	mv	a0,s2
    800001d8:	00002097          	auipc	ra,0x2
    800001dc:	350080e7          	jalr	848(ra) # 80002528 <sleep>
    while(cons.r == cons.w){
    800001e0:	0984a783          	lw	a5,152(s1)
    800001e4:	09c4a703          	lw	a4,156(s1)
    800001e8:	fef700e3          	beq	a4,a5,800001c8 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ec:	0017871b          	addiw	a4,a5,1
    800001f0:	08e4ac23          	sw	a4,152(s1)
    800001f4:	07f7f713          	andi	a4,a5,127
    800001f8:	9726                	add	a4,a4,s1
    800001fa:	01874703          	lbu	a4,24(a4)
    800001fe:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000202:	077d0563          	beq	s10,s7,8000026c <consoleread+0x100>
    cbuf = c;
    80000206:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	f9f40613          	addi	a2,s0,-97
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	58a080e7          	jalr	1418(ra) # 8000279e <either_copyout>
    8000021c:	01850663          	beq	a0,s8,80000228 <consoleread+0xbc>
    dst++;
    80000220:	0a05                	addi	s4,s4,1
    --n;
    80000222:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000224:	f99d1ae3          	bne	s10,s9,800001b8 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	60850513          	addi	a0,a0,1544 # 80011830 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a80080e7          	jalr	-1408(ra) # 80000cb0 <release>

  return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xe4>
        release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	5f250513          	addi	a0,a0,1522 # 80011830 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	a6a080e7          	jalr	-1430(ra) # 80000cb0 <release>
        return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	70a6                	ld	ra,104(sp)
    80000252:	7406                	ld	s0,96(sp)
    80000254:	64e6                	ld	s1,88(sp)
    80000256:	6946                	ld	s2,80(sp)
    80000258:	69a6                	ld	s3,72(sp)
    8000025a:	6a06                	ld	s4,64(sp)
    8000025c:	7ae2                	ld	s5,56(sp)
    8000025e:	7b42                	ld	s6,48(sp)
    80000260:	7ba2                	ld	s7,40(sp)
    80000262:	7c02                	ld	s8,32(sp)
    80000264:	6ce2                	ld	s9,24(sp)
    80000266:	6d42                	ld	s10,16(sp)
    80000268:	6165                	addi	sp,sp,112
    8000026a:	8082                	ret
      if(n < target){
    8000026c:	0009871b          	sext.w	a4,s3
    80000270:	fb677ce3          	bgeu	a4,s6,80000228 <consoleread+0xbc>
        cons.r--;
    80000274:	00011717          	auipc	a4,0x11
    80000278:	64f72a23          	sw	a5,1620(a4) # 800118c8 <cons+0x98>
    8000027c:	b775                	j	80000228 <consoleread+0xbc>

000000008000027e <consputc>:
{
    8000027e:	1141                	addi	sp,sp,-16
    80000280:	e406                	sd	ra,8(sp)
    80000282:	e022                	sd	s0,0(sp)
    80000284:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000286:	10000793          	li	a5,256
    8000028a:	00f50a63          	beq	a0,a5,8000029e <consputc+0x20>
    uartputc_sync(c);
    8000028e:	00000097          	auipc	ra,0x0
    80000292:	55e080e7          	jalr	1374(ra) # 800007ec <uartputc_sync>
}
    80000296:	60a2                	ld	ra,8(sp)
    80000298:	6402                	ld	s0,0(sp)
    8000029a:	0141                	addi	sp,sp,16
    8000029c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	54c080e7          	jalr	1356(ra) # 800007ec <uartputc_sync>
    800002a8:	02000513          	li	a0,32
    800002ac:	00000097          	auipc	ra,0x0
    800002b0:	540080e7          	jalr	1344(ra) # 800007ec <uartputc_sync>
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	536080e7          	jalr	1334(ra) # 800007ec <uartputc_sync>
    800002be:	bfe1                	j	80000296 <consputc+0x18>

00000000800002c0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c0:	1101                	addi	sp,sp,-32
    800002c2:	ec06                	sd	ra,24(sp)
    800002c4:	e822                	sd	s0,16(sp)
    800002c6:	e426                	sd	s1,8(sp)
    800002c8:	e04a                	sd	s2,0(sp)
    800002ca:	1000                	addi	s0,sp,32
    800002cc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002ce:	00011517          	auipc	a0,0x11
    800002d2:	56250513          	addi	a0,a0,1378 # 80011830 <cons>
    800002d6:	00001097          	auipc	ra,0x1
    800002da:	926080e7          	jalr	-1754(ra) # 80000bfc <acquire>

  switch(c){
    800002de:	47d5                	li	a5,21
    800002e0:	0af48663          	beq	s1,a5,8000038c <consoleintr+0xcc>
    800002e4:	0297ca63          	blt	a5,s1,80000318 <consoleintr+0x58>
    800002e8:	47a1                	li	a5,8
    800002ea:	0ef48763          	beq	s1,a5,800003d8 <consoleintr+0x118>
    800002ee:	47c1                	li	a5,16
    800002f0:	10f49a63          	bne	s1,a5,80000404 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f4:	00002097          	auipc	ra,0x2
    800002f8:	556080e7          	jalr	1366(ra) # 8000284a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fc:	00011517          	auipc	a0,0x11
    80000300:	53450513          	addi	a0,a0,1332 # 80011830 <cons>
    80000304:	00001097          	auipc	ra,0x1
    80000308:	9ac080e7          	jalr	-1620(ra) # 80000cb0 <release>
}
    8000030c:	60e2                	ld	ra,24(sp)
    8000030e:	6442                	ld	s0,16(sp)
    80000310:	64a2                	ld	s1,8(sp)
    80000312:	6902                	ld	s2,0(sp)
    80000314:	6105                	addi	sp,sp,32
    80000316:	8082                	ret
  switch(c){
    80000318:	07f00793          	li	a5,127
    8000031c:	0af48e63          	beq	s1,a5,800003d8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000320:	00011717          	auipc	a4,0x11
    80000324:	51070713          	addi	a4,a4,1296 # 80011830 <cons>
    80000328:	0a072783          	lw	a5,160(a4)
    8000032c:	09872703          	lw	a4,152(a4)
    80000330:	9f99                	subw	a5,a5,a4
    80000332:	07f00713          	li	a4,127
    80000336:	fcf763e3          	bltu	a4,a5,800002fc <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033a:	47b5                	li	a5,13
    8000033c:	0cf48763          	beq	s1,a5,8000040a <consoleintr+0x14a>
      consputc(c);
    80000340:	8526                	mv	a0,s1
    80000342:	00000097          	auipc	ra,0x0
    80000346:	f3c080e7          	jalr	-196(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034a:	00011797          	auipc	a5,0x11
    8000034e:	4e678793          	addi	a5,a5,1254 # 80011830 <cons>
    80000352:	0a07a703          	lw	a4,160(a5)
    80000356:	0017069b          	addiw	a3,a4,1
    8000035a:	0006861b          	sext.w	a2,a3
    8000035e:	0ad7a023          	sw	a3,160(a5)
    80000362:	07f77713          	andi	a4,a4,127
    80000366:	97ba                	add	a5,a5,a4
    80000368:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036c:	47a9                	li	a5,10
    8000036e:	0cf48563          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000372:	4791                	li	a5,4
    80000374:	0cf48263          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000378:	00011797          	auipc	a5,0x11
    8000037c:	5507a783          	lw	a5,1360(a5) # 800118c8 <cons+0x98>
    80000380:	0807879b          	addiw	a5,a5,128
    80000384:	f6f61ce3          	bne	a2,a5,800002fc <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000388:	863e                	mv	a2,a5
    8000038a:	a07d                	j	80000438 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038c:	00011717          	auipc	a4,0x11
    80000390:	4a470713          	addi	a4,a4,1188 # 80011830 <cons>
    80000394:	0a072783          	lw	a5,160(a4)
    80000398:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039c:	00011497          	auipc	s1,0x11
    800003a0:	49448493          	addi	s1,s1,1172 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a4:	4929                	li	s2,10
    800003a6:	f4f70be3          	beq	a4,a5,800002fc <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003aa:	37fd                	addiw	a5,a5,-1
    800003ac:	07f7f713          	andi	a4,a5,127
    800003b0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b2:	01874703          	lbu	a4,24(a4)
    800003b6:	f52703e3          	beq	a4,s2,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ba:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003be:	10000513          	li	a0,256
    800003c2:	00000097          	auipc	ra,0x0
    800003c6:	ebc080e7          	jalr	-324(ra) # 8000027e <consputc>
    while(cons.e != cons.w &&
    800003ca:	0a04a783          	lw	a5,160(s1)
    800003ce:	09c4a703          	lw	a4,156(s1)
    800003d2:	fcf71ce3          	bne	a4,a5,800003aa <consoleintr+0xea>
    800003d6:	b71d                	j	800002fc <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	45870713          	addi	a4,a4,1112 # 80011830 <cons>
    800003e0:	0a072783          	lw	a5,160(a4)
    800003e4:	09c72703          	lw	a4,156(a4)
    800003e8:	f0f70ae3          	beq	a4,a5,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ec:	37fd                	addiw	a5,a5,-1
    800003ee:	00011717          	auipc	a4,0x11
    800003f2:	4ef72123          	sw	a5,1250(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f6:	10000513          	li	a0,256
    800003fa:	00000097          	auipc	ra,0x0
    800003fe:	e84080e7          	jalr	-380(ra) # 8000027e <consputc>
    80000402:	bded                	j	800002fc <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000404:	ee048ce3          	beqz	s1,800002fc <consoleintr+0x3c>
    80000408:	bf21                	j	80000320 <consoleintr+0x60>
      consputc(c);
    8000040a:	4529                	li	a0,10
    8000040c:	00000097          	auipc	ra,0x0
    80000410:	e72080e7          	jalr	-398(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000414:	00011797          	auipc	a5,0x11
    80000418:	41c78793          	addi	a5,a5,1052 # 80011830 <cons>
    8000041c:	0a07a703          	lw	a4,160(a5)
    80000420:	0017069b          	addiw	a3,a4,1
    80000424:	0006861b          	sext.w	a2,a3
    80000428:	0ad7a023          	sw	a3,160(a5)
    8000042c:	07f77713          	andi	a4,a4,127
    80000430:	97ba                	add	a5,a5,a4
    80000432:	4729                	li	a4,10
    80000434:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000438:	00011797          	auipc	a5,0x11
    8000043c:	48c7aa23          	sw	a2,1172(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000440:	00011517          	auipc	a0,0x11
    80000444:	48850513          	addi	a0,a0,1160 # 800118c8 <cons+0x98>
    80000448:	00002097          	auipc	ra,0x2
    8000044c:	26c080e7          	jalr	620(ra) # 800026b4 <wakeup>
    80000450:	b575                	j	800002fc <consoleintr+0x3c>

0000000080000452 <consoleinit>:

void
consoleinit(void)
{
    80000452:	1141                	addi	sp,sp,-16
    80000454:	e406                	sd	ra,8(sp)
    80000456:	e022                	sd	s0,0(sp)
    80000458:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045a:	00008597          	auipc	a1,0x8
    8000045e:	bb658593          	addi	a1,a1,-1098 # 80008010 <etext+0x10>
    80000462:	00011517          	auipc	a0,0x11
    80000466:	3ce50513          	addi	a0,a0,974 # 80011830 <cons>
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	702080e7          	jalr	1794(ra) # 80000b6c <initlock>

  uartinit();
    80000472:	00000097          	auipc	ra,0x0
    80000476:	32a080e7          	jalr	810(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047a:	00022797          	auipc	a5,0x22
    8000047e:	23678793          	addi	a5,a5,566 # 800226b0 <devsw>
    80000482:	00000717          	auipc	a4,0x0
    80000486:	cea70713          	addi	a4,a4,-790 # 8000016c <consoleread>
    8000048a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048c:	00000717          	auipc	a4,0x0
    80000490:	c5e70713          	addi	a4,a4,-930 # 800000ea <consolewrite>
    80000494:	ef98                	sd	a4,24(a5)
}
    80000496:	60a2                	ld	ra,8(sp)
    80000498:	6402                	ld	s0,0(sp)
    8000049a:	0141                	addi	sp,sp,16
    8000049c:	8082                	ret

000000008000049e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049e:	7179                	addi	sp,sp,-48
    800004a0:	f406                	sd	ra,40(sp)
    800004a2:	f022                	sd	s0,32(sp)
    800004a4:	ec26                	sd	s1,24(sp)
    800004a6:	e84a                	sd	s2,16(sp)
    800004a8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004aa:	c219                	beqz	a2,800004b0 <printint+0x12>
    800004ac:	08054663          	bltz	a0,80000538 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b0:	2501                	sext.w	a0,a0
    800004b2:	4881                	li	a7,0
    800004b4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ba:	2581                	sext.w	a1,a1
    800004bc:	00008617          	auipc	a2,0x8
    800004c0:	b8460613          	addi	a2,a2,-1148 # 80008040 <digits>
    800004c4:	883a                	mv	a6,a4
    800004c6:	2705                	addiw	a4,a4,1
    800004c8:	02b577bb          	remuw	a5,a0,a1
    800004cc:	1782                	slli	a5,a5,0x20
    800004ce:	9381                	srli	a5,a5,0x20
    800004d0:	97b2                	add	a5,a5,a2
    800004d2:	0007c783          	lbu	a5,0(a5)
    800004d6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004da:	0005079b          	sext.w	a5,a0
    800004de:	02b5553b          	divuw	a0,a0,a1
    800004e2:	0685                	addi	a3,a3,1
    800004e4:	feb7f0e3          	bgeu	a5,a1,800004c4 <printint+0x26>

  if(sign)
    800004e8:	00088b63          	beqz	a7,800004fe <printint+0x60>
    buf[i++] = '-';
    800004ec:	fe040793          	addi	a5,s0,-32
    800004f0:	973e                	add	a4,a4,a5
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x8e>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d60080e7          	jalr	-672(ra) # 8000027e <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7c>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf9d                	j	800004b4 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	3a07a223          	sw	zero,932(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b7a50513          	addi	a0,a0,-1158 # 800080e8 <digits+0xa8>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00009717          	auipc	a4,0x9
    80000584:	a8f72023          	sw	a5,-1408(a4) # 80009000 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	334dad83          	lw	s11,820(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00011517          	auipc	a0,0x11
    800005fe:	2de50513          	addi	a0,a0,734 # 800118d8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5fa080e7          	jalr	1530(ra) # 80000bfc <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c62080e7          	jalr	-926(ra) # 8000027e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e32080e7          	jalr	-462(ra) # 8000049e <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0e080e7          	jalr	-498(ra) # 8000049e <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bd0080e7          	jalr	-1072(ra) # 8000027e <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc4080e7          	jalr	-1084(ra) # 8000027e <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bb0080e7          	jalr	-1104(ra) # 8000027e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b8a080e7          	jalr	-1142(ra) # 8000027e <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b68080e7          	jalr	-1176(ra) # 8000027e <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5c080e7          	jalr	-1188(ra) # 8000027e <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b52080e7          	jalr	-1198(ra) # 8000027e <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00011517          	auipc	a0,0x11
    8000075c:	18050513          	addi	a0,a0,384 # 800118d8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	550080e7          	jalr	1360(ra) # 80000cb0 <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00011497          	auipc	s1,0x11
    80000778:	16448493          	addi	s1,s1,356 # 800118d8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3e6080e7          	jalr	998(ra) # 80000b6c <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00011517          	auipc	a0,0x11
    800007d8:	12450513          	addi	a0,a0,292 # 800118f8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	390080e7          	jalr	912(ra) # 80000b6c <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	3b8080e7          	jalr	952(ra) # 80000bb0 <push_off>

  if(panicked){
    80000800:	00009797          	auipc	a5,0x9
    80000804:	8007a783          	lw	a5,-2048(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	andi	a0,s1,255
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	42a080e7          	jalr	1066(ra) # 80000c50 <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	7cc7a783          	lw	a5,1996(a5) # 80009004 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c872703          	lw	a4,1992(a4) # 80009008 <uart_tx_w>
    80000848:	08f70063          	beq	a4,a5,800008c8 <uartstart+0x90>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000862:	00011a97          	auipc	s5,0x11
    80000866:	096a8a93          	addi	s5,s5,150 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	79a48493          	addi	s1,s1,1946 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008a17          	auipc	s4,0x8
    80000876:	796a0a13          	addi	s4,s4,1942 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	cb15                	beqz	a4,800008b6 <uartstart+0x7e>
    int c = uart_tx_buf[uart_tx_r];
    80000884:	00fa8733          	add	a4,s5,a5
    80000888:	01874983          	lbu	s3,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088c:	2785                	addiw	a5,a5,1
    8000088e:	41f7d71b          	sraiw	a4,a5,0x1f
    80000892:	01b7571b          	srliw	a4,a4,0x1b
    80000896:	9fb9                	addw	a5,a5,a4
    80000898:	8bfd                	andi	a5,a5,31
    8000089a:	9f99                	subw	a5,a5,a4
    8000089c:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	e14080e7          	jalr	-492(ra) # 800026b4 <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01390023          	sb	s3,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	409c                	lw	a5,0(s1)
    800008ae:	000a2703          	lw	a4,0(s4)
    800008b2:	fcf714e3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	84aa                	mv	s1,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	01c50513          	addi	a0,a0,28 # 800118f8 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	318080e7          	jalr	792(ra) # 80000bfc <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800008f8:	00008697          	auipc	a3,0x8
    800008fc:	7106a683          	lw	a3,1808(a3) # 80009008 <uart_tx_w>
    80000900:	0016879b          	addiw	a5,a3,1
    80000904:	41f7d71b          	sraiw	a4,a5,0x1f
    80000908:	01b7571b          	srliw	a4,a4,0x1b
    8000090c:	9fb9                	addw	a5,a5,a4
    8000090e:	8bfd                	andi	a5,a5,31
    80000910:	9f99                	subw	a5,a5,a4
    80000912:	00008717          	auipc	a4,0x8
    80000916:	6f272703          	lw	a4,1778(a4) # 80009004 <uart_tx_r>
    8000091a:	04f71363          	bne	a4,a5,80000960 <uartputc+0x96>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091e:	00011a17          	auipc	s4,0x11
    80000922:	fdaa0a13          	addi	s4,s4,-38 # 800118f8 <uart_tx_lock>
    80000926:	00008917          	auipc	s2,0x8
    8000092a:	6de90913          	addi	s2,s2,1758 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000092e:	00008997          	auipc	s3,0x8
    80000932:	6da98993          	addi	s3,s3,1754 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000936:	85d2                	mv	a1,s4
    80000938:	854a                	mv	a0,s2
    8000093a:	00002097          	auipc	ra,0x2
    8000093e:	bee080e7          	jalr	-1042(ra) # 80002528 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000942:	0009a683          	lw	a3,0(s3)
    80000946:	0016879b          	addiw	a5,a3,1
    8000094a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000094e:	01b7571b          	srliw	a4,a4,0x1b
    80000952:	9fb9                	addw	a5,a5,a4
    80000954:	8bfd                	andi	a5,a5,31
    80000956:	9f99                	subw	a5,a5,a4
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	fcf70de3          	beq	a4,a5,80000936 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000960:	00011917          	auipc	s2,0x11
    80000964:	f9890913          	addi	s2,s2,-104 # 800118f8 <uart_tx_lock>
    80000968:	96ca                	add	a3,a3,s2
    8000096a:	00968c23          	sb	s1,24(a3)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000096e:	00008717          	auipc	a4,0x8
    80000972:	68f72d23          	sw	a5,1690(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000976:	00000097          	auipc	ra,0x0
    8000097a:	ec2080e7          	jalr	-318(ra) # 80000838 <uartstart>
      release(&uart_tx_lock);
    8000097e:	854a                	mv	a0,s2
    80000980:	00000097          	auipc	ra,0x0
    80000984:	330080e7          	jalr	816(ra) # 80000cb0 <release>
}
    80000988:	70a2                	ld	ra,40(sp)
    8000098a:	7402                	ld	s0,32(sp)
    8000098c:	64e2                	ld	s1,24(sp)
    8000098e:	6942                	ld	s2,16(sp)
    80000990:	69a2                	ld	s3,8(sp)
    80000992:	6a02                	ld	s4,0(sp)
    80000994:	6145                	addi	sp,sp,48
    80000996:	8082                	ret

0000000080000998 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000998:	1141                	addi	sp,sp,-16
    8000099a:	e422                	sd	s0,8(sp)
    8000099c:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009a6:	8b85                	andi	a5,a5,1
    800009a8:	cb91                	beqz	a5,800009bc <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009aa:	100007b7          	lui	a5,0x10000
    800009ae:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009b2:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009b6:	6422                	ld	s0,8(sp)
    800009b8:	0141                	addi	sp,sp,16
    800009ba:	8082                	ret
    return -1;
    800009bc:	557d                	li	a0,-1
    800009be:	bfe5                	j	800009b6 <uartgetc+0x1e>

00000000800009c0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009c0:	1101                	addi	sp,sp,-32
    800009c2:	ec06                	sd	ra,24(sp)
    800009c4:	e822                	sd	s0,16(sp)
    800009c6:	e426                	sd	s1,8(sp)
    800009c8:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ca:	54fd                	li	s1,-1
    800009cc:	a029                	j	800009d6 <uartintr+0x16>
      break;
    consoleintr(c);
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	8f2080e7          	jalr	-1806(ra) # 800002c0 <consoleintr>
    int c = uartgetc();
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	fc2080e7          	jalr	-62(ra) # 80000998 <uartgetc>
    if(c == -1)
    800009de:	fe9518e3          	bne	a0,s1,800009ce <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009e2:	00011497          	auipc	s1,0x11
    800009e6:	f1648493          	addi	s1,s1,-234 # 800118f8 <uart_tx_lock>
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	210080e7          	jalr	528(ra) # 80000bfc <acquire>
  uartstart();
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	e44080e7          	jalr	-444(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009fc:	8526                	mv	a0,s1
    800009fe:	00000097          	auipc	ra,0x0
    80000a02:	2b2080e7          	jalr	690(ra) # 80000cb0 <release>
}
    80000a06:	60e2                	ld	ra,24(sp)
    80000a08:	6442                	ld	s0,16(sp)
    80000a0a:	64a2                	ld	s1,8(sp)
    80000a0c:	6105                	addi	sp,sp,32
    80000a0e:	8082                	ret

0000000080000a10 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a10:	1101                	addi	sp,sp,-32
    80000a12:	ec06                	sd	ra,24(sp)
    80000a14:	e822                	sd	s0,16(sp)
    80000a16:	e426                	sd	s1,8(sp)
    80000a18:	e04a                	sd	s2,0(sp)
    80000a1a:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a1c:	03451793          	slli	a5,a0,0x34
    80000a20:	ebb9                	bnez	a5,80000a76 <kfree+0x66>
    80000a22:	84aa                	mv	s1,a0
    80000a24:	00026797          	auipc	a5,0x26
    80000a28:	5dc78793          	addi	a5,a5,1500 # 80027000 <end>
    80000a2c:	04f56563          	bltu	a0,a5,80000a76 <kfree+0x66>
    80000a30:	47c5                	li	a5,17
    80000a32:	07ee                	slli	a5,a5,0x1b
    80000a34:	04f57163          	bgeu	a0,a5,80000a76 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a38:	6605                	lui	a2,0x1
    80000a3a:	4585                	li	a1,1
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	2bc080e7          	jalr	700(ra) # 80000cf8 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a44:	00011917          	auipc	s2,0x11
    80000a48:	eec90913          	addi	s2,s2,-276 # 80011930 <kmem>
    80000a4c:	854a                	mv	a0,s2
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	1ae080e7          	jalr	430(ra) # 80000bfc <acquire>
  r->next = kmem.freelist;
    80000a56:	01893783          	ld	a5,24(s2)
    80000a5a:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5c:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	24e080e7          	jalr	590(ra) # 80000cb0 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00007517          	auipc	a0,0x7
    80000a7a:	5ea50513          	addi	a0,a0,1514 # 80008060 <digits+0x20>
    80000a7e:	00000097          	auipc	ra,0x0
    80000a82:	ac2080e7          	jalr	-1342(ra) # 80000540 <panic>

0000000080000a86 <freerange>:
{
    80000a86:	7179                	addi	sp,sp,-48
    80000a88:	f406                	sd	ra,40(sp)
    80000a8a:	f022                	sd	s0,32(sp)
    80000a8c:	ec26                	sd	s1,24(sp)
    80000a8e:	e84a                	sd	s2,16(sp)
    80000a90:	e44e                	sd	s3,8(sp)
    80000a92:	e052                	sd	s4,0(sp)
    80000a94:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a96:	6785                	lui	a5,0x1
    80000a98:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a9c:	94aa                	add	s1,s1,a0
    80000a9e:	757d                	lui	a0,0xfffff
    80000aa0:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94be                	add	s1,s1,a5
    80000aa4:	0095ee63          	bltu	a1,s1,80000ac0 <freerange+0x3a>
    80000aa8:	892e                	mv	s2,a1
    kfree(p);
    80000aaa:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aac:	6985                	lui	s3,0x1
    kfree(p);
    80000aae:	01448533          	add	a0,s1,s4
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	f5e080e7          	jalr	-162(ra) # 80000a10 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aba:	94ce                	add	s1,s1,s3
    80000abc:	fe9979e3          	bgeu	s2,s1,80000aae <freerange+0x28>
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6942                	ld	s2,16(sp)
    80000ac8:	69a2                	ld	s3,8(sp)
    80000aca:	6a02                	ld	s4,0(sp)
    80000acc:	6145                	addi	sp,sp,48
    80000ace:	8082                	ret

0000000080000ad0 <kinit>:
{
    80000ad0:	1141                	addi	sp,sp,-16
    80000ad2:	e406                	sd	ra,8(sp)
    80000ad4:	e022                	sd	s0,0(sp)
    80000ad6:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad8:	00007597          	auipc	a1,0x7
    80000adc:	59058593          	addi	a1,a1,1424 # 80008068 <digits+0x28>
    80000ae0:	00011517          	auipc	a0,0x11
    80000ae4:	e5050513          	addi	a0,a0,-432 # 80011930 <kmem>
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	084080e7          	jalr	132(ra) # 80000b6c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000af0:	45c5                	li	a1,17
    80000af2:	05ee                	slli	a1,a1,0x1b
    80000af4:	00026517          	auipc	a0,0x26
    80000af8:	50c50513          	addi	a0,a0,1292 # 80027000 <end>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	f8a080e7          	jalr	-118(ra) # 80000a86 <freerange>
}
    80000b04:	60a2                	ld	ra,8(sp)
    80000b06:	6402                	ld	s0,0(sp)
    80000b08:	0141                	addi	sp,sp,16
    80000b0a:	8082                	ret

0000000080000b0c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b0c:	1101                	addi	sp,sp,-32
    80000b0e:	ec06                	sd	ra,24(sp)
    80000b10:	e822                	sd	s0,16(sp)
    80000b12:	e426                	sd	s1,8(sp)
    80000b14:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b16:	00011497          	auipc	s1,0x11
    80000b1a:	e1a48493          	addi	s1,s1,-486 # 80011930 <kmem>
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	0dc080e7          	jalr	220(ra) # 80000bfc <acquire>
  r = kmem.freelist;
    80000b28:	6c84                	ld	s1,24(s1)
  if(r)
    80000b2a:	c885                	beqz	s1,80000b5a <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b2c:	609c                	ld	a5,0(s1)
    80000b2e:	00011517          	auipc	a0,0x11
    80000b32:	e0250513          	addi	a0,a0,-510 # 80011930 <kmem>
    80000b36:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	178080e7          	jalr	376(ra) # 80000cb0 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b40:	6605                	lui	a2,0x1
    80000b42:	4595                	li	a1,5
    80000b44:	8526                	mv	a0,s1
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	1b2080e7          	jalr	434(ra) # 80000cf8 <memset>
  return (void*)r;
}
    80000b4e:	8526                	mv	a0,s1
    80000b50:	60e2                	ld	ra,24(sp)
    80000b52:	6442                	ld	s0,16(sp)
    80000b54:	64a2                	ld	s1,8(sp)
    80000b56:	6105                	addi	sp,sp,32
    80000b58:	8082                	ret
  release(&kmem.lock);
    80000b5a:	00011517          	auipc	a0,0x11
    80000b5e:	dd650513          	addi	a0,a0,-554 # 80011930 <kmem>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	14e080e7          	jalr	334(ra) # 80000cb0 <release>
  if(r)
    80000b6a:	b7d5                	j	80000b4e <kalloc+0x42>

0000000080000b6c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b6c:	1141                	addi	sp,sp,-16
    80000b6e:	e422                	sd	s0,8(sp)
    80000b70:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b72:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b74:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b78:	00053823          	sd	zero,16(a0)
}
    80000b7c:	6422                	ld	s0,8(sp)
    80000b7e:	0141                	addi	sp,sp,16
    80000b80:	8082                	ret

0000000080000b82 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	411c                	lw	a5,0(a0)
    80000b84:	e399                	bnez	a5,80000b8a <holding+0x8>
    80000b86:	4501                	li	a0,0
  return r;
}
    80000b88:	8082                	ret
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b94:	6904                	ld	s1,16(a0)
    80000b96:	00001097          	auipc	ra,0x1
    80000b9a:	f3c080e7          	jalr	-196(ra) # 80001ad2 <mycpu>
    80000b9e:	40a48533          	sub	a0,s1,a0
    80000ba2:	00153513          	seqz	a0,a0
}
    80000ba6:	60e2                	ld	ra,24(sp)
    80000ba8:	6442                	ld	s0,16(sp)
    80000baa:	64a2                	ld	s1,8(sp)
    80000bac:	6105                	addi	sp,sp,32
    80000bae:	8082                	ret

0000000080000bb0 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bb0:	1101                	addi	sp,sp,-32
    80000bb2:	ec06                	sd	ra,24(sp)
    80000bb4:	e822                	sd	s0,16(sp)
    80000bb6:	e426                	sd	s1,8(sp)
    80000bb8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bba:	100024f3          	csrr	s1,sstatus
    80000bbe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bc2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bc4:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bc8:	00001097          	auipc	ra,0x1
    80000bcc:	f0a080e7          	jalr	-246(ra) # 80001ad2 <mycpu>
    80000bd0:	5d3c                	lw	a5,120(a0)
    80000bd2:	cf89                	beqz	a5,80000bec <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	efe080e7          	jalr	-258(ra) # 80001ad2 <mycpu>
    80000bdc:	5d3c                	lw	a5,120(a0)
    80000bde:	2785                	addiw	a5,a5,1
    80000be0:	dd3c                	sw	a5,120(a0)
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	addi	sp,sp,32
    80000bea:	8082                	ret
    mycpu()->intena = old;
    80000bec:	00001097          	auipc	ra,0x1
    80000bf0:	ee6080e7          	jalr	-282(ra) # 80001ad2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bf4:	8085                	srli	s1,s1,0x1
    80000bf6:	8885                	andi	s1,s1,1
    80000bf8:	dd64                	sw	s1,124(a0)
    80000bfa:	bfe9                	j	80000bd4 <push_off+0x24>

0000000080000bfc <acquire>:
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
    80000c06:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c08:	00000097          	auipc	ra,0x0
    80000c0c:	fa8080e7          	jalr	-88(ra) # 80000bb0 <push_off>
  if(holding(lk))
    80000c10:	8526                	mv	a0,s1
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	f70080e7          	jalr	-144(ra) # 80000b82 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1a:	4705                	li	a4,1
  if(holding(lk))
    80000c1c:	e115                	bnez	a0,80000c40 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c1e:	87ba                	mv	a5,a4
    80000c20:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c24:	2781                	sext.w	a5,a5
    80000c26:	ffe5                	bnez	a5,80000c1e <acquire+0x22>
  __sync_synchronize();
    80000c28:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	ea6080e7          	jalr	-346(ra) # 80001ad2 <mycpu>
    80000c34:	e888                	sd	a0,16(s1)
}
    80000c36:	60e2                	ld	ra,24(sp)
    80000c38:	6442                	ld	s0,16(sp)
    80000c3a:	64a2                	ld	s1,8(sp)
    80000c3c:	6105                	addi	sp,sp,32
    80000c3e:	8082                	ret
    panic("acquire");
    80000c40:	00007517          	auipc	a0,0x7
    80000c44:	43050513          	addi	a0,a0,1072 # 80008070 <digits+0x30>
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	8f8080e7          	jalr	-1800(ra) # 80000540 <panic>

0000000080000c50 <pop_off>:

void
pop_off(void)
{
    80000c50:	1141                	addi	sp,sp,-16
    80000c52:	e406                	sd	ra,8(sp)
    80000c54:	e022                	sd	s0,0(sp)
    80000c56:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c58:	00001097          	auipc	ra,0x1
    80000c5c:	e7a080e7          	jalr	-390(ra) # 80001ad2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c64:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c66:	e78d                	bnez	a5,80000c90 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c68:	5d3c                	lw	a5,120(a0)
    80000c6a:	02f05b63          	blez	a5,80000ca0 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c6e:	37fd                	addiw	a5,a5,-1
    80000c70:	0007871b          	sext.w	a4,a5
    80000c74:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c76:	eb09                	bnez	a4,80000c88 <pop_off+0x38>
    80000c78:	5d7c                	lw	a5,124(a0)
    80000c7a:	c799                	beqz	a5,80000c88 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c7c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c80:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c84:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c88:	60a2                	ld	ra,8(sp)
    80000c8a:	6402                	ld	s0,0(sp)
    80000c8c:	0141                	addi	sp,sp,16
    80000c8e:	8082                	ret
    panic("pop_off - interruptible");
    80000c90:	00007517          	auipc	a0,0x7
    80000c94:	3e850513          	addi	a0,a0,1000 # 80008078 <digits+0x38>
    80000c98:	00000097          	auipc	ra,0x0
    80000c9c:	8a8080e7          	jalr	-1880(ra) # 80000540 <panic>
    panic("pop_off");
    80000ca0:	00007517          	auipc	a0,0x7
    80000ca4:	3f050513          	addi	a0,a0,1008 # 80008090 <digits+0x50>
    80000ca8:	00000097          	auipc	ra,0x0
    80000cac:	898080e7          	jalr	-1896(ra) # 80000540 <panic>

0000000080000cb0 <release>:
{
    80000cb0:	1101                	addi	sp,sp,-32
    80000cb2:	ec06                	sd	ra,24(sp)
    80000cb4:	e822                	sd	s0,16(sp)
    80000cb6:	e426                	sd	s1,8(sp)
    80000cb8:	1000                	addi	s0,sp,32
    80000cba:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	ec6080e7          	jalr	-314(ra) # 80000b82 <holding>
    80000cc4:	c115                	beqz	a0,80000ce8 <release+0x38>
  lk->cpu = 0;
    80000cc6:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cca:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cce:	0f50000f          	fence	iorw,ow
    80000cd2:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cd6:	00000097          	auipc	ra,0x0
    80000cda:	f7a080e7          	jalr	-134(ra) # 80000c50 <pop_off>
}
    80000cde:	60e2                	ld	ra,24(sp)
    80000ce0:	6442                	ld	s0,16(sp)
    80000ce2:	64a2                	ld	s1,8(sp)
    80000ce4:	6105                	addi	sp,sp,32
    80000ce6:	8082                	ret
    panic("release");
    80000ce8:	00007517          	auipc	a0,0x7
    80000cec:	3b050513          	addi	a0,a0,944 # 80008098 <digits+0x58>
    80000cf0:	00000097          	auipc	ra,0x0
    80000cf4:	850080e7          	jalr	-1968(ra) # 80000540 <panic>

0000000080000cf8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cfe:	ca19                	beqz	a2,80000d14 <memset+0x1c>
    80000d00:	87aa                	mv	a5,a0
    80000d02:	1602                	slli	a2,a2,0x20
    80000d04:	9201                	srli	a2,a2,0x20
    80000d06:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d0a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d0e:	0785                	addi	a5,a5,1
    80000d10:	fee79de3          	bne	a5,a4,80000d0a <memset+0x12>
  }
  return dst;
}
    80000d14:	6422                	ld	s0,8(sp)
    80000d16:	0141                	addi	sp,sp,16
    80000d18:	8082                	ret

0000000080000d1a <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d20:	ca05                	beqz	a2,80000d50 <memcmp+0x36>
    80000d22:	fff6069b          	addiw	a3,a2,-1
    80000d26:	1682                	slli	a3,a3,0x20
    80000d28:	9281                	srli	a3,a3,0x20
    80000d2a:	0685                	addi	a3,a3,1
    80000d2c:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d2e:	00054783          	lbu	a5,0(a0)
    80000d32:	0005c703          	lbu	a4,0(a1)
    80000d36:	00e79863          	bne	a5,a4,80000d46 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d3a:	0505                	addi	a0,a0,1
    80000d3c:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d3e:	fed518e3          	bne	a0,a3,80000d2e <memcmp+0x14>
  }

  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	a019                	j	80000d4a <memcmp+0x30>
      return *s1 - *s2;
    80000d46:	40e7853b          	subw	a0,a5,a4
}
    80000d4a:	6422                	ld	s0,8(sp)
    80000d4c:	0141                	addi	sp,sp,16
    80000d4e:	8082                	ret
  return 0;
    80000d50:	4501                	li	a0,0
    80000d52:	bfe5                	j	80000d4a <memcmp+0x30>

0000000080000d54 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d54:	1141                	addi	sp,sp,-16
    80000d56:	e422                	sd	s0,8(sp)
    80000d58:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d5a:	02a5e563          	bltu	a1,a0,80000d84 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5e:	fff6069b          	addiw	a3,a2,-1
    80000d62:	ce11                	beqz	a2,80000d7e <memmove+0x2a>
    80000d64:	1682                	slli	a3,a3,0x20
    80000d66:	9281                	srli	a3,a3,0x20
    80000d68:	0685                	addi	a3,a3,1
    80000d6a:	96ae                	add	a3,a3,a1
    80000d6c:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0785                	addi	a5,a5,1
    80000d72:	fff5c703          	lbu	a4,-1(a1)
    80000d76:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d7a:	fed59ae3          	bne	a1,a3,80000d6e <memmove+0x1a>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
  if(s < d && s + n > d){
    80000d84:	02061713          	slli	a4,a2,0x20
    80000d88:	9301                	srli	a4,a4,0x20
    80000d8a:	00e587b3          	add	a5,a1,a4
    80000d8e:	fcf578e3          	bgeu	a0,a5,80000d5e <memmove+0xa>
    d += n;
    80000d92:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d94:	fff6069b          	addiw	a3,a2,-1
    80000d98:	d27d                	beqz	a2,80000d7e <memmove+0x2a>
    80000d9a:	02069613          	slli	a2,a3,0x20
    80000d9e:	9201                	srli	a2,a2,0x20
    80000da0:	fff64613          	not	a2,a2
    80000da4:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000da6:	17fd                	addi	a5,a5,-1
    80000da8:	177d                	addi	a4,a4,-1
    80000daa:	0007c683          	lbu	a3,0(a5)
    80000dae:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000db2:	fef61ae3          	bne	a2,a5,80000da6 <memmove+0x52>
    80000db6:	b7e1                	j	80000d7e <memmove+0x2a>

0000000080000db8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e406                	sd	ra,8(sp)
    80000dbc:	e022                	sd	s0,0(sp)
    80000dbe:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dc0:	00000097          	auipc	ra,0x0
    80000dc4:	f94080e7          	jalr	-108(ra) # 80000d54 <memmove>
}
    80000dc8:	60a2                	ld	ra,8(sp)
    80000dca:	6402                	ld	s0,0(sp)
    80000dcc:	0141                	addi	sp,sp,16
    80000dce:	8082                	ret

0000000080000dd0 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e422                	sd	s0,8(sp)
    80000dd4:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dd6:	ce11                	beqz	a2,80000df2 <strncmp+0x22>
    80000dd8:	00054783          	lbu	a5,0(a0)
    80000ddc:	cf89                	beqz	a5,80000df6 <strncmp+0x26>
    80000dde:	0005c703          	lbu	a4,0(a1)
    80000de2:	00f71a63          	bne	a4,a5,80000df6 <strncmp+0x26>
    n--, p++, q++;
    80000de6:	367d                	addiw	a2,a2,-1
    80000de8:	0505                	addi	a0,a0,1
    80000dea:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dec:	f675                	bnez	a2,80000dd8 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dee:	4501                	li	a0,0
    80000df0:	a809                	j	80000e02 <strncmp+0x32>
    80000df2:	4501                	li	a0,0
    80000df4:	a039                	j	80000e02 <strncmp+0x32>
  if(n == 0)
    80000df6:	ca09                	beqz	a2,80000e08 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000df8:	00054503          	lbu	a0,0(a0)
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	9d1d                	subw	a0,a0,a5
}
    80000e02:	6422                	ld	s0,8(sp)
    80000e04:	0141                	addi	sp,sp,16
    80000e06:	8082                	ret
    return 0;
    80000e08:	4501                	li	a0,0
    80000e0a:	bfe5                	j	80000e02 <strncmp+0x32>

0000000080000e0c <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e0c:	1141                	addi	sp,sp,-16
    80000e0e:	e422                	sd	s0,8(sp)
    80000e10:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e12:	872a                	mv	a4,a0
    80000e14:	8832                	mv	a6,a2
    80000e16:	367d                	addiw	a2,a2,-1
    80000e18:	01005963          	blez	a6,80000e2a <strncpy+0x1e>
    80000e1c:	0705                	addi	a4,a4,1
    80000e1e:	0005c783          	lbu	a5,0(a1)
    80000e22:	fef70fa3          	sb	a5,-1(a4)
    80000e26:	0585                	addi	a1,a1,1
    80000e28:	f7f5                	bnez	a5,80000e14 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e2a:	86ba                	mv	a3,a4
    80000e2c:	00c05c63          	blez	a2,80000e44 <strncpy+0x38>
    *s++ = 0;
    80000e30:	0685                	addi	a3,a3,1
    80000e32:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e36:	fff6c793          	not	a5,a3
    80000e3a:	9fb9                	addw	a5,a5,a4
    80000e3c:	010787bb          	addw	a5,a5,a6
    80000e40:	fef048e3          	bgtz	a5,80000e30 <strncpy+0x24>
  return os;
}
    80000e44:	6422                	ld	s0,8(sp)
    80000e46:	0141                	addi	sp,sp,16
    80000e48:	8082                	ret

0000000080000e4a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e4a:	1141                	addi	sp,sp,-16
    80000e4c:	e422                	sd	s0,8(sp)
    80000e4e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e50:	02c05363          	blez	a2,80000e76 <safestrcpy+0x2c>
    80000e54:	fff6069b          	addiw	a3,a2,-1
    80000e58:	1682                	slli	a3,a3,0x20
    80000e5a:	9281                	srli	a3,a3,0x20
    80000e5c:	96ae                	add	a3,a3,a1
    80000e5e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e60:	00d58963          	beq	a1,a3,80000e72 <safestrcpy+0x28>
    80000e64:	0585                	addi	a1,a1,1
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff5c703          	lbu	a4,-1(a1)
    80000e6c:	fee78fa3          	sb	a4,-1(a5)
    80000e70:	fb65                	bnez	a4,80000e60 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e72:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e76:	6422                	ld	s0,8(sp)
    80000e78:	0141                	addi	sp,sp,16
    80000e7a:	8082                	ret

0000000080000e7c <strlen>:

int
strlen(const char *s)
{
    80000e7c:	1141                	addi	sp,sp,-16
    80000e7e:	e422                	sd	s0,8(sp)
    80000e80:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e82:	00054783          	lbu	a5,0(a0)
    80000e86:	cf91                	beqz	a5,80000ea2 <strlen+0x26>
    80000e88:	0505                	addi	a0,a0,1
    80000e8a:	87aa                	mv	a5,a0
    80000e8c:	4685                	li	a3,1
    80000e8e:	9e89                	subw	a3,a3,a0
    80000e90:	00f6853b          	addw	a0,a3,a5
    80000e94:	0785                	addi	a5,a5,1
    80000e96:	fff7c703          	lbu	a4,-1(a5)
    80000e9a:	fb7d                	bnez	a4,80000e90 <strlen+0x14>
    ;
  return n;
}
    80000e9c:	6422                	ld	s0,8(sp)
    80000e9e:	0141                	addi	sp,sp,16
    80000ea0:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ea2:	4501                	li	a0,0
    80000ea4:	bfe5                	j	80000e9c <strlen+0x20>

0000000080000ea6 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ea6:	1141                	addi	sp,sp,-16
    80000ea8:	e406                	sd	ra,8(sp)
    80000eaa:	e022                	sd	s0,0(sp)
    80000eac:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eae:	00001097          	auipc	ra,0x1
    80000eb2:	c14080e7          	jalr	-1004(ra) # 80001ac2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000eb6:	00008717          	auipc	a4,0x8
    80000eba:	15670713          	addi	a4,a4,342 # 8000900c <started>
  if(cpuid() == 0){
    80000ebe:	c139                	beqz	a0,80000f04 <main+0x5e>
    while(started == 0)
    80000ec0:	431c                	lw	a5,0(a4)
    80000ec2:	2781                	sext.w	a5,a5
    80000ec4:	dff5                	beqz	a5,80000ec0 <main+0x1a>
      ;
    __sync_synchronize();
    80000ec6:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	bf8080e7          	jalr	-1032(ra) # 80001ac2 <cpuid>
    80000ed2:	85aa                	mv	a1,a0
    80000ed4:	00007517          	auipc	a0,0x7
    80000ed8:	20450513          	addi	a0,a0,516 # 800080d8 <digits+0x98>
    80000edc:	fffff097          	auipc	ra,0xfffff
    80000ee0:	6ae080e7          	jalr	1710(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000ee4:	00000097          	auipc	ra,0x0
    80000ee8:	0c8080e7          	jalr	200(ra) # 80000fac <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eec:	00002097          	auipc	ra,0x2
    80000ef0:	aa0080e7          	jalr	-1376(ra) # 8000298c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ef4:	00005097          	auipc	ra,0x5
    80000ef8:	04c080e7          	jalr	76(ra) # 80005f40 <plicinithart>
  }

  scheduler();        
    80000efc:	00001097          	auipc	ra,0x1
    80000f00:	1aa080e7          	jalr	426(ra) # 800020a6 <scheduler>
    consoleinit();
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	54e080e7          	jalr	1358(ra) # 80000452 <consoleinit>
    printfinit();
    80000f0c:	00000097          	auipc	ra,0x0
    80000f10:	85e080e7          	jalr	-1954(ra) # 8000076a <printfinit>
    printf("\n");
    80000f14:	00007517          	auipc	a0,0x7
    80000f18:	1d450513          	addi	a0,a0,468 # 800080e8 <digits+0xa8>
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	66e080e7          	jalr	1646(ra) # 8000058a <printf>
    printf("EEE3535 Operating Systems: booting xv6-riscv kernel\n");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	17c50513          	addi	a0,a0,380 # 800080a0 <digits+0x60>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	65e080e7          	jalr	1630(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	b9c080e7          	jalr	-1124(ra) # 80000ad0 <kinit>
    kvminit();       // create kernel page table
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	2a0080e7          	jalr	672(ra) # 800011dc <kvminit>
    kvminithart();   // turn on paging
    80000f44:	00000097          	auipc	ra,0x0
    80000f48:	068080e7          	jalr	104(ra) # 80000fac <kvminithart>
    procinit();      // process table
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	aa6080e7          	jalr	-1370(ra) # 800019f2 <procinit>
    trapinit();      // trap vectors
    80000f54:	00002097          	auipc	ra,0x2
    80000f58:	a10080e7          	jalr	-1520(ra) # 80002964 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5c:	00002097          	auipc	ra,0x2
    80000f60:	a30080e7          	jalr	-1488(ra) # 8000298c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	fc6080e7          	jalr	-58(ra) # 80005f2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6c:	00005097          	auipc	ra,0x5
    80000f70:	fd4080e7          	jalr	-44(ra) # 80005f40 <plicinithart>
    binit();         // buffer cache
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	180080e7          	jalr	384(ra) # 800030f4 <binit>
    iinit();         // inode cache
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	812080e7          	jalr	-2030(ra) # 8000378e <iinit>
    fileinit();      // file table
    80000f84:	00003097          	auipc	ra,0x3
    80000f88:	7b0080e7          	jalr	1968(ra) # 80004734 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	0bc080e7          	jalr	188(ra) # 80006048 <virtio_disk_init>
    userinit();      // first user process
    80000f94:	00001097          	auipc	ra,0x1
    80000f98:	e72080e7          	jalr	-398(ra) # 80001e06 <userinit>
    __sync_synchronize();
    80000f9c:	0ff0000f          	fence
    started = 1;
    80000fa0:	4785                	li	a5,1
    80000fa2:	00008717          	auipc	a4,0x8
    80000fa6:	06f72523          	sw	a5,106(a4) # 8000900c <started>
    80000faa:	bf89                	j	80000efc <main+0x56>

0000000080000fac <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fac:	1141                	addi	sp,sp,-16
    80000fae:	e422                	sd	s0,8(sp)
    80000fb0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb2:	00008797          	auipc	a5,0x8
    80000fb6:	05e7b783          	ld	a5,94(a5) # 80009010 <kernel_pagetable>
    80000fba:	83b1                	srli	a5,a5,0xc
    80000fbc:	577d                	li	a4,-1
    80000fbe:	177e                	slli	a4,a4,0x3f
    80000fc0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc6:	12000073          	sfence.vma
  sfence_vma();
}
    80000fca:	6422                	ld	s0,8(sp)
    80000fcc:	0141                	addi	sp,sp,16
    80000fce:	8082                	ret

0000000080000fd0 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd0:	7139                	addi	sp,sp,-64
    80000fd2:	fc06                	sd	ra,56(sp)
    80000fd4:	f822                	sd	s0,48(sp)
    80000fd6:	f426                	sd	s1,40(sp)
    80000fd8:	f04a                	sd	s2,32(sp)
    80000fda:	ec4e                	sd	s3,24(sp)
    80000fdc:	e852                	sd	s4,16(sp)
    80000fde:	e456                	sd	s5,8(sp)
    80000fe0:	e05a                	sd	s6,0(sp)
    80000fe2:	0080                	addi	s0,sp,64
    80000fe4:	84aa                	mv	s1,a0
    80000fe6:	89ae                	mv	s3,a1
    80000fe8:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fea:	57fd                	li	a5,-1
    80000fec:	83e9                	srli	a5,a5,0x1a
    80000fee:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff0:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff2:	04b7f263          	bgeu	a5,a1,80001036 <walk+0x66>
    panic("walk");
    80000ff6:	00007517          	auipc	a0,0x7
    80000ffa:	0fa50513          	addi	a0,a0,250 # 800080f0 <digits+0xb0>
    80000ffe:	fffff097          	auipc	ra,0xfffff
    80001002:	542080e7          	jalr	1346(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001006:	060a8663          	beqz	s5,80001072 <walk+0xa2>
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	b02080e7          	jalr	-1278(ra) # 80000b0c <kalloc>
    80001012:	84aa                	mv	s1,a0
    80001014:	c529                	beqz	a0,8000105e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001016:	6605                	lui	a2,0x1
    80001018:	4581                	li	a1,0
    8000101a:	00000097          	auipc	ra,0x0
    8000101e:	cde080e7          	jalr	-802(ra) # 80000cf8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001022:	00c4d793          	srli	a5,s1,0xc
    80001026:	07aa                	slli	a5,a5,0xa
    80001028:	0017e793          	ori	a5,a5,1
    8000102c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001030:	3a5d                	addiw	s4,s4,-9
    80001032:	036a0063          	beq	s4,s6,80001052 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001036:	0149d933          	srl	s2,s3,s4
    8000103a:	1ff97913          	andi	s2,s2,511
    8000103e:	090e                	slli	s2,s2,0x3
    80001040:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001042:	00093483          	ld	s1,0(s2)
    80001046:	0014f793          	andi	a5,s1,1
    8000104a:	dfd5                	beqz	a5,80001006 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104c:	80a9                	srli	s1,s1,0xa
    8000104e:	04b2                	slli	s1,s1,0xc
    80001050:	b7c5                	j	80001030 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001052:	00c9d513          	srli	a0,s3,0xc
    80001056:	1ff57513          	andi	a0,a0,511
    8000105a:	050e                	slli	a0,a0,0x3
    8000105c:	9526                	add	a0,a0,s1
}
    8000105e:	70e2                	ld	ra,56(sp)
    80001060:	7442                	ld	s0,48(sp)
    80001062:	74a2                	ld	s1,40(sp)
    80001064:	7902                	ld	s2,32(sp)
    80001066:	69e2                	ld	s3,24(sp)
    80001068:	6a42                	ld	s4,16(sp)
    8000106a:	6aa2                	ld	s5,8(sp)
    8000106c:	6b02                	ld	s6,0(sp)
    8000106e:	6121                	addi	sp,sp,64
    80001070:	8082                	ret
        return 0;
    80001072:	4501                	li	a0,0
    80001074:	b7ed                	j	8000105e <walk+0x8e>

0000000080001076 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001076:	57fd                	li	a5,-1
    80001078:	83e9                	srli	a5,a5,0x1a
    8000107a:	00b7f463          	bgeu	a5,a1,80001082 <walkaddr+0xc>
    return 0;
    8000107e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001080:	8082                	ret
{
    80001082:	1141                	addi	sp,sp,-16
    80001084:	e406                	sd	ra,8(sp)
    80001086:	e022                	sd	s0,0(sp)
    80001088:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108a:	4601                	li	a2,0
    8000108c:	00000097          	auipc	ra,0x0
    80001090:	f44080e7          	jalr	-188(ra) # 80000fd0 <walk>
  if(pte == 0)
    80001094:	c105                	beqz	a0,800010b4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001096:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001098:	0117f693          	andi	a3,a5,17
    8000109c:	4745                	li	a4,17
    return 0;
    8000109e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a0:	00e68663          	beq	a3,a4,800010ac <walkaddr+0x36>
}
    800010a4:	60a2                	ld	ra,8(sp)
    800010a6:	6402                	ld	s0,0(sp)
    800010a8:	0141                	addi	sp,sp,16
    800010aa:	8082                	ret
  pa = PTE2PA(*pte);
    800010ac:	00a7d513          	srli	a0,a5,0xa
    800010b0:	0532                	slli	a0,a0,0xc
  return pa;
    800010b2:	bfcd                	j	800010a4 <walkaddr+0x2e>
    return 0;
    800010b4:	4501                	li	a0,0
    800010b6:	b7fd                	j	800010a4 <walkaddr+0x2e>

00000000800010b8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010b8:	1101                	addi	sp,sp,-32
    800010ba:	ec06                	sd	ra,24(sp)
    800010bc:	e822                	sd	s0,16(sp)
    800010be:	e426                	sd	s1,8(sp)
    800010c0:	1000                	addi	s0,sp,32
    800010c2:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010c4:	1552                	slli	a0,a0,0x34
    800010c6:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010ca:	4601                	li	a2,0
    800010cc:	00008517          	auipc	a0,0x8
    800010d0:	f4453503          	ld	a0,-188(a0) # 80009010 <kernel_pagetable>
    800010d4:	00000097          	auipc	ra,0x0
    800010d8:	efc080e7          	jalr	-260(ra) # 80000fd0 <walk>
  if(pte == 0)
    800010dc:	cd09                	beqz	a0,800010f6 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800010de:	6108                	ld	a0,0(a0)
    800010e0:	00157793          	andi	a5,a0,1
    800010e4:	c38d                	beqz	a5,80001106 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800010e6:	8129                	srli	a0,a0,0xa
    800010e8:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800010ea:	9526                	add	a0,a0,s1
    800010ec:	60e2                	ld	ra,24(sp)
    800010ee:	6442                	ld	s0,16(sp)
    800010f0:	64a2                	ld	s1,8(sp)
    800010f2:	6105                	addi	sp,sp,32
    800010f4:	8082                	ret
    panic("kvmpa");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	00250513          	addi	a0,a0,2 # 800080f8 <digits+0xb8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	442080e7          	jalr	1090(ra) # 80000540 <panic>
    panic("kvmpa");
    80001106:	00007517          	auipc	a0,0x7
    8000110a:	ff250513          	addi	a0,a0,-14 # 800080f8 <digits+0xb8>
    8000110e:	fffff097          	auipc	ra,0xfffff
    80001112:	432080e7          	jalr	1074(ra) # 80000540 <panic>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
    8000112c:	8aaa                	mv	s5,a0
    8000112e:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001130:	777d                	lui	a4,0xfffff
    80001132:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001136:	167d                	addi	a2,a2,-1
    80001138:	00b609b3          	add	s3,a2,a1
    8000113c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001140:	893e                	mv	s2,a5
    80001142:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001146:	6b85                	lui	s7,0x1
    80001148:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114c:	4605                	li	a2,1
    8000114e:	85ca                	mv	a1,s2
    80001150:	8556                	mv	a0,s5
    80001152:	00000097          	auipc	ra,0x0
    80001156:	e7e080e7          	jalr	-386(ra) # 80000fd0 <walk>
    8000115a:	c51d                	beqz	a0,80001188 <mappages+0x72>
    if(*pte & PTE_V)
    8000115c:	611c                	ld	a5,0(a0)
    8000115e:	8b85                	andi	a5,a5,1
    80001160:	ef81                	bnez	a5,80001178 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001162:	80b1                	srli	s1,s1,0xc
    80001164:	04aa                	slli	s1,s1,0xa
    80001166:	0164e4b3          	or	s1,s1,s6
    8000116a:	0014e493          	ori	s1,s1,1
    8000116e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001170:	03390863          	beq	s2,s3,800011a0 <mappages+0x8a>
    a += PGSIZE;
    80001174:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001176:	bfc9                	j	80001148 <mappages+0x32>
      panic("remap");
    80001178:	00007517          	auipc	a0,0x7
    8000117c:	f8850513          	addi	a0,a0,-120 # 80008100 <digits+0xc0>
    80001180:	fffff097          	auipc	ra,0xfffff
    80001184:	3c0080e7          	jalr	960(ra) # 80000540 <panic>
      return -1;
    80001188:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000118a:	60a6                	ld	ra,72(sp)
    8000118c:	6406                	ld	s0,64(sp)
    8000118e:	74e2                	ld	s1,56(sp)
    80001190:	7942                	ld	s2,48(sp)
    80001192:	79a2                	ld	s3,40(sp)
    80001194:	7a02                	ld	s4,32(sp)
    80001196:	6ae2                	ld	s5,24(sp)
    80001198:	6b42                	ld	s6,16(sp)
    8000119a:	6ba2                	ld	s7,8(sp)
    8000119c:	6161                	addi	sp,sp,80
    8000119e:	8082                	ret
  return 0;
    800011a0:	4501                	li	a0,0
    800011a2:	b7e5                	j	8000118a <mappages+0x74>

00000000800011a4 <kvmmap>:
{
    800011a4:	1141                	addi	sp,sp,-16
    800011a6:	e406                	sd	ra,8(sp)
    800011a8:	e022                	sd	s0,0(sp)
    800011aa:	0800                	addi	s0,sp,16
    800011ac:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011ae:	86ae                	mv	a3,a1
    800011b0:	85aa                	mv	a1,a0
    800011b2:	00008517          	auipc	a0,0x8
    800011b6:	e5e53503          	ld	a0,-418(a0) # 80009010 <kernel_pagetable>
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	f5c080e7          	jalr	-164(ra) # 80001116 <mappages>
    800011c2:	e509                	bnez	a0,800011cc <kvmmap+0x28>
}
    800011c4:	60a2                	ld	ra,8(sp)
    800011c6:	6402                	ld	s0,0(sp)
    800011c8:	0141                	addi	sp,sp,16
    800011ca:	8082                	ret
    panic("kvmmap");
    800011cc:	00007517          	auipc	a0,0x7
    800011d0:	f3c50513          	addi	a0,a0,-196 # 80008108 <digits+0xc8>
    800011d4:	fffff097          	auipc	ra,0xfffff
    800011d8:	36c080e7          	jalr	876(ra) # 80000540 <panic>

00000000800011dc <kvminit>:
{
    800011dc:	1101                	addi	sp,sp,-32
    800011de:	ec06                	sd	ra,24(sp)
    800011e0:	e822                	sd	s0,16(sp)
    800011e2:	e426                	sd	s1,8(sp)
    800011e4:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800011e6:	00000097          	auipc	ra,0x0
    800011ea:	926080e7          	jalr	-1754(ra) # 80000b0c <kalloc>
    800011ee:	00008797          	auipc	a5,0x8
    800011f2:	e2a7b123          	sd	a0,-478(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800011f6:	6605                	lui	a2,0x1
    800011f8:	4581                	li	a1,0
    800011fa:	00000097          	auipc	ra,0x0
    800011fe:	afe080e7          	jalr	-1282(ra) # 80000cf8 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001202:	4699                	li	a3,6
    80001204:	6605                	lui	a2,0x1
    80001206:	100005b7          	lui	a1,0x10000
    8000120a:	10000537          	lui	a0,0x10000
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f96080e7          	jalr	-106(ra) # 800011a4 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001216:	4699                	li	a3,6
    80001218:	6605                	lui	a2,0x1
    8000121a:	100015b7          	lui	a1,0x10001
    8000121e:	10001537          	lui	a0,0x10001
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f82080e7          	jalr	-126(ra) # 800011a4 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6641                	lui	a2,0x10
    8000122e:	020005b7          	lui	a1,0x2000
    80001232:	02000537          	lui	a0,0x2000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f6e080e7          	jalr	-146(ra) # 800011a4 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	00400637          	lui	a2,0x400
    80001244:	0c0005b7          	lui	a1,0xc000
    80001248:	0c000537          	lui	a0,0xc000
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f58080e7          	jalr	-168(ra) # 800011a4 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001254:	00007497          	auipc	s1,0x7
    80001258:	dac48493          	addi	s1,s1,-596 # 80008000 <etext>
    8000125c:	46a9                	li	a3,10
    8000125e:	80007617          	auipc	a2,0x80007
    80001262:	da260613          	addi	a2,a2,-606 # 8000 <_entry-0x7fff8000>
    80001266:	4585                	li	a1,1
    80001268:	05fe                	slli	a1,a1,0x1f
    8000126a:	852e                	mv	a0,a1
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f38080e7          	jalr	-200(ra) # 800011a4 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001274:	4699                	li	a3,6
    80001276:	4645                	li	a2,17
    80001278:	066e                	slli	a2,a2,0x1b
    8000127a:	8e05                	sub	a2,a2,s1
    8000127c:	85a6                	mv	a1,s1
    8000127e:	8526                	mv	a0,s1
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f24080e7          	jalr	-220(ra) # 800011a4 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001288:	46a9                	li	a3,10
    8000128a:	6605                	lui	a2,0x1
    8000128c:	00006597          	auipc	a1,0x6
    80001290:	d7458593          	addi	a1,a1,-652 # 80007000 <_trampoline>
    80001294:	04000537          	lui	a0,0x4000
    80001298:	157d                	addi	a0,a0,-1
    8000129a:	0532                	slli	a0,a0,0xc
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f08080e7          	jalr	-248(ra) # 800011a4 <kvmmap>
}
    800012a4:	60e2                	ld	ra,24(sp)
    800012a6:	6442                	ld	s0,16(sp)
    800012a8:	64a2                	ld	s1,8(sp)
    800012aa:	6105                	addi	sp,sp,32
    800012ac:	8082                	ret

00000000800012ae <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ae:	715d                	addi	sp,sp,-80
    800012b0:	e486                	sd	ra,72(sp)
    800012b2:	e0a2                	sd	s0,64(sp)
    800012b4:	fc26                	sd	s1,56(sp)
    800012b6:	f84a                	sd	s2,48(sp)
    800012b8:	f44e                	sd	s3,40(sp)
    800012ba:	f052                	sd	s4,32(sp)
    800012bc:	ec56                	sd	s5,24(sp)
    800012be:	e85a                	sd	s6,16(sp)
    800012c0:	e45e                	sd	s7,8(sp)
    800012c2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c4:	03459793          	slli	a5,a1,0x34
    800012c8:	e795                	bnez	a5,800012f4 <uvmunmap+0x46>
    800012ca:	8a2a                	mv	s4,a0
    800012cc:	892e                	mv	s2,a1
    800012ce:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d0:	0632                	slli	a2,a2,0xc
    800012d2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d8:	6b05                	lui	s6,0x1
    800012da:	0735e263          	bltu	a1,s3,8000133e <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012de:	60a6                	ld	ra,72(sp)
    800012e0:	6406                	ld	s0,64(sp)
    800012e2:	74e2                	ld	s1,56(sp)
    800012e4:	7942                	ld	s2,48(sp)
    800012e6:	79a2                	ld	s3,40(sp)
    800012e8:	7a02                	ld	s4,32(sp)
    800012ea:	6ae2                	ld	s5,24(sp)
    800012ec:	6b42                	ld	s6,16(sp)
    800012ee:	6ba2                	ld	s7,8(sp)
    800012f0:	6161                	addi	sp,sp,80
    800012f2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e1c50513          	addi	a0,a0,-484 # 80008110 <digits+0xd0>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	244080e7          	jalr	580(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001304:	00007517          	auipc	a0,0x7
    80001308:	e2450513          	addi	a0,a0,-476 # 80008128 <digits+0xe8>
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	234080e7          	jalr	564(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001314:	00007517          	auipc	a0,0x7
    80001318:	e2450513          	addi	a0,a0,-476 # 80008138 <digits+0xf8>
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	224080e7          	jalr	548(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001324:	00007517          	auipc	a0,0x7
    80001328:	e2c50513          	addi	a0,a0,-468 # 80008150 <digits+0x110>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	214080e7          	jalr	532(ra) # 80000540 <panic>
    *pte = 0;
    80001334:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001338:	995a                	add	s2,s2,s6
    8000133a:	fb3972e3          	bgeu	s2,s3,800012de <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000133e:	4601                	li	a2,0
    80001340:	85ca                	mv	a1,s2
    80001342:	8552                	mv	a0,s4
    80001344:	00000097          	auipc	ra,0x0
    80001348:	c8c080e7          	jalr	-884(ra) # 80000fd0 <walk>
    8000134c:	84aa                	mv	s1,a0
    8000134e:	d95d                	beqz	a0,80001304 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001350:	6108                	ld	a0,0(a0)
    80001352:	00157793          	andi	a5,a0,1
    80001356:	dfdd                	beqz	a5,80001314 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001358:	3ff57793          	andi	a5,a0,1023
    8000135c:	fd7784e3          	beq	a5,s7,80001324 <uvmunmap+0x76>
    if(do_free){
    80001360:	fc0a8ae3          	beqz	s5,80001334 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001364:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001366:	0532                	slli	a0,a0,0xc
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	6a8080e7          	jalr	1704(ra) # 80000a10 <kfree>
    80001370:	b7d1                	j	80001334 <uvmunmap+0x86>

0000000080001372 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001372:	1101                	addi	sp,sp,-32
    80001374:	ec06                	sd	ra,24(sp)
    80001376:	e822                	sd	s0,16(sp)
    80001378:	e426                	sd	s1,8(sp)
    8000137a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000137c:	fffff097          	auipc	ra,0xfffff
    80001380:	790080e7          	jalr	1936(ra) # 80000b0c <kalloc>
    80001384:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001386:	c519                	beqz	a0,80001394 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001388:	6605                	lui	a2,0x1
    8000138a:	4581                	li	a1,0
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	96c080e7          	jalr	-1684(ra) # 80000cf8 <memset>
  return pagetable;
}
    80001394:	8526                	mv	a0,s1
    80001396:	60e2                	ld	ra,24(sp)
    80001398:	6442                	ld	s0,16(sp)
    8000139a:	64a2                	ld	s1,8(sp)
    8000139c:	6105                	addi	sp,sp,32
    8000139e:	8082                	ret

00000000800013a0 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013a0:	7179                	addi	sp,sp,-48
    800013a2:	f406                	sd	ra,40(sp)
    800013a4:	f022                	sd	s0,32(sp)
    800013a6:	ec26                	sd	s1,24(sp)
    800013a8:	e84a                	sd	s2,16(sp)
    800013aa:	e44e                	sd	s3,8(sp)
    800013ac:	e052                	sd	s4,0(sp)
    800013ae:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013b0:	6785                	lui	a5,0x1
    800013b2:	04f67863          	bgeu	a2,a5,80001402 <uvminit+0x62>
    800013b6:	8a2a                	mv	s4,a0
    800013b8:	89ae                	mv	s3,a1
    800013ba:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	750080e7          	jalr	1872(ra) # 80000b0c <kalloc>
    800013c4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c6:	6605                	lui	a2,0x1
    800013c8:	4581                	li	a1,0
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	92e080e7          	jalr	-1746(ra) # 80000cf8 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013d2:	4779                	li	a4,30
    800013d4:	86ca                	mv	a3,s2
    800013d6:	6605                	lui	a2,0x1
    800013d8:	4581                	li	a1,0
    800013da:	8552                	mv	a0,s4
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	d3a080e7          	jalr	-710(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    800013e4:	8626                	mv	a2,s1
    800013e6:	85ce                	mv	a1,s3
    800013e8:	854a                	mv	a0,s2
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	96a080e7          	jalr	-1686(ra) # 80000d54 <memmove>
}
    800013f2:	70a2                	ld	ra,40(sp)
    800013f4:	7402                	ld	s0,32(sp)
    800013f6:	64e2                	ld	s1,24(sp)
    800013f8:	6942                	ld	s2,16(sp)
    800013fa:	69a2                	ld	s3,8(sp)
    800013fc:	6a02                	ld	s4,0(sp)
    800013fe:	6145                	addi	sp,sp,48
    80001400:	8082                	ret
    panic("inituvm: more than a page");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d6650513          	addi	a0,a0,-666 # 80008168 <digits+0x128>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	136080e7          	jalr	310(ra) # 80000540 <panic>

0000000080001412 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001412:	1101                	addi	sp,sp,-32
    80001414:	ec06                	sd	ra,24(sp)
    80001416:	e822                	sd	s0,16(sp)
    80001418:	e426                	sd	s1,8(sp)
    8000141a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000141c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000141e:	00b67d63          	bgeu	a2,a1,80001438 <uvmdealloc+0x26>
    80001422:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001424:	6785                	lui	a5,0x1
    80001426:	17fd                	addi	a5,a5,-1
    80001428:	00f60733          	add	a4,a2,a5
    8000142c:	767d                	lui	a2,0xfffff
    8000142e:	8f71                	and	a4,a4,a2
    80001430:	97ae                	add	a5,a5,a1
    80001432:	8ff1                	and	a5,a5,a2
    80001434:	00f76863          	bltu	a4,a5,80001444 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001438:	8526                	mv	a0,s1
    8000143a:	60e2                	ld	ra,24(sp)
    8000143c:	6442                	ld	s0,16(sp)
    8000143e:	64a2                	ld	s1,8(sp)
    80001440:	6105                	addi	sp,sp,32
    80001442:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001444:	8f99                	sub	a5,a5,a4
    80001446:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001448:	4685                	li	a3,1
    8000144a:	0007861b          	sext.w	a2,a5
    8000144e:	85ba                	mv	a1,a4
    80001450:	00000097          	auipc	ra,0x0
    80001454:	e5e080e7          	jalr	-418(ra) # 800012ae <uvmunmap>
    80001458:	b7c5                	j	80001438 <uvmdealloc+0x26>

000000008000145a <uvmalloc>:
  if(newsz < oldsz)
    8000145a:	0ab66163          	bltu	a2,a1,800014fc <uvmalloc+0xa2>
{
    8000145e:	7139                	addi	sp,sp,-64
    80001460:	fc06                	sd	ra,56(sp)
    80001462:	f822                	sd	s0,48(sp)
    80001464:	f426                	sd	s1,40(sp)
    80001466:	f04a                	sd	s2,32(sp)
    80001468:	ec4e                	sd	s3,24(sp)
    8000146a:	e852                	sd	s4,16(sp)
    8000146c:	e456                	sd	s5,8(sp)
    8000146e:	0080                	addi	s0,sp,64
    80001470:	8aaa                	mv	s5,a0
    80001472:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001474:	6985                	lui	s3,0x1
    80001476:	19fd                	addi	s3,s3,-1
    80001478:	95ce                	add	a1,a1,s3
    8000147a:	79fd                	lui	s3,0xfffff
    8000147c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001480:	08c9f063          	bgeu	s3,a2,80001500 <uvmalloc+0xa6>
    80001484:	894e                	mv	s2,s3
    mem = kalloc();
    80001486:	fffff097          	auipc	ra,0xfffff
    8000148a:	686080e7          	jalr	1670(ra) # 80000b0c <kalloc>
    8000148e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001490:	c51d                	beqz	a0,800014be <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001492:	6605                	lui	a2,0x1
    80001494:	4581                	li	a1,0
    80001496:	00000097          	auipc	ra,0x0
    8000149a:	862080e7          	jalr	-1950(ra) # 80000cf8 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000149e:	4779                	li	a4,30
    800014a0:	86a6                	mv	a3,s1
    800014a2:	6605                	lui	a2,0x1
    800014a4:	85ca                	mv	a1,s2
    800014a6:	8556                	mv	a0,s5
    800014a8:	00000097          	auipc	ra,0x0
    800014ac:	c6e080e7          	jalr	-914(ra) # 80001116 <mappages>
    800014b0:	e905                	bnez	a0,800014e0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b2:	6785                	lui	a5,0x1
    800014b4:	993e                	add	s2,s2,a5
    800014b6:	fd4968e3          	bltu	s2,s4,80001486 <uvmalloc+0x2c>
  return newsz;
    800014ba:	8552                	mv	a0,s4
    800014bc:	a809                	j	800014ce <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014be:	864e                	mv	a2,s3
    800014c0:	85ca                	mv	a1,s2
    800014c2:	8556                	mv	a0,s5
    800014c4:	00000097          	auipc	ra,0x0
    800014c8:	f4e080e7          	jalr	-178(ra) # 80001412 <uvmdealloc>
      return 0;
    800014cc:	4501                	li	a0,0
}
    800014ce:	70e2                	ld	ra,56(sp)
    800014d0:	7442                	ld	s0,48(sp)
    800014d2:	74a2                	ld	s1,40(sp)
    800014d4:	7902                	ld	s2,32(sp)
    800014d6:	69e2                	ld	s3,24(sp)
    800014d8:	6a42                	ld	s4,16(sp)
    800014da:	6aa2                	ld	s5,8(sp)
    800014dc:	6121                	addi	sp,sp,64
    800014de:	8082                	ret
      kfree(mem);
    800014e0:	8526                	mv	a0,s1
    800014e2:	fffff097          	auipc	ra,0xfffff
    800014e6:	52e080e7          	jalr	1326(ra) # 80000a10 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014ea:	864e                	mv	a2,s3
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	f22080e7          	jalr	-222(ra) # 80001412 <uvmdealloc>
      return 0;
    800014f8:	4501                	li	a0,0
    800014fa:	bfd1                	j	800014ce <uvmalloc+0x74>
    return oldsz;
    800014fc:	852e                	mv	a0,a1
}
    800014fe:	8082                	ret
  return newsz;
    80001500:	8532                	mv	a0,a2
    80001502:	b7f1                	j	800014ce <uvmalloc+0x74>

0000000080001504 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001504:	7179                	addi	sp,sp,-48
    80001506:	f406                	sd	ra,40(sp)
    80001508:	f022                	sd	s0,32(sp)
    8000150a:	ec26                	sd	s1,24(sp)
    8000150c:	e84a                	sd	s2,16(sp)
    8000150e:	e44e                	sd	s3,8(sp)
    80001510:	e052                	sd	s4,0(sp)
    80001512:	1800                	addi	s0,sp,48
    80001514:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001516:	84aa                	mv	s1,a0
    80001518:	6905                	lui	s2,0x1
    8000151a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000151c:	4985                	li	s3,1
    8000151e:	a821                	j	80001536 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001520:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001522:	0532                	slli	a0,a0,0xc
    80001524:	00000097          	auipc	ra,0x0
    80001528:	fe0080e7          	jalr	-32(ra) # 80001504 <freewalk>
      pagetable[i] = 0;
    8000152c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001530:	04a1                	addi	s1,s1,8
    80001532:	03248163          	beq	s1,s2,80001554 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001536:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001538:	00f57793          	andi	a5,a0,15
    8000153c:	ff3782e3          	beq	a5,s3,80001520 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001540:	8905                	andi	a0,a0,1
    80001542:	d57d                	beqz	a0,80001530 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001544:	00007517          	auipc	a0,0x7
    80001548:	c4450513          	addi	a0,a0,-956 # 80008188 <digits+0x148>
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	ff4080e7          	jalr	-12(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001554:	8552                	mv	a0,s4
    80001556:	fffff097          	auipc	ra,0xfffff
    8000155a:	4ba080e7          	jalr	1210(ra) # 80000a10 <kfree>
}
    8000155e:	70a2                	ld	ra,40(sp)
    80001560:	7402                	ld	s0,32(sp)
    80001562:	64e2                	ld	s1,24(sp)
    80001564:	6942                	ld	s2,16(sp)
    80001566:	69a2                	ld	s3,8(sp)
    80001568:	6a02                	ld	s4,0(sp)
    8000156a:	6145                	addi	sp,sp,48
    8000156c:	8082                	ret

000000008000156e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000156e:	1101                	addi	sp,sp,-32
    80001570:	ec06                	sd	ra,24(sp)
    80001572:	e822                	sd	s0,16(sp)
    80001574:	e426                	sd	s1,8(sp)
    80001576:	1000                	addi	s0,sp,32
    80001578:	84aa                	mv	s1,a0
  if(sz > 0)
    8000157a:	e999                	bnez	a1,80001590 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000157c:	8526                	mv	a0,s1
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	f86080e7          	jalr	-122(ra) # 80001504 <freewalk>
}
    80001586:	60e2                	ld	ra,24(sp)
    80001588:	6442                	ld	s0,16(sp)
    8000158a:	64a2                	ld	s1,8(sp)
    8000158c:	6105                	addi	sp,sp,32
    8000158e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001590:	6605                	lui	a2,0x1
    80001592:	167d                	addi	a2,a2,-1
    80001594:	962e                	add	a2,a2,a1
    80001596:	4685                	li	a3,1
    80001598:	8231                	srli	a2,a2,0xc
    8000159a:	4581                	li	a1,0
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	d12080e7          	jalr	-750(ra) # 800012ae <uvmunmap>
    800015a4:	bfe1                	j	8000157c <uvmfree+0xe>

00000000800015a6 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015a6:	c679                	beqz	a2,80001674 <uvmcopy+0xce>
{
    800015a8:	715d                	addi	sp,sp,-80
    800015aa:	e486                	sd	ra,72(sp)
    800015ac:	e0a2                	sd	s0,64(sp)
    800015ae:	fc26                	sd	s1,56(sp)
    800015b0:	f84a                	sd	s2,48(sp)
    800015b2:	f44e                	sd	s3,40(sp)
    800015b4:	f052                	sd	s4,32(sp)
    800015b6:	ec56                	sd	s5,24(sp)
    800015b8:	e85a                	sd	s6,16(sp)
    800015ba:	e45e                	sd	s7,8(sp)
    800015bc:	0880                	addi	s0,sp,80
    800015be:	8b2a                	mv	s6,a0
    800015c0:	8aae                	mv	s5,a1
    800015c2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015c4:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015c6:	4601                	li	a2,0
    800015c8:	85ce                	mv	a1,s3
    800015ca:	855a                	mv	a0,s6
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	a04080e7          	jalr	-1532(ra) # 80000fd0 <walk>
    800015d4:	c531                	beqz	a0,80001620 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015d6:	6118                	ld	a4,0(a0)
    800015d8:	00177793          	andi	a5,a4,1
    800015dc:	cbb1                	beqz	a5,80001630 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015de:	00a75593          	srli	a1,a4,0xa
    800015e2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015e6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	522080e7          	jalr	1314(ra) # 80000b0c <kalloc>
    800015f2:	892a                	mv	s2,a0
    800015f4:	c939                	beqz	a0,8000164a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015f6:	6605                	lui	a2,0x1
    800015f8:	85de                	mv	a1,s7
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	75a080e7          	jalr	1882(ra) # 80000d54 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001602:	8726                	mv	a4,s1
    80001604:	86ca                	mv	a3,s2
    80001606:	6605                	lui	a2,0x1
    80001608:	85ce                	mv	a1,s3
    8000160a:	8556                	mv	a0,s5
    8000160c:	00000097          	auipc	ra,0x0
    80001610:	b0a080e7          	jalr	-1270(ra) # 80001116 <mappages>
    80001614:	e515                	bnez	a0,80001640 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001616:	6785                	lui	a5,0x1
    80001618:	99be                	add	s3,s3,a5
    8000161a:	fb49e6e3          	bltu	s3,s4,800015c6 <uvmcopy+0x20>
    8000161e:	a081                	j	8000165e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001620:	00007517          	auipc	a0,0x7
    80001624:	b7850513          	addi	a0,a0,-1160 # 80008198 <digits+0x158>
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	f18080e7          	jalr	-232(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    80001630:	00007517          	auipc	a0,0x7
    80001634:	b8850513          	addi	a0,a0,-1144 # 800081b8 <digits+0x178>
    80001638:	fffff097          	auipc	ra,0xfffff
    8000163c:	f08080e7          	jalr	-248(ra) # 80000540 <panic>
      kfree(mem);
    80001640:	854a                	mv	a0,s2
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	3ce080e7          	jalr	974(ra) # 80000a10 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000164a:	4685                	li	a3,1
    8000164c:	00c9d613          	srli	a2,s3,0xc
    80001650:	4581                	li	a1,0
    80001652:	8556                	mv	a0,s5
    80001654:	00000097          	auipc	ra,0x0
    80001658:	c5a080e7          	jalr	-934(ra) # 800012ae <uvmunmap>
  return -1;
    8000165c:	557d                	li	a0,-1
}
    8000165e:	60a6                	ld	ra,72(sp)
    80001660:	6406                	ld	s0,64(sp)
    80001662:	74e2                	ld	s1,56(sp)
    80001664:	7942                	ld	s2,48(sp)
    80001666:	79a2                	ld	s3,40(sp)
    80001668:	7a02                	ld	s4,32(sp)
    8000166a:	6ae2                	ld	s5,24(sp)
    8000166c:	6b42                	ld	s6,16(sp)
    8000166e:	6ba2                	ld	s7,8(sp)
    80001670:	6161                	addi	sp,sp,80
    80001672:	8082                	ret
  return 0;
    80001674:	4501                	li	a0,0
}
    80001676:	8082                	ret

0000000080001678 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001678:	1141                	addi	sp,sp,-16
    8000167a:	e406                	sd	ra,8(sp)
    8000167c:	e022                	sd	s0,0(sp)
    8000167e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001680:	4601                	li	a2,0
    80001682:	00000097          	auipc	ra,0x0
    80001686:	94e080e7          	jalr	-1714(ra) # 80000fd0 <walk>
  if(pte == 0)
    8000168a:	c901                	beqz	a0,8000169a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000168c:	611c                	ld	a5,0(a0)
    8000168e:	9bbd                	andi	a5,a5,-17
    80001690:	e11c                	sd	a5,0(a0)
}
    80001692:	60a2                	ld	ra,8(sp)
    80001694:	6402                	ld	s0,0(sp)
    80001696:	0141                	addi	sp,sp,16
    80001698:	8082                	ret
    panic("uvmclear");
    8000169a:	00007517          	auipc	a0,0x7
    8000169e:	b3e50513          	addi	a0,a0,-1218 # 800081d8 <digits+0x198>
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	e9e080e7          	jalr	-354(ra) # 80000540 <panic>

00000000800016aa <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016aa:	c6bd                	beqz	a3,80001718 <copyout+0x6e>
{
    800016ac:	715d                	addi	sp,sp,-80
    800016ae:	e486                	sd	ra,72(sp)
    800016b0:	e0a2                	sd	s0,64(sp)
    800016b2:	fc26                	sd	s1,56(sp)
    800016b4:	f84a                	sd	s2,48(sp)
    800016b6:	f44e                	sd	s3,40(sp)
    800016b8:	f052                	sd	s4,32(sp)
    800016ba:	ec56                	sd	s5,24(sp)
    800016bc:	e85a                	sd	s6,16(sp)
    800016be:	e45e                	sd	s7,8(sp)
    800016c0:	e062                	sd	s8,0(sp)
    800016c2:	0880                	addi	s0,sp,80
    800016c4:	8b2a                	mv	s6,a0
    800016c6:	8c2e                	mv	s8,a1
    800016c8:	8a32                	mv	s4,a2
    800016ca:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016cc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ce:	6a85                	lui	s5,0x1
    800016d0:	a015                	j	800016f4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016d2:	9562                	add	a0,a0,s8
    800016d4:	0004861b          	sext.w	a2,s1
    800016d8:	85d2                	mv	a1,s4
    800016da:	41250533          	sub	a0,a0,s2
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	676080e7          	jalr	1654(ra) # 80000d54 <memmove>

    len -= n;
    800016e6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ea:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ec:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016f0:	02098263          	beqz	s3,80001714 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016f8:	85ca                	mv	a1,s2
    800016fa:	855a                	mv	a0,s6
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	97a080e7          	jalr	-1670(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001704:	cd01                	beqz	a0,8000171c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001706:	418904b3          	sub	s1,s2,s8
    8000170a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000170c:	fc99f3e3          	bgeu	s3,s1,800016d2 <copyout+0x28>
    80001710:	84ce                	mv	s1,s3
    80001712:	b7c1                	j	800016d2 <copyout+0x28>
  }
  return 0;
    80001714:	4501                	li	a0,0
    80001716:	a021                	j	8000171e <copyout+0x74>
    80001718:	4501                	li	a0,0
}
    8000171a:	8082                	ret
      return -1;
    8000171c:	557d                	li	a0,-1
}
    8000171e:	60a6                	ld	ra,72(sp)
    80001720:	6406                	ld	s0,64(sp)
    80001722:	74e2                	ld	s1,56(sp)
    80001724:	7942                	ld	s2,48(sp)
    80001726:	79a2                	ld	s3,40(sp)
    80001728:	7a02                	ld	s4,32(sp)
    8000172a:	6ae2                	ld	s5,24(sp)
    8000172c:	6b42                	ld	s6,16(sp)
    8000172e:	6ba2                	ld	s7,8(sp)
    80001730:	6c02                	ld	s8,0(sp)
    80001732:	6161                	addi	sp,sp,80
    80001734:	8082                	ret

0000000080001736 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001736:	caa5                	beqz	a3,800017a6 <copyin+0x70>
{
    80001738:	715d                	addi	sp,sp,-80
    8000173a:	e486                	sd	ra,72(sp)
    8000173c:	e0a2                	sd	s0,64(sp)
    8000173e:	fc26                	sd	s1,56(sp)
    80001740:	f84a                	sd	s2,48(sp)
    80001742:	f44e                	sd	s3,40(sp)
    80001744:	f052                	sd	s4,32(sp)
    80001746:	ec56                	sd	s5,24(sp)
    80001748:	e85a                	sd	s6,16(sp)
    8000174a:	e45e                	sd	s7,8(sp)
    8000174c:	e062                	sd	s8,0(sp)
    8000174e:	0880                	addi	s0,sp,80
    80001750:	8b2a                	mv	s6,a0
    80001752:	8a2e                	mv	s4,a1
    80001754:	8c32                	mv	s8,a2
    80001756:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001758:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000175a:	6a85                	lui	s5,0x1
    8000175c:	a01d                	j	80001782 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000175e:	018505b3          	add	a1,a0,s8
    80001762:	0004861b          	sext.w	a2,s1
    80001766:	412585b3          	sub	a1,a1,s2
    8000176a:	8552                	mv	a0,s4
    8000176c:	fffff097          	auipc	ra,0xfffff
    80001770:	5e8080e7          	jalr	1512(ra) # 80000d54 <memmove>

    len -= n;
    80001774:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001778:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000177a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000177e:	02098263          	beqz	s3,800017a2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001782:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001786:	85ca                	mv	a1,s2
    80001788:	855a                	mv	a0,s6
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	8ec080e7          	jalr	-1812(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001792:	cd01                	beqz	a0,800017aa <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001794:	418904b3          	sub	s1,s2,s8
    80001798:	94d6                	add	s1,s1,s5
    if(n > len)
    8000179a:	fc99f2e3          	bgeu	s3,s1,8000175e <copyin+0x28>
    8000179e:	84ce                	mv	s1,s3
    800017a0:	bf7d                	j	8000175e <copyin+0x28>
  }
  return 0;
    800017a2:	4501                	li	a0,0
    800017a4:	a021                	j	800017ac <copyin+0x76>
    800017a6:	4501                	li	a0,0
}
    800017a8:	8082                	ret
      return -1;
    800017aa:	557d                	li	a0,-1
}
    800017ac:	60a6                	ld	ra,72(sp)
    800017ae:	6406                	ld	s0,64(sp)
    800017b0:	74e2                	ld	s1,56(sp)
    800017b2:	7942                	ld	s2,48(sp)
    800017b4:	79a2                	ld	s3,40(sp)
    800017b6:	7a02                	ld	s4,32(sp)
    800017b8:	6ae2                	ld	s5,24(sp)
    800017ba:	6b42                	ld	s6,16(sp)
    800017bc:	6ba2                	ld	s7,8(sp)
    800017be:	6c02                	ld	s8,0(sp)
    800017c0:	6161                	addi	sp,sp,80
    800017c2:	8082                	ret

00000000800017c4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017c4:	c6c5                	beqz	a3,8000186c <copyinstr+0xa8>
{
    800017c6:	715d                	addi	sp,sp,-80
    800017c8:	e486                	sd	ra,72(sp)
    800017ca:	e0a2                	sd	s0,64(sp)
    800017cc:	fc26                	sd	s1,56(sp)
    800017ce:	f84a                	sd	s2,48(sp)
    800017d0:	f44e                	sd	s3,40(sp)
    800017d2:	f052                	sd	s4,32(sp)
    800017d4:	ec56                	sd	s5,24(sp)
    800017d6:	e85a                	sd	s6,16(sp)
    800017d8:	e45e                	sd	s7,8(sp)
    800017da:	0880                	addi	s0,sp,80
    800017dc:	8a2a                	mv	s4,a0
    800017de:	8b2e                	mv	s6,a1
    800017e0:	8bb2                	mv	s7,a2
    800017e2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017e4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e6:	6985                	lui	s3,0x1
    800017e8:	a035                	j	80001814 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ea:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ee:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017f0:	0017b793          	seqz	a5,a5
    800017f4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017f8:	60a6                	ld	ra,72(sp)
    800017fa:	6406                	ld	s0,64(sp)
    800017fc:	74e2                	ld	s1,56(sp)
    800017fe:	7942                	ld	s2,48(sp)
    80001800:	79a2                	ld	s3,40(sp)
    80001802:	7a02                	ld	s4,32(sp)
    80001804:	6ae2                	ld	s5,24(sp)
    80001806:	6b42                	ld	s6,16(sp)
    80001808:	6ba2                	ld	s7,8(sp)
    8000180a:	6161                	addi	sp,sp,80
    8000180c:	8082                	ret
    srcva = va0 + PGSIZE;
    8000180e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001812:	c8a9                	beqz	s1,80001864 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001814:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001818:	85ca                	mv	a1,s2
    8000181a:	8552                	mv	a0,s4
    8000181c:	00000097          	auipc	ra,0x0
    80001820:	85a080e7          	jalr	-1958(ra) # 80001076 <walkaddr>
    if(pa0 == 0)
    80001824:	c131                	beqz	a0,80001868 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001826:	41790833          	sub	a6,s2,s7
    8000182a:	984e                	add	a6,a6,s3
    if(n > max)
    8000182c:	0104f363          	bgeu	s1,a6,80001832 <copyinstr+0x6e>
    80001830:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001832:	955e                	add	a0,a0,s7
    80001834:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001838:	fc080be3          	beqz	a6,8000180e <copyinstr+0x4a>
    8000183c:	985a                	add	a6,a6,s6
    8000183e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001840:	41650633          	sub	a2,a0,s6
    80001844:	14fd                	addi	s1,s1,-1
    80001846:	9b26                	add	s6,s6,s1
    80001848:	00f60733          	add	a4,a2,a5
    8000184c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    80001850:	df49                	beqz	a4,800017ea <copyinstr+0x26>
        *dst = *p;
    80001852:	00e78023          	sb	a4,0(a5)
      --max;
    80001856:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000185a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000185c:	ff0796e3          	bne	a5,a6,80001848 <copyinstr+0x84>
      dst++;
    80001860:	8b42                	mv	s6,a6
    80001862:	b775                	j	8000180e <copyinstr+0x4a>
    80001864:	4781                	li	a5,0
    80001866:	b769                	j	800017f0 <copyinstr+0x2c>
      return -1;
    80001868:	557d                	li	a0,-1
    8000186a:	b779                	j	800017f8 <copyinstr+0x34>
  int got_null = 0;
    8000186c:	4781                	li	a5,0
  if(got_null){
    8000186e:	0017b793          	seqz	a5,a5
    80001872:	40f00533          	neg	a0,a5
}
    80001876:	8082                	ret

0000000080001878 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001878:	1101                	addi	sp,sp,-32
    8000187a:	ec06                	sd	ra,24(sp)
    8000187c:	e822                	sd	s0,16(sp)
    8000187e:	e426                	sd	s1,8(sp)
    80001880:	1000                	addi	s0,sp,32
    80001882:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001884:	fffff097          	auipc	ra,0xfffff
    80001888:	2fe080e7          	jalr	766(ra) # 80000b82 <holding>
    8000188c:	c909                	beqz	a0,8000189e <wakeup1+0x26>
    panic("wakeup1");
  if (p->chan == p && p->state == SLEEPING)
    8000188e:	749c                	ld	a5,40(s1)
    80001890:	00978f63          	beq	a5,s1,800018ae <wakeup1+0x36>
  {
    p->state = RUNNABLE;
    // should be moved to Q2
    p->change = 3;
  }
}
    80001894:	60e2                	ld	ra,24(sp)
    80001896:	6442                	ld	s0,16(sp)
    80001898:	64a2                	ld	s1,8(sp)
    8000189a:	6105                	addi	sp,sp,32
    8000189c:	8082                	ret
    panic("wakeup1");
    8000189e:	00007517          	auipc	a0,0x7
    800018a2:	94a50513          	addi	a0,a0,-1718 # 800081e8 <digits+0x1a8>
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	c9a080e7          	jalr	-870(ra) # 80000540 <panic>
  if (p->chan == p && p->state == SLEEPING)
    800018ae:	4c98                	lw	a4,24(s1)
    800018b0:	4785                	li	a5,1
    800018b2:	fef711e3          	bne	a4,a5,80001894 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018b6:	4789                	li	a5,2
    800018b8:	cc9c                	sw	a5,24(s1)
    p->change = 3;
    800018ba:	478d                	li	a5,3
    800018bc:	16f4a423          	sw	a5,360(s1)
}
    800018c0:	bfd1                	j	80001894 <wakeup1+0x1c>

00000000800018c2 <getportion>:
{
    800018c2:	1141                	addi	sp,sp,-16
    800018c4:	e422                	sd	s0,8(sp)
    800018c6:	0800                	addi	s0,sp,16
  int total = p->Qtime[2] + p->Qtime[1] + p->Qtime[0];
    800018c8:	17452683          	lw	a3,372(a0)
    800018cc:	17052703          	lw	a4,368(a0)
    800018d0:	16c52583          	lw	a1,364(a0)
    800018d4:	00e6863b          	addw	a2,a3,a4
    800018d8:	9e2d                	addw	a2,a2,a1
  p->Qtime[2] = p->Qtime[2] * 100 / total;
    800018da:	06400793          	li	a5,100
    800018de:	02d786bb          	mulw	a3,a5,a3
    800018e2:	02c6c6bb          	divw	a3,a3,a2
    800018e6:	16d52a23          	sw	a3,372(a0)
  p->Qtime[1] = p->Qtime[1] * 100 / total;
    800018ea:	02e7873b          	mulw	a4,a5,a4
    800018ee:	02c7473b          	divw	a4,a4,a2
    800018f2:	16e52823          	sw	a4,368(a0)
  p->Qtime[0] = p->Qtime[0] * 100 / total;
    800018f6:	02b787bb          	mulw	a5,a5,a1
    800018fa:	02c7c7bb          	divw	a5,a5,a2
    800018fe:	16f52623          	sw	a5,364(a0)
}
    80001902:	6422                	ld	s0,8(sp)
    80001904:	0141                	addi	sp,sp,16
    80001906:	8082                	ret

0000000080001908 <findproc>:
{
    80001908:	1141                	addi	sp,sp,-16
    8000190a:	e422                	sd	s0,8(sp)
    8000190c:	0800                	addi	s0,sp,16
    if (Q[priority][index] == obj)
    8000190e:	00959713          	slli	a4,a1,0x9
    80001912:	00010797          	auipc	a5,0x10
    80001916:	03e78793          	addi	a5,a5,62 # 80011950 <Q>
    8000191a:	97ba                	add	a5,a5,a4
    8000191c:	639c                	ld	a5,0(a5)
    8000191e:	02f50263          	beq	a0,a5,80001942 <findproc+0x3a>
    80001922:	86aa                	mv	a3,a0
    80001924:	00010797          	auipc	a5,0x10
    80001928:	03478793          	addi	a5,a5,52 # 80011958 <Q+0x8>
    8000192c:	97ba                	add	a5,a5,a4
  int index = 0;
    8000192e:	4501                	li	a0,0
    index++;
    80001930:	2505                	addiw	a0,a0,1
    if (Q[priority][index] == obj)
    80001932:	07a1                	addi	a5,a5,8
    80001934:	ff87b703          	ld	a4,-8(a5)
    80001938:	fed71ce3          	bne	a4,a3,80001930 <findproc+0x28>
}
    8000193c:	6422                	ld	s0,8(sp)
    8000193e:	0141                	addi	sp,sp,16
    80001940:	8082                	ret
  int index = 0;
    80001942:	4501                	li	a0,0
    80001944:	bfe5                	j	8000193c <findproc+0x34>

0000000080001946 <movequeue>:
{
    80001946:	7179                	addi	sp,sp,-48
    80001948:	f406                	sd	ra,40(sp)
    8000194a:	f022                	sd	s0,32(sp)
    8000194c:	ec26                	sd	s1,24(sp)
    8000194e:	e84a                	sd	s2,16(sp)
    80001950:	e44e                	sd	s3,8(sp)
    80001952:	1800                	addi	s0,sp,48
    80001954:	84aa                	mv	s1,a0
    80001956:	892e                	mv	s2,a1
  if (opt != INSERT)
    80001958:	4785                	li	a5,1
    8000195a:	06f60163          	beq	a2,a5,800019bc <movequeue+0x76>
    8000195e:	89b2                	mv	s3,a2
    int pos = findproc(obj, obj->priority);
    80001960:	17852583          	lw	a1,376(a0)
    80001964:	00000097          	auipc	ra,0x0
    80001968:	fa4080e7          	jalr	-92(ra) # 80001908 <findproc>
    for (int i = pos; i < NPROC - 1; i++)
    8000196c:	03e00793          	li	a5,62
    80001970:	02a7c863          	blt	a5,a0,800019a0 <movequeue+0x5a>
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    80001974:	00010697          	auipc	a3,0x10
    80001978:	fdc68693          	addi	a3,a3,-36 # 80011950 <Q>
    for (int i = pos; i < NPROC - 1; i++)
    8000197c:	03f00593          	li	a1,63
      Q[obj->priority][i] = Q[obj->priority][i + 1];
    80001980:	1784a783          	lw	a5,376(s1)
    80001984:	862a                	mv	a2,a0
    80001986:	2505                	addiw	a0,a0,1
    80001988:	079a                	slli	a5,a5,0x6
    8000198a:	00a78733          	add	a4,a5,a0
    8000198e:	070e                	slli	a4,a4,0x3
    80001990:	9736                	add	a4,a4,a3
    80001992:	6318                	ld	a4,0(a4)
    80001994:	97b2                	add	a5,a5,a2
    80001996:	078e                	slli	a5,a5,0x3
    80001998:	97b6                	add	a5,a5,a3
    8000199a:	e398                	sd	a4,0(a5)
    for (int i = pos; i < NPROC - 1; i++)
    8000199c:	feb512e3          	bne	a0,a1,80001980 <movequeue+0x3a>
    Q[obj->priority][NPROC - 1] = 0;
    800019a0:	1784a783          	lw	a5,376(s1)
    800019a4:	00979713          	slli	a4,a5,0x9
    800019a8:	00010797          	auipc	a5,0x10
    800019ac:	fa878793          	addi	a5,a5,-88 # 80011950 <Q>
    800019b0:	97ba                	add	a5,a5,a4
    800019b2:	1e07bc23          	sd	zero,504(a5)
  if (opt != DELETE)
    800019b6:	4789                	li	a5,2
    800019b8:	02f98463          	beq	s3,a5,800019e0 <movequeue+0x9a>
    int endstart = findproc(0, priority);
    800019bc:	85ca                	mv	a1,s2
    800019be:	4501                	li	a0,0
    800019c0:	00000097          	auipc	ra,0x0
    800019c4:	f48080e7          	jalr	-184(ra) # 80001908 <findproc>
    Q[priority][endstart] = obj;
    800019c8:	00691793          	slli	a5,s2,0x6
    800019cc:	97aa                	add	a5,a5,a0
    800019ce:	078e                	slli	a5,a5,0x3
    800019d0:	00010717          	auipc	a4,0x10
    800019d4:	f8070713          	addi	a4,a4,-128 # 80011950 <Q>
    800019d8:	97ba                	add	a5,a5,a4
    800019da:	e384                	sd	s1,0(a5)
    obj->priority = priority;
    800019dc:	1724ac23          	sw	s2,376(s1)
  obj->change = 0;
    800019e0:	1604a423          	sw	zero,360(s1)
}
    800019e4:	70a2                	ld	ra,40(sp)
    800019e6:	7402                	ld	s0,32(sp)
    800019e8:	64e2                	ld	s1,24(sp)
    800019ea:	6942                	ld	s2,16(sp)
    800019ec:	69a2                	ld	s3,8(sp)
    800019ee:	6145                	addi	sp,sp,48
    800019f0:	8082                	ret

00000000800019f2 <procinit>:
{
    800019f2:	715d                	addi	sp,sp,-80
    800019f4:	e486                	sd	ra,72(sp)
    800019f6:	e0a2                	sd	s0,64(sp)
    800019f8:	fc26                	sd	s1,56(sp)
    800019fa:	f84a                	sd	s2,48(sp)
    800019fc:	f44e                	sd	s3,40(sp)
    800019fe:	f052                	sd	s4,32(sp)
    80001a00:	ec56                	sd	s5,24(sp)
    80001a02:	e85a                	sd	s6,16(sp)
    80001a04:	e45e                	sd	s7,8(sp)
    80001a06:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a08:	00006597          	auipc	a1,0x6
    80001a0c:	7e858593          	addi	a1,a1,2024 # 800081f0 <digits+0x1b0>
    80001a10:	00010517          	auipc	a0,0x10
    80001a14:	54050513          	addi	a0,a0,1344 # 80011f50 <pid_lock>
    80001a18:	fffff097          	auipc	ra,0xfffff
    80001a1c:	154080e7          	jalr	340(ra) # 80000b6c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001a20:	00011917          	auipc	s2,0x11
    80001a24:	a4890913          	addi	s2,s2,-1464 # 80012468 <proc>
    initlock(&p->lock, "proc");
    80001a28:	00006b97          	auipc	s7,0x6
    80001a2c:	7d0b8b93          	addi	s7,s7,2000 # 800081f8 <digits+0x1b8>
    uint64 va = KSTACK((int)(p - proc));
    80001a30:	8b4a                	mv	s6,s2
    80001a32:	00006a97          	auipc	s5,0x6
    80001a36:	5cea8a93          	addi	s5,s5,1486 # 80008000 <etext>
    80001a3a:	040009b7          	lui	s3,0x4000
    80001a3e:	19fd                	addi	s3,s3,-1
    80001a40:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001a42:	00017a17          	auipc	s4,0x17
    80001a46:	a26a0a13          	addi	s4,s4,-1498 # 80018468 <tickslock>
    initlock(&p->lock, "proc");
    80001a4a:	85de                	mv	a1,s7
    80001a4c:	854a                	mv	a0,s2
    80001a4e:	fffff097          	auipc	ra,0xfffff
    80001a52:	11e080e7          	jalr	286(ra) # 80000b6c <initlock>
    char *pa = kalloc();
    80001a56:	fffff097          	auipc	ra,0xfffff
    80001a5a:	0b6080e7          	jalr	182(ra) # 80000b0c <kalloc>
    80001a5e:	85aa                	mv	a1,a0
    if (pa == 0)
    80001a60:	c929                	beqz	a0,80001ab2 <procinit+0xc0>
    uint64 va = KSTACK((int)(p - proc));
    80001a62:	416904b3          	sub	s1,s2,s6
    80001a66:	849d                	srai	s1,s1,0x7
    80001a68:	000ab783          	ld	a5,0(s5)
    80001a6c:	02f484b3          	mul	s1,s1,a5
    80001a70:	2485                	addiw	s1,s1,1
    80001a72:	00d4949b          	slliw	s1,s1,0xd
    80001a76:	409984b3          	sub	s1,s3,s1
    kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a7a:	4699                	li	a3,6
    80001a7c:	6605                	lui	a2,0x1
    80001a7e:	8526                	mv	a0,s1
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	724080e7          	jalr	1828(ra) # 800011a4 <kvmmap>
    p->kstack = va;
    80001a88:	04993023          	sd	s1,64(s2)
  for (p = proc; p < &proc[NPROC]; p++)
    80001a8c:	18090913          	addi	s2,s2,384
    80001a90:	fb491de3          	bne	s2,s4,80001a4a <procinit+0x58>
  kvminithart();
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	518080e7          	jalr	1304(ra) # 80000fac <kvminithart>
}
    80001a9c:	60a6                	ld	ra,72(sp)
    80001a9e:	6406                	ld	s0,64(sp)
    80001aa0:	74e2                	ld	s1,56(sp)
    80001aa2:	7942                	ld	s2,48(sp)
    80001aa4:	79a2                	ld	s3,40(sp)
    80001aa6:	7a02                	ld	s4,32(sp)
    80001aa8:	6ae2                	ld	s5,24(sp)
    80001aaa:	6b42                	ld	s6,16(sp)
    80001aac:	6ba2                	ld	s7,8(sp)
    80001aae:	6161                	addi	sp,sp,80
    80001ab0:	8082                	ret
      panic("kalloc");
    80001ab2:	00006517          	auipc	a0,0x6
    80001ab6:	74e50513          	addi	a0,a0,1870 # 80008200 <digits+0x1c0>
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	a86080e7          	jalr	-1402(ra) # 80000540 <panic>

0000000080001ac2 <cpuid>:
{
    80001ac2:	1141                	addi	sp,sp,-16
    80001ac4:	e422                	sd	s0,8(sp)
    80001ac6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ac8:	8512                	mv	a0,tp
}
    80001aca:	2501                	sext.w	a0,a0
    80001acc:	6422                	ld	s0,8(sp)
    80001ace:	0141                	addi	sp,sp,16
    80001ad0:	8082                	ret

0000000080001ad2 <mycpu>:
{
    80001ad2:	1141                	addi	sp,sp,-16
    80001ad4:	e422                	sd	s0,8(sp)
    80001ad6:	0800                	addi	s0,sp,16
    80001ad8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ada:	2781                	sext.w	a5,a5
    80001adc:	079e                	slli	a5,a5,0x7
}
    80001ade:	00010517          	auipc	a0,0x10
    80001ae2:	48a50513          	addi	a0,a0,1162 # 80011f68 <cpus>
    80001ae6:	953e                	add	a0,a0,a5
    80001ae8:	6422                	ld	s0,8(sp)
    80001aea:	0141                	addi	sp,sp,16
    80001aec:	8082                	ret

0000000080001aee <myproc>:
{
    80001aee:	1101                	addi	sp,sp,-32
    80001af0:	ec06                	sd	ra,24(sp)
    80001af2:	e822                	sd	s0,16(sp)
    80001af4:	e426                	sd	s1,8(sp)
    80001af6:	1000                	addi	s0,sp,32
  push_off();
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	0b8080e7          	jalr	184(ra) # 80000bb0 <push_off>
    80001b00:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b02:	2781                	sext.w	a5,a5
    80001b04:	079e                	slli	a5,a5,0x7
    80001b06:	00010717          	auipc	a4,0x10
    80001b0a:	e4a70713          	addi	a4,a4,-438 # 80011950 <Q>
    80001b0e:	97ba                	add	a5,a5,a4
    80001b10:	6187b483          	ld	s1,1560(a5)
  pop_off();
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	13c080e7          	jalr	316(ra) # 80000c50 <pop_off>
}
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	60e2                	ld	ra,24(sp)
    80001b20:	6442                	ld	s0,16(sp)
    80001b22:	64a2                	ld	s1,8(sp)
    80001b24:	6105                	addi	sp,sp,32
    80001b26:	8082                	ret

0000000080001b28 <forkret>:
{
    80001b28:	1141                	addi	sp,sp,-16
    80001b2a:	e406                	sd	ra,8(sp)
    80001b2c:	e022                	sd	s0,0(sp)
    80001b2e:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b30:	00000097          	auipc	ra,0x0
    80001b34:	fbe080e7          	jalr	-66(ra) # 80001aee <myproc>
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	178080e7          	jalr	376(ra) # 80000cb0 <release>
  if (first)
    80001b40:	00007797          	auipc	a5,0x7
    80001b44:	d207a783          	lw	a5,-736(a5) # 80008860 <first.1>
    80001b48:	eb89                	bnez	a5,80001b5a <forkret+0x32>
  usertrapret();
    80001b4a:	00001097          	auipc	ra,0x1
    80001b4e:	e5a080e7          	jalr	-422(ra) # 800029a4 <usertrapret>
}
    80001b52:	60a2                	ld	ra,8(sp)
    80001b54:	6402                	ld	s0,0(sp)
    80001b56:	0141                	addi	sp,sp,16
    80001b58:	8082                	ret
    first = 0;
    80001b5a:	00007797          	auipc	a5,0x7
    80001b5e:	d007a323          	sw	zero,-762(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001b62:	4505                	li	a0,1
    80001b64:	00002097          	auipc	ra,0x2
    80001b68:	baa080e7          	jalr	-1110(ra) # 8000370e <fsinit>
    80001b6c:	bff9                	j	80001b4a <forkret+0x22>

0000000080001b6e <allocpid>:
{
    80001b6e:	1101                	addi	sp,sp,-32
    80001b70:	ec06                	sd	ra,24(sp)
    80001b72:	e822                	sd	s0,16(sp)
    80001b74:	e426                	sd	s1,8(sp)
    80001b76:	e04a                	sd	s2,0(sp)
    80001b78:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b7a:	00010917          	auipc	s2,0x10
    80001b7e:	3d690913          	addi	s2,s2,982 # 80011f50 <pid_lock>
    80001b82:	854a                	mv	a0,s2
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	078080e7          	jalr	120(ra) # 80000bfc <acquire>
  pid = nextpid;
    80001b8c:	00007797          	auipc	a5,0x7
    80001b90:	cd878793          	addi	a5,a5,-808 # 80008864 <nextpid>
    80001b94:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b96:	0014871b          	addiw	a4,s1,1
    80001b9a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b9c:	854a                	mv	a0,s2
    80001b9e:	fffff097          	auipc	ra,0xfffff
    80001ba2:	112080e7          	jalr	274(ra) # 80000cb0 <release>
}
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6902                	ld	s2,0(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret

0000000080001bb4 <proc_pagetable>:
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	e04a                	sd	s2,0(sp)
    80001bbe:	1000                	addi	s0,sp,32
    80001bc0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bc2:	fffff097          	auipc	ra,0xfffff
    80001bc6:	7b0080e7          	jalr	1968(ra) # 80001372 <uvmcreate>
    80001bca:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bcc:	c121                	beqz	a0,80001c0c <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bce:	4729                	li	a4,10
    80001bd0:	00005697          	auipc	a3,0x5
    80001bd4:	43068693          	addi	a3,a3,1072 # 80007000 <_trampoline>
    80001bd8:	6605                	lui	a2,0x1
    80001bda:	040005b7          	lui	a1,0x4000
    80001bde:	15fd                	addi	a1,a1,-1
    80001be0:	05b2                	slli	a1,a1,0xc
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	534080e7          	jalr	1332(ra) # 80001116 <mappages>
    80001bea:	02054863          	bltz	a0,80001c1a <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bee:	4719                	li	a4,6
    80001bf0:	05893683          	ld	a3,88(s2)
    80001bf4:	6605                	lui	a2,0x1
    80001bf6:	020005b7          	lui	a1,0x2000
    80001bfa:	15fd                	addi	a1,a1,-1
    80001bfc:	05b6                	slli	a1,a1,0xd
    80001bfe:	8526                	mv	a0,s1
    80001c00:	fffff097          	auipc	ra,0xfffff
    80001c04:	516080e7          	jalr	1302(ra) # 80001116 <mappages>
    80001c08:	02054163          	bltz	a0,80001c2a <proc_pagetable+0x76>
}
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	60e2                	ld	ra,24(sp)
    80001c10:	6442                	ld	s0,16(sp)
    80001c12:	64a2                	ld	s1,8(sp)
    80001c14:	6902                	ld	s2,0(sp)
    80001c16:	6105                	addi	sp,sp,32
    80001c18:	8082                	ret
    uvmfree(pagetable, 0);
    80001c1a:	4581                	li	a1,0
    80001c1c:	8526                	mv	a0,s1
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	950080e7          	jalr	-1712(ra) # 8000156e <uvmfree>
    return 0;
    80001c26:	4481                	li	s1,0
    80001c28:	b7d5                	j	80001c0c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c2a:	4681                	li	a3,0
    80001c2c:	4605                	li	a2,1
    80001c2e:	040005b7          	lui	a1,0x4000
    80001c32:	15fd                	addi	a1,a1,-1
    80001c34:	05b2                	slli	a1,a1,0xc
    80001c36:	8526                	mv	a0,s1
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	676080e7          	jalr	1654(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001c40:	4581                	li	a1,0
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	92a080e7          	jalr	-1750(ra) # 8000156e <uvmfree>
    return 0;
    80001c4c:	4481                	li	s1,0
    80001c4e:	bf7d                	j	80001c0c <proc_pagetable+0x58>

0000000080001c50 <proc_freepagetable>:
{
    80001c50:	1101                	addi	sp,sp,-32
    80001c52:	ec06                	sd	ra,24(sp)
    80001c54:	e822                	sd	s0,16(sp)
    80001c56:	e426                	sd	s1,8(sp)
    80001c58:	e04a                	sd	s2,0(sp)
    80001c5a:	1000                	addi	s0,sp,32
    80001c5c:	84aa                	mv	s1,a0
    80001c5e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c60:	4681                	li	a3,0
    80001c62:	4605                	li	a2,1
    80001c64:	040005b7          	lui	a1,0x4000
    80001c68:	15fd                	addi	a1,a1,-1
    80001c6a:	05b2                	slli	a1,a1,0xc
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	642080e7          	jalr	1602(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c74:	4681                	li	a3,0
    80001c76:	4605                	li	a2,1
    80001c78:	020005b7          	lui	a1,0x2000
    80001c7c:	15fd                	addi	a1,a1,-1
    80001c7e:	05b6                	slli	a1,a1,0xd
    80001c80:	8526                	mv	a0,s1
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	62c080e7          	jalr	1580(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001c8a:	85ca                	mv	a1,s2
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	8e0080e7          	jalr	-1824(ra) # 8000156e <uvmfree>
}
    80001c96:	60e2                	ld	ra,24(sp)
    80001c98:	6442                	ld	s0,16(sp)
    80001c9a:	64a2                	ld	s1,8(sp)
    80001c9c:	6902                	ld	s2,0(sp)
    80001c9e:	6105                	addi	sp,sp,32
    80001ca0:	8082                	ret

0000000080001ca2 <freeproc>:
{
    80001ca2:	1101                	addi	sp,sp,-32
    80001ca4:	ec06                	sd	ra,24(sp)
    80001ca6:	e822                	sd	s0,16(sp)
    80001ca8:	e426                	sd	s1,8(sp)
    80001caa:	1000                	addi	s0,sp,32
    80001cac:	84aa                	mv	s1,a0
  getportion(p);
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	c14080e7          	jalr	-1004(ra) # 800018c2 <getportion>
  printf("%s (pid=%d): Q2(%d%%), Q1(%d%%), Q0(%d%%)\n",
    80001cb6:	16c4a783          	lw	a5,364(s1)
    80001cba:	1704a703          	lw	a4,368(s1)
    80001cbe:	1744a683          	lw	a3,372(s1)
    80001cc2:	5c90                	lw	a2,56(s1)
    80001cc4:	15848593          	addi	a1,s1,344
    80001cc8:	00006517          	auipc	a0,0x6
    80001ccc:	54050513          	addi	a0,a0,1344 # 80008208 <digits+0x1c8>
    80001cd0:	fffff097          	auipc	ra,0xfffff
    80001cd4:	8ba080e7          	jalr	-1862(ra) # 8000058a <printf>
  if (p->trapframe)
    80001cd8:	6ca8                	ld	a0,88(s1)
    80001cda:	c509                	beqz	a0,80001ce4 <freeproc+0x42>
    kfree((void *)p->trapframe);
    80001cdc:	fffff097          	auipc	ra,0xfffff
    80001ce0:	d34080e7          	jalr	-716(ra) # 80000a10 <kfree>
  p->trapframe = 0;
    80001ce4:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001ce8:	68a8                	ld	a0,80(s1)
    80001cea:	c511                	beqz	a0,80001cf6 <freeproc+0x54>
    proc_freepagetable(p->pagetable, p->sz);
    80001cec:	64ac                	ld	a1,72(s1)
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	f62080e7          	jalr	-158(ra) # 80001c50 <proc_freepagetable>
  p->pagetable = 0;
    80001cf6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cfa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cfe:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d02:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d06:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d0a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d0e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d12:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d16:	0004ac23          	sw	zero,24(s1)
  p->change = 0;
    80001d1a:	1604a423          	sw	zero,360(s1)
  p->Qtime[2] = 0;
    80001d1e:	1604aa23          	sw	zero,372(s1)
  p->Qtime[1] = 0;
    80001d22:	1604a823          	sw	zero,368(s1)
  p->Qtime[0] = 0;
    80001d26:	1604a623          	sw	zero,364(s1)
  p->priority = 0;
    80001d2a:	1604ac23          	sw	zero,376(s1)
  movequeue(p, 0, DELETE);
    80001d2e:	4609                	li	a2,2
    80001d30:	4581                	li	a1,0
    80001d32:	8526                	mv	a0,s1
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	c12080e7          	jalr	-1006(ra) # 80001946 <movequeue>
}
    80001d3c:	60e2                	ld	ra,24(sp)
    80001d3e:	6442                	ld	s0,16(sp)
    80001d40:	64a2                	ld	s1,8(sp)
    80001d42:	6105                	addi	sp,sp,32
    80001d44:	8082                	ret

0000000080001d46 <allocproc>:
{
    80001d46:	1101                	addi	sp,sp,-32
    80001d48:	ec06                	sd	ra,24(sp)
    80001d4a:	e822                	sd	s0,16(sp)
    80001d4c:	e426                	sd	s1,8(sp)
    80001d4e:	e04a                	sd	s2,0(sp)
    80001d50:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001d52:	00010497          	auipc	s1,0x10
    80001d56:	71648493          	addi	s1,s1,1814 # 80012468 <proc>
    80001d5a:	00016917          	auipc	s2,0x16
    80001d5e:	70e90913          	addi	s2,s2,1806 # 80018468 <tickslock>
    acquire(&p->lock);
    80001d62:	8526                	mv	a0,s1
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	e98080e7          	jalr	-360(ra) # 80000bfc <acquire>
    if (p->state == UNUSED)
    80001d6c:	4c9c                	lw	a5,24(s1)
    80001d6e:	cf81                	beqz	a5,80001d86 <allocproc+0x40>
      release(&p->lock);
    80001d70:	8526                	mv	a0,s1
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	f3e080e7          	jalr	-194(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d7a:	18048493          	addi	s1,s1,384
    80001d7e:	ff2492e3          	bne	s1,s2,80001d62 <allocproc+0x1c>
  return 0;
    80001d82:	4481                	li	s1,0
    80001d84:	a0b9                	j	80001dd2 <allocproc+0x8c>
  p->pid = allocpid();
    80001d86:	00000097          	auipc	ra,0x0
    80001d8a:	de8080e7          	jalr	-536(ra) # 80001b6e <allocpid>
    80001d8e:	dc88                	sw	a0,56(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	d7c080e7          	jalr	-644(ra) # 80000b0c <kalloc>
    80001d98:	892a                	mv	s2,a0
    80001d9a:	eca8                	sd	a0,88(s1)
    80001d9c:	c131                	beqz	a0,80001de0 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d9e:	8526                	mv	a0,s1
    80001da0:	00000097          	auipc	ra,0x0
    80001da4:	e14080e7          	jalr	-492(ra) # 80001bb4 <proc_pagetable>
    80001da8:	892a                	mv	s2,a0
    80001daa:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001dac:	c129                	beqz	a0,80001dee <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001dae:	07000613          	li	a2,112
    80001db2:	4581                	li	a1,0
    80001db4:	06048513          	addi	a0,s1,96
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	f40080e7          	jalr	-192(ra) # 80000cf8 <memset>
  p->context.ra = (uint64)forkret;
    80001dc0:	00000797          	auipc	a5,0x0
    80001dc4:	d6878793          	addi	a5,a5,-664 # 80001b28 <forkret>
    80001dc8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001dca:	60bc                	ld	a5,64(s1)
    80001dcc:	6705                	lui	a4,0x1
    80001dce:	97ba                	add	a5,a5,a4
    80001dd0:	f4bc                	sd	a5,104(s1)
}
    80001dd2:	8526                	mv	a0,s1
    80001dd4:	60e2                	ld	ra,24(sp)
    80001dd6:	6442                	ld	s0,16(sp)
    80001dd8:	64a2                	ld	s1,8(sp)
    80001dda:	6902                	ld	s2,0(sp)
    80001ddc:	6105                	addi	sp,sp,32
    80001dde:	8082                	ret
    release(&p->lock);
    80001de0:	8526                	mv	a0,s1
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	ece080e7          	jalr	-306(ra) # 80000cb0 <release>
    return 0;
    80001dea:	84ca                	mv	s1,s2
    80001dec:	b7dd                	j	80001dd2 <allocproc+0x8c>
    freeproc(p);
    80001dee:	8526                	mv	a0,s1
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	eb2080e7          	jalr	-334(ra) # 80001ca2 <freeproc>
    release(&p->lock);
    80001df8:	8526                	mv	a0,s1
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	eb6080e7          	jalr	-330(ra) # 80000cb0 <release>
    return 0;
    80001e02:	84ca                	mv	s1,s2
    80001e04:	b7f9                	j	80001dd2 <allocproc+0x8c>

0000000080001e06 <userinit>:
{
    80001e06:	1101                	addi	sp,sp,-32
    80001e08:	ec06                	sd	ra,24(sp)
    80001e0a:	e822                	sd	s0,16(sp)
    80001e0c:	e426                	sd	s1,8(sp)
    80001e0e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	f36080e7          	jalr	-202(ra) # 80001d46 <allocproc>
    80001e18:	84aa                	mv	s1,a0
  initproc = p;
    80001e1a:	00007797          	auipc	a5,0x7
    80001e1e:	1ea7bf23          	sd	a0,510(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e22:	03400613          	li	a2,52
    80001e26:	00007597          	auipc	a1,0x7
    80001e2a:	a4a58593          	addi	a1,a1,-1462 # 80008870 <initcode>
    80001e2e:	6928                	ld	a0,80(a0)
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	570080e7          	jalr	1392(ra) # 800013a0 <uvminit>
  p->sz = PGSIZE;
    80001e38:	6785                	lui	a5,0x1
    80001e3a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e3c:	6cb8                	ld	a4,88(s1)
    80001e3e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e42:	6cb8                	ld	a4,88(s1)
    80001e44:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e46:	4641                	li	a2,16
    80001e48:	00006597          	auipc	a1,0x6
    80001e4c:	3f058593          	addi	a1,a1,1008 # 80008238 <digits+0x1f8>
    80001e50:	15848513          	addi	a0,s1,344
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	ff6080e7          	jalr	-10(ra) # 80000e4a <safestrcpy>
  p->cwd = namei("/");
    80001e5c:	00006517          	auipc	a0,0x6
    80001e60:	3ec50513          	addi	a0,a0,1004 # 80008248 <digits+0x208>
    80001e64:	00002097          	auipc	ra,0x2
    80001e68:	2d2080e7          	jalr	722(ra) # 80004136 <namei>
    80001e6c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e70:	4789                	li	a5,2
    80001e72:	cc9c                	sw	a5,24(s1)
  movequeue(p, 2, INSERT);
    80001e74:	4605                	li	a2,1
    80001e76:	4589                	li	a1,2
    80001e78:	8526                	mv	a0,s1
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	acc080e7          	jalr	-1332(ra) # 80001946 <movequeue>
  p->Qtime[2] = 0;
    80001e82:	1604aa23          	sw	zero,372(s1)
  p->Qtime[1] = 0;
    80001e86:	1604a823          	sw	zero,368(s1)
  p->Qtime[0] = 0;
    80001e8a:	1604a623          	sw	zero,364(s1)
  release(&p->lock);
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	e20080e7          	jalr	-480(ra) # 80000cb0 <release>
}
    80001e98:	60e2                	ld	ra,24(sp)
    80001e9a:	6442                	ld	s0,16(sp)
    80001e9c:	64a2                	ld	s1,8(sp)
    80001e9e:	6105                	addi	sp,sp,32
    80001ea0:	8082                	ret

0000000080001ea2 <growproc>:
{
    80001ea2:	1101                	addi	sp,sp,-32
    80001ea4:	ec06                	sd	ra,24(sp)
    80001ea6:	e822                	sd	s0,16(sp)
    80001ea8:	e426                	sd	s1,8(sp)
    80001eaa:	e04a                	sd	s2,0(sp)
    80001eac:	1000                	addi	s0,sp,32
    80001eae:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001eb0:	00000097          	auipc	ra,0x0
    80001eb4:	c3e080e7          	jalr	-962(ra) # 80001aee <myproc>
    80001eb8:	892a                	mv	s2,a0
  sz = p->sz;
    80001eba:	652c                	ld	a1,72(a0)
    80001ebc:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001ec0:	00904f63          	bgtz	s1,80001ede <growproc+0x3c>
  else if (n < 0)
    80001ec4:	0204cc63          	bltz	s1,80001efc <growproc+0x5a>
  p->sz = sz;
    80001ec8:	1602                	slli	a2,a2,0x20
    80001eca:	9201                	srli	a2,a2,0x20
    80001ecc:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ed0:	4501                	li	a0,0
}
    80001ed2:	60e2                	ld	ra,24(sp)
    80001ed4:	6442                	ld	s0,16(sp)
    80001ed6:	64a2                	ld	s1,8(sp)
    80001ed8:	6902                	ld	s2,0(sp)
    80001eda:	6105                	addi	sp,sp,32
    80001edc:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001ede:	9e25                	addw	a2,a2,s1
    80001ee0:	1602                	slli	a2,a2,0x20
    80001ee2:	9201                	srli	a2,a2,0x20
    80001ee4:	1582                	slli	a1,a1,0x20
    80001ee6:	9181                	srli	a1,a1,0x20
    80001ee8:	6928                	ld	a0,80(a0)
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	570080e7          	jalr	1392(ra) # 8000145a <uvmalloc>
    80001ef2:	0005061b          	sext.w	a2,a0
    80001ef6:	fa69                	bnez	a2,80001ec8 <growproc+0x26>
      return -1;
    80001ef8:	557d                	li	a0,-1
    80001efa:	bfe1                	j	80001ed2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001efc:	9e25                	addw	a2,a2,s1
    80001efe:	1602                	slli	a2,a2,0x20
    80001f00:	9201                	srli	a2,a2,0x20
    80001f02:	1582                	slli	a1,a1,0x20
    80001f04:	9181                	srli	a1,a1,0x20
    80001f06:	6928                	ld	a0,80(a0)
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	50a080e7          	jalr	1290(ra) # 80001412 <uvmdealloc>
    80001f10:	0005061b          	sext.w	a2,a0
    80001f14:	bf55                	j	80001ec8 <growproc+0x26>

0000000080001f16 <fork>:
{
    80001f16:	7139                	addi	sp,sp,-64
    80001f18:	fc06                	sd	ra,56(sp)
    80001f1a:	f822                	sd	s0,48(sp)
    80001f1c:	f426                	sd	s1,40(sp)
    80001f1e:	f04a                	sd	s2,32(sp)
    80001f20:	ec4e                	sd	s3,24(sp)
    80001f22:	e852                	sd	s4,16(sp)
    80001f24:	e456                	sd	s5,8(sp)
    80001f26:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f28:	00000097          	auipc	ra,0x0
    80001f2c:	bc6080e7          	jalr	-1082(ra) # 80001aee <myproc>
    80001f30:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f32:	00000097          	auipc	ra,0x0
    80001f36:	e14080e7          	jalr	-492(ra) # 80001d46 <allocproc>
    80001f3a:	10050163          	beqz	a0,8000203c <fork+0x126>
    80001f3e:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f40:	048ab603          	ld	a2,72(s5)
    80001f44:	692c                	ld	a1,80(a0)
    80001f46:	050ab503          	ld	a0,80(s5)
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	65c080e7          	jalr	1628(ra) # 800015a6 <uvmcopy>
    80001f52:	04054a63          	bltz	a0,80001fa6 <fork+0x90>
  np->sz = p->sz;
    80001f56:	048ab783          	ld	a5,72(s5)
    80001f5a:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f5e:	0359b023          	sd	s5,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f62:	058ab683          	ld	a3,88(s5)
    80001f66:	87b6                	mv	a5,a3
    80001f68:	0589b703          	ld	a4,88(s3)
    80001f6c:	12068693          	addi	a3,a3,288
    80001f70:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f74:	6788                	ld	a0,8(a5)
    80001f76:	6b8c                	ld	a1,16(a5)
    80001f78:	6f90                	ld	a2,24(a5)
    80001f7a:	01073023          	sd	a6,0(a4)
    80001f7e:	e708                	sd	a0,8(a4)
    80001f80:	eb0c                	sd	a1,16(a4)
    80001f82:	ef10                	sd	a2,24(a4)
    80001f84:	02078793          	addi	a5,a5,32
    80001f88:	02070713          	addi	a4,a4,32
    80001f8c:	fed792e3          	bne	a5,a3,80001f70 <fork+0x5a>
  np->trapframe->a0 = 0;
    80001f90:	0589b783          	ld	a5,88(s3)
    80001f94:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001f98:	0d0a8493          	addi	s1,s5,208
    80001f9c:	0d098913          	addi	s2,s3,208
    80001fa0:	150a8a13          	addi	s4,s5,336
    80001fa4:	a00d                	j	80001fc6 <fork+0xb0>
    freeproc(np);
    80001fa6:	854e                	mv	a0,s3
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	cfa080e7          	jalr	-774(ra) # 80001ca2 <freeproc>
    release(&np->lock);
    80001fb0:	854e                	mv	a0,s3
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	cfe080e7          	jalr	-770(ra) # 80000cb0 <release>
    return -1;
    80001fba:	54fd                	li	s1,-1
    80001fbc:	a0b5                	j	80002028 <fork+0x112>
  for (i = 0; i < NOFILE; i++)
    80001fbe:	04a1                	addi	s1,s1,8
    80001fc0:	0921                	addi	s2,s2,8
    80001fc2:	01448b63          	beq	s1,s4,80001fd8 <fork+0xc2>
    if (p->ofile[i])
    80001fc6:	6088                	ld	a0,0(s1)
    80001fc8:	d97d                	beqz	a0,80001fbe <fork+0xa8>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fca:	00002097          	auipc	ra,0x2
    80001fce:	7fc080e7          	jalr	2044(ra) # 800047c6 <filedup>
    80001fd2:	00a93023          	sd	a0,0(s2)
    80001fd6:	b7e5                	j	80001fbe <fork+0xa8>
  np->cwd = idup(p->cwd);
    80001fd8:	150ab503          	ld	a0,336(s5)
    80001fdc:	00002097          	auipc	ra,0x2
    80001fe0:	96c080e7          	jalr	-1684(ra) # 80003948 <idup>
    80001fe4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fe8:	4641                	li	a2,16
    80001fea:	158a8593          	addi	a1,s5,344
    80001fee:	15898513          	addi	a0,s3,344
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	e58080e7          	jalr	-424(ra) # 80000e4a <safestrcpy>
  pid = np->pid;
    80001ffa:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ffe:	4789                	li	a5,2
    80002000:	00f9ac23          	sw	a5,24(s3)
  movequeue(np, 2, INSERT);
    80002004:	4605                	li	a2,1
    80002006:	4589                	li	a1,2
    80002008:	854e                	mv	a0,s3
    8000200a:	00000097          	auipc	ra,0x0
    8000200e:	93c080e7          	jalr	-1732(ra) # 80001946 <movequeue>
  np->Qtime[2] = 0;
    80002012:	1609aa23          	sw	zero,372(s3)
  np->Qtime[1] = 0;
    80002016:	1609a823          	sw	zero,368(s3)
  np->Qtime[0] = 0;
    8000201a:	1609a623          	sw	zero,364(s3)
  release(&np->lock);
    8000201e:	854e                	mv	a0,s3
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	c90080e7          	jalr	-880(ra) # 80000cb0 <release>
}
    80002028:	8526                	mv	a0,s1
    8000202a:	70e2                	ld	ra,56(sp)
    8000202c:	7442                	ld	s0,48(sp)
    8000202e:	74a2                	ld	s1,40(sp)
    80002030:	7902                	ld	s2,32(sp)
    80002032:	69e2                	ld	s3,24(sp)
    80002034:	6a42                	ld	s4,16(sp)
    80002036:	6aa2                	ld	s5,8(sp)
    80002038:	6121                	addi	sp,sp,64
    8000203a:	8082                	ret
    return -1;
    8000203c:	54fd                	li	s1,-1
    8000203e:	b7ed                	j	80002028 <fork+0x112>

0000000080002040 <reparent>:
{
    80002040:	7179                	addi	sp,sp,-48
    80002042:	f406                	sd	ra,40(sp)
    80002044:	f022                	sd	s0,32(sp)
    80002046:	ec26                	sd	s1,24(sp)
    80002048:	e84a                	sd	s2,16(sp)
    8000204a:	e44e                	sd	s3,8(sp)
    8000204c:	e052                	sd	s4,0(sp)
    8000204e:	1800                	addi	s0,sp,48
    80002050:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002052:	00010497          	auipc	s1,0x10
    80002056:	41648493          	addi	s1,s1,1046 # 80012468 <proc>
      pp->parent = initproc;
    8000205a:	00007a17          	auipc	s4,0x7
    8000205e:	fbea0a13          	addi	s4,s4,-66 # 80009018 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002062:	00016997          	auipc	s3,0x16
    80002066:	40698993          	addi	s3,s3,1030 # 80018468 <tickslock>
    8000206a:	a029                	j	80002074 <reparent+0x34>
    8000206c:	18048493          	addi	s1,s1,384
    80002070:	03348363          	beq	s1,s3,80002096 <reparent+0x56>
    if (pp->parent == p)
    80002074:	709c                	ld	a5,32(s1)
    80002076:	ff279be3          	bne	a5,s2,8000206c <reparent+0x2c>
      acquire(&pp->lock);
    8000207a:	8526                	mv	a0,s1
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	b80080e7          	jalr	-1152(ra) # 80000bfc <acquire>
      pp->parent = initproc;
    80002084:	000a3783          	ld	a5,0(s4)
    80002088:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	c24080e7          	jalr	-988(ra) # 80000cb0 <release>
    80002094:	bfe1                	j	8000206c <reparent+0x2c>
}
    80002096:	70a2                	ld	ra,40(sp)
    80002098:	7402                	ld	s0,32(sp)
    8000209a:	64e2                	ld	s1,24(sp)
    8000209c:	6942                	ld	s2,16(sp)
    8000209e:	69a2                	ld	s3,8(sp)
    800020a0:	6a02                	ld	s4,0(sp)
    800020a2:	6145                	addi	sp,sp,48
    800020a4:	8082                	ret

00000000800020a6 <scheduler>:
{
    800020a6:	7159                	addi	sp,sp,-112
    800020a8:	f486                	sd	ra,104(sp)
    800020aa:	f0a2                	sd	s0,96(sp)
    800020ac:	eca6                	sd	s1,88(sp)
    800020ae:	e8ca                	sd	s2,80(sp)
    800020b0:	e4ce                	sd	s3,72(sp)
    800020b2:	e0d2                	sd	s4,64(sp)
    800020b4:	fc56                	sd	s5,56(sp)
    800020b6:	f85a                	sd	s6,48(sp)
    800020b8:	f45e                	sd	s7,40(sp)
    800020ba:	f062                	sd	s8,32(sp)
    800020bc:	ec66                	sd	s9,24(sp)
    800020be:	e86a                	sd	s10,16(sp)
    800020c0:	e46e                	sd	s11,8(sp)
    800020c2:	1880                	addi	s0,sp,112
    800020c4:	8792                	mv	a5,tp
  int id = r_tp();
    800020c6:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020c8:	00779c93          	slli	s9,a5,0x7
    800020cc:	00010717          	auipc	a4,0x10
    800020d0:	88470713          	addi	a4,a4,-1916 # 80011950 <Q>
    800020d4:	9766                	add	a4,a4,s9
    800020d6:	60073c23          	sd	zero,1560(a4)
        swtch(&c->context, &p->context);
    800020da:	00010717          	auipc	a4,0x10
    800020de:	e9670713          	addi	a4,a4,-362 # 80011f70 <cpus+0x8>
    800020e2:	9cba                	add	s9,s9,a4
  int exec = 0;
    800020e4:	4c01                	li	s8,0
        c->proc = p;
    800020e6:	00010d97          	auipc	s11,0x10
    800020ea:	86ad8d93          	addi	s11,s11,-1942 # 80011950 <Q>
    800020ee:	079e                	slli	a5,a5,0x7
    800020f0:	00fd8b33          	add	s6,s11,a5
        pid[tail] = p->pid;
    800020f4:	00007b97          	auipc	s7,0x7
    800020f8:	f2cb8b93          	addi	s7,s7,-212 # 80009020 <tail>
    800020fc:	00011d17          	auipc	s10,0x11
    80002100:	854d0d13          	addi	s10,s10,-1964 # 80012950 <proc+0x4e8>
    80002104:	a2a9                	j	8000224e <scheduler+0x1a8>
      exec = 0;
    80002106:	4c01                	li	s8,0
    80002108:	a2a1                	j	80002250 <scheduler+0x1aa>
          (p->Qtime[2])++;
    8000210a:	1744a783          	lw	a5,372(s1)
    8000210e:	2785                	addiw	a5,a5,1
    80002110:	16f4aa23          	sw	a5,372(s1)
      switch (p->change)
    80002114:	1684a783          	lw	a5,360(s1)
    80002118:	07278163          	beq	a5,s2,8000217a <scheduler+0xd4>
    8000211c:	07578763          	beq	a5,s5,8000218a <scheduler+0xe4>
    80002120:	05378563          	beq	a5,s3,8000216a <scheduler+0xc4>
      release(&p->lock);
    80002124:	8526                	mv	a0,s1
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	b8a080e7          	jalr	-1142(ra) # 80000cb0 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000212e:	18048493          	addi	s1,s1,384
    80002132:	07448463          	beq	s1,s4,8000219a <scheduler+0xf4>
      acquire(&p->lock);
    80002136:	8526                	mv	a0,s1
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	ac4080e7          	jalr	-1340(ra) # 80000bfc <acquire>
      if (p->state != UNUSED)
    80002140:	4c9c                	lw	a5,24(s1)
    80002142:	dbe9                	beqz	a5,80002114 <scheduler+0x6e>
        if (p->priority == 2)
    80002144:	1784a783          	lw	a5,376(s1)
    80002148:	fd2781e3          	beq	a5,s2,8000210a <scheduler+0x64>
        else if (p->priority == 1)
    8000214c:	01378963          	beq	a5,s3,8000215e <scheduler+0xb8>
        else if (p->priority == 0)
    80002150:	f3f1                	bnez	a5,80002114 <scheduler+0x6e>
          (p->Qtime[0])++;
    80002152:	16c4a783          	lw	a5,364(s1)
    80002156:	2785                	addiw	a5,a5,1
    80002158:	16f4a623          	sw	a5,364(s1)
    8000215c:	bf65                	j	80002114 <scheduler+0x6e>
          (p->Qtime[1])++;
    8000215e:	1704a783          	lw	a5,368(s1)
    80002162:	2785                	addiw	a5,a5,1
    80002164:	16f4a823          	sw	a5,368(s1)
    80002168:	b775                	j	80002114 <scheduler+0x6e>
        movequeue(p, 1, MOVE);
    8000216a:	4601                	li	a2,0
    8000216c:	85ce                	mv	a1,s3
    8000216e:	8526                	mv	a0,s1
    80002170:	fffff097          	auipc	ra,0xfffff
    80002174:	7d6080e7          	jalr	2006(ra) # 80001946 <movequeue>
        break;
    80002178:	b775                	j	80002124 <scheduler+0x7e>
        movequeue(p, 0, MOVE);
    8000217a:	4601                	li	a2,0
    8000217c:	4581                	li	a1,0
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	7c6080e7          	jalr	1990(ra) # 80001946 <movequeue>
        break;
    80002188:	bf71                	j	80002124 <scheduler+0x7e>
        movequeue(p, 2, MOVE);
    8000218a:	4601                	li	a2,0
    8000218c:	85ca                	mv	a1,s2
    8000218e:	8526                	mv	a0,s1
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	7b6080e7          	jalr	1974(ra) # 80001946 <movequeue>
        break;
    80002198:	b771                	j	80002124 <scheduler+0x7e>
    int tail2 = findproc(0, 2) - 1;
    8000219a:	85ca                	mv	a1,s2
    8000219c:	4501                	li	a0,0
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	76a080e7          	jalr	1898(ra) # 80001908 <findproc>
    for (int i = 0; i <= tail2; i++)
    800021a6:	06a05e63          	blez	a0,80002222 <scheduler+0x17c>
    800021aa:	00010997          	auipc	s3,0x10
    800021ae:	ba698993          	addi	s3,s3,-1114 # 80011d50 <Q+0x400>
    800021b2:	fff50a1b          	addiw	s4,a0,-1
    800021b6:	020a1793          	slli	a5,s4,0x20
    800021ba:	01d7da13          	srli	s4,a5,0x1d
    800021be:	00010797          	auipc	a5,0x10
    800021c2:	b9a78793          	addi	a5,a5,-1126 # 80011d58 <Q+0x408>
    800021c6:	9a3e                	add	s4,s4,a5
        p->state = RUNNING;
    800021c8:	4a8d                	li	s5,3
    800021ca:	a809                	j	800021dc <scheduler+0x136>
      release(&p->lock);
    800021cc:	8526                	mv	a0,s1
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	ae2080e7          	jalr	-1310(ra) # 80000cb0 <release>
    for (int i = 0; i <= tail2; i++)
    800021d6:	09a1                	addi	s3,s3,8
    800021d8:	05498563          	beq	s3,s4,80002222 <scheduler+0x17c>
      p = Q[2][i];
    800021dc:	0009b483          	ld	s1,0(s3)
      acquire(&p->lock);
    800021e0:	8526                	mv	a0,s1
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	a1a080e7          	jalr	-1510(ra) # 80000bfc <acquire>
      if (p->state == RUNNABLE)
    800021ea:	4c9c                	lw	a5,24(s1)
    800021ec:	ff2790e3          	bne	a5,s2,800021cc <scheduler+0x126>
        p->state = RUNNING;
    800021f0:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    800021f4:	609b3c23          	sd	s1,1560(s6) # 1618 <_entry-0x7fffe9e8>
        swtch(&c->context, &p->context);
    800021f8:	06048593          	addi	a1,s1,96
    800021fc:	8566                	mv	a0,s9
    800021fe:	00000097          	auipc	ra,0x0
    80002202:	6fc080e7          	jalr	1788(ra) # 800028fa <swtch>
        pid[tail] = p->pid;
    80002206:	000ba783          	lw	a5,0(s7)
    8000220a:	5c94                	lw	a3,56(s1)
    8000220c:	00279713          	slli	a4,a5,0x2
    80002210:	976a                	add	a4,a4,s10
    80002212:	a0d72c23          	sw	a3,-1512(a4)
        tail++;
    80002216:	2785                	addiw	a5,a5,1
    80002218:	00fba023          	sw	a5,0(s7)
        c->proc = 0;
    8000221c:	600b3c23          	sd	zero,1560(s6)
    80002220:	b775                	j	800021cc <scheduler+0x126>
    p = Q[1][exec];
    80002222:	040c0793          	addi	a5,s8,64
    80002226:	078e                	slli	a5,a5,0x3
    80002228:	97ee                	add	a5,a5,s11
    8000222a:	6384                	ld	s1,0(a5)
    if (p == 0)
    8000222c:	ec048de3          	beqz	s1,80002106 <scheduler+0x60>
    acquire(&p->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	9ca080e7          	jalr	-1590(ra) # 80000bfc <acquire>
    if (p->state == RUNNABLE)
    8000223a:	4c98                	lw	a4,24(s1)
    8000223c:	4789                	li	a5,2
    8000223e:	02f70a63          	beq	a4,a5,80002272 <scheduler+0x1cc>
    release(&p->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	a6c080e7          	jalr	-1428(ra) # 80000cb0 <release>
    exec++;
    8000224c:	2c05                	addiw	s8,s8,1
        if (p->priority == 2)
    8000224e:	4909                	li	s2,2
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002250:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002254:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002258:	10079073          	csrw	sstatus,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000225c:	00010497          	auipc	s1,0x10
    80002260:	20c48493          	addi	s1,s1,524 # 80012468 <proc>
        else if (p->priority == 1)
    80002264:	4985                	li	s3,1
      switch (p->change)
    80002266:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002268:	00016a17          	auipc	s4,0x16
    8000226c:	200a0a13          	addi	s4,s4,512 # 80018468 <tickslock>
    80002270:	b5d9                	j	80002136 <scheduler+0x90>
      p->state = RUNNING;
    80002272:	478d                	li	a5,3
    80002274:	cc9c                	sw	a5,24(s1)
      c->proc = p;
    80002276:	609b3c23          	sd	s1,1560(s6)
      swtch(&c->context, &p->context);
    8000227a:	06048593          	addi	a1,s1,96
    8000227e:	8566                	mv	a0,s9
    80002280:	00000097          	auipc	ra,0x0
    80002284:	67a080e7          	jalr	1658(ra) # 800028fa <swtch>
      pid[tail] = p->pid;
    80002288:	000ba783          	lw	a5,0(s7)
    8000228c:	5c94                	lw	a3,56(s1)
    8000228e:	00279713          	slli	a4,a5,0x2
    80002292:	976a                	add	a4,a4,s10
    80002294:	a0d72c23          	sw	a3,-1512(a4)
      tail++;
    80002298:	2785                	addiw	a5,a5,1
    8000229a:	00fba023          	sw	a5,0(s7)
      c->proc = 0;
    8000229e:	600b3c23          	sd	zero,1560(s6)
    800022a2:	b745                	j	80002242 <scheduler+0x19c>

00000000800022a4 <sched>:
{
    800022a4:	7179                	addi	sp,sp,-48
    800022a6:	f406                	sd	ra,40(sp)
    800022a8:	f022                	sd	s0,32(sp)
    800022aa:	ec26                	sd	s1,24(sp)
    800022ac:	e84a                	sd	s2,16(sp)
    800022ae:	e44e                	sd	s3,8(sp)
    800022b0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022b2:	00000097          	auipc	ra,0x0
    800022b6:	83c080e7          	jalr	-1988(ra) # 80001aee <myproc>
    800022ba:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	8c6080e7          	jalr	-1850(ra) # 80000b82 <holding>
    800022c4:	c93d                	beqz	a0,8000233a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022c6:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800022c8:	2781                	sext.w	a5,a5
    800022ca:	079e                	slli	a5,a5,0x7
    800022cc:	0000f717          	auipc	a4,0xf
    800022d0:	68470713          	addi	a4,a4,1668 # 80011950 <Q>
    800022d4:	97ba                	add	a5,a5,a4
    800022d6:	6907a703          	lw	a4,1680(a5)
    800022da:	4785                	li	a5,1
    800022dc:	06f71763          	bne	a4,a5,8000234a <sched+0xa6>
  if (p->state == RUNNING)
    800022e0:	4c98                	lw	a4,24(s1)
    800022e2:	478d                	li	a5,3
    800022e4:	06f70b63          	beq	a4,a5,8000235a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022e8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022ec:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022ee:	efb5                	bnez	a5,8000236a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022f0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022f2:	0000f917          	auipc	s2,0xf
    800022f6:	65e90913          	addi	s2,s2,1630 # 80011950 <Q>
    800022fa:	2781                	sext.w	a5,a5
    800022fc:	079e                	slli	a5,a5,0x7
    800022fe:	97ca                	add	a5,a5,s2
    80002300:	6947a983          	lw	s3,1684(a5)
    80002304:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002306:	2781                	sext.w	a5,a5
    80002308:	079e                	slli	a5,a5,0x7
    8000230a:	00010597          	auipc	a1,0x10
    8000230e:	c6658593          	addi	a1,a1,-922 # 80011f70 <cpus+0x8>
    80002312:	95be                	add	a1,a1,a5
    80002314:	06048513          	addi	a0,s1,96
    80002318:	00000097          	auipc	ra,0x0
    8000231c:	5e2080e7          	jalr	1506(ra) # 800028fa <swtch>
    80002320:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002322:	2781                	sext.w	a5,a5
    80002324:	079e                	slli	a5,a5,0x7
    80002326:	97ca                	add	a5,a5,s2
    80002328:	6937aa23          	sw	s3,1684(a5)
}
    8000232c:	70a2                	ld	ra,40(sp)
    8000232e:	7402                	ld	s0,32(sp)
    80002330:	64e2                	ld	s1,24(sp)
    80002332:	6942                	ld	s2,16(sp)
    80002334:	69a2                	ld	s3,8(sp)
    80002336:	6145                	addi	sp,sp,48
    80002338:	8082                	ret
    panic("sched p->lock");
    8000233a:	00006517          	auipc	a0,0x6
    8000233e:	f1650513          	addi	a0,a0,-234 # 80008250 <digits+0x210>
    80002342:	ffffe097          	auipc	ra,0xffffe
    80002346:	1fe080e7          	jalr	510(ra) # 80000540 <panic>
    panic("sched locks");
    8000234a:	00006517          	auipc	a0,0x6
    8000234e:	f1650513          	addi	a0,a0,-234 # 80008260 <digits+0x220>
    80002352:	ffffe097          	auipc	ra,0xffffe
    80002356:	1ee080e7          	jalr	494(ra) # 80000540 <panic>
    panic("sched running");
    8000235a:	00006517          	auipc	a0,0x6
    8000235e:	f1650513          	addi	a0,a0,-234 # 80008270 <digits+0x230>
    80002362:	ffffe097          	auipc	ra,0xffffe
    80002366:	1de080e7          	jalr	478(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000236a:	00006517          	auipc	a0,0x6
    8000236e:	f1650513          	addi	a0,a0,-234 # 80008280 <digits+0x240>
    80002372:	ffffe097          	auipc	ra,0xffffe
    80002376:	1ce080e7          	jalr	462(ra) # 80000540 <panic>

000000008000237a <exit>:
{
    8000237a:	7179                	addi	sp,sp,-48
    8000237c:	f406                	sd	ra,40(sp)
    8000237e:	f022                	sd	s0,32(sp)
    80002380:	ec26                	sd	s1,24(sp)
    80002382:	e84a                	sd	s2,16(sp)
    80002384:	e44e                	sd	s3,8(sp)
    80002386:	e052                	sd	s4,0(sp)
    80002388:	1800                	addi	s0,sp,48
    8000238a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	762080e7          	jalr	1890(ra) # 80001aee <myproc>
    80002394:	89aa                	mv	s3,a0
  if (p == initproc)
    80002396:	00007797          	auipc	a5,0x7
    8000239a:	c827b783          	ld	a5,-894(a5) # 80009018 <initproc>
    8000239e:	0d050493          	addi	s1,a0,208
    800023a2:	15050913          	addi	s2,a0,336
    800023a6:	02a79363          	bne	a5,a0,800023cc <exit+0x52>
    panic("init exiting");
    800023aa:	00006517          	auipc	a0,0x6
    800023ae:	eee50513          	addi	a0,a0,-274 # 80008298 <digits+0x258>
    800023b2:	ffffe097          	auipc	ra,0xffffe
    800023b6:	18e080e7          	jalr	398(ra) # 80000540 <panic>
      fileclose(f);
    800023ba:	00002097          	auipc	ra,0x2
    800023be:	45e080e7          	jalr	1118(ra) # 80004818 <fileclose>
      p->ofile[fd] = 0;
    800023c2:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800023c6:	04a1                	addi	s1,s1,8
    800023c8:	01248563          	beq	s1,s2,800023d2 <exit+0x58>
    if (p->ofile[fd])
    800023cc:	6088                	ld	a0,0(s1)
    800023ce:	f575                	bnez	a0,800023ba <exit+0x40>
    800023d0:	bfdd                	j	800023c6 <exit+0x4c>
  begin_op();
    800023d2:	00002097          	auipc	ra,0x2
    800023d6:	f74080e7          	jalr	-140(ra) # 80004346 <begin_op>
  iput(p->cwd);
    800023da:	1509b503          	ld	a0,336(s3)
    800023de:	00001097          	auipc	ra,0x1
    800023e2:	762080e7          	jalr	1890(ra) # 80003b40 <iput>
  end_op();
    800023e6:	00002097          	auipc	ra,0x2
    800023ea:	fe0080e7          	jalr	-32(ra) # 800043c6 <end_op>
  p->cwd = 0;
    800023ee:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800023f2:	00007497          	auipc	s1,0x7
    800023f6:	c2648493          	addi	s1,s1,-986 # 80009018 <initproc>
    800023fa:	6088                	ld	a0,0(s1)
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	800080e7          	jalr	-2048(ra) # 80000bfc <acquire>
  wakeup1(initproc);
    80002404:	6088                	ld	a0,0(s1)
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	472080e7          	jalr	1138(ra) # 80001878 <wakeup1>
  release(&initproc->lock);
    8000240e:	6088                	ld	a0,0(s1)
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	8a0080e7          	jalr	-1888(ra) # 80000cb0 <release>
  acquire(&p->lock);
    80002418:	854e                	mv	a0,s3
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	7e2080e7          	jalr	2018(ra) # 80000bfc <acquire>
  struct proc *original_parent = p->parent;
    80002422:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002426:	854e                	mv	a0,s3
    80002428:	fffff097          	auipc	ra,0xfffff
    8000242c:	888080e7          	jalr	-1912(ra) # 80000cb0 <release>
  acquire(&original_parent->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	7ca080e7          	jalr	1994(ra) # 80000bfc <acquire>
  acquire(&p->lock);
    8000243a:	854e                	mv	a0,s3
    8000243c:	ffffe097          	auipc	ra,0xffffe
    80002440:	7c0080e7          	jalr	1984(ra) # 80000bfc <acquire>
  reparent(p);
    80002444:	854e                	mv	a0,s3
    80002446:	00000097          	auipc	ra,0x0
    8000244a:	bfa080e7          	jalr	-1030(ra) # 80002040 <reparent>
  wakeup1(original_parent);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	428080e7          	jalr	1064(ra) # 80001878 <wakeup1>
  p->xstate = status;
    80002458:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000245c:	4791                	li	a5,4
    8000245e:	00f9ac23          	sw	a5,24(s3)
  p->change = 2;
    80002462:	4789                	li	a5,2
    80002464:	16f9a423          	sw	a5,360(s3)
  release(&original_parent->lock);
    80002468:	8526                	mv	a0,s1
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	846080e7          	jalr	-1978(ra) # 80000cb0 <release>
  sched();
    80002472:	00000097          	auipc	ra,0x0
    80002476:	e32080e7          	jalr	-462(ra) # 800022a4 <sched>
  panic("zombie exit");
    8000247a:	00006517          	auipc	a0,0x6
    8000247e:	e2e50513          	addi	a0,a0,-466 # 800082a8 <digits+0x268>
    80002482:	ffffe097          	auipc	ra,0xffffe
    80002486:	0be080e7          	jalr	190(ra) # 80000540 <panic>

000000008000248a <yield>:
{
    8000248a:	1101                	addi	sp,sp,-32
    8000248c:	ec06                	sd	ra,24(sp)
    8000248e:	e822                	sd	s0,16(sp)
    80002490:	e426                	sd	s1,8(sp)
    80002492:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002494:	fffff097          	auipc	ra,0xfffff
    80002498:	65a080e7          	jalr	1626(ra) # 80001aee <myproc>
    8000249c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000249e:	ffffe097          	auipc	ra,0xffffe
    800024a2:	75e080e7          	jalr	1886(ra) # 80000bfc <acquire>
  p->state = RUNNABLE;
    800024a6:	4789                	li	a5,2
    800024a8:	cc9c                	sw	a5,24(s1)
  if (p->priority == 2)
    800024aa:	1784a703          	lw	a4,376(s1)
    800024ae:	02f70063          	beq	a4,a5,800024ce <yield+0x44>
  sched();
    800024b2:	00000097          	auipc	ra,0x0
    800024b6:	df2080e7          	jalr	-526(ra) # 800022a4 <sched>
  release(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7f4080e7          	jalr	2036(ra) # 80000cb0 <release>
}
    800024c4:	60e2                	ld	ra,24(sp)
    800024c6:	6442                	ld	s0,16(sp)
    800024c8:	64a2                	ld	s1,8(sp)
    800024ca:	6105                	addi	sp,sp,32
    800024cc:	8082                	ret
    for (int i = 0; i < tail; i++)
    800024ce:	00007597          	auipc	a1,0x7
    800024d2:	b525a583          	lw	a1,-1198(a1) # 80009020 <tail>
    800024d6:	04b05563          	blez	a1,80002520 <yield+0x96>
    800024da:	00010797          	auipc	a5,0x10
    800024de:	e8e78793          	addi	a5,a5,-370 # 80012368 <pid>
    800024e2:	35fd                	addiw	a1,a1,-1
    800024e4:	02059713          	slli	a4,a1,0x20
    800024e8:	01e75593          	srli	a1,a4,0x1e
    800024ec:	00010717          	auipc	a4,0x10
    800024f0:	e8070713          	addi	a4,a4,-384 # 8001236c <pid+0x4>
    800024f4:	95ba                	add	a1,a1,a4
  int down = 1;
    800024f6:	4505                	li	a0,1
        down = 0;
    800024f8:	4801                	li	a6,0
    800024fa:	a031                	j	80002506 <yield+0x7c>
      pid[i] = 0;
    800024fc:	00072023          	sw	zero,0(a4)
    for (int i = 0; i < tail; i++)
    80002500:	0791                	addi	a5,a5,4
    80002502:	00b78963          	beq	a5,a1,80002514 <yield+0x8a>
      if (pid[i] != p->pid)
    80002506:	873e                	mv	a4,a5
    80002508:	4390                	lw	a2,0(a5)
    8000250a:	5c94                	lw	a3,56(s1)
    8000250c:	fed608e3          	beq	a2,a3,800024fc <yield+0x72>
        down = 0;
    80002510:	8542                	mv	a0,a6
    80002512:	b7ed                	j	800024fc <yield+0x72>
    if (down)
    80002514:	e511                	bnez	a0,80002520 <yield+0x96>
    tail = 0;
    80002516:	00007797          	auipc	a5,0x7
    8000251a:	b007a523          	sw	zero,-1270(a5) # 80009020 <tail>
    8000251e:	bf51                	j	800024b2 <yield+0x28>
      p->change = 1;
    80002520:	4785                	li	a5,1
    80002522:	16f4a423          	sw	a5,360(s1)
    80002526:	bfc5                	j	80002516 <yield+0x8c>

0000000080002528 <sleep>:
{
    80002528:	7179                	addi	sp,sp,-48
    8000252a:	f406                	sd	ra,40(sp)
    8000252c:	f022                	sd	s0,32(sp)
    8000252e:	ec26                	sd	s1,24(sp)
    80002530:	e84a                	sd	s2,16(sp)
    80002532:	e44e                	sd	s3,8(sp)
    80002534:	1800                	addi	s0,sp,48
    80002536:	89aa                	mv	s3,a0
    80002538:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000253a:	fffff097          	auipc	ra,0xfffff
    8000253e:	5b4080e7          	jalr	1460(ra) # 80001aee <myproc>
    80002542:	84aa                	mv	s1,a0
  if (lk != &p->lock)
    80002544:	05250963          	beq	a0,s2,80002596 <sleep+0x6e>
    acquire(&p->lock); //DOC: sleeplock1
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	6b4080e7          	jalr	1716(ra) # 80000bfc <acquire>
    release(lk);
    80002550:	854a                	mv	a0,s2
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	75e080e7          	jalr	1886(ra) # 80000cb0 <release>
  p->chan = chan;
    8000255a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000255e:	4785                	li	a5,1
    80002560:	cc9c                	sw	a5,24(s1)
  p->change = 2;
    80002562:	4789                	li	a5,2
    80002564:	16f4a423          	sw	a5,360(s1)
  sched();
    80002568:	00000097          	auipc	ra,0x0
    8000256c:	d3c080e7          	jalr	-708(ra) # 800022a4 <sched>
  p->chan = 0;
    80002570:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002574:	8526                	mv	a0,s1
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	73a080e7          	jalr	1850(ra) # 80000cb0 <release>
    acquire(lk);
    8000257e:	854a                	mv	a0,s2
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	67c080e7          	jalr	1660(ra) # 80000bfc <acquire>
}
    80002588:	70a2                	ld	ra,40(sp)
    8000258a:	7402                	ld	s0,32(sp)
    8000258c:	64e2                	ld	s1,24(sp)
    8000258e:	6942                	ld	s2,16(sp)
    80002590:	69a2                	ld	s3,8(sp)
    80002592:	6145                	addi	sp,sp,48
    80002594:	8082                	ret
  p->chan = chan;
    80002596:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000259a:	4785                	li	a5,1
    8000259c:	cd1c                	sw	a5,24(a0)
  p->change = 2;
    8000259e:	4789                	li	a5,2
    800025a0:	16f52423          	sw	a5,360(a0)
  sched();
    800025a4:	00000097          	auipc	ra,0x0
    800025a8:	d00080e7          	jalr	-768(ra) # 800022a4 <sched>
  p->chan = 0;
    800025ac:	0204b423          	sd	zero,40(s1)
  if (lk != &p->lock)
    800025b0:	bfe1                	j	80002588 <sleep+0x60>

00000000800025b2 <wait>:
{
    800025b2:	715d                	addi	sp,sp,-80
    800025b4:	e486                	sd	ra,72(sp)
    800025b6:	e0a2                	sd	s0,64(sp)
    800025b8:	fc26                	sd	s1,56(sp)
    800025ba:	f84a                	sd	s2,48(sp)
    800025bc:	f44e                	sd	s3,40(sp)
    800025be:	f052                	sd	s4,32(sp)
    800025c0:	ec56                	sd	s5,24(sp)
    800025c2:	e85a                	sd	s6,16(sp)
    800025c4:	e45e                	sd	s7,8(sp)
    800025c6:	0880                	addi	s0,sp,80
    800025c8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	524080e7          	jalr	1316(ra) # 80001aee <myproc>
    800025d2:	892a                	mv	s2,a0
  acquire(&p->lock);
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	628080e7          	jalr	1576(ra) # 80000bfc <acquire>
    havekids = 0;
    800025dc:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    800025de:	4a11                	li	s4,4
        havekids = 1;
    800025e0:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    800025e2:	00016997          	auipc	s3,0x16
    800025e6:	e8698993          	addi	s3,s3,-378 # 80018468 <tickslock>
    havekids = 0;
    800025ea:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    800025ec:	00010497          	auipc	s1,0x10
    800025f0:	e7c48493          	addi	s1,s1,-388 # 80012468 <proc>
    800025f4:	a08d                	j	80002656 <wait+0xa4>
          pid = np->pid;
    800025f6:	0384a983          	lw	s3,56(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025fa:	000b0e63          	beqz	s6,80002616 <wait+0x64>
    800025fe:	4691                	li	a3,4
    80002600:	03448613          	addi	a2,s1,52
    80002604:	85da                	mv	a1,s6
    80002606:	05093503          	ld	a0,80(s2)
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	0a0080e7          	jalr	160(ra) # 800016aa <copyout>
    80002612:	02054263          	bltz	a0,80002636 <wait+0x84>
          freeproc(np);
    80002616:	8526                	mv	a0,s1
    80002618:	fffff097          	auipc	ra,0xfffff
    8000261c:	68a080e7          	jalr	1674(ra) # 80001ca2 <freeproc>
          release(&np->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	68e080e7          	jalr	1678(ra) # 80000cb0 <release>
          release(&p->lock);
    8000262a:	854a                	mv	a0,s2
    8000262c:	ffffe097          	auipc	ra,0xffffe
    80002630:	684080e7          	jalr	1668(ra) # 80000cb0 <release>
          return pid;
    80002634:	a8a9                	j	8000268e <wait+0xdc>
            release(&np->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	678080e7          	jalr	1656(ra) # 80000cb0 <release>
            release(&p->lock);
    80002640:	854a                	mv	a0,s2
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	66e080e7          	jalr	1646(ra) # 80000cb0 <release>
            return -1;
    8000264a:	59fd                	li	s3,-1
    8000264c:	a089                	j	8000268e <wait+0xdc>
    for (np = proc; np < &proc[NPROC]; np++)
    8000264e:	18048493          	addi	s1,s1,384
    80002652:	03348463          	beq	s1,s3,8000267a <wait+0xc8>
      if (np->parent == p)
    80002656:	709c                	ld	a5,32(s1)
    80002658:	ff279be3          	bne	a5,s2,8000264e <wait+0x9c>
        acquire(&np->lock);
    8000265c:	8526                	mv	a0,s1
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	59e080e7          	jalr	1438(ra) # 80000bfc <acquire>
        if (np->state == ZOMBIE)
    80002666:	4c9c                	lw	a5,24(s1)
    80002668:	f94787e3          	beq	a5,s4,800025f6 <wait+0x44>
        release(&np->lock);
    8000266c:	8526                	mv	a0,s1
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	642080e7          	jalr	1602(ra) # 80000cb0 <release>
        havekids = 1;
    80002676:	8756                	mv	a4,s5
    80002678:	bfd9                	j	8000264e <wait+0x9c>
    if (!havekids || p->killed)
    8000267a:	c701                	beqz	a4,80002682 <wait+0xd0>
    8000267c:	03092783          	lw	a5,48(s2)
    80002680:	c39d                	beqz	a5,800026a6 <wait+0xf4>
      release(&p->lock);
    80002682:	854a                	mv	a0,s2
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	62c080e7          	jalr	1580(ra) # 80000cb0 <release>
      return -1;
    8000268c:	59fd                	li	s3,-1
}
    8000268e:	854e                	mv	a0,s3
    80002690:	60a6                	ld	ra,72(sp)
    80002692:	6406                	ld	s0,64(sp)
    80002694:	74e2                	ld	s1,56(sp)
    80002696:	7942                	ld	s2,48(sp)
    80002698:	79a2                	ld	s3,40(sp)
    8000269a:	7a02                	ld	s4,32(sp)
    8000269c:	6ae2                	ld	s5,24(sp)
    8000269e:	6b42                	ld	s6,16(sp)
    800026a0:	6ba2                	ld	s7,8(sp)
    800026a2:	6161                	addi	sp,sp,80
    800026a4:	8082                	ret
    sleep(p, &p->lock); //DOC: wait-sleep
    800026a6:	85ca                	mv	a1,s2
    800026a8:	854a                	mv	a0,s2
    800026aa:	00000097          	auipc	ra,0x0
    800026ae:	e7e080e7          	jalr	-386(ra) # 80002528 <sleep>
    havekids = 0;
    800026b2:	bf25                	j	800025ea <wait+0x38>

00000000800026b4 <wakeup>:
{
    800026b4:	7139                	addi	sp,sp,-64
    800026b6:	fc06                	sd	ra,56(sp)
    800026b8:	f822                	sd	s0,48(sp)
    800026ba:	f426                	sd	s1,40(sp)
    800026bc:	f04a                	sd	s2,32(sp)
    800026be:	ec4e                	sd	s3,24(sp)
    800026c0:	e852                	sd	s4,16(sp)
    800026c2:	e456                	sd	s5,8(sp)
    800026c4:	e05a                	sd	s6,0(sp)
    800026c6:	0080                	addi	s0,sp,64
    800026c8:	8a2a                	mv	s4,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800026ca:	00010497          	auipc	s1,0x10
    800026ce:	d9e48493          	addi	s1,s1,-610 # 80012468 <proc>
    if (p->state == SLEEPING && p->chan == chan)
    800026d2:	4985                	li	s3,1
      p->state = RUNNABLE;
    800026d4:	4b09                	li	s6,2
      p->change = 3;
    800026d6:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800026d8:	00016917          	auipc	s2,0x16
    800026dc:	d9090913          	addi	s2,s2,-624 # 80018468 <tickslock>
    800026e0:	a811                	j	800026f4 <wakeup+0x40>
    release(&p->lock);
    800026e2:	8526                	mv	a0,s1
    800026e4:	ffffe097          	auipc	ra,0xffffe
    800026e8:	5cc080e7          	jalr	1484(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026ec:	18048493          	addi	s1,s1,384
    800026f0:	03248263          	beq	s1,s2,80002714 <wakeup+0x60>
    acquire(&p->lock);
    800026f4:	8526                	mv	a0,s1
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	506080e7          	jalr	1286(ra) # 80000bfc <acquire>
    if (p->state == SLEEPING && p->chan == chan)
    800026fe:	4c9c                	lw	a5,24(s1)
    80002700:	ff3791e3          	bne	a5,s3,800026e2 <wakeup+0x2e>
    80002704:	749c                	ld	a5,40(s1)
    80002706:	fd479ee3          	bne	a5,s4,800026e2 <wakeup+0x2e>
      p->state = RUNNABLE;
    8000270a:	0164ac23          	sw	s6,24(s1)
      p->change = 3;
    8000270e:	1754a423          	sw	s5,360(s1)
    80002712:	bfc1                	j	800026e2 <wakeup+0x2e>
}
    80002714:	70e2                	ld	ra,56(sp)
    80002716:	7442                	ld	s0,48(sp)
    80002718:	74a2                	ld	s1,40(sp)
    8000271a:	7902                	ld	s2,32(sp)
    8000271c:	69e2                	ld	s3,24(sp)
    8000271e:	6a42                	ld	s4,16(sp)
    80002720:	6aa2                	ld	s5,8(sp)
    80002722:	6b02                	ld	s6,0(sp)
    80002724:	6121                	addi	sp,sp,64
    80002726:	8082                	ret

0000000080002728 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002728:	7179                	addi	sp,sp,-48
    8000272a:	f406                	sd	ra,40(sp)
    8000272c:	f022                	sd	s0,32(sp)
    8000272e:	ec26                	sd	s1,24(sp)
    80002730:	e84a                	sd	s2,16(sp)
    80002732:	e44e                	sd	s3,8(sp)
    80002734:	1800                	addi	s0,sp,48
    80002736:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002738:	00010497          	auipc	s1,0x10
    8000273c:	d3048493          	addi	s1,s1,-720 # 80012468 <proc>
    80002740:	00016997          	auipc	s3,0x16
    80002744:	d2898993          	addi	s3,s3,-728 # 80018468 <tickslock>
  {
    acquire(&p->lock);
    80002748:	8526                	mv	a0,s1
    8000274a:	ffffe097          	auipc	ra,0xffffe
    8000274e:	4b2080e7          	jalr	1202(ra) # 80000bfc <acquire>
    if (p->pid == pid)
    80002752:	5c9c                	lw	a5,56(s1)
    80002754:	01278d63          	beq	a5,s2,8000276e <kill+0x46>
        p->change = 3;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002758:	8526                	mv	a0,s1
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	556080e7          	jalr	1366(ra) # 80000cb0 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002762:	18048493          	addi	s1,s1,384
    80002766:	ff3491e3          	bne	s1,s3,80002748 <kill+0x20>
  }
  return -1;
    8000276a:	557d                	li	a0,-1
    8000276c:	a821                	j	80002784 <kill+0x5c>
      p->killed = 1;
    8000276e:	4785                	li	a5,1
    80002770:	d89c                	sw	a5,48(s1)
      if (p->state == SLEEPING)
    80002772:	4c98                	lw	a4,24(s1)
    80002774:	00f70f63          	beq	a4,a5,80002792 <kill+0x6a>
      release(&p->lock);
    80002778:	8526                	mv	a0,s1
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	536080e7          	jalr	1334(ra) # 80000cb0 <release>
      return 0;
    80002782:	4501                	li	a0,0
}
    80002784:	70a2                	ld	ra,40(sp)
    80002786:	7402                	ld	s0,32(sp)
    80002788:	64e2                	ld	s1,24(sp)
    8000278a:	6942                	ld	s2,16(sp)
    8000278c:	69a2                	ld	s3,8(sp)
    8000278e:	6145                	addi	sp,sp,48
    80002790:	8082                	ret
        p->state = RUNNABLE;
    80002792:	4789                	li	a5,2
    80002794:	cc9c                	sw	a5,24(s1)
        p->change = 3;
    80002796:	478d                	li	a5,3
    80002798:	16f4a423          	sw	a5,360(s1)
    8000279c:	bff1                	j	80002778 <kill+0x50>

000000008000279e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000279e:	7179                	addi	sp,sp,-48
    800027a0:	f406                	sd	ra,40(sp)
    800027a2:	f022                	sd	s0,32(sp)
    800027a4:	ec26                	sd	s1,24(sp)
    800027a6:	e84a                	sd	s2,16(sp)
    800027a8:	e44e                	sd	s3,8(sp)
    800027aa:	e052                	sd	s4,0(sp)
    800027ac:	1800                	addi	s0,sp,48
    800027ae:	84aa                	mv	s1,a0
    800027b0:	892e                	mv	s2,a1
    800027b2:	89b2                	mv	s3,a2
    800027b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027b6:	fffff097          	auipc	ra,0xfffff
    800027ba:	338080e7          	jalr	824(ra) # 80001aee <myproc>
  if (user_dst)
    800027be:	c08d                	beqz	s1,800027e0 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027c0:	86d2                	mv	a3,s4
    800027c2:	864e                	mv	a2,s3
    800027c4:	85ca                	mv	a1,s2
    800027c6:	6928                	ld	a0,80(a0)
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	ee2080e7          	jalr	-286(ra) # 800016aa <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027d0:	70a2                	ld	ra,40(sp)
    800027d2:	7402                	ld	s0,32(sp)
    800027d4:	64e2                	ld	s1,24(sp)
    800027d6:	6942                	ld	s2,16(sp)
    800027d8:	69a2                	ld	s3,8(sp)
    800027da:	6a02                	ld	s4,0(sp)
    800027dc:	6145                	addi	sp,sp,48
    800027de:	8082                	ret
    memmove((char *)dst, src, len);
    800027e0:	000a061b          	sext.w	a2,s4
    800027e4:	85ce                	mv	a1,s3
    800027e6:	854a                	mv	a0,s2
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	56c080e7          	jalr	1388(ra) # 80000d54 <memmove>
    return 0;
    800027f0:	8526                	mv	a0,s1
    800027f2:	bff9                	j	800027d0 <either_copyout+0x32>

00000000800027f4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800027f4:	7179                	addi	sp,sp,-48
    800027f6:	f406                	sd	ra,40(sp)
    800027f8:	f022                	sd	s0,32(sp)
    800027fa:	ec26                	sd	s1,24(sp)
    800027fc:	e84a                	sd	s2,16(sp)
    800027fe:	e44e                	sd	s3,8(sp)
    80002800:	e052                	sd	s4,0(sp)
    80002802:	1800                	addi	s0,sp,48
    80002804:	892a                	mv	s2,a0
    80002806:	84ae                	mv	s1,a1
    80002808:	89b2                	mv	s3,a2
    8000280a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000280c:	fffff097          	auipc	ra,0xfffff
    80002810:	2e2080e7          	jalr	738(ra) # 80001aee <myproc>
  if (user_src)
    80002814:	c08d                	beqz	s1,80002836 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002816:	86d2                	mv	a3,s4
    80002818:	864e                	mv	a2,s3
    8000281a:	85ca                	mv	a1,s2
    8000281c:	6928                	ld	a0,80(a0)
    8000281e:	fffff097          	auipc	ra,0xfffff
    80002822:	f18080e7          	jalr	-232(ra) # 80001736 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002826:	70a2                	ld	ra,40(sp)
    80002828:	7402                	ld	s0,32(sp)
    8000282a:	64e2                	ld	s1,24(sp)
    8000282c:	6942                	ld	s2,16(sp)
    8000282e:	69a2                	ld	s3,8(sp)
    80002830:	6a02                	ld	s4,0(sp)
    80002832:	6145                	addi	sp,sp,48
    80002834:	8082                	ret
    memmove(dst, (char *)src, len);
    80002836:	000a061b          	sext.w	a2,s4
    8000283a:	85ce                	mv	a1,s3
    8000283c:	854a                	mv	a0,s2
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	516080e7          	jalr	1302(ra) # 80000d54 <memmove>
    return 0;
    80002846:	8526                	mv	a0,s1
    80002848:	bff9                	j	80002826 <either_copyin+0x32>

000000008000284a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000284a:	715d                	addi	sp,sp,-80
    8000284c:	e486                	sd	ra,72(sp)
    8000284e:	e0a2                	sd	s0,64(sp)
    80002850:	fc26                	sd	s1,56(sp)
    80002852:	f84a                	sd	s2,48(sp)
    80002854:	f44e                	sd	s3,40(sp)
    80002856:	f052                	sd	s4,32(sp)
    80002858:	ec56                	sd	s5,24(sp)
    8000285a:	e85a                	sd	s6,16(sp)
    8000285c:	e45e                	sd	s7,8(sp)
    8000285e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002860:	00006517          	auipc	a0,0x6
    80002864:	88850513          	addi	a0,a0,-1912 # 800080e8 <digits+0xa8>
    80002868:	ffffe097          	auipc	ra,0xffffe
    8000286c:	d22080e7          	jalr	-734(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002870:	00010497          	auipc	s1,0x10
    80002874:	d5048493          	addi	s1,s1,-688 # 800125c0 <proc+0x158>
    80002878:	00016917          	auipc	s2,0x16
    8000287c:	d4890913          	addi	s2,s2,-696 # 800185c0 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002880:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002882:	00006997          	auipc	s3,0x6
    80002886:	a3698993          	addi	s3,s3,-1482 # 800082b8 <digits+0x278>
    printf("%d %s %s", p->pid, state, p->name);
    8000288a:	00006a97          	auipc	s5,0x6
    8000288e:	a36a8a93          	addi	s5,s5,-1482 # 800082c0 <digits+0x280>
    printf("\n");
    80002892:	00006a17          	auipc	s4,0x6
    80002896:	856a0a13          	addi	s4,s4,-1962 # 800080e8 <digits+0xa8>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000289a:	00006b97          	auipc	s7,0x6
    8000289e:	a5eb8b93          	addi	s7,s7,-1442 # 800082f8 <states.0>
    800028a2:	a00d                	j	800028c4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028a4:	ee06a583          	lw	a1,-288(a3)
    800028a8:	8556                	mv	a0,s5
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	ce0080e7          	jalr	-800(ra) # 8000058a <printf>
    printf("\n");
    800028b2:	8552                	mv	a0,s4
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	cd6080e7          	jalr	-810(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028bc:	18048493          	addi	s1,s1,384
    800028c0:	03248263          	beq	s1,s2,800028e4 <procdump+0x9a>
    if (p->state == UNUSED)
    800028c4:	86a6                	mv	a3,s1
    800028c6:	ec04a783          	lw	a5,-320(s1)
    800028ca:	dbed                	beqz	a5,800028bc <procdump+0x72>
      state = "???";
    800028cc:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ce:	fcfb6be3          	bltu	s6,a5,800028a4 <procdump+0x5a>
    800028d2:	02079713          	slli	a4,a5,0x20
    800028d6:	01d75793          	srli	a5,a4,0x1d
    800028da:	97de                	add	a5,a5,s7
    800028dc:	6390                	ld	a2,0(a5)
    800028de:	f279                	bnez	a2,800028a4 <procdump+0x5a>
      state = "???";
    800028e0:	864e                	mv	a2,s3
    800028e2:	b7c9                	j	800028a4 <procdump+0x5a>
  }
}
    800028e4:	60a6                	ld	ra,72(sp)
    800028e6:	6406                	ld	s0,64(sp)
    800028e8:	74e2                	ld	s1,56(sp)
    800028ea:	7942                	ld	s2,48(sp)
    800028ec:	79a2                	ld	s3,40(sp)
    800028ee:	7a02                	ld	s4,32(sp)
    800028f0:	6ae2                	ld	s5,24(sp)
    800028f2:	6b42                	ld	s6,16(sp)
    800028f4:	6ba2                	ld	s7,8(sp)
    800028f6:	6161                	addi	sp,sp,80
    800028f8:	8082                	ret

00000000800028fa <swtch>:
    800028fa:	00153023          	sd	ra,0(a0)
    800028fe:	00253423          	sd	sp,8(a0)
    80002902:	e900                	sd	s0,16(a0)
    80002904:	ed04                	sd	s1,24(a0)
    80002906:	03253023          	sd	s2,32(a0)
    8000290a:	03353423          	sd	s3,40(a0)
    8000290e:	03453823          	sd	s4,48(a0)
    80002912:	03553c23          	sd	s5,56(a0)
    80002916:	05653023          	sd	s6,64(a0)
    8000291a:	05753423          	sd	s7,72(a0)
    8000291e:	05853823          	sd	s8,80(a0)
    80002922:	05953c23          	sd	s9,88(a0)
    80002926:	07a53023          	sd	s10,96(a0)
    8000292a:	07b53423          	sd	s11,104(a0)
    8000292e:	0005b083          	ld	ra,0(a1)
    80002932:	0085b103          	ld	sp,8(a1)
    80002936:	6980                	ld	s0,16(a1)
    80002938:	6d84                	ld	s1,24(a1)
    8000293a:	0205b903          	ld	s2,32(a1)
    8000293e:	0285b983          	ld	s3,40(a1)
    80002942:	0305ba03          	ld	s4,48(a1)
    80002946:	0385ba83          	ld	s5,56(a1)
    8000294a:	0405bb03          	ld	s6,64(a1)
    8000294e:	0485bb83          	ld	s7,72(a1)
    80002952:	0505bc03          	ld	s8,80(a1)
    80002956:	0585bc83          	ld	s9,88(a1)
    8000295a:	0605bd03          	ld	s10,96(a1)
    8000295e:	0685bd83          	ld	s11,104(a1)
    80002962:	8082                	ret

0000000080002964 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002964:	1141                	addi	sp,sp,-16
    80002966:	e406                	sd	ra,8(sp)
    80002968:	e022                	sd	s0,0(sp)
    8000296a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000296c:	00006597          	auipc	a1,0x6
    80002970:	9b458593          	addi	a1,a1,-1612 # 80008320 <states.0+0x28>
    80002974:	00016517          	auipc	a0,0x16
    80002978:	af450513          	addi	a0,a0,-1292 # 80018468 <tickslock>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	1f0080e7          	jalr	496(ra) # 80000b6c <initlock>
}
    80002984:	60a2                	ld	ra,8(sp)
    80002986:	6402                	ld	s0,0(sp)
    80002988:	0141                	addi	sp,sp,16
    8000298a:	8082                	ret

000000008000298c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000298c:	1141                	addi	sp,sp,-16
    8000298e:	e422                	sd	s0,8(sp)
    80002990:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002992:	00003797          	auipc	a5,0x3
    80002996:	4de78793          	addi	a5,a5,1246 # 80005e70 <kernelvec>
    8000299a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000299e:	6422                	ld	s0,8(sp)
    800029a0:	0141                	addi	sp,sp,16
    800029a2:	8082                	ret

00000000800029a4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029a4:	1141                	addi	sp,sp,-16
    800029a6:	e406                	sd	ra,8(sp)
    800029a8:	e022                	sd	s0,0(sp)
    800029aa:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029ac:	fffff097          	auipc	ra,0xfffff
    800029b0:	142080e7          	jalr	322(ra) # 80001aee <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029b8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ba:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029be:	00004617          	auipc	a2,0x4
    800029c2:	64260613          	addi	a2,a2,1602 # 80007000 <_trampoline>
    800029c6:	00004697          	auipc	a3,0x4
    800029ca:	63a68693          	addi	a3,a3,1594 # 80007000 <_trampoline>
    800029ce:	8e91                	sub	a3,a3,a2
    800029d0:	040007b7          	lui	a5,0x4000
    800029d4:	17fd                	addi	a5,a5,-1
    800029d6:	07b2                	slli	a5,a5,0xc
    800029d8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029da:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029de:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029e0:	180026f3          	csrr	a3,satp
    800029e4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e6:	6d38                	ld	a4,88(a0)
    800029e8:	6134                	ld	a3,64(a0)
    800029ea:	6585                	lui	a1,0x1
    800029ec:	96ae                	add	a3,a3,a1
    800029ee:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029f0:	6d38                	ld	a4,88(a0)
    800029f2:	00000697          	auipc	a3,0x0
    800029f6:	13868693          	addi	a3,a3,312 # 80002b2a <usertrap>
    800029fa:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029fc:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029fe:	8692                	mv	a3,tp
    80002a00:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a06:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a0a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a0e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a12:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a14:	6f18                	ld	a4,24(a4)
    80002a16:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a1a:	692c                	ld	a1,80(a0)
    80002a1c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a1e:	00004717          	auipc	a4,0x4
    80002a22:	67270713          	addi	a4,a4,1650 # 80007090 <userret>
    80002a26:	8f11                	sub	a4,a4,a2
    80002a28:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a2a:	577d                	li	a4,-1
    80002a2c:	177e                	slli	a4,a4,0x3f
    80002a2e:	8dd9                	or	a1,a1,a4
    80002a30:	02000537          	lui	a0,0x2000
    80002a34:	157d                	addi	a0,a0,-1
    80002a36:	0536                	slli	a0,a0,0xd
    80002a38:	9782                	jalr	a5
}
    80002a3a:	60a2                	ld	ra,8(sp)
    80002a3c:	6402                	ld	s0,0(sp)
    80002a3e:	0141                	addi	sp,sp,16
    80002a40:	8082                	ret

0000000080002a42 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a42:	1101                	addi	sp,sp,-32
    80002a44:	ec06                	sd	ra,24(sp)
    80002a46:	e822                	sd	s0,16(sp)
    80002a48:	e426                	sd	s1,8(sp)
    80002a4a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a4c:	00016497          	auipc	s1,0x16
    80002a50:	a1c48493          	addi	s1,s1,-1508 # 80018468 <tickslock>
    80002a54:	8526                	mv	a0,s1
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	1a6080e7          	jalr	422(ra) # 80000bfc <acquire>
  ticks++;
    80002a5e:	00006517          	auipc	a0,0x6
    80002a62:	5c650513          	addi	a0,a0,1478 # 80009024 <ticks>
    80002a66:	411c                	lw	a5,0(a0)
    80002a68:	2785                	addiw	a5,a5,1
    80002a6a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a6c:	00000097          	auipc	ra,0x0
    80002a70:	c48080e7          	jalr	-952(ra) # 800026b4 <wakeup>
  release(&tickslock);
    80002a74:	8526                	mv	a0,s1
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	23a080e7          	jalr	570(ra) # 80000cb0 <release>
}
    80002a7e:	60e2                	ld	ra,24(sp)
    80002a80:	6442                	ld	s0,16(sp)
    80002a82:	64a2                	ld	s1,8(sp)
    80002a84:	6105                	addi	sp,sp,32
    80002a86:	8082                	ret

0000000080002a88 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a88:	1101                	addi	sp,sp,-32
    80002a8a:	ec06                	sd	ra,24(sp)
    80002a8c:	e822                	sd	s0,16(sp)
    80002a8e:	e426                	sd	s1,8(sp)
    80002a90:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a92:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a96:	00074d63          	bltz	a4,80002ab0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a9a:	57fd                	li	a5,-1
    80002a9c:	17fe                	slli	a5,a5,0x3f
    80002a9e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002aa0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002aa2:	06f70363          	beq	a4,a5,80002b08 <devintr+0x80>
  }
}
    80002aa6:	60e2                	ld	ra,24(sp)
    80002aa8:	6442                	ld	s0,16(sp)
    80002aaa:	64a2                	ld	s1,8(sp)
    80002aac:	6105                	addi	sp,sp,32
    80002aae:	8082                	ret
     (scause & 0xff) == 9){
    80002ab0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ab4:	46a5                	li	a3,9
    80002ab6:	fed792e3          	bne	a5,a3,80002a9a <devintr+0x12>
    int irq = plic_claim();
    80002aba:	00003097          	auipc	ra,0x3
    80002abe:	4be080e7          	jalr	1214(ra) # 80005f78 <plic_claim>
    80002ac2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ac4:	47a9                	li	a5,10
    80002ac6:	02f50763          	beq	a0,a5,80002af4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002aca:	4785                	li	a5,1
    80002acc:	02f50963          	beq	a0,a5,80002afe <devintr+0x76>
    return 1;
    80002ad0:	4505                	li	a0,1
    } else if(irq){
    80002ad2:	d8f1                	beqz	s1,80002aa6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ad4:	85a6                	mv	a1,s1
    80002ad6:	00006517          	auipc	a0,0x6
    80002ada:	85250513          	addi	a0,a0,-1966 # 80008328 <states.0+0x30>
    80002ade:	ffffe097          	auipc	ra,0xffffe
    80002ae2:	aac080e7          	jalr	-1364(ra) # 8000058a <printf>
      plic_complete(irq);
    80002ae6:	8526                	mv	a0,s1
    80002ae8:	00003097          	auipc	ra,0x3
    80002aec:	4b4080e7          	jalr	1204(ra) # 80005f9c <plic_complete>
    return 1;
    80002af0:	4505                	li	a0,1
    80002af2:	bf55                	j	80002aa6 <devintr+0x1e>
      uartintr();
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	ecc080e7          	jalr	-308(ra) # 800009c0 <uartintr>
    80002afc:	b7ed                	j	80002ae6 <devintr+0x5e>
      virtio_disk_intr();
    80002afe:	00004097          	auipc	ra,0x4
    80002b02:	918080e7          	jalr	-1768(ra) # 80006416 <virtio_disk_intr>
    80002b06:	b7c5                	j	80002ae6 <devintr+0x5e>
    if(cpuid() == 0){
    80002b08:	fffff097          	auipc	ra,0xfffff
    80002b0c:	fba080e7          	jalr	-70(ra) # 80001ac2 <cpuid>
    80002b10:	c901                	beqz	a0,80002b20 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b12:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b16:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b18:	14479073          	csrw	sip,a5
    return 2;
    80002b1c:	4509                	li	a0,2
    80002b1e:	b761                	j	80002aa6 <devintr+0x1e>
      clockintr();
    80002b20:	00000097          	auipc	ra,0x0
    80002b24:	f22080e7          	jalr	-222(ra) # 80002a42 <clockintr>
    80002b28:	b7ed                	j	80002b12 <devintr+0x8a>

0000000080002b2a <usertrap>:
{
    80002b2a:	1101                	addi	sp,sp,-32
    80002b2c:	ec06                	sd	ra,24(sp)
    80002b2e:	e822                	sd	s0,16(sp)
    80002b30:	e426                	sd	s1,8(sp)
    80002b32:	e04a                	sd	s2,0(sp)
    80002b34:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b36:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b3a:	1007f793          	andi	a5,a5,256
    80002b3e:	e3ad                	bnez	a5,80002ba0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b40:	00003797          	auipc	a5,0x3
    80002b44:	33078793          	addi	a5,a5,816 # 80005e70 <kernelvec>
    80002b48:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	fa2080e7          	jalr	-94(ra) # 80001aee <myproc>
    80002b54:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b56:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b58:	14102773          	csrr	a4,sepc
    80002b5c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b62:	47a1                	li	a5,8
    80002b64:	04f71c63          	bne	a4,a5,80002bbc <usertrap+0x92>
    if(p->killed)
    80002b68:	591c                	lw	a5,48(a0)
    80002b6a:	e3b9                	bnez	a5,80002bb0 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b6c:	6cb8                	ld	a4,88(s1)
    80002b6e:	6f1c                	ld	a5,24(a4)
    80002b70:	0791                	addi	a5,a5,4
    80002b72:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b74:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b78:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7c:	10079073          	csrw	sstatus,a5
    syscall();
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	2f8080e7          	jalr	760(ra) # 80002e78 <syscall>
  if(p->killed)
    80002b88:	589c                	lw	a5,48(s1)
    80002b8a:	ebc1                	bnez	a5,80002c1a <usertrap+0xf0>
  usertrapret();
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	e18080e7          	jalr	-488(ra) # 800029a4 <usertrapret>
}
    80002b94:	60e2                	ld	ra,24(sp)
    80002b96:	6442                	ld	s0,16(sp)
    80002b98:	64a2                	ld	s1,8(sp)
    80002b9a:	6902                	ld	s2,0(sp)
    80002b9c:	6105                	addi	sp,sp,32
    80002b9e:	8082                	ret
    panic("usertrap: not from user mode");
    80002ba0:	00005517          	auipc	a0,0x5
    80002ba4:	7a850513          	addi	a0,a0,1960 # 80008348 <states.0+0x50>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	998080e7          	jalr	-1640(ra) # 80000540 <panic>
      exit(-1);
    80002bb0:	557d                	li	a0,-1
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	7c8080e7          	jalr	1992(ra) # 8000237a <exit>
    80002bba:	bf4d                	j	80002b6c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	ecc080e7          	jalr	-308(ra) # 80002a88 <devintr>
    80002bc4:	892a                	mv	s2,a0
    80002bc6:	c501                	beqz	a0,80002bce <usertrap+0xa4>
  if(p->killed)
    80002bc8:	589c                	lw	a5,48(s1)
    80002bca:	c3a1                	beqz	a5,80002c0a <usertrap+0xe0>
    80002bcc:	a815                	j	80002c00 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bce:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bd2:	5c90                	lw	a2,56(s1)
    80002bd4:	00005517          	auipc	a0,0x5
    80002bd8:	79450513          	addi	a0,a0,1940 # 80008368 <states.0+0x70>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	9ae080e7          	jalr	-1618(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002be8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bec:	00005517          	auipc	a0,0x5
    80002bf0:	7ac50513          	addi	a0,a0,1964 # 80008398 <states.0+0xa0>
    80002bf4:	ffffe097          	auipc	ra,0xffffe
    80002bf8:	996080e7          	jalr	-1642(ra) # 8000058a <printf>
    p->killed = 1;
    80002bfc:	4785                	li	a5,1
    80002bfe:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002c00:	557d                	li	a0,-1
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	778080e7          	jalr	1912(ra) # 8000237a <exit>
  if(which_dev == 2)
    80002c0a:	4789                	li	a5,2
    80002c0c:	f8f910e3          	bne	s2,a5,80002b8c <usertrap+0x62>
    yield();
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	87a080e7          	jalr	-1926(ra) # 8000248a <yield>
    80002c18:	bf95                	j	80002b8c <usertrap+0x62>
  int which_dev = 0;
    80002c1a:	4901                	li	s2,0
    80002c1c:	b7d5                	j	80002c00 <usertrap+0xd6>

0000000080002c1e <kerneltrap>:
{
    80002c1e:	7179                	addi	sp,sp,-48
    80002c20:	f406                	sd	ra,40(sp)
    80002c22:	f022                	sd	s0,32(sp)
    80002c24:	ec26                	sd	s1,24(sp)
    80002c26:	e84a                	sd	s2,16(sp)
    80002c28:	e44e                	sd	s3,8(sp)
    80002c2a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c30:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c34:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c38:	1004f793          	andi	a5,s1,256
    80002c3c:	cb85                	beqz	a5,80002c6c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c3e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c42:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c44:	ef85                	bnez	a5,80002c7c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	e42080e7          	jalr	-446(ra) # 80002a88 <devintr>
    80002c4e:	cd1d                	beqz	a0,80002c8c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c50:	4789                	li	a5,2
    80002c52:	08f50663          	beq	a0,a5,80002cde <kerneltrap+0xc0>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c56:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c5a:	10049073          	csrw	sstatus,s1
}
    80002c5e:	70a2                	ld	ra,40(sp)
    80002c60:	7402                	ld	s0,32(sp)
    80002c62:	64e2                	ld	s1,24(sp)
    80002c64:	6942                	ld	s2,16(sp)
    80002c66:	69a2                	ld	s3,8(sp)
    80002c68:	6145                	addi	sp,sp,48
    80002c6a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c6c:	00005517          	auipc	a0,0x5
    80002c70:	74c50513          	addi	a0,a0,1868 # 800083b8 <states.0+0xc0>
    80002c74:	ffffe097          	auipc	ra,0xffffe
    80002c78:	8cc080e7          	jalr	-1844(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c7c:	00005517          	auipc	a0,0x5
    80002c80:	76450513          	addi	a0,a0,1892 # 800083e0 <states.0+0xe8>
    80002c84:	ffffe097          	auipc	ra,0xffffe
    80002c88:	8bc080e7          	jalr	-1860(ra) # 80000540 <panic>
    printf("%d\n", ticks);
    80002c8c:	00006597          	auipc	a1,0x6
    80002c90:	3985a583          	lw	a1,920(a1) # 80009024 <ticks>
    80002c94:	00005517          	auipc	a0,0x5
    80002c98:	7c450513          	addi	a0,a0,1988 # 80008458 <states.0+0x160>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8ee080e7          	jalr	-1810(ra) # 8000058a <printf>
    printf("scause %p\n", scause);
    80002ca4:	85ce                	mv	a1,s3
    80002ca6:	00005517          	auipc	a0,0x5
    80002caa:	75a50513          	addi	a0,a0,1882 # 80008400 <states.0+0x108>
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	8dc080e7          	jalr	-1828(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cba:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cbe:	00005517          	auipc	a0,0x5
    80002cc2:	75250513          	addi	a0,a0,1874 # 80008410 <states.0+0x118>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	8c4080e7          	jalr	-1852(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002cce:	00005517          	auipc	a0,0x5
    80002cd2:	75a50513          	addi	a0,a0,1882 # 80008428 <states.0+0x130>
    80002cd6:	ffffe097          	auipc	ra,0xffffe
    80002cda:	86a080e7          	jalr	-1942(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	e10080e7          	jalr	-496(ra) # 80001aee <myproc>
    80002ce6:	d925                	beqz	a0,80002c56 <kerneltrap+0x38>
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	e06080e7          	jalr	-506(ra) # 80001aee <myproc>
    80002cf0:	4d18                	lw	a4,24(a0)
    80002cf2:	478d                	li	a5,3
    80002cf4:	f6f711e3          	bne	a4,a5,80002c56 <kerneltrap+0x38>
    yield();
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	792080e7          	jalr	1938(ra) # 8000248a <yield>
    80002d00:	bf99                	j	80002c56 <kerneltrap+0x38>

0000000080002d02 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d02:	1101                	addi	sp,sp,-32
    80002d04:	ec06                	sd	ra,24(sp)
    80002d06:	e822                	sd	s0,16(sp)
    80002d08:	e426                	sd	s1,8(sp)
    80002d0a:	1000                	addi	s0,sp,32
    80002d0c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	de0080e7          	jalr	-544(ra) # 80001aee <myproc>
  switch (n)
    80002d16:	4795                	li	a5,5
    80002d18:	0497e163          	bltu	a5,s1,80002d5a <argraw+0x58>
    80002d1c:	048a                	slli	s1,s1,0x2
    80002d1e:	00005717          	auipc	a4,0x5
    80002d22:	74270713          	addi	a4,a4,1858 # 80008460 <states.0+0x168>
    80002d26:	94ba                	add	s1,s1,a4
    80002d28:	409c                	lw	a5,0(s1)
    80002d2a:	97ba                	add	a5,a5,a4
    80002d2c:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002d2e:	6d3c                	ld	a5,88(a0)
    80002d30:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d32:	60e2                	ld	ra,24(sp)
    80002d34:	6442                	ld	s0,16(sp)
    80002d36:	64a2                	ld	s1,8(sp)
    80002d38:	6105                	addi	sp,sp,32
    80002d3a:	8082                	ret
    return p->trapframe->a1;
    80002d3c:	6d3c                	ld	a5,88(a0)
    80002d3e:	7fa8                	ld	a0,120(a5)
    80002d40:	bfcd                	j	80002d32 <argraw+0x30>
    return p->trapframe->a2;
    80002d42:	6d3c                	ld	a5,88(a0)
    80002d44:	63c8                	ld	a0,128(a5)
    80002d46:	b7f5                	j	80002d32 <argraw+0x30>
    return p->trapframe->a3;
    80002d48:	6d3c                	ld	a5,88(a0)
    80002d4a:	67c8                	ld	a0,136(a5)
    80002d4c:	b7dd                	j	80002d32 <argraw+0x30>
    return p->trapframe->a4;
    80002d4e:	6d3c                	ld	a5,88(a0)
    80002d50:	6bc8                	ld	a0,144(a5)
    80002d52:	b7c5                	j	80002d32 <argraw+0x30>
    return p->trapframe->a5;
    80002d54:	6d3c                	ld	a5,88(a0)
    80002d56:	6fc8                	ld	a0,152(a5)
    80002d58:	bfe9                	j	80002d32 <argraw+0x30>
  panic("argraw");
    80002d5a:	00005517          	auipc	a0,0x5
    80002d5e:	6de50513          	addi	a0,a0,1758 # 80008438 <states.0+0x140>
    80002d62:	ffffd097          	auipc	ra,0xffffd
    80002d66:	7de080e7          	jalr	2014(ra) # 80000540 <panic>

0000000080002d6a <fetchaddr>:
{
    80002d6a:	1101                	addi	sp,sp,-32
    80002d6c:	ec06                	sd	ra,24(sp)
    80002d6e:	e822                	sd	s0,16(sp)
    80002d70:	e426                	sd	s1,8(sp)
    80002d72:	e04a                	sd	s2,0(sp)
    80002d74:	1000                	addi	s0,sp,32
    80002d76:	84aa                	mv	s1,a0
    80002d78:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d7a:	fffff097          	auipc	ra,0xfffff
    80002d7e:	d74080e7          	jalr	-652(ra) # 80001aee <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002d82:	653c                	ld	a5,72(a0)
    80002d84:	02f4f863          	bgeu	s1,a5,80002db4 <fetchaddr+0x4a>
    80002d88:	00848713          	addi	a4,s1,8
    80002d8c:	02e7e663          	bltu	a5,a4,80002db8 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d90:	46a1                	li	a3,8
    80002d92:	8626                	mv	a2,s1
    80002d94:	85ca                	mv	a1,s2
    80002d96:	6928                	ld	a0,80(a0)
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	99e080e7          	jalr	-1634(ra) # 80001736 <copyin>
    80002da0:	00a03533          	snez	a0,a0
    80002da4:	40a00533          	neg	a0,a0
}
    80002da8:	60e2                	ld	ra,24(sp)
    80002daa:	6442                	ld	s0,16(sp)
    80002dac:	64a2                	ld	s1,8(sp)
    80002dae:	6902                	ld	s2,0(sp)
    80002db0:	6105                	addi	sp,sp,32
    80002db2:	8082                	ret
    return -1;
    80002db4:	557d                	li	a0,-1
    80002db6:	bfcd                	j	80002da8 <fetchaddr+0x3e>
    80002db8:	557d                	li	a0,-1
    80002dba:	b7fd                	j	80002da8 <fetchaddr+0x3e>

0000000080002dbc <fetchstr>:
{
    80002dbc:	7179                	addi	sp,sp,-48
    80002dbe:	f406                	sd	ra,40(sp)
    80002dc0:	f022                	sd	s0,32(sp)
    80002dc2:	ec26                	sd	s1,24(sp)
    80002dc4:	e84a                	sd	s2,16(sp)
    80002dc6:	e44e                	sd	s3,8(sp)
    80002dc8:	1800                	addi	s0,sp,48
    80002dca:	892a                	mv	s2,a0
    80002dcc:	84ae                	mv	s1,a1
    80002dce:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	d1e080e7          	jalr	-738(ra) # 80001aee <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dd8:	86ce                	mv	a3,s3
    80002dda:	864a                	mv	a2,s2
    80002ddc:	85a6                	mv	a1,s1
    80002dde:	6928                	ld	a0,80(a0)
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	9e4080e7          	jalr	-1564(ra) # 800017c4 <copyinstr>
  if (err < 0)
    80002de8:	00054763          	bltz	a0,80002df6 <fetchstr+0x3a>
  return strlen(buf);
    80002dec:	8526                	mv	a0,s1
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	08e080e7          	jalr	142(ra) # 80000e7c <strlen>
}
    80002df6:	70a2                	ld	ra,40(sp)
    80002df8:	7402                	ld	s0,32(sp)
    80002dfa:	64e2                	ld	s1,24(sp)
    80002dfc:	6942                	ld	s2,16(sp)
    80002dfe:	69a2                	ld	s3,8(sp)
    80002e00:	6145                	addi	sp,sp,48
    80002e02:	8082                	ret

0000000080002e04 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	e426                	sd	s1,8(sp)
    80002e0c:	1000                	addi	s0,sp,32
    80002e0e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e10:	00000097          	auipc	ra,0x0
    80002e14:	ef2080e7          	jalr	-270(ra) # 80002d02 <argraw>
    80002e18:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e1a:	4501                	li	a0,0
    80002e1c:	60e2                	ld	ra,24(sp)
    80002e1e:	6442                	ld	s0,16(sp)
    80002e20:	64a2                	ld	s1,8(sp)
    80002e22:	6105                	addi	sp,sp,32
    80002e24:	8082                	ret

0000000080002e26 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002e26:	1101                	addi	sp,sp,-32
    80002e28:	ec06                	sd	ra,24(sp)
    80002e2a:	e822                	sd	s0,16(sp)
    80002e2c:	e426                	sd	s1,8(sp)
    80002e2e:	1000                	addi	s0,sp,32
    80002e30:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	ed0080e7          	jalr	-304(ra) # 80002d02 <argraw>
    80002e3a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e3c:	4501                	li	a0,0
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	64a2                	ld	s1,8(sp)
    80002e44:	6105                	addi	sp,sp,32
    80002e46:	8082                	ret

0000000080002e48 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	e426                	sd	s1,8(sp)
    80002e50:	e04a                	sd	s2,0(sp)
    80002e52:	1000                	addi	s0,sp,32
    80002e54:	84ae                	mv	s1,a1
    80002e56:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	eaa080e7          	jalr	-342(ra) # 80002d02 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e60:	864a                	mv	a2,s2
    80002e62:	85a6                	mv	a1,s1
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	f58080e7          	jalr	-168(ra) # 80002dbc <fetchstr>
}
    80002e6c:	60e2                	ld	ra,24(sp)
    80002e6e:	6442                	ld	s0,16(sp)
    80002e70:	64a2                	ld	s1,8(sp)
    80002e72:	6902                	ld	s2,0(sp)
    80002e74:	6105                	addi	sp,sp,32
    80002e76:	8082                	ret

0000000080002e78 <syscall>:
    [SYS_mkdir] sys_mkdir,
    [SYS_close] sys_close,
};

void syscall(void)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	e426                	sd	s1,8(sp)
    80002e80:	e04a                	sd	s2,0(sp)
    80002e82:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e84:	fffff097          	auipc	ra,0xfffff
    80002e88:	c6a080e7          	jalr	-918(ra) # 80001aee <myproc>
    80002e8c:	84aa                	mv	s1,a0
  // Assignment 4
  // when syscall is invoked and
  // its priority was not 2,
  // move to Q2 process

  if(p->priority != 2)
    80002e8e:	17852703          	lw	a4,376(a0)
    80002e92:	4789                	li	a5,2
    80002e94:	00f70563          	beq	a4,a5,80002e9e <syscall+0x26>
    p->change = 3;
    80002e98:	478d                	li	a5,3
    80002e9a:	16f52423          	sw	a5,360(a0)

  num = p->trapframe->a7;
    80002e9e:	0584b903          	ld	s2,88(s1)
    80002ea2:	0a893783          	ld	a5,168(s2)
    80002ea6:	0007869b          	sext.w	a3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002eaa:	37fd                	addiw	a5,a5,-1
    80002eac:	4751                	li	a4,20
    80002eae:	00f76f63          	bltu	a4,a5,80002ecc <syscall+0x54>
    80002eb2:	00369713          	slli	a4,a3,0x3
    80002eb6:	00005797          	auipc	a5,0x5
    80002eba:	5c278793          	addi	a5,a5,1474 # 80008478 <syscalls>
    80002ebe:	97ba                	add	a5,a5,a4
    80002ec0:	639c                	ld	a5,0(a5)
    80002ec2:	c789                	beqz	a5,80002ecc <syscall+0x54>
  {
    p->trapframe->a0 = syscalls[num]();
    80002ec4:	9782                	jalr	a5
    80002ec6:	06a93823          	sd	a0,112(s2)
    80002eca:	a839                	j	80002ee8 <syscall+0x70>
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002ecc:	15848613          	addi	a2,s1,344
    80002ed0:	5c8c                	lw	a1,56(s1)
    80002ed2:	00005517          	auipc	a0,0x5
    80002ed6:	56e50513          	addi	a0,a0,1390 # 80008440 <states.0+0x148>
    80002eda:	ffffd097          	auipc	ra,0xffffd
    80002ede:	6b0080e7          	jalr	1712(ra) # 8000058a <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ee2:	6cbc                	ld	a5,88(s1)
    80002ee4:	577d                	li	a4,-1
    80002ee6:	fbb8                	sd	a4,112(a5)
  }
}
    80002ee8:	60e2                	ld	ra,24(sp)
    80002eea:	6442                	ld	s0,16(sp)
    80002eec:	64a2                	ld	s1,8(sp)
    80002eee:	6902                	ld	s2,0(sp)
    80002ef0:	6105                	addi	sp,sp,32
    80002ef2:	8082                	ret

0000000080002ef4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ef4:	1101                	addi	sp,sp,-32
    80002ef6:	ec06                	sd	ra,24(sp)
    80002ef8:	e822                	sd	s0,16(sp)
    80002efa:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002efc:	fec40593          	addi	a1,s0,-20
    80002f00:	4501                	li	a0,0
    80002f02:	00000097          	auipc	ra,0x0
    80002f06:	f02080e7          	jalr	-254(ra) # 80002e04 <argint>
    return -1;
    80002f0a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f0c:	00054963          	bltz	a0,80002f1e <sys_exit+0x2a>
  exit(n);
    80002f10:	fec42503          	lw	a0,-20(s0)
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	466080e7          	jalr	1126(ra) # 8000237a <exit>
  return 0;  // not reached
    80002f1c:	4781                	li	a5,0
}
    80002f1e:	853e                	mv	a0,a5
    80002f20:	60e2                	ld	ra,24(sp)
    80002f22:	6442                	ld	s0,16(sp)
    80002f24:	6105                	addi	sp,sp,32
    80002f26:	8082                	ret

0000000080002f28 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f28:	1141                	addi	sp,sp,-16
    80002f2a:	e406                	sd	ra,8(sp)
    80002f2c:	e022                	sd	s0,0(sp)
    80002f2e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f30:	fffff097          	auipc	ra,0xfffff
    80002f34:	bbe080e7          	jalr	-1090(ra) # 80001aee <myproc>
}
    80002f38:	5d08                	lw	a0,56(a0)
    80002f3a:	60a2                	ld	ra,8(sp)
    80002f3c:	6402                	ld	s0,0(sp)
    80002f3e:	0141                	addi	sp,sp,16
    80002f40:	8082                	ret

0000000080002f42 <sys_fork>:

uint64
sys_fork(void)
{
    80002f42:	1141                	addi	sp,sp,-16
    80002f44:	e406                	sd	ra,8(sp)
    80002f46:	e022                	sd	s0,0(sp)
    80002f48:	0800                	addi	s0,sp,16
  return fork();
    80002f4a:	fffff097          	auipc	ra,0xfffff
    80002f4e:	fcc080e7          	jalr	-52(ra) # 80001f16 <fork>
}
    80002f52:	60a2                	ld	ra,8(sp)
    80002f54:	6402                	ld	s0,0(sp)
    80002f56:	0141                	addi	sp,sp,16
    80002f58:	8082                	ret

0000000080002f5a <sys_wait>:

uint64
sys_wait(void)
{
    80002f5a:	1101                	addi	sp,sp,-32
    80002f5c:	ec06                	sd	ra,24(sp)
    80002f5e:	e822                	sd	s0,16(sp)
    80002f60:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f62:	fe840593          	addi	a1,s0,-24
    80002f66:	4501                	li	a0,0
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	ebe080e7          	jalr	-322(ra) # 80002e26 <argaddr>
    80002f70:	87aa                	mv	a5,a0
    return -1;
    80002f72:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f74:	0007c863          	bltz	a5,80002f84 <sys_wait+0x2a>
  return wait(p);
    80002f78:	fe843503          	ld	a0,-24(s0)
    80002f7c:	fffff097          	auipc	ra,0xfffff
    80002f80:	636080e7          	jalr	1590(ra) # 800025b2 <wait>
}
    80002f84:	60e2                	ld	ra,24(sp)
    80002f86:	6442                	ld	s0,16(sp)
    80002f88:	6105                	addi	sp,sp,32
    80002f8a:	8082                	ret

0000000080002f8c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f8c:	7179                	addi	sp,sp,-48
    80002f8e:	f406                	sd	ra,40(sp)
    80002f90:	f022                	sd	s0,32(sp)
    80002f92:	ec26                	sd	s1,24(sp)
    80002f94:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f96:	fdc40593          	addi	a1,s0,-36
    80002f9a:	4501                	li	a0,0
    80002f9c:	00000097          	auipc	ra,0x0
    80002fa0:	e68080e7          	jalr	-408(ra) # 80002e04 <argint>
    return -1;
    80002fa4:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002fa6:	00054f63          	bltz	a0,80002fc4 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002faa:	fffff097          	auipc	ra,0xfffff
    80002fae:	b44080e7          	jalr	-1212(ra) # 80001aee <myproc>
    80002fb2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fb4:	fdc42503          	lw	a0,-36(s0)
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	eea080e7          	jalr	-278(ra) # 80001ea2 <growproc>
    80002fc0:	00054863          	bltz	a0,80002fd0 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002fc4:	8526                	mv	a0,s1
    80002fc6:	70a2                	ld	ra,40(sp)
    80002fc8:	7402                	ld	s0,32(sp)
    80002fca:	64e2                	ld	s1,24(sp)
    80002fcc:	6145                	addi	sp,sp,48
    80002fce:	8082                	ret
    return -1;
    80002fd0:	54fd                	li	s1,-1
    80002fd2:	bfcd                	j	80002fc4 <sys_sbrk+0x38>

0000000080002fd4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fd4:	7139                	addi	sp,sp,-64
    80002fd6:	fc06                	sd	ra,56(sp)
    80002fd8:	f822                	sd	s0,48(sp)
    80002fda:	f426                	sd	s1,40(sp)
    80002fdc:	f04a                	sd	s2,32(sp)
    80002fde:	ec4e                	sd	s3,24(sp)
    80002fe0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fe2:	fcc40593          	addi	a1,s0,-52
    80002fe6:	4501                	li	a0,0
    80002fe8:	00000097          	auipc	ra,0x0
    80002fec:	e1c080e7          	jalr	-484(ra) # 80002e04 <argint>
    return -1;
    80002ff0:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ff2:	06054563          	bltz	a0,8000305c <sys_sleep+0x88>
  acquire(&tickslock);
    80002ff6:	00015517          	auipc	a0,0x15
    80002ffa:	47250513          	addi	a0,a0,1138 # 80018468 <tickslock>
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	bfe080e7          	jalr	-1026(ra) # 80000bfc <acquire>
  ticks0 = ticks;
    80003006:	00006917          	auipc	s2,0x6
    8000300a:	01e92903          	lw	s2,30(s2) # 80009024 <ticks>
  while(ticks - ticks0 < n){
    8000300e:	fcc42783          	lw	a5,-52(s0)
    80003012:	cf85                	beqz	a5,8000304a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003014:	00015997          	auipc	s3,0x15
    80003018:	45498993          	addi	s3,s3,1108 # 80018468 <tickslock>
    8000301c:	00006497          	auipc	s1,0x6
    80003020:	00848493          	addi	s1,s1,8 # 80009024 <ticks>
    if(myproc()->killed){
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	aca080e7          	jalr	-1334(ra) # 80001aee <myproc>
    8000302c:	591c                	lw	a5,48(a0)
    8000302e:	ef9d                	bnez	a5,8000306c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003030:	85ce                	mv	a1,s3
    80003032:	8526                	mv	a0,s1
    80003034:	fffff097          	auipc	ra,0xfffff
    80003038:	4f4080e7          	jalr	1268(ra) # 80002528 <sleep>
  while(ticks - ticks0 < n){
    8000303c:	409c                	lw	a5,0(s1)
    8000303e:	412787bb          	subw	a5,a5,s2
    80003042:	fcc42703          	lw	a4,-52(s0)
    80003046:	fce7efe3          	bltu	a5,a4,80003024 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000304a:	00015517          	auipc	a0,0x15
    8000304e:	41e50513          	addi	a0,a0,1054 # 80018468 <tickslock>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	c5e080e7          	jalr	-930(ra) # 80000cb0 <release>
  return 0;
    8000305a:	4781                	li	a5,0
}
    8000305c:	853e                	mv	a0,a5
    8000305e:	70e2                	ld	ra,56(sp)
    80003060:	7442                	ld	s0,48(sp)
    80003062:	74a2                	ld	s1,40(sp)
    80003064:	7902                	ld	s2,32(sp)
    80003066:	69e2                	ld	s3,24(sp)
    80003068:	6121                	addi	sp,sp,64
    8000306a:	8082                	ret
      release(&tickslock);
    8000306c:	00015517          	auipc	a0,0x15
    80003070:	3fc50513          	addi	a0,a0,1020 # 80018468 <tickslock>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	c3c080e7          	jalr	-964(ra) # 80000cb0 <release>
      return -1;
    8000307c:	57fd                	li	a5,-1
    8000307e:	bff9                	j	8000305c <sys_sleep+0x88>

0000000080003080 <sys_kill>:

uint64
sys_kill(void)
{
    80003080:	1101                	addi	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003088:	fec40593          	addi	a1,s0,-20
    8000308c:	4501                	li	a0,0
    8000308e:	00000097          	auipc	ra,0x0
    80003092:	d76080e7          	jalr	-650(ra) # 80002e04 <argint>
    80003096:	87aa                	mv	a5,a0
    return -1;
    80003098:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000309a:	0007c863          	bltz	a5,800030aa <sys_kill+0x2a>
  return kill(pid);
    8000309e:	fec42503          	lw	a0,-20(s0)
    800030a2:	fffff097          	auipc	ra,0xfffff
    800030a6:	686080e7          	jalr	1670(ra) # 80002728 <kill>
}
    800030aa:	60e2                	ld	ra,24(sp)
    800030ac:	6442                	ld	s0,16(sp)
    800030ae:	6105                	addi	sp,sp,32
    800030b0:	8082                	ret

00000000800030b2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030b2:	1101                	addi	sp,sp,-32
    800030b4:	ec06                	sd	ra,24(sp)
    800030b6:	e822                	sd	s0,16(sp)
    800030b8:	e426                	sd	s1,8(sp)
    800030ba:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030bc:	00015517          	auipc	a0,0x15
    800030c0:	3ac50513          	addi	a0,a0,940 # 80018468 <tickslock>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	b38080e7          	jalr	-1224(ra) # 80000bfc <acquire>
  xticks = ticks;
    800030cc:	00006497          	auipc	s1,0x6
    800030d0:	f584a483          	lw	s1,-168(s1) # 80009024 <ticks>
  release(&tickslock);
    800030d4:	00015517          	auipc	a0,0x15
    800030d8:	39450513          	addi	a0,a0,916 # 80018468 <tickslock>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	bd4080e7          	jalr	-1068(ra) # 80000cb0 <release>
  return xticks;
}
    800030e4:	02049513          	slli	a0,s1,0x20
    800030e8:	9101                	srli	a0,a0,0x20
    800030ea:	60e2                	ld	ra,24(sp)
    800030ec:	6442                	ld	s0,16(sp)
    800030ee:	64a2                	ld	s1,8(sp)
    800030f0:	6105                	addi	sp,sp,32
    800030f2:	8082                	ret

00000000800030f4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030f4:	7179                	addi	sp,sp,-48
    800030f6:	f406                	sd	ra,40(sp)
    800030f8:	f022                	sd	s0,32(sp)
    800030fa:	ec26                	sd	s1,24(sp)
    800030fc:	e84a                	sd	s2,16(sp)
    800030fe:	e44e                	sd	s3,8(sp)
    80003100:	e052                	sd	s4,0(sp)
    80003102:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003104:	00005597          	auipc	a1,0x5
    80003108:	42458593          	addi	a1,a1,1060 # 80008528 <syscalls+0xb0>
    8000310c:	00015517          	auipc	a0,0x15
    80003110:	37450513          	addi	a0,a0,884 # 80018480 <bcache>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	a58080e7          	jalr	-1448(ra) # 80000b6c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000311c:	0001d797          	auipc	a5,0x1d
    80003120:	36478793          	addi	a5,a5,868 # 80020480 <bcache+0x8000>
    80003124:	0001d717          	auipc	a4,0x1d
    80003128:	5c470713          	addi	a4,a4,1476 # 800206e8 <bcache+0x8268>
    8000312c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003130:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003134:	00015497          	auipc	s1,0x15
    80003138:	36448493          	addi	s1,s1,868 # 80018498 <bcache+0x18>
    b->next = bcache.head.next;
    8000313c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000313e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003140:	00005a17          	auipc	s4,0x5
    80003144:	3f0a0a13          	addi	s4,s4,1008 # 80008530 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003148:	2b893783          	ld	a5,696(s2)
    8000314c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000314e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003152:	85d2                	mv	a1,s4
    80003154:	01048513          	addi	a0,s1,16
    80003158:	00001097          	auipc	ra,0x1
    8000315c:	4b2080e7          	jalr	1202(ra) # 8000460a <initsleeplock>
    bcache.head.next->prev = b;
    80003160:	2b893783          	ld	a5,696(s2)
    80003164:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003166:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000316a:	45848493          	addi	s1,s1,1112
    8000316e:	fd349de3          	bne	s1,s3,80003148 <binit+0x54>
  }
}
    80003172:	70a2                	ld	ra,40(sp)
    80003174:	7402                	ld	s0,32(sp)
    80003176:	64e2                	ld	s1,24(sp)
    80003178:	6942                	ld	s2,16(sp)
    8000317a:	69a2                	ld	s3,8(sp)
    8000317c:	6a02                	ld	s4,0(sp)
    8000317e:	6145                	addi	sp,sp,48
    80003180:	8082                	ret

0000000080003182 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003182:	7179                	addi	sp,sp,-48
    80003184:	f406                	sd	ra,40(sp)
    80003186:	f022                	sd	s0,32(sp)
    80003188:	ec26                	sd	s1,24(sp)
    8000318a:	e84a                	sd	s2,16(sp)
    8000318c:	e44e                	sd	s3,8(sp)
    8000318e:	1800                	addi	s0,sp,48
    80003190:	892a                	mv	s2,a0
    80003192:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003194:	00015517          	auipc	a0,0x15
    80003198:	2ec50513          	addi	a0,a0,748 # 80018480 <bcache>
    8000319c:	ffffe097          	auipc	ra,0xffffe
    800031a0:	a60080e7          	jalr	-1440(ra) # 80000bfc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031a4:	0001d497          	auipc	s1,0x1d
    800031a8:	5944b483          	ld	s1,1428(s1) # 80020738 <bcache+0x82b8>
    800031ac:	0001d797          	auipc	a5,0x1d
    800031b0:	53c78793          	addi	a5,a5,1340 # 800206e8 <bcache+0x8268>
    800031b4:	02f48f63          	beq	s1,a5,800031f2 <bread+0x70>
    800031b8:	873e                	mv	a4,a5
    800031ba:	a021                	j	800031c2 <bread+0x40>
    800031bc:	68a4                	ld	s1,80(s1)
    800031be:	02e48a63          	beq	s1,a4,800031f2 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031c2:	449c                	lw	a5,8(s1)
    800031c4:	ff279ce3          	bne	a5,s2,800031bc <bread+0x3a>
    800031c8:	44dc                	lw	a5,12(s1)
    800031ca:	ff3799e3          	bne	a5,s3,800031bc <bread+0x3a>
      b->refcnt++;
    800031ce:	40bc                	lw	a5,64(s1)
    800031d0:	2785                	addiw	a5,a5,1
    800031d2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031d4:	00015517          	auipc	a0,0x15
    800031d8:	2ac50513          	addi	a0,a0,684 # 80018480 <bcache>
    800031dc:	ffffe097          	auipc	ra,0xffffe
    800031e0:	ad4080e7          	jalr	-1324(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    800031e4:	01048513          	addi	a0,s1,16
    800031e8:	00001097          	auipc	ra,0x1
    800031ec:	45c080e7          	jalr	1116(ra) # 80004644 <acquiresleep>
      return b;
    800031f0:	a8b9                	j	8000324e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031f2:	0001d497          	auipc	s1,0x1d
    800031f6:	53e4b483          	ld	s1,1342(s1) # 80020730 <bcache+0x82b0>
    800031fa:	0001d797          	auipc	a5,0x1d
    800031fe:	4ee78793          	addi	a5,a5,1262 # 800206e8 <bcache+0x8268>
    80003202:	00f48863          	beq	s1,a5,80003212 <bread+0x90>
    80003206:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003208:	40bc                	lw	a5,64(s1)
    8000320a:	cf81                	beqz	a5,80003222 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000320c:	64a4                	ld	s1,72(s1)
    8000320e:	fee49de3          	bne	s1,a4,80003208 <bread+0x86>
  panic("bget: no buffers");
    80003212:	00005517          	auipc	a0,0x5
    80003216:	32650513          	addi	a0,a0,806 # 80008538 <syscalls+0xc0>
    8000321a:	ffffd097          	auipc	ra,0xffffd
    8000321e:	326080e7          	jalr	806(ra) # 80000540 <panic>
      b->dev = dev;
    80003222:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003226:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000322a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000322e:	4785                	li	a5,1
    80003230:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003232:	00015517          	auipc	a0,0x15
    80003236:	24e50513          	addi	a0,a0,590 # 80018480 <bcache>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	a76080e7          	jalr	-1418(ra) # 80000cb0 <release>
      acquiresleep(&b->lock);
    80003242:	01048513          	addi	a0,s1,16
    80003246:	00001097          	auipc	ra,0x1
    8000324a:	3fe080e7          	jalr	1022(ra) # 80004644 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000324e:	409c                	lw	a5,0(s1)
    80003250:	cb89                	beqz	a5,80003262 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003252:	8526                	mv	a0,s1
    80003254:	70a2                	ld	ra,40(sp)
    80003256:	7402                	ld	s0,32(sp)
    80003258:	64e2                	ld	s1,24(sp)
    8000325a:	6942                	ld	s2,16(sp)
    8000325c:	69a2                	ld	s3,8(sp)
    8000325e:	6145                	addi	sp,sp,48
    80003260:	8082                	ret
    virtio_disk_rw(b, 0);
    80003262:	4581                	li	a1,0
    80003264:	8526                	mv	a0,s1
    80003266:	00003097          	auipc	ra,0x3
    8000326a:	f26080e7          	jalr	-218(ra) # 8000618c <virtio_disk_rw>
    b->valid = 1;
    8000326e:	4785                	li	a5,1
    80003270:	c09c                	sw	a5,0(s1)
  return b;
    80003272:	b7c5                	j	80003252 <bread+0xd0>

0000000080003274 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003274:	1101                	addi	sp,sp,-32
    80003276:	ec06                	sd	ra,24(sp)
    80003278:	e822                	sd	s0,16(sp)
    8000327a:	e426                	sd	s1,8(sp)
    8000327c:	1000                	addi	s0,sp,32
    8000327e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003280:	0541                	addi	a0,a0,16
    80003282:	00001097          	auipc	ra,0x1
    80003286:	45c080e7          	jalr	1116(ra) # 800046de <holdingsleep>
    8000328a:	cd01                	beqz	a0,800032a2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000328c:	4585                	li	a1,1
    8000328e:	8526                	mv	a0,s1
    80003290:	00003097          	auipc	ra,0x3
    80003294:	efc080e7          	jalr	-260(ra) # 8000618c <virtio_disk_rw>
}
    80003298:	60e2                	ld	ra,24(sp)
    8000329a:	6442                	ld	s0,16(sp)
    8000329c:	64a2                	ld	s1,8(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret
    panic("bwrite");
    800032a2:	00005517          	auipc	a0,0x5
    800032a6:	2ae50513          	addi	a0,a0,686 # 80008550 <syscalls+0xd8>
    800032aa:	ffffd097          	auipc	ra,0xffffd
    800032ae:	296080e7          	jalr	662(ra) # 80000540 <panic>

00000000800032b2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032b2:	1101                	addi	sp,sp,-32
    800032b4:	ec06                	sd	ra,24(sp)
    800032b6:	e822                	sd	s0,16(sp)
    800032b8:	e426                	sd	s1,8(sp)
    800032ba:	e04a                	sd	s2,0(sp)
    800032bc:	1000                	addi	s0,sp,32
    800032be:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032c0:	01050913          	addi	s2,a0,16
    800032c4:	854a                	mv	a0,s2
    800032c6:	00001097          	auipc	ra,0x1
    800032ca:	418080e7          	jalr	1048(ra) # 800046de <holdingsleep>
    800032ce:	c92d                	beqz	a0,80003340 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032d0:	854a                	mv	a0,s2
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	3c8080e7          	jalr	968(ra) # 8000469a <releasesleep>

  acquire(&bcache.lock);
    800032da:	00015517          	auipc	a0,0x15
    800032de:	1a650513          	addi	a0,a0,422 # 80018480 <bcache>
    800032e2:	ffffe097          	auipc	ra,0xffffe
    800032e6:	91a080e7          	jalr	-1766(ra) # 80000bfc <acquire>
  b->refcnt--;
    800032ea:	40bc                	lw	a5,64(s1)
    800032ec:	37fd                	addiw	a5,a5,-1
    800032ee:	0007871b          	sext.w	a4,a5
    800032f2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032f4:	eb05                	bnez	a4,80003324 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032f6:	68bc                	ld	a5,80(s1)
    800032f8:	64b8                	ld	a4,72(s1)
    800032fa:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032fc:	64bc                	ld	a5,72(s1)
    800032fe:	68b8                	ld	a4,80(s1)
    80003300:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003302:	0001d797          	auipc	a5,0x1d
    80003306:	17e78793          	addi	a5,a5,382 # 80020480 <bcache+0x8000>
    8000330a:	2b87b703          	ld	a4,696(a5)
    8000330e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003310:	0001d717          	auipc	a4,0x1d
    80003314:	3d870713          	addi	a4,a4,984 # 800206e8 <bcache+0x8268>
    80003318:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000331a:	2b87b703          	ld	a4,696(a5)
    8000331e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003320:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003324:	00015517          	auipc	a0,0x15
    80003328:	15c50513          	addi	a0,a0,348 # 80018480 <bcache>
    8000332c:	ffffe097          	auipc	ra,0xffffe
    80003330:	984080e7          	jalr	-1660(ra) # 80000cb0 <release>
}
    80003334:	60e2                	ld	ra,24(sp)
    80003336:	6442                	ld	s0,16(sp)
    80003338:	64a2                	ld	s1,8(sp)
    8000333a:	6902                	ld	s2,0(sp)
    8000333c:	6105                	addi	sp,sp,32
    8000333e:	8082                	ret
    panic("brelse");
    80003340:	00005517          	auipc	a0,0x5
    80003344:	21850513          	addi	a0,a0,536 # 80008558 <syscalls+0xe0>
    80003348:	ffffd097          	auipc	ra,0xffffd
    8000334c:	1f8080e7          	jalr	504(ra) # 80000540 <panic>

0000000080003350 <bpin>:

void
bpin(struct buf *b) {
    80003350:	1101                	addi	sp,sp,-32
    80003352:	ec06                	sd	ra,24(sp)
    80003354:	e822                	sd	s0,16(sp)
    80003356:	e426                	sd	s1,8(sp)
    80003358:	1000                	addi	s0,sp,32
    8000335a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000335c:	00015517          	auipc	a0,0x15
    80003360:	12450513          	addi	a0,a0,292 # 80018480 <bcache>
    80003364:	ffffe097          	auipc	ra,0xffffe
    80003368:	898080e7          	jalr	-1896(ra) # 80000bfc <acquire>
  b->refcnt++;
    8000336c:	40bc                	lw	a5,64(s1)
    8000336e:	2785                	addiw	a5,a5,1
    80003370:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003372:	00015517          	auipc	a0,0x15
    80003376:	10e50513          	addi	a0,a0,270 # 80018480 <bcache>
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	936080e7          	jalr	-1738(ra) # 80000cb0 <release>
}
    80003382:	60e2                	ld	ra,24(sp)
    80003384:	6442                	ld	s0,16(sp)
    80003386:	64a2                	ld	s1,8(sp)
    80003388:	6105                	addi	sp,sp,32
    8000338a:	8082                	ret

000000008000338c <bunpin>:

void
bunpin(struct buf *b) {
    8000338c:	1101                	addi	sp,sp,-32
    8000338e:	ec06                	sd	ra,24(sp)
    80003390:	e822                	sd	s0,16(sp)
    80003392:	e426                	sd	s1,8(sp)
    80003394:	1000                	addi	s0,sp,32
    80003396:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003398:	00015517          	auipc	a0,0x15
    8000339c:	0e850513          	addi	a0,a0,232 # 80018480 <bcache>
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	85c080e7          	jalr	-1956(ra) # 80000bfc <acquire>
  b->refcnt--;
    800033a8:	40bc                	lw	a5,64(s1)
    800033aa:	37fd                	addiw	a5,a5,-1
    800033ac:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033ae:	00015517          	auipc	a0,0x15
    800033b2:	0d250513          	addi	a0,a0,210 # 80018480 <bcache>
    800033b6:	ffffe097          	auipc	ra,0xffffe
    800033ba:	8fa080e7          	jalr	-1798(ra) # 80000cb0 <release>
}
    800033be:	60e2                	ld	ra,24(sp)
    800033c0:	6442                	ld	s0,16(sp)
    800033c2:	64a2                	ld	s1,8(sp)
    800033c4:	6105                	addi	sp,sp,32
    800033c6:	8082                	ret

00000000800033c8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033c8:	1101                	addi	sp,sp,-32
    800033ca:	ec06                	sd	ra,24(sp)
    800033cc:	e822                	sd	s0,16(sp)
    800033ce:	e426                	sd	s1,8(sp)
    800033d0:	e04a                	sd	s2,0(sp)
    800033d2:	1000                	addi	s0,sp,32
    800033d4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033d6:	00d5d59b          	srliw	a1,a1,0xd
    800033da:	0001d797          	auipc	a5,0x1d
    800033de:	7827a783          	lw	a5,1922(a5) # 80020b5c <sb+0x1c>
    800033e2:	9dbd                	addw	a1,a1,a5
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	d9e080e7          	jalr	-610(ra) # 80003182 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033ec:	0074f713          	andi	a4,s1,7
    800033f0:	4785                	li	a5,1
    800033f2:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033f6:	14ce                	slli	s1,s1,0x33
    800033f8:	90d9                	srli	s1,s1,0x36
    800033fa:	00950733          	add	a4,a0,s1
    800033fe:	05874703          	lbu	a4,88(a4)
    80003402:	00e7f6b3          	and	a3,a5,a4
    80003406:	c69d                	beqz	a3,80003434 <bfree+0x6c>
    80003408:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000340a:	94aa                	add	s1,s1,a0
    8000340c:	fff7c793          	not	a5,a5
    80003410:	8ff9                	and	a5,a5,a4
    80003412:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003416:	00001097          	auipc	ra,0x1
    8000341a:	106080e7          	jalr	262(ra) # 8000451c <log_write>
  brelse(bp);
    8000341e:	854a                	mv	a0,s2
    80003420:	00000097          	auipc	ra,0x0
    80003424:	e92080e7          	jalr	-366(ra) # 800032b2 <brelse>
}
    80003428:	60e2                	ld	ra,24(sp)
    8000342a:	6442                	ld	s0,16(sp)
    8000342c:	64a2                	ld	s1,8(sp)
    8000342e:	6902                	ld	s2,0(sp)
    80003430:	6105                	addi	sp,sp,32
    80003432:	8082                	ret
    panic("freeing free block");
    80003434:	00005517          	auipc	a0,0x5
    80003438:	12c50513          	addi	a0,a0,300 # 80008560 <syscalls+0xe8>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	104080e7          	jalr	260(ra) # 80000540 <panic>

0000000080003444 <balloc>:
{
    80003444:	711d                	addi	sp,sp,-96
    80003446:	ec86                	sd	ra,88(sp)
    80003448:	e8a2                	sd	s0,80(sp)
    8000344a:	e4a6                	sd	s1,72(sp)
    8000344c:	e0ca                	sd	s2,64(sp)
    8000344e:	fc4e                	sd	s3,56(sp)
    80003450:	f852                	sd	s4,48(sp)
    80003452:	f456                	sd	s5,40(sp)
    80003454:	f05a                	sd	s6,32(sp)
    80003456:	ec5e                	sd	s7,24(sp)
    80003458:	e862                	sd	s8,16(sp)
    8000345a:	e466                	sd	s9,8(sp)
    8000345c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000345e:	0001d797          	auipc	a5,0x1d
    80003462:	6e67a783          	lw	a5,1766(a5) # 80020b44 <sb+0x4>
    80003466:	cbd1                	beqz	a5,800034fa <balloc+0xb6>
    80003468:	8baa                	mv	s7,a0
    8000346a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000346c:	0001db17          	auipc	s6,0x1d
    80003470:	6d4b0b13          	addi	s6,s6,1748 # 80020b40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003474:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003476:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003478:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000347a:	6c89                	lui	s9,0x2
    8000347c:	a831                	j	80003498 <balloc+0x54>
    brelse(bp);
    8000347e:	854a                	mv	a0,s2
    80003480:	00000097          	auipc	ra,0x0
    80003484:	e32080e7          	jalr	-462(ra) # 800032b2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003488:	015c87bb          	addw	a5,s9,s5
    8000348c:	00078a9b          	sext.w	s5,a5
    80003490:	004b2703          	lw	a4,4(s6)
    80003494:	06eaf363          	bgeu	s5,a4,800034fa <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003498:	41fad79b          	sraiw	a5,s5,0x1f
    8000349c:	0137d79b          	srliw	a5,a5,0x13
    800034a0:	015787bb          	addw	a5,a5,s5
    800034a4:	40d7d79b          	sraiw	a5,a5,0xd
    800034a8:	01cb2583          	lw	a1,28(s6)
    800034ac:	9dbd                	addw	a1,a1,a5
    800034ae:	855e                	mv	a0,s7
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	cd2080e7          	jalr	-814(ra) # 80003182 <bread>
    800034b8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ba:	004b2503          	lw	a0,4(s6)
    800034be:	000a849b          	sext.w	s1,s5
    800034c2:	8662                	mv	a2,s8
    800034c4:	faa4fde3          	bgeu	s1,a0,8000347e <balloc+0x3a>
      m = 1 << (bi % 8);
    800034c8:	41f6579b          	sraiw	a5,a2,0x1f
    800034cc:	01d7d69b          	srliw	a3,a5,0x1d
    800034d0:	00c6873b          	addw	a4,a3,a2
    800034d4:	00777793          	andi	a5,a4,7
    800034d8:	9f95                	subw	a5,a5,a3
    800034da:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034de:	4037571b          	sraiw	a4,a4,0x3
    800034e2:	00e906b3          	add	a3,s2,a4
    800034e6:	0586c683          	lbu	a3,88(a3)
    800034ea:	00d7f5b3          	and	a1,a5,a3
    800034ee:	cd91                	beqz	a1,8000350a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034f0:	2605                	addiw	a2,a2,1
    800034f2:	2485                	addiw	s1,s1,1
    800034f4:	fd4618e3          	bne	a2,s4,800034c4 <balloc+0x80>
    800034f8:	b759                	j	8000347e <balloc+0x3a>
  panic("balloc: out of blocks");
    800034fa:	00005517          	auipc	a0,0x5
    800034fe:	07e50513          	addi	a0,a0,126 # 80008578 <syscalls+0x100>
    80003502:	ffffd097          	auipc	ra,0xffffd
    80003506:	03e080e7          	jalr	62(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000350a:	974a                	add	a4,a4,s2
    8000350c:	8fd5                	or	a5,a5,a3
    8000350e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003512:	854a                	mv	a0,s2
    80003514:	00001097          	auipc	ra,0x1
    80003518:	008080e7          	jalr	8(ra) # 8000451c <log_write>
        brelse(bp);
    8000351c:	854a                	mv	a0,s2
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	d94080e7          	jalr	-620(ra) # 800032b2 <brelse>
  bp = bread(dev, bno);
    80003526:	85a6                	mv	a1,s1
    80003528:	855e                	mv	a0,s7
    8000352a:	00000097          	auipc	ra,0x0
    8000352e:	c58080e7          	jalr	-936(ra) # 80003182 <bread>
    80003532:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003534:	40000613          	li	a2,1024
    80003538:	4581                	li	a1,0
    8000353a:	05850513          	addi	a0,a0,88
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	7ba080e7          	jalr	1978(ra) # 80000cf8 <memset>
  log_write(bp);
    80003546:	854a                	mv	a0,s2
    80003548:	00001097          	auipc	ra,0x1
    8000354c:	fd4080e7          	jalr	-44(ra) # 8000451c <log_write>
  brelse(bp);
    80003550:	854a                	mv	a0,s2
    80003552:	00000097          	auipc	ra,0x0
    80003556:	d60080e7          	jalr	-672(ra) # 800032b2 <brelse>
}
    8000355a:	8526                	mv	a0,s1
    8000355c:	60e6                	ld	ra,88(sp)
    8000355e:	6446                	ld	s0,80(sp)
    80003560:	64a6                	ld	s1,72(sp)
    80003562:	6906                	ld	s2,64(sp)
    80003564:	79e2                	ld	s3,56(sp)
    80003566:	7a42                	ld	s4,48(sp)
    80003568:	7aa2                	ld	s5,40(sp)
    8000356a:	7b02                	ld	s6,32(sp)
    8000356c:	6be2                	ld	s7,24(sp)
    8000356e:	6c42                	ld	s8,16(sp)
    80003570:	6ca2                	ld	s9,8(sp)
    80003572:	6125                	addi	sp,sp,96
    80003574:	8082                	ret

0000000080003576 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003576:	7179                	addi	sp,sp,-48
    80003578:	f406                	sd	ra,40(sp)
    8000357a:	f022                	sd	s0,32(sp)
    8000357c:	ec26                	sd	s1,24(sp)
    8000357e:	e84a                	sd	s2,16(sp)
    80003580:	e44e                	sd	s3,8(sp)
    80003582:	e052                	sd	s4,0(sp)
    80003584:	1800                	addi	s0,sp,48
    80003586:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003588:	47ad                	li	a5,11
    8000358a:	04b7fe63          	bgeu	a5,a1,800035e6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000358e:	ff45849b          	addiw	s1,a1,-12
    80003592:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003596:	0ff00793          	li	a5,255
    8000359a:	0ae7e463          	bltu	a5,a4,80003642 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000359e:	08052583          	lw	a1,128(a0)
    800035a2:	c5b5                	beqz	a1,8000360e <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035a4:	00092503          	lw	a0,0(s2)
    800035a8:	00000097          	auipc	ra,0x0
    800035ac:	bda080e7          	jalr	-1062(ra) # 80003182 <bread>
    800035b0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035b2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035b6:	02049713          	slli	a4,s1,0x20
    800035ba:	01e75593          	srli	a1,a4,0x1e
    800035be:	00b784b3          	add	s1,a5,a1
    800035c2:	0004a983          	lw	s3,0(s1)
    800035c6:	04098e63          	beqz	s3,80003622 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035ca:	8552                	mv	a0,s4
    800035cc:	00000097          	auipc	ra,0x0
    800035d0:	ce6080e7          	jalr	-794(ra) # 800032b2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035d4:	854e                	mv	a0,s3
    800035d6:	70a2                	ld	ra,40(sp)
    800035d8:	7402                	ld	s0,32(sp)
    800035da:	64e2                	ld	s1,24(sp)
    800035dc:	6942                	ld	s2,16(sp)
    800035de:	69a2                	ld	s3,8(sp)
    800035e0:	6a02                	ld	s4,0(sp)
    800035e2:	6145                	addi	sp,sp,48
    800035e4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035e6:	02059793          	slli	a5,a1,0x20
    800035ea:	01e7d593          	srli	a1,a5,0x1e
    800035ee:	00b504b3          	add	s1,a0,a1
    800035f2:	0504a983          	lw	s3,80(s1)
    800035f6:	fc099fe3          	bnez	s3,800035d4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035fa:	4108                	lw	a0,0(a0)
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	e48080e7          	jalr	-440(ra) # 80003444 <balloc>
    80003604:	0005099b          	sext.w	s3,a0
    80003608:	0534a823          	sw	s3,80(s1)
    8000360c:	b7e1                	j	800035d4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000360e:	4108                	lw	a0,0(a0)
    80003610:	00000097          	auipc	ra,0x0
    80003614:	e34080e7          	jalr	-460(ra) # 80003444 <balloc>
    80003618:	0005059b          	sext.w	a1,a0
    8000361c:	08b92023          	sw	a1,128(s2)
    80003620:	b751                	j	800035a4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003622:	00092503          	lw	a0,0(s2)
    80003626:	00000097          	auipc	ra,0x0
    8000362a:	e1e080e7          	jalr	-482(ra) # 80003444 <balloc>
    8000362e:	0005099b          	sext.w	s3,a0
    80003632:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003636:	8552                	mv	a0,s4
    80003638:	00001097          	auipc	ra,0x1
    8000363c:	ee4080e7          	jalr	-284(ra) # 8000451c <log_write>
    80003640:	b769                	j	800035ca <bmap+0x54>
  panic("bmap: out of range");
    80003642:	00005517          	auipc	a0,0x5
    80003646:	f4e50513          	addi	a0,a0,-178 # 80008590 <syscalls+0x118>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	ef6080e7          	jalr	-266(ra) # 80000540 <panic>

0000000080003652 <iget>:
{
    80003652:	7179                	addi	sp,sp,-48
    80003654:	f406                	sd	ra,40(sp)
    80003656:	f022                	sd	s0,32(sp)
    80003658:	ec26                	sd	s1,24(sp)
    8000365a:	e84a                	sd	s2,16(sp)
    8000365c:	e44e                	sd	s3,8(sp)
    8000365e:	e052                	sd	s4,0(sp)
    80003660:	1800                	addi	s0,sp,48
    80003662:	89aa                	mv	s3,a0
    80003664:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003666:	0001d517          	auipc	a0,0x1d
    8000366a:	4fa50513          	addi	a0,a0,1274 # 80020b60 <icache>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	58e080e7          	jalr	1422(ra) # 80000bfc <acquire>
  empty = 0;
    80003676:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003678:	0001d497          	auipc	s1,0x1d
    8000367c:	50048493          	addi	s1,s1,1280 # 80020b78 <icache+0x18>
    80003680:	0001f697          	auipc	a3,0x1f
    80003684:	f8868693          	addi	a3,a3,-120 # 80022608 <log>
    80003688:	a039                	j	80003696 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000368a:	02090b63          	beqz	s2,800036c0 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000368e:	08848493          	addi	s1,s1,136
    80003692:	02d48a63          	beq	s1,a3,800036c6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003696:	449c                	lw	a5,8(s1)
    80003698:	fef059e3          	blez	a5,8000368a <iget+0x38>
    8000369c:	4098                	lw	a4,0(s1)
    8000369e:	ff3716e3          	bne	a4,s3,8000368a <iget+0x38>
    800036a2:	40d8                	lw	a4,4(s1)
    800036a4:	ff4713e3          	bne	a4,s4,8000368a <iget+0x38>
      ip->ref++;
    800036a8:	2785                	addiw	a5,a5,1
    800036aa:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036ac:	0001d517          	auipc	a0,0x1d
    800036b0:	4b450513          	addi	a0,a0,1204 # 80020b60 <icache>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	5fc080e7          	jalr	1532(ra) # 80000cb0 <release>
      return ip;
    800036bc:	8926                	mv	s2,s1
    800036be:	a03d                	j	800036ec <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c0:	f7f9                	bnez	a5,8000368e <iget+0x3c>
    800036c2:	8926                	mv	s2,s1
    800036c4:	b7e9                	j	8000368e <iget+0x3c>
  if(empty == 0)
    800036c6:	02090c63          	beqz	s2,800036fe <iget+0xac>
  ip->dev = dev;
    800036ca:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036ce:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036d2:	4785                	li	a5,1
    800036d4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036d8:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036dc:	0001d517          	auipc	a0,0x1d
    800036e0:	48450513          	addi	a0,a0,1156 # 80020b60 <icache>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	5cc080e7          	jalr	1484(ra) # 80000cb0 <release>
}
    800036ec:	854a                	mv	a0,s2
    800036ee:	70a2                	ld	ra,40(sp)
    800036f0:	7402                	ld	s0,32(sp)
    800036f2:	64e2                	ld	s1,24(sp)
    800036f4:	6942                	ld	s2,16(sp)
    800036f6:	69a2                	ld	s3,8(sp)
    800036f8:	6a02                	ld	s4,0(sp)
    800036fa:	6145                	addi	sp,sp,48
    800036fc:	8082                	ret
    panic("iget: no inodes");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	eaa50513          	addi	a0,a0,-342 # 800085a8 <syscalls+0x130>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e3a080e7          	jalr	-454(ra) # 80000540 <panic>

000000008000370e <fsinit>:
fsinit(int dev) {
    8000370e:	7179                	addi	sp,sp,-48
    80003710:	f406                	sd	ra,40(sp)
    80003712:	f022                	sd	s0,32(sp)
    80003714:	ec26                	sd	s1,24(sp)
    80003716:	e84a                	sd	s2,16(sp)
    80003718:	e44e                	sd	s3,8(sp)
    8000371a:	1800                	addi	s0,sp,48
    8000371c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000371e:	4585                	li	a1,1
    80003720:	00000097          	auipc	ra,0x0
    80003724:	a62080e7          	jalr	-1438(ra) # 80003182 <bread>
    80003728:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000372a:	0001d997          	auipc	s3,0x1d
    8000372e:	41698993          	addi	s3,s3,1046 # 80020b40 <sb>
    80003732:	02000613          	li	a2,32
    80003736:	05850593          	addi	a1,a0,88
    8000373a:	854e                	mv	a0,s3
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	618080e7          	jalr	1560(ra) # 80000d54 <memmove>
  brelse(bp);
    80003744:	8526                	mv	a0,s1
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	b6c080e7          	jalr	-1172(ra) # 800032b2 <brelse>
  if(sb.magic != FSMAGIC)
    8000374e:	0009a703          	lw	a4,0(s3)
    80003752:	102037b7          	lui	a5,0x10203
    80003756:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000375a:	02f71263          	bne	a4,a5,8000377e <fsinit+0x70>
  initlog(dev, &sb);
    8000375e:	0001d597          	auipc	a1,0x1d
    80003762:	3e258593          	addi	a1,a1,994 # 80020b40 <sb>
    80003766:	854a                	mv	a0,s2
    80003768:	00001097          	auipc	ra,0x1
    8000376c:	b3a080e7          	jalr	-1222(ra) # 800042a2 <initlog>
}
    80003770:	70a2                	ld	ra,40(sp)
    80003772:	7402                	ld	s0,32(sp)
    80003774:	64e2                	ld	s1,24(sp)
    80003776:	6942                	ld	s2,16(sp)
    80003778:	69a2                	ld	s3,8(sp)
    8000377a:	6145                	addi	sp,sp,48
    8000377c:	8082                	ret
    panic("invalid file system");
    8000377e:	00005517          	auipc	a0,0x5
    80003782:	e3a50513          	addi	a0,a0,-454 # 800085b8 <syscalls+0x140>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	dba080e7          	jalr	-582(ra) # 80000540 <panic>

000000008000378e <iinit>:
{
    8000378e:	7179                	addi	sp,sp,-48
    80003790:	f406                	sd	ra,40(sp)
    80003792:	f022                	sd	s0,32(sp)
    80003794:	ec26                	sd	s1,24(sp)
    80003796:	e84a                	sd	s2,16(sp)
    80003798:	e44e                	sd	s3,8(sp)
    8000379a:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000379c:	00005597          	auipc	a1,0x5
    800037a0:	e3458593          	addi	a1,a1,-460 # 800085d0 <syscalls+0x158>
    800037a4:	0001d517          	auipc	a0,0x1d
    800037a8:	3bc50513          	addi	a0,a0,956 # 80020b60 <icache>
    800037ac:	ffffd097          	auipc	ra,0xffffd
    800037b0:	3c0080e7          	jalr	960(ra) # 80000b6c <initlock>
  for(i = 0; i < NINODE; i++) {
    800037b4:	0001d497          	auipc	s1,0x1d
    800037b8:	3d448493          	addi	s1,s1,980 # 80020b88 <icache+0x28>
    800037bc:	0001f997          	auipc	s3,0x1f
    800037c0:	e5c98993          	addi	s3,s3,-420 # 80022618 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037c4:	00005917          	auipc	s2,0x5
    800037c8:	e1490913          	addi	s2,s2,-492 # 800085d8 <syscalls+0x160>
    800037cc:	85ca                	mv	a1,s2
    800037ce:	8526                	mv	a0,s1
    800037d0:	00001097          	auipc	ra,0x1
    800037d4:	e3a080e7          	jalr	-454(ra) # 8000460a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037d8:	08848493          	addi	s1,s1,136
    800037dc:	ff3498e3          	bne	s1,s3,800037cc <iinit+0x3e>
}
    800037e0:	70a2                	ld	ra,40(sp)
    800037e2:	7402                	ld	s0,32(sp)
    800037e4:	64e2                	ld	s1,24(sp)
    800037e6:	6942                	ld	s2,16(sp)
    800037e8:	69a2                	ld	s3,8(sp)
    800037ea:	6145                	addi	sp,sp,48
    800037ec:	8082                	ret

00000000800037ee <ialloc>:
{
    800037ee:	715d                	addi	sp,sp,-80
    800037f0:	e486                	sd	ra,72(sp)
    800037f2:	e0a2                	sd	s0,64(sp)
    800037f4:	fc26                	sd	s1,56(sp)
    800037f6:	f84a                	sd	s2,48(sp)
    800037f8:	f44e                	sd	s3,40(sp)
    800037fa:	f052                	sd	s4,32(sp)
    800037fc:	ec56                	sd	s5,24(sp)
    800037fe:	e85a                	sd	s6,16(sp)
    80003800:	e45e                	sd	s7,8(sp)
    80003802:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003804:	0001d717          	auipc	a4,0x1d
    80003808:	34872703          	lw	a4,840(a4) # 80020b4c <sb+0xc>
    8000380c:	4785                	li	a5,1
    8000380e:	04e7fa63          	bgeu	a5,a4,80003862 <ialloc+0x74>
    80003812:	8aaa                	mv	s5,a0
    80003814:	8bae                	mv	s7,a1
    80003816:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003818:	0001da17          	auipc	s4,0x1d
    8000381c:	328a0a13          	addi	s4,s4,808 # 80020b40 <sb>
    80003820:	00048b1b          	sext.w	s6,s1
    80003824:	0044d793          	srli	a5,s1,0x4
    80003828:	018a2583          	lw	a1,24(s4)
    8000382c:	9dbd                	addw	a1,a1,a5
    8000382e:	8556                	mv	a0,s5
    80003830:	00000097          	auipc	ra,0x0
    80003834:	952080e7          	jalr	-1710(ra) # 80003182 <bread>
    80003838:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000383a:	05850993          	addi	s3,a0,88
    8000383e:	00f4f793          	andi	a5,s1,15
    80003842:	079a                	slli	a5,a5,0x6
    80003844:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003846:	00099783          	lh	a5,0(s3)
    8000384a:	c785                	beqz	a5,80003872 <ialloc+0x84>
    brelse(bp);
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	a66080e7          	jalr	-1434(ra) # 800032b2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003854:	0485                	addi	s1,s1,1
    80003856:	00ca2703          	lw	a4,12(s4)
    8000385a:	0004879b          	sext.w	a5,s1
    8000385e:	fce7e1e3          	bltu	a5,a4,80003820 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003862:	00005517          	auipc	a0,0x5
    80003866:	d7e50513          	addi	a0,a0,-642 # 800085e0 <syscalls+0x168>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	cd6080e7          	jalr	-810(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003872:	04000613          	li	a2,64
    80003876:	4581                	li	a1,0
    80003878:	854e                	mv	a0,s3
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	47e080e7          	jalr	1150(ra) # 80000cf8 <memset>
      dip->type = type;
    80003882:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003886:	854a                	mv	a0,s2
    80003888:	00001097          	auipc	ra,0x1
    8000388c:	c94080e7          	jalr	-876(ra) # 8000451c <log_write>
      brelse(bp);
    80003890:	854a                	mv	a0,s2
    80003892:	00000097          	auipc	ra,0x0
    80003896:	a20080e7          	jalr	-1504(ra) # 800032b2 <brelse>
      return iget(dev, inum);
    8000389a:	85da                	mv	a1,s6
    8000389c:	8556                	mv	a0,s5
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	db4080e7          	jalr	-588(ra) # 80003652 <iget>
}
    800038a6:	60a6                	ld	ra,72(sp)
    800038a8:	6406                	ld	s0,64(sp)
    800038aa:	74e2                	ld	s1,56(sp)
    800038ac:	7942                	ld	s2,48(sp)
    800038ae:	79a2                	ld	s3,40(sp)
    800038b0:	7a02                	ld	s4,32(sp)
    800038b2:	6ae2                	ld	s5,24(sp)
    800038b4:	6b42                	ld	s6,16(sp)
    800038b6:	6ba2                	ld	s7,8(sp)
    800038b8:	6161                	addi	sp,sp,80
    800038ba:	8082                	ret

00000000800038bc <iupdate>:
{
    800038bc:	1101                	addi	sp,sp,-32
    800038be:	ec06                	sd	ra,24(sp)
    800038c0:	e822                	sd	s0,16(sp)
    800038c2:	e426                	sd	s1,8(sp)
    800038c4:	e04a                	sd	s2,0(sp)
    800038c6:	1000                	addi	s0,sp,32
    800038c8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ca:	415c                	lw	a5,4(a0)
    800038cc:	0047d79b          	srliw	a5,a5,0x4
    800038d0:	0001d597          	auipc	a1,0x1d
    800038d4:	2885a583          	lw	a1,648(a1) # 80020b58 <sb+0x18>
    800038d8:	9dbd                	addw	a1,a1,a5
    800038da:	4108                	lw	a0,0(a0)
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	8a6080e7          	jalr	-1882(ra) # 80003182 <bread>
    800038e4:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e6:	05850793          	addi	a5,a0,88
    800038ea:	40c8                	lw	a0,4(s1)
    800038ec:	893d                	andi	a0,a0,15
    800038ee:	051a                	slli	a0,a0,0x6
    800038f0:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038f2:	04449703          	lh	a4,68(s1)
    800038f6:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038fa:	04649703          	lh	a4,70(s1)
    800038fe:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003902:	04849703          	lh	a4,72(s1)
    80003906:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000390a:	04a49703          	lh	a4,74(s1)
    8000390e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003912:	44f8                	lw	a4,76(s1)
    80003914:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003916:	03400613          	li	a2,52
    8000391a:	05048593          	addi	a1,s1,80
    8000391e:	0531                	addi	a0,a0,12
    80003920:	ffffd097          	auipc	ra,0xffffd
    80003924:	434080e7          	jalr	1076(ra) # 80000d54 <memmove>
  log_write(bp);
    80003928:	854a                	mv	a0,s2
    8000392a:	00001097          	auipc	ra,0x1
    8000392e:	bf2080e7          	jalr	-1038(ra) # 8000451c <log_write>
  brelse(bp);
    80003932:	854a                	mv	a0,s2
    80003934:	00000097          	auipc	ra,0x0
    80003938:	97e080e7          	jalr	-1666(ra) # 800032b2 <brelse>
}
    8000393c:	60e2                	ld	ra,24(sp)
    8000393e:	6442                	ld	s0,16(sp)
    80003940:	64a2                	ld	s1,8(sp)
    80003942:	6902                	ld	s2,0(sp)
    80003944:	6105                	addi	sp,sp,32
    80003946:	8082                	ret

0000000080003948 <idup>:
{
    80003948:	1101                	addi	sp,sp,-32
    8000394a:	ec06                	sd	ra,24(sp)
    8000394c:	e822                	sd	s0,16(sp)
    8000394e:	e426                	sd	s1,8(sp)
    80003950:	1000                	addi	s0,sp,32
    80003952:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003954:	0001d517          	auipc	a0,0x1d
    80003958:	20c50513          	addi	a0,a0,524 # 80020b60 <icache>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	2a0080e7          	jalr	672(ra) # 80000bfc <acquire>
  ip->ref++;
    80003964:	449c                	lw	a5,8(s1)
    80003966:	2785                	addiw	a5,a5,1
    80003968:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000396a:	0001d517          	auipc	a0,0x1d
    8000396e:	1f650513          	addi	a0,a0,502 # 80020b60 <icache>
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	33e080e7          	jalr	830(ra) # 80000cb0 <release>
}
    8000397a:	8526                	mv	a0,s1
    8000397c:	60e2                	ld	ra,24(sp)
    8000397e:	6442                	ld	s0,16(sp)
    80003980:	64a2                	ld	s1,8(sp)
    80003982:	6105                	addi	sp,sp,32
    80003984:	8082                	ret

0000000080003986 <ilock>:
{
    80003986:	1101                	addi	sp,sp,-32
    80003988:	ec06                	sd	ra,24(sp)
    8000398a:	e822                	sd	s0,16(sp)
    8000398c:	e426                	sd	s1,8(sp)
    8000398e:	e04a                	sd	s2,0(sp)
    80003990:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003992:	c115                	beqz	a0,800039b6 <ilock+0x30>
    80003994:	84aa                	mv	s1,a0
    80003996:	451c                	lw	a5,8(a0)
    80003998:	00f05f63          	blez	a5,800039b6 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000399c:	0541                	addi	a0,a0,16
    8000399e:	00001097          	auipc	ra,0x1
    800039a2:	ca6080e7          	jalr	-858(ra) # 80004644 <acquiresleep>
  if(ip->valid == 0){
    800039a6:	40bc                	lw	a5,64(s1)
    800039a8:	cf99                	beqz	a5,800039c6 <ilock+0x40>
}
    800039aa:	60e2                	ld	ra,24(sp)
    800039ac:	6442                	ld	s0,16(sp)
    800039ae:	64a2                	ld	s1,8(sp)
    800039b0:	6902                	ld	s2,0(sp)
    800039b2:	6105                	addi	sp,sp,32
    800039b4:	8082                	ret
    panic("ilock");
    800039b6:	00005517          	auipc	a0,0x5
    800039ba:	c4250513          	addi	a0,a0,-958 # 800085f8 <syscalls+0x180>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	b82080e7          	jalr	-1150(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039c6:	40dc                	lw	a5,4(s1)
    800039c8:	0047d79b          	srliw	a5,a5,0x4
    800039cc:	0001d597          	auipc	a1,0x1d
    800039d0:	18c5a583          	lw	a1,396(a1) # 80020b58 <sb+0x18>
    800039d4:	9dbd                	addw	a1,a1,a5
    800039d6:	4088                	lw	a0,0(s1)
    800039d8:	fffff097          	auipc	ra,0xfffff
    800039dc:	7aa080e7          	jalr	1962(ra) # 80003182 <bread>
    800039e0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039e2:	05850593          	addi	a1,a0,88
    800039e6:	40dc                	lw	a5,4(s1)
    800039e8:	8bbd                	andi	a5,a5,15
    800039ea:	079a                	slli	a5,a5,0x6
    800039ec:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039ee:	00059783          	lh	a5,0(a1)
    800039f2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039f6:	00259783          	lh	a5,2(a1)
    800039fa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039fe:	00459783          	lh	a5,4(a1)
    80003a02:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a06:	00659783          	lh	a5,6(a1)
    80003a0a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a0e:	459c                	lw	a5,8(a1)
    80003a10:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a12:	03400613          	li	a2,52
    80003a16:	05b1                	addi	a1,a1,12
    80003a18:	05048513          	addi	a0,s1,80
    80003a1c:	ffffd097          	auipc	ra,0xffffd
    80003a20:	338080e7          	jalr	824(ra) # 80000d54 <memmove>
    brelse(bp);
    80003a24:	854a                	mv	a0,s2
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	88c080e7          	jalr	-1908(ra) # 800032b2 <brelse>
    ip->valid = 1;
    80003a2e:	4785                	li	a5,1
    80003a30:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a32:	04449783          	lh	a5,68(s1)
    80003a36:	fbb5                	bnez	a5,800039aa <ilock+0x24>
      panic("ilock: no type");
    80003a38:	00005517          	auipc	a0,0x5
    80003a3c:	bc850513          	addi	a0,a0,-1080 # 80008600 <syscalls+0x188>
    80003a40:	ffffd097          	auipc	ra,0xffffd
    80003a44:	b00080e7          	jalr	-1280(ra) # 80000540 <panic>

0000000080003a48 <iunlock>:
{
    80003a48:	1101                	addi	sp,sp,-32
    80003a4a:	ec06                	sd	ra,24(sp)
    80003a4c:	e822                	sd	s0,16(sp)
    80003a4e:	e426                	sd	s1,8(sp)
    80003a50:	e04a                	sd	s2,0(sp)
    80003a52:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a54:	c905                	beqz	a0,80003a84 <iunlock+0x3c>
    80003a56:	84aa                	mv	s1,a0
    80003a58:	01050913          	addi	s2,a0,16
    80003a5c:	854a                	mv	a0,s2
    80003a5e:	00001097          	auipc	ra,0x1
    80003a62:	c80080e7          	jalr	-896(ra) # 800046de <holdingsleep>
    80003a66:	cd19                	beqz	a0,80003a84 <iunlock+0x3c>
    80003a68:	449c                	lw	a5,8(s1)
    80003a6a:	00f05d63          	blez	a5,80003a84 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a6e:	854a                	mv	a0,s2
    80003a70:	00001097          	auipc	ra,0x1
    80003a74:	c2a080e7          	jalr	-982(ra) # 8000469a <releasesleep>
}
    80003a78:	60e2                	ld	ra,24(sp)
    80003a7a:	6442                	ld	s0,16(sp)
    80003a7c:	64a2                	ld	s1,8(sp)
    80003a7e:	6902                	ld	s2,0(sp)
    80003a80:	6105                	addi	sp,sp,32
    80003a82:	8082                	ret
    panic("iunlock");
    80003a84:	00005517          	auipc	a0,0x5
    80003a88:	b8c50513          	addi	a0,a0,-1140 # 80008610 <syscalls+0x198>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	ab4080e7          	jalr	-1356(ra) # 80000540 <panic>

0000000080003a94 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a94:	7179                	addi	sp,sp,-48
    80003a96:	f406                	sd	ra,40(sp)
    80003a98:	f022                	sd	s0,32(sp)
    80003a9a:	ec26                	sd	s1,24(sp)
    80003a9c:	e84a                	sd	s2,16(sp)
    80003a9e:	e44e                	sd	s3,8(sp)
    80003aa0:	e052                	sd	s4,0(sp)
    80003aa2:	1800                	addi	s0,sp,48
    80003aa4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003aa6:	05050493          	addi	s1,a0,80
    80003aaa:	08050913          	addi	s2,a0,128
    80003aae:	a021                	j	80003ab6 <itrunc+0x22>
    80003ab0:	0491                	addi	s1,s1,4
    80003ab2:	01248d63          	beq	s1,s2,80003acc <itrunc+0x38>
    if(ip->addrs[i]){
    80003ab6:	408c                	lw	a1,0(s1)
    80003ab8:	dde5                	beqz	a1,80003ab0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aba:	0009a503          	lw	a0,0(s3)
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	90a080e7          	jalr	-1782(ra) # 800033c8 <bfree>
      ip->addrs[i] = 0;
    80003ac6:	0004a023          	sw	zero,0(s1)
    80003aca:	b7dd                	j	80003ab0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003acc:	0809a583          	lw	a1,128(s3)
    80003ad0:	e185                	bnez	a1,80003af0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ad2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ad6:	854e                	mv	a0,s3
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	de4080e7          	jalr	-540(ra) # 800038bc <iupdate>
}
    80003ae0:	70a2                	ld	ra,40(sp)
    80003ae2:	7402                	ld	s0,32(sp)
    80003ae4:	64e2                	ld	s1,24(sp)
    80003ae6:	6942                	ld	s2,16(sp)
    80003ae8:	69a2                	ld	s3,8(sp)
    80003aea:	6a02                	ld	s4,0(sp)
    80003aec:	6145                	addi	sp,sp,48
    80003aee:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003af0:	0009a503          	lw	a0,0(s3)
    80003af4:	fffff097          	auipc	ra,0xfffff
    80003af8:	68e080e7          	jalr	1678(ra) # 80003182 <bread>
    80003afc:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003afe:	05850493          	addi	s1,a0,88
    80003b02:	45850913          	addi	s2,a0,1112
    80003b06:	a021                	j	80003b0e <itrunc+0x7a>
    80003b08:	0491                	addi	s1,s1,4
    80003b0a:	01248b63          	beq	s1,s2,80003b20 <itrunc+0x8c>
      if(a[j])
    80003b0e:	408c                	lw	a1,0(s1)
    80003b10:	dde5                	beqz	a1,80003b08 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b12:	0009a503          	lw	a0,0(s3)
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	8b2080e7          	jalr	-1870(ra) # 800033c8 <bfree>
    80003b1e:	b7ed                	j	80003b08 <itrunc+0x74>
    brelse(bp);
    80003b20:	8552                	mv	a0,s4
    80003b22:	fffff097          	auipc	ra,0xfffff
    80003b26:	790080e7          	jalr	1936(ra) # 800032b2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b2a:	0809a583          	lw	a1,128(s3)
    80003b2e:	0009a503          	lw	a0,0(s3)
    80003b32:	00000097          	auipc	ra,0x0
    80003b36:	896080e7          	jalr	-1898(ra) # 800033c8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b3a:	0809a023          	sw	zero,128(s3)
    80003b3e:	bf51                	j	80003ad2 <itrunc+0x3e>

0000000080003b40 <iput>:
{
    80003b40:	1101                	addi	sp,sp,-32
    80003b42:	ec06                	sd	ra,24(sp)
    80003b44:	e822                	sd	s0,16(sp)
    80003b46:	e426                	sd	s1,8(sp)
    80003b48:	e04a                	sd	s2,0(sp)
    80003b4a:	1000                	addi	s0,sp,32
    80003b4c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b4e:	0001d517          	auipc	a0,0x1d
    80003b52:	01250513          	addi	a0,a0,18 # 80020b60 <icache>
    80003b56:	ffffd097          	auipc	ra,0xffffd
    80003b5a:	0a6080e7          	jalr	166(ra) # 80000bfc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b5e:	4498                	lw	a4,8(s1)
    80003b60:	4785                	li	a5,1
    80003b62:	02f70363          	beq	a4,a5,80003b88 <iput+0x48>
  ip->ref--;
    80003b66:	449c                	lw	a5,8(s1)
    80003b68:	37fd                	addiw	a5,a5,-1
    80003b6a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b6c:	0001d517          	auipc	a0,0x1d
    80003b70:	ff450513          	addi	a0,a0,-12 # 80020b60 <icache>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	13c080e7          	jalr	316(ra) # 80000cb0 <release>
}
    80003b7c:	60e2                	ld	ra,24(sp)
    80003b7e:	6442                	ld	s0,16(sp)
    80003b80:	64a2                	ld	s1,8(sp)
    80003b82:	6902                	ld	s2,0(sp)
    80003b84:	6105                	addi	sp,sp,32
    80003b86:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b88:	40bc                	lw	a5,64(s1)
    80003b8a:	dff1                	beqz	a5,80003b66 <iput+0x26>
    80003b8c:	04a49783          	lh	a5,74(s1)
    80003b90:	fbf9                	bnez	a5,80003b66 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b92:	01048913          	addi	s2,s1,16
    80003b96:	854a                	mv	a0,s2
    80003b98:	00001097          	auipc	ra,0x1
    80003b9c:	aac080e7          	jalr	-1364(ra) # 80004644 <acquiresleep>
    release(&icache.lock);
    80003ba0:	0001d517          	auipc	a0,0x1d
    80003ba4:	fc050513          	addi	a0,a0,-64 # 80020b60 <icache>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	108080e7          	jalr	264(ra) # 80000cb0 <release>
    itrunc(ip);
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	00000097          	auipc	ra,0x0
    80003bb6:	ee2080e7          	jalr	-286(ra) # 80003a94 <itrunc>
    ip->type = 0;
    80003bba:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bbe:	8526                	mv	a0,s1
    80003bc0:	00000097          	auipc	ra,0x0
    80003bc4:	cfc080e7          	jalr	-772(ra) # 800038bc <iupdate>
    ip->valid = 0;
    80003bc8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bcc:	854a                	mv	a0,s2
    80003bce:	00001097          	auipc	ra,0x1
    80003bd2:	acc080e7          	jalr	-1332(ra) # 8000469a <releasesleep>
    acquire(&icache.lock);
    80003bd6:	0001d517          	auipc	a0,0x1d
    80003bda:	f8a50513          	addi	a0,a0,-118 # 80020b60 <icache>
    80003bde:	ffffd097          	auipc	ra,0xffffd
    80003be2:	01e080e7          	jalr	30(ra) # 80000bfc <acquire>
    80003be6:	b741                	j	80003b66 <iput+0x26>

0000000080003be8 <iunlockput>:
{
    80003be8:	1101                	addi	sp,sp,-32
    80003bea:	ec06                	sd	ra,24(sp)
    80003bec:	e822                	sd	s0,16(sp)
    80003bee:	e426                	sd	s1,8(sp)
    80003bf0:	1000                	addi	s0,sp,32
    80003bf2:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	e54080e7          	jalr	-428(ra) # 80003a48 <iunlock>
  iput(ip);
    80003bfc:	8526                	mv	a0,s1
    80003bfe:	00000097          	auipc	ra,0x0
    80003c02:	f42080e7          	jalr	-190(ra) # 80003b40 <iput>
}
    80003c06:	60e2                	ld	ra,24(sp)
    80003c08:	6442                	ld	s0,16(sp)
    80003c0a:	64a2                	ld	s1,8(sp)
    80003c0c:	6105                	addi	sp,sp,32
    80003c0e:	8082                	ret

0000000080003c10 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c10:	1141                	addi	sp,sp,-16
    80003c12:	e422                	sd	s0,8(sp)
    80003c14:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c16:	411c                	lw	a5,0(a0)
    80003c18:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c1a:	415c                	lw	a5,4(a0)
    80003c1c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c1e:	04451783          	lh	a5,68(a0)
    80003c22:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c26:	04a51783          	lh	a5,74(a0)
    80003c2a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c2e:	04c56783          	lwu	a5,76(a0)
    80003c32:	e99c                	sd	a5,16(a1)
}
    80003c34:	6422                	ld	s0,8(sp)
    80003c36:	0141                	addi	sp,sp,16
    80003c38:	8082                	ret

0000000080003c3a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c3a:	457c                	lw	a5,76(a0)
    80003c3c:	0ed7e863          	bltu	a5,a3,80003d2c <readi+0xf2>
{
    80003c40:	7159                	addi	sp,sp,-112
    80003c42:	f486                	sd	ra,104(sp)
    80003c44:	f0a2                	sd	s0,96(sp)
    80003c46:	eca6                	sd	s1,88(sp)
    80003c48:	e8ca                	sd	s2,80(sp)
    80003c4a:	e4ce                	sd	s3,72(sp)
    80003c4c:	e0d2                	sd	s4,64(sp)
    80003c4e:	fc56                	sd	s5,56(sp)
    80003c50:	f85a                	sd	s6,48(sp)
    80003c52:	f45e                	sd	s7,40(sp)
    80003c54:	f062                	sd	s8,32(sp)
    80003c56:	ec66                	sd	s9,24(sp)
    80003c58:	e86a                	sd	s10,16(sp)
    80003c5a:	e46e                	sd	s11,8(sp)
    80003c5c:	1880                	addi	s0,sp,112
    80003c5e:	8baa                	mv	s7,a0
    80003c60:	8c2e                	mv	s8,a1
    80003c62:	8ab2                	mv	s5,a2
    80003c64:	84b6                	mv	s1,a3
    80003c66:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c68:	9f35                	addw	a4,a4,a3
    return 0;
    80003c6a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c6c:	08d76f63          	bltu	a4,a3,80003d0a <readi+0xd0>
  if(off + n > ip->size)
    80003c70:	00e7f463          	bgeu	a5,a4,80003c78 <readi+0x3e>
    n = ip->size - off;
    80003c74:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c78:	0a0b0863          	beqz	s6,80003d28 <readi+0xee>
    80003c7c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c7e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c82:	5cfd                	li	s9,-1
    80003c84:	a82d                	j	80003cbe <readi+0x84>
    80003c86:	020a1d93          	slli	s11,s4,0x20
    80003c8a:	020ddd93          	srli	s11,s11,0x20
    80003c8e:	05890793          	addi	a5,s2,88
    80003c92:	86ee                	mv	a3,s11
    80003c94:	963e                	add	a2,a2,a5
    80003c96:	85d6                	mv	a1,s5
    80003c98:	8562                	mv	a0,s8
    80003c9a:	fffff097          	auipc	ra,0xfffff
    80003c9e:	b04080e7          	jalr	-1276(ra) # 8000279e <either_copyout>
    80003ca2:	05950d63          	beq	a0,s9,80003cfc <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003ca6:	854a                	mv	a0,s2
    80003ca8:	fffff097          	auipc	ra,0xfffff
    80003cac:	60a080e7          	jalr	1546(ra) # 800032b2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb0:	013a09bb          	addw	s3,s4,s3
    80003cb4:	009a04bb          	addw	s1,s4,s1
    80003cb8:	9aee                	add	s5,s5,s11
    80003cba:	0569f663          	bgeu	s3,s6,80003d06 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cbe:	000ba903          	lw	s2,0(s7)
    80003cc2:	00a4d59b          	srliw	a1,s1,0xa
    80003cc6:	855e                	mv	a0,s7
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	8ae080e7          	jalr	-1874(ra) # 80003576 <bmap>
    80003cd0:	0005059b          	sext.w	a1,a0
    80003cd4:	854a                	mv	a0,s2
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	4ac080e7          	jalr	1196(ra) # 80003182 <bread>
    80003cde:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce0:	3ff4f613          	andi	a2,s1,1023
    80003ce4:	40cd07bb          	subw	a5,s10,a2
    80003ce8:	413b073b          	subw	a4,s6,s3
    80003cec:	8a3e                	mv	s4,a5
    80003cee:	2781                	sext.w	a5,a5
    80003cf0:	0007069b          	sext.w	a3,a4
    80003cf4:	f8f6f9e3          	bgeu	a3,a5,80003c86 <readi+0x4c>
    80003cf8:	8a3a                	mv	s4,a4
    80003cfa:	b771                	j	80003c86 <readi+0x4c>
      brelse(bp);
    80003cfc:	854a                	mv	a0,s2
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	5b4080e7          	jalr	1460(ra) # 800032b2 <brelse>
  }
  return tot;
    80003d06:	0009851b          	sext.w	a0,s3
}
    80003d0a:	70a6                	ld	ra,104(sp)
    80003d0c:	7406                	ld	s0,96(sp)
    80003d0e:	64e6                	ld	s1,88(sp)
    80003d10:	6946                	ld	s2,80(sp)
    80003d12:	69a6                	ld	s3,72(sp)
    80003d14:	6a06                	ld	s4,64(sp)
    80003d16:	7ae2                	ld	s5,56(sp)
    80003d18:	7b42                	ld	s6,48(sp)
    80003d1a:	7ba2                	ld	s7,40(sp)
    80003d1c:	7c02                	ld	s8,32(sp)
    80003d1e:	6ce2                	ld	s9,24(sp)
    80003d20:	6d42                	ld	s10,16(sp)
    80003d22:	6da2                	ld	s11,8(sp)
    80003d24:	6165                	addi	sp,sp,112
    80003d26:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d28:	89da                	mv	s3,s6
    80003d2a:	bff1                	j	80003d06 <readi+0xcc>
    return 0;
    80003d2c:	4501                	li	a0,0
}
    80003d2e:	8082                	ret

0000000080003d30 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d30:	457c                	lw	a5,76(a0)
    80003d32:	10d7e663          	bltu	a5,a3,80003e3e <writei+0x10e>
{
    80003d36:	7159                	addi	sp,sp,-112
    80003d38:	f486                	sd	ra,104(sp)
    80003d3a:	f0a2                	sd	s0,96(sp)
    80003d3c:	eca6                	sd	s1,88(sp)
    80003d3e:	e8ca                	sd	s2,80(sp)
    80003d40:	e4ce                	sd	s3,72(sp)
    80003d42:	e0d2                	sd	s4,64(sp)
    80003d44:	fc56                	sd	s5,56(sp)
    80003d46:	f85a                	sd	s6,48(sp)
    80003d48:	f45e                	sd	s7,40(sp)
    80003d4a:	f062                	sd	s8,32(sp)
    80003d4c:	ec66                	sd	s9,24(sp)
    80003d4e:	e86a                	sd	s10,16(sp)
    80003d50:	e46e                	sd	s11,8(sp)
    80003d52:	1880                	addi	s0,sp,112
    80003d54:	8baa                	mv	s7,a0
    80003d56:	8c2e                	mv	s8,a1
    80003d58:	8ab2                	mv	s5,a2
    80003d5a:	8936                	mv	s2,a3
    80003d5c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d5e:	00e687bb          	addw	a5,a3,a4
    80003d62:	0ed7e063          	bltu	a5,a3,80003e42 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d66:	00043737          	lui	a4,0x43
    80003d6a:	0cf76e63          	bltu	a4,a5,80003e46 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d6e:	0a0b0763          	beqz	s6,80003e1c <writei+0xec>
    80003d72:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d74:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d78:	5cfd                	li	s9,-1
    80003d7a:	a091                	j	80003dbe <writei+0x8e>
    80003d7c:	02099d93          	slli	s11,s3,0x20
    80003d80:	020ddd93          	srli	s11,s11,0x20
    80003d84:	05848793          	addi	a5,s1,88
    80003d88:	86ee                	mv	a3,s11
    80003d8a:	8656                	mv	a2,s5
    80003d8c:	85e2                	mv	a1,s8
    80003d8e:	953e                	add	a0,a0,a5
    80003d90:	fffff097          	auipc	ra,0xfffff
    80003d94:	a64080e7          	jalr	-1436(ra) # 800027f4 <either_copyin>
    80003d98:	07950263          	beq	a0,s9,80003dfc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d9c:	8526                	mv	a0,s1
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	77e080e7          	jalr	1918(ra) # 8000451c <log_write>
    brelse(bp);
    80003da6:	8526                	mv	a0,s1
    80003da8:	fffff097          	auipc	ra,0xfffff
    80003dac:	50a080e7          	jalr	1290(ra) # 800032b2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db0:	01498a3b          	addw	s4,s3,s4
    80003db4:	0129893b          	addw	s2,s3,s2
    80003db8:	9aee                	add	s5,s5,s11
    80003dba:	056a7663          	bgeu	s4,s6,80003e06 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dbe:	000ba483          	lw	s1,0(s7)
    80003dc2:	00a9559b          	srliw	a1,s2,0xa
    80003dc6:	855e                	mv	a0,s7
    80003dc8:	fffff097          	auipc	ra,0xfffff
    80003dcc:	7ae080e7          	jalr	1966(ra) # 80003576 <bmap>
    80003dd0:	0005059b          	sext.w	a1,a0
    80003dd4:	8526                	mv	a0,s1
    80003dd6:	fffff097          	auipc	ra,0xfffff
    80003dda:	3ac080e7          	jalr	940(ra) # 80003182 <bread>
    80003dde:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003de0:	3ff97513          	andi	a0,s2,1023
    80003de4:	40ad07bb          	subw	a5,s10,a0
    80003de8:	414b073b          	subw	a4,s6,s4
    80003dec:	89be                	mv	s3,a5
    80003dee:	2781                	sext.w	a5,a5
    80003df0:	0007069b          	sext.w	a3,a4
    80003df4:	f8f6f4e3          	bgeu	a3,a5,80003d7c <writei+0x4c>
    80003df8:	89ba                	mv	s3,a4
    80003dfa:	b749                	j	80003d7c <writei+0x4c>
      brelse(bp);
    80003dfc:	8526                	mv	a0,s1
    80003dfe:	fffff097          	auipc	ra,0xfffff
    80003e02:	4b4080e7          	jalr	1204(ra) # 800032b2 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003e06:	04cba783          	lw	a5,76(s7)
    80003e0a:	0127f463          	bgeu	a5,s2,80003e12 <writei+0xe2>
      ip->size = off;
    80003e0e:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e12:	855e                	mv	a0,s7
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	aa8080e7          	jalr	-1368(ra) # 800038bc <iupdate>
  }

  return n;
    80003e1c:	000b051b          	sext.w	a0,s6
}
    80003e20:	70a6                	ld	ra,104(sp)
    80003e22:	7406                	ld	s0,96(sp)
    80003e24:	64e6                	ld	s1,88(sp)
    80003e26:	6946                	ld	s2,80(sp)
    80003e28:	69a6                	ld	s3,72(sp)
    80003e2a:	6a06                	ld	s4,64(sp)
    80003e2c:	7ae2                	ld	s5,56(sp)
    80003e2e:	7b42                	ld	s6,48(sp)
    80003e30:	7ba2                	ld	s7,40(sp)
    80003e32:	7c02                	ld	s8,32(sp)
    80003e34:	6ce2                	ld	s9,24(sp)
    80003e36:	6d42                	ld	s10,16(sp)
    80003e38:	6da2                	ld	s11,8(sp)
    80003e3a:	6165                	addi	sp,sp,112
    80003e3c:	8082                	ret
    return -1;
    80003e3e:	557d                	li	a0,-1
}
    80003e40:	8082                	ret
    return -1;
    80003e42:	557d                	li	a0,-1
    80003e44:	bff1                	j	80003e20 <writei+0xf0>
    return -1;
    80003e46:	557d                	li	a0,-1
    80003e48:	bfe1                	j	80003e20 <writei+0xf0>

0000000080003e4a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e4a:	1141                	addi	sp,sp,-16
    80003e4c:	e406                	sd	ra,8(sp)
    80003e4e:	e022                	sd	s0,0(sp)
    80003e50:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e52:	4639                	li	a2,14
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	f7c080e7          	jalr	-132(ra) # 80000dd0 <strncmp>
}
    80003e5c:	60a2                	ld	ra,8(sp)
    80003e5e:	6402                	ld	s0,0(sp)
    80003e60:	0141                	addi	sp,sp,16
    80003e62:	8082                	ret

0000000080003e64 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e64:	7139                	addi	sp,sp,-64
    80003e66:	fc06                	sd	ra,56(sp)
    80003e68:	f822                	sd	s0,48(sp)
    80003e6a:	f426                	sd	s1,40(sp)
    80003e6c:	f04a                	sd	s2,32(sp)
    80003e6e:	ec4e                	sd	s3,24(sp)
    80003e70:	e852                	sd	s4,16(sp)
    80003e72:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e74:	04451703          	lh	a4,68(a0)
    80003e78:	4785                	li	a5,1
    80003e7a:	00f71a63          	bne	a4,a5,80003e8e <dirlookup+0x2a>
    80003e7e:	892a                	mv	s2,a0
    80003e80:	89ae                	mv	s3,a1
    80003e82:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e84:	457c                	lw	a5,76(a0)
    80003e86:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e88:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8a:	e79d                	bnez	a5,80003eb8 <dirlookup+0x54>
    80003e8c:	a8a5                	j	80003f04 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e8e:	00004517          	auipc	a0,0x4
    80003e92:	78a50513          	addi	a0,a0,1930 # 80008618 <syscalls+0x1a0>
    80003e96:	ffffc097          	auipc	ra,0xffffc
    80003e9a:	6aa080e7          	jalr	1706(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003e9e:	00004517          	auipc	a0,0x4
    80003ea2:	79250513          	addi	a0,a0,1938 # 80008630 <syscalls+0x1b8>
    80003ea6:	ffffc097          	auipc	ra,0xffffc
    80003eaa:	69a080e7          	jalr	1690(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eae:	24c1                	addiw	s1,s1,16
    80003eb0:	04c92783          	lw	a5,76(s2)
    80003eb4:	04f4f763          	bgeu	s1,a5,80003f02 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb8:	4741                	li	a4,16
    80003eba:	86a6                	mv	a3,s1
    80003ebc:	fc040613          	addi	a2,s0,-64
    80003ec0:	4581                	li	a1,0
    80003ec2:	854a                	mv	a0,s2
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	d76080e7          	jalr	-650(ra) # 80003c3a <readi>
    80003ecc:	47c1                	li	a5,16
    80003ece:	fcf518e3          	bne	a0,a5,80003e9e <dirlookup+0x3a>
    if(de.inum == 0)
    80003ed2:	fc045783          	lhu	a5,-64(s0)
    80003ed6:	dfe1                	beqz	a5,80003eae <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ed8:	fc240593          	addi	a1,s0,-62
    80003edc:	854e                	mv	a0,s3
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	f6c080e7          	jalr	-148(ra) # 80003e4a <namecmp>
    80003ee6:	f561                	bnez	a0,80003eae <dirlookup+0x4a>
      if(poff)
    80003ee8:	000a0463          	beqz	s4,80003ef0 <dirlookup+0x8c>
        *poff = off;
    80003eec:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ef0:	fc045583          	lhu	a1,-64(s0)
    80003ef4:	00092503          	lw	a0,0(s2)
    80003ef8:	fffff097          	auipc	ra,0xfffff
    80003efc:	75a080e7          	jalr	1882(ra) # 80003652 <iget>
    80003f00:	a011                	j	80003f04 <dirlookup+0xa0>
  return 0;
    80003f02:	4501                	li	a0,0
}
    80003f04:	70e2                	ld	ra,56(sp)
    80003f06:	7442                	ld	s0,48(sp)
    80003f08:	74a2                	ld	s1,40(sp)
    80003f0a:	7902                	ld	s2,32(sp)
    80003f0c:	69e2                	ld	s3,24(sp)
    80003f0e:	6a42                	ld	s4,16(sp)
    80003f10:	6121                	addi	sp,sp,64
    80003f12:	8082                	ret

0000000080003f14 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f14:	711d                	addi	sp,sp,-96
    80003f16:	ec86                	sd	ra,88(sp)
    80003f18:	e8a2                	sd	s0,80(sp)
    80003f1a:	e4a6                	sd	s1,72(sp)
    80003f1c:	e0ca                	sd	s2,64(sp)
    80003f1e:	fc4e                	sd	s3,56(sp)
    80003f20:	f852                	sd	s4,48(sp)
    80003f22:	f456                	sd	s5,40(sp)
    80003f24:	f05a                	sd	s6,32(sp)
    80003f26:	ec5e                	sd	s7,24(sp)
    80003f28:	e862                	sd	s8,16(sp)
    80003f2a:	e466                	sd	s9,8(sp)
    80003f2c:	1080                	addi	s0,sp,96
    80003f2e:	84aa                	mv	s1,a0
    80003f30:	8aae                	mv	s5,a1
    80003f32:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f34:	00054703          	lbu	a4,0(a0)
    80003f38:	02f00793          	li	a5,47
    80003f3c:	02f70363          	beq	a4,a5,80003f62 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f40:	ffffe097          	auipc	ra,0xffffe
    80003f44:	bae080e7          	jalr	-1106(ra) # 80001aee <myproc>
    80003f48:	15053503          	ld	a0,336(a0)
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	9fc080e7          	jalr	-1540(ra) # 80003948 <idup>
    80003f54:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f56:	02f00913          	li	s2,47
  len = path - s;
    80003f5a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f5c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f5e:	4b85                	li	s7,1
    80003f60:	a865                	j	80004018 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f62:	4585                	li	a1,1
    80003f64:	4505                	li	a0,1
    80003f66:	fffff097          	auipc	ra,0xfffff
    80003f6a:	6ec080e7          	jalr	1772(ra) # 80003652 <iget>
    80003f6e:	89aa                	mv	s3,a0
    80003f70:	b7dd                	j	80003f56 <namex+0x42>
      iunlockput(ip);
    80003f72:	854e                	mv	a0,s3
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	c74080e7          	jalr	-908(ra) # 80003be8 <iunlockput>
      return 0;
    80003f7c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f7e:	854e                	mv	a0,s3
    80003f80:	60e6                	ld	ra,88(sp)
    80003f82:	6446                	ld	s0,80(sp)
    80003f84:	64a6                	ld	s1,72(sp)
    80003f86:	6906                	ld	s2,64(sp)
    80003f88:	79e2                	ld	s3,56(sp)
    80003f8a:	7a42                	ld	s4,48(sp)
    80003f8c:	7aa2                	ld	s5,40(sp)
    80003f8e:	7b02                	ld	s6,32(sp)
    80003f90:	6be2                	ld	s7,24(sp)
    80003f92:	6c42                	ld	s8,16(sp)
    80003f94:	6ca2                	ld	s9,8(sp)
    80003f96:	6125                	addi	sp,sp,96
    80003f98:	8082                	ret
      iunlock(ip);
    80003f9a:	854e                	mv	a0,s3
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	aac080e7          	jalr	-1364(ra) # 80003a48 <iunlock>
      return ip;
    80003fa4:	bfe9                	j	80003f7e <namex+0x6a>
      iunlockput(ip);
    80003fa6:	854e                	mv	a0,s3
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	c40080e7          	jalr	-960(ra) # 80003be8 <iunlockput>
      return 0;
    80003fb0:	89e6                	mv	s3,s9
    80003fb2:	b7f1                	j	80003f7e <namex+0x6a>
  len = path - s;
    80003fb4:	40b48633          	sub	a2,s1,a1
    80003fb8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003fbc:	099c5463          	bge	s8,s9,80004044 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fc0:	4639                	li	a2,14
    80003fc2:	8552                	mv	a0,s4
    80003fc4:	ffffd097          	auipc	ra,0xffffd
    80003fc8:	d90080e7          	jalr	-624(ra) # 80000d54 <memmove>
  while(*path == '/')
    80003fcc:	0004c783          	lbu	a5,0(s1)
    80003fd0:	01279763          	bne	a5,s2,80003fde <namex+0xca>
    path++;
    80003fd4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fd6:	0004c783          	lbu	a5,0(s1)
    80003fda:	ff278de3          	beq	a5,s2,80003fd4 <namex+0xc0>
    ilock(ip);
    80003fde:	854e                	mv	a0,s3
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	9a6080e7          	jalr	-1626(ra) # 80003986 <ilock>
    if(ip->type != T_DIR){
    80003fe8:	04499783          	lh	a5,68(s3)
    80003fec:	f97793e3          	bne	a5,s7,80003f72 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ff0:	000a8563          	beqz	s5,80003ffa <namex+0xe6>
    80003ff4:	0004c783          	lbu	a5,0(s1)
    80003ff8:	d3cd                	beqz	a5,80003f9a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ffa:	865a                	mv	a2,s6
    80003ffc:	85d2                	mv	a1,s4
    80003ffe:	854e                	mv	a0,s3
    80004000:	00000097          	auipc	ra,0x0
    80004004:	e64080e7          	jalr	-412(ra) # 80003e64 <dirlookup>
    80004008:	8caa                	mv	s9,a0
    8000400a:	dd51                	beqz	a0,80003fa6 <namex+0x92>
    iunlockput(ip);
    8000400c:	854e                	mv	a0,s3
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	bda080e7          	jalr	-1062(ra) # 80003be8 <iunlockput>
    ip = next;
    80004016:	89e6                	mv	s3,s9
  while(*path == '/')
    80004018:	0004c783          	lbu	a5,0(s1)
    8000401c:	05279763          	bne	a5,s2,8000406a <namex+0x156>
    path++;
    80004020:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004022:	0004c783          	lbu	a5,0(s1)
    80004026:	ff278de3          	beq	a5,s2,80004020 <namex+0x10c>
  if(*path == 0)
    8000402a:	c79d                	beqz	a5,80004058 <namex+0x144>
    path++;
    8000402c:	85a6                	mv	a1,s1
  len = path - s;
    8000402e:	8cda                	mv	s9,s6
    80004030:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004032:	01278963          	beq	a5,s2,80004044 <namex+0x130>
    80004036:	dfbd                	beqz	a5,80003fb4 <namex+0xa0>
    path++;
    80004038:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000403a:	0004c783          	lbu	a5,0(s1)
    8000403e:	ff279ce3          	bne	a5,s2,80004036 <namex+0x122>
    80004042:	bf8d                	j	80003fb4 <namex+0xa0>
    memmove(name, s, len);
    80004044:	2601                	sext.w	a2,a2
    80004046:	8552                	mv	a0,s4
    80004048:	ffffd097          	auipc	ra,0xffffd
    8000404c:	d0c080e7          	jalr	-756(ra) # 80000d54 <memmove>
    name[len] = 0;
    80004050:	9cd2                	add	s9,s9,s4
    80004052:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004056:	bf9d                	j	80003fcc <namex+0xb8>
  if(nameiparent){
    80004058:	f20a83e3          	beqz	s5,80003f7e <namex+0x6a>
    iput(ip);
    8000405c:	854e                	mv	a0,s3
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	ae2080e7          	jalr	-1310(ra) # 80003b40 <iput>
    return 0;
    80004066:	4981                	li	s3,0
    80004068:	bf19                	j	80003f7e <namex+0x6a>
  if(*path == 0)
    8000406a:	d7fd                	beqz	a5,80004058 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000406c:	0004c783          	lbu	a5,0(s1)
    80004070:	85a6                	mv	a1,s1
    80004072:	b7d1                	j	80004036 <namex+0x122>

0000000080004074 <dirlink>:
{
    80004074:	7139                	addi	sp,sp,-64
    80004076:	fc06                	sd	ra,56(sp)
    80004078:	f822                	sd	s0,48(sp)
    8000407a:	f426                	sd	s1,40(sp)
    8000407c:	f04a                	sd	s2,32(sp)
    8000407e:	ec4e                	sd	s3,24(sp)
    80004080:	e852                	sd	s4,16(sp)
    80004082:	0080                	addi	s0,sp,64
    80004084:	892a                	mv	s2,a0
    80004086:	8a2e                	mv	s4,a1
    80004088:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000408a:	4601                	li	a2,0
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	dd8080e7          	jalr	-552(ra) # 80003e64 <dirlookup>
    80004094:	e93d                	bnez	a0,8000410a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004096:	04c92483          	lw	s1,76(s2)
    8000409a:	c49d                	beqz	s1,800040c8 <dirlink+0x54>
    8000409c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000409e:	4741                	li	a4,16
    800040a0:	86a6                	mv	a3,s1
    800040a2:	fc040613          	addi	a2,s0,-64
    800040a6:	4581                	li	a1,0
    800040a8:	854a                	mv	a0,s2
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	b90080e7          	jalr	-1136(ra) # 80003c3a <readi>
    800040b2:	47c1                	li	a5,16
    800040b4:	06f51163          	bne	a0,a5,80004116 <dirlink+0xa2>
    if(de.inum == 0)
    800040b8:	fc045783          	lhu	a5,-64(s0)
    800040bc:	c791                	beqz	a5,800040c8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040be:	24c1                	addiw	s1,s1,16
    800040c0:	04c92783          	lw	a5,76(s2)
    800040c4:	fcf4ede3          	bltu	s1,a5,8000409e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040c8:	4639                	li	a2,14
    800040ca:	85d2                	mv	a1,s4
    800040cc:	fc240513          	addi	a0,s0,-62
    800040d0:	ffffd097          	auipc	ra,0xffffd
    800040d4:	d3c080e7          	jalr	-708(ra) # 80000e0c <strncpy>
  de.inum = inum;
    800040d8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040dc:	4741                	li	a4,16
    800040de:	86a6                	mv	a3,s1
    800040e0:	fc040613          	addi	a2,s0,-64
    800040e4:	4581                	li	a1,0
    800040e6:	854a                	mv	a0,s2
    800040e8:	00000097          	auipc	ra,0x0
    800040ec:	c48080e7          	jalr	-952(ra) # 80003d30 <writei>
    800040f0:	872a                	mv	a4,a0
    800040f2:	47c1                	li	a5,16
  return 0;
    800040f4:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f6:	02f71863          	bne	a4,a5,80004126 <dirlink+0xb2>
}
    800040fa:	70e2                	ld	ra,56(sp)
    800040fc:	7442                	ld	s0,48(sp)
    800040fe:	74a2                	ld	s1,40(sp)
    80004100:	7902                	ld	s2,32(sp)
    80004102:	69e2                	ld	s3,24(sp)
    80004104:	6a42                	ld	s4,16(sp)
    80004106:	6121                	addi	sp,sp,64
    80004108:	8082                	ret
    iput(ip);
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	a36080e7          	jalr	-1482(ra) # 80003b40 <iput>
    return -1;
    80004112:	557d                	li	a0,-1
    80004114:	b7dd                	j	800040fa <dirlink+0x86>
      panic("dirlink read");
    80004116:	00004517          	auipc	a0,0x4
    8000411a:	52a50513          	addi	a0,a0,1322 # 80008640 <syscalls+0x1c8>
    8000411e:	ffffc097          	auipc	ra,0xffffc
    80004122:	422080e7          	jalr	1058(ra) # 80000540 <panic>
    panic("dirlink");
    80004126:	00004517          	auipc	a0,0x4
    8000412a:	63a50513          	addi	a0,a0,1594 # 80008760 <syscalls+0x2e8>
    8000412e:	ffffc097          	auipc	ra,0xffffc
    80004132:	412080e7          	jalr	1042(ra) # 80000540 <panic>

0000000080004136 <namei>:

struct inode*
namei(char *path)
{
    80004136:	1101                	addi	sp,sp,-32
    80004138:	ec06                	sd	ra,24(sp)
    8000413a:	e822                	sd	s0,16(sp)
    8000413c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000413e:	fe040613          	addi	a2,s0,-32
    80004142:	4581                	li	a1,0
    80004144:	00000097          	auipc	ra,0x0
    80004148:	dd0080e7          	jalr	-560(ra) # 80003f14 <namex>
}
    8000414c:	60e2                	ld	ra,24(sp)
    8000414e:	6442                	ld	s0,16(sp)
    80004150:	6105                	addi	sp,sp,32
    80004152:	8082                	ret

0000000080004154 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004154:	1141                	addi	sp,sp,-16
    80004156:	e406                	sd	ra,8(sp)
    80004158:	e022                	sd	s0,0(sp)
    8000415a:	0800                	addi	s0,sp,16
    8000415c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000415e:	4585                	li	a1,1
    80004160:	00000097          	auipc	ra,0x0
    80004164:	db4080e7          	jalr	-588(ra) # 80003f14 <namex>
}
    80004168:	60a2                	ld	ra,8(sp)
    8000416a:	6402                	ld	s0,0(sp)
    8000416c:	0141                	addi	sp,sp,16
    8000416e:	8082                	ret

0000000080004170 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004170:	1101                	addi	sp,sp,-32
    80004172:	ec06                	sd	ra,24(sp)
    80004174:	e822                	sd	s0,16(sp)
    80004176:	e426                	sd	s1,8(sp)
    80004178:	e04a                	sd	s2,0(sp)
    8000417a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000417c:	0001e917          	auipc	s2,0x1e
    80004180:	48c90913          	addi	s2,s2,1164 # 80022608 <log>
    80004184:	01892583          	lw	a1,24(s2)
    80004188:	02892503          	lw	a0,40(s2)
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	ff6080e7          	jalr	-10(ra) # 80003182 <bread>
    80004194:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004196:	02c92683          	lw	a3,44(s2)
    8000419a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000419c:	02d05863          	blez	a3,800041cc <write_head+0x5c>
    800041a0:	0001e797          	auipc	a5,0x1e
    800041a4:	49878793          	addi	a5,a5,1176 # 80022638 <log+0x30>
    800041a8:	05c50713          	addi	a4,a0,92
    800041ac:	36fd                	addiw	a3,a3,-1
    800041ae:	02069613          	slli	a2,a3,0x20
    800041b2:	01e65693          	srli	a3,a2,0x1e
    800041b6:	0001e617          	auipc	a2,0x1e
    800041ba:	48660613          	addi	a2,a2,1158 # 8002263c <log+0x34>
    800041be:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041c0:	4390                	lw	a2,0(a5)
    800041c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041c4:	0791                	addi	a5,a5,4
    800041c6:	0711                	addi	a4,a4,4
    800041c8:	fed79ce3          	bne	a5,a3,800041c0 <write_head+0x50>
  }
  bwrite(buf);
    800041cc:	8526                	mv	a0,s1
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	0a6080e7          	jalr	166(ra) # 80003274 <bwrite>
  brelse(buf);
    800041d6:	8526                	mv	a0,s1
    800041d8:	fffff097          	auipc	ra,0xfffff
    800041dc:	0da080e7          	jalr	218(ra) # 800032b2 <brelse>
}
    800041e0:	60e2                	ld	ra,24(sp)
    800041e2:	6442                	ld	s0,16(sp)
    800041e4:	64a2                	ld	s1,8(sp)
    800041e6:	6902                	ld	s2,0(sp)
    800041e8:	6105                	addi	sp,sp,32
    800041ea:	8082                	ret

00000000800041ec <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ec:	0001e797          	auipc	a5,0x1e
    800041f0:	4487a783          	lw	a5,1096(a5) # 80022634 <log+0x2c>
    800041f4:	0af05663          	blez	a5,800042a0 <install_trans+0xb4>
{
    800041f8:	7139                	addi	sp,sp,-64
    800041fa:	fc06                	sd	ra,56(sp)
    800041fc:	f822                	sd	s0,48(sp)
    800041fe:	f426                	sd	s1,40(sp)
    80004200:	f04a                	sd	s2,32(sp)
    80004202:	ec4e                	sd	s3,24(sp)
    80004204:	e852                	sd	s4,16(sp)
    80004206:	e456                	sd	s5,8(sp)
    80004208:	0080                	addi	s0,sp,64
    8000420a:	0001ea97          	auipc	s5,0x1e
    8000420e:	42ea8a93          	addi	s5,s5,1070 # 80022638 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004212:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004214:	0001e997          	auipc	s3,0x1e
    80004218:	3f498993          	addi	s3,s3,1012 # 80022608 <log>
    8000421c:	0189a583          	lw	a1,24(s3)
    80004220:	014585bb          	addw	a1,a1,s4
    80004224:	2585                	addiw	a1,a1,1
    80004226:	0289a503          	lw	a0,40(s3)
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	f58080e7          	jalr	-168(ra) # 80003182 <bread>
    80004232:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004234:	000aa583          	lw	a1,0(s5)
    80004238:	0289a503          	lw	a0,40(s3)
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	f46080e7          	jalr	-186(ra) # 80003182 <bread>
    80004244:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004246:	40000613          	li	a2,1024
    8000424a:	05890593          	addi	a1,s2,88
    8000424e:	05850513          	addi	a0,a0,88
    80004252:	ffffd097          	auipc	ra,0xffffd
    80004256:	b02080e7          	jalr	-1278(ra) # 80000d54 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000425a:	8526                	mv	a0,s1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	018080e7          	jalr	24(ra) # 80003274 <bwrite>
    bunpin(dbuf);
    80004264:	8526                	mv	a0,s1
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	126080e7          	jalr	294(ra) # 8000338c <bunpin>
    brelse(lbuf);
    8000426e:	854a                	mv	a0,s2
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	042080e7          	jalr	66(ra) # 800032b2 <brelse>
    brelse(dbuf);
    80004278:	8526                	mv	a0,s1
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	038080e7          	jalr	56(ra) # 800032b2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004282:	2a05                	addiw	s4,s4,1
    80004284:	0a91                	addi	s5,s5,4
    80004286:	02c9a783          	lw	a5,44(s3)
    8000428a:	f8fa49e3          	blt	s4,a5,8000421c <install_trans+0x30>
}
    8000428e:	70e2                	ld	ra,56(sp)
    80004290:	7442                	ld	s0,48(sp)
    80004292:	74a2                	ld	s1,40(sp)
    80004294:	7902                	ld	s2,32(sp)
    80004296:	69e2                	ld	s3,24(sp)
    80004298:	6a42                	ld	s4,16(sp)
    8000429a:	6aa2                	ld	s5,8(sp)
    8000429c:	6121                	addi	sp,sp,64
    8000429e:	8082                	ret
    800042a0:	8082                	ret

00000000800042a2 <initlog>:
{
    800042a2:	7179                	addi	sp,sp,-48
    800042a4:	f406                	sd	ra,40(sp)
    800042a6:	f022                	sd	s0,32(sp)
    800042a8:	ec26                	sd	s1,24(sp)
    800042aa:	e84a                	sd	s2,16(sp)
    800042ac:	e44e                	sd	s3,8(sp)
    800042ae:	1800                	addi	s0,sp,48
    800042b0:	892a                	mv	s2,a0
    800042b2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042b4:	0001e497          	auipc	s1,0x1e
    800042b8:	35448493          	addi	s1,s1,852 # 80022608 <log>
    800042bc:	00004597          	auipc	a1,0x4
    800042c0:	39458593          	addi	a1,a1,916 # 80008650 <syscalls+0x1d8>
    800042c4:	8526                	mv	a0,s1
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	8a6080e7          	jalr	-1882(ra) # 80000b6c <initlock>
  log.start = sb->logstart;
    800042ce:	0149a583          	lw	a1,20(s3)
    800042d2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042d4:	0109a783          	lw	a5,16(s3)
    800042d8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042da:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042de:	854a                	mv	a0,s2
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	ea2080e7          	jalr	-350(ra) # 80003182 <bread>
  log.lh.n = lh->n;
    800042e8:	4d34                	lw	a3,88(a0)
    800042ea:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042ec:	02d05663          	blez	a3,80004318 <initlog+0x76>
    800042f0:	05c50793          	addi	a5,a0,92
    800042f4:	0001e717          	auipc	a4,0x1e
    800042f8:	34470713          	addi	a4,a4,836 # 80022638 <log+0x30>
    800042fc:	36fd                	addiw	a3,a3,-1
    800042fe:	02069613          	slli	a2,a3,0x20
    80004302:	01e65693          	srli	a3,a2,0x1e
    80004306:	06050613          	addi	a2,a0,96
    8000430a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000430c:	4390                	lw	a2,0(a5)
    8000430e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004310:	0791                	addi	a5,a5,4
    80004312:	0711                	addi	a4,a4,4
    80004314:	fed79ce3          	bne	a5,a3,8000430c <initlog+0x6a>
  brelse(buf);
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	f9a080e7          	jalr	-102(ra) # 800032b2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004320:	00000097          	auipc	ra,0x0
    80004324:	ecc080e7          	jalr	-308(ra) # 800041ec <install_trans>
  log.lh.n = 0;
    80004328:	0001e797          	auipc	a5,0x1e
    8000432c:	3007a623          	sw	zero,780(a5) # 80022634 <log+0x2c>
  write_head(); // clear the log
    80004330:	00000097          	auipc	ra,0x0
    80004334:	e40080e7          	jalr	-448(ra) # 80004170 <write_head>
}
    80004338:	70a2                	ld	ra,40(sp)
    8000433a:	7402                	ld	s0,32(sp)
    8000433c:	64e2                	ld	s1,24(sp)
    8000433e:	6942                	ld	s2,16(sp)
    80004340:	69a2                	ld	s3,8(sp)
    80004342:	6145                	addi	sp,sp,48
    80004344:	8082                	ret

0000000080004346 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004346:	1101                	addi	sp,sp,-32
    80004348:	ec06                	sd	ra,24(sp)
    8000434a:	e822                	sd	s0,16(sp)
    8000434c:	e426                	sd	s1,8(sp)
    8000434e:	e04a                	sd	s2,0(sp)
    80004350:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004352:	0001e517          	auipc	a0,0x1e
    80004356:	2b650513          	addi	a0,a0,694 # 80022608 <log>
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	8a2080e7          	jalr	-1886(ra) # 80000bfc <acquire>
  while(1){
    if(log.committing){
    80004362:	0001e497          	auipc	s1,0x1e
    80004366:	2a648493          	addi	s1,s1,678 # 80022608 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000436a:	4979                	li	s2,30
    8000436c:	a039                	j	8000437a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000436e:	85a6                	mv	a1,s1
    80004370:	8526                	mv	a0,s1
    80004372:	ffffe097          	auipc	ra,0xffffe
    80004376:	1b6080e7          	jalr	438(ra) # 80002528 <sleep>
    if(log.committing){
    8000437a:	50dc                	lw	a5,36(s1)
    8000437c:	fbed                	bnez	a5,8000436e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000437e:	509c                	lw	a5,32(s1)
    80004380:	0017871b          	addiw	a4,a5,1
    80004384:	0007069b          	sext.w	a3,a4
    80004388:	0027179b          	slliw	a5,a4,0x2
    8000438c:	9fb9                	addw	a5,a5,a4
    8000438e:	0017979b          	slliw	a5,a5,0x1
    80004392:	54d8                	lw	a4,44(s1)
    80004394:	9fb9                	addw	a5,a5,a4
    80004396:	00f95963          	bge	s2,a5,800043a8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000439a:	85a6                	mv	a1,s1
    8000439c:	8526                	mv	a0,s1
    8000439e:	ffffe097          	auipc	ra,0xffffe
    800043a2:	18a080e7          	jalr	394(ra) # 80002528 <sleep>
    800043a6:	bfd1                	j	8000437a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043a8:	0001e517          	auipc	a0,0x1e
    800043ac:	26050513          	addi	a0,a0,608 # 80022608 <log>
    800043b0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	8fe080e7          	jalr	-1794(ra) # 80000cb0 <release>
      break;
    }
  }
}
    800043ba:	60e2                	ld	ra,24(sp)
    800043bc:	6442                	ld	s0,16(sp)
    800043be:	64a2                	ld	s1,8(sp)
    800043c0:	6902                	ld	s2,0(sp)
    800043c2:	6105                	addi	sp,sp,32
    800043c4:	8082                	ret

00000000800043c6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043c6:	7139                	addi	sp,sp,-64
    800043c8:	fc06                	sd	ra,56(sp)
    800043ca:	f822                	sd	s0,48(sp)
    800043cc:	f426                	sd	s1,40(sp)
    800043ce:	f04a                	sd	s2,32(sp)
    800043d0:	ec4e                	sd	s3,24(sp)
    800043d2:	e852                	sd	s4,16(sp)
    800043d4:	e456                	sd	s5,8(sp)
    800043d6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043d8:	0001e497          	auipc	s1,0x1e
    800043dc:	23048493          	addi	s1,s1,560 # 80022608 <log>
    800043e0:	8526                	mv	a0,s1
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	81a080e7          	jalr	-2022(ra) # 80000bfc <acquire>
  log.outstanding -= 1;
    800043ea:	509c                	lw	a5,32(s1)
    800043ec:	37fd                	addiw	a5,a5,-1
    800043ee:	0007891b          	sext.w	s2,a5
    800043f2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043f4:	50dc                	lw	a5,36(s1)
    800043f6:	e7b9                	bnez	a5,80004444 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043f8:	04091e63          	bnez	s2,80004454 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800043fc:	0001e497          	auipc	s1,0x1e
    80004400:	20c48493          	addi	s1,s1,524 # 80022608 <log>
    80004404:	4785                	li	a5,1
    80004406:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004408:	8526                	mv	a0,s1
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	8a6080e7          	jalr	-1882(ra) # 80000cb0 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004412:	54dc                	lw	a5,44(s1)
    80004414:	06f04763          	bgtz	a5,80004482 <end_op+0xbc>
    acquire(&log.lock);
    80004418:	0001e497          	auipc	s1,0x1e
    8000441c:	1f048493          	addi	s1,s1,496 # 80022608 <log>
    80004420:	8526                	mv	a0,s1
    80004422:	ffffc097          	auipc	ra,0xffffc
    80004426:	7da080e7          	jalr	2010(ra) # 80000bfc <acquire>
    log.committing = 0;
    8000442a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffe097          	auipc	ra,0xffffe
    80004434:	284080e7          	jalr	644(ra) # 800026b4 <wakeup>
    release(&log.lock);
    80004438:	8526                	mv	a0,s1
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	876080e7          	jalr	-1930(ra) # 80000cb0 <release>
}
    80004442:	a03d                	j	80004470 <end_op+0xaa>
    panic("log.committing");
    80004444:	00004517          	auipc	a0,0x4
    80004448:	21450513          	addi	a0,a0,532 # 80008658 <syscalls+0x1e0>
    8000444c:	ffffc097          	auipc	ra,0xffffc
    80004450:	0f4080e7          	jalr	244(ra) # 80000540 <panic>
    wakeup(&log);
    80004454:	0001e497          	auipc	s1,0x1e
    80004458:	1b448493          	addi	s1,s1,436 # 80022608 <log>
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffe097          	auipc	ra,0xffffe
    80004462:	256080e7          	jalr	598(ra) # 800026b4 <wakeup>
  release(&log.lock);
    80004466:	8526                	mv	a0,s1
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	848080e7          	jalr	-1976(ra) # 80000cb0 <release>
}
    80004470:	70e2                	ld	ra,56(sp)
    80004472:	7442                	ld	s0,48(sp)
    80004474:	74a2                	ld	s1,40(sp)
    80004476:	7902                	ld	s2,32(sp)
    80004478:	69e2                	ld	s3,24(sp)
    8000447a:	6a42                	ld	s4,16(sp)
    8000447c:	6aa2                	ld	s5,8(sp)
    8000447e:	6121                	addi	sp,sp,64
    80004480:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004482:	0001ea97          	auipc	s5,0x1e
    80004486:	1b6a8a93          	addi	s5,s5,438 # 80022638 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000448a:	0001ea17          	auipc	s4,0x1e
    8000448e:	17ea0a13          	addi	s4,s4,382 # 80022608 <log>
    80004492:	018a2583          	lw	a1,24(s4)
    80004496:	012585bb          	addw	a1,a1,s2
    8000449a:	2585                	addiw	a1,a1,1
    8000449c:	028a2503          	lw	a0,40(s4)
    800044a0:	fffff097          	auipc	ra,0xfffff
    800044a4:	ce2080e7          	jalr	-798(ra) # 80003182 <bread>
    800044a8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044aa:	000aa583          	lw	a1,0(s5)
    800044ae:	028a2503          	lw	a0,40(s4)
    800044b2:	fffff097          	auipc	ra,0xfffff
    800044b6:	cd0080e7          	jalr	-816(ra) # 80003182 <bread>
    800044ba:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044bc:	40000613          	li	a2,1024
    800044c0:	05850593          	addi	a1,a0,88
    800044c4:	05848513          	addi	a0,s1,88
    800044c8:	ffffd097          	auipc	ra,0xffffd
    800044cc:	88c080e7          	jalr	-1908(ra) # 80000d54 <memmove>
    bwrite(to);  // write the log
    800044d0:	8526                	mv	a0,s1
    800044d2:	fffff097          	auipc	ra,0xfffff
    800044d6:	da2080e7          	jalr	-606(ra) # 80003274 <bwrite>
    brelse(from);
    800044da:	854e                	mv	a0,s3
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	dd6080e7          	jalr	-554(ra) # 800032b2 <brelse>
    brelse(to);
    800044e4:	8526                	mv	a0,s1
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	dcc080e7          	jalr	-564(ra) # 800032b2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ee:	2905                	addiw	s2,s2,1
    800044f0:	0a91                	addi	s5,s5,4
    800044f2:	02ca2783          	lw	a5,44(s4)
    800044f6:	f8f94ee3          	blt	s2,a5,80004492 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	c76080e7          	jalr	-906(ra) # 80004170 <write_head>
    install_trans(); // Now install writes to home locations
    80004502:	00000097          	auipc	ra,0x0
    80004506:	cea080e7          	jalr	-790(ra) # 800041ec <install_trans>
    log.lh.n = 0;
    8000450a:	0001e797          	auipc	a5,0x1e
    8000450e:	1207a523          	sw	zero,298(a5) # 80022634 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004512:	00000097          	auipc	ra,0x0
    80004516:	c5e080e7          	jalr	-930(ra) # 80004170 <write_head>
    8000451a:	bdfd                	j	80004418 <end_op+0x52>

000000008000451c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000451c:	1101                	addi	sp,sp,-32
    8000451e:	ec06                	sd	ra,24(sp)
    80004520:	e822                	sd	s0,16(sp)
    80004522:	e426                	sd	s1,8(sp)
    80004524:	e04a                	sd	s2,0(sp)
    80004526:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004528:	0001e717          	auipc	a4,0x1e
    8000452c:	10c72703          	lw	a4,268(a4) # 80022634 <log+0x2c>
    80004530:	47f5                	li	a5,29
    80004532:	08e7c063          	blt	a5,a4,800045b2 <log_write+0x96>
    80004536:	84aa                	mv	s1,a0
    80004538:	0001e797          	auipc	a5,0x1e
    8000453c:	0ec7a783          	lw	a5,236(a5) # 80022624 <log+0x1c>
    80004540:	37fd                	addiw	a5,a5,-1
    80004542:	06f75863          	bge	a4,a5,800045b2 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004546:	0001e797          	auipc	a5,0x1e
    8000454a:	0e27a783          	lw	a5,226(a5) # 80022628 <log+0x20>
    8000454e:	06f05a63          	blez	a5,800045c2 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004552:	0001e917          	auipc	s2,0x1e
    80004556:	0b690913          	addi	s2,s2,182 # 80022608 <log>
    8000455a:	854a                	mv	a0,s2
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	6a0080e7          	jalr	1696(ra) # 80000bfc <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004564:	02c92603          	lw	a2,44(s2)
    80004568:	06c05563          	blez	a2,800045d2 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000456c:	44cc                	lw	a1,12(s1)
    8000456e:	0001e717          	auipc	a4,0x1e
    80004572:	0ca70713          	addi	a4,a4,202 # 80022638 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004576:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004578:	4314                	lw	a3,0(a4)
    8000457a:	04b68d63          	beq	a3,a1,800045d4 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000457e:	2785                	addiw	a5,a5,1
    80004580:	0711                	addi	a4,a4,4
    80004582:	fec79be3          	bne	a5,a2,80004578 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004586:	0621                	addi	a2,a2,8
    80004588:	060a                	slli	a2,a2,0x2
    8000458a:	0001e797          	auipc	a5,0x1e
    8000458e:	07e78793          	addi	a5,a5,126 # 80022608 <log>
    80004592:	963e                	add	a2,a2,a5
    80004594:	44dc                	lw	a5,12(s1)
    80004596:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004598:	8526                	mv	a0,s1
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	db6080e7          	jalr	-586(ra) # 80003350 <bpin>
    log.lh.n++;
    800045a2:	0001e717          	auipc	a4,0x1e
    800045a6:	06670713          	addi	a4,a4,102 # 80022608 <log>
    800045aa:	575c                	lw	a5,44(a4)
    800045ac:	2785                	addiw	a5,a5,1
    800045ae:	d75c                	sw	a5,44(a4)
    800045b0:	a83d                	j	800045ee <log_write+0xd2>
    panic("too big a transaction");
    800045b2:	00004517          	auipc	a0,0x4
    800045b6:	0b650513          	addi	a0,a0,182 # 80008668 <syscalls+0x1f0>
    800045ba:	ffffc097          	auipc	ra,0xffffc
    800045be:	f86080e7          	jalr	-122(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800045c2:	00004517          	auipc	a0,0x4
    800045c6:	0be50513          	addi	a0,a0,190 # 80008680 <syscalls+0x208>
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	f76080e7          	jalr	-138(ra) # 80000540 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800045d2:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800045d4:	00878713          	addi	a4,a5,8
    800045d8:	00271693          	slli	a3,a4,0x2
    800045dc:	0001e717          	auipc	a4,0x1e
    800045e0:	02c70713          	addi	a4,a4,44 # 80022608 <log>
    800045e4:	9736                	add	a4,a4,a3
    800045e6:	44d4                	lw	a3,12(s1)
    800045e8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045ea:	faf607e3          	beq	a2,a5,80004598 <log_write+0x7c>
  }
  release(&log.lock);
    800045ee:	0001e517          	auipc	a0,0x1e
    800045f2:	01a50513          	addi	a0,a0,26 # 80022608 <log>
    800045f6:	ffffc097          	auipc	ra,0xffffc
    800045fa:	6ba080e7          	jalr	1722(ra) # 80000cb0 <release>
}
    800045fe:	60e2                	ld	ra,24(sp)
    80004600:	6442                	ld	s0,16(sp)
    80004602:	64a2                	ld	s1,8(sp)
    80004604:	6902                	ld	s2,0(sp)
    80004606:	6105                	addi	sp,sp,32
    80004608:	8082                	ret

000000008000460a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000460a:	1101                	addi	sp,sp,-32
    8000460c:	ec06                	sd	ra,24(sp)
    8000460e:	e822                	sd	s0,16(sp)
    80004610:	e426                	sd	s1,8(sp)
    80004612:	e04a                	sd	s2,0(sp)
    80004614:	1000                	addi	s0,sp,32
    80004616:	84aa                	mv	s1,a0
    80004618:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000461a:	00004597          	auipc	a1,0x4
    8000461e:	08658593          	addi	a1,a1,134 # 800086a0 <syscalls+0x228>
    80004622:	0521                	addi	a0,a0,8
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	548080e7          	jalr	1352(ra) # 80000b6c <initlock>
  lk->name = name;
    8000462c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004630:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004634:	0204a423          	sw	zero,40(s1)
}
    80004638:	60e2                	ld	ra,24(sp)
    8000463a:	6442                	ld	s0,16(sp)
    8000463c:	64a2                	ld	s1,8(sp)
    8000463e:	6902                	ld	s2,0(sp)
    80004640:	6105                	addi	sp,sp,32
    80004642:	8082                	ret

0000000080004644 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004644:	1101                	addi	sp,sp,-32
    80004646:	ec06                	sd	ra,24(sp)
    80004648:	e822                	sd	s0,16(sp)
    8000464a:	e426                	sd	s1,8(sp)
    8000464c:	e04a                	sd	s2,0(sp)
    8000464e:	1000                	addi	s0,sp,32
    80004650:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004652:	00850913          	addi	s2,a0,8
    80004656:	854a                	mv	a0,s2
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	5a4080e7          	jalr	1444(ra) # 80000bfc <acquire>
  while (lk->locked) {
    80004660:	409c                	lw	a5,0(s1)
    80004662:	cb89                	beqz	a5,80004674 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004664:	85ca                	mv	a1,s2
    80004666:	8526                	mv	a0,s1
    80004668:	ffffe097          	auipc	ra,0xffffe
    8000466c:	ec0080e7          	jalr	-320(ra) # 80002528 <sleep>
  while (lk->locked) {
    80004670:	409c                	lw	a5,0(s1)
    80004672:	fbed                	bnez	a5,80004664 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004674:	4785                	li	a5,1
    80004676:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004678:	ffffd097          	auipc	ra,0xffffd
    8000467c:	476080e7          	jalr	1142(ra) # 80001aee <myproc>
    80004680:	5d1c                	lw	a5,56(a0)
    80004682:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004684:	854a                	mv	a0,s2
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	62a080e7          	jalr	1578(ra) # 80000cb0 <release>
}
    8000468e:	60e2                	ld	ra,24(sp)
    80004690:	6442                	ld	s0,16(sp)
    80004692:	64a2                	ld	s1,8(sp)
    80004694:	6902                	ld	s2,0(sp)
    80004696:	6105                	addi	sp,sp,32
    80004698:	8082                	ret

000000008000469a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000469a:	1101                	addi	sp,sp,-32
    8000469c:	ec06                	sd	ra,24(sp)
    8000469e:	e822                	sd	s0,16(sp)
    800046a0:	e426                	sd	s1,8(sp)
    800046a2:	e04a                	sd	s2,0(sp)
    800046a4:	1000                	addi	s0,sp,32
    800046a6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046a8:	00850913          	addi	s2,a0,8
    800046ac:	854a                	mv	a0,s2
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	54e080e7          	jalr	1358(ra) # 80000bfc <acquire>
  lk->locked = 0;
    800046b6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ba:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046be:	8526                	mv	a0,s1
    800046c0:	ffffe097          	auipc	ra,0xffffe
    800046c4:	ff4080e7          	jalr	-12(ra) # 800026b4 <wakeup>
  release(&lk->lk);
    800046c8:	854a                	mv	a0,s2
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	5e6080e7          	jalr	1510(ra) # 80000cb0 <release>
}
    800046d2:	60e2                	ld	ra,24(sp)
    800046d4:	6442                	ld	s0,16(sp)
    800046d6:	64a2                	ld	s1,8(sp)
    800046d8:	6902                	ld	s2,0(sp)
    800046da:	6105                	addi	sp,sp,32
    800046dc:	8082                	ret

00000000800046de <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046de:	7179                	addi	sp,sp,-48
    800046e0:	f406                	sd	ra,40(sp)
    800046e2:	f022                	sd	s0,32(sp)
    800046e4:	ec26                	sd	s1,24(sp)
    800046e6:	e84a                	sd	s2,16(sp)
    800046e8:	e44e                	sd	s3,8(sp)
    800046ea:	1800                	addi	s0,sp,48
    800046ec:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046ee:	00850913          	addi	s2,a0,8
    800046f2:	854a                	mv	a0,s2
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	508080e7          	jalr	1288(ra) # 80000bfc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046fc:	409c                	lw	a5,0(s1)
    800046fe:	ef99                	bnez	a5,8000471c <holdingsleep+0x3e>
    80004700:	4481                	li	s1,0
  release(&lk->lk);
    80004702:	854a                	mv	a0,s2
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	5ac080e7          	jalr	1452(ra) # 80000cb0 <release>
  return r;
}
    8000470c:	8526                	mv	a0,s1
    8000470e:	70a2                	ld	ra,40(sp)
    80004710:	7402                	ld	s0,32(sp)
    80004712:	64e2                	ld	s1,24(sp)
    80004714:	6942                	ld	s2,16(sp)
    80004716:	69a2                	ld	s3,8(sp)
    80004718:	6145                	addi	sp,sp,48
    8000471a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000471c:	0284a983          	lw	s3,40(s1)
    80004720:	ffffd097          	auipc	ra,0xffffd
    80004724:	3ce080e7          	jalr	974(ra) # 80001aee <myproc>
    80004728:	5d04                	lw	s1,56(a0)
    8000472a:	413484b3          	sub	s1,s1,s3
    8000472e:	0014b493          	seqz	s1,s1
    80004732:	bfc1                	j	80004702 <holdingsleep+0x24>

0000000080004734 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004734:	1141                	addi	sp,sp,-16
    80004736:	e406                	sd	ra,8(sp)
    80004738:	e022                	sd	s0,0(sp)
    8000473a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000473c:	00004597          	auipc	a1,0x4
    80004740:	f7458593          	addi	a1,a1,-140 # 800086b0 <syscalls+0x238>
    80004744:	0001e517          	auipc	a0,0x1e
    80004748:	00c50513          	addi	a0,a0,12 # 80022750 <ftable>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	420080e7          	jalr	1056(ra) # 80000b6c <initlock>
}
    80004754:	60a2                	ld	ra,8(sp)
    80004756:	6402                	ld	s0,0(sp)
    80004758:	0141                	addi	sp,sp,16
    8000475a:	8082                	ret

000000008000475c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000475c:	1101                	addi	sp,sp,-32
    8000475e:	ec06                	sd	ra,24(sp)
    80004760:	e822                	sd	s0,16(sp)
    80004762:	e426                	sd	s1,8(sp)
    80004764:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004766:	0001e517          	auipc	a0,0x1e
    8000476a:	fea50513          	addi	a0,a0,-22 # 80022750 <ftable>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	48e080e7          	jalr	1166(ra) # 80000bfc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004776:	0001e497          	auipc	s1,0x1e
    8000477a:	ff248493          	addi	s1,s1,-14 # 80022768 <ftable+0x18>
    8000477e:	0001f717          	auipc	a4,0x1f
    80004782:	f8a70713          	addi	a4,a4,-118 # 80023708 <ftable+0xfb8>
    if(f->ref == 0){
    80004786:	40dc                	lw	a5,4(s1)
    80004788:	cf99                	beqz	a5,800047a6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000478a:	02848493          	addi	s1,s1,40
    8000478e:	fee49ce3          	bne	s1,a4,80004786 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004792:	0001e517          	auipc	a0,0x1e
    80004796:	fbe50513          	addi	a0,a0,-66 # 80022750 <ftable>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	516080e7          	jalr	1302(ra) # 80000cb0 <release>
  return 0;
    800047a2:	4481                	li	s1,0
    800047a4:	a819                	j	800047ba <filealloc+0x5e>
      f->ref = 1;
    800047a6:	4785                	li	a5,1
    800047a8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047aa:	0001e517          	auipc	a0,0x1e
    800047ae:	fa650513          	addi	a0,a0,-90 # 80022750 <ftable>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	4fe080e7          	jalr	1278(ra) # 80000cb0 <release>
}
    800047ba:	8526                	mv	a0,s1
    800047bc:	60e2                	ld	ra,24(sp)
    800047be:	6442                	ld	s0,16(sp)
    800047c0:	64a2                	ld	s1,8(sp)
    800047c2:	6105                	addi	sp,sp,32
    800047c4:	8082                	ret

00000000800047c6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047c6:	1101                	addi	sp,sp,-32
    800047c8:	ec06                	sd	ra,24(sp)
    800047ca:	e822                	sd	s0,16(sp)
    800047cc:	e426                	sd	s1,8(sp)
    800047ce:	1000                	addi	s0,sp,32
    800047d0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047d2:	0001e517          	auipc	a0,0x1e
    800047d6:	f7e50513          	addi	a0,a0,-130 # 80022750 <ftable>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	422080e7          	jalr	1058(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    800047e2:	40dc                	lw	a5,4(s1)
    800047e4:	02f05263          	blez	a5,80004808 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047e8:	2785                	addiw	a5,a5,1
    800047ea:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047ec:	0001e517          	auipc	a0,0x1e
    800047f0:	f6450513          	addi	a0,a0,-156 # 80022750 <ftable>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	4bc080e7          	jalr	1212(ra) # 80000cb0 <release>
  return f;
}
    800047fc:	8526                	mv	a0,s1
    800047fe:	60e2                	ld	ra,24(sp)
    80004800:	6442                	ld	s0,16(sp)
    80004802:	64a2                	ld	s1,8(sp)
    80004804:	6105                	addi	sp,sp,32
    80004806:	8082                	ret
    panic("filedup");
    80004808:	00004517          	auipc	a0,0x4
    8000480c:	eb050513          	addi	a0,a0,-336 # 800086b8 <syscalls+0x240>
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	d30080e7          	jalr	-720(ra) # 80000540 <panic>

0000000080004818 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004818:	7139                	addi	sp,sp,-64
    8000481a:	fc06                	sd	ra,56(sp)
    8000481c:	f822                	sd	s0,48(sp)
    8000481e:	f426                	sd	s1,40(sp)
    80004820:	f04a                	sd	s2,32(sp)
    80004822:	ec4e                	sd	s3,24(sp)
    80004824:	e852                	sd	s4,16(sp)
    80004826:	e456                	sd	s5,8(sp)
    80004828:	0080                	addi	s0,sp,64
    8000482a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000482c:	0001e517          	auipc	a0,0x1e
    80004830:	f2450513          	addi	a0,a0,-220 # 80022750 <ftable>
    80004834:	ffffc097          	auipc	ra,0xffffc
    80004838:	3c8080e7          	jalr	968(ra) # 80000bfc <acquire>
  if(f->ref < 1)
    8000483c:	40dc                	lw	a5,4(s1)
    8000483e:	06f05163          	blez	a5,800048a0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004842:	37fd                	addiw	a5,a5,-1
    80004844:	0007871b          	sext.w	a4,a5
    80004848:	c0dc                	sw	a5,4(s1)
    8000484a:	06e04363          	bgtz	a4,800048b0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000484e:	0004a903          	lw	s2,0(s1)
    80004852:	0094ca83          	lbu	s5,9(s1)
    80004856:	0104ba03          	ld	s4,16(s1)
    8000485a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000485e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004862:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004866:	0001e517          	auipc	a0,0x1e
    8000486a:	eea50513          	addi	a0,a0,-278 # 80022750 <ftable>
    8000486e:	ffffc097          	auipc	ra,0xffffc
    80004872:	442080e7          	jalr	1090(ra) # 80000cb0 <release>

  if(ff.type == FD_PIPE){
    80004876:	4785                	li	a5,1
    80004878:	04f90d63          	beq	s2,a5,800048d2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000487c:	3979                	addiw	s2,s2,-2
    8000487e:	4785                	li	a5,1
    80004880:	0527e063          	bltu	a5,s2,800048c0 <fileclose+0xa8>
    begin_op();
    80004884:	00000097          	auipc	ra,0x0
    80004888:	ac2080e7          	jalr	-1342(ra) # 80004346 <begin_op>
    iput(ff.ip);
    8000488c:	854e                	mv	a0,s3
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	2b2080e7          	jalr	690(ra) # 80003b40 <iput>
    end_op();
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	b30080e7          	jalr	-1232(ra) # 800043c6 <end_op>
    8000489e:	a00d                	j	800048c0 <fileclose+0xa8>
    panic("fileclose");
    800048a0:	00004517          	auipc	a0,0x4
    800048a4:	e2050513          	addi	a0,a0,-480 # 800086c0 <syscalls+0x248>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	c98080e7          	jalr	-872(ra) # 80000540 <panic>
    release(&ftable.lock);
    800048b0:	0001e517          	auipc	a0,0x1e
    800048b4:	ea050513          	addi	a0,a0,-352 # 80022750 <ftable>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	3f8080e7          	jalr	1016(ra) # 80000cb0 <release>
  }
}
    800048c0:	70e2                	ld	ra,56(sp)
    800048c2:	7442                	ld	s0,48(sp)
    800048c4:	74a2                	ld	s1,40(sp)
    800048c6:	7902                	ld	s2,32(sp)
    800048c8:	69e2                	ld	s3,24(sp)
    800048ca:	6a42                	ld	s4,16(sp)
    800048cc:	6aa2                	ld	s5,8(sp)
    800048ce:	6121                	addi	sp,sp,64
    800048d0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048d2:	85d6                	mv	a1,s5
    800048d4:	8552                	mv	a0,s4
    800048d6:	00000097          	auipc	ra,0x0
    800048da:	372080e7          	jalr	882(ra) # 80004c48 <pipeclose>
    800048de:	b7cd                	j	800048c0 <fileclose+0xa8>

00000000800048e0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048e0:	715d                	addi	sp,sp,-80
    800048e2:	e486                	sd	ra,72(sp)
    800048e4:	e0a2                	sd	s0,64(sp)
    800048e6:	fc26                	sd	s1,56(sp)
    800048e8:	f84a                	sd	s2,48(sp)
    800048ea:	f44e                	sd	s3,40(sp)
    800048ec:	0880                	addi	s0,sp,80
    800048ee:	84aa                	mv	s1,a0
    800048f0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048f2:	ffffd097          	auipc	ra,0xffffd
    800048f6:	1fc080e7          	jalr	508(ra) # 80001aee <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048fa:	409c                	lw	a5,0(s1)
    800048fc:	37f9                	addiw	a5,a5,-2
    800048fe:	4705                	li	a4,1
    80004900:	04f76763          	bltu	a4,a5,8000494e <filestat+0x6e>
    80004904:	892a                	mv	s2,a0
    ilock(f->ip);
    80004906:	6c88                	ld	a0,24(s1)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	07e080e7          	jalr	126(ra) # 80003986 <ilock>
    stati(f->ip, &st);
    80004910:	fb840593          	addi	a1,s0,-72
    80004914:	6c88                	ld	a0,24(s1)
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	2fa080e7          	jalr	762(ra) # 80003c10 <stati>
    iunlock(f->ip);
    8000491e:	6c88                	ld	a0,24(s1)
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	128080e7          	jalr	296(ra) # 80003a48 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004928:	46e1                	li	a3,24
    8000492a:	fb840613          	addi	a2,s0,-72
    8000492e:	85ce                	mv	a1,s3
    80004930:	05093503          	ld	a0,80(s2)
    80004934:	ffffd097          	auipc	ra,0xffffd
    80004938:	d76080e7          	jalr	-650(ra) # 800016aa <copyout>
    8000493c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004940:	60a6                	ld	ra,72(sp)
    80004942:	6406                	ld	s0,64(sp)
    80004944:	74e2                	ld	s1,56(sp)
    80004946:	7942                	ld	s2,48(sp)
    80004948:	79a2                	ld	s3,40(sp)
    8000494a:	6161                	addi	sp,sp,80
    8000494c:	8082                	ret
  return -1;
    8000494e:	557d                	li	a0,-1
    80004950:	bfc5                	j	80004940 <filestat+0x60>

0000000080004952 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004952:	7179                	addi	sp,sp,-48
    80004954:	f406                	sd	ra,40(sp)
    80004956:	f022                	sd	s0,32(sp)
    80004958:	ec26                	sd	s1,24(sp)
    8000495a:	e84a                	sd	s2,16(sp)
    8000495c:	e44e                	sd	s3,8(sp)
    8000495e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004960:	00854783          	lbu	a5,8(a0)
    80004964:	c3d5                	beqz	a5,80004a08 <fileread+0xb6>
    80004966:	84aa                	mv	s1,a0
    80004968:	89ae                	mv	s3,a1
    8000496a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000496c:	411c                	lw	a5,0(a0)
    8000496e:	4705                	li	a4,1
    80004970:	04e78963          	beq	a5,a4,800049c2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004974:	470d                	li	a4,3
    80004976:	04e78d63          	beq	a5,a4,800049d0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000497a:	4709                	li	a4,2
    8000497c:	06e79e63          	bne	a5,a4,800049f8 <fileread+0xa6>
    ilock(f->ip);
    80004980:	6d08                	ld	a0,24(a0)
    80004982:	fffff097          	auipc	ra,0xfffff
    80004986:	004080e7          	jalr	4(ra) # 80003986 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000498a:	874a                	mv	a4,s2
    8000498c:	5094                	lw	a3,32(s1)
    8000498e:	864e                	mv	a2,s3
    80004990:	4585                	li	a1,1
    80004992:	6c88                	ld	a0,24(s1)
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	2a6080e7          	jalr	678(ra) # 80003c3a <readi>
    8000499c:	892a                	mv	s2,a0
    8000499e:	00a05563          	blez	a0,800049a8 <fileread+0x56>
      f->off += r;
    800049a2:	509c                	lw	a5,32(s1)
    800049a4:	9fa9                	addw	a5,a5,a0
    800049a6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049a8:	6c88                	ld	a0,24(s1)
    800049aa:	fffff097          	auipc	ra,0xfffff
    800049ae:	09e080e7          	jalr	158(ra) # 80003a48 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049b2:	854a                	mv	a0,s2
    800049b4:	70a2                	ld	ra,40(sp)
    800049b6:	7402                	ld	s0,32(sp)
    800049b8:	64e2                	ld	s1,24(sp)
    800049ba:	6942                	ld	s2,16(sp)
    800049bc:	69a2                	ld	s3,8(sp)
    800049be:	6145                	addi	sp,sp,48
    800049c0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049c2:	6908                	ld	a0,16(a0)
    800049c4:	00000097          	auipc	ra,0x0
    800049c8:	3f4080e7          	jalr	1012(ra) # 80004db8 <piperead>
    800049cc:	892a                	mv	s2,a0
    800049ce:	b7d5                	j	800049b2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049d0:	02451783          	lh	a5,36(a0)
    800049d4:	03079693          	slli	a3,a5,0x30
    800049d8:	92c1                	srli	a3,a3,0x30
    800049da:	4725                	li	a4,9
    800049dc:	02d76863          	bltu	a4,a3,80004a0c <fileread+0xba>
    800049e0:	0792                	slli	a5,a5,0x4
    800049e2:	0001e717          	auipc	a4,0x1e
    800049e6:	cce70713          	addi	a4,a4,-818 # 800226b0 <devsw>
    800049ea:	97ba                	add	a5,a5,a4
    800049ec:	639c                	ld	a5,0(a5)
    800049ee:	c38d                	beqz	a5,80004a10 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049f0:	4505                	li	a0,1
    800049f2:	9782                	jalr	a5
    800049f4:	892a                	mv	s2,a0
    800049f6:	bf75                	j	800049b2 <fileread+0x60>
    panic("fileread");
    800049f8:	00004517          	auipc	a0,0x4
    800049fc:	cd850513          	addi	a0,a0,-808 # 800086d0 <syscalls+0x258>
    80004a00:	ffffc097          	auipc	ra,0xffffc
    80004a04:	b40080e7          	jalr	-1216(ra) # 80000540 <panic>
    return -1;
    80004a08:	597d                	li	s2,-1
    80004a0a:	b765                	j	800049b2 <fileread+0x60>
      return -1;
    80004a0c:	597d                	li	s2,-1
    80004a0e:	b755                	j	800049b2 <fileread+0x60>
    80004a10:	597d                	li	s2,-1
    80004a12:	b745                	j	800049b2 <fileread+0x60>

0000000080004a14 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a14:	00954783          	lbu	a5,9(a0)
    80004a18:	14078563          	beqz	a5,80004b62 <filewrite+0x14e>
{
    80004a1c:	715d                	addi	sp,sp,-80
    80004a1e:	e486                	sd	ra,72(sp)
    80004a20:	e0a2                	sd	s0,64(sp)
    80004a22:	fc26                	sd	s1,56(sp)
    80004a24:	f84a                	sd	s2,48(sp)
    80004a26:	f44e                	sd	s3,40(sp)
    80004a28:	f052                	sd	s4,32(sp)
    80004a2a:	ec56                	sd	s5,24(sp)
    80004a2c:	e85a                	sd	s6,16(sp)
    80004a2e:	e45e                	sd	s7,8(sp)
    80004a30:	e062                	sd	s8,0(sp)
    80004a32:	0880                	addi	s0,sp,80
    80004a34:	892a                	mv	s2,a0
    80004a36:	8aae                	mv	s5,a1
    80004a38:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a3a:	411c                	lw	a5,0(a0)
    80004a3c:	4705                	li	a4,1
    80004a3e:	02e78263          	beq	a5,a4,80004a62 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a42:	470d                	li	a4,3
    80004a44:	02e78563          	beq	a5,a4,80004a6e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a48:	4709                	li	a4,2
    80004a4a:	10e79463          	bne	a5,a4,80004b52 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a4e:	0ec05e63          	blez	a2,80004b4a <filewrite+0x136>
    int i = 0;
    80004a52:	4981                	li	s3,0
    80004a54:	6b05                	lui	s6,0x1
    80004a56:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a5a:	6b85                	lui	s7,0x1
    80004a5c:	c00b8b9b          	addiw	s7,s7,-1024
    80004a60:	a851                	j	80004af4 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a62:	6908                	ld	a0,16(a0)
    80004a64:	00000097          	auipc	ra,0x0
    80004a68:	254080e7          	jalr	596(ra) # 80004cb8 <pipewrite>
    80004a6c:	a85d                	j	80004b22 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a6e:	02451783          	lh	a5,36(a0)
    80004a72:	03079693          	slli	a3,a5,0x30
    80004a76:	92c1                	srli	a3,a3,0x30
    80004a78:	4725                	li	a4,9
    80004a7a:	0ed76663          	bltu	a4,a3,80004b66 <filewrite+0x152>
    80004a7e:	0792                	slli	a5,a5,0x4
    80004a80:	0001e717          	auipc	a4,0x1e
    80004a84:	c3070713          	addi	a4,a4,-976 # 800226b0 <devsw>
    80004a88:	97ba                	add	a5,a5,a4
    80004a8a:	679c                	ld	a5,8(a5)
    80004a8c:	cff9                	beqz	a5,80004b6a <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a8e:	4505                	li	a0,1
    80004a90:	9782                	jalr	a5
    80004a92:	a841                	j	80004b22 <filewrite+0x10e>
    80004a94:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	8ae080e7          	jalr	-1874(ra) # 80004346 <begin_op>
      ilock(f->ip);
    80004aa0:	01893503          	ld	a0,24(s2)
    80004aa4:	fffff097          	auipc	ra,0xfffff
    80004aa8:	ee2080e7          	jalr	-286(ra) # 80003986 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aac:	8762                	mv	a4,s8
    80004aae:	02092683          	lw	a3,32(s2)
    80004ab2:	01598633          	add	a2,s3,s5
    80004ab6:	4585                	li	a1,1
    80004ab8:	01893503          	ld	a0,24(s2)
    80004abc:	fffff097          	auipc	ra,0xfffff
    80004ac0:	274080e7          	jalr	628(ra) # 80003d30 <writei>
    80004ac4:	84aa                	mv	s1,a0
    80004ac6:	02a05f63          	blez	a0,80004b04 <filewrite+0xf0>
        f->off += r;
    80004aca:	02092783          	lw	a5,32(s2)
    80004ace:	9fa9                	addw	a5,a5,a0
    80004ad0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ad4:	01893503          	ld	a0,24(s2)
    80004ad8:	fffff097          	auipc	ra,0xfffff
    80004adc:	f70080e7          	jalr	-144(ra) # 80003a48 <iunlock>
      end_op();
    80004ae0:	00000097          	auipc	ra,0x0
    80004ae4:	8e6080e7          	jalr	-1818(ra) # 800043c6 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004ae8:	049c1963          	bne	s8,s1,80004b3a <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004aec:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004af0:	0349d663          	bge	s3,s4,80004b1c <filewrite+0x108>
      int n1 = n - i;
    80004af4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004af8:	84be                	mv	s1,a5
    80004afa:	2781                	sext.w	a5,a5
    80004afc:	f8fb5ce3          	bge	s6,a5,80004a94 <filewrite+0x80>
    80004b00:	84de                	mv	s1,s7
    80004b02:	bf49                	j	80004a94 <filewrite+0x80>
      iunlock(f->ip);
    80004b04:	01893503          	ld	a0,24(s2)
    80004b08:	fffff097          	auipc	ra,0xfffff
    80004b0c:	f40080e7          	jalr	-192(ra) # 80003a48 <iunlock>
      end_op();
    80004b10:	00000097          	auipc	ra,0x0
    80004b14:	8b6080e7          	jalr	-1866(ra) # 800043c6 <end_op>
      if(r < 0)
    80004b18:	fc04d8e3          	bgez	s1,80004ae8 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b1c:	8552                	mv	a0,s4
    80004b1e:	033a1863          	bne	s4,s3,80004b4e <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b22:	60a6                	ld	ra,72(sp)
    80004b24:	6406                	ld	s0,64(sp)
    80004b26:	74e2                	ld	s1,56(sp)
    80004b28:	7942                	ld	s2,48(sp)
    80004b2a:	79a2                	ld	s3,40(sp)
    80004b2c:	7a02                	ld	s4,32(sp)
    80004b2e:	6ae2                	ld	s5,24(sp)
    80004b30:	6b42                	ld	s6,16(sp)
    80004b32:	6ba2                	ld	s7,8(sp)
    80004b34:	6c02                	ld	s8,0(sp)
    80004b36:	6161                	addi	sp,sp,80
    80004b38:	8082                	ret
        panic("short filewrite");
    80004b3a:	00004517          	auipc	a0,0x4
    80004b3e:	ba650513          	addi	a0,a0,-1114 # 800086e0 <syscalls+0x268>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	9fe080e7          	jalr	-1538(ra) # 80000540 <panic>
    int i = 0;
    80004b4a:	4981                	li	s3,0
    80004b4c:	bfc1                	j	80004b1c <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b4e:	557d                	li	a0,-1
    80004b50:	bfc9                	j	80004b22 <filewrite+0x10e>
    panic("filewrite");
    80004b52:	00004517          	auipc	a0,0x4
    80004b56:	b9e50513          	addi	a0,a0,-1122 # 800086f0 <syscalls+0x278>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	9e6080e7          	jalr	-1562(ra) # 80000540 <panic>
    return -1;
    80004b62:	557d                	li	a0,-1
}
    80004b64:	8082                	ret
      return -1;
    80004b66:	557d                	li	a0,-1
    80004b68:	bf6d                	j	80004b22 <filewrite+0x10e>
    80004b6a:	557d                	li	a0,-1
    80004b6c:	bf5d                	j	80004b22 <filewrite+0x10e>

0000000080004b6e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b6e:	7179                	addi	sp,sp,-48
    80004b70:	f406                	sd	ra,40(sp)
    80004b72:	f022                	sd	s0,32(sp)
    80004b74:	ec26                	sd	s1,24(sp)
    80004b76:	e84a                	sd	s2,16(sp)
    80004b78:	e44e                	sd	s3,8(sp)
    80004b7a:	e052                	sd	s4,0(sp)
    80004b7c:	1800                	addi	s0,sp,48
    80004b7e:	84aa                	mv	s1,a0
    80004b80:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b82:	0005b023          	sd	zero,0(a1)
    80004b86:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b8a:	00000097          	auipc	ra,0x0
    80004b8e:	bd2080e7          	jalr	-1070(ra) # 8000475c <filealloc>
    80004b92:	e088                	sd	a0,0(s1)
    80004b94:	c551                	beqz	a0,80004c20 <pipealloc+0xb2>
    80004b96:	00000097          	auipc	ra,0x0
    80004b9a:	bc6080e7          	jalr	-1082(ra) # 8000475c <filealloc>
    80004b9e:	00aa3023          	sd	a0,0(s4)
    80004ba2:	c92d                	beqz	a0,80004c14 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	f68080e7          	jalr	-152(ra) # 80000b0c <kalloc>
    80004bac:	892a                	mv	s2,a0
    80004bae:	c125                	beqz	a0,80004c0e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bb0:	4985                	li	s3,1
    80004bb2:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bb6:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bba:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bbe:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bc2:	00004597          	auipc	a1,0x4
    80004bc6:	b3e58593          	addi	a1,a1,-1218 # 80008700 <syscalls+0x288>
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	fa2080e7          	jalr	-94(ra) # 80000b6c <initlock>
  (*f0)->type = FD_PIPE;
    80004bd2:	609c                	ld	a5,0(s1)
    80004bd4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bd8:	609c                	ld	a5,0(s1)
    80004bda:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bde:	609c                	ld	a5,0(s1)
    80004be0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004be4:	609c                	ld	a5,0(s1)
    80004be6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bea:	000a3783          	ld	a5,0(s4)
    80004bee:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bf2:	000a3783          	ld	a5,0(s4)
    80004bf6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bfa:	000a3783          	ld	a5,0(s4)
    80004bfe:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c02:	000a3783          	ld	a5,0(s4)
    80004c06:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c0a:	4501                	li	a0,0
    80004c0c:	a025                	j	80004c34 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c0e:	6088                	ld	a0,0(s1)
    80004c10:	e501                	bnez	a0,80004c18 <pipealloc+0xaa>
    80004c12:	a039                	j	80004c20 <pipealloc+0xb2>
    80004c14:	6088                	ld	a0,0(s1)
    80004c16:	c51d                	beqz	a0,80004c44 <pipealloc+0xd6>
    fileclose(*f0);
    80004c18:	00000097          	auipc	ra,0x0
    80004c1c:	c00080e7          	jalr	-1024(ra) # 80004818 <fileclose>
  if(*f1)
    80004c20:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c24:	557d                	li	a0,-1
  if(*f1)
    80004c26:	c799                	beqz	a5,80004c34 <pipealloc+0xc6>
    fileclose(*f1);
    80004c28:	853e                	mv	a0,a5
    80004c2a:	00000097          	auipc	ra,0x0
    80004c2e:	bee080e7          	jalr	-1042(ra) # 80004818 <fileclose>
  return -1;
    80004c32:	557d                	li	a0,-1
}
    80004c34:	70a2                	ld	ra,40(sp)
    80004c36:	7402                	ld	s0,32(sp)
    80004c38:	64e2                	ld	s1,24(sp)
    80004c3a:	6942                	ld	s2,16(sp)
    80004c3c:	69a2                	ld	s3,8(sp)
    80004c3e:	6a02                	ld	s4,0(sp)
    80004c40:	6145                	addi	sp,sp,48
    80004c42:	8082                	ret
  return -1;
    80004c44:	557d                	li	a0,-1
    80004c46:	b7fd                	j	80004c34 <pipealloc+0xc6>

0000000080004c48 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c48:	1101                	addi	sp,sp,-32
    80004c4a:	ec06                	sd	ra,24(sp)
    80004c4c:	e822                	sd	s0,16(sp)
    80004c4e:	e426                	sd	s1,8(sp)
    80004c50:	e04a                	sd	s2,0(sp)
    80004c52:	1000                	addi	s0,sp,32
    80004c54:	84aa                	mv	s1,a0
    80004c56:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	fa4080e7          	jalr	-92(ra) # 80000bfc <acquire>
  if(writable){
    80004c60:	02090d63          	beqz	s2,80004c9a <pipeclose+0x52>
    pi->writeopen = 0;
    80004c64:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c68:	21848513          	addi	a0,s1,536
    80004c6c:	ffffe097          	auipc	ra,0xffffe
    80004c70:	a48080e7          	jalr	-1464(ra) # 800026b4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c74:	2204b783          	ld	a5,544(s1)
    80004c78:	eb95                	bnez	a5,80004cac <pipeclose+0x64>
    release(&pi->lock);
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	034080e7          	jalr	52(ra) # 80000cb0 <release>
    kfree((char*)pi);
    80004c84:	8526                	mv	a0,s1
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	d8a080e7          	jalr	-630(ra) # 80000a10 <kfree>
  } else
    release(&pi->lock);
}
    80004c8e:	60e2                	ld	ra,24(sp)
    80004c90:	6442                	ld	s0,16(sp)
    80004c92:	64a2                	ld	s1,8(sp)
    80004c94:	6902                	ld	s2,0(sp)
    80004c96:	6105                	addi	sp,sp,32
    80004c98:	8082                	ret
    pi->readopen = 0;
    80004c9a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c9e:	21c48513          	addi	a0,s1,540
    80004ca2:	ffffe097          	auipc	ra,0xffffe
    80004ca6:	a12080e7          	jalr	-1518(ra) # 800026b4 <wakeup>
    80004caa:	b7e9                	j	80004c74 <pipeclose+0x2c>
    release(&pi->lock);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	002080e7          	jalr	2(ra) # 80000cb0 <release>
}
    80004cb6:	bfe1                	j	80004c8e <pipeclose+0x46>

0000000080004cb8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cb8:	711d                	addi	sp,sp,-96
    80004cba:	ec86                	sd	ra,88(sp)
    80004cbc:	e8a2                	sd	s0,80(sp)
    80004cbe:	e4a6                	sd	s1,72(sp)
    80004cc0:	e0ca                	sd	s2,64(sp)
    80004cc2:	fc4e                	sd	s3,56(sp)
    80004cc4:	f852                	sd	s4,48(sp)
    80004cc6:	f456                	sd	s5,40(sp)
    80004cc8:	f05a                	sd	s6,32(sp)
    80004cca:	ec5e                	sd	s7,24(sp)
    80004ccc:	e862                	sd	s8,16(sp)
    80004cce:	1080                	addi	s0,sp,96
    80004cd0:	84aa                	mv	s1,a0
    80004cd2:	8b2e                	mv	s6,a1
    80004cd4:	8ab2                	mv	s5,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	e18080e7          	jalr	-488(ra) # 80001aee <myproc>
    80004cde:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ce0:	8526                	mv	a0,s1
    80004ce2:	ffffc097          	auipc	ra,0xffffc
    80004ce6:	f1a080e7          	jalr	-230(ra) # 80000bfc <acquire>
  for(i = 0; i < n; i++){
    80004cea:	09505763          	blez	s5,80004d78 <pipewrite+0xc0>
    80004cee:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004cf0:	21848a13          	addi	s4,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cf4:	21c48993          	addi	s3,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cf8:	5c7d                	li	s8,-1
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cfa:	2184a783          	lw	a5,536(s1)
    80004cfe:	21c4a703          	lw	a4,540(s1)
    80004d02:	2007879b          	addiw	a5,a5,512
    80004d06:	02f71b63          	bne	a4,a5,80004d3c <pipewrite+0x84>
      if(pi->readopen == 0 || pr->killed){
    80004d0a:	2204a783          	lw	a5,544(s1)
    80004d0e:	c3d1                	beqz	a5,80004d92 <pipewrite+0xda>
    80004d10:	03092783          	lw	a5,48(s2)
    80004d14:	efbd                	bnez	a5,80004d92 <pipewrite+0xda>
      wakeup(&pi->nread);
    80004d16:	8552                	mv	a0,s4
    80004d18:	ffffe097          	auipc	ra,0xffffe
    80004d1c:	99c080e7          	jalr	-1636(ra) # 800026b4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d20:	85a6                	mv	a1,s1
    80004d22:	854e                	mv	a0,s3
    80004d24:	ffffe097          	auipc	ra,0xffffe
    80004d28:	804080e7          	jalr	-2044(ra) # 80002528 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d2c:	2184a783          	lw	a5,536(s1)
    80004d30:	21c4a703          	lw	a4,540(s1)
    80004d34:	2007879b          	addiw	a5,a5,512
    80004d38:	fcf709e3          	beq	a4,a5,80004d0a <pipewrite+0x52>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d3c:	4685                	li	a3,1
    80004d3e:	865a                	mv	a2,s6
    80004d40:	faf40593          	addi	a1,s0,-81
    80004d44:	05093503          	ld	a0,80(s2)
    80004d48:	ffffd097          	auipc	ra,0xffffd
    80004d4c:	9ee080e7          	jalr	-1554(ra) # 80001736 <copyin>
    80004d50:	03850563          	beq	a0,s8,80004d7a <pipewrite+0xc2>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d54:	21c4a783          	lw	a5,540(s1)
    80004d58:	0017871b          	addiw	a4,a5,1
    80004d5c:	20e4ae23          	sw	a4,540(s1)
    80004d60:	1ff7f793          	andi	a5,a5,511
    80004d64:	97a6                	add	a5,a5,s1
    80004d66:	faf44703          	lbu	a4,-81(s0)
    80004d6a:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d6e:	2b85                	addiw	s7,s7,1
    80004d70:	0b05                	addi	s6,s6,1
    80004d72:	f97a94e3          	bne	s5,s7,80004cfa <pipewrite+0x42>
    80004d76:	a011                	j	80004d7a <pipewrite+0xc2>
    80004d78:	4b81                	li	s7,0
  }
  wakeup(&pi->nread);
    80004d7a:	21848513          	addi	a0,s1,536
    80004d7e:	ffffe097          	auipc	ra,0xffffe
    80004d82:	936080e7          	jalr	-1738(ra) # 800026b4 <wakeup>
  release(&pi->lock);
    80004d86:	8526                	mv	a0,s1
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	f28080e7          	jalr	-216(ra) # 80000cb0 <release>
  return i;
    80004d90:	a039                	j	80004d9e <pipewrite+0xe6>
        release(&pi->lock);
    80004d92:	8526                	mv	a0,s1
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	f1c080e7          	jalr	-228(ra) # 80000cb0 <release>
        return -1;
    80004d9c:	5bfd                	li	s7,-1
}
    80004d9e:	855e                	mv	a0,s7
    80004da0:	60e6                	ld	ra,88(sp)
    80004da2:	6446                	ld	s0,80(sp)
    80004da4:	64a6                	ld	s1,72(sp)
    80004da6:	6906                	ld	s2,64(sp)
    80004da8:	79e2                	ld	s3,56(sp)
    80004daa:	7a42                	ld	s4,48(sp)
    80004dac:	7aa2                	ld	s5,40(sp)
    80004dae:	7b02                	ld	s6,32(sp)
    80004db0:	6be2                	ld	s7,24(sp)
    80004db2:	6c42                	ld	s8,16(sp)
    80004db4:	6125                	addi	sp,sp,96
    80004db6:	8082                	ret

0000000080004db8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004db8:	715d                	addi	sp,sp,-80
    80004dba:	e486                	sd	ra,72(sp)
    80004dbc:	e0a2                	sd	s0,64(sp)
    80004dbe:	fc26                	sd	s1,56(sp)
    80004dc0:	f84a                	sd	s2,48(sp)
    80004dc2:	f44e                	sd	s3,40(sp)
    80004dc4:	f052                	sd	s4,32(sp)
    80004dc6:	ec56                	sd	s5,24(sp)
    80004dc8:	e85a                	sd	s6,16(sp)
    80004dca:	0880                	addi	s0,sp,80
    80004dcc:	84aa                	mv	s1,a0
    80004dce:	892e                	mv	s2,a1
    80004dd0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004dd2:	ffffd097          	auipc	ra,0xffffd
    80004dd6:	d1c080e7          	jalr	-740(ra) # 80001aee <myproc>
    80004dda:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ddc:	8526                	mv	a0,s1
    80004dde:	ffffc097          	auipc	ra,0xffffc
    80004de2:	e1e080e7          	jalr	-482(ra) # 80000bfc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004de6:	2184a703          	lw	a4,536(s1)
    80004dea:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dee:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df2:	02f71463          	bne	a4,a5,80004e1a <piperead+0x62>
    80004df6:	2244a783          	lw	a5,548(s1)
    80004dfa:	c385                	beqz	a5,80004e1a <piperead+0x62>
    if(pr->killed){
    80004dfc:	030a2783          	lw	a5,48(s4)
    80004e00:	ebc1                	bnez	a5,80004e90 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e02:	85a6                	mv	a1,s1
    80004e04:	854e                	mv	a0,s3
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	722080e7          	jalr	1826(ra) # 80002528 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e0e:	2184a703          	lw	a4,536(s1)
    80004e12:	21c4a783          	lw	a5,540(s1)
    80004e16:	fef700e3          	beq	a4,a5,80004df6 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e1a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e1c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e1e:	05505363          	blez	s5,80004e64 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e22:	2184a783          	lw	a5,536(s1)
    80004e26:	21c4a703          	lw	a4,540(s1)
    80004e2a:	02f70d63          	beq	a4,a5,80004e64 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e2e:	0017871b          	addiw	a4,a5,1
    80004e32:	20e4ac23          	sw	a4,536(s1)
    80004e36:	1ff7f793          	andi	a5,a5,511
    80004e3a:	97a6                	add	a5,a5,s1
    80004e3c:	0187c783          	lbu	a5,24(a5)
    80004e40:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e44:	4685                	li	a3,1
    80004e46:	fbf40613          	addi	a2,s0,-65
    80004e4a:	85ca                	mv	a1,s2
    80004e4c:	050a3503          	ld	a0,80(s4)
    80004e50:	ffffd097          	auipc	ra,0xffffd
    80004e54:	85a080e7          	jalr	-1958(ra) # 800016aa <copyout>
    80004e58:	01650663          	beq	a0,s6,80004e64 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e5c:	2985                	addiw	s3,s3,1
    80004e5e:	0905                	addi	s2,s2,1
    80004e60:	fd3a91e3          	bne	s5,s3,80004e22 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e64:	21c48513          	addi	a0,s1,540
    80004e68:	ffffe097          	auipc	ra,0xffffe
    80004e6c:	84c080e7          	jalr	-1972(ra) # 800026b4 <wakeup>
  release(&pi->lock);
    80004e70:	8526                	mv	a0,s1
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	e3e080e7          	jalr	-450(ra) # 80000cb0 <release>
  return i;
}
    80004e7a:	854e                	mv	a0,s3
    80004e7c:	60a6                	ld	ra,72(sp)
    80004e7e:	6406                	ld	s0,64(sp)
    80004e80:	74e2                	ld	s1,56(sp)
    80004e82:	7942                	ld	s2,48(sp)
    80004e84:	79a2                	ld	s3,40(sp)
    80004e86:	7a02                	ld	s4,32(sp)
    80004e88:	6ae2                	ld	s5,24(sp)
    80004e8a:	6b42                	ld	s6,16(sp)
    80004e8c:	6161                	addi	sp,sp,80
    80004e8e:	8082                	ret
      release(&pi->lock);
    80004e90:	8526                	mv	a0,s1
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	e1e080e7          	jalr	-482(ra) # 80000cb0 <release>
      return -1;
    80004e9a:	59fd                	li	s3,-1
    80004e9c:	bff9                	j	80004e7a <piperead+0xc2>

0000000080004e9e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e9e:	de010113          	addi	sp,sp,-544
    80004ea2:	20113c23          	sd	ra,536(sp)
    80004ea6:	20813823          	sd	s0,528(sp)
    80004eaa:	20913423          	sd	s1,520(sp)
    80004eae:	21213023          	sd	s2,512(sp)
    80004eb2:	ffce                	sd	s3,504(sp)
    80004eb4:	fbd2                	sd	s4,496(sp)
    80004eb6:	f7d6                	sd	s5,488(sp)
    80004eb8:	f3da                	sd	s6,480(sp)
    80004eba:	efde                	sd	s7,472(sp)
    80004ebc:	ebe2                	sd	s8,464(sp)
    80004ebe:	e7e6                	sd	s9,456(sp)
    80004ec0:	e3ea                	sd	s10,448(sp)
    80004ec2:	ff6e                	sd	s11,440(sp)
    80004ec4:	1400                	addi	s0,sp,544
    80004ec6:	892a                	mv	s2,a0
    80004ec8:	dea43423          	sd	a0,-536(s0)
    80004ecc:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ed0:	ffffd097          	auipc	ra,0xffffd
    80004ed4:	c1e080e7          	jalr	-994(ra) # 80001aee <myproc>
    80004ed8:	84aa                	mv	s1,a0

  begin_op();
    80004eda:	fffff097          	auipc	ra,0xfffff
    80004ede:	46c080e7          	jalr	1132(ra) # 80004346 <begin_op>

  if((ip = namei(path)) == 0){
    80004ee2:	854a                	mv	a0,s2
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	252080e7          	jalr	594(ra) # 80004136 <namei>
    80004eec:	c93d                	beqz	a0,80004f62 <exec+0xc4>
    80004eee:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	a96080e7          	jalr	-1386(ra) # 80003986 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ef8:	04000713          	li	a4,64
    80004efc:	4681                	li	a3,0
    80004efe:	e4840613          	addi	a2,s0,-440
    80004f02:	4581                	li	a1,0
    80004f04:	8556                	mv	a0,s5
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	d34080e7          	jalr	-716(ra) # 80003c3a <readi>
    80004f0e:	04000793          	li	a5,64
    80004f12:	00f51a63          	bne	a0,a5,80004f26 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f16:	e4842703          	lw	a4,-440(s0)
    80004f1a:	464c47b7          	lui	a5,0x464c4
    80004f1e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f22:	04f70663          	beq	a4,a5,80004f6e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f26:	8556                	mv	a0,s5
    80004f28:	fffff097          	auipc	ra,0xfffff
    80004f2c:	cc0080e7          	jalr	-832(ra) # 80003be8 <iunlockput>
    end_op();
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	496080e7          	jalr	1174(ra) # 800043c6 <end_op>
  }
  return -1;
    80004f38:	557d                	li	a0,-1
}
    80004f3a:	21813083          	ld	ra,536(sp)
    80004f3e:	21013403          	ld	s0,528(sp)
    80004f42:	20813483          	ld	s1,520(sp)
    80004f46:	20013903          	ld	s2,512(sp)
    80004f4a:	79fe                	ld	s3,504(sp)
    80004f4c:	7a5e                	ld	s4,496(sp)
    80004f4e:	7abe                	ld	s5,488(sp)
    80004f50:	7b1e                	ld	s6,480(sp)
    80004f52:	6bfe                	ld	s7,472(sp)
    80004f54:	6c5e                	ld	s8,464(sp)
    80004f56:	6cbe                	ld	s9,456(sp)
    80004f58:	6d1e                	ld	s10,448(sp)
    80004f5a:	7dfa                	ld	s11,440(sp)
    80004f5c:	22010113          	addi	sp,sp,544
    80004f60:	8082                	ret
    end_op();
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	464080e7          	jalr	1124(ra) # 800043c6 <end_op>
    return -1;
    80004f6a:	557d                	li	a0,-1
    80004f6c:	b7f9                	j	80004f3a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f6e:	8526                	mv	a0,s1
    80004f70:	ffffd097          	auipc	ra,0xffffd
    80004f74:	c44080e7          	jalr	-956(ra) # 80001bb4 <proc_pagetable>
    80004f78:	8b2a                	mv	s6,a0
    80004f7a:	d555                	beqz	a0,80004f26 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f7c:	e6842783          	lw	a5,-408(s0)
    80004f80:	e8045703          	lhu	a4,-384(s0)
    80004f84:	c735                	beqz	a4,80004ff0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f86:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f88:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004f8c:	6a05                	lui	s4,0x1
    80004f8e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004f92:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004f96:	6d85                	lui	s11,0x1
    80004f98:	7d7d                	lui	s10,0xfffff
    80004f9a:	ac1d                	j	800051d0 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f9c:	00003517          	auipc	a0,0x3
    80004fa0:	76c50513          	addi	a0,a0,1900 # 80008708 <syscalls+0x290>
    80004fa4:	ffffb097          	auipc	ra,0xffffb
    80004fa8:	59c080e7          	jalr	1436(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fac:	874a                	mv	a4,s2
    80004fae:	009c86bb          	addw	a3,s9,s1
    80004fb2:	4581                	li	a1,0
    80004fb4:	8556                	mv	a0,s5
    80004fb6:	fffff097          	auipc	ra,0xfffff
    80004fba:	c84080e7          	jalr	-892(ra) # 80003c3a <readi>
    80004fbe:	2501                	sext.w	a0,a0
    80004fc0:	1aa91863          	bne	s2,a0,80005170 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004fc4:	009d84bb          	addw	s1,s11,s1
    80004fc8:	013d09bb          	addw	s3,s10,s3
    80004fcc:	1f74f263          	bgeu	s1,s7,800051b0 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004fd0:	02049593          	slli	a1,s1,0x20
    80004fd4:	9181                	srli	a1,a1,0x20
    80004fd6:	95e2                	add	a1,a1,s8
    80004fd8:	855a                	mv	a0,s6
    80004fda:	ffffc097          	auipc	ra,0xffffc
    80004fde:	09c080e7          	jalr	156(ra) # 80001076 <walkaddr>
    80004fe2:	862a                	mv	a2,a0
    if(pa == 0)
    80004fe4:	dd45                	beqz	a0,80004f9c <exec+0xfe>
      n = PGSIZE;
    80004fe6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004fe8:	fd49f2e3          	bgeu	s3,s4,80004fac <exec+0x10e>
      n = sz - i;
    80004fec:	894e                	mv	s2,s3
    80004fee:	bf7d                	j	80004fac <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ff0:	4481                	li	s1,0
  iunlockput(ip);
    80004ff2:	8556                	mv	a0,s5
    80004ff4:	fffff097          	auipc	ra,0xfffff
    80004ff8:	bf4080e7          	jalr	-1036(ra) # 80003be8 <iunlockput>
  end_op();
    80004ffc:	fffff097          	auipc	ra,0xfffff
    80005000:	3ca080e7          	jalr	970(ra) # 800043c6 <end_op>
  p = myproc();
    80005004:	ffffd097          	auipc	ra,0xffffd
    80005008:	aea080e7          	jalr	-1302(ra) # 80001aee <myproc>
    8000500c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000500e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005012:	6785                	lui	a5,0x1
    80005014:	17fd                	addi	a5,a5,-1
    80005016:	94be                	add	s1,s1,a5
    80005018:	77fd                	lui	a5,0xfffff
    8000501a:	8fe5                	and	a5,a5,s1
    8000501c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005020:	6609                	lui	a2,0x2
    80005022:	963e                	add	a2,a2,a5
    80005024:	85be                	mv	a1,a5
    80005026:	855a                	mv	a0,s6
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	432080e7          	jalr	1074(ra) # 8000145a <uvmalloc>
    80005030:	8c2a                	mv	s8,a0
  ip = 0;
    80005032:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005034:	12050e63          	beqz	a0,80005170 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005038:	75f9                	lui	a1,0xffffe
    8000503a:	95aa                	add	a1,a1,a0
    8000503c:	855a                	mv	a0,s6
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	63a080e7          	jalr	1594(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    80005046:	7afd                	lui	s5,0xfffff
    80005048:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000504a:	df043783          	ld	a5,-528(s0)
    8000504e:	6388                	ld	a0,0(a5)
    80005050:	c925                	beqz	a0,800050c0 <exec+0x222>
    80005052:	e8840993          	addi	s3,s0,-376
    80005056:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000505a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000505c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	e1e080e7          	jalr	-482(ra) # 80000e7c <strlen>
    80005066:	0015079b          	addiw	a5,a0,1
    8000506a:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000506e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005072:	13596363          	bltu	s2,s5,80005198 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005076:	df043d83          	ld	s11,-528(s0)
    8000507a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000507e:	8552                	mv	a0,s4
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	dfc080e7          	jalr	-516(ra) # 80000e7c <strlen>
    80005088:	0015069b          	addiw	a3,a0,1
    8000508c:	8652                	mv	a2,s4
    8000508e:	85ca                	mv	a1,s2
    80005090:	855a                	mv	a0,s6
    80005092:	ffffc097          	auipc	ra,0xffffc
    80005096:	618080e7          	jalr	1560(ra) # 800016aa <copyout>
    8000509a:	10054363          	bltz	a0,800051a0 <exec+0x302>
    ustack[argc] = sp;
    8000509e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050a2:	0485                	addi	s1,s1,1
    800050a4:	008d8793          	addi	a5,s11,8
    800050a8:	def43823          	sd	a5,-528(s0)
    800050ac:	008db503          	ld	a0,8(s11)
    800050b0:	c911                	beqz	a0,800050c4 <exec+0x226>
    if(argc >= MAXARG)
    800050b2:	09a1                	addi	s3,s3,8
    800050b4:	fb3c95e3          	bne	s9,s3,8000505e <exec+0x1c0>
  sz = sz1;
    800050b8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050bc:	4a81                	li	s5,0
    800050be:	a84d                	j	80005170 <exec+0x2d2>
  sp = sz;
    800050c0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050c2:	4481                	li	s1,0
  ustack[argc] = 0;
    800050c4:	00349793          	slli	a5,s1,0x3
    800050c8:	f9040713          	addi	a4,s0,-112
    800050cc:	97ba                	add	a5,a5,a4
    800050ce:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    800050d2:	00148693          	addi	a3,s1,1
    800050d6:	068e                	slli	a3,a3,0x3
    800050d8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050dc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050e0:	01597663          	bgeu	s2,s5,800050ec <exec+0x24e>
  sz = sz1;
    800050e4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050e8:	4a81                	li	s5,0
    800050ea:	a059                	j	80005170 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050ec:	e8840613          	addi	a2,s0,-376
    800050f0:	85ca                	mv	a1,s2
    800050f2:	855a                	mv	a0,s6
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	5b6080e7          	jalr	1462(ra) # 800016aa <copyout>
    800050fc:	0a054663          	bltz	a0,800051a8 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005100:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005104:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005108:	de843783          	ld	a5,-536(s0)
    8000510c:	0007c703          	lbu	a4,0(a5)
    80005110:	cf11                	beqz	a4,8000512c <exec+0x28e>
    80005112:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005114:	02f00693          	li	a3,47
    80005118:	a039                	j	80005126 <exec+0x288>
      last = s+1;
    8000511a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    8000511e:	0785                	addi	a5,a5,1
    80005120:	fff7c703          	lbu	a4,-1(a5)
    80005124:	c701                	beqz	a4,8000512c <exec+0x28e>
    if(*s == '/')
    80005126:	fed71ce3          	bne	a4,a3,8000511e <exec+0x280>
    8000512a:	bfc5                	j	8000511a <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000512c:	4641                	li	a2,16
    8000512e:	de843583          	ld	a1,-536(s0)
    80005132:	158b8513          	addi	a0,s7,344
    80005136:	ffffc097          	auipc	ra,0xffffc
    8000513a:	d14080e7          	jalr	-748(ra) # 80000e4a <safestrcpy>
  oldpagetable = p->pagetable;
    8000513e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005142:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005146:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000514a:	058bb783          	ld	a5,88(s7)
    8000514e:	e6043703          	ld	a4,-416(s0)
    80005152:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005154:	058bb783          	ld	a5,88(s7)
    80005158:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000515c:	85ea                	mv	a1,s10
    8000515e:	ffffd097          	auipc	ra,0xffffd
    80005162:	af2080e7          	jalr	-1294(ra) # 80001c50 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005166:	0004851b          	sext.w	a0,s1
    8000516a:	bbc1                	j	80004f3a <exec+0x9c>
    8000516c:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005170:	df843583          	ld	a1,-520(s0)
    80005174:	855a                	mv	a0,s6
    80005176:	ffffd097          	auipc	ra,0xffffd
    8000517a:	ada080e7          	jalr	-1318(ra) # 80001c50 <proc_freepagetable>
  if(ip){
    8000517e:	da0a94e3          	bnez	s5,80004f26 <exec+0x88>
  return -1;
    80005182:	557d                	li	a0,-1
    80005184:	bb5d                	j	80004f3a <exec+0x9c>
    80005186:	de943c23          	sd	s1,-520(s0)
    8000518a:	b7dd                	j	80005170 <exec+0x2d2>
    8000518c:	de943c23          	sd	s1,-520(s0)
    80005190:	b7c5                	j	80005170 <exec+0x2d2>
    80005192:	de943c23          	sd	s1,-520(s0)
    80005196:	bfe9                	j	80005170 <exec+0x2d2>
  sz = sz1;
    80005198:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000519c:	4a81                	li	s5,0
    8000519e:	bfc9                	j	80005170 <exec+0x2d2>
  sz = sz1;
    800051a0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051a4:	4a81                	li	s5,0
    800051a6:	b7e9                	j	80005170 <exec+0x2d2>
  sz = sz1;
    800051a8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051ac:	4a81                	li	s5,0
    800051ae:	b7c9                	j	80005170 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051b0:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051b4:	e0843783          	ld	a5,-504(s0)
    800051b8:	0017869b          	addiw	a3,a5,1
    800051bc:	e0d43423          	sd	a3,-504(s0)
    800051c0:	e0043783          	ld	a5,-512(s0)
    800051c4:	0387879b          	addiw	a5,a5,56
    800051c8:	e8045703          	lhu	a4,-384(s0)
    800051cc:	e2e6d3e3          	bge	a3,a4,80004ff2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051d0:	2781                	sext.w	a5,a5
    800051d2:	e0f43023          	sd	a5,-512(s0)
    800051d6:	03800713          	li	a4,56
    800051da:	86be                	mv	a3,a5
    800051dc:	e1040613          	addi	a2,s0,-496
    800051e0:	4581                	li	a1,0
    800051e2:	8556                	mv	a0,s5
    800051e4:	fffff097          	auipc	ra,0xfffff
    800051e8:	a56080e7          	jalr	-1450(ra) # 80003c3a <readi>
    800051ec:	03800793          	li	a5,56
    800051f0:	f6f51ee3          	bne	a0,a5,8000516c <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    800051f4:	e1042783          	lw	a5,-496(s0)
    800051f8:	4705                	li	a4,1
    800051fa:	fae79de3          	bne	a5,a4,800051b4 <exec+0x316>
    if(ph.memsz < ph.filesz)
    800051fe:	e3843603          	ld	a2,-456(s0)
    80005202:	e3043783          	ld	a5,-464(s0)
    80005206:	f8f660e3          	bltu	a2,a5,80005186 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000520a:	e2043783          	ld	a5,-480(s0)
    8000520e:	963e                	add	a2,a2,a5
    80005210:	f6f66ee3          	bltu	a2,a5,8000518c <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005214:	85a6                	mv	a1,s1
    80005216:	855a                	mv	a0,s6
    80005218:	ffffc097          	auipc	ra,0xffffc
    8000521c:	242080e7          	jalr	578(ra) # 8000145a <uvmalloc>
    80005220:	dea43c23          	sd	a0,-520(s0)
    80005224:	d53d                	beqz	a0,80005192 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005226:	e2043c03          	ld	s8,-480(s0)
    8000522a:	de043783          	ld	a5,-544(s0)
    8000522e:	00fc77b3          	and	a5,s8,a5
    80005232:	ff9d                	bnez	a5,80005170 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005234:	e1842c83          	lw	s9,-488(s0)
    80005238:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000523c:	f60b8ae3          	beqz	s7,800051b0 <exec+0x312>
    80005240:	89de                	mv	s3,s7
    80005242:	4481                	li	s1,0
    80005244:	b371                	j	80004fd0 <exec+0x132>

0000000080005246 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005246:	7179                	addi	sp,sp,-48
    80005248:	f406                	sd	ra,40(sp)
    8000524a:	f022                	sd	s0,32(sp)
    8000524c:	ec26                	sd	s1,24(sp)
    8000524e:	e84a                	sd	s2,16(sp)
    80005250:	1800                	addi	s0,sp,48
    80005252:	892e                	mv	s2,a1
    80005254:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005256:	fdc40593          	addi	a1,s0,-36
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	baa080e7          	jalr	-1110(ra) # 80002e04 <argint>
    80005262:	04054063          	bltz	a0,800052a2 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005266:	fdc42703          	lw	a4,-36(s0)
    8000526a:	47bd                	li	a5,15
    8000526c:	02e7ed63          	bltu	a5,a4,800052a6 <argfd+0x60>
    80005270:	ffffd097          	auipc	ra,0xffffd
    80005274:	87e080e7          	jalr	-1922(ra) # 80001aee <myproc>
    80005278:	fdc42703          	lw	a4,-36(s0)
    8000527c:	01a70793          	addi	a5,a4,26
    80005280:	078e                	slli	a5,a5,0x3
    80005282:	953e                	add	a0,a0,a5
    80005284:	611c                	ld	a5,0(a0)
    80005286:	c395                	beqz	a5,800052aa <argfd+0x64>
    return -1;
  if(pfd)
    80005288:	00090463          	beqz	s2,80005290 <argfd+0x4a>
    *pfd = fd;
    8000528c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005290:	4501                	li	a0,0
  if(pf)
    80005292:	c091                	beqz	s1,80005296 <argfd+0x50>
    *pf = f;
    80005294:	e09c                	sd	a5,0(s1)
}
    80005296:	70a2                	ld	ra,40(sp)
    80005298:	7402                	ld	s0,32(sp)
    8000529a:	64e2                	ld	s1,24(sp)
    8000529c:	6942                	ld	s2,16(sp)
    8000529e:	6145                	addi	sp,sp,48
    800052a0:	8082                	ret
    return -1;
    800052a2:	557d                	li	a0,-1
    800052a4:	bfcd                	j	80005296 <argfd+0x50>
    return -1;
    800052a6:	557d                	li	a0,-1
    800052a8:	b7fd                	j	80005296 <argfd+0x50>
    800052aa:	557d                	li	a0,-1
    800052ac:	b7ed                	j	80005296 <argfd+0x50>

00000000800052ae <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052ae:	1101                	addi	sp,sp,-32
    800052b0:	ec06                	sd	ra,24(sp)
    800052b2:	e822                	sd	s0,16(sp)
    800052b4:	e426                	sd	s1,8(sp)
    800052b6:	1000                	addi	s0,sp,32
    800052b8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052ba:	ffffd097          	auipc	ra,0xffffd
    800052be:	834080e7          	jalr	-1996(ra) # 80001aee <myproc>
    800052c2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052c4:	0d050793          	addi	a5,a0,208
    800052c8:	4501                	li	a0,0
    800052ca:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052cc:	6398                	ld	a4,0(a5)
    800052ce:	cb19                	beqz	a4,800052e4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052d0:	2505                	addiw	a0,a0,1
    800052d2:	07a1                	addi	a5,a5,8
    800052d4:	fed51ce3          	bne	a0,a3,800052cc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052d8:	557d                	li	a0,-1
}
    800052da:	60e2                	ld	ra,24(sp)
    800052dc:	6442                	ld	s0,16(sp)
    800052de:	64a2                	ld	s1,8(sp)
    800052e0:	6105                	addi	sp,sp,32
    800052e2:	8082                	ret
      p->ofile[fd] = f;
    800052e4:	01a50793          	addi	a5,a0,26
    800052e8:	078e                	slli	a5,a5,0x3
    800052ea:	963e                	add	a2,a2,a5
    800052ec:	e204                	sd	s1,0(a2)
      return fd;
    800052ee:	b7f5                	j	800052da <fdalloc+0x2c>

00000000800052f0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052f0:	715d                	addi	sp,sp,-80
    800052f2:	e486                	sd	ra,72(sp)
    800052f4:	e0a2                	sd	s0,64(sp)
    800052f6:	fc26                	sd	s1,56(sp)
    800052f8:	f84a                	sd	s2,48(sp)
    800052fa:	f44e                	sd	s3,40(sp)
    800052fc:	f052                	sd	s4,32(sp)
    800052fe:	ec56                	sd	s5,24(sp)
    80005300:	0880                	addi	s0,sp,80
    80005302:	89ae                	mv	s3,a1
    80005304:	8ab2                	mv	s5,a2
    80005306:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005308:	fb040593          	addi	a1,s0,-80
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	e48080e7          	jalr	-440(ra) # 80004154 <nameiparent>
    80005314:	892a                	mv	s2,a0
    80005316:	12050e63          	beqz	a0,80005452 <create+0x162>
    return 0;

  ilock(dp);
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	66c080e7          	jalr	1644(ra) # 80003986 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005322:	4601                	li	a2,0
    80005324:	fb040593          	addi	a1,s0,-80
    80005328:	854a                	mv	a0,s2
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	b3a080e7          	jalr	-1222(ra) # 80003e64 <dirlookup>
    80005332:	84aa                	mv	s1,a0
    80005334:	c921                	beqz	a0,80005384 <create+0x94>
    iunlockput(dp);
    80005336:	854a                	mv	a0,s2
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	8b0080e7          	jalr	-1872(ra) # 80003be8 <iunlockput>
    ilock(ip);
    80005340:	8526                	mv	a0,s1
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	644080e7          	jalr	1604(ra) # 80003986 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000534a:	2981                	sext.w	s3,s3
    8000534c:	4789                	li	a5,2
    8000534e:	02f99463          	bne	s3,a5,80005376 <create+0x86>
    80005352:	0444d783          	lhu	a5,68(s1)
    80005356:	37f9                	addiw	a5,a5,-2
    80005358:	17c2                	slli	a5,a5,0x30
    8000535a:	93c1                	srli	a5,a5,0x30
    8000535c:	4705                	li	a4,1
    8000535e:	00f76c63          	bltu	a4,a5,80005376 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005362:	8526                	mv	a0,s1
    80005364:	60a6                	ld	ra,72(sp)
    80005366:	6406                	ld	s0,64(sp)
    80005368:	74e2                	ld	s1,56(sp)
    8000536a:	7942                	ld	s2,48(sp)
    8000536c:	79a2                	ld	s3,40(sp)
    8000536e:	7a02                	ld	s4,32(sp)
    80005370:	6ae2                	ld	s5,24(sp)
    80005372:	6161                	addi	sp,sp,80
    80005374:	8082                	ret
    iunlockput(ip);
    80005376:	8526                	mv	a0,s1
    80005378:	fffff097          	auipc	ra,0xfffff
    8000537c:	870080e7          	jalr	-1936(ra) # 80003be8 <iunlockput>
    return 0;
    80005380:	4481                	li	s1,0
    80005382:	b7c5                	j	80005362 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005384:	85ce                	mv	a1,s3
    80005386:	00092503          	lw	a0,0(s2)
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	464080e7          	jalr	1124(ra) # 800037ee <ialloc>
    80005392:	84aa                	mv	s1,a0
    80005394:	c521                	beqz	a0,800053dc <create+0xec>
  ilock(ip);
    80005396:	ffffe097          	auipc	ra,0xffffe
    8000539a:	5f0080e7          	jalr	1520(ra) # 80003986 <ilock>
  ip->major = major;
    8000539e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800053a2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800053a6:	4a05                	li	s4,1
    800053a8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800053ac:	8526                	mv	a0,s1
    800053ae:	ffffe097          	auipc	ra,0xffffe
    800053b2:	50e080e7          	jalr	1294(ra) # 800038bc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053b6:	2981                	sext.w	s3,s3
    800053b8:	03498a63          	beq	s3,s4,800053ec <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800053bc:	40d0                	lw	a2,4(s1)
    800053be:	fb040593          	addi	a1,s0,-80
    800053c2:	854a                	mv	a0,s2
    800053c4:	fffff097          	auipc	ra,0xfffff
    800053c8:	cb0080e7          	jalr	-848(ra) # 80004074 <dirlink>
    800053cc:	06054b63          	bltz	a0,80005442 <create+0x152>
  iunlockput(dp);
    800053d0:	854a                	mv	a0,s2
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	816080e7          	jalr	-2026(ra) # 80003be8 <iunlockput>
  return ip;
    800053da:	b761                	j	80005362 <create+0x72>
    panic("create: ialloc");
    800053dc:	00003517          	auipc	a0,0x3
    800053e0:	34c50513          	addi	a0,a0,844 # 80008728 <syscalls+0x2b0>
    800053e4:	ffffb097          	auipc	ra,0xffffb
    800053e8:	15c080e7          	jalr	348(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    800053ec:	04a95783          	lhu	a5,74(s2)
    800053f0:	2785                	addiw	a5,a5,1
    800053f2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053f6:	854a                	mv	a0,s2
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	4c4080e7          	jalr	1220(ra) # 800038bc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005400:	40d0                	lw	a2,4(s1)
    80005402:	00003597          	auipc	a1,0x3
    80005406:	33658593          	addi	a1,a1,822 # 80008738 <syscalls+0x2c0>
    8000540a:	8526                	mv	a0,s1
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	c68080e7          	jalr	-920(ra) # 80004074 <dirlink>
    80005414:	00054f63          	bltz	a0,80005432 <create+0x142>
    80005418:	00492603          	lw	a2,4(s2)
    8000541c:	00003597          	auipc	a1,0x3
    80005420:	32458593          	addi	a1,a1,804 # 80008740 <syscalls+0x2c8>
    80005424:	8526                	mv	a0,s1
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	c4e080e7          	jalr	-946(ra) # 80004074 <dirlink>
    8000542e:	f80557e3          	bgez	a0,800053bc <create+0xcc>
      panic("create dots");
    80005432:	00003517          	auipc	a0,0x3
    80005436:	31650513          	addi	a0,a0,790 # 80008748 <syscalls+0x2d0>
    8000543a:	ffffb097          	auipc	ra,0xffffb
    8000543e:	106080e7          	jalr	262(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005442:	00003517          	auipc	a0,0x3
    80005446:	31650513          	addi	a0,a0,790 # 80008758 <syscalls+0x2e0>
    8000544a:	ffffb097          	auipc	ra,0xffffb
    8000544e:	0f6080e7          	jalr	246(ra) # 80000540 <panic>
    return 0;
    80005452:	84aa                	mv	s1,a0
    80005454:	b739                	j	80005362 <create+0x72>

0000000080005456 <sys_dup>:
{
    80005456:	7179                	addi	sp,sp,-48
    80005458:	f406                	sd	ra,40(sp)
    8000545a:	f022                	sd	s0,32(sp)
    8000545c:	ec26                	sd	s1,24(sp)
    8000545e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005460:	fd840613          	addi	a2,s0,-40
    80005464:	4581                	li	a1,0
    80005466:	4501                	li	a0,0
    80005468:	00000097          	auipc	ra,0x0
    8000546c:	dde080e7          	jalr	-546(ra) # 80005246 <argfd>
    return -1;
    80005470:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005472:	02054363          	bltz	a0,80005498 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005476:	fd843503          	ld	a0,-40(s0)
    8000547a:	00000097          	auipc	ra,0x0
    8000547e:	e34080e7          	jalr	-460(ra) # 800052ae <fdalloc>
    80005482:	84aa                	mv	s1,a0
    return -1;
    80005484:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005486:	00054963          	bltz	a0,80005498 <sys_dup+0x42>
  filedup(f);
    8000548a:	fd843503          	ld	a0,-40(s0)
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	338080e7          	jalr	824(ra) # 800047c6 <filedup>
  return fd;
    80005496:	87a6                	mv	a5,s1
}
    80005498:	853e                	mv	a0,a5
    8000549a:	70a2                	ld	ra,40(sp)
    8000549c:	7402                	ld	s0,32(sp)
    8000549e:	64e2                	ld	s1,24(sp)
    800054a0:	6145                	addi	sp,sp,48
    800054a2:	8082                	ret

00000000800054a4 <sys_read>:
{
    800054a4:	7179                	addi	sp,sp,-48
    800054a6:	f406                	sd	ra,40(sp)
    800054a8:	f022                	sd	s0,32(sp)
    800054aa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054ac:	fe840613          	addi	a2,s0,-24
    800054b0:	4581                	li	a1,0
    800054b2:	4501                	li	a0,0
    800054b4:	00000097          	auipc	ra,0x0
    800054b8:	d92080e7          	jalr	-622(ra) # 80005246 <argfd>
    return -1;
    800054bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054be:	04054163          	bltz	a0,80005500 <sys_read+0x5c>
    800054c2:	fe440593          	addi	a1,s0,-28
    800054c6:	4509                	li	a0,2
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	93c080e7          	jalr	-1732(ra) # 80002e04 <argint>
    return -1;
    800054d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d2:	02054763          	bltz	a0,80005500 <sys_read+0x5c>
    800054d6:	fd840593          	addi	a1,s0,-40
    800054da:	4505                	li	a0,1
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	94a080e7          	jalr	-1718(ra) # 80002e26 <argaddr>
    return -1;
    800054e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e6:	00054d63          	bltz	a0,80005500 <sys_read+0x5c>
  return fileread(f, p, n);
    800054ea:	fe442603          	lw	a2,-28(s0)
    800054ee:	fd843583          	ld	a1,-40(s0)
    800054f2:	fe843503          	ld	a0,-24(s0)
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	45c080e7          	jalr	1116(ra) # 80004952 <fileread>
    800054fe:	87aa                	mv	a5,a0
}
    80005500:	853e                	mv	a0,a5
    80005502:	70a2                	ld	ra,40(sp)
    80005504:	7402                	ld	s0,32(sp)
    80005506:	6145                	addi	sp,sp,48
    80005508:	8082                	ret

000000008000550a <sys_write>:
{
    8000550a:	7179                	addi	sp,sp,-48
    8000550c:	f406                	sd	ra,40(sp)
    8000550e:	f022                	sd	s0,32(sp)
    80005510:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005512:	fe840613          	addi	a2,s0,-24
    80005516:	4581                	li	a1,0
    80005518:	4501                	li	a0,0
    8000551a:	00000097          	auipc	ra,0x0
    8000551e:	d2c080e7          	jalr	-724(ra) # 80005246 <argfd>
    return -1;
    80005522:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005524:	04054163          	bltz	a0,80005566 <sys_write+0x5c>
    80005528:	fe440593          	addi	a1,s0,-28
    8000552c:	4509                	li	a0,2
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	8d6080e7          	jalr	-1834(ra) # 80002e04 <argint>
    return -1;
    80005536:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005538:	02054763          	bltz	a0,80005566 <sys_write+0x5c>
    8000553c:	fd840593          	addi	a1,s0,-40
    80005540:	4505                	li	a0,1
    80005542:	ffffe097          	auipc	ra,0xffffe
    80005546:	8e4080e7          	jalr	-1820(ra) # 80002e26 <argaddr>
    return -1;
    8000554a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000554c:	00054d63          	bltz	a0,80005566 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005550:	fe442603          	lw	a2,-28(s0)
    80005554:	fd843583          	ld	a1,-40(s0)
    80005558:	fe843503          	ld	a0,-24(s0)
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	4b8080e7          	jalr	1208(ra) # 80004a14 <filewrite>
    80005564:	87aa                	mv	a5,a0
}
    80005566:	853e                	mv	a0,a5
    80005568:	70a2                	ld	ra,40(sp)
    8000556a:	7402                	ld	s0,32(sp)
    8000556c:	6145                	addi	sp,sp,48
    8000556e:	8082                	ret

0000000080005570 <sys_close>:
{
    80005570:	1101                	addi	sp,sp,-32
    80005572:	ec06                	sd	ra,24(sp)
    80005574:	e822                	sd	s0,16(sp)
    80005576:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005578:	fe040613          	addi	a2,s0,-32
    8000557c:	fec40593          	addi	a1,s0,-20
    80005580:	4501                	li	a0,0
    80005582:	00000097          	auipc	ra,0x0
    80005586:	cc4080e7          	jalr	-828(ra) # 80005246 <argfd>
    return -1;
    8000558a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000558c:	02054463          	bltz	a0,800055b4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005590:	ffffc097          	auipc	ra,0xffffc
    80005594:	55e080e7          	jalr	1374(ra) # 80001aee <myproc>
    80005598:	fec42783          	lw	a5,-20(s0)
    8000559c:	07e9                	addi	a5,a5,26
    8000559e:	078e                	slli	a5,a5,0x3
    800055a0:	97aa                	add	a5,a5,a0
    800055a2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800055a6:	fe043503          	ld	a0,-32(s0)
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	26e080e7          	jalr	622(ra) # 80004818 <fileclose>
  return 0;
    800055b2:	4781                	li	a5,0
}
    800055b4:	853e                	mv	a0,a5
    800055b6:	60e2                	ld	ra,24(sp)
    800055b8:	6442                	ld	s0,16(sp)
    800055ba:	6105                	addi	sp,sp,32
    800055bc:	8082                	ret

00000000800055be <sys_fstat>:
{
    800055be:	1101                	addi	sp,sp,-32
    800055c0:	ec06                	sd	ra,24(sp)
    800055c2:	e822                	sd	s0,16(sp)
    800055c4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055c6:	fe840613          	addi	a2,s0,-24
    800055ca:	4581                	li	a1,0
    800055cc:	4501                	li	a0,0
    800055ce:	00000097          	auipc	ra,0x0
    800055d2:	c78080e7          	jalr	-904(ra) # 80005246 <argfd>
    return -1;
    800055d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055d8:	02054563          	bltz	a0,80005602 <sys_fstat+0x44>
    800055dc:	fe040593          	addi	a1,s0,-32
    800055e0:	4505                	li	a0,1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	844080e7          	jalr	-1980(ra) # 80002e26 <argaddr>
    return -1;
    800055ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ec:	00054b63          	bltz	a0,80005602 <sys_fstat+0x44>
  return filestat(f, st);
    800055f0:	fe043583          	ld	a1,-32(s0)
    800055f4:	fe843503          	ld	a0,-24(s0)
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	2e8080e7          	jalr	744(ra) # 800048e0 <filestat>
    80005600:	87aa                	mv	a5,a0
}
    80005602:	853e                	mv	a0,a5
    80005604:	60e2                	ld	ra,24(sp)
    80005606:	6442                	ld	s0,16(sp)
    80005608:	6105                	addi	sp,sp,32
    8000560a:	8082                	ret

000000008000560c <sys_link>:
{
    8000560c:	7169                	addi	sp,sp,-304
    8000560e:	f606                	sd	ra,296(sp)
    80005610:	f222                	sd	s0,288(sp)
    80005612:	ee26                	sd	s1,280(sp)
    80005614:	ea4a                	sd	s2,272(sp)
    80005616:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005618:	08000613          	li	a2,128
    8000561c:	ed040593          	addi	a1,s0,-304
    80005620:	4501                	li	a0,0
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	826080e7          	jalr	-2010(ra) # 80002e48 <argstr>
    return -1;
    8000562a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000562c:	10054e63          	bltz	a0,80005748 <sys_link+0x13c>
    80005630:	08000613          	li	a2,128
    80005634:	f5040593          	addi	a1,s0,-176
    80005638:	4505                	li	a0,1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	80e080e7          	jalr	-2034(ra) # 80002e48 <argstr>
    return -1;
    80005642:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005644:	10054263          	bltz	a0,80005748 <sys_link+0x13c>
  begin_op();
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	cfe080e7          	jalr	-770(ra) # 80004346 <begin_op>
  if((ip = namei(old)) == 0){
    80005650:	ed040513          	addi	a0,s0,-304
    80005654:	fffff097          	auipc	ra,0xfffff
    80005658:	ae2080e7          	jalr	-1310(ra) # 80004136 <namei>
    8000565c:	84aa                	mv	s1,a0
    8000565e:	c551                	beqz	a0,800056ea <sys_link+0xde>
  ilock(ip);
    80005660:	ffffe097          	auipc	ra,0xffffe
    80005664:	326080e7          	jalr	806(ra) # 80003986 <ilock>
  if(ip->type == T_DIR){
    80005668:	04449703          	lh	a4,68(s1)
    8000566c:	4785                	li	a5,1
    8000566e:	08f70463          	beq	a4,a5,800056f6 <sys_link+0xea>
  ip->nlink++;
    80005672:	04a4d783          	lhu	a5,74(s1)
    80005676:	2785                	addiw	a5,a5,1
    80005678:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	23e080e7          	jalr	574(ra) # 800038bc <iupdate>
  iunlock(ip);
    80005686:	8526                	mv	a0,s1
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	3c0080e7          	jalr	960(ra) # 80003a48 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005690:	fd040593          	addi	a1,s0,-48
    80005694:	f5040513          	addi	a0,s0,-176
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	abc080e7          	jalr	-1348(ra) # 80004154 <nameiparent>
    800056a0:	892a                	mv	s2,a0
    800056a2:	c935                	beqz	a0,80005716 <sys_link+0x10a>
  ilock(dp);
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	2e2080e7          	jalr	738(ra) # 80003986 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056ac:	00092703          	lw	a4,0(s2)
    800056b0:	409c                	lw	a5,0(s1)
    800056b2:	04f71d63          	bne	a4,a5,8000570c <sys_link+0x100>
    800056b6:	40d0                	lw	a2,4(s1)
    800056b8:	fd040593          	addi	a1,s0,-48
    800056bc:	854a                	mv	a0,s2
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	9b6080e7          	jalr	-1610(ra) # 80004074 <dirlink>
    800056c6:	04054363          	bltz	a0,8000570c <sys_link+0x100>
  iunlockput(dp);
    800056ca:	854a                	mv	a0,s2
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	51c080e7          	jalr	1308(ra) # 80003be8 <iunlockput>
  iput(ip);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	46a080e7          	jalr	1130(ra) # 80003b40 <iput>
  end_op();
    800056de:	fffff097          	auipc	ra,0xfffff
    800056e2:	ce8080e7          	jalr	-792(ra) # 800043c6 <end_op>
  return 0;
    800056e6:	4781                	li	a5,0
    800056e8:	a085                	j	80005748 <sys_link+0x13c>
    end_op();
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	cdc080e7          	jalr	-804(ra) # 800043c6 <end_op>
    return -1;
    800056f2:	57fd                	li	a5,-1
    800056f4:	a891                	j	80005748 <sys_link+0x13c>
    iunlockput(ip);
    800056f6:	8526                	mv	a0,s1
    800056f8:	ffffe097          	auipc	ra,0xffffe
    800056fc:	4f0080e7          	jalr	1264(ra) # 80003be8 <iunlockput>
    end_op();
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	cc6080e7          	jalr	-826(ra) # 800043c6 <end_op>
    return -1;
    80005708:	57fd                	li	a5,-1
    8000570a:	a83d                	j	80005748 <sys_link+0x13c>
    iunlockput(dp);
    8000570c:	854a                	mv	a0,s2
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	4da080e7          	jalr	1242(ra) # 80003be8 <iunlockput>
  ilock(ip);
    80005716:	8526                	mv	a0,s1
    80005718:	ffffe097          	auipc	ra,0xffffe
    8000571c:	26e080e7          	jalr	622(ra) # 80003986 <ilock>
  ip->nlink--;
    80005720:	04a4d783          	lhu	a5,74(s1)
    80005724:	37fd                	addiw	a5,a5,-1
    80005726:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	190080e7          	jalr	400(ra) # 800038bc <iupdate>
  iunlockput(ip);
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	4b2080e7          	jalr	1202(ra) # 80003be8 <iunlockput>
  end_op();
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	c88080e7          	jalr	-888(ra) # 800043c6 <end_op>
  return -1;
    80005746:	57fd                	li	a5,-1
}
    80005748:	853e                	mv	a0,a5
    8000574a:	70b2                	ld	ra,296(sp)
    8000574c:	7412                	ld	s0,288(sp)
    8000574e:	64f2                	ld	s1,280(sp)
    80005750:	6952                	ld	s2,272(sp)
    80005752:	6155                	addi	sp,sp,304
    80005754:	8082                	ret

0000000080005756 <sys_unlink>:
{
    80005756:	7151                	addi	sp,sp,-240
    80005758:	f586                	sd	ra,232(sp)
    8000575a:	f1a2                	sd	s0,224(sp)
    8000575c:	eda6                	sd	s1,216(sp)
    8000575e:	e9ca                	sd	s2,208(sp)
    80005760:	e5ce                	sd	s3,200(sp)
    80005762:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005764:	08000613          	li	a2,128
    80005768:	f3040593          	addi	a1,s0,-208
    8000576c:	4501                	li	a0,0
    8000576e:	ffffd097          	auipc	ra,0xffffd
    80005772:	6da080e7          	jalr	1754(ra) # 80002e48 <argstr>
    80005776:	18054163          	bltz	a0,800058f8 <sys_unlink+0x1a2>
  begin_op();
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	bcc080e7          	jalr	-1076(ra) # 80004346 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005782:	fb040593          	addi	a1,s0,-80
    80005786:	f3040513          	addi	a0,s0,-208
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	9ca080e7          	jalr	-1590(ra) # 80004154 <nameiparent>
    80005792:	84aa                	mv	s1,a0
    80005794:	c979                	beqz	a0,8000586a <sys_unlink+0x114>
  ilock(dp);
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	1f0080e7          	jalr	496(ra) # 80003986 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000579e:	00003597          	auipc	a1,0x3
    800057a2:	f9a58593          	addi	a1,a1,-102 # 80008738 <syscalls+0x2c0>
    800057a6:	fb040513          	addi	a0,s0,-80
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	6a0080e7          	jalr	1696(ra) # 80003e4a <namecmp>
    800057b2:	14050a63          	beqz	a0,80005906 <sys_unlink+0x1b0>
    800057b6:	00003597          	auipc	a1,0x3
    800057ba:	f8a58593          	addi	a1,a1,-118 # 80008740 <syscalls+0x2c8>
    800057be:	fb040513          	addi	a0,s0,-80
    800057c2:	ffffe097          	auipc	ra,0xffffe
    800057c6:	688080e7          	jalr	1672(ra) # 80003e4a <namecmp>
    800057ca:	12050e63          	beqz	a0,80005906 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057ce:	f2c40613          	addi	a2,s0,-212
    800057d2:	fb040593          	addi	a1,s0,-80
    800057d6:	8526                	mv	a0,s1
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	68c080e7          	jalr	1676(ra) # 80003e64 <dirlookup>
    800057e0:	892a                	mv	s2,a0
    800057e2:	12050263          	beqz	a0,80005906 <sys_unlink+0x1b0>
  ilock(ip);
    800057e6:	ffffe097          	auipc	ra,0xffffe
    800057ea:	1a0080e7          	jalr	416(ra) # 80003986 <ilock>
  if(ip->nlink < 1)
    800057ee:	04a91783          	lh	a5,74(s2)
    800057f2:	08f05263          	blez	a5,80005876 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057f6:	04491703          	lh	a4,68(s2)
    800057fa:	4785                	li	a5,1
    800057fc:	08f70563          	beq	a4,a5,80005886 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005800:	4641                	li	a2,16
    80005802:	4581                	li	a1,0
    80005804:	fc040513          	addi	a0,s0,-64
    80005808:	ffffb097          	auipc	ra,0xffffb
    8000580c:	4f0080e7          	jalr	1264(ra) # 80000cf8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005810:	4741                	li	a4,16
    80005812:	f2c42683          	lw	a3,-212(s0)
    80005816:	fc040613          	addi	a2,s0,-64
    8000581a:	4581                	li	a1,0
    8000581c:	8526                	mv	a0,s1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	512080e7          	jalr	1298(ra) # 80003d30 <writei>
    80005826:	47c1                	li	a5,16
    80005828:	0af51563          	bne	a0,a5,800058d2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000582c:	04491703          	lh	a4,68(s2)
    80005830:	4785                	li	a5,1
    80005832:	0af70863          	beq	a4,a5,800058e2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005836:	8526                	mv	a0,s1
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	3b0080e7          	jalr	944(ra) # 80003be8 <iunlockput>
  ip->nlink--;
    80005840:	04a95783          	lhu	a5,74(s2)
    80005844:	37fd                	addiw	a5,a5,-1
    80005846:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000584a:	854a                	mv	a0,s2
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	070080e7          	jalr	112(ra) # 800038bc <iupdate>
  iunlockput(ip);
    80005854:	854a                	mv	a0,s2
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	392080e7          	jalr	914(ra) # 80003be8 <iunlockput>
  end_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	b68080e7          	jalr	-1176(ra) # 800043c6 <end_op>
  return 0;
    80005866:	4501                	li	a0,0
    80005868:	a84d                	j	8000591a <sys_unlink+0x1c4>
    end_op();
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	b5c080e7          	jalr	-1188(ra) # 800043c6 <end_op>
    return -1;
    80005872:	557d                	li	a0,-1
    80005874:	a05d                	j	8000591a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005876:	00003517          	auipc	a0,0x3
    8000587a:	ef250513          	addi	a0,a0,-270 # 80008768 <syscalls+0x2f0>
    8000587e:	ffffb097          	auipc	ra,0xffffb
    80005882:	cc2080e7          	jalr	-830(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005886:	04c92703          	lw	a4,76(s2)
    8000588a:	02000793          	li	a5,32
    8000588e:	f6e7f9e3          	bgeu	a5,a4,80005800 <sys_unlink+0xaa>
    80005892:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005896:	4741                	li	a4,16
    80005898:	86ce                	mv	a3,s3
    8000589a:	f1840613          	addi	a2,s0,-232
    8000589e:	4581                	li	a1,0
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	398080e7          	jalr	920(ra) # 80003c3a <readi>
    800058aa:	47c1                	li	a5,16
    800058ac:	00f51b63          	bne	a0,a5,800058c2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058b0:	f1845783          	lhu	a5,-232(s0)
    800058b4:	e7a1                	bnez	a5,800058fc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058b6:	29c1                	addiw	s3,s3,16
    800058b8:	04c92783          	lw	a5,76(s2)
    800058bc:	fcf9ede3          	bltu	s3,a5,80005896 <sys_unlink+0x140>
    800058c0:	b781                	j	80005800 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058c2:	00003517          	auipc	a0,0x3
    800058c6:	ebe50513          	addi	a0,a0,-322 # 80008780 <syscalls+0x308>
    800058ca:	ffffb097          	auipc	ra,0xffffb
    800058ce:	c76080e7          	jalr	-906(ra) # 80000540 <panic>
    panic("unlink: writei");
    800058d2:	00003517          	auipc	a0,0x3
    800058d6:	ec650513          	addi	a0,a0,-314 # 80008798 <syscalls+0x320>
    800058da:	ffffb097          	auipc	ra,0xffffb
    800058de:	c66080e7          	jalr	-922(ra) # 80000540 <panic>
    dp->nlink--;
    800058e2:	04a4d783          	lhu	a5,74(s1)
    800058e6:	37fd                	addiw	a5,a5,-1
    800058e8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058ec:	8526                	mv	a0,s1
    800058ee:	ffffe097          	auipc	ra,0xffffe
    800058f2:	fce080e7          	jalr	-50(ra) # 800038bc <iupdate>
    800058f6:	b781                	j	80005836 <sys_unlink+0xe0>
    return -1;
    800058f8:	557d                	li	a0,-1
    800058fa:	a005                	j	8000591a <sys_unlink+0x1c4>
    iunlockput(ip);
    800058fc:	854a                	mv	a0,s2
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	2ea080e7          	jalr	746(ra) # 80003be8 <iunlockput>
  iunlockput(dp);
    80005906:	8526                	mv	a0,s1
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	2e0080e7          	jalr	736(ra) # 80003be8 <iunlockput>
  end_op();
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	ab6080e7          	jalr	-1354(ra) # 800043c6 <end_op>
  return -1;
    80005918:	557d                	li	a0,-1
}
    8000591a:	70ae                	ld	ra,232(sp)
    8000591c:	740e                	ld	s0,224(sp)
    8000591e:	64ee                	ld	s1,216(sp)
    80005920:	694e                	ld	s2,208(sp)
    80005922:	69ae                	ld	s3,200(sp)
    80005924:	616d                	addi	sp,sp,240
    80005926:	8082                	ret

0000000080005928 <sys_open>:

uint64
sys_open(void)
{
    80005928:	7131                	addi	sp,sp,-192
    8000592a:	fd06                	sd	ra,184(sp)
    8000592c:	f922                	sd	s0,176(sp)
    8000592e:	f526                	sd	s1,168(sp)
    80005930:	f14a                	sd	s2,160(sp)
    80005932:	ed4e                	sd	s3,152(sp)
    80005934:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005936:	08000613          	li	a2,128
    8000593a:	f5040593          	addi	a1,s0,-176
    8000593e:	4501                	li	a0,0
    80005940:	ffffd097          	auipc	ra,0xffffd
    80005944:	508080e7          	jalr	1288(ra) # 80002e48 <argstr>
    return -1;
    80005948:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000594a:	0c054163          	bltz	a0,80005a0c <sys_open+0xe4>
    8000594e:	f4c40593          	addi	a1,s0,-180
    80005952:	4505                	li	a0,1
    80005954:	ffffd097          	auipc	ra,0xffffd
    80005958:	4b0080e7          	jalr	1200(ra) # 80002e04 <argint>
    8000595c:	0a054863          	bltz	a0,80005a0c <sys_open+0xe4>

  begin_op();
    80005960:	fffff097          	auipc	ra,0xfffff
    80005964:	9e6080e7          	jalr	-1562(ra) # 80004346 <begin_op>

  if(omode & O_CREATE){
    80005968:	f4c42783          	lw	a5,-180(s0)
    8000596c:	2007f793          	andi	a5,a5,512
    80005970:	cbdd                	beqz	a5,80005a26 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005972:	4681                	li	a3,0
    80005974:	4601                	li	a2,0
    80005976:	4589                	li	a1,2
    80005978:	f5040513          	addi	a0,s0,-176
    8000597c:	00000097          	auipc	ra,0x0
    80005980:	974080e7          	jalr	-1676(ra) # 800052f0 <create>
    80005984:	892a                	mv	s2,a0
    if(ip == 0){
    80005986:	c959                	beqz	a0,80005a1c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005988:	04491703          	lh	a4,68(s2)
    8000598c:	478d                	li	a5,3
    8000598e:	00f71763          	bne	a4,a5,8000599c <sys_open+0x74>
    80005992:	04695703          	lhu	a4,70(s2)
    80005996:	47a5                	li	a5,9
    80005998:	0ce7ec63          	bltu	a5,a4,80005a70 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	dc0080e7          	jalr	-576(ra) # 8000475c <filealloc>
    800059a4:	89aa                	mv	s3,a0
    800059a6:	10050263          	beqz	a0,80005aaa <sys_open+0x182>
    800059aa:	00000097          	auipc	ra,0x0
    800059ae:	904080e7          	jalr	-1788(ra) # 800052ae <fdalloc>
    800059b2:	84aa                	mv	s1,a0
    800059b4:	0e054663          	bltz	a0,80005aa0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059b8:	04491703          	lh	a4,68(s2)
    800059bc:	478d                	li	a5,3
    800059be:	0cf70463          	beq	a4,a5,80005a86 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059c2:	4789                	li	a5,2
    800059c4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059c8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059cc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059d0:	f4c42783          	lw	a5,-180(s0)
    800059d4:	0017c713          	xori	a4,a5,1
    800059d8:	8b05                	andi	a4,a4,1
    800059da:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059de:	0037f713          	andi	a4,a5,3
    800059e2:	00e03733          	snez	a4,a4
    800059e6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059ea:	4007f793          	andi	a5,a5,1024
    800059ee:	c791                	beqz	a5,800059fa <sys_open+0xd2>
    800059f0:	04491703          	lh	a4,68(s2)
    800059f4:	4789                	li	a5,2
    800059f6:	08f70f63          	beq	a4,a5,80005a94 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059fa:	854a                	mv	a0,s2
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	04c080e7          	jalr	76(ra) # 80003a48 <iunlock>
  end_op();
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	9c2080e7          	jalr	-1598(ra) # 800043c6 <end_op>

  return fd;
}
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	70ea                	ld	ra,184(sp)
    80005a10:	744a                	ld	s0,176(sp)
    80005a12:	74aa                	ld	s1,168(sp)
    80005a14:	790a                	ld	s2,160(sp)
    80005a16:	69ea                	ld	s3,152(sp)
    80005a18:	6129                	addi	sp,sp,192
    80005a1a:	8082                	ret
      end_op();
    80005a1c:	fffff097          	auipc	ra,0xfffff
    80005a20:	9aa080e7          	jalr	-1622(ra) # 800043c6 <end_op>
      return -1;
    80005a24:	b7e5                	j	80005a0c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a26:	f5040513          	addi	a0,s0,-176
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	70c080e7          	jalr	1804(ra) # 80004136 <namei>
    80005a32:	892a                	mv	s2,a0
    80005a34:	c905                	beqz	a0,80005a64 <sys_open+0x13c>
    ilock(ip);
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	f50080e7          	jalr	-176(ra) # 80003986 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a3e:	04491703          	lh	a4,68(s2)
    80005a42:	4785                	li	a5,1
    80005a44:	f4f712e3          	bne	a4,a5,80005988 <sys_open+0x60>
    80005a48:	f4c42783          	lw	a5,-180(s0)
    80005a4c:	dba1                	beqz	a5,8000599c <sys_open+0x74>
      iunlockput(ip);
    80005a4e:	854a                	mv	a0,s2
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	198080e7          	jalr	408(ra) # 80003be8 <iunlockput>
      end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	96e080e7          	jalr	-1682(ra) # 800043c6 <end_op>
      return -1;
    80005a60:	54fd                	li	s1,-1
    80005a62:	b76d                	j	80005a0c <sys_open+0xe4>
      end_op();
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	962080e7          	jalr	-1694(ra) # 800043c6 <end_op>
      return -1;
    80005a6c:	54fd                	li	s1,-1
    80005a6e:	bf79                	j	80005a0c <sys_open+0xe4>
    iunlockput(ip);
    80005a70:	854a                	mv	a0,s2
    80005a72:	ffffe097          	auipc	ra,0xffffe
    80005a76:	176080e7          	jalr	374(ra) # 80003be8 <iunlockput>
    end_op();
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	94c080e7          	jalr	-1716(ra) # 800043c6 <end_op>
    return -1;
    80005a82:	54fd                	li	s1,-1
    80005a84:	b761                	j	80005a0c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a86:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a8a:	04691783          	lh	a5,70(s2)
    80005a8e:	02f99223          	sh	a5,36(s3)
    80005a92:	bf2d                	j	800059cc <sys_open+0xa4>
    itrunc(ip);
    80005a94:	854a                	mv	a0,s2
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	ffe080e7          	jalr	-2(ra) # 80003a94 <itrunc>
    80005a9e:	bfb1                	j	800059fa <sys_open+0xd2>
      fileclose(f);
    80005aa0:	854e                	mv	a0,s3
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	d76080e7          	jalr	-650(ra) # 80004818 <fileclose>
    iunlockput(ip);
    80005aaa:	854a                	mv	a0,s2
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	13c080e7          	jalr	316(ra) # 80003be8 <iunlockput>
    end_op();
    80005ab4:	fffff097          	auipc	ra,0xfffff
    80005ab8:	912080e7          	jalr	-1774(ra) # 800043c6 <end_op>
    return -1;
    80005abc:	54fd                	li	s1,-1
    80005abe:	b7b9                	j	80005a0c <sys_open+0xe4>

0000000080005ac0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ac0:	7175                	addi	sp,sp,-144
    80005ac2:	e506                	sd	ra,136(sp)
    80005ac4:	e122                	sd	s0,128(sp)
    80005ac6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	87e080e7          	jalr	-1922(ra) # 80004346 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ad0:	08000613          	li	a2,128
    80005ad4:	f7040593          	addi	a1,s0,-144
    80005ad8:	4501                	li	a0,0
    80005ada:	ffffd097          	auipc	ra,0xffffd
    80005ade:	36e080e7          	jalr	878(ra) # 80002e48 <argstr>
    80005ae2:	02054963          	bltz	a0,80005b14 <sys_mkdir+0x54>
    80005ae6:	4681                	li	a3,0
    80005ae8:	4601                	li	a2,0
    80005aea:	4585                	li	a1,1
    80005aec:	f7040513          	addi	a0,s0,-144
    80005af0:	00000097          	auipc	ra,0x0
    80005af4:	800080e7          	jalr	-2048(ra) # 800052f0 <create>
    80005af8:	cd11                	beqz	a0,80005b14 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	0ee080e7          	jalr	238(ra) # 80003be8 <iunlockput>
  end_op();
    80005b02:	fffff097          	auipc	ra,0xfffff
    80005b06:	8c4080e7          	jalr	-1852(ra) # 800043c6 <end_op>
  return 0;
    80005b0a:	4501                	li	a0,0
}
    80005b0c:	60aa                	ld	ra,136(sp)
    80005b0e:	640a                	ld	s0,128(sp)
    80005b10:	6149                	addi	sp,sp,144
    80005b12:	8082                	ret
    end_op();
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	8b2080e7          	jalr	-1870(ra) # 800043c6 <end_op>
    return -1;
    80005b1c:	557d                	li	a0,-1
    80005b1e:	b7fd                	j	80005b0c <sys_mkdir+0x4c>

0000000080005b20 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b20:	7135                	addi	sp,sp,-160
    80005b22:	ed06                	sd	ra,152(sp)
    80005b24:	e922                	sd	s0,144(sp)
    80005b26:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	81e080e7          	jalr	-2018(ra) # 80004346 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b30:	08000613          	li	a2,128
    80005b34:	f7040593          	addi	a1,s0,-144
    80005b38:	4501                	li	a0,0
    80005b3a:	ffffd097          	auipc	ra,0xffffd
    80005b3e:	30e080e7          	jalr	782(ra) # 80002e48 <argstr>
    80005b42:	04054a63          	bltz	a0,80005b96 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b46:	f6c40593          	addi	a1,s0,-148
    80005b4a:	4505                	li	a0,1
    80005b4c:	ffffd097          	auipc	ra,0xffffd
    80005b50:	2b8080e7          	jalr	696(ra) # 80002e04 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b54:	04054163          	bltz	a0,80005b96 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b58:	f6840593          	addi	a1,s0,-152
    80005b5c:	4509                	li	a0,2
    80005b5e:	ffffd097          	auipc	ra,0xffffd
    80005b62:	2a6080e7          	jalr	678(ra) # 80002e04 <argint>
     argint(1, &major) < 0 ||
    80005b66:	02054863          	bltz	a0,80005b96 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b6a:	f6841683          	lh	a3,-152(s0)
    80005b6e:	f6c41603          	lh	a2,-148(s0)
    80005b72:	458d                	li	a1,3
    80005b74:	f7040513          	addi	a0,s0,-144
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	778080e7          	jalr	1912(ra) # 800052f0 <create>
     argint(2, &minor) < 0 ||
    80005b80:	c919                	beqz	a0,80005b96 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	066080e7          	jalr	102(ra) # 80003be8 <iunlockput>
  end_op();
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	83c080e7          	jalr	-1988(ra) # 800043c6 <end_op>
  return 0;
    80005b92:	4501                	li	a0,0
    80005b94:	a031                	j	80005ba0 <sys_mknod+0x80>
    end_op();
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	830080e7          	jalr	-2000(ra) # 800043c6 <end_op>
    return -1;
    80005b9e:	557d                	li	a0,-1
}
    80005ba0:	60ea                	ld	ra,152(sp)
    80005ba2:	644a                	ld	s0,144(sp)
    80005ba4:	610d                	addi	sp,sp,160
    80005ba6:	8082                	ret

0000000080005ba8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ba8:	7135                	addi	sp,sp,-160
    80005baa:	ed06                	sd	ra,152(sp)
    80005bac:	e922                	sd	s0,144(sp)
    80005bae:	e526                	sd	s1,136(sp)
    80005bb0:	e14a                	sd	s2,128(sp)
    80005bb2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bb4:	ffffc097          	auipc	ra,0xffffc
    80005bb8:	f3a080e7          	jalr	-198(ra) # 80001aee <myproc>
    80005bbc:	892a                	mv	s2,a0
  
  begin_op();
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	788080e7          	jalr	1928(ra) # 80004346 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bc6:	08000613          	li	a2,128
    80005bca:	f6040593          	addi	a1,s0,-160
    80005bce:	4501                	li	a0,0
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	278080e7          	jalr	632(ra) # 80002e48 <argstr>
    80005bd8:	04054b63          	bltz	a0,80005c2e <sys_chdir+0x86>
    80005bdc:	f6040513          	addi	a0,s0,-160
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	556080e7          	jalr	1366(ra) # 80004136 <namei>
    80005be8:	84aa                	mv	s1,a0
    80005bea:	c131                	beqz	a0,80005c2e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	d9a080e7          	jalr	-614(ra) # 80003986 <ilock>
  if(ip->type != T_DIR){
    80005bf4:	04449703          	lh	a4,68(s1)
    80005bf8:	4785                	li	a5,1
    80005bfa:	04f71063          	bne	a4,a5,80005c3a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bfe:	8526                	mv	a0,s1
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	e48080e7          	jalr	-440(ra) # 80003a48 <iunlock>
  iput(p->cwd);
    80005c08:	15093503          	ld	a0,336(s2)
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	f34080e7          	jalr	-204(ra) # 80003b40 <iput>
  end_op();
    80005c14:	ffffe097          	auipc	ra,0xffffe
    80005c18:	7b2080e7          	jalr	1970(ra) # 800043c6 <end_op>
  p->cwd = ip;
    80005c1c:	14993823          	sd	s1,336(s2)
  return 0;
    80005c20:	4501                	li	a0,0
}
    80005c22:	60ea                	ld	ra,152(sp)
    80005c24:	644a                	ld	s0,144(sp)
    80005c26:	64aa                	ld	s1,136(sp)
    80005c28:	690a                	ld	s2,128(sp)
    80005c2a:	610d                	addi	sp,sp,160
    80005c2c:	8082                	ret
    end_op();
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	798080e7          	jalr	1944(ra) # 800043c6 <end_op>
    return -1;
    80005c36:	557d                	li	a0,-1
    80005c38:	b7ed                	j	80005c22 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c3a:	8526                	mv	a0,s1
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	fac080e7          	jalr	-84(ra) # 80003be8 <iunlockput>
    end_op();
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	782080e7          	jalr	1922(ra) # 800043c6 <end_op>
    return -1;
    80005c4c:	557d                	li	a0,-1
    80005c4e:	bfd1                	j	80005c22 <sys_chdir+0x7a>

0000000080005c50 <sys_exec>:

uint64
sys_exec(void)
{
    80005c50:	7145                	addi	sp,sp,-464
    80005c52:	e786                	sd	ra,456(sp)
    80005c54:	e3a2                	sd	s0,448(sp)
    80005c56:	ff26                	sd	s1,440(sp)
    80005c58:	fb4a                	sd	s2,432(sp)
    80005c5a:	f74e                	sd	s3,424(sp)
    80005c5c:	f352                	sd	s4,416(sp)
    80005c5e:	ef56                	sd	s5,408(sp)
    80005c60:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c62:	08000613          	li	a2,128
    80005c66:	f4040593          	addi	a1,s0,-192
    80005c6a:	4501                	li	a0,0
    80005c6c:	ffffd097          	auipc	ra,0xffffd
    80005c70:	1dc080e7          	jalr	476(ra) # 80002e48 <argstr>
    return -1;
    80005c74:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c76:	0c054a63          	bltz	a0,80005d4a <sys_exec+0xfa>
    80005c7a:	e3840593          	addi	a1,s0,-456
    80005c7e:	4505                	li	a0,1
    80005c80:	ffffd097          	auipc	ra,0xffffd
    80005c84:	1a6080e7          	jalr	422(ra) # 80002e26 <argaddr>
    80005c88:	0c054163          	bltz	a0,80005d4a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c8c:	10000613          	li	a2,256
    80005c90:	4581                	li	a1,0
    80005c92:	e4040513          	addi	a0,s0,-448
    80005c96:	ffffb097          	auipc	ra,0xffffb
    80005c9a:	062080e7          	jalr	98(ra) # 80000cf8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c9e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ca2:	89a6                	mv	s3,s1
    80005ca4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ca6:	02000a13          	li	s4,32
    80005caa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cae:	00391793          	slli	a5,s2,0x3
    80005cb2:	e3040593          	addi	a1,s0,-464
    80005cb6:	e3843503          	ld	a0,-456(s0)
    80005cba:	953e                	add	a0,a0,a5
    80005cbc:	ffffd097          	auipc	ra,0xffffd
    80005cc0:	0ae080e7          	jalr	174(ra) # 80002d6a <fetchaddr>
    80005cc4:	02054a63          	bltz	a0,80005cf8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cc8:	e3043783          	ld	a5,-464(s0)
    80005ccc:	c3b9                	beqz	a5,80005d12 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cce:	ffffb097          	auipc	ra,0xffffb
    80005cd2:	e3e080e7          	jalr	-450(ra) # 80000b0c <kalloc>
    80005cd6:	85aa                	mv	a1,a0
    80005cd8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cdc:	cd11                	beqz	a0,80005cf8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cde:	6605                	lui	a2,0x1
    80005ce0:	e3043503          	ld	a0,-464(s0)
    80005ce4:	ffffd097          	auipc	ra,0xffffd
    80005ce8:	0d8080e7          	jalr	216(ra) # 80002dbc <fetchstr>
    80005cec:	00054663          	bltz	a0,80005cf8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005cf0:	0905                	addi	s2,s2,1
    80005cf2:	09a1                	addi	s3,s3,8
    80005cf4:	fb491be3          	bne	s2,s4,80005caa <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cf8:	10048913          	addi	s2,s1,256
    80005cfc:	6088                	ld	a0,0(s1)
    80005cfe:	c529                	beqz	a0,80005d48 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d00:	ffffb097          	auipc	ra,0xffffb
    80005d04:	d10080e7          	jalr	-752(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d08:	04a1                	addi	s1,s1,8
    80005d0a:	ff2499e3          	bne	s1,s2,80005cfc <sys_exec+0xac>
  return -1;
    80005d0e:	597d                	li	s2,-1
    80005d10:	a82d                	j	80005d4a <sys_exec+0xfa>
      argv[i] = 0;
    80005d12:	0a8e                	slli	s5,s5,0x3
    80005d14:	fc040793          	addi	a5,s0,-64
    80005d18:	9abe                	add	s5,s5,a5
    80005d1a:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd7e80>
  int ret = exec(path, argv);
    80005d1e:	e4040593          	addi	a1,s0,-448
    80005d22:	f4040513          	addi	a0,s0,-192
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	178080e7          	jalr	376(ra) # 80004e9e <exec>
    80005d2e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d30:	10048993          	addi	s3,s1,256
    80005d34:	6088                	ld	a0,0(s1)
    80005d36:	c911                	beqz	a0,80005d4a <sys_exec+0xfa>
    kfree(argv[i]);
    80005d38:	ffffb097          	auipc	ra,0xffffb
    80005d3c:	cd8080e7          	jalr	-808(ra) # 80000a10 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d40:	04a1                	addi	s1,s1,8
    80005d42:	ff3499e3          	bne	s1,s3,80005d34 <sys_exec+0xe4>
    80005d46:	a011                	j	80005d4a <sys_exec+0xfa>
  return -1;
    80005d48:	597d                	li	s2,-1
}
    80005d4a:	854a                	mv	a0,s2
    80005d4c:	60be                	ld	ra,456(sp)
    80005d4e:	641e                	ld	s0,448(sp)
    80005d50:	74fa                	ld	s1,440(sp)
    80005d52:	795a                	ld	s2,432(sp)
    80005d54:	79ba                	ld	s3,424(sp)
    80005d56:	7a1a                	ld	s4,416(sp)
    80005d58:	6afa                	ld	s5,408(sp)
    80005d5a:	6179                	addi	sp,sp,464
    80005d5c:	8082                	ret

0000000080005d5e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d5e:	7139                	addi	sp,sp,-64
    80005d60:	fc06                	sd	ra,56(sp)
    80005d62:	f822                	sd	s0,48(sp)
    80005d64:	f426                	sd	s1,40(sp)
    80005d66:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	d86080e7          	jalr	-634(ra) # 80001aee <myproc>
    80005d70:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d72:	fd840593          	addi	a1,s0,-40
    80005d76:	4501                	li	a0,0
    80005d78:	ffffd097          	auipc	ra,0xffffd
    80005d7c:	0ae080e7          	jalr	174(ra) # 80002e26 <argaddr>
    return -1;
    80005d80:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d82:	0e054063          	bltz	a0,80005e62 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d86:	fc840593          	addi	a1,s0,-56
    80005d8a:	fd040513          	addi	a0,s0,-48
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	de0080e7          	jalr	-544(ra) # 80004b6e <pipealloc>
    return -1;
    80005d96:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d98:	0c054563          	bltz	a0,80005e62 <sys_pipe+0x104>
  fd0 = -1;
    80005d9c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005da0:	fd043503          	ld	a0,-48(s0)
    80005da4:	fffff097          	auipc	ra,0xfffff
    80005da8:	50a080e7          	jalr	1290(ra) # 800052ae <fdalloc>
    80005dac:	fca42223          	sw	a0,-60(s0)
    80005db0:	08054c63          	bltz	a0,80005e48 <sys_pipe+0xea>
    80005db4:	fc843503          	ld	a0,-56(s0)
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	4f6080e7          	jalr	1270(ra) # 800052ae <fdalloc>
    80005dc0:	fca42023          	sw	a0,-64(s0)
    80005dc4:	06054863          	bltz	a0,80005e34 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dc8:	4691                	li	a3,4
    80005dca:	fc440613          	addi	a2,s0,-60
    80005dce:	fd843583          	ld	a1,-40(s0)
    80005dd2:	68a8                	ld	a0,80(s1)
    80005dd4:	ffffc097          	auipc	ra,0xffffc
    80005dd8:	8d6080e7          	jalr	-1834(ra) # 800016aa <copyout>
    80005ddc:	02054063          	bltz	a0,80005dfc <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005de0:	4691                	li	a3,4
    80005de2:	fc040613          	addi	a2,s0,-64
    80005de6:	fd843583          	ld	a1,-40(s0)
    80005dea:	0591                	addi	a1,a1,4
    80005dec:	68a8                	ld	a0,80(s1)
    80005dee:	ffffc097          	auipc	ra,0xffffc
    80005df2:	8bc080e7          	jalr	-1860(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005df6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005df8:	06055563          	bgez	a0,80005e62 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dfc:	fc442783          	lw	a5,-60(s0)
    80005e00:	07e9                	addi	a5,a5,26
    80005e02:	078e                	slli	a5,a5,0x3
    80005e04:	97a6                	add	a5,a5,s1
    80005e06:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e0a:	fc042503          	lw	a0,-64(s0)
    80005e0e:	0569                	addi	a0,a0,26
    80005e10:	050e                	slli	a0,a0,0x3
    80005e12:	9526                	add	a0,a0,s1
    80005e14:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e18:	fd043503          	ld	a0,-48(s0)
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	9fc080e7          	jalr	-1540(ra) # 80004818 <fileclose>
    fileclose(wf);
    80005e24:	fc843503          	ld	a0,-56(s0)
    80005e28:	fffff097          	auipc	ra,0xfffff
    80005e2c:	9f0080e7          	jalr	-1552(ra) # 80004818 <fileclose>
    return -1;
    80005e30:	57fd                	li	a5,-1
    80005e32:	a805                	j	80005e62 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e34:	fc442783          	lw	a5,-60(s0)
    80005e38:	0007c863          	bltz	a5,80005e48 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e3c:	01a78513          	addi	a0,a5,26
    80005e40:	050e                	slli	a0,a0,0x3
    80005e42:	9526                	add	a0,a0,s1
    80005e44:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e48:	fd043503          	ld	a0,-48(s0)
    80005e4c:	fffff097          	auipc	ra,0xfffff
    80005e50:	9cc080e7          	jalr	-1588(ra) # 80004818 <fileclose>
    fileclose(wf);
    80005e54:	fc843503          	ld	a0,-56(s0)
    80005e58:	fffff097          	auipc	ra,0xfffff
    80005e5c:	9c0080e7          	jalr	-1600(ra) # 80004818 <fileclose>
    return -1;
    80005e60:	57fd                	li	a5,-1
}
    80005e62:	853e                	mv	a0,a5
    80005e64:	70e2                	ld	ra,56(sp)
    80005e66:	7442                	ld	s0,48(sp)
    80005e68:	74a2                	ld	s1,40(sp)
    80005e6a:	6121                	addi	sp,sp,64
    80005e6c:	8082                	ret
	...

0000000080005e70 <kernelvec>:
    80005e70:	7111                	addi	sp,sp,-256
    80005e72:	e006                	sd	ra,0(sp)
    80005e74:	e40a                	sd	sp,8(sp)
    80005e76:	e80e                	sd	gp,16(sp)
    80005e78:	ec12                	sd	tp,24(sp)
    80005e7a:	f016                	sd	t0,32(sp)
    80005e7c:	f41a                	sd	t1,40(sp)
    80005e7e:	f81e                	sd	t2,48(sp)
    80005e80:	fc22                	sd	s0,56(sp)
    80005e82:	e0a6                	sd	s1,64(sp)
    80005e84:	e4aa                	sd	a0,72(sp)
    80005e86:	e8ae                	sd	a1,80(sp)
    80005e88:	ecb2                	sd	a2,88(sp)
    80005e8a:	f0b6                	sd	a3,96(sp)
    80005e8c:	f4ba                	sd	a4,104(sp)
    80005e8e:	f8be                	sd	a5,112(sp)
    80005e90:	fcc2                	sd	a6,120(sp)
    80005e92:	e146                	sd	a7,128(sp)
    80005e94:	e54a                	sd	s2,136(sp)
    80005e96:	e94e                	sd	s3,144(sp)
    80005e98:	ed52                	sd	s4,152(sp)
    80005e9a:	f156                	sd	s5,160(sp)
    80005e9c:	f55a                	sd	s6,168(sp)
    80005e9e:	f95e                	sd	s7,176(sp)
    80005ea0:	fd62                	sd	s8,184(sp)
    80005ea2:	e1e6                	sd	s9,192(sp)
    80005ea4:	e5ea                	sd	s10,200(sp)
    80005ea6:	e9ee                	sd	s11,208(sp)
    80005ea8:	edf2                	sd	t3,216(sp)
    80005eaa:	f1f6                	sd	t4,224(sp)
    80005eac:	f5fa                	sd	t5,232(sp)
    80005eae:	f9fe                	sd	t6,240(sp)
    80005eb0:	d6ffc0ef          	jal	ra,80002c1e <kerneltrap>
    80005eb4:	6082                	ld	ra,0(sp)
    80005eb6:	6122                	ld	sp,8(sp)
    80005eb8:	61c2                	ld	gp,16(sp)
    80005eba:	7282                	ld	t0,32(sp)
    80005ebc:	7322                	ld	t1,40(sp)
    80005ebe:	73c2                	ld	t2,48(sp)
    80005ec0:	7462                	ld	s0,56(sp)
    80005ec2:	6486                	ld	s1,64(sp)
    80005ec4:	6526                	ld	a0,72(sp)
    80005ec6:	65c6                	ld	a1,80(sp)
    80005ec8:	6666                	ld	a2,88(sp)
    80005eca:	7686                	ld	a3,96(sp)
    80005ecc:	7726                	ld	a4,104(sp)
    80005ece:	77c6                	ld	a5,112(sp)
    80005ed0:	7866                	ld	a6,120(sp)
    80005ed2:	688a                	ld	a7,128(sp)
    80005ed4:	692a                	ld	s2,136(sp)
    80005ed6:	69ca                	ld	s3,144(sp)
    80005ed8:	6a6a                	ld	s4,152(sp)
    80005eda:	7a8a                	ld	s5,160(sp)
    80005edc:	7b2a                	ld	s6,168(sp)
    80005ede:	7bca                	ld	s7,176(sp)
    80005ee0:	7c6a                	ld	s8,184(sp)
    80005ee2:	6c8e                	ld	s9,192(sp)
    80005ee4:	6d2e                	ld	s10,200(sp)
    80005ee6:	6dce                	ld	s11,208(sp)
    80005ee8:	6e6e                	ld	t3,216(sp)
    80005eea:	7e8e                	ld	t4,224(sp)
    80005eec:	7f2e                	ld	t5,232(sp)
    80005eee:	7fce                	ld	t6,240(sp)
    80005ef0:	6111                	addi	sp,sp,256
    80005ef2:	10200073          	sret
    80005ef6:	00000013          	nop
    80005efa:	00000013          	nop
    80005efe:	0001                	nop

0000000080005f00 <timervec>:
    80005f00:	34051573          	csrrw	a0,mscratch,a0
    80005f04:	e10c                	sd	a1,0(a0)
    80005f06:	e510                	sd	a2,8(a0)
    80005f08:	e914                	sd	a3,16(a0)
    80005f0a:	710c                	ld	a1,32(a0)
    80005f0c:	7510                	ld	a2,40(a0)
    80005f0e:	6194                	ld	a3,0(a1)
    80005f10:	96b2                	add	a3,a3,a2
    80005f12:	e194                	sd	a3,0(a1)
    80005f14:	4589                	li	a1,2
    80005f16:	14459073          	csrw	sip,a1
    80005f1a:	6914                	ld	a3,16(a0)
    80005f1c:	6510                	ld	a2,8(a0)
    80005f1e:	610c                	ld	a1,0(a0)
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	30200073          	mret
	...

0000000080005f2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f2a:	1141                	addi	sp,sp,-16
    80005f2c:	e422                	sd	s0,8(sp)
    80005f2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f30:	0c0007b7          	lui	a5,0xc000
    80005f34:	4705                	li	a4,1
    80005f36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f38:	c3d8                	sw	a4,4(a5)
}
    80005f3a:	6422                	ld	s0,8(sp)
    80005f3c:	0141                	addi	sp,sp,16
    80005f3e:	8082                	ret

0000000080005f40 <plicinithart>:

void
plicinithart(void)
{
    80005f40:	1141                	addi	sp,sp,-16
    80005f42:	e406                	sd	ra,8(sp)
    80005f44:	e022                	sd	s0,0(sp)
    80005f46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	b7a080e7          	jalr	-1158(ra) # 80001ac2 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f50:	0085171b          	slliw	a4,a0,0x8
    80005f54:	0c0027b7          	lui	a5,0xc002
    80005f58:	97ba                	add	a5,a5,a4
    80005f5a:	40200713          	li	a4,1026
    80005f5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f62:	00d5151b          	slliw	a0,a0,0xd
    80005f66:	0c2017b7          	lui	a5,0xc201
    80005f6a:	953e                	add	a0,a0,a5
    80005f6c:	00052023          	sw	zero,0(a0)
}
    80005f70:	60a2                	ld	ra,8(sp)
    80005f72:	6402                	ld	s0,0(sp)
    80005f74:	0141                	addi	sp,sp,16
    80005f76:	8082                	ret

0000000080005f78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f78:	1141                	addi	sp,sp,-16
    80005f7a:	e406                	sd	ra,8(sp)
    80005f7c:	e022                	sd	s0,0(sp)
    80005f7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f80:	ffffc097          	auipc	ra,0xffffc
    80005f84:	b42080e7          	jalr	-1214(ra) # 80001ac2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f88:	00d5179b          	slliw	a5,a0,0xd
    80005f8c:	0c201537          	lui	a0,0xc201
    80005f90:	953e                	add	a0,a0,a5
  return irq;
}
    80005f92:	4148                	lw	a0,4(a0)
    80005f94:	60a2                	ld	ra,8(sp)
    80005f96:	6402                	ld	s0,0(sp)
    80005f98:	0141                	addi	sp,sp,16
    80005f9a:	8082                	ret

0000000080005f9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f9c:	1101                	addi	sp,sp,-32
    80005f9e:	ec06                	sd	ra,24(sp)
    80005fa0:	e822                	sd	s0,16(sp)
    80005fa2:	e426                	sd	s1,8(sp)
    80005fa4:	1000                	addi	s0,sp,32
    80005fa6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	b1a080e7          	jalr	-1254(ra) # 80001ac2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fb0:	00d5151b          	slliw	a0,a0,0xd
    80005fb4:	0c2017b7          	lui	a5,0xc201
    80005fb8:	97aa                	add	a5,a5,a0
    80005fba:	c3c4                	sw	s1,4(a5)
}
    80005fbc:	60e2                	ld	ra,24(sp)
    80005fbe:	6442                	ld	s0,16(sp)
    80005fc0:	64a2                	ld	s1,8(sp)
    80005fc2:	6105                	addi	sp,sp,32
    80005fc4:	8082                	ret

0000000080005fc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fc6:	1141                	addi	sp,sp,-16
    80005fc8:	e406                	sd	ra,8(sp)
    80005fca:	e022                	sd	s0,0(sp)
    80005fcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fce:	479d                	li	a5,7
    80005fd0:	04a7cc63          	blt	a5,a0,80006028 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005fd4:	0001e797          	auipc	a5,0x1e
    80005fd8:	02c78793          	addi	a5,a5,44 # 80024000 <disk>
    80005fdc:	00a78733          	add	a4,a5,a0
    80005fe0:	6789                	lui	a5,0x2
    80005fe2:	97ba                	add	a5,a5,a4
    80005fe4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fe8:	eba1                	bnez	a5,80006038 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005fea:	00451713          	slli	a4,a0,0x4
    80005fee:	00020797          	auipc	a5,0x20
    80005ff2:	0127b783          	ld	a5,18(a5) # 80026000 <disk+0x2000>
    80005ff6:	97ba                	add	a5,a5,a4
    80005ff8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005ffc:	0001e797          	auipc	a5,0x1e
    80006000:	00478793          	addi	a5,a5,4 # 80024000 <disk>
    80006004:	97aa                	add	a5,a5,a0
    80006006:	6509                	lui	a0,0x2
    80006008:	953e                	add	a0,a0,a5
    8000600a:	4785                	li	a5,1
    8000600c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006010:	00020517          	auipc	a0,0x20
    80006014:	00850513          	addi	a0,a0,8 # 80026018 <disk+0x2018>
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	69c080e7          	jalr	1692(ra) # 800026b4 <wakeup>
}
    80006020:	60a2                	ld	ra,8(sp)
    80006022:	6402                	ld	s0,0(sp)
    80006024:	0141                	addi	sp,sp,16
    80006026:	8082                	ret
    panic("virtio_disk_intr 1");
    80006028:	00002517          	auipc	a0,0x2
    8000602c:	78050513          	addi	a0,a0,1920 # 800087a8 <syscalls+0x330>
    80006030:	ffffa097          	auipc	ra,0xffffa
    80006034:	510080e7          	jalr	1296(ra) # 80000540 <panic>
    panic("virtio_disk_intr 2");
    80006038:	00002517          	auipc	a0,0x2
    8000603c:	78850513          	addi	a0,a0,1928 # 800087c0 <syscalls+0x348>
    80006040:	ffffa097          	auipc	ra,0xffffa
    80006044:	500080e7          	jalr	1280(ra) # 80000540 <panic>

0000000080006048 <virtio_disk_init>:
{
    80006048:	1101                	addi	sp,sp,-32
    8000604a:	ec06                	sd	ra,24(sp)
    8000604c:	e822                	sd	s0,16(sp)
    8000604e:	e426                	sd	s1,8(sp)
    80006050:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006052:	00002597          	auipc	a1,0x2
    80006056:	78658593          	addi	a1,a1,1926 # 800087d8 <syscalls+0x360>
    8000605a:	00020517          	auipc	a0,0x20
    8000605e:	04e50513          	addi	a0,a0,78 # 800260a8 <disk+0x20a8>
    80006062:	ffffb097          	auipc	ra,0xffffb
    80006066:	b0a080e7          	jalr	-1270(ra) # 80000b6c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000606a:	100017b7          	lui	a5,0x10001
    8000606e:	4398                	lw	a4,0(a5)
    80006070:	2701                	sext.w	a4,a4
    80006072:	747277b7          	lui	a5,0x74727
    80006076:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000607a:	0ef71163          	bne	a4,a5,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	43dc                	lw	a5,4(a5)
    80006084:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006086:	4705                	li	a4,1
    80006088:	0ce79a63          	bne	a5,a4,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	479c                	lw	a5,8(a5)
    80006092:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006094:	4709                	li	a4,2
    80006096:	0ce79363          	bne	a5,a4,8000615c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000609a:	100017b7          	lui	a5,0x10001
    8000609e:	47d8                	lw	a4,12(a5)
    800060a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060a2:	554d47b7          	lui	a5,0x554d4
    800060a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060aa:	0af71963          	bne	a4,a5,8000615c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ae:	100017b7          	lui	a5,0x10001
    800060b2:	4705                	li	a4,1
    800060b4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b6:	470d                	li	a4,3
    800060b8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060bc:	c7ffe737          	lui	a4,0xc7ffe
    800060c0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    800060c4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060c6:	2701                	sext.w	a4,a4
    800060c8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ca:	472d                	li	a4,11
    800060cc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ce:	473d                	li	a4,15
    800060d0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060d2:	6705                	lui	a4,0x1
    800060d4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060d6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060da:	5bdc                	lw	a5,52(a5)
    800060dc:	2781                	sext.w	a5,a5
  if(max == 0)
    800060de:	c7d9                	beqz	a5,8000616c <virtio_disk_init+0x124>
  if(max < NUM)
    800060e0:	471d                	li	a4,7
    800060e2:	08f77d63          	bgeu	a4,a5,8000617c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060e6:	100014b7          	lui	s1,0x10001
    800060ea:	47a1                	li	a5,8
    800060ec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060ee:	6609                	lui	a2,0x2
    800060f0:	4581                	li	a1,0
    800060f2:	0001e517          	auipc	a0,0x1e
    800060f6:	f0e50513          	addi	a0,a0,-242 # 80024000 <disk>
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	bfe080e7          	jalr	-1026(ra) # 80000cf8 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006102:	0001e717          	auipc	a4,0x1e
    80006106:	efe70713          	addi	a4,a4,-258 # 80024000 <disk>
    8000610a:	00c75793          	srli	a5,a4,0xc
    8000610e:	2781                	sext.w	a5,a5
    80006110:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006112:	00020797          	auipc	a5,0x20
    80006116:	eee78793          	addi	a5,a5,-274 # 80026000 <disk+0x2000>
    8000611a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000611c:	0001e717          	auipc	a4,0x1e
    80006120:	f6470713          	addi	a4,a4,-156 # 80024080 <disk+0x80>
    80006124:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006126:	0001f717          	auipc	a4,0x1f
    8000612a:	eda70713          	addi	a4,a4,-294 # 80025000 <disk+0x1000>
    8000612e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006130:	4705                	li	a4,1
    80006132:	00e78c23          	sb	a4,24(a5)
    80006136:	00e78ca3          	sb	a4,25(a5)
    8000613a:	00e78d23          	sb	a4,26(a5)
    8000613e:	00e78da3          	sb	a4,27(a5)
    80006142:	00e78e23          	sb	a4,28(a5)
    80006146:	00e78ea3          	sb	a4,29(a5)
    8000614a:	00e78f23          	sb	a4,30(a5)
    8000614e:	00e78fa3          	sb	a4,31(a5)
}
    80006152:	60e2                	ld	ra,24(sp)
    80006154:	6442                	ld	s0,16(sp)
    80006156:	64a2                	ld	s1,8(sp)
    80006158:	6105                	addi	sp,sp,32
    8000615a:	8082                	ret
    panic("could not find virtio disk");
    8000615c:	00002517          	auipc	a0,0x2
    80006160:	68c50513          	addi	a0,a0,1676 # 800087e8 <syscalls+0x370>
    80006164:	ffffa097          	auipc	ra,0xffffa
    80006168:	3dc080e7          	jalr	988(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    8000616c:	00002517          	auipc	a0,0x2
    80006170:	69c50513          	addi	a0,a0,1692 # 80008808 <syscalls+0x390>
    80006174:	ffffa097          	auipc	ra,0xffffa
    80006178:	3cc080e7          	jalr	972(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    8000617c:	00002517          	auipc	a0,0x2
    80006180:	6ac50513          	addi	a0,a0,1708 # 80008828 <syscalls+0x3b0>
    80006184:	ffffa097          	auipc	ra,0xffffa
    80006188:	3bc080e7          	jalr	956(ra) # 80000540 <panic>

000000008000618c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000618c:	7175                	addi	sp,sp,-144
    8000618e:	e506                	sd	ra,136(sp)
    80006190:	e122                	sd	s0,128(sp)
    80006192:	fca6                	sd	s1,120(sp)
    80006194:	f8ca                	sd	s2,112(sp)
    80006196:	f4ce                	sd	s3,104(sp)
    80006198:	f0d2                	sd	s4,96(sp)
    8000619a:	ecd6                	sd	s5,88(sp)
    8000619c:	e8da                	sd	s6,80(sp)
    8000619e:	e4de                	sd	s7,72(sp)
    800061a0:	e0e2                	sd	s8,64(sp)
    800061a2:	fc66                	sd	s9,56(sp)
    800061a4:	f86a                	sd	s10,48(sp)
    800061a6:	f46e                	sd	s11,40(sp)
    800061a8:	0900                	addi	s0,sp,144
    800061aa:	8aaa                	mv	s5,a0
    800061ac:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061ae:	00c52c83          	lw	s9,12(a0)
    800061b2:	001c9c9b          	slliw	s9,s9,0x1
    800061b6:	1c82                	slli	s9,s9,0x20
    800061b8:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061bc:	00020517          	auipc	a0,0x20
    800061c0:	eec50513          	addi	a0,a0,-276 # 800260a8 <disk+0x20a8>
    800061c4:	ffffb097          	auipc	ra,0xffffb
    800061c8:	a38080e7          	jalr	-1480(ra) # 80000bfc <acquire>
  for(int i = 0; i < 3; i++){
    800061cc:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061ce:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061d0:	0001ec17          	auipc	s8,0x1e
    800061d4:	e30c0c13          	addi	s8,s8,-464 # 80024000 <disk>
    800061d8:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    800061da:	4b0d                	li	s6,3
    800061dc:	a0ad                	j	80006246 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    800061de:	00fc0733          	add	a4,s8,a5
    800061e2:	975e                	add	a4,a4,s7
    800061e4:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061e8:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800061ea:	0207c563          	bltz	a5,80006214 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800061ee:	2905                	addiw	s2,s2,1
    800061f0:	0611                	addi	a2,a2,4
    800061f2:	19690d63          	beq	s2,s6,8000638c <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    800061f6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800061f8:	00020717          	auipc	a4,0x20
    800061fc:	e2070713          	addi	a4,a4,-480 # 80026018 <disk+0x2018>
    80006200:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006202:	00074683          	lbu	a3,0(a4)
    80006206:	fee1                	bnez	a3,800061de <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006208:	2785                	addiw	a5,a5,1
    8000620a:	0705                	addi	a4,a4,1
    8000620c:	fe979be3          	bne	a5,s1,80006202 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006210:	57fd                	li	a5,-1
    80006212:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006214:	01205d63          	blez	s2,8000622e <virtio_disk_rw+0xa2>
    80006218:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    8000621a:	000a2503          	lw	a0,0(s4)
    8000621e:	00000097          	auipc	ra,0x0
    80006222:	da8080e7          	jalr	-600(ra) # 80005fc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006226:	2d85                	addiw	s11,s11,1
    80006228:	0a11                	addi	s4,s4,4
    8000622a:	ffb918e3          	bne	s2,s11,8000621a <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000622e:	00020597          	auipc	a1,0x20
    80006232:	e7a58593          	addi	a1,a1,-390 # 800260a8 <disk+0x20a8>
    80006236:	00020517          	auipc	a0,0x20
    8000623a:	de250513          	addi	a0,a0,-542 # 80026018 <disk+0x2018>
    8000623e:	ffffc097          	auipc	ra,0xffffc
    80006242:	2ea080e7          	jalr	746(ra) # 80002528 <sleep>
  for(int i = 0; i < 3; i++){
    80006246:	f8040a13          	addi	s4,s0,-128
{
    8000624a:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    8000624c:	894e                	mv	s2,s3
    8000624e:	b765                	j	800061f6 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006250:	00020717          	auipc	a4,0x20
    80006254:	db073703          	ld	a4,-592(a4) # 80026000 <disk+0x2000>
    80006258:	973e                	add	a4,a4,a5
    8000625a:	00071623          	sh	zero,12(a4)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000625e:	0001e517          	auipc	a0,0x1e
    80006262:	da250513          	addi	a0,a0,-606 # 80024000 <disk>
    80006266:	00020717          	auipc	a4,0x20
    8000626a:	d9a70713          	addi	a4,a4,-614 # 80026000 <disk+0x2000>
    8000626e:	6314                	ld	a3,0(a4)
    80006270:	96be                	add	a3,a3,a5
    80006272:	00c6d603          	lhu	a2,12(a3)
    80006276:	00166613          	ori	a2,a2,1
    8000627a:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000627e:	f8842683          	lw	a3,-120(s0)
    80006282:	6310                	ld	a2,0(a4)
    80006284:	97b2                	add	a5,a5,a2
    80006286:	00d79723          	sh	a3,14(a5)

  disk.info[idx[0]].status = 0;
    8000628a:	20048613          	addi	a2,s1,512 # 10001200 <_entry-0x6fffee00>
    8000628e:	0612                	slli	a2,a2,0x4
    80006290:	962a                	add	a2,a2,a0
    80006292:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006296:	00469793          	slli	a5,a3,0x4
    8000629a:	630c                	ld	a1,0(a4)
    8000629c:	95be                	add	a1,a1,a5
    8000629e:	6689                	lui	a3,0x2
    800062a0:	03068693          	addi	a3,a3,48 # 2030 <_entry-0x7fffdfd0>
    800062a4:	96ca                	add	a3,a3,s2
    800062a6:	96aa                	add	a3,a3,a0
    800062a8:	e194                	sd	a3,0(a1)
  disk.desc[idx[2]].len = 1;
    800062aa:	6314                	ld	a3,0(a4)
    800062ac:	96be                	add	a3,a3,a5
    800062ae:	4585                	li	a1,1
    800062b0:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062b2:	6314                	ld	a3,0(a4)
    800062b4:	96be                	add	a3,a3,a5
    800062b6:	4509                	li	a0,2
    800062b8:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800062bc:	6314                	ld	a3,0(a4)
    800062be:	97b6                	add	a5,a5,a3
    800062c0:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062c4:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800062c8:	03563423          	sd	s5,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800062cc:	6714                	ld	a3,8(a4)
    800062ce:	0026d783          	lhu	a5,2(a3)
    800062d2:	8b9d                	andi	a5,a5,7
    800062d4:	0789                	addi	a5,a5,2
    800062d6:	0786                	slli	a5,a5,0x1
    800062d8:	97b6                	add	a5,a5,a3
    800062da:	00979023          	sh	s1,0(a5)
  __sync_synchronize();
    800062de:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800062e2:	6718                	ld	a4,8(a4)
    800062e4:	00275783          	lhu	a5,2(a4)
    800062e8:	2785                	addiw	a5,a5,1
    800062ea:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062ee:	100017b7          	lui	a5,0x10001
    800062f2:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062f6:	004aa783          	lw	a5,4(s5)
    800062fa:	02b79163          	bne	a5,a1,8000631c <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800062fe:	00020917          	auipc	s2,0x20
    80006302:	daa90913          	addi	s2,s2,-598 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006306:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006308:	85ca                	mv	a1,s2
    8000630a:	8556                	mv	a0,s5
    8000630c:	ffffc097          	auipc	ra,0xffffc
    80006310:	21c080e7          	jalr	540(ra) # 80002528 <sleep>
  while(b->disk == 1) {
    80006314:	004aa783          	lw	a5,4(s5)
    80006318:	fe9788e3          	beq	a5,s1,80006308 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    8000631c:	f8042483          	lw	s1,-128(s0)
    80006320:	20048793          	addi	a5,s1,512
    80006324:	00479713          	slli	a4,a5,0x4
    80006328:	0001e797          	auipc	a5,0x1e
    8000632c:	cd878793          	addi	a5,a5,-808 # 80024000 <disk>
    80006330:	97ba                	add	a5,a5,a4
    80006332:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006336:	00020917          	auipc	s2,0x20
    8000633a:	cca90913          	addi	s2,s2,-822 # 80026000 <disk+0x2000>
    8000633e:	a019                	j	80006344 <virtio_disk_rw+0x1b8>
      i = disk.desc[i].next;
    80006340:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006344:	8526                	mv	a0,s1
    80006346:	00000097          	auipc	ra,0x0
    8000634a:	c80080e7          	jalr	-896(ra) # 80005fc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    8000634e:	0492                	slli	s1,s1,0x4
    80006350:	00093783          	ld	a5,0(s2)
    80006354:	94be                	add	s1,s1,a5
    80006356:	00c4d783          	lhu	a5,12(s1)
    8000635a:	8b85                	andi	a5,a5,1
    8000635c:	f3f5                	bnez	a5,80006340 <virtio_disk_rw+0x1b4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000635e:	00020517          	auipc	a0,0x20
    80006362:	d4a50513          	addi	a0,a0,-694 # 800260a8 <disk+0x20a8>
    80006366:	ffffb097          	auipc	ra,0xffffb
    8000636a:	94a080e7          	jalr	-1718(ra) # 80000cb0 <release>
}
    8000636e:	60aa                	ld	ra,136(sp)
    80006370:	640a                	ld	s0,128(sp)
    80006372:	74e6                	ld	s1,120(sp)
    80006374:	7946                	ld	s2,112(sp)
    80006376:	79a6                	ld	s3,104(sp)
    80006378:	7a06                	ld	s4,96(sp)
    8000637a:	6ae6                	ld	s5,88(sp)
    8000637c:	6b46                	ld	s6,80(sp)
    8000637e:	6ba6                	ld	s7,72(sp)
    80006380:	6c06                	ld	s8,64(sp)
    80006382:	7ce2                	ld	s9,56(sp)
    80006384:	7d42                	ld	s10,48(sp)
    80006386:	7da2                	ld	s11,40(sp)
    80006388:	6149                	addi	sp,sp,144
    8000638a:	8082                	ret
  if(write)
    8000638c:	01a037b3          	snez	a5,s10
    80006390:	f6f42823          	sw	a5,-144(s0)
  buf0.reserved = 0;
    80006394:	f6042a23          	sw	zero,-140(s0)
  buf0.sector = sector;
    80006398:	f7943c23          	sd	s9,-136(s0)
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    8000639c:	f8042483          	lw	s1,-128(s0)
    800063a0:	00449913          	slli	s2,s1,0x4
    800063a4:	00020997          	auipc	s3,0x20
    800063a8:	c5c98993          	addi	s3,s3,-932 # 80026000 <disk+0x2000>
    800063ac:	0009ba03          	ld	s4,0(s3)
    800063b0:	9a4a                	add	s4,s4,s2
    800063b2:	f7040513          	addi	a0,s0,-144
    800063b6:	ffffb097          	auipc	ra,0xffffb
    800063ba:	d02080e7          	jalr	-766(ra) # 800010b8 <kvmpa>
    800063be:	00aa3023          	sd	a0,0(s4)
  disk.desc[idx[0]].len = sizeof(buf0);
    800063c2:	0009b783          	ld	a5,0(s3)
    800063c6:	97ca                	add	a5,a5,s2
    800063c8:	4741                	li	a4,16
    800063ca:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063cc:	0009b783          	ld	a5,0(s3)
    800063d0:	97ca                	add	a5,a5,s2
    800063d2:	4705                	li	a4,1
    800063d4:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800063d8:	f8442783          	lw	a5,-124(s0)
    800063dc:	0009b703          	ld	a4,0(s3)
    800063e0:	974a                	add	a4,a4,s2
    800063e2:	00f71723          	sh	a5,14(a4)
  disk.desc[idx[1]].addr = (uint64) b->data;
    800063e6:	0792                	slli	a5,a5,0x4
    800063e8:	0009b703          	ld	a4,0(s3)
    800063ec:	973e                	add	a4,a4,a5
    800063ee:	058a8693          	addi	a3,s5,88
    800063f2:	e314                	sd	a3,0(a4)
  disk.desc[idx[1]].len = BSIZE;
    800063f4:	0009b703          	ld	a4,0(s3)
    800063f8:	973e                	add	a4,a4,a5
    800063fa:	40000693          	li	a3,1024
    800063fe:	c714                	sw	a3,8(a4)
  if(write)
    80006400:	e40d18e3          	bnez	s10,80006250 <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006404:	00020717          	auipc	a4,0x20
    80006408:	bfc73703          	ld	a4,-1028(a4) # 80026000 <disk+0x2000>
    8000640c:	973e                	add	a4,a4,a5
    8000640e:	4689                	li	a3,2
    80006410:	00d71623          	sh	a3,12(a4)
    80006414:	b5a9                	j	8000625e <virtio_disk_rw+0xd2>

0000000080006416 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006416:	1101                	addi	sp,sp,-32
    80006418:	ec06                	sd	ra,24(sp)
    8000641a:	e822                	sd	s0,16(sp)
    8000641c:	e426                	sd	s1,8(sp)
    8000641e:	e04a                	sd	s2,0(sp)
    80006420:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006422:	00020517          	auipc	a0,0x20
    80006426:	c8650513          	addi	a0,a0,-890 # 800260a8 <disk+0x20a8>
    8000642a:	ffffa097          	auipc	ra,0xffffa
    8000642e:	7d2080e7          	jalr	2002(ra) # 80000bfc <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006432:	00020717          	auipc	a4,0x20
    80006436:	bce70713          	addi	a4,a4,-1074 # 80026000 <disk+0x2000>
    8000643a:	02075783          	lhu	a5,32(a4)
    8000643e:	6b18                	ld	a4,16(a4)
    80006440:	00275683          	lhu	a3,2(a4)
    80006444:	8ebd                	xor	a3,a3,a5
    80006446:	8a9d                	andi	a3,a3,7
    80006448:	cab9                	beqz	a3,8000649e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000644a:	0001e917          	auipc	s2,0x1e
    8000644e:	bb690913          	addi	s2,s2,-1098 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006452:	00020497          	auipc	s1,0x20
    80006456:	bae48493          	addi	s1,s1,-1106 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000645a:	078e                	slli	a5,a5,0x3
    8000645c:	97ba                	add	a5,a5,a4
    8000645e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006460:	20078713          	addi	a4,a5,512
    80006464:	0712                	slli	a4,a4,0x4
    80006466:	974a                	add	a4,a4,s2
    80006468:	03074703          	lbu	a4,48(a4)
    8000646c:	ef21                	bnez	a4,800064c4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000646e:	20078793          	addi	a5,a5,512
    80006472:	0792                	slli	a5,a5,0x4
    80006474:	97ca                	add	a5,a5,s2
    80006476:	7798                	ld	a4,40(a5)
    80006478:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000647c:	7788                	ld	a0,40(a5)
    8000647e:	ffffc097          	auipc	ra,0xffffc
    80006482:	236080e7          	jalr	566(ra) # 800026b4 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006486:	0204d783          	lhu	a5,32(s1)
    8000648a:	2785                	addiw	a5,a5,1
    8000648c:	8b9d                	andi	a5,a5,7
    8000648e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006492:	6898                	ld	a4,16(s1)
    80006494:	00275683          	lhu	a3,2(a4)
    80006498:	8a9d                	andi	a3,a3,7
    8000649a:	fcf690e3          	bne	a3,a5,8000645a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000649e:	10001737          	lui	a4,0x10001
    800064a2:	533c                	lw	a5,96(a4)
    800064a4:	8b8d                	andi	a5,a5,3
    800064a6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800064a8:	00020517          	auipc	a0,0x20
    800064ac:	c0050513          	addi	a0,a0,-1024 # 800260a8 <disk+0x20a8>
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	800080e7          	jalr	-2048(ra) # 80000cb0 <release>
}
    800064b8:	60e2                	ld	ra,24(sp)
    800064ba:	6442                	ld	s0,16(sp)
    800064bc:	64a2                	ld	s1,8(sp)
    800064be:	6902                	ld	s2,0(sp)
    800064c0:	6105                	addi	sp,sp,32
    800064c2:	8082                	ret
      panic("virtio_disk_intr status");
    800064c4:	00002517          	auipc	a0,0x2
    800064c8:	38450513          	addi	a0,a0,900 # 80008848 <syscalls+0x3d0>
    800064cc:	ffffa097          	auipc	ra,0xffffa
    800064d0:	074080e7          	jalr	116(ra) # 80000540 <panic>
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
