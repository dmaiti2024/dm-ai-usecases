package com.bank.service;

import com.bank.dto.CategoryUpdateRequest;
import com.bank.dto.DisputeRequest;
import com.bank.dto.TransactionDTO;
import com.bank.dto.TransactionRequest;
import com.bank.entity.BankAccount;
import com.bank.entity.Dispute;
import com.bank.entity.Transaction;
import com.bank.repository.BankAccountRepository;
import com.bank.repository.DisputeRepository;
import com.bank.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final BankAccountRepository bankAccountRepository;
    private final DisputeRepository disputeRepository;

    public TransactionService(TransactionRepository transactionRepository,
                               BankAccountRepository bankAccountRepository,
                               DisputeRepository disputeRepository) {
        this.transactionRepository = transactionRepository;
        this.bankAccountRepository = bankAccountRepository;
        this.disputeRepository = disputeRepository;
    }

    @Transactional
    public TransactionDTO postTransaction(TransactionRequest request) {
        BankAccount account = bankAccountRepository.findByAccountNumber(request.accountNumber())
                .orElseThrow(() -> new RuntimeException("Account not found: " + request.accountNumber()));

        if ("DEBIT".equals(request.transactionType()) && account.getBalance().compareTo(request.amount()) < 0) {
            throw new RuntimeException("Insufficient funds");
        }

        Transaction txn = new Transaction();
        txn.setAccountId(account.getAccountId());
        txn.setTransactionDate(LocalDateTime.now());
        txn.setTransactionType(request.transactionType());
        txn.setAmount(request.amount());
        txn.setDescription(request.description());
        txn.setMerchantName(request.merchantName());
        txn.setReferenceNo(request.referenceNo() != null ? request.referenceNo() : UUID.randomUUID().toString().substring(0, 12).toUpperCase());
        txn.setStatus("COMPLETED");
        txn.setCreatedAt(LocalDateTime.now());
        txn = transactionRepository.save(txn);

        if ("CREDIT".equals(request.transactionType())) {
            account.setBalance(account.getBalance().add(request.amount()));
            account.setAvailableBalance(account.getAvailableBalance().add(request.amount()));
        } else {
            account.setBalance(account.getBalance().subtract(request.amount()));
            account.setAvailableBalance(account.getAvailableBalance().subtract(request.amount()));
        }
        bankAccountRepository.save(account);

        return toDTO(txn, account.getAccountNumber());
    }

    public List<TransactionDTO> getTransactionsByAccount(Long accountId) {
        BankAccount account = bankAccountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found"));
        return transactionRepository.findByAccountIdOrderByTransactionDateDesc(accountId)
                .stream().map(t -> toDTO(t, account.getAccountNumber())).collect(Collectors.toList());
    }

    public List<TransactionDTO> getTransactionsByCustomer(Long customerId) {
        List<BankAccount> accounts = bankAccountRepository.findByCustomerId(customerId);
        List<Long> accountIds = accounts.stream().map(BankAccount::getAccountId).collect(Collectors.toList());
        if (accountIds.isEmpty()) return List.of();
        return transactionRepository.findByAccountIdInOrderByTransactionDateDesc(accountIds)
                .stream()
                .map(t -> {
                    String accNo = accounts.stream()
                            .filter(a -> a.getAccountId().equals(t.getAccountId()))
                            .map(BankAccount::getAccountNumber).findFirst().orElse("");
                    return toDTO(t, accNo);
                }).collect(Collectors.toList());
    }

    public List<TransactionDTO> getDebitsByAccountAndDateRange(Long accountId, LocalDateTime start, LocalDateTime end) {
        BankAccount account = bankAccountRepository.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found"));
        return transactionRepository.findDebitsByAccountIdAndDateRange(accountId, start, end)
                .stream().map(t -> toDTO(t, account.getAccountNumber())).collect(Collectors.toList());
    }

    @Transactional
    public TransactionDTO updateCategory(CategoryUpdateRequest request) {
        Transaction txn = transactionRepository.findById(request.transactionId())
                .orElseThrow(() -> new RuntimeException("Transaction not found"));
        txn.setCategory(request.category());
        txn = transactionRepository.save(txn);
        BankAccount account = bankAccountRepository.findById(txn.getAccountId()).orElse(null);
        return toDTO(txn, account != null ? account.getAccountNumber() : "");
    }

    @Transactional
    public Dispute raiseDispute(DisputeRequest request) {
        Transaction txn = transactionRepository.findById(request.transactionId())
                .orElseThrow(() -> new RuntimeException("Transaction not found"));
        txn.setStatus("DISPUTED");
        transactionRepository.save(txn);

        Dispute dispute = new Dispute();
        dispute.setTransactionId(request.transactionId());
        dispute.setCustomerId(request.customerId());
        dispute.setRaisedBy(request.raisedBy());
        dispute.setDisputeReason(request.disputeReason());
        dispute.setDisputeStatus("OPEN");
        dispute.setRaisedDate(LocalDateTime.now());
        return disputeRepository.save(dispute);
    }

    public List<Dispute> getDisputesByCustomer(Long customerId) {
        return disputeRepository.findByCustomerId(customerId);
    }

    private TransactionDTO toDTO(Transaction t, String accountNumber) {
        return new TransactionDTO(
                t.getTransactionId(), t.getAccountId(), accountNumber,
                t.getTransactionDate(), t.getTransactionType(), t.getAmount(),
                t.getDescription(), t.getCategory(), t.getMerchantName(),
                t.getReferenceNo(), t.getStatus()
        );
    }
}
