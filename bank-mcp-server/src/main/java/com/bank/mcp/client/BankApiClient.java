package com.bank.mcp.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.util.Map;

/**
 * REST client for the bank-portal API.
 * Authenticates at startup using the helpdesk service account and attaches
 * the JWT to all subsequent requests.
 */
@Component
public class BankApiClient {

    private static final Logger log = LoggerFactory.getLogger(BankApiClient.class);

    private final String baseUrl;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private RestClient restClient;
    private String serviceToken;

    public BankApiClient(@Value("${bank.api.base-url}") String baseUrl) {
        this.baseUrl = baseUrl;
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .defaultHeader("Content-Type", "application/json")
                .defaultHeader("Accept", "application/json")
                .build();
    }

    @PostConstruct
    public void authenticate() {
        try {
            String loginBody = "{\"username\":\"helpdesk\",\"password\":\"password123\"}";
            String response = restClient.post()
                    .uri("/api/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(loginBody)
                    .retrieve()
                    .body(String.class);

            JsonNode node = objectMapper.readTree(response);
            this.serviceToken = node.path("token").asText();
            log.info("BankApiClient authenticated as helpdesk service account");

            // Rebuild client with auth header
            this.restClient = RestClient.builder()
                    .baseUrl(baseUrl)
                    .defaultHeader("Content-Type", "application/json")
                    .defaultHeader("Accept", "application/json")
                    .defaultHeader("Authorization", "Bearer " + serviceToken)
                    .build();
        } catch (Exception e) {
            log.warn("BankApiClient auth failed — API calls will fail until bank-portal is running. {}", e.getMessage());
        }
    }

    public String getTransactionById(Long transactionId) {
        return get("/api/transactions/" + transactionId);
    }

    public String getTransactionsByCustomer(Long customerId) {
        return get("/api/transactions/customer/" + customerId);
    }

    public String getAccountsByCustomer(Long customerId) {
        return get("/api/accounts/customer/" + customerId);
    }

    public String getDisputesByCustomer(Long customerId) {
        return get("/api/transactions/disputes/customer/" + customerId);
    }

    public String raiseDispute(Long transactionId, Long customerId, String raisedBy, String reason) {
        Map<String, Object> body = Map.of(
                "transactionId", transactionId,
                "customerId", customerId,
                "raisedBy", raisedBy,
                "disputeReason", reason
        );
        return post("/api/transactions/dispute", body);
    }

    public String postTransaction(String accountNumber, String type, double amount,
                                  String description, String merchantName) {
        java.util.Map<String, Object> body = new java.util.HashMap<>();
        body.put("accountNumber", accountNumber);
        body.put("transactionType", type);
        body.put("amount", amount);
        body.put("description", description);
        body.put("merchantName", merchantName);
        return post("/api/transactions", body);
    }

    private String get(String uri) {
        try {
            return restClient.get().uri(uri).retrieve().body(String.class);
        } catch (RestClientException ex) {
            return errorJson(uri, ex.getMessage());
        }
    }

    private String post(String uri, Object body) {
        try {
            return restClient.post()
                    .uri(uri)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(String.class);
        } catch (RestClientException ex) {
            return errorJson(uri, ex.getMessage());
        }
    }

    private String errorJson(String uri, String message) {
        String safeMsg = (message != null ? message : "Bank backend may not be running. Start it on port 9081 first.")
                .replace("\"", "'");
        return String.format(
                "{\"error\":\"Bank API call failed\",\"endpoint\":\"%s\",\"message\":\"%s\"}",
                uri, safeMsg);
    }
}
