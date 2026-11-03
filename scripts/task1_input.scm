;;;;;;;;;;;;;;;;;;;;;;;
;;1. 待实现的命令清单
;; m <src> <dst>：从 src 尾部 取出 1 张，推入 dst 尾部
;; mh <src> <dst>：从 src 尾部 取出 1 张，推入 dst 头部
;; mhh <src> <dst>：从 src 头部 取出 1 张，推入 dst 头部
;; mht <src> <dst>：从 src 头部 取出 1 张，推入 dst 尾部
;; ma <src> <dst>：整行搬迁，将 src 行的所有卡牌整体推入 dst 尾部
;;;;;;;;;;;;;;;;;;;;;;;

(define (pop-head cards)
  (car cards))
(define (last-element lst)
  (if (null? (cdr lst))
      (car lst)
      (last-element (cdr lst))))
(define (pop-tail cards)
  (last-element cards))
(define (push-head card cards)
  (cons card cards))
(define (push-tail card cards)
  (append card cards))

(define (m src dst)
  (push-tail (pop-tail src) dst))





(provide m)