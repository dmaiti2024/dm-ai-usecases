package com.bank.service;

import com.bank.dto.AccountSummaryDTO;
import com.bank.entity.BankAccount;
import com.bank.repository.BankAccountRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AccountService {

    private final BankAccountRepository bankAccountRepository;

    public AccountService(BankAccountRepository bankAccountRepository) {
        this.bankAccountRepository = bankAccountRepository;
    }

    public List<AccountSummaryDTO> getAccountsByCustomer(Long customerId) {
        return bankAccountRepository.findByCustomerId(customerId)
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }

    public BankAccount getAccountByNumber(String accountNumber) {
        return bankAccountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new RuntimeException("Account not found: " + accountNumber));
    }

    private AccountSummaryDTO toDTO(BankAccount a) {
        return new AccountSummaryDTO(
                a.getAccountId(), a.getAccountNumber(), a.getAccountType(),
                a.getBalance(), a.getAvailableBalance(), a.getAccountStatus(), a.getOpenedDate()
        );
    }
}
