package com.bank.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public record AccountSummaryDTO(
    Long accountId,
    String accountNumber,
    String accountType,
    BigDecimal balance,
    BigDecimal availableBalance,
    String accountStatus,
    LocalDate openedDate
) {}
