ALTER TABLE rental_contracts
    ADD COLUMN tenant_confirmed_at DATETIME(6) NULL AFTER status,
    ADD COLUMN tenant_rejected_at DATETIME(6) NULL AFTER tenant_confirmed_at,
    ADD COLUMN tenant_rejection_reason VARCHAR(500) NULL AFTER tenant_rejected_at;

ALTER TABLE rental_contracts
    DROP CHECK chk_rental_contracts_status;

UPDATE rental_contracts
SET status = 'PENDING_CONFIRMATION'
WHERE status = 'DRAFT'
  AND is_deleted = FALSE;

ALTER TABLE rental_contracts
    ADD CONSTRAINT chk_rental_contracts_status CHECK (
        status IN (
            'DRAFT',
            'PENDING_CONFIRMATION',
            'ACTIVE',
            'REJECTED',
            'EXPIRED',
            'TERMINATED',
            'CANCELLED'
        )
    );
