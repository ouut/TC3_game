(define *next-card-id* 0)

(define (make-card name icon type)
  (set! *next-card-id* (+ *next-card-id* 1))
  (hash "id" *next-card-id* "name" name "icon" icon "type" type))

(define *lines*
  (list
    (list (make-card "村民" "🧑" "unit")
      (make-card "浆果" "🍎" "food")
      (make-card "树木" "🌲" "resource"))
    (list (make-card "石头" "⛰️" "resource")
      (make-card "浆果" "🍎" "food")
      (make-card "浆果" "🍎" "food"))
    '()
    '()))

(define (update-list-nth lst idx f)
  (let loop ([l lst] [i idx])
    (cond [(empty? l) l]
          [(< 0) l]
          [(= i 0) (cons (f (first l)) (rest l))]
          [else (cons (car l) (loop (cdr l) (- i 1)))])))

; (update-nth (list 0 1 2 3 4) 2 (lambda (x) (* x 2)))
; (update-nth (list 0 1 2 3 4) -1 (lambda (x) (* x 2)))
; (update-nth (list 0 1 2 3 4) 2000 (lambda (x) (* x 2)))

(provide *lines* update-list-nth)
