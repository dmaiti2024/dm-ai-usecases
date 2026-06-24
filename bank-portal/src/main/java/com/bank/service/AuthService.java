package com.bank.service;

import com.bank.config.JwtUtil;
import com.bank.dto.LoginRequest;
import com.bank.dto.LoginResponse;
import com.bank.entity.Customer;
import com.bank.repository.CustomerRepository;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final CustomerRepository customerRepository;
    private final AuthenticationManager authManager;
    private final JwtUtil jwtUtil;

    public AuthService(CustomerRepository customerRepository, AuthenticationManager authManager, JwtUtil jwtUtil) {
        this.customerRepository = customerRepository;
        this.authManager = authManager;
        this.jwtUtil = jwtUtil;
    }

    public LoginResponse login(LoginRequest request) {
        authManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.username(), request.password()));
        Customer customer = customerRepository.findByUsername(request.username())
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        String token = jwtUtil.generateToken(customer.getUsername(), customer.getCustomerType(), customer.getCustomerId());
        return new LoginResponse(token, customer.getUsername(), customer.getFullName(),
                customer.getCustomerType(), customer.getCustomerId());
    }
}
