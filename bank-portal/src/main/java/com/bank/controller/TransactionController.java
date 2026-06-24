package com.bank.controller;

import com.bank.config.JwtUtil;
import com.bank.dto.*;
import com.bank.entity.Dispute;
import com.bank.service.TransactionService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/transactions")
@CrossOrigin(origins = "*")
public class TransactionController {

    private final TransactionService transactionService;
    private final JwtUtil jwtUtil;

    public TransactionController(TransactionService transactionService, JwtUtil jwtUtil) {
        this.transactionService = transactionService;
        this.jwtUtil = jwtUtil;
    }

    @PostMapping
    public ResponseEntity<TransactionDTO> postTransaction(@RequestBody TransactionRequest request) {
        return ResponseEntity.ok(transactionService.postTransaction(request));
    }

    @GetMapping("/account/{accountId}")
    public ResponseEntity<List<TransactionDTO>> getByAccount(@PathVariable Long accountId) {
        return ResponseEntity.ok(transactionService.getTransactionsByAccount(accountId));
    }

    @GetMapping("/my")
    public ResponseEntity<List<TransactionDTO>> getMyTransactions(
            @RequestHeader("Authorization") String authHeader) {
        Long customerId = extractCustomerId(authHeader);
        return ResponseEntity.ok(transactionService.getTransactionsByCustomer(customerId));
    }

    @GetMapping("/customer/{customerId}")
    public ResponseEntity<List<TransactionDTO>> getByCustomer(@PathVariable Long customerId) {
        return ResponseEntity.ok(transactionService.getTransactionsByCustomer(customerId));
    }

    @GetMapping("/debits/{accountId}")
    public ResponseEntity<List<TransactionDTO>> getDebits(
            @PathVariable Long accountId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        return ResponseEntity.ok(transactionService.getDebitsByAccountAndDateRange(accountId, start, end));
    }

    @PutMapping("/category")
    public ResponseEntity<TransactionDTO> updateCategory(@RequestBody CategoryUpdateRequest request) {
        return ResponseEntity.ok(transactionService.updateCategory(request));
    }

    @PostMapping("/dispute")
    public ResponseEntity<Dispute> raiseDispute(@RequestBody DisputeRequest request) {
        return ResponseEntity.ok(transactionService.raiseDispute(request));
    }

    @GetMapping("/disputes/my")
    public ResponseEntity<List<Dispute>> getMyDisputes(
            @RequestHeader("Authorization") String authHeader) {
        Long customerId = extractCustomerId(authHeader);
        return ResponseEntity.ok(transactionService.getDisputesByCustomer(customerId));
    }

    @GetMapping("/disputes/customer/{customerId}")
    public ResponseEntity<List<Dispute>> getDisputesByCustomer(@PathVariable Long customerId) {
        return ResponseEntity.ok(transactionService.getDisputesByCustomer(customerId));
    }

    private Long extractCustomerId(String authHeader) {
        String token = authHeader.replace("Bearer ", "");
        return jwtUtil.extractCustomerId(token);
    }
}
