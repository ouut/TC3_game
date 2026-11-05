
(require "mcp_help.scm")

;; 全局状态与脏标记（x, y 坐标，用于驱动画面移动）
(define *visual-version* 0)


(require "task0_cards.scm")
(require "task1_render.scm")
(require "task2_input.scm")





;; 【初始化】
(define (engine:on-init)
  (engine:log "[System] Hello World 初始化完成！")
  'ok)

(define (engine:on-tick dt tick-id)
  'ok)

;; 【控制台指令】：接收命令行输入 -> 交互：处理 (ping) 指令并全服广播
(define (engine:on-command pid datum raw)
  (if (string=? (engine:strip-ansi raw) "(ping)")
      (engine:send-message pid "chat" "pong!")
      (engine:broadcast "chat" (string-append "全服广播: " raw)))
  'ok)

;; 【快照渲染】：必须返回包含 cols, rows, screen(ANSI字符串), hud(字典) 的哈希
(define (engine:render-snapshot pid)
  (let* ()
    (hash
      "cols" 80
      "rows" 24
      "screen" (render-all-lines *lines*)
      "hud" (hash "hp" 100 "max_hp" 100 "gold" 888 "name" (string-append "Player_" (to-string pid))))))






 

 

