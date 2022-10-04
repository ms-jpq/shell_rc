assoc .env=EnvFile
ftype EnvFile=cat.exe -- "%1" %*

assoc .awk=Awk.File
ftype Awk.File=awk.exe --file "%1" %*
