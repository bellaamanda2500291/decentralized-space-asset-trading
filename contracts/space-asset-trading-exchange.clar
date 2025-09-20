;; Space Asset Trading Exchange Contract
;; Facilitates peer-to-peer trading of orbital space assets

;; Error constants  
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-ORDER-NOT-FOUND (err u404))
(define-constant ERR-ASSET-NOT-FOUND (err u405))
(define-constant ERR-INSUFFICIENT-FUNDS (err u406))
(define-constant ERR-ORDER-EXPIRED (err u407))
(define-constant ERR-INVALID-PRICE (err u400))
(define-constant ERR-ASSET-NOT-OWNED (err u403))

;; Contract dependencies
;; Asset registry integration would be implemented via contract calls in production

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Data structures
(define-map trading-orders
  { order-id: (buff 32) }
  {
    seller: principal,
    asset-id: (buff 32),
    price: uint,
    order-type: (string-ascii 8), ;; "sell" or "buy"
    expiry-height: uint,
    status: (string-ascii 16), ;; "active", "filled", "cancelled"
    created-height: uint,
    trade-conditions: (string-ascii 256)
  }
)

(define-map trade-history
  { trade-id: (buff 32) }
  {
    order-id: (buff 32),
    buyer: principal,
    seller: principal,
    asset-id: (buff 32),
    price: uint,
    trade-height: uint,
    settlement-status: (string-ascii 16)
  }
)

(define-map asset-valuations
  { asset-id: (buff 32) }
  {
    last-trade-price: uint,
    market-valuation: uint,
    valuation-height: uint,
    price-history: (list 10 uint)
  }
)

(define-map trading-fees
  { trader: principal }
  {
    total-volume: uint,
    fees-paid: uint,
    discount-tier: uint
  }
)

;; Trading state
(define-data-var next-order-id uint u1)
(define-data-var trading-fee-rate uint u250) ;; 2.5% in basis points
(define-data-var total-trading-volume uint u0)
(define-data-var platform-revenue uint u0)

;; Helper functions
(define-private (generate-order-id (seller principal) (asset-id (buff 32)))
  (keccak256 0x1122334455667788112233445566778811223344556677881122334455667788)
)

(define-private (generate-trade-id (order-id (buff 32)) (buyer principal))
  (keccak256 0x8877665544332211887766554433221188776655443322118877665544332211)
)

(define-private (calculate-trading-fee (price uint))
  (/ (* price (var-get trading-fee-rate)) u10000)
)

(define-private (is-order-expired (expiry-height uint))
  (> u1 expiry-height)
)

;; Public functions
(define-public (create-sell-order
  (asset-id (buff 32))
  (price uint)
  (expiry-duration uint)
  (trade-conditions (string-ascii 256)))
  (let 
    ((order-id (generate-order-id tx-sender asset-id))
     (current-height u1)
     (expiry-height (+ current-height expiry-duration)))
    (asserts! (> price u0) ERR-INVALID-PRICE)
    ;; Note: In a real implementation, we would verify asset ownership through the registry contract
    (asserts! (is-none (map-get? trading-orders { order-id: order-id })) ERR-ORDER-NOT-FOUND)
    (map-set trading-orders
      { order-id: order-id }
      {
        seller: tx-sender,
        asset-id: asset-id,
        price: price,
        order-type: "sell",
        expiry-height: expiry-height,
        status: "active",
        created-height: current-height,
        trade-conditions: trade-conditions
      })
    (ok { order-id: order-id, price: price })))

(define-public (create-buy-order
  (asset-id (buff 32))
  (price uint)
  (expiry-duration uint)
  (trade-conditions (string-ascii 256)))
  (let 
    ((order-id (generate-order-id tx-sender asset-id))
     (current-height u1)
     (expiry-height (+ current-height expiry-duration)))
    (asserts! (> price u0) ERR-INVALID-PRICE)
    (asserts! (>= (stx-get-balance tx-sender) price) ERR-INSUFFICIENT-FUNDS)
    (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
    (map-set trading-orders
      { order-id: order-id }
      {
        seller: tx-sender,
        asset-id: asset-id,
        price: price,
        order-type: "buy",
        expiry-height: expiry-height,
        status: "active",
        created-height: current-height,
        trade-conditions: trade-conditions
      })
    (ok { order-id: order-id, price: price })))

(define-public (execute-sell-order (order-id (buff 32)))
  (let 
    ((order-data (unwrap! (map-get? trading-orders { order-id: order-id }) ERR-ORDER-NOT-FOUND))
     (trade-id (generate-trade-id order-id tx-sender))
     (trading-fee (calculate-trading-fee (get price order-data)))
     (seller-proceeds (- (get price order-data) trading-fee))
     (current-height u1))
    (asserts! (is-eq (get status order-data) "active") ERR-ORDER-NOT-FOUND)
    (asserts! (is-eq (get order-type order-data) "sell") ERR-NOT-AUTHORIZED)
    (asserts! (not (is-order-expired (get expiry-height order-data))) ERR-ORDER-EXPIRED)
    (asserts! (>= (stx-get-balance tx-sender) (get price order-data)) ERR-INSUFFICIENT-FUNDS)
    
    ;; Execute the trade
    (try! (stx-transfer? (get price order-data) tx-sender (get seller order-data)))
    (try! (stx-transfer? trading-fee (get seller order-data) CONTRACT-OWNER))
    
    ;; Update order status
    (map-set trading-orders
      { order-id: order-id }
      (merge order-data { status: "filled" }))
    
    ;; Record trade history
    (map-set trade-history
      { trade-id: trade-id }
      {
        order-id: order-id,
        buyer: tx-sender,
        seller: (get seller order-data),
        asset-id: (get asset-id order-data),
        price: (get price order-data),
        trade-height: current-height,
        settlement-status: "completed"
      })
    
    ;; Update asset valuation
    (map-set asset-valuations
      { asset-id: (get asset-id order-data) }
      {
        last-trade-price: (get price order-data),
        market-valuation: (get price order-data),
        valuation-height: current-height,
        price-history: (list (get price order-data))
      })
    
    ;; Update trading stats
    (var-set total-trading-volume (+ (var-get total-trading-volume) (get price order-data)))
    (var-set platform-revenue (+ (var-get platform-revenue) trading-fee))
    
    (ok { trade-id: trade-id, price: (get price order-data) })))

(define-public (execute-buy-order (order-id (buff 32)) (asset-id (buff 32)))
  (let 
    ((order-data (unwrap! (map-get? trading-orders { order-id: order-id }) ERR-ORDER-NOT-FOUND))
     (trade-id (generate-trade-id order-id tx-sender))
     (trading-fee (calculate-trading-fee (get price order-data)))
     (current-height u1))
    (asserts! (is-eq (get status order-data) "active") ERR-ORDER-NOT-FOUND)
    (asserts! (is-eq (get order-type order-data) "buy") ERR-NOT-AUTHORIZED)
    (asserts! (not (is-order-expired (get expiry-height order-data))) ERR-ORDER-EXPIRED)
    (asserts! (is-eq asset-id (get asset-id order-data)) ERR-ASSET-NOT-FOUND)
    
    ;; Execute the trade - release escrowed funds to seller
    (try! (as-contract (stx-transfer? (- (get price order-data) trading-fee) tx-sender tx-sender)))
    (try! (as-contract (stx-transfer? trading-fee tx-sender CONTRACT-OWNER)))
    
    ;; Update order status
    (map-set trading-orders
      { order-id: order-id }
      (merge order-data { status: "filled" }))
    
    ;; Record trade history
    (map-set trade-history
      { trade-id: trade-id }
      {
        order-id: order-id,
        buyer: (get seller order-data),
        seller: tx-sender,
        asset-id: asset-id,
        price: (get price order-data),
        trade-height: current-height,
        settlement-status: "completed"
      })
    
    (ok { trade-id: trade-id, buyer: (get seller order-data) })))

(define-public (cancel-order (order-id (buff 32)))
  (let 
    ((order-data (unwrap! (map-get? trading-orders { order-id: order-id }) ERR-ORDER-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get seller order-data)) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status order-data) "active") ERR-ORDER-NOT-FOUND)
    
    ;; Refund escrowed funds for buy orders
    (if (is-eq (get order-type order-data) "buy")
      (try! (as-contract (stx-transfer? (get price order-data) tx-sender (get seller order-data))))
      true)
    
    (map-set trading-orders
      { order-id: order-id }
      (merge order-data { status: "cancelled" }))
    
    (ok { order-id: order-id, status: "cancelled" })))

(define-public (update-asset-valuation (asset-id (buff 32)) (new-valuation uint))
  (let 
    ((current-valuation (default-to 
      { last-trade-price: u0, market-valuation: u0, valuation-height: u0, price-history: (list) }
      (map-get? asset-valuations { asset-id: asset-id })))
     (current-height u1))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set asset-valuations
      { asset-id: asset-id }
      (merge current-valuation { 
        market-valuation: new-valuation,
        valuation-height: current-height
      }))
    (ok { asset-id: asset-id, valuation: new-valuation })))

;; Read-only functions
(define-read-only (get-order-info (order-id (buff 32)))
  (map-get? trading-orders { order-id: order-id })
)

(define-read-only (get-trade-info (trade-id (buff 32)))
  (map-get? trade-history { trade-id: trade-id })
)

(define-read-only (get-asset-valuation (asset-id (buff 32)))
  (map-get? asset-valuations { asset-id: asset-id })
)

(define-read-only (get-trading-stats)
  {
    total-volume: (var-get total-trading-volume),
    platform-revenue: (var-get platform-revenue),
    trading-fee-rate: (var-get trading-fee-rate)
  }
)

(define-read-only (get-trader-stats (trader principal))
  (default-to 
    { total-volume: u0, fees-paid: u0, discount-tier: u0 }
    (map-get? trading-fees { trader: trader })
  )
)

;; Administrative functions
(define-public (set-trading-fee-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-rate u1000) ERR-INVALID-PRICE) ;; Max 10%
    (var-set trading-fee-rate new-rate)
    (ok new-rate)))

(define-public (withdraw-platform-revenue (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= amount (var-get platform-revenue)) ERR-INSUFFICIENT-FUNDS)
    (try! (stx-transfer? amount (as-contract tx-sender) CONTRACT-OWNER))
    (var-set platform-revenue (- (var-get platform-revenue) amount))
    (ok amount)))