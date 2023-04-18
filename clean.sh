#!/bin/bash

# 删除项目根目录下的 .mypy_cache 目录
rm -rf .mypy_cache

# 删除各个目录下的 __pycache__ 文件
find . -type d -print0 | while read -d $'\0' dir; do
    path="${dir}/__pycache__"
    if [ -d "$path" ]; then
        rm -rf "$path"
    fi
done