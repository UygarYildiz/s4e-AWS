#!/bin/bash
# Network Policy Test Scripti

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Network Policy Test Başlatılıyor...${NC}"
echo "--------------------------------------"

# Namespace'lerin varlığını kontrol et
echo -e "${YELLOW}[1/5] Namespace'ler kontrol ediliyor...${NC}"
if kubectl get namespace codegen &>/dev/null && kubectl get namespace nonamens &>/dev/null; then
    echo -e "${GREEN}✓ codegen ve nonamens namespace'leri mevcut${NC}"
else
    echo -e "${RED}✗ Namespace'ler bulunamadı. Lütfen önce namespace'leri oluşturun.${NC}"
    exit 1
fi

# Pod'ların çalışıp çalışmadığını kontrol et
echo -e "${YELLOW}[2/5] Pod'lar kontrol ediliyor...${NC}"
CODEGEN_PODS=$(kubectl get pods -n codegen -o name 2>/dev/null | wc -l)
NONAMENS_PODS=$(kubectl get pods -n nonamens -o name 2>/dev/null | wc -l)

if [ "$CODEGEN_PODS" -gt 0 ] && [ "$NONAMENS_PODS" -gt 0 ]; then
    echo -e "${GREEN}✓ Her iki namespace'de de çalışan pod'lar mevcut${NC}"
    echo "  - codegen namespace'inde $CODEGEN_PODS pod"
    echo "  - nonamens namespace'inde $NONAMENS_PODS pod"
else
    echo -e "${RED}✗ Bazı namespace'lerde çalışan pod bulunamadı.${NC}"
    [ "$CODEGEN_PODS" -eq 0 ] && echo -e "${RED}  - codegen namespace'inde pod bulunamadı${NC}"
    [ "$NONAMENS_PODS" -eq 0 ] && echo -e "${RED}  - nonamens namespace'inde pod bulunamadı${NC}"
    exit 1
fi

# Network policy'lerin varlığını kontrol et
echo -e "${YELLOW}[3/5] Network policy'ler kontrol ediliyor...${NC}"
if kubectl get networkpolicy -n codegen deny-from-nonamens &>/dev/null; then
    echo -e "${GREEN}✓ codegen namespace'inde deny-from-nonamens policy'si mevcut${NC}"
else
    echo -e "${RED}✗ codegen namespace'inde deny-from-nonamens policy'si bulunamadı${NC}"
    exit 1
fi

# nonamens'den codegen'e erişim testi
echo -e "${YELLOW}[4/5] nonamens'den codegen'e erişim testi yapılıyor...${NC}"
NONAMENS_POD=$(kubectl get pod -n nonamens -o name | head -n 1 | cut -d'/' -f2)
CODEGEN_SVC=$(kubectl get svc -n codegen -o name | head -n 1 | cut -d'/' -f2)

if [ -z "$NONAMENS_POD" ] || [ -z "$CODEGEN_SVC" ]; then
    echo -e "${RED}✗ Test için gerekli pod veya servis bulunamadı${NC}"
    exit 1
fi

echo "nonamens namespace'indeki $NONAMENS_POD pod'undan codegen namespace'indeki $CODEGEN_SVC servisine erişim deneniyor..."

# Ping testi
PING_RESULT=$(kubectl exec -n nonamens $NONAMENS_POD -- ping -c 2 -W 2 $CODEGEN_SVC.codegen.svc.cluster.local 2>&1)
if echo "$PING_RESULT" | grep -q "100% packet loss" || echo "$PING_RESULT" | grep -q "command terminated with exit code 1"; then
    echo -e "${GREEN}✓ Ping engellendi - Network policy çalışıyor${NC}"
else
    echo -e "${RED}✗ Ping engellenmedi - Network policy çalışmıyor olabilir${NC}"
    echo "$PING_RESULT"
fi

# HTTP testi
HTTP_RESULT=$(kubectl exec -n nonamens $NONAMENS_POD -- curl -s --connect-timeout 5 $CODEGEN_SVC.codegen.svc.cluster.local 2>&1)
if echo "$HTTP_RESULT" | grep -q "Connection timed out" || echo "$HTTP_RESULT" | grep -q "command terminated with exit code"; then
    echo -e "${GREEN}✓ HTTP isteği engellendi - Network policy çalışıyor${NC}"
else
    echo -e "${RED}✗ HTTP isteği engellenmedi - Network policy çalışmıyor olabilir${NC}"
    echo "$HTTP_RESULT"
fi

# codegen'den nonamens'e erişim testi (bu yönde engelleme olmamalı)
echo -e "${YELLOW}[5/5] codegen'den nonamens'e erişim testi yapılıyor...${NC}"
CODEGEN_POD=$(kubectl get pod -n codegen -o name | head -n 1 | cut -d'/' -f2)
NONAMENS_SVC=$(kubectl get svc -n nonamens -o name | head -n 1 | cut -d'/' -f2)

if [ -z "$CODEGEN_POD" ] || [ -z "$NONAMENS_SVC" ]; then
    echo -e "${RED}✗ Test için gerekli pod veya servis bulunamadı${NC}"
    exit 1
fi

echo "codegen namespace'indeki $CODEGEN_POD pod'undan nonamens namespace'indeki $NONAMENS_SVC servisine erişim deneniyor..."

# HTTP testi
HTTP_RESULT=$(kubectl exec -n codegen $CODEGEN_POD -- curl -s --connect-timeout 5 $NONAMENS_SVC.nonamens.svc.cluster.local 2>&1)
if echo "$HTTP_RESULT" | grep -q "Connection timed out" || echo "$HTTP_RESULT" | grep -q "command terminated with exit code"; then
    echo -e "${RED}✗ HTTP isteği engellendi - Bu yönde engelleme olmamalıydı${NC}"
    echo "$HTTP_RESULT"
else
    echo -e "${GREEN}✓ HTTP isteği başarılı - Bu yönde engelleme yok${NC}"
fi

echo "--------------------------------------"
echo -e "${YELLOW}Network Policy Test Tamamlandı${NC}"
