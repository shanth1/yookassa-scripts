include .env
export

IDEMPOTENCE_KEY := $(shell date +%s)
API_URL := https://api.yookassa.ru/v3

# Просто цвета, чтобы было видно заголовки
YELLOW=\033[1;33m
NC=\033[0m

# --- КОМАНДЫ ---

pay:
	@echo "${YELLOW}>>> СОЗДАЮ ПЛАТЕЖ...${NC}"
	@# Мы просто делаем запрос и сразу показываем результат через jq
	@curl -s -X POST $(API_URL)/payments \
		-u $(SHOP_ID):$(SECRET_KEY) \
		-H "Idempotence-Key: $(IDEMPOTENCE_KEY)" \
		-H "Content-Type: application/json" \
		-d '{ \
			"amount": {"value": "$(AMOUNT)", "currency": "$(CURRENCY)"}, \
			"capture": true, \
			"confirmation": {"type": "redirect", "return_url": "$(RETURN_URL)"}, \
			"description": "$(DESCRIPTION)" \
		}' | jq .
	@echo "${YELLOW}>>> СКОПИРУЙ confirmation_url ВЫШЕ И ОТПРАВЬ КЛИЕНТУ${NC}"
	@echo "${YELLOW}>>> СКОПИРУЙ id ВЫШЕ В ФАЙЛ .env ДЛЯ ПРОВЕРКИ${NC}"

status:
	@echo "${YELLOW}>>> ПРОВЕРЯЮ СТАТУС $(PAYMENT_ID)...${NC}"
	@curl -s -X GET $(API_URL)/payments/$(PAYMENT_ID) \
		-u $(SHOP_ID):$(SECRET_KEY) \
		| jq .

refund:
	@echo "${YELLOW}>>> ДЕЛАЮ ВОЗВРАТ...${NC}"
	@curl -s -X POST $(API_URL)/refunds \
		-u $(SHOP_ID):$(SECRET_KEY) \
		-H "Idempotence-Key: $(IDEMPOTENCE_KEY)" \
		-H "Content-Type: application/json" \
		-d '{ "payment_id": "$(PAYMENT_ID)", "amount": {"value": "$(AMOUNT)", "currency": "$(CURRENCY)"} }' \
		| jq .
