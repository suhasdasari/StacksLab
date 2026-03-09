;; Options Core Contract
;; Handles round creation, bet intake, and settlement logic for Bynomo-on-Stacks

(define-constant STATUS-OPEN u0)
(define-constant STATUS-LOCKED u1)
(define-constant STATUS-SETTLED u2)
(define-constant STATUS-CANCELED u3)

(define-constant ERR-NOT-AUTHORIZED u400)
(define-constant ERR-ROUND-CLOSED u401)
(define-constant ERR-ROUND-NOT-FOUND u402)
(define-constant ERR-RISK-LIMIT u403)
(define-constant ERR-SETTLED u404)
(define-constant ERR-CONFIG u405)
(define-constant ERR-ROUND-EXISTS u406)
(define-constant ERR-DUP-BET u407)
(define-constant ERR-CANCELED u408)
(define-constant ERR-NO-PAYOUT u409)

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
    status: uint,
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
  (/ (* stake multiplier-bps) PRECISION))

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
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
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
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (asserts! (> expiry lock-height) (err ERR-CONFIG))
    (match (map-get? rounds {id: round-id})
      existing (err ERR-ROUND-EXISTS)
      (begin
        (map-set rounds {id: round-id}
          {
            asset: asset,
            strike: strike,
            expiry: expiry,
            lock-height: lock-height,
            oracle-id: oracle-id,
            status: STATUS-OPEN,
            settlement-price: none
          })
        (ok round-id)))))

(define-public (cancel-round (round-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (let ((round (try! (round-exists? round-id))))
      (asserts! (is-eq (get status round) STATUS-OPEN) (err ERR-ROUND-CLOSED))
      (map-set rounds {id: round-id}
        (merge round {status: STATUS-CANCELED, settlement-price: none}))
      (ok true))))

(define-public (place-bet (round-id uint)
                          (stake uint)
                          (multiplier-bps uint)
                          (direction bool))
  (let ((round (try! (round-exists? round-id))))
    (begin
      (asserts! (is-eq (get status round) STATUS-OPEN) (err ERR-ROUND-CLOSED))
      (asserts! (> stake u0) (err ERR-RISK-LIMIT))
      (asserts! (> multiplier-bps u0) (err ERR-RISK-LIMIT))
      (match (map-get? bets {round-id: round-id, player: tx-sender})
        existing (err ERR-DUP-BET)
        (begin
          ;; TODO: transfer stake into liquidity vault once wired
          (map-set bets {round-id: round-id, player: tx-sender}
            {
              stake: stake,
              multiplier-bps: multiplier-bps,
              direction: direction,
              claimed: false
            })
          (ok true))))))

(define-public (lock-round (round-id uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (let ((round (try! (round-exists? round-id))))
      (asserts! (is-eq (get status round) STATUS-OPEN) (err ERR-SETTLED))
      (map-set rounds {id: round-id} (merge round {status: STATUS-LOCKED}))
      (ok true))))

(define-public (settle-round (round-id uint) (final-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-some (var-get oracle-adapter)) (err ERR-CONFIG))
    (let ((round (try! (round-exists? round-id))))
      (asserts! (is-eq (get status round) STATUS-LOCKED) (err ERR-ROUND-CLOSED))
      (asserts! (> final-price u0) (err ERR-RISK-LIMIT))
      ;; TODO: fetch reference price from oracle adapter and validate `final-price`
      (map-set rounds {id: round-id}
        (merge round {status: STATUS-SETTLED, settlement-price: (some final-price)}))
      (ok true))))

(define-public (claim-winnings (round-id uint))
  (let ((round (try! (round-exists? round-id)))
        (bet (map-get? bets {round-id: round-id, player: tx-sender})))
    (match bet
      bet-data
      (begin
        (asserts! (is-eq (get status round) STATUS-SETTLED) (err ERR-ROUND-CLOSED))
        (asserts! (is-eq (get claimed bet-data) false) (err ERR-SETTLED))
        (let ((maybe-price (get settlement-price round)))
          (match maybe-price
            final
            (let ((strike (get strike round))
                  (won (if (> final strike)
                           (get direction bet-data)
                           (if (< final strike)
                               (not (get direction bet-data))
                               false))))
              (map-set bets {round-id: round-id, player: tx-sender}
                (merge bet-data {claimed: true}))
              (if won
                  (let ((payout (compute-payout (get stake bet-data)
                                                (get multiplier-bps bet-data))))
                    ;; TODO: transfer payout from liquidity pool once LP contract escrows STX
                    (ok payout))
                  (err ERR-NO-PAYOUT)))
            (err ERR-SETTLED))))
      (err ERR-ROUND-NOT-FOUND))))
