#!/bin/bash

# RoboTwin ACT Model Evaluation Container Entrypoint

set -e

# 显示帮助信息
show_help() {
    cat << EOF
RoboTwin ACT Model Evaluation Container

Usage:
    docker run [docker-options] robotwin-act-eval [task_name] [task_config] [ckpt_setting] [expert_data_num] [seed] [gpu_id]

Parameters:
    task_name        Task name, e.g., beat_block_hammer (required)
    task_config      Task configuration (required)
    ckpt_setting     Checkpoint setting used during training (required)
    expert_data_num  Number of expert data used for training (default: 50)
    seed             Random seed (default: 0)
    gpu_id           GPU ID to use (default: 0)

Examples:
    # Basic evaluation
    docker run -v /path/to/model:/models \\
               -v /path/to/assets:/RoboTwin/assets \\
               -v /path/to/results:/results \\
               --gpus all \\
               robotwin-act-eval \\
               beat_block_hammer

    # Full parameter evaluation
    docker run -v /path/to/model:/models \\
               -v /path/to/assets:/RoboTwin/assets \\
               -v /path/to/results:/results \\
               --gpus all \\
               robotwin-act-eval \\
               beat_block_hammer demo_clean demo_randomized 100 42 0

Required Docker volumes:
    - Model directory: -v /host/path/to/model:/models
    - Assets directory: -v /host/path/to/assets:/RoboTwin/assets
    - Results directory: -v /host/path/to/results:/results

Notes:
    - Assets must be downloaded first using the official download script
    - The container requires GPU access (--gpus all)
    - Model should be placed in policy/ACT/act_ckpt/act-{task_name}/{ckpt_setting}-{expert_data_num}/
    - Results will be saved to the mounted results directory

EOF
}

# 检查是否有参数或显示帮助
if [ $# -eq 0 ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# 参数设置
task_name=${1:-""}
task_config=${2:-""}
ckpt_setting=${3:-""}
expert_data_num=${4:-"50"}
seed=${5:-"0"}
gpu_id=${6:-"0"}

# 检查必需参数
if [ -z "$task_name" ]; then
    echo "ERROR: Task name is required"
    show_help
    exit 1
fi

if [ -z "$task_config" ]; then
    echo "ERROR: Task config is required"
    show_help
    exit 1
fi

if [ -z "$ckpt_setting" ]; then
    echo "ERROR: Checkpoint setting is required"
    show_help
    exit 1
fi

echo "Starting RoboTwin ACT evaluation..."
echo "Task: $task_name"
echo "Config: $task_config"
echo "Checkpoint Setting: $ckpt_setting"
echo "Expert Data Num: $expert_data_num"
echo "Seed: $seed"
echo "GPU ID: $gpu_id"

# 检查必需的挂载点
echo "Checking required directories..."

# 检查assets目录
if [ ! -d "/RoboTwin/assets/objects" ]; then
    echo "ERROR: Assets directory not found or incomplete."
    echo "Please mount the assets directory: -v /path/to/assets:/RoboTwin/assets"
    echo "Assets should be downloaded using: bash script/_download_assets.sh"
    exit 1
fi

# 检查模型目录
model_path="/RoboTwin/policy/ACT/act_ckpt/act-${task_name}/${ckpt_setting}-${expert_data_num}"
if [ ! -d "/models" ]; then
    echo "ERROR: Model directory not mounted."
    echo "Please mount the model directory: -v /path/to/model:/models"
    exit 1
fi

# 检查results目录挂载点
if [ ! -w "/results" ]; then
    echo "WARNING: Results directory is not writable. Results may not persist."
    echo "Consider mounting: -v /path/to/results:/results"
fi

# 进入工作目录
cd /RoboTwin

# 复制模型文件到指定位置
echo "Preparing model files..."
mkdir -p "$model_path"
cp -r /models/* "$model_path/"
echo "Model files copied to: $model_path"

# 检查CUDA是否可用
echo "Checking CUDA availability..."
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA devices: {torch.cuda.device_count()}')" || {
    echo "WARNING: CUDA check failed. GPU evaluation may not work."
}

# 运行官方评估脚本
echo "Running evaluation using official eval.sh script..."
cd policy/ACT

# 设置CUDA环境变量
export CUDA_VISIBLE_DEVICES=$gpu_id

bash eval.sh "$task_name" "$task_config" "$ckpt_setting" "$expert_data_num" "$seed" "$gpu_id"

# 检查评估结果
if [ $? -eq 0 ]; then
    echo "Evaluation completed successfully!"
    
    # 复制结果到results目录
    if [ -d "/RoboTwin/eval_result" ]; then
        echo "Copying results to /results..."
        cp -r /RoboTwin/eval_result/* /results/ 2>/dev/null || true
        echo "Results copied to /results"
    fi
    
    # 显示结果目录内容
    echo "Generated files in /results:"
    ls -la /results/ 2>/dev/null || echo "No results found"
else
    echo "Evaluation failed!"
    exit 1
fi
