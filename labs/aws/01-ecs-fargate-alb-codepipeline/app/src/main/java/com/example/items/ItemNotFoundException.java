package com.example.items;

/** No item with the requested ID (HTTP 404). */
class ItemNotFoundException extends RuntimeException {

    ItemNotFoundException() {
        super("item not found");
    }
}
