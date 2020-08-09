(module
  (import "native" "write_length" (func $write_length (result i32)))
  (import "native" "write" (func $write (param i32 i32)))
  (memory 1) ;; at least 64 KB
  (func (export "write_utf8")
    (local $length i32)
    (call $write_length)
    local.set $length
    i32.const 0 ;; offset of 0
    local.get $length
    (call $write)))

