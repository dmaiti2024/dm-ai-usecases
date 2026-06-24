package com.bank.dto;

import java.math.BigDecimal;

public record CategorizationRequest(String description, BigDecimal amount) {}
