;;;;;;;;;;;;;;;;;;;;;;;
;; tt <src> <dst>：从 src 尾部 取出 1 张，推入 dst 尾部
;; th <src> <dst>：从 src 尾部 取出 1 张，推入 dst 头部
;; hh <src> <dst>：从 src 头部 取出 1 张，推入 dst 头部
;; ht <src> <dst>：从 src 头部 取出 1 张，推入 dst 尾部
;; at <src> <dst>：整行搬迁，将 src 行的所有卡牌整体推入 dst 尾部
;;;;;;;;;;;;;;;;;;;;;;;


(define (tt src dst)
  (let* ([src-element (last src)]
         [src-modify  (take src (- (length src) 1))]
         [dst-modify  (append dst (list src-element))])
    (list src-modify dst-modify)))





(provide tt)
