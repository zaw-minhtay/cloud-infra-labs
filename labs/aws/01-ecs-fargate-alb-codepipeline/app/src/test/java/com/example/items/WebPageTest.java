package com.example.items;

import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.charset.StandardCharsets;

import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;

/** Checks the web page is packaged where Spring Boot serves it at / and that it calls the API. */
class WebPageTest {

    @Test
    void pageIsPackagedAndCallsTheApi() throws Exception {
        var page = new ClassPathResource("static/index.html");
        assertTrue(page.exists(), "static/index.html must exist: Spring Boot serves it at /");

        String html = page.getContentAsString(StandardCharsets.UTF_8);
        assertTrue(html.contains("\"/info\""), "the page shows the version from /info");
        assertTrue(html.contains("\"/items\""), "the page lists and creates items through /items");
    }
}
