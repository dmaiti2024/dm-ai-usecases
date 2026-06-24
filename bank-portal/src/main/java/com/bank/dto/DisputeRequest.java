package com.bank.dto;

public record DisputeRequest(Long transactionId, Long customerId, String raisedBy, String disputeReason) {}
