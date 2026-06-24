package com.bank.mcp.tools;

import org.springframework.ai.tool.annotation.Tool;
import org.springframework.stereotype.Component;

@Component
public class CustomerTools {

    @Tool(description = """
            Returns the known customer directory for this bank.
            Use to look up customer IDs when you only have a name.
            Customer list:
            - Customer ID 1: John Smith (john.smith) - CHECKING account: 4012001234567890, SAVINGS: 4012001234567891
            - Customer ID 2: Sarah Johnson (sarah.johnson) - CHECKING account: 4012009876543210, SAVINGS: 4012009876543211
            Use this to resolve customer names to IDs before calling other tools.
            """)
    public String getCustomerDirectory() {
        return """
                {
                  "customers": [
                    {"customerId": 1, "name": "John Smith", "username": "john.smith",
                     "accounts": [
                       {"accountNumber": "4012001234567890", "type": "CHECKING"},
                       {"accountNumber": "4012001234567891", "type": "SAVINGS"}
                     ]},
                    {"customerId": 2, "name": "Sarah Johnson", "username": "sarah.johnson",
                     "accounts": [
                       {"accountNumber": "4012009876543210", "type": "CHECKING"},
                       {"accountNumber": "4012009876543211", "type": "SAVINGS"}
                     ]}
                  ]
                }
                """;
    }

    @Tool(description = """
            Returns spending analysis for a customer - breakdown by category.
            Use when: 'Analyze John's spending patterns', 'How much does Sarah spend on grocery?',
            'Compare spending between two customers', 'What is the biggest expense category?'.
            First call getTransactionsByCustomer, then this tool for analysis guidance.
            """)
    public String getSpendingCategories() {
        return """
                {
                  "categories": ["Mortgage", "Household", "Utility", "Restaurant", "Dress", "Indian Grocery", "Misc"],
                  "note": "Call getTransactionsByCustomer first to get actual transaction data, then analyze by category field"
                }
                """;
    }
}
