package com.bank.entity;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "RAG_INDEX_TRACKER")
@Data
public class RagIndexTracker {
    @Id
    private Integer id;

    @Column(name = "last_indexed_transaction_id")
    private Long lastIndexedTransactionId;
}
