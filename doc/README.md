## Install

+ 使用安装包：推荐使用vnpy官网安装包，如果担心和自己常用的Python环境冲突就把自己的环境删掉（狗头）
	+ 缺点：
		+ 只能用于win
		+ 要安装一个完整的Python环境
+ 手动构建：在Ubuntu上只能选择手动构建，但是提醒您的是vnpy的构建方式对机器原生的系统是侵入式的，无论是win还是Ubuntu都要抱着自己的环境被污染的准备
+ [我的项目](https://github.com/zweix123/znpy)：为了解决vnpy的部署对原生环境的破坏，我考虑将vnpy构建在由Poetrty维护的虚拟环境中，所以您可以在我的基础上进行构建，我已经完成了最困难的部分
	+ 最困难的部分：
		>官方提供了`requirements.txt`文件，那么还有什么困难呢？原因在下面两点。

		1. `ta-lib`的依赖是一般机器所没有的，这里建议使用手动下载`whl`文件的方式安装
		2. `PySide6`很容易在由Poetry维护的虚拟环境中出现依赖冲突，这里我的解决方法可以参考项目中的`pyproject.toml`文件

# Develop

+ 我会讨论的部分：
	+ 基础设施：RestClient，WebSocketClient、数据库、数据服务
	+ App：策略模块、回测模块
	+ Gateway：OKEX、Binance
		>交易的最底层要落实到对应平台的API上，发送HTTPS GET请求Python确实可以，但是这样直接简单的发送请求的话代码是不易维护，于是有各种各样的封装/抽象层，vnpy gateway即为vnpy对这些平台API的封装。

## UI

>为什么选择从UI入手？
>没有为什么、个人觉得合适

+ 这部分倒不需要必须有Qt基础，但是最好有图形化编程的基础，有很多写法很“图形化”，另外Qt有独特的概念：信号和槽
	+ 信号就像这样`signal: QtCore.Signal = QtCore.Signal(参数)`，每个信号可以绑定一个槽`signal.connect(槽函数)`，如果信号调用`emit`方法即会调用对应的槽函数  
		其中信号的参数即为通信的数据，在emit中放入，要求绑定的槽函数有相同的参数

代码在`vnpy/trader/ui`目录下，先看`qt.py`再看`mainwindow.py`，文件`widget.py`中的都是辅助性窗口，看到哪里再跳转过去。

+ `qt.py`：定义、配置并返回了一个QApplication作为后台程序，`create_app`函数参数并非窗口标题，而是用于windows进程管理的
+ `mainwindows.py`：定义、配置并返回了一个QWidget作为主窗口，这里的`windows_title`才是窗口标题
	+ 标题`windows_title`，其作用不仅是窗口title，还和软件配置的保存路径有关，可以去子串`TRADER_DIR`被定义的文件`vnpy/trader/setting.py`中看一下，返回它的函数是先判断项目路径下有无名为`.vntrader`的目录，没有则在用户根目录创建。所以这个变量即为用户根目录，和其对应的`TEMP_DIR`即为软件配置文件所在目录  
		`windows_title`还有一个作用，看下面的代码
		```python
		settings: QtCore.QSettings = QtCore.QSettings(self.window_title, name)
		```
		关于`QtCore.QSettings`的具体功能我不清楚，但是观测结果是这是对文件`~/.config/${windows_title}/name`进行读写，代码中作为name的有`custom.conf`和`default.conf`
		>这也是vnpy狗血的地方，在Linux中`TRADER_DIR`是一个路径，这个路径作为一个字符串的子串，然后按这个字符串去创建目录则会连续嵌套创建多个。

	+ 在`init_menu`方法中有些值得讨论的地方（从`__init__`到`init_ui`到`init_menu`）
		+ 在“连接”（原代码叫“系统”）中，如何获得`gateway_names`设计到引擎部分，这里留下个hook先暂时跳过，我们看对每个gateway是怎么处理的。
			+ 首先是`self.connect`方法，在这里创建了一个`ConnectDialog`类，在这个类中首先是一堆根据gateway配置来设置界面的语句，然后进入了它的`connect`方法，在这里保存配置，调用主引擎的`connect`方法，跳转过去其实主引擎是调用对应gateway的`connect`方法（这里也算一个hook）
				+ 关于配置：在`__init__`中的`filename`即为配置名，然后在`init_ui`中通过`load_json`从本地载入内存，我们需要进入这个函数看一下，因为它有些功能没有在名字中表达出来（坑），首先路径是通过`get_file_path`得到的，这个函数是通过`TEMP_DIR`拼接出来的，到这里我们已经知道配置文件保存在哪里了，然后如果配置文件不存在，则会创建一个文件。回到`ConnectDialog`，图形化界面是根据对应gateway的默认配置设置的，然后看本地的文件中是否有对应的配置，有则填入。最后在connect函数中将内存中的配置存入文件，完成闭环。
			+ 然后是`self.add_action`方法，我们进去看这个方法是创建一个`QtGui.QAction`（感性理解其作用）它和参数中的函数`func`“产生联系”，而这个动作被添加到参数`menu`中
				+ 回到调用该函数的语句就发现就是“连接”添加了调用partial过的connect函数这个动作。
		+ 继续往下看，给出了主窗口如何调用各种App的窗口
			```python
			app_menu: QtWidgets.QMenu = bar.addMenu("功能")
			all_apps: List[BaseApp] = self.main_engine.get_all_apps()
	        for app in all_apps:
	            ui_module: ModuleType = import_module(app.app_module + ".ui")
	            widget_class: QtWidgets.QWidget = getattr(ui_module, app.widget_name)  # noqa
	            func: Callable = partial(self.open_widget, widget_class, app.app_name)  # noqa
	            self.add_action(app_menu, app.display_name, app.icon_name, func, True)  # noqa
			```

			我们仍然暂时忽略主引擎的部分，这段代码其实相当的Python。首先是找到对应app的module（python万物即对象，而module可以理解既是文件又是对象），然后找到这个module/文件下的`ui` module/文件，然后app.widget_name本身是一个字符串，我可以预告下，这个字符串的内容就是对应app主窗口的类的名字，这里通过`getattr`使用字符串在一个module中拿到对应的类；然后就是`self.open_widget`这个方法，它首先是在内存中通过app名找到是否有窗口，否则则创建（通过这样的方式避免重复创建），然后运行窗口；在循环的最后通过`add_action`将这个函数转换成动作并添加到Menu中。

		+ 还是在这个方法中，下面为“帮助”这个选项卡添加按钮，这里的`add_action`我们已经遇到很多次了，这里对应的看添加的动作使用的是哪个函数即可
			+ 关于“查询合约”，这里打开了一个`ContractManager`这个Widget，点击会触发`show_contracts`方法，在这个方法中通过主引擎的`get_all_contracts`方法得到信息，我们发现数据最后还是来自主引擎，但是我们还没有分析主引擎，所以暂时先留下一个hook
			+ 关于“还原窗口”，这里将关于窗口的信息保存到本地（这里的路径是在`.config`下的），上面讨论过

## Engine

### event engine

+ Pre:
	+ 生产者-消费者模型：通过缓冲区交流
	+ 发布-订阅设计模式：通过中介/消息代理交流
		+ 发布者将消息发送到中介。
		+ 中介将消息给到订阅了该**类**消息的订阅者。

+ 事件驱动引擎，可以认为是发布-订阅设计模式的一种实现，引擎即为发布-订阅设计模式中的中介。  
	见代码`vnpy/event/engine.py`（下面的讲解有该模式本身，也有该模式在Python中的实现，也有在vnpy中的实现）
	+ 事件：即类`Event`，两个属性分别表示事件的类型和数据
	+ 事件处理器：即`HandlerType: callable = Callable[[Event], None]`，就是一个函数，参数为事件，在某类事件出现时用参数为对应事件的事件处理器处理来处理表示订阅
	+ 事件驱动引擎`EventEngine`
		+ 事件注册：代码中最后两个方法，把一个事件处理器注册进引擎中，表示注册的事件处理器的参数的事件类型被订阅
		+ 事件队列：类的一个属性，是一个线程安全的队列，有个线程不断的从队列中出去事件，并用注册了该事件类型的事件处理器去处理该事件；而外界也可以不断往里`put`事件

### main engine
我们来到了vnpy的核心，在`vnpy/trader/`目录下

+ `event.py`：很简短，各常量是事件引擎中的事件的类型
+ `setting.py`：很简短，关于UI的初始化配置。
	+ 值得一提的是，`Dict`的`update`是对参数有的键才更新，所以这里逻辑是合理的。还记得这个读取配置的`load_json`函数中嘛？它在没有对应文件的时候会创建对应文件，那么这个配置文件什么时候被写入的呢？我们看`mainwindows.py`的这里
		```python
		action: QtGui.QAction = QtWidgets.QAction("配置", self)
		action.triggered.connect(self.edit_global_setting)
		bar.addAction(action)
		```
		这里的`self.edit_global_setting`方法会创建一个`GlobalDialog`对象，在这个类中的方法`update_setting`中调用了`save_json`函数

+ app基类在`app.py`的`BaseApp(ABC)`，所有app都派生自该基类  
	gateway基类在`gateway.py`的`BaseGateway(ABC)`，所有gateway都派生自该基类

+ `engine.py`：核心，事件驱动引擎是基础设施，主引擎`mainengne`则是使用者，管理各个app和gateway，为它们对接event engine，还会对接不同app中的引擎
	+ 这里有个属性就是事件驱动引擎，这里受限于Python的语义，它不应该理解为一个包含在mainengine里的engine，而是指针，指向mainengine使用的engine
	+ 这里有个`BaseEngine`基类，各个app中的引擎由该基类派生，我们看它的定义有一个engine和mainengine，这里的理解和上面类似，表示“归属于”哪个mainengine，用的是哪个event engine。
		>这里可以管中窥豹一下，各大app中的引擎为什么需要知道event engine呢？因为整体上就只有一个event engine，即使是app中的engine，也是用的这个event engine

		实际上，其他engine就是用的整体的event engine，但是并非没有自己独立运行“逻辑”的能力，有单开一个线程的，有用`ThreadPoolExecutor`的，所以下面如果遇到不应惊讶，我也不会专门的提。


	+ 这个代码中还有派生自`BaseEngine`的三个类：`LogEngine`、`OmsEngine`、`EmailEngine`
		+ OmsEngine是重点，我们发现有大量的事件和事件对应的事件处理器在这里被注册进事件驱动引擎的。
			>这个类的意义就是专门用来添加方法的，不然这么多的内容注册放在MainEngine中会很乱。

		+ LogEngine是用来初始化一个`logging`模块的，就像上面说的，它的处理仍然使用的MainEngine的EventEngine

		+ EmailEngine则有独立的线程，专门处理，这个就是少有的没有使用整体event engine的engine，因为它只有一个任务嘛，就一个个丢进子线程中去运行

下面会分别结合gateway和app来解释vnpy整体上是怎么工作的。

## Infrastructure

关于协程的基本知识可以查看我的[笔记](https://github.com/zweix123/CS-notes/blob/master/Programing-Language/Python/Concurrency.md#%E5%8D%8F%E7%A8%8B)，这里讲一些vnpy对相关api的使用。

启动是这样的语句
```python
"""启动客户端的事件循环"""
try:
	self.loop = get_running_loop()
except RuntimeError:
	self.loop = new_event_loop()

start_event_loop(self.loop)
```
这里就是找到一个正在运行的event loop，如果找不到则创建一个，然后用这个event loop去运行`start_event_loop`这个函数，那么这个函数是什么呢？
```python
def start_event_loop(loop: AbstractEventLoop) -> None:
    """启动事件循环"""
    # 如果事件循环未运行，则创建后台线程来运行
    if not loop.is_running():
        thread = Thread(target=run_event_loop, args=(loop,))
        thread.daemon = True
        thread.start()
```
我们发现这个协程是丢给一个线程去运行的，具体是让一个线程去运行`run_event_loop`这个函数，那么这又是什么函数呢？
```python
def run_event_loop(loop: AbstractEventLoop) -> None:
    """运行事件循环"""
    set_event_loop(loop)
    loop.run_forever()
```
这里就明朗了，vnpy将拿到/创建的event loop作为当前的event loop并让它一直运行，而这个运行也是在子线程中。
>在拿到event loop的语句里，基本就是通过catch exception创建，所以这里语义上是需要这个异常的，且预测这个异常就应该出现。

这里我们的当前线程就是不断的将任务给到运行在子线程的event loop了，怎么做的呢？
```python
coro: coroutine = 一个使用关键字async标记的函数
fut: Future = run_coroutine_threadsafe(coro, self.loop)
return fut.result()
```
这里的`coro`是一个coroutine object，通过api `run_coroutine_threadsafe`交给event loop去运行，然后拿到结果。

### vnpy_rest

有了上面的解释，这份代码就非常好理解了。

其中`Request`和`Reponse`这两个类就是数据传输对象

对于`RestClient`，其中的`request`方法即是发送一个request，得到reponse；`add_request`则是通过回调函数去处理request的reponse。

### vnpy_websocket

和vnpy_rest非常类似。

+ `send_packet(dict)`发包：包括编码和发包
+ `unpack_data(str)`解包：没有收包，只有编码

+ `start`会在子线程的event loop中运行这样一个函数`_run`，在这里不断的建立连接，处理收到的信息和断开连接，共有三个回调函数
	+ `on_packet(dict)`对收到的信息的处理（dict已经被unpack_data解包）
	+ `on_connected()`连接回调
	+ `on_disconnected()`断开回调

	这三个函数由子类实现继而实现对应功能

## Gateway

这里的复杂性体现在子类实现大量的基类要求的那些函数，而整体逻辑上不难。

值得一提的是关于websocket相关派生类的回调，它是做了一个字符串到函数的映射，在`on_packet`的回调用通过字符串找到对应的函数去处理对应的数据。

### vnpy_okex
>目前(2023.4.18)，vnpy官网的版本还有bug，可以使用我的版本。

## App
关于主窗口如何和各个app的窗口产生连接已经在ui部分讨论过，可以看到各个app目录下的`__init__.py`文件中派生自`BaseApp`的类的两个属性`engine_class`和`widget_name`，分别指app使用的引擎和窗口，引擎是一个具体的类的实现，窗口是是一个类的名字的字符串，为什么这样也在ui部分讨论过了。这里的引擎，最终使用的也是主引擎的时间驱动引擎，这部分也在主引擎部分讨论过了。所以这里的app的引擎更像是main engine而不是event engine，是event engine的使用者。

### vnpy_ctastrategy
相信您对这个app最好奇的地方一定是它是怎么将我们通过派生`CtaTemplate`的方式写的策略去执行的