#!/bin/bash

echo "🔧 Agregando archivos al proyecto Xcode..."

# Abre Xcode y espera
open Decked.xcodeproj

echo "
📋 PASOS MANUALES EN XCODE:

1. Espera a que Xcode abra completamente
2. En el navegador izquierdo, haz RIGHT-CLICK en 'Decked' (carpeta azul)
3. Selecciona 'Add Files to Decked...'
4. Navega a: $(pwd)/Decked/
5. Selecciona estas carpetas (mantén Cmd):
   ✓ App
   ✓ Features  
   ✓ Models
   ✓ Services
   ✓ Shared

6. Asegúrate de marcar:
   ✓ Copy items if needed
   ✓ Create groups
   ✓ Target: Decked

7. Haz clic en 'Add'

8. Limpia y recompila:
   - Shift+Cmd+K (Clean)
   - Cmd+B (Build)
   - Cmd+R (Run)

✅ Listo! La app debería funcionar correctamente.
"
