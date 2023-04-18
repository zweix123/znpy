# znpy
>二次开发于[vnpy](https://github.com/vnpy)

## Install
>目前还在学习中, 得益于poetry管理依赖的方式是独立的，我将必要或者普通的依赖由poetry管理，特殊的或者不计划放在项目中的依赖手动管理

1. 下载大部分依赖：

    ```bash
    poetry install
    ```

2. 进入虚拟环境（下面的操作都要保证您在虚拟环境中）

    ```bash
    poetry shell
    ```

3. 下载特殊依赖
    + 使用pip：
    
        ```bash
        pip install ta-lib
        ```
    
    + 如果失败（很可能失败），使用whl下载：
        >[网址](https://www.lfd.uci.edu/~gohlke/pythonlibs/#ta-lib)

4. 下载vnpy其他模块
    ```bash
    pip install vnpy_rqdata
    ```

## Develop

推荐我个人的对vnpy的源码解析[笔记](https://github.com/zweix123/CS-notes/blob/master/Quant/vnpy.md)
