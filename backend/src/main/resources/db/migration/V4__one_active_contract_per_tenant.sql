ALTER TABLE rental_contracts
    ADD COLUMN active_tenant_id BIGINT UNSIGNED GENERATED ALWAYS AS (
        CASE
            WHEN status = 'ACTIVE' AND is_deleted = FALSE THEN primary_tenant_id
            ELSE NULL
        END
    ) STORED,
    ADD CONSTRAINT uq_rental_contracts_active_tenant UNIQUE (active_tenant_id);
