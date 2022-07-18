# This reproduces a bug with jump table identification where jump table has
# entries pointing to code in function and its cold fragment.

# REQUIRES: system-linux

# RUN: %clang++ %p/Inputs/gcd.cpp -o %t -Wl,-q
# RUN: llvm-bolt %t -o %t.out 2>&1 | FileCheck %s -check-prefix=CHECK-NOSTRIP
# RUN: cp %t %t.stripped
# RUN: llvm-strip -s %t.stripped
# RUN: llvm-bolt %t.stripped -o %t.out 2>&1 | FileCheck %s -check-prefix=CHECK-STRIP

# CHECK-NOSTRIP-NOT: BOLT-INFO: target binary is stripped!
# CHECK-STRIP: BOLT-INFO: target binary is stripped!
