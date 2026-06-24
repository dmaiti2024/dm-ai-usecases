package com.bank.repository;

import com.bank.entity.Dispute;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface DisputeRepository extends JpaRepository<Dispute, Long> {
    List<Dispute> findByCustomerId(Long customerId);
    List<Dispute> findByTransactionId(Long transactionId);
    List<Dispute> findByDisputeStatus(String status);
}
