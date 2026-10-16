# SCADA / OT Security Lab: Modbus Attack, Detection and Hardening

A small, self-contained lab that shows why industrial control protocols are risky, how to detect an attack on them, and how to block it. Everything runs in Docker on one laptop, using free and open-source tools.

**Stack:** Docker, OpenPLC, Modbus TCP, pymodbus, Suricata IDS, iptables

> For learning only. Run it on an isolated local network. The default OpenPLC login (`openplc` / `openplc`) is used on purpose for the lab and must never be used on a real system.

---

## The problem

Modbus TCP has no login and no encryption. Any machine that can reach port 502 can read or change what a PLC is doing.

## What I built

Four containers on one isolated network (`172.28.0.0/24`):

| Role | Tool | IP | Job |
|------|------|----|-----|
| PLC | OpenPLC | 172.28.0.10 | Runs a tank/pump control program, Modbus server on port 502 |
| HMI | Python (pymodbus) | 172.28.0.20 | The real operator station |
| Attacker | Python (pymodbus) | 172.28.0.30 | An unauthorized machine on the same network |
| IDS | Suricata | shares the PLC's network | Watches all traffic going to the PLC |

The PLC program (`plc/pump_level.st`) keeps a tank level near a setpoint of 50 by switching a pump on and off.

## Stage 1: Normal operation

The HMI reads the tank once a second. The level moves between about 44 and 56 around the setpoint of 50.

![HMI normal operation](screenshots/hmi_normal.png)

## Stage 2: Attack

The attacker writes the setpoint to 0. The PLC accepts it and no password is asked.

```
write_register(1 -> 0) result: WriteRegisterResponse 1 => 0
```

![Attack succeeds](screenshots/attack_success.png)

## Stage 3: Detection

A Suricata rule raises an alert for any Modbus write that does not come from the HMI:

```
alert modbus !172.28.0.20 any -> 172.28.0.10 502 (msg:"OT LAB Unauthorized Modbus write to PLC"; modbus: access write; sid:1000001; rev:1;)
```

The alert names the attacker's address:

![Suricata alert](screenshots/suricata_alert.png)

## Stage 4: Hardening

A firewall on the PLC (`harden.sh`) allows port 502 only from the HMI and drops everyone else:

```
iptables -A INPUT -p tcp --dport 502 -s 172.28.0.20 -j ACCEPT
iptables -A INPUT -p tcp --dport 502 -j DROP
```

![Firewall rules](screenshots/firewall_rules.png)

The same attack now fails:

![Attack blocked](screenshots/attack_blocked.png)

The real HMI keeps working:

![HMI still works](screenshots/hmi_still_works.png)

| Check | Before hardening | After hardening |
|-------|------------------|-----------------|
| Attacker can write to the PLC | Yes | No (connection timed out) |
| HMI can read and write | Yes | Yes |

## How it maps to IEC 62443

- **Zones:** PLC and HMI form the control zone. The attacker sits in an untrusted zone.
- **Conduit:** the network path to port 502. The firewall controls that boundary.
- **FR1 (Identification and Authentication):** Modbus has none. This is the weakness shown here.
- **FR5 (Restricted Data Flow):** the allow-list firewall enforces the zone boundary.
- **FR6 (Timely Response to Events):** Suricata detects and logs the unauthorized access.

## Run it yourself

Needs Docker Desktop.

1. `docker compose up -d --build` (the first build takes 15 to 20 minutes while OpenPLC compiles)
2. Open http://localhost:8080 and sign in with `openplc` / `openplc`
3. Programs, upload `plc/pump_level.st`, launch it. Settings, enable the Modbus server. Dashboard, Start PLC.
4. `docker exec hmi pip install -r /scripts/requirements.txt` and the same for `attacker`
5. Normal traffic: `docker exec hmi python /scripts/hmi_read.py`
6. Attack: `docker exec attacker python /scripts/attack_write.py 0`
7. Alerts: `docker exec ids cat /var/log/suricata/fast.log`
8. Harden: `docker cp harden.sh plc:/harden.sh` then `docker exec plc sh /harden.sh`, then repeat step 6
9. Reset the setpoint: `docker exec hmi python /scripts/attack_write.py 50`
10. Stop: `docker compose stop`

## Limits

- It is a simulation. There is a software PLC and no real hardware.
- Modbus itself is still unauthenticated. Only the network path is protected, so a compromised HMI would still be trusted.
- The network is flat. A real plant would add a DMZ, one-way gateways and secure protocols such as OPC UA.
