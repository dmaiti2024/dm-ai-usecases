package com.bank.repository;

import com.bank.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;
import java.util.List;

public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    List<Transaction> findByAccountIdOrderByTransactionDateDesc(Long accountId);

    @Query("SELECT t FROM Transaction t WHERE t.accountId = :accountId AND t.transactionDate BETWEEN :start AND :end ORDER BY t.transactionDate DESC")
    List<Transaction> findByAccountIdAndDateRange(@Param("accountId") Long accountId,
                                                   @Param("start") LocalDateTime start,
                                                   @Param("end") LocalDateTime end);

    @Query("SELECT t FROM Transaction t WHERE t.accountId = :accountId AND t.transactionType = 'DEBIT' AND t.transactionDate BETWEEN :start AND :end ORDER BY t.transactionDate DESC")
    List<Transaction> findDebitsByAccountIdAndDateRange(@Param("accountId") Long accountId,
                                                         @Param("start") LocalDateTime start,
                                                         @Param("end") LocalDateTime end);

    List<Transaction> findByTransactionIdGreaterThanOrderByTransactionIdAsc(Long id);

    // Used to fetch all transactions for a set of account IDs (for customer-level queries)
    List<Transaction> findByAccountIdInOrderByTransactionDateDesc(List<Long> accountIds);
}
