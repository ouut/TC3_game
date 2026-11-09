;; mock_engine.scm
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

(provide engine:log engine:send-message engine:broadcast engine:random-int engine:strip-ansi)
