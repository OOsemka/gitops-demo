# httpd container used for iso


**Manually setup deployment**
```
oc apply -k httpd-server/overlays/default
```

**Copy ISO to httpd container**
```
ISO_FILE=$HOME/win2k19.iso
POD_NAME=$(oc get pods --selector=app=httpd-server -o jsonpath='{.items[0].metadata.name}')
oc -v cp $HOME/win2k19.iso $POD_NAME:/opt/app-root/src
```