package com.bank.mcp.tools;

import com.bank.mcp.client.BankApiClient;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

@Component
public class DisputeTools {

    private static final double HIGH_VALUE_THRESHOLD = 1000.0;
    private static final String CUSTOMER_CARE_NUMBER = "1-800-xxx-xxxx";

    private final BankApiClient client;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public DisputeTools(BankApiClient client) {
        this.client = client;
    }

    @Tool(description = """
            Returns all disputes filed by or for a given customer.
            Use when: 'Show me disputes for John Smith', 'What disputes has customer 2 filed?',
            'Are there any open disputes for Sarah Johnson?'.
            Returns dispute ID, transaction ID, reason, status (OPEN/IN_REVIEW/RESOLVED/CLOSED), and resolution.
            """)
    public String getDisputesByCustomer(
            @ToolParam(description = "The numeric customer ID") Long customerId) {
        return client.getDisputesByCustomer(customerId);
    }

    @Tool(description = """
            Raises a dispute on a specific transaction for a customer.
            Use when: 'John Smith wants to dispute transaction 15',
            'File a dispute for an unauthorized charge on Sarah's account',
            'The customer is disputing a transaction they didn't authorize'.
            This marks the transaction as DISPUTED and creates a dispute record.
            Note: high-value transactions are automatically routed to human review.
            """)
    public String raiseDispute(
            @ToolParam(description = "The transaction ID to dispute") Long transactionId,
            @ToolParam(description = "The customer ID filing the dispute") Long customerId,
            @ToolParam(description = "Username of who is raising the dispute (e.g. 'helpdesk' or customer username)") String raisedBy,
            @ToolParam(description = "Detailed reason for the dispute") String disputeReason) {
        try {
            String txnJson = client.getTransactionById(transactionId);
            JsonNode txn = objectMapper.readTree(txnJson);
            double amount = txn.path("amount").asDouble(0.0);
            if (amount > HIGH_VALUE_THRESHOLD) {
                return String.format(
                    "{\"status\":\"REQUIRES_HUMAN_REVIEW\",\"message\":\"This transaction of $%.2f exceeds the $1,000 limit for automated dispute resolution. Please call our Customer Care team at %s for assistance.\"}",
                    amount, CUSTOMER_CARE_NUMBER);
            }
        } catch (Exception e) {
            return "{\"error\":\"Could not verify transaction amount before raising dispute: " + e.getMessage() + "\"}";
        }
        return client.raiseDispute(transactionId, customerId, raisedBy, disputeReason);
    }
}
