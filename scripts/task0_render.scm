;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; render 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (render-card card)
  (string-append (hash-ref card "icon")))
(define (render-line row-idx cards)
  (string-append "[" (to-string row-idx) "] "
                  (if (null? cards)
                    ""
                    (apply string-append (map render-card cards)))
                  "\n"))
(define (render-all-lines lines)
  (let ((indices (range 0 (length lines))))
    (apply string-append
          (map (lambda (idx cards) (render-line idx cards))
                indices
                lines))))



(provide render-all-lines)