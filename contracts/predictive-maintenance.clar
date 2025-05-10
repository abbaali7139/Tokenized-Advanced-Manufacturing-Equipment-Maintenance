;; Predictive Maintenance Contract
;; Schedules service based on usage data

(define-map asset-usage
  {asset-id: uint}
  {runtime-hours: uint,
   cycles-completed: uint,
   last-updated: uint})

(define-map maintenance-schedules
  {asset-id: uint}
  {next-service-date: uint,
   service-interval: uint,
   runtime-threshold: uint,
   cycle-threshold: uint})

(define-public (update-usage-data
                (asset-id uint)
                (runtime-hours uint)
                (cycles-completed uint))
  (let ((existing-data (map-get? asset-usage {asset-id: asset-id}))
        (current-time block-height))
    (begin
      (map-set asset-usage
               {asset-id: asset-id}
               {runtime-hours: (if (is-some existing-data)
                                  (+ runtime-hours (get runtime-hours (unwrap-panic existing-data)))
                                  runtime-hours),
                cycles-completed: (if (is-some existing-data)
                                     (+ cycles-completed (get cycles-completed (unwrap-panic existing-data)))
                                     cycles-completed),
                last-updated: current-time})
      (check-maintenance-triggers asset-id)
      (ok true))))

(define-public (set-maintenance-schedule
                (asset-id uint)
                (next-service-date uint)
                (service-interval uint)
                (runtime-threshold uint)
                (cycle-threshold uint))
  (begin
    (map-set maintenance-schedules
             {asset-id: asset-id}
             {next-service-date: next-service-date,
              service-interval: service-interval,
              runtime-threshold: runtime-threshold,
              cycle-threshold: cycle-threshold})
    (ok true)))

(define-read-only (check-maintenance-triggers (asset-id uint))
  (let ((usage (map-get? asset-usage {asset-id: asset-id}))
        (schedule (map-get? maintenance-schedules {asset-id: asset-id}))
        (current-time block-height))
    (if (and (is-some usage) (is-some schedule))
      (or
        (>= current-time (get next-service-date (unwrap-panic schedule)))
        (>= (get runtime-hours (unwrap-panic usage)) (get runtime-threshold (unwrap-panic schedule)))
        (>= (get cycles-completed (unwrap-panic usage)) (get cycle-threshold (unwrap-panic schedule))))
      false)))

(define-read-only (get-maintenance-due-assets (asset-ids (list 100 uint)))
  (filter check-maintenance-triggers asset-ids))
