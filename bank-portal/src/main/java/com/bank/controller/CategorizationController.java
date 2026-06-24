package com.bank.controller;

import com.bank.dto.CategorizationRequest;
import com.bank.dto.CategorizationResponse;
import com.bank.rag.RagCategorizationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/categorize")
@CrossOrigin(origins = "*")
public class CategorizationController {

    private final RagCategorizationService ragService;

    public CategorizationController(RagCategorizationService ragService) {
        this.ragService = ragService;
    }

    @PostMapping
    public ResponseEntity<CategorizationResponse> categorize(@RequestBody CategorizationRequest request) {
        return ResponseEntity.ok(ragService.categorize(request.description(), request.amount()));
    }
}
