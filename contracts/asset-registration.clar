;; Asset Registration Contract
;; Records details of industrial machinery

(define-data-var last-asset-id uint u0)

(define-map assets
  {asset-id: uint}
  {name: (string-ascii 100),
   manufacturer: (string-ascii 100),
   model: (string-ascii 100),
   serial-number: (string-ascii 100),
   installation-date: uint,
   expected-lifetime: uint,
   owner: principal})

(define-public (register-asset
                (name (string-ascii 100))
                (manufacturer (string-ascii 100))
                (model (string-ascii 100))
                (serial-number (string-ascii 100))
                (installation-date uint)
                (expected-lifetime uint))
  (let ((new-id (+ (var-get last-asset-id) u1)))
    (begin
      (map-set assets
               {asset-id: new-id}
               {name: name,
                manufacturer: manufacturer,
                model: model,
                serial-number: serial-number,
                installation-date: installation-date,
                expected-lifetime: expected-lifetime,
                owner: tx-sender})
      (var-set last-asset-id new-id)
      (ok new-id))))

(define-read-only (get-asset (asset-id uint))
  (map-get? assets {asset-id: asset-id}))

(define-public (transfer-asset (asset-id uint) (new-owner principal))
  (let ((asset (map-get? assets {asset-id: asset-id})))
    (if (and (is-some asset) (is-eq tx-sender (get owner (unwrap-panic asset))))
      (begin
        (map-set assets
                 {asset-id: asset-id}
                 (merge (unwrap-panic asset) {owner: new-owner}))
        (ok true))
      (err u403))))
