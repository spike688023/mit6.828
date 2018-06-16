用這個人的docker 就可以了
https://hub.docker.com/r/grantbot/xv6/

sudo apt-get install gcc-4.8-multilib

Structure and Interpretation of Computer Programs

https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-001-structure-and-interpretation-of-computer-programs-spring-2005/index.htm


Operating System Engineering
https://ocw.mit.edu/courses/electrical-engineering-and-computer-science/6-828-operating-system-engineering-fall-2012/


物件導件的東西， 我想，除了看MIT 那二份影片外，

我也可以從 geeksforgeeks的網頁去補，我想學的部份。

具体来说，这门课一共有7个lab，写完这7个lab，一个操作系统就被写出来了

在讲课阶段会主要以xv6（一个教学的操作系统，它是Monolithic kernel）的代码讲解OS概念

介绍一下每个Lab的需要做的事情：

Lab1是熟悉的过程，需要学习QEMU模拟器的使用、开机启动流程、调试工具、bootloader、以及整个加载kernel的流程。做完这个lab会具备基本的内核调试能力，以及掌握开机到通电，bootloader是如何加载kernel的。

Lab2要完成JOS的的内存管理模块，需要学习一些计算机基础知识，如虚拟地址系统是如何工作的，地址空间是如何切分的，物理页面是如何管理的。做完这个lab将会给JOS添加最基本的内存管理功能，即Kernel其余模块需要物理页，这个模块可以分配出来。


0.xv6源码不要用MIT官网的那份，我的主机是Linux/Ubuntu 14.0各种编译error，我都改的想吐．后来直接用github上别人改好的，直接能跑起来没有编译错误的xv6.

照這裡面的 schedule 跑，一步步的看，應該就可以了
https://pdos.csail.mit.edu/6.828/2014/index.html


這目録的材料都是從，以下這個修完課的學生的git ，下載來的：
https://github.com/fatsheepzzq/6.828mit.git

Reference:

http://www.cnblogs.com/fatsheep9146/p/5060292.html

http://lifeofzjs.com/blog/2016/02/24/recommmend-6-dot-828/
