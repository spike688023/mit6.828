
obj/user/hello:     file format elf32-i386


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
  80002c:	e8 2e 00 00 00       	call   80005f <libmain>
1:	jmp 1b
  800031:	eb fe                	jmp    800031 <args_exist+0x5>

00800033 <umain>:
// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
  800033:	55                   	push   %ebp
  800034:	89 e5                	mov    %esp,%ebp
  800036:	83 ec 18             	sub    $0x18,%esp
	cprintf("hello, world\n");
  800039:	c7 04 24 80 0e 80 00 	movl   $0x800e80,(%esp)
  800040:	e8 1c 01 00 00       	call   800161 <cprintf>
	cprintf("i am environment %08x\n", thisenv->env_id);
  800045:	a1 04 20 80 00       	mov    0x802004,%eax
  80004a:	8b 40 48             	mov    0x48(%eax),%eax
  80004d:	89 44 24 04          	mov    %eax,0x4(%esp)
  800051:	c7 04 24 8e 0e 80 00 	movl   $0x800e8e,(%esp)
  800058:	e8 04 01 00 00       	call   800161 <cprintf>
}
  80005d:	c9                   	leave  
  80005e:	c3                   	ret    

0080005f <libmain>:
const volatile struct Env *thisenv;
const char *binaryname = "<unknown>";

void
libmain(int argc, char **argv)
{
  80005f:	55                   	push   %ebp
  800060:	89 e5                	mov    %esp,%ebp
  800062:	56                   	push   %esi
  800063:	53                   	push   %ebx
  800064:	83 ec 10             	sub    $0x10,%esp
  800067:	8b 5d 08             	mov    0x8(%ebp),%ebx
  80006a:	8b 75 0c             	mov    0xc(%ebp),%esi
	// set thisenv to point at our Env structure in envs[].
	// LAB 3: Your code here.
	thisenv = &envs[ENVX(sys_getenvid())];
  80006d:	e8 03 0b 00 00       	call   800b75 <sys_getenvid>
  800072:	25 ff 03 00 00       	and    $0x3ff,%eax
  800077:	8d 04 40             	lea    (%eax,%eax,2),%eax
  80007a:	c1 e0 05             	shl    $0x5,%eax
  80007d:	05 00 00 c0 ee       	add    $0xeec00000,%eax
  800082:	a3 04 20 80 00       	mov    %eax,0x802004

	// save the name of the program so that panic() can use it
	if (argc > 0)
  800087:	85 db                	test   %ebx,%ebx
  800089:	7e 07                	jle    800092 <libmain+0x33>
		binaryname = argv[0];
  80008b:	8b 06                	mov    (%esi),%eax
  80008d:	a3 00 20 80 00       	mov    %eax,0x802000

	// call user main routine
	umain(argc, argv);
  800092:	89 74 24 04          	mov    %esi,0x4(%esp)
  800096:	89 1c 24             	mov    %ebx,(%esp)
  800099:	e8 95 ff ff ff       	call   800033 <umain>

	// exit gracefully
	exit();
  80009e:	e8 07 00 00 00       	call   8000aa <exit>
}
  8000a3:	83 c4 10             	add    $0x10,%esp
  8000a6:	5b                   	pop    %ebx
  8000a7:	5e                   	pop    %esi
  8000a8:	5d                   	pop    %ebp
  8000a9:	c3                   	ret    

008000aa <exit>:

#include <inc/lib.h>

void
exit(void)
{
  8000aa:	55                   	push   %ebp
  8000ab:	89 e5                	mov    %esp,%ebp
  8000ad:	83 ec 18             	sub    $0x18,%esp
	sys_env_destroy(0);
  8000b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
  8000b7:	e8 67 0a 00 00       	call   800b23 <sys_env_destroy>
}
  8000bc:	c9                   	leave  
  8000bd:	c3                   	ret    

008000be <putch>:
};


static void
putch(int ch, struct printbuf *b)
{
  8000be:	55                   	push   %ebp
  8000bf:	89 e5                	mov    %esp,%ebp
  8000c1:	53                   	push   %ebx
  8000c2:	83 ec 14             	sub    $0x14,%esp
  8000c5:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	b->buf[b->idx++] = ch;
  8000c8:	8b 13                	mov    (%ebx),%edx
  8000ca:	8d 42 01             	lea    0x1(%edx),%eax
  8000cd:	89 03                	mov    %eax,(%ebx)
  8000cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
  8000d2:	88 4c 13 08          	mov    %cl,0x8(%ebx,%edx,1)
	if (b->idx == 256-1) {
  8000d6:	3d ff 00 00 00       	cmp    $0xff,%eax
  8000db:	75 19                	jne    8000f6 <putch+0x38>
		sys_cputs(b->buf, b->idx);
  8000dd:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
  8000e4:	00 
  8000e5:	8d 43 08             	lea    0x8(%ebx),%eax
  8000e8:	89 04 24             	mov    %eax,(%esp)
  8000eb:	e8 f6 09 00 00       	call   800ae6 <sys_cputs>
		b->idx = 0;
  8000f0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	}
	b->cnt++;
  8000f6:	83 43 04 01          	addl   $0x1,0x4(%ebx)
}
  8000fa:	83 c4 14             	add    $0x14,%esp
  8000fd:	5b                   	pop    %ebx
  8000fe:	5d                   	pop    %ebp
  8000ff:	c3                   	ret    

00800100 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
  800100:	55                   	push   %ebp
  800101:	89 e5                	mov    %esp,%ebp
  800103:	81 ec 28 01 00 00    	sub    $0x128,%esp
	struct printbuf b;

	b.idx = 0;
  800109:	c7 85 f0 fe ff ff 00 	movl   $0x0,-0x110(%ebp)
  800110:	00 00 00 
	b.cnt = 0;
  800113:	c7 85 f4 fe ff ff 00 	movl   $0x0,-0x10c(%ebp)
  80011a:	00 00 00 
	vprintfmt((void*)putch, &b, fmt, ap);
  80011d:	8b 45 0c             	mov    0xc(%ebp),%eax
  800120:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800124:	8b 45 08             	mov    0x8(%ebp),%eax
  800127:	89 44 24 08          	mov    %eax,0x8(%esp)
  80012b:	8d 85 f0 fe ff ff    	lea    -0x110(%ebp),%eax
  800131:	89 44 24 04          	mov    %eax,0x4(%esp)
  800135:	c7 04 24 be 00 80 00 	movl   $0x8000be,(%esp)
  80013c:	e8 ad 01 00 00       	call   8002ee <vprintfmt>
	sys_cputs(b.buf, b.idx);
  800141:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
  800147:	89 44 24 04          	mov    %eax,0x4(%esp)
  80014b:	8d 85 f8 fe ff ff    	lea    -0x108(%ebp),%eax
  800151:	89 04 24             	mov    %eax,(%esp)
  800154:	e8 8d 09 00 00       	call   800ae6 <sys_cputs>

	return b.cnt;
}
  800159:	8b 85 f4 fe ff ff    	mov    -0x10c(%ebp),%eax
  80015f:	c9                   	leave  
  800160:	c3                   	ret    

00800161 <cprintf>:

int
cprintf(const char *fmt, ...)
{
  800161:	55                   	push   %ebp
  800162:	89 e5                	mov    %esp,%ebp
  800164:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
  800167:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
  80016a:	89 44 24 04          	mov    %eax,0x4(%esp)
  80016e:	8b 45 08             	mov    0x8(%ebp),%eax
  800171:	89 04 24             	mov    %eax,(%esp)
  800174:	e8 87 ff ff ff       	call   800100 <vcprintf>
	va_end(ap);

	return cnt;
}
  800179:	c9                   	leave  
  80017a:	c3                   	ret    
  80017b:	66 90                	xchg   %ax,%ax
  80017d:	66 90                	xchg   %ax,%ax
  80017f:	90                   	nop

00800180 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
  800180:	55                   	push   %ebp
  800181:	89 e5                	mov    %esp,%ebp
  800183:	57                   	push   %edi
  800184:	56                   	push   %esi
  800185:	53                   	push   %ebx
  800186:	83 ec 3c             	sub    $0x3c,%esp
  800189:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  80018c:	89 d7                	mov    %edx,%edi
  80018e:	8b 45 08             	mov    0x8(%ebp),%eax
  800191:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800194:	8b 45 0c             	mov    0xc(%ebp),%eax
  800197:	89 c3                	mov    %eax,%ebx
  800199:	89 45 d4             	mov    %eax,-0x2c(%ebp)
  80019c:	8b 45 10             	mov    0x10(%ebp),%eax
  80019f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
  8001a2:	b9 00 00 00 00       	mov    $0x0,%ecx
  8001a7:	89 45 d8             	mov    %eax,-0x28(%ebp)
  8001aa:	89 4d dc             	mov    %ecx,-0x24(%ebp)
  8001ad:	39 d9                	cmp    %ebx,%ecx
  8001af:	72 05                	jb     8001b6 <printnum+0x36>
  8001b1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
  8001b4:	77 69                	ja     80021f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
  8001b6:	8b 4d 18             	mov    0x18(%ebp),%ecx
  8001b9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  8001bd:	83 ee 01             	sub    $0x1,%esi
  8001c0:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001c4:	89 44 24 08          	mov    %eax,0x8(%esp)
  8001c8:	8b 44 24 08          	mov    0x8(%esp),%eax
  8001cc:	8b 54 24 0c          	mov    0xc(%esp),%edx
  8001d0:	89 c3                	mov    %eax,%ebx
  8001d2:	89 d6                	mov    %edx,%esi
  8001d4:	8b 55 d8             	mov    -0x28(%ebp),%edx
  8001d7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
  8001da:	89 54 24 08          	mov    %edx,0x8(%esp)
  8001de:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
  8001e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8001e5:	89 04 24             	mov    %eax,(%esp)
  8001e8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  8001eb:	89 44 24 04          	mov    %eax,0x4(%esp)
  8001ef:	e8 fc 09 00 00       	call   800bf0 <__udivdi3>
  8001f4:	89 d9                	mov    %ebx,%ecx
  8001f6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  8001fa:	89 74 24 0c          	mov    %esi,0xc(%esp)
  8001fe:	89 04 24             	mov    %eax,(%esp)
  800201:	89 54 24 04          	mov    %edx,0x4(%esp)
  800205:	89 fa                	mov    %edi,%edx
  800207:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  80020a:	e8 71 ff ff ff       	call   800180 <printnum>
  80020f:	eb 1b                	jmp    80022c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
  800211:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800215:	8b 45 18             	mov    0x18(%ebp),%eax
  800218:	89 04 24             	mov    %eax,(%esp)
  80021b:	ff d3                	call   *%ebx
  80021d:	eb 03                	jmp    800222 <printnum+0xa2>
  80021f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
  800222:	83 ee 01             	sub    $0x1,%esi
  800225:	85 f6                	test   %esi,%esi
  800227:	7f e8                	jg     800211 <printnum+0x91>
  800229:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
  80022c:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800230:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800234:	8b 45 d8             	mov    -0x28(%ebp),%eax
  800237:	8b 55 dc             	mov    -0x24(%ebp),%edx
  80023a:	89 44 24 08          	mov    %eax,0x8(%esp)
  80023e:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800242:	8b 45 e0             	mov    -0x20(%ebp),%eax
  800245:	89 04 24             	mov    %eax,(%esp)
  800248:	8b 45 d4             	mov    -0x2c(%ebp),%eax
  80024b:	89 44 24 04          	mov    %eax,0x4(%esp)
  80024f:	e8 cc 0a 00 00       	call   800d20 <__umoddi3>
  800254:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800258:	0f be 80 af 0e 80 00 	movsbl 0x800eaf(%eax),%eax
  80025f:	89 04 24             	mov    %eax,(%esp)
  800262:	8b 45 e4             	mov    -0x1c(%ebp),%eax
  800265:	ff d0                	call   *%eax
}
  800267:	83 c4 3c             	add    $0x3c,%esp
  80026a:	5b                   	pop    %ebx
  80026b:	5e                   	pop    %esi
  80026c:	5f                   	pop    %edi
  80026d:	5d                   	pop    %ebp
  80026e:	c3                   	ret    

0080026f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
  80026f:	55                   	push   %ebp
  800270:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
  800272:	83 fa 01             	cmp    $0x1,%edx
  800275:	7e 0e                	jle    800285 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
  800277:	8b 10                	mov    (%eax),%edx
  800279:	8d 4a 08             	lea    0x8(%edx),%ecx
  80027c:	89 08                	mov    %ecx,(%eax)
  80027e:	8b 02                	mov    (%edx),%eax
  800280:	8b 52 04             	mov    0x4(%edx),%edx
  800283:	eb 22                	jmp    8002a7 <getuint+0x38>
	else if (lflag)
  800285:	85 d2                	test   %edx,%edx
  800287:	74 10                	je     800299 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
  800289:	8b 10                	mov    (%eax),%edx
  80028b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80028e:	89 08                	mov    %ecx,(%eax)
  800290:	8b 02                	mov    (%edx),%eax
  800292:	ba 00 00 00 00       	mov    $0x0,%edx
  800297:	eb 0e                	jmp    8002a7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
  800299:	8b 10                	mov    (%eax),%edx
  80029b:	8d 4a 04             	lea    0x4(%edx),%ecx
  80029e:	89 08                	mov    %ecx,(%eax)
  8002a0:	8b 02                	mov    (%edx),%eax
  8002a2:	ba 00 00 00 00       	mov    $0x0,%edx
}
  8002a7:	5d                   	pop    %ebp
  8002a8:	c3                   	ret    

008002a9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
  8002a9:	55                   	push   %ebp
  8002aa:	89 e5                	mov    %esp,%ebp
  8002ac:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
  8002af:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
  8002b3:	8b 10                	mov    (%eax),%edx
  8002b5:	3b 50 04             	cmp    0x4(%eax),%edx
  8002b8:	73 0a                	jae    8002c4 <sprintputch+0x1b>
		*b->buf++ = ch;
  8002ba:	8d 4a 01             	lea    0x1(%edx),%ecx
  8002bd:	89 08                	mov    %ecx,(%eax)
  8002bf:	8b 45 08             	mov    0x8(%ebp),%eax
  8002c2:	88 02                	mov    %al,(%edx)
}
  8002c4:	5d                   	pop    %ebp
  8002c5:	c3                   	ret    

008002c6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
  8002c6:	55                   	push   %ebp
  8002c7:	89 e5                	mov    %esp,%ebp
  8002c9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
  8002cc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
  8002cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
  8002d3:	8b 45 10             	mov    0x10(%ebp),%eax
  8002d6:	89 44 24 08          	mov    %eax,0x8(%esp)
  8002da:	8b 45 0c             	mov    0xc(%ebp),%eax
  8002dd:	89 44 24 04          	mov    %eax,0x4(%esp)
  8002e1:	8b 45 08             	mov    0x8(%ebp),%eax
  8002e4:	89 04 24             	mov    %eax,(%esp)
  8002e7:	e8 02 00 00 00       	call   8002ee <vprintfmt>
	va_end(ap);
}
  8002ec:	c9                   	leave  
  8002ed:	c3                   	ret    

008002ee <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
  8002ee:	55                   	push   %ebp
  8002ef:	89 e5                	mov    %esp,%ebp
  8002f1:	57                   	push   %edi
  8002f2:	56                   	push   %esi
  8002f3:	53                   	push   %ebx
  8002f4:	83 ec 3c             	sub    $0x3c,%esp
  8002f7:	8b 7d 0c             	mov    0xc(%ebp),%edi
  8002fa:	8b 5d 10             	mov    0x10(%ebp),%ebx
  8002fd:	eb 14                	jmp    800313 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')									//当然中间如果遇到'\0'，代表这个字符串的访问结束
  8002ff:	85 c0                	test   %eax,%eax
  800301:	0f 84 c7 03 00 00    	je     8006ce <vprintfmt+0x3e0>
				return;
			putch(ch, putdat);								//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
  800307:	89 7c 24 04          	mov    %edi,0x4(%esp)
  80030b:	89 04 24             	mov    %eax,(%esp)
  80030e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
  800311:	89 f3                	mov    %esi,%ebx
  800313:	8d 73 01             	lea    0x1(%ebx),%esi
  800316:	0f b6 03             	movzbl (%ebx),%eax
  800319:	83 f8 25             	cmp    $0x25,%eax
  80031c:	75 e1                	jne    8002ff <vprintfmt+0x11>
  80031e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
  800322:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  800329:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
  800330:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
  800337:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
  80033e:	b9 00 00 00 00       	mov    $0x0,%ecx
  800343:	eb 1d                	jmp    800362 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800345:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':											//%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
  800347:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
  80034b:	eb 15                	jmp    800362 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  80034d:	89 de                	mov    %ebx,%esi
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;									//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0':											//0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';										//对其方式标志位变为0
  80034f:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
  800353:	eb 0d                	jmp    800362 <vprintfmt+0x74>
			altflag = 1;
			goto reswitch;

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
				width = precision, precision = -1;
  800355:	8b 45 d0             	mov    -0x30(%ebp),%eax
  800358:	89 45 dc             	mov    %eax,-0x24(%ebp)
  80035b:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800362:	8d 5e 01             	lea    0x1(%esi),%ebx
  800365:	0f b6 16             	movzbl (%esi),%edx
  800368:	0f b6 c2             	movzbl %dl,%eax
  80036b:	83 ea 23             	sub    $0x23,%edx
  80036e:	80 fa 55             	cmp    $0x55,%dl
  800371:	0f 87 37 03 00 00    	ja     8006ae <vprintfmt+0x3c0>
  800377:	0f b6 d2             	movzbl %dl,%edx
  80037a:	ff 24 95 40 0f 80 00 	jmp    *0x800f40(,%edx,4)
  800381:	89 de                	mov    %ebx,%esi
  800383:	89 ca                	mov    %ecx,%edx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
  800385:	8d 14 92             	lea    (%edx,%edx,4),%edx
  800388:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
  80038c:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
  80038f:	8d 58 d0             	lea    -0x30(%eax),%ebx
  800392:	83 fb 09             	cmp    $0x9,%ebx
  800395:	77 31                	ja     8003c8 <vprintfmt+0xda>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
  800397:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
  80039a:	eb e9                	jmp    800385 <vprintfmt+0x97>
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
  80039c:	8b 45 14             	mov    0x14(%ebp),%eax
  80039f:	8d 50 04             	lea    0x4(%eax),%edx
  8003a2:	89 55 14             	mov    %edx,0x14(%ebp)
  8003a5:	8b 00                	mov    (%eax),%eax
  8003a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  8003aa:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
  8003ac:	eb 1d                	jmp    8003cb <vprintfmt+0xdd>
  8003ae:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8003b1:	85 c0                	test   %eax,%eax
  8003b3:	0f 48 c1             	cmovs  %ecx,%eax
  8003b6:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  8003b9:	89 de                	mov    %ebx,%esi
  8003bb:	eb a5                	jmp    800362 <vprintfmt+0x74>
  8003bd:	89 de                	mov    %ebx,%esi
			if (width < 0)									//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;			
			goto reswitch;

		case '#':
			altflag = 1;
  8003bf:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
  8003c6:	eb 9a                	jmp    800362 <vprintfmt+0x74>
  8003c8:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
  8003cb:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
  8003cf:	79 91                	jns    800362 <vprintfmt+0x74>
  8003d1:	eb 82                	jmp    800355 <vprintfmt+0x67>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
  8003d3:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  8003d7:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
			goto reswitch;
  8003d9:	eb 87                	jmp    800362 <vprintfmt+0x74>

		// character
		case 'c':											//如果是'c'代表显示一个字符
			putch(va_arg(ap, int), putdat);					//调用输出一个字符到内存的函数putch
  8003db:	8b 45 14             	mov    0x14(%ebp),%eax
  8003de:	8d 50 04             	lea    0x4(%eax),%edx
  8003e1:	89 55 14             	mov    %edx,0x14(%ebp)
  8003e4:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8003e8:	8b 00                	mov    (%eax),%eax
  8003ea:	89 04 24             	mov    %eax,(%esp)
  8003ed:	ff 55 08             	call   *0x8(%ebp)
			break;
  8003f0:	e9 1e ff ff ff       	jmp    800313 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
  8003f5:	8b 45 14             	mov    0x14(%ebp),%eax
  8003f8:	8d 50 04             	lea    0x4(%eax),%edx
  8003fb:	89 55 14             	mov    %edx,0x14(%ebp)
  8003fe:	8b 00                	mov    (%eax),%eax
  800400:	99                   	cltd   
  800401:	31 d0                	xor    %edx,%eax
  800403:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
  800405:	83 f8 07             	cmp    $0x7,%eax
  800408:	7f 0b                	jg     800415 <vprintfmt+0x127>
  80040a:	8b 14 85 a0 10 80 00 	mov    0x8010a0(,%eax,4),%edx
  800411:	85 d2                	test   %edx,%edx
  800413:	75 20                	jne    800435 <vprintfmt+0x147>
				printfmt(putch, putdat, "error %d", err);
  800415:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800419:	c7 44 24 08 c7 0e 80 	movl   $0x800ec7,0x8(%esp)
  800420:	00 
  800421:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800425:	8b 45 08             	mov    0x8(%ebp),%eax
  800428:	89 04 24             	mov    %eax,(%esp)
  80042b:	e8 96 fe ff ff       	call   8002c6 <printfmt>
  800430:	e9 de fe ff ff       	jmp    800313 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
  800435:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800439:	c7 44 24 08 d0 0e 80 	movl   $0x800ed0,0x8(%esp)
  800440:	00 
  800441:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800445:	8b 45 08             	mov    0x8(%ebp),%eax
  800448:	89 04 24             	mov    %eax,(%esp)
  80044b:	e8 76 fe ff ff       	call   8002c6 <printfmt>
  800450:	e9 be fe ff ff       	jmp    800313 <vprintfmt+0x25>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
  800455:	8b 4d d0             	mov    -0x30(%ebp),%ecx
  800458:	8b 45 dc             	mov    -0x24(%ebp),%eax
  80045b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
  80045e:	8b 45 14             	mov    0x14(%ebp),%eax
  800461:	8d 50 04             	lea    0x4(%eax),%edx
  800464:	89 55 14             	mov    %edx,0x14(%ebp)
  800467:	8b 30                	mov    (%eax),%esi
				p = "(null)";
  800469:	85 f6                	test   %esi,%esi
  80046b:	b8 c0 0e 80 00       	mov    $0x800ec0,%eax
  800470:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
  800473:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
  800477:	0f 84 97 00 00 00    	je     800514 <vprintfmt+0x226>
  80047d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  800481:	0f 8e 9b 00 00 00    	jle    800522 <vprintfmt+0x234>
				for (width -= strnlen(p, precision); width > 0; width--)
  800487:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  80048b:	89 34 24             	mov    %esi,(%esp)
  80048e:	e8 e5 02 00 00       	call   800778 <strnlen>
  800493:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  800496:	29 c1                	sub    %eax,%ecx
  800498:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
					putch(padc, putdat);
  80049b:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
  80049f:	89 45 dc             	mov    %eax,-0x24(%ebp)
  8004a2:	89 75 d8             	mov    %esi,-0x28(%ebp)
  8004a5:	8b 75 08             	mov    0x8(%ebp),%esi
  8004a8:	89 5d 10             	mov    %ebx,0x10(%ebp)
  8004ab:	89 cb                	mov    %ecx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004ad:	eb 0f                	jmp    8004be <vprintfmt+0x1d0>
					putch(padc, putdat);
  8004af:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8004b3:	8b 45 dc             	mov    -0x24(%ebp),%eax
  8004b6:	89 04 24             	mov    %eax,(%esp)
  8004b9:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
  8004bb:	83 eb 01             	sub    $0x1,%ebx
  8004be:	85 db                	test   %ebx,%ebx
  8004c0:	7f ed                	jg     8004af <vprintfmt+0x1c1>
  8004c2:	8b 75 d8             	mov    -0x28(%ebp),%esi
  8004c5:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
  8004c8:	85 c9                	test   %ecx,%ecx
  8004ca:	b8 00 00 00 00       	mov    $0x0,%eax
  8004cf:	0f 49 c1             	cmovns %ecx,%eax
  8004d2:	29 c1                	sub    %eax,%ecx
  8004d4:	89 7d 0c             	mov    %edi,0xc(%ebp)
  8004d7:	89 cf                	mov    %ecx,%edi
  8004d9:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  8004dc:	eb 50                	jmp    80052e <vprintfmt+0x240>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
  8004de:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
  8004e2:	74 1e                	je     800502 <vprintfmt+0x214>
  8004e4:	0f be d2             	movsbl %dl,%edx
  8004e7:	83 ea 20             	sub    $0x20,%edx
  8004ea:	83 fa 5e             	cmp    $0x5e,%edx
  8004ed:	76 13                	jbe    800502 <vprintfmt+0x214>
					putch('?', putdat);
  8004ef:	8b 45 0c             	mov    0xc(%ebp),%eax
  8004f2:	89 44 24 04          	mov    %eax,0x4(%esp)
  8004f6:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
  8004fd:	ff 55 08             	call   *0x8(%ebp)
  800500:	eb 0d                	jmp    80050f <vprintfmt+0x221>
				else
					putch(ch, putdat);
  800502:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800505:	89 4c 24 04          	mov    %ecx,0x4(%esp)
  800509:	89 04 24             	mov    %eax,(%esp)
  80050c:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
  80050f:	83 ef 01             	sub    $0x1,%edi
  800512:	eb 1a                	jmp    80052e <vprintfmt+0x240>
  800514:	89 7d 0c             	mov    %edi,0xc(%ebp)
  800517:	8b 7d dc             	mov    -0x24(%ebp),%edi
  80051a:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80051d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  800520:	eb 0c                	jmp    80052e <vprintfmt+0x240>
  800522:	89 7d 0c             	mov    %edi,0xc(%ebp)
  800525:	8b 7d dc             	mov    -0x24(%ebp),%edi
  800528:	89 5d 10             	mov    %ebx,0x10(%ebp)
  80052b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
  80052e:	83 c6 01             	add    $0x1,%esi
  800531:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
  800535:	0f be c2             	movsbl %dl,%eax
  800538:	85 c0                	test   %eax,%eax
  80053a:	74 27                	je     800563 <vprintfmt+0x275>
  80053c:	85 db                	test   %ebx,%ebx
  80053e:	78 9e                	js     8004de <vprintfmt+0x1f0>
  800540:	83 eb 01             	sub    $0x1,%ebx
  800543:	79 99                	jns    8004de <vprintfmt+0x1f0>
  800545:	89 f8                	mov    %edi,%eax
  800547:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80054a:	8b 75 08             	mov    0x8(%ebp),%esi
  80054d:	89 c3                	mov    %eax,%ebx
  80054f:	eb 1a                	jmp    80056b <vprintfmt+0x27d>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
  800551:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800555:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
  80055c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
  80055e:	83 eb 01             	sub    $0x1,%ebx
  800561:	eb 08                	jmp    80056b <vprintfmt+0x27d>
  800563:	89 fb                	mov    %edi,%ebx
  800565:	8b 75 08             	mov    0x8(%ebp),%esi
  800568:	8b 7d 0c             	mov    0xc(%ebp),%edi
  80056b:	85 db                	test   %ebx,%ebx
  80056d:	7f e2                	jg     800551 <vprintfmt+0x263>
  80056f:	89 75 08             	mov    %esi,0x8(%ebp)
  800572:	8b 5d 10             	mov    0x10(%ebp),%ebx
  800575:	e9 99 fd ff ff       	jmp    800313 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
  80057a:	83 7d d4 01          	cmpl   $0x1,-0x2c(%ebp)
  80057e:	7e 16                	jle    800596 <vprintfmt+0x2a8>
		return va_arg(*ap, long long);
  800580:	8b 45 14             	mov    0x14(%ebp),%eax
  800583:	8d 50 08             	lea    0x8(%eax),%edx
  800586:	89 55 14             	mov    %edx,0x14(%ebp)
  800589:	8b 50 04             	mov    0x4(%eax),%edx
  80058c:	8b 00                	mov    (%eax),%eax
  80058e:	89 45 e0             	mov    %eax,-0x20(%ebp)
  800591:	89 55 e4             	mov    %edx,-0x1c(%ebp)
  800594:	eb 34                	jmp    8005ca <vprintfmt+0x2dc>
	else if (lflag)
  800596:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
  80059a:	74 18                	je     8005b4 <vprintfmt+0x2c6>
		return va_arg(*ap, long);
  80059c:	8b 45 14             	mov    0x14(%ebp),%eax
  80059f:	8d 50 04             	lea    0x4(%eax),%edx
  8005a2:	89 55 14             	mov    %edx,0x14(%ebp)
  8005a5:	8b 30                	mov    (%eax),%esi
  8005a7:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8005aa:	89 f0                	mov    %esi,%eax
  8005ac:	c1 f8 1f             	sar    $0x1f,%eax
  8005af:	89 45 e4             	mov    %eax,-0x1c(%ebp)
  8005b2:	eb 16                	jmp    8005ca <vprintfmt+0x2dc>
	else
		return va_arg(*ap, int);
  8005b4:	8b 45 14             	mov    0x14(%ebp),%eax
  8005b7:	8d 50 04             	lea    0x4(%eax),%edx
  8005ba:	89 55 14             	mov    %edx,0x14(%ebp)
  8005bd:	8b 30                	mov    (%eax),%esi
  8005bf:	89 75 e0             	mov    %esi,-0x20(%ebp)
  8005c2:	89 f0                	mov    %esi,%eax
  8005c4:	c1 f8 1f             	sar    $0x1f,%eax
  8005c7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
  8005ca:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005cd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
  8005d0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
  8005d5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
  8005d9:	0f 89 97 00 00 00    	jns    800676 <vprintfmt+0x388>
				putch('-', putdat);
  8005df:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8005e3:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
  8005ea:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
  8005ed:	8b 45 e0             	mov    -0x20(%ebp),%eax
  8005f0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
  8005f3:	f7 d8                	neg    %eax
  8005f5:	83 d2 00             	adc    $0x0,%edx
  8005f8:	f7 da                	neg    %edx
			}
			base = 10;
  8005fa:	b9 0a 00 00 00       	mov    $0xa,%ecx
  8005ff:	eb 75                	jmp    800676 <vprintfmt+0x388>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
  800601:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800604:	8d 45 14             	lea    0x14(%ebp),%eax
  800607:	e8 63 fc ff ff       	call   80026f <getuint>
			base = 10;
  80060c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
  800611:	eb 63                	jmp    800676 <vprintfmt+0x388>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('0', putdat);
  800613:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800617:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80061e:	ff 55 08             	call   *0x8(%ebp)
			num = getuint(&ap, lflag);
  800621:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800624:	8d 45 14             	lea    0x14(%ebp),%eax
  800627:	e8 43 fc ff ff       	call   80026f <getuint>
			base = 8;
  80062c:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
  800631:	eb 43                	jmp    800676 <vprintfmt+0x388>
		// pointer
		case 'p':
			putch('0', putdat);
  800633:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800637:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
  80063e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
  800641:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800645:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
  80064c:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
  80064f:	8b 45 14             	mov    0x14(%ebp),%eax
  800652:	8d 50 04             	lea    0x4(%eax),%edx
  800655:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
  800658:	8b 00                	mov    (%eax),%eax
  80065a:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
  80065f:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
  800664:	eb 10                	jmp    800676 <vprintfmt+0x388>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
  800666:	8b 55 d4             	mov    -0x2c(%ebp),%edx
  800669:	8d 45 14             	lea    0x14(%ebp),%eax
  80066c:	e8 fe fb ff ff       	call   80026f <getuint>
			base = 16;
  800671:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
  800676:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
  80067a:	89 74 24 10          	mov    %esi,0x10(%esp)
  80067e:	8b 75 dc             	mov    -0x24(%ebp),%esi
  800681:	89 74 24 0c          	mov    %esi,0xc(%esp)
  800685:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800689:	89 04 24             	mov    %eax,(%esp)
  80068c:	89 54 24 04          	mov    %edx,0x4(%esp)
  800690:	89 fa                	mov    %edi,%edx
  800692:	8b 45 08             	mov    0x8(%ebp),%eax
  800695:	e8 e6 fa ff ff       	call   800180 <printnum>
			break;
  80069a:	e9 74 fc ff ff       	jmp    800313 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
  80069f:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006a3:	89 04 24             	mov    %eax,(%esp)
  8006a6:	ff 55 08             	call   *0x8(%ebp)
			break;
  8006a9:	e9 65 fc ff ff       	jmp    800313 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
  8006ae:	89 7c 24 04          	mov    %edi,0x4(%esp)
  8006b2:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
  8006b9:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
  8006bc:	89 f3                	mov    %esi,%ebx
  8006be:	eb 03                	jmp    8006c3 <vprintfmt+0x3d5>
  8006c0:	83 eb 01             	sub    $0x1,%ebx
  8006c3:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
  8006c7:	75 f7                	jne    8006c0 <vprintfmt+0x3d2>
  8006c9:	e9 45 fc ff ff       	jmp    800313 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
  8006ce:	83 c4 3c             	add    $0x3c,%esp
  8006d1:	5b                   	pop    %ebx
  8006d2:	5e                   	pop    %esi
  8006d3:	5f                   	pop    %edi
  8006d4:	5d                   	pop    %ebp
  8006d5:	c3                   	ret    

008006d6 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
  8006d6:	55                   	push   %ebp
  8006d7:	89 e5                	mov    %esp,%ebp
  8006d9:	83 ec 28             	sub    $0x28,%esp
  8006dc:	8b 45 08             	mov    0x8(%ebp),%eax
  8006df:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
  8006e2:	89 45 ec             	mov    %eax,-0x14(%ebp)
  8006e5:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
  8006e9:	89 4d f0             	mov    %ecx,-0x10(%ebp)
  8006ec:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
  8006f3:	85 c0                	test   %eax,%eax
  8006f5:	74 30                	je     800727 <vsnprintf+0x51>
  8006f7:	85 d2                	test   %edx,%edx
  8006f9:	7e 2c                	jle    800727 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
  8006fb:	8b 45 14             	mov    0x14(%ebp),%eax
  8006fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
  800702:	8b 45 10             	mov    0x10(%ebp),%eax
  800705:	89 44 24 08          	mov    %eax,0x8(%esp)
  800709:	8d 45 ec             	lea    -0x14(%ebp),%eax
  80070c:	89 44 24 04          	mov    %eax,0x4(%esp)
  800710:	c7 04 24 a9 02 80 00 	movl   $0x8002a9,(%esp)
  800717:	e8 d2 fb ff ff       	call   8002ee <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
  80071c:	8b 45 ec             	mov    -0x14(%ebp),%eax
  80071f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
  800722:	8b 45 f4             	mov    -0xc(%ebp),%eax
  800725:	eb 05                	jmp    80072c <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
  800727:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
  80072c:	c9                   	leave  
  80072d:	c3                   	ret    

0080072e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
  80072e:	55                   	push   %ebp
  80072f:	89 e5                	mov    %esp,%ebp
  800731:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
  800734:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
  800737:	89 44 24 0c          	mov    %eax,0xc(%esp)
  80073b:	8b 45 10             	mov    0x10(%ebp),%eax
  80073e:	89 44 24 08          	mov    %eax,0x8(%esp)
  800742:	8b 45 0c             	mov    0xc(%ebp),%eax
  800745:	89 44 24 04          	mov    %eax,0x4(%esp)
  800749:	8b 45 08             	mov    0x8(%ebp),%eax
  80074c:	89 04 24             	mov    %eax,(%esp)
  80074f:	e8 82 ff ff ff       	call   8006d6 <vsnprintf>
	va_end(ap);

	return rc;
}
  800754:	c9                   	leave  
  800755:	c3                   	ret    
  800756:	66 90                	xchg   %ax,%ax
  800758:	66 90                	xchg   %ax,%ax
  80075a:	66 90                	xchg   %ax,%ax
  80075c:	66 90                	xchg   %ax,%ax
  80075e:	66 90                	xchg   %ax,%ax

00800760 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
  800760:	55                   	push   %ebp
  800761:	89 e5                	mov    %esp,%ebp
  800763:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
  800766:	b8 00 00 00 00       	mov    $0x0,%eax
  80076b:	eb 03                	jmp    800770 <strlen+0x10>
		n++;
  80076d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
  800770:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
  800774:	75 f7                	jne    80076d <strlen+0xd>
		n++;
	return n;
}
  800776:	5d                   	pop    %ebp
  800777:	c3                   	ret    

00800778 <strnlen>:

int
strnlen(const char *s, size_t size)
{
  800778:	55                   	push   %ebp
  800779:	89 e5                	mov    %esp,%ebp
  80077b:	8b 4d 08             	mov    0x8(%ebp),%ecx
  80077e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  800781:	b8 00 00 00 00       	mov    $0x0,%eax
  800786:	eb 03                	jmp    80078b <strnlen+0x13>
		n++;
  800788:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
  80078b:	39 d0                	cmp    %edx,%eax
  80078d:	74 06                	je     800795 <strnlen+0x1d>
  80078f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
  800793:	75 f3                	jne    800788 <strnlen+0x10>
		n++;
	return n;
}
  800795:	5d                   	pop    %ebp
  800796:	c3                   	ret    

00800797 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
  800797:	55                   	push   %ebp
  800798:	89 e5                	mov    %esp,%ebp
  80079a:	53                   	push   %ebx
  80079b:	8b 45 08             	mov    0x8(%ebp),%eax
  80079e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
  8007a1:	89 c2                	mov    %eax,%edx
  8007a3:	83 c2 01             	add    $0x1,%edx
  8007a6:	83 c1 01             	add    $0x1,%ecx
  8007a9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
  8007ad:	88 5a ff             	mov    %bl,-0x1(%edx)
  8007b0:	84 db                	test   %bl,%bl
  8007b2:	75 ef                	jne    8007a3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
  8007b4:	5b                   	pop    %ebx
  8007b5:	5d                   	pop    %ebp
  8007b6:	c3                   	ret    

008007b7 <strcat>:

char *
strcat(char *dst, const char *src)
{
  8007b7:	55                   	push   %ebp
  8007b8:	89 e5                	mov    %esp,%ebp
  8007ba:	53                   	push   %ebx
  8007bb:	83 ec 08             	sub    $0x8,%esp
  8007be:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
  8007c1:	89 1c 24             	mov    %ebx,(%esp)
  8007c4:	e8 97 ff ff ff       	call   800760 <strlen>
	strcpy(dst + len, src);
  8007c9:	8b 55 0c             	mov    0xc(%ebp),%edx
  8007cc:	89 54 24 04          	mov    %edx,0x4(%esp)
  8007d0:	01 d8                	add    %ebx,%eax
  8007d2:	89 04 24             	mov    %eax,(%esp)
  8007d5:	e8 bd ff ff ff       	call   800797 <strcpy>
	return dst;
}
  8007da:	89 d8                	mov    %ebx,%eax
  8007dc:	83 c4 08             	add    $0x8,%esp
  8007df:	5b                   	pop    %ebx
  8007e0:	5d                   	pop    %ebp
  8007e1:	c3                   	ret    

008007e2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
  8007e2:	55                   	push   %ebp
  8007e3:	89 e5                	mov    %esp,%ebp
  8007e5:	56                   	push   %esi
  8007e6:	53                   	push   %ebx
  8007e7:	8b 75 08             	mov    0x8(%ebp),%esi
  8007ea:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8007ed:	89 f3                	mov    %esi,%ebx
  8007ef:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  8007f2:	89 f2                	mov    %esi,%edx
  8007f4:	eb 0f                	jmp    800805 <strncpy+0x23>
		*dst++ = *src;
  8007f6:	83 c2 01             	add    $0x1,%edx
  8007f9:	0f b6 01             	movzbl (%ecx),%eax
  8007fc:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
  8007ff:	80 39 01             	cmpb   $0x1,(%ecx)
  800802:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
  800805:	39 da                	cmp    %ebx,%edx
  800807:	75 ed                	jne    8007f6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
  800809:	89 f0                	mov    %esi,%eax
  80080b:	5b                   	pop    %ebx
  80080c:	5e                   	pop    %esi
  80080d:	5d                   	pop    %ebp
  80080e:	c3                   	ret    

0080080f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
  80080f:	55                   	push   %ebp
  800810:	89 e5                	mov    %esp,%ebp
  800812:	56                   	push   %esi
  800813:	53                   	push   %ebx
  800814:	8b 75 08             	mov    0x8(%ebp),%esi
  800817:	8b 55 0c             	mov    0xc(%ebp),%edx
  80081a:	8b 4d 10             	mov    0x10(%ebp),%ecx
  80081d:	89 f0                	mov    %esi,%eax
  80081f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
  800823:	85 c9                	test   %ecx,%ecx
  800825:	75 0b                	jne    800832 <strlcpy+0x23>
  800827:	eb 1d                	jmp    800846 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
  800829:	83 c0 01             	add    $0x1,%eax
  80082c:	83 c2 01             	add    $0x1,%edx
  80082f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
  800832:	39 d8                	cmp    %ebx,%eax
  800834:	74 0b                	je     800841 <strlcpy+0x32>
  800836:	0f b6 0a             	movzbl (%edx),%ecx
  800839:	84 c9                	test   %cl,%cl
  80083b:	75 ec                	jne    800829 <strlcpy+0x1a>
  80083d:	89 c2                	mov    %eax,%edx
  80083f:	eb 02                	jmp    800843 <strlcpy+0x34>
  800841:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
  800843:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
  800846:	29 f0                	sub    %esi,%eax
}
  800848:	5b                   	pop    %ebx
  800849:	5e                   	pop    %esi
  80084a:	5d                   	pop    %ebp
  80084b:	c3                   	ret    

0080084c <strcmp>:

int
strcmp(const char *p, const char *q)
{
  80084c:	55                   	push   %ebp
  80084d:	89 e5                	mov    %esp,%ebp
  80084f:	8b 4d 08             	mov    0x8(%ebp),%ecx
  800852:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
  800855:	eb 06                	jmp    80085d <strcmp+0x11>
		p++, q++;
  800857:	83 c1 01             	add    $0x1,%ecx
  80085a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
  80085d:	0f b6 01             	movzbl (%ecx),%eax
  800860:	84 c0                	test   %al,%al
  800862:	74 04                	je     800868 <strcmp+0x1c>
  800864:	3a 02                	cmp    (%edx),%al
  800866:	74 ef                	je     800857 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
  800868:	0f b6 c0             	movzbl %al,%eax
  80086b:	0f b6 12             	movzbl (%edx),%edx
  80086e:	29 d0                	sub    %edx,%eax
}
  800870:	5d                   	pop    %ebp
  800871:	c3                   	ret    

00800872 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
  800872:	55                   	push   %ebp
  800873:	89 e5                	mov    %esp,%ebp
  800875:	53                   	push   %ebx
  800876:	8b 45 08             	mov    0x8(%ebp),%eax
  800879:	8b 55 0c             	mov    0xc(%ebp),%edx
  80087c:	89 c3                	mov    %eax,%ebx
  80087e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
  800881:	eb 06                	jmp    800889 <strncmp+0x17>
		n--, p++, q++;
  800883:	83 c0 01             	add    $0x1,%eax
  800886:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
  800889:	39 d8                	cmp    %ebx,%eax
  80088b:	74 15                	je     8008a2 <strncmp+0x30>
  80088d:	0f b6 08             	movzbl (%eax),%ecx
  800890:	84 c9                	test   %cl,%cl
  800892:	74 04                	je     800898 <strncmp+0x26>
  800894:	3a 0a                	cmp    (%edx),%cl
  800896:	74 eb                	je     800883 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
  800898:	0f b6 00             	movzbl (%eax),%eax
  80089b:	0f b6 12             	movzbl (%edx),%edx
  80089e:	29 d0                	sub    %edx,%eax
  8008a0:	eb 05                	jmp    8008a7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
  8008a2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
  8008a7:	5b                   	pop    %ebx
  8008a8:	5d                   	pop    %ebp
  8008a9:	c3                   	ret    

008008aa <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
  8008aa:	55                   	push   %ebp
  8008ab:	89 e5                	mov    %esp,%ebp
  8008ad:	8b 45 08             	mov    0x8(%ebp),%eax
  8008b0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008b4:	eb 07                	jmp    8008bd <strchr+0x13>
		if (*s == c)
  8008b6:	38 ca                	cmp    %cl,%dl
  8008b8:	74 0f                	je     8008c9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
  8008ba:	83 c0 01             	add    $0x1,%eax
  8008bd:	0f b6 10             	movzbl (%eax),%edx
  8008c0:	84 d2                	test   %dl,%dl
  8008c2:	75 f2                	jne    8008b6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
  8008c4:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8008c9:	5d                   	pop    %ebp
  8008ca:	c3                   	ret    

008008cb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
  8008cb:	55                   	push   %ebp
  8008cc:	89 e5                	mov    %esp,%ebp
  8008ce:	8b 45 08             	mov    0x8(%ebp),%eax
  8008d1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
  8008d5:	eb 07                	jmp    8008de <strfind+0x13>
		if (*s == c)
  8008d7:	38 ca                	cmp    %cl,%dl
  8008d9:	74 0a                	je     8008e5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
  8008db:	83 c0 01             	add    $0x1,%eax
  8008de:	0f b6 10             	movzbl (%eax),%edx
  8008e1:	84 d2                	test   %dl,%dl
  8008e3:	75 f2                	jne    8008d7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
  8008e5:	5d                   	pop    %ebp
  8008e6:	c3                   	ret    

008008e7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
  8008e7:	55                   	push   %ebp
  8008e8:	89 e5                	mov    %esp,%ebp
  8008ea:	57                   	push   %edi
  8008eb:	56                   	push   %esi
  8008ec:	53                   	push   %ebx
  8008ed:	8b 7d 08             	mov    0x8(%ebp),%edi
  8008f0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
  8008f3:	85 c9                	test   %ecx,%ecx
  8008f5:	74 36                	je     80092d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
  8008f7:	f7 c7 03 00 00 00    	test   $0x3,%edi
  8008fd:	75 28                	jne    800927 <memset+0x40>
  8008ff:	f6 c1 03             	test   $0x3,%cl
  800902:	75 23                	jne    800927 <memset+0x40>
		c &= 0xFF;
  800904:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
  800908:	89 d3                	mov    %edx,%ebx
  80090a:	c1 e3 08             	shl    $0x8,%ebx
  80090d:	89 d6                	mov    %edx,%esi
  80090f:	c1 e6 18             	shl    $0x18,%esi
  800912:	89 d0                	mov    %edx,%eax
  800914:	c1 e0 10             	shl    $0x10,%eax
  800917:	09 f0                	or     %esi,%eax
  800919:	09 c2                	or     %eax,%edx
  80091b:	89 d0                	mov    %edx,%eax
  80091d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
  80091f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
  800922:	fc                   	cld    
  800923:	f3 ab                	rep stos %eax,%es:(%edi)
  800925:	eb 06                	jmp    80092d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
  800927:	8b 45 0c             	mov    0xc(%ebp),%eax
  80092a:	fc                   	cld    
  80092b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
  80092d:	89 f8                	mov    %edi,%eax
  80092f:	5b                   	pop    %ebx
  800930:	5e                   	pop    %esi
  800931:	5f                   	pop    %edi
  800932:	5d                   	pop    %ebp
  800933:	c3                   	ret    

00800934 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
  800934:	55                   	push   %ebp
  800935:	89 e5                	mov    %esp,%ebp
  800937:	57                   	push   %edi
  800938:	56                   	push   %esi
  800939:	8b 45 08             	mov    0x8(%ebp),%eax
  80093c:	8b 75 0c             	mov    0xc(%ebp),%esi
  80093f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
  800942:	39 c6                	cmp    %eax,%esi
  800944:	73 35                	jae    80097b <memmove+0x47>
  800946:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
  800949:	39 d0                	cmp    %edx,%eax
  80094b:	73 2e                	jae    80097b <memmove+0x47>
		s += n;
		d += n;
  80094d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
  800950:	89 d6                	mov    %edx,%esi
  800952:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  800954:	f7 c6 03 00 00 00    	test   $0x3,%esi
  80095a:	75 13                	jne    80096f <memmove+0x3b>
  80095c:	f6 c1 03             	test   $0x3,%cl
  80095f:	75 0e                	jne    80096f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
  800961:	83 ef 04             	sub    $0x4,%edi
  800964:	8d 72 fc             	lea    -0x4(%edx),%esi
  800967:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
  80096a:	fd                   	std    
  80096b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  80096d:	eb 09                	jmp    800978 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
  80096f:	83 ef 01             	sub    $0x1,%edi
  800972:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
  800975:	fd                   	std    
  800976:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
  800978:	fc                   	cld    
  800979:	eb 1d                	jmp    800998 <memmove+0x64>
  80097b:	89 f2                	mov    %esi,%edx
  80097d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
  80097f:	f6 c2 03             	test   $0x3,%dl
  800982:	75 0f                	jne    800993 <memmove+0x5f>
  800984:	f6 c1 03             	test   $0x3,%cl
  800987:	75 0a                	jne    800993 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
  800989:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
  80098c:	89 c7                	mov    %eax,%edi
  80098e:	fc                   	cld    
  80098f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
  800991:	eb 05                	jmp    800998 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
  800993:	89 c7                	mov    %eax,%edi
  800995:	fc                   	cld    
  800996:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
  800998:	5e                   	pop    %esi
  800999:	5f                   	pop    %edi
  80099a:	5d                   	pop    %ebp
  80099b:	c3                   	ret    

0080099c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
  80099c:	55                   	push   %ebp
  80099d:	89 e5                	mov    %esp,%ebp
  80099f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
  8009a2:	8b 45 10             	mov    0x10(%ebp),%eax
  8009a5:	89 44 24 08          	mov    %eax,0x8(%esp)
  8009a9:	8b 45 0c             	mov    0xc(%ebp),%eax
  8009ac:	89 44 24 04          	mov    %eax,0x4(%esp)
  8009b0:	8b 45 08             	mov    0x8(%ebp),%eax
  8009b3:	89 04 24             	mov    %eax,(%esp)
  8009b6:	e8 79 ff ff ff       	call   800934 <memmove>
}
  8009bb:	c9                   	leave  
  8009bc:	c3                   	ret    

008009bd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
  8009bd:	55                   	push   %ebp
  8009be:	89 e5                	mov    %esp,%ebp
  8009c0:	56                   	push   %esi
  8009c1:	53                   	push   %ebx
  8009c2:	8b 55 08             	mov    0x8(%ebp),%edx
  8009c5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  8009c8:	89 d6                	mov    %edx,%esi
  8009ca:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009cd:	eb 1a                	jmp    8009e9 <memcmp+0x2c>
		if (*s1 != *s2)
  8009cf:	0f b6 02             	movzbl (%edx),%eax
  8009d2:	0f b6 19             	movzbl (%ecx),%ebx
  8009d5:	38 d8                	cmp    %bl,%al
  8009d7:	74 0a                	je     8009e3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
  8009d9:	0f b6 c0             	movzbl %al,%eax
  8009dc:	0f b6 db             	movzbl %bl,%ebx
  8009df:	29 d8                	sub    %ebx,%eax
  8009e1:	eb 0f                	jmp    8009f2 <memcmp+0x35>
		s1++, s2++;
  8009e3:	83 c2 01             	add    $0x1,%edx
  8009e6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
  8009e9:	39 f2                	cmp    %esi,%edx
  8009eb:	75 e2                	jne    8009cf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
  8009ed:	b8 00 00 00 00       	mov    $0x0,%eax
}
  8009f2:	5b                   	pop    %ebx
  8009f3:	5e                   	pop    %esi
  8009f4:	5d                   	pop    %ebp
  8009f5:	c3                   	ret    

008009f6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
  8009f6:	55                   	push   %ebp
  8009f7:	89 e5                	mov    %esp,%ebp
  8009f9:	8b 45 08             	mov    0x8(%ebp),%eax
  8009fc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
  8009ff:	89 c2                	mov    %eax,%edx
  800a01:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
  800a04:	eb 07                	jmp    800a0d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
  800a06:	38 08                	cmp    %cl,(%eax)
  800a08:	74 07                	je     800a11 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
  800a0a:	83 c0 01             	add    $0x1,%eax
  800a0d:	39 d0                	cmp    %edx,%eax
  800a0f:	72 f5                	jb     800a06 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
  800a11:	5d                   	pop    %ebp
  800a12:	c3                   	ret    

00800a13 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
  800a13:	55                   	push   %ebp
  800a14:	89 e5                	mov    %esp,%ebp
  800a16:	57                   	push   %edi
  800a17:	56                   	push   %esi
  800a18:	53                   	push   %ebx
  800a19:	8b 55 08             	mov    0x8(%ebp),%edx
  800a1c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a1f:	eb 03                	jmp    800a24 <strtol+0x11>
		s++;
  800a21:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
  800a24:	0f b6 0a             	movzbl (%edx),%ecx
  800a27:	80 f9 09             	cmp    $0x9,%cl
  800a2a:	74 f5                	je     800a21 <strtol+0xe>
  800a2c:	80 f9 20             	cmp    $0x20,%cl
  800a2f:	74 f0                	je     800a21 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
  800a31:	80 f9 2b             	cmp    $0x2b,%cl
  800a34:	75 0a                	jne    800a40 <strtol+0x2d>
		s++;
  800a36:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
  800a39:	bf 00 00 00 00       	mov    $0x0,%edi
  800a3e:	eb 11                	jmp    800a51 <strtol+0x3e>
  800a40:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
  800a45:	80 f9 2d             	cmp    $0x2d,%cl
  800a48:	75 07                	jne    800a51 <strtol+0x3e>
		s++, neg = 1;
  800a4a:	8d 52 01             	lea    0x1(%edx),%edx
  800a4d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
  800a51:	a9 ef ff ff ff       	test   $0xffffffef,%eax
  800a56:	75 15                	jne    800a6d <strtol+0x5a>
  800a58:	80 3a 30             	cmpb   $0x30,(%edx)
  800a5b:	75 10                	jne    800a6d <strtol+0x5a>
  800a5d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
  800a61:	75 0a                	jne    800a6d <strtol+0x5a>
		s += 2, base = 16;
  800a63:	83 c2 02             	add    $0x2,%edx
  800a66:	b8 10 00 00 00       	mov    $0x10,%eax
  800a6b:	eb 10                	jmp    800a7d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
  800a6d:	85 c0                	test   %eax,%eax
  800a6f:	75 0c                	jne    800a7d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
  800a71:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
  800a73:	80 3a 30             	cmpb   $0x30,(%edx)
  800a76:	75 05                	jne    800a7d <strtol+0x6a>
		s++, base = 8;
  800a78:	83 c2 01             	add    $0x1,%edx
  800a7b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
  800a7d:	bb 00 00 00 00       	mov    $0x0,%ebx
  800a82:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
  800a85:	0f b6 0a             	movzbl (%edx),%ecx
  800a88:	8d 71 d0             	lea    -0x30(%ecx),%esi
  800a8b:	89 f0                	mov    %esi,%eax
  800a8d:	3c 09                	cmp    $0x9,%al
  800a8f:	77 08                	ja     800a99 <strtol+0x86>
			dig = *s - '0';
  800a91:	0f be c9             	movsbl %cl,%ecx
  800a94:	83 e9 30             	sub    $0x30,%ecx
  800a97:	eb 20                	jmp    800ab9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
  800a99:	8d 71 9f             	lea    -0x61(%ecx),%esi
  800a9c:	89 f0                	mov    %esi,%eax
  800a9e:	3c 19                	cmp    $0x19,%al
  800aa0:	77 08                	ja     800aaa <strtol+0x97>
			dig = *s - 'a' + 10;
  800aa2:	0f be c9             	movsbl %cl,%ecx
  800aa5:	83 e9 57             	sub    $0x57,%ecx
  800aa8:	eb 0f                	jmp    800ab9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
  800aaa:	8d 71 bf             	lea    -0x41(%ecx),%esi
  800aad:	89 f0                	mov    %esi,%eax
  800aaf:	3c 19                	cmp    $0x19,%al
  800ab1:	77 16                	ja     800ac9 <strtol+0xb6>
			dig = *s - 'A' + 10;
  800ab3:	0f be c9             	movsbl %cl,%ecx
  800ab6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
  800ab9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
  800abc:	7d 0f                	jge    800acd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
  800abe:	83 c2 01             	add    $0x1,%edx
  800ac1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
  800ac5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
  800ac7:	eb bc                	jmp    800a85 <strtol+0x72>
  800ac9:	89 d8                	mov    %ebx,%eax
  800acb:	eb 02                	jmp    800acf <strtol+0xbc>
  800acd:	89 d8                	mov    %ebx,%eax

	if (endptr)
  800acf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
  800ad3:	74 05                	je     800ada <strtol+0xc7>
		*endptr = (char *) s;
  800ad5:	8b 75 0c             	mov    0xc(%ebp),%esi
  800ad8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
  800ada:	f7 d8                	neg    %eax
  800adc:	85 ff                	test   %edi,%edi
  800ade:	0f 44 c3             	cmove  %ebx,%eax
}
  800ae1:	5b                   	pop    %ebx
  800ae2:	5e                   	pop    %esi
  800ae3:	5f                   	pop    %edi
  800ae4:	5d                   	pop    %ebp
  800ae5:	c3                   	ret    

00800ae6 <sys_cputs>:
	return ret;
}

void
sys_cputs(const char *s, size_t len)
{
  800ae6:	55                   	push   %ebp
  800ae7:	89 e5                	mov    %esp,%ebp
  800ae9:	57                   	push   %edi
  800aea:	56                   	push   %esi
  800aeb:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800aec:	b8 00 00 00 00       	mov    $0x0,%eax
  800af1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
  800af4:	8b 55 08             	mov    0x8(%ebp),%edx
  800af7:	89 c3                	mov    %eax,%ebx
  800af9:	89 c7                	mov    %eax,%edi
  800afb:	89 c6                	mov    %eax,%esi
  800afd:	cd 30                	int    $0x30

void
sys_cputs(const char *s, size_t len)
{
	syscall(SYS_cputs, 0, (uint32_t)s, len, 0, 0, 0);
}
  800aff:	5b                   	pop    %ebx
  800b00:	5e                   	pop    %esi
  800b01:	5f                   	pop    %edi
  800b02:	5d                   	pop    %ebp
  800b03:	c3                   	ret    

00800b04 <sys_cgetc>:

int
sys_cgetc(void)
{
  800b04:	55                   	push   %ebp
  800b05:	89 e5                	mov    %esp,%ebp
  800b07:	57                   	push   %edi
  800b08:	56                   	push   %esi
  800b09:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b0a:	ba 00 00 00 00       	mov    $0x0,%edx
  800b0f:	b8 01 00 00 00       	mov    $0x1,%eax
  800b14:	89 d1                	mov    %edx,%ecx
  800b16:	89 d3                	mov    %edx,%ebx
  800b18:	89 d7                	mov    %edx,%edi
  800b1a:	89 d6                	mov    %edx,%esi
  800b1c:	cd 30                	int    $0x30

int
sys_cgetc(void)
{
	return syscall(SYS_cgetc, 0, 0, 0, 0, 0, 0);
}
  800b1e:	5b                   	pop    %ebx
  800b1f:	5e                   	pop    %esi
  800b20:	5f                   	pop    %edi
  800b21:	5d                   	pop    %ebp
  800b22:	c3                   	ret    

00800b23 <sys_env_destroy>:

int
sys_env_destroy(envid_t envid)
{
  800b23:	55                   	push   %ebp
  800b24:	89 e5                	mov    %esp,%ebp
  800b26:	57                   	push   %edi
  800b27:	56                   	push   %esi
  800b28:	53                   	push   %ebx
  800b29:	83 ec 2c             	sub    $0x2c,%esp
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b2c:	b9 00 00 00 00       	mov    $0x0,%ecx
  800b31:	b8 03 00 00 00       	mov    $0x3,%eax
  800b36:	8b 55 08             	mov    0x8(%ebp),%edx
  800b39:	89 cb                	mov    %ecx,%ebx
  800b3b:	89 cf                	mov    %ecx,%edi
  800b3d:	89 ce                	mov    %ecx,%esi
  800b3f:	cd 30                	int    $0x30
		  "b" (a3),
		  "D" (a4),
		  "S" (a5)
		: "cc", "memory");

	if(check && ret > 0)
  800b41:	85 c0                	test   %eax,%eax
  800b43:	7e 28                	jle    800b6d <sys_env_destroy+0x4a>
		panic("syscall %d returned %d (> 0)", num, ret);
  800b45:	89 44 24 10          	mov    %eax,0x10(%esp)
  800b49:	c7 44 24 0c 03 00 00 	movl   $0x3,0xc(%esp)
  800b50:	00 
  800b51:	c7 44 24 08 c0 10 80 	movl   $0x8010c0,0x8(%esp)
  800b58:	00 
  800b59:	c7 44 24 04 23 00 00 	movl   $0x23,0x4(%esp)
  800b60:	00 
  800b61:	c7 04 24 dd 10 80 00 	movl   $0x8010dd,(%esp)
  800b68:	e8 27 00 00 00       	call   800b94 <_panic>

int
sys_env_destroy(envid_t envid)
{
	return syscall(SYS_env_destroy, 1, envid, 0, 0, 0, 0);
}
  800b6d:	83 c4 2c             	add    $0x2c,%esp
  800b70:	5b                   	pop    %ebx
  800b71:	5e                   	pop    %esi
  800b72:	5f                   	pop    %edi
  800b73:	5d                   	pop    %ebp
  800b74:	c3                   	ret    

00800b75 <sys_getenvid>:

envid_t
sys_getenvid(void)
{
  800b75:	55                   	push   %ebp
  800b76:	89 e5                	mov    %esp,%ebp
  800b78:	57                   	push   %edi
  800b79:	56                   	push   %esi
  800b7a:	53                   	push   %ebx
	//
	// The last clause tells the assembler that this can
	// potentially change the condition codes and arbitrary
	// memory locations.

	asm volatile("int %1\n"
  800b7b:	ba 00 00 00 00       	mov    $0x0,%edx
  800b80:	b8 02 00 00 00       	mov    $0x2,%eax
  800b85:	89 d1                	mov    %edx,%ecx
  800b87:	89 d3                	mov    %edx,%ebx
  800b89:	89 d7                	mov    %edx,%edi
  800b8b:	89 d6                	mov    %edx,%esi
  800b8d:	cd 30                	int    $0x30

envid_t
sys_getenvid(void)
{
	 return syscall(SYS_getenvid, 0, 0, 0, 0, 0, 0);
}
  800b8f:	5b                   	pop    %ebx
  800b90:	5e                   	pop    %esi
  800b91:	5f                   	pop    %edi
  800b92:	5d                   	pop    %ebp
  800b93:	c3                   	ret    

00800b94 <_panic>:
 * It prints "panic: <message>", then causes a breakpoint exception,
 * which causes JOS to enter the JOS kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt, ...)
{
  800b94:	55                   	push   %ebp
  800b95:	89 e5                	mov    %esp,%ebp
  800b97:	56                   	push   %esi
  800b98:	53                   	push   %ebx
  800b99:	83 ec 20             	sub    $0x20,%esp
	va_list ap;

	va_start(ap, fmt);
  800b9c:	8d 5d 14             	lea    0x14(%ebp),%ebx

	// Print the panic message
	cprintf("[%08x] user panic in %s at %s:%d: ",
  800b9f:	8b 35 00 20 80 00    	mov    0x802000,%esi
  800ba5:	e8 cb ff ff ff       	call   800b75 <sys_getenvid>
  800baa:	8b 55 0c             	mov    0xc(%ebp),%edx
  800bad:	89 54 24 10          	mov    %edx,0x10(%esp)
  800bb1:	8b 55 08             	mov    0x8(%ebp),%edx
  800bb4:	89 54 24 0c          	mov    %edx,0xc(%esp)
  800bb8:	89 74 24 08          	mov    %esi,0x8(%esp)
  800bbc:	89 44 24 04          	mov    %eax,0x4(%esp)
  800bc0:	c7 04 24 ec 10 80 00 	movl   $0x8010ec,(%esp)
  800bc7:	e8 95 f5 ff ff       	call   800161 <cprintf>
		sys_getenvid(), binaryname, file, line);
	vcprintf(fmt, ap);
  800bcc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
  800bd0:	8b 45 10             	mov    0x10(%ebp),%eax
  800bd3:	89 04 24             	mov    %eax,(%esp)
  800bd6:	e8 25 f5 ff ff       	call   800100 <vcprintf>
	cprintf("\n");
  800bdb:	c7 04 24 8c 0e 80 00 	movl   $0x800e8c,(%esp)
  800be2:	e8 7a f5 ff ff       	call   800161 <cprintf>

	// Cause a breakpoint exception
	while (1)
		asm volatile("int3");
  800be7:	cc                   	int3   
  800be8:	eb fd                	jmp    800be7 <_panic+0x53>
  800bea:	66 90                	xchg   %ax,%ax
  800bec:	66 90                	xchg   %ax,%ax
  800bee:	66 90                	xchg   %ax,%ax

00800bf0 <__udivdi3>:
  800bf0:	55                   	push   %ebp
  800bf1:	57                   	push   %edi
  800bf2:	56                   	push   %esi
  800bf3:	83 ec 0c             	sub    $0xc,%esp
  800bf6:	8b 44 24 28          	mov    0x28(%esp),%eax
  800bfa:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
  800bfe:	8b 6c 24 20          	mov    0x20(%esp),%ebp
  800c02:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800c06:	85 c0                	test   %eax,%eax
  800c08:	89 7c 24 04          	mov    %edi,0x4(%esp)
  800c0c:	89 ea                	mov    %ebp,%edx
  800c0e:	89 0c 24             	mov    %ecx,(%esp)
  800c11:	75 2d                	jne    800c40 <__udivdi3+0x50>
  800c13:	39 e9                	cmp    %ebp,%ecx
  800c15:	77 61                	ja     800c78 <__udivdi3+0x88>
  800c17:	85 c9                	test   %ecx,%ecx
  800c19:	89 ce                	mov    %ecx,%esi
  800c1b:	75 0b                	jne    800c28 <__udivdi3+0x38>
  800c1d:	b8 01 00 00 00       	mov    $0x1,%eax
  800c22:	31 d2                	xor    %edx,%edx
  800c24:	f7 f1                	div    %ecx
  800c26:	89 c6                	mov    %eax,%esi
  800c28:	31 d2                	xor    %edx,%edx
  800c2a:	89 e8                	mov    %ebp,%eax
  800c2c:	f7 f6                	div    %esi
  800c2e:	89 c5                	mov    %eax,%ebp
  800c30:	89 f8                	mov    %edi,%eax
  800c32:	f7 f6                	div    %esi
  800c34:	89 ea                	mov    %ebp,%edx
  800c36:	83 c4 0c             	add    $0xc,%esp
  800c39:	5e                   	pop    %esi
  800c3a:	5f                   	pop    %edi
  800c3b:	5d                   	pop    %ebp
  800c3c:	c3                   	ret    
  800c3d:	8d 76 00             	lea    0x0(%esi),%esi
  800c40:	39 e8                	cmp    %ebp,%eax
  800c42:	77 24                	ja     800c68 <__udivdi3+0x78>
  800c44:	0f bd e8             	bsr    %eax,%ebp
  800c47:	83 f5 1f             	xor    $0x1f,%ebp
  800c4a:	75 3c                	jne    800c88 <__udivdi3+0x98>
  800c4c:	8b 74 24 04          	mov    0x4(%esp),%esi
  800c50:	39 34 24             	cmp    %esi,(%esp)
  800c53:	0f 86 9f 00 00 00    	jbe    800cf8 <__udivdi3+0x108>
  800c59:	39 d0                	cmp    %edx,%eax
  800c5b:	0f 82 97 00 00 00    	jb     800cf8 <__udivdi3+0x108>
  800c61:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
  800c68:	31 d2                	xor    %edx,%edx
  800c6a:	31 c0                	xor    %eax,%eax
  800c6c:	83 c4 0c             	add    $0xc,%esp
  800c6f:	5e                   	pop    %esi
  800c70:	5f                   	pop    %edi
  800c71:	5d                   	pop    %ebp
  800c72:	c3                   	ret    
  800c73:	90                   	nop
  800c74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800c78:	89 f8                	mov    %edi,%eax
  800c7a:	f7 f1                	div    %ecx
  800c7c:	31 d2                	xor    %edx,%edx
  800c7e:	83 c4 0c             	add    $0xc,%esp
  800c81:	5e                   	pop    %esi
  800c82:	5f                   	pop    %edi
  800c83:	5d                   	pop    %ebp
  800c84:	c3                   	ret    
  800c85:	8d 76 00             	lea    0x0(%esi),%esi
  800c88:	89 e9                	mov    %ebp,%ecx
  800c8a:	8b 3c 24             	mov    (%esp),%edi
  800c8d:	d3 e0                	shl    %cl,%eax
  800c8f:	89 c6                	mov    %eax,%esi
  800c91:	b8 20 00 00 00       	mov    $0x20,%eax
  800c96:	29 e8                	sub    %ebp,%eax
  800c98:	89 c1                	mov    %eax,%ecx
  800c9a:	d3 ef                	shr    %cl,%edi
  800c9c:	89 e9                	mov    %ebp,%ecx
  800c9e:	89 7c 24 08          	mov    %edi,0x8(%esp)
  800ca2:	8b 3c 24             	mov    (%esp),%edi
  800ca5:	09 74 24 08          	or     %esi,0x8(%esp)
  800ca9:	89 d6                	mov    %edx,%esi
  800cab:	d3 e7                	shl    %cl,%edi
  800cad:	89 c1                	mov    %eax,%ecx
  800caf:	89 3c 24             	mov    %edi,(%esp)
  800cb2:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800cb6:	d3 ee                	shr    %cl,%esi
  800cb8:	89 e9                	mov    %ebp,%ecx
  800cba:	d3 e2                	shl    %cl,%edx
  800cbc:	89 c1                	mov    %eax,%ecx
  800cbe:	d3 ef                	shr    %cl,%edi
  800cc0:	09 d7                	or     %edx,%edi
  800cc2:	89 f2                	mov    %esi,%edx
  800cc4:	89 f8                	mov    %edi,%eax
  800cc6:	f7 74 24 08          	divl   0x8(%esp)
  800cca:	89 d6                	mov    %edx,%esi
  800ccc:	89 c7                	mov    %eax,%edi
  800cce:	f7 24 24             	mull   (%esp)
  800cd1:	39 d6                	cmp    %edx,%esi
  800cd3:	89 14 24             	mov    %edx,(%esp)
  800cd6:	72 30                	jb     800d08 <__udivdi3+0x118>
  800cd8:	8b 54 24 04          	mov    0x4(%esp),%edx
  800cdc:	89 e9                	mov    %ebp,%ecx
  800cde:	d3 e2                	shl    %cl,%edx
  800ce0:	39 c2                	cmp    %eax,%edx
  800ce2:	73 05                	jae    800ce9 <__udivdi3+0xf9>
  800ce4:	3b 34 24             	cmp    (%esp),%esi
  800ce7:	74 1f                	je     800d08 <__udivdi3+0x118>
  800ce9:	89 f8                	mov    %edi,%eax
  800ceb:	31 d2                	xor    %edx,%edx
  800ced:	e9 7a ff ff ff       	jmp    800c6c <__udivdi3+0x7c>
  800cf2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
  800cf8:	31 d2                	xor    %edx,%edx
  800cfa:	b8 01 00 00 00       	mov    $0x1,%eax
  800cff:	e9 68 ff ff ff       	jmp    800c6c <__udivdi3+0x7c>
  800d04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800d08:	8d 47 ff             	lea    -0x1(%edi),%eax
  800d0b:	31 d2                	xor    %edx,%edx
  800d0d:	83 c4 0c             	add    $0xc,%esp
  800d10:	5e                   	pop    %esi
  800d11:	5f                   	pop    %edi
  800d12:	5d                   	pop    %ebp
  800d13:	c3                   	ret    
  800d14:	66 90                	xchg   %ax,%ax
  800d16:	66 90                	xchg   %ax,%ax
  800d18:	66 90                	xchg   %ax,%ax
  800d1a:	66 90                	xchg   %ax,%ax
  800d1c:	66 90                	xchg   %ax,%ax
  800d1e:	66 90                	xchg   %ax,%ax

00800d20 <__umoddi3>:
  800d20:	55                   	push   %ebp
  800d21:	57                   	push   %edi
  800d22:	56                   	push   %esi
  800d23:	83 ec 14             	sub    $0x14,%esp
  800d26:	8b 44 24 28          	mov    0x28(%esp),%eax
  800d2a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
  800d2e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
  800d32:	89 c7                	mov    %eax,%edi
  800d34:	89 44 24 04          	mov    %eax,0x4(%esp)
  800d38:	8b 44 24 30          	mov    0x30(%esp),%eax
  800d3c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
  800d40:	89 34 24             	mov    %esi,(%esp)
  800d43:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d47:	85 c0                	test   %eax,%eax
  800d49:	89 c2                	mov    %eax,%edx
  800d4b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d4f:	75 17                	jne    800d68 <__umoddi3+0x48>
  800d51:	39 fe                	cmp    %edi,%esi
  800d53:	76 4b                	jbe    800da0 <__umoddi3+0x80>
  800d55:	89 c8                	mov    %ecx,%eax
  800d57:	89 fa                	mov    %edi,%edx
  800d59:	f7 f6                	div    %esi
  800d5b:	89 d0                	mov    %edx,%eax
  800d5d:	31 d2                	xor    %edx,%edx
  800d5f:	83 c4 14             	add    $0x14,%esp
  800d62:	5e                   	pop    %esi
  800d63:	5f                   	pop    %edi
  800d64:	5d                   	pop    %ebp
  800d65:	c3                   	ret    
  800d66:	66 90                	xchg   %ax,%ax
  800d68:	39 f8                	cmp    %edi,%eax
  800d6a:	77 54                	ja     800dc0 <__umoddi3+0xa0>
  800d6c:	0f bd e8             	bsr    %eax,%ebp
  800d6f:	83 f5 1f             	xor    $0x1f,%ebp
  800d72:	75 5c                	jne    800dd0 <__umoddi3+0xb0>
  800d74:	8b 7c 24 08          	mov    0x8(%esp),%edi
  800d78:	39 3c 24             	cmp    %edi,(%esp)
  800d7b:	0f 87 e7 00 00 00    	ja     800e68 <__umoddi3+0x148>
  800d81:	8b 7c 24 04          	mov    0x4(%esp),%edi
  800d85:	29 f1                	sub    %esi,%ecx
  800d87:	19 c7                	sbb    %eax,%edi
  800d89:	89 4c 24 08          	mov    %ecx,0x8(%esp)
  800d8d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800d91:	8b 44 24 08          	mov    0x8(%esp),%eax
  800d95:	8b 54 24 0c          	mov    0xc(%esp),%edx
  800d99:	83 c4 14             	add    $0x14,%esp
  800d9c:	5e                   	pop    %esi
  800d9d:	5f                   	pop    %edi
  800d9e:	5d                   	pop    %ebp
  800d9f:	c3                   	ret    
  800da0:	85 f6                	test   %esi,%esi
  800da2:	89 f5                	mov    %esi,%ebp
  800da4:	75 0b                	jne    800db1 <__umoddi3+0x91>
  800da6:	b8 01 00 00 00       	mov    $0x1,%eax
  800dab:	31 d2                	xor    %edx,%edx
  800dad:	f7 f6                	div    %esi
  800daf:	89 c5                	mov    %eax,%ebp
  800db1:	8b 44 24 04          	mov    0x4(%esp),%eax
  800db5:	31 d2                	xor    %edx,%edx
  800db7:	f7 f5                	div    %ebp
  800db9:	89 c8                	mov    %ecx,%eax
  800dbb:	f7 f5                	div    %ebp
  800dbd:	eb 9c                	jmp    800d5b <__umoddi3+0x3b>
  800dbf:	90                   	nop
  800dc0:	89 c8                	mov    %ecx,%eax
  800dc2:	89 fa                	mov    %edi,%edx
  800dc4:	83 c4 14             	add    $0x14,%esp
  800dc7:	5e                   	pop    %esi
  800dc8:	5f                   	pop    %edi
  800dc9:	5d                   	pop    %ebp
  800dca:	c3                   	ret    
  800dcb:	90                   	nop
  800dcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800dd0:	8b 04 24             	mov    (%esp),%eax
  800dd3:	be 20 00 00 00       	mov    $0x20,%esi
  800dd8:	89 e9                	mov    %ebp,%ecx
  800dda:	29 ee                	sub    %ebp,%esi
  800ddc:	d3 e2                	shl    %cl,%edx
  800dde:	89 f1                	mov    %esi,%ecx
  800de0:	d3 e8                	shr    %cl,%eax
  800de2:	89 e9                	mov    %ebp,%ecx
  800de4:	89 44 24 04          	mov    %eax,0x4(%esp)
  800de8:	8b 04 24             	mov    (%esp),%eax
  800deb:	09 54 24 04          	or     %edx,0x4(%esp)
  800def:	89 fa                	mov    %edi,%edx
  800df1:	d3 e0                	shl    %cl,%eax
  800df3:	89 f1                	mov    %esi,%ecx
  800df5:	89 44 24 08          	mov    %eax,0x8(%esp)
  800df9:	8b 44 24 10          	mov    0x10(%esp),%eax
  800dfd:	d3 ea                	shr    %cl,%edx
  800dff:	89 e9                	mov    %ebp,%ecx
  800e01:	d3 e7                	shl    %cl,%edi
  800e03:	89 f1                	mov    %esi,%ecx
  800e05:	d3 e8                	shr    %cl,%eax
  800e07:	89 e9                	mov    %ebp,%ecx
  800e09:	09 f8                	or     %edi,%eax
  800e0b:	8b 7c 24 10          	mov    0x10(%esp),%edi
  800e0f:	f7 74 24 04          	divl   0x4(%esp)
  800e13:	d3 e7                	shl    %cl,%edi
  800e15:	89 7c 24 0c          	mov    %edi,0xc(%esp)
  800e19:	89 d7                	mov    %edx,%edi
  800e1b:	f7 64 24 08          	mull   0x8(%esp)
  800e1f:	39 d7                	cmp    %edx,%edi
  800e21:	89 c1                	mov    %eax,%ecx
  800e23:	89 14 24             	mov    %edx,(%esp)
  800e26:	72 2c                	jb     800e54 <__umoddi3+0x134>
  800e28:	39 44 24 0c          	cmp    %eax,0xc(%esp)
  800e2c:	72 22                	jb     800e50 <__umoddi3+0x130>
  800e2e:	8b 44 24 0c          	mov    0xc(%esp),%eax
  800e32:	29 c8                	sub    %ecx,%eax
  800e34:	19 d7                	sbb    %edx,%edi
  800e36:	89 e9                	mov    %ebp,%ecx
  800e38:	89 fa                	mov    %edi,%edx
  800e3a:	d3 e8                	shr    %cl,%eax
  800e3c:	89 f1                	mov    %esi,%ecx
  800e3e:	d3 e2                	shl    %cl,%edx
  800e40:	89 e9                	mov    %ebp,%ecx
  800e42:	d3 ef                	shr    %cl,%edi
  800e44:	09 d0                	or     %edx,%eax
  800e46:	89 fa                	mov    %edi,%edx
  800e48:	83 c4 14             	add    $0x14,%esp
  800e4b:	5e                   	pop    %esi
  800e4c:	5f                   	pop    %edi
  800e4d:	5d                   	pop    %ebp
  800e4e:	c3                   	ret    
  800e4f:	90                   	nop
  800e50:	39 d7                	cmp    %edx,%edi
  800e52:	75 da                	jne    800e2e <__umoddi3+0x10e>
  800e54:	8b 14 24             	mov    (%esp),%edx
  800e57:	89 c1                	mov    %eax,%ecx
  800e59:	2b 4c 24 08          	sub    0x8(%esp),%ecx
  800e5d:	1b 54 24 04          	sbb    0x4(%esp),%edx
  800e61:	eb cb                	jmp    800e2e <__umoddi3+0x10e>
  800e63:	90                   	nop
  800e64:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
  800e68:	3b 44 24 0c          	cmp    0xc(%esp),%eax
  800e6c:	0f 82 0f ff ff ff    	jb     800d81 <__umoddi3+0x61>
  800e72:	e9 1a ff ff ff       	jmp    800d91 <__umoddi3+0x71>
