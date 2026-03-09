;; Liquidity Pool Contract
;; Tracks LP shares, bankroll, and handles payouts for Bynomo-on-Stacks

(define-constant ERR-NOT-AUTHORIZED u500)
(define-constant ERR-INSUFFICIENT-LIQ u501)

(define-data-var pool-admin principal tx-sender)
(define-data-var pool-balance uint u0)

(define-map lp-shares {lp: principal}
  {
    shares: uint
  })


(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get pool-admin)) (err ERR-NOT-AUTHORIZED))
    (var-set pool-admin new-admin)
    (ok true)))

(define-public (deposit (amount uint))
  (begin
    ;; TODO: transfer tokens into pool
    (var-set pool-balance (+ (var-get pool-balance) amount))
    (map-set lp-shares {lp: tx-sender}
      (match (map-get? lp-shares {lp: tx-sender})
        current {shares: (+ (get shares current) amount)}
        {shares: amount}))
    (ok true)))

(define-public (withdraw (amount uint))
  (begin
    (asserts! (>= (var-get pool-balance) amount) (err ERR-INSUFFICIENT-LIQ))
    ;; TODO: enforce share-based withdrawal
    (var-set pool-balance (- (var-get pool-balance) amount))
    ;; TODO: transfer tokens back to LP
    (ok true)))

(define-public (record-stake (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get pool-admin)) (err ERR-NOT-AUTHORIZED))
    (var-set pool-balance (+ (var-get pool-balance) amount))
    (ok true)))

(define-public (record-payout (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get pool-admin)) (err ERR-NOT-AUTHORIZED))
    (asserts! (>= (var-get pool-balance) amount) (err ERR-INSUFFICIENT-LIQ))
    (var-set pool-balance (- (var-get pool-balance) amount))
    (ok true)))

(define-public (pay-winner (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get pool-admin)) (err ERR-NOT-AUTHORIZED))
    (asserts! (>= (var-get pool-balance) amount) (err ERR-INSUFFICIENT-LIQ))
    ;; TODO: token transfer once STX escrow lives in this contract
    (var-set pool-balance (- (var-get pool-balance) amount))
    (ok true)))
