;; Maintenance History Contract
;; Tracks repairs and servicing

(define-map maintenance-records
  {asset-id: uint, record-id: uint}
  {maintenance-type: (string-ascii 50),
   description: (string-ascii 500),
   date: uint,
   performed-by: principal,
   cost: uint})

(define-map asset-last-record-id
  {asset-id: uint}
  {last-record-id: uint})

(define-public (add-maintenance-record
                (asset-id uint)
                (maintenance-type (string-ascii 50))
                (description (string-ascii 500))
                (date uint)
                (cost uint))
  (let ((last-id-data (map-get? asset-last-record-id {asset-id: asset-id}))
        (next-id (if (is-some last-id-data)
                     (+ (get last-record-id (unwrap-panic last-id-data)) u1)
                     u1)))
    (begin
      (map-set maintenance-records
              {asset-id: asset-id, record-id: next-id}
              {maintenance-type: maintenance-type,
               description: description,
               date: date,
               performed-by: tx-sender,
               cost: cost})
      (map-set asset-last-record-id
              {asset-id: asset-id}
              {last-record-id: next-id})
      (ok next-id))))

(define-read-only (get-maintenance-record (asset-id uint) (record-id uint))
  (map-get? maintenance-records {asset-id: asset-id, record-id: record-id}))

(define-read-only (get-last-record-id (asset-id uint))
  (default-to u0 (get last-record-id (map-get? asset-last-record-id {asset-id: asset-id}))))
