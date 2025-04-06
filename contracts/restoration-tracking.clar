;; Restoration Tracking Contract
;; Documents repairs and conservation efforts

(define-map restorations
  { item-id: uint, restoration-id: uint }
  {
    restorer: principal,
    description: (string-utf8 500),
    date-started: uint,
    date-completed: uint,
    techniques-used: (string-utf8 500),
    materials-used: (string-utf8 500)
  }
)

(define-map restoration-counts
  { item-id: uint }
  { count: uint }
)

(define-map approved-restorers
  { address: principal }
  {
    name: (string-utf8 100),
    credentials: (string-utf8 500),
    active: bool
  }
)

(define-data-var admin principal tx-sender)

(define-public (register-restorer
    (restorer-address principal)
    (name (string-utf8 100))
    (credentials (string-utf8 500)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set approved-restorers
      { address: restorer-address }
      {
        name: name,
        credentials: credentials,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (record-restoration
    (item-id uint)
    (description (string-utf8 500))
    (date-started uint)
    (date-completed uint)
    (techniques-used (string-utf8 500))
    (materials-used (string-utf8 500)))
  (let
    (
      (restorer-info (map-get? approved-restorers { address: tx-sender }))
      (count-data (default-to { count: u0 } (map-get? restoration-counts { item-id: item-id })))
      (current-count (get count count-data))
      (new-count (+ current-count u1))
    )
    (asserts! (and (is-some restorer-info) (get active (unwrap! restorer-info (err u404)))) (err u401))

    ;; Record the restoration
    (map-set restorations
      { item-id: item-id, restoration-id: new-count }
      {
        restorer: tx-sender,
        description: description,
        date-started: date-started,
        date-completed: date-completed,
        techniques-used: techniques-used,
        materials-used: materials-used
      }
    )

    ;; Update count
    (map-set restoration-counts
      { item-id: item-id }
      { count: new-count }
    )

    (ok new-count)
  )
)

(define-read-only (get-restoration (item-id uint) (restoration-id uint))
  (map-get? restorations { item-id: item-id, restoration-id: restoration-id })
)

(define-read-only (get-restoration-count (item-id uint))
  (default-to { count: u0 } (map-get? restoration-counts { item-id: item-id }))
)

(define-read-only (is-approved-restorer (address principal))
  (is-some (map-get? approved-restorers { address: address }))
)
