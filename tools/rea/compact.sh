#!/bin/bash
# compact.sh <file.c>...: print decompiler output without blank lines and without the exception frame lines.
for f in "$@"; do
  echo "=== $(basename "$f" .c)"
  grep -v '^\s*$' "$f" | grep -v 'ExceptionList\|puStack_c = \|local_8 = 0xffffffff;\|^  void \*local_10;\|undefined1 \*puStack_c;\|^  undefined4 local_8;\|^  local_8 = 0;$\|local_8 = (uint)local_8\|local_8._0_1_ = \|local_8 = CONCAT31\|local_10 = \*unaff_FS\|\*unaff_FS_OFFSET = ' 
done
