package com.bank.mcp.tools;

import com.bank.mcp.client.BankApiClient;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

@Component
public class AccountTools {

    private final BankApiClient client;

    public AccountTools(BankApiClient client) {
        this.client = client;
    }

    @Tool(description = """
            Returns all bank accounts for a given customer including balances.
            Use when: 'What is John Smith's account balance?', 'How many accounts does customer 2 have?',
            'Show me Sarah Johnson's checking account details'.
            Returns account number, type (CHECKING/SAVINGS), balance, available balance, and status.
            """)
    public String getAccountsByCustomer(
            @ToolParam(description = "The numeric customer ID (e.g. 1 for John Smith, 2 for Sarah Johnson)") Long customerId) {
        return client.getAccountsByCustomer(customerId);
    }
}
