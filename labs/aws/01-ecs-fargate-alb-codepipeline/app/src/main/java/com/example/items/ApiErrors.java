package com.example.items;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/** Turns errors into short JSON responses: {"error": "..."}. */
@RestControllerAdvice
class ApiErrors {

    private static final Logger log = LoggerFactory.getLogger(ApiErrors.class);

    @ExceptionHandler(InvalidItemException.class)
    ResponseEntity<Map<String, String>> invalid(InvalidItemException e) {
        return error(HttpStatus.BAD_REQUEST, e.getMessage());
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    ResponseEntity<Map<String, String>> unreadable(HttpMessageNotReadableException e) {
        return error(HttpStatus.BAD_REQUEST, "body must be JSON: {\"name\": \"...\", \"description\": \"...\"}");
    }

    @ExceptionHandler(ItemNotFoundException.class)
    ResponseEntity<Map<String, String>> notFound(ItemNotFoundException e) {
        return error(HttpStatus.NOT_FOUND, e.getMessage());
    }

    // Database down or failing over: tell the client to retry instead of returning a 500.
    @ExceptionHandler(DataAccessException.class)
    ResponseEntity<Map<String, String>> storageUnavailable(DataAccessException e) {
        log.warn("Storage error: {}", e.getClass().getSimpleName());
        return error(HttpStatus.SERVICE_UNAVAILABLE, "storage unavailable, try again");
    }

    private static ResponseEntity<Map<String, String>> error(HttpStatus status, String message) {
        return ResponseEntity.status(status).body(Map.of("error", message));
    }
}
