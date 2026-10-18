#!/system/bin/sh
# s20fe: para serviços de hardware que o console não usa, para liberar RAM (roda pelo Magisk, service.d).
# Câmera (~120 MB), leitor de digital (~20 MB), IA/NN (~11 MB), elemento seguro (pagamento NFC).
# Para voltar: apagar este arquivo de /data/adb/service.d e reiniciar.
SERVICES="vendor.camera.provider cameraserver vendor.fingerprint-default neuralnetworks_hal_service vendor.secure_element_hal_service gto_secure_element_aidl_service"
LOG=/data/local/tmp/s20fe-slim.log
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 2; done
sleep 20   # deixa o system_server terminar de subir antes
for s in $SERVICES; do
    stop "$s" 2>/dev/null
done
sleep 2
echo "$(date '+%F %T') parados: $(for s in $SERVICES; do echo -n "$s=$(getprop init.svc.$s) "; done)" >> $LOG
