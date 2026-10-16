"""Normal HMI behaviour: poll the PLC (tank level + pump state) every second."""
import time
from pymodbus.client import ModbusTcpClient
PLC = "172.28.0.10"
c = ModbusTcpClient(PLC, port=502)
c.connect()
while True:
    coils = c.read_coils(0, 2)          # %QX0.0 pump, %QX0.1 valve
    regs = c.read_holding_registers(0, 2)  # %QW0 level, %QW1 setpoint
    print("coils:", coils.bits[:2] if not coils.isError() else coils,
          "regs:", regs.registers if not regs.isError() else regs)
    time.sleep(1)
