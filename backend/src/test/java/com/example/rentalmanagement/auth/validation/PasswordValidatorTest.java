package com.example.rentalmanagement.auth.validation;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PasswordValidatorTest {
    private final PasswordValidator validator = new PasswordValidator();

    @Test
    void acceptsPasswordWithLetterAndNumber() {
        assertTrue(validator.isValid("MatKhau123", null));
    }

    @Test
    void rejectsWeakPasswords() {
        assertFalse(validator.isValid("12345678", null));
        assertFalse(validator.isValid("OnlyLetters", null));
        assertFalse(validator.isValid("Abc123", null));
    }
}
