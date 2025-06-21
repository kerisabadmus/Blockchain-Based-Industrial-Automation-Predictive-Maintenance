;; Equipment Manufacturer Verification Contract
;; Validates and manages equipment manufacturers

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_MANUFACTURER_EXISTS (err u101))
(define-constant ERR_MANUFACTURER_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CERTIFICATION (err u103))

;; Data structures
(define-map manufacturers
  { manufacturer-id: uint }
  {
    name: (string-ascii 100),
    certification-level: uint,
    verified: bool,
    registration-date: uint,
    contact-info: (string-ascii 200)
  }
)

(define-map manufacturer-equipment
  { manufacturer-id: uint, equipment-type: (string-ascii 50) }
  { certified: bool, certification-date: uint }
)

(define-data-var next-manufacturer-id uint u1)

;; Public functions
(define-public (register-manufacturer
  (name (string-ascii 100))
  (certification-level uint)
  (contact-info (string-ascii 200)))
  (let ((manufacturer-id (var-get next-manufacturer-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? manufacturers { manufacturer-id: manufacturer-id })) ERR_MANUFACTURER_EXISTS)

    (map-set manufacturers
      { manufacturer-id: manufacturer-id }
      {
        name: name,
        certification-level: certification-level,
        verified: true,
        registration-date: block-height,
        contact-info: contact-info
      }
    )

    (var-set next-manufacturer-id (+ manufacturer-id u1))
    (ok manufacturer-id)
  )
)

(define-public (certify-equipment
  (manufacturer-id uint)
  (equipment-type (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-some (map-get? manufacturers { manufacturer-id: manufacturer-id })) ERR_MANUFACTURER_NOT_FOUND)

    (map-set manufacturer-equipment
      { manufacturer-id: manufacturer-id, equipment-type: equipment-type }
      { certified: true, certification-date: block-height }
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-manufacturer (manufacturer-id uint))
  (map-get? manufacturers { manufacturer-id: manufacturer-id })
)

(define-read-only (is-equipment-certified (manufacturer-id uint) (equipment-type (string-ascii 50)))
  (default-to false
    (get certified
      (map-get? manufacturer-equipment
        { manufacturer-id: manufacturer-id, equipment-type: equipment-type }
      )
    )
  )
)

(define-read-only (get-next-manufacturer-id)
  (var-get next-manufacturer-id)
)
