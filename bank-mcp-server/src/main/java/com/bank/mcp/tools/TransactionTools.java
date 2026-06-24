package com.bank.mcp.tools;

import com.bank.mcp.client.BankApiClient;
import org.springframework.ai.tool.annotation.Tool;
import org.springframework.ai.tool.annotation.ToolParam;
import org.springframework.stereotype.Component;

@Component
public class TransactionTools {

    private final BankApiClient client;

    public TransactionTools(BankApiClient client) {
        this.client = client;
    }

    @Tool(description = """
            Returns all transactions (CREDIT and DEBIT) for a given customer.
            Use when: 'Show me all transactions for customer John Smith',
            'What did customer ID 1 spend?', 'List all transactions for account holder'.
            The customerId is the numeric ID of the customer (e.g. 1 for John Smith, 2 for Sarah Johnson).
            """)
    public String getTransactionsByCustomer(
            @ToolParam(description = "The numeric customer ID (e.g. 1 for John Smith, 2 for Sarah Johnson)") Long customerId) {
        return client.getTransactionsByCustomer(customerId);
    }

    @Tool(description = """
            Posts (inserts) a new CREDIT or DEBIT transaction to a bank account.
            Use when: 'Post a $500 credit to account', 'Record a debit transaction',
            'Add a new transaction to the account'.
            transactionType must be exactly 'CREDIT' or 'DEBIT'.
            """)
    public String postTransaction(
            @ToolParam(description = "The bank account number (e.g. 4012001234567890)") String accountNumber,
            @ToolParam(description = "Transaction type: must be 'CREDIT' or 'DEBIT'") String transactionType,
            @ToolParam(description = "Transaction amount in dollars (e.g. 500.00)") Double amount,
            @ToolParam(description = "Description of the transaction (e.g. 'Direct Deposit', 'Grocery Shopping')") String description,
            @ToolParam(description = "Merchant or payer name (e.g. 'Safeway', 'Acme Corp')") String merchantName) {
        return client.postTransaction(accountNumber, transactionType, amount, description, merchantName);
    }
}
