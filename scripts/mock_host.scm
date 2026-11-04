;; ====================================================================
;; mock_host.scm - TextCraft 3.0 Rust 宿主原生函数本地模拟桩 (Stub)
;; 用途: 允许直接在独立的 Steel REPL 中 (load "scripts/main.scm") 进行离线交互测试
;; ====================================================================

(define (engine:log text)
  (displayln (string-append "\x1b;[36m[HOST LOG]\x1b;[0m " (to-string text))))

(define (engine:send-message pid channel text)
  (displayln (string-append "\x1b;[33m[MSG to PID:" (to-string pid) " @" (to-string channel) "]\x1b;[0m " (to-string text))))

(define (engine:broadcast channel text)
  (displayln (string-append "\x1b;[35m[BROADCAST @" (to-string channel) "]\x1b;[0m " (to-string text))))

(define (engine:random-int lo hi)
  lo)

(define (engine:strip-ansi text)
  text)

(displayln "\x1b;[32m✔ TextCraft Rust 宿主模拟桩已加载，可直接 load 业务脚本。\x1b;[0m")

(load "main.scm")
