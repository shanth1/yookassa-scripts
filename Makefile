include .env
export

IDEMPOTENCE_KEY := $(shell date +%s)
API_URL := https://api.yookassa.ru/v3
LOG_FILE := history.log
TEMP_FILE := response.json

YELLOW=\033[1;33m
GREEN=\033[0;32m
CYAN=\033[0;36m
NC=\033[0m

pay:
	@echo "${YELLOW}>>> 1. ОТПРАВЛЯЮ ЗАПРОС...${NC}"
	@curl -s -X POST $(API_URL)/payments \
		-u $(SHOP_ID):$(SECRET_KEY) \
		-H "Idempotence-Key: $(IDEMPOTENCE_KEY)" \
		-H "Content-Type: application/json" \
		-d '{ \
			"amount": {"value": "$(AMOUNT)", "currency": "$(CURRENCY)"}, \
			"capture": true, \
			"confirmation": {"type": "redirect", "return_url": "$(RETURN_URL)"}, \
			"description": "$(DESCRIPTION)" \
		}' > $(TEMP_FILE)

	@echo "${GREEN}>>> 2. РЕЗУЛЬТАТ:${NC}"
	@cat $(TEMP_FILE) | jq -r '"URL ОПЛАТЫ: " + .confirmation.confirmation_url'
	@cat $(TEMP_FILE) | jq -r '"ID ПЛАТЕЖА: " + .id'

	@echo "$(shell date '+%Y-%m-%d %H:%M:%S') | $(AMOUNT) | $(DESCRIPTION) | $$(cat $(TEMP_FILE) | jq -r .id) | $$(cat $(TEMP_FILE) | jq -r .confirmation.confirmation_url)" >> $(LOG_FILE)
	@echo "${CYAN}>>> 3. СОХРАНЕНО В $(LOG_FILE)${NC}"

status:
	@echo "${YELLOW}>>> ПРОВЕРЯЮ СТАТУС $(PAYMENT_ID)...${NC}"
	@curl -s -X GET $(API_URL)/payments/$(PAYMENT_ID) \
		-u $(SHOP_ID):$(SECRET_KEY) \
		| jq -r '"СТАТУС: " + .status + " | СУММА: " + .amount.value'

refund:
	@echo "${YELLOW}>>> ДЕЛАЮ ВОЗВРАТ...${NC}"
	@curl -s -X POST $(API_URL)/refunds \
		-u $(SHOP_ID):$(SECRET_KEY) \
		-H "Idempotence-Key: $(IDEMPOTENCE_KEY)" \
		-H "Content-Type: application/json" \
		-d '{ "payment_id": "$(PAYMENT_ID)", "amount": {"value": "$(AMOUNT)", "currency": "$(CURRENCY)"} }' \
		| jq .

list:
	@echo "${CYAN}ПОСЛЕДНИЕ 5 ЗАПИСЕЙ:${NC}"
	@tail -n 5 $(LOG_FILE)
