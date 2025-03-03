;; NanoTrade Marketplace Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-invalid-listing (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-listing-expired (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-contract-paused (err u105))
(define-constant err-invalid-price (err u106))
(define-constant err-invalid-description (err u107))

;; Data variables
(define-data-var contract-paused bool false)
(define-data-var listing-counter uint u0)

;; Data structures 
(define-map listings
  { listing-id: uint }
  {
    seller: principal,
    price: uint,
    description: (string-utf8 256),
    expiry: uint,
    status: (string-ascii 10),
    verified: bool
  }
)

;; Events
(define-map-event listing-created 
  ((listing-id uint) (seller principal) (price uint))
)

(define-map-event listing-purchased 
  ((listing-id uint) (buyer principal) (price uint))
)

(define-map-event listing-cancelled
  ((listing-id uint) (seller principal))
)

;; Admin functions
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    (var-set contract-paused true)
    (ok true))
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-owner)
    (var-set contract-paused false)
    (ok true))
)

;; Read-only functions
(define-read-only (get-listing (listing-id uint))
  (map-get? listings {listing-id: listing-id})
)

(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

;; Public functions
(define-public (create-listing (price uint) (description (string-utf8 256)) (expiry uint))
  (let 
    ((listing-id (var-get listing-counter)))
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (> price u0) err-invalid-price)
    (asserts! (> expiry block-height) err-invalid-listing)
    (asserts! (> (len description) u0) err-invalid-description)
    (begin
      (map-set listings
        {listing-id: listing-id}
        {
          seller: tx-sender,
          price: price,
          description: description,
          expiry: expiry,
          status: "active",
          verified: false
        }
      )
      (var-set listing-counter (+ listing-id u1))
      (emit-listing-created listing-id tx-sender price)
      (ok listing-id)
    )
  )
)

(define-public (buy-listing (listing-id uint))
  (let ((listing (unwrap! (get-listing listing-id) err-invalid-listing)))
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-eq (get status listing) "active") err-invalid-status)
    (asserts! (<= block-height (get expiry listing)) err-listing-expired)
    (begin
      (try! (stx-transfer? (get price listing) tx-sender (get seller listing)))
      (map-set listings
        {listing-id: listing-id}
        (merge listing {status: "sold"})
      )
      (emit-listing-purchased listing-id tx-sender (get price listing))
      (ok true)
    )
  )
)

(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (get-listing listing-id) err-invalid-listing)))
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-eq tx-sender (get seller listing)) err-not-owner)
    (asserts! (is-eq (get status listing) "active") err-invalid-status)
    (begin
      (map-set listings
        {listing-id: listing-id}
        (merge listing {status: "cancelled"})
      )
      (emit-listing-cancelled listing-id tx-sender)
      (ok true)
    )
  )
)
