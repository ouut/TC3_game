;; 1. 全局状态与脏标记（x, y 坐标，用于驱动画面移动）
(define *visual-version* 0)
(define *pos* (hash "x" 10 "y" 5 "tick" 0))

;; 【初始化】
(define (engine:on-init)
  (engine:log "[System] Hello World 初始化完成！")
  'ok)

;; 【每帧心跳】：接收 (dt 帧间隔, tick-id 帧序号)
(define (engine:on-tick dt tick-id)
  (set! *pos* (hash-insert *pos* "tick" tick-id))
  'ok)

;; 【玩家连接】：接收 (pid 玩家ID, token 鉴权字串) -> 交互：向客户端发送一条消息
(define (engine:on-player-join pid token)
  (engine:send-message pid "sys" (string-append "欢迎 PID: " (to-string pid) "，按 WASD 移动！"))
  'ok)

;; 【离线 / 重连 / 退出】
(define (engine:on-player-disconnect pid) (engine:log (string-append "玩家掉线: " (to-string pid))))
(define (engine:on-player-reconnect pid)  (engine:log (string-append "玩家重连: " (to-string pid))))
(define (engine:on-player-leave pid)      (engine:log (string-append "玩家退出: " (to-string pid))))

;; 【按键/鼠标输入】：接收 (pid, input 哈希) -> 交互：解析 KeyW/KeyA/KeyS/KeyD 并修改坐标
(define (engine:on-input pid input)
  (let* ((code (if (hash-contains? input "code") (hash-ref input "code") ""))
         (x (hash-ref *pos* "x"))
         (y (hash-ref *pos* "y"))
         (new-x (cond ((string=? code "KeyA") (- x 1)) ((string=? code "KeyD") (+ x 1)) (else x)))
         (new-y (cond ((string=? code "KeyW") (- y 1)) ((string=? code "KeyS") (+ y 1)) (else y))))
    (set! *pos* (hash-insert (hash-insert *pos* "x" new-x) "y" new-y))
    (set! *visual-version* (+ *visual-version* 1)) ;; 标记画面有更新
    'ok))

;; 【HUD 交互】：接收前端发送的动作（如点击背包、按钮）
(define (engine:on-ui-action pid action)
  (engine:send-message pid "ui" (string-append "收到前端操作: " (hash-ref action "action")))
  'ok)

;; 【控制台指令】：接收命令行输入 -> 交互：处理 (ping) 指令并全服广播
(define (engine:on-command pid datum raw)
  (if (string=? (engine:strip-ansi raw) "(ping)")
      (engine:send-message pid "chat" "pong!")
      (engine:broadcast "chat" (string-append "全服广播: " raw)))
  'ok)

;; 【快照渲染】：必须返回包含 cols, rows, screen(ANSI字符串), hud(字典) 的哈希
(define (engine:render-snapshot pid)
  (let* ((x (hash-ref *pos* "x"))
         (y (hash-ref *pos* "y"))
         (info (string-append "当前坐标: (" (to-string x) ", " (to-string y) ")\n\n"))
         (char-layer "   [ @ ] <- 你在这里 (按 WASD 移动角色)\n   [ : ] <- 按冒号发指令 (如 (ping))\n"))
    (hash
      "cols" 80
      "rows" 24
      "screen" (string-append "\x1b;[38;2;80;200;255m=== TextCraft 极简交互示例 ===\x1b;[0m\n" info char-layer)
      "hud" (hash "hp" 100 "max_hp" 100 "gold" 888 "name" (string-append "Player_" (to-string pid))))))