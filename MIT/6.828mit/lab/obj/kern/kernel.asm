
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 b0 de 17 f0       	mov    $0xf017deb0,%eax
f010004b:	2d 9d cf 17 f0       	sub    $0xf017cf9d,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 9d cf 17 f0 	movl   $0xf017cf9d,(%esp)
f0100063:	e8 bf 4a 00 00       	call   f0104b27 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 b2 04 00 00       	call   f010051f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 c0 4f 10 f0 	movl   $0xf0104fc0,(%esp)
f010007c:	e8 60 36 00 00       	call   f01036e1 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 3f 11 00 00       	call   f01011c5 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 f2 2f 00 00       	call   f010307d <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 c8 36 00 00       	call   f010375d <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100095:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010009c:	00 
f010009d:	c7 04 24 56 b3 11 f0 	movl   $0xf011b356,(%esp)
f01000a4:	e8 d2 31 00 00       	call   f010327b <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a9:	a1 ec d1 17 f0       	mov    0xf017d1ec,%eax
f01000ae:	89 04 24             	mov    %eax,(%esp)
f01000b1:	e8 4f 35 00 00       	call   f0103605 <env_run>

f01000b6 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b6:	55                   	push   %ebp
f01000b7:	89 e5                	mov    %esp,%ebp
f01000b9:	56                   	push   %esi
f01000ba:	53                   	push   %ebx
f01000bb:	83 ec 10             	sub    $0x10,%esp
f01000be:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c1:	83 3d a0 de 17 f0 00 	cmpl   $0x0,0xf017dea0
f01000c8:	75 3d                	jne    f0100107 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000ca:	89 35 a0 de 17 f0    	mov    %esi,0xf017dea0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d0:	fa                   	cli    
f01000d1:	fc                   	cld    

	va_start(ap, fmt);
f01000d2:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000d8:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000dc:	8b 45 08             	mov    0x8(%ebp),%eax
f01000df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000e3:	c7 04 24 db 4f 10 f0 	movl   $0xf0104fdb,(%esp)
f01000ea:	e8 f2 35 00 00       	call   f01036e1 <cprintf>
	vcprintf(fmt, ap);
f01000ef:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000f3:	89 34 24             	mov    %esi,(%esp)
f01000f6:	e8 b3 35 00 00       	call   f01036ae <vcprintf>
	cprintf("\n");
f01000fb:	c7 04 24 a9 57 10 f0 	movl   $0xf01057a9,(%esp)
f0100102:	e8 da 35 00 00       	call   f01036e1 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100107:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010010e:	e8 17 07 00 00       	call   f010082a <monitor>
f0100113:	eb f2                	jmp    f0100107 <_panic+0x51>

f0100115 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100115:	55                   	push   %ebp
f0100116:	89 e5                	mov    %esp,%ebp
f0100118:	53                   	push   %ebx
f0100119:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010011c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010011f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100126:	8b 45 08             	mov    0x8(%ebp),%eax
f0100129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012d:	c7 04 24 f3 4f 10 f0 	movl   $0xf0104ff3,(%esp)
f0100134:	e8 a8 35 00 00       	call   f01036e1 <cprintf>
	vcprintf(fmt, ap);
f0100139:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010013d:	8b 45 10             	mov    0x10(%ebp),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 66 35 00 00       	call   f01036ae <vcprintf>
	cprintf("\n");
f0100148:	c7 04 24 a9 57 10 f0 	movl   $0xf01057a9,(%esp)
f010014f:	e8 8d 35 00 00       	call   f01036e1 <cprintf>
	va_end(ap);
}
f0100154:	83 c4 14             	add    $0x14,%esp
f0100157:	5b                   	pop    %ebx
f0100158:	5d                   	pop    %ebp
f0100159:	c3                   	ret    
f010015a:	66 90                	xchg   %ax,%ax
f010015c:	66 90                	xchg   %ax,%ax
f010015e:	66 90                	xchg   %ax,%ax

f0100160 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100160:	55                   	push   %ebp
f0100161:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100163:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100168:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100169:	a8 01                	test   $0x1,%al
f010016b:	74 08                	je     f0100175 <serial_proc_data+0x15>
f010016d:	b2 f8                	mov    $0xf8,%dl
f010016f:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100170:	0f b6 c0             	movzbl %al,%eax
f0100173:	eb 05                	jmp    f010017a <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100175:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f010017a:	5d                   	pop    %ebp
f010017b:	c3                   	ret    

f010017c <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010017c:	55                   	push   %ebp
f010017d:	89 e5                	mov    %esp,%ebp
f010017f:	53                   	push   %ebx
f0100180:	83 ec 04             	sub    $0x4,%esp
f0100183:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100185:	eb 2a                	jmp    f01001b1 <cons_intr+0x35>
		if (c == 0)
f0100187:	85 d2                	test   %edx,%edx
f0100189:	74 26                	je     f01001b1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010018b:	a1 c4 d1 17 f0       	mov    0xf017d1c4,%eax
f0100190:	8d 48 01             	lea    0x1(%eax),%ecx
f0100193:	89 0d c4 d1 17 f0    	mov    %ecx,0xf017d1c4
f0100199:	88 90 c0 cf 17 f0    	mov    %dl,-0xfe83040(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010019f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01001a5:	75 0a                	jne    f01001b1 <cons_intr+0x35>
			cons.wpos = 0;
f01001a7:	c7 05 c4 d1 17 f0 00 	movl   $0x0,0xf017d1c4
f01001ae:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001b1:	ff d3                	call   *%ebx
f01001b3:	89 c2                	mov    %eax,%edx
f01001b5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001b8:	75 cd                	jne    f0100187 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001ba:	83 c4 04             	add    $0x4,%esp
f01001bd:	5b                   	pop    %ebx
f01001be:	5d                   	pop    %ebp
f01001bf:	c3                   	ret    

f01001c0 <kbd_proc_data>:
f01001c0:	ba 64 00 00 00       	mov    $0x64,%edx
f01001c5:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001c6:	a8 01                	test   $0x1,%al
f01001c8:	0f 84 ef 00 00 00    	je     f01002bd <kbd_proc_data+0xfd>
f01001ce:	b2 60                	mov    $0x60,%dl
f01001d0:	ec                   	in     (%dx),%al
f01001d1:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001d3:	3c e0                	cmp    $0xe0,%al
f01001d5:	75 0d                	jne    f01001e4 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001d7:	83 0d a0 cf 17 f0 40 	orl    $0x40,0xf017cfa0
		return 0;
f01001de:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001e3:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001e4:	55                   	push   %ebp
f01001e5:	89 e5                	mov    %esp,%ebp
f01001e7:	53                   	push   %ebx
f01001e8:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001eb:	84 c0                	test   %al,%al
f01001ed:	79 37                	jns    f0100226 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001ef:	8b 0d a0 cf 17 f0    	mov    0xf017cfa0,%ecx
f01001f5:	89 cb                	mov    %ecx,%ebx
f01001f7:	83 e3 40             	and    $0x40,%ebx
f01001fa:	83 e0 7f             	and    $0x7f,%eax
f01001fd:	85 db                	test   %ebx,%ebx
f01001ff:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100202:	0f b6 d2             	movzbl %dl,%edx
f0100205:	0f b6 82 60 51 10 f0 	movzbl -0xfefaea0(%edx),%eax
f010020c:	83 c8 40             	or     $0x40,%eax
f010020f:	0f b6 c0             	movzbl %al,%eax
f0100212:	f7 d0                	not    %eax
f0100214:	21 c1                	and    %eax,%ecx
f0100216:	89 0d a0 cf 17 f0    	mov    %ecx,0xf017cfa0
		return 0;
f010021c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100221:	e9 9d 00 00 00       	jmp    f01002c3 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100226:	8b 0d a0 cf 17 f0    	mov    0xf017cfa0,%ecx
f010022c:	f6 c1 40             	test   $0x40,%cl
f010022f:	74 0e                	je     f010023f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100231:	83 c8 80             	or     $0xffffff80,%eax
f0100234:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100236:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100239:	89 0d a0 cf 17 f0    	mov    %ecx,0xf017cfa0
	}

	shift |= shiftcode[data];
f010023f:	0f b6 d2             	movzbl %dl,%edx
f0100242:	0f b6 82 60 51 10 f0 	movzbl -0xfefaea0(%edx),%eax
f0100249:	0b 05 a0 cf 17 f0    	or     0xf017cfa0,%eax
	shift ^= togglecode[data];
f010024f:	0f b6 8a 60 50 10 f0 	movzbl -0xfefafa0(%edx),%ecx
f0100256:	31 c8                	xor    %ecx,%eax
f0100258:	a3 a0 cf 17 f0       	mov    %eax,0xf017cfa0

	c = charcode[shift & (CTL | SHIFT)][data];
f010025d:	89 c1                	mov    %eax,%ecx
f010025f:	83 e1 03             	and    $0x3,%ecx
f0100262:	8b 0c 8d 40 50 10 f0 	mov    -0xfefafc0(,%ecx,4),%ecx
f0100269:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010026d:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f0100270:	a8 08                	test   $0x8,%al
f0100272:	74 1b                	je     f010028f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100274:	89 da                	mov    %ebx,%edx
f0100276:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100279:	83 f9 19             	cmp    $0x19,%ecx
f010027c:	77 05                	ja     f0100283 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010027e:	83 eb 20             	sub    $0x20,%ebx
f0100281:	eb 0c                	jmp    f010028f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100283:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100286:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100289:	83 fa 19             	cmp    $0x19,%edx
f010028c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010028f:	f7 d0                	not    %eax
f0100291:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100293:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100295:	f6 c2 06             	test   $0x6,%dl
f0100298:	75 29                	jne    f01002c3 <kbd_proc_data+0x103>
f010029a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01002a0:	75 21                	jne    f01002c3 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01002a2:	c7 04 24 0d 50 10 f0 	movl   $0xf010500d,(%esp)
f01002a9:	e8 33 34 00 00       	call   f01036e1 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ae:	ba 92 00 00 00       	mov    $0x92,%edx
f01002b3:	b8 03 00 00 00       	mov    $0x3,%eax
f01002b8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002b9:	89 d8                	mov    %ebx,%eax
f01002bb:	eb 06                	jmp    f01002c3 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002c2:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002c3:	83 c4 14             	add    $0x14,%esp
f01002c6:	5b                   	pop    %ebx
f01002c7:	5d                   	pop    %ebp
f01002c8:	c3                   	ret    

f01002c9 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01002c9:	55                   	push   %ebp
f01002ca:	89 e5                	mov    %esp,%ebp
f01002cc:	57                   	push   %edi
f01002cd:	56                   	push   %esi
f01002ce:	53                   	push   %ebx
f01002cf:	83 ec 1c             	sub    $0x1c,%esp
f01002d2:	89 c7                	mov    %eax,%edi
f01002d4:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002d9:	be fd 03 00 00       	mov    $0x3fd,%esi
f01002de:	b9 84 00 00 00       	mov    $0x84,%ecx
f01002e3:	eb 06                	jmp    f01002eb <cons_putc+0x22>
f01002e5:	89 ca                	mov    %ecx,%edx
f01002e7:	ec                   	in     (%dx),%al
f01002e8:	ec                   	in     (%dx),%al
f01002e9:	ec                   	in     (%dx),%al
f01002ea:	ec                   	in     (%dx),%al
f01002eb:	89 f2                	mov    %esi,%edx
f01002ed:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01002ee:	a8 20                	test   $0x20,%al
f01002f0:	75 05                	jne    f01002f7 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01002f2:	83 eb 01             	sub    $0x1,%ebx
f01002f5:	75 ee                	jne    f01002e5 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01002f7:	89 f8                	mov    %edi,%eax
f01002f9:	0f b6 c0             	movzbl %al,%eax
f01002fc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002ff:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100304:	ee                   	out    %al,(%dx)
f0100305:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030a:	be 79 03 00 00       	mov    $0x379,%esi
f010030f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100314:	eb 06                	jmp    f010031c <cons_putc+0x53>
f0100316:	89 ca                	mov    %ecx,%edx
f0100318:	ec                   	in     (%dx),%al
f0100319:	ec                   	in     (%dx),%al
f010031a:	ec                   	in     (%dx),%al
f010031b:	ec                   	in     (%dx),%al
f010031c:	89 f2                	mov    %esi,%edx
f010031e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010031f:	84 c0                	test   %al,%al
f0100321:	78 05                	js     f0100328 <cons_putc+0x5f>
f0100323:	83 eb 01             	sub    $0x1,%ebx
f0100326:	75 ee                	jne    f0100316 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100328:	ba 78 03 00 00       	mov    $0x378,%edx
f010032d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100331:	ee                   	out    %al,(%dx)
f0100332:	b2 7a                	mov    $0x7a,%dl
f0100334:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100339:	ee                   	out    %al,(%dx)
f010033a:	b8 08 00 00 00       	mov    $0x8,%eax
f010033f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100340:	89 fa                	mov    %edi,%edx
f0100342:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100348:	89 f8                	mov    %edi,%eax
f010034a:	80 cc 07             	or     $0x7,%ah
f010034d:	85 d2                	test   %edx,%edx
f010034f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100352:	89 f8                	mov    %edi,%eax
f0100354:	0f b6 c0             	movzbl %al,%eax
f0100357:	83 f8 09             	cmp    $0x9,%eax
f010035a:	74 76                	je     f01003d2 <cons_putc+0x109>
f010035c:	83 f8 09             	cmp    $0x9,%eax
f010035f:	7f 0a                	jg     f010036b <cons_putc+0xa2>
f0100361:	83 f8 08             	cmp    $0x8,%eax
f0100364:	74 16                	je     f010037c <cons_putc+0xb3>
f0100366:	e9 9b 00 00 00       	jmp    f0100406 <cons_putc+0x13d>
f010036b:	83 f8 0a             	cmp    $0xa,%eax
f010036e:	66 90                	xchg   %ax,%ax
f0100370:	74 3a                	je     f01003ac <cons_putc+0xe3>
f0100372:	83 f8 0d             	cmp    $0xd,%eax
f0100375:	74 3d                	je     f01003b4 <cons_putc+0xeb>
f0100377:	e9 8a 00 00 00       	jmp    f0100406 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f010037c:	0f b7 05 c8 d1 17 f0 	movzwl 0xf017d1c8,%eax
f0100383:	66 85 c0             	test   %ax,%ax
f0100386:	0f 84 e5 00 00 00    	je     f0100471 <cons_putc+0x1a8>
			crt_pos--;
f010038c:	83 e8 01             	sub    $0x1,%eax
f010038f:	66 a3 c8 d1 17 f0    	mov    %ax,0xf017d1c8
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100395:	0f b7 c0             	movzwl %ax,%eax
f0100398:	66 81 e7 00 ff       	and    $0xff00,%di
f010039d:	83 cf 20             	or     $0x20,%edi
f01003a0:	8b 15 cc d1 17 f0    	mov    0xf017d1cc,%edx
f01003a6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01003aa:	eb 78                	jmp    f0100424 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01003ac:	66 83 05 c8 d1 17 f0 	addw   $0x50,0xf017d1c8
f01003b3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01003b4:	0f b7 05 c8 d1 17 f0 	movzwl 0xf017d1c8,%eax
f01003bb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003c1:	c1 e8 16             	shr    $0x16,%eax
f01003c4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003c7:	c1 e0 04             	shl    $0x4,%eax
f01003ca:	66 a3 c8 d1 17 f0    	mov    %ax,0xf017d1c8
f01003d0:	eb 52                	jmp    f0100424 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f01003d2:	b8 20 00 00 00       	mov    $0x20,%eax
f01003d7:	e8 ed fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003dc:	b8 20 00 00 00       	mov    $0x20,%eax
f01003e1:	e8 e3 fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003e6:	b8 20 00 00 00       	mov    $0x20,%eax
f01003eb:	e8 d9 fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003f0:	b8 20 00 00 00       	mov    $0x20,%eax
f01003f5:	e8 cf fe ff ff       	call   f01002c9 <cons_putc>
		cons_putc(' ');
f01003fa:	b8 20 00 00 00       	mov    $0x20,%eax
f01003ff:	e8 c5 fe ff ff       	call   f01002c9 <cons_putc>
f0100404:	eb 1e                	jmp    f0100424 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100406:	0f b7 05 c8 d1 17 f0 	movzwl 0xf017d1c8,%eax
f010040d:	8d 50 01             	lea    0x1(%eax),%edx
f0100410:	66 89 15 c8 d1 17 f0 	mov    %dx,0xf017d1c8
f0100417:	0f b7 c0             	movzwl %ax,%eax
f010041a:	8b 15 cc d1 17 f0    	mov    0xf017d1cc,%edx
f0100420:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100424:	66 81 3d c8 d1 17 f0 	cmpw   $0x7cf,0xf017d1c8
f010042b:	cf 07 
f010042d:	76 42                	jbe    f0100471 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010042f:	a1 cc d1 17 f0       	mov    0xf017d1cc,%eax
f0100434:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010043b:	00 
f010043c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100442:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100446:	89 04 24             	mov    %eax,(%esp)
f0100449:	e8 26 47 00 00       	call   f0104b74 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010044e:	8b 15 cc d1 17 f0    	mov    0xf017d1cc,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100454:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100459:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010045f:	83 c0 01             	add    $0x1,%eax
f0100462:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100467:	75 f0                	jne    f0100459 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100469:	66 83 2d c8 d1 17 f0 	subw   $0x50,0xf017d1c8
f0100470:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100471:	8b 0d d0 d1 17 f0    	mov    0xf017d1d0,%ecx
f0100477:	b8 0e 00 00 00       	mov    $0xe,%eax
f010047c:	89 ca                	mov    %ecx,%edx
f010047e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010047f:	0f b7 1d c8 d1 17 f0 	movzwl 0xf017d1c8,%ebx
f0100486:	8d 71 01             	lea    0x1(%ecx),%esi
f0100489:	89 d8                	mov    %ebx,%eax
f010048b:	66 c1 e8 08          	shr    $0x8,%ax
f010048f:	89 f2                	mov    %esi,%edx
f0100491:	ee                   	out    %al,(%dx)
f0100492:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100497:	89 ca                	mov    %ecx,%edx
f0100499:	ee                   	out    %al,(%dx)
f010049a:	89 d8                	mov    %ebx,%eax
f010049c:	89 f2                	mov    %esi,%edx
f010049e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010049f:	83 c4 1c             	add    $0x1c,%esp
f01004a2:	5b                   	pop    %ebx
f01004a3:	5e                   	pop    %esi
f01004a4:	5f                   	pop    %edi
f01004a5:	5d                   	pop    %ebp
f01004a6:	c3                   	ret    

f01004a7 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01004a7:	80 3d d4 d1 17 f0 00 	cmpb   $0x0,0xf017d1d4
f01004ae:	74 11                	je     f01004c1 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004b0:	55                   	push   %ebp
f01004b1:	89 e5                	mov    %esp,%ebp
f01004b3:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01004b6:	b8 60 01 10 f0       	mov    $0xf0100160,%eax
f01004bb:	e8 bc fc ff ff       	call   f010017c <cons_intr>
}
f01004c0:	c9                   	leave  
f01004c1:	f3 c3                	repz ret 

f01004c3 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004c3:	55                   	push   %ebp
f01004c4:	89 e5                	mov    %esp,%ebp
f01004c6:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004c9:	b8 c0 01 10 f0       	mov    $0xf01001c0,%eax
f01004ce:	e8 a9 fc ff ff       	call   f010017c <cons_intr>
}
f01004d3:	c9                   	leave  
f01004d4:	c3                   	ret    

f01004d5 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004d5:	55                   	push   %ebp
f01004d6:	89 e5                	mov    %esp,%ebp
f01004d8:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004db:	e8 c7 ff ff ff       	call   f01004a7 <serial_intr>
	kbd_intr();
f01004e0:	e8 de ff ff ff       	call   f01004c3 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004e5:	a1 c0 d1 17 f0       	mov    0xf017d1c0,%eax
f01004ea:	3b 05 c4 d1 17 f0    	cmp    0xf017d1c4,%eax
f01004f0:	74 26                	je     f0100518 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f01004f2:	8d 50 01             	lea    0x1(%eax),%edx
f01004f5:	89 15 c0 d1 17 f0    	mov    %edx,0xf017d1c0
f01004fb:	0f b6 88 c0 cf 17 f0 	movzbl -0xfe83040(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100502:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100504:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010050a:	75 11                	jne    f010051d <cons_getc+0x48>
			cons.rpos = 0;
f010050c:	c7 05 c0 d1 17 f0 00 	movl   $0x0,0xf017d1c0
f0100513:	00 00 00 
f0100516:	eb 05                	jmp    f010051d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100518:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010051d:	c9                   	leave  
f010051e:	c3                   	ret    

f010051f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010051f:	55                   	push   %ebp
f0100520:	89 e5                	mov    %esp,%ebp
f0100522:	57                   	push   %edi
f0100523:	56                   	push   %esi
f0100524:	53                   	push   %ebx
f0100525:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100528:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010052f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100536:	5a a5 
	if (*cp != 0xA55A) {
f0100538:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010053f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100543:	74 11                	je     f0100556 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100545:	c7 05 d0 d1 17 f0 b4 	movl   $0x3b4,0xf017d1d0
f010054c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010054f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100554:	eb 16                	jmp    f010056c <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100556:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010055d:	c7 05 d0 d1 17 f0 d4 	movl   $0x3d4,0xf017d1d0
f0100564:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100567:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f010056c:	8b 0d d0 d1 17 f0    	mov    0xf017d1d0,%ecx
f0100572:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100577:	89 ca                	mov    %ecx,%edx
f0100579:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010057a:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010057d:	89 da                	mov    %ebx,%edx
f010057f:	ec                   	in     (%dx),%al
f0100580:	0f b6 f0             	movzbl %al,%esi
f0100583:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100586:	b8 0f 00 00 00       	mov    $0xf,%eax
f010058b:	89 ca                	mov    %ecx,%edx
f010058d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058e:	89 da                	mov    %ebx,%edx
f0100590:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100591:	89 3d cc d1 17 f0    	mov    %edi,0xf017d1cc

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100597:	0f b6 d8             	movzbl %al,%ebx
f010059a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010059c:	66 89 35 c8 d1 17 f0 	mov    %si,0xf017d1c8
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005a3:	be fa 03 00 00       	mov    $0x3fa,%esi
f01005a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ad:	89 f2                	mov    %esi,%edx
f01005af:	ee                   	out    %al,(%dx)
f01005b0:	b2 fb                	mov    $0xfb,%dl
f01005b2:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005b7:	ee                   	out    %al,(%dx)
f01005b8:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f01005bd:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b2 f9                	mov    $0xf9,%dl
f01005c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005cc:	ee                   	out    %al,(%dx)
f01005cd:	b2 fb                	mov    $0xfb,%dl
f01005cf:	b8 03 00 00 00       	mov    $0x3,%eax
f01005d4:	ee                   	out    %al,(%dx)
f01005d5:	b2 fc                	mov    $0xfc,%dl
f01005d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01005dc:	ee                   	out    %al,(%dx)
f01005dd:	b2 f9                	mov    $0xf9,%dl
f01005df:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005e5:	b2 fd                	mov    $0xfd,%dl
f01005e7:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005e8:	3c ff                	cmp    $0xff,%al
f01005ea:	0f 95 c1             	setne  %cl
f01005ed:	88 0d d4 d1 17 f0    	mov    %cl,0xf017d1d4
f01005f3:	89 f2                	mov    %esi,%edx
f01005f5:	ec                   	in     (%dx),%al
f01005f6:	89 da                	mov    %ebx,%edx
f01005f8:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005f9:	84 c9                	test   %cl,%cl
f01005fb:	75 0c                	jne    f0100609 <cons_init+0xea>
		cprintf("Serial port does not exist!\n");
f01005fd:	c7 04 24 19 50 10 f0 	movl   $0xf0105019,(%esp)
f0100604:	e8 d8 30 00 00       	call   f01036e1 <cprintf>
}
f0100609:	83 c4 1c             	add    $0x1c,%esp
f010060c:	5b                   	pop    %ebx
f010060d:	5e                   	pop    %esi
f010060e:	5f                   	pop    %edi
f010060f:	5d                   	pop    %ebp
f0100610:	c3                   	ret    

f0100611 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100611:	55                   	push   %ebp
f0100612:	89 e5                	mov    %esp,%ebp
f0100614:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100617:	8b 45 08             	mov    0x8(%ebp),%eax
f010061a:	e8 aa fc ff ff       	call   f01002c9 <cons_putc>
}
f010061f:	c9                   	leave  
f0100620:	c3                   	ret    

f0100621 <getchar>:

int
getchar(void)
{
f0100621:	55                   	push   %ebp
f0100622:	89 e5                	mov    %esp,%ebp
f0100624:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100627:	e8 a9 fe ff ff       	call   f01004d5 <cons_getc>
f010062c:	85 c0                	test   %eax,%eax
f010062e:	74 f7                	je     f0100627 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100630:	c9                   	leave  
f0100631:	c3                   	ret    

f0100632 <iscons>:

int
iscons(int fdnum)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100635:	b8 01 00 00 00       	mov    $0x1,%eax
f010063a:	5d                   	pop    %ebp
f010063b:	c3                   	ret    
f010063c:	66 90                	xchg   %ax,%ax
f010063e:	66 90                	xchg   %ax,%ax

f0100640 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100640:	55                   	push   %ebp
f0100641:	89 e5                	mov    %esp,%ebp
f0100643:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100646:	c7 44 24 08 60 52 10 	movl   $0xf0105260,0x8(%esp)
f010064d:	f0 
f010064e:	c7 44 24 04 7e 52 10 	movl   $0xf010527e,0x4(%esp)
f0100655:	f0 
f0100656:	c7 04 24 83 52 10 f0 	movl   $0xf0105283,(%esp)
f010065d:	e8 7f 30 00 00       	call   f01036e1 <cprintf>
f0100662:	c7 44 24 08 24 53 10 	movl   $0xf0105324,0x8(%esp)
f0100669:	f0 
f010066a:	c7 44 24 04 8c 52 10 	movl   $0xf010528c,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 83 52 10 f0 	movl   $0xf0105283,(%esp)
f0100679:	e8 63 30 00 00       	call   f01036e1 <cprintf>
f010067e:	c7 44 24 08 4c 53 10 	movl   $0xf010534c,0x8(%esp)
f0100685:	f0 
f0100686:	c7 44 24 04 95 52 10 	movl   $0xf0105295,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 83 52 10 f0 	movl   $0xf0105283,(%esp)
f0100695:	e8 47 30 00 00       	call   f01036e1 <cprintf>
	return 0;
}
f010069a:	b8 00 00 00 00       	mov    $0x0,%eax
f010069f:	c9                   	leave  
f01006a0:	c3                   	ret    

f01006a1 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006a1:	55                   	push   %ebp
f01006a2:	89 e5                	mov    %esp,%ebp
f01006a4:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006a7:	c7 04 24 9f 52 10 f0 	movl   $0xf010529f,(%esp)
f01006ae:	e8 2e 30 00 00       	call   f01036e1 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006b3:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006ba:	00 
f01006bb:	c7 04 24 70 53 10 f0 	movl   $0xf0105370,(%esp)
f01006c2:	e8 1a 30 00 00       	call   f01036e1 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006c7:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ce:	00 
f01006cf:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006d6:	f0 
f01006d7:	c7 04 24 98 53 10 f0 	movl   $0xf0105398,(%esp)
f01006de:	e8 fe 2f 00 00       	call   f01036e1 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006e3:	c7 44 24 08 b7 4f 10 	movl   $0x104fb7,0x8(%esp)
f01006ea:	00 
f01006eb:	c7 44 24 04 b7 4f 10 	movl   $0xf0104fb7,0x4(%esp)
f01006f2:	f0 
f01006f3:	c7 04 24 bc 53 10 f0 	movl   $0xf01053bc,(%esp)
f01006fa:	e8 e2 2f 00 00       	call   f01036e1 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ff:	c7 44 24 08 9d cf 17 	movl   $0x17cf9d,0x8(%esp)
f0100706:	00 
f0100707:	c7 44 24 04 9d cf 17 	movl   $0xf017cf9d,0x4(%esp)
f010070e:	f0 
f010070f:	c7 04 24 e0 53 10 f0 	movl   $0xf01053e0,(%esp)
f0100716:	e8 c6 2f 00 00       	call   f01036e1 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010071b:	c7 44 24 08 b0 de 17 	movl   $0x17deb0,0x8(%esp)
f0100722:	00 
f0100723:	c7 44 24 04 b0 de 17 	movl   $0xf017deb0,0x4(%esp)
f010072a:	f0 
f010072b:	c7 04 24 04 54 10 f0 	movl   $0xf0105404,(%esp)
f0100732:	e8 aa 2f 00 00       	call   f01036e1 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100737:	b8 af e2 17 f0       	mov    $0xf017e2af,%eax
f010073c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100741:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100746:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010074c:	85 c0                	test   %eax,%eax
f010074e:	0f 48 c2             	cmovs  %edx,%eax
f0100751:	c1 f8 0a             	sar    $0xa,%eax
f0100754:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100758:	c7 04 24 28 54 10 f0 	movl   $0xf0105428,(%esp)
f010075f:	e8 7d 2f 00 00       	call   f01036e1 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100764:	b8 00 00 00 00       	mov    $0x0,%eax
f0100769:	c9                   	leave  
f010076a:	c3                   	ret    

f010076b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010076b:	55                   	push   %ebp
f010076c:	89 e5                	mov    %esp,%ebp
f010076e:	53                   	push   %ebx
f010076f:	83 ec 14             	sub    $0x14,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100772:	89 e8                	mov    %ebp,%eax
	//The ebp value of the program, which calls the mon_backtrace
	int regebp = read_ebp();
	regebp = *((int *)regebp);
	int *ebp = (int *)regebp;
f0100774:	8b 18                	mov    (%eax),%ebx
	
	cprintf("Stack backtrace:\n");
f0100776:	c7 04 24 b8 52 10 f0 	movl   $0xf01052b8,(%esp)
f010077d:	e8 5f 2f 00 00       	call   f01036e1 <cprintf>
	//If only we haven't pass the stack frame of i386_init
	while((int)ebp != 0x0) {
f0100782:	e9 90 00 00 00       	jmp    f0100817 <mon_backtrace+0xac>
		cprintf("  ebp %08x", (int)ebp);
f0100787:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010078b:	c7 04 24 ca 52 10 f0 	movl   $0xf01052ca,(%esp)
f0100792:	e8 4a 2f 00 00       	call   f01036e1 <cprintf>
		cprintf("  eip %08x", *(ebp+1));
f0100797:	8b 43 04             	mov    0x4(%ebx),%eax
f010079a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079e:	c7 04 24 d5 52 10 f0 	movl   $0xf01052d5,(%esp)
f01007a5:	e8 37 2f 00 00       	call   f01036e1 <cprintf>
		cprintf("  args");
f01007aa:	c7 04 24 e0 52 10 f0 	movl   $0xf01052e0,(%esp)
f01007b1:	e8 2b 2f 00 00       	call   f01036e1 <cprintf>
		cprintf(" %08x", *(ebp+2));
f01007b6:	8b 43 08             	mov    0x8(%ebx),%eax
f01007b9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007bd:	c7 04 24 cf 52 10 f0 	movl   $0xf01052cf,(%esp)
f01007c4:	e8 18 2f 00 00       	call   f01036e1 <cprintf>
		cprintf(" %08x", *(ebp+3));
f01007c9:	8b 43 0c             	mov    0xc(%ebx),%eax
f01007cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d0:	c7 04 24 cf 52 10 f0 	movl   $0xf01052cf,(%esp)
f01007d7:	e8 05 2f 00 00       	call   f01036e1 <cprintf>
		cprintf(" %08x", *(ebp+4));
f01007dc:	8b 43 10             	mov    0x10(%ebx),%eax
f01007df:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e3:	c7 04 24 cf 52 10 f0 	movl   $0xf01052cf,(%esp)
f01007ea:	e8 f2 2e 00 00       	call   f01036e1 <cprintf>
		cprintf(" %08x", *(ebp+5));
f01007ef:	8b 43 14             	mov    0x14(%ebx),%eax
f01007f2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007f6:	c7 04 24 cf 52 10 f0 	movl   $0xf01052cf,(%esp)
f01007fd:	e8 df 2e 00 00       	call   f01036e1 <cprintf>
		cprintf(" %08x\n", *(ebp+6));
f0100802:	8b 43 18             	mov    0x18(%ebx),%eax
f0100805:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100809:	c7 04 24 c1 64 10 f0 	movl   $0xf01064c1,(%esp)
f0100810:	e8 cc 2e 00 00       	call   f01036e1 <cprintf>
		ebp = (int *)(*ebp);
f0100815:	8b 1b                	mov    (%ebx),%ebx
	regebp = *((int *)regebp);
	int *ebp = (int *)regebp;
	
	cprintf("Stack backtrace:\n");
	//If only we haven't pass the stack frame of i386_init
	while((int)ebp != 0x0) {
f0100817:	85 db                	test   %ebx,%ebx
f0100819:	0f 85 68 ff ff ff    	jne    f0100787 <mon_backtrace+0x1c>
		cprintf(" %08x", *(ebp+5));
		cprintf(" %08x\n", *(ebp+6));
		ebp = (int *)(*ebp);
	}
	return 0;
}
f010081f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100824:	83 c4 14             	add    $0x14,%esp
f0100827:	5b                   	pop    %ebx
f0100828:	5d                   	pop    %ebp
f0100829:	c3                   	ret    

f010082a <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010082a:	55                   	push   %ebp
f010082b:	89 e5                	mov    %esp,%ebp
f010082d:	57                   	push   %edi
f010082e:	56                   	push   %esi
f010082f:	53                   	push   %ebx
f0100830:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100833:	c7 04 24 54 54 10 f0 	movl   $0xf0105454,(%esp)
f010083a:	e8 a2 2e 00 00       	call   f01036e1 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010083f:	c7 04 24 78 54 10 f0 	movl   $0xf0105478,(%esp)
f0100846:	e8 96 2e 00 00       	call   f01036e1 <cprintf>

	if (tf != NULL)
f010084b:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010084f:	74 0b                	je     f010085c <monitor+0x32>
		print_trapframe(tf);
f0100851:	8b 45 08             	mov    0x8(%ebp),%eax
f0100854:	89 04 24             	mov    %eax,(%esp)
f0100857:	e8 e3 32 00 00       	call   f0103b3f <print_trapframe>

	while (1) {
		buf = readline("K> ");
f010085c:	c7 04 24 e7 52 10 f0 	movl   $0xf01052e7,(%esp)
f0100863:	e8 68 40 00 00       	call   f01048d0 <readline>
f0100868:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f010086a:	85 c0                	test   %eax,%eax
f010086c:	74 ee                	je     f010085c <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010086e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100875:	be 00 00 00 00       	mov    $0x0,%esi
f010087a:	eb 0a                	jmp    f0100886 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010087c:	c6 03 00             	movb   $0x0,(%ebx)
f010087f:	89 f7                	mov    %esi,%edi
f0100881:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100884:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100886:	0f b6 03             	movzbl (%ebx),%eax
f0100889:	84 c0                	test   %al,%al
f010088b:	74 63                	je     f01008f0 <monitor+0xc6>
f010088d:	0f be c0             	movsbl %al,%eax
f0100890:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100894:	c7 04 24 eb 52 10 f0 	movl   $0xf01052eb,(%esp)
f010089b:	e8 4a 42 00 00       	call   f0104aea <strchr>
f01008a0:	85 c0                	test   %eax,%eax
f01008a2:	75 d8                	jne    f010087c <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f01008a4:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a7:	74 47                	je     f01008f0 <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a9:	83 fe 0f             	cmp    $0xf,%esi
f01008ac:	75 16                	jne    f01008c4 <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008ae:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008b5:	00 
f01008b6:	c7 04 24 f0 52 10 f0 	movl   $0xf01052f0,(%esp)
f01008bd:	e8 1f 2e 00 00       	call   f01036e1 <cprintf>
f01008c2:	eb 98                	jmp    f010085c <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f01008c4:	8d 7e 01             	lea    0x1(%esi),%edi
f01008c7:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008cb:	eb 03                	jmp    f01008d0 <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01008cd:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d0:	0f b6 03             	movzbl (%ebx),%eax
f01008d3:	84 c0                	test   %al,%al
f01008d5:	74 ad                	je     f0100884 <monitor+0x5a>
f01008d7:	0f be c0             	movsbl %al,%eax
f01008da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008de:	c7 04 24 eb 52 10 f0 	movl   $0xf01052eb,(%esp)
f01008e5:	e8 00 42 00 00       	call   f0104aea <strchr>
f01008ea:	85 c0                	test   %eax,%eax
f01008ec:	74 df                	je     f01008cd <monitor+0xa3>
f01008ee:	eb 94                	jmp    f0100884 <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f01008f0:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f7:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f8:	85 f6                	test   %esi,%esi
f01008fa:	0f 84 5c ff ff ff    	je     f010085c <monitor+0x32>
f0100900:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100905:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100908:	8b 04 85 a0 54 10 f0 	mov    -0xfefab60(,%eax,4),%eax
f010090f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100913:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100916:	89 04 24             	mov    %eax,(%esp)
f0100919:	e8 6e 41 00 00       	call   f0104a8c <strcmp>
f010091e:	85 c0                	test   %eax,%eax
f0100920:	75 24                	jne    f0100946 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100922:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100925:	8b 55 08             	mov    0x8(%ebp),%edx
f0100928:	89 54 24 08          	mov    %edx,0x8(%esp)
f010092c:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f010092f:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100933:	89 34 24             	mov    %esi,(%esp)
f0100936:	ff 14 85 a8 54 10 f0 	call   *-0xfefab58(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010093d:	85 c0                	test   %eax,%eax
f010093f:	78 25                	js     f0100966 <monitor+0x13c>
f0100941:	e9 16 ff ff ff       	jmp    f010085c <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100946:	83 c3 01             	add    $0x1,%ebx
f0100949:	83 fb 03             	cmp    $0x3,%ebx
f010094c:	75 b7                	jne    f0100905 <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010094e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100951:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100955:	c7 04 24 0d 53 10 f0 	movl   $0xf010530d,(%esp)
f010095c:	e8 80 2d 00 00       	call   f01036e1 <cprintf>
f0100961:	e9 f6 fe ff ff       	jmp    f010085c <monitor+0x32>
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}

}
f0100966:	83 c4 5c             	add    $0x5c,%esp
f0100969:	5b                   	pop    %ebx
f010096a:	5e                   	pop    %esi
f010096b:	5f                   	pop    %edi
f010096c:	5d                   	pop    %ebp
f010096d:	c3                   	ret    
f010096e:	66 90                	xchg   %ax,%ax

f0100970 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100970:	83 3d d8 d1 17 f0 00 	cmpl   $0x0,0xf017d1d8
f0100977:	75 11                	jne    f010098a <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100979:	ba af ee 17 f0       	mov    $0xf017eeaf,%edx
f010097e:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100984:	89 15 d8 d1 17 f0    	mov    %edx,0xf017d1d8
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f010098a:	8b 0d d8 d1 17 f0    	mov    0xf017d1d8,%ecx
	nextfree = ROUNDUP(nextfree+n, PGSIZE);
f0100990:	8d 94 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%edx
f0100997:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010099d:	89 15 d8 d1 17 f0    	mov    %edx,0xf017d1d8
	if((uint32_t)nextfree-KERNBASE > (npages * PGSIZE)) {
f01009a3:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f01009a9:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f01009ae:	c1 e0 0c             	shl    $0xc,%eax
f01009b1:	39 c2                	cmp    %eax,%edx
f01009b3:	76 22                	jbe    f01009d7 <boot_alloc+0x67>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009b5:	55                   	push   %ebp
f01009b6:	89 e5                	mov    %esp,%ebp
f01009b8:	83 ec 18             	sub    $0x18,%esp
	//
	// LAB 2: Your code here.
	result = nextfree;
	nextfree = ROUNDUP(nextfree+n, PGSIZE);
	if((uint32_t)nextfree-KERNBASE > (npages * PGSIZE)) {
		panic("Out of memory!\n");
f01009bb:	c7 44 24 08 c4 54 10 	movl   $0xf01054c4,0x8(%esp)
f01009c2:	f0 
f01009c3:	c7 44 24 04 69 00 00 	movl   $0x69,0x4(%esp)
f01009ca:	00 
f01009cb:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01009d2:	e8 df f6 ff ff       	call   f01000b6 <_panic>
	}
	return result;
}
f01009d7:	89 c8                	mov    %ecx,%eax
f01009d9:	c3                   	ret    

f01009da <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01009da:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f01009e0:	c1 f8 03             	sar    $0x3,%eax
f01009e3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009e6:	89 c2                	mov    %eax,%edx
f01009e8:	c1 ea 0c             	shr    $0xc,%edx
f01009eb:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f01009f1:	72 26                	jb     f0100a19 <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f01009f3:	55                   	push   %ebp
f01009f4:	89 e5                	mov    %esp,%ebp
f01009f6:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009f9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009fd:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0100a04:	f0 
f0100a05:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100a0c:	00 
f0100a0d:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f0100a14:	e8 9d f6 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100a19:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));
}
f0100a1e:	c3                   	ret    

f0100a1f <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a1f:	89 d1                	mov    %edx,%ecx
f0100a21:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a24:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a27:	a8 01                	test   $0x1,%al
f0100a29:	74 5d                	je     f0100a88 <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a2b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a30:	89 c1                	mov    %eax,%ecx
f0100a32:	c1 e9 0c             	shr    $0xc,%ecx
f0100a35:	3b 0d a4 de 17 f0    	cmp    0xf017dea4,%ecx
f0100a3b:	72 26                	jb     f0100a63 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a3d:	55                   	push   %ebp
f0100a3e:	89 e5                	mov    %esp,%ebp
f0100a40:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a43:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100a47:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0100a4e:	f0 
f0100a4f:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0100a56:	00 
f0100a57:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100a5e:	e8 53 f6 ff ff       	call   f01000b6 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a63:	c1 ea 0c             	shr    $0xc,%edx
f0100a66:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a6c:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a73:	89 c2                	mov    %eax,%edx
f0100a75:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a78:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a7d:	85 d2                	test   %edx,%edx
f0100a7f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100a84:	0f 44 c2             	cmove  %edx,%eax
f0100a87:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100a88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100a8d:	c3                   	ret    

f0100a8e <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a8e:	55                   	push   %ebp
f0100a8f:	89 e5                	mov    %esp,%ebp
f0100a91:	57                   	push   %edi
f0100a92:	56                   	push   %esi
f0100a93:	53                   	push   %ebx
f0100a94:	83 ec 4c             	sub    $0x4c,%esp
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a97:	84 c0                	test   %al,%al
f0100a99:	0f 85 07 03 00 00    	jne    f0100da6 <check_page_free_list+0x318>
f0100a9f:	e9 14 03 00 00       	jmp    f0100db8 <check_page_free_list+0x32a>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100aa4:	c7 44 24 08 00 58 10 	movl   $0xf0105800,0x8(%esp)
f0100aab:	f0 
f0100aac:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f0100ab3:	00 
f0100ab4:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100abb:	e8 f6 f5 ff ff       	call   f01000b6 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ac0:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ac3:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ac6:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ac9:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100acc:	89 c2                	mov    %eax,%edx
f0100ace:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100ad4:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ada:	0f 95 c2             	setne  %dl
f0100add:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ae0:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ae4:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ae6:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100aea:	8b 00                	mov    (%eax),%eax
f0100aec:	85 c0                	test   %eax,%eax
f0100aee:	75 dc                	jne    f0100acc <check_page_free_list+0x3e>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100af0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100af3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100af9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100afc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100aff:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b01:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b04:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0
check_page_free_list(bool only_low_memory)
{
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b09:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b0e:	8b 1d e0 d1 17 f0    	mov    0xf017d1e0,%ebx
f0100b14:	eb 63                	jmp    f0100b79 <check_page_free_list+0xeb>
f0100b16:	89 d8                	mov    %ebx,%eax
f0100b18:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0100b1e:	c1 f8 03             	sar    $0x3,%eax
f0100b21:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b24:	89 c2                	mov    %eax,%edx
f0100b26:	c1 ea 16             	shr    $0x16,%edx
f0100b29:	39 f2                	cmp    %esi,%edx
f0100b2b:	73 4a                	jae    f0100b77 <check_page_free_list+0xe9>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b2d:	89 c2                	mov    %eax,%edx
f0100b2f:	c1 ea 0c             	shr    $0xc,%edx
f0100b32:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0100b38:	72 20                	jb     f0100b5a <check_page_free_list+0xcc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b3a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b3e:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0100b45:	f0 
f0100b46:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b4d:	00 
f0100b4e:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f0100b55:	e8 5c f5 ff ff       	call   f01000b6 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b5a:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b61:	00 
f0100b62:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b69:	00 
	return (void *)(pa + KERNBASE);
f0100b6a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b6f:	89 04 24             	mov    %eax,(%esp)
f0100b72:	e8 b0 3f 00 00       	call   f0104b27 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b77:	8b 1b                	mov    (%ebx),%ebx
f0100b79:	85 db                	test   %ebx,%ebx
f0100b7b:	75 99                	jne    f0100b16 <check_page_free_list+0x88>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b7d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b82:	e8 e9 fd ff ff       	call   f0100970 <boot_alloc>
f0100b87:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b8a:	8b 15 e0 d1 17 f0    	mov    0xf017d1e0,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b90:	8b 0d ac de 17 f0    	mov    0xf017deac,%ecx
		assert(pp < pages + npages);
f0100b96:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f0100b9b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100b9e:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100ba1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100ba4:	89 4d d0             	mov    %ecx,-0x30(%ebp)
{
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ba7:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bac:	89 5d cc             	mov    %ebx,-0x34(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100baf:	e9 97 01 00 00       	jmp    f0100d4b <check_page_free_list+0x2bd>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bb4:	39 ca                	cmp    %ecx,%edx
f0100bb6:	73 24                	jae    f0100bdc <check_page_free_list+0x14e>
f0100bb8:	c7 44 24 0c ee 54 10 	movl   $0xf01054ee,0xc(%esp)
f0100bbf:	f0 
f0100bc0:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100bc7:	f0 
f0100bc8:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0100bcf:	00 
f0100bd0:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100bd7:	e8 da f4 ff ff       	call   f01000b6 <_panic>
		assert(pp < pages + npages);
f0100bdc:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bdf:	72 24                	jb     f0100c05 <check_page_free_list+0x177>
f0100be1:	c7 44 24 0c 0f 55 10 	movl   $0xf010550f,0xc(%esp)
f0100be8:	f0 
f0100be9:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100bf0:	f0 
f0100bf1:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f0100bf8:	00 
f0100bf9:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100c00:	e8 b1 f4 ff ff       	call   f01000b6 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c05:	89 d0                	mov    %edx,%eax
f0100c07:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c0a:	a8 07                	test   $0x7,%al
f0100c0c:	74 24                	je     f0100c32 <check_page_free_list+0x1a4>
f0100c0e:	c7 44 24 0c 24 58 10 	movl   $0xf0105824,0xc(%esp)
f0100c15:	f0 
f0100c16:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100c1d:	f0 
f0100c1e:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0100c25:	00 
f0100c26:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100c2d:	e8 84 f4 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c32:	c1 f8 03             	sar    $0x3,%eax
f0100c35:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c38:	85 c0                	test   %eax,%eax
f0100c3a:	75 24                	jne    f0100c60 <check_page_free_list+0x1d2>
f0100c3c:	c7 44 24 0c 23 55 10 	movl   $0xf0105523,0xc(%esp)
f0100c43:	f0 
f0100c44:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100c4b:	f0 
f0100c4c:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0100c53:	00 
f0100c54:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100c5b:	e8 56 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c60:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c65:	75 24                	jne    f0100c8b <check_page_free_list+0x1fd>
f0100c67:	c7 44 24 0c 34 55 10 	movl   $0xf0105534,0xc(%esp)
f0100c6e:	f0 
f0100c6f:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100c76:	f0 
f0100c77:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f0100c7e:	00 
f0100c7f:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100c86:	e8 2b f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c8b:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c90:	75 24                	jne    f0100cb6 <check_page_free_list+0x228>
f0100c92:	c7 44 24 0c 58 58 10 	movl   $0xf0105858,0xc(%esp)
f0100c99:	f0 
f0100c9a:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100ca1:	f0 
f0100ca2:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0100ca9:	00 
f0100caa:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100cb1:	e8 00 f4 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cb6:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cbb:	75 24                	jne    f0100ce1 <check_page_free_list+0x253>
f0100cbd:	c7 44 24 0c 4d 55 10 	movl   $0xf010554d,0xc(%esp)
f0100cc4:	f0 
f0100cc5:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100ccc:	f0 
f0100ccd:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f0100cd4:	00 
f0100cd5:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100cdc:	e8 d5 f3 ff ff       	call   f01000b6 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ce1:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100ce6:	76 58                	jbe    f0100d40 <check_page_free_list+0x2b2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ce8:	89 c3                	mov    %eax,%ebx
f0100cea:	c1 eb 0c             	shr    $0xc,%ebx
f0100ced:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100cf0:	77 20                	ja     f0100d12 <check_page_free_list+0x284>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cf2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cf6:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0100cfd:	f0 
f0100cfe:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d05:	00 
f0100d06:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f0100d0d:	e8 a4 f3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0100d12:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d17:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d1a:	76 2a                	jbe    f0100d46 <check_page_free_list+0x2b8>
f0100d1c:	c7 44 24 0c 7c 58 10 	movl   $0xf010587c,0xc(%esp)
f0100d23:	f0 
f0100d24:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100d2b:	f0 
f0100d2c:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0100d33:	00 
f0100d34:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100d3b:	e8 76 f3 ff ff       	call   f01000b6 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d40:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d44:	eb 03                	jmp    f0100d49 <check_page_free_list+0x2bb>
		else
			++nfree_extmem;
f0100d46:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d49:	8b 12                	mov    (%edx),%edx
f0100d4b:	85 d2                	test   %edx,%edx
f0100d4d:	0f 85 61 fe ff ff    	jne    f0100bb4 <check_page_free_list+0x126>
f0100d53:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d56:	85 db                	test   %ebx,%ebx
f0100d58:	7f 24                	jg     f0100d7e <check_page_free_list+0x2f0>
f0100d5a:	c7 44 24 0c 67 55 10 	movl   $0xf0105567,0xc(%esp)
f0100d61:	f0 
f0100d62:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100d69:	f0 
f0100d6a:	c7 44 24 04 a2 02 00 	movl   $0x2a2,0x4(%esp)
f0100d71:	00 
f0100d72:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100d79:	e8 38 f3 ff ff       	call   f01000b6 <_panic>
	assert(nfree_extmem > 0);
f0100d7e:	85 ff                	test   %edi,%edi
f0100d80:	7f 4d                	jg     f0100dcf <check_page_free_list+0x341>
f0100d82:	c7 44 24 0c 79 55 10 	movl   $0xf0105579,0xc(%esp)
f0100d89:	f0 
f0100d8a:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100d91:	f0 
f0100d92:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
f0100d99:	00 
f0100d9a:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100da1:	e8 10 f3 ff ff       	call   f01000b6 <_panic>
	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100da6:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f0100dab:	85 c0                	test   %eax,%eax
f0100dad:	0f 85 0d fd ff ff    	jne    f0100ac0 <check_page_free_list+0x32>
f0100db3:	e9 ec fc ff ff       	jmp    f0100aa4 <check_page_free_list+0x16>
f0100db8:	83 3d e0 d1 17 f0 00 	cmpl   $0x0,0xf017d1e0
f0100dbf:	0f 84 df fc ff ff    	je     f0100aa4 <check_page_free_list+0x16>
check_page_free_list(bool only_low_memory)
{
//	cprintf("\nEntering check_page_free_list\n");

	struct PageInfo *pp = NULL;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100dc5:	be 00 04 00 00       	mov    $0x400,%esi
f0100dca:	e9 3f fd ff ff       	jmp    f0100b0e <check_page_free_list+0x80>
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
}
f0100dcf:	83 c4 4c             	add    $0x4c,%esp
f0100dd2:	5b                   	pop    %ebx
f0100dd3:	5e                   	pop    %esi
f0100dd4:	5f                   	pop    %edi
f0100dd5:	5d                   	pop    %ebp
f0100dd6:	c3                   	ret    

f0100dd7 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dd7:	55                   	push   %ebp
f0100dd8:	89 e5                	mov    %esp,%ebp
f0100dda:	57                   	push   %edi
f0100ddb:	56                   	push   %esi
f0100ddc:	53                   	push   %ebx
f0100ddd:	83 ec 0c             	sub    $0xc,%esp
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	page_free_list = NULL;
f0100de0:	c7 05 e0 d1 17 f0 00 	movl   $0x0,0xf017d1e0
f0100de7:	00 00 00 
//	cprintf("kern_pgdir locates at %p\n", kern_pgdir);
//	cprintf("pages locates at %p\n", pages);
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
f0100dea:	b8 00 00 00 00       	mov    $0x0,%eax
f0100def:	e8 7c fb ff ff       	call   f0100970 <boot_alloc>
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
		if(i == 0){       //Physical page 0 is in use.
			pages[i].pp_ref = 1;
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f0100df4:	8b 35 e4 d1 17 f0    	mov    0xf017d1e4,%esi
	page_free_list = NULL;
//	cprintf("kern_pgdir locates at %p\n", kern_pgdir);
//	cprintf("pages locates at %p\n", pages);
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
f0100dfa:	05 00 00 00 10       	add    $0x10000000,%eax
f0100dff:	c1 e8 0c             	shr    $0xc,%eax
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
		if(i == 0){       //Physical page 0 is in use.
			pages[i].pp_ref = 1;
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f0100e02:	8d 7c 06 60          	lea    0x60(%esi,%eax,1),%edi
f0100e06:	8b 1d e0 d1 17 f0    	mov    0xf017d1e0,%ebx
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
	int num_iohole = 96;
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
f0100e0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e11:	eb 4b                	jmp    f0100e5e <page_init+0x87>
		if(i == 0){       //Physical page 0 is in use.
f0100e13:	85 c0                	test   %eax,%eax
f0100e15:	75 0e                	jne    f0100e25 <page_init+0x4e>
			pages[i].pp_ref = 1;
f0100e17:	8b 15 ac de 17 f0    	mov    0xf017deac,%edx
f0100e1d:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
f0100e23:	eb 36                	jmp    f0100e5b <page_init+0x84>
		}
		else if(i >= npages_basemem && i < npages_basemem + num_iohole + num_alloc) {
f0100e25:	39 f0                	cmp    %esi,%eax
f0100e27:	72 13                	jb     f0100e3c <page_init+0x65>
f0100e29:	39 f8                	cmp    %edi,%eax
f0100e2b:	73 0f                	jae    f0100e3c <page_init+0x65>
			pages[i].pp_ref = 1;
f0100e2d:	8b 15 ac de 17 f0    	mov    0xf017deac,%edx
f0100e33:	66 c7 44 c2 04 01 00 	movw   $0x1,0x4(%edx,%eax,8)
f0100e3a:	eb 1f                	jmp    f0100e5b <page_init+0x84>
f0100e3c:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		}
		else {
			pages[i].pp_ref = 0;
f0100e43:	89 d1                	mov    %edx,%ecx
f0100e45:	03 0d ac de 17 f0    	add    0xf017deac,%ecx
f0100e4b:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
			pages[i].pp_link = page_free_list;
f0100e51:	89 19                	mov    %ebx,(%ecx)
			page_free_list = &pages[i];
f0100e53:	89 d3                	mov    %edx,%ebx
f0100e55:	03 1d ac de 17 f0    	add    0xf017deac,%ebx
//	cprintf("nextfree locates at %p\n", boot_alloc);
//	int alloc = (int)((char *)kern_pgdir-KERNBASE)/PGSIZE + (int)((char *)boot_alloc(0)-(char *)pages)/PGSIZE;
	int num_alloc =((uint32_t)boot_alloc(0) - KERNBASE) / PGSIZE;    //The allocated pages in extended memory.
	int num_iohole = 96;
//	cprintf("there are %d allocated pages.\n", alloc);
	for (i = 0; i < npages; i++) {
f0100e5b:	83 c0 01             	add    $0x1,%eax
f0100e5e:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f0100e64:	72 ad                	jb     f0100e13 <page_init+0x3c>
f0100e66:	89 1d e0 d1 17 f0    	mov    %ebx,0xf017d1e0
			pages[i].pp_ref = 0;
			pages[i].pp_link = page_free_list;
			page_free_list = &pages[i];
		}
	}
}
f0100e6c:	83 c4 0c             	add    $0xc,%esp
f0100e6f:	5b                   	pop    %ebx
f0100e70:	5e                   	pop    %esi
f0100e71:	5f                   	pop    %edi
f0100e72:	5d                   	pop    %ebp
f0100e73:	c3                   	ret    

f0100e74 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100e74:	55                   	push   %ebp
f0100e75:	89 e5                	mov    %esp,%ebp
f0100e77:	53                   	push   %ebx
f0100e78:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	struct PageInfo * result = page_free_list;
f0100e7b:	8b 1d e0 d1 17 f0    	mov    0xf017d1e0,%ebx
	if(page_free_list == NULL)
f0100e81:	85 db                	test   %ebx,%ebx
f0100e83:	74 6f                	je     f0100ef4 <page_alloc+0x80>
		return NULL;
	page_free_list = page_free_list->pp_link;
f0100e85:	8b 03                	mov    (%ebx),%eax
f0100e87:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0

	result->pp_link = NULL;
f0100e8c:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if(alloc_flags & ALLOC_ZERO)
		memset(page2kva(result), 0, PGSIZE);
	return result;
f0100e92:	89 d8                	mov    %ebx,%eax
	if(page_free_list == NULL)
		return NULL;
	page_free_list = page_free_list->pp_link;

	result->pp_link = NULL;
	if(alloc_flags & ALLOC_ZERO)
f0100e94:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100e98:	74 5f                	je     f0100ef9 <page_alloc+0x85>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e9a:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0100ea0:	c1 f8 03             	sar    $0x3,%eax
f0100ea3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ea6:	89 c2                	mov    %eax,%edx
f0100ea8:	c1 ea 0c             	shr    $0xc,%edx
f0100eab:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0100eb1:	72 20                	jb     f0100ed3 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eb3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eb7:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0100ebe:	f0 
f0100ebf:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100ec6:	00 
f0100ec7:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f0100ece:	e8 e3 f1 ff ff       	call   f01000b6 <_panic>
		memset(page2kva(result), 0, PGSIZE);
f0100ed3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100eda:	00 
f0100edb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100ee2:	00 
	return (void *)(pa + KERNBASE);
f0100ee3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ee8:	89 04 24             	mov    %eax,(%esp)
f0100eeb:	e8 37 3c 00 00       	call   f0104b27 <memset>
	return result;
f0100ef0:	89 d8                	mov    %ebx,%eax
f0100ef2:	eb 05                	jmp    f0100ef9 <page_alloc+0x85>
page_alloc(int alloc_flags)
{
	// Fill this function in
	struct PageInfo * result = page_free_list;
	if(page_free_list == NULL)
		return NULL;
f0100ef4:	b8 00 00 00 00       	mov    $0x0,%eax

	result->pp_link = NULL;
	if(alloc_flags & ALLOC_ZERO)
		memset(page2kva(result), 0, PGSIZE);
	return result;
}
f0100ef9:	83 c4 14             	add    $0x14,%esp
f0100efc:	5b                   	pop    %ebx
f0100efd:	5d                   	pop    %ebp
f0100efe:	c3                   	ret    

f0100eff <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100eff:	55                   	push   %ebp
f0100f00:	89 e5                	mov    %esp,%ebp
f0100f02:	83 ec 18             	sub    $0x18,%esp
f0100f05:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
	assert(pp->pp_ref == 0);
f0100f08:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f0d:	74 24                	je     f0100f33 <page_free+0x34>
f0100f0f:	c7 44 24 0c 8a 55 10 	movl   $0xf010558a,0xc(%esp)
f0100f16:	f0 
f0100f17:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100f1e:	f0 
f0100f1f:	c7 44 24 04 51 01 00 	movl   $0x151,0x4(%esp)
f0100f26:	00 
f0100f27:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100f2e:	e8 83 f1 ff ff       	call   f01000b6 <_panic>
	assert(pp->pp_link == NULL);
f0100f33:	83 38 00             	cmpl   $0x0,(%eax)
f0100f36:	74 24                	je     f0100f5c <page_free+0x5d>
f0100f38:	c7 44 24 0c 9a 55 10 	movl   $0xf010559a,0xc(%esp)
f0100f3f:	f0 
f0100f40:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0100f47:	f0 
f0100f48:	c7 44 24 04 52 01 00 	movl   $0x152,0x4(%esp)
f0100f4f:	00 
f0100f50:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0100f57:	e8 5a f1 ff ff       	call   f01000b6 <_panic>

	pp->pp_link = page_free_list;
f0100f5c:	8b 15 e0 d1 17 f0    	mov    0xf017d1e0,%edx
f0100f62:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100f64:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0
}
f0100f69:	c9                   	leave  
f0100f6a:	c3                   	ret    

f0100f6b <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100f6b:	55                   	push   %ebp
f0100f6c:	89 e5                	mov    %esp,%ebp
f0100f6e:	83 ec 18             	sub    $0x18,%esp
f0100f71:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f74:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100f78:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100f7b:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f7f:	66 85 d2             	test   %dx,%dx
f0100f82:	75 08                	jne    f0100f8c <page_decref+0x21>
		page_free(pp);
f0100f84:	89 04 24             	mov    %eax,(%esp)
f0100f87:	e8 73 ff ff ff       	call   f0100eff <page_free>
}
f0100f8c:	c9                   	leave  
f0100f8d:	c3                   	ret    

f0100f8e <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f8e:	55                   	push   %ebp
f0100f8f:	89 e5                	mov    %esp,%ebp
f0100f91:	56                   	push   %esi
f0100f92:	53                   	push   %ebx
f0100f93:	83 ec 10             	sub    $0x10,%esp
f0100f96:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	unsigned int page_off;
	pte_t *page_base = NULL;
	struct PageInfo* new_page = NULL;
	unsigned int dic_off = PDX(va); 						 //The page directory index of this page table page.
f0100f99:	89 f3                	mov    %esi,%ebx
f0100f9b:	c1 eb 16             	shr    $0x16,%ebx
	pde_t *dic_entry_ptr = pgdir + dic_off;        //The page directory entry of this page table page.
f0100f9e:	c1 e3 02             	shl    $0x2,%ebx
f0100fa1:	03 5d 08             	add    0x8(%ebp),%ebx
	if( !(*dic_entry_ptr) & PTE_P )                        //If this page table page exists.
f0100fa4:	83 3b 00             	cmpl   $0x0,(%ebx)
f0100fa7:	75 2c                	jne    f0100fd5 <pgdir_walk+0x47>
	{
		if(create)								 //If create is true, then create a new page table page.
f0100fa9:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100fad:	74 6c                	je     f010101b <pgdir_walk+0x8d>
		{
			new_page = page_alloc(1);
f0100faf:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100fb6:	e8 b9 fe ff ff       	call   f0100e74 <page_alloc>
			if(new_page == NULL) return NULL;    //Allocation failed.
f0100fbb:	85 c0                	test   %eax,%eax
f0100fbd:	74 63                	je     f0101022 <pgdir_walk+0x94>
			new_page->pp_ref++;
f0100fbf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fc4:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0100fca:	c1 f8 03             	sar    $0x3,%eax
f0100fcd:	c1 e0 0c             	shl    $0xc,%eax
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
f0100fd0:	83 c8 07             	or     $0x7,%eax
f0100fd3:	89 03                	mov    %eax,(%ebx)
		}
		else
			return NULL; 
	}	
	page_off = PTX(va);						 //The page table index of this page.
f0100fd5:	c1 ee 0c             	shr    $0xc,%esi
f0100fd8:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
f0100fde:	8b 03                	mov    (%ebx),%eax
f0100fe0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fe5:	89 c2                	mov    %eax,%edx
f0100fe7:	c1 ea 0c             	shr    $0xc,%edx
f0100fea:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0100ff0:	72 20                	jb     f0101012 <pgdir_walk+0x84>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ff2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ff6:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0100ffd:	f0 
f0100ffe:	c7 44 24 04 8f 01 00 	movl   $0x18f,0x4(%esp)
f0101005:	00 
f0101006:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010100d:	e8 a4 f0 ff ff       	call   f01000b6 <_panic>
	return &page_base[page_off];
f0101012:	8d 84 b0 00 00 00 f0 	lea    -0x10000000(%eax,%esi,4),%eax
f0101019:	eb 0c                	jmp    f0101027 <pgdir_walk+0x99>
			if(new_page == NULL) return NULL;    //Allocation failed.
			new_page->pp_ref++;
			*dic_entry_ptr = (page2pa(new_page) | PTE_P | PTE_W | PTE_U);
		}
		else
			return NULL; 
f010101b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101020:	eb 05                	jmp    f0101027 <pgdir_walk+0x99>
	if( !(*dic_entry_ptr) & PTE_P )                        //If this page table page exists.
	{
		if(create)								 //If create is true, then create a new page table page.
		{
			new_page = page_alloc(1);
			if(new_page == NULL) return NULL;    //Allocation failed.
f0101022:	b8 00 00 00 00       	mov    $0x0,%eax
			return NULL; 
	}	
	page_off = PTX(va);						 //The page table index of this page.
	page_base = KADDR(PTE_ADDR(*dic_entry_ptr));
	return &page_base[page_off];
}
f0101027:	83 c4 10             	add    $0x10,%esp
f010102a:	5b                   	pop    %ebx
f010102b:	5e                   	pop    %esi
f010102c:	5d                   	pop    %ebp
f010102d:	c3                   	ret    

f010102e <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010102e:	55                   	push   %ebp
f010102f:	89 e5                	mov    %esp,%ebp
f0101031:	57                   	push   %edi
f0101032:	56                   	push   %esi
f0101033:	53                   	push   %ebx
f0101034:	83 ec 2c             	sub    $0x2c,%esp
f0101037:	89 c7                	mov    %eax,%edi
f0101039:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010103c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f010103f:	bb 00 00 00 00       	mov    $0x0,%ebx
	{
		entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
		*entry = (pa | perm | PTE_P);
f0101044:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101047:	83 c8 01             	or     $0x1,%eax
f010104a:	89 45 dc             	mov    %eax,-0x24(%ebp)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f010104d:	eb 24                	jmp    f0101073 <boot_map_region+0x45>
	{
		entry = pgdir_walk(pgdir,(void *)va, 1);    //Get the table entry of this page.
f010104f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101056:	00 
f0101057:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010105a:	01 d8                	add    %ebx,%eax
f010105c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101060:	89 3c 24             	mov    %edi,(%esp)
f0101063:	e8 26 ff ff ff       	call   f0100f8e <pgdir_walk>
		*entry = (pa | perm | PTE_P);
f0101068:	0b 75 dc             	or     -0x24(%ebp),%esi
f010106b:	89 30                	mov    %esi,(%eax)
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	int nadd;
	pte_t *entry = NULL;
	for(nadd = 0; nadd < size; nadd += PGSIZE)
f010106d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101073:	89 de                	mov    %ebx,%esi
f0101075:	03 75 08             	add    0x8(%ebp),%esi
f0101078:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f010107b:	77 d2                	ja     f010104f <boot_map_region+0x21>
		
		pa += PGSIZE;
		va += PGSIZE;
		
	}
}
f010107d:	83 c4 2c             	add    $0x2c,%esp
f0101080:	5b                   	pop    %ebx
f0101081:	5e                   	pop    %esi
f0101082:	5f                   	pop    %edi
f0101083:	5d                   	pop    %ebp
f0101084:	c3                   	ret    

f0101085 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101085:	55                   	push   %ebp
f0101086:	89 e5                	mov    %esp,%ebp
f0101088:	53                   	push   %ebx
f0101089:	83 ec 14             	sub    $0x14,%esp
f010108c:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;

	entry = pgdir_walk(pgdir, va, 0);
f010108f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101096:	00 
f0101097:	8b 45 0c             	mov    0xc(%ebp),%eax
f010109a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010109e:	8b 45 08             	mov    0x8(%ebp),%eax
f01010a1:	89 04 24             	mov    %eax,(%esp)
f01010a4:	e8 e5 fe ff ff       	call   f0100f8e <pgdir_walk>
f01010a9:	89 c2                	mov    %eax,%edx
	if(entry == NULL)
f01010ab:	85 c0                	test   %eax,%eax
f01010ad:	74 3e                	je     f01010ed <page_lookup+0x68>
		return NULL;
	if(!(*entry & PTE_P))
f01010af:	8b 00                	mov    (%eax),%eax
f01010b1:	a8 01                	test   $0x1,%al
f01010b3:	74 3f                	je     f01010f4 <page_lookup+0x6f>
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010b5:	c1 e8 0c             	shr    $0xc,%eax
f01010b8:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f01010be:	72 1c                	jb     f01010dc <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f01010c0:	c7 44 24 08 c4 58 10 	movl   $0xf01058c4,0x8(%esp)
f01010c7:	f0 
f01010c8:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01010cf:	00 
f01010d0:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f01010d7:	e8 da ef ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01010dc:	8b 0d ac de 17 f0    	mov    0xf017deac,%ecx
f01010e2:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
		return NULL;
	
	ret = pa2page(PTE_ADDR(*entry));
	if(pte_store != NULL)
f01010e5:	85 db                	test   %ebx,%ebx
f01010e7:	74 10                	je     f01010f9 <page_lookup+0x74>
	{
		*pte_store = entry;
f01010e9:	89 13                	mov    %edx,(%ebx)
f01010eb:	eb 0c                	jmp    f01010f9 <page_lookup+0x74>
	pte_t *entry = NULL;
	struct PageInfo *ret = NULL;

	entry = pgdir_walk(pgdir, va, 0);
	if(entry == NULL)
		return NULL;
f01010ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f2:	eb 05                	jmp    f01010f9 <page_lookup+0x74>
	if(!(*entry & PTE_P))
		return NULL;
f01010f4:	b8 00 00 00 00       	mov    $0x0,%eax
	if(pte_store != NULL)
	{
		*pte_store = entry;
	}
	return ret;
}
f01010f9:	83 c4 14             	add    $0x14,%esp
f01010fc:	5b                   	pop    %ebx
f01010fd:	5d                   	pop    %ebp
f01010fe:	c3                   	ret    

f01010ff <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01010ff:	55                   	push   %ebp
f0101100:	89 e5                	mov    %esp,%ebp
f0101102:	53                   	push   %ebx
f0101103:	83 ec 24             	sub    $0x24,%esp
f0101106:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t *pte = NULL;
f0101109:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
	struct PageInfo *page = page_lookup(pgdir, va, &pte);
f0101110:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101113:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010111b:	8b 45 08             	mov    0x8(%ebp),%eax
f010111e:	89 04 24             	mov    %eax,(%esp)
f0101121:	e8 5f ff ff ff       	call   f0101085 <page_lookup>
	if(page == NULL) return ;	
f0101126:	85 c0                	test   %eax,%eax
f0101128:	74 14                	je     f010113e <page_remove+0x3f>
	
	page_decref(page);
f010112a:	89 04 24             	mov    %eax,(%esp)
f010112d:	e8 39 fe ff ff       	call   f0100f6b <page_decref>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101132:	0f 01 3b             	invlpg (%ebx)
	tlb_invalidate(pgdir, va);
	*pte = 0;
f0101135:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101138:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
}
f010113e:	83 c4 24             	add    $0x24,%esp
f0101141:	5b                   	pop    %ebx
f0101142:	5d                   	pop    %ebp
f0101143:	c3                   	ret    

f0101144 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101144:	55                   	push   %ebp
f0101145:	89 e5                	mov    %esp,%ebp
f0101147:	57                   	push   %edi
f0101148:	56                   	push   %esi
f0101149:	53                   	push   %ebx
f010114a:	83 ec 1c             	sub    $0x1c,%esp
f010114d:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101150:	8b 7d 0c             	mov    0xc(%ebp),%edi
	pte_t *entry = NULL;
	entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
f0101153:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010115a:	00 
f010115b:	8b 45 10             	mov    0x10(%ebp),%eax
f010115e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101162:	89 1c 24             	mov    %ebx,(%esp)
f0101165:	e8 24 fe ff ff       	call   f0100f8e <pgdir_walk>
f010116a:	89 c6                	mov    %eax,%esi
	if(entry == NULL) return -E_NO_MEM;
f010116c:	85 c0                	test   %eax,%eax
f010116e:	74 48                	je     f01011b8 <page_insert+0x74>

	pp->pp_ref++;
f0101170:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	if((*entry) & PTE_P) 	        //If this virtual address is already mapped.
f0101175:	f6 00 01             	testb  $0x1,(%eax)
f0101178:	74 15                	je     f010118f <page_insert+0x4b>
f010117a:	8b 45 10             	mov    0x10(%ebp),%eax
f010117d:	0f 01 38             	invlpg (%eax)
	{
		tlb_invalidate(pgdir, va);
		page_remove(pgdir, va);
f0101180:	8b 45 10             	mov    0x10(%ebp),%eax
f0101183:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101187:	89 1c 24             	mov    %ebx,(%esp)
f010118a:	e8 70 ff ff ff       	call   f01010ff <page_remove>
	}
	*entry = (page2pa(pp) | perm | PTE_P);
f010118f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101192:	83 c8 01             	or     $0x1,%eax
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101195:	2b 3d ac de 17 f0    	sub    0xf017deac,%edi
f010119b:	c1 ff 03             	sar    $0x3,%edi
f010119e:	c1 e7 0c             	shl    $0xc,%edi
f01011a1:	09 c7                	or     %eax,%edi
f01011a3:	89 3e                	mov    %edi,(%esi)
	pgdir[PDX(va)] |= perm;			      //Remember this step!
f01011a5:	8b 45 10             	mov    0x10(%ebp),%eax
f01011a8:	c1 e8 16             	shr    $0x16,%eax
f01011ab:	8b 55 14             	mov    0x14(%ebp),%edx
f01011ae:	09 14 83             	or     %edx,(%ebx,%eax,4)
		
	return 0;
f01011b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01011b6:	eb 05                	jmp    f01011bd <page_insert+0x79>
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
	pte_t *entry = NULL;
	entry =  pgdir_walk(pgdir, va, 1);    //Get the mapping page of this address va.
	if(entry == NULL) return -E_NO_MEM;
f01011b8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	}
	*entry = (page2pa(pp) | perm | PTE_P);
	pgdir[PDX(va)] |= perm;			      //Remember this step!
		
	return 0;
}
f01011bd:	83 c4 1c             	add    $0x1c,%esp
f01011c0:	5b                   	pop    %ebx
f01011c1:	5e                   	pop    %esi
f01011c2:	5f                   	pop    %edi
f01011c3:	5d                   	pop    %ebp
f01011c4:	c3                   	ret    

f01011c5 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011c5:	55                   	push   %ebp
f01011c6:	89 e5                	mov    %esp,%ebp
f01011c8:	57                   	push   %edi
f01011c9:	56                   	push   %esi
f01011ca:	53                   	push   %ebx
f01011cb:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01011ce:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01011d5:	e8 97 24 00 00       	call   f0103671 <mc146818_read>
f01011da:	89 c3                	mov    %eax,%ebx
f01011dc:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01011e3:	e8 89 24 00 00       	call   f0103671 <mc146818_read>
f01011e8:	c1 e0 08             	shl    $0x8,%eax
f01011eb:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01011ed:	89 d8                	mov    %ebx,%eax
f01011ef:	c1 e0 0a             	shl    $0xa,%eax
f01011f2:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011f8:	85 c0                	test   %eax,%eax
f01011fa:	0f 48 c2             	cmovs  %edx,%eax
f01011fd:	c1 f8 0c             	sar    $0xc,%eax
f0101200:	a3 e4 d1 17 f0       	mov    %eax,0xf017d1e4
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101205:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010120c:	e8 60 24 00 00       	call   f0103671 <mc146818_read>
f0101211:	89 c3                	mov    %eax,%ebx
f0101213:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010121a:	e8 52 24 00 00       	call   f0103671 <mc146818_read>
f010121f:	c1 e0 08             	shl    $0x8,%eax
f0101222:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101224:	89 d8                	mov    %ebx,%eax
f0101226:	c1 e0 0a             	shl    $0xa,%eax
f0101229:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010122f:	85 c0                	test   %eax,%eax
f0101231:	0f 48 c2             	cmovs  %edx,%eax
f0101234:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101237:	85 c0                	test   %eax,%eax
f0101239:	74 0e                	je     f0101249 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010123b:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101241:	89 15 a4 de 17 f0    	mov    %edx,0xf017dea4
f0101247:	eb 0c                	jmp    f0101255 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101249:	8b 15 e4 d1 17 f0    	mov    0xf017d1e4,%edx
f010124f:	89 15 a4 de 17 f0    	mov    %edx,0xf017dea4

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101255:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101258:	c1 e8 0a             	shr    $0xa,%eax
f010125b:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010125f:	a1 e4 d1 17 f0       	mov    0xf017d1e4,%eax
f0101264:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101267:	c1 e8 0a             	shr    $0xa,%eax
f010126a:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010126e:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f0101273:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101276:	c1 e8 0a             	shr    $0xa,%eax
f0101279:	89 44 24 04          	mov    %eax,0x4(%esp)
f010127d:	c7 04 24 e4 58 10 f0 	movl   $0xf01058e4,(%esp)
f0101284:	e8 58 24 00 00       	call   f01036e1 <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101289:	b8 00 10 00 00       	mov    $0x1000,%eax
f010128e:	e8 dd f6 ff ff       	call   f0100970 <boot_alloc>
f0101293:	a3 a8 de 17 f0       	mov    %eax,0xf017dea8
	memset(kern_pgdir, 0, PGSIZE);
f0101298:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010129f:	00 
f01012a0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01012a7:	00 
f01012a8:	89 04 24             	mov    %eax,(%esp)
f01012ab:	e8 77 38 00 00       	call   f0104b27 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01012b0:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01012b5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01012ba:	77 20                	ja     f01012dc <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01012bc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012c0:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f01012c7:	f0 
f01012c8:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f01012cf:	00 
f01012d0:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01012d7:	e8 da ed ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01012dc:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01012e2:	83 ca 05             	or     $0x5,%edx
f01012e5:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *)boot_alloc(npages * sizeof(struct PageInfo));
f01012eb:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f01012f0:	c1 e0 03             	shl    $0x3,%eax
f01012f3:	e8 78 f6 ff ff       	call   f0100970 <boot_alloc>
f01012f8:	a3 ac de 17 f0       	mov    %eax,0xf017deac
	memset(pages, 0, npages * sizeof(struct PageInfo));
f01012fd:	8b 0d a4 de 17 f0    	mov    0xf017dea4,%ecx
f0101303:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010130a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010130e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101315:	00 
f0101316:	89 04 24             	mov    %eax,(%esp)
f0101319:	e8 09 38 00 00       	call   f0104b27 <memset>

	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = (struct Env *)boot_alloc(NENV * sizeof(struct Env));
f010131e:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101323:	e8 48 f6 ff ff       	call   f0100970 <boot_alloc>
f0101328:	a3 ec d1 17 f0       	mov    %eax,0xf017d1ec
	memset(envs, 0, NENV * sizeof(struct Env));
f010132d:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f0101334:	00 
f0101335:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010133c:	00 
f010133d:	89 04 24             	mov    %eax,(%esp)
f0101340:	e8 e2 37 00 00       	call   f0104b27 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101345:	e8 8d fa ff ff       	call   f0100dd7 <page_init>

	check_page_free_list(1);
f010134a:	b8 01 00 00 00       	mov    $0x1,%eax
f010134f:	e8 3a f7 ff ff       	call   f0100a8e <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101354:	83 3d ac de 17 f0 00 	cmpl   $0x0,0xf017deac
f010135b:	75 1c                	jne    f0101379 <mem_init+0x1b4>
		panic("'pages' is a null pointer!");
f010135d:	c7 44 24 08 ae 55 10 	movl   $0xf01055ae,0x8(%esp)
f0101364:	f0 
f0101365:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f010136c:	00 
f010136d:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101374:	e8 3d ed ff ff       	call   f01000b6 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101379:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f010137e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101383:	eb 05                	jmp    f010138a <mem_init+0x1c5>
		++nfree;
f0101385:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101388:	8b 00                	mov    (%eax),%eax
f010138a:	85 c0                	test   %eax,%eax
f010138c:	75 f7                	jne    f0101385 <mem_init+0x1c0>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010138e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101395:	e8 da fa ff ff       	call   f0100e74 <page_alloc>
f010139a:	89 c7                	mov    %eax,%edi
f010139c:	85 c0                	test   %eax,%eax
f010139e:	75 24                	jne    f01013c4 <mem_init+0x1ff>
f01013a0:	c7 44 24 0c c9 55 10 	movl   $0xf01055c9,0xc(%esp)
f01013a7:	f0 
f01013a8:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01013af:	f0 
f01013b0:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f01013b7:	00 
f01013b8:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01013bf:	e8 f2 ec ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f01013c4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01013cb:	e8 a4 fa ff ff       	call   f0100e74 <page_alloc>
f01013d0:	89 c6                	mov    %eax,%esi
f01013d2:	85 c0                	test   %eax,%eax
f01013d4:	75 24                	jne    f01013fa <mem_init+0x235>
f01013d6:	c7 44 24 0c df 55 10 	movl   $0xf01055df,0xc(%esp)
f01013dd:	f0 
f01013de:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01013e5:	f0 
f01013e6:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f01013ed:	00 
f01013ee:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01013f5:	e8 bc ec ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01013fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101401:	e8 6e fa ff ff       	call   f0100e74 <page_alloc>
f0101406:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101409:	85 c0                	test   %eax,%eax
f010140b:	75 24                	jne    f0101431 <mem_init+0x26c>
f010140d:	c7 44 24 0c f5 55 10 	movl   $0xf01055f5,0xc(%esp)
f0101414:	f0 
f0101415:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010141c:	f0 
f010141d:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0101424:	00 
f0101425:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010142c:	e8 85 ec ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101431:	39 f7                	cmp    %esi,%edi
f0101433:	75 24                	jne    f0101459 <mem_init+0x294>
f0101435:	c7 44 24 0c 0b 56 10 	movl   $0xf010560b,0xc(%esp)
f010143c:	f0 
f010143d:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101444:	f0 
f0101445:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f010144c:	00 
f010144d:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101454:	e8 5d ec ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101459:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010145c:	39 c6                	cmp    %eax,%esi
f010145e:	74 04                	je     f0101464 <mem_init+0x29f>
f0101460:	39 c7                	cmp    %eax,%edi
f0101462:	75 24                	jne    f0101488 <mem_init+0x2c3>
f0101464:	c7 44 24 0c 44 59 10 	movl   $0xf0105944,0xc(%esp)
f010146b:	f0 
f010146c:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101473:	f0 
f0101474:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f010147b:	00 
f010147c:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101483:	e8 2e ec ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101488:	8b 15 ac de 17 f0    	mov    0xf017deac,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010148e:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f0101493:	c1 e0 0c             	shl    $0xc,%eax
f0101496:	89 f9                	mov    %edi,%ecx
f0101498:	29 d1                	sub    %edx,%ecx
f010149a:	c1 f9 03             	sar    $0x3,%ecx
f010149d:	c1 e1 0c             	shl    $0xc,%ecx
f01014a0:	39 c1                	cmp    %eax,%ecx
f01014a2:	72 24                	jb     f01014c8 <mem_init+0x303>
f01014a4:	c7 44 24 0c 1d 56 10 	movl   $0xf010561d,0xc(%esp)
f01014ab:	f0 
f01014ac:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01014b3:	f0 
f01014b4:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f01014bb:	00 
f01014bc:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01014c3:	e8 ee eb ff ff       	call   f01000b6 <_panic>
f01014c8:	89 f1                	mov    %esi,%ecx
f01014ca:	29 d1                	sub    %edx,%ecx
f01014cc:	c1 f9 03             	sar    $0x3,%ecx
f01014cf:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01014d2:	39 c8                	cmp    %ecx,%eax
f01014d4:	77 24                	ja     f01014fa <mem_init+0x335>
f01014d6:	c7 44 24 0c 3a 56 10 	movl   $0xf010563a,0xc(%esp)
f01014dd:	f0 
f01014de:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01014e5:	f0 
f01014e6:	c7 44 24 04 c4 02 00 	movl   $0x2c4,0x4(%esp)
f01014ed:	00 
f01014ee:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01014f5:	e8 bc eb ff ff       	call   f01000b6 <_panic>
f01014fa:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01014fd:	29 d1                	sub    %edx,%ecx
f01014ff:	89 ca                	mov    %ecx,%edx
f0101501:	c1 fa 03             	sar    $0x3,%edx
f0101504:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101507:	39 d0                	cmp    %edx,%eax
f0101509:	77 24                	ja     f010152f <mem_init+0x36a>
f010150b:	c7 44 24 0c 57 56 10 	movl   $0xf0105657,0xc(%esp)
f0101512:	f0 
f0101513:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010151a:	f0 
f010151b:	c7 44 24 04 c5 02 00 	movl   $0x2c5,0x4(%esp)
f0101522:	00 
f0101523:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010152a:	e8 87 eb ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010152f:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f0101534:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101537:	c7 05 e0 d1 17 f0 00 	movl   $0x0,0xf017d1e0
f010153e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101541:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101548:	e8 27 f9 ff ff       	call   f0100e74 <page_alloc>
f010154d:	85 c0                	test   %eax,%eax
f010154f:	74 24                	je     f0101575 <mem_init+0x3b0>
f0101551:	c7 44 24 0c 74 56 10 	movl   $0xf0105674,0xc(%esp)
f0101558:	f0 
f0101559:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101560:	f0 
f0101561:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f0101568:	00 
f0101569:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101570:	e8 41 eb ff ff       	call   f01000b6 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101575:	89 3c 24             	mov    %edi,(%esp)
f0101578:	e8 82 f9 ff ff       	call   f0100eff <page_free>
	page_free(pp1);
f010157d:	89 34 24             	mov    %esi,(%esp)
f0101580:	e8 7a f9 ff ff       	call   f0100eff <page_free>
	page_free(pp2);
f0101585:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101588:	89 04 24             	mov    %eax,(%esp)
f010158b:	e8 6f f9 ff ff       	call   f0100eff <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101590:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101597:	e8 d8 f8 ff ff       	call   f0100e74 <page_alloc>
f010159c:	89 c6                	mov    %eax,%esi
f010159e:	85 c0                	test   %eax,%eax
f01015a0:	75 24                	jne    f01015c6 <mem_init+0x401>
f01015a2:	c7 44 24 0c c9 55 10 	movl   $0xf01055c9,0xc(%esp)
f01015a9:	f0 
f01015aa:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01015b1:	f0 
f01015b2:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f01015b9:	00 
f01015ba:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01015c1:	e8 f0 ea ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f01015c6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015cd:	e8 a2 f8 ff ff       	call   f0100e74 <page_alloc>
f01015d2:	89 c7                	mov    %eax,%edi
f01015d4:	85 c0                	test   %eax,%eax
f01015d6:	75 24                	jne    f01015fc <mem_init+0x437>
f01015d8:	c7 44 24 0c df 55 10 	movl   $0xf01055df,0xc(%esp)
f01015df:	f0 
f01015e0:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01015e7:	f0 
f01015e8:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f01015ef:	00 
f01015f0:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01015f7:	e8 ba ea ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01015fc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101603:	e8 6c f8 ff ff       	call   f0100e74 <page_alloc>
f0101608:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010160b:	85 c0                	test   %eax,%eax
f010160d:	75 24                	jne    f0101633 <mem_init+0x46e>
f010160f:	c7 44 24 0c f5 55 10 	movl   $0xf01055f5,0xc(%esp)
f0101616:	f0 
f0101617:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010161e:	f0 
f010161f:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f0101626:	00 
f0101627:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010162e:	e8 83 ea ff ff       	call   f01000b6 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101633:	39 fe                	cmp    %edi,%esi
f0101635:	75 24                	jne    f010165b <mem_init+0x496>
f0101637:	c7 44 24 0c 0b 56 10 	movl   $0xf010560b,0xc(%esp)
f010163e:	f0 
f010163f:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101646:	f0 
f0101647:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f010164e:	00 
f010164f:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101656:	e8 5b ea ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010165b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010165e:	39 c7                	cmp    %eax,%edi
f0101660:	74 04                	je     f0101666 <mem_init+0x4a1>
f0101662:	39 c6                	cmp    %eax,%esi
f0101664:	75 24                	jne    f010168a <mem_init+0x4c5>
f0101666:	c7 44 24 0c 44 59 10 	movl   $0xf0105944,0xc(%esp)
f010166d:	f0 
f010166e:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101675:	f0 
f0101676:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f010167d:	00 
f010167e:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101685:	e8 2c ea ff ff       	call   f01000b6 <_panic>
	assert(!page_alloc(0));
f010168a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101691:	e8 de f7 ff ff       	call   f0100e74 <page_alloc>
f0101696:	85 c0                	test   %eax,%eax
f0101698:	74 24                	je     f01016be <mem_init+0x4f9>
f010169a:	c7 44 24 0c 74 56 10 	movl   $0xf0105674,0xc(%esp)
f01016a1:	f0 
f01016a2:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01016a9:	f0 
f01016aa:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f01016b1:	00 
f01016b2:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01016b9:	e8 f8 e9 ff ff       	call   f01000b6 <_panic>
f01016be:	89 f0                	mov    %esi,%eax
f01016c0:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f01016c6:	c1 f8 03             	sar    $0x3,%eax
f01016c9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016cc:	89 c2                	mov    %eax,%edx
f01016ce:	c1 ea 0c             	shr    $0xc,%edx
f01016d1:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f01016d7:	72 20                	jb     f01016f9 <mem_init+0x534>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016dd:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f01016e4:	f0 
f01016e5:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01016ec:	00 
f01016ed:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f01016f4:	e8 bd e9 ff ff       	call   f01000b6 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01016f9:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101700:	00 
f0101701:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101708:	00 
	return (void *)(pa + KERNBASE);
f0101709:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010170e:	89 04 24             	mov    %eax,(%esp)
f0101711:	e8 11 34 00 00       	call   f0104b27 <memset>
	page_free(pp0);
f0101716:	89 34 24             	mov    %esi,(%esp)
f0101719:	e8 e1 f7 ff ff       	call   f0100eff <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010171e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101725:	e8 4a f7 ff ff       	call   f0100e74 <page_alloc>
f010172a:	85 c0                	test   %eax,%eax
f010172c:	75 24                	jne    f0101752 <mem_init+0x58d>
f010172e:	c7 44 24 0c 83 56 10 	movl   $0xf0105683,0xc(%esp)
f0101735:	f0 
f0101736:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010173d:	f0 
f010173e:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f0101745:	00 
f0101746:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010174d:	e8 64 e9 ff ff       	call   f01000b6 <_panic>
	assert(pp && pp0 == pp);
f0101752:	39 c6                	cmp    %eax,%esi
f0101754:	74 24                	je     f010177a <mem_init+0x5b5>
f0101756:	c7 44 24 0c a1 56 10 	movl   $0xf01056a1,0xc(%esp)
f010175d:	f0 
f010175e:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101765:	f0 
f0101766:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f010176d:	00 
f010176e:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101775:	e8 3c e9 ff ff       	call   f01000b6 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010177a:	89 f0                	mov    %esi,%eax
f010177c:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0101782:	c1 f8 03             	sar    $0x3,%eax
f0101785:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101788:	89 c2                	mov    %eax,%edx
f010178a:	c1 ea 0c             	shr    $0xc,%edx
f010178d:	3b 15 a4 de 17 f0    	cmp    0xf017dea4,%edx
f0101793:	72 20                	jb     f01017b5 <mem_init+0x5f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101795:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101799:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f01017a0:	f0 
f01017a1:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01017a8:	00 
f01017a9:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f01017b0:	e8 01 e9 ff ff       	call   f01000b6 <_panic>
f01017b5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01017bb:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01017c1:	80 38 00             	cmpb   $0x0,(%eax)
f01017c4:	74 24                	je     f01017ea <mem_init+0x625>
f01017c6:	c7 44 24 0c b1 56 10 	movl   $0xf01056b1,0xc(%esp)
f01017cd:	f0 
f01017ce:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01017d5:	f0 
f01017d6:	c7 44 24 04 e2 02 00 	movl   $0x2e2,0x4(%esp)
f01017dd:	00 
f01017de:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01017e5:	e8 cc e8 ff ff       	call   f01000b6 <_panic>
f01017ea:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01017ed:	39 d0                	cmp    %edx,%eax
f01017ef:	75 d0                	jne    f01017c1 <mem_init+0x5fc>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01017f1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01017f4:	a3 e0 d1 17 f0       	mov    %eax,0xf017d1e0

	// free the pages we took
	page_free(pp0);
f01017f9:	89 34 24             	mov    %esi,(%esp)
f01017fc:	e8 fe f6 ff ff       	call   f0100eff <page_free>
	page_free(pp1);
f0101801:	89 3c 24             	mov    %edi,(%esp)
f0101804:	e8 f6 f6 ff ff       	call   f0100eff <page_free>
	page_free(pp2);
f0101809:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010180c:	89 04 24             	mov    %eax,(%esp)
f010180f:	e8 eb f6 ff ff       	call   f0100eff <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101814:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f0101819:	eb 05                	jmp    f0101820 <mem_init+0x65b>
		--nfree;
f010181b:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010181e:	8b 00                	mov    (%eax),%eax
f0101820:	85 c0                	test   %eax,%eax
f0101822:	75 f7                	jne    f010181b <mem_init+0x656>
		--nfree;
	assert(nfree == 0);
f0101824:	85 db                	test   %ebx,%ebx
f0101826:	74 24                	je     f010184c <mem_init+0x687>
f0101828:	c7 44 24 0c bb 56 10 	movl   $0xf01056bb,0xc(%esp)
f010182f:	f0 
f0101830:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101837:	f0 
f0101838:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f010183f:	00 
f0101840:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101847:	e8 6a e8 ff ff       	call   f01000b6 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f010184c:	c7 04 24 64 59 10 f0 	movl   $0xf0105964,(%esp)
f0101853:	e8 89 1e 00 00       	call   f01036e1 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101858:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010185f:	e8 10 f6 ff ff       	call   f0100e74 <page_alloc>
f0101864:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101867:	85 c0                	test   %eax,%eax
f0101869:	75 24                	jne    f010188f <mem_init+0x6ca>
f010186b:	c7 44 24 0c c9 55 10 	movl   $0xf01055c9,0xc(%esp)
f0101872:	f0 
f0101873:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010187a:	f0 
f010187b:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101882:	00 
f0101883:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010188a:	e8 27 e8 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f010188f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101896:	e8 d9 f5 ff ff       	call   f0100e74 <page_alloc>
f010189b:	89 c3                	mov    %eax,%ebx
f010189d:	85 c0                	test   %eax,%eax
f010189f:	75 24                	jne    f01018c5 <mem_init+0x700>
f01018a1:	c7 44 24 0c df 55 10 	movl   $0xf01055df,0xc(%esp)
f01018a8:	f0 
f01018a9:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01018b0:	f0 
f01018b1:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f01018b8:	00 
f01018b9:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01018c0:	e8 f1 e7 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f01018c5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018cc:	e8 a3 f5 ff ff       	call   f0100e74 <page_alloc>
f01018d1:	89 c6                	mov    %eax,%esi
f01018d3:	85 c0                	test   %eax,%eax
f01018d5:	75 24                	jne    f01018fb <mem_init+0x736>
f01018d7:	c7 44 24 0c f5 55 10 	movl   $0xf01055f5,0xc(%esp)
f01018de:	f0 
f01018df:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01018e6:	f0 
f01018e7:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f01018ee:	00 
f01018ef:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01018f6:	e8 bb e7 ff ff       	call   f01000b6 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018fb:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01018fe:	75 24                	jne    f0101924 <mem_init+0x75f>
f0101900:	c7 44 24 0c 0b 56 10 	movl   $0xf010560b,0xc(%esp)
f0101907:	f0 
f0101908:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010190f:	f0 
f0101910:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0101917:	00 
f0101918:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010191f:	e8 92 e7 ff ff       	call   f01000b6 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101924:	39 c3                	cmp    %eax,%ebx
f0101926:	74 05                	je     f010192d <mem_init+0x768>
f0101928:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f010192b:	75 24                	jne    f0101951 <mem_init+0x78c>
f010192d:	c7 44 24 0c 44 59 10 	movl   $0xf0105944,0xc(%esp)
f0101934:	f0 
f0101935:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010193c:	f0 
f010193d:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0101944:	00 
f0101945:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010194c:	e8 65 e7 ff ff       	call   f01000b6 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101951:	a1 e0 d1 17 f0       	mov    0xf017d1e0,%eax
f0101956:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101959:	c7 05 e0 d1 17 f0 00 	movl   $0x0,0xf017d1e0
f0101960:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101963:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010196a:	e8 05 f5 ff ff       	call   f0100e74 <page_alloc>
f010196f:	85 c0                	test   %eax,%eax
f0101971:	74 24                	je     f0101997 <mem_init+0x7d2>
f0101973:	c7 44 24 0c 74 56 10 	movl   $0xf0105674,0xc(%esp)
f010197a:	f0 
f010197b:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101982:	f0 
f0101983:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f010198a:	00 
f010198b:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101992:	e8 1f e7 ff ff       	call   f01000b6 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101997:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010199a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010199e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01019a5:	00 
f01019a6:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01019ab:	89 04 24             	mov    %eax,(%esp)
f01019ae:	e8 d2 f6 ff ff       	call   f0101085 <page_lookup>
f01019b3:	85 c0                	test   %eax,%eax
f01019b5:	74 24                	je     f01019db <mem_init+0x816>
f01019b7:	c7 44 24 0c 84 59 10 	movl   $0xf0105984,0xc(%esp)
f01019be:	f0 
f01019bf:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01019c6:	f0 
f01019c7:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f01019ce:	00 
f01019cf:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01019d6:	e8 db e6 ff ff       	call   f01000b6 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01019db:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019e2:	00 
f01019e3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019ea:	00 
f01019eb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01019ef:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01019f4:	89 04 24             	mov    %eax,(%esp)
f01019f7:	e8 48 f7 ff ff       	call   f0101144 <page_insert>
f01019fc:	85 c0                	test   %eax,%eax
f01019fe:	78 24                	js     f0101a24 <mem_init+0x85f>
f0101a00:	c7 44 24 0c bc 59 10 	movl   $0xf01059bc,0xc(%esp)
f0101a07:	f0 
f0101a08:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101a0f:	f0 
f0101a10:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0101a17:	00 
f0101a18:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101a1f:	e8 92 e6 ff ff       	call   f01000b6 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101a24:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a27:	89 04 24             	mov    %eax,(%esp)
f0101a2a:	e8 d0 f4 ff ff       	call   f0100eff <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101a2f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a36:	00 
f0101a37:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101a3e:	00 
f0101a3f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a43:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101a48:	89 04 24             	mov    %eax,(%esp)
f0101a4b:	e8 f4 f6 ff ff       	call   f0101144 <page_insert>
f0101a50:	85 c0                	test   %eax,%eax
f0101a52:	74 24                	je     f0101a78 <mem_init+0x8b3>
f0101a54:	c7 44 24 0c ec 59 10 	movl   $0xf01059ec,0xc(%esp)
f0101a5b:	f0 
f0101a5c:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101a63:	f0 
f0101a64:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101a6b:	00 
f0101a6c:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101a73:	e8 3e e6 ff ff       	call   f01000b6 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a78:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a7e:	a1 ac de 17 f0       	mov    0xf017deac,%eax
f0101a83:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a86:	8b 17                	mov    (%edi),%edx
f0101a88:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a8e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101a91:	29 c1                	sub    %eax,%ecx
f0101a93:	89 c8                	mov    %ecx,%eax
f0101a95:	c1 f8 03             	sar    $0x3,%eax
f0101a98:	c1 e0 0c             	shl    $0xc,%eax
f0101a9b:	39 c2                	cmp    %eax,%edx
f0101a9d:	74 24                	je     f0101ac3 <mem_init+0x8fe>
f0101a9f:	c7 44 24 0c 1c 5a 10 	movl   $0xf0105a1c,0xc(%esp)
f0101aa6:	f0 
f0101aa7:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101aae:	f0 
f0101aaf:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0101ab6:	00 
f0101ab7:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101abe:	e8 f3 e5 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101ac3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ac8:	89 f8                	mov    %edi,%eax
f0101aca:	e8 50 ef ff ff       	call   f0100a1f <check_va2pa>
f0101acf:	89 da                	mov    %ebx,%edx
f0101ad1:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101ad4:	c1 fa 03             	sar    $0x3,%edx
f0101ad7:	c1 e2 0c             	shl    $0xc,%edx
f0101ada:	39 d0                	cmp    %edx,%eax
f0101adc:	74 24                	je     f0101b02 <mem_init+0x93d>
f0101ade:	c7 44 24 0c 44 5a 10 	movl   $0xf0105a44,0xc(%esp)
f0101ae5:	f0 
f0101ae6:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101aed:	f0 
f0101aee:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0101af5:	00 
f0101af6:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101afd:	e8 b4 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0101b02:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b07:	74 24                	je     f0101b2d <mem_init+0x968>
f0101b09:	c7 44 24 0c c6 56 10 	movl   $0xf01056c6,0xc(%esp)
f0101b10:	f0 
f0101b11:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101b18:	f0 
f0101b19:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0101b20:	00 
f0101b21:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101b28:	e8 89 e5 ff ff       	call   f01000b6 <_panic>
	assert(pp0->pp_ref == 1);
f0101b2d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b30:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b35:	74 24                	je     f0101b5b <mem_init+0x996>
f0101b37:	c7 44 24 0c d7 56 10 	movl   $0xf01056d7,0xc(%esp)
f0101b3e:	f0 
f0101b3f:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101b46:	f0 
f0101b47:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0101b4e:	00 
f0101b4f:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101b56:	e8 5b e5 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b5b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b62:	00 
f0101b63:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b6a:	00 
f0101b6b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101b6f:	89 3c 24             	mov    %edi,(%esp)
f0101b72:	e8 cd f5 ff ff       	call   f0101144 <page_insert>
f0101b77:	85 c0                	test   %eax,%eax
f0101b79:	74 24                	je     f0101b9f <mem_init+0x9da>
f0101b7b:	c7 44 24 0c 74 5a 10 	movl   $0xf0105a74,0xc(%esp)
f0101b82:	f0 
f0101b83:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101b8a:	f0 
f0101b8b:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0101b92:	00 
f0101b93:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101b9a:	e8 17 e5 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b9f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ba4:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101ba9:	e8 71 ee ff ff       	call   f0100a1f <check_va2pa>
f0101bae:	89 f2                	mov    %esi,%edx
f0101bb0:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0101bb6:	c1 fa 03             	sar    $0x3,%edx
f0101bb9:	c1 e2 0c             	shl    $0xc,%edx
f0101bbc:	39 d0                	cmp    %edx,%eax
f0101bbe:	74 24                	je     f0101be4 <mem_init+0xa1f>
f0101bc0:	c7 44 24 0c b0 5a 10 	movl   $0xf0105ab0,0xc(%esp)
f0101bc7:	f0 
f0101bc8:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101bcf:	f0 
f0101bd0:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f0101bd7:	00 
f0101bd8:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101bdf:	e8 d2 e4 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101be4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101be9:	74 24                	je     f0101c0f <mem_init+0xa4a>
f0101beb:	c7 44 24 0c e8 56 10 	movl   $0xf01056e8,0xc(%esp)
f0101bf2:	f0 
f0101bf3:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101bfa:	f0 
f0101bfb:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f0101c02:	00 
f0101c03:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101c0a:	e8 a7 e4 ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101c0f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c16:	e8 59 f2 ff ff       	call   f0100e74 <page_alloc>
f0101c1b:	85 c0                	test   %eax,%eax
f0101c1d:	74 24                	je     f0101c43 <mem_init+0xa7e>
f0101c1f:	c7 44 24 0c 74 56 10 	movl   $0xf0105674,0xc(%esp)
f0101c26:	f0 
f0101c27:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101c2e:	f0 
f0101c2f:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f0101c36:	00 
f0101c37:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101c3e:	e8 73 e4 ff ff       	call   f01000b6 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c43:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c4a:	00 
f0101c4b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c52:	00 
f0101c53:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c57:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101c5c:	89 04 24             	mov    %eax,(%esp)
f0101c5f:	e8 e0 f4 ff ff       	call   f0101144 <page_insert>
f0101c64:	85 c0                	test   %eax,%eax
f0101c66:	74 24                	je     f0101c8c <mem_init+0xac7>
f0101c68:	c7 44 24 0c 74 5a 10 	movl   $0xf0105a74,0xc(%esp)
f0101c6f:	f0 
f0101c70:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101c77:	f0 
f0101c78:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0101c7f:	00 
f0101c80:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101c87:	e8 2a e4 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c8c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c91:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101c96:	e8 84 ed ff ff       	call   f0100a1f <check_va2pa>
f0101c9b:	89 f2                	mov    %esi,%edx
f0101c9d:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0101ca3:	c1 fa 03             	sar    $0x3,%edx
f0101ca6:	c1 e2 0c             	shl    $0xc,%edx
f0101ca9:	39 d0                	cmp    %edx,%eax
f0101cab:	74 24                	je     f0101cd1 <mem_init+0xb0c>
f0101cad:	c7 44 24 0c b0 5a 10 	movl   $0xf0105ab0,0xc(%esp)
f0101cb4:	f0 
f0101cb5:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101cbc:	f0 
f0101cbd:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0101cc4:	00 
f0101cc5:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101ccc:	e8 e5 e3 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101cd1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cd6:	74 24                	je     f0101cfc <mem_init+0xb37>
f0101cd8:	c7 44 24 0c e8 56 10 	movl   $0xf01056e8,0xc(%esp)
f0101cdf:	f0 
f0101ce0:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101ce7:	f0 
f0101ce8:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0101cef:	00 
f0101cf0:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101cf7:	e8 ba e3 ff ff       	call   f01000b6 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cfc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d03:	e8 6c f1 ff ff       	call   f0100e74 <page_alloc>
f0101d08:	85 c0                	test   %eax,%eax
f0101d0a:	74 24                	je     f0101d30 <mem_init+0xb6b>
f0101d0c:	c7 44 24 0c 74 56 10 	movl   $0xf0105674,0xc(%esp)
f0101d13:	f0 
f0101d14:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101d1b:	f0 
f0101d1c:	c7 44 24 04 79 03 00 	movl   $0x379,0x4(%esp)
f0101d23:	00 
f0101d24:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101d2b:	e8 86 e3 ff ff       	call   f01000b6 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d30:	8b 15 a8 de 17 f0    	mov    0xf017dea8,%edx
f0101d36:	8b 02                	mov    (%edx),%eax
f0101d38:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d3d:	89 c1                	mov    %eax,%ecx
f0101d3f:	c1 e9 0c             	shr    $0xc,%ecx
f0101d42:	3b 0d a4 de 17 f0    	cmp    0xf017dea4,%ecx
f0101d48:	72 20                	jb     f0101d6a <mem_init+0xba5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d4a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101d4e:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0101d55:	f0 
f0101d56:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f0101d5d:	00 
f0101d5e:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101d65:	e8 4c e3 ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0101d6a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d6f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d72:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d79:	00 
f0101d7a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d81:	00 
f0101d82:	89 14 24             	mov    %edx,(%esp)
f0101d85:	e8 04 f2 ff ff       	call   f0100f8e <pgdir_walk>
f0101d8a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d8d:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d90:	39 d0                	cmp    %edx,%eax
f0101d92:	74 24                	je     f0101db8 <mem_init+0xbf3>
f0101d94:	c7 44 24 0c e0 5a 10 	movl   $0xf0105ae0,0xc(%esp)
f0101d9b:	f0 
f0101d9c:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101da3:	f0 
f0101da4:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f0101dab:	00 
f0101dac:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101db3:	e8 fe e2 ff ff       	call   f01000b6 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101db8:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101dbf:	00 
f0101dc0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dc7:	00 
f0101dc8:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101dcc:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101dd1:	89 04 24             	mov    %eax,(%esp)
f0101dd4:	e8 6b f3 ff ff       	call   f0101144 <page_insert>
f0101dd9:	85 c0                	test   %eax,%eax
f0101ddb:	74 24                	je     f0101e01 <mem_init+0xc3c>
f0101ddd:	c7 44 24 0c 20 5b 10 	movl   $0xf0105b20,0xc(%esp)
f0101de4:	f0 
f0101de5:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101dec:	f0 
f0101ded:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0101df4:	00 
f0101df5:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101dfc:	e8 b5 e2 ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e01:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
f0101e07:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e0c:	89 f8                	mov    %edi,%eax
f0101e0e:	e8 0c ec ff ff       	call   f0100a1f <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e13:	89 f2                	mov    %esi,%edx
f0101e15:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0101e1b:	c1 fa 03             	sar    $0x3,%edx
f0101e1e:	c1 e2 0c             	shl    $0xc,%edx
f0101e21:	39 d0                	cmp    %edx,%eax
f0101e23:	74 24                	je     f0101e49 <mem_init+0xc84>
f0101e25:	c7 44 24 0c b0 5a 10 	movl   $0xf0105ab0,0xc(%esp)
f0101e2c:	f0 
f0101e2d:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101e34:	f0 
f0101e35:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101e3c:	00 
f0101e3d:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101e44:	e8 6d e2 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0101e49:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e4e:	74 24                	je     f0101e74 <mem_init+0xcaf>
f0101e50:	c7 44 24 0c e8 56 10 	movl   $0xf01056e8,0xc(%esp)
f0101e57:	f0 
f0101e58:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101e5f:	f0 
f0101e60:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0101e67:	00 
f0101e68:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101e6f:	e8 42 e2 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e74:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e7b:	00 
f0101e7c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e83:	00 
f0101e84:	89 3c 24             	mov    %edi,(%esp)
f0101e87:	e8 02 f1 ff ff       	call   f0100f8e <pgdir_walk>
f0101e8c:	f6 00 04             	testb  $0x4,(%eax)
f0101e8f:	75 24                	jne    f0101eb5 <mem_init+0xcf0>
f0101e91:	c7 44 24 0c 60 5b 10 	movl   $0xf0105b60,0xc(%esp)
f0101e98:	f0 
f0101e99:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101ea0:	f0 
f0101ea1:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0101ea8:	00 
f0101ea9:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101eb0:	e8 01 e2 ff ff       	call   f01000b6 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101eb5:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101eba:	f6 00 04             	testb  $0x4,(%eax)
f0101ebd:	75 24                	jne    f0101ee3 <mem_init+0xd1e>
f0101ebf:	c7 44 24 0c f9 56 10 	movl   $0xf01056f9,0xc(%esp)
f0101ec6:	f0 
f0101ec7:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101ece:	f0 
f0101ecf:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0101ed6:	00 
f0101ed7:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101ede:	e8 d3 e1 ff ff       	call   f01000b6 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ee3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101eea:	00 
f0101eeb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ef2:	00 
f0101ef3:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101ef7:	89 04 24             	mov    %eax,(%esp)
f0101efa:	e8 45 f2 ff ff       	call   f0101144 <page_insert>
f0101eff:	85 c0                	test   %eax,%eax
f0101f01:	74 24                	je     f0101f27 <mem_init+0xd62>
f0101f03:	c7 44 24 0c 74 5a 10 	movl   $0xf0105a74,0xc(%esp)
f0101f0a:	f0 
f0101f0b:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101f12:	f0 
f0101f13:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f0101f1a:	00 
f0101f1b:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101f22:	e8 8f e1 ff ff       	call   f01000b6 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101f27:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f2e:	00 
f0101f2f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f36:	00 
f0101f37:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101f3c:	89 04 24             	mov    %eax,(%esp)
f0101f3f:	e8 4a f0 ff ff       	call   f0100f8e <pgdir_walk>
f0101f44:	f6 00 02             	testb  $0x2,(%eax)
f0101f47:	75 24                	jne    f0101f6d <mem_init+0xda8>
f0101f49:	c7 44 24 0c 94 5b 10 	movl   $0xf0105b94,0xc(%esp)
f0101f50:	f0 
f0101f51:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101f58:	f0 
f0101f59:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0101f60:	00 
f0101f61:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101f68:	e8 49 e1 ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f6d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f74:	00 
f0101f75:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f7c:	00 
f0101f7d:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101f82:	89 04 24             	mov    %eax,(%esp)
f0101f85:	e8 04 f0 ff ff       	call   f0100f8e <pgdir_walk>
f0101f8a:	f6 00 04             	testb  $0x4,(%eax)
f0101f8d:	74 24                	je     f0101fb3 <mem_init+0xdee>
f0101f8f:	c7 44 24 0c c8 5b 10 	movl   $0xf0105bc8,0xc(%esp)
f0101f96:	f0 
f0101f97:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101f9e:	f0 
f0101f9f:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0101fa6:	00 
f0101fa7:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101fae:	e8 03 e1 ff ff       	call   f01000b6 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101fb3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fba:	00 
f0101fbb:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101fc2:	00 
f0101fc3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101fca:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0101fcf:	89 04 24             	mov    %eax,(%esp)
f0101fd2:	e8 6d f1 ff ff       	call   f0101144 <page_insert>
f0101fd7:	85 c0                	test   %eax,%eax
f0101fd9:	78 24                	js     f0101fff <mem_init+0xe3a>
f0101fdb:	c7 44 24 0c 00 5c 10 	movl   $0xf0105c00,0xc(%esp)
f0101fe2:	f0 
f0101fe3:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0101fea:	f0 
f0101feb:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0101ff2:	00 
f0101ff3:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0101ffa:	e8 b7 e0 ff ff       	call   f01000b6 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101fff:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102006:	00 
f0102007:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010200e:	00 
f010200f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102013:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102018:	89 04 24             	mov    %eax,(%esp)
f010201b:	e8 24 f1 ff ff       	call   f0101144 <page_insert>
f0102020:	85 c0                	test   %eax,%eax
f0102022:	74 24                	je     f0102048 <mem_init+0xe83>
f0102024:	c7 44 24 0c 38 5c 10 	movl   $0xf0105c38,0xc(%esp)
f010202b:	f0 
f010202c:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102033:	f0 
f0102034:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f010203b:	00 
f010203c:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102043:	e8 6e e0 ff ff       	call   f01000b6 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102048:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010204f:	00 
f0102050:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102057:	00 
f0102058:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010205d:	89 04 24             	mov    %eax,(%esp)
f0102060:	e8 29 ef ff ff       	call   f0100f8e <pgdir_walk>
f0102065:	f6 00 04             	testb  $0x4,(%eax)
f0102068:	74 24                	je     f010208e <mem_init+0xec9>
f010206a:	c7 44 24 0c c8 5b 10 	movl   $0xf0105bc8,0xc(%esp)
f0102071:	f0 
f0102072:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102079:	f0 
f010207a:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f0102081:	00 
f0102082:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102089:	e8 28 e0 ff ff       	call   f01000b6 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010208e:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
f0102094:	ba 00 00 00 00       	mov    $0x0,%edx
f0102099:	89 f8                	mov    %edi,%eax
f010209b:	e8 7f e9 ff ff       	call   f0100a1f <check_va2pa>
f01020a0:	89 c1                	mov    %eax,%ecx
f01020a2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01020a5:	89 d8                	mov    %ebx,%eax
f01020a7:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f01020ad:	c1 f8 03             	sar    $0x3,%eax
f01020b0:	c1 e0 0c             	shl    $0xc,%eax
f01020b3:	39 c1                	cmp    %eax,%ecx
f01020b5:	74 24                	je     f01020db <mem_init+0xf16>
f01020b7:	c7 44 24 0c 74 5c 10 	movl   $0xf0105c74,0xc(%esp)
f01020be:	f0 
f01020bf:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01020c6:	f0 
f01020c7:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f01020ce:	00 
f01020cf:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01020d6:	e8 db df ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020db:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020e0:	89 f8                	mov    %edi,%eax
f01020e2:	e8 38 e9 ff ff       	call   f0100a1f <check_va2pa>
f01020e7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01020ea:	74 24                	je     f0102110 <mem_init+0xf4b>
f01020ec:	c7 44 24 0c a0 5c 10 	movl   $0xf0105ca0,0xc(%esp)
f01020f3:	f0 
f01020f4:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01020fb:	f0 
f01020fc:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102103:	00 
f0102104:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010210b:	e8 a6 df ff ff       	call   f01000b6 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102110:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102115:	74 24                	je     f010213b <mem_init+0xf76>
f0102117:	c7 44 24 0c 0f 57 10 	movl   $0xf010570f,0xc(%esp)
f010211e:	f0 
f010211f:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102126:	f0 
f0102127:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f010212e:	00 
f010212f:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102136:	e8 7b df ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010213b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102140:	74 24                	je     f0102166 <mem_init+0xfa1>
f0102142:	c7 44 24 0c 20 57 10 	movl   $0xf0105720,0xc(%esp)
f0102149:	f0 
f010214a:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102151:	f0 
f0102152:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102159:	00 
f010215a:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102161:	e8 50 df ff ff       	call   f01000b6 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102166:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010216d:	e8 02 ed ff ff       	call   f0100e74 <page_alloc>
f0102172:	85 c0                	test   %eax,%eax
f0102174:	74 04                	je     f010217a <mem_init+0xfb5>
f0102176:	39 c6                	cmp    %eax,%esi
f0102178:	74 24                	je     f010219e <mem_init+0xfd9>
f010217a:	c7 44 24 0c d0 5c 10 	movl   $0xf0105cd0,0xc(%esp)
f0102181:	f0 
f0102182:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102189:	f0 
f010218a:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f0102191:	00 
f0102192:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102199:	e8 18 df ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010219e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01021a5:	00 
f01021a6:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01021ab:	89 04 24             	mov    %eax,(%esp)
f01021ae:	e8 4c ef ff ff       	call   f01010ff <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021b3:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
f01021b9:	ba 00 00 00 00       	mov    $0x0,%edx
f01021be:	89 f8                	mov    %edi,%eax
f01021c0:	e8 5a e8 ff ff       	call   f0100a1f <check_va2pa>
f01021c5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021c8:	74 24                	je     f01021ee <mem_init+0x1029>
f01021ca:	c7 44 24 0c f4 5c 10 	movl   $0xf0105cf4,0xc(%esp)
f01021d1:	f0 
f01021d2:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01021d9:	f0 
f01021da:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f01021e1:	00 
f01021e2:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01021e9:	e8 c8 de ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01021ee:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021f3:	89 f8                	mov    %edi,%eax
f01021f5:	e8 25 e8 ff ff       	call   f0100a1f <check_va2pa>
f01021fa:	89 da                	mov    %ebx,%edx
f01021fc:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0102202:	c1 fa 03             	sar    $0x3,%edx
f0102205:	c1 e2 0c             	shl    $0xc,%edx
f0102208:	39 d0                	cmp    %edx,%eax
f010220a:	74 24                	je     f0102230 <mem_init+0x106b>
f010220c:	c7 44 24 0c a0 5c 10 	movl   $0xf0105ca0,0xc(%esp)
f0102213:	f0 
f0102214:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010221b:	f0 
f010221c:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102223:	00 
f0102224:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010222b:	e8 86 de ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 1);
f0102230:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102235:	74 24                	je     f010225b <mem_init+0x1096>
f0102237:	c7 44 24 0c c6 56 10 	movl   $0xf01056c6,0xc(%esp)
f010223e:	f0 
f010223f:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102246:	f0 
f0102247:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f010224e:	00 
f010224f:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102256:	e8 5b de ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f010225b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102260:	74 24                	je     f0102286 <mem_init+0x10c1>
f0102262:	c7 44 24 0c 20 57 10 	movl   $0xf0105720,0xc(%esp)
f0102269:	f0 
f010226a:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102271:	f0 
f0102272:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102279:	00 
f010227a:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102281:	e8 30 de ff ff       	call   f01000b6 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102286:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010228d:	00 
f010228e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102295:	00 
f0102296:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010229a:	89 3c 24             	mov    %edi,(%esp)
f010229d:	e8 a2 ee ff ff       	call   f0101144 <page_insert>
f01022a2:	85 c0                	test   %eax,%eax
f01022a4:	74 24                	je     f01022ca <mem_init+0x1105>
f01022a6:	c7 44 24 0c 18 5d 10 	movl   $0xf0105d18,0xc(%esp)
f01022ad:	f0 
f01022ae:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01022b5:	f0 
f01022b6:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01022bd:	00 
f01022be:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01022c5:	e8 ec dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref);
f01022ca:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01022cf:	75 24                	jne    f01022f5 <mem_init+0x1130>
f01022d1:	c7 44 24 0c 31 57 10 	movl   $0xf0105731,0xc(%esp)
f01022d8:	f0 
f01022d9:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01022e0:	f0 
f01022e1:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f01022e8:	00 
f01022e9:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01022f0:	e8 c1 dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_link == NULL);
f01022f5:	83 3b 00             	cmpl   $0x0,(%ebx)
f01022f8:	74 24                	je     f010231e <mem_init+0x1159>
f01022fa:	c7 44 24 0c 3d 57 10 	movl   $0xf010573d,0xc(%esp)
f0102301:	f0 
f0102302:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102309:	f0 
f010230a:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f0102311:	00 
f0102312:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102319:	e8 98 dd ff ff       	call   f01000b6 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010231e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102325:	00 
f0102326:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010232b:	89 04 24             	mov    %eax,(%esp)
f010232e:	e8 cc ed ff ff       	call   f01010ff <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102333:	8b 3d a8 de 17 f0    	mov    0xf017dea8,%edi
f0102339:	ba 00 00 00 00       	mov    $0x0,%edx
f010233e:	89 f8                	mov    %edi,%eax
f0102340:	e8 da e6 ff ff       	call   f0100a1f <check_va2pa>
f0102345:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102348:	74 24                	je     f010236e <mem_init+0x11a9>
f010234a:	c7 44 24 0c f4 5c 10 	movl   $0xf0105cf4,0xc(%esp)
f0102351:	f0 
f0102352:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102359:	f0 
f010235a:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102361:	00 
f0102362:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102369:	e8 48 dd ff ff       	call   f01000b6 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010236e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102373:	89 f8                	mov    %edi,%eax
f0102375:	e8 a5 e6 ff ff       	call   f0100a1f <check_va2pa>
f010237a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010237d:	74 24                	je     f01023a3 <mem_init+0x11de>
f010237f:	c7 44 24 0c 50 5d 10 	movl   $0xf0105d50,0xc(%esp)
f0102386:	f0 
f0102387:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010238e:	f0 
f010238f:	c7 44 24 04 ab 03 00 	movl   $0x3ab,0x4(%esp)
f0102396:	00 
f0102397:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010239e:	e8 13 dd ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f01023a3:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01023a8:	74 24                	je     f01023ce <mem_init+0x1209>
f01023aa:	c7 44 24 0c 52 57 10 	movl   $0xf0105752,0xc(%esp)
f01023b1:	f0 
f01023b2:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01023b9:	f0 
f01023ba:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f01023c1:	00 
f01023c2:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01023c9:	e8 e8 dc ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 0);
f01023ce:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023d3:	74 24                	je     f01023f9 <mem_init+0x1234>
f01023d5:	c7 44 24 0c 20 57 10 	movl   $0xf0105720,0xc(%esp)
f01023dc:	f0 
f01023dd:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01023e4:	f0 
f01023e5:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f01023ec:	00 
f01023ed:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01023f4:	e8 bd dc ff ff       	call   f01000b6 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01023f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102400:	e8 6f ea ff ff       	call   f0100e74 <page_alloc>
f0102405:	85 c0                	test   %eax,%eax
f0102407:	74 04                	je     f010240d <mem_init+0x1248>
f0102409:	39 c3                	cmp    %eax,%ebx
f010240b:	74 24                	je     f0102431 <mem_init+0x126c>
f010240d:	c7 44 24 0c 78 5d 10 	movl   $0xf0105d78,0xc(%esp)
f0102414:	f0 
f0102415:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010241c:	f0 
f010241d:	c7 44 24 04 b0 03 00 	movl   $0x3b0,0x4(%esp)
f0102424:	00 
f0102425:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010242c:	e8 85 dc ff ff       	call   f01000b6 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102431:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102438:	e8 37 ea ff ff       	call   f0100e74 <page_alloc>
f010243d:	85 c0                	test   %eax,%eax
f010243f:	74 24                	je     f0102465 <mem_init+0x12a0>
f0102441:	c7 44 24 0c 74 56 10 	movl   $0xf0105674,0xc(%esp)
f0102448:	f0 
f0102449:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102450:	f0 
f0102451:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0102458:	00 
f0102459:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102460:	e8 51 dc ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102465:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010246a:	8b 08                	mov    (%eax),%ecx
f010246c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102472:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102475:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f010247b:	c1 fa 03             	sar    $0x3,%edx
f010247e:	c1 e2 0c             	shl    $0xc,%edx
f0102481:	39 d1                	cmp    %edx,%ecx
f0102483:	74 24                	je     f01024a9 <mem_init+0x12e4>
f0102485:	c7 44 24 0c 1c 5a 10 	movl   $0xf0105a1c,0xc(%esp)
f010248c:	f0 
f010248d:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102494:	f0 
f0102495:	c7 44 24 04 b6 03 00 	movl   $0x3b6,0x4(%esp)
f010249c:	00 
f010249d:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01024a4:	e8 0d dc ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f01024a9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01024af:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024b2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01024b7:	74 24                	je     f01024dd <mem_init+0x1318>
f01024b9:	c7 44 24 0c d7 56 10 	movl   $0xf01056d7,0xc(%esp)
f01024c0:	f0 
f01024c1:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01024c8:	f0 
f01024c9:	c7 44 24 04 b8 03 00 	movl   $0x3b8,0x4(%esp)
f01024d0:	00 
f01024d1:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01024d8:	e8 d9 db ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f01024dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01024e0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01024e6:	89 04 24             	mov    %eax,(%esp)
f01024e9:	e8 11 ea ff ff       	call   f0100eff <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01024ee:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024f5:	00 
f01024f6:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01024fd:	00 
f01024fe:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102503:	89 04 24             	mov    %eax,(%esp)
f0102506:	e8 83 ea ff ff       	call   f0100f8e <pgdir_walk>
f010250b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010250e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102511:	8b 15 a8 de 17 f0    	mov    0xf017dea8,%edx
f0102517:	8b 7a 04             	mov    0x4(%edx),%edi
f010251a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102520:	8b 0d a4 de 17 f0    	mov    0xf017dea4,%ecx
f0102526:	89 f8                	mov    %edi,%eax
f0102528:	c1 e8 0c             	shr    $0xc,%eax
f010252b:	39 c8                	cmp    %ecx,%eax
f010252d:	72 20                	jb     f010254f <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010252f:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102533:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f010253a:	f0 
f010253b:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0102542:	00 
f0102543:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010254a:	e8 67 db ff ff       	call   f01000b6 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010254f:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102555:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102558:	74 24                	je     f010257e <mem_init+0x13b9>
f010255a:	c7 44 24 0c 63 57 10 	movl   $0xf0105763,0xc(%esp)
f0102561:	f0 
f0102562:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102569:	f0 
f010256a:	c7 44 24 04 c0 03 00 	movl   $0x3c0,0x4(%esp)
f0102571:	00 
f0102572:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102579:	e8 38 db ff ff       	call   f01000b6 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010257e:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102585:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102588:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010258e:	2b 05 ac de 17 f0    	sub    0xf017deac,%eax
f0102594:	c1 f8 03             	sar    $0x3,%eax
f0102597:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010259a:	89 c2                	mov    %eax,%edx
f010259c:	c1 ea 0c             	shr    $0xc,%edx
f010259f:	39 d1                	cmp    %edx,%ecx
f01025a1:	77 20                	ja     f01025c3 <mem_init+0x13fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025a7:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f01025ae:	f0 
f01025af:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01025b6:	00 
f01025b7:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f01025be:	e8 f3 da ff ff       	call   f01000b6 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01025c3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025ca:	00 
f01025cb:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01025d2:	00 
	return (void *)(pa + KERNBASE);
f01025d3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025d8:	89 04 24             	mov    %eax,(%esp)
f01025db:	e8 47 25 00 00       	call   f0104b27 <memset>
	page_free(pp0);
f01025e0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01025e3:	89 3c 24             	mov    %edi,(%esp)
f01025e6:	e8 14 e9 ff ff       	call   f0100eff <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01025eb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01025f2:	00 
f01025f3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025fa:	00 
f01025fb:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102600:	89 04 24             	mov    %eax,(%esp)
f0102603:	e8 86 e9 ff ff       	call   f0100f8e <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102608:	89 fa                	mov    %edi,%edx
f010260a:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0102610:	c1 fa 03             	sar    $0x3,%edx
f0102613:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102616:	89 d0                	mov    %edx,%eax
f0102618:	c1 e8 0c             	shr    $0xc,%eax
f010261b:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f0102621:	72 20                	jb     f0102643 <mem_init+0x147e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102623:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102627:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f010262e:	f0 
f010262f:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102636:	00 
f0102637:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f010263e:	e8 73 da ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f0102643:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102649:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010264c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102652:	f6 00 01             	testb  $0x1,(%eax)
f0102655:	74 24                	je     f010267b <mem_init+0x14b6>
f0102657:	c7 44 24 0c 7b 57 10 	movl   $0xf010577b,0xc(%esp)
f010265e:	f0 
f010265f:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102666:	f0 
f0102667:	c7 44 24 04 ca 03 00 	movl   $0x3ca,0x4(%esp)
f010266e:	00 
f010266f:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102676:	e8 3b da ff ff       	call   f01000b6 <_panic>
f010267b:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010267e:	39 d0                	cmp    %edx,%eax
f0102680:	75 d0                	jne    f0102652 <mem_init+0x148d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102682:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102687:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010268d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102690:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102696:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102699:	89 3d e0 d1 17 f0    	mov    %edi,0xf017d1e0

	// free the pages we took
	page_free(pp0);
f010269f:	89 04 24             	mov    %eax,(%esp)
f01026a2:	e8 58 e8 ff ff       	call   f0100eff <page_free>
	page_free(pp1);
f01026a7:	89 1c 24             	mov    %ebx,(%esp)
f01026aa:	e8 50 e8 ff ff       	call   f0100eff <page_free>
	page_free(pp2);
f01026af:	89 34 24             	mov    %esi,(%esp)
f01026b2:	e8 48 e8 ff ff       	call   f0100eff <page_free>

	cprintf("check_page() succeeded!\n");
f01026b7:	c7 04 24 92 57 10 f0 	movl   $0xf0105792,(%esp)
f01026be:	e8 1e 10 00 00       	call   f01036e1 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01026c3:	a1 ac de 17 f0       	mov    0xf017deac,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026c8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026cd:	77 20                	ja     f01026ef <mem_init+0x152a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026d3:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f01026da:	f0 
f01026db:	c7 44 24 04 b8 00 00 	movl   $0xb8,0x4(%esp)
f01026e2:	00 
f01026e3:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01026ea:	e8 c7 d9 ff ff       	call   f01000b6 <_panic>
f01026ef:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01026f6:	00 
	return (physaddr_t)kva - KERNBASE;
f01026f7:	05 00 00 00 10       	add    $0x10000000,%eax
f01026fc:	89 04 24             	mov    %eax,(%esp)
f01026ff:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102704:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102709:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010270e:	e8 1b e9 ff ff       	call   f010102e <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);	
f0102713:	a1 ec d1 17 f0       	mov    0xf017d1ec,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102718:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010271d:	77 20                	ja     f010273f <mem_init+0x157a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010271f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102723:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f010272a:	f0 
f010272b:	c7 44 24 04 c1 00 00 	movl   $0xc1,0x4(%esp)
f0102732:	00 
f0102733:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010273a:	e8 77 d9 ff ff       	call   f01000b6 <_panic>
f010273f:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102746:	00 
	return (physaddr_t)kva - KERNBASE;
f0102747:	05 00 00 00 10       	add    $0x10000000,%eax
f010274c:	89 04 24             	mov    %eax,(%esp)
f010274f:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102754:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102759:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f010275e:	e8 cb e8 ff ff       	call   f010102e <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102763:	bb 00 10 11 f0       	mov    $0xf0111000,%ebx
f0102768:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f010276e:	77 20                	ja     f0102790 <mem_init+0x15cb>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102770:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102774:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f010277b:	f0 
f010277c:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
f0102783:	00 
f0102784:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010278b:	e8 26 d9 ff ff       	call   f01000b6 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102790:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102797:	00 
f0102798:	c7 04 24 00 10 11 00 	movl   $0x111000,(%esp)
f010279f:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027a4:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01027a9:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01027ae:	e8 7b e8 ff ff       	call   f010102e <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff-KERNBASE, 0, PTE_W);
f01027b3:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01027ba:	00 
f01027bb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027c2:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f01027c7:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027cc:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01027d1:	e8 58 e8 ff ff       	call   f010102e <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01027d6:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f01027db:	89 45 d4             	mov    %eax,-0x2c(%ebp)

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01027de:	a1 a4 de 17 f0       	mov    0xf017dea4,%eax
f01027e3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01027e6:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01027ed:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01027f2:	89 45 cc             	mov    %eax,-0x34(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01027f5:	8b 3d ac de 17 f0    	mov    0xf017deac,%edi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027fb:	89 7d c8             	mov    %edi,-0x38(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f01027fe:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0102804:	89 45 c4             	mov    %eax,-0x3c(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102807:	be 00 00 00 00       	mov    $0x0,%esi
f010280c:	eb 6b                	jmp    f0102879 <mem_init+0x16b4>
f010280e:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102814:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102817:	e8 03 e2 ff ff       	call   f0100a1f <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010281c:	81 7d c8 ff ff ff ef 	cmpl   $0xefffffff,-0x38(%ebp)
f0102823:	77 20                	ja     f0102845 <mem_init+0x1680>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102825:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102829:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f0102830:	f0 
f0102831:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0102838:	00 
f0102839:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102840:	e8 71 d8 ff ff       	call   f01000b6 <_panic>
f0102845:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0102848:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010284b:	39 d0                	cmp    %edx,%eax
f010284d:	74 24                	je     f0102873 <mem_init+0x16ae>
f010284f:	c7 44 24 0c 9c 5d 10 	movl   $0xf0105d9c,0xc(%esp)
f0102856:	f0 
f0102857:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010285e:	f0 
f010285f:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0102866:	00 
f0102867:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010286e:	e8 43 d8 ff ff       	call   f01000b6 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102873:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102879:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f010287c:	77 90                	ja     f010280e <mem_init+0x1649>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f010287e:	8b 35 ec d1 17 f0    	mov    0xf017d1ec,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102884:	89 f7                	mov    %esi,%edi
f0102886:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f010288b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010288e:	e8 8c e1 ff ff       	call   f0100a1f <check_va2pa>
f0102893:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102899:	77 20                	ja     f01028bb <mem_init+0x16f6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010289b:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010289f:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f01028a6:	f0 
f01028a7:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f01028ae:	00 
f01028af:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01028b6:	e8 fb d7 ff ff       	call   f01000b6 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028bb:	be 00 00 c0 ee       	mov    $0xeec00000,%esi
f01028c0:	81 c7 00 00 40 21    	add    $0x21400000,%edi
f01028c6:	8d 14 37             	lea    (%edi,%esi,1),%edx
f01028c9:	39 c2                	cmp    %eax,%edx
f01028cb:	74 24                	je     f01028f1 <mem_init+0x172c>
f01028cd:	c7 44 24 0c d0 5d 10 	movl   $0xf0105dd0,0xc(%esp)
f01028d4:	f0 
f01028d5:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01028dc:	f0 
f01028dd:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f01028e4:	00 
f01028e5:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01028ec:	e8 c5 d7 ff ff       	call   f01000b6 <_panic>
f01028f1:	81 c6 00 10 00 00    	add    $0x1000,%esi
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028f7:	81 fe 00 80 c1 ee    	cmp    $0xeec18000,%esi
f01028fd:	0f 85 26 05 00 00    	jne    f0102e29 <mem_init+0x1c64>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102903:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0102906:	c1 e7 0c             	shl    $0xc,%edi
f0102909:	be 00 00 00 00       	mov    $0x0,%esi
f010290e:	eb 3c                	jmp    f010294c <mem_init+0x1787>
f0102910:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102916:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102919:	e8 01 e1 ff ff       	call   f0100a1f <check_va2pa>
f010291e:	39 c6                	cmp    %eax,%esi
f0102920:	74 24                	je     f0102946 <mem_init+0x1781>
f0102922:	c7 44 24 0c 04 5e 10 	movl   $0xf0105e04,0xc(%esp)
f0102929:	f0 
f010292a:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102931:	f0 
f0102932:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0102939:	00 
f010293a:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102941:	e8 70 d7 ff ff       	call   f01000b6 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102946:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010294c:	39 fe                	cmp    %edi,%esi
f010294e:	72 c0                	jb     f0102910 <mem_init+0x174b>
f0102950:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0102955:	81 c3 00 80 00 20    	add    $0x20008000,%ebx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010295b:	89 f2                	mov    %esi,%edx
f010295d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102960:	e8 ba e0 ff ff       	call   f0100a1f <check_va2pa>
f0102965:	8d 14 33             	lea    (%ebx,%esi,1),%edx
f0102968:	39 d0                	cmp    %edx,%eax
f010296a:	74 24                	je     f0102990 <mem_init+0x17cb>
f010296c:	c7 44 24 0c 2c 5e 10 	movl   $0xf0105e2c,0xc(%esp)
f0102973:	f0 
f0102974:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f010297b:	f0 
f010297c:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102983:	00 
f0102984:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f010298b:	e8 26 d7 ff ff       	call   f01000b6 <_panic>
f0102990:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102996:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f010299c:	75 bd                	jne    f010295b <mem_init+0x1796>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f010299e:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01029a3:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01029a6:	89 f8                	mov    %edi,%eax
f01029a8:	e8 72 e0 ff ff       	call   f0100a1f <check_va2pa>
f01029ad:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029b0:	75 0c                	jne    f01029be <mem_init+0x17f9>
f01029b2:	b8 00 00 00 00       	mov    $0x0,%eax
f01029b7:	89 fa                	mov    %edi,%edx
f01029b9:	e9 f0 00 00 00       	jmp    f0102aae <mem_init+0x18e9>
f01029be:	c7 44 24 0c 74 5e 10 	movl   $0xf0105e74,0xc(%esp)
f01029c5:	f0 
f01029c6:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f01029cd:	f0 
f01029ce:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f01029d5:	00 
f01029d6:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f01029dd:	e8 d4 d6 ff ff       	call   f01000b6 <_panic>

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01029e2:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01029e7:	72 3c                	jb     f0102a25 <mem_init+0x1860>
f01029e9:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01029ee:	76 07                	jbe    f01029f7 <mem_init+0x1832>
f01029f0:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01029f5:	75 2e                	jne    f0102a25 <mem_init+0x1860>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01029f7:	f6 04 82 01          	testb  $0x1,(%edx,%eax,4)
f01029fb:	0f 85 aa 00 00 00    	jne    f0102aab <mem_init+0x18e6>
f0102a01:	c7 44 24 0c ab 57 10 	movl   $0xf01057ab,0xc(%esp)
f0102a08:	f0 
f0102a09:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102a10:	f0 
f0102a11:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0102a18:	00 
f0102a19:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102a20:	e8 91 d6 ff ff       	call   f01000b6 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a25:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a2a:	76 55                	jbe    f0102a81 <mem_init+0x18bc>
				assert(pgdir[i] & PTE_P);
f0102a2c:	8b 0c 82             	mov    (%edx,%eax,4),%ecx
f0102a2f:	f6 c1 01             	test   $0x1,%cl
f0102a32:	75 24                	jne    f0102a58 <mem_init+0x1893>
f0102a34:	c7 44 24 0c ab 57 10 	movl   $0xf01057ab,0xc(%esp)
f0102a3b:	f0 
f0102a3c:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102a43:	f0 
f0102a44:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0102a4b:	00 
f0102a4c:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102a53:	e8 5e d6 ff ff       	call   f01000b6 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a58:	f6 c1 02             	test   $0x2,%cl
f0102a5b:	75 4e                	jne    f0102aab <mem_init+0x18e6>
f0102a5d:	c7 44 24 0c bc 57 10 	movl   $0xf01057bc,0xc(%esp)
f0102a64:	f0 
f0102a65:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102a6c:	f0 
f0102a6d:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0102a74:	00 
f0102a75:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102a7c:	e8 35 d6 ff ff       	call   f01000b6 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a81:	83 3c 82 00          	cmpl   $0x0,(%edx,%eax,4)
f0102a85:	74 24                	je     f0102aab <mem_init+0x18e6>
f0102a87:	c7 44 24 0c cd 57 10 	movl   $0xf01057cd,0xc(%esp)
f0102a8e:	f0 
f0102a8f:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102a96:	f0 
f0102a97:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0102a9e:	00 
f0102a9f:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102aa6:	e8 0b d6 ff ff       	call   f01000b6 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102aab:	83 c0 01             	add    $0x1,%eax
f0102aae:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102ab3:	0f 85 29 ff ff ff    	jne    f01029e2 <mem_init+0x181d>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102ab9:	c7 04 24 a4 5e 10 f0 	movl   $0xf0105ea4,(%esp)
f0102ac0:	e8 1c 0c 00 00       	call   f01036e1 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102ac5:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102aca:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102acf:	77 20                	ja     f0102af1 <mem_init+0x192c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ad1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ad5:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f0102adc:	f0 
f0102add:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
f0102ae4:	00 
f0102ae5:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102aec:	e8 c5 d5 ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102af1:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102af6:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102af9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102afe:	e8 8b df ff ff       	call   f0100a8e <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b03:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b06:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b09:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b0e:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b11:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b18:	e8 57 e3 ff ff       	call   f0100e74 <page_alloc>
f0102b1d:	89 c3                	mov    %eax,%ebx
f0102b1f:	85 c0                	test   %eax,%eax
f0102b21:	75 24                	jne    f0102b47 <mem_init+0x1982>
f0102b23:	c7 44 24 0c c9 55 10 	movl   $0xf01055c9,0xc(%esp)
f0102b2a:	f0 
f0102b2b:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102b32:	f0 
f0102b33:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102b3a:	00 
f0102b3b:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102b42:	e8 6f d5 ff ff       	call   f01000b6 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b47:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b4e:	e8 21 e3 ff ff       	call   f0100e74 <page_alloc>
f0102b53:	89 c7                	mov    %eax,%edi
f0102b55:	85 c0                	test   %eax,%eax
f0102b57:	75 24                	jne    f0102b7d <mem_init+0x19b8>
f0102b59:	c7 44 24 0c df 55 10 	movl   $0xf01055df,0xc(%esp)
f0102b60:	f0 
f0102b61:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102b68:	f0 
f0102b69:	c7 44 24 04 e6 03 00 	movl   $0x3e6,0x4(%esp)
f0102b70:	00 
f0102b71:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102b78:	e8 39 d5 ff ff       	call   f01000b6 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b7d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b84:	e8 eb e2 ff ff       	call   f0100e74 <page_alloc>
f0102b89:	89 c6                	mov    %eax,%esi
f0102b8b:	85 c0                	test   %eax,%eax
f0102b8d:	75 24                	jne    f0102bb3 <mem_init+0x19ee>
f0102b8f:	c7 44 24 0c f5 55 10 	movl   $0xf01055f5,0xc(%esp)
f0102b96:	f0 
f0102b97:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102b9e:	f0 
f0102b9f:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102ba6:	00 
f0102ba7:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102bae:	e8 03 d5 ff ff       	call   f01000b6 <_panic>
	page_free(pp0);
f0102bb3:	89 1c 24             	mov    %ebx,(%esp)
f0102bb6:	e8 44 e3 ff ff       	call   f0100eff <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0102bbb:	89 f8                	mov    %edi,%eax
f0102bbd:	e8 18 de ff ff       	call   f01009da <page2kva>
f0102bc2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bc9:	00 
f0102bca:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102bd1:	00 
f0102bd2:	89 04 24             	mov    %eax,(%esp)
f0102bd5:	e8 4d 1f 00 00       	call   f0104b27 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0102bda:	89 f0                	mov    %esi,%eax
f0102bdc:	e8 f9 dd ff ff       	call   f01009da <page2kva>
f0102be1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102be8:	00 
f0102be9:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102bf0:	00 
f0102bf1:	89 04 24             	mov    %eax,(%esp)
f0102bf4:	e8 2e 1f 00 00       	call   f0104b27 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102bf9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c00:	00 
f0102c01:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c08:	00 
f0102c09:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102c0d:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102c12:	89 04 24             	mov    %eax,(%esp)
f0102c15:	e8 2a e5 ff ff       	call   f0101144 <page_insert>
	assert(pp1->pp_ref == 1);
f0102c1a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c1f:	74 24                	je     f0102c45 <mem_init+0x1a80>
f0102c21:	c7 44 24 0c c6 56 10 	movl   $0xf01056c6,0xc(%esp)
f0102c28:	f0 
f0102c29:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102c30:	f0 
f0102c31:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0102c38:	00 
f0102c39:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102c40:	e8 71 d4 ff ff       	call   f01000b6 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c45:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c4c:	01 01 01 
f0102c4f:	74 24                	je     f0102c75 <mem_init+0x1ab0>
f0102c51:	c7 44 24 0c c4 5e 10 	movl   $0xf0105ec4,0xc(%esp)
f0102c58:	f0 
f0102c59:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102c60:	f0 
f0102c61:	c7 44 24 04 ed 03 00 	movl   $0x3ed,0x4(%esp)
f0102c68:	00 
f0102c69:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102c70:	e8 41 d4 ff ff       	call   f01000b6 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c75:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c7c:	00 
f0102c7d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c84:	00 
f0102c85:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102c89:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102c8e:	89 04 24             	mov    %eax,(%esp)
f0102c91:	e8 ae e4 ff ff       	call   f0101144 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c96:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c9d:	02 02 02 
f0102ca0:	74 24                	je     f0102cc6 <mem_init+0x1b01>
f0102ca2:	c7 44 24 0c e8 5e 10 	movl   $0xf0105ee8,0xc(%esp)
f0102ca9:	f0 
f0102caa:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102cb1:	f0 
f0102cb2:	c7 44 24 04 ef 03 00 	movl   $0x3ef,0x4(%esp)
f0102cb9:	00 
f0102cba:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102cc1:	e8 f0 d3 ff ff       	call   f01000b6 <_panic>
	assert(pp2->pp_ref == 1);
f0102cc6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ccb:	74 24                	je     f0102cf1 <mem_init+0x1b2c>
f0102ccd:	c7 44 24 0c e8 56 10 	movl   $0xf01056e8,0xc(%esp)
f0102cd4:	f0 
f0102cd5:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102cdc:	f0 
f0102cdd:	c7 44 24 04 f0 03 00 	movl   $0x3f0,0x4(%esp)
f0102ce4:	00 
f0102ce5:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102cec:	e8 c5 d3 ff ff       	call   f01000b6 <_panic>
	assert(pp1->pp_ref == 0);
f0102cf1:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cf6:	74 24                	je     f0102d1c <mem_init+0x1b57>
f0102cf8:	c7 44 24 0c 52 57 10 	movl   $0xf0105752,0xc(%esp)
f0102cff:	f0 
f0102d00:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102d07:	f0 
f0102d08:	c7 44 24 04 f1 03 00 	movl   $0x3f1,0x4(%esp)
f0102d0f:	00 
f0102d10:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102d17:	e8 9a d3 ff ff       	call   f01000b6 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d1c:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d23:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d26:	89 f0                	mov    %esi,%eax
f0102d28:	e8 ad dc ff ff       	call   f01009da <page2kva>
f0102d2d:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f0102d33:	74 24                	je     f0102d59 <mem_init+0x1b94>
f0102d35:	c7 44 24 0c 0c 5f 10 	movl   $0xf0105f0c,0xc(%esp)
f0102d3c:	f0 
f0102d3d:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102d44:	f0 
f0102d45:	c7 44 24 04 f3 03 00 	movl   $0x3f3,0x4(%esp)
f0102d4c:	00 
f0102d4d:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102d54:	e8 5d d3 ff ff       	call   f01000b6 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d59:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102d60:	00 
f0102d61:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102d66:	89 04 24             	mov    %eax,(%esp)
f0102d69:	e8 91 e3 ff ff       	call   f01010ff <page_remove>
	assert(pp2->pp_ref == 0);
f0102d6e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d73:	74 24                	je     f0102d99 <mem_init+0x1bd4>
f0102d75:	c7 44 24 0c 20 57 10 	movl   $0xf0105720,0xc(%esp)
f0102d7c:	f0 
f0102d7d:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102d84:	f0 
f0102d85:	c7 44 24 04 f5 03 00 	movl   $0x3f5,0x4(%esp)
f0102d8c:	00 
f0102d8d:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102d94:	e8 1d d3 ff ff       	call   f01000b6 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d99:	a1 a8 de 17 f0       	mov    0xf017dea8,%eax
f0102d9e:	8b 08                	mov    (%eax),%ecx
f0102da0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102da6:	89 da                	mov    %ebx,%edx
f0102da8:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f0102dae:	c1 fa 03             	sar    $0x3,%edx
f0102db1:	c1 e2 0c             	shl    $0xc,%edx
f0102db4:	39 d1                	cmp    %edx,%ecx
f0102db6:	74 24                	je     f0102ddc <mem_init+0x1c17>
f0102db8:	c7 44 24 0c 1c 5a 10 	movl   $0xf0105a1c,0xc(%esp)
f0102dbf:	f0 
f0102dc0:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102dc7:	f0 
f0102dc8:	c7 44 24 04 f8 03 00 	movl   $0x3f8,0x4(%esp)
f0102dcf:	00 
f0102dd0:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102dd7:	e8 da d2 ff ff       	call   f01000b6 <_panic>
	kern_pgdir[0] = 0;
f0102ddc:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102de2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102de7:	74 24                	je     f0102e0d <mem_init+0x1c48>
f0102de9:	c7 44 24 0c d7 56 10 	movl   $0xf01056d7,0xc(%esp)
f0102df0:	f0 
f0102df1:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0102df8:	f0 
f0102df9:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f0102e00:	00 
f0102e01:	c7 04 24 d4 54 10 f0 	movl   $0xf01054d4,(%esp)
f0102e08:	e8 a9 d2 ff ff       	call   f01000b6 <_panic>
	pp0->pp_ref = 0;
f0102e0d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e13:	89 1c 24             	mov    %ebx,(%esp)
f0102e16:	e8 e4 e0 ff ff       	call   f0100eff <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e1b:	c7 04 24 38 5f 10 f0 	movl   $0xf0105f38,(%esp)
f0102e22:	e8 ba 08 00 00       	call   f01036e1 <cprintf>
f0102e27:	eb 0f                	jmp    f0102e38 <mem_init+0x1c73>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102e29:	89 f2                	mov    %esi,%edx
f0102e2b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e2e:	e8 ec db ff ff       	call   f0100a1f <check_va2pa>
f0102e33:	e9 8e fa ff ff       	jmp    f01028c6 <mem_init+0x1701>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e38:	83 c4 4c             	add    $0x4c,%esp
f0102e3b:	5b                   	pop    %ebx
f0102e3c:	5e                   	pop    %esi
f0102e3d:	5f                   	pop    %edi
f0102e3e:	5d                   	pop    %ebp
f0102e3f:	c3                   	ret    

f0102e40 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102e40:	55                   	push   %ebp
f0102e41:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102e43:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e46:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102e49:	5d                   	pop    %ebp
f0102e4a:	c3                   	ret    

f0102e4b <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e4b:	55                   	push   %ebp
f0102e4c:	89 e5                	mov    %esp,%ebp
f0102e4e:	57                   	push   %edi
f0102e4f:	56                   	push   %esi
f0102e50:	53                   	push   %ebx
f0102e51:	83 ec 2c             	sub    $0x2c,%esp
f0102e54:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102e57:	8b 75 14             	mov    0x14(%ebp),%esi
	// LAB 3: Your code here.
	char * end = NULL;
	char * start = NULL;
	start = ROUNDDOWN((char *)va, PGSIZE); 
f0102e5a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e5d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e62:	89 c3                	mov    %eax,%ebx
f0102e64:	89 45 e0             	mov    %eax,-0x20(%ebp)
	end = ROUNDUP((char *)(va + len), PGSIZE);
f0102e67:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e6a:	03 45 10             	add    0x10(%ebp),%eax
f0102e6d:	05 ff 0f 00 00       	add    $0xfff,%eax
f0102e72:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102e77:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	pte_t *cur = NULL;

	for(; start < end; start += PGSIZE) {
f0102e7a:	eb 54                	jmp    f0102ed0 <user_mem_check+0x85>
		cur = pgdir_walk(env->env_pgdir, (void *)start, 0);
f0102e7c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102e83:	00 
f0102e84:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102e88:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102e8b:	89 04 24             	mov    %eax,(%esp)
f0102e8e:	e8 fb e0 ff ff       	call   f0100f8e <pgdir_walk>
		if((int)start > ULIM || cur == NULL || ((uint32_t)(*cur) & perm) != perm) {
f0102e93:	89 da                	mov    %ebx,%edx
f0102e95:	85 c0                	test   %eax,%eax
f0102e97:	74 10                	je     f0102ea9 <user_mem_check+0x5e>
f0102e99:	81 fb 00 00 80 ef    	cmp    $0xef800000,%ebx
f0102e9f:	77 08                	ja     f0102ea9 <user_mem_check+0x5e>
f0102ea1:	89 f1                	mov    %esi,%ecx
f0102ea3:	23 08                	and    (%eax),%ecx
f0102ea5:	39 ce                	cmp    %ecx,%esi
f0102ea7:	74 21                	je     f0102eca <user_mem_check+0x7f>
			  if(start == ROUNDDOWN((char *)va, PGSIZE)) {
f0102ea9:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f0102eac:	75 0f                	jne    f0102ebd <user_mem_check+0x72>
					user_mem_check_addr = (uintptr_t)va;
f0102eae:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102eb1:	a3 dc d1 17 f0       	mov    %eax,0xf017d1dc
			  }
			  else {
			  		user_mem_check_addr = (uintptr_t)start;
			  }
			  return -E_FAULT;
f0102eb6:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102ebb:	eb 1d                	jmp    f0102eda <user_mem_check+0x8f>
		if((int)start > ULIM || cur == NULL || ((uint32_t)(*cur) & perm) != perm) {
			  if(start == ROUNDDOWN((char *)va, PGSIZE)) {
					user_mem_check_addr = (uintptr_t)va;
			  }
			  else {
			  		user_mem_check_addr = (uintptr_t)start;
f0102ebd:	89 15 dc d1 17 f0    	mov    %edx,0xf017d1dc
			  }
			  return -E_FAULT;
f0102ec3:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102ec8:	eb 10                	jmp    f0102eda <user_mem_check+0x8f>
	char * start = NULL;
	start = ROUNDDOWN((char *)va, PGSIZE); 
	end = ROUNDUP((char *)(va + len), PGSIZE);
	pte_t *cur = NULL;

	for(; start < end; start += PGSIZE) {
f0102eca:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102ed0:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0102ed3:	72 a7                	jb     f0102e7c <user_mem_check+0x31>
			  return -E_FAULT;
		}
		
	}
		
	return 0;
f0102ed5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102eda:	83 c4 2c             	add    $0x2c,%esp
f0102edd:	5b                   	pop    %ebx
f0102ede:	5e                   	pop    %esi
f0102edf:	5f                   	pop    %edi
f0102ee0:	5d                   	pop    %ebp
f0102ee1:	c3                   	ret    

f0102ee2 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102ee2:	55                   	push   %ebp
f0102ee3:	89 e5                	mov    %esp,%ebp
f0102ee5:	53                   	push   %ebx
f0102ee6:	83 ec 14             	sub    $0x14,%esp
f0102ee9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102eec:	8b 45 14             	mov    0x14(%ebp),%eax
f0102eef:	83 c8 04             	or     $0x4,%eax
f0102ef2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ef6:	8b 45 10             	mov    0x10(%ebp),%eax
f0102ef9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102efd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f00:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f04:	89 1c 24             	mov    %ebx,(%esp)
f0102f07:	e8 3f ff ff ff       	call   f0102e4b <user_mem_check>
f0102f0c:	85 c0                	test   %eax,%eax
f0102f0e:	79 24                	jns    f0102f34 <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f10:	a1 dc d1 17 f0       	mov    0xf017d1dc,%eax
f0102f15:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f19:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f1c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f20:	c7 04 24 64 5f 10 f0 	movl   $0xf0105f64,(%esp)
f0102f27:	e8 b5 07 00 00       	call   f01036e1 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f2c:	89 1c 24             	mov    %ebx,(%esp)
f0102f2f:	e8 7a 06 00 00       	call   f01035ae <env_destroy>
	}
}
f0102f34:	83 c4 14             	add    $0x14,%esp
f0102f37:	5b                   	pop    %ebx
f0102f38:	5d                   	pop    %ebp
f0102f39:	c3                   	ret    

f0102f3a <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f3a:	55                   	push   %ebp
f0102f3b:	89 e5                	mov    %esp,%ebp
f0102f3d:	57                   	push   %edi
f0102f3e:	56                   	push   %esi
f0102f3f:	53                   	push   %ebx
f0102f40:	83 ec 1c             	sub    $0x1c,%esp
f0102f43:	89 c7                	mov    %eax,%edi
	// LAB 3: Your code here.
	// (But only if you need it for load_icode.)
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
f0102f45:	89 d3                	mov    %edx,%ebx
f0102f47:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
f0102f4d:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102f54:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE){
f0102f5a:	eb 6d                	jmp    f0102fc9 <region_alloc+0x8f>
		p = page_alloc(0);
f0102f5c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f63:	e8 0c df ff ff       	call   f0100e74 <page_alloc>
		if(p == NULL)
f0102f68:	85 c0                	test   %eax,%eax
f0102f6a:	75 1c                	jne    f0102f88 <region_alloc+0x4e>
			panic(" region alloc, allocation failed.");
f0102f6c:	c7 44 24 08 9c 5f 10 	movl   $0xf0105f9c,0x8(%esp)
f0102f73:	f0 
f0102f74:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
f0102f7b:	00 
f0102f7c:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f0102f83:	e8 2e d1 ff ff       	call   f01000b6 <_panic>

		r = page_insert(e->env_pgdir, p, i, PTE_W | PTE_U);
f0102f88:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102f8f:	00 
f0102f90:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102f94:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f98:	8b 47 5c             	mov    0x5c(%edi),%eax
f0102f9b:	89 04 24             	mov    %eax,(%esp)
f0102f9e:	e8 a1 e1 ff ff       	call   f0101144 <page_insert>
		if(r != 0) {
f0102fa3:	85 c0                	test   %eax,%eax
f0102fa5:	74 1c                	je     f0102fc3 <region_alloc+0x89>
			panic("region alloc error");
f0102fa7:	c7 44 24 08 91 60 10 	movl   $0xf0106091,0x8(%esp)
f0102fae:	f0 
f0102faf:	c7 44 24 04 28 01 00 	movl   $0x128,0x4(%esp)
f0102fb6:	00 
f0102fb7:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f0102fbe:	e8 f3 d0 ff ff       	call   f01000b6 <_panic>
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
	struct PageInfo *p = NULL;
	void* i;
	int r;
	for(i=start; i<end; i+=PGSIZE){
f0102fc3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102fc9:	39 f3                	cmp    %esi,%ebx
f0102fcb:	72 8f                	jb     f0102f5c <region_alloc+0x22>
	}
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
}
f0102fcd:	83 c4 1c             	add    $0x1c,%esp
f0102fd0:	5b                   	pop    %ebx
f0102fd1:	5e                   	pop    %esi
f0102fd2:	5f                   	pop    %edi
f0102fd3:	5d                   	pop    %ebp
f0102fd4:	c3                   	ret    

f0102fd5 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102fd5:	55                   	push   %ebp
f0102fd6:	89 e5                	mov    %esp,%ebp
f0102fd8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fdb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102fde:	85 c0                	test   %eax,%eax
f0102fe0:	75 11                	jne    f0102ff3 <envid2env+0x1e>
		*env_store = curenv;
f0102fe2:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0102fe7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102fea:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102fec:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ff1:	eb 5e                	jmp    f0103051 <envid2env+0x7c>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102ff3:	89 c2                	mov    %eax,%edx
f0102ff5:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102ffb:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102ffe:	c1 e2 05             	shl    $0x5,%edx
f0103001:	03 15 ec d1 17 f0    	add    0xf017d1ec,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103007:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f010300b:	74 05                	je     f0103012 <envid2env+0x3d>
f010300d:	39 42 48             	cmp    %eax,0x48(%edx)
f0103010:	74 10                	je     f0103022 <envid2env+0x4d>
		*env_store = 0;
f0103012:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103015:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010301b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103020:	eb 2f                	jmp    f0103051 <envid2env+0x7c>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103022:	84 c9                	test   %cl,%cl
f0103024:	74 21                	je     f0103047 <envid2env+0x72>
f0103026:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f010302b:	39 c2                	cmp    %eax,%edx
f010302d:	74 18                	je     f0103047 <envid2env+0x72>
f010302f:	8b 40 48             	mov    0x48(%eax),%eax
f0103032:	39 42 4c             	cmp    %eax,0x4c(%edx)
f0103035:	74 10                	je     f0103047 <envid2env+0x72>
		*env_store = 0;
f0103037:	8b 45 0c             	mov    0xc(%ebp),%eax
f010303a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103040:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103045:	eb 0a                	jmp    f0103051 <envid2env+0x7c>
	}

	*env_store = e;
f0103047:	8b 45 0c             	mov    0xc(%ebp),%eax
f010304a:	89 10                	mov    %edx,(%eax)
	return 0;
f010304c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103051:	5d                   	pop    %ebp
f0103052:	c3                   	ret    

f0103053 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103053:	55                   	push   %ebp
f0103054:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103056:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f010305b:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f010305e:	b8 23 00 00 00       	mov    $0x23,%eax
f0103063:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0103065:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0103067:	b0 10                	mov    $0x10,%al
f0103069:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f010306b:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f010306d:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f010306f:	ea 76 30 10 f0 08 00 	ljmp   $0x8,$0xf0103076
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0103076:	b0 00                	mov    $0x0,%al
f0103078:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f010307b:	5d                   	pop    %ebp
f010307c:	c3                   	ret    

f010307d <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f010307d:	55                   	push   %ebp
f010307e:	89 e5                	mov    %esp,%ebp
f0103080:	56                   	push   %esi
f0103081:	53                   	push   %ebx
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--){
		envs[i].env_id = 0;
f0103082:	8b 35 ec d1 17 f0    	mov    0xf017d1ec,%esi
f0103088:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f010308e:	ba 00 04 00 00       	mov    $0x400,%edx
f0103093:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103098:	89 c3                	mov    %eax,%ebx
f010309a:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_status = ENV_FREE;
f01030a1:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		envs[i].env_link = env_free_list;
f01030a8:	89 48 44             	mov    %ecx,0x44(%eax)
f01030ab:	83 e8 60             	sub    $0x60,%eax
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	env_free_list = NULL;
	for(i=NENV-1; i>=0; i--){
f01030ae:	83 ea 01             	sub    $0x1,%edx
f01030b1:	74 04                	je     f01030b7 <env_init+0x3a>
		envs[i].env_id = 0;
		envs[i].env_status = ENV_FREE;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
f01030b3:	89 d9                	mov    %ebx,%ecx
f01030b5:	eb e1                	jmp    f0103098 <env_init+0x1b>
f01030b7:	89 35 f0 d1 17 f0    	mov    %esi,0xf017d1f0
	}
	// Per-CPU part of the initialization
	env_init_percpu();
f01030bd:	e8 91 ff ff ff       	call   f0103053 <env_init_percpu>
}
f01030c2:	5b                   	pop    %ebx
f01030c3:	5e                   	pop    %esi
f01030c4:	5d                   	pop    %ebp
f01030c5:	c3                   	ret    

f01030c6 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01030c6:	55                   	push   %ebp
f01030c7:	89 e5                	mov    %esp,%ebp
f01030c9:	53                   	push   %ebx
f01030ca:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01030cd:	8b 1d f0 d1 17 f0    	mov    0xf017d1f0,%ebx
f01030d3:	85 db                	test   %ebx,%ebx
f01030d5:	0f 84 8e 01 00 00    	je     f0103269 <env_alloc+0x1a3>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f01030db:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01030e2:	e8 8d dd ff ff       	call   f0100e74 <page_alloc>
f01030e7:	85 c0                	test   %eax,%eax
f01030e9:	0f 84 81 01 00 00    	je     f0103270 <env_alloc+0x1aa>
f01030ef:	89 c2                	mov    %eax,%edx
f01030f1:	2b 15 ac de 17 f0    	sub    0xf017deac,%edx
f01030f7:	c1 fa 03             	sar    $0x3,%edx
f01030fa:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01030fd:	89 d1                	mov    %edx,%ecx
f01030ff:	c1 e9 0c             	shr    $0xc,%ecx
f0103102:	3b 0d a4 de 17 f0    	cmp    0xf017dea4,%ecx
f0103108:	72 20                	jb     f010312a <env_alloc+0x64>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010310a:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010310e:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f0103115:	f0 
f0103116:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010311d:	00 
f010311e:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f0103125:	e8 8c cf ff ff       	call   f01000b6 <_panic>
	return (void *)(pa + KERNBASE);
f010312a:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0103130:	89 53 5c             	mov    %edx,0x5c(%ebx)
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;
f0103133:	66 83 40 04 01       	addw   $0x1,0x4(%eax)

	//Map the directory below UTOP.
	for(i = 0; i < PDX(UTOP); i++) {
f0103138:	b8 00 00 00 00       	mov    $0x0,%eax
f010313d:	ba 00 00 00 00       	mov    $0x0,%edx
		e->env_pgdir[i] = 0;		
f0103142:	8b 4b 5c             	mov    0x5c(%ebx),%ecx
f0103145:	c7 04 91 00 00 00 00 	movl   $0x0,(%ecx,%edx,4)
	// LAB 3: Your code here.
	e->env_pgdir = (pde_t *)page2kva(p);
	p->pp_ref++;

	//Map the directory below UTOP.
	for(i = 0; i < PDX(UTOP); i++) {
f010314c:	83 c0 01             	add    $0x1,%eax
f010314f:	89 c2                	mov    %eax,%edx
f0103151:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0103156:	75 ea                	jne    f0103142 <env_alloc+0x7c>
f0103158:	66 b8 ec 0e          	mov    $0xeec,%ax
		e->env_pgdir[i] = 0;		
	}

	//Map the directory above UTOP
	for(i = PDX(UTOP); i < NPDENTRIES; i++) {
		e->env_pgdir[i] = kern_pgdir[i];
f010315c:	8b 15 a8 de 17 f0    	mov    0xf017dea8,%edx
f0103162:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103165:	8b 53 5c             	mov    0x5c(%ebx),%edx
f0103168:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f010316b:	83 c0 04             	add    $0x4,%eax
	for(i = 0; i < PDX(UTOP); i++) {
		e->env_pgdir[i] = 0;		
	}

	//Map the directory above UTOP
	for(i = PDX(UTOP); i < NPDENTRIES; i++) {
f010316e:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0103173:	75 e7                	jne    f010315c <env_alloc+0x96>
		e->env_pgdir[i] = kern_pgdir[i];
	}
		
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103175:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103178:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010317d:	77 20                	ja     f010319f <env_alloc+0xd9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010317f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103183:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f010318a:	f0 
f010318b:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
f0103192:	00 
f0103193:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f010319a:	e8 17 cf ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010319f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01031a5:	83 ca 05             	or     $0x5,%edx
f01031a8:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01031ae:	8b 43 48             	mov    0x48(%ebx),%eax
f01031b1:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01031b6:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01031bb:	ba 00 10 00 00       	mov    $0x1000,%edx
f01031c0:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01031c3:	89 da                	mov    %ebx,%edx
f01031c5:	2b 15 ec d1 17 f0    	sub    0xf017d1ec,%edx
f01031cb:	c1 fa 05             	sar    $0x5,%edx
f01031ce:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01031d4:	09 d0                	or     %edx,%eax
f01031d6:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01031d9:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031dc:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01031df:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01031e6:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01031ed:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01031f4:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f01031fb:	00 
f01031fc:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103203:	00 
f0103204:	89 1c 24             	mov    %ebx,(%esp)
f0103207:	e8 1b 19 00 00       	call   f0104b27 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f010320c:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103212:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103218:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f010321e:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103225:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f010322b:	8b 43 44             	mov    0x44(%ebx),%eax
f010322e:	a3 f0 d1 17 f0       	mov    %eax,0xf017d1f0
	*newenv_store = e;
f0103233:	8b 45 08             	mov    0x8(%ebp),%eax
f0103236:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103238:	8b 53 48             	mov    0x48(%ebx),%edx
f010323b:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103240:	85 c0                	test   %eax,%eax
f0103242:	74 05                	je     f0103249 <env_alloc+0x183>
f0103244:	8b 40 48             	mov    0x48(%eax),%eax
f0103247:	eb 05                	jmp    f010324e <env_alloc+0x188>
f0103249:	b8 00 00 00 00       	mov    $0x0,%eax
f010324e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103252:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103256:	c7 04 24 a4 60 10 f0 	movl   $0xf01060a4,(%esp)
f010325d:	e8 7f 04 00 00       	call   f01036e1 <cprintf>
	return 0;
f0103262:	b8 00 00 00 00       	mov    $0x0,%eax
f0103267:	eb 0c                	jmp    f0103275 <env_alloc+0x1af>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103269:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010326e:	eb 05                	jmp    f0103275 <env_alloc+0x1af>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103270:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103275:	83 c4 14             	add    $0x14,%esp
f0103278:	5b                   	pop    %ebx
f0103279:	5d                   	pop    %ebp
f010327a:	c3                   	ret    

f010327b <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010327b:	55                   	push   %ebp
f010327c:	89 e5                	mov    %esp,%ebp
f010327e:	57                   	push   %edi
f010327f:	56                   	push   %esi
f0103280:	53                   	push   %ebx
f0103281:	83 ec 3c             	sub    $0x3c,%esp
f0103284:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	struct Env *e;
	int rc;
	if((rc = env_alloc(&e, 0)) != 0) {
f0103287:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010328e:	00 
f010328f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103292:	89 04 24             	mov    %eax,(%esp)
f0103295:	e8 2c fe ff ff       	call   f01030c6 <env_alloc>
f010329a:	85 c0                	test   %eax,%eax
f010329c:	74 1c                	je     f01032ba <env_create+0x3f>
		panic("env_create failed: env_alloc failed.\n");
f010329e:	c7 44 24 08 c0 5f 10 	movl   $0xf0105fc0,0x8(%esp)
f01032a5:	f0 
f01032a6:	c7 44 24 04 98 01 00 	movl   $0x198,0x4(%esp)
f01032ad:	00 
f01032ae:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f01032b5:	e8 fc cd ff ff       	call   f01000b6 <_panic>
	}

	load_icode(e, binary);
f01032ba:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032bd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
	struct Elf* header = (struct Elf*)binary;
	
	if(header->e_magic != ELF_MAGIC) {
f01032c0:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01032c6:	74 1c                	je     f01032e4 <env_create+0x69>
		panic("load_icode failed: The binary we load is not elf.\n");
f01032c8:	c7 44 24 08 e8 5f 10 	movl   $0xf0105fe8,0x8(%esp)
f01032cf:	f0 
f01032d0:	c7 44 24 04 6a 01 00 	movl   $0x16a,0x4(%esp)
f01032d7:	00 
f01032d8:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f01032df:	e8 d2 cd ff ff       	call   f01000b6 <_panic>
	}

	if(header->e_entry == 0){
f01032e4:	8b 47 18             	mov    0x18(%edi),%eax
f01032e7:	85 c0                	test   %eax,%eax
f01032e9:	75 1c                	jne    f0103307 <env_create+0x8c>
		panic("load_icode failed: The elf file can't be excuterd.\n");
f01032eb:	c7 44 24 08 1c 60 10 	movl   $0xf010601c,0x8(%esp)
f01032f2:	f0 
f01032f3:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
f01032fa:	00 
f01032fb:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f0103302:	e8 af cd ff ff       	call   f01000b6 <_panic>
	}

	e->env_tf.tf_eip = header->e_entry;
f0103307:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010330a:	89 41 30             	mov    %eax,0x30(%ecx)

	lcr3(PADDR(e->env_pgdir));   //?????
f010330d:	8b 41 5c             	mov    0x5c(%ecx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103310:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103315:	77 20                	ja     f0103337 <env_create+0xbc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103317:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010331b:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f0103322:	f0 
f0103323:	c7 44 24 04 73 01 00 	movl   $0x173,0x4(%esp)
f010332a:	00 
f010332b:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f0103332:	e8 7f cd ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103337:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010333c:	0f 22 d8             	mov    %eax,%cr3

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
f010333f:	89 fb                	mov    %edi,%ebx
f0103341:	03 5f 1c             	add    0x1c(%edi),%ebx
	eph = ph + header->e_phnum;
f0103344:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103348:	c1 e6 05             	shl    $0x5,%esi
f010334b:	01 de                	add    %ebx,%esi
f010334d:	eb 50                	jmp    f010339f <env_create+0x124>
	for(; ph < eph; ph++) {
		if(ph->p_type == ELF_PROG_LOAD) {
f010334f:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103352:	75 48                	jne    f010339c <env_create+0x121>
			if(ph->p_memsz - ph->p_filesz < 0) {
				panic("load icode failed : p_memsz < p_filesz.\n");
			}

			region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0103354:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103357:	8b 53 08             	mov    0x8(%ebx),%edx
f010335a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010335d:	e8 d8 fb ff ff       	call   f0102f3a <region_alloc>
			memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103362:	8b 43 10             	mov    0x10(%ebx),%eax
f0103365:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103369:	89 f8                	mov    %edi,%eax
f010336b:	03 43 04             	add    0x4(%ebx),%eax
f010336e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103372:	8b 43 08             	mov    0x8(%ebx),%eax
f0103375:	89 04 24             	mov    %eax,(%esp)
f0103378:	e8 f7 17 00 00       	call   f0104b74 <memmove>
			memset((void *)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f010337d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103380:	8b 53 14             	mov    0x14(%ebx),%edx
f0103383:	29 c2                	sub    %eax,%edx
f0103385:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103389:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103390:	00 
f0103391:	03 43 08             	add    0x8(%ebx),%eax
f0103394:	89 04 24             	mov    %eax,(%esp)
f0103397:	e8 8b 17 00 00       	call   f0104b27 <memset>
	lcr3(PADDR(e->env_pgdir));   //?????

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
	eph = ph + header->e_phnum;
	for(; ph < eph; ph++) {
f010339c:	83 c3 20             	add    $0x20,%ebx
f010339f:	39 de                	cmp    %ebx,%esi
f01033a1:	77 ac                	ja     f010334f <env_create+0xd4>
		}
	} 
	 
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.
	region_alloc(e,(void *)(USTACKTOP-PGSIZE), PGSIZE);
f01033a3:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01033a8:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01033ad:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033b0:	e8 85 fb ff ff       	call   f0102f3a <region_alloc>
	if((rc = env_alloc(&e, 0)) != 0) {
		panic("env_create failed: env_alloc failed.\n");
	}

	load_icode(e, binary);
	e->env_type = type;
f01033b5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033b8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033bb:	89 50 50             	mov    %edx,0x50(%eax)
}
f01033be:	83 c4 3c             	add    $0x3c,%esp
f01033c1:	5b                   	pop    %ebx
f01033c2:	5e                   	pop    %esi
f01033c3:	5f                   	pop    %edi
f01033c4:	5d                   	pop    %ebp
f01033c5:	c3                   	ret    

f01033c6 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033c6:	55                   	push   %ebp
f01033c7:	89 e5                	mov    %esp,%ebp
f01033c9:	57                   	push   %edi
f01033ca:	56                   	push   %esi
f01033cb:	53                   	push   %ebx
f01033cc:	83 ec 2c             	sub    $0x2c,%esp
f01033cf:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033d2:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f01033d7:	39 c7                	cmp    %eax,%edi
f01033d9:	75 37                	jne    f0103412 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f01033db:	8b 15 a8 de 17 f0    	mov    0xf017dea8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033e1:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01033e7:	77 20                	ja     f0103409 <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033e9:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01033ed:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f01033f4:	f0 
f01033f5:	c7 44 24 04 ad 01 00 	movl   $0x1ad,0x4(%esp)
f01033fc:	00 
f01033fd:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f0103404:	e8 ad cc ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103409:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f010340f:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103412:	8b 57 48             	mov    0x48(%edi),%edx
f0103415:	85 c0                	test   %eax,%eax
f0103417:	74 05                	je     f010341e <env_free+0x58>
f0103419:	8b 40 48             	mov    0x48(%eax),%eax
f010341c:	eb 05                	jmp    f0103423 <env_free+0x5d>
f010341e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103423:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103427:	89 44 24 04          	mov    %eax,0x4(%esp)
f010342b:	c7 04 24 b9 60 10 f0 	movl   $0xf01060b9,(%esp)
f0103432:	e8 aa 02 00 00       	call   f01036e1 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103437:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f010343e:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103441:	89 c8                	mov    %ecx,%eax
f0103443:	c1 e0 02             	shl    $0x2,%eax
f0103446:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103449:	8b 47 5c             	mov    0x5c(%edi),%eax
f010344c:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f010344f:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103455:	0f 84 b7 00 00 00    	je     f0103512 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010345b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103461:	89 f0                	mov    %esi,%eax
f0103463:	c1 e8 0c             	shr    $0xc,%eax
f0103466:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103469:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f010346f:	72 20                	jb     f0103491 <env_free+0xcb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103471:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103475:	c7 44 24 08 dc 57 10 	movl   $0xf01057dc,0x8(%esp)
f010347c:	f0 
f010347d:	c7 44 24 04 bc 01 00 	movl   $0x1bc,0x4(%esp)
f0103484:	00 
f0103485:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f010348c:	e8 25 cc ff ff       	call   f01000b6 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103491:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103494:	c1 e0 16             	shl    $0x16,%eax
f0103497:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010349a:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010349f:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01034a6:	01 
f01034a7:	74 17                	je     f01034c0 <env_free+0xfa>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034a9:	89 d8                	mov    %ebx,%eax
f01034ab:	c1 e0 0c             	shl    $0xc,%eax
f01034ae:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01034b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034b5:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034b8:	89 04 24             	mov    %eax,(%esp)
f01034bb:	e8 3f dc ff ff       	call   f01010ff <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034c0:	83 c3 01             	add    $0x1,%ebx
f01034c3:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01034c9:	75 d4                	jne    f010349f <env_free+0xd9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01034cb:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034ce:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034d1:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034d8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01034db:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f01034e1:	72 1c                	jb     f01034ff <env_free+0x139>
		panic("pa2page called with invalid pa");
f01034e3:	c7 44 24 08 c4 58 10 	movl   $0xf01058c4,0x8(%esp)
f01034ea:	f0 
f01034eb:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01034f2:	00 
f01034f3:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f01034fa:	e8 b7 cb ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f01034ff:	a1 ac de 17 f0       	mov    0xf017deac,%eax
f0103504:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103507:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f010350a:	89 04 24             	mov    %eax,(%esp)
f010350d:	e8 59 da ff ff       	call   f0100f6b <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103512:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103516:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f010351d:	0f 85 1b ff ff ff    	jne    f010343e <env_free+0x78>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103523:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103526:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010352b:	77 20                	ja     f010354d <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010352d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103531:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f0103538:	f0 
f0103539:	c7 44 24 04 ca 01 00 	movl   $0x1ca,0x4(%esp)
f0103540:	00 
f0103541:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f0103548:	e8 69 cb ff ff       	call   f01000b6 <_panic>
	e->env_pgdir = 0;
f010354d:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103554:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103559:	c1 e8 0c             	shr    $0xc,%eax
f010355c:	3b 05 a4 de 17 f0    	cmp    0xf017dea4,%eax
f0103562:	72 1c                	jb     f0103580 <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f0103564:	c7 44 24 08 c4 58 10 	movl   $0xf01058c4,0x8(%esp)
f010356b:	f0 
f010356c:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103573:	00 
f0103574:	c7 04 24 e0 54 10 f0 	movl   $0xf01054e0,(%esp)
f010357b:	e8 36 cb ff ff       	call   f01000b6 <_panic>
	return &pages[PGNUM(pa)];
f0103580:	8b 15 ac de 17 f0    	mov    0xf017deac,%edx
f0103586:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103589:	89 04 24             	mov    %eax,(%esp)
f010358c:	e8 da d9 ff ff       	call   f0100f6b <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103591:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103598:	a1 f0 d1 17 f0       	mov    0xf017d1f0,%eax
f010359d:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01035a0:	89 3d f0 d1 17 f0    	mov    %edi,0xf017d1f0
}
f01035a6:	83 c4 2c             	add    $0x2c,%esp
f01035a9:	5b                   	pop    %ebx
f01035aa:	5e                   	pop    %esi
f01035ab:	5f                   	pop    %edi
f01035ac:	5d                   	pop    %ebp
f01035ad:	c3                   	ret    

f01035ae <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01035ae:	55                   	push   %ebp
f01035af:	89 e5                	mov    %esp,%ebp
f01035b1:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f01035b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01035b7:	89 04 24             	mov    %eax,(%esp)
f01035ba:	e8 07 fe ff ff       	call   f01033c6 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f01035bf:	c7 04 24 50 60 10 f0 	movl   $0xf0106050,(%esp)
f01035c6:	e8 16 01 00 00       	call   f01036e1 <cprintf>
	while (1)
		monitor(NULL);
f01035cb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01035d2:	e8 53 d2 ff ff       	call   f010082a <monitor>
f01035d7:	eb f2                	jmp    f01035cb <env_destroy+0x1d>

f01035d9 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035d9:	55                   	push   %ebp
f01035da:	89 e5                	mov    %esp,%ebp
f01035dc:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f01035df:	8b 65 08             	mov    0x8(%ebp),%esp
f01035e2:	61                   	popa   
f01035e3:	07                   	pop    %es
f01035e4:	1f                   	pop    %ds
f01035e5:	83 c4 08             	add    $0x8,%esp
f01035e8:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01035e9:	c7 44 24 08 cf 60 10 	movl   $0xf01060cf,0x8(%esp)
f01035f0:	f0 
f01035f1:	c7 44 24 04 f2 01 00 	movl   $0x1f2,0x4(%esp)
f01035f8:	00 
f01035f9:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f0103600:	e8 b1 ca ff ff       	call   f01000b6 <_panic>

f0103605 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103605:	55                   	push   %ebp
f0103606:	89 e5                	mov    %esp,%ebp
f0103608:	83 ec 18             	sub    $0x18,%esp
f010360b:	8b 45 08             	mov    0x8(%ebp),%eax
	//	   4. Update its 'env_runs' counter,
	//	   5. Use lcr3() to switch to its address space.
	// Step 2: Use env_pop_tf() to restore the environment's
	//	   registers and drop into user mode in the
	//	   environment.
	if(curenv != NULL && curenv->env_status == ENV_RUNNING) {
f010360e:	8b 15 e8 d1 17 f0    	mov    0xf017d1e8,%edx
f0103614:	85 d2                	test   %edx,%edx
f0103616:	74 0d                	je     f0103625 <env_run+0x20>
f0103618:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f010361c:	75 07                	jne    f0103625 <env_run+0x20>
		curenv->env_status = ENV_RUNNABLE;
f010361e:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
	}

	curenv = e;
f0103625:	a3 e8 d1 17 f0       	mov    %eax,0xf017d1e8
	curenv->env_status = ENV_RUNNING;
f010362a:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;
f0103631:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(curenv->env_pgdir));
f0103635:	8b 50 5c             	mov    0x5c(%eax),%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103638:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010363e:	77 20                	ja     f0103660 <env_run+0x5b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103640:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103644:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f010364b:	f0 
f010364c:	c7 44 24 04 10 02 00 	movl   $0x210,0x4(%esp)
f0103653:	00 
f0103654:	c7 04 24 86 60 10 f0 	movl   $0xf0106086,(%esp)
f010365b:	e8 56 ca ff ff       	call   f01000b6 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103660:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103666:	0f 22 da             	mov    %edx,%cr3
	// Hint: This function loads the new environment's state from
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.
	env_pop_tf(&curenv->env_tf);
f0103669:	89 04 24             	mov    %eax,(%esp)
f010366c:	e8 68 ff ff ff       	call   f01035d9 <env_pop_tf>

f0103671 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103671:	55                   	push   %ebp
f0103672:	89 e5                	mov    %esp,%ebp
f0103674:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103678:	ba 70 00 00 00       	mov    $0x70,%edx
f010367d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010367e:	b2 71                	mov    $0x71,%dl
f0103680:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103681:	0f b6 c0             	movzbl %al,%eax
}
f0103684:	5d                   	pop    %ebp
f0103685:	c3                   	ret    

f0103686 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103686:	55                   	push   %ebp
f0103687:	89 e5                	mov    %esp,%ebp
f0103689:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010368d:	ba 70 00 00 00       	mov    $0x70,%edx
f0103692:	ee                   	out    %al,(%dx)
f0103693:	b2 71                	mov    $0x71,%dl
f0103695:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103698:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103699:	5d                   	pop    %ebp
f010369a:	c3                   	ret    

f010369b <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010369b:	55                   	push   %ebp
f010369c:	89 e5                	mov    %esp,%ebp
f010369e:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01036a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01036a4:	89 04 24             	mov    %eax,(%esp)
f01036a7:	e8 65 cf ff ff       	call   f0100611 <cputchar>
	*cnt++;
}
f01036ac:	c9                   	leave  
f01036ad:	c3                   	ret    

f01036ae <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01036ae:	55                   	push   %ebp
f01036af:	89 e5                	mov    %esp,%ebp
f01036b1:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01036b4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01036bb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036be:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036c2:	8b 45 08             	mov    0x8(%ebp),%eax
f01036c5:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036c9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01036cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036d0:	c7 04 24 9b 36 10 f0 	movl   $0xf010369b,(%esp)
f01036d7:	e8 82 0d 00 00       	call   f010445e <vprintfmt>
	return cnt;
}
f01036dc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036df:	c9                   	leave  
f01036e0:	c3                   	ret    

f01036e1 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01036e1:	55                   	push   %ebp
f01036e2:	89 e5                	mov    %esp,%ebp
f01036e4:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01036e7:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01036ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01036f1:	89 04 24             	mov    %eax,(%esp)
f01036f4:	e8 b5 ff ff ff       	call   f01036ae <vcprintf>
	va_end(ap);

	return cnt;
}
f01036f9:	c9                   	leave  
f01036fa:	c3                   	ret    
f01036fb:	66 90                	xchg   %ax,%ax
f01036fd:	66 90                	xchg   %ax,%ax
f01036ff:	90                   	nop

f0103700 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103700:	55                   	push   %ebp
f0103701:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103703:	c7 05 24 da 17 f0 00 	movl   $0xf0000000,0xf017da24
f010370a:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f010370d:	66 c7 05 28 da 17 f0 	movw   $0x10,0xf017da28
f0103714:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103716:	66 c7 05 48 b3 11 f0 	movw   $0x67,0xf011b348
f010371d:	67 00 
f010371f:	b8 20 da 17 f0       	mov    $0xf017da20,%eax
f0103724:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f010372a:	89 c2                	mov    %eax,%edx
f010372c:	c1 ea 10             	shr    $0x10,%edx
f010372f:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0103735:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f010373c:	c1 e8 18             	shr    $0x18,%eax
f010373f:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103744:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010374b:	b8 28 00 00 00       	mov    $0x28,%eax
f0103750:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103753:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103758:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010375b:	5d                   	pop    %ebp
f010375c:	c3                   	ret    

f010375d <trap_init>:
}


void
trap_init(void)
{
f010375d:	55                   	push   %ebp
f010375e:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	SETGATE(idt[T_DIVIDE], 0, GD_KT, t_divide, 0);
f0103760:	b8 9c 3e 10 f0       	mov    $0xf0103e9c,%eax
f0103765:	66 a3 00 d2 17 f0    	mov    %ax,0xf017d200
f010376b:	66 c7 05 02 d2 17 f0 	movw   $0x8,0xf017d202
f0103772:	08 00 
f0103774:	c6 05 04 d2 17 f0 00 	movb   $0x0,0xf017d204
f010377b:	c6 05 05 d2 17 f0 8e 	movb   $0x8e,0xf017d205
f0103782:	c1 e8 10             	shr    $0x10,%eax
f0103785:	66 a3 06 d2 17 f0    	mov    %ax,0xf017d206
	SETGATE(idt[T_DEBUG], 0, GD_KT, t_debug, 0);
f010378b:	b8 a2 3e 10 f0       	mov    $0xf0103ea2,%eax
f0103790:	66 a3 08 d2 17 f0    	mov    %ax,0xf017d208
f0103796:	66 c7 05 0a d2 17 f0 	movw   $0x8,0xf017d20a
f010379d:	08 00 
f010379f:	c6 05 0c d2 17 f0 00 	movb   $0x0,0xf017d20c
f01037a6:	c6 05 0d d2 17 f0 8e 	movb   $0x8e,0xf017d20d
f01037ad:	c1 e8 10             	shr    $0x10,%eax
f01037b0:	66 a3 0e d2 17 f0    	mov    %ax,0xf017d20e
	SETGATE(idt[T_NMI], 0, GD_KT, t_nmi, 0);
f01037b6:	b8 a8 3e 10 f0       	mov    $0xf0103ea8,%eax
f01037bb:	66 a3 10 d2 17 f0    	mov    %ax,0xf017d210
f01037c1:	66 c7 05 12 d2 17 f0 	movw   $0x8,0xf017d212
f01037c8:	08 00 
f01037ca:	c6 05 14 d2 17 f0 00 	movb   $0x0,0xf017d214
f01037d1:	c6 05 15 d2 17 f0 8e 	movb   $0x8e,0xf017d215
f01037d8:	c1 e8 10             	shr    $0x10,%eax
f01037db:	66 a3 16 d2 17 f0    	mov    %ax,0xf017d216
	SETGATE(idt[T_BRKPT], 0, GD_KT, t_brkpt, 3);
f01037e1:	b8 ae 3e 10 f0       	mov    $0xf0103eae,%eax
f01037e6:	66 a3 18 d2 17 f0    	mov    %ax,0xf017d218
f01037ec:	66 c7 05 1a d2 17 f0 	movw   $0x8,0xf017d21a
f01037f3:	08 00 
f01037f5:	c6 05 1c d2 17 f0 00 	movb   $0x0,0xf017d21c
f01037fc:	c6 05 1d d2 17 f0 ee 	movb   $0xee,0xf017d21d
f0103803:	c1 e8 10             	shr    $0x10,%eax
f0103806:	66 a3 1e d2 17 f0    	mov    %ax,0xf017d21e
	SETGATE(idt[T_OFLOW], 0, GD_KT, t_oflow, 0);
f010380c:	b8 b4 3e 10 f0       	mov    $0xf0103eb4,%eax
f0103811:	66 a3 20 d2 17 f0    	mov    %ax,0xf017d220
f0103817:	66 c7 05 22 d2 17 f0 	movw   $0x8,0xf017d222
f010381e:	08 00 
f0103820:	c6 05 24 d2 17 f0 00 	movb   $0x0,0xf017d224
f0103827:	c6 05 25 d2 17 f0 8e 	movb   $0x8e,0xf017d225
f010382e:	c1 e8 10             	shr    $0x10,%eax
f0103831:	66 a3 26 d2 17 f0    	mov    %ax,0xf017d226
	SETGATE(idt[T_BOUND], 0, GD_KT, t_bound, 0);
f0103837:	b8 ba 3e 10 f0       	mov    $0xf0103eba,%eax
f010383c:	66 a3 28 d2 17 f0    	mov    %ax,0xf017d228
f0103842:	66 c7 05 2a d2 17 f0 	movw   $0x8,0xf017d22a
f0103849:	08 00 
f010384b:	c6 05 2c d2 17 f0 00 	movb   $0x0,0xf017d22c
f0103852:	c6 05 2d d2 17 f0 8e 	movb   $0x8e,0xf017d22d
f0103859:	c1 e8 10             	shr    $0x10,%eax
f010385c:	66 a3 2e d2 17 f0    	mov    %ax,0xf017d22e
	SETGATE(idt[T_ILLOP], 0, GD_KT, t_illop, 0);
f0103862:	b8 c0 3e 10 f0       	mov    $0xf0103ec0,%eax
f0103867:	66 a3 30 d2 17 f0    	mov    %ax,0xf017d230
f010386d:	66 c7 05 32 d2 17 f0 	movw   $0x8,0xf017d232
f0103874:	08 00 
f0103876:	c6 05 34 d2 17 f0 00 	movb   $0x0,0xf017d234
f010387d:	c6 05 35 d2 17 f0 8e 	movb   $0x8e,0xf017d235
f0103884:	c1 e8 10             	shr    $0x10,%eax
f0103887:	66 a3 36 d2 17 f0    	mov    %ax,0xf017d236
	SETGATE(idt[T_DEVICE], 0, GD_KT, t_device, 0);
f010388d:	b8 c6 3e 10 f0       	mov    $0xf0103ec6,%eax
f0103892:	66 a3 38 d2 17 f0    	mov    %ax,0xf017d238
f0103898:	66 c7 05 3a d2 17 f0 	movw   $0x8,0xf017d23a
f010389f:	08 00 
f01038a1:	c6 05 3c d2 17 f0 00 	movb   $0x0,0xf017d23c
f01038a8:	c6 05 3d d2 17 f0 8e 	movb   $0x8e,0xf017d23d
f01038af:	c1 e8 10             	shr    $0x10,%eax
f01038b2:	66 a3 3e d2 17 f0    	mov    %ax,0xf017d23e
	SETGATE(idt[T_DBLFLT], 0, GD_KT, t_dblflt, 0);
f01038b8:	b8 cc 3e 10 f0       	mov    $0xf0103ecc,%eax
f01038bd:	66 a3 40 d2 17 f0    	mov    %ax,0xf017d240
f01038c3:	66 c7 05 42 d2 17 f0 	movw   $0x8,0xf017d242
f01038ca:	08 00 
f01038cc:	c6 05 44 d2 17 f0 00 	movb   $0x0,0xf017d244
f01038d3:	c6 05 45 d2 17 f0 8e 	movb   $0x8e,0xf017d245
f01038da:	c1 e8 10             	shr    $0x10,%eax
f01038dd:	66 a3 46 d2 17 f0    	mov    %ax,0xf017d246
	SETGATE(idt[T_TSS], 0, GD_KT, t_tss, 0);
f01038e3:	b8 d0 3e 10 f0       	mov    $0xf0103ed0,%eax
f01038e8:	66 a3 50 d2 17 f0    	mov    %ax,0xf017d250
f01038ee:	66 c7 05 52 d2 17 f0 	movw   $0x8,0xf017d252
f01038f5:	08 00 
f01038f7:	c6 05 54 d2 17 f0 00 	movb   $0x0,0xf017d254
f01038fe:	c6 05 55 d2 17 f0 8e 	movb   $0x8e,0xf017d255
f0103905:	c1 e8 10             	shr    $0x10,%eax
f0103908:	66 a3 56 d2 17 f0    	mov    %ax,0xf017d256
	SETGATE(idt[T_SEGNP], 0, GD_KT, t_segnp, 0);
f010390e:	b8 d4 3e 10 f0       	mov    $0xf0103ed4,%eax
f0103913:	66 a3 58 d2 17 f0    	mov    %ax,0xf017d258
f0103919:	66 c7 05 5a d2 17 f0 	movw   $0x8,0xf017d25a
f0103920:	08 00 
f0103922:	c6 05 5c d2 17 f0 00 	movb   $0x0,0xf017d25c
f0103929:	c6 05 5d d2 17 f0 8e 	movb   $0x8e,0xf017d25d
f0103930:	c1 e8 10             	shr    $0x10,%eax
f0103933:	66 a3 5e d2 17 f0    	mov    %ax,0xf017d25e
	SETGATE(idt[T_STACK], 0, GD_KT, t_stack, 0);
f0103939:	b8 d8 3e 10 f0       	mov    $0xf0103ed8,%eax
f010393e:	66 a3 60 d2 17 f0    	mov    %ax,0xf017d260
f0103944:	66 c7 05 62 d2 17 f0 	movw   $0x8,0xf017d262
f010394b:	08 00 
f010394d:	c6 05 64 d2 17 f0 00 	movb   $0x0,0xf017d264
f0103954:	c6 05 65 d2 17 f0 8e 	movb   $0x8e,0xf017d265
f010395b:	c1 e8 10             	shr    $0x10,%eax
f010395e:	66 a3 66 d2 17 f0    	mov    %ax,0xf017d266
	SETGATE(idt[T_GPFLT], 0, GD_KT, t_gpflt, 0);
f0103964:	b8 dc 3e 10 f0       	mov    $0xf0103edc,%eax
f0103969:	66 a3 68 d2 17 f0    	mov    %ax,0xf017d268
f010396f:	66 c7 05 6a d2 17 f0 	movw   $0x8,0xf017d26a
f0103976:	08 00 
f0103978:	c6 05 6c d2 17 f0 00 	movb   $0x0,0xf017d26c
f010397f:	c6 05 6d d2 17 f0 8e 	movb   $0x8e,0xf017d26d
f0103986:	c1 e8 10             	shr    $0x10,%eax
f0103989:	66 a3 6e d2 17 f0    	mov    %ax,0xf017d26e
	SETGATE(idt[T_PGFLT], 0, GD_KT, t_pgflt, 0);
f010398f:	b8 e0 3e 10 f0       	mov    $0xf0103ee0,%eax
f0103994:	66 a3 70 d2 17 f0    	mov    %ax,0xf017d270
f010399a:	66 c7 05 72 d2 17 f0 	movw   $0x8,0xf017d272
f01039a1:	08 00 
f01039a3:	c6 05 74 d2 17 f0 00 	movb   $0x0,0xf017d274
f01039aa:	c6 05 75 d2 17 f0 8e 	movb   $0x8e,0xf017d275
f01039b1:	c1 e8 10             	shr    $0x10,%eax
f01039b4:	66 a3 76 d2 17 f0    	mov    %ax,0xf017d276
	SETGATE(idt[T_FPERR], 0, GD_KT, t_fperr, 0);
f01039ba:	b8 e4 3e 10 f0       	mov    $0xf0103ee4,%eax
f01039bf:	66 a3 80 d2 17 f0    	mov    %ax,0xf017d280
f01039c5:	66 c7 05 82 d2 17 f0 	movw   $0x8,0xf017d282
f01039cc:	08 00 
f01039ce:	c6 05 84 d2 17 f0 00 	movb   $0x0,0xf017d284
f01039d5:	c6 05 85 d2 17 f0 8e 	movb   $0x8e,0xf017d285
f01039dc:	c1 e8 10             	shr    $0x10,%eax
f01039df:	66 a3 86 d2 17 f0    	mov    %ax,0xf017d286
	SETGATE(idt[T_ALIGN], 0, GD_KT, t_align, 0);
f01039e5:	b8 ea 3e 10 f0       	mov    $0xf0103eea,%eax
f01039ea:	66 a3 88 d2 17 f0    	mov    %ax,0xf017d288
f01039f0:	66 c7 05 8a d2 17 f0 	movw   $0x8,0xf017d28a
f01039f7:	08 00 
f01039f9:	c6 05 8c d2 17 f0 00 	movb   $0x0,0xf017d28c
f0103a00:	c6 05 8d d2 17 f0 8e 	movb   $0x8e,0xf017d28d
f0103a07:	c1 e8 10             	shr    $0x10,%eax
f0103a0a:	66 a3 8e d2 17 f0    	mov    %ax,0xf017d28e
	SETGATE(idt[T_MCHK], 0, GD_KT, t_mchk, 0);
f0103a10:	b8 ee 3e 10 f0       	mov    $0xf0103eee,%eax
f0103a15:	66 a3 90 d2 17 f0    	mov    %ax,0xf017d290
f0103a1b:	66 c7 05 92 d2 17 f0 	movw   $0x8,0xf017d292
f0103a22:	08 00 
f0103a24:	c6 05 94 d2 17 f0 00 	movb   $0x0,0xf017d294
f0103a2b:	c6 05 95 d2 17 f0 8e 	movb   $0x8e,0xf017d295
f0103a32:	c1 e8 10             	shr    $0x10,%eax
f0103a35:	66 a3 96 d2 17 f0    	mov    %ax,0xf017d296
	SETGATE(idt[T_SIMDERR], 0, GD_KT, t_simderr, 0);
f0103a3b:	b8 f4 3e 10 f0       	mov    $0xf0103ef4,%eax
f0103a40:	66 a3 98 d2 17 f0    	mov    %ax,0xf017d298
f0103a46:	66 c7 05 9a d2 17 f0 	movw   $0x8,0xf017d29a
f0103a4d:	08 00 
f0103a4f:	c6 05 9c d2 17 f0 00 	movb   $0x0,0xf017d29c
f0103a56:	c6 05 9d d2 17 f0 8e 	movb   $0x8e,0xf017d29d
f0103a5d:	c1 e8 10             	shr    $0x10,%eax
f0103a60:	66 a3 9e d2 17 f0    	mov    %ax,0xf017d29e
	SETGATE(idt[T_SYSCALL], 0, GD_KT, t_syscall, 3);
f0103a66:	b8 fa 3e 10 f0       	mov    $0xf0103efa,%eax
f0103a6b:	66 a3 80 d3 17 f0    	mov    %ax,0xf017d380
f0103a71:	66 c7 05 82 d3 17 f0 	movw   $0x8,0xf017d382
f0103a78:	08 00 
f0103a7a:	c6 05 84 d3 17 f0 00 	movb   $0x0,0xf017d384
f0103a81:	c6 05 85 d3 17 f0 ee 	movb   $0xee,0xf017d385
f0103a88:	c1 e8 10             	shr    $0x10,%eax
f0103a8b:	66 a3 86 d3 17 f0    	mov    %ax,0xf017d386
	// Per-CPU setup 
	trap_init_percpu();
f0103a91:	e8 6a fc ff ff       	call   f0103700 <trap_init_percpu>
}
f0103a96:	5d                   	pop    %ebp
f0103a97:	c3                   	ret    

f0103a98 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103a98:	55                   	push   %ebp
f0103a99:	89 e5                	mov    %esp,%ebp
f0103a9b:	53                   	push   %ebx
f0103a9c:	83 ec 14             	sub    $0x14,%esp
f0103a9f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103aa2:	8b 03                	mov    (%ebx),%eax
f0103aa4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aa8:	c7 04 24 db 60 10 f0 	movl   $0xf01060db,(%esp)
f0103aaf:	e8 2d fc ff ff       	call   f01036e1 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103ab4:	8b 43 04             	mov    0x4(%ebx),%eax
f0103ab7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103abb:	c7 04 24 ea 60 10 f0 	movl   $0xf01060ea,(%esp)
f0103ac2:	e8 1a fc ff ff       	call   f01036e1 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103ac7:	8b 43 08             	mov    0x8(%ebx),%eax
f0103aca:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ace:	c7 04 24 f9 60 10 f0 	movl   $0xf01060f9,(%esp)
f0103ad5:	e8 07 fc ff ff       	call   f01036e1 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103ada:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103add:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ae1:	c7 04 24 08 61 10 f0 	movl   $0xf0106108,(%esp)
f0103ae8:	e8 f4 fb ff ff       	call   f01036e1 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103aed:	8b 43 10             	mov    0x10(%ebx),%eax
f0103af0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103af4:	c7 04 24 17 61 10 f0 	movl   $0xf0106117,(%esp)
f0103afb:	e8 e1 fb ff ff       	call   f01036e1 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103b00:	8b 43 14             	mov    0x14(%ebx),%eax
f0103b03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b07:	c7 04 24 26 61 10 f0 	movl   $0xf0106126,(%esp)
f0103b0e:	e8 ce fb ff ff       	call   f01036e1 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103b13:	8b 43 18             	mov    0x18(%ebx),%eax
f0103b16:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b1a:	c7 04 24 35 61 10 f0 	movl   $0xf0106135,(%esp)
f0103b21:	e8 bb fb ff ff       	call   f01036e1 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103b26:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103b29:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b2d:	c7 04 24 44 61 10 f0 	movl   $0xf0106144,(%esp)
f0103b34:	e8 a8 fb ff ff       	call   f01036e1 <cprintf>
}
f0103b39:	83 c4 14             	add    $0x14,%esp
f0103b3c:	5b                   	pop    %ebx
f0103b3d:	5d                   	pop    %ebp
f0103b3e:	c3                   	ret    

f0103b3f <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103b3f:	55                   	push   %ebp
f0103b40:	89 e5                	mov    %esp,%ebp
f0103b42:	56                   	push   %esi
f0103b43:	53                   	push   %ebx
f0103b44:	83 ec 10             	sub    $0x10,%esp
f0103b47:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103b4a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b4e:	c7 04 24 7a 62 10 f0 	movl   $0xf010627a,(%esp)
f0103b55:	e8 87 fb ff ff       	call   f01036e1 <cprintf>
	print_regs(&tf->tf_regs);
f0103b5a:	89 1c 24             	mov    %ebx,(%esp)
f0103b5d:	e8 36 ff ff ff       	call   f0103a98 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103b62:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103b66:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b6a:	c7 04 24 95 61 10 f0 	movl   $0xf0106195,(%esp)
f0103b71:	e8 6b fb ff ff       	call   f01036e1 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103b76:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103b7a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b7e:	c7 04 24 a8 61 10 f0 	movl   $0xf01061a8,(%esp)
f0103b85:	e8 57 fb ff ff       	call   f01036e1 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103b8a:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103b8d:	83 f8 13             	cmp    $0x13,%eax
f0103b90:	77 09                	ja     f0103b9b <print_trapframe+0x5c>
		return excnames[trapno];
f0103b92:	8b 14 85 40 64 10 f0 	mov    -0xfef9bc0(,%eax,4),%edx
f0103b99:	eb 10                	jmp    f0103bab <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103b9b:	83 f8 30             	cmp    $0x30,%eax
f0103b9e:	ba 53 61 10 f0       	mov    $0xf0106153,%edx
f0103ba3:	b9 5f 61 10 f0       	mov    $0xf010615f,%ecx
f0103ba8:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103bab:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103baf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bb3:	c7 04 24 bb 61 10 f0 	movl   $0xf01061bb,(%esp)
f0103bba:	e8 22 fb ff ff       	call   f01036e1 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103bbf:	3b 1d 00 da 17 f0    	cmp    0xf017da00,%ebx
f0103bc5:	75 19                	jne    f0103be0 <print_trapframe+0xa1>
f0103bc7:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bcb:	75 13                	jne    f0103be0 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103bcd:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103bd0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bd4:	c7 04 24 cd 61 10 f0 	movl   $0xf01061cd,(%esp)
f0103bdb:	e8 01 fb ff ff       	call   f01036e1 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103be0:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103be3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103be7:	c7 04 24 dc 61 10 f0 	movl   $0xf01061dc,(%esp)
f0103bee:	e8 ee fa ff ff       	call   f01036e1 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103bf3:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103bf7:	75 51                	jne    f0103c4a <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103bf9:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103bfc:	89 c2                	mov    %eax,%edx
f0103bfe:	83 e2 01             	and    $0x1,%edx
f0103c01:	ba 6e 61 10 f0       	mov    $0xf010616e,%edx
f0103c06:	b9 79 61 10 f0       	mov    $0xf0106179,%ecx
f0103c0b:	0f 45 ca             	cmovne %edx,%ecx
f0103c0e:	89 c2                	mov    %eax,%edx
f0103c10:	83 e2 02             	and    $0x2,%edx
f0103c13:	ba 85 61 10 f0       	mov    $0xf0106185,%edx
f0103c18:	be 8b 61 10 f0       	mov    $0xf010618b,%esi
f0103c1d:	0f 44 d6             	cmove  %esi,%edx
f0103c20:	83 e0 04             	and    $0x4,%eax
f0103c23:	b8 90 61 10 f0       	mov    $0xf0106190,%eax
f0103c28:	be a5 62 10 f0       	mov    $0xf01062a5,%esi
f0103c2d:	0f 44 c6             	cmove  %esi,%eax
f0103c30:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103c34:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103c38:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c3c:	c7 04 24 ea 61 10 f0 	movl   $0xf01061ea,(%esp)
f0103c43:	e8 99 fa ff ff       	call   f01036e1 <cprintf>
f0103c48:	eb 0c                	jmp    f0103c56 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103c4a:	c7 04 24 a9 57 10 f0 	movl   $0xf01057a9,(%esp)
f0103c51:	e8 8b fa ff ff       	call   f01036e1 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103c56:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c59:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c5d:	c7 04 24 f9 61 10 f0 	movl   $0xf01061f9,(%esp)
f0103c64:	e8 78 fa ff ff       	call   f01036e1 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103c69:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103c6d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c71:	c7 04 24 08 62 10 f0 	movl   $0xf0106208,(%esp)
f0103c78:	e8 64 fa ff ff       	call   f01036e1 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103c7d:	8b 43 38             	mov    0x38(%ebx),%eax
f0103c80:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c84:	c7 04 24 1b 62 10 f0 	movl   $0xf010621b,(%esp)
f0103c8b:	e8 51 fa ff ff       	call   f01036e1 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103c90:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103c94:	74 27                	je     f0103cbd <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103c96:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103c99:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c9d:	c7 04 24 2a 62 10 f0 	movl   $0xf010622a,(%esp)
f0103ca4:	e8 38 fa ff ff       	call   f01036e1 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103ca9:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103cad:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cb1:	c7 04 24 39 62 10 f0 	movl   $0xf0106239,(%esp)
f0103cb8:	e8 24 fa ff ff       	call   f01036e1 <cprintf>
	}
}
f0103cbd:	83 c4 10             	add    $0x10,%esp
f0103cc0:	5b                   	pop    %ebx
f0103cc1:	5e                   	pop    %esi
f0103cc2:	5d                   	pop    %ebp
f0103cc3:	c3                   	ret    

f0103cc4 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103cc4:	55                   	push   %ebp
f0103cc5:	89 e5                	mov    %esp,%ebp
f0103cc7:	53                   	push   %ebx
f0103cc8:	83 ec 14             	sub    $0x14,%esp
f0103ccb:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103cce:	0f 20 d0             	mov    %cr2,%eax
	
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103cd1:	8b 53 30             	mov    0x30(%ebx),%edx
f0103cd4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103cd8:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103cdc:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103ce1:	8b 40 48             	mov    0x48(%eax),%eax
f0103ce4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ce8:	c7 04 24 f0 63 10 f0 	movl   $0xf01063f0,(%esp)
f0103cef:	e8 ed f9 ff ff       	call   f01036e1 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103cf4:	89 1c 24             	mov    %ebx,(%esp)
f0103cf7:	e8 43 fe ff ff       	call   f0103b3f <print_trapframe>
	env_destroy(curenv);
f0103cfc:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103d01:	89 04 24             	mov    %eax,(%esp)
f0103d04:	e8 a5 f8 ff ff       	call   f01035ae <env_destroy>
}
f0103d09:	83 c4 14             	add    $0x14,%esp
f0103d0c:	5b                   	pop    %ebx
f0103d0d:	5d                   	pop    %ebp
f0103d0e:	c3                   	ret    

f0103d0f <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103d0f:	55                   	push   %ebp
f0103d10:	89 e5                	mov    %esp,%ebp
f0103d12:	57                   	push   %edi
f0103d13:	56                   	push   %esi
f0103d14:	83 ec 20             	sub    $0x20,%esp
f0103d17:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103d1a:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d1b:	9c                   	pushf  
f0103d1c:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d1d:	f6 c4 02             	test   $0x2,%ah
f0103d20:	74 24                	je     f0103d46 <trap+0x37>
f0103d22:	c7 44 24 0c 4c 62 10 	movl   $0xf010624c,0xc(%esp)
f0103d29:	f0 
f0103d2a:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0103d31:	f0 
f0103d32:	c7 44 24 04 e5 00 00 	movl   $0xe5,0x4(%esp)
f0103d39:	00 
f0103d3a:	c7 04 24 65 62 10 f0 	movl   $0xf0106265,(%esp)
f0103d41:	e8 70 c3 ff ff       	call   f01000b6 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103d46:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103d4a:	c7 04 24 71 62 10 f0 	movl   $0xf0106271,(%esp)
f0103d51:	e8 8b f9 ff ff       	call   f01036e1 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103d56:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d5a:	83 e0 03             	and    $0x3,%eax
f0103d5d:	66 83 f8 03          	cmp    $0x3,%ax
f0103d61:	75 3c                	jne    f0103d9f <trap+0x90>
		// Trapped from user mode.
		assert(curenv);
f0103d63:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103d68:	85 c0                	test   %eax,%eax
f0103d6a:	75 24                	jne    f0103d90 <trap+0x81>
f0103d6c:	c7 44 24 0c 8c 62 10 	movl   $0xf010628c,0xc(%esp)
f0103d73:	f0 
f0103d74:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0103d7b:	f0 
f0103d7c:	c7 44 24 04 eb 00 00 	movl   $0xeb,0x4(%esp)
f0103d83:	00 
f0103d84:	c7 04 24 65 62 10 f0 	movl   $0xf0106265,(%esp)
f0103d8b:	e8 26 c3 ff ff       	call   f01000b6 <_panic>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103d90:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103d95:	89 c7                	mov    %eax,%edi
f0103d97:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103d99:	8b 35 e8 d1 17 f0    	mov    0xf017d1e8,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103d9f:	89 35 00 da 17 f0    	mov    %esi,0xf017da00
trap_dispatch(struct Trapframe *tf)
{
	int32_t ret_code;
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch(tf->tf_trapno) {
f0103da5:	8b 46 28             	mov    0x28(%esi),%eax
f0103da8:	83 f8 03             	cmp    $0x3,%eax
f0103dab:	74 2d                	je     f0103dda <trap+0xcb>
f0103dad:	83 f8 03             	cmp    $0x3,%eax
f0103db0:	77 07                	ja     f0103db9 <trap+0xaa>
f0103db2:	83 f8 01             	cmp    $0x1,%eax
f0103db5:	74 35                	je     f0103dec <trap+0xdd>
f0103db7:	eb 6f                	jmp    f0103e28 <trap+0x119>
f0103db9:	83 f8 0e             	cmp    $0xe,%eax
f0103dbc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103dc0:	74 07                	je     f0103dc9 <trap+0xba>
f0103dc2:	83 f8 30             	cmp    $0x30,%eax
f0103dc5:	74 2f                	je     f0103df6 <trap+0xe7>
f0103dc7:	eb 5f                	jmp    f0103e28 <trap+0x119>
		case (T_PGFLT):
			page_fault_handler(tf);
f0103dc9:	89 34 24             	mov    %esi,(%esp)
f0103dcc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103dd0:	e8 ef fe ff ff       	call   f0103cc4 <page_fault_handler>
f0103dd5:	e9 86 00 00 00       	jmp    f0103e60 <trap+0x151>
			break; 
		case (T_BRKPT):
			print_trapframe(tf);
f0103dda:	89 34 24             	mov    %esi,(%esp)
f0103ddd:	e8 5d fd ff ff       	call   f0103b3f <print_trapframe>
			monitor(tf);		
f0103de2:	89 34 24             	mov    %esi,(%esp)
f0103de5:	e8 40 ca ff ff       	call   f010082a <monitor>
f0103dea:	eb 74                	jmp    f0103e60 <trap+0x151>
			break;
		case (T_DEBUG):
			monitor(tf);
f0103dec:	89 34 24             	mov    %esi,(%esp)
f0103def:	e8 36 ca ff ff       	call   f010082a <monitor>
f0103df4:	eb 6a                	jmp    f0103e60 <trap+0x151>
			break;
		case (T_SYSCALL):
	//		print_trapframe(tf);
			ret_code = syscall(
f0103df6:	8b 46 04             	mov    0x4(%esi),%eax
f0103df9:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103dfd:	8b 06                	mov    (%esi),%eax
f0103dff:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103e03:	8b 46 10             	mov    0x10(%esi),%eax
f0103e06:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e0a:	8b 46 18             	mov    0x18(%esi),%eax
f0103e0d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e11:	8b 46 14             	mov    0x14(%esi),%eax
f0103e14:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e18:	8b 46 1c             	mov    0x1c(%esi),%eax
f0103e1b:	89 04 24             	mov    %eax,(%esp)
f0103e1e:	e8 fd 00 00 00       	call   f0103f20 <syscall>
					tf->tf_regs.reg_edx,
					tf->tf_regs.reg_ecx,
					tf->tf_regs.reg_ebx,
					tf->tf_regs.reg_edi,
					tf->tf_regs.reg_esi);
			tf->tf_regs.reg_eax = ret_code;
f0103e23:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e26:	eb 38                	jmp    f0103e60 <trap+0x151>
			break;
 		default:
			// Unexpected trap: The user process or the kernel has a bug.
			print_trapframe(tf);
f0103e28:	89 34 24             	mov    %esi,(%esp)
f0103e2b:	e8 0f fd ff ff       	call   f0103b3f <print_trapframe>
			if (tf->tf_cs == GD_KT)
f0103e30:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e35:	75 1c                	jne    f0103e53 <trap+0x144>
				panic("unhandled trap in kernel");
f0103e37:	c7 44 24 08 93 62 10 	movl   $0xf0106293,0x8(%esp)
f0103e3e:	f0 
f0103e3f:	c7 44 24 04 d3 00 00 	movl   $0xd3,0x4(%esp)
f0103e46:	00 
f0103e47:	c7 04 24 65 62 10 f0 	movl   $0xf0106265,(%esp)
f0103e4e:	e8 63 c2 ff ff       	call   f01000b6 <_panic>
			else {
				env_destroy(curenv);
f0103e53:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103e58:	89 04 24             	mov    %eax,(%esp)
f0103e5b:	e8 4e f7 ff ff       	call   f01035ae <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103e60:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103e65:	85 c0                	test   %eax,%eax
f0103e67:	74 06                	je     f0103e6f <trap+0x160>
f0103e69:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103e6d:	74 24                	je     f0103e93 <trap+0x184>
f0103e6f:	c7 44 24 0c 14 64 10 	movl   $0xf0106414,0xc(%esp)
f0103e76:	f0 
f0103e77:	c7 44 24 08 fa 54 10 	movl   $0xf01054fa,0x8(%esp)
f0103e7e:	f0 
f0103e7f:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
f0103e86:	00 
f0103e87:	c7 04 24 65 62 10 f0 	movl   $0xf0106265,(%esp)
f0103e8e:	e8 23 c2 ff ff       	call   f01000b6 <_panic>
	env_run(curenv);
f0103e93:	89 04 24             	mov    %eax,(%esp)
f0103e96:	e8 6a f7 ff ff       	call   f0103605 <env_run>
f0103e9b:	90                   	nop

f0103e9c <t_divide>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(t_divide, T_DIVIDE)
f0103e9c:	6a 00                	push   $0x0
f0103e9e:	6a 00                	push   $0x0
f0103ea0:	eb 5e                	jmp    f0103f00 <_alltraps>

f0103ea2 <t_debug>:
TRAPHANDLER_NOEC(t_debug, T_DEBUG)
f0103ea2:	6a 00                	push   $0x0
f0103ea4:	6a 01                	push   $0x1
f0103ea6:	eb 58                	jmp    f0103f00 <_alltraps>

f0103ea8 <t_nmi>:
TRAPHANDLER_NOEC(t_nmi, T_NMI)
f0103ea8:	6a 00                	push   $0x0
f0103eaa:	6a 02                	push   $0x2
f0103eac:	eb 52                	jmp    f0103f00 <_alltraps>

f0103eae <t_brkpt>:
TRAPHANDLER_NOEC(t_brkpt, T_BRKPT)
f0103eae:	6a 00                	push   $0x0
f0103eb0:	6a 03                	push   $0x3
f0103eb2:	eb 4c                	jmp    f0103f00 <_alltraps>

f0103eb4 <t_oflow>:
TRAPHANDLER_NOEC(t_oflow, T_OFLOW)
f0103eb4:	6a 00                	push   $0x0
f0103eb6:	6a 04                	push   $0x4
f0103eb8:	eb 46                	jmp    f0103f00 <_alltraps>

f0103eba <t_bound>:
TRAPHANDLER_NOEC(t_bound, T_BOUND)
f0103eba:	6a 00                	push   $0x0
f0103ebc:	6a 05                	push   $0x5
f0103ebe:	eb 40                	jmp    f0103f00 <_alltraps>

f0103ec0 <t_illop>:
TRAPHANDLER_NOEC(t_illop, T_ILLOP)
f0103ec0:	6a 00                	push   $0x0
f0103ec2:	6a 06                	push   $0x6
f0103ec4:	eb 3a                	jmp    f0103f00 <_alltraps>

f0103ec6 <t_device>:
TRAPHANDLER_NOEC(t_device, T_DEVICE)
f0103ec6:	6a 00                	push   $0x0
f0103ec8:	6a 07                	push   $0x7
f0103eca:	eb 34                	jmp    f0103f00 <_alltraps>

f0103ecc <t_dblflt>:
TRAPHANDLER(t_dblflt, T_DBLFLT)
f0103ecc:	6a 08                	push   $0x8
f0103ece:	eb 30                	jmp    f0103f00 <_alltraps>

f0103ed0 <t_tss>:
TRAPHANDLER(t_tss, T_TSS)
f0103ed0:	6a 0a                	push   $0xa
f0103ed2:	eb 2c                	jmp    f0103f00 <_alltraps>

f0103ed4 <t_segnp>:
TRAPHANDLER(t_segnp, T_SEGNP)
f0103ed4:	6a 0b                	push   $0xb
f0103ed6:	eb 28                	jmp    f0103f00 <_alltraps>

f0103ed8 <t_stack>:
TRAPHANDLER(t_stack, T_STACK)
f0103ed8:	6a 0c                	push   $0xc
f0103eda:	eb 24                	jmp    f0103f00 <_alltraps>

f0103edc <t_gpflt>:
TRAPHANDLER(t_gpflt, T_GPFLT)
f0103edc:	6a 0d                	push   $0xd
f0103ede:	eb 20                	jmp    f0103f00 <_alltraps>

f0103ee0 <t_pgflt>:
TRAPHANDLER(t_pgflt, T_PGFLT)
f0103ee0:	6a 0e                	push   $0xe
f0103ee2:	eb 1c                	jmp    f0103f00 <_alltraps>

f0103ee4 <t_fperr>:
TRAPHANDLER_NOEC(t_fperr, T_FPERR)
f0103ee4:	6a 00                	push   $0x0
f0103ee6:	6a 10                	push   $0x10
f0103ee8:	eb 16                	jmp    f0103f00 <_alltraps>

f0103eea <t_align>:
TRAPHANDLER(t_align, T_ALIGN)
f0103eea:	6a 11                	push   $0x11
f0103eec:	eb 12                	jmp    f0103f00 <_alltraps>

f0103eee <t_mchk>:
TRAPHANDLER_NOEC(t_mchk, T_MCHK)
f0103eee:	6a 00                	push   $0x0
f0103ef0:	6a 12                	push   $0x12
f0103ef2:	eb 0c                	jmp    f0103f00 <_alltraps>

f0103ef4 <t_simderr>:
TRAPHANDLER_NOEC(t_simderr, T_SIMDERR)
f0103ef4:	6a 00                	push   $0x0
f0103ef6:	6a 13                	push   $0x13
f0103ef8:	eb 06                	jmp    f0103f00 <_alltraps>

f0103efa <t_syscall>:

TRAPHANDLER_NOEC(t_syscall, T_SYSCALL)
f0103efa:	6a 00                	push   $0x0
f0103efc:	6a 30                	push   $0x30
f0103efe:	eb 00                	jmp    f0103f00 <_alltraps>

f0103f00 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f0103f00:	1e                   	push   %ds
	pushl %es
f0103f01:	06                   	push   %es
	pushal 
f0103f02:	60                   	pusha  

	movl $GD_KD, %eax
f0103f03:	b8 10 00 00 00       	mov    $0x10,%eax
	movw %ax, %ds
f0103f08:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0103f0a:	8e c0                	mov    %eax,%es

	push %esp
f0103f0c:	54                   	push   %esp
	call trap	
f0103f0d:	e8 fd fd ff ff       	call   f0103d0f <trap>
f0103f12:	66 90                	xchg   %ax,%ax
f0103f14:	66 90                	xchg   %ax,%ax
f0103f16:	66 90                	xchg   %ax,%ax
f0103f18:	66 90                	xchg   %ax,%ax
f0103f1a:	66 90                	xchg   %ax,%ax
f0103f1c:	66 90                	xchg   %ax,%ax
f0103f1e:	66 90                	xchg   %ax,%ax

f0103f20 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103f20:	55                   	push   %ebp
f0103f21:	89 e5                	mov    %esp,%ebp
f0103f23:	83 ec 28             	sub    $0x28,%esp
f0103f26:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	//	panic("syscall not implemented");

	switch (syscallno) {
f0103f29:	83 f8 01             	cmp    $0x1,%eax
f0103f2c:	74 5e                	je     f0103f8c <syscall+0x6c>
f0103f2e:	83 f8 01             	cmp    $0x1,%eax
f0103f31:	72 12                	jb     f0103f45 <syscall+0x25>
f0103f33:	83 f8 02             	cmp    $0x2,%eax
f0103f36:	74 5b                	je     f0103f93 <syscall+0x73>
f0103f38:	83 f8 03             	cmp    $0x3,%eax
f0103f3b:	74 60                	je     f0103f9d <syscall+0x7d>
f0103f3d:	8d 76 00             	lea    0x0(%esi),%esi
f0103f40:	e9 c4 00 00 00       	jmp    f0104009 <syscall+0xe9>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not:.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, 0);
f0103f45:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103f4c:	00 
f0103f4d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103f50:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f54:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f57:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f5b:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103f60:	89 04 24             	mov    %eax,(%esp)
f0103f63:	e8 7a ef ff ff       	call   f0102ee2 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103f68:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103f6b:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f6f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103f72:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f76:	c7 04 24 90 64 10 f0 	movl   $0xf0106490,(%esp)
f0103f7d:	e8 5f f7 ff ff       	call   f01036e1 <cprintf>
	//	panic("syscall not implemented");

	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
f0103f82:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f87:	e9 82 00 00 00       	jmp    f010400e <syscall+0xee>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103f8c:	e8 44 c5 ff ff       	call   f01004d5 <cons_getc>
	switch (syscallno) {
		case (SYS_cputs):
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
f0103f91:	eb 7b                	jmp    f010400e <syscall+0xee>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103f93:	a1 e8 d1 17 f0       	mov    0xf017d1e8,%eax
f0103f98:	8b 40 48             	mov    0x48(%eax),%eax
			sys_cputs((const char *)a1, a2);
			return 0;
		case (SYS_cgetc):
			return sys_cgetc();
		case (SYS_getenvid):
			return sys_getenvid();
f0103f9b:	eb 71                	jmp    f010400e <syscall+0xee>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103f9d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0103fa4:	00 
f0103fa5:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103fa8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fac:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103faf:	89 04 24             	mov    %eax,(%esp)
f0103fb2:	e8 1e f0 ff ff       	call   f0102fd5 <envid2env>
f0103fb7:	85 c0                	test   %eax,%eax
f0103fb9:	78 53                	js     f010400e <syscall+0xee>
		return r;
	if (e == curenv)
f0103fbb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103fbe:	8b 15 e8 d1 17 f0    	mov    0xf017d1e8,%edx
f0103fc4:	39 d0                	cmp    %edx,%eax
f0103fc6:	75 15                	jne    f0103fdd <syscall+0xbd>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103fc8:	8b 40 48             	mov    0x48(%eax),%eax
f0103fcb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fcf:	c7 04 24 95 64 10 f0 	movl   $0xf0106495,(%esp)
f0103fd6:	e8 06 f7 ff ff       	call   f01036e1 <cprintf>
f0103fdb:	eb 1a                	jmp    f0103ff7 <syscall+0xd7>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103fdd:	8b 40 48             	mov    0x48(%eax),%eax
f0103fe0:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fe4:	8b 42 48             	mov    0x48(%edx),%eax
f0103fe7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103feb:	c7 04 24 b0 64 10 f0 	movl   $0xf01064b0,(%esp)
f0103ff2:	e8 ea f6 ff ff       	call   f01036e1 <cprintf>
	env_destroy(e);
f0103ff7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103ffa:	89 04 24             	mov    %eax,(%esp)
f0103ffd:	e8 ac f5 ff ff       	call   f01035ae <env_destroy>
	return 0;
f0104002:	b8 00 00 00 00       	mov    $0x0,%eax
f0104007:	eb 05                	jmp    f010400e <syscall+0xee>
		case (SYS_getenvid):
			return sys_getenvid();
		case (SYS_env_destroy):
			return sys_env_destroy(a1);
		default:
			return -E_INVAL;
f0104009:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
}
f010400e:	c9                   	leave  
f010400f:	c3                   	ret    

f0104010 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104010:	55                   	push   %ebp
f0104011:	89 e5                	mov    %esp,%ebp
f0104013:	57                   	push   %edi
f0104014:	56                   	push   %esi
f0104015:	53                   	push   %ebx
f0104016:	83 ec 14             	sub    $0x14,%esp
f0104019:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010401c:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010401f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104022:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104025:	8b 1a                	mov    (%edx),%ebx
f0104027:	8b 01                	mov    (%ecx),%eax
f0104029:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010402c:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104033:	e9 88 00 00 00       	jmp    f01040c0 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104038:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010403b:	01 d8                	add    %ebx,%eax
f010403d:	89 c7                	mov    %eax,%edi
f010403f:	c1 ef 1f             	shr    $0x1f,%edi
f0104042:	01 c7                	add    %eax,%edi
f0104044:	d1 ff                	sar    %edi
f0104046:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104049:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010404c:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f010404f:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104051:	eb 03                	jmp    f0104056 <stab_binsearch+0x46>
			m--;
f0104053:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104056:	39 c3                	cmp    %eax,%ebx
f0104058:	7f 1f                	jg     f0104079 <stab_binsearch+0x69>
f010405a:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010405e:	83 ea 0c             	sub    $0xc,%edx
f0104061:	39 f1                	cmp    %esi,%ecx
f0104063:	75 ee                	jne    f0104053 <stab_binsearch+0x43>
f0104065:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104068:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010406b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010406e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104072:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104075:	76 18                	jbe    f010408f <stab_binsearch+0x7f>
f0104077:	eb 05                	jmp    f010407e <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104079:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f010407c:	eb 42                	jmp    f01040c0 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f010407e:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104081:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104083:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104086:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010408d:	eb 31                	jmp    f01040c0 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010408f:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104092:	73 17                	jae    f01040ab <stab_binsearch+0x9b>
			*region_right = m - 1;
f0104094:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104097:	83 e8 01             	sub    $0x1,%eax
f010409a:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010409d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01040a0:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040a2:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01040a9:	eb 15                	jmp    f01040c0 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01040ab:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040ae:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01040b1:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f01040b3:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01040b7:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01040b9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01040c0:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01040c3:	0f 8e 6f ff ff ff    	jle    f0104038 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01040c9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01040cd:	75 0f                	jne    f01040de <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f01040cf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01040d2:	8b 00                	mov    (%eax),%eax
f01040d4:	83 e8 01             	sub    $0x1,%eax
f01040d7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01040da:	89 07                	mov    %eax,(%edi)
f01040dc:	eb 2c                	jmp    f010410a <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01040de:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01040e1:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01040e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01040e6:	8b 0f                	mov    (%edi),%ecx
f01040e8:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01040eb:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01040ee:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01040f1:	eb 03                	jmp    f01040f6 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01040f3:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01040f6:	39 c8                	cmp    %ecx,%eax
f01040f8:	7e 0b                	jle    f0104105 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f01040fa:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f01040fe:	83 ea 0c             	sub    $0xc,%edx
f0104101:	39 f3                	cmp    %esi,%ebx
f0104103:	75 ee                	jne    f01040f3 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104105:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104108:	89 07                	mov    %eax,(%edi)
	}
}
f010410a:	83 c4 14             	add    $0x14,%esp
f010410d:	5b                   	pop    %ebx
f010410e:	5e                   	pop    %esi
f010410f:	5f                   	pop    %edi
f0104110:	5d                   	pop    %ebp
f0104111:	c3                   	ret    

f0104112 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104112:	55                   	push   %ebp
f0104113:	89 e5                	mov    %esp,%ebp
f0104115:	57                   	push   %edi
f0104116:	56                   	push   %esi
f0104117:	53                   	push   %ebx
f0104118:	83 ec 3c             	sub    $0x3c,%esp
f010411b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010411e:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104121:	c7 06 c8 64 10 f0    	movl   $0xf01064c8,(%esi)
	info->eip_line = 0;
f0104127:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f010412e:	c7 46 08 c8 64 10 f0 	movl   $0xf01064c8,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104135:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010413c:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f010413f:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104146:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010414c:	77 21                	ja     f010416f <debuginfo_eip+0x5d>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f010414e:	a1 00 00 20 00       	mov    0x200000,%eax
f0104153:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0104156:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f010415b:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f0104161:	89 5d d0             	mov    %ebx,-0x30(%ebp)
		stabstr_end = usd->stabstr_end;
f0104164:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f010416a:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f010416d:	eb 1a                	jmp    f0104189 <debuginfo_eip+0x77>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f010416f:	c7 45 cc d7 0c 11 f0 	movl   $0xf0110cd7,-0x34(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104176:	c7 45 d0 5d e2 10 f0 	movl   $0xf010e25d,-0x30(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010417d:	b8 5c e2 10 f0       	mov    $0xf010e25c,%eax
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104182:	c7 45 d4 f0 66 10 f0 	movl   $0xf01066f0,-0x2c(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104189:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010418c:	39 4d d0             	cmp    %ecx,-0x30(%ebp)
f010418f:	0f 83 2f 01 00 00    	jae    f01042c4 <debuginfo_eip+0x1b2>
f0104195:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0104199:	0f 85 2c 01 00 00    	jne    f01042cb <debuginfo_eip+0x1b9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010419f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01041a6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01041a9:	29 d8                	sub    %ebx,%eax
f01041ab:	c1 f8 02             	sar    $0x2,%eax
f01041ae:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01041b4:	83 e8 01             	sub    $0x1,%eax
f01041b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01041ba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01041be:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01041c5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01041c8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01041cb:	89 d8                	mov    %ebx,%eax
f01041cd:	e8 3e fe ff ff       	call   f0104010 <stab_binsearch>
	if (lfile == 0)
f01041d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01041d5:	85 c0                	test   %eax,%eax
f01041d7:	0f 84 f5 00 00 00    	je     f01042d2 <debuginfo_eip+0x1c0>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01041dd:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01041e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01041e3:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01041e6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01041ea:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01041f1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01041f4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01041f7:	89 d8                	mov    %ebx,%eax
f01041f9:	e8 12 fe ff ff       	call   f0104010 <stab_binsearch>

	if (lfun <= rfun) {
f01041fe:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0104201:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0104204:	7f 23                	jg     f0104229 <debuginfo_eip+0x117>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104206:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104209:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010420c:	8d 04 87             	lea    (%edi,%eax,4),%eax
f010420f:	8b 10                	mov    (%eax),%edx
f0104211:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104214:	2b 4d d0             	sub    -0x30(%ebp),%ecx
f0104217:	39 ca                	cmp    %ecx,%edx
f0104219:	73 06                	jae    f0104221 <debuginfo_eip+0x10f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010421b:	03 55 d0             	add    -0x30(%ebp),%edx
f010421e:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104221:	8b 40 08             	mov    0x8(%eax),%eax
f0104224:	89 46 10             	mov    %eax,0x10(%esi)
f0104227:	eb 06                	jmp    f010422f <debuginfo_eip+0x11d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104229:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f010422c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010422f:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104236:	00 
f0104237:	8b 46 08             	mov    0x8(%esi),%eax
f010423a:	89 04 24             	mov    %eax,(%esp)
f010423d:	e8 c9 08 00 00       	call   f0104b0b <strfind>
f0104242:	2b 46 08             	sub    0x8(%esi),%eax
f0104245:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104248:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010424b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010424e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104251:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0104254:	eb 06                	jmp    f010425c <debuginfo_eip+0x14a>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0104256:	83 eb 01             	sub    $0x1,%ebx
f0104259:	83 e8 0c             	sub    $0xc,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010425c:	39 fb                	cmp    %edi,%ebx
f010425e:	7c 2c                	jl     f010428c <debuginfo_eip+0x17a>
	       && stabs[lline].n_type != N_SOL
f0104260:	0f b6 50 04          	movzbl 0x4(%eax),%edx
f0104264:	80 fa 84             	cmp    $0x84,%dl
f0104267:	74 0b                	je     f0104274 <debuginfo_eip+0x162>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104269:	80 fa 64             	cmp    $0x64,%dl
f010426c:	75 e8                	jne    f0104256 <debuginfo_eip+0x144>
f010426e:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0104272:	74 e2                	je     f0104256 <debuginfo_eip+0x144>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104274:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104277:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010427a:	8b 04 87             	mov    (%edi,%eax,4),%eax
f010427d:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0104280:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0104283:	39 d0                	cmp    %edx,%eax
f0104285:	73 05                	jae    f010428c <debuginfo_eip+0x17a>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104287:	03 45 d0             	add    -0x30(%ebp),%eax
f010428a:	89 06                	mov    %eax,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010428c:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f010428f:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104292:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104297:	39 cb                	cmp    %ecx,%ebx
f0104299:	7d 43                	jge    f01042de <debuginfo_eip+0x1cc>
		for (lline = lfun + 1;
f010429b:	8d 53 01             	lea    0x1(%ebx),%edx
f010429e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01042a1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01042a4:	8d 04 87             	lea    (%edi,%eax,4),%eax
f01042a7:	eb 07                	jmp    f01042b0 <debuginfo_eip+0x19e>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f01042a9:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01042ad:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01042b0:	39 ca                	cmp    %ecx,%edx
f01042b2:	74 25                	je     f01042d9 <debuginfo_eip+0x1c7>
f01042b4:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01042b7:	80 78 04 a0          	cmpb   $0xa0,0x4(%eax)
f01042bb:	74 ec                	je     f01042a9 <debuginfo_eip+0x197>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01042bd:	b8 00 00 00 00       	mov    $0x0,%eax
f01042c2:	eb 1a                	jmp    f01042de <debuginfo_eip+0x1cc>
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01042c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01042c9:	eb 13                	jmp    f01042de <debuginfo_eip+0x1cc>
f01042cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01042d0:	eb 0c                	jmp    f01042de <debuginfo_eip+0x1cc>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01042d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01042d7:	eb 05                	jmp    f01042de <debuginfo_eip+0x1cc>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01042d9:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01042de:	83 c4 3c             	add    $0x3c,%esp
f01042e1:	5b                   	pop    %ebx
f01042e2:	5e                   	pop    %esi
f01042e3:	5f                   	pop    %edi
f01042e4:	5d                   	pop    %ebp
f01042e5:	c3                   	ret    
f01042e6:	66 90                	xchg   %ax,%ax
f01042e8:	66 90                	xchg   %ax,%ax
f01042ea:	66 90                	xchg   %ax,%ax
f01042ec:	66 90                	xchg   %ax,%ax
f01042ee:	66 90                	xchg   %ax,%ax

f01042f0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01042f0:	55                   	push   %ebp
f01042f1:	89 e5                	mov    %esp,%ebp
f01042f3:	57                   	push   %edi
f01042f4:	56                   	push   %esi
f01042f5:	53                   	push   %ebx
f01042f6:	83 ec 3c             	sub    $0x3c,%esp
f01042f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01042fc:	89 d7                	mov    %edx,%edi
f01042fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0104301:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104304:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104307:	89 c3                	mov    %eax,%ebx
f0104309:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010430c:	8b 45 10             	mov    0x10(%ebp),%eax
f010430f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104312:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104317:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010431a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010431d:	39 d9                	cmp    %ebx,%ecx
f010431f:	72 05                	jb     f0104326 <printnum+0x36>
f0104321:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0104324:	77 69                	ja     f010438f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104326:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104329:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f010432d:	83 ee 01             	sub    $0x1,%esi
f0104330:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104334:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104338:	8b 44 24 08          	mov    0x8(%esp),%eax
f010433c:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104340:	89 c3                	mov    %eax,%ebx
f0104342:	89 d6                	mov    %edx,%esi
f0104344:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104347:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010434a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010434e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104352:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104355:	89 04 24             	mov    %eax,(%esp)
f0104358:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010435b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010435f:	e8 cc 09 00 00       	call   f0104d30 <__udivdi3>
f0104364:	89 d9                	mov    %ebx,%ecx
f0104366:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010436a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010436e:	89 04 24             	mov    %eax,(%esp)
f0104371:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104375:	89 fa                	mov    %edi,%edx
f0104377:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010437a:	e8 71 ff ff ff       	call   f01042f0 <printnum>
f010437f:	eb 1b                	jmp    f010439c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104381:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104385:	8b 45 18             	mov    0x18(%ebp),%eax
f0104388:	89 04 24             	mov    %eax,(%esp)
f010438b:	ff d3                	call   *%ebx
f010438d:	eb 03                	jmp    f0104392 <printnum+0xa2>
f010438f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104392:	83 ee 01             	sub    $0x1,%esi
f0104395:	85 f6                	test   %esi,%esi
f0104397:	7f e8                	jg     f0104381 <printnum+0x91>
f0104399:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010439c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01043a0:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01043a4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01043a7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01043aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01043ae:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01043b2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043b5:	89 04 24             	mov    %eax,(%esp)
f01043b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01043bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043bf:	e8 9c 0a 00 00       	call   f0104e60 <__umoddi3>
f01043c4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01043c8:	0f be 80 d2 64 10 f0 	movsbl -0xfef9b2e(%eax),%eax
f01043cf:	89 04 24             	mov    %eax,(%esp)
f01043d2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043d5:	ff d0                	call   *%eax
}
f01043d7:	83 c4 3c             	add    $0x3c,%esp
f01043da:	5b                   	pop    %ebx
f01043db:	5e                   	pop    %esi
f01043dc:	5f                   	pop    %edi
f01043dd:	5d                   	pop    %ebp
f01043de:	c3                   	ret    

f01043df <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01043df:	55                   	push   %ebp
f01043e0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01043e2:	83 fa 01             	cmp    $0x1,%edx
f01043e5:	7e 0e                	jle    f01043f5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01043e7:	8b 10                	mov    (%eax),%edx
f01043e9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01043ec:	89 08                	mov    %ecx,(%eax)
f01043ee:	8b 02                	mov    (%edx),%eax
f01043f0:	8b 52 04             	mov    0x4(%edx),%edx
f01043f3:	eb 22                	jmp    f0104417 <getuint+0x38>
	else if (lflag)
f01043f5:	85 d2                	test   %edx,%edx
f01043f7:	74 10                	je     f0104409 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01043f9:	8b 10                	mov    (%eax),%edx
f01043fb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01043fe:	89 08                	mov    %ecx,(%eax)
f0104400:	8b 02                	mov    (%edx),%eax
f0104402:	ba 00 00 00 00       	mov    $0x0,%edx
f0104407:	eb 0e                	jmp    f0104417 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104409:	8b 10                	mov    (%eax),%edx
f010440b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010440e:	89 08                	mov    %ecx,(%eax)
f0104410:	8b 02                	mov    (%edx),%eax
f0104412:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104417:	5d                   	pop    %ebp
f0104418:	c3                   	ret    

f0104419 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104419:	55                   	push   %ebp
f010441a:	89 e5                	mov    %esp,%ebp
f010441c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010441f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104423:	8b 10                	mov    (%eax),%edx
f0104425:	3b 50 04             	cmp    0x4(%eax),%edx
f0104428:	73 0a                	jae    f0104434 <sprintputch+0x1b>
		*b->buf++ = ch;
f010442a:	8d 4a 01             	lea    0x1(%edx),%ecx
f010442d:	89 08                	mov    %ecx,(%eax)
f010442f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104432:	88 02                	mov    %al,(%edx)
}
f0104434:	5d                   	pop    %ebp
f0104435:	c3                   	ret    

f0104436 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104436:	55                   	push   %ebp
f0104437:	89 e5                	mov    %esp,%ebp
f0104439:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f010443c:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010443f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104443:	8b 45 10             	mov    0x10(%ebp),%eax
f0104446:	89 44 24 08          	mov    %eax,0x8(%esp)
f010444a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010444d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104451:	8b 45 08             	mov    0x8(%ebp),%eax
f0104454:	89 04 24             	mov    %eax,(%esp)
f0104457:	e8 02 00 00 00       	call   f010445e <vprintfmt>
	va_end(ap);
}
f010445c:	c9                   	leave  
f010445d:	c3                   	ret    

f010445e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010445e:	55                   	push   %ebp
f010445f:	89 e5                	mov    %esp,%ebp
f0104461:	57                   	push   %edi
f0104462:	56                   	push   %esi
f0104463:	53                   	push   %ebx
f0104464:	83 ec 3c             	sub    $0x3c,%esp
f0104467:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010446a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010446d:	eb 14                	jmp    f0104483 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
			if (ch == '\0')									//当然中间如果遇到'\0'，代表这个字符串的访问结束
f010446f:	85 c0                	test   %eax,%eax
f0104471:	0f 84 c7 03 00 00    	je     f010483e <vprintfmt+0x3e0>
				return;
			putch(ch, putdat);								//调用putch函数，把一个字符ch输出到putdat指针所指向的地址中所存放的值对应的地址处
f0104477:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010447b:	89 04 24             	mov    %eax,(%esp)
f010447e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {    //遍历输入的第一个参数，即输出信息的格式，先把格式字符串中'%'之前的字符一个个输出，因为它们前面没有'%'，所以它们就是要直接显示在屏幕上的
f0104481:	89 f3                	mov    %esi,%ebx
f0104483:	8d 73 01             	lea    0x1(%ebx),%esi
f0104486:	0f b6 03             	movzbl (%ebx),%eax
f0104489:	83 f8 25             	cmp    $0x25,%eax
f010448c:	75 e1                	jne    f010446f <vprintfmt+0x11>
f010448e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104492:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0104499:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f01044a0:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f01044a7:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f01044ae:	b9 00 00 00 00       	mov    $0x0,%ecx
f01044b3:	eb 1d                	jmp    f01044d2 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f01044b5:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':											//%后面的'-'代表要进行左对齐输出，右边填空格，如果省略代表右对齐
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
f01044b7:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01044bb:	eb 15                	jmp    f01044d2 <vprintfmt+0x74>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f01044bd:	89 de                	mov    %ebx,%esi
			padc = '-';										//如果有这个字符代表左对齐，则把对齐方式标志位变为'-'
			goto reswitch;									//处理下一个字符

		// flag to pad with 0's instead of spaces
		case '0':											//0--有0表示进行对齐输出时填0,如省略表示填入空格，并且如果为0，则一定是右对齐
			padc = '0';										//对其方式标志位变为0
f01044bf:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01044c3:	eb 0d                	jmp    f01044d2 <vprintfmt+0x74>
			altflag = 1;
			goto reswitch;

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
				width = precision, precision = -1;
f01044c5:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01044c8:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01044cb:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f01044d2:	8d 5e 01             	lea    0x1(%esi),%ebx
f01044d5:	0f b6 16             	movzbl (%esi),%edx
f01044d8:	0f b6 c2             	movzbl %dl,%eax
f01044db:	83 ea 23             	sub    $0x23,%edx
f01044de:	80 fa 55             	cmp    $0x55,%dl
f01044e1:	0f 87 37 03 00 00    	ja     f010481e <vprintfmt+0x3c0>
f01044e7:	0f b6 d2             	movzbl %dl,%edx
f01044ea:	ff 24 95 60 65 10 f0 	jmp    *-0xfef9aa0(,%edx,4)
f01044f1:	89 de                	mov    %ebx,%esi
f01044f3:	89 ca                	mov    %ecx,%edx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
				precision = precision * 10 + ch - '0';
f01044f5:	8d 14 92             	lea    (%edx,%edx,4),%edx
f01044f8:	8d 54 50 d0          	lea    -0x30(%eax,%edx,2),%edx
				ch = *fmt;
f01044fc:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01044ff:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0104502:	83 fb 09             	cmp    $0x9,%ebx
f0104505:	77 31                	ja     f0104538 <vprintfmt+0xda>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {					//把遇到的位数字符串转换为真实的位数，比如输入的'%40'，代表有效位数为40位，下面的循环就是把precesion的值设置为40
f0104507:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f010450a:	eb e9                	jmp    f01044f5 <vprintfmt+0x97>
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
f010450c:	8b 45 14             	mov    0x14(%ebp),%eax
f010450f:	8d 50 04             	lea    0x4(%eax),%edx
f0104512:	89 55 14             	mov    %edx,0x14(%ebp)
f0104515:	8b 00                	mov    (%eax),%eax
f0104517:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f010451a:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;							//跳转到process_precistion子过程

		case '*':											//*--代表有效数字的位数也是由输入参数指定的，比如printf("%*.*f", 10, 2, n)，其中10,2就是用来指定显示的有效数字位数的
			precision = va_arg(ap, int);
			goto process_precision;
f010451c:	eb 1d                	jmp    f010453b <vprintfmt+0xdd>
f010451e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104521:	85 c0                	test   %eax,%eax
f0104523:	0f 48 c1             	cmovs  %ecx,%eax
f0104526:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0104529:	89 de                	mov    %ebx,%esi
f010452b:	eb a5                	jmp    f01044d2 <vprintfmt+0x74>
f010452d:	89 de                	mov    %ebx,%esi
			if (width < 0)									//代表有小数点，但是小数点前面并没有数字，比如'%.6f'这种情况，此时代表整数部分全部显示
				width = 0;			
			goto reswitch;

		case '#':
			altflag = 1;
f010452f:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f0104536:	eb 9a                	jmp    f01044d2 <vprintfmt+0x74>
f0104538:	89 55 d0             	mov    %edx,-0x30(%ebp)

		process_precision:									//处理输出精度，把width字段赋值为刚刚计算出来的precision值，所以width应该是整数部分的有效数字位数
			if (width < 0)
f010453b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010453f:	79 91                	jns    f01044d2 <vprintfmt+0x74>
f0104541:	eb 82                	jmp    f01044c5 <vprintfmt+0x67>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
f0104543:	83 45 d4 01          	addl   $0x1,-0x2c(%ebp)
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f0104547:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)				
		case 'l':											//如果遇到'l'，代表应该是输入long类型，如果有两个'l'代表long long
			lflag++;										//此时把lflag++
			goto reswitch;
f0104549:	eb 87                	jmp    f01044d2 <vprintfmt+0x74>

		// character
		case 'c':											//如果是'c'代表显示一个字符
			putch(va_arg(ap, int), putdat);					//调用输出一个字符到内存的函数putch
f010454b:	8b 45 14             	mov    0x14(%ebp),%eax
f010454e:	8d 50 04             	lea    0x4(%eax),%edx
f0104551:	89 55 14             	mov    %edx,0x14(%ebp)
f0104554:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104558:	8b 00                	mov    (%eax),%eax
f010455a:	89 04 24             	mov    %eax,(%esp)
f010455d:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104560:	e9 1e ff ff ff       	jmp    f0104483 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104565:	8b 45 14             	mov    0x14(%ebp),%eax
f0104568:	8d 50 04             	lea    0x4(%eax),%edx
f010456b:	89 55 14             	mov    %edx,0x14(%ebp)
f010456e:	8b 00                	mov    (%eax),%eax
f0104570:	99                   	cltd   
f0104571:	31 d0                	xor    %edx,%eax
f0104573:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104575:	83 f8 07             	cmp    $0x7,%eax
f0104578:	7f 0b                	jg     f0104585 <vprintfmt+0x127>
f010457a:	8b 14 85 c0 66 10 f0 	mov    -0xfef9940(,%eax,4),%edx
f0104581:	85 d2                	test   %edx,%edx
f0104583:	75 20                	jne    f01045a5 <vprintfmt+0x147>
				printfmt(putch, putdat, "error %d", err);
f0104585:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104589:	c7 44 24 08 ea 64 10 	movl   $0xf01064ea,0x8(%esp)
f0104590:	f0 
f0104591:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104595:	8b 45 08             	mov    0x8(%ebp),%eax
f0104598:	89 04 24             	mov    %eax,(%esp)
f010459b:	e8 96 fe ff ff       	call   f0104436 <printfmt>
f01045a0:	e9 de fe ff ff       	jmp    f0104483 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f01045a5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01045a9:	c7 44 24 08 0c 55 10 	movl   $0xf010550c,0x8(%esp)
f01045b0:	f0 
f01045b1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01045b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01045b8:	89 04 24             	mov    %eax,(%esp)
f01045bb:	e8 76 fe ff ff       	call   f0104436 <printfmt>
f01045c0:	e9 be fe ff ff       	jmp    f0104483 <vprintfmt+0x25>
		width = -1;											//整数部分有效数字位数
		precision = -1;										//小数部分有效数字位数
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {			//根据位于'%'后面的第一个字符进行分情况处理
f01045c5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01045c8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01045cb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01045ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01045d1:	8d 50 04             	lea    0x4(%eax),%edx
f01045d4:	89 55 14             	mov    %edx,0x14(%ebp)
f01045d7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01045d9:	85 f6                	test   %esi,%esi
f01045db:	b8 e3 64 10 f0       	mov    $0xf01064e3,%eax
f01045e0:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01045e3:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01045e7:	0f 84 97 00 00 00    	je     f0104684 <vprintfmt+0x226>
f01045ed:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01045f1:	0f 8e 9b 00 00 00    	jle    f0104692 <vprintfmt+0x234>
				for (width -= strnlen(p, precision); width > 0; width--)
f01045f7:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01045fb:	89 34 24             	mov    %esi,(%esp)
f01045fe:	e8 b5 03 00 00       	call   f01049b8 <strnlen>
f0104603:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104606:	29 c1                	sub    %eax,%ecx
f0104608:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
					putch(padc, putdat);
f010460b:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010460f:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104612:	89 75 d8             	mov    %esi,-0x28(%ebp)
f0104615:	8b 75 08             	mov    0x8(%ebp),%esi
f0104618:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010461b:	89 cb                	mov    %ecx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010461d:	eb 0f                	jmp    f010462e <vprintfmt+0x1d0>
					putch(padc, putdat);
f010461f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104623:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104626:	89 04 24             	mov    %eax,(%esp)
f0104629:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010462b:	83 eb 01             	sub    $0x1,%ebx
f010462e:	85 db                	test   %ebx,%ebx
f0104630:	7f ed                	jg     f010461f <vprintfmt+0x1c1>
f0104632:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0104635:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0104638:	85 c9                	test   %ecx,%ecx
f010463a:	b8 00 00 00 00       	mov    $0x0,%eax
f010463f:	0f 49 c1             	cmovns %ecx,%eax
f0104642:	29 c1                	sub    %eax,%ecx
f0104644:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104647:	89 cf                	mov    %ecx,%edi
f0104649:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010464c:	eb 50                	jmp    f010469e <vprintfmt+0x240>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010464e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104652:	74 1e                	je     f0104672 <vprintfmt+0x214>
f0104654:	0f be d2             	movsbl %dl,%edx
f0104657:	83 ea 20             	sub    $0x20,%edx
f010465a:	83 fa 5e             	cmp    $0x5e,%edx
f010465d:	76 13                	jbe    f0104672 <vprintfmt+0x214>
					putch('?', putdat);
f010465f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104662:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104666:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f010466d:	ff 55 08             	call   *0x8(%ebp)
f0104670:	eb 0d                	jmp    f010467f <vprintfmt+0x221>
				else
					putch(ch, putdat);
f0104672:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104675:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104679:	89 04 24             	mov    %eax,(%esp)
f010467c:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010467f:	83 ef 01             	sub    $0x1,%edi
f0104682:	eb 1a                	jmp    f010469e <vprintfmt+0x240>
f0104684:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104687:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010468a:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010468d:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0104690:	eb 0c                	jmp    f010469e <vprintfmt+0x240>
f0104692:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104695:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104698:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010469b:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010469e:	83 c6 01             	add    $0x1,%esi
f01046a1:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f01046a5:	0f be c2             	movsbl %dl,%eax
f01046a8:	85 c0                	test   %eax,%eax
f01046aa:	74 27                	je     f01046d3 <vprintfmt+0x275>
f01046ac:	85 db                	test   %ebx,%ebx
f01046ae:	78 9e                	js     f010464e <vprintfmt+0x1f0>
f01046b0:	83 eb 01             	sub    $0x1,%ebx
f01046b3:	79 99                	jns    f010464e <vprintfmt+0x1f0>
f01046b5:	89 f8                	mov    %edi,%eax
f01046b7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01046ba:	8b 75 08             	mov    0x8(%ebp),%esi
f01046bd:	89 c3                	mov    %eax,%ebx
f01046bf:	eb 1a                	jmp    f01046db <vprintfmt+0x27d>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01046c1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01046c5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01046cc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01046ce:	83 eb 01             	sub    $0x1,%ebx
f01046d1:	eb 08                	jmp    f01046db <vprintfmt+0x27d>
f01046d3:	89 fb                	mov    %edi,%ebx
f01046d5:	8b 75 08             	mov    0x8(%ebp),%esi
f01046d8:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01046db:	85 db                	test   %ebx,%ebx
f01046dd:	7f e2                	jg     f01046c1 <vprintfmt+0x263>
f01046df:	89 75 08             	mov    %esi,0x8(%ebp)
f01046e2:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01046e5:	e9 99 fd ff ff       	jmp    f0104483 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01046ea:	83 7d d4 01          	cmpl   $0x1,-0x2c(%ebp)
f01046ee:	7e 16                	jle    f0104706 <vprintfmt+0x2a8>
		return va_arg(*ap, long long);
f01046f0:	8b 45 14             	mov    0x14(%ebp),%eax
f01046f3:	8d 50 08             	lea    0x8(%eax),%edx
f01046f6:	89 55 14             	mov    %edx,0x14(%ebp)
f01046f9:	8b 50 04             	mov    0x4(%eax),%edx
f01046fc:	8b 00                	mov    (%eax),%eax
f01046fe:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104701:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104704:	eb 34                	jmp    f010473a <vprintfmt+0x2dc>
	else if (lflag)
f0104706:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f010470a:	74 18                	je     f0104724 <vprintfmt+0x2c6>
		return va_arg(*ap, long);
f010470c:	8b 45 14             	mov    0x14(%ebp),%eax
f010470f:	8d 50 04             	lea    0x4(%eax),%edx
f0104712:	89 55 14             	mov    %edx,0x14(%ebp)
f0104715:	8b 30                	mov    (%eax),%esi
f0104717:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010471a:	89 f0                	mov    %esi,%eax
f010471c:	c1 f8 1f             	sar    $0x1f,%eax
f010471f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104722:	eb 16                	jmp    f010473a <vprintfmt+0x2dc>
	else
		return va_arg(*ap, int);
f0104724:	8b 45 14             	mov    0x14(%ebp),%eax
f0104727:	8d 50 04             	lea    0x4(%eax),%edx
f010472a:	89 55 14             	mov    %edx,0x14(%ebp)
f010472d:	8b 30                	mov    (%eax),%esi
f010472f:	89 75 e0             	mov    %esi,-0x20(%ebp)
f0104732:	89 f0                	mov    %esi,%eax
f0104734:	c1 f8 1f             	sar    $0x1f,%eax
f0104737:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f010473a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010473d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104740:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104745:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104749:	0f 89 97 00 00 00    	jns    f01047e6 <vprintfmt+0x388>
				putch('-', putdat);
f010474f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104753:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010475a:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010475d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104760:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104763:	f7 d8                	neg    %eax
f0104765:	83 d2 00             	adc    $0x0,%edx
f0104768:	f7 da                	neg    %edx
			}
			base = 10;
f010476a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f010476f:	eb 75                	jmp    f01047e6 <vprintfmt+0x388>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104771:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104774:	8d 45 14             	lea    0x14(%ebp),%eax
f0104777:	e8 63 fc ff ff       	call   f01043df <getuint>
			base = 10;
f010477c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104781:	eb 63                	jmp    f01047e6 <vprintfmt+0x388>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('0', putdat);
f0104783:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104787:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010478e:	ff 55 08             	call   *0x8(%ebp)
			num = getuint(&ap, lflag);
f0104791:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104794:	8d 45 14             	lea    0x14(%ebp),%eax
f0104797:	e8 43 fc ff ff       	call   f01043df <getuint>
			base = 8;
f010479c:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f01047a1:	eb 43                	jmp    f01047e6 <vprintfmt+0x388>
		// pointer
		case 'p':
			putch('0', putdat);
f01047a3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01047a7:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01047ae:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01047b1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01047b5:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01047bc:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01047bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01047c2:	8d 50 04             	lea    0x4(%eax),%edx
f01047c5:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01047c8:	8b 00                	mov    (%eax),%eax
f01047ca:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01047cf:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f01047d4:	eb 10                	jmp    f01047e6 <vprintfmt+0x388>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01047d6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01047d9:	8d 45 14             	lea    0x14(%ebp),%eax
f01047dc:	e8 fe fb ff ff       	call   f01043df <getuint>
			base = 16;
f01047e1:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f01047e6:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f01047ea:	89 74 24 10          	mov    %esi,0x10(%esp)
f01047ee:	8b 75 dc             	mov    -0x24(%ebp),%esi
f01047f1:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01047f5:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01047f9:	89 04 24             	mov    %eax,(%esp)
f01047fc:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104800:	89 fa                	mov    %edi,%edx
f0104802:	8b 45 08             	mov    0x8(%ebp),%eax
f0104805:	e8 e6 fa ff ff       	call   f01042f0 <printnum>
			break;
f010480a:	e9 74 fc ff ff       	jmp    f0104483 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010480f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104813:	89 04 24             	mov    %eax,(%esp)
f0104816:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104819:	e9 65 fc ff ff       	jmp    f0104483 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010481e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104822:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104829:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010482c:	89 f3                	mov    %esi,%ebx
f010482e:	eb 03                	jmp    f0104833 <vprintfmt+0x3d5>
f0104830:	83 eb 01             	sub    $0x1,%ebx
f0104833:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0104837:	75 f7                	jne    f0104830 <vprintfmt+0x3d2>
f0104839:	e9 45 fc ff ff       	jmp    f0104483 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010483e:	83 c4 3c             	add    $0x3c,%esp
f0104841:	5b                   	pop    %ebx
f0104842:	5e                   	pop    %esi
f0104843:	5f                   	pop    %edi
f0104844:	5d                   	pop    %ebp
f0104845:	c3                   	ret    

f0104846 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104846:	55                   	push   %ebp
f0104847:	89 e5                	mov    %esp,%ebp
f0104849:	83 ec 28             	sub    $0x28,%esp
f010484c:	8b 45 08             	mov    0x8(%ebp),%eax
f010484f:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104852:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104855:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104859:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010485c:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104863:	85 c0                	test   %eax,%eax
f0104865:	74 30                	je     f0104897 <vsnprintf+0x51>
f0104867:	85 d2                	test   %edx,%edx
f0104869:	7e 2c                	jle    f0104897 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f010486b:	8b 45 14             	mov    0x14(%ebp),%eax
f010486e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104872:	8b 45 10             	mov    0x10(%ebp),%eax
f0104875:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104879:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010487c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104880:	c7 04 24 19 44 10 f0 	movl   $0xf0104419,(%esp)
f0104887:	e8 d2 fb ff ff       	call   f010445e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010488c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010488f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104892:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104895:	eb 05                	jmp    f010489c <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104897:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010489c:	c9                   	leave  
f010489d:	c3                   	ret    

f010489e <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010489e:	55                   	push   %ebp
f010489f:	89 e5                	mov    %esp,%ebp
f01048a1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01048a4:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01048a7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01048ab:	8b 45 10             	mov    0x10(%ebp),%eax
f01048ae:	89 44 24 08          	mov    %eax,0x8(%esp)
f01048b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01048b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01048b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01048bc:	89 04 24             	mov    %eax,(%esp)
f01048bf:	e8 82 ff ff ff       	call   f0104846 <vsnprintf>
	va_end(ap);

	return rc;
}
f01048c4:	c9                   	leave  
f01048c5:	c3                   	ret    
f01048c6:	66 90                	xchg   %ax,%ax
f01048c8:	66 90                	xchg   %ax,%ax
f01048ca:	66 90                	xchg   %ax,%ax
f01048cc:	66 90                	xchg   %ax,%ax
f01048ce:	66 90                	xchg   %ax,%ax

f01048d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01048d0:	55                   	push   %ebp
f01048d1:	89 e5                	mov    %esp,%ebp
f01048d3:	57                   	push   %edi
f01048d4:	56                   	push   %esi
f01048d5:	53                   	push   %ebx
f01048d6:	83 ec 1c             	sub    $0x1c,%esp
f01048d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01048dc:	85 c0                	test   %eax,%eax
f01048de:	74 10                	je     f01048f0 <readline+0x20>
		cprintf("%s", prompt);
f01048e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01048e4:	c7 04 24 0c 55 10 f0 	movl   $0xf010550c,(%esp)
f01048eb:	e8 f1 ed ff ff       	call   f01036e1 <cprintf>

	i = 0;
	echoing = iscons(0);
f01048f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01048f7:	e8 36 bd ff ff       	call   f0100632 <iscons>
f01048fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01048fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104903:	e8 19 bd ff ff       	call   f0100621 <getchar>
f0104908:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010490a:	85 c0                	test   %eax,%eax
f010490c:	79 17                	jns    f0104925 <readline+0x55>
			cprintf("read error: %e\n", c);
f010490e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104912:	c7 04 24 e0 66 10 f0 	movl   $0xf01066e0,(%esp)
f0104919:	e8 c3 ed ff ff       	call   f01036e1 <cprintf>
			return NULL;
f010491e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104923:	eb 6d                	jmp    f0104992 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104925:	83 f8 7f             	cmp    $0x7f,%eax
f0104928:	74 05                	je     f010492f <readline+0x5f>
f010492a:	83 f8 08             	cmp    $0x8,%eax
f010492d:	75 19                	jne    f0104948 <readline+0x78>
f010492f:	85 f6                	test   %esi,%esi
f0104931:	7e 15                	jle    f0104948 <readline+0x78>
			if (echoing)
f0104933:	85 ff                	test   %edi,%edi
f0104935:	74 0c                	je     f0104943 <readline+0x73>
				cputchar('\b');
f0104937:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010493e:	e8 ce bc ff ff       	call   f0100611 <cputchar>
			i--;
f0104943:	83 ee 01             	sub    $0x1,%esi
f0104946:	eb bb                	jmp    f0104903 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104948:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010494e:	7f 1c                	jg     f010496c <readline+0x9c>
f0104950:	83 fb 1f             	cmp    $0x1f,%ebx
f0104953:	7e 17                	jle    f010496c <readline+0x9c>
			if (echoing)
f0104955:	85 ff                	test   %edi,%edi
f0104957:	74 08                	je     f0104961 <readline+0x91>
				cputchar(c);
f0104959:	89 1c 24             	mov    %ebx,(%esp)
f010495c:	e8 b0 bc ff ff       	call   f0100611 <cputchar>
			buf[i++] = c;
f0104961:	88 9e a0 da 17 f0    	mov    %bl,-0xfe82560(%esi)
f0104967:	8d 76 01             	lea    0x1(%esi),%esi
f010496a:	eb 97                	jmp    f0104903 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010496c:	83 fb 0d             	cmp    $0xd,%ebx
f010496f:	74 05                	je     f0104976 <readline+0xa6>
f0104971:	83 fb 0a             	cmp    $0xa,%ebx
f0104974:	75 8d                	jne    f0104903 <readline+0x33>
			if (echoing)
f0104976:	85 ff                	test   %edi,%edi
f0104978:	74 0c                	je     f0104986 <readline+0xb6>
				cputchar('\n');
f010497a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104981:	e8 8b bc ff ff       	call   f0100611 <cputchar>
			buf[i] = 0;
f0104986:	c6 86 a0 da 17 f0 00 	movb   $0x0,-0xfe82560(%esi)
			return buf;
f010498d:	b8 a0 da 17 f0       	mov    $0xf017daa0,%eax
		}
	}
}
f0104992:	83 c4 1c             	add    $0x1c,%esp
f0104995:	5b                   	pop    %ebx
f0104996:	5e                   	pop    %esi
f0104997:	5f                   	pop    %edi
f0104998:	5d                   	pop    %ebp
f0104999:	c3                   	ret    
f010499a:	66 90                	xchg   %ax,%ax
f010499c:	66 90                	xchg   %ax,%ax
f010499e:	66 90                	xchg   %ax,%ax

f01049a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01049a0:	55                   	push   %ebp
f01049a1:	89 e5                	mov    %esp,%ebp
f01049a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01049a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01049ab:	eb 03                	jmp    f01049b0 <strlen+0x10>
		n++;
f01049ad:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01049b0:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01049b4:	75 f7                	jne    f01049ad <strlen+0xd>
		n++;
	return n;
}
f01049b6:	5d                   	pop    %ebp
f01049b7:	c3                   	ret    

f01049b8 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01049b8:	55                   	push   %ebp
f01049b9:	89 e5                	mov    %esp,%ebp
f01049bb:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01049be:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01049c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01049c6:	eb 03                	jmp    f01049cb <strnlen+0x13>
		n++;
f01049c8:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01049cb:	39 d0                	cmp    %edx,%eax
f01049cd:	74 06                	je     f01049d5 <strnlen+0x1d>
f01049cf:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01049d3:	75 f3                	jne    f01049c8 <strnlen+0x10>
		n++;
	return n;
}
f01049d5:	5d                   	pop    %ebp
f01049d6:	c3                   	ret    

f01049d7 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01049d7:	55                   	push   %ebp
f01049d8:	89 e5                	mov    %esp,%ebp
f01049da:	53                   	push   %ebx
f01049db:	8b 45 08             	mov    0x8(%ebp),%eax
f01049de:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01049e1:	89 c2                	mov    %eax,%edx
f01049e3:	83 c2 01             	add    $0x1,%edx
f01049e6:	83 c1 01             	add    $0x1,%ecx
f01049e9:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01049ed:	88 5a ff             	mov    %bl,-0x1(%edx)
f01049f0:	84 db                	test   %bl,%bl
f01049f2:	75 ef                	jne    f01049e3 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01049f4:	5b                   	pop    %ebx
f01049f5:	5d                   	pop    %ebp
f01049f6:	c3                   	ret    

f01049f7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01049f7:	55                   	push   %ebp
f01049f8:	89 e5                	mov    %esp,%ebp
f01049fa:	53                   	push   %ebx
f01049fb:	83 ec 08             	sub    $0x8,%esp
f01049fe:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104a01:	89 1c 24             	mov    %ebx,(%esp)
f0104a04:	e8 97 ff ff ff       	call   f01049a0 <strlen>
	strcpy(dst + len, src);
f0104a09:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104a0c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104a10:	01 d8                	add    %ebx,%eax
f0104a12:	89 04 24             	mov    %eax,(%esp)
f0104a15:	e8 bd ff ff ff       	call   f01049d7 <strcpy>
	return dst;
}
f0104a1a:	89 d8                	mov    %ebx,%eax
f0104a1c:	83 c4 08             	add    $0x8,%esp
f0104a1f:	5b                   	pop    %ebx
f0104a20:	5d                   	pop    %ebp
f0104a21:	c3                   	ret    

f0104a22 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104a22:	55                   	push   %ebp
f0104a23:	89 e5                	mov    %esp,%ebp
f0104a25:	56                   	push   %esi
f0104a26:	53                   	push   %ebx
f0104a27:	8b 75 08             	mov    0x8(%ebp),%esi
f0104a2a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104a2d:	89 f3                	mov    %esi,%ebx
f0104a2f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104a32:	89 f2                	mov    %esi,%edx
f0104a34:	eb 0f                	jmp    f0104a45 <strncpy+0x23>
		*dst++ = *src;
f0104a36:	83 c2 01             	add    $0x1,%edx
f0104a39:	0f b6 01             	movzbl (%ecx),%eax
f0104a3c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104a3f:	80 39 01             	cmpb   $0x1,(%ecx)
f0104a42:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104a45:	39 da                	cmp    %ebx,%edx
f0104a47:	75 ed                	jne    f0104a36 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104a49:	89 f0                	mov    %esi,%eax
f0104a4b:	5b                   	pop    %ebx
f0104a4c:	5e                   	pop    %esi
f0104a4d:	5d                   	pop    %ebp
f0104a4e:	c3                   	ret    

f0104a4f <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104a4f:	55                   	push   %ebp
f0104a50:	89 e5                	mov    %esp,%ebp
f0104a52:	56                   	push   %esi
f0104a53:	53                   	push   %ebx
f0104a54:	8b 75 08             	mov    0x8(%ebp),%esi
f0104a57:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104a5a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104a5d:	89 f0                	mov    %esi,%eax
f0104a5f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104a63:	85 c9                	test   %ecx,%ecx
f0104a65:	75 0b                	jne    f0104a72 <strlcpy+0x23>
f0104a67:	eb 1d                	jmp    f0104a86 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104a69:	83 c0 01             	add    $0x1,%eax
f0104a6c:	83 c2 01             	add    $0x1,%edx
f0104a6f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104a72:	39 d8                	cmp    %ebx,%eax
f0104a74:	74 0b                	je     f0104a81 <strlcpy+0x32>
f0104a76:	0f b6 0a             	movzbl (%edx),%ecx
f0104a79:	84 c9                	test   %cl,%cl
f0104a7b:	75 ec                	jne    f0104a69 <strlcpy+0x1a>
f0104a7d:	89 c2                	mov    %eax,%edx
f0104a7f:	eb 02                	jmp    f0104a83 <strlcpy+0x34>
f0104a81:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104a83:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104a86:	29 f0                	sub    %esi,%eax
}
f0104a88:	5b                   	pop    %ebx
f0104a89:	5e                   	pop    %esi
f0104a8a:	5d                   	pop    %ebp
f0104a8b:	c3                   	ret    

f0104a8c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104a8c:	55                   	push   %ebp
f0104a8d:	89 e5                	mov    %esp,%ebp
f0104a8f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104a92:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104a95:	eb 06                	jmp    f0104a9d <strcmp+0x11>
		p++, q++;
f0104a97:	83 c1 01             	add    $0x1,%ecx
f0104a9a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104a9d:	0f b6 01             	movzbl (%ecx),%eax
f0104aa0:	84 c0                	test   %al,%al
f0104aa2:	74 04                	je     f0104aa8 <strcmp+0x1c>
f0104aa4:	3a 02                	cmp    (%edx),%al
f0104aa6:	74 ef                	je     f0104a97 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104aa8:	0f b6 c0             	movzbl %al,%eax
f0104aab:	0f b6 12             	movzbl (%edx),%edx
f0104aae:	29 d0                	sub    %edx,%eax
}
f0104ab0:	5d                   	pop    %ebp
f0104ab1:	c3                   	ret    

f0104ab2 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104ab2:	55                   	push   %ebp
f0104ab3:	89 e5                	mov    %esp,%ebp
f0104ab5:	53                   	push   %ebx
f0104ab6:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ab9:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104abc:	89 c3                	mov    %eax,%ebx
f0104abe:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104ac1:	eb 06                	jmp    f0104ac9 <strncmp+0x17>
		n--, p++, q++;
f0104ac3:	83 c0 01             	add    $0x1,%eax
f0104ac6:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104ac9:	39 d8                	cmp    %ebx,%eax
f0104acb:	74 15                	je     f0104ae2 <strncmp+0x30>
f0104acd:	0f b6 08             	movzbl (%eax),%ecx
f0104ad0:	84 c9                	test   %cl,%cl
f0104ad2:	74 04                	je     f0104ad8 <strncmp+0x26>
f0104ad4:	3a 0a                	cmp    (%edx),%cl
f0104ad6:	74 eb                	je     f0104ac3 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104ad8:	0f b6 00             	movzbl (%eax),%eax
f0104adb:	0f b6 12             	movzbl (%edx),%edx
f0104ade:	29 d0                	sub    %edx,%eax
f0104ae0:	eb 05                	jmp    f0104ae7 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104ae2:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104ae7:	5b                   	pop    %ebx
f0104ae8:	5d                   	pop    %ebp
f0104ae9:	c3                   	ret    

f0104aea <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104aea:	55                   	push   %ebp
f0104aeb:	89 e5                	mov    %esp,%ebp
f0104aed:	8b 45 08             	mov    0x8(%ebp),%eax
f0104af0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104af4:	eb 07                	jmp    f0104afd <strchr+0x13>
		if (*s == c)
f0104af6:	38 ca                	cmp    %cl,%dl
f0104af8:	74 0f                	je     f0104b09 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104afa:	83 c0 01             	add    $0x1,%eax
f0104afd:	0f b6 10             	movzbl (%eax),%edx
f0104b00:	84 d2                	test   %dl,%dl
f0104b02:	75 f2                	jne    f0104af6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0104b04:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104b09:	5d                   	pop    %ebp
f0104b0a:	c3                   	ret    

f0104b0b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104b0b:	55                   	push   %ebp
f0104b0c:	89 e5                	mov    %esp,%ebp
f0104b0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b11:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104b15:	eb 07                	jmp    f0104b1e <strfind+0x13>
		if (*s == c)
f0104b17:	38 ca                	cmp    %cl,%dl
f0104b19:	74 0a                	je     f0104b25 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104b1b:	83 c0 01             	add    $0x1,%eax
f0104b1e:	0f b6 10             	movzbl (%eax),%edx
f0104b21:	84 d2                	test   %dl,%dl
f0104b23:	75 f2                	jne    f0104b17 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0104b25:	5d                   	pop    %ebp
f0104b26:	c3                   	ret    

f0104b27 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104b27:	55                   	push   %ebp
f0104b28:	89 e5                	mov    %esp,%ebp
f0104b2a:	57                   	push   %edi
f0104b2b:	56                   	push   %esi
f0104b2c:	53                   	push   %ebx
f0104b2d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104b30:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104b33:	85 c9                	test   %ecx,%ecx
f0104b35:	74 36                	je     f0104b6d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104b37:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104b3d:	75 28                	jne    f0104b67 <memset+0x40>
f0104b3f:	f6 c1 03             	test   $0x3,%cl
f0104b42:	75 23                	jne    f0104b67 <memset+0x40>
		c &= 0xFF;
f0104b44:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104b48:	89 d3                	mov    %edx,%ebx
f0104b4a:	c1 e3 08             	shl    $0x8,%ebx
f0104b4d:	89 d6                	mov    %edx,%esi
f0104b4f:	c1 e6 18             	shl    $0x18,%esi
f0104b52:	89 d0                	mov    %edx,%eax
f0104b54:	c1 e0 10             	shl    $0x10,%eax
f0104b57:	09 f0                	or     %esi,%eax
f0104b59:	09 c2                	or     %eax,%edx
f0104b5b:	89 d0                	mov    %edx,%eax
f0104b5d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104b5f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104b62:	fc                   	cld    
f0104b63:	f3 ab                	rep stos %eax,%es:(%edi)
f0104b65:	eb 06                	jmp    f0104b6d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104b67:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104b6a:	fc                   	cld    
f0104b6b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104b6d:	89 f8                	mov    %edi,%eax
f0104b6f:	5b                   	pop    %ebx
f0104b70:	5e                   	pop    %esi
f0104b71:	5f                   	pop    %edi
f0104b72:	5d                   	pop    %ebp
f0104b73:	c3                   	ret    

f0104b74 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104b74:	55                   	push   %ebp
f0104b75:	89 e5                	mov    %esp,%ebp
f0104b77:	57                   	push   %edi
f0104b78:	56                   	push   %esi
f0104b79:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b7c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104b7f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104b82:	39 c6                	cmp    %eax,%esi
f0104b84:	73 35                	jae    f0104bbb <memmove+0x47>
f0104b86:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104b89:	39 d0                	cmp    %edx,%eax
f0104b8b:	73 2e                	jae    f0104bbb <memmove+0x47>
		s += n;
		d += n;
f0104b8d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104b90:	89 d6                	mov    %edx,%esi
f0104b92:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104b94:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104b9a:	75 13                	jne    f0104baf <memmove+0x3b>
f0104b9c:	f6 c1 03             	test   $0x3,%cl
f0104b9f:	75 0e                	jne    f0104baf <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104ba1:	83 ef 04             	sub    $0x4,%edi
f0104ba4:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104ba7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0104baa:	fd                   	std    
f0104bab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104bad:	eb 09                	jmp    f0104bb8 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104baf:	83 ef 01             	sub    $0x1,%edi
f0104bb2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104bb5:	fd                   	std    
f0104bb6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104bb8:	fc                   	cld    
f0104bb9:	eb 1d                	jmp    f0104bd8 <memmove+0x64>
f0104bbb:	89 f2                	mov    %esi,%edx
f0104bbd:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104bbf:	f6 c2 03             	test   $0x3,%dl
f0104bc2:	75 0f                	jne    f0104bd3 <memmove+0x5f>
f0104bc4:	f6 c1 03             	test   $0x3,%cl
f0104bc7:	75 0a                	jne    f0104bd3 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104bc9:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0104bcc:	89 c7                	mov    %eax,%edi
f0104bce:	fc                   	cld    
f0104bcf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104bd1:	eb 05                	jmp    f0104bd8 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104bd3:	89 c7                	mov    %eax,%edi
f0104bd5:	fc                   	cld    
f0104bd6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104bd8:	5e                   	pop    %esi
f0104bd9:	5f                   	pop    %edi
f0104bda:	5d                   	pop    %ebp
f0104bdb:	c3                   	ret    

f0104bdc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104bdc:	55                   	push   %ebp
f0104bdd:	89 e5                	mov    %esp,%ebp
f0104bdf:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104be2:	8b 45 10             	mov    0x10(%ebp),%eax
f0104be5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104be9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104bec:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104bf0:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bf3:	89 04 24             	mov    %eax,(%esp)
f0104bf6:	e8 79 ff ff ff       	call   f0104b74 <memmove>
}
f0104bfb:	c9                   	leave  
f0104bfc:	c3                   	ret    

f0104bfd <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104bfd:	55                   	push   %ebp
f0104bfe:	89 e5                	mov    %esp,%ebp
f0104c00:	56                   	push   %esi
f0104c01:	53                   	push   %ebx
f0104c02:	8b 55 08             	mov    0x8(%ebp),%edx
f0104c05:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c08:	89 d6                	mov    %edx,%esi
f0104c0a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104c0d:	eb 1a                	jmp    f0104c29 <memcmp+0x2c>
		if (*s1 != *s2)
f0104c0f:	0f b6 02             	movzbl (%edx),%eax
f0104c12:	0f b6 19             	movzbl (%ecx),%ebx
f0104c15:	38 d8                	cmp    %bl,%al
f0104c17:	74 0a                	je     f0104c23 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0104c19:	0f b6 c0             	movzbl %al,%eax
f0104c1c:	0f b6 db             	movzbl %bl,%ebx
f0104c1f:	29 d8                	sub    %ebx,%eax
f0104c21:	eb 0f                	jmp    f0104c32 <memcmp+0x35>
		s1++, s2++;
f0104c23:	83 c2 01             	add    $0x1,%edx
f0104c26:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104c29:	39 f2                	cmp    %esi,%edx
f0104c2b:	75 e2                	jne    f0104c0f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104c2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104c32:	5b                   	pop    %ebx
f0104c33:	5e                   	pop    %esi
f0104c34:	5d                   	pop    %ebp
f0104c35:	c3                   	ret    

f0104c36 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104c36:	55                   	push   %ebp
f0104c37:	89 e5                	mov    %esp,%ebp
f0104c39:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c3c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104c3f:	89 c2                	mov    %eax,%edx
f0104c41:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104c44:	eb 07                	jmp    f0104c4d <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104c46:	38 08                	cmp    %cl,(%eax)
f0104c48:	74 07                	je     f0104c51 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104c4a:	83 c0 01             	add    $0x1,%eax
f0104c4d:	39 d0                	cmp    %edx,%eax
f0104c4f:	72 f5                	jb     f0104c46 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104c51:	5d                   	pop    %ebp
f0104c52:	c3                   	ret    

f0104c53 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104c53:	55                   	push   %ebp
f0104c54:	89 e5                	mov    %esp,%ebp
f0104c56:	57                   	push   %edi
f0104c57:	56                   	push   %esi
f0104c58:	53                   	push   %ebx
f0104c59:	8b 55 08             	mov    0x8(%ebp),%edx
f0104c5c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104c5f:	eb 03                	jmp    f0104c64 <strtol+0x11>
		s++;
f0104c61:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104c64:	0f b6 0a             	movzbl (%edx),%ecx
f0104c67:	80 f9 09             	cmp    $0x9,%cl
f0104c6a:	74 f5                	je     f0104c61 <strtol+0xe>
f0104c6c:	80 f9 20             	cmp    $0x20,%cl
f0104c6f:	74 f0                	je     f0104c61 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104c71:	80 f9 2b             	cmp    $0x2b,%cl
f0104c74:	75 0a                	jne    f0104c80 <strtol+0x2d>
		s++;
f0104c76:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104c79:	bf 00 00 00 00       	mov    $0x0,%edi
f0104c7e:	eb 11                	jmp    f0104c91 <strtol+0x3e>
f0104c80:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104c85:	80 f9 2d             	cmp    $0x2d,%cl
f0104c88:	75 07                	jne    f0104c91 <strtol+0x3e>
		s++, neg = 1;
f0104c8a:	8d 52 01             	lea    0x1(%edx),%edx
f0104c8d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104c91:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104c96:	75 15                	jne    f0104cad <strtol+0x5a>
f0104c98:	80 3a 30             	cmpb   $0x30,(%edx)
f0104c9b:	75 10                	jne    f0104cad <strtol+0x5a>
f0104c9d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104ca1:	75 0a                	jne    f0104cad <strtol+0x5a>
		s += 2, base = 16;
f0104ca3:	83 c2 02             	add    $0x2,%edx
f0104ca6:	b8 10 00 00 00       	mov    $0x10,%eax
f0104cab:	eb 10                	jmp    f0104cbd <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0104cad:	85 c0                	test   %eax,%eax
f0104caf:	75 0c                	jne    f0104cbd <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104cb1:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104cb3:	80 3a 30             	cmpb   $0x30,(%edx)
f0104cb6:	75 05                	jne    f0104cbd <strtol+0x6a>
		s++, base = 8;
f0104cb8:	83 c2 01             	add    $0x1,%edx
f0104cbb:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0104cbd:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104cc2:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104cc5:	0f b6 0a             	movzbl (%edx),%ecx
f0104cc8:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104ccb:	89 f0                	mov    %esi,%eax
f0104ccd:	3c 09                	cmp    $0x9,%al
f0104ccf:	77 08                	ja     f0104cd9 <strtol+0x86>
			dig = *s - '0';
f0104cd1:	0f be c9             	movsbl %cl,%ecx
f0104cd4:	83 e9 30             	sub    $0x30,%ecx
f0104cd7:	eb 20                	jmp    f0104cf9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0104cd9:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104cdc:	89 f0                	mov    %esi,%eax
f0104cde:	3c 19                	cmp    $0x19,%al
f0104ce0:	77 08                	ja     f0104cea <strtol+0x97>
			dig = *s - 'a' + 10;
f0104ce2:	0f be c9             	movsbl %cl,%ecx
f0104ce5:	83 e9 57             	sub    $0x57,%ecx
f0104ce8:	eb 0f                	jmp    f0104cf9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0104cea:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104ced:	89 f0                	mov    %esi,%eax
f0104cef:	3c 19                	cmp    $0x19,%al
f0104cf1:	77 16                	ja     f0104d09 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0104cf3:	0f be c9             	movsbl %cl,%ecx
f0104cf6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104cf9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0104cfc:	7d 0f                	jge    f0104d0d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0104cfe:	83 c2 01             	add    $0x1,%edx
f0104d01:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0104d05:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0104d07:	eb bc                	jmp    f0104cc5 <strtol+0x72>
f0104d09:	89 d8                	mov    %ebx,%eax
f0104d0b:	eb 02                	jmp    f0104d0f <strtol+0xbc>
f0104d0d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0104d0f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104d13:	74 05                	je     f0104d1a <strtol+0xc7>
		*endptr = (char *) s;
f0104d15:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d18:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0104d1a:	f7 d8                	neg    %eax
f0104d1c:	85 ff                	test   %edi,%edi
f0104d1e:	0f 44 c3             	cmove  %ebx,%eax
}
f0104d21:	5b                   	pop    %ebx
f0104d22:	5e                   	pop    %esi
f0104d23:	5f                   	pop    %edi
f0104d24:	5d                   	pop    %ebp
f0104d25:	c3                   	ret    
f0104d26:	66 90                	xchg   %ax,%ax
f0104d28:	66 90                	xchg   %ax,%ax
f0104d2a:	66 90                	xchg   %ax,%ax
f0104d2c:	66 90                	xchg   %ax,%ax
f0104d2e:	66 90                	xchg   %ax,%ax

f0104d30 <__udivdi3>:
f0104d30:	55                   	push   %ebp
f0104d31:	57                   	push   %edi
f0104d32:	56                   	push   %esi
f0104d33:	83 ec 0c             	sub    $0xc,%esp
f0104d36:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104d3a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f0104d3e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0104d42:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104d46:	85 c0                	test   %eax,%eax
f0104d48:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104d4c:	89 ea                	mov    %ebp,%edx
f0104d4e:	89 0c 24             	mov    %ecx,(%esp)
f0104d51:	75 2d                	jne    f0104d80 <__udivdi3+0x50>
f0104d53:	39 e9                	cmp    %ebp,%ecx
f0104d55:	77 61                	ja     f0104db8 <__udivdi3+0x88>
f0104d57:	85 c9                	test   %ecx,%ecx
f0104d59:	89 ce                	mov    %ecx,%esi
f0104d5b:	75 0b                	jne    f0104d68 <__udivdi3+0x38>
f0104d5d:	b8 01 00 00 00       	mov    $0x1,%eax
f0104d62:	31 d2                	xor    %edx,%edx
f0104d64:	f7 f1                	div    %ecx
f0104d66:	89 c6                	mov    %eax,%esi
f0104d68:	31 d2                	xor    %edx,%edx
f0104d6a:	89 e8                	mov    %ebp,%eax
f0104d6c:	f7 f6                	div    %esi
f0104d6e:	89 c5                	mov    %eax,%ebp
f0104d70:	89 f8                	mov    %edi,%eax
f0104d72:	f7 f6                	div    %esi
f0104d74:	89 ea                	mov    %ebp,%edx
f0104d76:	83 c4 0c             	add    $0xc,%esp
f0104d79:	5e                   	pop    %esi
f0104d7a:	5f                   	pop    %edi
f0104d7b:	5d                   	pop    %ebp
f0104d7c:	c3                   	ret    
f0104d7d:	8d 76 00             	lea    0x0(%esi),%esi
f0104d80:	39 e8                	cmp    %ebp,%eax
f0104d82:	77 24                	ja     f0104da8 <__udivdi3+0x78>
f0104d84:	0f bd e8             	bsr    %eax,%ebp
f0104d87:	83 f5 1f             	xor    $0x1f,%ebp
f0104d8a:	75 3c                	jne    f0104dc8 <__udivdi3+0x98>
f0104d8c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0104d90:	39 34 24             	cmp    %esi,(%esp)
f0104d93:	0f 86 9f 00 00 00    	jbe    f0104e38 <__udivdi3+0x108>
f0104d99:	39 d0                	cmp    %edx,%eax
f0104d9b:	0f 82 97 00 00 00    	jb     f0104e38 <__udivdi3+0x108>
f0104da1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104da8:	31 d2                	xor    %edx,%edx
f0104daa:	31 c0                	xor    %eax,%eax
f0104dac:	83 c4 0c             	add    $0xc,%esp
f0104daf:	5e                   	pop    %esi
f0104db0:	5f                   	pop    %edi
f0104db1:	5d                   	pop    %ebp
f0104db2:	c3                   	ret    
f0104db3:	90                   	nop
f0104db4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104db8:	89 f8                	mov    %edi,%eax
f0104dba:	f7 f1                	div    %ecx
f0104dbc:	31 d2                	xor    %edx,%edx
f0104dbe:	83 c4 0c             	add    $0xc,%esp
f0104dc1:	5e                   	pop    %esi
f0104dc2:	5f                   	pop    %edi
f0104dc3:	5d                   	pop    %ebp
f0104dc4:	c3                   	ret    
f0104dc5:	8d 76 00             	lea    0x0(%esi),%esi
f0104dc8:	89 e9                	mov    %ebp,%ecx
f0104dca:	8b 3c 24             	mov    (%esp),%edi
f0104dcd:	d3 e0                	shl    %cl,%eax
f0104dcf:	89 c6                	mov    %eax,%esi
f0104dd1:	b8 20 00 00 00       	mov    $0x20,%eax
f0104dd6:	29 e8                	sub    %ebp,%eax
f0104dd8:	89 c1                	mov    %eax,%ecx
f0104dda:	d3 ef                	shr    %cl,%edi
f0104ddc:	89 e9                	mov    %ebp,%ecx
f0104dde:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0104de2:	8b 3c 24             	mov    (%esp),%edi
f0104de5:	09 74 24 08          	or     %esi,0x8(%esp)
f0104de9:	89 d6                	mov    %edx,%esi
f0104deb:	d3 e7                	shl    %cl,%edi
f0104ded:	89 c1                	mov    %eax,%ecx
f0104def:	89 3c 24             	mov    %edi,(%esp)
f0104df2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104df6:	d3 ee                	shr    %cl,%esi
f0104df8:	89 e9                	mov    %ebp,%ecx
f0104dfa:	d3 e2                	shl    %cl,%edx
f0104dfc:	89 c1                	mov    %eax,%ecx
f0104dfe:	d3 ef                	shr    %cl,%edi
f0104e00:	09 d7                	or     %edx,%edi
f0104e02:	89 f2                	mov    %esi,%edx
f0104e04:	89 f8                	mov    %edi,%eax
f0104e06:	f7 74 24 08          	divl   0x8(%esp)
f0104e0a:	89 d6                	mov    %edx,%esi
f0104e0c:	89 c7                	mov    %eax,%edi
f0104e0e:	f7 24 24             	mull   (%esp)
f0104e11:	39 d6                	cmp    %edx,%esi
f0104e13:	89 14 24             	mov    %edx,(%esp)
f0104e16:	72 30                	jb     f0104e48 <__udivdi3+0x118>
f0104e18:	8b 54 24 04          	mov    0x4(%esp),%edx
f0104e1c:	89 e9                	mov    %ebp,%ecx
f0104e1e:	d3 e2                	shl    %cl,%edx
f0104e20:	39 c2                	cmp    %eax,%edx
f0104e22:	73 05                	jae    f0104e29 <__udivdi3+0xf9>
f0104e24:	3b 34 24             	cmp    (%esp),%esi
f0104e27:	74 1f                	je     f0104e48 <__udivdi3+0x118>
f0104e29:	89 f8                	mov    %edi,%eax
f0104e2b:	31 d2                	xor    %edx,%edx
f0104e2d:	e9 7a ff ff ff       	jmp    f0104dac <__udivdi3+0x7c>
f0104e32:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104e38:	31 d2                	xor    %edx,%edx
f0104e3a:	b8 01 00 00 00       	mov    $0x1,%eax
f0104e3f:	e9 68 ff ff ff       	jmp    f0104dac <__udivdi3+0x7c>
f0104e44:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104e48:	8d 47 ff             	lea    -0x1(%edi),%eax
f0104e4b:	31 d2                	xor    %edx,%edx
f0104e4d:	83 c4 0c             	add    $0xc,%esp
f0104e50:	5e                   	pop    %esi
f0104e51:	5f                   	pop    %edi
f0104e52:	5d                   	pop    %ebp
f0104e53:	c3                   	ret    
f0104e54:	66 90                	xchg   %ax,%ax
f0104e56:	66 90                	xchg   %ax,%ax
f0104e58:	66 90                	xchg   %ax,%ax
f0104e5a:	66 90                	xchg   %ax,%ax
f0104e5c:	66 90                	xchg   %ax,%ax
f0104e5e:	66 90                	xchg   %ax,%ax

f0104e60 <__umoddi3>:
f0104e60:	55                   	push   %ebp
f0104e61:	57                   	push   %edi
f0104e62:	56                   	push   %esi
f0104e63:	83 ec 14             	sub    $0x14,%esp
f0104e66:	8b 44 24 28          	mov    0x28(%esp),%eax
f0104e6a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0104e6e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0104e72:	89 c7                	mov    %eax,%edi
f0104e74:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e78:	8b 44 24 30          	mov    0x30(%esp),%eax
f0104e7c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104e80:	89 34 24             	mov    %esi,(%esp)
f0104e83:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104e87:	85 c0                	test   %eax,%eax
f0104e89:	89 c2                	mov    %eax,%edx
f0104e8b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104e8f:	75 17                	jne    f0104ea8 <__umoddi3+0x48>
f0104e91:	39 fe                	cmp    %edi,%esi
f0104e93:	76 4b                	jbe    f0104ee0 <__umoddi3+0x80>
f0104e95:	89 c8                	mov    %ecx,%eax
f0104e97:	89 fa                	mov    %edi,%edx
f0104e99:	f7 f6                	div    %esi
f0104e9b:	89 d0                	mov    %edx,%eax
f0104e9d:	31 d2                	xor    %edx,%edx
f0104e9f:	83 c4 14             	add    $0x14,%esp
f0104ea2:	5e                   	pop    %esi
f0104ea3:	5f                   	pop    %edi
f0104ea4:	5d                   	pop    %ebp
f0104ea5:	c3                   	ret    
f0104ea6:	66 90                	xchg   %ax,%ax
f0104ea8:	39 f8                	cmp    %edi,%eax
f0104eaa:	77 54                	ja     f0104f00 <__umoddi3+0xa0>
f0104eac:	0f bd e8             	bsr    %eax,%ebp
f0104eaf:	83 f5 1f             	xor    $0x1f,%ebp
f0104eb2:	75 5c                	jne    f0104f10 <__umoddi3+0xb0>
f0104eb4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0104eb8:	39 3c 24             	cmp    %edi,(%esp)
f0104ebb:	0f 87 e7 00 00 00    	ja     f0104fa8 <__umoddi3+0x148>
f0104ec1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104ec5:	29 f1                	sub    %esi,%ecx
f0104ec7:	19 c7                	sbb    %eax,%edi
f0104ec9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104ecd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104ed1:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104ed5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104ed9:	83 c4 14             	add    $0x14,%esp
f0104edc:	5e                   	pop    %esi
f0104edd:	5f                   	pop    %edi
f0104ede:	5d                   	pop    %ebp
f0104edf:	c3                   	ret    
f0104ee0:	85 f6                	test   %esi,%esi
f0104ee2:	89 f5                	mov    %esi,%ebp
f0104ee4:	75 0b                	jne    f0104ef1 <__umoddi3+0x91>
f0104ee6:	b8 01 00 00 00       	mov    $0x1,%eax
f0104eeb:	31 d2                	xor    %edx,%edx
f0104eed:	f7 f6                	div    %esi
f0104eef:	89 c5                	mov    %eax,%ebp
f0104ef1:	8b 44 24 04          	mov    0x4(%esp),%eax
f0104ef5:	31 d2                	xor    %edx,%edx
f0104ef7:	f7 f5                	div    %ebp
f0104ef9:	89 c8                	mov    %ecx,%eax
f0104efb:	f7 f5                	div    %ebp
f0104efd:	eb 9c                	jmp    f0104e9b <__umoddi3+0x3b>
f0104eff:	90                   	nop
f0104f00:	89 c8                	mov    %ecx,%eax
f0104f02:	89 fa                	mov    %edi,%edx
f0104f04:	83 c4 14             	add    $0x14,%esp
f0104f07:	5e                   	pop    %esi
f0104f08:	5f                   	pop    %edi
f0104f09:	5d                   	pop    %ebp
f0104f0a:	c3                   	ret    
f0104f0b:	90                   	nop
f0104f0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104f10:	8b 04 24             	mov    (%esp),%eax
f0104f13:	be 20 00 00 00       	mov    $0x20,%esi
f0104f18:	89 e9                	mov    %ebp,%ecx
f0104f1a:	29 ee                	sub    %ebp,%esi
f0104f1c:	d3 e2                	shl    %cl,%edx
f0104f1e:	89 f1                	mov    %esi,%ecx
f0104f20:	d3 e8                	shr    %cl,%eax
f0104f22:	89 e9                	mov    %ebp,%ecx
f0104f24:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f28:	8b 04 24             	mov    (%esp),%eax
f0104f2b:	09 54 24 04          	or     %edx,0x4(%esp)
f0104f2f:	89 fa                	mov    %edi,%edx
f0104f31:	d3 e0                	shl    %cl,%eax
f0104f33:	89 f1                	mov    %esi,%ecx
f0104f35:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104f39:	8b 44 24 10          	mov    0x10(%esp),%eax
f0104f3d:	d3 ea                	shr    %cl,%edx
f0104f3f:	89 e9                	mov    %ebp,%ecx
f0104f41:	d3 e7                	shl    %cl,%edi
f0104f43:	89 f1                	mov    %esi,%ecx
f0104f45:	d3 e8                	shr    %cl,%eax
f0104f47:	89 e9                	mov    %ebp,%ecx
f0104f49:	09 f8                	or     %edi,%eax
f0104f4b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f0104f4f:	f7 74 24 04          	divl   0x4(%esp)
f0104f53:	d3 e7                	shl    %cl,%edi
f0104f55:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104f59:	89 d7                	mov    %edx,%edi
f0104f5b:	f7 64 24 08          	mull   0x8(%esp)
f0104f5f:	39 d7                	cmp    %edx,%edi
f0104f61:	89 c1                	mov    %eax,%ecx
f0104f63:	89 14 24             	mov    %edx,(%esp)
f0104f66:	72 2c                	jb     f0104f94 <__umoddi3+0x134>
f0104f68:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f0104f6c:	72 22                	jb     f0104f90 <__umoddi3+0x130>
f0104f6e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0104f72:	29 c8                	sub    %ecx,%eax
f0104f74:	19 d7                	sbb    %edx,%edi
f0104f76:	89 e9                	mov    %ebp,%ecx
f0104f78:	89 fa                	mov    %edi,%edx
f0104f7a:	d3 e8                	shr    %cl,%eax
f0104f7c:	89 f1                	mov    %esi,%ecx
f0104f7e:	d3 e2                	shl    %cl,%edx
f0104f80:	89 e9                	mov    %ebp,%ecx
f0104f82:	d3 ef                	shr    %cl,%edi
f0104f84:	09 d0                	or     %edx,%eax
f0104f86:	89 fa                	mov    %edi,%edx
f0104f88:	83 c4 14             	add    $0x14,%esp
f0104f8b:	5e                   	pop    %esi
f0104f8c:	5f                   	pop    %edi
f0104f8d:	5d                   	pop    %ebp
f0104f8e:	c3                   	ret    
f0104f8f:	90                   	nop
f0104f90:	39 d7                	cmp    %edx,%edi
f0104f92:	75 da                	jne    f0104f6e <__umoddi3+0x10e>
f0104f94:	8b 14 24             	mov    (%esp),%edx
f0104f97:	89 c1                	mov    %eax,%ecx
f0104f99:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f0104f9d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0104fa1:	eb cb                	jmp    f0104f6e <__umoddi3+0x10e>
f0104fa3:	90                   	nop
f0104fa4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104fa8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f0104fac:	0f 82 0f ff ff ff    	jb     f0104ec1 <__umoddi3+0x61>
f0104fb2:	e9 1a ff ff ff       	jmp    f0104ed1 <__umoddi3+0x71>
