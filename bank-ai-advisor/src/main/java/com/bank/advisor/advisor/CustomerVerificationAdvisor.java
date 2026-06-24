package com.bank.advisor.advisor;

import com.bank.advisor.client.BankPortalClient;
import org.springframework.ai.chat.client.ChatClientRequest;
import org.springframework.ai.chat.client.ChatClientResponse;
import org.springframework.ai.chat.client.advisor.api.CallAdvisor;
import org.springframework.ai.chat.client.advisor.api.CallAdvisorChain;
import org.springframework.ai.chat.messages.AssistantMessage;
import org.springframework.ai.chat.messages.MessageType;
import org.springframework.ai.chat.model.ChatResponse;
import org.springframework.ai.chat.model.Generation;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.core.Ordered;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class CustomerVerificationAdvisor implements CallAdvisor {

    private static final String CONVERSATION_ID_KEY = "chat_memory_conversation_id";
    private static final Pattern EMAIL_PATTERN =
            Pattern.compile("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}");
    private static final Pattern PHONE_PATTERN =
            Pattern.compile("\\b\\d{3}[-.\\s]?\\d{3}[-.\\s]?\\d{4}\\b");

    private final BankPortalClient bankPortalClient;
    private final Set<String> verifiedSessions = ConcurrentHashMap.newKeySet();

    public CustomerVerificationAdvisor(BankPortalClient bankPortalClient) {
        this.bankPortalClient = bankPortalClient;
    }

    @Override
    public ChatClientResponse adviseCall(ChatClientRequest request, CallAdvisorChain chain) {
        String sessionId = (String) request.context().get(CONVERSATION_ID_KEY);

        // Session already verified — pass through to LLM
        if (sessionId != null && verifiedSessions.contains(sessionId)) {
            return chain.nextCall(request);
        }

        // Extract email and phone from the latest user message
        String userMessage = extractLatestUserMessage(request);
        Matcher emailMatcher = EMAIL_PATTERN.matcher(userMessage);
        Matcher phoneMatcher = PHONE_PATTERN.matcher(userMessage);

        if (emailMatcher.find() && phoneMatcher.find()) {
            String email = emailMatcher.group();
            String phone = phoneMatcher.group();

            if (bankPortalClient.verifyCustomer(email, phone)) {
                if (sessionId != null) {
                    verifiedSessions.add(sessionId);
                }
                return chain.nextCall(request);
            }

            return blockedResponse(
                "Verification failed. The email or phone number did not match our records. " +
                "Please double-check and try again.",
                request);
        }

        // No credentials in message — ask for them
        return blockedResponse(
            "For your security, I need to verify your identity before accessing any account information. " +
            "Please provide your registered email address and phone number to proceed.",
            request);
    }

    private String extractLatestUserMessage(ChatClientRequest request) {
        return request.prompt().getInstructions().stream()
                .filter(m -> m.getMessageType() == MessageType.USER)
                .reduce((first, second) -> second)
                .map(m -> m.getText())
                .orElse("");
    }

    private ChatClientResponse blockedResponse(String message, ChatClientRequest request) {
        ChatResponse chatResponse = new ChatResponse(
                List.of(new Generation(new AssistantMessage(message))));
        return new ChatClientResponse(chatResponse, request.context());
    }

    @Override
    public String getName() {
        return "CustomerVerificationAdvisor";
    }

    @Override
    public int getOrder() {
        return Ordered.HIGHEST_PRECEDENCE;
    }
}
