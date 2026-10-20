# s20fe: controlador da ventoinha do console (Raspberry Pi Pico 2, CircuitPython 10.3.1).
# Quem decide a velocidade é o celular (scripts/fanctl.sh, que lê as temperaturas do SoC e da
# bateria). O Pico só obedece, protege e informa:
#  - recebe "F <0-100>" (relatório HID 1) e aplica o PWM na ventoinha (GP15);
#  - responde "S <aplicado> <rpm> <dissipador> <pico> <modo>" (modo C = celular, N = NTC local,
#    E = emergência); "-" quando não há tacômetro/NTC;
#  - partida: de parada para girando, 100% por PARTIDA_S (motor parado não arranca com PWM baixo);
#  - SEM SINAL do celular por SEM_SINAL_S (serviço caiu, celular travou): com NTC, curva local
#    pela temperatura do dissipador; sem NTC, 100%. A ventoinha nunca fica parada "às cegas".
# LED: aceso = celular no controle; piscando rápido = sem sinal (NTC/emergência).
# Ligações e montagem: hardware/README.md, seção 10.

import time

import analogio
import board
import digitalio
import microcontroller
import pwmio
import usb_hid

# ---- ajustes ---------------------------------------------------------------------------------
PINO_PWM = board.GP15        # pino 20 -> base do transistor (1 kΩ) ou gate do MOSFET (100 Ω)
PINO_TACO = None             # ventoinha de 2 fios: sem tacômetro (3/4 fios: board.GP14, pino 19)
PINO_NTC = board.GP26        # pino 31 <- divisor NTC 10k; None se não usar NTC
USA_NTC = False              # True depois de colar o NTC no dissipador
FREQ_PWM = 25000             # 25 kHz: fora da faixa audível
INVERTER = False             # True para ventoinha de 4 fios com o fio PWM puxado pelo transistor
MINIMO = 30                  # % mínimo em que a ventoinha gira de forma estável (medir no teste)
PARTIDA_S = 1.0
SEM_SINAL_S = 10
EMERGENCIA = 100
PULSOS_POR_VOLTA = 2
NTC_R25, NTC_BETA, NTC_SERIE = 10000, 3950, 10000
NTC_CURVA = (35, 45)         # dissipador: abaixo de 35 °C parada, 45 °C ou mais = 100%
# ----------------------------------------------------------------------------------------------

dev = usb_hid.devices[0]
pwm = pwmio.PWMOut(PINO_PWM, frequency=FREQ_PWM, duty_cycle=0)
led = digitalio.DigitalInOut(board.LED)
led.switch_to_output(False)

edicao = digitalio.DigitalInOut(board.GP22)       # jumper GP22-GND = modo de edição (boot.py)
edicao.switch_to_input(pull=digitalio.Pull.UP)
MODO_EDICAO = not edicao.value

taco = None
if PINO_TACO is not None:
    try:
        import countio
        taco = countio.Counter(PINO_TACO, edge=countio.Edge.FALL, pull=digitalio.Pull.UP)
    except (ImportError, ValueError):
        taco = None

ntc = analogio.AnalogIn(PINO_NTC) if USA_NTC and PINO_NTC is not None else None


def temp_ntc():
    """NTC entre o pino e o GND, resistor de 10k entre o pino e o 3V3."""
    if ntc is None:
        return None
    import math
    v = ntc.value / 65535
    if v <= 0.01 or v >= 0.99:          # fio solto ou em curto
        return None
    r = NTC_SERIE * v / (1 - v)
    return 1 / (1 / 298.15 + math.log(r / NTC_R25) / NTC_BETA) - 273.15


def curva_local(t):
    if t is None:
        return EMERGENCIA
    ini, fim = NTC_CURVA
    if t < ini:
        return 0
    if t >= fim:
        return 100
    return MINIMO + (t - ini) * (100 - MINIMO) / (fim - ini)


def escrever(pct):
    pct = max(0, min(100, pct))
    v = int(pct * 65535 / 100)
    pwm.duty_cycle = 65535 - v if INVERTER else v


def main():
    pedido = EMERGENCIA
    ultimo_rx = None                    # nunca recebeu: começa em emergência até o celular falar
    aplicado = 0
    partida_ate = 0.0
    rpm = None
    taco_t = time.monotonic()
    modo = "E"
    t_dis = None
    pisca = 0.0

    while True:
        agora = time.monotonic()

        rel = dev.get_last_received_report(1)
        if rel:
            partes = bytes(rel).split(b"\x00")[0].decode("ascii", "ignore").split()
            if len(partes) >= 2 and partes[0] == "F":
                try:
                    pedido = int(partes[1])
                    ultimo_rx = agora
                except ValueError:
                    pass

        t_dis = temp_ntc()
        if ultimo_rx is not None and agora - ultimo_rx <= SEM_SINAL_S:
            alvo, modo = pedido, "C"
        elif ntc is not None and t_dis is not None:
            alvo, modo = curva_local(t_dis), "N"
        else:
            alvo, modo = EMERGENCIA, "E"
        alvo = int(max(0, min(100, alvo)))
        if 0 < alvo < MINIMO:
            alvo = MINIMO

        if aplicado == 0 and alvo > 0:
            partida_ate = agora + PARTIDA_S
        aplicado = alvo
        escrever(100 if (alvo > 0 and agora < partida_ate) else alvo)

        if taco is not None and agora - taco_t >= 1.0:
            pulsos = taco.count
            taco.reset()
            rpm = int(pulsos * 60 / PULSOS_POR_VOLTA / (agora - taco_t))
            taco_t = agora

        if rel:                         # responde a cada pedido do celular
            texto = "S %d %s %s %.1f %s" % (
                aplicado,
                "-" if rpm is None else rpm,
                "-" if t_dis is None else "%.1f" % t_dis,
                microcontroller.cpu.temperature,
                modo,
            )
            buf = bytearray(32)
            b = texto.encode()[:32]
            buf[: len(b)] = b
            try:
                dev.send_report(buf, 1)
            except OSError:
                pass

        if modo == "C":
            led.value = True
        elif agora >= pisca:
            led.value = not led.value
            pisca = agora + 0.15

        time.sleep(0.05)


try:
    main()
except Exception as e:  # noqa: BLE001 — qualquer erro: no console, reinicia o Pico
    print("erro:", repr(e))
    if not MODO_EDICAO:
        time.sleep(1)
        microcontroller.reset()
    raise
