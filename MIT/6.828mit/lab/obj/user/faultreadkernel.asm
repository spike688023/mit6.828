
obj/user/faultreadkernel:     file format elf32-i386


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
  80002c:	e8 1f 00 00 00       	call   800050 <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("I read %08x from location 0xf0100000!\n", *(unsigned*)0xf0100000);
  800039:	a1 00 00 10 f0       	mov    0xf0100000,%eax
  80003e:	89 44 24 04          	mov    %eax,0x4(%esp)
  800042:	c7 04 24 80 0e 80 00 	movl   $0x800e80,(%esp)
  800049:	e8 04 01 00 00       	call   800152 <cprintf>
}
  80004e:	c9                   	leave  
  80004f:	c3                   	ret    

00800050 <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  800050:	55                   	push   %ebp
  800051:	89 e5                	mov    %esp,%ebp
  800053:	56                   	push   %esi
  800054:	53                   	push   %ebx
  800055:	83 ec 10             	sub    $0x10,%esp
  800058:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80005b:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  80005e:	e8 02 0b 00 00       	call   800b65 <sys_getenvid>
  800063:	25 ff 03 00 00       	and    $0x3ff,%eax
  800068:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80006b:	c1 e0 05             	shl    $0x5,%eax
  80006e:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800073:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800078:	85 db                	test   %ebx,%ebx
  80007a:	7e 07                	jle    800083 <libmain+0x33>
		binaryname = argv[0];
  80007c:	8b 06                	mov    (%esi),%eax
  80007e:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800083:	89 74 24 04          	mov    %esi,0x4(%esp)
  800087:	89 1c 24             	mov    %ebx,(%esp)
  80008a:	e8 a4 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80008f:	e8 07 00 00 00       	call   80009b <exit>
}
  800094:	83 c4 10             	add    $0x10,%esp
  800097:	5b                   	pop    %ebx
  800098:	5e                   	pop    %esi
  800099:	5d                   	pop    %ebp
  80009a:	c3                   	ret    

0080009b <exit>:

#include <inc/lib.h>

void
exit(void)
{
  80009b:	55                   	push   %ebp
  80009c:	89 e5                	mov    %esp,%ebp
  80009e:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000a1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000a8:	e8 66 0a 00 00       	call   800b13 <sys_env_destroy>
}
  8000ad:	c9                   	leave  
  8000ae:	c3                   	ret    

008000af <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000af:	55                   	push   %ebp
  8000b0:	89 e5                	mov    %esp,%ebp
  8000b2:	53                   	push   %ebx
  8000b3:	83 ec 14             	sub    $0x14,%esp
  8000b6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000b9:	8b 13                	mov    (%ebx),%edx
  8000bb:	8d 42 01             	lea    0x1(%edx),%eax
  8000be:	89 03                	mov    %eax,(%ebx)
  8000c0:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000c3:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000c7:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000cc:	75 19                	jne    8000e7 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000ce:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000d5:	00 
  8000d6:	8d 43 08             	lea    0x8(%ebx),%eax
  8000d9:	89 04 24             	mov    %eax,(%esp)
  8000dc:	e8 f5 09 00 00       	call   800ad6 <sys_cputs>
		b->idx = 0;
  8000e1:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000e7:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000eb:	83 c4 14             	add    $0x14,%esp
  8000ee:	5b                   	pop    %ebx
  8000ef:	5d                   	pop    %ebp
  8000f0:	c3                   	ret    

008000f1 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  8000f1:	55                   	push   %ebp
  8000f2:	89 e5                	mov    %esp,%ebp
  8000f4:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  8000fa:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800101:	00 00 00 
	b.cnt = 0;
  800104:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80010b:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80010e:	8b 45 0c             	mov    0xc(%ebp),%eax
  800111:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800115:	8b 45 08             	mov    0x8(%ebp),%eax
  800118:	89 44 24 08          	mov    %eax,0x8(%esp)
  80011c:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800122:	89 44 24 04          	mov    %eax,0x4(%esp)
  800126:	c7 04 24 af 00 80 00 	movl   $0x8000af,(%esp)
  80012d:	e8 ac 01 00 00       	call   8002de <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800132:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800138:	89 44 24 04          	mov    %eax,0x4(%esp)
  80013c:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800142:	89 04 24             	mov    %eax,(%esp)
  800145:	e8 8c 09 00 00       	call   800ad6 <sys_cputs>

	return b.cnt;
}
  80014a:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  800150:	c9                   	leave  
  800151:	c3                   	ret    

00800152 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800152:	55                   	push   %ebp
  800153:	89 e5                	mov    %esp,%ebp
  800155:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800158:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80015b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80015f:	8b 45 08             	mov    0x8(%ebp),%eax
  800162:	89 04 24             	mov    %eax,(%esp)
  800165:	e8 87 ff ff ff       	call   8000f1 <vcprintf>
	va_end(ap);

	return cnt;
}
  80016a:	c9                   	leave  
  80016b:	c3                   	ret    
  80016c:	66 90                	xchg   %ax,%ax
  80016e:	66 90                	xchg   %ax,%ax

00800170 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800170:	55                   	push   %ebp
  800171:	89 e5                	mov    %esp,%ebp
  800173:	57                   	push   %edi
  800174:	56                   	push   %esi
  800175:	53                   	push   %ebx
  800176:	83 ec 3c             	sub    $0x3c,%esp
  800179:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80017c:	89 d7                	mov    %edx,%edi
  80017e:	8b 45 08             	mov    0x8(%ebp),%eax
  800181:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800184:	8b 45 0c             	mov    0xc(%ebp),%eax
  800187:	89 c3                	mov    %eax,%ebx
  800189:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80018c:	8b 45 10             	mov    0x10(%ebp),%eax
  80018f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  800192:	b9 00 00 00 00       	mov    $0x0,%ecx
  800197:	89 45 d8             	mov    %eax,-0x28(%ebp)
  80019a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  80019d:	39 d9                	cmp    %ebx,%ecx
  80019f:	72 05                	jb     8001a6 <printnum+0x36>
  8001a1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8001a4:	77 69                	ja     80020f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001a6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8001a9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8001ad:	83 ee 01             	sub    $0x1,%esi
  8001b0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001b4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001b8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001bc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001c0:	89 c3                	mov    %eax,%ebx
  8001c2:	89 d6                	mov    %edx,%esi
  8001c4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8001c7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8001ca:	89 54 24 08          	mov    %edx,0x8(%esp)
  8001ce:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8001d2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001d5:	89 04 24             	mov    %eax,(%esp)
  8001d8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8001db:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001df:	e8 fc 09 00 00       	call   800be0 <__udivdi3>
  8001e4:	89 d9                	mov    %ebx,%ecx
  8001e6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001ea:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001ee:	89 04 24             	mov    %eax,(%esp)
  8001f1:	89 54 24 04          	mov    %edx,0x4(%esp)
  8001f5:	89 fa                	mov    %edi,%edx
  8001f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  8001fa:	e8 71 ff ff ff       	call   800170 <printnum>
  8001ff:	eb 1b                	jmp    80021c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800201:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800205:	8b 45 18             	mov    0x18(%ebp),%eax
  800208:	89 04 24             	mov    %eax,(%esp)
  80020b:	ff d3                	call   *%ebx
  80020d:	eb 03                	jmp    800212 <printnum+0xa2>
  80020f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800212:	83 ee 01             	sub    $0x1,%esi
  800215:	85 f6                	test   %esi,%esi
  800217:	7f e8                	jg     800201 <printnum+0x91>
  800219:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80021c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800220:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800224:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800227:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80022a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80022e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800232:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800235:	89 04 24             	mov    %eax,(%esp)
  800238:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80023b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80023f:	e8 cc 0a 00 00       	call   800d10 <__umoddi3>
  800244:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800248:	0f be 80 b1 0e 80 00 	movsbl 0x800eb1(%eax),%eax
  80024f:	89 04 24             	mov    %eax,(%esp)
  800252:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800255:	ff d0                	call   *%eax
}
  800257:	83 c4 3c             	add    $0x3c,%esp
  80025a:	5b                   	pop    %ebx
  80025b:	5e                   	pop    %esi
  80025c:	5f                   	pop    %edi
  80025d:	5d                   	pop    %ebp
  80025e:	c3                   	ret    

0080025f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80025f:	55                   	push   %ebp
  800260:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800262:	83 fa 01             	cmp    $0x1,%edx
  800265:	7e 0e                	jle    800275 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800267:	8b 10                	mov    (%eax),%edx
  800269:	8d 4a 08             	lea    0x8(%edx),%ecx
  80026c:	89 08                	mov    %ecx,(%eax)
  80026e:	8b 02                	mov    (%edx),%eax
  800270:	8b 52 04             	mov    0x4(%edx),%edx
  800273:	eb 22                	jmp    800297 <getuint+0x38>
	else if (lflag)
  800275:	85 d2                	test   %edx,%edx
  800277:	74 10                	je     800289 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800279:	8b 10                	mov    (%eax),%edx
  80027b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80027e:	89 08                	mov    %ecx,(%eax)
  800280:	8b 02                	mov    (%edx),%eax
  800282:	ba 00 00 00 00       	mov    $0x0,%edx
  800287:	eb 0e                	jmp    800297 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800289:	8b 10                	mov    (%eax),%edx
  80028b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80028e:	89 08                	mov    %ecx,(%eax)
  800290:	8b 02                	mov    (%edx),%eax
  800292:	ba 00 00 00 00       	mov    $0x0,%edx
}
  800297:	5d                   	pop    %ebp
  800298:	c3                   	ret    

00800299 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  800299:	55                   	push   %ebp
  80029a:	89 e5                	mov    %esp,%ebp
  80029c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  80029f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002a3:	8b 10                	mov    (%eax),%edx
  8002a5:	3b 50 04             	cmp    0x4(%eax),%edx
  8002a8:	73 0a                	jae    8002b4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002aa:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002ad:	89 08                	mov    %ecx,(%eax)
  8002af:	8b 45 08             	mov    0x8(%ebp),%eax
  8002b2:	88 02                	mov    %al,(%edx)
}
  8002b4:	5d                   	pop    %ebp
  8002b5:	c3                   	ret    

008002b6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002b6:	55                   	push   %ebp
  8002b7:	89 e5                	mov    %esp,%ebp
  8002b9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002bc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002c3:	8b 45 10             	mov    0x10(%ebp),%eax
  8002c6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002ca:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002cd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002d1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002d4:	89 04 24             	mov    %eax,(%esp)
  8002d7:	e8 02 00 00 00       	call   8002de <vprintfmt>
	va_end(ap);
}
  8002dc:	c9                   	leave  
  8002dd:	c3                   	ret    

008002de <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002de:	55                   	push   %ebp
  8002df:	89 e5                	mov    %esp,%ebp
  8002e1:	57                   	push   %edi
  8002e2:	56                   	push   %esi
  8002e3:	53                   	push   %ebx
  8002e4:	83 ec 3c             	sub    $0x3c,%esp
  8002e7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8002ea:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002ed:	eb 14                	jmp    800303 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')									//当然中间如果遇到'\0'，代表这个字符串的访问结束
  8002ef:	85 c0                	test   %eax,%eax
  8002f1:	0f 84 c7 03 00 00    	je     8006be <vprintfmt+0x3e0>
				return;
			putch(ch, putdat);								//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  8002f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8002fb:	89 04 24             	mov    %eax,(%esp)
  8002fe:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  800301:	89 f3                	mov    %esi,%ebx
  800303:	8d 73 01             	lea    0x1(%ebx),%esi
  800306:	0f b6 03             	movzbl (%ebx),%eax
  800309:	83 f8 25             	cmp    $0x25,%eax
  80030c:	75 e1                	jne    8002ef <vprintfmt+0x11>
  80030e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800312:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800319:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800320:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800327:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  80032e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800333:	eb 1d                	jmp    800352 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800335:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':											//%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  800337:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  80033b:	eb 15                	jmp    800352 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  80033d:	89 de                	mov    %ebx,%esi
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;									//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0':											//0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';										//对其方式标志位变为0
  80033f:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  800343:	eb 0d                	jmp    800352 <vprintfmt+0x74>
			altflag = 1;
			goto reswitch;

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
				width = precision, precision = -1;
  800345:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800348:	89 45 dc             	mov    %eax,-0x24(%ebp)
  80034b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800352:	8d 5e 01             	lea    0x1(%esi),%ebx
  800355:	0f b6 16             	movzbl (%esi),%edx
  800358:	0f b6 c2             	movzbl %dl,%eax
  80035b:	83 ea 23             	sub    $0x23,%edx
  80035e:	80 fa 55             	cmp    $0x55,%dl
  800361:	0f 87 37 03 00 00    	ja     80069e <vprintfmt+0x3c0>
  800367:	0f b6 d2             	movzbl %dl,%edx
  80036a:	ff 24 95 40 0f 80 00 	jmp    *0x800f40(,%edx,4)
  800371:	89 de                	mov    %ebx,%esi
  800373:	89 ca                	mov    %ecx,%edx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  800375:	8d 14 92             	lea    (%edx,%edx,4),%edx
  800378:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  80037c:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80037f:	8d 58 d0             	lea    -0x30(%eax),%ebx
  800382:	83 fb 09             	cmp    $0x9,%ebx
  800385:	77 31                	ja     8003b8 <vprintfmt+0xda>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  800387:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80038a:	eb e9                	jmp    800375 <vprintfmt+0x97>
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  80038c:	8b 45 14             	mov    0x14(%ebp),%eax
  80038f:	8d 50 04             	lea    0x4(%eax),%edx
  800392:	89 55 14             	mov    %edx,0x14(%ebp)
  800395:	8b 00                	mov    (%eax),%eax
  800397:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  80039a:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  80039c:	eb 1d                	jmp    8003bb <vprintfmt+0xdd>
  80039e:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8003a1:	85 c0                	test   %eax,%eax
  8003a3:	0f 48 c1             	cmovs  %ecx,%eax
  8003a6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  8003a9:	89 de                	mov    %ebx,%esi
  8003ab:	eb a5                	jmp    800352 <vprintfmt+0x74>
  8003ad:	89 de                	mov    %ebx,%esi
			if (width < 0)									//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;			
			goto reswitch;

		case '#':
			altflag = 1;
  8003af:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8003b6:	eb 9a                	jmp    800352 <vprintfmt+0x74>
  8003b8:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  8003bb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8003bf:	79 91                	jns    800352 <vprintfmt+0x74>
  8003c1:	eb 82                	jmp    800345 <vprintfmt+0x67>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
  8003c3:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  8003c7:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
			goto reswitch;
  8003c9:	eb 87                	jmp    800352 <vprintfmt+0x74>

		// character
		case 'c':											//如果是'c'代表显示一个字符
			putch(va_arg(ap, int), putdat);					//调用输出一个字符到内存的函数putch
  8003cb:	8b 45 14             	mov    0x14(%ebp),%eax
  8003ce:	8d 50 04             	lea    0x4(%eax),%edx
  8003d1:	89 55 14             	mov    %edx,0x14(%ebp)
  8003d4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003d8:	8b 00                	mov    (%eax),%eax
  8003da:	89 04 24             	mov    %eax,(%esp)
  8003dd:	ff 55 08             	call   *0x8(%ebp)
			break;
  8003e0:	e9 1e ff ff ff       	jmp    800303 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003e5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003e8:	8d 50 04             	lea    0x4(%eax),%edx
  8003eb:	89 55 14             	mov    %edx,0x14(%ebp)
  8003ee:	8b 00                	mov    (%eax),%eax
  8003f0:	99                   	cltd   
  8003f1:	31 d0                	xor    %edx,%eax
  8003f3:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  8003f5:	83 f8 07             	cmp    $0x7,%eax
  8003f8:	7f 0b                	jg     800405 <vprintfmt+0x127>
  8003fa:	8b 14 85 a0 10 80 00 	mov    0x8010a0(,%eax,4),%edx
  800401:	85 d2                	test   %edx,%edx
  800403:	75 20                	jne    800425 <vprintfmt+0x147>
				printfmt(putch, putdat, "error %d", err);
  800405:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800409:	c7 44 24 08 c9 0e 80 	movl   $0x800ec9,0x8(%esp)
  800410:	00 
  800411:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800415:	8b 45 08             	mov    0x8(%ebp),%eax
  800418:	89 04 24             	mov    %eax,(%esp)
  80041b:	e8 96 fe ff ff       	call   8002b6 <printfmt>
  800420:	e9 de fe ff ff       	jmp    800303 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800425:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800429:	c7 44 24 08 d2 0e 80 	movl   $0x800ed2,0x8(%esp)
  800430:	00 
  800431:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800435:	8b 45 08             	mov    0x8(%ebp),%eax
  800438:	89 04 24             	mov    %eax,(%esp)
  80043b:	e8 76 fe ff ff       	call   8002b6 <printfmt>
  800440:	e9 be fe ff ff       	jmp    800303 <vprintfmt+0x25>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800445:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  800448:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80044b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80044e:	8b 45 14             	mov    0x14(%ebp),%eax
  800451:	8d 50 04             	lea    0x4(%eax),%edx
  800454:	89 55 14             	mov    %edx,0x14(%ebp)
  800457:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  800459:	85 f6                	test   %esi,%esi
  80045b:	b8 c2 0e 80 00       	mov    $0x800ec2,%eax
  800460:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800463:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  800467:	0f 84 97 00 00 00    	je     800504 <vprintfmt+0x226>
  80046d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800471:	0f 8e 9b 00 00 00    	jle    800512 <vprintfmt+0x234>
				for (width -= strnlen(p, precision); width > 0; width--)
  800477:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80047b:	89 34 24             	mov    %esi,(%esp)
  80047e:	e8 e5 02 00 00       	call   800768 <strnlen>
  800483:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  800486:	29 c1                	sub    %eax,%ecx
  800488:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
					putch(padc, putdat);
  80048b:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  80048f:	89 45 dc             	mov    %eax,-0x24(%ebp)
  800492:	89 75 d8             	mov    %esi,-0x28(%ebp)
  800495:	8b 75 08             	mov    0x8(%ebp),%esi
  800498:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80049b:	89 cb                	mov    %ecx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  80049d:	eb 0f                	jmp    8004ae <vprintfmt+0x1d0>
					putch(padc, putdat);
  80049f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004a3:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004a6:	89 04 24             	mov    %eax,(%esp)
  8004a9:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ab:	83 eb 01             	sub    $0x1,%ebx
  8004ae:	85 db                	test   %ebx,%ebx
  8004b0:	7f ed                	jg     80049f <vprintfmt+0x1c1>
  8004b2:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8004b5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8004b8:	85 c9                	test   %ecx,%ecx
  8004ba:	b8 00 00 00 00       	mov    $0x0,%eax
  8004bf:	0f 49 c1             	cmovns %ecx,%eax
  8004c2:	29 c1                	sub    %eax,%ecx
  8004c4:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8004c7:	89 cf                	mov    %ecx,%edi
  8004c9:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  8004cc:	eb 50                	jmp    80051e <vprintfmt+0x240>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004ce:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004d2:	74 1e                	je     8004f2 <vprintfmt+0x214>
  8004d4:	0f be d2             	movsbl %dl,%edx
  8004d7:	83 ea 20             	sub    $0x20,%edx
  8004da:	83 fa 5e             	cmp    $0x5e,%edx
  8004dd:	76 13                	jbe    8004f2 <vprintfmt+0x214>
					putch('?', putdat);
  8004df:	8b 45 0c             	mov    0xc(%ebp),%eax
  8004e2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004e6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8004ed:	ff 55 08             	call   *0x8(%ebp)
  8004f0:	eb 0d                	jmp    8004ff <vprintfmt+0x221>
				else
					putch(ch, putdat);
  8004f2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8004f5:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  8004f9:	89 04 24             	mov    %eax,(%esp)
  8004fc:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  8004ff:	83 ef 01             	sub    $0x1,%edi
  800502:	eb 1a                	jmp    80051e <vprintfmt+0x240>
  800504:	89 7d 0c             	mov    %edi,0xc(%ebp)
  800507:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80050a:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80050d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  800510:	eb 0c                	jmp    80051e <vprintfmt+0x240>
  800512:	89 7d 0c             	mov    %edi,0xc(%ebp)
  800515:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800518:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80051b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  80051e:	83 c6 01             	add    $0x1,%esi
  800521:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  800525:	0f be c2             	movsbl %dl,%eax
  800528:	85 c0                	test   %eax,%eax
  80052a:	74 27                	je     800553 <vprintfmt+0x275>
  80052c:	85 db                	test   %ebx,%ebx
  80052e:	78 9e                	js     8004ce <vprintfmt+0x1f0>
  800530:	83 eb 01             	sub    $0x1,%ebx
  800533:	79 99                	jns    8004ce <vprintfmt+0x1f0>
  800535:	89 f8                	mov    %edi,%eax
  800537:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80053a:	8b 75 08             	mov    0x8(%ebp),%esi
  80053d:	89 c3                	mov    %eax,%ebx
  80053f:	eb 1a                	jmp    80055b <vprintfmt+0x27d>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800541:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800545:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80054c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80054e:	83 eb 01             	sub    $0x1,%ebx
  800551:	eb 08                	jmp    80055b <vprintfmt+0x27d>
  800553:	89 fb                	mov    %edi,%ebx
  800555:	8b 75 08             	mov    0x8(%ebp),%esi
  800558:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80055b:	85 db                	test   %ebx,%ebx
  80055d:	7f e2                	jg     800541 <vprintfmt+0x263>
  80055f:	89 75 08             	mov    %esi,0x8(%ebp)
  800562:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800565:	e9 99 fd ff ff       	jmp    800303 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80056a:	83 7d d4 01          	cmpl   $0x1,-0x2c(%ebp)
  80056e:	7e 16                	jle    800586 <vprintfmt+0x2a8>
		return va_arg(*ap, long long);
  800570:	8b 45 14             	mov    0x14(%ebp),%eax
  800573:	8d 50 08             	lea    0x8(%eax),%edx
  800576:	89 55 14             	mov    %edx,0x14(%ebp)
  800579:	8b 50 04             	mov    0x4(%eax),%edx
  80057c:	8b 00                	mov    (%eax),%eax
  80057e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800581:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800584:	eb 34                	jmp    8005ba <vprintfmt+0x2dc>
	else if (lflag)
  800586:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  80058a:	74 18                	je     8005a4 <vprintfmt+0x2c6>
		return va_arg(*ap, long);
  80058c:	8b 45 14             	mov    0x14(%ebp),%eax
  80058f:	8d 50 04             	lea    0x4(%eax),%edx
  800592:	89 55 14             	mov    %edx,0x14(%ebp)
  800595:	8b 30                	mov    (%eax),%esi
  800597:	89 75 e0             	mov    %esi,-0x20(%ebp)
  80059a:	89 f0                	mov    %esi,%eax
  80059c:	c1 f8 1f             	sar    $0x1f,%eax
  80059f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8005a2:	eb 16                	jmp    8005ba <vprintfmt+0x2dc>
	else
		return va_arg(*ap, int);
  8005a4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005a7:	8d 50 04             	lea    0x4(%eax),%edx
  8005aa:	89 55 14             	mov    %edx,0x14(%ebp)
  8005ad:	8b 30                	mov    (%eax),%esi
  8005af:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8005b2:	89 f0                	mov    %esi,%eax
  8005b4:	c1 f8 1f             	sar    $0x1f,%eax
  8005b7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005ba:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005bd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005c0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005c5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8005c9:	0f 89 97 00 00 00    	jns    800666 <vprintfmt+0x388>
				putch('-', putdat);
  8005cf:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005d3:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005da:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005dd:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005e0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005e3:	f7 d8                	neg    %eax
  8005e5:	83 d2 00             	adc    $0x0,%edx
  8005e8:	f7 da                	neg    %edx
			}
			base = 10;
  8005ea:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8005ef:	eb 75                	jmp    800666 <vprintfmt+0x388>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  8005f1:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  8005f4:	8d 45 14             	lea    0x14(%ebp),%eax
  8005f7:	e8 63 fc ff ff       	call   80025f <getuint>
			base = 10;
  8005fc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800601:	eb 63                	jmp    800666 <vprintfmt+0x388>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('0', putdat);
  800603:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800607:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80060e:	ff 55 08             	call   *0x8(%ebp)
			num = getuint(&ap, lflag);
  800611:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800614:	8d 45 14             	lea    0x14(%ebp),%eax
  800617:	e8 43 fc ff ff       	call   80025f <getuint>
			base = 8;
  80061c:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800621:	eb 43                	jmp    800666 <vprintfmt+0x388>
		// pointer
		case 'p':
			putch('0', putdat);
  800623:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800627:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80062e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800631:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800635:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80063c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80063f:	8b 45 14             	mov    0x14(%ebp),%eax
  800642:	8d 50 04             	lea    0x4(%eax),%edx
  800645:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800648:	8b 00                	mov    (%eax),%eax
  80064a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80064f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800654:	eb 10                	jmp    800666 <vprintfmt+0x388>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800656:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800659:	8d 45 14             	lea    0x14(%ebp),%eax
  80065c:	e8 fe fb ff ff       	call   80025f <getuint>
			base = 16;
  800661:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800666:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  80066a:	89 74 24 10          	mov    %esi,0x10(%esp)
  80066e:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800671:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800675:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800679:	89 04 24             	mov    %eax,(%esp)
  80067c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800680:	89 fa                	mov    %edi,%edx
  800682:	8b 45 08             	mov    0x8(%ebp),%eax
  800685:	e8 e6 fa ff ff       	call   800170 <printnum>
			break;
  80068a:	e9 74 fc ff ff       	jmp    800303 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80068f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800693:	89 04 24             	mov    %eax,(%esp)
  800696:	ff 55 08             	call   *0x8(%ebp)
			break;
  800699:	e9 65 fc ff ff       	jmp    800303 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  80069e:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006a2:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006a9:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006ac:	89 f3                	mov    %esi,%ebx
  8006ae:	eb 03                	jmp    8006b3 <vprintfmt+0x3d5>
  8006b0:	83 eb 01             	sub    $0x1,%ebx
  8006b3:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8006b7:	75 f7                	jne    8006b0 <vprintfmt+0x3d2>
  8006b9:	e9 45 fc ff ff       	jmp    800303 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8006be:	83 c4 3c             	add    $0x3c,%esp
  8006c1:	5b                   	pop    %ebx
  8006c2:	5e                   	pop    %esi
  8006c3:	5f                   	pop    %edi
  8006c4:	5d                   	pop    %ebp
  8006c5:	c3                   	ret    

008006c6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006c6:	55                   	push   %ebp
  8006c7:	89 e5                	mov    %esp,%ebp
  8006c9:	83 ec 28             	sub    $0x28,%esp
  8006cc:	8b 45 08             	mov    0x8(%ebp),%eax
  8006cf:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006d2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006d5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006d9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006dc:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006e3:	85 c0                	test   %eax,%eax
  8006e5:	74 30                	je     800717 <vsnprintf+0x51>
  8006e7:	85 d2                	test   %edx,%edx
  8006e9:	7e 2c                	jle    800717 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006eb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006ee:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8006f2:	8b 45 10             	mov    0x10(%ebp),%eax
  8006f5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8006f9:	8d 45 ec             	lea    -0x14(%ebp),%eax
  8006fc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800700:	c7 04 24 99 02 80 00 	movl   $0x800299,(%esp)
  800707:	e8 d2 fb ff ff       	call   8002de <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80070c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80070f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800712:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800715:	eb 05                	jmp    80071c <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800717:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80071c:	c9                   	leave  
  80071d:	c3                   	ret    

0080071e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80071e:	55                   	push   %ebp
  80071f:	89 e5                	mov    %esp,%ebp
  800721:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800724:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800727:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80072b:	8b 45 10             	mov    0x10(%ebp),%eax
  80072e:	89 44 24 08          	mov    %eax,0x8(%esp)
  800732:	8b 45 0c             	mov    0xc(%ebp),%eax
  800735:	89 44 24 04          	mov    %eax,0x4(%esp)
  800739:	8b 45 08             	mov    0x8(%ebp),%eax
  80073c:	89 04 24             	mov    %eax,(%esp)
  80073f:	e8 82 ff ff ff       	call   8006c6 <vsnprintf>
	va_end(ap);

	return rc;
}
  800744:	c9                   	leave  
  800745:	c3                   	ret    
  800746:	66 90                	xchg   %ax,%ax
  800748:	66 90                	xchg   %ax,%ax
  80074a:	66 90                	xchg   %ax,%ax
  80074c:	66 90                	xchg   %ax,%ax
  80074e:	66 90                	xchg   %ax,%ax

00800750 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800750:	55                   	push   %ebp
  800751:	89 e5                	mov    %esp,%ebp
  800753:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800756:	b8 00 00 00 00       	mov    $0x0,%eax
  80075b:	eb 03                	jmp    800760 <strlen+0x10>
		n++;
  80075d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800760:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800764:	75 f7                	jne    80075d <strlen+0xd>
		n++;
	return n;
}
  800766:	5d                   	pop    %ebp
  800767:	c3                   	ret    

00800768 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800768:	55                   	push   %ebp
  800769:	89 e5                	mov    %esp,%ebp
  80076b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80076e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800771:	b8 00 00 00 00       	mov    $0x0,%eax
  800776:	eb 03                	jmp    80077b <strnlen+0x13>
		n++;
  800778:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80077b:	39 d0                	cmp    %edx,%eax
  80077d:	74 06                	je     800785 <strnlen+0x1d>
  80077f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800783:	75 f3                	jne    800778 <strnlen+0x10>
		n++;
	return n;
}
  800785:	5d                   	pop    %ebp
  800786:	c3                   	ret    

00800787 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800787:	55                   	push   %ebp
  800788:	89 e5                	mov    %esp,%ebp
  80078a:	53                   	push   %ebx
  80078b:	8b 45 08             	mov    0x8(%ebp),%eax
  80078e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  800791:	89 c2                	mov    %eax,%edx
  800793:	83 c2 01             	add    $0x1,%edx
  800796:	83 c1 01             	add    $0x1,%ecx
  800799:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  80079d:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007a0:	84 db                	test   %bl,%bl
  8007a2:	75 ef                	jne    800793 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007a4:	5b                   	pop    %ebx
  8007a5:	5d                   	pop    %ebp
  8007a6:	c3                   	ret    

008007a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007a7:	55                   	push   %ebp
  8007a8:	89 e5                	mov    %esp,%ebp
  8007aa:	53                   	push   %ebx
  8007ab:	83 ec 08             	sub    $0x8,%esp
  8007ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007b1:	89 1c 24             	mov    %ebx,(%esp)
  8007b4:	e8 97 ff ff ff       	call   800750 <strlen>
	strcpy(dst + len, src);
  8007b9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007bc:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007c0:	01 d8                	add    %ebx,%eax
  8007c2:	89 04 24             	mov    %eax,(%esp)
  8007c5:	e8 bd ff ff ff       	call   800787 <strcpy>
	return dst;
}
  8007ca:	89 d8                	mov    %ebx,%eax
  8007cc:	83 c4 08             	add    $0x8,%esp
  8007cf:	5b                   	pop    %ebx
  8007d0:	5d                   	pop    %ebp
  8007d1:	c3                   	ret    

008007d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007d2:	55                   	push   %ebp
  8007d3:	89 e5                	mov    %esp,%ebp
  8007d5:	56                   	push   %esi
  8007d6:	53                   	push   %ebx
  8007d7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007dd:	89 f3                	mov    %esi,%ebx
  8007df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007e2:	89 f2                	mov    %esi,%edx
  8007e4:	eb 0f                	jmp    8007f5 <strncpy+0x23>
		*dst++ = *src;
  8007e6:	83 c2 01             	add    $0x1,%edx
  8007e9:	0f b6 01             	movzbl (%ecx),%eax
  8007ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ef:	80 39 01             	cmpb   $0x1,(%ecx)
  8007f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f5:	39 da                	cmp    %ebx,%edx
  8007f7:	75 ed                	jne    8007e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  8007f9:	89 f0                	mov    %esi,%eax
  8007fb:	5b                   	pop    %ebx
  8007fc:	5e                   	pop    %esi
  8007fd:	5d                   	pop    %ebp
  8007fe:	c3                   	ret    

008007ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  8007ff:	55                   	push   %ebp
  800800:	89 e5                	mov    %esp,%ebp
  800802:	56                   	push   %esi
  800803:	53                   	push   %ebx
  800804:	8b 75 08             	mov    0x8(%ebp),%esi
  800807:	8b 55 0c             	mov    0xc(%ebp),%edx
  80080a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80080d:	89 f0                	mov    %esi,%eax
  80080f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800813:	85 c9                	test   %ecx,%ecx
  800815:	75 0b                	jne    800822 <strlcpy+0x23>
  800817:	eb 1d                	jmp    800836 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800819:	83 c0 01             	add    $0x1,%eax
  80081c:	83 c2 01             	add    $0x1,%edx
  80081f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800822:	39 d8                	cmp    %ebx,%eax
  800824:	74 0b                	je     800831 <strlcpy+0x32>
  800826:	0f b6 0a             	movzbl (%edx),%ecx
  800829:	84 c9                	test   %cl,%cl
  80082b:	75 ec                	jne    800819 <strlcpy+0x1a>
  80082d:	89 c2                	mov    %eax,%edx
  80082f:	eb 02                	jmp    800833 <strlcpy+0x34>
  800831:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800833:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800836:	29 f0                	sub    %esi,%eax
}
  800838:	5b                   	pop    %ebx
  800839:	5e                   	pop    %esi
  80083a:	5d                   	pop    %ebp
  80083b:	c3                   	ret    

0080083c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80083c:	55                   	push   %ebp
  80083d:	89 e5                	mov    %esp,%ebp
  80083f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800842:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800845:	eb 06                	jmp    80084d <strcmp+0x11>
		p++, q++;
  800847:	83 c1 01             	add    $0x1,%ecx
  80084a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80084d:	0f b6 01             	movzbl (%ecx),%eax
  800850:	84 c0                	test   %al,%al
  800852:	74 04                	je     800858 <strcmp+0x1c>
  800854:	3a 02                	cmp    (%edx),%al
  800856:	74 ef                	je     800847 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800858:	0f b6 c0             	movzbl %al,%eax
  80085b:	0f b6 12             	movzbl (%edx),%edx
  80085e:	29 d0                	sub    %edx,%eax
}
  800860:	5d                   	pop    %ebp
  800861:	c3                   	ret    

00800862 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800862:	55                   	push   %ebp
  800863:	89 e5                	mov    %esp,%ebp
  800865:	53                   	push   %ebx
  800866:	8b 45 08             	mov    0x8(%ebp),%eax
  800869:	8b 55 0c             	mov    0xc(%ebp),%edx
  80086c:	89 c3                	mov    %eax,%ebx
  80086e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800871:	eb 06                	jmp    800879 <strncmp+0x17>
		n--, p++, q++;
  800873:	83 c0 01             	add    $0x1,%eax
  800876:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800879:	39 d8                	cmp    %ebx,%eax
  80087b:	74 15                	je     800892 <strncmp+0x30>
  80087d:	0f b6 08             	movzbl (%eax),%ecx
  800880:	84 c9                	test   %cl,%cl
  800882:	74 04                	je     800888 <strncmp+0x26>
  800884:	3a 0a                	cmp    (%edx),%cl
  800886:	74 eb                	je     800873 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800888:	0f b6 00             	movzbl (%eax),%eax
  80088b:	0f b6 12             	movzbl (%edx),%edx
  80088e:	29 d0                	sub    %edx,%eax
  800890:	eb 05                	jmp    800897 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  800892:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  800897:	5b                   	pop    %ebx
  800898:	5d                   	pop    %ebp
  800899:	c3                   	ret    

0080089a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  80089a:	55                   	push   %ebp
  80089b:	89 e5                	mov    %esp,%ebp
  80089d:	8b 45 08             	mov    0x8(%ebp),%eax
  8008a0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008a4:	eb 07                	jmp    8008ad <strchr+0x13>
		if (*s == c)
  8008a6:	38 ca                	cmp    %cl,%dl
  8008a8:	74 0f                	je     8008b9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008aa:	83 c0 01             	add    $0x1,%eax
  8008ad:	0f b6 10             	movzbl (%eax),%edx
  8008b0:	84 d2                	test   %dl,%dl
  8008b2:	75 f2                	jne    8008a6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008b9:	5d                   	pop    %ebp
  8008ba:	c3                   	ret    

008008bb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008bb:	55                   	push   %ebp
  8008bc:	89 e5                	mov    %esp,%ebp
  8008be:	8b 45 08             	mov    0x8(%ebp),%eax
  8008c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008c5:	eb 07                	jmp    8008ce <strfind+0x13>
		if (*s == c)
  8008c7:	38 ca                	cmp    %cl,%dl
  8008c9:	74 0a                	je     8008d5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8008cb:	83 c0 01             	add    $0x1,%eax
  8008ce:	0f b6 10             	movzbl (%eax),%edx
  8008d1:	84 d2                	test   %dl,%dl
  8008d3:	75 f2                	jne    8008c7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8008d5:	5d                   	pop    %ebp
  8008d6:	c3                   	ret    

008008d7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008d7:	55                   	push   %ebp
  8008d8:	89 e5                	mov    %esp,%ebp
  8008da:	57                   	push   %edi
  8008db:	56                   	push   %esi
  8008dc:	53                   	push   %ebx
  8008dd:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008e0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008e3:	85 c9                	test   %ecx,%ecx
  8008e5:	74 36                	je     80091d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008e7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008ed:	75 28                	jne    800917 <memset+0x40>
  8008ef:	f6 c1 03             	test   $0x3,%cl
  8008f2:	75 23                	jne    800917 <memset+0x40>
		c &= 0xFF;
  8008f4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  8008f8:	89 d3                	mov    %edx,%ebx
  8008fa:	c1 e3 08             	shl    $0x8,%ebx
  8008fd:	89 d6                	mov    %edx,%esi
  8008ff:	c1 e6 18             	shl    $0x18,%esi
  800902:	89 d0                	mov    %edx,%eax
  800904:	c1 e0 10             	shl    $0x10,%eax
  800907:	09 f0                	or     %esi,%eax
  800909:	09 c2                	or     %eax,%edx
  80090b:	89 d0                	mov    %edx,%eax
  80090d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  80090f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800912:	fc                   	cld    
  800913:	f3 ab                	rep stos %eax,%es:(%edi)
  800915:	eb 06                	jmp    80091d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800917:	8b 45 0c             	mov    0xc(%ebp),%eax
  80091a:	fc                   	cld    
  80091b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80091d:	89 f8                	mov    %edi,%eax
  80091f:	5b                   	pop    %ebx
  800920:	5e                   	pop    %esi
  800921:	5f                   	pop    %edi
  800922:	5d                   	pop    %ebp
  800923:	c3                   	ret    

00800924 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800924:	55                   	push   %ebp
  800925:	89 e5                	mov    %esp,%ebp
  800927:	57                   	push   %edi
  800928:	56                   	push   %esi
  800929:	8b 45 08             	mov    0x8(%ebp),%eax
  80092c:	8b 75 0c             	mov    0xc(%ebp),%esi
  80092f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800932:	39 c6                	cmp    %eax,%esi
  800934:	73 35                	jae    80096b <memmove+0x47>
  800936:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800939:	39 d0                	cmp    %edx,%eax
  80093b:	73 2e                	jae    80096b <memmove+0x47>
		s += n;
		d += n;
  80093d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800940:	89 d6                	mov    %edx,%esi
  800942:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800944:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80094a:	75 13                	jne    80095f <memmove+0x3b>
  80094c:	f6 c1 03             	test   $0x3,%cl
  80094f:	75 0e                	jne    80095f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800951:	83 ef 04             	sub    $0x4,%edi
  800954:	8d 72 fc             	lea    -0x4(%edx),%esi
  800957:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80095a:	fd                   	std    
  80095b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80095d:	eb 09                	jmp    800968 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  80095f:	83 ef 01             	sub    $0x1,%edi
  800962:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800965:	fd                   	std    
  800966:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800968:	fc                   	cld    
  800969:	eb 1d                	jmp    800988 <memmove+0x64>
  80096b:	89 f2                	mov    %esi,%edx
  80096d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80096f:	f6 c2 03             	test   $0x3,%dl
  800972:	75 0f                	jne    800983 <memmove+0x5f>
  800974:	f6 c1 03             	test   $0x3,%cl
  800977:	75 0a                	jne    800983 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800979:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  80097c:	89 c7                	mov    %eax,%edi
  80097e:	fc                   	cld    
  80097f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800981:	eb 05                	jmp    800988 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800983:	89 c7                	mov    %eax,%edi
  800985:	fc                   	cld    
  800986:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800988:	5e                   	pop    %esi
  800989:	5f                   	pop    %edi
  80098a:	5d                   	pop    %ebp
  80098b:	c3                   	ret    

0080098c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80098c:	55                   	push   %ebp
  80098d:	89 e5                	mov    %esp,%ebp
  80098f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  800992:	8b 45 10             	mov    0x10(%ebp),%eax
  800995:	89 44 24 08          	mov    %eax,0x8(%esp)
  800999:	8b 45 0c             	mov    0xc(%ebp),%eax
  80099c:	89 44 24 04          	mov    %eax,0x4(%esp)
  8009a0:	8b 45 08             	mov    0x8(%ebp),%eax
  8009a3:	89 04 24             	mov    %eax,(%esp)
  8009a6:	e8 79 ff ff ff       	call   800924 <memmove>
}
  8009ab:	c9                   	leave  
  8009ac:	c3                   	ret    

008009ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009ad:	55                   	push   %ebp
  8009ae:	89 e5                	mov    %esp,%ebp
  8009b0:	56                   	push   %esi
  8009b1:	53                   	push   %ebx
  8009b2:	8b 55 08             	mov    0x8(%ebp),%edx
  8009b5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8009b8:	89 d6                	mov    %edx,%esi
  8009ba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009bd:	eb 1a                	jmp    8009d9 <memcmp+0x2c>
		if (*s1 != *s2)
  8009bf:	0f b6 02             	movzbl (%edx),%eax
  8009c2:	0f b6 19             	movzbl (%ecx),%ebx
  8009c5:	38 d8                	cmp    %bl,%al
  8009c7:	74 0a                	je     8009d3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009c9:	0f b6 c0             	movzbl %al,%eax
  8009cc:	0f b6 db             	movzbl %bl,%ebx
  8009cf:	29 d8                	sub    %ebx,%eax
  8009d1:	eb 0f                	jmp    8009e2 <memcmp+0x35>
		s1++, s2++;
  8009d3:	83 c2 01             	add    $0x1,%edx
  8009d6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009d9:	39 f2                	cmp    %esi,%edx
  8009db:	75 e2                	jne    8009bf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009e2:	5b                   	pop    %ebx
  8009e3:	5e                   	pop    %esi
  8009e4:	5d                   	pop    %ebp
  8009e5:	c3                   	ret    

008009e6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009e6:	55                   	push   %ebp
  8009e7:	89 e5                	mov    %esp,%ebp
  8009e9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009ec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009ef:	89 c2                	mov    %eax,%edx
  8009f1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  8009f4:	eb 07                	jmp    8009fd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  8009f6:	38 08                	cmp    %cl,(%eax)
  8009f8:	74 07                	je     800a01 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  8009fa:	83 c0 01             	add    $0x1,%eax
  8009fd:	39 d0                	cmp    %edx,%eax
  8009ff:	72 f5                	jb     8009f6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a01:	5d                   	pop    %ebp
  800a02:	c3                   	ret    

00800a03 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a03:	55                   	push   %ebp
  800a04:	89 e5                	mov    %esp,%ebp
  800a06:	57                   	push   %edi
  800a07:	56                   	push   %esi
  800a08:	53                   	push   %ebx
  800a09:	8b 55 08             	mov    0x8(%ebp),%edx
  800a0c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a0f:	eb 03                	jmp    800a14 <strtol+0x11>
		s++;
  800a11:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a14:	0f b6 0a             	movzbl (%edx),%ecx
  800a17:	80 f9 09             	cmp    $0x9,%cl
  800a1a:	74 f5                	je     800a11 <strtol+0xe>
  800a1c:	80 f9 20             	cmp    $0x20,%cl
  800a1f:	74 f0                	je     800a11 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a21:	80 f9 2b             	cmp    $0x2b,%cl
  800a24:	75 0a                	jne    800a30 <strtol+0x2d>
		s++;
  800a26:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a29:	bf 00 00 00 00       	mov    $0x0,%edi
  800a2e:	eb 11                	jmp    800a41 <strtol+0x3e>
  800a30:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a35:	80 f9 2d             	cmp    $0x2d,%cl
  800a38:	75 07                	jne    800a41 <strtol+0x3e>
		s++, neg = 1;
  800a3a:	8d 52 01             	lea    0x1(%edx),%edx
  800a3d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a41:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800a46:	75 15                	jne    800a5d <strtol+0x5a>
  800a48:	80 3a 30             	cmpb   $0x30,(%edx)
  800a4b:	75 10                	jne    800a5d <strtol+0x5a>
  800a4d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a51:	75 0a                	jne    800a5d <strtol+0x5a>
		s += 2, base = 16;
  800a53:	83 c2 02             	add    $0x2,%edx
  800a56:	b8 10 00 00 00       	mov    $0x10,%eax
  800a5b:	eb 10                	jmp    800a6d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a5d:	85 c0                	test   %eax,%eax
  800a5f:	75 0c                	jne    800a6d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a61:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a63:	80 3a 30             	cmpb   $0x30,(%edx)
  800a66:	75 05                	jne    800a6d <strtol+0x6a>
		s++, base = 8;
  800a68:	83 c2 01             	add    $0x1,%edx
  800a6b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800a6d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800a72:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a75:	0f b6 0a             	movzbl (%edx),%ecx
  800a78:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800a7b:	89 f0                	mov    %esi,%eax
  800a7d:	3c 09                	cmp    $0x9,%al
  800a7f:	77 08                	ja     800a89 <strtol+0x86>
			dig = *s - '0';
  800a81:	0f be c9             	movsbl %cl,%ecx
  800a84:	83 e9 30             	sub    $0x30,%ecx
  800a87:	eb 20                	jmp    800aa9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800a89:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800a8c:	89 f0                	mov    %esi,%eax
  800a8e:	3c 19                	cmp    $0x19,%al
  800a90:	77 08                	ja     800a9a <strtol+0x97>
			dig = *s - 'a' + 10;
  800a92:	0f be c9             	movsbl %cl,%ecx
  800a95:	83 e9 57             	sub    $0x57,%ecx
  800a98:	eb 0f                	jmp    800aa9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800a9a:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800a9d:	89 f0                	mov    %esi,%eax
  800a9f:	3c 19                	cmp    $0x19,%al
  800aa1:	77 16                	ja     800ab9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800aa3:	0f be c9             	movsbl %cl,%ecx
  800aa6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800aa9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800aac:	7d 0f                	jge    800abd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800aae:	83 c2 01             	add    $0x1,%edx
  800ab1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800ab5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800ab7:	eb bc                	jmp    800a75 <strtol+0x72>
  800ab9:	89 d8                	mov    %ebx,%eax
  800abb:	eb 02                	jmp    800abf <strtol+0xbc>
  800abd:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800abf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ac3:	74 05                	je     800aca <strtol+0xc7>
		*endptr = (char *) s;
  800ac5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ac8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800aca:	f7 d8                	neg    %eax
  800acc:	85 ff                	test   %edi,%edi
  800ace:	0f 44 c3             	cmove  %ebx,%eax
}
  800ad1:	5b                   	pop    %ebx
  800ad2:	5e                   	pop    %esi
  800ad3:	5f                   	pop    %edi
  800ad4:	5d                   	pop    %ebp
  800ad5:	c3                   	ret    

00800ad6 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800ad6:	55                   	push   %ebp
  800ad7:	89 e5                	mov    %esp,%ebp
  800ad9:	57                   	push   %edi
  800ada:	56                   	push   %esi
  800adb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800adc:	b8 00 00 00 00       	mov    $0x0,%eax
  800ae1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800ae4:	8b 55 08             	mov    0x8(%ebp),%edx
  800ae7:	89 c3                	mov    %eax,%ebx
  800ae9:	89 c7                	mov    %eax,%edi
  800aeb:	89 c6                	mov    %eax,%esi
  800aed:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800aef:	5b                   	pop    %ebx
  800af0:	5e                   	pop    %esi
  800af1:	5f                   	pop    %edi
  800af2:	5d                   	pop    %ebp
  800af3:	c3                   	ret    

00800af4 <sys_cgetc>:

int
sys_cgetc(void)
{
  800af4:	55                   	push   %ebp
  800af5:	89 e5                	mov    %esp,%ebp
  800af7:	57                   	push   %edi
  800af8:	56                   	push   %esi
  800af9:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800afa:	ba 00 00 00 00       	mov    $0x0,%edx
  800aff:	b8 01 00 00 00       	mov    $0x1,%eax
  800b04:	89 d1                	mov    %edx,%ecx
  800b06:	89 d3                	mov    %edx,%ebx
  800b08:	89 d7                	mov    %edx,%edi
  800b0a:	89 d6                	mov    %edx,%esi
  800b0c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b0e:	5b                   	pop    %ebx
  800b0f:	5e                   	pop    %esi
  800b10:	5f                   	pop    %edi
  800b11:	5d                   	pop    %ebp
  800b12:	c3                   	ret    

00800b13 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b13:	55                   	push   %ebp
  800b14:	89 e5                	mov    %esp,%ebp
  800b16:	57                   	push   %edi
  800b17:	56                   	push   %esi
  800b18:	53                   	push   %ebx
  800b19:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b1c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b21:	b8 03 00 00 00       	mov    $0x3,%eax
  800b26:	8b 55 08             	mov    0x8(%ebp),%edx
  800b29:	89 cb                	mov    %ecx,%ebx
  800b2b:	89 cf                	mov    %ecx,%edi
  800b2d:	89 ce                	mov    %ecx,%esi
  800b2f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800b31:	85 c0                	test   %eax,%eax
  800b33:	7e 28                	jle    800b5d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b35:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b39:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800b40:	00 
  800b41:	c7 44 24 08 c0 10 80 	movl   $0x8010c0,0x8(%esp)
  800b48:	00 
  800b49:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800b50:	00 
  800b51:	c7 04 24 dd 10 80 00 	movl   $0x8010dd,(%esp)
  800b58:	e8 27 00 00 00       	call   800b84 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b5d:	83 c4 2c             	add    $0x2c,%esp
  800b60:	5b                   	pop    %ebx
  800b61:	5e                   	pop    %esi
  800b62:	5f                   	pop    %edi
  800b63:	5d                   	pop    %ebp
  800b64:	c3                   	ret    

00800b65 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b65:	55                   	push   %ebp
  800b66:	89 e5                	mov    %esp,%ebp
  800b68:	57                   	push   %edi
  800b69:	56                   	push   %esi
  800b6a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b6b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b70:	b8 02 00 00 00       	mov    $0x2,%eax
  800b75:	89 d1                	mov    %edx,%ecx
  800b77:	89 d3                	mov    %edx,%ebx
  800b79:	89 d7                	mov    %edx,%edi
  800b7b:	89 d6                	mov    %edx,%esi
  800b7d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b7f:	5b                   	pop    %ebx
  800b80:	5e                   	pop    %esi
  800b81:	5f                   	pop    %edi
  800b82:	5d                   	pop    %ebp
  800b83:	c3                   	ret    

00800b84 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b84:	55                   	push   %ebp
  800b85:	89 e5                	mov    %esp,%ebp
  800b87:	56                   	push   %esi
  800b88:	53                   	push   %ebx
  800b89:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800b8c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b8f:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800b95:	e8 cb ff ff ff       	call   800b65 <sys_getenvid>
  800b9a:	8b 55 0c             	mov    0xc(%ebp),%edx
  800b9d:	89 54 24 10          	mov    %edx,0x10(%esp)
  800ba1:	8b 55 08             	mov    0x8(%ebp),%edx
  800ba4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800ba8:	89 74 24 08          	mov    %esi,0x8(%esp)
  800bac:	89 44 24 04          	mov    %eax,0x4(%esp)
  800bb0:	c7 04 24 ec 10 80 00 	movl   $0x8010ec,(%esp)
  800bb7:	e8 96 f5 ff ff       	call   800152 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800bbc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800bc0:	8b 45 10             	mov    0x10(%ebp),%eax
  800bc3:	89 04 24             	mov    %eax,(%esp)
  800bc6:	e8 26 f5 ff ff       	call   8000f1 <vcprintf>
	cprintf("\n");
  800bcb:	c7 04 24 10 11 80 00 	movl   $0x801110,(%esp)
  800bd2:	e8 7b f5 ff ff       	call   800152 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800bd7:	cc                   	int3   
  800bd8:	eb fd                	jmp    800bd7 <_panic+0x53>
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
