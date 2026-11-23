package com.example.items;

/** Request body for creating or updating an item: {"name": "...", "description": "..."}. */
public record ItemRequest(String name, String description) {

    static final int NAME_MAX = 100;
    static final int DESCRIPTION_MAX = 500;

    /** Returns a cleaned copy, or throws {@link InvalidItemException} with a clear message. */
    ItemRequest validated() {
        if (name == null || name.isBlank() || name.strip().length() > NAME_MAX) {
            throw new InvalidItemException("name is required (1-" + NAME_MAX + " characters)");
        }
        String cleanDescription = description == null ? "" : description;
        if (cleanDescription.length() > DESCRIPTION_MAX) {
            throw new InvalidItemException("description must be up to " + DESCRIPTION_MAX + " characters");
        }
        return new ItemRequest(name.strip(), cleanDescription);
    }
}
