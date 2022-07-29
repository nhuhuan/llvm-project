# Test -jump-tables=move with stripped/non-stripped binary with split function
# accessing the jump table, reproduces the unresolved symbol issue due to losing
# symbols referenced from a jump table.

# REQUIRES: system-linux

# RUN: llvm-mc -filetype=obj -triple x86_64-unknown-unknown %s -o %t.o
# RUN: %clang %cflags -no-pie %t.o -o %t.exe -Wl,-q
# RUN: llvm-bolt %t.exe -o %t.out --lite=0 -v=1 --jump-tables=move -print-cfg 2>&1 | FileCheck %s -check-prefix=CHECK-NOSTRIP


# CHECK-NOSTRIP-NOT: unclaimed PC-relative relocations left in data
# CHECK-NOSTRIP: BOLT-INFO: marking main.cold.1 as a fragment of main
# CHECK-NOSTRIP: Ignoring main.cold.1
# CHECK-NOSTRIP: Ignoring main
# CHECK-NOSTRIP: Binary Function "main.cold.1" after building cfg
# CHECK-NOSTRIP: PIC Jump table JUMP_TABLE for function main.cold.1 at {{.*}} with a total count of 0
# CHECK-NOSTRIP-NEXT: 0x0000 : [[ENTRY:.+]]
# CHECK-NOSTRIP-NEXT: 0x0004 : [[ENTRY]]


# RUN: cp %t.exe %t.tmp.exe
# RUN: llvm-strip -s %t.tmp.exe
# RUN: llvm-bolt %t.tmp.exe -o %t.out --lite=0 -v=1 --jump-tables=move -print-cfg 2>&1 | FileCheck %s -check-prefix=CHECK-STRIP

# CHECK-STRIP-NOT: unclaimed PC-relative relocations left in data
# CHECK-STRIP: BOLT-INFO: marking [[MAIN:.+]] as a fragment of [[MAIN_COLD:.+]]
# CHECK-STRIP: Ignoring [[MAIN_COLD]]
# CHECK-STRIP: Ignoring [[MAIN]]
# CHECK-STRIP: Binary Function "[[MAIN_COLD]]" after building cfg
# CHECK-STRIP: PIC Jump table JUMP_TABLE/[[MAIN_COLD]]{{.*}} for function [[MAIN_COLD]] at {{.*}} with a total count of 0
# CHECK-STRIP-NEXT: 0x0000 : [[ENTRY:.+]]
# CHECK-STRIP-NEXT: 0x0004 : [[ENTRY]]

  .text
  .globl main
  .type main, %function
  .p2align 2
main:
    .cfi_startproc
    cmpl  $0x67, %edi
    jne main.cold.1
LBB0:
    retq
    .cfi_endproc

  .globl main.cold.1
  .type main.cold.1, %function
  .p2align 2
main.cold.1:
    .cfi_startproc
    leaq  JUMP_TABLE(%rip), %rax
    movslq  (%rax,%rdx,4), %rcx
    addq  %rax, %rcx
    jmpq  *%rcx
    .cfi_endproc

  .rodata
  .globl JUMP_TABLE
JUMP_TABLE:
  .long LBB0-JUMP_TABLE
  .long LBB0-JUMP_TABLE
