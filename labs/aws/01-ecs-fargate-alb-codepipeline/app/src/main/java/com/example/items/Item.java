package com.example.items;

import java.time.LocalDateTime;

/** One stored item, as returned by the API. */
public record Item(Long id, String name, String description, LocalDateTime updatedAt) {
}
