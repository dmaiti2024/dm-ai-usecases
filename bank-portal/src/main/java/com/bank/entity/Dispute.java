package com.bank.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "DISPUTE")
@Data
public class Dispute {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "dispute_id")
    private Long disputeId;

    @Column(name = "transaction_id")
    private Long transactionId;

    @Column(name = "customer_id")
    private Long customerId;

    @Column(name = "raised_by")
    private String raisedBy;

    @Column(name = "dispute_reason", columnDefinition = "TEXT")
    private String disputeReason;

    @Column(name = "dispute_status")
    private String disputeStatus; // OPEN, IN_REVIEW, RESOLVED, CLOSED

    @Column(name = "resolution", columnDefinition = "TEXT")
    private String resolution;

    @Column(name = "raised_date")
    private LocalDateTime raisedDate;

    @Column(name = "resolved_date")
    private LocalDateTime resolvedDate;
}
