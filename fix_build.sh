#!/bin/bash

echo "🔧 Creando script de limpieza..."

# Cerrar Xcode
killall Xcode 2>/dev/null
sleep 2

# Limpiar todo
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf .build
rm -rf Decked.xcodeproj/xcuserdata
rm -rf Decked.xcodeproj/project.xcworkspace/xcuserdata

echo "✅ Cache limpiado"

# Crear un nuevo build script
cat > rebuild.command << 'REBUILD'
#!/bin/bash
cd "$(dirname "$0")"
xcodebuild clean -project Decked.xcodeproj -scheme Decked
xcodebuild build -project Decked.xcodeproj -scheme Decked -destination 'generic/platform=iOS'
REBUILD

chmod +x rebuild.command

echo "
✅ Limpieza completada

🎯 PRÓXIMOS PASOS:

1. Abre Xcode manualmente
2. Abre el proyecto Decked.xcodeproj
3. En el menu: Product → Clean Build Folder (Shift+Cmd+K)
4. Cierra el proyecto (File → Close Project)
5. Vuelve a abrir Decked.xcodeproj
6. Compila (Cmd+B)

Si persisten los errores, en Xcode:
- Product → Scheme → Manage Schemes
- Delete 'Decked' scheme
- Click '+' para crear uno nuevo
- Selecciona target 'Decked'
- Click 'Close'
- Intenta compilar de nuevo

"

