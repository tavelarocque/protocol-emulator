"""The playground's TX words for examples/ws2812: three LEDs, red, green and
blue, encoded by the host driver the blind test's accept.py uses.

Usage: ws2812_words.py path/to/examples/ws2812/host.py"""
import importlib.util
import sys

spec = importlib.util.spec_from_file_location("ws2812_host", sys.argv[1])
host = importlib.util.module_from_spec(spec)
spec.loader.exec_module(host)
for word in host.encode([[(255, 0, 0), (0, 255, 0), (0, 0, 255)]]):
    print(word)
