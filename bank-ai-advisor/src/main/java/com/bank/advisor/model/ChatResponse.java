package com.bank.advisor.model;

public record ChatResponse(String sessionId, String response, String model, String toolSource) {}
