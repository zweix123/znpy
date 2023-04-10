# znpy
>二次开发于[vnpy](https://github.com/vnpy/vnpy)

## Install
> 目前还在学习中, 得益于poetry管理依赖的方式是独立的，我将必要或者普通的依赖由poetry管理，特殊的或者不计划放在项目中的依赖手动管理

1. 下载大部分依赖
    ```bash
    poetry install
    ```

2. 下载talib
    1. 使用pip（**进入虚拟环境**）
        ```bash
        pip install ta-lib
        ```

    2. （如果失败）使用whl下载：[网址](https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib)
        ```bash
        pip install xxx.whl
        ```

3. 下载vnpy某些模块：
    ```bash
    pip install vnpy_rqdata
    ```

## Develop

推荐我个人的对vnpy的源码解析[笔记](https://github.com/zweix123/CS-notes/blob/master/Quant/vnpy.md)
> 我的笔记可能重引导而不是逐字分析，还是要自己静下心来看代码