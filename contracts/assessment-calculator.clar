;; assessment-calculator.clar

;; This contract allows for calculating and updating assessment rates.

(define-constant ERR-INVALID-AMOUNT (err u100))
(define-constant ERR-UNAUTHORIZED (err u101))

(define-data-var assessment-rate uint u500)

;; Public function to get the current assessment rate.
(define-read-only (get-assessment-rate)
  (var-get assessment-rate)
)

;; Public function to set a new assessment rate.
(define-public (set-assessment-rate (new-rate uint))
  (begin
    (asserts! (and (> new-rate u0) (< new-rate u1000)) ERR-INVALID-AMOUNT)
    (var-set assessment-rate new-rate)
    (ok true)
  )
)
