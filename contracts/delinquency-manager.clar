;; Delinquency Manager Contract
;; Manages overdue taxes and collection procedures

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-PROPERTY-NOT-FOUND (err u101))
(define-constant ERR-INVALID-AMOUNT (err u102))
(define-constant ERR-INVALID-DATE (err u107))
(define-constant ERR-INVALID-STATUS (err u109))

;; Data Variables
(define-data-var penalty-rate uint u100) ;; 10% annual penalty rate
(define-data-var interest-rate uint u60) ;; 6% annual interest rate
(define-data-var grace-period uint u720) ;; 30 days grace period
(define-data-var next-delinquency-id uint u1)

;; Data Maps
(define-map delinquent-properties
  { property-id: uint, tax-year: uint }
  {
    delinquency-id: uint,
    original-amount: uint,
    penalty-amount: uint,
    interest-amount: uint,
    total-owed: uint,
    delinquent-since: uint,
    last-notice-date: uint,
    collection-status: (string-ascii 20),
    notices-sent: uint
  }
)

(define-map collection-actions
  { delinquency-id: uint }
  {
    property-id: uint,
    action-type: (string-ascii 30),
    action-date: uint,
    amount-involved: uint,
    notes: (string-ascii 200),
    performed-by: principal
  }
)

(define-map authorized-collectors
  { collector: principal }
  { authorized: bool }
)

;; Authorization Functions
(define-public (authorize-collector (collector principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-collectors { collector: collector } { authorized: true }))
  )
)

(define-public (revoke-collector (collector principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-collectors { collector: collector } { authorized: false }))
  )
)

;; Delinquency Management Functions
(define-public (mark-property-delinquent
  (property-id uint)
  (tax-year uint)
  (original-amount uint))
  (let
    (
      (delinquency-id (var-get next-delinquency-id))
      (current-date block-height)
    )
    (asserts! (is-authorized-collector tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> original-amount u0) ERR-INVALID-AMOUNT)

    (map-set delinquent-properties
      { property-id: property-id, tax-year: tax-year }
      {
        delinquency-id: delinquency-id,
        original-amount: original-amount,
        penalty-amount: u0,
        interest-amount: u0,
        total-owed: original-amount,
        delinquent-since: current-date,
        last-notice-date: u0,
        collection-status: "delinquent",
        notices-sent: u0
      }
    )

    (var-set next-delinquency-id (+ delinquency-id u1))
    (ok delinquency-id)
  )
)

(define-public (update-delinquency-amounts (property-id uint) (tax-year uint))
  (let
    (
      (delinquency-data (unwrap! (map-get? delinquent-properties { property-id: property-id, tax-year: tax-year }) ERR-PROPERTY-NOT-FOUND))
      (days-delinquent (- block-height (get delinquent-since delinquency-data)))
      (original-amount (get original-amount delinquency-data))
      (penalty-amount (calculate-penalty original-amount days-delinquent))
      (interest-amount (calculate-interest original-amount days-delinquent))
      (total-owed (+ original-amount penalty-amount interest-amount))
    )
    (asserts! (is-authorized-collector tx-sender) ERR-NOT-AUTHORIZED)

    (ok (map-set delinquent-properties
      { property-id: property-id, tax-year: tax-year }
      (merge delinquency-data {
        penalty-amount: penalty-amount,
        interest-amount: interest-amount,
        total-owed: total-owed
      })
    ))
  )
)

(define-public (send-delinquency-notice (property-id uint) (tax-year uint))
  (let
    (
      (delinquency-data (unwrap! (map-get? delinquent-properties { property-id: property-id, tax-year: tax-year }) ERR-PROPERTY-NOT-FOUND))
      (notices-sent (get notices-sent delinquency-data))
    )
    (asserts! (is-authorized-collector tx-sender) ERR-NOT-AUTHORIZED)

    ;; Record collection action
    (map-set collection-actions
      { delinquency-id: (get delinquency-id delinquency-data) }
      {
        property-id: property-id,
        action-type: "notice-sent",
        action-date: block-height,
        amount-involved: (get total-owed delinquency-data),
        notes: "Delinquency notice sent to property owner",
        performed-by: tx-sender
      }
    )

    ;; Update delinquency record
    (ok (map-set delinquent-properties
      { property-id: property-id, tax-year: tax-year }
      (merge delinquency-data {
        last-notice-date: block-height,
        notices-sent: (+ notices-sent u1)
      })
    ))
  )
)

(define-public (update-collection-status
  (property-id uint)
  (tax-year uint)
  (new-status (string-ascii 20)))
  (let
    (
      (delinquency-data (unwrap! (map-get? delinquent-properties { property-id: property-id, tax-year: tax-year }) ERR-PROPERTY-NOT-FOUND))
    )
    (asserts! (is-authorized-collector tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-status new-status) ERR-INVALID-STATUS)

    ;; Record status change
    (map-set collection-actions
      { delinquency-id: (get delinquency-id delinquency-data) }
      {
        property-id: property-id,
        action-type: "status-change",
        action-date: block-height,
        amount-involved: (get total-owed delinquency-data),
        notes: "Collection status updated",
        performed-by: tx-sender
      }
    )

    (ok (map-set delinquent-properties
      { property-id: property-id, tax-year: tax-year }
      (merge delinquency-data { collection-status: new-status })
    ))
  )
)

(define-public (resolve-delinquency (property-id uint) (tax-year uint) (payment-amount uint))
  (let
    (
      (delinquency-data (unwrap! (map-get? delinquent-properties { property-id: property-id, tax-year: tax-year }) ERR-PROPERTY-NOT-FOUND))
      (total-owed (get total-owed delinquency-data))
    )
    (asserts! (is-authorized-collector tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (>= payment-amount total-owed) ERR-INVALID-AMOUNT)

    ;; Record resolution
    (map-set collection-actions
      { delinquency-id: (get delinquency-id delinquency-data) }
      {
        property-id: property-id,
        action-type: "delinquency-resolved",
        action-date: block-height,
        amount-involved: payment-amount,
        notes: "Delinquency fully resolved",
        performed-by: tx-sender
      }
    )

    (ok (map-set delinquent-properties
      { property-id: property-id, tax-year: tax-year }
      (merge delinquency-data {
        collection-status: "resolved",
        total-owed: u0
      })
    ))
  )
)

;; Calculation Functions
(define-private (calculate-penalty (original-amount uint) (days-delinquent uint))
  (if (> days-delinquent (var-get grace-period))
    (let
      (
        (penalty-days (- days-delinquent (var-get grace-period)))
        (annual-penalty (* original-amount (var-get penalty-rate)))
        (daily-penalty (/ annual-penalty u36500)) ;; 365 days * 100 for percentage
      )
      (* daily-penalty penalty-days)
    )
    u0
  )
)

(define-private (calculate-interest (original-amount uint) (days-delinquent uint))
  (if (> days-delinquent (var-get grace-period))
    (let
      (
        (interest-days (- days-delinquent (var-get grace-period)))
        (annual-interest (* original-amount (var-get interest-rate)))
        (daily-interest (/ annual-interest u36500)) ;; 365 days * 100 for percentage
      )
      (* daily-interest interest-days)
    )
    u0
  )
)

;; Helper Functions
(define-private (is-authorized-collector (collector principal))
  (or
    (is-eq collector CONTRACT-OWNER)
    (default-to false (get authorized (map-get? authorized-collectors { collector: collector })))
  )
)

(define-private (is-valid-status (status (string-ascii 20)))
  (or
    (is-eq status "delinquent")
    (or
      (is-eq status "notice-sent")
      (or
        (is-eq status "in-collection")
        (or
          (is-eq status "payment-plan")
          (or
            (is-eq status "resolved")
            (is-eq status "written-off")
          )
        )
      )
    )
  )
)

;; Read-only Functions
(define-read-only (get-delinquency-details (property-id uint) (tax-year uint))
  (map-get? delinquent-properties { property-id: property-id, tax-year: tax-year })
)

(define-read-only (get-collection-action (delinquency-id uint))
  (map-get? collection-actions { delinquency-id: delinquency-id })
)

(define-read-only (calculate-current-amount-owed (property-id uint) (tax-year uint))
  (match (map-get? delinquent-properties { property-id: property-id, tax-year: tax-year })
    delinquency-data
    (let
      (
        (days-delinquent (- block-height (get delinquent-since delinquency-data)))
        (original-amount (get original-amount delinquency-data))
        (penalty-amount (calculate-penalty original-amount days-delinquent))
        (interest-amount (calculate-interest original-amount days-delinquent))
      )
      (some {
        original-amount: original-amount,
        penalty-amount: penalty-amount,
        interest-amount: interest-amount,
        total-owed: (+ original-amount penalty-amount interest-amount),
        days-delinquent: days-delinquent
      })
    )
    none
  )
)

;; Administrative Functions
(define-public (set-penalty-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-rate u500) ERR-INVALID-AMOUNT) ;; Max 50%
    (ok (var-set penalty-rate new-rate))
  )
)

(define-public (set-interest-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-rate u200) ERR-INVALID-AMOUNT) ;; Max 20%
    (ok (var-set interest-rate new-rate))
  )
)

(define-public (set-grace-period (new-period uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> new-period u0) ERR-INVALID-AMOUNT)
    (ok (var-set grace-period new-period))
  )
)
