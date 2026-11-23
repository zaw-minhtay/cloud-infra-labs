package com.example.items;

/** The request body is missing a field or a field is too long (HTTP 400). */
class InvalidItemException extends RuntimeException {

    InvalidItemException(String message) {
        super(message);
    }
}
