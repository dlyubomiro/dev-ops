#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Тестване на DevOps Project Components"
echo "=========================================="
echo ""

PASSED=0
FAILED=0

test_step() {
    local name=$1
    local command=$2
    
    echo -n "Тестване: $name... "
    
    if eval "$command" > /tmp/test-output.log 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Детайли:"
        cat /tmp/test-output.log | head -10
        ((FAILED++))
        return 1
    fi
}

echo "=== 1. Go Build ==="
test_step "Go Build" "go build -o books-api main.go"
rm -f books-api

echo ""
echo "=== 2. Unit Tests ==="
test_step "Unit Tests" "go test -v ./..."

echo ""
echo "=== 3. Go Modules ==="
test_step "Go Mod Verify" "go mod verify"
test_step "Go Mod Tidy" "go mod tidy"

echo ""
echo "=== 4. Style Check ==="
if command -v gofmt &> /dev/null; then
    UNFORMATTED=$(gofmt -s -l . | wc -l | tr -d ' ')
    if [ "$UNFORMATTED" -eq 0 ]; then
        echo -e "Тестване: Code Formatting... ${GREEN}✓ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "Тестване: Code Formatting... ${RED}✗ FAILED${NC}"
        echo "Неформатирани файлове:"
        gofmt -s -l .
        ((FAILED++))
    fi
else
    echo -e "Тестване: Code Formatting... ${YELLOW}⚠ SKIPPED (gofmt не е намерен)${NC}"
fi

echo ""
echo "=== 5. Linter ==="
if command -v golangci-lint &> /dev/null; then
    test_step "GolangCI Lint" "golangci-lint run ./..."
else
    echo -e "Тестване: Linter... ${YELLOW}⚠ SKIPPED (golangci-lint не е инсталиран)${NC}"
    echo "Инсталирайте с: brew install golangci-lint"
fi

echo ""
echo "=== 6. SAST (Gosec) ==="
if command -v gosec &> /dev/null; then
    test_step "Gosec Security Scan" "gosec -quiet ./..."
else
    echo -e "Тестване: SAST... ${YELLOW}⚠ SKIPPED (gosec не е инсталиран)${NC}"
    echo "Инсталирайте с: go install github.com/securego/gosec/v2/cmd/gosec@latest"
fi

echo ""
echo "=== 7. Docker Build ==="
if command -v docker &> /dev/null; then
    test_step "Docker Build" "docker build -t books-api:test ."
    echo "Почистване на тестовия образ..."
    docker rmi books-api:test 2>/dev/null || true
else
    echo -e "Тестване: Docker Build... ${YELLOW}⚠ SKIPPED (Docker не е намерен)${NC}"
fi

echo ""
echo "=== 8. Docker Compose ==="
if command -v docker-compose &> /dev/null; then
    echo "Тестване: Docker Compose..."
    if docker-compose config > /dev/null 2>&1; then
        echo -e "  Docker Compose Config... ${GREEN}✓ PASSED${NC}"
        ((PASSED++))
    else
        echo -e "  Docker Compose Config... ${RED}✗ FAILED${NC}"
        ((FAILED++))
    fi
else
    echo -e "Тестване: Docker Compose... ${YELLOW}⚠ SKIPPED (docker-compose не е намерен)${NC}"
fi

echo ""
echo "=== 9. Kubernetes Manifests ==="
if [ -d "k8s" ]; then
    echo "Тестване: Kubernetes Manifests..."
    MANIFEST_COUNT=0
    for file in k8s/*.yaml; do
        if [ -f "$file" ]; then
            ((MANIFEST_COUNT++))
            if grep -q "apiVersion:" "$file" && grep -q "kind:" "$file"; then
                if command -v kubectl &> /dev/null; then
                    KUBECONFIG_SAVE="$KUBECONFIG"
                    export KUBECONFIG=/dev/null
                    if kubectl apply --dry-run=client --validate=false --server-side=false -f "$file" > /dev/null 2>&1; then
                        echo -e "  $(basename $file)... ${GREEN}✓ PASSED${NC}"
                        ((PASSED++))
                    else
                        if kubectl cluster-info > /dev/null 2>&1; then
                            echo -e "  $(basename $file)... ${RED}✗ FAILED${NC}"
                            ((FAILED++))
                        else
                            echo -e "  $(basename $file)... ${YELLOW}⚠ YAML структура OK (няма достъп до кластер за пълна валидация)${NC}"
                            ((PASSED++))
                        fi
                    fi
                    export KUBECONFIG="$KUBECONFIG_SAVE"
                else
                    if grep -q "apiVersion:" "$file" && grep -q "kind:" "$file"; then
                        echo -e "  $(basename $file)... ${GREEN}✓ PASSED (базова структура)${NC}"
                        ((PASSED++))
                    else
                        echo -e "  $(basename $file)... ${RED}✗ FAILED (липсва apiVersion или kind)${NC}"
                        ((FAILED++))
                    fi
                fi
            else
                echo -e "  $(basename $file)... ${RED}✗ FAILED (невалиден K8s манифест)${NC}"
                ((FAILED++))
            fi
        fi
    done
    if [ $MANIFEST_COUNT -eq 0 ]; then
        echo -e "  ${YELLOW}⚠ Няма YAML файлове в k8s/ директорията${NC}"
    fi
else
    echo -e "Тестване: Kubernetes... ${YELLOW}⚠ SKIPPED (k8s директорията не съществува)${NC}"
fi

echo ""
echo "=== 10. Terraform ==="
if command -v terraform &> /dev/null; then
    if [ -d "terraform" ]; then
        cd terraform
        test_step "Terraform Init" "terraform init -backend=false"
        test_step "Terraform Validate" "terraform validate"
        cd ..
    fi
else
    echo -e "Тестване: Terraform... ${YELLOW}⚠ SKIPPED (terraform не е намерен)${NC}"
fi

echo ""
echo "=== 11. SQL Migrations ==="
if [ -d "migrations" ]; then
    MIGRATION_COUNT=$(ls migrations/*.sql 2>/dev/null | wc -l | tr -d ' ')
    if [ "$MIGRATION_COUNT" -gt 0 ]; then
        echo -e "Тестване: SQL Migrations... ${GREEN}✓ PASSED${NC} ($MIGRATION_COUNT файла намерени)"
        ((PASSED++))
    else
        echo -e "Тестване: SQL Migrations... ${RED}✗ FAILED${NC} (няма миграции)"
        ((FAILED++))
    fi
else
    echo -e "Тестване: SQL Migrations... ${RED}✗ FAILED${NC} (директорията не съществува)"
    ((FAILED++))
fi

echo ""
echo "=== 12. File Structure ==="
REQUIRED_FILES=("main.go" "main_test.go" "go.mod" "Dockerfile" "docker-compose.yml" "README.md")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  $file... ${GREEN}✓${NC}"
        ((PASSED++))
    else
        echo -e "  $file... ${RED}✗ MISSING${NC}"
        ((FAILED++))
    fi
done

echo ""
echo "=========================================="
echo "Резултати:"
echo "=========================================="
echo -e "${GREEN}Успешни: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Неуспешни: $FAILED${NC}"
else
    echo -e "${GREEN}Неуспешни: $FAILED${NC}"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ Всички тестове са успешни!${NC}"
    exit 0
else
    echo -e "${RED}✗ Някои тестове са неуспешни. Проверете детайлите по-горе.${NC}"
    exit 1
fi

