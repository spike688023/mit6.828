
obj/user/breakpoint:     file format elf32-i386


Disassembly of section .text:

00800020 <_start>:
// starts us running when we are initially loaded into a new environment.
.text
.globl _start
_start:
	// See if we were started with arguments on the stack
	cmpl $USTACKTOP, %esp
  800020:	81 fc 00 e0 bf ee    	cmp    $0xeebfe000,%esp
	jne args_exist
  800026:	75 04                	jne    80002c <args_exist>

	// If not, push dummy argc/argv arguments.
	// This happens when we are loaded by the kernel,
	// because the kernel does not know about passing arguments.
	pushl $0
  800028:	6a 00                	push   $0x0
	pushl $0
  80002a:	6a 00                	push   $0x0

0080002c <args_exist>:

args_exist:
	call libmain
  80002c:	e8 08 00 00 00       	call   800039 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	asm volatile("int $3");
  800036:	cc                   	int3   
}
  800037:	5d                   	pop    %ebp
  800038:	c3                   	ret    

00800039 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800039:	55                   	push   %ebp
  80003a:	89 e5                	mov    %esp,%ebp
  80003c:	56                   	push   %esi
  80003d:	53                   	push   %ebx
  80003e:	83 ec 10             	sub    $0x10,%esp
  800041:	8b 5d 08             	mov    0x8(%ebp),%ebx
  800044:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  800047:	e8 db 00 00 00       	call   800127 <sys_getenvid>
  80004c:	25 ff 03 00 00       	and    $0x3ff,%eax
  800051:	8d 04 40             	lea    (%eax,%eax,2),%eax
  800054:	c1 e0 05             	shl    $0x5,%eax
  800057:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  80005c:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800061:	85 db                	test   %ebx,%ebx
  800063:	7e 07                	jle    80006c <libmain+0x33>
		binaryname = argv[0];
  800065:	8b 06                	mov    (%esi),%eax
  800067:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  80006c:	89 74 24 04          	mov    %esi,0x4(%esp)
  800070:	89 1c 24             	mov    %ebx,(%esp)
  800073:	e8 bb ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800078:	e8 07 00 00 00       	call   800084 <exit>
}
  80007d:	83 c4 10             	add    $0x10,%esp
  800080:	5b                   	pop    %ebx
  800081:	5e                   	pop    %esi
  800082:	5d                   	pop    %ebp
  800083:	c3                   	ret    

00800084 <exit>:

#include <inc/lib.h>

void
exit(void)
{
  800084:	55                   	push   %ebp
  800085:	89 e5                	mov    %esp,%ebp
  800087:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  80008a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  800091:	e8 3f 00 00 00       	call   8000d5 <sys_env_destroy>
}
  800096:	c9                   	leave  
  800097:	c3                   	ret    

00800098 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800098:	55                   	push   %ebp
  800099:	89 e5                	mov    %esp,%ebp
  80009b:	57                   	push   %edi
  80009c:	56                   	push   %esi
  80009d:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80009e:	b8 00 00 00 00       	mov    $0x0,%eax
  8000a3:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000a6:	8b 55 08             	mov    0x8(%ebp),%edx
  8000a9:	89 c3                	mov    %eax,%ebx
  8000ab:	89 c7                	mov    %eax,%edi
  8000ad:	89 c6                	mov    %eax,%esi
  8000af:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000b1:	5b                   	pop    %ebx
  8000b2:	5e                   	pop    %esi
  8000b3:	5f                   	pop    %edi
  8000b4:	5d                   	pop    %ebp
  8000b5:	c3                   	ret    

008000b6 <sys_cgetc>:

int
sys_cgetc(void)
{
  8000b6:	55                   	push   %ebp
  8000b7:	89 e5                	mov    %esp,%ebp
  8000b9:	57                   	push   %edi
  8000ba:	56                   	push   %esi
  8000bb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000bc:	ba 00 00 00 00       	mov    $0x0,%edx
  8000c1:	b8 01 00 00 00       	mov    $0x1,%eax
  8000c6:	89 d1                	mov    %edx,%ecx
  8000c8:	89 d3                	mov    %edx,%ebx
  8000ca:	89 d7                	mov    %edx,%edi
  8000cc:	89 d6                	mov    %edx,%esi
  8000ce:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000d0:	5b                   	pop    %ebx
  8000d1:	5e                   	pop    %esi
  8000d2:	5f                   	pop    %edi
  8000d3:	5d                   	pop    %ebp
  8000d4:	c3                   	ret    

008000d5 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000d5:	55                   	push   %ebp
  8000d6:	89 e5                	mov    %esp,%ebp
  8000d8:	57                   	push   %edi
  8000d9:	56                   	push   %esi
  8000da:	53                   	push   %ebx
  8000db:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000de:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000e3:	b8 03 00 00 00       	mov    $0x3,%eax
  8000e8:	8b 55 08             	mov    0x8(%ebp),%edx
  8000eb:	89 cb                	mov    %ecx,%ebx
  8000ed:	89 cf                	mov    %ecx,%edi
  8000ef:	89 ce                	mov    %ecx,%esi
  8000f1:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000f3:	85 c0                	test   %eax,%eax
  8000f5:	7e 28                	jle    80011f <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  8000f7:	89 44 24 10          	mov    %eax,0x10(%esp)
  8000fb:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800102:	00 
  800103:	c7 44 24 08 6a 0e 80 	movl   $0x800e6a,0x8(%esp)
  80010a:	00 
  80010b:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800112:	00 
  800113:	c7 04 24 87 0e 80 00 	movl   $0x800e87,(%esp)
  80011a:	e8 27 00 00 00       	call   800146 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  80011f:	83 c4 2c             	add    $0x2c,%esp
  800122:	5b                   	pop    %ebx
  800123:	5e                   	pop    %esi
  800124:	5f                   	pop    %edi
  800125:	5d                   	pop    %ebp
  800126:	c3                   	ret    

00800127 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800127:	55                   	push   %ebp
  800128:	89 e5                	mov    %esp,%ebp
  80012a:	57                   	push   %edi
  80012b:	56                   	push   %esi
  80012c:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  80012d:	ba 00 00 00 00       	mov    $0x0,%edx
  800132:	b8 02 00 00 00       	mov    $0x2,%eax
  800137:	89 d1                	mov    %edx,%ecx
  800139:	89 d3                	mov    %edx,%ebx
  80013b:	89 d7                	mov    %edx,%edi
  80013d:	89 d6                	mov    %edx,%esi
  80013f:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800141:	5b                   	pop    %ebx
  800142:	5e                   	pop    %esi
  800143:	5f                   	pop    %edi
  800144:	5d                   	pop    %ebp
  800145:	c3                   	ret    

00800146 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800146:	55                   	push   %ebp
  800147:	89 e5                	mov    %esp,%ebp
  800149:	56                   	push   %esi
  80014a:	53                   	push   %ebx
  80014b:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  80014e:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800151:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800157:	e8 cb ff ff ff       	call   800127 <sys_getenvid>
  80015c:	8b 55 0c             	mov    0xc(%ebp),%edx
  80015f:	89 54 24 10          	mov    %edx,0x10(%esp)
  800163:	8b 55 08             	mov    0x8(%ebp),%edx
  800166:	89 54 24 0c          	mov    %edx,0xc(%esp)
  80016a:	89 74 24 08          	mov    %esi,0x8(%esp)
  80016e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800172:	c7 04 24 98 0e 80 00 	movl   $0x800e98,(%esp)
  800179:	e8 c1 00 00 00       	call   80023f <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  80017e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800182:	8b 45 10             	mov    0x10(%ebp),%eax
  800185:	89 04 24             	mov    %eax,(%esp)
  800188:	e8 51 00 00 00       	call   8001de <vcprintf>
	cprintf("\n");
  80018d:	c7 04 24 bc 0e 80 00 	movl   $0x800ebc,(%esp)
  800194:	e8 a6 00 00 00       	call   80023f <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800199:	cc                   	int3   
  80019a:	eb fd                	jmp    800199 <_panic+0x53>

0080019c <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  80019c:	55                   	push   %ebp
  80019d:	89 e5                	mov    %esp,%ebp
  80019f:	53                   	push   %ebx
  8001a0:	83 ec 14             	sub    $0x14,%esp
  8001a3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001a6:	8b 13                	mov    (%ebx),%edx
  8001a8:	8d 42 01             	lea    0x1(%edx),%eax
  8001ab:	89 03                	mov    %eax,(%ebx)
  8001ad:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001b0:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001b4:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001b9:	75 19                	jne    8001d4 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001bb:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001c2:	00 
  8001c3:	8d 43 08             	lea    0x8(%ebx),%eax
  8001c6:	89 04 24             	mov    %eax,(%esp)
  8001c9:	e8 ca fe ff ff       	call   800098 <sys_cputs>
		b->idx = 0;
  8001ce:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8001d4:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001d8:	83 c4 14             	add    $0x14,%esp
  8001db:	5b                   	pop    %ebx
  8001dc:	5d                   	pop    %ebp
  8001dd:	c3                   	ret    

008001de <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001de:	55                   	push   %ebp
  8001df:	89 e5                	mov    %esp,%ebp
  8001e1:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8001e7:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001ee:	00 00 00 
	b.cnt = 0;
  8001f1:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  8001f8:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  8001fb:	8b 45 0c             	mov    0xc(%ebp),%eax
  8001fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800202:	8b 45 08             	mov    0x8(%ebp),%eax
  800205:	89 44 24 08          	mov    %eax,0x8(%esp)
  800209:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  80020f:	89 44 24 04          	mov    %eax,0x4(%esp)
  800213:	c7 04 24 9c 01 80 00 	movl   $0x80019c,(%esp)
  80021a:	e8 af 01 00 00       	call   8003ce <vprintfmt>
	sys_cputs(b.buf, b.idx);
  80021f:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800225:	89 44 24 04          	mov    %eax,0x4(%esp)
  800229:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  80022f:	89 04 24             	mov    %eax,(%esp)
  800232:	e8 61 fe ff ff       	call   800098 <sys_cputs>

	return b.cnt;
}
  800237:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80023d:	c9                   	leave  
  80023e:	c3                   	ret    

0080023f <cprintf>:

int
cprintf(const char *fmt, ...)
{
  80023f:	55                   	push   %ebp
  800240:	89 e5                	mov    %esp,%ebp
  800242:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800245:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800248:	89 44 24 04          	mov    %eax,0x4(%esp)
  80024c:	8b 45 08             	mov    0x8(%ebp),%eax
  80024f:	89 04 24             	mov    %eax,(%esp)
  800252:	e8 87 ff ff ff       	call   8001de <vcprintf>
	va_end(ap);

	return cnt;
}
  800257:	c9                   	leave  
  800258:	c3                   	ret    
  800259:	66 90                	xchg   %ax,%ax
  80025b:	66 90                	xchg   %ax,%ax
  80025d:	66 90                	xchg   %ax,%ax
  80025f:	90                   	nop

00800260 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800260:	55                   	push   %ebp
  800261:	89 e5                	mov    %esp,%ebp
  800263:	57                   	push   %edi
  800264:	56                   	push   %esi
  800265:	53                   	push   %ebx
  800266:	83 ec 3c             	sub    $0x3c,%esp
  800269:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80026c:	89 d7                	mov    %edx,%edi
  80026e:	8b 45 08             	mov    0x8(%ebp),%eax
  800271:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800274:	8b 45 0c             	mov    0xc(%ebp),%eax
  800277:	89 c3                	mov    %eax,%ebx
  800279:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80027c:	8b 45 10             	mov    0x10(%ebp),%eax
  80027f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800282:	b9 00 00 00 00       	mov    $0x0,%ecx
  800287:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80028a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80028d:	39 d9                	cmp    %ebx,%ecx
  80028f:	72 05                	jb     800296 <printnum+0x36>
  800291:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  800294:	77 69                	ja     8002ff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  800296:	8b 4d 18             	mov    0x18(%ebp),%ecx
  800299:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  80029d:	83 ee 01             	sub    $0x1,%esi
  8002a0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002a4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002a8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002ac:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002b0:	89 c3                	mov    %eax,%ebx
  8002b2:	89 d6                	mov    %edx,%esi
  8002b4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8002b7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8002ba:	89 54 24 08          	mov    %edx,0x8(%esp)
  8002be:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8002c2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002c5:	89 04 24             	mov    %eax,(%esp)
  8002c8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002cb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002cf:	e8 fc 08 00 00       	call   800bd0 <__udivdi3>
  8002d4:	89 d9                	mov    %ebx,%ecx
  8002d6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8002da:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002de:	89 04 24             	mov    %eax,(%esp)
  8002e1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8002e5:	89 fa                	mov    %edi,%edx
  8002e7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8002ea:	e8 71 ff ff ff       	call   800260 <printnum>
  8002ef:	eb 1b                	jmp    80030c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  8002f1:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002f5:	8b 45 18             	mov    0x18(%ebp),%eax
  8002f8:	89 04 24             	mov    %eax,(%esp)
  8002fb:	ff d3                	call   *%ebx
  8002fd:	eb 03                	jmp    800302 <printnum+0xa2>
  8002ff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800302:	83 ee 01             	sub    $0x1,%esi
  800305:	85 f6                	test   %esi,%esi
  800307:	7f e8                	jg     8002f1 <printnum+0x91>
  800309:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80030c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800310:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800314:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800317:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80031a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80031e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800322:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800325:	89 04 24             	mov    %eax,(%esp)
  800328:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80032b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80032f:	e8 cc 09 00 00       	call   800d00 <__umoddi3>
  800334:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800338:	0f be 80 be 0e 80 00 	movsbl 0x800ebe(%eax),%eax
  80033f:	89 04 24             	mov    %eax,(%esp)
  800342:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800345:	ff d0                	call   *%eax
}
  800347:	83 c4 3c             	add    $0x3c,%esp
  80034a:	5b                   	pop    %ebx
  80034b:	5e                   	pop    %esi
  80034c:	5f                   	pop    %edi
  80034d:	5d                   	pop    %ebp
  80034e:	c3                   	ret    

0080034f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80034f:	55                   	push   %ebp
  800350:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800352:	83 fa 01             	cmp    $0x1,%edx
  800355:	7e 0e                	jle    800365 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800357:	8b 10                	mov    (%eax),%edx
  800359:	8d 4a 08             	lea    0x8(%edx),%ecx
  80035c:	89 08                	mov    %ecx,(%eax)
  80035e:	8b 02                	mov    (%edx),%eax
  800360:	8b 52 04             	mov    0x4(%edx),%edx
  800363:	eb 22                	jmp    800387 <getuint+0x38>
	else if (lflag)
  800365:	85 d2                	test   %edx,%edx
  800367:	74 10                	je     800379 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800369:	8b 10                	mov    (%eax),%edx
  80036b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80036e:	89 08                	mov    %ecx,(%eax)
  800370:	8b 02                	mov    (%edx),%eax
  800372:	ba 00 00 00 00       	mov    $0x0,%edx
  800377:	eb 0e                	jmp    800387 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800379:	8b 10                	mov    (%eax),%edx
  80037b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80037e:	89 08                	mov    %ecx,(%eax)
  800380:	8b 02                	mov    (%edx),%eax
  800382:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800387:	5d                   	pop    %ebp
  800388:	c3                   	ret    

00800389 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800389:	55                   	push   %ebp
  80038a:	89 e5                	mov    %esp,%ebp
  80038c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80038f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  800393:	8b 10                	mov    (%eax),%edx
  800395:	3b 50 04             	cmp    0x4(%eax),%edx
  800398:	73 0a                	jae    8003a4 <sprintputch+0x1b>
		*b->buf++ = ch;
  80039a:	8d 4a 01             	lea    0x1(%edx),%ecx
  80039d:	89 08                	mov    %ecx,(%eax)
  80039f:	8b 45 08             	mov    0x8(%ebp),%eax
  8003a2:	88 02                	mov    %al,(%edx)
}
  8003a4:	5d                   	pop    %ebp
  8003a5:	c3                   	ret    

008003a6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003a6:	55                   	push   %ebp
  8003a7:	89 e5                	mov    %esp,%ebp
  8003a9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003ac:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003af:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003b3:	8b 45 10             	mov    0x10(%ebp),%eax
  8003b6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003ba:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003bd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003c1:	8b 45 08             	mov    0x8(%ebp),%eax
  8003c4:	89 04 24             	mov    %eax,(%esp)
  8003c7:	e8 02 00 00 00       	call   8003ce <vprintfmt>
	va_end(ap);
}
  8003cc:	c9                   	leave  
  8003cd:	c3                   	ret    

008003ce <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003ce:	55                   	push   %ebp
  8003cf:	89 e5                	mov    %esp,%ebp
  8003d1:	57                   	push   %edi
  8003d2:	56                   	push   %esi
  8003d3:	53                   	push   %ebx
  8003d4:	83 ec 3c             	sub    $0x3c,%esp
  8003d7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8003da:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003dd:	eb 14                	jmp    8003f3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')									//当然中间如果遇到'\0'，代表这个字符串的访问结束
  8003df:	85 c0                	test   %eax,%eax
  8003e1:	0f 84 c7 03 00 00    	je     8007ae <vprintfmt+0x3e0>
				return;
			putch(ch, putdat);								//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  8003e7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003eb:	89 04 24             	mov    %eax,(%esp)
  8003ee:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  8003f1:	89 f3                	mov    %esi,%ebx
  8003f3:	8d 73 01             	lea    0x1(%ebx),%esi
  8003f6:	0f b6 03             	movzbl (%ebx),%eax
  8003f9:	83 f8 25             	cmp    $0x25,%eax
  8003fc:	75 e1                	jne    8003df <vprintfmt+0x11>
  8003fe:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800402:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800409:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800410:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800417:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  80041e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800423:	eb 1d                	jmp    800442 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800425:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':											//%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  800427:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  80042b:	eb 15                	jmp    800442 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  80042d:	89 de                	mov    %ebx,%esi
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;									//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0':											//0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';										//对其方式标志位变为0
  80042f:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  800433:	eb 0d                	jmp    800442 <vprintfmt+0x74>
			altflag = 1;
			goto reswitch;

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
				width = precision, precision = -1;
  800435:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800438:	89 45 dc             	mov    %eax,-0x24(%ebp)
  80043b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800442:	8d 5e 01             	lea    0x1(%esi),%ebx
  800445:	0f b6 16             	movzbl (%esi),%edx
  800448:	0f b6 c2             	movzbl %dl,%eax
  80044b:	83 ea 23             	sub    $0x23,%edx
  80044e:	80 fa 55             	cmp    $0x55,%dl
  800451:	0f 87 37 03 00 00    	ja     80078e <vprintfmt+0x3c0>
  800457:	0f b6 d2             	movzbl %dl,%edx
  80045a:	ff 24 95 60 0f 80 00 	jmp    *0x800f60(,%edx,4)
  800461:	89 de                	mov    %ebx,%esi
  800463:	89 ca                	mov    %ecx,%edx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  800465:	8d 14 92             	lea    (%edx,%edx,4),%edx
  800468:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  80046c:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80046f:	8d 58 d0             	lea    -0x30(%eax),%ebx
  800472:	83 fb 09             	cmp    $0x9,%ebx
  800475:	77 31                	ja     8004a8 <vprintfmt+0xda>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  800477:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80047a:	eb e9                	jmp    800465 <vprintfmt+0x97>
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  80047c:	8b 45 14             	mov    0x14(%ebp),%eax
  80047f:	8d 50 04             	lea    0x4(%eax),%edx
  800482:	89 55 14             	mov    %edx,0x14(%ebp)
  800485:	8b 00                	mov    (%eax),%eax
  800487:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  80048a:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  80048c:	eb 1d                	jmp    8004ab <vprintfmt+0xdd>
  80048e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800491:	85 c0                	test   %eax,%eax
  800493:	0f 48 c1             	cmovs  %ecx,%eax
  800496:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800499:	89 de                	mov    %ebx,%esi
  80049b:	eb a5                	jmp    800442 <vprintfmt+0x74>
  80049d:	89 de                	mov    %ebx,%esi
			if (width < 0)									//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;			
			goto reswitch;

		case '#':
			altflag = 1;
  80049f:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8004a6:	eb 9a                	jmp    800442 <vprintfmt+0x74>
  8004a8:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  8004ab:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8004af:	79 91                	jns    800442 <vprintfmt+0x74>
  8004b1:	eb 82                	jmp    800435 <vprintfmt+0x67>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
  8004b3:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  8004b7:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
			goto reswitch;
  8004b9:	eb 87                	jmp    800442 <vprintfmt+0x74>

		// character
		case 'c':											//如果是'c'代表显示一个字符
			putch(va_arg(ap, int), putdat);					//调用输出一个字符到内存的函数putch
  8004bb:	8b 45 14             	mov    0x14(%ebp),%eax
  8004be:	8d 50 04             	lea    0x4(%eax),%edx
  8004c1:	89 55 14             	mov    %edx,0x14(%ebp)
  8004c4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004c8:	8b 00                	mov    (%eax),%eax
  8004ca:	89 04 24             	mov    %eax,(%esp)
  8004cd:	ff 55 08             	call   *0x8(%ebp)
			break;
  8004d0:	e9 1e ff ff ff       	jmp    8003f3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004d5:	8b 45 14             	mov    0x14(%ebp),%eax
  8004d8:	8d 50 04             	lea    0x4(%eax),%edx
  8004db:	89 55 14             	mov    %edx,0x14(%ebp)
  8004de:	8b 00                	mov    (%eax),%eax
  8004e0:	99                   	cltd   
  8004e1:	31 d0                	xor    %edx,%eax
  8004e3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004e5:	83 f8 07             	cmp    $0x7,%eax
  8004e8:	7f 0b                	jg     8004f5 <vprintfmt+0x127>
  8004ea:	8b 14 85 c0 10 80 00 	mov    0x8010c0(,%eax,4),%edx
  8004f1:	85 d2                	test   %edx,%edx
  8004f3:	75 20                	jne    800515 <vprintfmt+0x147>
				printfmt(putch, putdat, "error %d", err);
  8004f5:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8004f9:	c7 44 24 08 d6 0e 80 	movl   $0x800ed6,0x8(%esp)
  800500:	00 
  800501:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800505:	8b 45 08             	mov    0x8(%ebp),%eax
  800508:	89 04 24             	mov    %eax,(%esp)
  80050b:	e8 96 fe ff ff       	call   8003a6 <printfmt>
  800510:	e9 de fe ff ff       	jmp    8003f3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800515:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800519:	c7 44 24 08 df 0e 80 	movl   $0x800edf,0x8(%esp)
  800520:	00 
  800521:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800525:	8b 45 08             	mov    0x8(%ebp),%eax
  800528:	89 04 24             	mov    %eax,(%esp)
  80052b:	e8 76 fe ff ff       	call   8003a6 <printfmt>
  800530:	e9 be fe ff ff       	jmp    8003f3 <vprintfmt+0x25>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800535:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  800538:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80053b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80053e:	8b 45 14             	mov    0x14(%ebp),%eax
  800541:	8d 50 04             	lea    0x4(%eax),%edx
  800544:	89 55 14             	mov    %edx,0x14(%ebp)
  800547:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  800549:	85 f6                	test   %esi,%esi
  80054b:	b8 cf 0e 80 00       	mov    $0x800ecf,%eax
  800550:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800553:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  800557:	0f 84 97 00 00 00    	je     8005f4 <vprintfmt+0x226>
  80055d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800561:	0f 8e 9b 00 00 00    	jle    800602 <vprintfmt+0x234>
				for (width -= strnlen(p, precision); width > 0; width--)
  800567:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80056b:	89 34 24             	mov    %esi,(%esp)
  80056e:	e8 e5 02 00 00       	call   800858 <strnlen>
  800573:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  800576:	29 c1                	sub    %eax,%ecx
  800578:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
					putch(padc, putdat);
  80057b:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  80057f:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800582:	89 75 d8             	mov    %esi,-0x28(%ebp)
  800585:	8b 75 08             	mov    0x8(%ebp),%esi
  800588:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80058b:	89 cb                	mov    %ecx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80058d:	eb 0f                	jmp    80059e <vprintfmt+0x1d0>
					putch(padc, putdat);
  80058f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800593:	8b 45 dc             	mov    -0x24(%ebp),%eax
  800596:	89 04 24             	mov    %eax,(%esp)
  800599:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80059b:	83 eb 01             	sub    $0x1,%ebx
  80059e:	85 db                	test   %ebx,%ebx
  8005a0:	7f ed                	jg     80058f <vprintfmt+0x1c1>
  8005a2:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8005a5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8005a8:	85 c9                	test   %ecx,%ecx
  8005aa:	b8 00 00 00 00       	mov    $0x0,%eax
  8005af:	0f 49 c1             	cmovns %ecx,%eax
  8005b2:	29 c1                	sub    %eax,%ecx
  8005b4:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005b7:	89 cf                	mov    %ecx,%edi
  8005b9:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  8005bc:	eb 50                	jmp    80060e <vprintfmt+0x240>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005be:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005c2:	74 1e                	je     8005e2 <vprintfmt+0x214>
  8005c4:	0f be d2             	movsbl %dl,%edx
  8005c7:	83 ea 20             	sub    $0x20,%edx
  8005ca:	83 fa 5e             	cmp    $0x5e,%edx
  8005cd:	76 13                	jbe    8005e2 <vprintfmt+0x214>
					putch('?', putdat);
  8005cf:	8b 45 0c             	mov    0xc(%ebp),%eax
  8005d2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8005d6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8005dd:	ff 55 08             	call   *0x8(%ebp)
  8005e0:	eb 0d                	jmp    8005ef <vprintfmt+0x221>
				else
					putch(ch, putdat);
  8005e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8005e5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005e9:	89 04 24             	mov    %eax,(%esp)
  8005ec:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005ef:	83 ef 01             	sub    $0x1,%edi
  8005f2:	eb 1a                	jmp    80060e <vprintfmt+0x240>
  8005f4:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005f7:	8b 7d dc             	mov    -0x24(%ebp),%edi
  8005fa:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8005fd:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  800600:	eb 0c                	jmp    80060e <vprintfmt+0x240>
  800602:	89 7d 0c             	mov    %edi,0xc(%ebp)
  800605:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800608:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80060b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  80060e:	83 c6 01             	add    $0x1,%esi
  800611:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  800615:	0f be c2             	movsbl %dl,%eax
  800618:	85 c0                	test   %eax,%eax
  80061a:	74 27                	je     800643 <vprintfmt+0x275>
  80061c:	85 db                	test   %ebx,%ebx
  80061e:	78 9e                	js     8005be <vprintfmt+0x1f0>
  800620:	83 eb 01             	sub    $0x1,%ebx
  800623:	79 99                	jns    8005be <vprintfmt+0x1f0>
  800625:	89 f8                	mov    %edi,%eax
  800627:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80062a:	8b 75 08             	mov    0x8(%ebp),%esi
  80062d:	89 c3                	mov    %eax,%ebx
  80062f:	eb 1a                	jmp    80064b <vprintfmt+0x27d>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800631:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800635:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80063c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80063e:	83 eb 01             	sub    $0x1,%ebx
  800641:	eb 08                	jmp    80064b <vprintfmt+0x27d>
  800643:	89 fb                	mov    %edi,%ebx
  800645:	8b 75 08             	mov    0x8(%ebp),%esi
  800648:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80064b:	85 db                	test   %ebx,%ebx
  80064d:	7f e2                	jg     800631 <vprintfmt+0x263>
  80064f:	89 75 08             	mov    %esi,0x8(%ebp)
  800652:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800655:	e9 99 fd ff ff       	jmp    8003f3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80065a:	83 7d d4 01          	cmpl   $0x1,-0x2c(%ebp)
  80065e:	7e 16                	jle    800676 <vprintfmt+0x2a8>
		return va_arg(*ap, long long);
  800660:	8b 45 14             	mov    0x14(%ebp),%eax
  800663:	8d 50 08             	lea    0x8(%eax),%edx
  800666:	89 55 14             	mov    %edx,0x14(%ebp)
  800669:	8b 50 04             	mov    0x4(%eax),%edx
  80066c:	8b 00                	mov    (%eax),%eax
  80066e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800671:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800674:	eb 34                	jmp    8006aa <vprintfmt+0x2dc>
	else if (lflag)
  800676:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  80067a:	74 18                	je     800694 <vprintfmt+0x2c6>
		return va_arg(*ap, long);
  80067c:	8b 45 14             	mov    0x14(%ebp),%eax
  80067f:	8d 50 04             	lea    0x4(%eax),%edx
  800682:	89 55 14             	mov    %edx,0x14(%ebp)
  800685:	8b 30                	mov    (%eax),%esi
  800687:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80068a:	89 f0                	mov    %esi,%eax
  80068c:	c1 f8 1f             	sar    $0x1f,%eax
  80068f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  800692:	eb 16                	jmp    8006aa <vprintfmt+0x2dc>
	else
		return va_arg(*ap, int);
  800694:	8b 45 14             	mov    0x14(%ebp),%eax
  800697:	8d 50 04             	lea    0x4(%eax),%edx
  80069a:	89 55 14             	mov    %edx,0x14(%ebp)
  80069d:	8b 30                	mov    (%eax),%esi
  80069f:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8006a2:	89 f0                	mov    %esi,%eax
  8006a4:	c1 f8 1f             	sar    $0x1f,%eax
  8006a7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8006aa:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006ad:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006b0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006b5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8006b9:	0f 89 97 00 00 00    	jns    800756 <vprintfmt+0x388>
				putch('-', putdat);
  8006bf:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006c3:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006ca:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8006cd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006d0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8006d3:	f7 d8                	neg    %eax
  8006d5:	83 d2 00             	adc    $0x0,%edx
  8006d8:	f7 da                	neg    %edx
			}
			base = 10;
  8006da:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8006df:	eb 75                	jmp    800756 <vprintfmt+0x388>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006e1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8006e4:	8d 45 14             	lea    0x14(%ebp),%eax
  8006e7:	e8 63 fc ff ff       	call   80034f <getuint>
			base = 10;
  8006ec:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  8006f1:	eb 63                	jmp    800756 <vprintfmt+0x388>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('0', putdat);
  8006f3:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006f7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  8006fe:	ff 55 08             	call   *0x8(%ebp)
			num = getuint(&ap, lflag);
  800701:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800704:	8d 45 14             	lea    0x14(%ebp),%eax
  800707:	e8 43 fc ff ff       	call   80034f <getuint>
			base = 8;
  80070c:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800711:	eb 43                	jmp    800756 <vprintfmt+0x388>
		// pointer
		case 'p':
			putch('0', putdat);
  800713:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800717:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80071e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800721:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800725:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80072c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80072f:	8b 45 14             	mov    0x14(%ebp),%eax
  800732:	8d 50 04             	lea    0x4(%eax),%edx
  800735:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800738:	8b 00                	mov    (%eax),%eax
  80073a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80073f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800744:	eb 10                	jmp    800756 <vprintfmt+0x388>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800746:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800749:	8d 45 14             	lea    0x14(%ebp),%eax
  80074c:	e8 fe fb ff ff       	call   80034f <getuint>
			base = 16;
  800751:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800756:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  80075a:	89 74 24 10          	mov    %esi,0x10(%esp)
  80075e:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800761:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800765:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800769:	89 04 24             	mov    %eax,(%esp)
  80076c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800770:	89 fa                	mov    %edi,%edx
  800772:	8b 45 08             	mov    0x8(%ebp),%eax
  800775:	e8 e6 fa ff ff       	call   800260 <printnum>
			break;
  80077a:	e9 74 fc ff ff       	jmp    8003f3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80077f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800783:	89 04 24             	mov    %eax,(%esp)
  800786:	ff 55 08             	call   *0x8(%ebp)
			break;
  800789:	e9 65 fc ff ff       	jmp    8003f3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80078e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800792:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  800799:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  80079c:	89 f3                	mov    %esi,%ebx
  80079e:	eb 03                	jmp    8007a3 <vprintfmt+0x3d5>
  8007a0:	83 eb 01             	sub    $0x1,%ebx
  8007a3:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8007a7:	75 f7                	jne    8007a0 <vprintfmt+0x3d2>
  8007a9:	e9 45 fc ff ff       	jmp    8003f3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8007ae:	83 c4 3c             	add    $0x3c,%esp
  8007b1:	5b                   	pop    %ebx
  8007b2:	5e                   	pop    %esi
  8007b3:	5f                   	pop    %edi
  8007b4:	5d                   	pop    %ebp
  8007b5:	c3                   	ret    

008007b6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007b6:	55                   	push   %ebp
  8007b7:	89 e5                	mov    %esp,%ebp
  8007b9:	83 ec 28             	sub    $0x28,%esp
  8007bc:	8b 45 08             	mov    0x8(%ebp),%eax
  8007bf:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007c2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007c5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007c9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007cc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007d3:	85 c0                	test   %eax,%eax
  8007d5:	74 30                	je     800807 <vsnprintf+0x51>
  8007d7:	85 d2                	test   %edx,%edx
  8007d9:	7e 2c                	jle    800807 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007db:	8b 45 14             	mov    0x14(%ebp),%eax
  8007de:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007e2:	8b 45 10             	mov    0x10(%ebp),%eax
  8007e5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007e9:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007ec:	89 44 24 04          	mov    %eax,0x4(%esp)
  8007f0:	c7 04 24 89 03 80 00 	movl   $0x800389,(%esp)
  8007f7:	e8 d2 fb ff ff       	call   8003ce <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  8007fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
  8007ff:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800802:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800805:	eb 05                	jmp    80080c <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800807:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80080c:	c9                   	leave  
  80080d:	c3                   	ret    

0080080e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80080e:	55                   	push   %ebp
  80080f:	89 e5                	mov    %esp,%ebp
  800811:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800814:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800817:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80081b:	8b 45 10             	mov    0x10(%ebp),%eax
  80081e:	89 44 24 08          	mov    %eax,0x8(%esp)
  800822:	8b 45 0c             	mov    0xc(%ebp),%eax
  800825:	89 44 24 04          	mov    %eax,0x4(%esp)
  800829:	8b 45 08             	mov    0x8(%ebp),%eax
  80082c:	89 04 24             	mov    %eax,(%esp)
  80082f:	e8 82 ff ff ff       	call   8007b6 <vsnprintf>
	va_end(ap);

	return rc;
}
  800834:	c9                   	leave  
  800835:	c3                   	ret    
  800836:	66 90                	xchg   %ax,%ax
  800838:	66 90                	xchg   %ax,%ax
  80083a:	66 90                	xchg   %ax,%ax
  80083c:	66 90                	xchg   %ax,%ax
  80083e:	66 90                	xchg   %ax,%ax

00800840 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800840:	55                   	push   %ebp
  800841:	89 e5                	mov    %esp,%ebp
  800843:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800846:	b8 00 00 00 00       	mov    $0x0,%eax
  80084b:	eb 03                	jmp    800850 <strlen+0x10>
		n++;
  80084d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800850:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800854:	75 f7                	jne    80084d <strlen+0xd>
		n++;
	return n;
}
  800856:	5d                   	pop    %ebp
  800857:	c3                   	ret    

00800858 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800858:	55                   	push   %ebp
  800859:	89 e5                	mov    %esp,%ebp
  80085b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80085e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800861:	b8 00 00 00 00       	mov    $0x0,%eax
  800866:	eb 03                	jmp    80086b <strnlen+0x13>
		n++;
  800868:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80086b:	39 d0                	cmp    %edx,%eax
  80086d:	74 06                	je     800875 <strnlen+0x1d>
  80086f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800873:	75 f3                	jne    800868 <strnlen+0x10>
		n++;
	return n;
}
  800875:	5d                   	pop    %ebp
  800876:	c3                   	ret    

00800877 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800877:	55                   	push   %ebp
  800878:	89 e5                	mov    %esp,%ebp
  80087a:	53                   	push   %ebx
  80087b:	8b 45 08             	mov    0x8(%ebp),%eax
  80087e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800881:	89 c2                	mov    %eax,%edx
  800883:	83 c2 01             	add    $0x1,%edx
  800886:	83 c1 01             	add    $0x1,%ecx
  800889:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80088d:	88 5a ff             	mov    %bl,-0x1(%edx)
  800890:	84 db                	test   %bl,%bl
  800892:	75 ef                	jne    800883 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  800894:	5b                   	pop    %ebx
  800895:	5d                   	pop    %ebp
  800896:	c3                   	ret    

00800897 <strcat>:

char *
strcat(char *dst, const char *src)
{
  800897:	55                   	push   %ebp
  800898:	89 e5                	mov    %esp,%ebp
  80089a:	53                   	push   %ebx
  80089b:	83 ec 08             	sub    $0x8,%esp
  80089e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008a1:	89 1c 24             	mov    %ebx,(%esp)
  8008a4:	e8 97 ff ff ff       	call   800840 <strlen>
	strcpy(dst + len, src);
  8008a9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008ac:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008b0:	01 d8                	add    %ebx,%eax
  8008b2:	89 04 24             	mov    %eax,(%esp)
  8008b5:	e8 bd ff ff ff       	call   800877 <strcpy>
	return dst;
}
  8008ba:	89 d8                	mov    %ebx,%eax
  8008bc:	83 c4 08             	add    $0x8,%esp
  8008bf:	5b                   	pop    %ebx
  8008c0:	5d                   	pop    %ebp
  8008c1:	c3                   	ret    

008008c2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008c2:	55                   	push   %ebp
  8008c3:	89 e5                	mov    %esp,%ebp
  8008c5:	56                   	push   %esi
  8008c6:	53                   	push   %ebx
  8008c7:	8b 75 08             	mov    0x8(%ebp),%esi
  8008ca:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008cd:	89 f3                	mov    %esi,%ebx
  8008cf:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008d2:	89 f2                	mov    %esi,%edx
  8008d4:	eb 0f                	jmp    8008e5 <strncpy+0x23>
		*dst++ = *src;
  8008d6:	83 c2 01             	add    $0x1,%edx
  8008d9:	0f b6 01             	movzbl (%ecx),%eax
  8008dc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008df:	80 39 01             	cmpb   $0x1,(%ecx)
  8008e2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008e5:	39 da                	cmp    %ebx,%edx
  8008e7:	75 ed                	jne    8008d6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008e9:	89 f0                	mov    %esi,%eax
  8008eb:	5b                   	pop    %ebx
  8008ec:	5e                   	pop    %esi
  8008ed:	5d                   	pop    %ebp
  8008ee:	c3                   	ret    

008008ef <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008ef:	55                   	push   %ebp
  8008f0:	89 e5                	mov    %esp,%ebp
  8008f2:	56                   	push   %esi
  8008f3:	53                   	push   %ebx
  8008f4:	8b 75 08             	mov    0x8(%ebp),%esi
  8008f7:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008fa:	8b 4d 10             	mov    0x10(%ebp),%ecx
  8008fd:	89 f0                	mov    %esi,%eax
  8008ff:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800903:	85 c9                	test   %ecx,%ecx
  800905:	75 0b                	jne    800912 <strlcpy+0x23>
  800907:	eb 1d                	jmp    800926 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800909:	83 c0 01             	add    $0x1,%eax
  80090c:	83 c2 01             	add    $0x1,%edx
  80090f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800912:	39 d8                	cmp    %ebx,%eax
  800914:	74 0b                	je     800921 <strlcpy+0x32>
  800916:	0f b6 0a             	movzbl (%edx),%ecx
  800919:	84 c9                	test   %cl,%cl
  80091b:	75 ec                	jne    800909 <strlcpy+0x1a>
  80091d:	89 c2                	mov    %eax,%edx
  80091f:	eb 02                	jmp    800923 <strlcpy+0x34>
  800921:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800923:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800926:	29 f0                	sub    %esi,%eax
}
  800928:	5b                   	pop    %ebx
  800929:	5e                   	pop    %esi
  80092a:	5d                   	pop    %ebp
  80092b:	c3                   	ret    

0080092c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80092c:	55                   	push   %ebp
  80092d:	89 e5                	mov    %esp,%ebp
  80092f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800932:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800935:	eb 06                	jmp    80093d <strcmp+0x11>
		p++, q++;
  800937:	83 c1 01             	add    $0x1,%ecx
  80093a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80093d:	0f b6 01             	movzbl (%ecx),%eax
  800940:	84 c0                	test   %al,%al
  800942:	74 04                	je     800948 <strcmp+0x1c>
  800944:	3a 02                	cmp    (%edx),%al
  800946:	74 ef                	je     800937 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800948:	0f b6 c0             	movzbl %al,%eax
  80094b:	0f b6 12             	movzbl (%edx),%edx
  80094e:	29 d0                	sub    %edx,%eax
}
  800950:	5d                   	pop    %ebp
  800951:	c3                   	ret    

00800952 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800952:	55                   	push   %ebp
  800953:	89 e5                	mov    %esp,%ebp
  800955:	53                   	push   %ebx
  800956:	8b 45 08             	mov    0x8(%ebp),%eax
  800959:	8b 55 0c             	mov    0xc(%ebp),%edx
  80095c:	89 c3                	mov    %eax,%ebx
  80095e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800961:	eb 06                	jmp    800969 <strncmp+0x17>
		n--, p++, q++;
  800963:	83 c0 01             	add    $0x1,%eax
  800966:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800969:	39 d8                	cmp    %ebx,%eax
  80096b:	74 15                	je     800982 <strncmp+0x30>
  80096d:	0f b6 08             	movzbl (%eax),%ecx
  800970:	84 c9                	test   %cl,%cl
  800972:	74 04                	je     800978 <strncmp+0x26>
  800974:	3a 0a                	cmp    (%edx),%cl
  800976:	74 eb                	je     800963 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800978:	0f b6 00             	movzbl (%eax),%eax
  80097b:	0f b6 12             	movzbl (%edx),%edx
  80097e:	29 d0                	sub    %edx,%eax
  800980:	eb 05                	jmp    800987 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800982:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800987:	5b                   	pop    %ebx
  800988:	5d                   	pop    %ebp
  800989:	c3                   	ret    

0080098a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80098a:	55                   	push   %ebp
  80098b:	89 e5                	mov    %esp,%ebp
  80098d:	8b 45 08             	mov    0x8(%ebp),%eax
  800990:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  800994:	eb 07                	jmp    80099d <strchr+0x13>
		if (*s == c)
  800996:	38 ca                	cmp    %cl,%dl
  800998:	74 0f                	je     8009a9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  80099a:	83 c0 01             	add    $0x1,%eax
  80099d:	0f b6 10             	movzbl (%eax),%edx
  8009a0:	84 d2                	test   %dl,%dl
  8009a2:	75 f2                	jne    800996 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009a4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009a9:	5d                   	pop    %ebp
  8009aa:	c3                   	ret    

008009ab <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009ab:	55                   	push   %ebp
  8009ac:	89 e5                	mov    %esp,%ebp
  8009ae:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009b5:	eb 07                	jmp    8009be <strfind+0x13>
		if (*s == c)
  8009b7:	38 ca                	cmp    %cl,%dl
  8009b9:	74 0a                	je     8009c5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8009bb:	83 c0 01             	add    $0x1,%eax
  8009be:	0f b6 10             	movzbl (%eax),%edx
  8009c1:	84 d2                	test   %dl,%dl
  8009c3:	75 f2                	jne    8009b7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8009c5:	5d                   	pop    %ebp
  8009c6:	c3                   	ret    

008009c7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009c7:	55                   	push   %ebp
  8009c8:	89 e5                	mov    %esp,%ebp
  8009ca:	57                   	push   %edi
  8009cb:	56                   	push   %esi
  8009cc:	53                   	push   %ebx
  8009cd:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009d0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009d3:	85 c9                	test   %ecx,%ecx
  8009d5:	74 36                	je     800a0d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009d7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009dd:	75 28                	jne    800a07 <memset+0x40>
  8009df:	f6 c1 03             	test   $0x3,%cl
  8009e2:	75 23                	jne    800a07 <memset+0x40>
		c &= 0xFF;
  8009e4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009e8:	89 d3                	mov    %edx,%ebx
  8009ea:	c1 e3 08             	shl    $0x8,%ebx
  8009ed:	89 d6                	mov    %edx,%esi
  8009ef:	c1 e6 18             	shl    $0x18,%esi
  8009f2:	89 d0                	mov    %edx,%eax
  8009f4:	c1 e0 10             	shl    $0x10,%eax
  8009f7:	09 f0                	or     %esi,%eax
  8009f9:	09 c2                	or     %eax,%edx
  8009fb:	89 d0                	mov    %edx,%eax
  8009fd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  8009ff:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a02:	fc                   	cld    
  800a03:	f3 ab                	rep stos %eax,%es:(%edi)
  800a05:	eb 06                	jmp    800a0d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a07:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a0a:	fc                   	cld    
  800a0b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a0d:	89 f8                	mov    %edi,%eax
  800a0f:	5b                   	pop    %ebx
  800a10:	5e                   	pop    %esi
  800a11:	5f                   	pop    %edi
  800a12:	5d                   	pop    %ebp
  800a13:	c3                   	ret    

00800a14 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a14:	55                   	push   %ebp
  800a15:	89 e5                	mov    %esp,%ebp
  800a17:	57                   	push   %edi
  800a18:	56                   	push   %esi
  800a19:	8b 45 08             	mov    0x8(%ebp),%eax
  800a1c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a1f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a22:	39 c6                	cmp    %eax,%esi
  800a24:	73 35                	jae    800a5b <memmove+0x47>
  800a26:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a29:	39 d0                	cmp    %edx,%eax
  800a2b:	73 2e                	jae    800a5b <memmove+0x47>
		s += n;
		d += n;
  800a2d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800a30:	89 d6                	mov    %edx,%esi
  800a32:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a34:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a3a:	75 13                	jne    800a4f <memmove+0x3b>
  800a3c:	f6 c1 03             	test   $0x3,%cl
  800a3f:	75 0e                	jne    800a4f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a41:	83 ef 04             	sub    $0x4,%edi
  800a44:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a47:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a4a:	fd                   	std    
  800a4b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a4d:	eb 09                	jmp    800a58 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a4f:	83 ef 01             	sub    $0x1,%edi
  800a52:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a55:	fd                   	std    
  800a56:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a58:	fc                   	cld    
  800a59:	eb 1d                	jmp    800a78 <memmove+0x64>
  800a5b:	89 f2                	mov    %esi,%edx
  800a5d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a5f:	f6 c2 03             	test   $0x3,%dl
  800a62:	75 0f                	jne    800a73 <memmove+0x5f>
  800a64:	f6 c1 03             	test   $0x3,%cl
  800a67:	75 0a                	jne    800a73 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a69:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a6c:	89 c7                	mov    %eax,%edi
  800a6e:	fc                   	cld    
  800a6f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a71:	eb 05                	jmp    800a78 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a73:	89 c7                	mov    %eax,%edi
  800a75:	fc                   	cld    
  800a76:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a78:	5e                   	pop    %esi
  800a79:	5f                   	pop    %edi
  800a7a:	5d                   	pop    %ebp
  800a7b:	c3                   	ret    

00800a7c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a7c:	55                   	push   %ebp
  800a7d:	89 e5                	mov    %esp,%ebp
  800a7f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a82:	8b 45 10             	mov    0x10(%ebp),%eax
  800a85:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a89:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a8c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800a90:	8b 45 08             	mov    0x8(%ebp),%eax
  800a93:	89 04 24             	mov    %eax,(%esp)
  800a96:	e8 79 ff ff ff       	call   800a14 <memmove>
}
  800a9b:	c9                   	leave  
  800a9c:	c3                   	ret    

00800a9d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800a9d:	55                   	push   %ebp
  800a9e:	89 e5                	mov    %esp,%ebp
  800aa0:	56                   	push   %esi
  800aa1:	53                   	push   %ebx
  800aa2:	8b 55 08             	mov    0x8(%ebp),%edx
  800aa5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800aa8:	89 d6                	mov    %edx,%esi
  800aaa:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800aad:	eb 1a                	jmp    800ac9 <memcmp+0x2c>
		if (*s1 != *s2)
  800aaf:	0f b6 02             	movzbl (%edx),%eax
  800ab2:	0f b6 19             	movzbl (%ecx),%ebx
  800ab5:	38 d8                	cmp    %bl,%al
  800ab7:	74 0a                	je     800ac3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800ab9:	0f b6 c0             	movzbl %al,%eax
  800abc:	0f b6 db             	movzbl %bl,%ebx
  800abf:	29 d8                	sub    %ebx,%eax
  800ac1:	eb 0f                	jmp    800ad2 <memcmp+0x35>
		s1++, s2++;
  800ac3:	83 c2 01             	add    $0x1,%edx
  800ac6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ac9:	39 f2                	cmp    %esi,%edx
  800acb:	75 e2                	jne    800aaf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800acd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ad2:	5b                   	pop    %ebx
  800ad3:	5e                   	pop    %esi
  800ad4:	5d                   	pop    %ebp
  800ad5:	c3                   	ret    

00800ad6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ad6:	55                   	push   %ebp
  800ad7:	89 e5                	mov    %esp,%ebp
  800ad9:	8b 45 08             	mov    0x8(%ebp),%eax
  800adc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800adf:	89 c2                	mov    %eax,%edx
  800ae1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800ae4:	eb 07                	jmp    800aed <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800ae6:	38 08                	cmp    %cl,(%eax)
  800ae8:	74 07                	je     800af1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800aea:	83 c0 01             	add    $0x1,%eax
  800aed:	39 d0                	cmp    %edx,%eax
  800aef:	72 f5                	jb     800ae6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800af1:	5d                   	pop    %ebp
  800af2:	c3                   	ret    

00800af3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800af3:	55                   	push   %ebp
  800af4:	89 e5                	mov    %esp,%ebp
  800af6:	57                   	push   %edi
  800af7:	56                   	push   %esi
  800af8:	53                   	push   %ebx
  800af9:	8b 55 08             	mov    0x8(%ebp),%edx
  800afc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800aff:	eb 03                	jmp    800b04 <strtol+0x11>
		s++;
  800b01:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b04:	0f b6 0a             	movzbl (%edx),%ecx
  800b07:	80 f9 09             	cmp    $0x9,%cl
  800b0a:	74 f5                	je     800b01 <strtol+0xe>
  800b0c:	80 f9 20             	cmp    $0x20,%cl
  800b0f:	74 f0                	je     800b01 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b11:	80 f9 2b             	cmp    $0x2b,%cl
  800b14:	75 0a                	jne    800b20 <strtol+0x2d>
		s++;
  800b16:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b19:	bf 00 00 00 00       	mov    $0x0,%edi
  800b1e:	eb 11                	jmp    800b31 <strtol+0x3e>
  800b20:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b25:	80 f9 2d             	cmp    $0x2d,%cl
  800b28:	75 07                	jne    800b31 <strtol+0x3e>
		s++, neg = 1;
  800b2a:	8d 52 01             	lea    0x1(%edx),%edx
  800b2d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b31:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b36:	75 15                	jne    800b4d <strtol+0x5a>
  800b38:	80 3a 30             	cmpb   $0x30,(%edx)
  800b3b:	75 10                	jne    800b4d <strtol+0x5a>
  800b3d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b41:	75 0a                	jne    800b4d <strtol+0x5a>
		s += 2, base = 16;
  800b43:	83 c2 02             	add    $0x2,%edx
  800b46:	b8 10 00 00 00       	mov    $0x10,%eax
  800b4b:	eb 10                	jmp    800b5d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800b4d:	85 c0                	test   %eax,%eax
  800b4f:	75 0c                	jne    800b5d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b51:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b53:	80 3a 30             	cmpb   $0x30,(%edx)
  800b56:	75 05                	jne    800b5d <strtol+0x6a>
		s++, base = 8;
  800b58:	83 c2 01             	add    $0x1,%edx
  800b5b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800b5d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b62:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b65:	0f b6 0a             	movzbl (%edx),%ecx
  800b68:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b6b:	89 f0                	mov    %esi,%eax
  800b6d:	3c 09                	cmp    $0x9,%al
  800b6f:	77 08                	ja     800b79 <strtol+0x86>
			dig = *s - '0';
  800b71:	0f be c9             	movsbl %cl,%ecx
  800b74:	83 e9 30             	sub    $0x30,%ecx
  800b77:	eb 20                	jmp    800b99 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b79:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b7c:	89 f0                	mov    %esi,%eax
  800b7e:	3c 19                	cmp    $0x19,%al
  800b80:	77 08                	ja     800b8a <strtol+0x97>
			dig = *s - 'a' + 10;
  800b82:	0f be c9             	movsbl %cl,%ecx
  800b85:	83 e9 57             	sub    $0x57,%ecx
  800b88:	eb 0f                	jmp    800b99 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800b8a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b8d:	89 f0                	mov    %esi,%eax
  800b8f:	3c 19                	cmp    $0x19,%al
  800b91:	77 16                	ja     800ba9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800b93:	0f be c9             	movsbl %cl,%ecx
  800b96:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800b99:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800b9c:	7d 0f                	jge    800bad <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800b9e:	83 c2 01             	add    $0x1,%edx
  800ba1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800ba5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800ba7:	eb bc                	jmp    800b65 <strtol+0x72>
  800ba9:	89 d8                	mov    %ebx,%eax
  800bab:	eb 02                	jmp    800baf <strtol+0xbc>
  800bad:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800baf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bb3:	74 05                	je     800bba <strtol+0xc7>
		*endptr = (char *) s;
  800bb5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bb8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800bba:	f7 d8                	neg    %eax
  800bbc:	85 ff                	test   %edi,%edi
  800bbe:	0f 44 c3             	cmove  %ebx,%eax
}
  800bc1:	5b                   	pop    %ebx
  800bc2:	5e                   	pop    %esi
  800bc3:	5f                   	pop    %edi
  800bc4:	5d                   	pop    %ebp
  800bc5:	c3                   	ret    
  800bc6:	66 90                	xchg   %ax,%ax
  800bc8:	66 90                	xchg   %ax,%ax
  800bca:	66 90                	xchg   %ax,%ax
  800bcc:	66 90                	xchg   %ax,%ax
  800bce:	66 90                	xchg   %ax,%ax

00800bd0 <__udivdi3>:
  800bd0:	55                   	push   %ebp
  800bd1:	57                   	push   %edi
  800bd2:	56                   	push   %esi
  800bd3:	83 ec 0c             	sub    $0xc,%esp
  800bd6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800bda:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800bde:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800be2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800be6:	85 c0                	test   %eax,%eax
  800be8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800bec:	89 ea                	mov    %ebp,%edx
  800bee:	89 0c 24             	mov    %ecx,(%esp)
  800bf1:	75 2d                	jne    800c20 <__udivdi3+0x50>
  800bf3:	39 e9                	cmp    %ebp,%ecx
  800bf5:	77 61                	ja     800c58 <__udivdi3+0x88>
  800bf7:	85 c9                	test   %ecx,%ecx
  800bf9:	89 ce                	mov    %ecx,%esi
  800bfb:	75 0b                	jne    800c08 <__udivdi3+0x38>
  800bfd:	b8 01 00 00 00       	mov    $0x1,%eax
  800c02:	31 d2                	xor    %edx,%edx
  800c04:	f7 f1                	div    %ecx
  800c06:	89 c6                	mov    %eax,%esi
  800c08:	31 d2                	xor    %edx,%edx
  800c0a:	89 e8                	mov    %ebp,%eax
  800c0c:	f7 f6                	div    %esi
  800c0e:	89 c5                	mov    %eax,%ebp
  800c10:	89 f8                	mov    %edi,%eax
  800c12:	f7 f6                	div    %esi
  800c14:	89 ea                	mov    %ebp,%edx
  800c16:	83 c4 0c             	add    $0xc,%esp
  800c19:	5e                   	pop    %esi
  800c1a:	5f                   	pop    %edi
  800c1b:	5d                   	pop    %ebp
  800c1c:	c3                   	ret    
  800c1d:	8d 76 00             	lea    0x0(%esi),%esi
  800c20:	39 e8                	cmp    %ebp,%eax
  800c22:	77 24                	ja     800c48 <__udivdi3+0x78>
  800c24:	0f bd e8             	bsr    %eax,%ebp
  800c27:	83 f5 1f             	xor    $0x1f,%ebp
  800c2a:	75 3c                	jne    800c68 <__udivdi3+0x98>
  800c2c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800c30:	39 34 24             	cmp    %esi,(%esp)
  800c33:	0f 86 9f 00 00 00    	jbe    800cd8 <__udivdi3+0x108>
  800c39:	39 d0                	cmp    %edx,%eax
  800c3b:	0f 82 97 00 00 00    	jb     800cd8 <__udivdi3+0x108>
  800c41:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c48:	31 d2                	xor    %edx,%edx
  800c4a:	31 c0                	xor    %eax,%eax
  800c4c:	83 c4 0c             	add    $0xc,%esp
  800c4f:	5e                   	pop    %esi
  800c50:	5f                   	pop    %edi
  800c51:	5d                   	pop    %ebp
  800c52:	c3                   	ret    
  800c53:	90                   	nop
  800c54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c58:	89 f8                	mov    %edi,%eax
  800c5a:	f7 f1                	div    %ecx
  800c5c:	31 d2                	xor    %edx,%edx
  800c5e:	83 c4 0c             	add    $0xc,%esp
  800c61:	5e                   	pop    %esi
  800c62:	5f                   	pop    %edi
  800c63:	5d                   	pop    %ebp
  800c64:	c3                   	ret    
  800c65:	8d 76 00             	lea    0x0(%esi),%esi
  800c68:	89 e9                	mov    %ebp,%ecx
  800c6a:	8b 3c 24             	mov    (%esp),%edi
  800c6d:	d3 e0                	shl    %cl,%eax
  800c6f:	89 c6                	mov    %eax,%esi
  800c71:	b8 20 00 00 00       	mov    $0x20,%eax
  800c76:	29 e8                	sub    %ebp,%eax
  800c78:	89 c1                	mov    %eax,%ecx
  800c7a:	d3 ef                	shr    %cl,%edi
  800c7c:	89 e9                	mov    %ebp,%ecx
  800c7e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c82:	8b 3c 24             	mov    (%esp),%edi
  800c85:	09 74 24 08          	or     %esi,0x8(%esp)
  800c89:	89 d6                	mov    %edx,%esi
  800c8b:	d3 e7                	shl    %cl,%edi
  800c8d:	89 c1                	mov    %eax,%ecx
  800c8f:	89 3c 24             	mov    %edi,(%esp)
  800c92:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800c96:	d3 ee                	shr    %cl,%esi
  800c98:	89 e9                	mov    %ebp,%ecx
  800c9a:	d3 e2                	shl    %cl,%edx
  800c9c:	89 c1                	mov    %eax,%ecx
  800c9e:	d3 ef                	shr    %cl,%edi
  800ca0:	09 d7                	or     %edx,%edi
  800ca2:	89 f2                	mov    %esi,%edx
  800ca4:	89 f8                	mov    %edi,%eax
  800ca6:	f7 74 24 08          	divl   0x8(%esp)
  800caa:	89 d6                	mov    %edx,%esi
  800cac:	89 c7                	mov    %eax,%edi
  800cae:	f7 24 24             	mull   (%esp)
  800cb1:	39 d6                	cmp    %edx,%esi
  800cb3:	89 14 24             	mov    %edx,(%esp)
  800cb6:	72 30                	jb     800ce8 <__udivdi3+0x118>
  800cb8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800cbc:	89 e9                	mov    %ebp,%ecx
  800cbe:	d3 e2                	shl    %cl,%edx
  800cc0:	39 c2                	cmp    %eax,%edx
  800cc2:	73 05                	jae    800cc9 <__udivdi3+0xf9>
  800cc4:	3b 34 24             	cmp    (%esp),%esi
  800cc7:	74 1f                	je     800ce8 <__udivdi3+0x118>
  800cc9:	89 f8                	mov    %edi,%eax
  800ccb:	31 d2                	xor    %edx,%edx
  800ccd:	e9 7a ff ff ff       	jmp    800c4c <__udivdi3+0x7c>
  800cd2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cd8:	31 d2                	xor    %edx,%edx
  800cda:	b8 01 00 00 00       	mov    $0x1,%eax
  800cdf:	e9 68 ff ff ff       	jmp    800c4c <__udivdi3+0x7c>
  800ce4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800ce8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800ceb:	31 d2                	xor    %edx,%edx
  800ced:	83 c4 0c             	add    $0xc,%esp
  800cf0:	5e                   	pop    %esi
  800cf1:	5f                   	pop    %edi
  800cf2:	5d                   	pop    %ebp
  800cf3:	c3                   	ret    
  800cf4:	66 90                	xchg   %ax,%ax
  800cf6:	66 90                	xchg   %ax,%ax
  800cf8:	66 90                	xchg   %ax,%ax
  800cfa:	66 90                	xchg   %ax,%ax
  800cfc:	66 90                	xchg   %ax,%ax
  800cfe:	66 90                	xchg   %ax,%ax

00800d00 <__umoddi3>:
  800d00:	55                   	push   %ebp
  800d01:	57                   	push   %edi
  800d02:	56                   	push   %esi
  800d03:	83 ec 14             	sub    $0x14,%esp
  800d06:	8b 44 24 28          	mov    0x28(%esp),%eax
  800d0a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800d0e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800d12:	89 c7                	mov    %eax,%edi
  800d14:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d18:	8b 44 24 30          	mov    0x30(%esp),%eax
  800d1c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800d20:	89 34 24             	mov    %esi,(%esp)
  800d23:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d27:	85 c0                	test   %eax,%eax
  800d29:	89 c2                	mov    %eax,%edx
  800d2b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d2f:	75 17                	jne    800d48 <__umoddi3+0x48>
  800d31:	39 fe                	cmp    %edi,%esi
  800d33:	76 4b                	jbe    800d80 <__umoddi3+0x80>
  800d35:	89 c8                	mov    %ecx,%eax
  800d37:	89 fa                	mov    %edi,%edx
  800d39:	f7 f6                	div    %esi
  800d3b:	89 d0                	mov    %edx,%eax
  800d3d:	31 d2                	xor    %edx,%edx
  800d3f:	83 c4 14             	add    $0x14,%esp
  800d42:	5e                   	pop    %esi
  800d43:	5f                   	pop    %edi
  800d44:	5d                   	pop    %ebp
  800d45:	c3                   	ret    
  800d46:	66 90                	xchg   %ax,%ax
  800d48:	39 f8                	cmp    %edi,%eax
  800d4a:	77 54                	ja     800da0 <__umoddi3+0xa0>
  800d4c:	0f bd e8             	bsr    %eax,%ebp
  800d4f:	83 f5 1f             	xor    $0x1f,%ebp
  800d52:	75 5c                	jne    800db0 <__umoddi3+0xb0>
  800d54:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800d58:	39 3c 24             	cmp    %edi,(%esp)
  800d5b:	0f 87 e7 00 00 00    	ja     800e48 <__umoddi3+0x148>
  800d61:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d65:	29 f1                	sub    %esi,%ecx
  800d67:	19 c7                	sbb    %eax,%edi
  800d69:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d6d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d71:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d75:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d79:	83 c4 14             	add    $0x14,%esp
  800d7c:	5e                   	pop    %esi
  800d7d:	5f                   	pop    %edi
  800d7e:	5d                   	pop    %ebp
  800d7f:	c3                   	ret    
  800d80:	85 f6                	test   %esi,%esi
  800d82:	89 f5                	mov    %esi,%ebp
  800d84:	75 0b                	jne    800d91 <__umoddi3+0x91>
  800d86:	b8 01 00 00 00       	mov    $0x1,%eax
  800d8b:	31 d2                	xor    %edx,%edx
  800d8d:	f7 f6                	div    %esi
  800d8f:	89 c5                	mov    %eax,%ebp
  800d91:	8b 44 24 04          	mov    0x4(%esp),%eax
  800d95:	31 d2                	xor    %edx,%edx
  800d97:	f7 f5                	div    %ebp
  800d99:	89 c8                	mov    %ecx,%eax
  800d9b:	f7 f5                	div    %ebp
  800d9d:	eb 9c                	jmp    800d3b <__umoddi3+0x3b>
  800d9f:	90                   	nop
  800da0:	89 c8                	mov    %ecx,%eax
  800da2:	89 fa                	mov    %edi,%edx
  800da4:	83 c4 14             	add    $0x14,%esp
  800da7:	5e                   	pop    %esi
  800da8:	5f                   	pop    %edi
  800da9:	5d                   	pop    %ebp
  800daa:	c3                   	ret    
  800dab:	90                   	nop
  800dac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800db0:	8b 04 24             	mov    (%esp),%eax
  800db3:	be 20 00 00 00       	mov    $0x20,%esi
  800db8:	89 e9                	mov    %ebp,%ecx
  800dba:	29 ee                	sub    %ebp,%esi
  800dbc:	d3 e2                	shl    %cl,%edx
  800dbe:	89 f1                	mov    %esi,%ecx
  800dc0:	d3 e8                	shr    %cl,%eax
  800dc2:	89 e9                	mov    %ebp,%ecx
  800dc4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800dc8:	8b 04 24             	mov    (%esp),%eax
  800dcb:	09 54 24 04          	or     %edx,0x4(%esp)
  800dcf:	89 fa                	mov    %edi,%edx
  800dd1:	d3 e0                	shl    %cl,%eax
  800dd3:	89 f1                	mov    %esi,%ecx
  800dd5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800dd9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800ddd:	d3 ea                	shr    %cl,%edx
  800ddf:	89 e9                	mov    %ebp,%ecx
  800de1:	d3 e7                	shl    %cl,%edi
  800de3:	89 f1                	mov    %esi,%ecx
  800de5:	d3 e8                	shr    %cl,%eax
  800de7:	89 e9                	mov    %ebp,%ecx
  800de9:	09 f8                	or     %edi,%eax
  800deb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800def:	f7 74 24 04          	divl   0x4(%esp)
  800df3:	d3 e7                	shl    %cl,%edi
  800df5:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800df9:	89 d7                	mov    %edx,%edi
  800dfb:	f7 64 24 08          	mull   0x8(%esp)
  800dff:	39 d7                	cmp    %edx,%edi
  800e01:	89 c1                	mov    %eax,%ecx
  800e03:	89 14 24             	mov    %edx,(%esp)
  800e06:	72 2c                	jb     800e34 <__umoddi3+0x134>
  800e08:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800e0c:	72 22                	jb     800e30 <__umoddi3+0x130>
  800e0e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e12:	29 c8                	sub    %ecx,%eax
  800e14:	19 d7                	sbb    %edx,%edi
  800e16:	89 e9                	mov    %ebp,%ecx
  800e18:	89 fa                	mov    %edi,%edx
  800e1a:	d3 e8                	shr    %cl,%eax
  800e1c:	89 f1                	mov    %esi,%ecx
  800e1e:	d3 e2                	shl    %cl,%edx
  800e20:	89 e9                	mov    %ebp,%ecx
  800e22:	d3 ef                	shr    %cl,%edi
  800e24:	09 d0                	or     %edx,%eax
  800e26:	89 fa                	mov    %edi,%edx
  800e28:	83 c4 14             	add    $0x14,%esp
  800e2b:	5e                   	pop    %esi
  800e2c:	5f                   	pop    %edi
  800e2d:	5d                   	pop    %ebp
  800e2e:	c3                   	ret    
  800e2f:	90                   	nop
  800e30:	39 d7                	cmp    %edx,%edi
  800e32:	75 da                	jne    800e0e <__umoddi3+0x10e>
  800e34:	8b 14 24             	mov    (%esp),%edx
  800e37:	89 c1                	mov    %eax,%ecx
  800e39:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800e3d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800e41:	eb cb                	jmp    800e0e <__umoddi3+0x10e>
  800e43:	90                   	nop
  800e44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e48:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800e4c:	0f 82 0f ff ff ff    	jb     800d61 <__umoddi3+0x61>
  800e52:	e9 1a ff ff ff       	jmp    800d71 <__umoddi3+0x71>
