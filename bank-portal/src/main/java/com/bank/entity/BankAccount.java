package com.bank.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "BANK_ACCOUNT")
@Data
public class BankAccount {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "account_id")
    private Long accountId;

    @Column(name = "customer_id")
    private Long customerId;

    @Column(name = "account_number", unique = true)
    private String accountNumber;

    @Column(name = "account_type")
    private String accountType; // CHECKING, SAVINGS

    @Column(name = "balance")
    private BigDecimal balance;

    @Column(name = "available_balance")
    private BigDecimal availableBalance;

    @Column(name = "account_status")
    private String accountStatus;

    @Column(name = "opened_date")
    private LocalDate openedDate;
}
