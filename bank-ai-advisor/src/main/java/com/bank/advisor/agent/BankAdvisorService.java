package com.bank.advisor.agent;

import com.bank.advisor.model.ChatResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.stereotype.Service;

@Service
public class BankAdvisorService {

    private static final Logger log = LoggerFactory.getLogger(BankAdvisorService.class);
    private static final String CONVERSATION_ID_KEY = "chat_memory_conversation_id";

    private final ChatClient chatClient;

    public BankAdvisorService(ChatClient chatClient) {
        this.chatClient = chatClient;
    }

    public ChatResponse chat(String sessionId, String userMessage) {
        log.debug("[{}] User: {}", sessionId, userMessage);
        String response = chatClient.prompt()
                .user(userMessage)
                .advisors(a -> a.param(CONVERSATION_ID_KEY, sessionId))
                .call()
                .content();
        log.debug("[{}] Assistant: {}", sessionId,
                response != null && response.length() > 100 ? response.substring(0, 100) + "..." : response);
        return new ChatResponse(sessionId, response, "gpt-4o-mini", "Bank MCP Server (port 8092)");
    }
}
