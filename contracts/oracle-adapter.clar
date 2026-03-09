;; Oracle Adapter (skeleton)
;; Consumes signed price feeds and exposes sanitized prices to options-core

(define-constant ERR-INVALID-SIGNER u600)
(define-constant ERR-STALE u601)

(define-data-var signer principal tx-sender)

(define-map latest-prices {asset: (string-ascii 10)}
  {
    price: uint,
    timestamp: uint
  })

(define-public (set-signer (new-signer principal))
  (begin
    (asserts! (is-eq tx-sender (var-get signer)) (err ERR-INVALID-SIGNER))
    (var-set signer new-signer)
    (ok true)))

(define-public (submit-price (asset (string-ascii 10)) (price uint) (timestamp uint) (signature (buff 65)))
  (begin
    ;; TODO: verify signature matches expected signer + payload
    (map-set latest-prices {asset: asset} {price: price, timestamp: timestamp})
    (ok true)))

(define-read-only (get-latest (asset (string-ascii 10)))
  (match (map-get? latest-prices {asset: asset})
    data (ok data)
    (err ERR-STALE)))
