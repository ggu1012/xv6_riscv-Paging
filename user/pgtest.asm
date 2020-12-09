
user/_pgtest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <ptinfo>:
#include "user/sid.h"

int gvar = 3535;                                            // A global variable

// Print 3-level page table information.
void ptinfo(char *name, void *addr) {
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	e052                	sd	s4,0(sp)
   e:	1800                	addi	s0,sp,48
  10:	892e                	mv	s2,a1
    printf("%s: \n", name);                                 // Variable name
  12:	85aa                	mv	a1,a0
  14:	00001517          	auipc	a0,0x1
  18:	94c50513          	addi	a0,a0,-1716 # 960 <malloc+0xea>
  1c:	00000097          	auipc	ra,0x0
  20:	79c080e7          	jalr	1948(ra) # 7b8 <printf>
    printf("    Virtual address = %p\n", addr);             // Virtual address
  24:	85ca                	mv	a1,s2
  26:	00001517          	auipc	a0,0x1
  2a:	94250513          	addi	a0,a0,-1726 # 968 <malloc+0xf2>
  2e:	00000097          	auipc	ra,0x0
  32:	78a080e7          	jalr	1930(ra) # 7b8 <printf>
    printf("    Physical address = %p\n", phyaddr(addr));   // Physical address
  36:	854a                	mv	a0,s2
  38:	00000097          	auipc	ra,0x0
  3c:	490080e7          	jalr	1168(ra) # 4c8 <phyaddr>
  40:	85aa                	mv	a1,a0
  42:	00001517          	auipc	a0,0x1
  46:	94650513          	addi	a0,a0,-1722 # 988 <malloc+0x112>
  4a:	00000097          	auipc	ra,0x0
  4e:	76e080e7          	jalr	1902(ra) # 7b8 <printf>
    for(int l = 2; l >= 0; l--) {                           // Page table index at each level
  52:	4489                	li	s1,2
        printf("    PT index at level %d: %d\n", l, ptidx(addr, l));
  54:	00001a17          	auipc	s4,0x1
  58:	954a0a13          	addi	s4,s4,-1708 # 9a8 <malloc+0x132>
    for(int l = 2; l >= 0; l--) {                           // Page table index at each level
  5c:	59fd                	li	s3,-1
        printf("    PT index at level %d: %d\n", l, ptidx(addr, l));
  5e:	85a6                	mv	a1,s1
  60:	854a                	mv	a0,s2
  62:	00000097          	auipc	ra,0x0
  66:	46e080e7          	jalr	1134(ra) # 4d0 <ptidx>
  6a:	862a                	mv	a2,a0
  6c:	85a6                	mv	a1,s1
  6e:	8552                	mv	a0,s4
  70:	00000097          	auipc	ra,0x0
  74:	748080e7          	jalr	1864(ra) # 7b8 <printf>
    for(int l = 2; l >= 0; l--) {                           // Page table index at each level
  78:	34fd                	addiw	s1,s1,-1
  7a:	ff3492e3          	bne	s1,s3,5e <ptinfo+0x5e>
    }
    printf("\n");
  7e:	00001517          	auipc	a0,0x1
  82:	90250513          	addi	a0,a0,-1790 # 980 <malloc+0x10a>
  86:	00000097          	auipc	ra,0x0
  8a:	732080e7          	jalr	1842(ra) # 7b8 <printf>
}
  8e:	70a2                	ld	ra,40(sp)
  90:	7402                	ld	s0,32(sp)
  92:	64e2                	ld	s1,24(sp)
  94:	6942                	ld	s2,16(sp)
  96:	69a2                	ld	s3,8(sp)
  98:	6a02                	ld	s4,0(sp)
  9a:	6145                	addi	sp,sp,48
  9c:	8082                	ret

000000000000009e <main>:

int main(int argc, char **argv) {
  9e:	7179                	addi	sp,sp,-48
  a0:	f406                	sd	ra,40(sp)
  a2:	f022                	sd	s0,32(sp)
  a4:	ec26                	sd	s1,24(sp)
  a6:	1800                	addi	s0,sp,48
    int lvar = 2020;                                        // A local variable
  a8:	7e400793          	li	a5,2020
  ac:	fcf42e23          	sw	a5,-36(s0)
    int *array = (int*)malloc(gvar*lvar*sizeof(int));       // Heap array
  b0:	00001497          	auipc	s1,0x1
  b4:	98c48493          	addi	s1,s1,-1652 # a3c <gvar>
  b8:	409c                	lw	a5,0(s1)
  ba:	7e400513          	li	a0,2020
  be:	02f5053b          	mulw	a0,a0,a5
  c2:	0025151b          	slliw	a0,a0,0x2
  c6:	00000097          	auipc	ra,0x0
  ca:	7b0080e7          	jalr	1968(ra) # 876 <malloc>
  ce:	fca43823          	sd	a0,-48(s0)
    
    for(int i = 0; i < gvar*lvar; i++) { array[i] = i; }    // Dummy loop
  d2:	408c                	lw	a1,0(s1)
  d4:	fdc42783          	lw	a5,-36(s0)
  d8:	02f585bb          	mulw	a1,a1,a5
  dc:	02b05463          	blez	a1,104 <main+0x66>
  e0:	4781                	li	a5,0
  e2:	8626                	mv	a2,s1
  e4:	00279693          	slli	a3,a5,0x2
  e8:	fd043703          	ld	a4,-48(s0)
  ec:	9736                	add	a4,a4,a3
  ee:	c31c                	sw	a5,0(a4)
  f0:	420c                	lw	a1,0(a2)
  f2:	fdc42703          	lw	a4,-36(s0)
  f6:	02e585bb          	mulw	a1,a1,a4
  fa:	0785                	addi	a5,a5,1
  fc:	0007871b          	sext.w	a4,a5
 100:	feb742e3          	blt	a4,a1,e4 <main+0x46>

    // Print out the details of each code component.
    ptinfo("&array[N-1]", &array[gvar*lvar-1]);
 104:	058a                	slli	a1,a1,0x2
 106:	15f1                	addi	a1,a1,-4
 108:	fd043783          	ld	a5,-48(s0)
 10c:	95be                	add	a1,a1,a5
 10e:	00001517          	auipc	a0,0x1
 112:	8ba50513          	addi	a0,a0,-1862 # 9c8 <malloc+0x152>
 116:	00000097          	auipc	ra,0x0
 11a:	eea080e7          	jalr	-278(ra) # 0 <ptinfo>
    ptinfo("array", array);
 11e:	fd043583          	ld	a1,-48(s0)
 122:	00001517          	auipc	a0,0x1
 126:	8b650513          	addi	a0,a0,-1866 # 9d8 <malloc+0x162>
 12a:	00000097          	auipc	ra,0x0
 12e:	ed6080e7          	jalr	-298(ra) # 0 <ptinfo>
    ptinfo("&lvar", &lvar);
 132:	fdc40593          	addi	a1,s0,-36
 136:	00001517          	auipc	a0,0x1
 13a:	8aa50513          	addi	a0,a0,-1878 # 9e0 <malloc+0x16a>
 13e:	00000097          	auipc	ra,0x0
 142:	ec2080e7          	jalr	-318(ra) # 0 <ptinfo>
    ptinfo("&array", &array);
 146:	fd040593          	addi	a1,s0,-48
 14a:	00001517          	auipc	a0,0x1
 14e:	89e50513          	addi	a0,a0,-1890 # 9e8 <malloc+0x172>
 152:	00000097          	auipc	ra,0x0
 156:	eae080e7          	jalr	-338(ra) # 0 <ptinfo>
    ptinfo("&gvar", &gvar);    
 15a:	00001597          	auipc	a1,0x1
 15e:	8e258593          	addi	a1,a1,-1822 # a3c <gvar>
 162:	00001517          	auipc	a0,0x1
 166:	88e50513          	addi	a0,a0,-1906 # 9f0 <malloc+0x17a>
 16a:	00000097          	auipc	ra,0x0
 16e:	e96080e7          	jalr	-362(ra) # 0 <ptinfo>
    ptinfo("&main", &main);
 172:	00000597          	auipc	a1,0x0
 176:	f2c58593          	addi	a1,a1,-212 # 9e <main>
 17a:	00001517          	auipc	a0,0x1
 17e:	87e50513          	addi	a0,a0,-1922 # 9f8 <malloc+0x182>
 182:	00000097          	auipc	ra,0x0
 186:	e7e080e7          	jalr	-386(ra) # 0 <ptinfo>

    // Tell how many pages this program uses.
    printf("Total number of pages = %d\n", pgcnt());
 18a:	00000097          	auipc	ra,0x0
 18e:	34e080e7          	jalr	846(ra) # 4d8 <pgcnt>
 192:	85aa                	mv	a1,a0
 194:	00001517          	auipc	a0,0x1
 198:	86c50513          	addi	a0,a0,-1940 # a00 <malloc+0x18a>
 19c:	00000097          	auipc	ra,0x0
 1a0:	61c080e7          	jalr	1564(ra) # 7b8 <printf>

    free(array);
 1a4:	fd043503          	ld	a0,-48(s0)
 1a8:	00000097          	auipc	ra,0x0
 1ac:	646080e7          	jalr	1606(ra) # 7ee <free>
    exit(0);
 1b0:	4501                	li	a0,0
 1b2:	00000097          	auipc	ra,0x0
 1b6:	276080e7          	jalr	630(ra) # 428 <exit>

00000000000001ba <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1ba:	1141                	addi	sp,sp,-16
 1bc:	e422                	sd	s0,8(sp)
 1be:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1c0:	87aa                	mv	a5,a0
 1c2:	0585                	addi	a1,a1,1
 1c4:	0785                	addi	a5,a5,1
 1c6:	fff5c703          	lbu	a4,-1(a1)
 1ca:	fee78fa3          	sb	a4,-1(a5)
 1ce:	fb75                	bnez	a4,1c2 <strcpy+0x8>
    ;
  return os;
}
 1d0:	6422                	ld	s0,8(sp)
 1d2:	0141                	addi	sp,sp,16
 1d4:	8082                	ret

00000000000001d6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1d6:	1141                	addi	sp,sp,-16
 1d8:	e422                	sd	s0,8(sp)
 1da:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1dc:	00054783          	lbu	a5,0(a0)
 1e0:	cb91                	beqz	a5,1f4 <strcmp+0x1e>
 1e2:	0005c703          	lbu	a4,0(a1)
 1e6:	00f71763          	bne	a4,a5,1f4 <strcmp+0x1e>
    p++, q++;
 1ea:	0505                	addi	a0,a0,1
 1ec:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1ee:	00054783          	lbu	a5,0(a0)
 1f2:	fbe5                	bnez	a5,1e2 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1f4:	0005c503          	lbu	a0,0(a1)
}
 1f8:	40a7853b          	subw	a0,a5,a0
 1fc:	6422                	ld	s0,8(sp)
 1fe:	0141                	addi	sp,sp,16
 200:	8082                	ret

0000000000000202 <strlen>:

uint
strlen(const char *s)
{
 202:	1141                	addi	sp,sp,-16
 204:	e422                	sd	s0,8(sp)
 206:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 208:	00054783          	lbu	a5,0(a0)
 20c:	cf91                	beqz	a5,228 <strlen+0x26>
 20e:	0505                	addi	a0,a0,1
 210:	87aa                	mv	a5,a0
 212:	4685                	li	a3,1
 214:	9e89                	subw	a3,a3,a0
 216:	00f6853b          	addw	a0,a3,a5
 21a:	0785                	addi	a5,a5,1
 21c:	fff7c703          	lbu	a4,-1(a5)
 220:	fb7d                	bnez	a4,216 <strlen+0x14>
    ;
  return n;
}
 222:	6422                	ld	s0,8(sp)
 224:	0141                	addi	sp,sp,16
 226:	8082                	ret
  for(n = 0; s[n]; n++)
 228:	4501                	li	a0,0
 22a:	bfe5                	j	222 <strlen+0x20>

000000000000022c <memset>:

void*
memset(void *dst, int c, uint n)
{
 22c:	1141                	addi	sp,sp,-16
 22e:	e422                	sd	s0,8(sp)
 230:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 232:	ca19                	beqz	a2,248 <memset+0x1c>
 234:	87aa                	mv	a5,a0
 236:	1602                	slli	a2,a2,0x20
 238:	9201                	srli	a2,a2,0x20
 23a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 23e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 242:	0785                	addi	a5,a5,1
 244:	fee79de3          	bne	a5,a4,23e <memset+0x12>
  }
  return dst;
}
 248:	6422                	ld	s0,8(sp)
 24a:	0141                	addi	sp,sp,16
 24c:	8082                	ret

000000000000024e <strchr>:

char*
strchr(const char *s, char c)
{
 24e:	1141                	addi	sp,sp,-16
 250:	e422                	sd	s0,8(sp)
 252:	0800                	addi	s0,sp,16
  for(; *s; s++)
 254:	00054783          	lbu	a5,0(a0)
 258:	cb99                	beqz	a5,26e <strchr+0x20>
    if(*s == c)
 25a:	00f58763          	beq	a1,a5,268 <strchr+0x1a>
  for(; *s; s++)
 25e:	0505                	addi	a0,a0,1
 260:	00054783          	lbu	a5,0(a0)
 264:	fbfd                	bnez	a5,25a <strchr+0xc>
      return (char*)s;
  return 0;
 266:	4501                	li	a0,0
}
 268:	6422                	ld	s0,8(sp)
 26a:	0141                	addi	sp,sp,16
 26c:	8082                	ret
  return 0;
 26e:	4501                	li	a0,0
 270:	bfe5                	j	268 <strchr+0x1a>

0000000000000272 <gets>:

char*
gets(char *buf, int max)
{
 272:	711d                	addi	sp,sp,-96
 274:	ec86                	sd	ra,88(sp)
 276:	e8a2                	sd	s0,80(sp)
 278:	e4a6                	sd	s1,72(sp)
 27a:	e0ca                	sd	s2,64(sp)
 27c:	fc4e                	sd	s3,56(sp)
 27e:	f852                	sd	s4,48(sp)
 280:	f456                	sd	s5,40(sp)
 282:	f05a                	sd	s6,32(sp)
 284:	ec5e                	sd	s7,24(sp)
 286:	1080                	addi	s0,sp,96
 288:	8baa                	mv	s7,a0
 28a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 28c:	892a                	mv	s2,a0
 28e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 290:	4aa9                	li	s5,10
 292:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 294:	89a6                	mv	s3,s1
 296:	2485                	addiw	s1,s1,1
 298:	0344d863          	bge	s1,s4,2c8 <gets+0x56>
    cc = read(0, &c, 1);
 29c:	4605                	li	a2,1
 29e:	faf40593          	addi	a1,s0,-81
 2a2:	4501                	li	a0,0
 2a4:	00000097          	auipc	ra,0x0
 2a8:	19c080e7          	jalr	412(ra) # 440 <read>
    if(cc < 1)
 2ac:	00a05e63          	blez	a0,2c8 <gets+0x56>
    buf[i++] = c;
 2b0:	faf44783          	lbu	a5,-81(s0)
 2b4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2b8:	01578763          	beq	a5,s5,2c6 <gets+0x54>
 2bc:	0905                	addi	s2,s2,1
 2be:	fd679be3          	bne	a5,s6,294 <gets+0x22>
  for(i=0; i+1 < max; ){
 2c2:	89a6                	mv	s3,s1
 2c4:	a011                	j	2c8 <gets+0x56>
 2c6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2c8:	99de                	add	s3,s3,s7
 2ca:	00098023          	sb	zero,0(s3)
  return buf;
}
 2ce:	855e                	mv	a0,s7
 2d0:	60e6                	ld	ra,88(sp)
 2d2:	6446                	ld	s0,80(sp)
 2d4:	64a6                	ld	s1,72(sp)
 2d6:	6906                	ld	s2,64(sp)
 2d8:	79e2                	ld	s3,56(sp)
 2da:	7a42                	ld	s4,48(sp)
 2dc:	7aa2                	ld	s5,40(sp)
 2de:	7b02                	ld	s6,32(sp)
 2e0:	6be2                	ld	s7,24(sp)
 2e2:	6125                	addi	sp,sp,96
 2e4:	8082                	ret

00000000000002e6 <stat>:

int
stat(const char *n, struct stat *st)
{
 2e6:	1101                	addi	sp,sp,-32
 2e8:	ec06                	sd	ra,24(sp)
 2ea:	e822                	sd	s0,16(sp)
 2ec:	e426                	sd	s1,8(sp)
 2ee:	e04a                	sd	s2,0(sp)
 2f0:	1000                	addi	s0,sp,32
 2f2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2f4:	4581                	li	a1,0
 2f6:	00000097          	auipc	ra,0x0
 2fa:	172080e7          	jalr	370(ra) # 468 <open>
  if(fd < 0)
 2fe:	02054563          	bltz	a0,328 <stat+0x42>
 302:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 304:	85ca                	mv	a1,s2
 306:	00000097          	auipc	ra,0x0
 30a:	17a080e7          	jalr	378(ra) # 480 <fstat>
 30e:	892a                	mv	s2,a0
  close(fd);
 310:	8526                	mv	a0,s1
 312:	00000097          	auipc	ra,0x0
 316:	13e080e7          	jalr	318(ra) # 450 <close>
  return r;
}
 31a:	854a                	mv	a0,s2
 31c:	60e2                	ld	ra,24(sp)
 31e:	6442                	ld	s0,16(sp)
 320:	64a2                	ld	s1,8(sp)
 322:	6902                	ld	s2,0(sp)
 324:	6105                	addi	sp,sp,32
 326:	8082                	ret
    return -1;
 328:	597d                	li	s2,-1
 32a:	bfc5                	j	31a <stat+0x34>

000000000000032c <atoi>:

int
atoi(const char *s)
{
 32c:	1141                	addi	sp,sp,-16
 32e:	e422                	sd	s0,8(sp)
 330:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 332:	00054603          	lbu	a2,0(a0)
 336:	fd06079b          	addiw	a5,a2,-48
 33a:	0ff7f793          	andi	a5,a5,255
 33e:	4725                	li	a4,9
 340:	02f76963          	bltu	a4,a5,372 <atoi+0x46>
 344:	86aa                	mv	a3,a0
  n = 0;
 346:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 348:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 34a:	0685                	addi	a3,a3,1
 34c:	0025179b          	slliw	a5,a0,0x2
 350:	9fa9                	addw	a5,a5,a0
 352:	0017979b          	slliw	a5,a5,0x1
 356:	9fb1                	addw	a5,a5,a2
 358:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 35c:	0006c603          	lbu	a2,0(a3)
 360:	fd06071b          	addiw	a4,a2,-48
 364:	0ff77713          	andi	a4,a4,255
 368:	fee5f1e3          	bgeu	a1,a4,34a <atoi+0x1e>
  return n;
}
 36c:	6422                	ld	s0,8(sp)
 36e:	0141                	addi	sp,sp,16
 370:	8082                	ret
  n = 0;
 372:	4501                	li	a0,0
 374:	bfe5                	j	36c <atoi+0x40>

0000000000000376 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 376:	1141                	addi	sp,sp,-16
 378:	e422                	sd	s0,8(sp)
 37a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 37c:	02b57463          	bgeu	a0,a1,3a4 <memmove+0x2e>
    while(n-- > 0)
 380:	00c05f63          	blez	a2,39e <memmove+0x28>
 384:	1602                	slli	a2,a2,0x20
 386:	9201                	srli	a2,a2,0x20
 388:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 38c:	872a                	mv	a4,a0
      *dst++ = *src++;
 38e:	0585                	addi	a1,a1,1
 390:	0705                	addi	a4,a4,1
 392:	fff5c683          	lbu	a3,-1(a1)
 396:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 39a:	fee79ae3          	bne	a5,a4,38e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 39e:	6422                	ld	s0,8(sp)
 3a0:	0141                	addi	sp,sp,16
 3a2:	8082                	ret
    dst += n;
 3a4:	00c50733          	add	a4,a0,a2
    src += n;
 3a8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3aa:	fec05ae3          	blez	a2,39e <memmove+0x28>
 3ae:	fff6079b          	addiw	a5,a2,-1
 3b2:	1782                	slli	a5,a5,0x20
 3b4:	9381                	srli	a5,a5,0x20
 3b6:	fff7c793          	not	a5,a5
 3ba:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3bc:	15fd                	addi	a1,a1,-1
 3be:	177d                	addi	a4,a4,-1
 3c0:	0005c683          	lbu	a3,0(a1)
 3c4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3c8:	fee79ae3          	bne	a5,a4,3bc <memmove+0x46>
 3cc:	bfc9                	j	39e <memmove+0x28>

00000000000003ce <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3ce:	1141                	addi	sp,sp,-16
 3d0:	e422                	sd	s0,8(sp)
 3d2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3d4:	ca05                	beqz	a2,404 <memcmp+0x36>
 3d6:	fff6069b          	addiw	a3,a2,-1
 3da:	1682                	slli	a3,a3,0x20
 3dc:	9281                	srli	a3,a3,0x20
 3de:	0685                	addi	a3,a3,1
 3e0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3e2:	00054783          	lbu	a5,0(a0)
 3e6:	0005c703          	lbu	a4,0(a1)
 3ea:	00e79863          	bne	a5,a4,3fa <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3ee:	0505                	addi	a0,a0,1
    p2++;
 3f0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3f2:	fed518e3          	bne	a0,a3,3e2 <memcmp+0x14>
  }
  return 0;
 3f6:	4501                	li	a0,0
 3f8:	a019                	j	3fe <memcmp+0x30>
      return *p1 - *p2;
 3fa:	40e7853b          	subw	a0,a5,a4
}
 3fe:	6422                	ld	s0,8(sp)
 400:	0141                	addi	sp,sp,16
 402:	8082                	ret
  return 0;
 404:	4501                	li	a0,0
 406:	bfe5                	j	3fe <memcmp+0x30>

0000000000000408 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 408:	1141                	addi	sp,sp,-16
 40a:	e406                	sd	ra,8(sp)
 40c:	e022                	sd	s0,0(sp)
 40e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 410:	00000097          	auipc	ra,0x0
 414:	f66080e7          	jalr	-154(ra) # 376 <memmove>
}
 418:	60a2                	ld	ra,8(sp)
 41a:	6402                	ld	s0,0(sp)
 41c:	0141                	addi	sp,sp,16
 41e:	8082                	ret

0000000000000420 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 420:	4885                	li	a7,1
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <exit>:
.global exit
exit:
 li a7, SYS_exit
 428:	4889                	li	a7,2
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <wait>:
.global wait
wait:
 li a7, SYS_wait
 430:	488d                	li	a7,3
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 438:	4891                	li	a7,4
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <read>:
.global read
read:
 li a7, SYS_read
 440:	4895                	li	a7,5
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <write>:
.global write
write:
 li a7, SYS_write
 448:	48c1                	li	a7,16
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <close>:
.global close
close:
 li a7, SYS_close
 450:	48d5                	li	a7,21
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <kill>:
.global kill
kill:
 li a7, SYS_kill
 458:	4899                	li	a7,6
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <exec>:
.global exec
exec:
 li a7, SYS_exec
 460:	489d                	li	a7,7
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <open>:
.global open
open:
 li a7, SYS_open
 468:	48bd                	li	a7,15
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 470:	48c5                	li	a7,17
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 478:	48c9                	li	a7,18
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 480:	48a1                	li	a7,8
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <link>:
.global link
link:
 li a7, SYS_link
 488:	48cd                	li	a7,19
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 490:	48d1                	li	a7,20
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 498:	48a5                	li	a7,9
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 4a0:	48a9                	li	a7,10
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4a8:	48ad                	li	a7,11
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4b0:	48b1                	li	a7,12
 ecall
 4b2:	00000073          	ecall
 ret
 4b6:	8082                	ret

00000000000004b8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4b8:	48b5                	li	a7,13
 ecall
 4ba:	00000073          	ecall
 ret
 4be:	8082                	ret

00000000000004c0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4c0:	48b9                	li	a7,14
 ecall
 4c2:	00000073          	ecall
 ret
 4c6:	8082                	ret

00000000000004c8 <phyaddr>:
.global phyaddr
phyaddr:
 li a7, SYS_phyaddr
 4c8:	48d9                	li	a7,22
 ecall
 4ca:	00000073          	ecall
 ret
 4ce:	8082                	ret

00000000000004d0 <ptidx>:
.global ptidx
ptidx:
 li a7, SYS_ptidx
 4d0:	48dd                	li	a7,23
 ecall
 4d2:	00000073          	ecall
 ret
 4d6:	8082                	ret

00000000000004d8 <pgcnt>:
.global pgcnt
pgcnt:
 li a7, SYS_pgcnt
 4d8:	48e1                	li	a7,24
 ecall
 4da:	00000073          	ecall
 ret
 4de:	8082                	ret

00000000000004e0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4e0:	1101                	addi	sp,sp,-32
 4e2:	ec06                	sd	ra,24(sp)
 4e4:	e822                	sd	s0,16(sp)
 4e6:	1000                	addi	s0,sp,32
 4e8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4ec:	4605                	li	a2,1
 4ee:	fef40593          	addi	a1,s0,-17
 4f2:	00000097          	auipc	ra,0x0
 4f6:	f56080e7          	jalr	-170(ra) # 448 <write>
}
 4fa:	60e2                	ld	ra,24(sp)
 4fc:	6442                	ld	s0,16(sp)
 4fe:	6105                	addi	sp,sp,32
 500:	8082                	ret

0000000000000502 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 502:	7139                	addi	sp,sp,-64
 504:	fc06                	sd	ra,56(sp)
 506:	f822                	sd	s0,48(sp)
 508:	f426                	sd	s1,40(sp)
 50a:	f04a                	sd	s2,32(sp)
 50c:	ec4e                	sd	s3,24(sp)
 50e:	0080                	addi	s0,sp,64
 510:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 512:	c299                	beqz	a3,518 <printint+0x16>
 514:	0805c863          	bltz	a1,5a4 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 518:	2581                	sext.w	a1,a1
  neg = 0;
 51a:	4881                	li	a7,0
 51c:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 520:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 522:	2601                	sext.w	a2,a2
 524:	00000517          	auipc	a0,0x0
 528:	50450513          	addi	a0,a0,1284 # a28 <digits>
 52c:	883a                	mv	a6,a4
 52e:	2705                	addiw	a4,a4,1
 530:	02c5f7bb          	remuw	a5,a1,a2
 534:	1782                	slli	a5,a5,0x20
 536:	9381                	srli	a5,a5,0x20
 538:	97aa                	add	a5,a5,a0
 53a:	0007c783          	lbu	a5,0(a5)
 53e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 542:	0005879b          	sext.w	a5,a1
 546:	02c5d5bb          	divuw	a1,a1,a2
 54a:	0685                	addi	a3,a3,1
 54c:	fec7f0e3          	bgeu	a5,a2,52c <printint+0x2a>
  if(neg)
 550:	00088b63          	beqz	a7,566 <printint+0x64>
    buf[i++] = '-';
 554:	fd040793          	addi	a5,s0,-48
 558:	973e                	add	a4,a4,a5
 55a:	02d00793          	li	a5,45
 55e:	fef70823          	sb	a5,-16(a4)
 562:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 566:	02e05863          	blez	a4,596 <printint+0x94>
 56a:	fc040793          	addi	a5,s0,-64
 56e:	00e78933          	add	s2,a5,a4
 572:	fff78993          	addi	s3,a5,-1
 576:	99ba                	add	s3,s3,a4
 578:	377d                	addiw	a4,a4,-1
 57a:	1702                	slli	a4,a4,0x20
 57c:	9301                	srli	a4,a4,0x20
 57e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 582:	fff94583          	lbu	a1,-1(s2)
 586:	8526                	mv	a0,s1
 588:	00000097          	auipc	ra,0x0
 58c:	f58080e7          	jalr	-168(ra) # 4e0 <putc>
  while(--i >= 0)
 590:	197d                	addi	s2,s2,-1
 592:	ff3918e3          	bne	s2,s3,582 <printint+0x80>
}
 596:	70e2                	ld	ra,56(sp)
 598:	7442                	ld	s0,48(sp)
 59a:	74a2                	ld	s1,40(sp)
 59c:	7902                	ld	s2,32(sp)
 59e:	69e2                	ld	s3,24(sp)
 5a0:	6121                	addi	sp,sp,64
 5a2:	8082                	ret
    x = -xx;
 5a4:	40b005bb          	negw	a1,a1
    neg = 1;
 5a8:	4885                	li	a7,1
    x = -xx;
 5aa:	bf8d                	j	51c <printint+0x1a>

00000000000005ac <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5ac:	7119                	addi	sp,sp,-128
 5ae:	fc86                	sd	ra,120(sp)
 5b0:	f8a2                	sd	s0,112(sp)
 5b2:	f4a6                	sd	s1,104(sp)
 5b4:	f0ca                	sd	s2,96(sp)
 5b6:	ecce                	sd	s3,88(sp)
 5b8:	e8d2                	sd	s4,80(sp)
 5ba:	e4d6                	sd	s5,72(sp)
 5bc:	e0da                	sd	s6,64(sp)
 5be:	fc5e                	sd	s7,56(sp)
 5c0:	f862                	sd	s8,48(sp)
 5c2:	f466                	sd	s9,40(sp)
 5c4:	f06a                	sd	s10,32(sp)
 5c6:	ec6e                	sd	s11,24(sp)
 5c8:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5ca:	0005c903          	lbu	s2,0(a1)
 5ce:	18090f63          	beqz	s2,76c <vprintf+0x1c0>
 5d2:	8aaa                	mv	s5,a0
 5d4:	8b32                	mv	s6,a2
 5d6:	00158493          	addi	s1,a1,1
  state = 0;
 5da:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5dc:	02500a13          	li	s4,37
      if(c == 'd'){
 5e0:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5e4:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5e8:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5ec:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5f0:	00000b97          	auipc	s7,0x0
 5f4:	438b8b93          	addi	s7,s7,1080 # a28 <digits>
 5f8:	a839                	j	616 <vprintf+0x6a>
        putc(fd, c);
 5fa:	85ca                	mv	a1,s2
 5fc:	8556                	mv	a0,s5
 5fe:	00000097          	auipc	ra,0x0
 602:	ee2080e7          	jalr	-286(ra) # 4e0 <putc>
 606:	a019                	j	60c <vprintf+0x60>
    } else if(state == '%'){
 608:	01498f63          	beq	s3,s4,626 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 60c:	0485                	addi	s1,s1,1
 60e:	fff4c903          	lbu	s2,-1(s1)
 612:	14090d63          	beqz	s2,76c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 616:	0009079b          	sext.w	a5,s2
    if(state == 0){
 61a:	fe0997e3          	bnez	s3,608 <vprintf+0x5c>
      if(c == '%'){
 61e:	fd479ee3          	bne	a5,s4,5fa <vprintf+0x4e>
        state = '%';
 622:	89be                	mv	s3,a5
 624:	b7e5                	j	60c <vprintf+0x60>
      if(c == 'd'){
 626:	05878063          	beq	a5,s8,666 <vprintf+0xba>
      } else if(c == 'l') {
 62a:	05978c63          	beq	a5,s9,682 <vprintf+0xd6>
      } else if(c == 'x') {
 62e:	07a78863          	beq	a5,s10,69e <vprintf+0xf2>
      } else if(c == 'p') {
 632:	09b78463          	beq	a5,s11,6ba <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 636:	07300713          	li	a4,115
 63a:	0ce78663          	beq	a5,a4,706 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 63e:	06300713          	li	a4,99
 642:	0ee78e63          	beq	a5,a4,73e <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 646:	11478863          	beq	a5,s4,756 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 64a:	85d2                	mv	a1,s4
 64c:	8556                	mv	a0,s5
 64e:	00000097          	auipc	ra,0x0
 652:	e92080e7          	jalr	-366(ra) # 4e0 <putc>
        putc(fd, c);
 656:	85ca                	mv	a1,s2
 658:	8556                	mv	a0,s5
 65a:	00000097          	auipc	ra,0x0
 65e:	e86080e7          	jalr	-378(ra) # 4e0 <putc>
      }
      state = 0;
 662:	4981                	li	s3,0
 664:	b765                	j	60c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 666:	008b0913          	addi	s2,s6,8
 66a:	4685                	li	a3,1
 66c:	4629                	li	a2,10
 66e:	000b2583          	lw	a1,0(s6)
 672:	8556                	mv	a0,s5
 674:	00000097          	auipc	ra,0x0
 678:	e8e080e7          	jalr	-370(ra) # 502 <printint>
 67c:	8b4a                	mv	s6,s2
      state = 0;
 67e:	4981                	li	s3,0
 680:	b771                	j	60c <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 682:	008b0913          	addi	s2,s6,8
 686:	4681                	li	a3,0
 688:	4629                	li	a2,10
 68a:	000b2583          	lw	a1,0(s6)
 68e:	8556                	mv	a0,s5
 690:	00000097          	auipc	ra,0x0
 694:	e72080e7          	jalr	-398(ra) # 502 <printint>
 698:	8b4a                	mv	s6,s2
      state = 0;
 69a:	4981                	li	s3,0
 69c:	bf85                	j	60c <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 69e:	008b0913          	addi	s2,s6,8
 6a2:	4681                	li	a3,0
 6a4:	4641                	li	a2,16
 6a6:	000b2583          	lw	a1,0(s6)
 6aa:	8556                	mv	a0,s5
 6ac:	00000097          	auipc	ra,0x0
 6b0:	e56080e7          	jalr	-426(ra) # 502 <printint>
 6b4:	8b4a                	mv	s6,s2
      state = 0;
 6b6:	4981                	li	s3,0
 6b8:	bf91                	j	60c <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6ba:	008b0793          	addi	a5,s6,8
 6be:	f8f43423          	sd	a5,-120(s0)
 6c2:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6c6:	03000593          	li	a1,48
 6ca:	8556                	mv	a0,s5
 6cc:	00000097          	auipc	ra,0x0
 6d0:	e14080e7          	jalr	-492(ra) # 4e0 <putc>
  putc(fd, 'x');
 6d4:	85ea                	mv	a1,s10
 6d6:	8556                	mv	a0,s5
 6d8:	00000097          	auipc	ra,0x0
 6dc:	e08080e7          	jalr	-504(ra) # 4e0 <putc>
 6e0:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6e2:	03c9d793          	srli	a5,s3,0x3c
 6e6:	97de                	add	a5,a5,s7
 6e8:	0007c583          	lbu	a1,0(a5)
 6ec:	8556                	mv	a0,s5
 6ee:	00000097          	auipc	ra,0x0
 6f2:	df2080e7          	jalr	-526(ra) # 4e0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6f6:	0992                	slli	s3,s3,0x4
 6f8:	397d                	addiw	s2,s2,-1
 6fa:	fe0914e3          	bnez	s2,6e2 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6fe:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 702:	4981                	li	s3,0
 704:	b721                	j	60c <vprintf+0x60>
        s = va_arg(ap, char*);
 706:	008b0993          	addi	s3,s6,8
 70a:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 70e:	02090163          	beqz	s2,730 <vprintf+0x184>
        while(*s != 0){
 712:	00094583          	lbu	a1,0(s2)
 716:	c9a1                	beqz	a1,766 <vprintf+0x1ba>
          putc(fd, *s);
 718:	8556                	mv	a0,s5
 71a:	00000097          	auipc	ra,0x0
 71e:	dc6080e7          	jalr	-570(ra) # 4e0 <putc>
          s++;
 722:	0905                	addi	s2,s2,1
        while(*s != 0){
 724:	00094583          	lbu	a1,0(s2)
 728:	f9e5                	bnez	a1,718 <vprintf+0x16c>
        s = va_arg(ap, char*);
 72a:	8b4e                	mv	s6,s3
      state = 0;
 72c:	4981                	li	s3,0
 72e:	bdf9                	j	60c <vprintf+0x60>
          s = "(null)";
 730:	00000917          	auipc	s2,0x0
 734:	2f090913          	addi	s2,s2,752 # a20 <malloc+0x1aa>
        while(*s != 0){
 738:	02800593          	li	a1,40
 73c:	bff1                	j	718 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 73e:	008b0913          	addi	s2,s6,8
 742:	000b4583          	lbu	a1,0(s6)
 746:	8556                	mv	a0,s5
 748:	00000097          	auipc	ra,0x0
 74c:	d98080e7          	jalr	-616(ra) # 4e0 <putc>
 750:	8b4a                	mv	s6,s2
      state = 0;
 752:	4981                	li	s3,0
 754:	bd65                	j	60c <vprintf+0x60>
        putc(fd, c);
 756:	85d2                	mv	a1,s4
 758:	8556                	mv	a0,s5
 75a:	00000097          	auipc	ra,0x0
 75e:	d86080e7          	jalr	-634(ra) # 4e0 <putc>
      state = 0;
 762:	4981                	li	s3,0
 764:	b565                	j	60c <vprintf+0x60>
        s = va_arg(ap, char*);
 766:	8b4e                	mv	s6,s3
      state = 0;
 768:	4981                	li	s3,0
 76a:	b54d                	j	60c <vprintf+0x60>
    }
  }
}
 76c:	70e6                	ld	ra,120(sp)
 76e:	7446                	ld	s0,112(sp)
 770:	74a6                	ld	s1,104(sp)
 772:	7906                	ld	s2,96(sp)
 774:	69e6                	ld	s3,88(sp)
 776:	6a46                	ld	s4,80(sp)
 778:	6aa6                	ld	s5,72(sp)
 77a:	6b06                	ld	s6,64(sp)
 77c:	7be2                	ld	s7,56(sp)
 77e:	7c42                	ld	s8,48(sp)
 780:	7ca2                	ld	s9,40(sp)
 782:	7d02                	ld	s10,32(sp)
 784:	6de2                	ld	s11,24(sp)
 786:	6109                	addi	sp,sp,128
 788:	8082                	ret

000000000000078a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 78a:	715d                	addi	sp,sp,-80
 78c:	ec06                	sd	ra,24(sp)
 78e:	e822                	sd	s0,16(sp)
 790:	1000                	addi	s0,sp,32
 792:	e010                	sd	a2,0(s0)
 794:	e414                	sd	a3,8(s0)
 796:	e818                	sd	a4,16(s0)
 798:	ec1c                	sd	a5,24(s0)
 79a:	03043023          	sd	a6,32(s0)
 79e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7a2:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7a6:	8622                	mv	a2,s0
 7a8:	00000097          	auipc	ra,0x0
 7ac:	e04080e7          	jalr	-508(ra) # 5ac <vprintf>
}
 7b0:	60e2                	ld	ra,24(sp)
 7b2:	6442                	ld	s0,16(sp)
 7b4:	6161                	addi	sp,sp,80
 7b6:	8082                	ret

00000000000007b8 <printf>:

void
printf(const char *fmt, ...)
{
 7b8:	711d                	addi	sp,sp,-96
 7ba:	ec06                	sd	ra,24(sp)
 7bc:	e822                	sd	s0,16(sp)
 7be:	1000                	addi	s0,sp,32
 7c0:	e40c                	sd	a1,8(s0)
 7c2:	e810                	sd	a2,16(s0)
 7c4:	ec14                	sd	a3,24(s0)
 7c6:	f018                	sd	a4,32(s0)
 7c8:	f41c                	sd	a5,40(s0)
 7ca:	03043823          	sd	a6,48(s0)
 7ce:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7d2:	00840613          	addi	a2,s0,8
 7d6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7da:	85aa                	mv	a1,a0
 7dc:	4505                	li	a0,1
 7de:	00000097          	auipc	ra,0x0
 7e2:	dce080e7          	jalr	-562(ra) # 5ac <vprintf>
}
 7e6:	60e2                	ld	ra,24(sp)
 7e8:	6442                	ld	s0,16(sp)
 7ea:	6125                	addi	sp,sp,96
 7ec:	8082                	ret

00000000000007ee <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7ee:	1141                	addi	sp,sp,-16
 7f0:	e422                	sd	s0,8(sp)
 7f2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7f4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7f8:	00000797          	auipc	a5,0x0
 7fc:	2487b783          	ld	a5,584(a5) # a40 <freep>
 800:	a805                	j	830 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 802:	4618                	lw	a4,8(a2)
 804:	9db9                	addw	a1,a1,a4
 806:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 80a:	6398                	ld	a4,0(a5)
 80c:	6318                	ld	a4,0(a4)
 80e:	fee53823          	sd	a4,-16(a0)
 812:	a091                	j	856 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 814:	ff852703          	lw	a4,-8(a0)
 818:	9e39                	addw	a2,a2,a4
 81a:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 81c:	ff053703          	ld	a4,-16(a0)
 820:	e398                	sd	a4,0(a5)
 822:	a099                	j	868 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 824:	6398                	ld	a4,0(a5)
 826:	00e7e463          	bltu	a5,a4,82e <free+0x40>
 82a:	00e6ea63          	bltu	a3,a4,83e <free+0x50>
{
 82e:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 830:	fed7fae3          	bgeu	a5,a3,824 <free+0x36>
 834:	6398                	ld	a4,0(a5)
 836:	00e6e463          	bltu	a3,a4,83e <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 83a:	fee7eae3          	bltu	a5,a4,82e <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 83e:	ff852583          	lw	a1,-8(a0)
 842:	6390                	ld	a2,0(a5)
 844:	02059813          	slli	a6,a1,0x20
 848:	01c85713          	srli	a4,a6,0x1c
 84c:	9736                	add	a4,a4,a3
 84e:	fae60ae3          	beq	a2,a4,802 <free+0x14>
    bp->s.ptr = p->s.ptr;
 852:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 856:	4790                	lw	a2,8(a5)
 858:	02061593          	slli	a1,a2,0x20
 85c:	01c5d713          	srli	a4,a1,0x1c
 860:	973e                	add	a4,a4,a5
 862:	fae689e3          	beq	a3,a4,814 <free+0x26>
  } else
    p->s.ptr = bp;
 866:	e394                	sd	a3,0(a5)
  freep = p;
 868:	00000717          	auipc	a4,0x0
 86c:	1cf73c23          	sd	a5,472(a4) # a40 <freep>
}
 870:	6422                	ld	s0,8(sp)
 872:	0141                	addi	sp,sp,16
 874:	8082                	ret

0000000000000876 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 876:	7139                	addi	sp,sp,-64
 878:	fc06                	sd	ra,56(sp)
 87a:	f822                	sd	s0,48(sp)
 87c:	f426                	sd	s1,40(sp)
 87e:	f04a                	sd	s2,32(sp)
 880:	ec4e                	sd	s3,24(sp)
 882:	e852                	sd	s4,16(sp)
 884:	e456                	sd	s5,8(sp)
 886:	e05a                	sd	s6,0(sp)
 888:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 88a:	02051493          	slli	s1,a0,0x20
 88e:	9081                	srli	s1,s1,0x20
 890:	04bd                	addi	s1,s1,15
 892:	8091                	srli	s1,s1,0x4
 894:	0014899b          	addiw	s3,s1,1
 898:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 89a:	00000517          	auipc	a0,0x0
 89e:	1a653503          	ld	a0,422(a0) # a40 <freep>
 8a2:	c515                	beqz	a0,8ce <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8a4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8a6:	4798                	lw	a4,8(a5)
 8a8:	02977f63          	bgeu	a4,s1,8e6 <malloc+0x70>
 8ac:	8a4e                	mv	s4,s3
 8ae:	0009871b          	sext.w	a4,s3
 8b2:	6685                	lui	a3,0x1
 8b4:	00d77363          	bgeu	a4,a3,8ba <malloc+0x44>
 8b8:	6a05                	lui	s4,0x1
 8ba:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8be:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8c2:	00000917          	auipc	s2,0x0
 8c6:	17e90913          	addi	s2,s2,382 # a40 <freep>
  if(p == (char*)-1)
 8ca:	5afd                	li	s5,-1
 8cc:	a895                	j	940 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 8ce:	00000797          	auipc	a5,0x0
 8d2:	17a78793          	addi	a5,a5,378 # a48 <base>
 8d6:	00000717          	auipc	a4,0x0
 8da:	16f73523          	sd	a5,362(a4) # a40 <freep>
 8de:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8e0:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8e4:	b7e1                	j	8ac <malloc+0x36>
      if(p->s.size == nunits)
 8e6:	02e48c63          	beq	s1,a4,91e <malloc+0xa8>
        p->s.size -= nunits;
 8ea:	4137073b          	subw	a4,a4,s3
 8ee:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8f0:	02071693          	slli	a3,a4,0x20
 8f4:	01c6d713          	srli	a4,a3,0x1c
 8f8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8fa:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8fe:	00000717          	auipc	a4,0x0
 902:	14a73123          	sd	a0,322(a4) # a40 <freep>
      return (void*)(p + 1);
 906:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 90a:	70e2                	ld	ra,56(sp)
 90c:	7442                	ld	s0,48(sp)
 90e:	74a2                	ld	s1,40(sp)
 910:	7902                	ld	s2,32(sp)
 912:	69e2                	ld	s3,24(sp)
 914:	6a42                	ld	s4,16(sp)
 916:	6aa2                	ld	s5,8(sp)
 918:	6b02                	ld	s6,0(sp)
 91a:	6121                	addi	sp,sp,64
 91c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 91e:	6398                	ld	a4,0(a5)
 920:	e118                	sd	a4,0(a0)
 922:	bff1                	j	8fe <malloc+0x88>
  hp->s.size = nu;
 924:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 928:	0541                	addi	a0,a0,16
 92a:	00000097          	auipc	ra,0x0
 92e:	ec4080e7          	jalr	-316(ra) # 7ee <free>
  return freep;
 932:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 936:	d971                	beqz	a0,90a <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 938:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 93a:	4798                	lw	a4,8(a5)
 93c:	fa9775e3          	bgeu	a4,s1,8e6 <malloc+0x70>
    if(p == freep)
 940:	00093703          	ld	a4,0(s2)
 944:	853e                	mv	a0,a5
 946:	fef719e3          	bne	a4,a5,938 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 94a:	8552                	mv	a0,s4
 94c:	00000097          	auipc	ra,0x0
 950:	b64080e7          	jalr	-1180(ra) # 4b0 <sbrk>
  if(p == (char*)-1)
 954:	fd5518e3          	bne	a0,s5,924 <malloc+0xae>
        return 0;
 958:	4501                	li	a0,0
 95a:	bf45                	j	90a <malloc+0x94>
