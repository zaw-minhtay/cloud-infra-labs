package com.example.items;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * GET  /              web page (src/main/resources/static/index.html, served by Spring Boot)
 * GET  /info          app name and version (the Git commit ID set by CodeBuild)
 * GET  /healthz       "ok" for the ALB health check; does NOT touch the database
 * GET  /items         list all items
 * POST /items         create an item
 * GET  /items/{id}    get one item
 * PUT  /items/{id}    update an item
 */
@RestController
public class ItemController {

    private final ItemRepository items;
    private final String version;

    public ItemController(ItemRepository items, @Value("${app.version}") String version) {
        this.items = items;
        this.version = version;
    }

    @GetMapping("/info")
    public Map<String, String> info() {
        return Map.of("app", "items-api-v2", "version", version);
    }

    // Kept independent of the database on purpose: a short Aurora failover must not make
    // the ALB mark every task unhealthy and take the whole app offline.
    @GetMapping(value = "/healthz", produces = MediaType.TEXT_PLAIN_VALUE)
    public String health() {
        return "ok";
    }

    @GetMapping("/items")
    public List<Item> list() {
        return items.findAll();
    }

    @PostMapping("/items")
    @ResponseStatus(HttpStatus.CREATED)
    public Item create(@RequestBody ItemRequest request) {
        ItemRequest item = request.validated();
        return items.create(item.name(), item.description());
    }

    @GetMapping("/items/{id}")
    public Item get(@PathVariable("id") long id) {
        return items.findById(id).orElseThrow(ItemNotFoundException::new);
    }

    @PutMapping("/items/{id}")
    public Item update(@PathVariable("id") long id, @RequestBody ItemRequest request) {
        ItemRequest item = request.validated();
        return items.update(id, item.name(), item.description()).orElseThrow(ItemNotFoundException::new);
    }
}
