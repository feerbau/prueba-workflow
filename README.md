# Workflow Fuzzing Configuration

Este directorio contiene la configuración necesaria para fuzzear el proyecto [vercel/workflow](https://github.com/vercel/workflow) usando Buttercup.

## Estructura

```
oss-fuzz/
└── projects/
    └── workflow/
        ├── project.yaml   # Metadata del proyecto
        ├── Dockerfile     # Entorno de build
        └── build.sh       # Script de compilación de fuzzers
```

## Fuzzers Incluidos

### 1. State Serialization Fuzzer
- **Objetivo:** Serialización/deserialización de estado de workflow
- **Busca:** Buffer overflows, injection, crashes en parseo, stack overflow

### 2. Runtime API Fuzzer
- **Objetivo:** APIs de runtime (createStep, Context, etc.)
- **Busca:** Crashes, memory leaks, stack overflow

### 3. Configuration Parser Fuzzer
- **Objetivo:** Parseo de archivos de configuración JSON/YAML
- **Busca:** Stack overflow, DoS, injection, malformed input handling

### 4. Event Processing Fuzzer
- **Objetivo:** Sistema de eventos y mensajes
- **Busca:** Race conditions, event injection, crashes

### 5. Trace/Observability Fuzzer
- **Objetivo:** Parseo de datos de tracing
- **Busca:** Information disclosure, crashes en parseo

### 6. Prototype Pollution Fuzzer
- **Objetivo:** Detección de prototype pollution en merge/extend
- **Busca:** Prototype pollution, object injection

## Pasos para Usar

### 1. Crear Repositorio de Fuzz-Tooling

**NO necesitas hacer fork del proyecto vercel/workflow** - Buttercup lo clonará automáticamente.

Solo crea un nuevo repositorio para la configuración de fuzzing:

```bash
cd /home/bote/buttercup/workflow-fuzz-setup
git init
git add .
git commit -m "Add workflow fuzzing configuration for Buttercup"
git remote add origin git@github.com:TU-USUARIO/workflow-fuzz-tooling.git
git push -u origin main
```

### 2. Enviar Tarea a Buttercup

#### Opción A: Usando el script

```bash
kubectl port-forward -n crs service/buttercup-ui 31323:1323 &

DATA='{
  "challenge_repo_url": "https://github.com/vercel/workflow.git",
  "challenge_repo_base_ref": "main",
  "challenge_repo_head_ref": "main",
  "fuzz_tooling_url": "git@github.com:TU-USUARIO/workflow-fuzz-tooling.git",
  "fuzz_tooling_ref": "main",
  "fuzz_tooling_project_name": "workflow",
  "duration": 7200
}'

./orchestrator/scripts/custom_task_crs.sh "$DATA"
```

#### Opción B: Usando curl directamente

```bash
curl -X 'POST' 'http://localhost:31323/webhook/trigger_task' \
  -H 'Content-Type: application/json' \
  -d '{
    "challenge_repo_url": "https://github.com/vercel/workflow.git",
    "challenge_repo_base_ref": "main",
    "challenge_repo_head_ref": "main",
    "fuzz_tooling_url": "git@github.com:TU-USUARIO/workflow-fuzz-tooling.git",
    "fuzz_tooling_ref": "main",
    "fuzz_tooling_project_name": "workflow",
    "duration": 7200
  }'
```

### 3. Monitorear Progreso

```bash
# Ver estado general
make status

# Ver logs del scheduler
kubectl logs -n crs -l app=scheduler --tail=-1 -f

# Ver logs del fuzzer
kubectl logs -n crs -l app=fuzzer --tail=100 -f

# Ver logs de LiteLLM (para ver uso de OpenRouter)
kubectl logs -n crs -l app.kubernetes.io/name=litellm --tail=100 -f
```

## Personalización

### Agregar Más Fuzzers

Edita `build.sh` y agrega nuevos fuzzers en la sección de fuzzers. Por ejemplo:

```javascript
// Fuzzer 4: Runtime API
cat > $SRC/fuzzers/fuzz_runtime_api.js << 'EOF'
const { FuzzedDataProvider } = require('@jazzer.js/core');

let RuntimeAPI;
try {
  const workflow = require('$SRC/workflow/packages/workflow/dist/index.js');
  RuntimeAPI = workflow.RuntimeAPI;
} catch (e) {
  console.error('Could not load RuntimeAPI:', e.message);
}

module.exports.fuzz = function(data) {
  const provider = new FuzzedDataProvider(data);
  
  try {
    if (RuntimeAPI) {
      const input = provider.consumeRemainingAsBytes();
      // Test runtime API with fuzzed input
      RuntimeAPI.process(input);
    }
  } catch (e) {
    // Handle errors
  }
};
EOF
```

### Ajustar Duración

Para proyectos grandes como workflow, considera aumentar la duración:

```json
{
  "duration": 86400  // 24 horas
}
```

## Troubleshooting

### Error: "Could not find project.yaml"
- Verifica que la estructura esté correcta
- Asegúrate que `fuzz_tooling_project_name` sea exactamente "workflow"

### Build Failures
- Verifica que pnpm install funcione
- Revisa los logs: `kubectl logs -n crs -l app=build-bot`

### No se encuentran vulnerabilidades
- Aumenta la duración
- Agrega más fuzzers específicos
- Verifica que los imports en los fuzzers sean correctos

## Notas

- Este es un proyecto TypeScript/JavaScript, por lo que usamos Jazzer.js
- Los fuzzers pueden necesitar ajustes según la estructura real de la API de workflow
- Considera agregar semillas (seed corpus) con ejemplos de configuraciones válidas
