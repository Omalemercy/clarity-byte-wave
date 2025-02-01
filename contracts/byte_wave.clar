;; ByteWave Contract
(define-fungible-token byte-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-level (err u103))

;; Data Maps
(define-map students 
    principal 
    {
        username: (string-ascii 50),
        level: uint,
        total-points: uint,
        challenges-completed: uint,
        skill-levels: {
            algorithms: uint,
            web: uint,
            databases: uint,
            security: uint
        },
        badges: (list 20 uint)
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
        difficulty: uint,
        skill-category: (string-ascii 20),
        skill-points: uint
    }
)

(define-map badges
    uint
    {
        name: (string-ascii 50),
        description: (string-ascii 200),
        required-skill: (string-ascii 20),
        required-level: uint
    }
)

;; Public Functions
(define-public (register-student (username (string-ascii 50)))
    (let ((student-data {
        username: username, 
        level: u1,
        total-points: u0,
        challenges-completed: u0,
        skill-levels: {
            algorithms: u1,
            web: u1,
            databases: u1,
            security: u1
        },
        badges: (list )
    }))
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
        (new-skill-levels (update-skill-level 
            (get skill-levels student)
            (get skill-category challenge)
            (get skill-points challenge)
        ))
    )
    (begin
        (try! (map-set students tx-sender 
            (merge student {
                total-points: (+ (get total-points student) (get points challenge)),
                challenges-completed: (+ (get challenges-completed student) u1),
                skill-levels: new-skill-levels,
                badges: (check-and-award-badges new-skill-levels (get badges student))
            })
        ))
        (try! (ft-mint? byte-token (get points challenge) tx-sender))
        (ok true)
    ))
)

(define-private (update-skill-level (current-levels {algorithms: uint, web: uint, databases: uint, security: uint}) (category (string-ascii 20)) (points uint))
    (match category
        "algorithms" (merge current-levels {algorithms: (+ (get algorithms current-levels) points)})
        "web" (merge current-levels {web: (+ (get web current-levels) points)})
        "databases" (merge current-levels {databases: (+ (get databases current-levels) points)})
        "security" (merge current-levels {security: (+ (get security current-levels) points)})
        current-levels
    )
)

(define-private (check-and-award-badges (skill-levels {algorithms: uint, web: uint, databases: uint, security: uint}) (current-badges (list 20 uint)))
    (let (
        (new-badges (filter check-badge-eligibility (map-get? badges)))
    )
    (append current-badges new-badges))
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
(define-public (add-challenge (id uint) (name (string-ascii 100)) (points uint) (difficulty uint) (skill-category (string-ascii 20)) (skill-points uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (try! (map-set challenges id {
                name: name,
                points: points,
                difficulty: difficulty,
                skill-category: skill-category,
                skill-points: skill-points
            }))
            (ok true)
        )
        err-owner-only
    )
)

(define-public (add-badge (id uint) (name (string-ascii 50)) (description (string-ascii 200)) (skill (string-ascii 20)) (level uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (try! (map-set badges id {
                name: name,
                description: description,
                required-skill: skill,
                required-level: level
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

(define-read-only (get-skill-levels (student principal))
    (match (map-get? students student)
        student-data (ok (get skill-levels student-data))
        (err err-not-found)
    )
)

(define-read-only (get-badges (student principal))
    (match (map-get? students student)
        student-data (ok (get badges student-data))
        (err err-not-found)
    )
)
