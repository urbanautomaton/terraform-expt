SHELL 		 := /bin/bash
SRC_DIR    := src
OUT_DIR    := out
STATE_DIR  := state
TF_SRC     := $(OUT_DIR)/terraform.tf
STATE_FILE := $(STATE_DIR)/terraform.tfstate
TERRAFORM  := terraform
TERRAFRAME := .bin/terraframe

.PHONY: plan apply show destroy clean

$(OUT_DIR)/terraform.tf: $(SRC_DIR)/terraform.rb
	mkdir -p $(OUT_DIR)
	$(TERRAFRAME) -f $< -p > $@

plan: $(TF_SRC)
	mkdir -p $(STATE_DIR)
	$(TERRAFORM) plan -refresh -state=$(STATE_FILE) $(OUT_DIR)

apply: $(TF_SRC)
	mkdir -p $(STATE_DIR)
	$(TERRAFORM) apply -refresh -state=$(STATE_FILE) $(OUT_DIR)

show: $(TF_SRC)
	$(TERRAFORM) show $(STATE_FILE)

destroy: $(TF_SRC)
	$(TERRAFORM) destroy -refresh -state=$(STATE_FILE) $(OUT_DIR)

clean:
	rm -f out/*
