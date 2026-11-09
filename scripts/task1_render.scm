;; ====================================================================
;; task1_render.scm - Textlands ANSI 光栅化与终端渲染引擎
;; 遵循规范: DOC-GAME-SPEC-001 (Section 4: ANSI Rendering Contract)
;; ====================================================================

(require "task0_cards.scm")

;; 根据类型和分类分配 ANSI 配色
(define (card-color card)
  (let ((kind (map-get card "kind" "item"))
        (type (map-get card "type" "")))
    (cond
      ((string=? kind "func") "\x1b;[36;1m")  ;; 青色高亮: 函数/算子
      ((string=? type "gold") "\x1b;[33;1m")  ;; 金黄色: 黄金财富
      ((string=? type "food") "\x1b;[32;1m")  ;; 嫩绿色: 食物
      ((string=? type "tree") "\x1b;[32m")    ;; 绿色: 自然树木
      ((string=? type "wood") "\x1b;[33m")    ;; 棕黄: 木材
      ((string=? type "stone") "\x1b;[90m")   ;; 灰色: 矿石
      ((string=? type "unit") "\x1b;[37;1m")  ;; 亮白: 村民/单位
      ((string=? type "spell") "\x1b;[35;1m") ;; 洋红: 咒语
      (else "\x1b;[0m"))))

;; 渲染单张卡牌
(define (render-card card)
  (let* ((kind (map-get card "kind" "item"))
         (name (map-get card "name" ""))
         (icon (map-get card "icon" ""))
         (color (card-color card))
         (reset "\x1b;[0m")
         (locked? (card-meta-get card "locked" #f))
         (prog (card-meta-get card "progress" 0.0))
         (dur (card-meta-get card "duration" 1.0)))
    (cond
      ;; 处于反应进度中的函数卡: [ 🪓 砍伐 60% ]
      ((and (string=? kind "func") locked? (> prog 0.0))
       (let* ((pct (inexact->exact (round (* 100 (/ prog dur)))))
              (pct-str (number->string (min 100 pct))))
         (string-append color "[ " icon " " name " " pct-str "% ]" reset)))
      ;; 空闲函数卡
      ((string=? kind "func")
       (string-append color "[ " icon " " name " ]" reset))
      ;; 被锁定规约中的参数卡: [ 🌲 树木* ]
      (locked?
       (string-append color "[ " icon " " name "* ]" reset))
      ;; 普通数据卡
      (else
       (string-append color "[ " icon " " name " ]" reset)))))

;; 提取当前行中处于进行中的规约进度信息
(define (find-line-progress cards)
  (let loop ((cs cards))
    (if (empty? cs)
        #f
        (let ((c (first cs)))
          (if (and (string=? (map-get c "kind" "") "func")
                   (card-meta-get c "locked" #f)
                   (> (card-meta-get c "progress" 0.0) 0.0))
              (list (card-meta-get c "progress" 0.0)
                    (card-meta-get c "duration" 1.0))
              (loop (rest cs)))))))

;; 格式化右侧进度条 (如: | 进度: 1.8s / 3.0s [======    ])
(define (format-prog-bar cur dur)
  (let* ((ratio (min 1.0 (/ cur dur)))
         (total-bars 8)
         (filled (inexact->exact (round (* total-bars ratio))))
         (empty-bars (- total-bars filled))
         (cur-int (inexact->exact (round (* cur 10))))
         (dur-int (inexact->exact (round (* dur 10))))
         (cur-str (string-append (number->string (quotient cur-int 10)) "." (number->string (modulo cur-int 10))))
         (dur-str (string-append (number->string (quotient dur-int 10)) "." (number->string (modulo dur-int 10)))))
    (string-append " \x1b;[90m| 进度: " cur-str "s/" dur-str "s ["
                   (make-string filled #\=)
                   (make-string empty-bars #\space)
                   "]\x1b;[0m")))

;; 渲染单行
(define (render-line row-idx cards)
  (let* ((idx-str (if (< row-idx 10) (string-append "0" (number->string row-idx)) (number->string row-idx)))
         (prefix (string-append "\x1b;[90m[" idx-str "]\x1b;[0m "))
         (body (if (empty? cards)
                   "\x1b;[90m(空)\x1b;[0m"
                   (apply string-append
                          (map (lambda (c) (string-append (render-card c) " ")) cards))))
         (prog-info (find-line-progress cards))
         (suffix (if prog-info
                     (format-prog-bar (first prog-info) (second prog-info))
                     "")))
    (string-append prefix body suffix "\n")))

;; 渲染所有行 (向上兼容)
(define (render-all-lines lines)
  (let ((indices (range 0 (length lines))))
    (apply string-append
           (map (lambda (idx cards) (render-line idx cards))
                indices
                lines))))

;; 完整终端主屏光栅化渲染
(define (render-screen board status-map)
  (let* ((lines (map-get board "lines" '()))
         (width (map-get board "width" 8))
         (height (map-get board "height" 4))
         (gold (map-get board "gold" 0))
         (food (map-get board "food" 100))
         (hp (map-get board "hp" 100))
         (max-hp (map-get board "max_hp" 100))
         ;; 头部标题栏
         (header (string-append "\x1b;[36;1m=== Textlands: 实体化 Lisp 机器卡牌流 ("
                                (number->string height) "x" (number->string width) ") ===\x1b;[0m\n\n"))
         ;; 桌面各行卡牌
         (board-ansi (render-all-lines lines))
         ;; 分隔线
         (sep "\x1b;[90m--------------------------------------------------------------------------------\x1b;[0m\n")
         ;; 底部资源与状态
         (status (string-append "\x1b;[37m[状态] 资源: \x1b;[33;1m🪙 x" (number->string gold)
                                "\x1b;[0m | 饱腹度: \x1b;[32m🍎 " (number->string (inexact->exact (round food))) "%"
                                "\x1b;[0m | 生命: \x1b;[31m❤️ " (number->string hp) "/" (number->string max-hp) "\x1b;[0m\n"))
         ;; 操作提示栏
         (hint "\x1b;[90m[提示] 移动: m <源> <目> (尾尾) | mh (尾首) | mhh (首首) | c <行> (卖出) | eat <行> (进食) | help\x1b;[0m\n")
         (prompt "\x1b;[32m> : \x1b;[0m"))
    (string-append header board-ansi sep status hint prompt)))

(provide
  card-color
  render-card
  render-line
  render-all-lines
  render-screen)
