;; ====================================================================
;; task0_cards.scm - Textlands 卡牌模型与桌面网格数据定义
;; 遵循规范: DOC-GAME-SPEC-001 (v1.0.0 Formal Baseline)
;; ====================================================================

(define *next-card-id* 100)

(define (gen-card-id!)
  (set! *next-card-id* (+ *next-card-id* 1))
  *next-card-id*)

;; 安全读取哈希字典
(define (map-get m k default)
  (if (hash-contains? m k)
      (hash-ref m k)
      default))

;; --------------------------------------------------------------------
;; 卡牌元数据 (Meta) 读取与设置
;; --------------------------------------------------------------------
(define (card-meta-get card key default)
  (let ((meta (map-get card "meta" (hash))))
    (map-get meta key default)))

(define (card-meta-set card key val)
  (let ((meta (map-get card "meta" (hash))))
    (hash-insert card "meta" (hash-insert meta key val))))

;; --------------------------------------------------------------------
;; 卡牌构造器
;; --------------------------------------------------------------------

;; 构造普通数据/物品卡 (Item Card)
(define (make-item-card name icon type meta)
  (hash "id" (gen-card-id!)
        "name" name
        "icon" icon
        "kind" "item"
        "type" type
        "meta" meta))

;; 构造函数卡 (Function Card)
;; meta 包含 inputs, output, duration, consume_self, progress, locked
(define (make-func-card name icon type inputs output duration consume_self meta)
  (let ((full-meta (hash-insert
                     (hash-insert
                       (hash-insert
                         (hash-insert
                           (hash-insert
                             (hash-insert meta "inputs" inputs)
                             "output" output)
                           "duration" duration)
                         "consume_self" consume_self)
                       "progress" 0.0)
                     "locked" #f)))
    (hash "id" (gen-card-id!)
          "name" name
          "icon" icon
          "kind" "func"
          "type" type
          "meta" full-meta)))

;; 向上兼容老接口
(define (make-card name icon type)
  (make-item-card name icon type (hash "value" 5 "nutrition" (if (string=? type "food") 20 0))))

;; --------------------------------------------------------------------
;; 状态查询与辅助方法
;; --------------------------------------------------------------------
(define (card-id card) (map-get card "id" 0))
(define (card-name card) (map-get card "name" ""))
(define (card-icon card) (map-get card "icon" ""))
(define (card-kind card) (map-get card "kind" "item"))
(define (card-type card) (map-get card "type" ""))

(define (card-func? card)
  (string=? (card-kind card) "func"))

(define (card-item? card)
  (string=? (card-kind card) "item"))

(define (card-locked? card)
  (card-meta-get card "locked" #f))

(define (card-lock card)
  (card-meta-set card "locked" #t))

(define (card-unlock card)
  (card-meta-set card "locked" #f))

(define (card-progress card)
  (card-meta-get card "progress" 0.0))

(define (card-set-progress card p)
  (card-meta-set card "progress" p))

;; --------------------------------------------------------------------
;; 列表更新工具函数 (不可变更新)
;; --------------------------------------------------------------------
(define (update-list-nth lst idx f)
  (let loop ([l lst] [i idx])
    (cond [(empty? l) l]
          [(< i 0) l]
          [(= i 0) (cons (f (first l)) (rest l))]
          [else (cons (car l) (loop (cdr l) (- i 1)))])))

;; --------------------------------------------------------------------
;; 产物原型定义 (Card Prototypes for Recipes)
;; --------------------------------------------------------------------
(define proto-wood
  (hash "name" "原木" "icon" "🪵" "kind" "item" "type" "wood" "meta" (hash "value" 5)))

(define proto-plank
  (hash "name" "木板" "icon" "🪵" "kind" "item" "type" "plank" "meta" (hash "value" 12)))

(define proto-gold
  (hash "name" "金币" "icon" "🪙" "kind" "item" "type" "gold" "meta" (hash "value" 10)))

(define proto-pie
  (hash "name" "馅饼" "icon" "🥧" "kind" "item" "type" "food" "meta" (hash "nutrition" 45 "value" 15)))

(define proto-bread
  (hash "name" "面包" "icon" "🍞" "kind" "item" "type" "food" "meta" (hash "nutrition" 30 "value" 10)))

(define proto-warehouse
  (hash "name" "仓库" "icon" "🏰" "kind" "item" "type" "building" "meta" (hash "expand" 2 "value" 30)))

;; --------------------------------------------------------------------
;; 桌面与初始卡牌流构建
;; --------------------------------------------------------------------
(define (create-initial-board)
  (let* (;; 函数卡
         (func-cut
           (make-func-card "砍伐" "🪓" "tool" '("tree") proto-wood 3.0 #f (hash)))
         (func-mine
           (make-func-card "采矿" "⛏️" "tool" '("stone") proto-gold 3.0 #f (hash)))
         (func-cook
           (make-func-card "烹饪" "🔥" "building" '("food") proto-pie 2.5 #f (hash)))
         (func-craft
           (make-func-card "制作" "🔨" "tool" '("wood") proto-plank 4.0 #f (hash)))
         (func-transmute
           (make-func-card "炼金" "✨" "spell" '("wood" "stone") proto-gold 3.0 #t (hash)))
         ;; 初始各行卡牌
         (line0 (list (make-item-card "村民" "🧑" "unit" (hash "value" 100))
                      func-cut
                      (make-item-card "树木" "🌲" "tree" (hash "value" 2))))
         (line1 (list func-mine
                      (make-item-card "石头" "🪨" "stone" (hash "value" 2))
                      (make-item-card "浆果" "🫐" "food" (hash "nutrition" 20 "value" 3))))
         (line2 (list (make-item-card "金币" "🪙" "gold" (hash "value" 10))
                      (make-item-card "金币" "🪙" "gold" (hash "value" 10))))
         (line3 '()))
    (hash
      "width" 8
      "height" 4
      "lines" (list line0 line1 line2 line3)
      "gold" 30
      "food" 100
      "hp" 100
      "max_hp" 100
      "recipes" (list
                  (hash "name" "砍伐 [🪓 + 🌲]" "desc" "消耗树木，产出原木 (常驻)")
                  (hash "name" "采矿 [⛏️ + 🪨]" "desc" "消耗石头，产出金币 (常驻)")
                  (hash "name" "烹饪 [🔥 + 🫐]" "desc" "消耗食物，产出高营养馅饼 (常驻)")
                  (hash "name" "制作 [🔨 + 🪵]" "desc" "消耗原木，产出高级木板 (常驻)")
                  (hash "name" "炼金 [✨ + 🪵 + 🪨]" "desc" "消耗原木和石头，点石成金 (一次性咒语)")
                  (hash "name" "扩建 [📦 + 🪵 + 🪙]" "desc" "扩建桌面容量上限 (一次性建筑)")))))

;; 兼容全局 `*lines*`
(define *board* (create-initial-board))
(define *lines* (map-get *board* "lines" '()))

(provide
  *next-card-id*
  gen-card-id!
  map-get
  card-meta-get
  card-meta-set
  make-item-card
  make-func-card
  make-card
  card-id
  card-name
  card-icon
  card-kind
  card-type
  card-func?
  card-item?
  card-locked?
  card-lock
  card-unlock
  card-progress
  card-set-progress
  update-list-nth
  proto-wood
  proto-plank
  proto-gold
  proto-pie
  proto-bread
  proto-warehouse
  create-initial-board
  *board*
  *lines*)
