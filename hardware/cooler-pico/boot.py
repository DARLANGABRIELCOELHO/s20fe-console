# s20fe: boot do controlador da ventoinha (Raspberry Pi Pico 2, CircuitPython 10.3.1).
# Roda antes do code.py e define como o Pico aparece na USB:
#  - um único dispositivo HID "de fabricante" (usage page 0xFF00), sem teclado/mouse/controle:
#    o Android não o trata como entrada, só cria /dev/hidrawN, onde o fanctl.sh (root) escreve.
#    O kernel do celular não tem CONFIG_USB_ACM (porta serial USB), por isso HID e não serial.
#  - nome "s20fe S20FE Fan" (HID_NAME no uevent), que o fanctl.sh procura.
#  - sem MIDI; o drive CIRCUITPY fica escondido (o Android montaria o "pendrive" toda vez).
#
# MODO DE EDIÇÃO: ligar GP22 (pino 29) ao GND (pino 28) com um jumper ANTES de conectar o Pico.
# Aí o drive CIRCUITPY aparece no PC para trocar o code.py. Tirar o jumper e reconectar depois.

import board
import digitalio
import storage
import supervisor
import usb_hid
import usb_midi

# Relatório 1: 32 bytes de entrada (Pico -> celular) e 32 de saída (celular -> Pico), em texto.
DESCRITOR = bytes((
    0x06, 0x00, 0xFF,  # Usage Page (Vendor 0xFF00)
    0x09, 0x01,        # Usage (1)
    0xA1, 0x01,        # Collection (Application)
    0x85, 0x01,        #   Report ID (1)
    0x15, 0x00,        #   Logical Minimum (0)
    0x26, 0xFF, 0x00,  #   Logical Maximum (255)
    0x75, 0x08,        #   Report Size (8)
    0x95, 0x20,        #   Report Count (32)
    0x09, 0x02,        #   Usage (2)
    0x81, 0x02,        #   Input (Data, Var, Abs)
    0x09, 0x03,        #   Usage (3)
    0x91, 0x02,        #   Output (Data, Var, Abs)
    0xC0,              # End Collection
))

ventoinha = usb_hid.Device(
    report_descriptor=DESCRITOR,
    usage_page=0xFF00,
    usage=0x01,
    report_ids=(1,),
    in_report_lengths=(32,),
    out_report_lengths=(32,),
)
usb_hid.enable((ventoinha,))
usb_midi.disable()
supervisor.set_usb_identification(manufacturer="s20fe", product="S20FE Fan")

edicao = digitalio.DigitalInOut(board.GP22)
edicao.switch_to_input(pull=digitalio.Pull.UP)
if edicao.value:              # sem jumper = modo console
    storage.disable_usb_drive()
edicao.deinit()
