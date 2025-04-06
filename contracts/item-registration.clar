;; Item Registration Contract
;; Records details of antique objects

(define-data-var last-item-id uint u0)

(define-map items
  { item-id: uint }
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    creation-date: (string-utf8 50),
    creator: (string-utf8 100),
    registered-by: principal,
    registration-date: uint
  }
)

(define-public (register-item
    (name (string-utf8 100))
    (description (string-utf8 500))
    (creation-date (string-utf8 50))
    (creator (string-utf8 100)))
  (let
    (
      (new-id (+ (var-get last-item-id) u1))
    )
    (var-set last-item-id new-id)
    (map-set items
      { item-id: new-id }
      {
        name: name,
        description: description,
        creation-date: creation-date,
        creator: creator,
        registered-by: tx-sender,
        registration-date: block-height
      }
    )
    (ok new-id)
  )
)

(define-read-only (get-item (item-id uint))
  (map-get? items { item-id: item-id })
)

(define-read-only (get-last-item-id)
  (var-get last-item-id)
)
