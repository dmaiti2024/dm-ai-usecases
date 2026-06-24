package com.bank.mcp.tools;

import com.bank.mcp.client.BankApiClient;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

@Component
public class DisputeTools {

    private final BankApiClient client;

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
            """)
    public String raiseDispute(
            @ToolParam(description = "The transaction ID to dispute") Long transactionId,
            @ToolParam(description = "The customer ID filing the dispute") Long customerId,
            @ToolParam(description = "Username of who is raising the dispute (e.g. 'helpdesk' or customer username)") String raisedBy,
            @ToolParam(description = "Detailed reason for the dispute") String disputeReason) {
        return client.raiseDispute(transactionId, customerId, raisedBy, disputeReason);
    }
}
