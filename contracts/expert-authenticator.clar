;; Expert Authentication Contract
;; Validates assessments by qualified appraisers

(define-map experts
  { address: principal }
  {
    name: (string-utf8 100),
    credentials: (string-utf8 500),
    active: bool
  }
)

(define-map authentications
  { item-id: uint }
  {
    expert: principal,
    verdict: bool,
    notes: (string-utf8 500),
    timestamp: uint
  }
)

(define-data-var admin principal tx-sender)

(define-public (register-expert
    (expert-address principal)
    (name (string-utf8 100))
    (credentials (string-utf8 500)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (map-set experts
      { address: expert-address }
      {
        name: name,
        credentials: credentials,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (authenticate-item
    (item-id uint)
    (verdict bool)
    (notes (string-utf8 500)))
  (let
    ((expert-info (map-get? experts { address: tx-sender })))
    (asserts! (and (is-some expert-info) (get active (unwrap! expert-info (err u404)))) (err u401))
    (map-set authentications
      { item-id: item-id }
      {
        expert: tx-sender,
        verdict: verdict,
        notes: notes,
        timestamp: block-height
      }
    )
    (ok true)
  )
)

(define-read-only (get-authentication (item-id uint))
  (map-get? authentications { item-id: item-id })
)

(define-read-only (is-expert (address principal))
  (is-some (map-get? experts { address: address }))
)
