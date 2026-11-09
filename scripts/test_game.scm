;; ====================================================================
;; test_game.scm - Textlands 自动化端到端测试套件
;; ====================================================================

(require "mock_engine.scm")
(require "task0_cards.scm")
(require "task1_render.scm")
(require "task2_input.scm")
(require "task3_engine.scm")
(require "mcp_help.scm")
(require "main.scm")

(define *tests-passed* 0)
(define *tests-failed* 0)

(define (test-assert name cond)
  (if cond
      (begin
        (set! *tests-passed* (+ *tests-passed* 1))
        (displayln (string-append "  \x1b;[32m✔ PASS:\x1b;[0m " name)))
      (begin
        (set! *tests-failed* (+ *tests-failed* 1))
        (displayln (string-append "  \x1b;[31m✘ FAIL:\x1b;[0m " name)))))

(displayln "\n\x1b;[36;1m==================================================")
(displayln "   Textlands 端到端自动化功能测试套件")
(displayln "==================================================\x1b;[0m\n")

;; --------------------------------------------------------------------
;; 1. 测试初始化与快照
;; --------------------------------------------------------------------
(displayln "【测试组 1: 初始化与快照生成】")
(engine:on-init)
(engine:on-player-join 1 "admin")

(define snap1 (engine:render-snapshot 1))
(test-assert "初始快照生成成功" (hash? snap1))
(test-assert "初始快照屏幕包含标题" (string-contains? (hash-ref snap1 "screen") "Textlands"))
(test-assert "未修改状态下再次渲染触发 Scheme 权威 HTTP 304 (返回 #f)" (not (engine:render-snapshot 1)))

;; --------------------------------------------------------------------
;; 2. 测试指令输入与移动卡牌
;; --------------------------------------------------------------------
(displayln "\n【测试组 2: 指令系统与卡牌移动】")

;; 移动第 2 行尾部的金币到第 3 行尾部: m 2 3
(engine:on-command 1 '() "m 2 3")
(define snap2 (engine:render-snapshot 1))
(test-assert "移动卡牌后标记变脏，成功重新生成快照" (hash? snap2))
(define board2 (get-board))
(define l2 (list-ref (map-get board2 "lines" '()) 2))
(define l3 (list-ref (map-get board2 "lines" '()) 3))
(test-assert "源行卡牌数量减少 1" (= (length l2) 1))
(test-assert "目标行卡牌数量增加 1" (= (length l3) 1))

;; 测试紧凑指令格式 t3h2 (从第 3 行尾移动到第 2 行首)
(engine:on-command 1 '() "t3h2")
(define board2_compact (get-board))
(define l2_new (list-ref (map-get board2_compact "lines" '()) 2))
(test-assert "紧凑指令 t3h2 成功将卡牌移至目标行首" (= (length l2_new) 2))

;; --------------------------------------------------------------------
;; 3. 测试规约倒计时与就地规约产出 (Applicative Order Reduction)
;; --------------------------------------------------------------------
(displayln "\n【测试组 3: Lisp 机器求值与就地规约】")

;; 行 0 初始: [ 村民 ] [ 砍伐 (duration: 3.0s) ] [ 树木 ]
;; 步进 1.0 秒
(engine:on-tick 1.0 1)
(define snap3 (engine:render-snapshot 1))
(test-assert "规约进行中视口发生变更" (hash? snap3))
(test-assert "屏幕正确渲染进度百分比" (string-contains? (hash-ref snap3 "screen") "砍伐 33%"))
(test-assert "屏幕正确渲染参数锁定标记 *" (string-contains? (hash-ref snap3 "screen") "树木*"))

;; 再步进 1.0 秒 (累计 2.0 秒)
(engine:on-tick 1.0 2)
(define snap4 (engine:render-snapshot 1))
(test-assert "屏幕进度更新为 67%" (string-contains? (hash-ref snap4 "screen") "砍伐 67%"))

;; 再步进 1.0 秒 (累计 3.0 秒 -> 触发规约完成!)
(engine:on-tick 1.0 3)
(define snap5 (engine:render-snapshot 1))
(define board5 (get-board))
(define l0 (list-ref (map-get board5 "lines" '()) 0))
(define names (map (lambda (c) (card-name c)) l0))
(test-assert "规约成功消耗树木并就地产出原木" (and (member "原木" names) (not (member "树木" names))))
(test-assert "常驻函数卡砍伐保留在行内" (member "砍伐" names))

;; --------------------------------------------------------------------
;; 4. 测试生活辅助指令: 出售、进食与购买
;; --------------------------------------------------------------------
(displayln "\n【测试组 4: 经济与生存指令】")

;; 出售行 0 尾部的原木 (c 0)
(define old-gold (map-get board5 "gold" 0))
(engine:on-command 1 '() "c 0")
(define board_sold (get-board))
(test-assert "出售卡牌后金币增加" (> (map-get board_sold "gold" 0) old-gold))

;; 进食行 1 的浆果 (eat 1)
(engine:on-command 1 '() "eat 1")
(define board_eaten (get-board))
(define l1_after_eat (list-ref (map-get board_eaten "lines" '()) 1))
(define names_l1 (map (lambda (c) (card-name c)) l1_after_eat))
(test-assert "浆果被成功消耗" (not (member "浆果" names_l1)))

;; 购买新树木 (buy tree)
(define gold-before-buy (map-get board_eaten "gold" 0))
(engine:on-command 1 '() "buy tree")
(define board_bought (get-board))
(test-assert "购买扣减金币" (< (map-get board_bought "gold" 0) gold-before-buy))

;; --------------------------------------------------------------------
;; 5. 测试 MCP 工具接口测试
;; --------------------------------------------------------------------
(displayln "\n【测试组 5: MCP 工具接口测试】")
(define mcp-summary (engine:on-mcp-call "get_board_summary" (hash)))
(test-assert "MCP get_board_summary 正常返回" (hash-contains? mcp-summary "lines"))
(test-assert "MCP get_board_summary 包含资源" (and (hash-contains? mcp-summary "gold")
                                                  (hash-contains? mcp-summary "food")))

(define mcp-move (engine:on-mcp-call "move_card" (hash "src" 0 "dst" 3 "mode" "m")))
(test-assert "MCP move_card 执行成功" (hash-ref mcp-move "ok"))

;; --------------------------------------------------------------------
;; 6. 测试状态导出与恢复 (Persistence)
;; --------------------------------------------------------------------
(displayln "\n【测试组 6: 世界状态导出与热重载导入】")
(define exported (engine:export-state))
(test-assert "export-state 导出纯数据哈希" (hash? exported))
(test-assert "导出的状态包含 board 与 players" (and (hash-contains? exported "board")
                                                 (hash-contains? exported "players")))

(engine:on-init) ;; 重置
(engine:import-state exported) ;; 恢复
(define restored-board (get-board))
(test-assert "import-state 正确还原金币数值" (= (map-get restored-board "gold" -1) (map-get (hash-ref exported "board") "gold" -2)))

;; --------------------------------------------------------------------
;; 汇总报告
;; --------------------------------------------------------------------
(displayln "\n==================================================")
(displayln (string-append "测试结果: \x1b;[32m" (number->string *tests-passed*) " 通过\x1b;[0m / "
                          (if (> *tests-failed* 0)
                              (string-append "\x1b;[31m" (number->string *tests-failed*) " 失败\x1b;[0m")
                              "\x1b;[32m0 失败\x1b;[0m")))
(displayln "==================================================\n")
