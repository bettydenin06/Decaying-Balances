(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_TRANSFER_FAILED (err u103))
(define-constant ERR_MINT_FAILED (err u104))
(define-constant ERR_RESCUE_ACTIVE (err u105))
(define-constant ERR_RESCUE_LOCKED (err u106))

(define-fungible-token decay-token)

(define-map token-balances 
    { owner: principal } 
    { balance: uint, last-update: uint }
)

(define-map allowances
    { owner: principal, spender: principal }
    { allowance: uint }
)

(define-map rescue-locks
    { owner: principal }
    { rescued-amount: uint, unlock-block: uint }
)

(define-data-var token-name (string-ascii 32) "DecayToken")
(define-data-var token-symbol (string-ascii 10) "DECAY")
(define-data-var token-decimals uint u6)
(define-data-var decay-rate uint u1000)
(define-data-var decay-interval uint u144)
(define-data-var total-supply uint u0)

(define-private (get-current-block-height)
   stacks-block-height
)

(define-private (calculate-decay (balance uint) (blocks-passed uint))
    (let ((decay-periods (/ blocks-passed (var-get decay-interval))))
        (if (> decay-periods u0)
            (let ((decay-amount (/ (* balance (var-get decay-rate)) u100000)))
                (if (>= decay-amount balance)
                    u0
                    (- balance (* decay-amount decay-periods))
                )
            )
            balance
        )
    )
)

(define-private (update-balance (owner principal))
    (let ((balance-data (default-to { balance: u0, last-update: u0 } 
                                   (map-get? token-balances { owner: owner }))))
        (let ((current-balance (get balance balance-data))
              (last-update (get last-update balance-data))
              (current-block (get-current-block-height))
              (blocks-passed (- current-block last-update)))
            (let ((new-balance (calculate-decay current-balance blocks-passed)))
                (map-set token-balances 
                    { owner: owner }
                    { balance: new-balance, last-update: current-block }
                )
                new-balance
            )
        )
    )
)

(define-read-only (get-balance (owner principal))
    (let ((balance-data (default-to { balance: u0, last-update: u0 } 
                                   (map-get? token-balances { owner: owner }))))
        (let ((current-balance (get balance balance-data))
              (last-update (get last-update balance-data))
              (current-block (get-current-block-height))
              (blocks-passed (- current-block last-update)))
            (calculate-decay current-balance blocks-passed)
        )
    )
)

(define-read-only (get-name)
    (ok (var-get token-name))
)

(define-read-only (get-symbol)
    (ok (var-get token-symbol))
)

(define-read-only (get-decimals)
    (ok (var-get token-decimals))
)

(define-read-only (get-total-supply)
    (ok (var-get total-supply))
)

(define-read-only (get-decay-rate)
    (var-get decay-rate)
)

(define-read-only (get-decay-interval)
    (var-get decay-interval)
)

(define-read-only (get-allowance (owner principal) (spender principal))
    (default-to u0 (get allowance (map-get? allowances { owner: owner, spender: spender })))
)

(define-read-only (get-rescue-lock (owner principal))
    (map-get? rescue-locks { owner: owner })
)

(define-read-only (get-available-balance (owner principal))
    (let ((total-balance (get-balance owner))
          (rescue-data (get-rescue-lock owner)))
        (match rescue-data 
            rescue-info 
            (let ((rescued-amount (get rescued-amount rescue-info))
                  (unlock-block (get unlock-block rescue-info)))
                (if (>= (get-current-block-height) unlock-block)
                    total-balance
                    (if (>= total-balance rescued-amount)
                        (- total-balance rescued-amount)
                        u0
                    )
                )
            )
            total-balance
        )
    )
)

(define-public (mint (recipient principal) (amount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (try! (ft-mint? decay-token amount recipient))
        (let ((current-balance (update-balance recipient)))
            (map-set token-balances 
                { owner: recipient }
                { balance: (+ current-balance amount), last-update: (get-current-block-height) }
            )
        )
        (var-set total-supply (+ (var-get total-supply) amount))
        (ok amount)
    )
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
    (begin
        (asserts! (or (is-eq tx-sender sender) (is-eq contract-caller sender)) ERR_NOT_AUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (let ((sender-balance (update-balance sender))
              (available-balance (get-available-balance sender)))
            (asserts! (>= available-balance amount) ERR_INSUFFICIENT_BALANCE)
            (try! (ft-transfer? decay-token amount sender recipient))
            (let ((recipient-balance (update-balance recipient)))
                (map-set token-balances 
                    { owner: sender }
                    { balance: (- sender-balance amount), last-update: (get-current-block-height) }
                )
                (map-set token-balances 
                    { owner: recipient }
                    { balance: (+ recipient-balance amount), last-update: (get-current-block-height) }
                )
            )
        )
        (match memo to-print (print to-print) 0x)
        (ok true)
    )
)

(define-public (approve (spender principal) (amount uint))
    (begin
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (map-set allowances 
            { owner: tx-sender, spender: spender }
            { allowance: amount }
        )
        (ok true)
    )
)

(define-public (transfer-from (amount uint) (owner principal) (recipient principal) (memo (optional (buff 34))))
    (let ((allowance (get-allowance owner tx-sender)))
        (asserts! (>= allowance amount) ERR_NOT_AUTHORIZED)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (let ((owner-balance (update-balance owner))
              (available-balance (get-available-balance owner)))
            (asserts! (>= available-balance amount) ERR_INSUFFICIENT_BALANCE)
            (try! (ft-transfer? decay-token amount owner recipient))
            (let ((recipient-balance (update-balance recipient)))
                (map-set token-balances 
                    { owner: owner }
                    { balance: (- owner-balance amount), last-update: (get-current-block-height) }
                )
                (map-set token-balances 
                    { owner: recipient }
                    { balance: (+ recipient-balance amount), last-update: (get-current-block-height) }
                )
                (map-set allowances 
                    { owner: owner, spender: tx-sender }
                    { allowance: (- allowance amount) }
                )
            )
        )
        (match memo to-print (print to-print) 0x)
        (ok true)
    )
)

(define-public (burn (amount uint))
    (begin
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (let ((sender-balance (update-balance tx-sender))
              (available-balance (get-available-balance tx-sender)))
            (asserts! (>= available-balance amount) ERR_INSUFFICIENT_BALANCE)
            (try! (ft-burn? decay-token amount tx-sender))
            (map-set token-balances 
                { owner: tx-sender }
                { balance: (- sender-balance amount), last-update: (get-current-block-height) }
            )
            (var-set total-supply (- (var-get total-supply) amount))
        )
        (ok amount)
    )
)

(define-public (set-decay-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (<= new-rate u10000) ERR_INVALID_AMOUNT)
        (var-set decay-rate new-rate)
        (ok true)
    )
)

(define-public (set-decay-interval (new-interval uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
        (asserts! (> new-interval u0) ERR_INVALID_AMOUNT)
        (var-set decay-interval new-interval)
        (ok true)
    )
)

(define-public (rescue-balance (amount uint) (lock-duration uint))
    (begin
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (> lock-duration u0) ERR_INVALID_AMOUNT)
        (let ((current-balance (update-balance tx-sender))
              (existing-rescue (get-rescue-lock tx-sender)))
            (asserts! (>= current-balance amount) ERR_INSUFFICIENT_BALANCE)
            (asserts! (is-none existing-rescue) ERR_RESCUE_ACTIVE)
            (let ((unlock-block (+ (get-current-block-height) lock-duration)))
                (map-set rescue-locks 
                    { owner: tx-sender }
                    { rescued-amount: amount, unlock-block: unlock-block }
                )
                (ok true)
            )
        )
    )
)

(define-public (release-rescue)
    (begin
        (let ((rescue-data (get-rescue-lock tx-sender)))
            (asserts! (is-some rescue-data) ERR_RESCUE_ACTIVE)
            (let ((rescue-info (unwrap-panic rescue-data)))
                (asserts! (>= (get-current-block-height) (get unlock-block rescue-info)) ERR_RESCUE_LOCKED)
                (map-delete rescue-locks { owner: tx-sender })
                (ok true)
            )
        )
    )
)