package com.example.items;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.core.io.ClassPathResource;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

/** Tests the HTTP API against a fresh in-memory H2 database (MySQL mode) for every test. */
class ItemControllerTest {

    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        var db = new DriverManagerDataSource(
                "jdbc:h2:mem:items-" + UUID.randomUUID() + ";MODE=MySQL;DB_CLOSE_DELAY=-1", "sa", "");
        new ResourceDatabasePopulator(new ClassPathResource("schema.sql")).execute(db);
        var controller = new ItemController(new ItemRepository(JdbcClient.create(db)), "test");
        mvc = MockMvcBuilders.standaloneSetup(controller).setControllerAdvice(new ApiErrors()).build();
    }

    private void createItem(String json) throws Exception {
        mvc.perform(post("/items").contentType(MediaType.APPLICATION_JSON).content(json))
                .andExpect(status().isCreated());
    }

    @Test
    void healthCheckReturnsOk() throws Exception {
        mvc.perform(get("/healthz")).andExpect(status().isOk()).andExpect(content().string("ok"));
    }

    @Test
    void rootShowsVersion() throws Exception {
        mvc.perform(get("/")).andExpect(status().isOk()).andExpect(jsonPath("$.version").value("test"));
    }

    @Test
    void createdItemCanBeRetrieved() throws Exception {
        mvc.perform(post("/items").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"Book\", \"description\": \"Read later\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.name").value("Book"));

        mvc.perform(get("/items/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Book"))
                .andExpect(jsonPath("$.description").value("Read later"));
    }

    @Test
    void listReturnsAllItems() throws Exception {
        createItem("{\"name\": \"Book\"}");
        createItem("{\"name\": \"Pen\"}");

        mvc.perform(get("/items"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[1].name").value("Pen"));
    }

    @Test
    void updateChangesTheItem() throws Exception {
        createItem("{\"name\": \"Book\", \"description\": \"Read later\"}");

        mvc.perform(put("/items/1").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\": \"Book\", \"description\": \"Finished\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.description").value("Finished"));

        mvc.perform(get("/items/1")).andExpect(jsonPath("$.description").value("Finished"));
    }

    @Test
    void missingItemReturns404() throws Exception {
        mvc.perform(get("/items/99"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("item not found"));
        mvc.perform(put("/items/99").contentType(MediaType.APPLICATION_JSON).content("{\"name\": \"X\"}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void invalidBodyReturns400() throws Exception {
        mvc.perform(post("/items").contentType(MediaType.APPLICATION_JSON).content("{\"description\": \"no name\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("name is required (1-100 characters)"));
        mvc.perform(post("/items").contentType(MediaType.APPLICATION_JSON).content("not json"))
                .andExpect(status().isBadRequest());
    }
}
