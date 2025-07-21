# RoboTwin Multi-Policy Model Evaluation Docker

RoboTwin多策略模型测评的Docker环境，支持多种Policy的评估，包括ACT、DP、DP3、RDT、DexVLA、TinyVLA、Pi0等，提供完整的测评环境，支持GPU加速。

支持的Policy类型：**ACT** | **DP** | **DP3** | **RDT** | **DexVLA** | **TinyVLA** | **Pi0**

## Docker Compose配置

### 基础路径配置
编辑 `docker-compose.yml` 文件，设置正确的路径：

```yaml
volumes:
  - /your/server/model/path:/models           # 模型文件路径
  - /your/server/assets/path:/RoboTwin/assets # 资源文件路径
  - /your/server/results/path:/results        # 结果输出路径
```

### 代理设置
如需使用代理，修改docker-compose.yml中的build args：
```yaml
build:
  args:
    HTTP_PROXY: http://your-proxy-server:port
    HTTPS_PROXY: https://your-proxy-server:port
```

### GPU配置
```yaml
environment:
  - CUDA_VISIBLE_DEVICES=0,1  # 指定使用的GPU
runtime: nvidia                # 启用GPU支持
```

### 支持的服务列表
- `robotwin-act-eval` - ACT Policy评估服务
- `robotwin-dp-eval` - DP Policy评估服务  
- `robotwin-dp3-eval` - DP3 Policy评估服务
- `robotwin-rdt-eval` - RDT Policy评估服务
- `robotwin-dexvla-eval` - DexVLA Policy评估服务
- `robotwin-tinyvla-eval` - TinyVLA Policy评估服务
- `robotwin-pi0-eval` - Pi0 Policy评估服务

## 参数设置

所有Policy容器都接受以下位置参数（按顺序）：

| 参数                | 类型 | 默认值 | 说明         |
| ------------------- | ---- | ------ | ------------ |
| **task_name**       | 必需 | -      | 任务名称     |
| **task_config**     | 必需 | -      | 任务配置     |
| **ckpt_setting**    | 必需 | -      | 训练时的配置 |
| **expert_data_num** | 可选 | 50     | 专家数据数量 |
| **seed**            | 可选 | 0      | 随机种子     |
| **gpu_id**          | 可选 | 0      | GPU ID       |

## 使用方法

### 1. 构建镜像

```bash
# 构建特定Policy镜像
docker-compose build robotwin-act-eval

# 构建多个Policy镜像
docker-compose build robotwin-act-eval robotwin-dp-eval robotwin-rdt-eval

# 构建所有Policy镜像
docker-compose build
```

### 2. 基础评估

```bash
# ACT Policy评估
docker-compose run --rm robotwin-act-eval beat_block_hammer demo_clean demo_randomized

# DP Policy评估  
docker-compose run --rm robotwin-dp-eval beat_block_hammer demo_clean demo_randomized

# RDT Policy评估
docker-compose run --rm robotwin-rdt-eval beat_block_hammer demo_clean demo_randomized
```

### 3. 完整参数评估

```bash
# 使用所有参数运行ACT评估
docker-compose run --rm robotwin-act-eval beat_block_hammer demo_clean demo_randomized 100 42 0

# 使用所有参数运行DP评估
docker-compose run --rm robotwin-dp-eval beat_block_hammer demo_clean demo_randomized 100 42 0
```

### 4. 高级用法

```bash
# 指定特定GPU运行
CUDA_VISIBLE_DEVICES=1 docker-compose run --rm robotwin-act-eval beat_block_hammer demo_clean demo_randomized

# 使用多GPU
docker-compose run --rm -e CUDA_VISIBLE_DEVICES=0,1 robotwin-act-eval beat_block_hammer demo_clean demo_randomized

# 自定义结果目录
docker-compose run --rm -v /tmp/my_results:/results robotwin-act-eval beat_block_hammer demo_clean demo_randomized

# 进入容器调试
docker-compose run --rm --entrypoint /bin/bash robotwin-act-eval

# 查看帮助信息
docker-compose run --rm robotwin-act-eval --help
```

### 5. 常用管理命令

```bash
# 查看所有服务
docker-compose config --services

# 查看特定服务配置
docker-compose config robotwin-act-eval

# 停止所有容器
docker-compose down

# 查看镜像
docker-compose images

# 删除镜像
docker-compose down --rmi all
```

## 注意事项

- **资源准备**: 确保已下载RoboTwin资源文件和模型文件
- **目录结构**: 模型应放置在正确的目录结构中
- **GPU支持**: 所有Policy都需要GPU支持
- **内存要求**: 确保有足够的GPU和系统内存
- **权限问题**: 检查挂载目录的读写权限
