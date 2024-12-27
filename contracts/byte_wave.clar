;; ByteWave Contract
(define-fungible-token byte-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))

;; Data Maps
(define-map students 
    principal 
    {
        username: (string-ascii 50),
        level: uint,
        total-points: uint,
        challenges-completed: uint
    }
)

(define-map achievements
    {student: principal, achievement-id: uint}
    {
        unlocked: bool,
        unlock-time: uint
    }
)

(define-map challenges
    uint 
    {
        name: (string-ascii 100),
        points: uint,
        difficulty: uint
    }
)

;; Public Functions
(define-public (register-student (username (string-ascii 50)))
    (let ((student-data {username: username, level: u1, total-points: u0, challenges-completed: u0}))
        (if (is-some (map-get? students tx-sender))
            err-already-exists
            (begin
                (try! (map-set students tx-sender student-data))
                (ok true)
            )
        )
    )
)

(define-public (complete-challenge (challenge-id uint))
    (let (
        (challenge (unwrap! (map-get? challenges challenge-id) err-not-found))
        (student (unwrap! (map-get? students tx-sender) err-not-found))
    )
    (begin
        (try! (map-set students tx-sender 
            (merge student {
                total-points: (+ (get total-points student) (get points challenge)),
                challenges-completed: (+ (get challenges-completed student) u1)
            })
        ))
        (try! (ft-mint? byte-token (get points challenge) tx-sender))
        (ok true)
    ))
)

(define-public (unlock-achievement (achievement-id uint))
    (let (
        (achievement-key {student: tx-sender, achievement-id: achievement-id})
    )
    (if (is-some (map-get? achievements achievement-key))
        err-already-exists
        (begin
            (try! (map-set achievements achievement-key 
                {unlocked: true, unlock-time: block-height}
            ))
            (try! (ft-mint? byte-token u100 tx-sender))
            (ok true)
        )
    ))
)

;; Admin Functions
(define-public (add-challenge (id uint) (name (string-ascii 100)) (points uint) (difficulty uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (try! (map-set challenges id {
                name: name,
                points: points,
                difficulty: difficulty
            }))
            (ok true)
        )
        err-owner-only
    )
)

;; Read-only Functions
(define-read-only (get-student-info (student principal))
    (ok (map-get? students student))
)

(define-read-only (get-challenge-info (challenge-id uint))
    (ok (map-get? challenges challenge-id))
)

(define-read-only (get-achievement-status (student principal) (achievement-id uint))
    (ok (map-get? achievements {student: student, achievement-id: achievement-id}))
)

(define-read-only (get-student-points (student principal))
    (match (map-get? students student)
        student-data (ok (get total-points student-data))
        (err err-not-found)
    )
)