## check-elffile-kernel.sh 说明    

### check-elffile-kernel.sh脚本程序说明：  
#### 主要实现的安全检测： 
主要进行安全更新包的检查、elf可执行程序的Pax安全特性是否开启、内核是否开启了SYN洪水攻击防护、列出不属于任何用户或组的孤儿文件、列出无用的用户名、列出密码过期的用户、列出设置了suid或sgid的文件；  

#### 使用方法  
此脚本程序所在目录中必须存在checksec脚本，此脚本程序使用方法为： 
chmod +x check-elffile-kernel.sh 
sudo ./check-elffile-kernel.sh 

有关此脚本中使用checksec脚本所使用的方法及修复详情请参看systemcheck目录中的checksec-howto.md文档；

**注意 **   
check-elffile-kernel.sh脚本需要使用root权限进行执行，此脚本只检测，不会对被检测文件或内容进行修改；  
checksec脚本必须与check-elffile-kernel.sh位于同一个目录；  

### checksec的简要说明及对应的编译选项 

### checksec  
是一个检测Pax安全特性是否开启的bash脚本程序。 
最新的版本在github上的地址为：  
https://github.com/slimm609/checksec.sh  
使用git clone或download ZIP均可以获取到到脚本程序。  

对checksec进行可执行权限的设置:  
\# chmod +x checksec  

查看checksec的版本信息：  
\# ./checksec --version  
checksec v1.7.4, Brian Davis, github.com/slimm609/checksec.sh, Dec 2015  
Based off checksec v1.5, Tobias Klein, www.trapkit.de, November 2011  
  
checksec脚本程序能够检查ELF可执行程序是否设置了PAX的安全特性，主要支持的安全特性如下：  

1）、RELRO：RELocation Read-Only，全局偏移表变成只读；  
GCC 选项：  
-z relro, -z relro -z now  

2）、Stack Canary：在压栈过程中加入一个值,在出栈时进行对比,如果被修改说明有漏洞利用的行为。  
GCC 选项 :   
-fstack-protector, 编译时给部分的函数加入canary  
-fstack-protector-all ,编译时给所有的函数加入 canary  

3）、NoeXecute (NX)：  
此功能编译器默认是开启的；

4）、Position Independent Code (PIE)：强制所有进程的代码段的基地址随机化；  
GCC 选项 :  
-pie -fpie, 代码段随机化  
条件: ASLR 支持，check /proc/sys/kernel/randomize_va_space是否为2；  

5）、Address Space Layout Randomization (ASLR)：地址空间布局随机化；  
6）、Fortify Source：防止字符串格式化漏洞利用；  
GCC 选项：  
-FORTIFY_SOURCE  

\# ./checksec 
Usage: checksec [--output {cli|csv|xml|json}] [OPTION]

Options:

  --file (-f) <executable-file>
  --dir (-d) <directory> [-v]
  --proc (-p) <process name>
  --proc-all (-pa)
  --proc-libs (-pl) <process ID>
  --kernel (-k) [kconfig]
  --fortify-file (-ff)<executable-file>
  --fortify-proc (-fp) <process ID>
  --version
  --help
  --update

For more information, see:
  http://github.com/slimm609/checksec.sh

各个option参数的意义：
--file (-f) <executable-file>用于检查哪些安全特性在可执行文件中进行了开启；
--dir (-d) <directory>用于检查指定目录directory下的可执行程序开启了哪些安全特性；

--proc (-p) <process name>：检查指定的进程开启了哪些安全特性；
  --proc-all (-pa)：检查当前运行的进程开启了哪些安全特性；
  --proc-libs (-pl) <process ID>：检查进程库开启了哪些安全特性；
  --kernel (-k) [kconfig]：检查内核保护是否开启；
  --fortify-file (-ff)<executable-file>: 检测二进制文件是否编译使用了FORTIFY_SOURCE特性的支持；
  --fortify-proc (-fp) <process ID>：检测进程是否编译时使用了 FORTIFY_SOURCE特性的支持；
  --version：显示版本号；
  --help：显示帮助信息；
  --update

示例：
日常中主要是对可执行文件进行检测是否开启了安全特性，现就此类检测及如何避免此类情况进行举例：
/*
* simple.c
*
* Linux:
*
gcc -c simple.c
*
*/
int printf( const char* format, ... );
int global_init_var = 84;
int global_uninit_var;

void func1( int i )
{
  printf( "%d\n", i);
}

int main(void)
{
  static int static_var = 85;
  static int static_var2;
  int a = 1;
  int b;
  func1( static_var + static_var2 + a + b );
  return a;
}

使用默认的编译方法：
gcc -o simple simple.c
使用checksec进行检查，
./checksec -f simple
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH	FORTIFY	Fortified Fortifiable  FILE
Partial RELRO   No canary found   NX enabled    No PIE          No RPATH   No RUNPATH   No	0			 2		        simple

可以看出，RELRO只是部分进行了开启，而stack canary特性并没有开启，PIE、FORTIRY也没有开启，那么如何将这些功能特性开启呢？在编译时使用上面介绍的功能特性的编译选项即可，如下：

gcc -o simple -fstack-protector-all -FORTIFY_SOURCE -pie -fpie -z relro -z now  simple.c

再次使用checksec进行检查，结果如下：
$ ./checksec -f simple
RELRO           STACK CANARY      NX            PIE             RPATH      RUNPATH	FORTIFY	Fortified Fortifiable  FILE
Full RELRO      Canary found      NX enabled    PIE enabled     No RPATH   No RUNPATH   Yes	0			  2	        simple

可以看出，使用安全特性参数进行编译后，再次检查的结果即可看到安全特性均已开启；



