package com.bank.advisor.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

@Component
public class BankPortalClient {

    private final RestClient restClient;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public BankPortalClient(@Value("${bank.portal.base-url}") String baseUrl) {
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .build();
    }

    public boolean verifyCustomer(String email, String phone) {
        try {
            String response = restClient.get()
                    .uri("/api/customers/verify?email={email}&phone={phone}", email, phone)
                    .retrieve()
                    .body(String.class);
            JsonNode node = objectMapper.readTree(response);
            return node.path("verified").asBoolean(false);
        } catch (Exception e) {
            return false;
        }
    }
}
