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

;; Calculate vested amount for a participant
(define-read-only (get-vested-amount (participant principal))
  (let (
    (schedule (unwrap! (map-get? vesting-schedules participant) ERR_NO_VESTING_SCHEDULE))
    (current-block block-height)
    (vesting-start (+ (get start-block schedule) (get cliff-duration schedule)))
    (vesting-end (+ (get start-block schedule) (get vesting-duration schedule)))
  )
    (if (>= current-block vesting-end)
      (ok (get total-allocation schedule))
      (if (< current-block vesting-start)
        (ok u0)
        (let (
          (vested-periods (/ (- current-block vesting-start) (get vesting-interval schedule)))
          (vesting-ratio (/ (* vested-periods (get vesting-interval schedule)) (get vesting-duration schedule)))
        )
          (ok (/ (* (get total-allocation schedule) vesting-ratio) u100))
        )
      )
    )
  )
)

;; Claim vested tokens
(define-public (claim-vested-tokens)
  (let (
    (participant tx-sender)
    (schedule (unwrap! (map-get? vesting-schedules participant) ERR_NO_VESTING_SCHEDULE))
    (vested-amount (unwrap! (get-vested-amount participant) ERR_INVALID_PARAMETER))
    (claimable-amount (- vested-amount (get amount-claimed schedule)))
  )
    (asserts! (> claimable-amount u0) ERR_INSUFFICIENT_BALANCE)
    (map-set vesting-schedules participant 
      (merge schedule { amount-claimed: vested-amount })
    )
    (map-set token-balances participant 
      (+ (default-to u0 (map-get? token-balances participant)) claimable-amount)
    )
    (ok claimable-amount)
  )
)

;; Get balance of a participant
(define-read-only (get-balance (account principal))
  (ok (default-to u0 (map-get? token-balances account)))
)

;; Transfer tokens (only for claimed tokens)
(define-public (transfer (amount uint) (recipient principal))
  (let (
    (sender tx-sender)
    (sender-balance (unwrap! (get-balance sender) ERR_INVALID_PARAMETER))
  )
    (asserts! (and (not (is-eq sender recipient)) (not (is-eq recipient (as-contract tx-sender)))) ERR_INVALID_RECIPIENT)
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    (try! (as-contract (transfer-tokens sender recipient amount)))
    (ok true)
  )
)

(define-private (transfer-tokens (sender principal) (recipient principal) (amount uint))
  (begin
    (map-set token-balances sender (- (unwrap! (get-balance sender) ERR_INVALID_PARAMETER) amount))
    (map-set token-balances recipient (+ (unwrap! (get-balance recipient) ERR_INVALID_PARAMETER) amount))
    (ok true)
  )
)

;; Get total supply
(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

;; Get token name
(define-read-only (get-name)
  (ok (var-get token-name))
)

;; Get token symbol
(define-read-only (get-symbol)
  (ok (var-get token-symbol))
)

;; Get token decimals
(define-read-only (get-decimals)
  (ok (var-get token-decimals))
)

;; Get vesting schedule for a participant
(define-read-only (get-vesting-schedule (participant principal))
  (ok (map-get? vesting-schedules participant))
)

;; Check if the contract is initialized
(define-read-only (is-initialized)
  (ok (var-get contract-initialized))
)
