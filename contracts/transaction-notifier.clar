;; transaction-notifier
;; A Clarity smart contract for tracking and notifying transaction events 
;; across different applications and game environments.

;; =================================
;; Error Constants
;; =================================

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-EVENT-ALREADY-REGISTERED (err u101))
(define-constant ERR-EVENT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-EVENT-TYPE (err u103))

;; =================================
;; Data Structures
;; =================================

;; Contract administrator
(define-data-var contract-owner principal tx-sender)

;; Event registry to track unique transaction events
(define-map transaction-events
  { event-id: (string-ascii 50) }
  {
    event-type: (string-ascii 50),
    source-app: (string-ascii 100),
    description: (string-utf8 500),
    created-by: principal,
    created-at: uint,
    metadata: (optional (string-utf8 1000))
  }
)

;; Event subscriptions for notifications
(define-map event-subscribers
  { event-id: (string-ascii 50), subscriber: principal }
  {
    subscribed-at: uint,
    active: bool
  }
)

;; =================================
;; Private Functions
;; =================================

;; Checks if the caller is the contract owner
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; =================================
;; Read-Only Functions
;; =================================

;; Get transaction event details
(define-read-only (get-transaction-event (event-id (string-ascii 50)))
  (map-get? transaction-events { event-id: event-id })
)

;; Check if a subscriber is registered for an event
(define-read-only (is-event-subscriber (event-id (string-ascii 50)) (subscriber principal))
  (match (map-get? event-subscribers { event-id: event-id, subscriber: subscriber })
    subscription (get active subscription)
    false
  )
)

;; =================================
;; Public Functions
;; =================================

;; Set a new contract owner
(define-public (set-contract-owner (new-owner principal))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (ok (var-set contract-owner new-owner))
  )
)

;; Register a new transaction event
(define-public (register-transaction-event
  (event-id (string-ascii 50))
  (event-type (string-ascii 50))
  (source-app (string-ascii 100))
  (description (string-utf8 500))
  (metadata (optional (string-utf8 1000)))
)
  (begin
    ;; Validate event type
    (asserts! 
      (or 
        (is-eq event-type "transfer") 
        (is-eq event-type "interaction")
        (is-eq event-type "conversion")
      ) 
      ERR-INVALID-EVENT-TYPE
    )

    ;; Check if event already exists
    (asserts! 
      (is-none (map-get? transaction-events { event-id: event-id })) 
      ERR-EVENT-ALREADY-REGISTERED
    )
    
    ;; Register the event
    (map-set transaction-events
      { event-id: event-id }
      {
        event-type: event-type,
        source-app: source-app,
        description: description,
        created-by: tx-sender,
        created-at: block-height,
        metadata: metadata
      }
    )
    
    (ok true)
  )
)

;; Subscribe to a transaction event
(define-public (subscribe-to-event 
  (event-id (string-ascii 50))
)
  (begin
    ;; Verify event exists
    (asserts! 
      (is-some (map-get? transaction-events { event-id: event-id })) 
      ERR-EVENT-NOT-FOUND
    )
    
    ;; Subscribe to the event
    (map-set event-subscribers
      { event-id: event-id, subscriber: tx-sender }
      {
        subscribed-at: block-height,
        active: true
      }
    )
    
    (ok true)
  )
)

;; Unsubscribe from a transaction event
(define-public (unsubscribe-from-event 
  (event-id (string-ascii 50))
)
  (begin
    ;; Verify event exists
    (asserts! 
      (is-some (map-get? transaction-events { event-id: event-id })) 
      ERR-EVENT-NOT-FOUND
    )
    
    ;; Unsubscribe from the event
    (map-set event-subscribers
      { event-id: event-id, subscriber: tx-sender }
      {
        subscribed-at: block-height,
        active: false
      }
    )
    
    (ok true)
  )
)