#!/bin/bash
echo "Stopping all bank servers..."
lsof -ti:9081,8092,8095 | xargs kill 2>/dev/null && echo "All servers stopped." || echo "No servers were running."
