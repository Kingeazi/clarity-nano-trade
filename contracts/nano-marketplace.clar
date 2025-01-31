;; NanoTrade Marketplace Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-invalid-listing (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-listing-expired (err u103))
(define-constant err-invalid-status (err u104))

;; Data structures 
(define-map listings
  { listing-id: uint }
  {
    seller: principal,
    price: uint,
    description: (string-utf8 256),
    expiry: uint,
    status: (string-ascii 10)
  }
)

;; Variables
(define-data-var listing-counter uint u0)

;; Read-only functions
(define-read-only (get-listing (listing-id uint))
  (map-get? listings {listing-id: listing-id})
)

;; Public functions
(define-public (create-listing (price uint) (description (string-utf8 256)) (expiry uint))
  (let 
    ((listing-id (var-get listing-counter)))
    (if (> expiry block-height)
      (begin
        (map-set listings
          {listing-id: listing-id}
          {
            seller: tx-sender,
            price: price,
            description: description,
            expiry: expiry,
            status: "active"
          }
        )
        (var-set listing-counter (+ listing-id u1))
        (ok listing-id)
      )
      err-invalid-listing
    )
  )
)

(define-public (buy-listing (listing-id uint))
  (let ((listing (unwrap! (get-listing listing-id) err-invalid-listing)))
    (if (and
          (is-eq (get status listing) "active")
          (<= block-height (get expiry listing)))
      (begin
        (try! (stx-transfer? (get price listing) tx-sender (get seller listing)))
        (map-set listings
          {listing-id: listing-id}
          (merge listing {status: "sold"})
        )
        (ok true)
      )
      err-listing-expired
    )
  )
)

(define-public (cancel-listing (listing-id uint))
  (let ((listing (unwrap! (get-listing listing-id) err-invalid-listing)))
    (if (is-eq tx-sender (get seller listing))
      (begin
        (map-set listings
          {listing-id: listing-id}
          (merge listing {status: "cancelled"})
        )
        (ok true)
      )
      err-not-owner
    )
  )
)
