package com.bank.dto;

import java.math.BigDecimal;

public record TransactionRequest(
    String accountNumber,
    String transactionType,
    BigDecimal amount,
    String description,
    String merchantName,
    String referenceNo
) {}
