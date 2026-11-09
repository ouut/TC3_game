;; ====================================================================
;; task2_input.scm - Textlands 指令输入解析与交互引擎
;; 遵循规范: DOC-GAME-SPEC-001 (Section 2: Orthogonal Command Grammar)
;; ====================================================================

(require "task0_cards.scm")

;; 截取除最后一个元素外的列表
(define (list-without-last lst)
  (take lst (- (length lst) 1)))

;; --------------------------------------------------------------------
;; 移动操作核心实现
;; --------------------------------------------------------------------
(define (move-card lines src-idx dst-idx mode width)
  (let ((height (length lines)))
    (cond
      ((or (< src-idx 0) (>= src-idx height))
       (hash "ok" #f "error" (string-append "无效源行: " (to-string src-idx))))
      ((or (< dst-idx 0) (>= dst-idx height))
       (hash "ok" #f "error" (string-append "无效目标行: " (to-string dst-idx))))
      ((= src-idx dst-idx)
       (hash "ok" #f "error" "源行与目标行不能相同"))
      (else
       (let ((src-row (list-ref lines src-idx))
             (dst-row (list-ref lines dst-idx)))
         (cond
           ((empty? src-row)
            (hash "ok" #f "error" (string-append "第 " (to-string src-idx) " 行为空，无法移动")))
           ((and (or (string=? mode "ma") (string=? mode "at") (string=? mode "mah") (string=? mode "ah"))
                 (> (+ (length src-row) (length dst-row)) width))
            (hash "ok" #f "error" (string-append "目标行空间不足，最大容量: " (to-string width))))
           ((and (not (or (string=? mode "ma") (string=? mode "at") (string=? mode "mah") (string=? mode "ah")))
                 (>= (length dst-row) width))
            (hash "ok" #f "error" (string-append "目标行已满 (最大容量: " (to-string width) ")")))
           (else
            (let ((res
                   (cond
                     ;; 整行搬移至尾部 (ma / at)
                     ((or (string=? mode "ma") (string=? mode "at"))
                      (list '() (append dst-row (map card-unlock src-row))))
                     ;; 整行搬移至头部 (mah / ah)
                     ((or (string=? mode "mah") (string=? mode "ah"))
                      (list '() (append (map card-unlock src-row) dst-row)))
                     ;; 尾 -> 尾 (m / tt)
                     ((or (string=? mode "m") (string=? mode "tt"))
                      (let ((card (card-unlock (last src-row))))
                        (list (list-without-last src-row) (append dst-row (list card)))))
                     ;; 尾 -> 头 (mh / th)
                     ((or (string=? mode "mh") (string=? mode "th"))
                      (let ((card (card-unlock (last src-row))))
                        (list (list-without-last src-row) (cons card dst-row))))
                     ;; 头 -> 头 (mhh / hh)
                     ((or (string=? mode "mhh") (string=? mode "hh"))
                      (let ((card (card-unlock (first src-row))))
                        (list (rest src-row) (cons card dst-row))))
                     ;; 头 -> 尾 (mht / ht)
                     ((or (string=? mode "mht") (string=? mode "ht"))
                      (let ((card (card-unlock (first src-row))))
                        (list (rest src-row) (append dst-row (list card)))))
                     (else #f))))
              (if (not res)
                  (hash "ok" #f "error" (string-append "未知移动模式: " mode))
                  (let* ((new-src (first res))
                         (new-dst (second res))
                         (l1 (update-list-nth lines src-idx (lambda (_) new-src)))
                         (l2 (update-list-nth l1 dst-idx (lambda (_) new-dst))))
                    (hash "ok" #t "lines" l2)))))))))))

;; --------------------------------------------------------------------
;; 辅助生活指令实现
;; --------------------------------------------------------------------

;; c <row>: 清理/出售 row 行尾部的卡牌
(define (sell-card board row-idx)
  (let* ((lines (map-get board "lines" '()))
         (height (length lines)))
    (if (or (< row-idx 0) (>= row-idx height))
        (hash "ok" #f "error" (string-append "无效行号: " (to-string row-idx)))
        (let ((row (list-ref lines row-idx)))
          (if (empty? row)
              (hash "ok" #f "error" (string-append "第 " (to-string row-idx) " 行为空，没有可出售的卡牌"))
              (let* ((card (last row))
                     (val (card-meta-get card "value" 5))
                     (new-row (list-without-last row))
                     (new-lines (update-list-nth lines row-idx (lambda (_) new-row)))
                     (new-gold (+ (map-get board "gold" 0) val))
                     (updated-board (hash-insert (hash-insert board "lines" new-lines) "gold" new-gold)))
                (hash "ok" #t
                      "board" updated-board
                      "msg" (string-append "已出售 " (card-icon card) " " (card-name card) "，获得 🪙 x" (number->string val)))))))))

;; eat <row>: 进食 row 行内的首张食物卡
(define (eat-food board row-idx)
  (let* ((lines (map-get board "lines" '()))
         (height (length lines)))
    (if (or (< row-idx 0) (>= row-idx height))
        (hash "ok" #f "error" (string-append "无效行号: " (to-string row-idx)))
        (let ((row (list-ref lines row-idx)))
          (let loop ((pre '()) (rem row))
            (cond
              ((empty? rem)
               (hash "ok" #f "error" (string-append "第 " (to-string row-idx) " 行没有找到食物卡牌！")))
              ((or (string=? (card-type (first rem)) "food")
                   (> (card-meta-get (first rem) "nutrition" 0) 0))
               (let* ((food-card (first rem))
                      (nutrition (card-meta-get food-card "nutrition" 25))
                      (cur-food (map-get board "food" 100))
                      (cur-hp (map-get board "hp" 100))
                      (max-hp (map-get board "max_hp" 100))
                      (new-food (min 100.0 (+ cur-food nutrition)))
                      (new-hp (min max-hp (+ cur-hp 10)))
                      (new-row (append pre (rest rem)))
                      (new-lines (update-list-nth lines row-idx (lambda (_) new-row)))
                      (updated-board (hash-insert
                                       (hash-insert
                                         (hash-insert board "lines" new-lines)
                                         "food" new-food)
                                       "hp" new-hp)))
                 (hash "ok" #t
                       "board" updated-board
                       "msg" (string-append "村民享用了 " (card-icon food-card) " " (card-name food-card)
                                            "，饱腹度 +" (number->string nutrition) "%，生命 +10！"))))
              (else
               (loop (append pre (list (first rem))) (rest rem)))))))))

;; buy <item-type>: 使用金币购买基础卡牌 (放入第一个有空位的行)
(define (buy-card board item-name)
  (let* ((catalog (hash
                    "tree"  (hash "name" "树木" "icon" "🌲" "type" "tree" "cost" 5 "meta" (hash "value" 2))
                    "stone" (hash "name" "石头" "icon" "🪨" "type" "stone" "cost" 5 "meta" (hash "value" 2))
                    "berry" (hash "name" "浆果" "icon" "🫐" "type" "food" "cost" 6 "meta" (hash "nutrition" 20 "value" 3))
                    "food"  (hash "name" "浆果" "icon" "🫐" "type" "food" "cost" 6 "meta" (hash "nutrition" 20 "value" 3))
                    "cut"   (hash "name" "砍伐" "icon" "🪓" "type" "tool" "cost" 15 "func" #t "inputs" '("tree") "output" proto-wood "duration" 3.0 "consume_self" #f)
                    "mine"  (hash "name" "采矿" "icon" "⛏️" "type" "tool" "cost" 15 "func" #t "inputs" '("stone") "output" proto-gold "duration" 3.0 "consume_self" #f)
                    "cook"  (hash "name" "烹饪" "icon" "🔥" "type" "building" "cost" 20 "func" #t "inputs" '("food") "output" proto-pie "duration" 2.5 "consume_self" #f)
                    "craft" (hash "name" "制作" "icon" "🔨" "type" "tool" "cost" 25 "func" #t "inputs" '("wood") "output" proto-plank "duration" 4.0 "consume_self" #f)
                    "spell" (hash "name" "炼金" "icon" "✨" "type" "spell" "cost" 30 "func" #t "inputs" '("wood" "stone") "output" proto-gold "duration" 3.0 "consume_self" #t)))
         (item-key (cond
                     ((string=? item-name "树木") "tree")
                     ((string=? item-name "石头") "stone")
                     ((string=? item-name "浆果") "berry")
                     ((string=? item-name "砍伐") "cut")
                     ((string=? item-name "采矿") "mine")
                     ((string=? item-name "烹饪") "cook")
                     ((string=? item-name "制作") "craft")
                     ((string=? item-name "炼金") "spell")
                     (else item-name))))
    (if (not (hash-contains? catalog item-key))
        (hash "ok" #f "error" (string-append "未知的商品: " item-name "。可选: tree, stone, berry, cut, mine, cook, craft, spell"))
        (let* ((item-info (hash-ref catalog item-key))
               (cost (map-get item-info "cost" 10))
               (cur-gold (map-get board "gold" 0)))
          (if (< cur-gold cost)
              (hash "ok" #f "error" (string-append "金币不足！需要 🪙 x" (number->string cost) "，当前只有 🪙 x" (number->string cur-gold)))
              (let* ((lines (map-get board "lines" '()))
                     (width (map-get board "width" 8))
                     ;; 寻找首个未满行
                     (target-row-idx
                       (let loop ((idx 0) (ls lines))
                         (cond
                           ((empty? ls) #f)
                           ((< (length (first ls)) width) idx)
                           (else (loop (+ idx 1) (rest ls)))))))
                (if (not target-row-idx)
                    (hash "ok" #f "error" "所有行均已满，请先清理或移动卡牌腾出空位！")
                    (let* ((new-card
                            (if (map-get item-info "func" #f)
                                (make-func-card
                                  (map-get item-info "name" "")
                                  (map-get item-info "icon" "")
                                  (map-get item-info "type" "")
                                  (map-get item-info "inputs" '())
                                  (map-get item-info "output" (hash))
                                  (map-get item-info "duration" 3.0)
                                  (map-get item-info "consume_self" #f)
                                  (hash))
                                (make-item-card
                                  (map-get item-info "name" "")
                                  (map-get item-info "icon" "")
                                  (map-get item-info "type" "")
                                  (map-get item-info "meta" (hash)))))
                           (row (list-ref lines target-row-idx))
                           (new-row (append row (list new-card)))
                           (new-lines (update-list-nth lines target-row-idx (lambda (_) new-row)))
                           (updated-board (hash-insert
                                            (hash-insert board "lines" new-lines)
                                            "gold" (- cur-gold cost))))
                      (hash "ok" #t
                            "board" updated-board
                            "msg" (string-append "成功购买 " (card-icon new-card) " " (card-name new-card)
                                                 " (放入第 " (number->string target-row-idx) " 行，花费 🪙 x" (number->string cost) ")"))))))))))

;; --------------------------------------------------------------------
;; 指令解析器 (支持无括号输入如 "m 0 1"、带括号 "(m 0 1)" 以及紧凑写法 "t0t1")
;; --------------------------------------------------------------------
(define (clean-input-str raw)
  (let ((s (trim raw)))
    (if (and (starts-with? s "(") (ends-with? s ")"))
        (trim (substring s 1 (- (string-length s) 1)))
        s)))

;; 解析紧凑写法如 "t0t1" -> ("tt" 0 1)
(define (parse-compact-cmd s)
  (if (= (string-length s) 4)
      (let ((c0 (substring s 0 1))
            (c1 (substring s 1 2))
            (c2 (substring s 2 3))
            (c3 (substring s 3 4)))
        (let ((n1 (string->number c1))
              (n2 (string->number c3)))
          (if (and (or (string=? c0 "t") (string=? c0 "h") (string=? c0 "a"))
                   (or (string=? c2 "t") (string=? c2 "h"))
                   n1 n2)
              (list (string-append c0 c2) n1 n2)
              #f)))
      #f))

(define (parse-cmd-tokens tokens)
  (if (empty? tokens)
      #f
      (let ((op (first tokens))
            (rest-toks (rest tokens)))
        (cond
          ;; 紧凑形式: "t0t1"
          ((= (length tokens) 1)
           (let ((compact (parse-compact-cmd (first tokens))))
             (if compact
                 compact
                 (list op))))
          ;; 单参数指令: 如 "c 0" 或 "eat 1" 或 "buy tree"
          ((= (length rest-toks) 1)
           (let ((arg0 (string->number (first rest-toks))))
             (if arg0
                 (list op arg0)
                 (list op (first rest-toks)))))
          ;; 双参数指令: 如 "m 0 1" 或 "tt 0 1"
          ((>= (length rest-toks) 2)
           (let ((arg0 (string->number (first rest-toks)))
                 (arg1 (string->number (second rest-toks))))
             (if (and arg0 arg1)
                 (list op arg0 arg1)
                 (list op (first rest-toks) (second rest-toks)))))
          (else (list op))))))

(define (parse-command input)
  (cond
    ((list? input)
     (map (lambda (x) (if (symbol? x) (symbol->string x) x)) input))
    ((string? input)
     (let* ((cleaned (clean-input-str input))
            (tokens (split-whitespace cleaned)))
       (parse-cmd-tokens tokens)))
    (else #f)))

;; --------------------------------------------------------------------
;; 向上兼容的历史便捷包装函数
;; --------------------------------------------------------------------
(define (tt src-idx dst-idx lines)
  (let ((res (move-card lines src-idx dst-idx "tt" 8)))
    (if (hash-ref res "ok") (hash-ref res "lines") lines)))

(define (th src-idx dst-idx lines)
  (let ((res (move-card lines src-idx dst-idx "th" 8)))
    (if (hash-ref res "ok") (hash-ref res "lines") lines)))

(define (hh src-idx dst-idx lines)
  (let ((res (move-card lines src-idx dst-idx "hh" 8)))
    (if (hash-ref res "ok") (hash-ref res "lines") lines)))

(define (ht src-idx dst-idx lines)
  (let ((res (move-card lines src-idx dst-idx "ht" 8)))
    (if (hash-ref res "ok") (hash-ref res "lines") lines)))

(define (at src-idx dst-idx lines)
  (let ((res (move-card lines src-idx dst-idx "at" 8)))
    (if (hash-ref res "ok") (hash-ref res "lines") lines)))

(define (ah src-idx dst-idx lines)
  (let ((res (move-card lines src-idx dst-idx "ah" 8)))
    (if (hash-ref res "ok") (hash-ref res "lines") lines)))

(provide
  list-without-last
  move-card
  sell-card
  eat-food
  buy-card
  clean-input-str
  parse-compact-cmd
  parse-command
  tt th hh ht at ah)
