;; Ownership History Contract
;; Tracks provenance and chain of possession

(define-map current-owners
  { item-id: uint }
  { owner: principal }
)

(define-map ownership-records
  { item-id: uint, index: uint }
  {
    previous-owner: principal,
    new-owner: principal,
    transfer-date: uint,
    transaction-details: (string-utf8 500)
  }
)

(define-map ownership-indices
  { item-id: uint }
  { last-index: uint }
)

(define-public (register-initial-owner (item-id uint) (owner principal))
  (begin
    (map-set current-owners
      { item-id: item-id }
      { owner: owner }
    )
    (map-set ownership-indices
      { item-id: item-id }
      { last-index: u0 }
    )
    (ok true)
  )
)

(define-public (transfer-ownership
    (item-id uint)
    (new-owner principal)
    (transaction-details (string-utf8 500)))
  (let
    (
      (current-owner-data (unwrap! (map-get? current-owners { item-id: item-id }) (err u404)))
      (current-owner (get owner current-owner-data))
      (index-data (default-to { last-index: u0 } (map-get? ownership-indices { item-id: item-id })))
      (current-index (get last-index index-data))
      (new-index (+ current-index u1))
    )
    (asserts! (is-eq tx-sender current-owner) (err u403))

    ;; Record the transfer
    (map-set ownership-records
      { item-id: item-id, index: new-index }
      {
        previous-owner: current-owner,
        new-owner: new-owner,
        transfer-date: block-height,
        transaction-details: transaction-details
      }
    )

    ;; Update current owner
    (map-set current-owners
      { item-id: item-id }
      { owner: new-owner }
    )

    ;; Update index
    (map-set ownership-indices
      { item-id: item-id }
      { last-index: new-index }
    )

    (ok true)
  )
)

(define-read-only (get-current-owner (item-id uint))
  (map-get? current-owners { item-id: item-id })
)

(define-read-only (get-ownership-record (item-id uint) (index uint))
  (map-get? ownership-records { item-id: item-id, index: index })
)

(define-read-only (get-last-transfer-index (item-id uint))
  (default-to { last-index: u0 } (map-get? ownership-indices { item-id: item-id }))
)
