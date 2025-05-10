;; Performance Analytics Contract
;; Tracks equipment reliability metrics

(define-map reliability-metrics
  {asset-id: uint}
  {uptime-percentage: uint,
   downtime-hours: uint,
   failure-count: uint,
   mean-time-between-failures: uint,
   last-failure-date: uint})

(define-map performance-data
  {asset-id: uint, entry-id: uint}
  {date: uint,
   produced-units: uint,
   energy-consumption: uint,
   defect-rate: uint})

(define-map asset-performance-entry-count
  {asset-id: uint}
  {count: uint})

(define-public (record-failure
                (asset-id uint)
                (downtime-hours uint))
  (let ((metrics (map-get? reliability-metrics {asset-id: asset-id}))
        (current-time block-height))
    (if (is-some metrics)
      (let ((existing (unwrap-panic metrics))
            (new-failure-count (+ (get failure-count existing) u1))
            (new-downtime (+ (get downtime-hours existing) downtime-hours))
            (mtbf (if (> (get last-failure-date existing) u0)
                     (/ (- current-time (get last-failure-date existing)) (* u24 u3600))
                     u0)))
        (begin
          (map-set reliability-metrics
                  {asset-id: asset-id}
                  {uptime-percentage: (calculate-uptime new-downtime (get-asset-age asset-id)),
                   downtime-hours: new-downtime,
                   failure-count: new-failure-count,
                   mean-time-between-failures: (if (> mtbf u0) mtbf (get mean-time-between-failures existing)),
                   last-failure-date: current-time})
          (ok true)))
      (begin
        (map-set reliability-metrics
                {asset-id: asset-id}
                {uptime-percentage: u100,
                 downtime-hours: downtime-hours,
                 failure-count: u1,
                 mean-time-between-failures: u0,
                 last-failure-date: current-time})
        (ok true)))))

(define-public (add-performance-data
                (asset-id uint)
                (produced-units uint)
                (energy-consumption uint)
                (defect-rate uint))
  (let ((entry-count-data (map-get? asset-performance-entry-count {asset-id: asset-id}))
        (next-id (if (is-some entry-count-data)
                     (+ (get count (unwrap-panic entry-count-data)) u1)
                     u1)))
    (begin
      (map-set performance-data
              {asset-id: asset-id, entry-id: next-id}
              {date: block-height,
               produced-units: produced-units,
               energy-consumption: energy-consumption,
               defect-rate: defect-rate})
      (map-set asset-performance-entry-count
              {asset-id: asset-id}
              {count: next-id})
      (ok next-id))))

(define-read-only (get-reliability-metrics (asset-id uint))
  (map-get? reliability-metrics {asset-id: asset-id}))

(define-read-only (get-performance-data (asset-id uint) (entry-id uint))
  (map-get? performance-data {asset-id: asset-id, entry-id: entry-id}))

(define-read-only (calculate-uptime (downtime-hours uint) (asset-age-hours uint))
  (if (> asset-age-hours u0)
    (* (/ (- asset-age-hours downtime-hours) asset-age-hours) u100)
    u100))

(define-read-only (get-asset-age (asset-id uint))
  (let ((current-time block-height)
        ;; Note: This would need to pull from the asset registration contract in a real implementation
        ;; This is a simplified version assuming we know when the asset was installed
        (install-time u0))
    (/ (- current-time install-time) (* u24 u3600))))
