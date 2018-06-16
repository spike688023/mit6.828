
obj/user/faultwritekernel:     file format elf32-i386


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
  80002c:	e8 11 00 00 00       	call   800042 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
	*(unsigned*)0xf0100000 = 0;
  800036:	c7 05 00 00 10 f0 00 	movl   $0x0,0xf0100000
  80003d:	00 00 00 
}
  800040:	5d                   	pop    %ebp
  800041:	c3                   	ret    

00800042 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800042:	55                   	push   %ebp
  800043:	89 e5                	mov    %esp,%ebp
  800045:	56                   	push   %esi
  800046:	53                   	push   %ebx
  800047:	83 ec 10             	sub    $0x10,%esp
  80004a:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80004d:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  800050:	e8 db 00 00 00       	call   800130 <sys_getenvid>
  800055:	25 ff 03 00 00       	and    $0x3ff,%eax
  80005a:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80005d:	c1 e0 05             	shl    $0x5,%eax
  800060:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800065:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  80006a:	85 db                	test   %ebx,%ebx
  80006c:	7e 07                	jle    800075 <libmain+0x33>
		binaryname = argv[0];
  80006e:	8b 06                	mov    (%esi),%eax
  800070:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800075:	89 74 24 04          	mov    %esi,0x4(%esp)
  800079:	89 1c 24             	mov    %ebx,(%esp)
  80007c:	e8 b2 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  800081:	e8 07 00 00 00       	call   80008d <exit>
}
  800086:	83 c4 10             	add    $0x10,%esp
  800089:	5b                   	pop    %ebx
  80008a:	5e                   	pop    %esi
  80008b:	5d                   	pop    %ebp
  80008c:	c3                   	ret    

0080008d <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80008d:	55                   	push   %ebp
  80008e:	89 e5                	mov    %esp,%ebp
  800090:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  800093:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  80009a:	e8 3f 00 00 00       	call   8000de <sys_env_destroy>
}
  80009f:	c9                   	leave  
  8000a0:	c3                   	ret    

008000a1 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  8000a1:	55                   	push   %ebp
  8000a2:	89 e5                	mov    %esp,%ebp
  8000a4:	57                   	push   %edi
  8000a5:	56                   	push   %esi
  8000a6:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000a7:	b8 00 00 00 00       	mov    $0x0,%eax
  8000ac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8000af:	8b 55 08             	mov    0x8(%ebp),%edx
  8000b2:	89 c3                	mov    %eax,%ebx
  8000b4:	89 c7                	mov    %eax,%edi
  8000b6:	89 c6                	mov    %eax,%esi
  8000b8:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  8000ba:	5b                   	pop    %ebx
  8000bb:	5e                   	pop    %esi
  8000bc:	5f                   	pop    %edi
  8000bd:	5d                   	pop    %ebp
  8000be:	c3                   	ret    

008000bf <sys_cgetc>:

int
sys_cgetc(void)
{
  8000bf:	55                   	push   %ebp
  8000c0:	89 e5                	mov    %esp,%ebp
  8000c2:	57                   	push   %edi
  8000c3:	56                   	push   %esi
  8000c4:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000c5:	ba 00 00 00 00       	mov    $0x0,%edx
  8000ca:	b8 01 00 00 00       	mov    $0x1,%eax
  8000cf:	89 d1                	mov    %edx,%ecx
  8000d1:	89 d3                	mov    %edx,%ebx
  8000d3:	89 d7                	mov    %edx,%edi
  8000d5:	89 d6                	mov    %edx,%esi
  8000d7:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  8000d9:	5b                   	pop    %ebx
  8000da:	5e                   	pop    %esi
  8000db:	5f                   	pop    %edi
  8000dc:	5d                   	pop    %ebp
  8000dd:	c3                   	ret    

008000de <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  8000de:	55                   	push   %ebp
  8000df:	89 e5                	mov    %esp,%ebp
  8000e1:	57                   	push   %edi
  8000e2:	56                   	push   %esi
  8000e3:	53                   	push   %ebx
  8000e4:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  8000e7:	b9 00 00 00 00       	mov    $0x0,%ecx
  8000ec:	b8 03 00 00 00       	mov    $0x3,%eax
  8000f1:	8b 55 08             	mov    0x8(%ebp),%edx
  8000f4:	89 cb                	mov    %ecx,%ebx
  8000f6:	89 cf                	mov    %ecx,%edi
  8000f8:	89 ce                	mov    %ecx,%esi
  8000fa:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  8000fc:	85 c0                	test   %eax,%eax
  8000fe:	7e 28                	jle    800128 <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800100:	89 44 24 10          	mov    %eax,0x10(%esp)
  800104:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  80010b:	00 
  80010c:	c7 44 24 08 8a 0e 80 	movl   $0x800e8a,0x8(%esp)
  800113:	00 
  800114:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  80011b:	00 
  80011c:	c7 04 24 a7 0e 80 00 	movl   $0x800ea7,(%esp)
  800123:	e8 27 00 00 00       	call   80014f <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800128:	83 c4 2c             	add    $0x2c,%esp
  80012b:	5b                   	pop    %ebx
  80012c:	5e                   	pop    %esi
  80012d:	5f                   	pop    %edi
  80012e:	5d                   	pop    %ebp
  80012f:	c3                   	ret    

00800130 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800130:	55                   	push   %ebp
  800131:	89 e5                	mov    %esp,%ebp
  800133:	57                   	push   %edi
  800134:	56                   	push   %esi
  800135:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800136:	ba 00 00 00 00       	mov    $0x0,%edx
  80013b:	b8 02 00 00 00       	mov    $0x2,%eax
  800140:	89 d1                	mov    %edx,%ecx
  800142:	89 d3                	mov    %edx,%ebx
  800144:	89 d7                	mov    %edx,%edi
  800146:	89 d6                	mov    %edx,%esi
  800148:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  80014a:	5b                   	pop    %ebx
  80014b:	5e                   	pop    %esi
  80014c:	5f                   	pop    %edi
  80014d:	5d                   	pop    %ebp
  80014e:	c3                   	ret    

0080014f <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  80014f:	55                   	push   %ebp
  800150:	89 e5                	mov    %esp,%ebp
  800152:	56                   	push   %esi
  800153:	53                   	push   %ebx
  800154:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800157:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  80015a:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800160:	e8 cb ff ff ff       	call   800130 <sys_getenvid>
  800165:	8b 55 0c             	mov    0xc(%ebp),%edx
  800168:	89 54 24 10          	mov    %edx,0x10(%esp)
  80016c:	8b 55 08             	mov    0x8(%ebp),%edx
  80016f:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800173:	89 74 24 08          	mov    %esi,0x8(%esp)
  800177:	89 44 24 04          	mov    %eax,0x4(%esp)
  80017b:	c7 04 24 b8 0e 80 00 	movl   $0x800eb8,(%esp)
  800182:	e8 c1 00 00 00       	call   800248 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800187:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  80018b:	8b 45 10             	mov    0x10(%ebp),%eax
  80018e:	89 04 24             	mov    %eax,(%esp)
  800191:	e8 51 00 00 00       	call   8001e7 <vcprintf>
	cprintf("\n");
  800196:	c7 04 24 dc 0e 80 00 	movl   $0x800edc,(%esp)
  80019d:	e8 a6 00 00 00       	call   800248 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  8001a2:	cc                   	int3   
  8001a3:	eb fd                	jmp    8001a2 <_panic+0x53>

008001a5 <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8001a5:	55                   	push   %ebp
  8001a6:	89 e5                	mov    %esp,%ebp
  8001a8:	53                   	push   %ebx
  8001a9:	83 ec 14             	sub    $0x14,%esp
  8001ac:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8001af:	8b 13                	mov    (%ebx),%edx
  8001b1:	8d 42 01             	lea    0x1(%edx),%eax
  8001b4:	89 03                	mov    %eax,(%ebx)
  8001b6:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8001b9:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8001bd:	3d ff 00 00 00       	cmp    $0xff,%eax
  8001c2:	75 19                	jne    8001dd <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8001c4:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8001cb:	00 
  8001cc:	8d 43 08             	lea    0x8(%ebx),%eax
  8001cf:	89 04 24             	mov    %eax,(%esp)
  8001d2:	e8 ca fe ff ff       	call   8000a1 <sys_cputs>
		b->idx = 0;
  8001d7:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8001dd:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8001e1:	83 c4 14             	add    $0x14,%esp
  8001e4:	5b                   	pop    %ebx
  8001e5:	5d                   	pop    %ebp
  8001e6:	c3                   	ret    

008001e7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8001e7:	55                   	push   %ebp
  8001e8:	89 e5                	mov    %esp,%ebp
  8001ea:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8001f0:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  8001f7:	00 00 00 
	b.cnt = 0;
  8001fa:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  800201:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  800204:	8b 45 0c             	mov    0xc(%ebp),%eax
  800207:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80020b:	8b 45 08             	mov    0x8(%ebp),%eax
  80020e:	89 44 24 08          	mov    %eax,0x8(%esp)
  800212:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800218:	89 44 24 04          	mov    %eax,0x4(%esp)
  80021c:	c7 04 24 a5 01 80 00 	movl   $0x8001a5,(%esp)
  800223:	e8 b6 01 00 00       	call   8003de <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800228:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  80022e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800232:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800238:	89 04 24             	mov    %eax,(%esp)
  80023b:	e8 61 fe ff ff       	call   8000a1 <sys_cputs>

	return b.cnt;
}
  800240:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800246:	c9                   	leave  
  800247:	c3                   	ret    

00800248 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800248:	55                   	push   %ebp
  800249:	89 e5                	mov    %esp,%ebp
  80024b:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  80024e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  800251:	89 44 24 04          	mov    %eax,0x4(%esp)
  800255:	8b 45 08             	mov    0x8(%ebp),%eax
  800258:	89 04 24             	mov    %eax,(%esp)
  80025b:	e8 87 ff ff ff       	call   8001e7 <vcprintf>
	va_end(ap);

	return cnt;
}
  800260:	c9                   	leave  
  800261:	c3                   	ret    
  800262:	66 90                	xchg   %ax,%ax
  800264:	66 90                	xchg   %ax,%ax
  800266:	66 90                	xchg   %ax,%ax
  800268:	66 90                	xchg   %ax,%ax
  80026a:	66 90                	xchg   %ax,%ax
  80026c:	66 90                	xchg   %ax,%ax
  80026e:	66 90                	xchg   %ax,%ax

00800270 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800270:	55                   	push   %ebp
  800271:	89 e5                	mov    %esp,%ebp
  800273:	57                   	push   %edi
  800274:	56                   	push   %esi
  800275:	53                   	push   %ebx
  800276:	83 ec 3c             	sub    $0x3c,%esp
  800279:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80027c:	89 d7                	mov    %edx,%edi
  80027e:	8b 45 08             	mov    0x8(%ebp),%eax
  800281:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800284:	8b 45 0c             	mov    0xc(%ebp),%eax
  800287:	89 c3                	mov    %eax,%ebx
  800289:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80028c:	8b 45 10             	mov    0x10(%ebp),%eax
  80028f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800292:	b9 00 00 00 00       	mov    $0x0,%ecx
  800297:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80029a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80029d:	39 d9                	cmp    %ebx,%ecx
  80029f:	72 05                	jb     8002a6 <printnum+0x36>
  8002a1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8002a4:	77 69                	ja     80030f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8002a6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8002a9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8002ad:	83 ee 01             	sub    $0x1,%esi
  8002b0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002b4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002b8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8002bc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8002c0:	89 c3                	mov    %eax,%ebx
  8002c2:	89 d6                	mov    %edx,%esi
  8002c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8002c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8002ca:	89 54 24 08          	mov    %edx,0x8(%esp)
  8002ce:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8002d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8002d5:	89 04 24             	mov    %eax,(%esp)
  8002d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8002db:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002df:	e8 fc 08 00 00       	call   800be0 <__udivdi3>
  8002e4:	89 d9                	mov    %ebx,%ecx
  8002e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8002ea:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8002ee:	89 04 24             	mov    %eax,(%esp)
  8002f1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8002f5:	89 fa                	mov    %edi,%edx
  8002f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8002fa:	e8 71 ff ff ff       	call   800270 <printnum>
  8002ff:	eb 1b                	jmp    80031c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800301:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800305:	8b 45 18             	mov    0x18(%ebp),%eax
  800308:	89 04 24             	mov    %eax,(%esp)
  80030b:	ff d3                	call   *%ebx
  80030d:	eb 03                	jmp    800312 <printnum+0xa2>
  80030f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800312:	83 ee 01             	sub    $0x1,%esi
  800315:	85 f6                	test   %esi,%esi
  800317:	7f e8                	jg     800301 <printnum+0x91>
  800319:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80031c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800320:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800324:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800327:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80032a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80032e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800332:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800335:	89 04 24             	mov    %eax,(%esp)
  800338:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80033b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80033f:	e8 cc 09 00 00       	call   800d10 <__umoddi3>
  800344:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800348:	0f be 80 de 0e 80 00 	movsbl 0x800ede(%eax),%eax
  80034f:	89 04 24             	mov    %eax,(%esp)
  800352:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800355:	ff d0                	call   *%eax
}
  800357:	83 c4 3c             	add    $0x3c,%esp
  80035a:	5b                   	pop    %ebx
  80035b:	5e                   	pop    %esi
  80035c:	5f                   	pop    %edi
  80035d:	5d                   	pop    %ebp
  80035e:	c3                   	ret    

0080035f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80035f:	55                   	push   %ebp
  800360:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800362:	83 fa 01             	cmp    $0x1,%edx
  800365:	7e 0e                	jle    800375 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800367:	8b 10                	mov    (%eax),%edx
  800369:	8d 4a 08             	lea    0x8(%edx),%ecx
  80036c:	89 08                	mov    %ecx,(%eax)
  80036e:	8b 02                	mov    (%edx),%eax
  800370:	8b 52 04             	mov    0x4(%edx),%edx
  800373:	eb 22                	jmp    800397 <getuint+0x38>
	else if (lflag)
  800375:	85 d2                	test   %edx,%edx
  800377:	74 10                	je     800389 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800379:	8b 10                	mov    (%eax),%edx
  80037b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80037e:	89 08                	mov    %ecx,(%eax)
  800380:	8b 02                	mov    (%edx),%eax
  800382:	ba 00 00 00 00       	mov    $0x0,%edx
  800387:	eb 0e                	jmp    800397 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800389:	8b 10                	mov    (%eax),%edx
  80038b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80038e:	89 08                	mov    %ecx,(%eax)
  800390:	8b 02                	mov    (%edx),%eax
  800392:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800397:	5d                   	pop    %ebp
  800398:	c3                   	ret    

00800399 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800399:	55                   	push   %ebp
  80039a:	89 e5                	mov    %esp,%ebp
  80039c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80039f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8003a3:	8b 10                	mov    (%eax),%edx
  8003a5:	3b 50 04             	cmp    0x4(%eax),%edx
  8003a8:	73 0a                	jae    8003b4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8003aa:	8d 4a 01             	lea    0x1(%edx),%ecx
  8003ad:	89 08                	mov    %ecx,(%eax)
  8003af:	8b 45 08             	mov    0x8(%ebp),%eax
  8003b2:	88 02                	mov    %al,(%edx)
}
  8003b4:	5d                   	pop    %ebp
  8003b5:	c3                   	ret    

008003b6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8003b6:	55                   	push   %ebp
  8003b7:	89 e5                	mov    %esp,%ebp
  8003b9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8003bc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8003bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8003c3:	8b 45 10             	mov    0x10(%ebp),%eax
  8003c6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8003ca:	8b 45 0c             	mov    0xc(%ebp),%eax
  8003cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8003d1:	8b 45 08             	mov    0x8(%ebp),%eax
  8003d4:	89 04 24             	mov    %eax,(%esp)
  8003d7:	e8 02 00 00 00       	call   8003de <vprintfmt>
	va_end(ap);
}
  8003dc:	c9                   	leave  
  8003dd:	c3                   	ret    

008003de <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8003de:	55                   	push   %ebp
  8003df:	89 e5                	mov    %esp,%ebp
  8003e1:	57                   	push   %edi
  8003e2:	56                   	push   %esi
  8003e3:	53                   	push   %ebx
  8003e4:	83 ec 3c             	sub    $0x3c,%esp
  8003e7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8003ea:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8003ed:	eb 14                	jmp    800403 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')									//当然中间如果遇到'\0'，代表这个字符串的访问结束
  8003ef:	85 c0                	test   %eax,%eax
  8003f1:	0f 84 c7 03 00 00    	je     8007be <vprintfmt+0x3e0>
				return;
			putch(ch, putdat);								//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  8003f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003fb:	89 04 24             	mov    %eax,(%esp)
  8003fe:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  800401:	89 f3                	mov    %esi,%ebx
  800403:	8d 73 01             	lea    0x1(%ebx),%esi
  800406:	0f b6 03             	movzbl (%ebx),%eax
  800409:	83 f8 25             	cmp    $0x25,%eax
  80040c:	75 e1                	jne    8003ef <vprintfmt+0x11>
  80040e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800412:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800419:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800420:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800427:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  80042e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800433:	eb 1d                	jmp    800452 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800435:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':											//%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  800437:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  80043b:	eb 15                	jmp    800452 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  80043d:	89 de                	mov    %ebx,%esi
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;									//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0':											//0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';										//对其方式标志位变为0
  80043f:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  800443:	eb 0d                	jmp    800452 <vprintfmt+0x74>
			altflag = 1;
			goto reswitch;

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
				width = precision, precision = -1;
  800445:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800448:	89 45 dc             	mov    %eax,-0x24(%ebp)
  80044b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800452:	8d 5e 01             	lea    0x1(%esi),%ebx
  800455:	0f b6 16             	movzbl (%esi),%edx
  800458:	0f b6 c2             	movzbl %dl,%eax
  80045b:	83 ea 23             	sub    $0x23,%edx
  80045e:	80 fa 55             	cmp    $0x55,%dl
  800461:	0f 87 37 03 00 00    	ja     80079e <vprintfmt+0x3c0>
  800467:	0f b6 d2             	movzbl %dl,%edx
  80046a:	ff 24 95 80 0f 80 00 	jmp    *0x800f80(,%edx,4)
  800471:	89 de                	mov    %ebx,%esi
  800473:	89 ca                	mov    %ecx,%edx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  800475:	8d 14 92             	lea    (%edx,%edx,4),%edx
  800478:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  80047c:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80047f:	8d 58 d0             	lea    -0x30(%eax),%ebx
  800482:	83 fb 09             	cmp    $0x9,%ebx
  800485:	77 31                	ja     8004b8 <vprintfmt+0xda>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  800487:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80048a:	eb e9                	jmp    800475 <vprintfmt+0x97>
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  80048c:	8b 45 14             	mov    0x14(%ebp),%eax
  80048f:	8d 50 04             	lea    0x4(%eax),%edx
  800492:	89 55 14             	mov    %edx,0x14(%ebp)
  800495:	8b 00                	mov    (%eax),%eax
  800497:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  80049a:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  80049c:	eb 1d                	jmp    8004bb <vprintfmt+0xdd>
  80049e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004a1:	85 c0                	test   %eax,%eax
  8004a3:	0f 48 c1             	cmovs  %ecx,%eax
  8004a6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  8004a9:	89 de                	mov    %ebx,%esi
  8004ab:	eb a5                	jmp    800452 <vprintfmt+0x74>
  8004ad:	89 de                	mov    %ebx,%esi
			if (width < 0)									//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;			
			goto reswitch;

		case '#':
			altflag = 1;
  8004af:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8004b6:	eb 9a                	jmp    800452 <vprintfmt+0x74>
  8004b8:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  8004bb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8004bf:	79 91                	jns    800452 <vprintfmt+0x74>
  8004c1:	eb 82                	jmp    800445 <vprintfmt+0x67>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
  8004c3:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  8004c7:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
			goto reswitch;
  8004c9:	eb 87                	jmp    800452 <vprintfmt+0x74>

		// character
		case 'c':											//如果是'c'代表显示一个字符
			putch(va_arg(ap, int), putdat);					//调用输出一个字符到内存的函数putch
  8004cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8004ce:	8d 50 04             	lea    0x4(%eax),%edx
  8004d1:	89 55 14             	mov    %edx,0x14(%ebp)
  8004d4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004d8:	8b 00                	mov    (%eax),%eax
  8004da:	89 04 24             	mov    %eax,(%esp)
  8004dd:	ff 55 08             	call   *0x8(%ebp)
			break;
  8004e0:	e9 1e ff ff ff       	jmp    800403 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8004e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8004e8:	8d 50 04             	lea    0x4(%eax),%edx
  8004eb:	89 55 14             	mov    %edx,0x14(%ebp)
  8004ee:	8b 00                	mov    (%eax),%eax
  8004f0:	99                   	cltd   
  8004f1:	31 d0                	xor    %edx,%eax
  8004f3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8004f5:	83 f8 07             	cmp    $0x7,%eax
  8004f8:	7f 0b                	jg     800505 <vprintfmt+0x127>
  8004fa:	8b 14 85 e0 10 80 00 	mov    0x8010e0(,%eax,4),%edx
  800501:	85 d2                	test   %edx,%edx
  800503:	75 20                	jne    800525 <vprintfmt+0x147>
				printfmt(putch, putdat, "error %d", err);
  800505:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800509:	c7 44 24 08 f6 0e 80 	movl   $0x800ef6,0x8(%esp)
  800510:	00 
  800511:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800515:	8b 45 08             	mov    0x8(%ebp),%eax
  800518:	89 04 24             	mov    %eax,(%esp)
  80051b:	e8 96 fe ff ff       	call   8003b6 <printfmt>
  800520:	e9 de fe ff ff       	jmp    800403 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800525:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800529:	c7 44 24 08 ff 0e 80 	movl   $0x800eff,0x8(%esp)
  800530:	00 
  800531:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800535:	8b 45 08             	mov    0x8(%ebp),%eax
  800538:	89 04 24             	mov    %eax,(%esp)
  80053b:	e8 76 fe ff ff       	call   8003b6 <printfmt>
  800540:	e9 be fe ff ff       	jmp    800403 <vprintfmt+0x25>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800545:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  800548:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80054b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80054e:	8b 45 14             	mov    0x14(%ebp),%eax
  800551:	8d 50 04             	lea    0x4(%eax),%edx
  800554:	89 55 14             	mov    %edx,0x14(%ebp)
  800557:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  800559:	85 f6                	test   %esi,%esi
  80055b:	b8 ef 0e 80 00       	mov    $0x800eef,%eax
  800560:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800563:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  800567:	0f 84 97 00 00 00    	je     800604 <vprintfmt+0x226>
  80056d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800571:	0f 8e 9b 00 00 00    	jle    800612 <vprintfmt+0x234>
				for (width -= strnlen(p, precision); width > 0; width--)
  800577:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80057b:	89 34 24             	mov    %esi,(%esp)
  80057e:	e8 e5 02 00 00       	call   800868 <strnlen>
  800583:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  800586:	29 c1                	sub    %eax,%ecx
  800588:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
					putch(padc, putdat);
  80058b:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  80058f:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800592:	89 75 d8             	mov    %esi,-0x28(%ebp)
  800595:	8b 75 08             	mov    0x8(%ebp),%esi
  800598:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80059b:	89 cb                	mov    %ecx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80059d:	eb 0f                	jmp    8005ae <vprintfmt+0x1d0>
					putch(padc, putdat);
  80059f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005a3:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8005a6:	89 04 24             	mov    %eax,(%esp)
  8005a9:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8005ab:	83 eb 01             	sub    $0x1,%ebx
  8005ae:	85 db                	test   %ebx,%ebx
  8005b0:	7f ed                	jg     80059f <vprintfmt+0x1c1>
  8005b2:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8005b5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8005b8:	85 c9                	test   %ecx,%ecx
  8005ba:	b8 00 00 00 00       	mov    $0x0,%eax
  8005bf:	0f 49 c1             	cmovns %ecx,%eax
  8005c2:	29 c1                	sub    %eax,%ecx
  8005c4:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8005c7:	89 cf                	mov    %ecx,%edi
  8005c9:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  8005cc:	eb 50                	jmp    80061e <vprintfmt+0x240>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8005ce:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8005d2:	74 1e                	je     8005f2 <vprintfmt+0x214>
  8005d4:	0f be d2             	movsbl %dl,%edx
  8005d7:	83 ea 20             	sub    $0x20,%edx
  8005da:	83 fa 5e             	cmp    $0x5e,%edx
  8005dd:	76 13                	jbe    8005f2 <vprintfmt+0x214>
					putch('?', putdat);
  8005df:	8b 45 0c             	mov    0xc(%ebp),%eax
  8005e2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8005e6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8005ed:	ff 55 08             	call   *0x8(%ebp)
  8005f0:	eb 0d                	jmp    8005ff <vprintfmt+0x221>
				else
					putch(ch, putdat);
  8005f2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8005f5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8005f9:	89 04 24             	mov    %eax,(%esp)
  8005fc:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8005ff:	83 ef 01             	sub    $0x1,%edi
  800602:	eb 1a                	jmp    80061e <vprintfmt+0x240>
  800604:	89 7d 0c             	mov    %edi,0xc(%ebp)
  800607:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80060a:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80060d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  800610:	eb 0c                	jmp    80061e <vprintfmt+0x240>
  800612:	89 7d 0c             	mov    %edi,0xc(%ebp)
  800615:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800618:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80061b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  80061e:	83 c6 01             	add    $0x1,%esi
  800621:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  800625:	0f be c2             	movsbl %dl,%eax
  800628:	85 c0                	test   %eax,%eax
  80062a:	74 27                	je     800653 <vprintfmt+0x275>
  80062c:	85 db                	test   %ebx,%ebx
  80062e:	78 9e                	js     8005ce <vprintfmt+0x1f0>
  800630:	83 eb 01             	sub    $0x1,%ebx
  800633:	79 99                	jns    8005ce <vprintfmt+0x1f0>
  800635:	89 f8                	mov    %edi,%eax
  800637:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80063a:	8b 75 08             	mov    0x8(%ebp),%esi
  80063d:	89 c3                	mov    %eax,%ebx
  80063f:	eb 1a                	jmp    80065b <vprintfmt+0x27d>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800641:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800645:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80064c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80064e:	83 eb 01             	sub    $0x1,%ebx
  800651:	eb 08                	jmp    80065b <vprintfmt+0x27d>
  800653:	89 fb                	mov    %edi,%ebx
  800655:	8b 75 08             	mov    0x8(%ebp),%esi
  800658:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80065b:	85 db                	test   %ebx,%ebx
  80065d:	7f e2                	jg     800641 <vprintfmt+0x263>
  80065f:	89 75 08             	mov    %esi,0x8(%ebp)
  800662:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800665:	e9 99 fd ff ff       	jmp    800403 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80066a:	83 7d d4 01          	cmpl   $0x1,-0x2c(%ebp)
  80066e:	7e 16                	jle    800686 <vprintfmt+0x2a8>
		return va_arg(*ap, long long);
  800670:	8b 45 14             	mov    0x14(%ebp),%eax
  800673:	8d 50 08             	lea    0x8(%eax),%edx
  800676:	89 55 14             	mov    %edx,0x14(%ebp)
  800679:	8b 50 04             	mov    0x4(%eax),%edx
  80067c:	8b 00                	mov    (%eax),%eax
  80067e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800681:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800684:	eb 34                	jmp    8006ba <vprintfmt+0x2dc>
	else if (lflag)
  800686:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  80068a:	74 18                	je     8006a4 <vprintfmt+0x2c6>
		return va_arg(*ap, long);
  80068c:	8b 45 14             	mov    0x14(%ebp),%eax
  80068f:	8d 50 04             	lea    0x4(%eax),%edx
  800692:	89 55 14             	mov    %edx,0x14(%ebp)
  800695:	8b 30                	mov    (%eax),%esi
  800697:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80069a:	89 f0                	mov    %esi,%eax
  80069c:	c1 f8 1f             	sar    $0x1f,%eax
  80069f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8006a2:	eb 16                	jmp    8006ba <vprintfmt+0x2dc>
	else
		return va_arg(*ap, int);
  8006a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8006a7:	8d 50 04             	lea    0x4(%eax),%edx
  8006aa:	89 55 14             	mov    %edx,0x14(%ebp)
  8006ad:	8b 30                	mov    (%eax),%esi
  8006af:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8006b2:	89 f0                	mov    %esi,%eax
  8006b4:	c1 f8 1f             	sar    $0x1f,%eax
  8006b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8006ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006bd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8006c0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8006c5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8006c9:	0f 89 97 00 00 00    	jns    800766 <vprintfmt+0x388>
				putch('-', putdat);
  8006cf:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006d3:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8006da:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8006dd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8006e0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8006e3:	f7 d8                	neg    %eax
  8006e5:	83 d2 00             	adc    $0x0,%edx
  8006e8:	f7 da                	neg    %edx
			}
			base = 10;
  8006ea:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8006ef:	eb 75                	jmp    800766 <vprintfmt+0x388>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8006f1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8006f4:	8d 45 14             	lea    0x14(%ebp),%eax
  8006f7:	e8 63 fc ff ff       	call   80035f <getuint>
			base = 10;
  8006fc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800701:	eb 63                	jmp    800766 <vprintfmt+0x388>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('0', putdat);
  800703:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800707:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80070e:	ff 55 08             	call   *0x8(%ebp)
			num = getuint(&ap, lflag);
  800711:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800714:	8d 45 14             	lea    0x14(%ebp),%eax
  800717:	e8 43 fc ff ff       	call   80035f <getuint>
			base = 8;
  80071c:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800721:	eb 43                	jmp    800766 <vprintfmt+0x388>
		// pointer
		case 'p':
			putch('0', putdat);
  800723:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800727:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80072e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800731:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800735:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80073c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80073f:	8b 45 14             	mov    0x14(%ebp),%eax
  800742:	8d 50 04             	lea    0x4(%eax),%edx
  800745:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800748:	8b 00                	mov    (%eax),%eax
  80074a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80074f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800754:	eb 10                	jmp    800766 <vprintfmt+0x388>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800756:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800759:	8d 45 14             	lea    0x14(%ebp),%eax
  80075c:	e8 fe fb ff ff       	call   80035f <getuint>
			base = 16;
  800761:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800766:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  80076a:	89 74 24 10          	mov    %esi,0x10(%esp)
  80076e:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800771:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800775:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800779:	89 04 24             	mov    %eax,(%esp)
  80077c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800780:	89 fa                	mov    %edi,%edx
  800782:	8b 45 08             	mov    0x8(%ebp),%eax
  800785:	e8 e6 fa ff ff       	call   800270 <printnum>
			break;
  80078a:	e9 74 fc ff ff       	jmp    800403 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80078f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800793:	89 04 24             	mov    %eax,(%esp)
  800796:	ff 55 08             	call   *0x8(%ebp)
			break;
  800799:	e9 65 fc ff ff       	jmp    800403 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80079e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8007a2:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8007a9:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8007ac:	89 f3                	mov    %esi,%ebx
  8007ae:	eb 03                	jmp    8007b3 <vprintfmt+0x3d5>
  8007b0:	83 eb 01             	sub    $0x1,%ebx
  8007b3:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8007b7:	75 f7                	jne    8007b0 <vprintfmt+0x3d2>
  8007b9:	e9 45 fc ff ff       	jmp    800403 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8007be:	83 c4 3c             	add    $0x3c,%esp
  8007c1:	5b                   	pop    %ebx
  8007c2:	5e                   	pop    %esi
  8007c3:	5f                   	pop    %edi
  8007c4:	5d                   	pop    %ebp
  8007c5:	c3                   	ret    

008007c6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8007c6:	55                   	push   %ebp
  8007c7:	89 e5                	mov    %esp,%ebp
  8007c9:	83 ec 28             	sub    $0x28,%esp
  8007cc:	8b 45 08             	mov    0x8(%ebp),%eax
  8007cf:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8007d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8007d5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8007d9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8007dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8007e3:	85 c0                	test   %eax,%eax
  8007e5:	74 30                	je     800817 <vsnprintf+0x51>
  8007e7:	85 d2                	test   %edx,%edx
  8007e9:	7e 2c                	jle    800817 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8007eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8007ee:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8007f2:	8b 45 10             	mov    0x10(%ebp),%eax
  8007f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8007f9:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8007fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800800:	c7 04 24 99 03 80 00 	movl   $0x800399,(%esp)
  800807:	e8 d2 fb ff ff       	call   8003de <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80080c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80080f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800812:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800815:	eb 05                	jmp    80081c <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800817:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80081c:	c9                   	leave  
  80081d:	c3                   	ret    

0080081e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80081e:	55                   	push   %ebp
  80081f:	89 e5                	mov    %esp,%ebp
  800821:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800824:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800827:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80082b:	8b 45 10             	mov    0x10(%ebp),%eax
  80082e:	89 44 24 08          	mov    %eax,0x8(%esp)
  800832:	8b 45 0c             	mov    0xc(%ebp),%eax
  800835:	89 44 24 04          	mov    %eax,0x4(%esp)
  800839:	8b 45 08             	mov    0x8(%ebp),%eax
  80083c:	89 04 24             	mov    %eax,(%esp)
  80083f:	e8 82 ff ff ff       	call   8007c6 <vsnprintf>
	va_end(ap);

	return rc;
}
  800844:	c9                   	leave  
  800845:	c3                   	ret    
  800846:	66 90                	xchg   %ax,%ax
  800848:	66 90                	xchg   %ax,%ax
  80084a:	66 90                	xchg   %ax,%ax
  80084c:	66 90                	xchg   %ax,%ax
  80084e:	66 90                	xchg   %ax,%ax

00800850 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800850:	55                   	push   %ebp
  800851:	89 e5                	mov    %esp,%ebp
  800853:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800856:	b8 00 00 00 00       	mov    $0x0,%eax
  80085b:	eb 03                	jmp    800860 <strlen+0x10>
		n++;
  80085d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800860:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800864:	75 f7                	jne    80085d <strlen+0xd>
		n++;
	return n;
}
  800866:	5d                   	pop    %ebp
  800867:	c3                   	ret    

00800868 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800868:	55                   	push   %ebp
  800869:	89 e5                	mov    %esp,%ebp
  80086b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80086e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800871:	b8 00 00 00 00       	mov    $0x0,%eax
  800876:	eb 03                	jmp    80087b <strnlen+0x13>
		n++;
  800878:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80087b:	39 d0                	cmp    %edx,%eax
  80087d:	74 06                	je     800885 <strnlen+0x1d>
  80087f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800883:	75 f3                	jne    800878 <strnlen+0x10>
		n++;
	return n;
}
  800885:	5d                   	pop    %ebp
  800886:	c3                   	ret    

00800887 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800887:	55                   	push   %ebp
  800888:	89 e5                	mov    %esp,%ebp
  80088a:	53                   	push   %ebx
  80088b:	8b 45 08             	mov    0x8(%ebp),%eax
  80088e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800891:	89 c2                	mov    %eax,%edx
  800893:	83 c2 01             	add    $0x1,%edx
  800896:	83 c1 01             	add    $0x1,%ecx
  800899:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80089d:	88 5a ff             	mov    %bl,-0x1(%edx)
  8008a0:	84 db                	test   %bl,%bl
  8008a2:	75 ef                	jne    800893 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8008a4:	5b                   	pop    %ebx
  8008a5:	5d                   	pop    %ebp
  8008a6:	c3                   	ret    

008008a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8008a7:	55                   	push   %ebp
  8008a8:	89 e5                	mov    %esp,%ebp
  8008aa:	53                   	push   %ebx
  8008ab:	83 ec 08             	sub    $0x8,%esp
  8008ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8008b1:	89 1c 24             	mov    %ebx,(%esp)
  8008b4:	e8 97 ff ff ff       	call   800850 <strlen>
	strcpy(dst + len, src);
  8008b9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8008bc:	89 54 24 04          	mov    %edx,0x4(%esp)
  8008c0:	01 d8                	add    %ebx,%eax
  8008c2:	89 04 24             	mov    %eax,(%esp)
  8008c5:	e8 bd ff ff ff       	call   800887 <strcpy>
	return dst;
}
  8008ca:	89 d8                	mov    %ebx,%eax
  8008cc:	83 c4 08             	add    $0x8,%esp
  8008cf:	5b                   	pop    %ebx
  8008d0:	5d                   	pop    %ebp
  8008d1:	c3                   	ret    

008008d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8008d2:	55                   	push   %ebp
  8008d3:	89 e5                	mov    %esp,%ebp
  8008d5:	56                   	push   %esi
  8008d6:	53                   	push   %ebx
  8008d7:	8b 75 08             	mov    0x8(%ebp),%esi
  8008da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8008dd:	89 f3                	mov    %esi,%ebx
  8008df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008e2:	89 f2                	mov    %esi,%edx
  8008e4:	eb 0f                	jmp    8008f5 <strncpy+0x23>
		*dst++ = *src;
  8008e6:	83 c2 01             	add    $0x1,%edx
  8008e9:	0f b6 01             	movzbl (%ecx),%eax
  8008ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8008ef:	80 39 01             	cmpb   $0x1,(%ecx)
  8008f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8008f5:	39 da                	cmp    %ebx,%edx
  8008f7:	75 ed                	jne    8008e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8008f9:	89 f0                	mov    %esi,%eax
  8008fb:	5b                   	pop    %ebx
  8008fc:	5e                   	pop    %esi
  8008fd:	5d                   	pop    %ebp
  8008fe:	c3                   	ret    

008008ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8008ff:	55                   	push   %ebp
  800900:	89 e5                	mov    %esp,%ebp
  800902:	56                   	push   %esi
  800903:	53                   	push   %ebx
  800904:	8b 75 08             	mov    0x8(%ebp),%esi
  800907:	8b 55 0c             	mov    0xc(%ebp),%edx
  80090a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80090d:	89 f0                	mov    %esi,%eax
  80090f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800913:	85 c9                	test   %ecx,%ecx
  800915:	75 0b                	jne    800922 <strlcpy+0x23>
  800917:	eb 1d                	jmp    800936 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800919:	83 c0 01             	add    $0x1,%eax
  80091c:	83 c2 01             	add    $0x1,%edx
  80091f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800922:	39 d8                	cmp    %ebx,%eax
  800924:	74 0b                	je     800931 <strlcpy+0x32>
  800926:	0f b6 0a             	movzbl (%edx),%ecx
  800929:	84 c9                	test   %cl,%cl
  80092b:	75 ec                	jne    800919 <strlcpy+0x1a>
  80092d:	89 c2                	mov    %eax,%edx
  80092f:	eb 02                	jmp    800933 <strlcpy+0x34>
  800931:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800933:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800936:	29 f0                	sub    %esi,%eax
}
  800938:	5b                   	pop    %ebx
  800939:	5e                   	pop    %esi
  80093a:	5d                   	pop    %ebp
  80093b:	c3                   	ret    

0080093c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80093c:	55                   	push   %ebp
  80093d:	89 e5                	mov    %esp,%ebp
  80093f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800942:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800945:	eb 06                	jmp    80094d <strcmp+0x11>
		p++, q++;
  800947:	83 c1 01             	add    $0x1,%ecx
  80094a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80094d:	0f b6 01             	movzbl (%ecx),%eax
  800950:	84 c0                	test   %al,%al
  800952:	74 04                	je     800958 <strcmp+0x1c>
  800954:	3a 02                	cmp    (%edx),%al
  800956:	74 ef                	je     800947 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800958:	0f b6 c0             	movzbl %al,%eax
  80095b:	0f b6 12             	movzbl (%edx),%edx
  80095e:	29 d0                	sub    %edx,%eax
}
  800960:	5d                   	pop    %ebp
  800961:	c3                   	ret    

00800962 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800962:	55                   	push   %ebp
  800963:	89 e5                	mov    %esp,%ebp
  800965:	53                   	push   %ebx
  800966:	8b 45 08             	mov    0x8(%ebp),%eax
  800969:	8b 55 0c             	mov    0xc(%ebp),%edx
  80096c:	89 c3                	mov    %eax,%ebx
  80096e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800971:	eb 06                	jmp    800979 <strncmp+0x17>
		n--, p++, q++;
  800973:	83 c0 01             	add    $0x1,%eax
  800976:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800979:	39 d8                	cmp    %ebx,%eax
  80097b:	74 15                	je     800992 <strncmp+0x30>
  80097d:	0f b6 08             	movzbl (%eax),%ecx
  800980:	84 c9                	test   %cl,%cl
  800982:	74 04                	je     800988 <strncmp+0x26>
  800984:	3a 0a                	cmp    (%edx),%cl
  800986:	74 eb                	je     800973 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800988:	0f b6 00             	movzbl (%eax),%eax
  80098b:	0f b6 12             	movzbl (%edx),%edx
  80098e:	29 d0                	sub    %edx,%eax
  800990:	eb 05                	jmp    800997 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800992:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800997:	5b                   	pop    %ebx
  800998:	5d                   	pop    %ebp
  800999:	c3                   	ret    

0080099a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80099a:	55                   	push   %ebp
  80099b:	89 e5                	mov    %esp,%ebp
  80099d:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009a4:	eb 07                	jmp    8009ad <strchr+0x13>
		if (*s == c)
  8009a6:	38 ca                	cmp    %cl,%dl
  8009a8:	74 0f                	je     8009b9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8009aa:	83 c0 01             	add    $0x1,%eax
  8009ad:	0f b6 10             	movzbl (%eax),%edx
  8009b0:	84 d2                	test   %dl,%dl
  8009b2:	75 f2                	jne    8009a6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8009b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009b9:	5d                   	pop    %ebp
  8009ba:	c3                   	ret    

008009bb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8009bb:	55                   	push   %ebp
  8009bc:	89 e5                	mov    %esp,%ebp
  8009be:	8b 45 08             	mov    0x8(%ebp),%eax
  8009c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8009c5:	eb 07                	jmp    8009ce <strfind+0x13>
		if (*s == c)
  8009c7:	38 ca                	cmp    %cl,%dl
  8009c9:	74 0a                	je     8009d5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8009cb:	83 c0 01             	add    $0x1,%eax
  8009ce:	0f b6 10             	movzbl (%eax),%edx
  8009d1:	84 d2                	test   %dl,%dl
  8009d3:	75 f2                	jne    8009c7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8009d5:	5d                   	pop    %ebp
  8009d6:	c3                   	ret    

008009d7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8009d7:	55                   	push   %ebp
  8009d8:	89 e5                	mov    %esp,%ebp
  8009da:	57                   	push   %edi
  8009db:	56                   	push   %esi
  8009dc:	53                   	push   %ebx
  8009dd:	8b 7d 08             	mov    0x8(%ebp),%edi
  8009e0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8009e3:	85 c9                	test   %ecx,%ecx
  8009e5:	74 36                	je     800a1d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8009e7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8009ed:	75 28                	jne    800a17 <memset+0x40>
  8009ef:	f6 c1 03             	test   $0x3,%cl
  8009f2:	75 23                	jne    800a17 <memset+0x40>
		c &= 0xFF;
  8009f4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8009f8:	89 d3                	mov    %edx,%ebx
  8009fa:	c1 e3 08             	shl    $0x8,%ebx
  8009fd:	89 d6                	mov    %edx,%esi
  8009ff:	c1 e6 18             	shl    $0x18,%esi
  800a02:	89 d0                	mov    %edx,%eax
  800a04:	c1 e0 10             	shl    $0x10,%eax
  800a07:	09 f0                	or     %esi,%eax
  800a09:	09 c2                	or     %eax,%edx
  800a0b:	89 d0                	mov    %edx,%eax
  800a0d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  800a0f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800a12:	fc                   	cld    
  800a13:	f3 ab                	rep stos %eax,%es:(%edi)
  800a15:	eb 06                	jmp    800a1d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800a17:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a1a:	fc                   	cld    
  800a1b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  800a1d:	89 f8                	mov    %edi,%eax
  800a1f:	5b                   	pop    %ebx
  800a20:	5e                   	pop    %esi
  800a21:	5f                   	pop    %edi
  800a22:	5d                   	pop    %ebp
  800a23:	c3                   	ret    

00800a24 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800a24:	55                   	push   %ebp
  800a25:	89 e5                	mov    %esp,%ebp
  800a27:	57                   	push   %edi
  800a28:	56                   	push   %esi
  800a29:	8b 45 08             	mov    0x8(%ebp),%eax
  800a2c:	8b 75 0c             	mov    0xc(%ebp),%esi
  800a2f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800a32:	39 c6                	cmp    %eax,%esi
  800a34:	73 35                	jae    800a6b <memmove+0x47>
  800a36:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800a39:	39 d0                	cmp    %edx,%eax
  800a3b:	73 2e                	jae    800a6b <memmove+0x47>
		s += n;
		d += n;
  800a3d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800a40:	89 d6                	mov    %edx,%esi
  800a42:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a44:	f7 c6 03 00 00 00    	test   $0x3,%esi
  800a4a:	75 13                	jne    800a5f <memmove+0x3b>
  800a4c:	f6 c1 03             	test   $0x3,%cl
  800a4f:	75 0e                	jne    800a5f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800a51:	83 ef 04             	sub    $0x4,%edi
  800a54:	8d 72 fc             	lea    -0x4(%edx),%esi
  800a57:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  800a5a:	fd                   	std    
  800a5b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a5d:	eb 09                	jmp    800a68 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  800a5f:	83 ef 01             	sub    $0x1,%edi
  800a62:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800a65:	fd                   	std    
  800a66:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800a68:	fc                   	cld    
  800a69:	eb 1d                	jmp    800a88 <memmove+0x64>
  800a6b:	89 f2                	mov    %esi,%edx
  800a6d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800a6f:	f6 c2 03             	test   $0x3,%dl
  800a72:	75 0f                	jne    800a83 <memmove+0x5f>
  800a74:	f6 c1 03             	test   $0x3,%cl
  800a77:	75 0a                	jne    800a83 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800a79:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  800a7c:	89 c7                	mov    %eax,%edi
  800a7e:	fc                   	cld    
  800a7f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800a81:	eb 05                	jmp    800a88 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800a83:	89 c7                	mov    %eax,%edi
  800a85:	fc                   	cld    
  800a86:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800a88:	5e                   	pop    %esi
  800a89:	5f                   	pop    %edi
  800a8a:	5d                   	pop    %ebp
  800a8b:	c3                   	ret    

00800a8c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  800a8c:	55                   	push   %ebp
  800a8d:	89 e5                	mov    %esp,%ebp
  800a8f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800a92:	8b 45 10             	mov    0x10(%ebp),%eax
  800a95:	89 44 24 08          	mov    %eax,0x8(%esp)
  800a99:	8b 45 0c             	mov    0xc(%ebp),%eax
  800a9c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800aa0:	8b 45 08             	mov    0x8(%ebp),%eax
  800aa3:	89 04 24             	mov    %eax,(%esp)
  800aa6:	e8 79 ff ff ff       	call   800a24 <memmove>
}
  800aab:	c9                   	leave  
  800aac:	c3                   	ret    

00800aad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  800aad:	55                   	push   %ebp
  800aae:	89 e5                	mov    %esp,%ebp
  800ab0:	56                   	push   %esi
  800ab1:	53                   	push   %ebx
  800ab2:	8b 55 08             	mov    0x8(%ebp),%edx
  800ab5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ab8:	89 d6                	mov    %edx,%esi
  800aba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800abd:	eb 1a                	jmp    800ad9 <memcmp+0x2c>
		if (*s1 != *s2)
  800abf:	0f b6 02             	movzbl (%edx),%eax
  800ac2:	0f b6 19             	movzbl (%ecx),%ebx
  800ac5:	38 d8                	cmp    %bl,%al
  800ac7:	74 0a                	je     800ad3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  800ac9:	0f b6 c0             	movzbl %al,%eax
  800acc:	0f b6 db             	movzbl %bl,%ebx
  800acf:	29 d8                	sub    %ebx,%eax
  800ad1:	eb 0f                	jmp    800ae2 <memcmp+0x35>
		s1++, s2++;
  800ad3:	83 c2 01             	add    $0x1,%edx
  800ad6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  800ad9:	39 f2                	cmp    %esi,%edx
  800adb:	75 e2                	jne    800abf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  800add:	b8 00 00 00 00       	mov    $0x0,%eax
}
  800ae2:	5b                   	pop    %ebx
  800ae3:	5e                   	pop    %esi
  800ae4:	5d                   	pop    %ebp
  800ae5:	c3                   	ret    

00800ae6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  800ae6:	55                   	push   %ebp
  800ae7:	89 e5                	mov    %esp,%ebp
  800ae9:	8b 45 08             	mov    0x8(%ebp),%eax
  800aec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  800aef:	89 c2                	mov    %eax,%edx
  800af1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800af4:	eb 07                	jmp    800afd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800af6:	38 08                	cmp    %cl,(%eax)
  800af8:	74 07                	je     800b01 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800afa:	83 c0 01             	add    $0x1,%eax
  800afd:	39 d0                	cmp    %edx,%eax
  800aff:	72 f5                	jb     800af6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800b01:	5d                   	pop    %ebp
  800b02:	c3                   	ret    

00800b03 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800b03:	55                   	push   %ebp
  800b04:	89 e5                	mov    %esp,%ebp
  800b06:	57                   	push   %edi
  800b07:	56                   	push   %esi
  800b08:	53                   	push   %ebx
  800b09:	8b 55 08             	mov    0x8(%ebp),%edx
  800b0c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b0f:	eb 03                	jmp    800b14 <strtol+0x11>
		s++;
  800b11:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800b14:	0f b6 0a             	movzbl (%edx),%ecx
  800b17:	80 f9 09             	cmp    $0x9,%cl
  800b1a:	74 f5                	je     800b11 <strtol+0xe>
  800b1c:	80 f9 20             	cmp    $0x20,%cl
  800b1f:	74 f0                	je     800b11 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800b21:	80 f9 2b             	cmp    $0x2b,%cl
  800b24:	75 0a                	jne    800b30 <strtol+0x2d>
		s++;
  800b26:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800b29:	bf 00 00 00 00       	mov    $0x0,%edi
  800b2e:	eb 11                	jmp    800b41 <strtol+0x3e>
  800b30:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800b35:	80 f9 2d             	cmp    $0x2d,%cl
  800b38:	75 07                	jne    800b41 <strtol+0x3e>
		s++, neg = 1;
  800b3a:	8d 52 01             	lea    0x1(%edx),%edx
  800b3d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800b41:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800b46:	75 15                	jne    800b5d <strtol+0x5a>
  800b48:	80 3a 30             	cmpb   $0x30,(%edx)
  800b4b:	75 10                	jne    800b5d <strtol+0x5a>
  800b4d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800b51:	75 0a                	jne    800b5d <strtol+0x5a>
		s += 2, base = 16;
  800b53:	83 c2 02             	add    $0x2,%edx
  800b56:	b8 10 00 00 00       	mov    $0x10,%eax
  800b5b:	eb 10                	jmp    800b6d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800b5d:	85 c0                	test   %eax,%eax
  800b5f:	75 0c                	jne    800b6d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800b61:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800b63:	80 3a 30             	cmpb   $0x30,(%edx)
  800b66:	75 05                	jne    800b6d <strtol+0x6a>
		s++, base = 8;
  800b68:	83 c2 01             	add    $0x1,%edx
  800b6b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800b6d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800b72:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800b75:	0f b6 0a             	movzbl (%edx),%ecx
  800b78:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800b7b:	89 f0                	mov    %esi,%eax
  800b7d:	3c 09                	cmp    $0x9,%al
  800b7f:	77 08                	ja     800b89 <strtol+0x86>
			dig = *s - '0';
  800b81:	0f be c9             	movsbl %cl,%ecx
  800b84:	83 e9 30             	sub    $0x30,%ecx
  800b87:	eb 20                	jmp    800ba9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800b89:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800b8c:	89 f0                	mov    %esi,%eax
  800b8e:	3c 19                	cmp    $0x19,%al
  800b90:	77 08                	ja     800b9a <strtol+0x97>
			dig = *s - 'a' + 10;
  800b92:	0f be c9             	movsbl %cl,%ecx
  800b95:	83 e9 57             	sub    $0x57,%ecx
  800b98:	eb 0f                	jmp    800ba9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800b9a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800b9d:	89 f0                	mov    %esi,%eax
  800b9f:	3c 19                	cmp    $0x19,%al
  800ba1:	77 16                	ja     800bb9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800ba3:	0f be c9             	movsbl %cl,%ecx
  800ba6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800ba9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800bac:	7d 0f                	jge    800bbd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800bae:	83 c2 01             	add    $0x1,%edx
  800bb1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800bb5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800bb7:	eb bc                	jmp    800b75 <strtol+0x72>
  800bb9:	89 d8                	mov    %ebx,%eax
  800bbb:	eb 02                	jmp    800bbf <strtol+0xbc>
  800bbd:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800bbf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800bc3:	74 05                	je     800bca <strtol+0xc7>
		*endptr = (char *) s;
  800bc5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800bc8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800bca:	f7 d8                	neg    %eax
  800bcc:	85 ff                	test   %edi,%edi
  800bce:	0f 44 c3             	cmove  %ebx,%eax
}
  800bd1:	5b                   	pop    %ebx
  800bd2:	5e                   	pop    %esi
  800bd3:	5f                   	pop    %edi
  800bd4:	5d                   	pop    %ebp
  800bd5:	c3                   	ret    
  800bd6:	66 90                	xchg   %ax,%ax
  800bd8:	66 90                	xchg   %ax,%ax
  800bda:	66 90                	xchg   %ax,%ax
  800bdc:	66 90                	xchg   %ax,%ax
  800bde:	66 90                	xchg   %ax,%ax

00800be0 <__udivdi3>:
  800be0:	55                   	push   %ebp
  800be1:	57                   	push   %edi
  800be2:	56                   	push   %esi
  800be3:	83 ec 0c             	sub    $0xc,%esp
  800be6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800bea:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800bee:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800bf2:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800bf6:	85 c0                	test   %eax,%eax
  800bf8:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800bfc:	89 ea                	mov    %ebp,%edx
  800bfe:	89 0c 24             	mov    %ecx,(%esp)
  800c01:	75 2d                	jne    800c30 <__udivdi3+0x50>
  800c03:	39 e9                	cmp    %ebp,%ecx
  800c05:	77 61                	ja     800c68 <__udivdi3+0x88>
  800c07:	85 c9                	test   %ecx,%ecx
  800c09:	89 ce                	mov    %ecx,%esi
  800c0b:	75 0b                	jne    800c18 <__udivdi3+0x38>
  800c0d:	b8 01 00 00 00       	mov    $0x1,%eax
  800c12:	31 d2                	xor    %edx,%edx
  800c14:	f7 f1                	div    %ecx
  800c16:	89 c6                	mov    %eax,%esi
  800c18:	31 d2                	xor    %edx,%edx
  800c1a:	89 e8                	mov    %ebp,%eax
  800c1c:	f7 f6                	div    %esi
  800c1e:	89 c5                	mov    %eax,%ebp
  800c20:	89 f8                	mov    %edi,%eax
  800c22:	f7 f6                	div    %esi
  800c24:	89 ea                	mov    %ebp,%edx
  800c26:	83 c4 0c             	add    $0xc,%esp
  800c29:	5e                   	pop    %esi
  800c2a:	5f                   	pop    %edi
  800c2b:	5d                   	pop    %ebp
  800c2c:	c3                   	ret    
  800c2d:	8d 76 00             	lea    0x0(%esi),%esi
  800c30:	39 e8                	cmp    %ebp,%eax
  800c32:	77 24                	ja     800c58 <__udivdi3+0x78>
  800c34:	0f bd e8             	bsr    %eax,%ebp
  800c37:	83 f5 1f             	xor    $0x1f,%ebp
  800c3a:	75 3c                	jne    800c78 <__udivdi3+0x98>
  800c3c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800c40:	39 34 24             	cmp    %esi,(%esp)
  800c43:	0f 86 9f 00 00 00    	jbe    800ce8 <__udivdi3+0x108>
  800c49:	39 d0                	cmp    %edx,%eax
  800c4b:	0f 82 97 00 00 00    	jb     800ce8 <__udivdi3+0x108>
  800c51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c58:	31 d2                	xor    %edx,%edx
  800c5a:	31 c0                	xor    %eax,%eax
  800c5c:	83 c4 0c             	add    $0xc,%esp
  800c5f:	5e                   	pop    %esi
  800c60:	5f                   	pop    %edi
  800c61:	5d                   	pop    %ebp
  800c62:	c3                   	ret    
  800c63:	90                   	nop
  800c64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c68:	89 f8                	mov    %edi,%eax
  800c6a:	f7 f1                	div    %ecx
  800c6c:	31 d2                	xor    %edx,%edx
  800c6e:	83 c4 0c             	add    $0xc,%esp
  800c71:	5e                   	pop    %esi
  800c72:	5f                   	pop    %edi
  800c73:	5d                   	pop    %ebp
  800c74:	c3                   	ret    
  800c75:	8d 76 00             	lea    0x0(%esi),%esi
  800c78:	89 e9                	mov    %ebp,%ecx
  800c7a:	8b 3c 24             	mov    (%esp),%edi
  800c7d:	d3 e0                	shl    %cl,%eax
  800c7f:	89 c6                	mov    %eax,%esi
  800c81:	b8 20 00 00 00       	mov    $0x20,%eax
  800c86:	29 e8                	sub    %ebp,%eax
  800c88:	89 c1                	mov    %eax,%ecx
  800c8a:	d3 ef                	shr    %cl,%edi
  800c8c:	89 e9                	mov    %ebp,%ecx
  800c8e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800c92:	8b 3c 24             	mov    (%esp),%edi
  800c95:	09 74 24 08          	or     %esi,0x8(%esp)
  800c99:	89 d6                	mov    %edx,%esi
  800c9b:	d3 e7                	shl    %cl,%edi
  800c9d:	89 c1                	mov    %eax,%ecx
  800c9f:	89 3c 24             	mov    %edi,(%esp)
  800ca2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800ca6:	d3 ee                	shr    %cl,%esi
  800ca8:	89 e9                	mov    %ebp,%ecx
  800caa:	d3 e2                	shl    %cl,%edx
  800cac:	89 c1                	mov    %eax,%ecx
  800cae:	d3 ef                	shr    %cl,%edi
  800cb0:	09 d7                	or     %edx,%edi
  800cb2:	89 f2                	mov    %esi,%edx
  800cb4:	89 f8                	mov    %edi,%eax
  800cb6:	f7 74 24 08          	divl   0x8(%esp)
  800cba:	89 d6                	mov    %edx,%esi
  800cbc:	89 c7                	mov    %eax,%edi
  800cbe:	f7 24 24             	mull   (%esp)
  800cc1:	39 d6                	cmp    %edx,%esi
  800cc3:	89 14 24             	mov    %edx,(%esp)
  800cc6:	72 30                	jb     800cf8 <__udivdi3+0x118>
  800cc8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800ccc:	89 e9                	mov    %ebp,%ecx
  800cce:	d3 e2                	shl    %cl,%edx
  800cd0:	39 c2                	cmp    %eax,%edx
  800cd2:	73 05                	jae    800cd9 <__udivdi3+0xf9>
  800cd4:	3b 34 24             	cmp    (%esp),%esi
  800cd7:	74 1f                	je     800cf8 <__udivdi3+0x118>
  800cd9:	89 f8                	mov    %edi,%eax
  800cdb:	31 d2                	xor    %edx,%edx
  800cdd:	e9 7a ff ff ff       	jmp    800c5c <__udivdi3+0x7c>
  800ce2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800ce8:	31 d2                	xor    %edx,%edx
  800cea:	b8 01 00 00 00       	mov    $0x1,%eax
  800cef:	e9 68 ff ff ff       	jmp    800c5c <__udivdi3+0x7c>
  800cf4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800cf8:	8d 47 ff             	lea    -0x1(%edi),%eax
  800cfb:	31 d2                	xor    %edx,%edx
  800cfd:	83 c4 0c             	add    $0xc,%esp
  800d00:	5e                   	pop    %esi
  800d01:	5f                   	pop    %edi
  800d02:	5d                   	pop    %ebp
  800d03:	c3                   	ret    
  800d04:	66 90                	xchg   %ax,%ax
  800d06:	66 90                	xchg   %ax,%ax
  800d08:	66 90                	xchg   %ax,%ax
  800d0a:	66 90                	xchg   %ax,%ax
  800d0c:	66 90                	xchg   %ax,%ax
  800d0e:	66 90                	xchg   %ax,%ax

00800d10 <__umoddi3>:
  800d10:	55                   	push   %ebp
  800d11:	57                   	push   %edi
  800d12:	56                   	push   %esi
  800d13:	83 ec 14             	sub    $0x14,%esp
  800d16:	8b 44 24 28          	mov    0x28(%esp),%eax
  800d1a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800d1e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800d22:	89 c7                	mov    %eax,%edi
  800d24:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d28:	8b 44 24 30          	mov    0x30(%esp),%eax
  800d2c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800d30:	89 34 24             	mov    %esi,(%esp)
  800d33:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d37:	85 c0                	test   %eax,%eax
  800d39:	89 c2                	mov    %eax,%edx
  800d3b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d3f:	75 17                	jne    800d58 <__umoddi3+0x48>
  800d41:	39 fe                	cmp    %edi,%esi
  800d43:	76 4b                	jbe    800d90 <__umoddi3+0x80>
  800d45:	89 c8                	mov    %ecx,%eax
  800d47:	89 fa                	mov    %edi,%edx
  800d49:	f7 f6                	div    %esi
  800d4b:	89 d0                	mov    %edx,%eax
  800d4d:	31 d2                	xor    %edx,%edx
  800d4f:	83 c4 14             	add    $0x14,%esp
  800d52:	5e                   	pop    %esi
  800d53:	5f                   	pop    %edi
  800d54:	5d                   	pop    %ebp
  800d55:	c3                   	ret    
  800d56:	66 90                	xchg   %ax,%ax
  800d58:	39 f8                	cmp    %edi,%eax
  800d5a:	77 54                	ja     800db0 <__umoddi3+0xa0>
  800d5c:	0f bd e8             	bsr    %eax,%ebp
  800d5f:	83 f5 1f             	xor    $0x1f,%ebp
  800d62:	75 5c                	jne    800dc0 <__umoddi3+0xb0>
  800d64:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800d68:	39 3c 24             	cmp    %edi,(%esp)
  800d6b:	0f 87 e7 00 00 00    	ja     800e58 <__umoddi3+0x148>
  800d71:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d75:	29 f1                	sub    %esi,%ecx
  800d77:	19 c7                	sbb    %eax,%edi
  800d79:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d7d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d81:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d85:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d89:	83 c4 14             	add    $0x14,%esp
  800d8c:	5e                   	pop    %esi
  800d8d:	5f                   	pop    %edi
  800d8e:	5d                   	pop    %ebp
  800d8f:	c3                   	ret    
  800d90:	85 f6                	test   %esi,%esi
  800d92:	89 f5                	mov    %esi,%ebp
  800d94:	75 0b                	jne    800da1 <__umoddi3+0x91>
  800d96:	b8 01 00 00 00       	mov    $0x1,%eax
  800d9b:	31 d2                	xor    %edx,%edx
  800d9d:	f7 f6                	div    %esi
  800d9f:	89 c5                	mov    %eax,%ebp
  800da1:	8b 44 24 04          	mov    0x4(%esp),%eax
  800da5:	31 d2                	xor    %edx,%edx
  800da7:	f7 f5                	div    %ebp
  800da9:	89 c8                	mov    %ecx,%eax
  800dab:	f7 f5                	div    %ebp
  800dad:	eb 9c                	jmp    800d4b <__umoddi3+0x3b>
  800daf:	90                   	nop
  800db0:	89 c8                	mov    %ecx,%eax
  800db2:	89 fa                	mov    %edi,%edx
  800db4:	83 c4 14             	add    $0x14,%esp
  800db7:	5e                   	pop    %esi
  800db8:	5f                   	pop    %edi
  800db9:	5d                   	pop    %ebp
  800dba:	c3                   	ret    
  800dbb:	90                   	nop
  800dbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dc0:	8b 04 24             	mov    (%esp),%eax
  800dc3:	be 20 00 00 00       	mov    $0x20,%esi
  800dc8:	89 e9                	mov    %ebp,%ecx
  800dca:	29 ee                	sub    %ebp,%esi
  800dcc:	d3 e2                	shl    %cl,%edx
  800dce:	89 f1                	mov    %esi,%ecx
  800dd0:	d3 e8                	shr    %cl,%eax
  800dd2:	89 e9                	mov    %ebp,%ecx
  800dd4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800dd8:	8b 04 24             	mov    (%esp),%eax
  800ddb:	09 54 24 04          	or     %edx,0x4(%esp)
  800ddf:	89 fa                	mov    %edi,%edx
  800de1:	d3 e0                	shl    %cl,%eax
  800de3:	89 f1                	mov    %esi,%ecx
  800de5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800de9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800ded:	d3 ea                	shr    %cl,%edx
  800def:	89 e9                	mov    %ebp,%ecx
  800df1:	d3 e7                	shl    %cl,%edi
  800df3:	89 f1                	mov    %esi,%ecx
  800df5:	d3 e8                	shr    %cl,%eax
  800df7:	89 e9                	mov    %ebp,%ecx
  800df9:	09 f8                	or     %edi,%eax
  800dfb:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800dff:	f7 74 24 04          	divl   0x4(%esp)
  800e03:	d3 e7                	shl    %cl,%edi
  800e05:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e09:	89 d7                	mov    %edx,%edi
  800e0b:	f7 64 24 08          	mull   0x8(%esp)
  800e0f:	39 d7                	cmp    %edx,%edi
  800e11:	89 c1                	mov    %eax,%ecx
  800e13:	89 14 24             	mov    %edx,(%esp)
  800e16:	72 2c                	jb     800e44 <__umoddi3+0x134>
  800e18:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800e1c:	72 22                	jb     800e40 <__umoddi3+0x130>
  800e1e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e22:	29 c8                	sub    %ecx,%eax
  800e24:	19 d7                	sbb    %edx,%edi
  800e26:	89 e9                	mov    %ebp,%ecx
  800e28:	89 fa                	mov    %edi,%edx
  800e2a:	d3 e8                	shr    %cl,%eax
  800e2c:	89 f1                	mov    %esi,%ecx
  800e2e:	d3 e2                	shl    %cl,%edx
  800e30:	89 e9                	mov    %ebp,%ecx
  800e32:	d3 ef                	shr    %cl,%edi
  800e34:	09 d0                	or     %edx,%eax
  800e36:	89 fa                	mov    %edi,%edx
  800e38:	83 c4 14             	add    $0x14,%esp
  800e3b:	5e                   	pop    %esi
  800e3c:	5f                   	pop    %edi
  800e3d:	5d                   	pop    %ebp
  800e3e:	c3                   	ret    
  800e3f:	90                   	nop
  800e40:	39 d7                	cmp    %edx,%edi
  800e42:	75 da                	jne    800e1e <__umoddi3+0x10e>
  800e44:	8b 14 24             	mov    (%esp),%edx
  800e47:	89 c1                	mov    %eax,%ecx
  800e49:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800e4d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800e51:	eb cb                	jmp    800e1e <__umoddi3+0x10e>
  800e53:	90                   	nop
  800e54:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e58:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800e5c:	0f 82 0f ff ff ff    	jb     800d71 <__umoddi3+0x61>
  800e62:	e9 1a ff ff ff       	jmp    800d81 <__umoddi3+0x71>
