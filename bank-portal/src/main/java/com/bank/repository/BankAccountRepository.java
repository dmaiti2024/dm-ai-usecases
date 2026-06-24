package com.bank.repository;

import com.bank.entity.BankAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface BankAccountRepository extends JpaRepository<BankAccount, Long> {
    List<BankAccount> findByCustomerId(Long customerId);
    java.util.Optional<BankAccount> findByAccountNumber(String accountNumber);
}
