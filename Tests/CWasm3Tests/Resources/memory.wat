(module
  (import "native" "write" (func $write (param i32 i32)))
  (memory 1) ;; at least 64 KB
  (func (export "write_utf8")
    i32.const 0 ;; offset of 0
    i32.const 13 ;; length of 13
    (call $write)))

