package com.bank.advisor.controller;

import com.bank.advisor.agent.BankAdvisorService;
import com.bank.advisor.model.ChatRequest;
import com.bank.advisor.model.ChatResponse;
import org.springframework.ai.mcp.SyncMcpToolCallbackProvider;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/advisor")
@CrossOrigin(origins = "*")
public class AdvisorController {

    private final BankAdvisorService advisorService;
    private final SyncMcpToolCallbackProvider mcpTools;

    public AdvisorController(BankAdvisorService advisorService, SyncMcpToolCallbackProvider mcpTools) {
        this.advisorService = advisorService;
        this.mcpTools = mcpTools;
    }

    @PostMapping("/chat")
    public ResponseEntity<ChatResponse> chat(@RequestBody ChatRequest request) {
        return ResponseEntity.ok(advisorService.chat(request.sessionId(), request.message()));
    }

    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> health() {
        var toolNames = Arrays.stream(mcpTools.getToolCallbacks())
                .map(t -> t.getToolDefinition().name())
                .collect(Collectors.toList());
        return ResponseEntity.ok(Map.of(
                "status", "UP",
                "agent", "Wells Fargo Bank AI Advisor (OpenAI gpt-4o-mini)",
                "toolSource", "Bank MCP Server — http://localhost:8092",
                "toolCount", toolNames.size(),
                "tools", toolNames
        ));
    }
}
