#!/bin/sh

echo "Starting install script"
cd /scripts

KC=kubectl
${KC} get ns kubevirt-os-images >& /dev/null
if [ $? == 0 ]
then
    IMAGES_NS=kubevirt-os-images
else
    IMAGES_NS=openshift-virtualization-os-images
fi

echo "check if windows iso pvc got created"
pvc_ready=$(${KC} get pvc win2k19-install-iso -o jsonpath='{.status.phase}')
while [ "$pvc_ready" != "Bound" ]
do
    sleep 10
    pvc_ready=$(${KC} get pvc win2k19-install-iso -o jsonpath='{.status.phase}')
done


MYCM=$(${KC} get configmap -o name --sort-by=metadata.creationTimestamp | awk -F / '/windows-install-scripts/ {a=$2} END{ print a }')
echo "Using ${MYCM}"
sed "s/WININST_CM/${MYCM}/" windows-install-vm.yaml | ${KC} apply -f -

echo "Applied VM, waiting for VM to start"
sleep 5
vm_ready=$(${KC} get vm windows-install -o jsonpath='{.status.ready}')
while [ "$vm_ready" != "true" ]
do
    sleep 10
    vm_ready=$(${KC} get vm windows-install -o jsonpath='{.status.ready}')
done

echo "VM is started. Waiting for VMI to finish successfully."
vmi_phase=$(${KC} get vm windows-install -o jsonpath='{.status.printableStatus}')
while [ "$vmi_phase" != "Stopped" ]
do
    sleep 20
    vmi_phase=$(${KC} get vm windows-install -o jsonpath='{.status.printableStatus}')
done

echo "VM has finished installing"
${KC} apply -n ${IMAGES_NS} -f clone-boot-source.yaml
echo "Applied DataVolume to clone boot source image"

sleep 5

#replacing this to accomodate rosa
#dv_phase=$(${KC} -n ${IMAGES_NS} get dv win2k19 -o jsonpath='{.status.phase}')
#while [ "$dv_phase" != "Succeeded" ]
#do
#    sleep 10
#    dv_phase=$(${KC} -n ${IMAGES_NS} get dv win2k19 -o jsonpath='{.status.phase}')
#    echo $dv_phase
#done

echo "checking if the pvc for windows got created"
win_ready=$(${KC} get pvc -n openshift-virtualization-os-images win2k19 -o jsonpath='{.status.phase}')
while [ "$win_ready" != "Bound" ]
do
    sleep 10
    win_ready=$(${KC} get pvc -n openshift-virtualization-os-images win2k19 -o jsonpath='{.status.phase}')
done



echo "Cleaning up"
${KC} delete -f windows-install-vm.yaml

my_app_name=$(${KC} get cm windows-install-scripts -o jsonpath='{.metadata.labels.app\.kubernetes\.io/instance}')

echo "Finished"
