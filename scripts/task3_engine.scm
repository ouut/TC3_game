;; ====================================================================
;; task3_engine.scm - Textlands Applicative Order 求值与规约引擎
;; 遵循规范: DOC-GAME-SPEC-001 (Section 3: Evaluation & Reduction Engine)
;; ====================================================================

(require "task0_cards.scm")

;; 检查单张卡牌是否满足纯数据参数要求
(define (param-match? card req-type)
  (and (string=? (map-get card "kind" "") "item")
       (or (string=? req-type "any")
           (string=? (map-get card "type" "") req-type)
           (string=? (map-get card "name" "") req-type))))

;; 递归检查紧随其后的若干张卡牌是否严格匹配 inputs 序列 ( Applicative Order 核心)
(define (params-match? cards req-list)
  (cond
    ((empty? req-list) #t)
    ((empty? cards) #f)
    ((param-match? (first cards) (first req-list))
     (params-match? (rest cards) (rest req-list)))
    (else #f)))

;; 实例化产物原型
(define (instantiate-proto proto)
  (hash "id" (gen-card-id!)
        "name" (map-get proto "name" "未知")
        "icon" (map-get proto "icon" "❓")
        "kind" (map-get proto "kind" "item")
        "type" (map-get proto "type" "misc")
        "meta" (map-get proto "meta" (hash))))

;; 批量解除一行中所有卡牌的锁定状态
(define (unlock-all-cards cards)
  (map (lambda (c) (card-meta-set (card-meta-set c "locked" #f) "progress" 0.0)) cards))

;; --------------------------------------------------------------------
;; 单行求值步进 (四阶段状态机: 扫描匹配 -> 锁定计时 -> 背压检测 -> 就地规约)
;; --------------------------------------------------------------------
(define (step-line line dt width)
  (let ((len (length line)))
    (let loop ((idx 0))
      (if (>= idx len)
          ;; 行内没有找到任何合法 Redex -> 清理残余虚假锁定
          (hash "line" (unlock-all-cards line) "event" #f "reduced" #f)
          (let ((card (list-ref line idx)))
            (if (not (string=? (map-get card "kind" "") "func"))
                (loop (+ idx 1))
                (let* ((inputs (card-meta-get card "inputs" '()))
                       (n (length inputs)))
                  (if (> (+ idx 1 n) len)
                      ;; 参数不足，跳过该函数继续向后扫描
                      (loop (+ idx 1))
                      (let ((sub-cards (take (drop line (+ idx 1)) n)))
                        (if (not (params-match? sub-cards inputs))
                            ;; 参数不匹配或遇到嵌套未求值的内部函数 -> 必须等待内层先求值！
                            (loop (+ idx 1))
                            ;; 【匹配到合法 Redex!】
                            (let* ((duration (card-meta-get card "duration" 3.0))
                                   (cur-prog (card-meta-get card "progress" 0.0))
                                   (new-prog (+ cur-prog dt)))
                              (if (>= new-prog duration)
                                  ;; 【倒计时结束：触发就地规约 (In-place Reduction)】
                                  (let* ((consume-self (card-meta-get card "consume_self" #f))
                                         (out-proto (card-meta-get card "output" (hash)))
                                         (new-card (instantiate-proto out-proto))
                                         (prefix (take line idx))
                                         (suffix (drop line (+ idx 1 n)))
                                         ;; 产出后的预测行长度
                                         (pred-len (if consume-self
                                                       (+ (length prefix) 1 (length suffix))
                                                       (+ (length prefix) 2 (length suffix)))))
                                    (if (> pred-len width)
                                        ;; 【背压机制】：行满暂停产出，锁定维持在 100%
                                        (let* ((hold-func (card-meta-set (card-meta-set card "locked" #t) "progress" duration))
                                               (locked-params (map (lambda (c) (card-meta-set c "locked" #t)) sub-cards))
                                               (new-line (append prefix (cons hold-func (append locked-params suffix)))))
                                          (hash "line" new-line "event" #f "reduced" #f))
                                        ;; 【执行就地规约替换】
                                        (let ((new-line
                                               (if consume-self
                                                   ;; 一次性算子: Func + Params 全部消耗，原地替换为产物
                                                   (append prefix (cons new-card suffix))
                                                   ;; 常驻机器: 保留 Func，消耗 Params，产物紧跟 Func 之后
                                                   (let ((clean-func (card-meta-set (card-meta-set card "locked" #f) "progress" 0.0)))
                                                     (append prefix (cons clean-func (cons new-card suffix)))))))
                                          (hash "line" new-line
                                                "event" (string-append "[规约完成] " (map-get card "icon" "") " " (map-get card "name" "")
                                                                       " 规约成功！产出 " (map-get new-card "icon" "") " " (map-get new-card "name" ""))
                                                "reduced" #t
                                                "product" new-card))))
                                  ;; 【锁定并累计进度条】
                                  (let* ((locked-func (card-meta-set (card-meta-set card "locked" #t) "progress" new-prog))
                                         (locked-params (map (lambda (c) (card-meta-set c "locked" #t)) sub-cards))
                                         (prefix (take line idx))
                                         (suffix (drop line (+ idx 1 n)))
                                         (new-line (append prefix (cons locked-func (append locked-params suffix)))))
                                    (hash "line" new-line "event" #f "reduced" #f))))))))))))))

;; 自定义列表存在性判定
(define (list-any pred lst)
  (cond
    ((empty? lst) #f)
    ((pred (first lst)) #t)
    (else (list-any pred (rest lst)))))

;; --------------------------------------------------------------------
;; 全局桌面求值步进
;; --------------------------------------------------------------------
(define (step-board board dt)
  (let* ((lines (map-get board "lines" '()))
         (width (map-get board "width" 8))
         (results (map (lambda (l) (step-line l dt width)) lines))
         (new-lines (map (lambda (r) (hash-ref r "line")) results))
         (events (let loop ((rem results) (evs '()))
                   (if (empty? rem)
                       (reverse evs)
                       (let ((ev (hash-ref (first rem) "event")))
                         (if ev
                             (loop (rest rem) (cons ev evs))
                             (loop (rest rem) evs))))))
         (any-reduced? (list-any (lambda (r) (hash-ref r "reduced")) results))
         ;; 检查是否有建筑扩容产物 (如仓库)
         (expand-delta (let loop ((rem results) (acc 0))
                         (if (empty? rem)
                             acc
                             (let ((prod (if (hash-contains? (first rem) "product") (hash-ref (first rem) "product") #f)))
                               (if (and prod (string=? (map-get prod "type" "") "building"))
                                   (loop (rest rem) (+ acc (card-meta-get prod "expand" 1)))
                                   (loop (rest rem) acc))))))
         (new-width (+ width expand-delta))
         (updated-board (hash-insert
                          (hash-insert board "lines" new-lines)
                          "width" new-width)))
    (hash "board" updated-board
          "events" events
          "changed" (or any-reduced?
                        (> expand-delta 0)
                        ;; 检查是否有进行中的进度变动
                        (list-any (lambda (r)
                                    (let ((l (hash-ref r "line")))
                                      (list-any (lambda (c)
                                                  (and (card-func? c)
                                                       (card-locked? c)
                                                       (> (card-progress c) 0.0)))
                                                l)))
                                  results)))))

(provide
  param-match?
  params-match?
  instantiate-proto
  unlock-all-cards
  step-line
  step-board)
