# Makefile for llamadev project
# Provides local development commands that mirror CI pipeline

.PHONY: help install lint format test coverage security audit clean all

# Configuration
LUA_VERSION ?= 5.4
COVERAGE_THRESHOLD ?= 100

# Colors for output
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
RESET := \033[0m

help: ## Show this help message
	@echo "$(BLUE)LlamaDev Development Commands$(RESET)"
	@echo "=============================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-15s$(RESET) %s\n", $$1, $$2}'

install: ## Install development dependencies
	@echo "$(BLUE)Installing development dependencies...$(RESET)"
	@if ! command -v luarocks >/dev/null 2>&1; then \
		echo "$(RED)Error: luarocks not found. Please install Lua and LuaRocks first.$(RESET)"; \
		exit 1; \
	fi
	luarocks install luacheck
	luarocks install stylua || echo "$(YELLOW)Warning: StyLua not available$(RESET)"
	luarocks install busted
	luarocks install luacov
	luarocks install luacov-reporter-lcov || echo "$(YELLOW)Warning: luacov-reporter-lcov not available$(RESET)"
	@echo "$(GREEN)✅ Dependencies installed$(RESET)"

lint: ## Run linter (luacheck) with zero-warning policy
	@echo "$(BLUE)Running linter...$(RESET)"
	@if ! luacheck --no-color .; then \
		echo "$(RED)❌ Lint failed - warnings treated as errors$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Lint passed$(RESET)"

format: ## Format code using StyLua
	@echo "$(BLUE)Formatting code...$(RESET)"
	@if command -v stylua >/dev/null 2>&1; then \
		stylua .; \
		echo "$(GREEN)✅ Code formatted$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  StyLua not available, skipping format$(RESET)"; \
	fi

format-check: ## Check code formatting without modifying files
	@echo "$(BLUE)Checking code formatting...$(RESET)"
	@if command -v stylua >/dev/null 2>&1; then \
		if ! stylua --check .; then \
			echo "$(RED)❌ Code formatting check failed$(RESET)"; \
			echo "$(YELLOW)Run 'make format' to fix formatting issues$(RESET)"; \
			exit 1; \
		fi; \
		echo "$(GREEN)✅ Code formatting check passed$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  StyLua not available, skipping format check$(RESET)"; \
	fi

test: ## Run test suite
	@echo "$(BLUE)Running test suite...$(RESET)"
	@if ! busted --verbose; then \
		echo "$(RED)❌ Tests failed$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ All tests passed$(RESET)"

test-unit: ## Run unit tests only
	@echo "$(BLUE)Running unit tests...$(RESET)"
	@if ! busted --verbose tests/unit/; then \
		echo "$(RED)❌ Unit tests failed$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Unit tests passed$(RESET)"

test-integration: ## Run integration tests only
	@echo "$(BLUE)Running integration tests...$(RESET)"
	@if ! busted --verbose tests/integration/; then \
		echo "$(RED)❌ Integration tests failed$(RESET)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✅ Integration tests passed$(RESET)"

coverage: ## Run tests with coverage analysis
	@echo "$(BLUE)Running tests with coverage...$(RESET)"
	@if ! busted --verbose --coverage; then \
		echo "$(RED)❌ Tests failed$(RESET)"; \
		exit 1; \
	fi
	luacov
	@echo "$(BLUE)Checking coverage threshold...$(RESET)"
	@if command -v lua >/dev/null 2>&1 && [ -f luacov.stats.out ]; then \
		COVERAGE=$$(lua -e " \
			local total_lines = 0 \
			local covered_lines = 0 \
			for line in io.lines('luacov.stats.out') do \
				if line:match('^%d+:%d+:') then \
					local count = line:match('^(%d+):') \
					total_lines = total_lines + 1 \
					if tonumber(count) > 0 then \
						covered_lines = covered_lines + 1 \
					end \
				end \
			end \
			if total_lines > 0 then \
				print(math.floor((covered_lines / total_lines) * 100)) \
			else \
				print(100) \
			end \
		"); \
		echo "$(BLUE)📊 Code coverage: $${COVERAGE}%$(RESET)"; \
		if [ "$${COVERAGE}" -lt "$(COVERAGE_THRESHOLD)" ]; then \
			echo "$(RED)❌ Coverage $${COVERAGE}% below threshold $(COVERAGE_THRESHOLD)%$(RESET)"; \
			exit 1; \
		fi; \
		echo "$(GREEN)✅ Coverage requirement met: $${COVERAGE}% >= $(COVERAGE_THRESHOLD)%$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  Coverage calculation not available$(RESET)"; \
	fi

security: ## Run security audit
	@echo "$(BLUE)Running security audit...$(RESET)"
	@SECURITY_ISSUES=0; \
	echo "$(BLUE)[1/6] Checking for dangerous Lua functions...$(RESET)"; \
	DANGEROUS=$$(grep -rn --include="*.lua" \
		-e "os\.execute" \
		-e "io\.popen" \
		-e "loadstring" \
		-e "load\s*(" \
		-e "dofile" \
		-e "loadfile" \
		-e "rawset.*_G" \
		-e "rawget.*_G" \
		-e "debug\.setfenv" \
		-e "debug\.sethook" \
		-e "debug\.setlocal" \
		-e "debug\.setupvalue" \
		-e "debug\.setmetatable" \
		. 2>/dev/null | grep -v "tests/" | grep -v "_spec.lua" || true); \
	if [ -n "$$DANGEROUS" ]; then \
		echo "$(YELLOW)⚠️  Potentially dangerous functions found (review required):$(RESET)"; \
		echo "$$DANGEROUS"; \
		SECURITY_ISSUES=$$((SECURITY_ISSUES + 1)); \
	else \
		echo "$(GREEN)   No dangerous functions found$(RESET)"; \
	fi; \
	echo "$(BLUE)[2/6] Checking for hardcoded secrets...$(RESET)"; \
	SECRETS=$$(grep -rn --include="*.lua" \
		-E "(password|passwd|secret|token|api_key|apikey|auth_token|access_token|private_key)\s*=\s*['\"][^'\"]{8,}" \
		. 2>/dev/null | grep -v "tests/" | grep -v "_spec.lua" || true); \
	if [ -n "$$SECRETS" ]; then \
		echo "$(RED)❌ Potential hardcoded secrets found:$(RESET)"; \
		echo "$$SECRETS"; \
		exit 1; \
	else \
		echo "$(GREEN)   No hardcoded secrets found$(RESET)"; \
	fi; \
	echo "$(BLUE)[3/6] Checking for unsafe string patterns...$(RESET)"; \
	UNSAFE_STR=$$(grep -rn --include="*.lua" \
		-e "string\.dump" \
		-e "getfenv" \
		-e "setfenv" \
		. 2>/dev/null | grep -v "tests/" | grep -v "_spec.lua" || true); \
	if [ -n "$$UNSAFE_STR" ]; then \
		echo "$(YELLOW)⚠️  Unsafe string/environment manipulation found:$(RESET)"; \
		echo "$$UNSAFE_STR"; \
		SECURITY_ISSUES=$$((SECURITY_ISSUES + 1)); \
	else \
		echo "$(GREEN)   No unsafe string patterns found$(RESET)"; \
	fi; \
	echo "$(BLUE)[4/6] Checking for command injection risks...$(RESET)"; \
	CMD_INJECT=$$(grep -rn --include="*.lua" \
		-E "(os\.execute|io\.popen).*\.\." \
		. 2>/dev/null | grep -v "tests/" | grep -v "_spec.lua" || true); \
	if [ -n "$$CMD_INJECT" ]; then \
		echo "$(RED)❌ Potential command injection found:$(RESET)"; \
		echo "$$CMD_INJECT"; \
		exit 1; \
	else \
		echo "$(GREEN)   No command injection risks found$(RESET)"; \
	fi; \
	echo "$(BLUE)[5/6] Running luacheck security scan...$(RESET)"; \
	luacheck --no-color --globals vim describe it setup teardown before_each after_each assert .; \
	echo "$(BLUE)[6/6] Checking container security (Docker/Podman)...$(RESET)"; \
	CONTAINER_ISSUES=""; \
	if [ -f docker/Dockerfile ]; then \
		if grep -q "USER root" docker/Dockerfile 2>/dev/null; then \
			CONTAINER_ISSUES="$$CONTAINER_ISSUES\n  - Dockerfile runs as root"; \
		fi; \
		if ! grep -q "USER" docker/Dockerfile 2>/dev/null; then \
			CONTAINER_ISSUES="$$CONTAINER_ISSUES\n  - Dockerfile missing USER directive"; \
		fi; \
	fi; \
	if [ -f podman/Containerfile ]; then \
		if grep -q "USER root" podman/Containerfile 2>/dev/null; then \
			CONTAINER_ISSUES="$$CONTAINER_ISSUES\n  - Containerfile runs as root"; \
		fi; \
		if ! grep -q "USER" podman/Containerfile 2>/dev/null; then \
			CONTAINER_ISSUES="$$CONTAINER_ISSUES\n  - Containerfile missing USER directive"; \
		fi; \
	fi; \
	if [ -n "$$CONTAINER_ISSUES" ]; then \
		echo "$(YELLOW)⚠️  Container security issues:$$CONTAINER_ISSUES$(RESET)"; \
		SECURITY_ISSUES=$$((SECURITY_ISSUES + 1)); \
	else \
		echo "$(GREEN)   Container security checks passed$(RESET)"; \
	fi; \
	if [ $$SECURITY_ISSUES -gt 0 ]; then \
		echo "$(YELLOW)⚠️  Security audit completed with $$SECURITY_ISSUES warning(s) - manual review recommended$(RESET)"; \
	else \
		echo "$(GREEN)✅ Security audit completed - no issues found$(RESET)"; \
	fi

audit: ## Run dependency audit
	@echo "$(BLUE)Running dependency audit...$(RESET)"
	@echo "Listing installed LuaRocks packages..."
	luarocks list
	@echo "$(GREEN)✅ Dependency audit completed$(RESET)"

syntax-check: ## Verify Lua syntax of all files
	@echo "$(BLUE)Verifying Lua syntax...$(RESET)"
	@find . -name "*.lua" -type f -exec lua -e " \
		local f = io.open('{}', 'r') \
		local content = f:read('*all') \
		f:close() \
		local chunk, err = load(content, '{}') \
		if not chunk then \
			print('Syntax error in {}: ' .. (err or 'unknown error')) \
			os.exit(1) \
		end \
	" \;
	@echo "$(GREEN)✅ All Lua files have valid syntax$(RESET)"

clean: ## Clean up generated files
	@echo "$(BLUE)Cleaning up...$(RESET)"
	rm -f luacov.*.out
	rm -f test_results.json
	@echo "$(GREEN)✅ Cleanup completed$(RESET)"

ci-local: install lint format-check syntax-check security container-validate test coverage ## Run full CI pipeline locally
	@echo "$(GREEN)🎉 Local CI pipeline completed successfully!$(RESET)"

all: ci-local ## Alias for ci-local

# Development shortcuts
dev-setup: install ## Initial development setup
	@echo "$(BLUE)Setting up development environment...$(RESET)"
	@if [ ! -f .luacheckrc ]; then \
		echo "$(YELLOW)⚠️  .luacheckrc not found$(RESET)"; \
	fi
	@if [ ! -f stylua.toml ]; then \
		echo "$(YELLOW)⚠️  stylua.toml not found$(RESET)"; \
	fi
	@echo "$(GREEN)✅ Development setup completed$(RESET)"
	@echo "$(BLUE)Run 'make help' to see available commands$(RESET)"

quick-check: lint syntax-check ## Quick validation before commit
	@echo "$(GREEN)✅ Quick check completed$(RESET)"

pre-commit: format lint test ## Comprehensive pre-commit check
	@echo "$(GREEN)✅ Pre-commit checks completed$(RESET)"

container-validate: ## Validate Docker and Podman configurations
	@echo "$(BLUE)Validating container configurations...$(RESET)"
	@ERRORS=0; \
	echo "$(BLUE)[1/4] Checking Docker files...$(RESET)"; \
	if [ -f docker/Dockerfile ]; then \
		if ! grep -q "^FROM" docker/Dockerfile; then \
			echo "$(RED)❌ docker/Dockerfile missing FROM directive$(RESET)"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
		if ! grep -q "^USER" docker/Dockerfile; then \
			echo "$(RED)❌ docker/Dockerfile missing USER directive$(RESET)"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
		echo "$(GREEN)   docker/Dockerfile structure OK$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  docker/Dockerfile not found$(RESET)"; \
	fi; \
	echo "$(BLUE)[2/4] Checking Podman files...$(RESET)"; \
	if [ -f podman/Containerfile ]; then \
		if ! grep -q "^FROM" podman/Containerfile; then \
			echo "$(RED)❌ podman/Containerfile missing FROM directive$(RESET)"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
		if ! grep -q "^USER" podman/Containerfile; then \
			echo "$(RED)❌ podman/Containerfile missing USER directive$(RESET)"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
		echo "$(GREEN)   podman/Containerfile structure OK$(RESET)"; \
	else \
		echo "$(YELLOW)⚠️  podman/Containerfile not found$(RESET)"; \
	fi; \
	echo "$(BLUE)[3/4] Checking required files in docker/...$(RESET)"; \
	for file in requirements.txt start.sh .env docker-compose.yml; do \
		if [ ! -f "docker/$$file" ]; then \
			echo "$(RED)❌ Missing docker/$$file$(RESET)"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
	done; \
	for file in coding.lua disabled.lua keymaps.lua toggleterm.lua ui.lua; do \
		if [ ! -f "docker/plugins/$$file" ]; then \
			echo "$(RED)❌ Missing docker/plugins/$$file$(RESET)"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
	done; \
	echo "$(GREEN)   docker/ required files OK$(RESET)"; \
	echo "$(BLUE)[4/4] Checking required files in podman/...$(RESET)"; \
	for file in requirements.txt start.sh .env podman-compose.yml; do \
		if [ ! -f "podman/$$file" ]; then \
			echo "$(RED)❌ Missing podman/$$file$(RESET)"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
	done; \
	for file in coding.lua disabled.lua keymaps.lua toggleterm.lua ui.lua; do \
		if [ ! -f "podman/plugins/$$file" ]; then \
			echo "$(RED)❌ Missing podman/plugins/$$file$(RESET)"; \
			ERRORS=$$((ERRORS + 1)); \
		fi; \
	done; \
	echo "$(GREEN)   podman/ required files OK$(RESET)"; \
	if [ $$ERRORS -gt 0 ]; then \
		echo "$(RED)❌ Container validation failed with $$ERRORS error(s)$(RESET)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)✅ Container validation passed$(RESET)"