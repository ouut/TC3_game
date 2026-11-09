;; ====================================================================
;; mock_host.scm - TextCraft 3.0 Rust 宿主本地模拟桩与 REPL 交互场
;; 用途: 允许直接在独立的 Steel REPL 中 (load "mock_host.scm") 进行离线交互测试
;; ====================================================================

(require "mock_engine.scm")
(require "task0_cards.scm")
(require "task1_render.scm")
(require "task2_input.scm")
(require "task3_engine.scm")
(require "mcp_help.scm")
(require "main.scm")

(displayln "\x1b;[32;1m✔ TextCraft Rust 宿主模拟桩已加载，Textlands 游戏核心已启动！\x1b;[0m")
(displayln "\x1b;[36m提示: 可以直接在 REPL 中调用以下函数调试游戏:\x1b;[0m")
(displayln "  (engine:on-init)                        ; 初始化世界")
(displayln "  (engine:on-command 1 '() \"m 0 1\")       ; 模拟玩家指令: 尾尾移动")
(displayln "  (engine:on-command 1 '() \"c 0\")         ; 模拟出售卡牌")
(displayln "  (engine:on-command 1 '() \"eat 1\")       ; 模拟进食")
(displayln "  (engine:on-command 1 '() \"buy tree\")    ; 模拟购买树木")
(displayln "  (engine:on-tick 1.0 1)                  ; 步进模拟时钟 1 秒")
(displayln "  (display (hash-ref (engine:render-snapshot 1) \"screen\")) ; 查看渲染画面\n")

;; 默认初始化并展示第一帧画面
(engine:on-init)
(engine:on-player-join 1 "test_token")
(let ((snap (engine:render-snapshot 1)))
  (if snap
      (display (hash-ref snap "screen"))
      (displayln "(画面未变脏)")))
