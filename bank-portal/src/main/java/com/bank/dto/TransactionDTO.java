package com.bank.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public record TransactionDTO(
    Long transactionId,
    Long accountId,
    String accountNumber,
    LocalDateTime transactionDate,
    String transactionType,
    BigDecimal amount,
    String description,
    String category,
    String merchantName,
    String referenceNo,
    String status
) {}
