# This reproduces a bug with jump table identification where jump table has
# entries pointing to code in function and its cold fragment. The fragment is
# only reachable through jump table.
# This test verifies support for both stripped and non-stripped binaries.

# REQUIRES: system-linux


# RUN: llvm-mc -filetype=obj -triple x86_64-unknown-unknown %s -o %t.o
# RUN: %clang %cflags %t.o -o %t.exe -Wl,-q
# RUN: llvm-strip --strip-unneeded %t.exe
# RUN: llvm-bolt %t.exe -o %t.out --lite=0 -v=1 -print-cfg 2>&1 | FileCheck %s -check-prefix=CHECK-NOSTRIP

# CHECK-NOSTRIP-NOT: unclaimed PC-relative relocations left in data
# CHECK-NOSTRIP: BOLT-INFO: marking main.cold.1 as a fragment of main
# CHECK-NOSTRIP: Ignoring main
# CHECK-NOSTRIP: Ignoring main.cold.1
# CHECK-NOSTRIP: Binary Function "main" after building cfg
# CHECK-NOSTRIP: PIC Jump table JUMP_TABLE for function main at {{.*}} with a total count of 0
# CHECK-NOSTRIP-NEXT: 0x0000 : {{.+}}
# CHECK-NOSTRIP-NEXT: 0x0004 : [[LBB3:.+]]
# CHECK-NOSTRIP-NEXT: 0x0008 : {{.*}}main.cold.1{{.*}}
# CHECK-NOSTRIP-NEXT: 0x000c : [[LBB3]]
# CHECK-NOSTRIP: Binary Function "main.cold.1" after building cfg


# RUN: cp %t.exe %t.tmp.exe
# RUN: llvm-strip -s %t.tmp.exe
# RUN: llvm-bolt %t.tmp.exe -o %t.out --lite=0 -v=1 -print-cfg 2>&1 | FileCheck %s -check-prefix=CHECK-STRIP

# CHECK-STRIP-NOT: unclaimed PC-relative relocations left in data
# CHECK-STRIP: BOLT-INFO: marking [[MAIN_COLD:.+]] as a fragment of [[MAIN:.+]]
# CHECK-STRIP: Ignoring [[MAIN]]
# CHECK-STRIP: Ignoring [[MAIN_COLD]]
# CHECK-STRIP: Binary Function "[[MAIN]]" after building cfg
# CHECK-STRIP: PIC Jump table JUMP_TABLE/[[MAIN]]{{.*}} for function [[MAIN]] at {{.*}} with a total count of 0
# CHECK-STRIP-NEXT: 0x0000 : {{.+}}
# CHECK-STRIP-NEXT: 0x0004 : [[LBB3:.+]]
# CHECK-STRIP-NEXT: 0x0008 : {{.*}}[[MAIN_COLD]]{{.*}}
# CHECK-STRIP-NEXT: 0x000c : [[LBB3]]
# CHECK-STRIP: Binary Function "[[MAIN_COLD]]" after building cfg

  .text
  .globl main
  .type main, %function
  .p2align 2
main:
LBB0:
  .cfi_startproc
  andl $0xf, %ecx
  cmpb $0x4, %cl
  # exit through ret
  ja LBB3

# jump table dispatch, jumping to label indexed by val in %ecx
LBB1:
  leaq JUMP_TABLE(%rip), %r8
  movzbl %cl, %ecx
  movslq (%r8,%rcx,4), %rax
  addq %rax, %r8
  jmpq *%r8

LBB2:
  xorq %rax, %rax
LBB3:
  addq $0x8, %rsp
  ret
  .cfi_endproc
.size main, .-main

# cold fragment is only reachable through jump table
  .globl main.cold.1
  .type main.cold.1, %function
  .p2align 2
main.cold.1:
  .cfi_startproc
  # load bearing nop: pad LBB4 so that it can't be treated
  # as __builtin_unreachable by analyzeJumpTable
  nop
LBB4:
  callq abort
.cfi_endproc
.size main.cold.1, .-main.cold.1

  .rodata
# jmp table, entries must be R_X86_64_PC32 relocs
  .globl JUMP_TABLE
JUMP_TABLE:
  .long LBB2-JUMP_TABLE
  .long LBB3-JUMP_TABLE
  .long LBB4-JUMP_TABLE
  .long LBB3-JUMP_TABLE
