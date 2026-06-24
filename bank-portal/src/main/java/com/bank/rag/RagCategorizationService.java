package com.bank.rag;

import com.bank.dto.CategorizationResponse;
import com.bank.entity.Transaction;
import com.bank.repository.RagIndexTrackerRepository;
import com.bank.repository.TransactionRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.ai.chat.prompt.Prompt;
import org.springframework.ai.document.Document;
import org.springframework.ai.vectorstore.SearchRequest;
import org.springframework.ai.vectorstore.VectorStore;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class RagCategorizationService {

    private static final Logger log = LoggerFactory.getLogger(RagCategorizationService.class);
    private static final int BATCH_SIZE = 100;
    private static final List<String> CATEGORIES = List.of(
            "Mortgage", "Household", "Utility", "Restaurant", "Dress", "Indian Grocery", "Misc"
    );

    private final VectorStore vectorStore;
    private final ChatModel chatModel;
    private final TransactionRepository transactionRepository;
    private final JdbcTemplate jdbcTemplate;

    public RagCategorizationService(VectorStore vectorStore, ChatModel chatModel,
                                     TransactionRepository transactionRepository,
                                     JdbcTemplate jdbcTemplate) {
        this.vectorStore = vectorStore;
        this.chatModel = chatModel;
        this.transactionRepository = transactionRepository;
        this.jdbcTemplate = jdbcTemplate;
    }

    @PostConstruct
    public void buildIndex() {
        try {
            buildIndexInternal();
        } catch (Exception e) {
            log.warn("RAG index build skipped. Cause: {}", e.getMessage());
        }
    }

    private void buildIndexInternal() {
        Integer vectorCount = jdbcTemplate.queryForObject("SELECT COUNT(*) FROM vector_store", Integer.class);
        if (vectorCount != null && vectorCount == 0) {
            jdbcTemplate.update("UPDATE RAG_INDEX_TRACKER SET last_indexed_transaction_id = 0 WHERE id = 1");
        }

        Long lastId = jdbcTemplate.queryForObject(
                "SELECT last_indexed_transaction_id FROM RAG_INDEX_TRACKER WHERE id = 1", Long.class);
        if (lastId == null) lastId = 0L;

        List<Transaction> newTxns = transactionRepository.findByTransactionIdGreaterThanOrderByTransactionIdAsc(lastId);
        if (newTxns.isEmpty()) {
            log.info("RAG | Index up to date. {} vectors in store.", vectorCount);
            return;
        }

        log.info("RAG | Indexing {} new DEBIT transactions.", newTxns.size());
        List<Document> documents = new ArrayList<>();
        long maxId = lastId;

        for (Transaction t : newTxns) {
            if (!"DEBIT".equals(t.getTransactionType())) continue;
            if (t.getDescription() == null || t.getDescription().isBlank()) continue;
            if (t.getCategory() == null || t.getCategory().isBlank()) continue;

            String text = String.format("Transaction: %s | Category: %s | Amount: $%.2f",
                    t.getDescription().trim(), t.getCategory(), t.getAmount());
            documents.add(new Document(text, Map.of(
                    "transactionId", t.getTransactionId(),
                    "category", t.getCategory(),
                    "amount", t.getAmount()
            )));
            if (t.getTransactionId() > maxId) maxId = t.getTransactionId();
        }

        if (!documents.isEmpty()) {
            for (int i = 0; i < documents.size(); i += BATCH_SIZE) {
                vectorStore.add(documents.subList(i, Math.min(i + BATCH_SIZE, documents.size())));
            }
        }

        final long finalMaxId = maxId;
        jdbcTemplate.update("UPDATE RAG_INDEX_TRACKER SET last_indexed_transaction_id = ? WHERE id = 1", finalMaxId);
        log.info("RAG | Indexed {} documents. Max transaction_id: {}", documents.size(), finalMaxId);
    }

    public CategorizationResponse categorize(String description, java.math.BigDecimal amount) {
        List<Document> similar = vectorStore.similaritySearch(
                SearchRequest.builder().query(description).topK(5).build());

        StringBuilder context = new StringBuilder();
        for (Document doc : similar) {
            context.append("- ").append(doc.getText()).append("\n");
        }

        String prompt = String.format("""
                You are a bank transaction categorization assistant.
                Based on the historical examples below, categorize the new transaction.
                You MUST choose exactly one category from this list: %s

                Historical examples:
                %s

                New transaction to categorize:
                Description: %s
                Amount: $%.2f

                Respond ONLY in JSON format: {"category": "<one from list>", "reasoning": "<brief reason>"}
                """,
                String.join(", ", CATEGORIES),
                context.toString(),
                description,
                amount != null ? amount.doubleValue() : 0.0
        );

        try {
            String response = chatModel.call(new Prompt(prompt))
                    .getResult().getOutput().getText();
            response = response.replaceAll("```json|```", "").trim();
            com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
            var node = mapper.readTree(response);
            return new CategorizationResponse(
                    node.path("category").asText("Misc"),
                    node.path("reasoning").asText("")
            );
        } catch (Exception e) {
            log.error("RAG categorization failed: {}", e.getMessage());
            return new CategorizationResponse("Misc", "Unable to categorize automatically.");
        }
    }

    public void reindexTransaction(Transaction txn) {
        if (!"DEBIT".equals(txn.getTransactionType())) return;
        if (txn.getCategory() == null || txn.getDescription() == null) return;
        String text = String.format("Transaction: %s | Category: %s | Amount: $%.2f",
                txn.getDescription().trim(), txn.getCategory(), txn.getAmount());
        vectorStore.add(List.of(new Document(text, Map.of(
                "transactionId", txn.getTransactionId(),
                "category", txn.getCategory()
        ))));
    }
}
