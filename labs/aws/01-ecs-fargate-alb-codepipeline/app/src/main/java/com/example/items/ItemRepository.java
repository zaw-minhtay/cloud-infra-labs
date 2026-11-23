package com.example.items;

import java.util.List;
import java.util.Optional;

import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Repository;

/** Reads and writes items in MySQL (Aurora) with plain SQL. */
@Repository
public class ItemRepository {

    private static final String COLUMNS = "id, name, description, updated_at";

    private final JdbcClient jdbc;

    public ItemRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    public List<Item> findAll() {
        return jdbc.sql("SELECT " + COLUMNS + " FROM items ORDER BY id")
                .query(Item.class)
                .list();
    }

    public Optional<Item> findById(long id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM items WHERE id = ?")
                .param(id)
                .query(Item.class)
                .optional();
    }

    public Item create(String name, String description) {
        KeyHolder keys = new GeneratedKeyHolder();
        jdbc.sql("INSERT INTO items (name, description) VALUES (?, ?)")
                .params(name, description)
                .update(keys, "id"); // ask only for the generated id (not updated_at)
        return findById(keys.getKey().longValue()).orElseThrow();
    }

    public Optional<Item> update(long id, String name, String description) {
        int rows = jdbc.sql("UPDATE items SET name = ?, description = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?")
                .params(name, description, id)
                .update();
        return rows == 0 ? Optional.empty() : findById(id);
    }
}
