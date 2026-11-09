;; ====================================================================
;; main.scm - Textlands: 实体化 Lisp 机器卡牌流 (TextCraft 3.0 游戏主核心)
;; 遵循规范: DOC-GAME-SPEC-001 & DOC-AGENT-DEVELOPER-GUIDE
;; ====================================================================

(require "mock_engine.scm")
(require "mcp_help.scm")
(require "task0_cards.scm")
(require "task1_render.scm")
(require "task2_input.scm")
(require "task3_engine.scm")

;; --------------------------------------------------------------------
;; 全局世界状态 (Pure Data Only, 零 Lambda 闭包)
;; --------------------------------------------------------------------
(define *visual-version* 0)

(define (bump-visual-version!)
  (set! *visual-version* (+ *visual-version* 1)))

(define (make-initial-world-state)
  (hash
    "board" (create-initial-board)
    "players" (hash)
    "tick_count" 0
    "elapsed_sec" 0.0
    "hunger_timer" 0.0
    "logs" (list (hash "channel" "system" "text" "欢迎进入 Textlands: 实体化 Lisp 机器卡牌流！" "tick" 0))))

(define *world-state* (make-initial-world-state))

(define (get-world-state)
  *world-state*)

(define (get-board)
  (map-get *world-state* "board" (hash)))

;; --------------------------------------------------------------------
;; 玩家状态辅助函数
;; --------------------------------------------------------------------
(define (get-player pid)
  (let ((players (map-get *world-state* "players" (hash))))
    (map-get players (to-string pid) #f)))

(define (ensure-player pid)
  (let* ((pid-str (to-string pid))
         (players (map-get *world-state* "players" (hash))))
    (if (hash-contains? players pid-str)
        (hash-ref players pid-str)
        (let ((new-p (hash
                       "id" pid
                       "name" (string-append "玩家_" pid-str)
                       "online" #t
                       "dirty" #t
                       "last_rendered_ver" -1
                       "pressed_keys" (hash)
                       "logs" '())))
          (set! *world-state* (hash-insert *world-state* "players" (hash-insert players pid-str new-p)))
          new-p))))

(define (update-player pid f)
  (let* ((p (ensure-player pid))
         (new-p (f p))
         (players (map-get *world-state* "players" (hash))))
    (set! *world-state* (hash-insert *world-state* "players" (hash-insert players (to-string pid) new-p)))
    new-p))

(define (player:mark-dirty! pid)
  (update-player pid (lambda (p) (hash-insert p "dirty" #t))))

(define (mark-all-players-dirty!)
  (let* ((players (map-get *world-state* "players" (hash)))
         (keys (hash-keys->list players)))
    (for-each (lambda (k)
                (let* ((p (hash-ref players k))
                       (np (hash-insert p "dirty" #t)))
                  (set! players (hash-insert players k np))))
              keys)
    (set! *world-state* (hash-insert *world-state* "players" players))))

(define (add-global-log text)
  (let* ((cur-logs (map-get *world-state* "logs" '()))
         (tick (map-get *world-state* "tick_count" 0))
         (entry (hash "channel" "system" "text" text "tick" tick))
         (new-logs (cons entry (take cur-logs (min 25 (length cur-logs))))))
    (set! *world-state* (hash-insert *world-state* "logs" new-logs))))

;; --------------------------------------------------------------------
;; MCP 自治开发工具注册
;; --------------------------------------------------------------------
(define (register-mcp-tools!)
  ;; 1. 查询桌面状态摘要
  (mcp:def-tool
    "get_board_summary"
    "获取当前桌面尺寸、资源(金币/饱腹度/生命)以及各行卡牌列表"
    (hash "type" "object")
    (lambda (args)
      (let* ((board (map-get *world-state* "board" (hash)))
             (lines (map-get board "lines" '()))
             (lines-summary
               (map (lambda (row)
                      (map (lambda (c)
                             (hash "name" (card-name c)
                                   "icon" (card-icon c)
                                   "kind" (card-kind c)
                                   "type" (card-type c)
                                   "locked" (card-locked? c)
                                   "progress" (card-progress c)))
                           row))
                    lines)))
        (hash "width" (map-get board "width" 8)
              "height" (map-get board "height" 4)
              "gold" (map-get board "gold" 0)
              "food" (map-get board "food" 100)
              "hp" (map-get board "hp" 100)
              "lines" lines-summary))))

  ;; 2. 移动卡牌
  (mcp:def-tool
    "move_card"
    "在桌面行之间移动卡牌 (mode: m=尾尾, mh=尾首, mhh=首首, mht=首尾, ma=整行搬移)"
    (hash "type" "object"
          "properties" (hash "src" (hash "type" "integer" "description" "源行索引 (0-3)")
                             "dst" (hash "type" "integer" "description" "目标行索引 (0-3)")
                             "mode" (hash "type" "string" "description" "移动模式: m, mh, mhh, mht, ma, mah"))
          "required" (list "src" "dst"))
    (lambda (args)
      (let* ((src (map-get args "src" 0))
             (dst (map-get args "dst" 1))
             (mode (map-get args "mode" "m"))
             (board (map-get *world-state* "board" (hash)))
             (lines (map-get board "lines" '()))
             (width (map-get board "width" 8))
             (res (move-card lines src dst mode width)))
        (if (hash-ref res "ok")
            (let ((new-board (hash-insert board "lines" (hash-ref res "lines"))))
              (set! *world-state* (hash-insert *world-state* "board" new-board))
              (bump-visual-version!)
              (mark-all-players-dirty!)
              (hash "ok" #t "msg" (string-append "成功移动: " (to-string src) " -> " (to-string dst))))
            (hash "ok" #f "error" (hash-ref res "error"))))))

  ;; 3. 出售卡牌
  (mcp:def-tool
    "sell_card"
    "出售指定行尾部的卡牌以换取金币"
    (hash "type" "object"
          "properties" (hash "row" (hash "type" "integer" "description" "行索引 (0-3)"))
          "required" (list "row"))
    (lambda (args)
      (let* ((row (map-get args "row" 0))
             (board (map-get *world-state* "board" (hash)))
             (res (sell-card board row)))
        (if (hash-ref res "ok")
            (begin
              (set! *world-state* (hash-insert *world-state* "board" (hash-ref res "board")))
              (bump-visual-version!)
              (mark-all-players-dirty!)
              (hash "ok" #t "msg" (hash-ref res "msg")))
            (hash "ok" #f "error" (hash-ref res "error"))))))

  ;; 4. 进食
  (mcp:def-tool
    "eat_food"
    "让村民消耗指定行内的首张食物卡，恢复饱腹度与生命值"
    (hash "type" "object"
          "properties" (hash "row" (hash "type" "integer" "description" "行索引 (0-3)"))
          "required" (list "row"))
    (lambda (args)
      (let* ((row (map-get args "row" 0))
             (board (map-get *world-state* "board" (hash)))
             (res (eat-food board row)))
        (if (hash-ref res "ok")
            (begin
              (set! *world-state* (hash-insert *world-state* "board" (hash-ref res "board")))
              (bump-visual-version!)
              (mark-all-players-dirty!)
              (hash "ok" #t "msg" (hash-ref res "msg")))
            (hash "ok" #f "error" (hash-ref res "error"))))))

  ;; 5. 购买卡牌
  (mcp:def-tool
    "buy_card"
    "使用金币购买基础资源或函数卡 (tree, stone, berry, cut, mine, cook, craft, spell)"
    (hash "type" "object"
          "properties" (hash "item" (hash "type" "string" "description" "卡牌标识名"))
          "required" (list "item"))
    (lambda (args)
      (let* ((item (map-get args "item" "tree"))
             (board (map-get *world-state* "board" (hash)))
             (res (buy-card board item)))
        (if (hash-ref res "ok")
            (begin
              (set! *world-state* (hash-insert *world-state* "board" (hash-ref res "board")))
              (bump-visual-version!)
              (mark-all-players-dirty!)
              (hash "ok" #t "msg" (hash-ref res "msg")))
            (hash "ok" #f "error" (hash-ref res "error"))))))

  ;; 6. 重置桌面
  (mcp:def-tool
    "reset_game"
    "重置桌面所有卡牌和资源至初始状态"
    (hash "type" "object")
    (lambda (args)
      (set! *world-state* (make-initial-world-state))
      (bump-visual-version!)
      (mark-all-players-dirty!)
      (hash "ok" #t "msg" "游戏已成功重置为初始状态！"))))

;; --------------------------------------------------------------------
;; TextCraft 3.0 标准生命周期钩子实现
;; --------------------------------------------------------------------

;; 【初始化】
(define (engine:on-init)
  (set! *world-state* (make-initial-world-state))
  (bump-visual-version!)
  (register-mcp-tools!)
  (engine:log "[Textlands] 实体化 Lisp 机器卡牌流初始化完成！")
  'ok)

;; 【节拍帧率查询】
(define (engine:target-fps)
  30)

;; 【视口尺寸】
(define (engine:viewport-size pid)
  '(80 24))

;; 【HUD 默认配置】
(define (engine:hud-config)
  (hash "title" "Textlands: Lisp Machine Card Flow"
        "theme" "cyberpunk"))

;; 【玩家首次加入】
(define (engine:on-player-join pid token)
  (ensure-player pid)
  (player:mark-dirty! pid)
  (bump-visual-version!)
  (engine:send-message pid "system" "欢迎来到 Textlands！输入 help 查看指令，输入 recipes 查看合成配方！")
  (engine:log (string-append "[Player] 玩家加入: PID " (to-string pid)))
  'ok)

;; 【玩家断线】
(define (engine:on-player-disconnect pid)
  (update-player pid (lambda (p) (hash-insert p "online" #f)))
  (engine:log (string-append "[Player] 玩家掉线 (进入宽限期): PID " (to-string pid)))
  'ok)

;; 【玩家重连】
(define (engine:on-player-reconnect pid)
  (update-player pid (lambda (p) (hash-insert (hash-insert p "online" #t) "dirty" #t)))
  (bump-visual-version!)
  (engine:log (string-append "[Player] 玩家重连: PID " (to-string pid)))
  'ok)

;; 【玩家离线超时注销】
(define (engine:on-player-leave pid)
  (let ((players (map-get *world-state* "players" (hash))))
    (set! *world-state* (hash-insert *world-state* "players" (hash-remove players (to-string pid)))))
  (engine:log (string-append "[Player] 玩家注销离开: PID " (to-string pid)))
  'ok)

;; 【物理时钟推进】
(define (engine:on-tick dt tick-id)
  (let* ((board (map-get *world-state* "board" (hash)))
         (step-res (step-board board dt))
         (new-board (hash-ref step-res "board"))
         (events (hash-ref step-res "events"))
         (changed? (hash-ref step-res "changed"))
         (cur-hunger (map-get *world-state* "hunger_timer" 0.0))
         (new-hunger (+ cur-hunger dt))
         (food-decay? (>= new-hunger 4.0))) ;; 每 4 秒消耗 1 点饱腹度
    ;; 广播规约事件
    (for-each (lambda (ev)
                (engine:broadcast "system" ev)
                (add-global-log ev))
              events)
    ;; 处理饱腹度自然衰减与饥饿扣血
    (let* ((hunger-board
            (if food-decay?
                (let* ((cur-food (map-get new-board "food" 100))
                       (cur-hp (map-get new-board "hp" 100)))
                  (if (> cur-food 0)
                      (hash-insert new-board "food" (max 0.0 (- cur-food 1.0)))
                      ;; 饱腹度为 0 时开始消耗生命值
                      (let ((new-hp (max 0 (- cur-hp 5))))
                        (if (and (= cur-hp 100) (< new-hp 100))
                            (engine:broadcast "system" "[警告] 村民正在挨饿！请尽快输入 eat <行号> 喂食！")
                            #f)
                        (hash-insert new-board "hp" new-hp))))
                new-board))
           (hunger-timer-reset (if food-decay? 0.0 new-hunger)))
      (set! *world-state*
            (hash-insert
              (hash-insert
                (hash-insert *world-state* "board" hunger-board)
                "hunger_timer" hunger-timer-reset)
              "tick_count" tick-id))
      (if (or changed? food-decay? (not (empty? events)))
          (begin
            (bump-visual-version!)
            (mark-all-players-dirty!))
          #f))
    'ok))

;; 【键盘与鼠标输入】
(define (engine:on-input pid input)
  (let* ((type (map-get input "type" ""))
         (code (map-get input "code" "")))
    (cond
      ;; 快捷按键 1-4 快速查看对应行
      ((and (string=? type "key") (starts-with? code "Digit"))
       (let ((digit (string->number (substring code 5 (string-length code)))))
         (if (and digit (>= digit 1) (<= digit 4))
             (engine:send-message pid "system" (string-append "选中行 [" (number->string (- digit 1)) "]"))
             #f)))
      (else #f))
    'ok))

;; 【HUD 前端点击交互】
(define (engine:on-ui-action pid action)
  (let* ((act (map-get action "action" ""))
         (board (map-get *world-state* "board" (hash))))
    (cond
      ((string=? act "sell_tail")
       (let* ((row (map-get action "row" 0))
              (res (sell-card board row)))
         (if (hash-ref res "ok")
             (begin
               (set! *world-state* (hash-insert *world-state* "board" (hash-ref res "board")))
               (bump-visual-version!)
               (mark-all-players-dirty!)
               (engine:send-message pid "system" (hash-ref res "msg")))
             (engine:send-message pid "system" (hash-ref res "error")))))
      ((string=? act "eat_food")
       (let* ((row (map-get action "row" 0))
              (res (eat-food board row)))
         (if (hash-ref res "ok")
             (begin
               (set! *world-state* (hash-insert *world-state* "board" (hash-ref res "board")))
               (bump-visual-version!)
               (mark-all-players-dirty!)
               (engine:send-message pid "system" (hash-ref res "msg")))
             (engine:send-message pid "system" (hash-ref res "error")))))
      (else
       (engine:send-message pid "system" (string-append "收到前端操作: " act))))
    'ok))

;; 【控制台指令系统 (无括号精炼指令与标准 Lisp S 表达式双兼容)】
(define (engine:on-command pid datum raw)
  (let* ((clean-raw (engine:strip-ansi raw))
         (parsed (parse-command clean-raw))
         (board (map-get *world-state* "board" (hash)))
         (width (map-get board "width" 8))
         (lines (map-get board "lines" '())))
    (if (or (not parsed) (empty? parsed))
        (engine:send-message pid "system" "请输入有效指令，输入 help 查看说明。")
        (let ((cmd (first parsed))
              (args (rest parsed)))
          (cond
            ;; ----------------------------------------------------
            ;; 1. 移动指令群 (m, mh, mhh, mht, ma, mah, tt, th, hh, ht, at, ah)
            ;; ----------------------------------------------------
            ((or (string=? cmd "m") (string=? cmd "tt")
                 (string=? cmd "mh") (string=? cmd "th")
                 (string=? cmd "mhh") (string=? cmd "hh")
                 (string=? cmd "mht") (string=? cmd "ht")
                 (string=? cmd "ma") (string=? cmd "at")
                 (string=? cmd "mah") (string=? cmd "ah"))
             (if (< (length args) 2)
                 (engine:send-message pid "system" (string-append "指令格式错误！用法: " cmd " <源行> <目标行> (例如: " cmd " 0 1)"))
                 (let* ((src (first args))
                        (dst (second args))
                        (src-num (if (number? src) src (string->number (to-string src))))
                        (dst-num (if (number? dst) dst (string->number (to-string dst)))))
                   (if (or (not src-num) (not dst-num))
                       (engine:send-message pid "system" "行号必须为整数 (0 到 3)！")
                       (let ((res (move-card lines src-num dst-num cmd width)))
                         (if (hash-ref res "ok")
                             (let ((new-board (hash-insert board "lines" (hash-ref res "lines"))))
                               (set! *world-state* (hash-insert *world-state* "board" new-board))
                               (bump-visual-version!)
                               (mark-all-players-dirty!)
                               (engine:send-message pid "system" (string-append "✔ 移动成功: [" (number->string src-num) "] -> [" (number->string dst-num) "]")))
                             (engine:send-message pid "system" (string-append "❌ " (hash-ref res "error")))))))))

            ;; ----------------------------------------------------
            ;; 2. 出售/清理指令 (c <row>)
            ;; ----------------------------------------------------
            ((string=? cmd "c")
             (if (empty? args)
                 (engine:send-message pid "system" "指令格式错误！用法: c <行号> (例如: c 0)")
                 (let* ((row (first args))
                        (row-num (if (number? row) row (string->number (to-string row)))))
                   (if (not row-num)
                       (engine:send-message pid "system" "行号必须为整数 (0 到 3)！")
                       (let ((res (sell-card board row-num)))
                         (if (hash-ref res "ok")
                             (begin
                               (set! *world-state* (hash-insert *world-state* "board" (hash-ref res "board")))
                               (bump-visual-version!)
                               (mark-all-players-dirty!)
                               (engine:send-message pid "system" (string-append "✔ " (hash-ref res "msg"))))
                             (engine:send-message pid "system" (string-append "❌ " (hash-ref res "error")))))))))

            ;; ----------------------------------------------------
            ;; 3. 进食指令 (eat <row>)
            ;; ----------------------------------------------------
            ((string=? cmd "eat")
             (if (empty? args)
                 (engine:send-message pid "system" "指令格式错误！用法: eat <行号> (例如: eat 1)")
                 (let* ((row (first args))
                        (row-num (if (number? row) row (string->number (to-string row)))))
                   (if (not row-num)
                       (engine:send-message pid "system" "行号必须为整数 (0 到 3)！")
                       (let ((res (eat-food board row-num)))
                         (if (hash-ref res "ok")
                             (begin
                               (set! *world-state* (hash-insert *world-state* "board" (hash-ref res "board")))
                               (bump-visual-version!)
                               (mark-all-players-dirty!)
                               (engine:send-message pid "system" (string-append "✔ " (hash-ref res "msg"))))
                             (engine:send-message pid "system" (string-append "❌ " (hash-ref res "error")))))))))

            ;; ----------------------------------------------------
            ;; 4. 购买指令 (buy <item>)
            ;; ----------------------------------------------------
            ((or (string=? cmd "buy") (string=? cmd "b"))
             (if (empty? args)
                 (engine:send-message pid "system" "用法: buy <物品名> (可选: tree, stone, berry, cut, mine, cook, craft, spell)")
                 (let* ((item (to-string (first args)))
                        (res (buy-card board item)))
                   (if (hash-ref res "ok")
                       (begin
                         (set! *world-state* (hash-insert *world-state* "board" (hash-ref res "board")))
                         (bump-visual-version!)
                         (mark-all-players-dirty!)
                         (engine:send-message pid "system" (string-append "✔ " (hash-ref res "msg"))))
                       (engine:send-message pid "system" (string-append "❌ " (hash-ref res "error")))))))

            ;; ----------------------------------------------------
            ;; 5. 配方手册 (recipes)
            ;; ----------------------------------------------------
            ((or (string=? cmd "recipes") (string=? cmd "recipe"))
             (let ((r-list (map-get board "recipes" '())))
               (engine:send-message pid "system" "=== Textlands 合成配方手册 ===")
               (for-each (lambda (r)
                           (engine:send-message pid "system" (string-append " • " (map-get r "name" "") ": " (map-get r "desc" ""))))
                         r-list)))

            ;; ----------------------------------------------------
            ;; 6. 帮助指令 (help)
            ;; ----------------------------------------------------
            ((or (string=? cmd "help") (string=? cmd "?"))
             (engine:send-message pid "system" "=== Textlands 操作指令指南 ===")
             (engine:send-message pid "system" "1. m <源> <目>   : 取出源行尾部卡牌，推入目标行尾部 (默认)")
             (engine:send-message pid "system" "2. mh <源> <目>  : 取出源行尾部卡牌，推入目标行头部 (喂料)")
             (engine:send-message pid "system" "3. mhh <源> <目> : 取出源行头部卡牌，推入目标行头部")
             (engine:send-message pid "system" "4. mht <源> <目> : 取出源行头部卡牌，推入目标行尾部")
             (engine:send-message pid "system" "5. ma <源> <目>  : 整行一键转移到目标行尾部 (流水线整理)")
             (engine:send-message pid "system" "6. c <行号>      : 清理并出售行尾卡牌，获得金币")
             (engine:send-message pid "system" "7. eat <行号>    : 让村民进食行内首份食物，恢复饱腹与生命")
             (engine:send-message pid "system" "8. buy <商品>    : 购买卡牌 (tree, stone, berry, cut, mine, cook...)")
             (engine:send-message pid "system" "9. recipes       : 查看所有函数卡合成公式")
             (engine:send-message pid "system" "10. reset        : 重置桌面回到初始状态"))

            ;; ----------------------------------------------------
            ;; 7. 重置指令 (reset)
            ;; ----------------------------------------------------
            ((string=? cmd "reset")
             (set! *world-state* (make-initial-world-state))
             (bump-visual-version!)
             (mark-all-players-dirty!)
             (engine:send-message pid "system" "✔ 游戏桌面已恢复为初始状态！"))

            ;; ----------------------------------------------------
            ;; 8. 调试 ping
            ;; ----------------------------------------------------
            ((string=? cmd "ping")
             (engine:send-message pid "chat" "pong!"))

            (else
             (engine:broadcast "chat" (string-append "全服广播: " clean-raw)))))))
  'ok)

;; 【快照渲染与 Scheme 权威脏检测 (HTTP 304 机制)】
(define (engine:render-snapshot pid)
  (let ((p (ensure-player pid)))
    (if (and (not (map-get p "dirty" #t))
             (= (map-get p "last_rendered_ver" -1) *visual-version*))
        ;; 视口未发生任何变更，返回 #f，由宿主零计算跳过本帧推流
        #f
        ;; 变脏，执行光栅化并刷新玩家标记
        (let* ((board (map-get *world-state* "board" (hash)))
               (screen-str (render-screen board *world-state*))
               (hud (hash
                      "gold" (map-get board "gold" 0)
                      "food" (inexact->exact (round (map-get board "food" 100)))
                      "hp" (map-get board "hp" 100)
                      "max_hp" (map-get board "max_hp" 100)
                      "width" (map-get board "width" 8)
                      "height" (map-get board "height" 4)
                      "name" (map-get p "name" (string-append "玩家_" (to-string pid)))
                      "recipes" (map-get board "recipes" '())
                      "logs" (take (map-get *world-state* "logs" '())
                                   (min 15 (length (map-get *world-state* "logs" '())))))))
          ;; 清除脏标记并更新渲染版本号
          (update-player pid (lambda (item)
                               (hash-insert
                                 (hash-insert item "dirty" #f)
                                 "last_rendered_ver" *visual-version*)))
          (hash
            "cols" 80
            "rows" 24
            "screen" screen-str
            "hud" hud)))))

;; 【状态持久化导出】
(define (engine:export-state)
  *world-state*)

;; 【状态恢复导入】
(define (engine:import-state data)
  (if (hash? data)
      (begin
        (set! *world-state* data)
        (bump-visual-version!)
        (mark-all-players-dirty!)
        (engine:log "[Textlands] 成功导入恢复存档世界状态！")
        'ok)
      'err))

(provide
  *visual-version*
  *world-state*
  get-world-state
  get-board
  bump-visual-version!
  get-player
  ensure-player
  update-player
  player:mark-dirty!
  mark-all-players-dirty!
  engine:on-init
  engine:target-fps
  engine:viewport-size
  engine:hud-config
  engine:on-player-join
  engine:on-player-disconnect
  engine:on-player-reconnect
  engine:on-player-leave
  engine:on-tick
  engine:on-input
  engine:on-ui-action
  engine:on-command
  engine:render-snapshot
  engine:export-state
  engine:import-state)

