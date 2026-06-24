package com.bank.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "BANK_TRANSACTION")
@Data
public class Transaction {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "transaction_id")
    private Long transactionId;

    @Column(name = "account_id")
    private Long accountId;

    @Column(name = "transaction_date")
    private LocalDateTime transactionDate;

    @Column(name = "transaction_type")
    private String transactionType; // CREDIT, DEBIT

    @Column(name = "amount")
    private BigDecimal amount;

    @Column(name = "description")
    private String description;

    @Column(name = "category")
    private String category; // Mortgage, Household, Utility, Restaurant, Dress, Indian Grocery, Misc

    @Column(name = "merchant_name")
    private String merchantName;

    @Column(name = "reference_no")
    private String referenceNo;

    @Column(name = "status")
    private String status; // COMPLETED, PENDING, DISPUTED

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
