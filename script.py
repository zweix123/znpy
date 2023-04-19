from time import sleep
from vnpy_scripttrader import ScriptEngine


def run(engine: ScriptEngine):
    while True:
        engine.write_log("1")
        sleep(1)
