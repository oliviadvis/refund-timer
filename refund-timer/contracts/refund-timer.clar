;; Refund Timer Contract - Delayed Refund Processing
;; A time-locked contract that releases funds after a specified delay

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_TIMEOUT_NOT_REACHED (err u103))
(define-constant ERR_INSUFFICIENT_FUNDS (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))

;; Data Variables
(define-data-var contract-active bool true)

;; Data Maps
(define-map refund-requests
  { requester: principal }
  {
    amount: uint,
    timeout-block: uint,
    created-at: uint
  }
)

;; Public Functions

;; Create a refund request with time lock
(define-public (create-refund-request (amount uint) (delay-blocks uint))
  (let
    (
      (requester tx-sender)
      (timeout-block (+ block-height delay-blocks))
      (existing-request (map-get? refund-requests { requester: requester }))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (is-none existing-request) ERR_ALREADY_EXISTS)
    (asserts! (>= (stx-get-balance requester) amount) ERR_INSUFFICIENT_FUNDS)
    
    ;; Transfer STX to contract
    (try! (stx-transfer? amount requester (as-contract tx-sender)))
    
    ;; Store refund request
    (map-set refund-requests
      { requester: requester }
      {
        amount: amount,
        timeout-block: timeout-block,
        created-at: block-height
      }
    )
    
    (ok timeout-block)
  )
)

;; Claim refund after timeout period
(define-public (claim-refund)
  (let
    (
      (requester tx-sender)
      (request (unwrap! (map-get? refund-requests { requester: requester }) ERR_NOT_FOUND))
      (amount (get amount request))
      (timeout-block (get timeout-block request))
    )
    (asserts! (>= block-height timeout-block) ERR_TIMEOUT_NOT_REACHED)
    
    ;; Delete the request
    (map-delete refund-requests { requester: requester })
    
    ;; Transfer STX back to requester
    (as-contract (stx-transfer? amount tx-sender requester))
  )
)

;; Cancel refund request (only before timeout)
(define-public (cancel-refund-request)
  (let
    (
      (requester tx-sender)
      (request (unwrap! (map-get? refund-requests { requester: requester }) ERR_NOT_FOUND))
      (amount (get amount request))
      (timeout-block (get timeout-block request))
    )
    (asserts! (< block-height timeout-block) ERR_TIMEOUT_NOT_REACHED)
    
    ;; Delete the request
    (map-delete refund-requests { requester: requester })
    
    ;; Transfer STX back to requester
    (as-contract (stx-transfer? amount tx-sender requester))
  )
)

;; Emergency function - contract owner can pause/unpause
(define-public (toggle-contract-active)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

;; Read-only Functions

;; Get refund request details
(define-read-only (get-refund-request (requester principal))
  (map-get? refund-requests { requester: requester })
)
;; Check if refund is ready to claim
(define-read-only (is-refund-ready (requester principal))
  (match (map-get? refund-requests { requester: requester })
    request (>= block-height (get timeout-block request))
    false
  )
)

;; Get remaining blocks until refund is available
(define-read-only (get-blocks-until-refund (requester principal))
  (match (map-get? refund-requests { requester: requester })
    request 
      (let ((remaining (- (get timeout-block request) block-height)))
        (if (> remaining u0) (some remaining) none)
      )
    none
  )
)

;; Get contract status
(define-read-only (get-contract-status)
  {
    active: (var-get contract-active),
    owner: CONTRACT_OWNER,
    current-block: block-height
  }
)

;; Get contract balance
(define-read-only (get-contract-balance)
  (stx-get-balance (as-contract tx-sender))
)