# mojson Benchmark Makefile
#
# CPU: mojson (via simdjson FFI)
# GPU: mojson (optionally vs cuJSON on NVIDIA)
#
# Usage:
#   make cpu                    # CPU benchmark
#   make gpu                    # GPU benchmark (mojson only)
#   make gpu-cujson             # GPU benchmark (mojson vs cuJSON, requires cuJSON)
#   make gpu-large              # GPU benchmark (804MB file)

NVCC := nvcc
NVCC_FLAGS := -O3 -w -std=c++17 -arch=sm_100

CUJSON_DIR := cuJSON
DATASET_DIR := datasets
BUILD_DIR := build

# Default datasets
CPU_FILE ?= $(DATASET_DIR)/twitter.json
GPU_FILE ?= $(DATASET_DIR)/twitter.json
GPU_LARGE_FILE ?= $(DATASET_DIR)/twitter_large_record.json

PIXI := /home/ubuntu/.pixi/bin/pixi

.PHONY: all clean cpu gpu gpu-cujson gpu-cujson-large gpu-large build-cpu build-gpu check-cujson

all: $(BUILD_DIR)/bench_cpu $(BUILD_DIR)/bench_gpu

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Build mojson CPU benchmark binary
$(BUILD_DIR)/bench_cpu: mojo/bench_cpu.mojo | $(BUILD_DIR)
	@echo "Building mojson CPU benchmark..."
	@cd .. && $(PIXI) run mojo build -I . -o benchmark/$(BUILD_DIR)/bench_cpu benchmark/mojo/bench_cpu.mojo

# Build mojson GPU benchmark binary
$(BUILD_DIR)/bench_gpu: mojo/bench_gpu.mojo | $(BUILD_DIR)
	@echo "Building mojson GPU benchmark..."
	@cd .. && $(PIXI) run mojo build -I . -o benchmark/$(BUILD_DIR)/bench_gpu benchmark/mojo/bench_gpu.mojo

# =============================================================================
# CPU Benchmark
# =============================================================================
build-cpu: $(BUILD_DIR)/bench_cpu

cpu: $(BUILD_DIR)/bench_cpu
	@echo ""
	@echo "========================================================================"
	@echo "CPU Benchmark: mojson (via simdjson FFI)"
	@echo "========================================================================"
	@echo ""
	@cd .. && benchmark/$(BUILD_DIR)/bench_cpu benchmark/$(CPU_FILE)

# =============================================================================
# GPU Benchmark (mojson only)
# =============================================================================
build-gpu: $(BUILD_DIR)/bench_gpu

gpu: $(BUILD_DIR)/bench_gpu
	@echo ""
	@echo "========================================================================"
	@echo "GPU Benchmark: mojson"
	@echo "========================================================================"
	@echo ""
	@cd .. && benchmark/$(BUILD_DIR)/bench_gpu benchmark/$(GPU_FILE)

gpu-large: $(BUILD_DIR)/bench_gpu
	@if [ -f "$(GPU_LARGE_FILE)" ]; then \
		echo ""; \
		echo "========================================================================"; \
		echo "GPU Benchmark: Large Dataset (twitter_large_record.json - 804MB)"; \
		echo "========================================================================"; \
		echo ""; \
		cd .. && benchmark/$(BUILD_DIR)/bench_gpu benchmark/$(GPU_LARGE_FILE); \
	else \
		echo "Large dataset not found. Download from cuJSON Google Drive:"; \
		echo "  https://drive.google.com/drive/folders/1PkDEy0zWOkVREfL7VuINI-m9wJe45P2Q"; \
		echo "Place twitter_large_record.json in benchmark/datasets/"; \
	fi

# =============================================================================
# GPU Benchmark with cuJSON comparison (NVIDIA only)
# =============================================================================
check-cujson:
	@if [ ! -f "$(CUJSON_DIR)/paper_reproduced/src/cuJSON-standardjson.cu" ]; then \
		echo "Error: cuJSON not found."; \
		echo "Download it first: cd benchmark && git clone https://github.com/AutomataLab/cuJSON.git"; \
		exit 1; \
	fi

$(CUJSON_DIR)/build:
	mkdir -p $(CUJSON_DIR)/build

$(CUJSON_DIR)/build/cujson_benchmark: $(CUJSON_DIR)/paper_reproduced/src/cuJSON-standardjson.cu | $(CUJSON_DIR)/build
	$(NVCC) $(NVCC_FLAGS) -o $@ $<

gpu-cujson: check-cujson $(CUJSON_DIR)/build/cujson_benchmark $(BUILD_DIR)/bench_gpu
	@echo ""
	@echo "========================================================================"
	@echo "GPU Benchmark: mojson vs cuJSON"
	@echo "========================================================================"
	@echo ""
	@echo "--- cuJSON (CUDA C++) ---"
	@$(CUJSON_DIR)/build/cujson_benchmark -b $(GPU_FILE)
	@echo ""
	@cd .. && benchmark/$(BUILD_DIR)/bench_gpu benchmark/$(GPU_FILE)

gpu-cujson-large: check-cujson $(CUJSON_DIR)/build/cujson_benchmark $(BUILD_DIR)/bench_gpu
	@if [ -f "$(GPU_LARGE_FILE)" ]; then \
		echo ""; \
		echo "========================================================================"; \
		echo "GPU Benchmark (vs cuJSON): Large Dataset (twitter_large_record.json - 804MB)"; \
		echo "========================================================================"; \
		echo ""; \
		echo "--- cuJSON (CUDA C++) ---"; \
		$(CUJSON_DIR)/build/cujson_benchmark -b $(GPU_LARGE_FILE); \
		echo ""; \
		cd .. && benchmark/$(BUILD_DIR)/bench_gpu benchmark/$(GPU_LARGE_FILE); \
	else \
		echo "Large dataset not found. Download from cuJSON Google Drive:"; \
		echo "  https://drive.google.com/drive/folders/1PkDEy0zWOkVREfL7VuINI-m9wJe45P2Q"; \
		echo "Place twitter_large_record.json in benchmark/datasets/"; \
	fi

clean:
	rm -rf $(BUILD_DIR) $(CUJSON_DIR)/build
