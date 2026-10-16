PROGRAM tank
  VAR
    level AT %QW0 : INT := 50;
    setpoint AT %QW1 : INT := 50;
    pump AT %QX0.0 : BOOL;
    valve AT %QX0.1 : BOOL;
  END_VAR
  VAR
    tick : TON;
  END_VAR

  tick(IN := NOT tick.Q, PT := T#500ms);
  IF tick.Q THEN
    IF pump AND level < 100 THEN level := level + 1; END_IF;
    IF (NOT pump) AND level > 0 THEN level := level - 1; END_IF;
  END_IF;

  IF level < setpoint - 5 THEN pump := TRUE; END_IF;
  IF level > setpoint + 5 THEN pump := FALSE; END_IF;
END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK plc_task(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH plc_task : tank;
  END_RESOURCE
END_CONFIGURATION
