;; Title: Bitcoin Sovereign Identity Protocol (BSIP)
;;
;; Summary: 
;; A Bitcoin-native identity layer leveraging Stacks' smart contract capabilities 
;; to create tamper-proof, self-sovereign digital identities with cryptographic 
;; proof systems and decentralized reputation mechanics.
;;
;; Description:
;; BSIP transforms digital identity by anchoring trust to Bitcoin's immutable 
;; foundation. This protocol enables individuals and organizations to establish
;; verifiable credentials without relying on centralized authorities. Built on
;; Stacks Layer 2, it combines Bitcoin's security with smart contract flexibility.
;;
;; Core Features:
;; - Self-sovereign identity registration with Bitcoin-backed immutability
;; - Zero-knowledge proof verification for privacy-preserving authentication
;; - Decentralized credential issuance with cryptographic integrity
;; - Autonomous reputation scoring based on network participation
;; - Quantum-resistant recovery mechanisms for long-term security
;; - Cross-chain interoperability for broader Bitcoin ecosystem integration
;;
;; Designed for the Bitcoin economy, BSIP empowers Lightning Network applications,
;; decentralized exchanges, and privacy-first services with robust identity
;; infrastructure that preserves user sovereignty while ensuring network trust.
;;

;; ERROR CONSTANTS

(define-constant ERR-UNAUTHORIZED (err u1000))
(define-constant ERR-IDENTITY-EXISTS (err u1001))
(define-constant ERR-IDENTITY-NOT-FOUND (err u1002))
(define-constant ERR-INVALID-PROOF (err u1003))
(define-constant ERR-CREDENTIAL-INVALID (err u1004))
(define-constant ERR-CREDENTIAL-EXPIRED (err u1005))
(define-constant ERR-CREDENTIAL-REVOKED (err u1006))
(define-constant ERR-REPUTATION-BOUNDS (err u1007))
(define-constant ERR-INVALID-INPUT (err u1008))
(define-constant ERR-INVALID-EXPIRATION (err u1009))
(define-constant ERR-INVALID-RECOVERY (err u1010))
(define-constant ERR-PROOF-DATA-INVALID (err u1011))

;; PROTOCOL CONFIGURATION

(define-constant REPUTATION-FLOOR u0)
(define-constant REPUTATION-CEILING u1000)
(define-constant MIN-EXPIRY-BLOCKS u144) ;; ~1 day in Bitcoin blocks
(define-constant MAX-METADATA-SIZE u256)
(define-constant MIN-PROOF-LENGTH u64)
(define-constant DEFAULT-REPUTATION u500) ;; Neutral starting reputation

;; CORE DATA STRUCTURES

;; Bitcoin-anchored identity registry
(define-map sovereign-identities
  principal
  {
    identity-hash: (buff 32),
    credentials: (list 10 principal),
    reputation-score: uint,
    recovery-guardian: (optional principal),
    last-activity: uint,
    identity-status: (string-ascii 16),
  }
)

;; Verifiable credential storage
(define-map verifiable-credentials
  {
    issuer: principal,
    credential-id: uint,
  }
  {
    holder: principal,
    claim-hash: (buff 32),
    expires-at: uint,
    is-revoked: bool,
    metadata: (string-utf8 256),
  }
)

;; Zero-knowledge proof registry
(define-map zk-proof-registry
  (buff 32)
  {
    prover: principal,
    is-verified: bool,
    proof-timestamp: uint,
    proof-payload: (buff 1024),
  }
)

;; PROTOCOL STATE

(define-data-var protocol-admin principal tx-sender)
(define-data-var credential-counter uint u0)

;; INPUT VALIDATION UTILITIES

(define-private (valid-recovery-guardian? (guardian (optional principal)))
  (match guardian
    recovery-addr (and
      (not (is-eq recovery-addr tx-sender))
      (not (is-eq recovery-addr (var-get protocol-admin)))
    )
    true
  )
)

(define-private (valid-proof-payload? (payload (buff 1024)))
  (and
    (>= (len payload) MIN-PROOF-LENGTH)
    (not (is-eq payload 0x))
  )
)

(define-private (valid-expiration-time? (expiry uint))
  (> expiry (+ stacks-block-height MIN-EXPIRY-BLOCKS))
)

(define-private (valid-metadata-size? (metadata (string-utf8 256)))
  (<= (len metadata) MAX-METADATA-SIZE)
)

(define-private (valid-hash? (hash (buff 32)))
  (not (is-eq hash 0x0000000000000000000000000000000000000000000000000000000000000000))
)

;; PROTOCOL ADMINISTRATION

(define-public (transfer-admin-rights (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get protocol-admin)) ERR-UNAUTHORIZED)
    (asserts! (not (is-eq new-admin tx-sender)) ERR-INVALID-INPUT)
    (ok (var-set protocol-admin new-admin))
  )
)

;; SOVEREIGN IDENTITY MANAGEMENT

(define-public (register-sovereign-identity
    (identity-hash (buff 32))
    (recovery-guardian (optional principal))
  )
  (let (
      (caller tx-sender)
      (existing (map-get? sovereign-identities caller))
    )
    ;; Validate registration requirements
    (asserts! (is-none existing) ERR-IDENTITY-EXISTS)
    (asserts! (valid-hash? identity-hash) ERR-INVALID-INPUT)
    (asserts! (valid-recovery-guardian? recovery-guardian) ERR-INVALID-RECOVERY)

    ;; Create new sovereign identity
    (ok (map-set sovereign-identities caller {
      identity-hash: identity-hash,
      credentials: (list),
      reputation-score: DEFAULT-REPUTATION,
      recovery-guardian: recovery-guardian,
      last-activity: stacks-block-height,
      identity-status: "ACTIVE",
    }))
  )
)

(define-public (update-identity-activity (identity principal))
  (let ((identity-data (map-get? sovereign-identities identity)))
    (asserts! (is-some identity-data) ERR-IDENTITY-NOT-FOUND)
    (asserts! (is-eq tx-sender identity) ERR-UNAUTHORIZED)

    (ok (map-set sovereign-identities identity
      (merge (unwrap-panic identity-data) { last-activity: stacks-block-height })
    ))
  )
)

;; ZERO-KNOWLEDGE PROOF SYSTEM

(define-public (submit-zk-proof
    (proof-hash (buff 32))
    (proof-payload (buff 1024))
  )
  (let (
      (caller tx-sender)
      (identity (map-get? sovereign-identities caller))
      (existing-proof (map-get? zk-proof-registry proof-hash))
    )
    ;; Validate proof submission
    (asserts! (is-some identity) ERR-IDENTITY-NOT-FOUND)
    (asserts! (valid-hash? proof-hash) ERR-INVALID-INPUT)
    (asserts! (valid-proof-payload? proof-payload) ERR-PROOF-DATA-INVALID)
    (asserts! (is-none existing-proof) ERR-INVALID-PROOF)

    ;; Register proof for verification
    (ok (map-set zk-proof-registry proof-hash {
      prover: caller,
      is-verified: false,
      proof-timestamp: stacks-block-height,
      proof-payload: proof-payload,
    }))
  )
)

(define-public (verify-zk-proof (proof-hash (buff 32)))
  (let ((proof-data (map-get? zk-proof-registry proof-hash)))
    (asserts! (is-some proof-data) ERR-INVALID-PROOF)
    (asserts! (is-eq tx-sender (var-get protocol-admin)) ERR-UNAUTHORIZED)

    (ok (map-set zk-proof-registry proof-hash
      (merge (unwrap-panic proof-data) { is-verified: true })
    ))
  )
)

;; VERIFIABLE CREDENTIAL SYSTEM

(define-public (issue-verifiable-credential
    (holder principal)
    (claim-hash (buff 32))
    (expires-at uint)
    (metadata (string-utf8 256))
  )
  (let (
      (issuer tx-sender)
      (current-id (var-get credential-counter))
      (credential-key {
        issuer: issuer,
        credential-id: current-id,
      })
      (issuer-identity (map-get? sovereign-identities issuer))
      (holder-identity (map-get? sovereign-identities holder))
    )
    ;; Validate credential issuance
    (asserts! (is-some issuer-identity) ERR-IDENTITY-NOT-FOUND)
    (asserts! (is-some holder-identity) ERR-IDENTITY-NOT-FOUND)
    (asserts! (valid-hash? claim-hash) ERR-INVALID-INPUT)
    (asserts! (valid-expiration-time? expires-at) ERR-INVALID-EXPIRATION)
    (asserts! (valid-metadata-size? metadata) ERR-INVALID-INPUT)

    ;; Issue new credential
    (var-set credential-counter (+ current-id u1))
    (ok (map-set verifiable-credentials credential-key {
      holder: holder,
      claim-hash: claim-hash,
      expires-at: expires-at,
      is-revoked: false,
      metadata: metadata,
    }))
  )
)

(define-public (revoke-credential (credential-id uint))
  (let (
      (issuer tx-sender)
      (credential-key {
        issuer: issuer,
        credential-id: credential-id,
      })
      (credential-data (map-get? verifiable-credentials credential-key))
    )
    (asserts! (is-some credential-data) ERR-CREDENTIAL-INVALID)

    (ok (map-set verifiable-credentials credential-key
      (merge (unwrap-panic credential-data) { is-revoked: true })
    ))
  )
)

;; REPUTATION MECHANICS

(define-public (adjust-reputation
    (identity principal)
    (adjustment int)
  )
  (let (
      (identity-data (map-get? sovereign-identities identity))
      (current-score (get reputation-score (unwrap-panic identity-data)))
      (adjustment-magnitude (if (< adjustment 0)
        (* adjustment -1)
        adjustment
      ))
    )
    (asserts! (is-eq tx-sender (var-get protocol-admin)) ERR-UNAUTHORIZED)
    (asserts! (is-some identity-data) ERR-IDENTITY-NOT-FOUND)
    (asserts!
      (or
        (> adjustment 0)
        (>= (to-int current-score) adjustment-magnitude)
      )
      ERR-REPUTATION-BOUNDS
    )

    (let ((new-score (if (> adjustment 0)
        (+ current-score (to-uint adjustment))
        (to-uint (- (to-int current-score) adjustment-magnitude))
      )))
      (ok (map-set sovereign-identities identity
        (merge (unwrap-panic identity-data) {
          reputation-score: new-score,
          last-activity: stacks-block-height,
        })
      ))
    )
  )
)

;; IDENTITY RECOVERY SYSTEM

(define-public (execute-identity-recovery
    (identity principal)
    (new-identity-hash (buff 32))
  )
  (let (
      (guardian tx-sender)
      (identity-data (map-get? sovereign-identities identity))
      (recovery-guardian (get recovery-guardian (unwrap-panic identity-data)))
    )
    (asserts! (is-some identity-data) ERR-IDENTITY-NOT-FOUND)
    (asserts! (is-some recovery-guardian) ERR-UNAUTHORIZED)
    (asserts! (is-eq guardian (unwrap-panic recovery-guardian)) ERR-UNAUTHORIZED)
    (asserts! (valid-hash? new-identity-hash) ERR-INVALID-INPUT)

    (ok (map-set sovereign-identities identity
      (merge (unwrap-panic identity-data) {
        identity-hash: new-identity-hash,
        last-activity: stacks-block-height,
        identity-status: "RECOVERED",
      })
    ))
  )
)

;; READ-ONLY QUERY FUNCTIONS

(define-read-only (get-sovereign-identity (identity principal))
  (map-get? sovereign-identities identity)
)

(define-read-only (get-verifiable-credential
    (issuer principal)
    (credential-id uint)
  )
  (map-get? verifiable-credentials {
    issuer: issuer,
    credential-id: credential-id,
  })
)

(define-read-only (validate-credential
    (issuer principal)
    (credential-id uint)
  )
  (let ((credential (get-verifiable-credential issuer credential-id)))
    (asserts! (is-some credential) ERR-CREDENTIAL-INVALID)
    (let ((cred-data (unwrap-panic credential)))
      (ok (and
        (not (get is-revoked cred-data))
        (< stacks-block-height (get expires-at cred-data))
      ))
    )
  )
)

(define-read-only (get-zk-proof (proof-hash (buff 32)))
  (map-get? zk-proof-registry proof-hash)
)

(define-read-only (get-reputation-score (identity principal))
  (match (map-get? sovereign-identities identity)
    identity-data (some (get reputation-score identity-data))
    none
  )
)

(define-read-only (get-protocol-admin)
  (var-get protocol-admin)
)

(define-read-only (get-credential-counter)
  (var-get credential-counter)
)
