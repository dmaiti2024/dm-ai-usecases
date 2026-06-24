package com.bank.mcp;

import com.bank.mcp.tools.AccountTools;
import com.bank.mcp.tools.CustomerTools;
import com.bank.mcp.tools.DisputeTools;
import com.bank.mcp.tools.TransactionTools;
import org.springframework.ai.tool.ToolCallbackProvider;
import org.springframework.ai.tool.method.MethodToolCallbackProvider;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

@SpringBootApplication
public class BankMcpServerApplication {
    public static void main(String[] args) {
        SpringApplication.run(BankMcpServerApplication.class, args);
    }

    @Bean
    public ToolCallbackProvider bankTools(
            TransactionTools transactionTools,
            AccountTools accountTools,
            CustomerTools customerTools,
            DisputeTools disputeTools) {
        return MethodToolCallbackProvider.builder()
                .toolObjects(transactionTools, accountTools, customerTools, disputeTools)
                .build();
    }
}
