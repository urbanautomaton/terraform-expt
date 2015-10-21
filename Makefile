SHELL 		 := /bin/bash
SRC_DIR    := src
OUT_DIR    := out
TF_SRC     := $(OUT_DIR)/terraform.tf
STATE_FILE := state/terraform.tfstate
TERRAFORM  := terraform
TERRAFRAME := .bin/terraframe

.PHONY: plan apply

$(OUT_DIR)/terraform.tf: $(SRC_DIR)/terraform.rb
	$(TERRAFRAME) -f $< -p > $@

plan: $(TF_SRC)
	$(TERRAFORM) plan -refresh -state $(STATE_FILE) $(OUT_DIR)

apply: $(TF_SRC)
	$(TERRAFORM) apply -refresh -state $(STATE_FILE) $(OUT_DIR)
