(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-score (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-insufficient-reputation (err u105))

(define-data-var reputation-threshold uint u50)
(define-data-var decay-rate uint u1)
(define-data-var decay-interval uint u144)

(define-map users
    principal
    {
        reputation-score: uint,
        total-interactions: uint,
        positive-feedbacks: uint,
        negative-feedbacks: uint,
        sectors: (list 10 (string-ascii 20)),
        registered-at: uint,
        is-verified: bool,
        last-activity: uint
    }
)

(define-map sector-reputation
    { user: principal, sector: (string-ascii 20) }
    {
        score: uint,
        interactions: uint,
        last-updated: uint
    }
)

(define-map verifiers
    principal
    {
        is-active: bool,
        verifications-count: uint,
        sectors: (list 10 (string-ascii 20))
    }
)

(define-map interactions
    uint
    {
        from-user: principal,
        to-user: principal,
        sector: (string-ascii 20),
        score-change: int,
        verified: bool,
        timestamp: uint,
        verifier: (optional principal)
    }
)

(define-data-var interaction-nonce uint u0)

(define-read-only (get-user-reputation (user principal))
    (ok (map-get? users user))
)

(define-read-only (get-sector-reputation (user principal) (sector (string-ascii 20)))
    (ok (map-get? sector-reputation { user: user, sector: sector }))
)

(define-read-only (get-verifier-info (verifier principal))
    (ok (map-get? verifiers verifier))
)

(define-read-only (get-interaction (interaction-id uint))
    (ok (map-get? interactions interaction-id))
)

(define-read-only (get-reputation-threshold)
    (ok (var-get reputation-threshold))
)

(define-read-only (is-user-verified (user principal))
    (ok (default-to false 
        (get is-verified (map-get? users user))
    ))
)

(define-public (register-user (sectors (list 10 (string-ascii 20))))
    (let
        (
            (caller tx-sender)
            (existing-user (map-get? users caller))
        )
        (asserts! (is-none existing-user) err-already-exists)
        (ok (map-set users caller {
            reputation-score: u0,
            total-interactions: u0,
            positive-feedbacks: u0,
            negative-feedbacks: u0,
            sectors: sectors,
            registered-at: stacks-block-height,
            is-verified: false,
            last-activity: stacks-block-height
        }))
    )
)

(define-public (register-verifier (sectors (list 10 (string-ascii 20))))
    (let
        (
            (caller tx-sender)
        )
        (asserts! (is-eq caller contract-owner) err-owner-only)
        (ok (map-set verifiers tx-sender {
            is-active: true,
            verifications-count: u0,
            sectors: sectors
        }))
    )
)

(define-public (add-verifier (verifier principal) (sectors (list 10 (string-ascii 20))))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set verifiers verifier {
            is-active: true,
            verifications-count: u0,
            sectors: sectors
        }))
    )
)

(define-public (record-interaction (to-user principal) (sector (string-ascii 20)) (score-change int))
    (let
        (
            (caller tx-sender)
            (from-user-data (unwrap! (map-get? users caller) err-not-found))
            (to-user-data (unwrap! (map-get? users to-user) err-not-found))
            (current-nonce (var-get interaction-nonce))
        )
        (map-set interactions current-nonce {
            from-user: caller,
            to-user: to-user,
            sector: sector,
            score-change: score-change,
            verified: false,
            timestamp: stacks-block-height,
            verifier: none
        })
        (var-set interaction-nonce (+ current-nonce u1))
        (ok current-nonce)
    )
)

(define-public (verify-interaction (interaction-id uint))
    (let
        (
            (caller tx-sender)
            (verifier-data (unwrap! (map-get? verifiers caller) err-unauthorized))
            (interaction-data (unwrap! (map-get? interactions interaction-id) err-not-found))
            (to-user (get to-user interaction-data))
            (sector (get sector interaction-data))
            (score-change (get score-change interaction-data))
            (user-data (unwrap! (map-get? users to-user) err-not-found))
            (sector-data (default-to 
                { score: u0, interactions: u0, last-updated: u0 }
                (map-get? sector-reputation { user: to-user, sector: sector })
            ))
        )
        (asserts! (get is-active verifier-data) err-unauthorized)
        (asserts! (not (get verified interaction-data)) err-already-exists)
        
        (map-set interactions interaction-id
            (merge interaction-data { 
                verified: true, 
                verifier: (some caller) 
            })
        )
        
        (let
            (
                (new-score (if (> score-change 0)
                    (+ (get reputation-score user-data) (to-uint score-change))
                    (if (>= (get reputation-score user-data) (to-uint (* score-change -1)))
                        (- (get reputation-score user-data) (to-uint (* score-change -1)))
                        u0
                    )
                ))
                (new-positive (if (> score-change 0) 
                    (+ (get positive-feedbacks user-data) u1)
                    (get positive-feedbacks user-data)
                ))
                (new-negative (if (< score-change 0)
                    (+ (get negative-feedbacks user-data) u1)
                    (get negative-feedbacks user-data)
                ))
            )
            (map-set users to-user
                (merge user-data {
                    reputation-score: new-score,
                    total-interactions: (+ (get total-interactions user-data) u1),
                    positive-feedbacks: new-positive,
                    negative-feedbacks: new-negative,
                    last-activity: stacks-block-height
                })
            )
            
            (map-set sector-reputation { user: to-user, sector: sector }
                {
                    score: (if (> score-change 0)
                        (+ (get score sector-data) (to-uint score-change))
                        (if (>= (get score sector-data) (to-uint (* score-change -1)))
                            (- (get score sector-data) (to-uint (* score-change -1)))
                            u0
                        )
                    ),
                    interactions: (+ (get interactions sector-data) u1),
                    last-updated: stacks-block-height
                }
            )
            
            (map-set verifiers caller
                (merge verifier-data {
                    verifications-count: (+ (get verifications-count verifier-data) u1)
                })
            )
        )
        (ok true)
    )
)

(define-public (verify-user (user principal))
    (let
        (
            (caller tx-sender)
            (user-data (unwrap! (map-get? users user) err-not-found))
        )
        (asserts! (is-eq caller contract-owner) err-owner-only)
        (asserts! (>= (get reputation-score user-data) (var-get reputation-threshold)) err-insufficient-reputation)
        (ok (map-set users user
            (merge user-data { is-verified: true })
        ))
    )
)

(define-public (update-reputation-threshold (new-threshold uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set reputation-threshold new-threshold))
    )
)

(define-public (deactivate-verifier (verifier principal))
    (let
        (
            (verifier-data (unwrap! (map-get? verifiers verifier) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set verifiers verifier
            (merge verifier-data { is-active: false })
        ))
    )
)

(define-public (activate-verifier (verifier principal))
    (let
        (
            (verifier-data (unwrap! (map-get? verifiers verifier) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set verifiers verifier
            (merge verifier-data { is-active: true })
        ))
    )
)

(define-read-only (calculate-reputation-decay (user principal))
    (let
        (
            (user-data (unwrap! (map-get? users user) err-not-found))
            (current-score (get reputation-score user-data))
            (last-active (get last-activity user-data))
            (blocks-inactive (- stacks-block-height last-active))
            (decay-periods (/ blocks-inactive (var-get decay-interval)))
            (total-decay (* decay-periods (var-get decay-rate)))
        )
        (ok {
            current-score: current-score,
            decay-amount: total-decay,
            new-score: (if (>= current-score total-decay)
                (- current-score total-decay)
                u0
            ),
            blocks-inactive: blocks-inactive
        })
    )
)

(define-public (apply-reputation-decay (user principal))
    (let
        (
            (user-data (unwrap! (map-get? users user) err-not-found))
            (decay-info (unwrap! (calculate-reputation-decay user) err-not-found))
            (new-score (get new-score decay-info))
        )
        (ok (map-set users user
            (merge user-data {
                reputation-score: new-score,
                last-activity: stacks-block-height
            })
        ))
    )
)

(define-public (update-decay-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set decay-rate new-rate))
    )
)

(define-public (update-decay-interval (new-interval uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set decay-interval new-interval))
    )
)

(define-read-only (get-decay-config)
    (ok {
        decay-rate: (var-get decay-rate),
        decay-interval: (var-get decay-interval)
    })
)
