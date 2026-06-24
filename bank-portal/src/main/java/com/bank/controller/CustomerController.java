package com.bank.controller;

import com.bank.entity.Customer;
import com.bank.repository.CustomerRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/customers")
@CrossOrigin(origins = "*")
public class CustomerController {

    private final CustomerRepository customerRepository;

    public CustomerController(CustomerRepository customerRepository) {
        this.customerRepository = customerRepository;
    }

    @GetMapping("/verify")
    public ResponseEntity<Map<String, Object>> verify(
            @RequestParam String email,
            @RequestParam String phone) {
        Optional<Customer> customer = customerRepository.findByEmail(email);
        if (customer.isPresent() && normalizePhone(customer.get().getPhone()).equals(normalizePhone(phone))) {
            return ResponseEntity.ok(Map.of(
                "verified", true,
                "customerId", customer.get().getCustomerId(),
                "name", customer.get().getFullName()
            ));
        }
        return ResponseEntity.ok(Map.of("verified", false));
    }

    private String normalizePhone(String phone) {
        return phone == null ? "" : phone.replaceAll("[^0-9]", "");
    }
}
