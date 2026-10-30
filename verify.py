import lupa
import sys

lua = lupa.LuaRuntime(unpack_returned_tuples=True)

with open("C:/Users/WINDOWS 10/Desktop/ShadowProtocol/_test_harness.lua", "r") as f:
    code = f.read()

try:
    lua.execute(code)
    print("\nALL TESTS COMPLETED")
except Exception as e:
    print("ERROR:", str(e))
    import traceback
    traceback.print_exc()
    sys.exit(1)
