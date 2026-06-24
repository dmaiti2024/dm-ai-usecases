package com.bank.advisor.config;

import com.bank.advisor.advisor.CustomerVerificationAdvisor;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.client.advisor.MessageChatMemoryAdvisor;
import org.springframework.ai.chat.memory.InMemoryChatMemoryRepository;
import org.springframework.ai.chat.memory.MessageWindowChatMemory;
import org.springframework.ai.mcp.SyncMcpToolCallbackProvider;
import org.springframework.ai.openai.OpenAiChatModel;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AdvisorConfig {

    private static final String SYSTEM_PROMPT = """
            You are a professional Wells Fargo Bank AI Advisor. You have access to real banking data
            including customer accounts, transactions, and disputes.

            You serve two types of users:
            1. CUSTOMERS: Help them understand their spending patterns, analyze income vs expenses,
               review transaction history, and raise disputes on unauthorized transactions.
            2. HELPDESK STAFF: Help them look up customer data, answer customer questions,
               investigate transactions, and file disputes on behalf of customers.

            Key capabilities:
            - Query transaction history for any customer (by customer ID or name)
            - Look up account balances and account details
            - Analyze spending by category (Mortgage, Household, Utility, Restaurant, Dress, Indian Grocery, Misc)
            - Compare income (CREDIT) vs expenses (DEBIT)
            - Identify spending trends over time periods
            - Raise disputes on specific transactions
            - Review existing disputes and their status

            Customer directory:
            - Customer 1: John Smith (higher income, diverse spending including restaurants and clothing)
            - Customer 2: Sarah Johnson (moderate income, focused on grocery and utilities)

            Guidelines:
            - Always use tools to get real data before answering
            - Format currency as $X,XXX.XX
            - Be professional and empathetic
            - For disputes, always confirm the transaction ID and amount before filing
            - IMPORTANT: if the transaction amount exceeds $1,000, do NOT file a dispute via the tool.
              Instead, inform the customer: "This transaction exceeds $1,000 and must be reviewed by a
              human agent. Please call our Customer Care team at 1-800-xxx-xxxx for assistance."
            - Provide actionable insights, not just raw data
            - When asked about spending trends, pull multiple months of data
            - If user says "my account" or "I" without specifying, ask for their customer ID or name
            """;

    @Bean
    public MessageWindowChatMemory chatMemory(
            @Value("${agent.memory.window-size:20}") int windowSize) {
        return MessageWindowChatMemory.builder()
                .chatMemoryRepository(new InMemoryChatMemoryRepository())
                .maxMessages(windowSize)
                .build();
    }

    @Bean
    public ChatClient chatClient(OpenAiChatModel model,
                                  SyncMcpToolCallbackProvider mcpTools,
                                  MessageWindowChatMemory chatMemory,
                                  CustomerVerificationAdvisor verificationAdvisor) {
        return ChatClient.builder(model)
                .defaultSystem(SYSTEM_PROMPT)
                .defaultToolCallbacks(mcpTools)
                .defaultAdvisors(
                        verificationAdvisor,
                        MessageChatMemoryAdvisor.builder(chatMemory).build())
                .build();
    }
}
