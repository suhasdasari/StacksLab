;; Options Core Contract
;; Handles round creation, bet intake, and settlement logic for Bynomo-on-Stacks

(impl-trait 'SP000000000000000000002Q6VF78.pox-3-trait.pox-3-trait) ;; placeholder trait impl

(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-ROUND-CLOSED (err u401))
(define-constant ERR-ROUND-NOT-FOUND (err u402))
(define-constant ERR-RISK-LIMIT (err u403))
(define-constant ERR-SETTLED (err u404))
(define-constant ERR-CONFIG (err u405))
(define-constant ERR-NO-PAYOUT (err u406))

(define-constant PRECISION u10000)

(define-data-var admin principal tx-sender)
(define-data-var liquidity-pool (optional principal) none)
(define-data-var oracle-adapter (optional principal) none)

(define-map rounds {id: uint}
  {
    asset: (string-ascii 10),
    strike: uint,
    expiry: uint,
    lock-height: uint,
    oracle-id: (string-ascii 32),
    status: uint, ;; 0 = open, 1 = locked, 2 = settled
    settlement-price: (optional uint)
  })

(define-map bets {round-id: uint, player: principal}
  {
    stake: uint,
    multiplier-bps: uint,
    direction: bool,
    claimed: bool
  })

;; --- helpers -----------------------------------------------------------------

(define-read-only (round-exists? (round-id uint))
  (match (map-get? rounds {id: round-id})
    round-data (ok round-data)
    (err ERR-ROUND-NOT-FOUND)))

(define-read-only (compute-payout (stake uint) (multiplier-bps uint))
  (ok (/ (* stake multiplier-bps) PRECISION)))

(define-read-only (get-round (round-id uint))
  (match (map-get? rounds {id: round-id})
    round-data (ok round-data)
    (err ERR-ROUND-NOT-FOUND)))

(define-read-only (get-bet (round-id uint) (player principal))
  (match (map-get? bets {round-id: round-id, player: player})
    bet (ok bet)
    (err ERR-ROUND-NOT-FOUND)))

;; --- public entrypoints -------------------------------------------------------

(define-public (set-contracts (lp principal) (oracle principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (var-set liquidity-pool (some lp))
    (var-set oracle-adapter (some oracle))
    (ok true)))

(define-public (create-round (round-id uint)
                             (asset (string-ascii 10))
                             (strike uint)
                             (expiry uint)
                             (lock-height uint)
                             (oracle-id (string-ascii 32)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-AUTHORIZED)
    (map-set rounds {id: round-id}
      {
        asset: asset,
        strike: strike,
        expiry: expiry,
        lock-height: lock-height,
        oracle-id: oracle-id,
        status: u0,
        settlement-price: none
      })
    (ok round-id)))

(define-public (place-bet (round-id uint)
                          (stake uint)
                          (multiplier-bps uint)
                          (direction bool))
  (let ((round (try! (round-exists? round-id)))
        (lp (unwrap! (var-get liquidity-pool) ERR-CONFIG)))
    (begin
      (asserts! (is-eq (get status round) u0) ERR-ROUND-CLOSED)
      (asserts! (<= block-height (get lock-height round)) ERR-ROUND-CLOSED)
      (asserts! (> stake u0) ERR-RISK-LIMIT)
      (try! (stx-transfer? stake tx-sender lp))
      (map-set bets {round-id: round-id, player: tx-sender}
        {
          stake: stake,
          multiplier-bps: multiplier-bps,
          direction: direction,
          claimed: false
        })
      (ok true))))

(define-public (lock-round (round-id uint))
  (let ((round (try! (round-exists? round-id))))
    (begin
      (asserts! (is-eq (get status round) u0) ERR-SETTLED)
      (map-set rounds {id: round-id} (merge round {status: u1}))
      (ok true))))

(define-public (settle-round (round-id uint) (final-price uint))
  (let ((round (try! (round-exists? round-id))))
    (begin
      (asserts! (is-eq (get status round) u1) ERR-ROUND-CLOSED)
      (asserts! (> final-price u0) ERR-RISK-LIMIT)
      ;; TODO: fetch reference price from oracle adapter and validate `final-price`
      (map-set rounds {id: round-id}
        (merge round {status: u2, settlement-price: (some final-price)}))
      (ok true))))

(define-public (claim-winnings (round-id uint))
  (let ((round (try! (round-exists? round-id)))
        (bet (map-get? bets {round-id: round-id, player: tx-sender}))
        (lp (unwrap! (var-get liquidity-pool) ERR-CONFIG)))
    (match bet
      bet-data
      (begin
        (asserts! (is-eq (get status round) u2) ERR-ROUND-CLOSED)
        (asserts! (is-eq (get claimed bet-data) false) ERR-SETTLED)
        (let ((maybe-price (get settlement-price round)))
          (match maybe-price
            final
            (let ((strike (get strike round))
                  (won (if (> final strike)
                           (is-eq (get direction bet-data) true)
                           (if (< final strike)
                               (is-eq (get direction bet-data) false)
                               false)))
                  (claimant tx-sender))
              (map-set bets {round-id: round-id, player: tx-sender}
                (merge bet-data {claimed: true}))
              (if won
                  (let ((payout (try! (compute-payout (get stake bet-data)
                                                      (get multiplier-bps bet-data)))))
                    (as-contract (try! (stx-transfer? payout lp claimant)))
                    (ok payout))
                  (err ERR-NO-PAYOUT)))
            (err ERR-SETTLED))))
      (err ERR-ROUND-NOT-FOUND))))
