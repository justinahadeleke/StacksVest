;; vesting-contract.clar

;; Define constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_INITIALIZED (err u101))
(define-constant ERR_NOT_INITIALIZED (err u102))
(define-constant ERR_NO_VESTING_SCHEDULE (err u103))
(define-constant ERR_INSUFFICIENT_BALANCE (err u104))
(define-constant ERR_INVALID_PARAMETER (err u105))
(define-constant ERR_TRANSFER_FAILED (err u106))
(define-constant ERR_ALREADY_HAS_SCHEDULE (err u107))
(define-constant ERR_INVALID_RECIPIENT (err u108))

;; Define data variables
(define-data-var token-name (string-ascii 32) "")
(define-data-var token-symbol (string-ascii 32) "")
(define-data-var token-decimals uint u0)
(define-data-var total-supply uint u0)
(define-data-var contract-initialized bool false)

;; Define data maps
(define-map token-balances principal uint)
(define-map vesting-schedules
  principal
  {
    total-allocation: uint,
    start-block: uint,
    cliff-duration: uint,
    vesting-duration: uint,
    vesting-interval: uint,
    amount-claimed: uint
  }
)

;; Initialize the contract
(define-public (initialize (name (string-ascii 32)) (symbol (string-ascii 32)) (decimals uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (var-get contract-initialized)) ERR_ALREADY_INITIALIZED)
    (asserts! (and (> (len name) u0) (<= (len name) u32)) ERR_INVALID_PARAMETER)
    (asserts! (and (> (len symbol) u0) (<= (len symbol) u32)) ERR_INVALID_PARAMETER)
    (asserts! (<= decimals u18) ERR_INVALID_PARAMETER)
    (var-set token-name name)
    (var-set token-symbol symbol)
    (var-set token-decimals decimals)
    (var-set contract-initialized true)
    (ok true)
  )
)

;; Create a vesting schedule for a participant
(define-public (create-vesting-schedule 
  (participant principal) 
  (total-allocation uint)
  (start-block uint)
  (cliff-duration uint)
  (vesting-duration uint)
  (vesting-interval uint)
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (var-get contract-initialized) ERR_NOT_INITIALIZED)
    (asserts! (is-none (map-get? vesting-schedules participant)) ERR_ALREADY_HAS_SCHEDULE)
    (asserts! (> total-allocation u0) ERR_INVALID_PARAMETER)
    (asserts! (>= start-block block-height) ERR_INVALID_PARAMETER)
    (asserts! (>= vesting-duration cliff-duration) ERR_INVALID_PARAMETER)
    (asserts! (> vesting-interval u0) ERR_INVALID_PARAMETER)
    (asserts! (<= vesting-interval vesting-duration) ERR_INVALID_PARAMETER)
    (map-set vesting-schedules participant {
      total-allocation: total-allocation,
      start-block: start-block,
      cliff-duration: cliff-duration,
      vesting-duration: vesting-duration,
      vesting-interval: vesting-interval,
      amount-claimed: u0
    })
    (var-set total-supply (+ (var-get total-supply) total-allocation))
    (ok true)
  )
)
