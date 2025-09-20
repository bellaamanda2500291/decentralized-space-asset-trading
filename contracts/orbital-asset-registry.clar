;; Orbital Asset Registry Contract
;; Manages registration and ownership of space-based assets

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-ASSET-EXISTS (err u402))
(define-constant ERR-ASSET-NOT-FOUND (err u404))
(define-constant ERR-INVALID-COORDINATES (err u400))
(define-constant ERR-TRANSFER-FAILED (err u405))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Data structures
(define-map orbital-assets
  { asset-id: (buff 32) }
  {
    owner: principal,
    asset-type: (string-ascii 32),
    orbital-coordinates: { x: int, y: int, z: int },
    mass-kg: uint,
    launch-date: uint,
    operational-status: (string-ascii 16),
    registration-height: uint,
    metadata: (string-ascii 256)
  }
)

(define-map asset-ownership
  { owner: principal, asset-id: (buff 32) }
  { 
    acquired-height: uint,
    transfer-restrictions: (string-ascii 128)
  }
)

(define-map orbital-zones
  { zone-id: (buff 32) }
  {
    zone-name: (string-ascii 64),
    coordinates-bounds: { min-x: int, max-x: int, min-y: int, max-y: int, min-z: int, max-z: int },
    regulatory-authority: principal,
    zone-type: (string-ascii 32),
    access-fee: uint
  }
)

;; Asset registration tracking
(define-data-var next-asset-id uint u1)
(define-data-var registration-fee uint u1000000) ;; 1 STX in microstacks
(define-data-var total-registered-assets uint u0)

;; Helper functions
(define-private (generate-asset-id (owner principal) (asset-type (string-ascii 32)))
  (keccak256 0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef)
)

(define-private (generate-zone-id (zone-name (string-ascii 64)))
  (keccak256 0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321)
)

(define-private (validate-coordinates (coords { x: int, y: int, z: int }))
  (and 
    (>= (get x coords) -1000000)
    (<= (get x coords) 1000000)
    (>= (get y coords) -1000000)
    (<= (get y coords) 1000000)
    (>= (get z coords) -1000000)
    (<= (get z coords) 1000000)
  )
)

;; Public functions
(define-public (register-orbital-asset 
  (asset-type (string-ascii 32))
  (orbital-coordinates { x: int, y: int, z: int })
  (mass-kg uint)
  (launch-date uint)
  (operational-status (string-ascii 16))
  (metadata (string-ascii 256)))
  (let 
    ((asset-id (generate-asset-id tx-sender asset-type))
     (current-height u1))
    (asserts! (validate-coordinates orbital-coordinates) ERR-INVALID-COORDINATES)
    (asserts! (is-none (map-get? orbital-assets { asset-id: asset-id })) ERR-ASSET-EXISTS)
    (try! (stx-transfer? (var-get registration-fee) tx-sender CONTRACT-OWNER))
    (map-set orbital-assets
      { asset-id: asset-id }
      {
        owner: tx-sender,
        asset-type: asset-type,
        orbital-coordinates: orbital-coordinates,
        mass-kg: mass-kg,
        launch-date: launch-date,
        operational-status: operational-status,
        registration-height: current-height,
        metadata: metadata
      })
    (map-set asset-ownership
      { owner: tx-sender, asset-id: asset-id }
      {
        acquired-height: current-height,
        transfer-restrictions: "none"
      })
    (var-set total-registered-assets (+ (var-get total-registered-assets) u1))
    (ok { asset-id: asset-id })))

(define-public (transfer-asset (asset-id (buff 32)) (new-owner principal))
  (let 
    ((asset-data (unwrap! (map-get? orbital-assets { asset-id: asset-id }) ERR-ASSET-NOT-FOUND))
     (current-height u1))
    (asserts! (is-eq tx-sender (get owner asset-data)) ERR-NOT-AUTHORIZED)
    (map-delete asset-ownership { owner: tx-sender, asset-id: asset-id })
    (map-set orbital-assets
      { asset-id: asset-id }
      (merge asset-data { owner: new-owner }))
    (map-set asset-ownership
      { owner: new-owner, asset-id: asset-id }
      {
        acquired-height: current-height,
        transfer-restrictions: "none"
      })
    (ok { asset-id: asset-id, new-owner: new-owner })))

(define-public (update-operational-status (asset-id (buff 32)) (new-status (string-ascii 16)))
  (let 
    ((asset-data (unwrap! (map-get? orbital-assets { asset-id: asset-id }) ERR-ASSET-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner asset-data)) ERR-NOT-AUTHORIZED)
    (map-set orbital-assets
      { asset-id: asset-id }
      (merge asset-data { operational-status: new-status }))
    (ok { asset-id: asset-id, status: new-status })))

(define-public (register-orbital-zone 
  (zone-name (string-ascii 64))
  (coordinates-bounds { min-x: int, max-x: int, min-y: int, max-y: int, min-z: int, max-z: int })
  (zone-type (string-ascii 32))
  (access-fee uint))
  (let 
    ((zone-id (generate-zone-id zone-name)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-none (map-get? orbital-zones { zone-id: zone-id })) ERR-ASSET-EXISTS)
    (map-set orbital-zones
      { zone-id: zone-id }
      {
        zone-name: zone-name,
        coordinates-bounds: coordinates-bounds,
        regulatory-authority: tx-sender,
        zone-type: zone-type,
        access-fee: access-fee
      })
    (ok { zone-id: zone-id })))

(define-public (update-asset-coordinates (asset-id (buff 32)) (new-coordinates { x: int, y: int, z: int }))
  (let 
    ((asset-data (unwrap! (map-get? orbital-assets { asset-id: asset-id }) ERR-ASSET-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get owner asset-data)) ERR-NOT-AUTHORIZED)
    (asserts! (validate-coordinates new-coordinates) ERR-INVALID-COORDINATES)
    (map-set orbital-assets
      { asset-id: asset-id }
      (merge asset-data { orbital-coordinates: new-coordinates }))
    (ok { asset-id: asset-id, coordinates: new-coordinates })))

;; Read-only functions
(define-read-only (get-asset-info (asset-id (buff 32)))
  (map-get? orbital-assets { asset-id: asset-id })
)

(define-read-only (get-asset-ownership (owner principal) (asset-id (buff 32)))
  (map-get? asset-ownership { owner: owner, asset-id: asset-id })
)

(define-read-only (get-orbital-zone (zone-id (buff 32)))
  (map-get? orbital-zones { zone-id: zone-id })
)

(define-read-only (get-registration-fee)
  (var-get registration-fee)
)

(define-read-only (get-total-registered-assets)
  (var-get total-registered-assets)
)

(define-read-only (is-asset-owner (asset-id (buff 32)) (user principal))
  (match (map-get? orbital-assets { asset-id: asset-id })
    asset-data (is-eq user (get owner asset-data))
    false
  )
)

;; Administrative functions
(define-public (set-registration-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set registration-fee new-fee)
    (ok new-fee)))

(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (try! (stx-transfer? amount (as-contract tx-sender) CONTRACT-OWNER))
    (ok amount)))