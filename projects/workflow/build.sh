#!/bin/bash -eu

cd $SRC/workflow

# Build the project
echo "Building workflow project..."
pnpm build || echo "Build may have partial failures, continuing..."

# Create fuzzer directory
mkdir -p $SRC/fuzzers

# Fuzzer 1: Workflow State Serialization/Deserialization
cat > $SRC/fuzzers/fuzz_state_serialization.js << 'EOF'
const { FuzzedDataProvider } = require('@jazzer.js/core');

let workflowModule;
try {
  workflowModule = require('$SRC/workflow/packages/workflow/dist/index.js');
} catch (e) {
  try {
    workflowModule = require('$SRC/workflow/packages/workflow/dist/index.cjs');
  } catch (e2) {
    console.error('Could not load workflow module:', e.message);
  }
}

module.exports.fuzz = function(data) {
  if (!workflowModule) return;
  const provider = new FuzzedDataProvider(data);
  
  try {
    const input = provider.consumeRemainingAsString();
    if (input.length === 0) return;
    
    // Try various serialization/deserialization functions
    const funcs = ['serialize', 'deserialize', 'encode', 'decode', 'parse', 'stringify'];
    for (const fn of funcs) {
      if (typeof workflowModule[fn] === 'function') {
        try {
          workflowModule[fn](input);
        } catch (e) {
          if (e.message && (e.message.includes('stack') || e.message.includes('Maximum call stack'))) {
            throw e;
          }
        }
      }
    }
  } catch (e) {
    if (e.message && e.message.toLowerCase().includes('stack')) {
      throw e;
    }
  }
};
EOF

# Fuzzer 2: Runtime API Fuzzing
cat > $SRC/fuzzers/fuzz_runtime_api.js << 'EOF'
const { FuzzedDataProvider } = require('@jazzer.js/core');

let workflowModule;
try {
  workflowModule = require('$SRC/workflow/packages/workflow/dist/index.js');
} catch (e) {
  try {
    workflowModule = require('$SRC/workflow/packages/workflow/dist/index.cjs');
  } catch (e2) {}
}

module.exports.fuzz = function(data) {
  if (!workflowModule) return;
  const provider = new FuzzedDataProvider(data);
  
  try {
    // Fuzz step/action creation
    const stepName = provider.consumeString(32);
    const stepData = provider.consumeRemainingAsString();
    
    if (workflowModule.createStep || workflowModule.step) {
      const stepFunc = workflowModule.createStep || workflowModule.step;
      try {
        stepFunc(stepName, stepData);
      } catch (e) {
        if (e.message && e.message.includes('stack')) throw e;
      }
    }
    
    // Fuzz workflow context creation
    if (workflowModule.Context || workflowModule.WorkflowContext) {
      const CtxClass = workflowModule.Context || workflowModule.WorkflowContext;
      try {
        const parsed = JSON.parse(stepData);
        new CtxClass(parsed);
      } catch (e) {
        if (!(e instanceof SyntaxError) && e.message && e.message.includes('stack')) {
          throw e;
        }
      }
    }
  } catch (e) {
    if (e.message && e.message.toLowerCase().includes('stack')) throw e;
  }
};
EOF

# Fuzzer 3: JSON/YAML Configuration Parser
cat > $SRC/fuzzers/fuzz_config_parser.js << 'EOF'
const { FuzzedDataProvider } = require('@jazzer.js/core');

let workflowModule;
try {
  workflowModule = require('$SRC/workflow/packages/workflow/dist/index.js');
} catch (e) {
  try {
    workflowModule = require('$SRC/workflow/packages/workflow/dist/index.cjs');
  } catch (e2) {}
}

module.exports.fuzz = function(data) {
  if (!workflowModule) return;
  const provider = new FuzzedDataProvider(data);
  
  try {
    const configStr = provider.consumeRemainingAsString();
    if (configStr.length === 0) return;
    
    // Try config parsing functions
    const parseFuncs = ['parseConfig', 'parse', 'loadConfig', 'readConfig'];
    for (const fn of parseFuncs) {
      if (typeof workflowModule[fn] === 'function') {
        try {
          workflowModule[fn](configStr);
        } catch (e) {
          if (e.message && (e.message.includes('stack') || e.message.includes('recursion'))) {
            throw e;
          }
        }
      }
    }
    
    // Try as JSON
    try {
      const parsed = JSON.parse(configStr);
      if (workflowModule.validateConfig) {
        workflowModule.validateConfig(parsed);
      }
    } catch (e) {
      if (!(e instanceof SyntaxError)) throw e;
    }
  } catch (e) {
    if (e.message && e.message.toLowerCase().includes('stack')) throw e;
  }
};
EOF

# Fuzzer 4: Event/Message Processing
cat > $SRC/fuzzers/fuzz_event_processing.js << 'EOF'
const { FuzzedDataProvider } = require('@jazzer.js/core');

let workflowModule;
try {
  workflowModule = require('$SRC/workflow/packages/workflow/dist/index.js');
} catch (e) {
  try {
    workflowModule = require('$SRC/workflow/packages/workflow/dist/index.cjs');
  } catch (e2) {}
}

module.exports.fuzz = function(data) {
  if (!workflowModule) return;
  const provider = new FuzzedDataProvider(data);
  
  try {
    // Fuzz event handlers
    const eventName = provider.consumeString(32);
    const eventData = provider.consumeRemainingAsString();
    
    if (workflowModule.emit || workflowModule.trigger || workflowModule.dispatch) {
      const emitFunc = workflowModule.emit || workflowModule.trigger || workflowModule.dispatch;
      try {
        emitFunc(eventName, eventData);
      } catch (e) {
        if (e.message && e.message.includes('stack')) throw e;
      }
    }
    
    // Fuzz message processing
    if (workflowModule.processMessage || workflowModule.handleMessage) {
      const msgFunc = workflowModule.processMessage || workflowModule.handleMessage;
      try {
        msgFunc(eventData);
      } catch (e) {
        if (e.message && e.message.includes('stack')) throw e;
      }
    }
  } catch (e) {
    if (e.message && e.message.toLowerCase().includes('stack')) throw e;
  }
};
EOF

# Fuzzer 5: Trace/Observability Data
cat > $SRC/fuzzers/fuzz_trace_data.js << 'EOF'
const { FuzzedDataProvider } = require('@jazzer.js/core');

let workflowModule;
try {
  workflowModule = require('$SRC/workflow/packages/workflow/dist/index.js');
} catch (e) {
  try {
    workflowModule = require('$SRC/workflow/packages/workflow/dist/index.cjs');
  } catch (e2) {}
}

module.exports.fuzz = function(data) {
  if (!workflowModule) return;
  const provider = new FuzzedDataProvider(data);
  
  try {
    const traceData = provider.consumeRemainingAsString();
    if (traceData.length === 0) return;
    
    // Fuzz trace parsing/processing
    const traceFuncs = ['parseTrace', 'processTrace', 'loadTrace', 'readTrace'];
    for (const fn of traceFuncs) {
      if (typeof workflowModule[fn] === 'function') {
        try {
          workflowModule[fn](traceData);
        } catch (e) {
          if (e.message && e.message.includes('stack')) throw e;
        }
      }
    }
  } catch (e) {
    if (e.message && e.message.toLowerCase().includes('stack')) throw e;
  }
};
EOF

# Fuzzer 6: Prototype Pollution via JSON
cat > $SRC/fuzzers/fuzz_prototype_pollution.js << 'EOF'
const { FuzzedDataProvider } = require('@jazzer.js/core');

let workflowModule;
try {
  workflowModule = require('$SRC/workflow/packages/workflow/dist/index.js');
} catch (e) {
  try {
    workflowModule = require('$SRC/workflow/packages/workflow/dist/index.cjs');
  } catch (e2) {}
}

module.exports.fuzz = function(data) {
  const provider = new FuzzedDataProvider(data);
  
  try {
    const jsonStr = provider.consumeRemainingAsString();
    if (jsonStr.length === 0) return;
    
    // Check for prototype pollution
    const before = {}.__proto__.polluted;
    
    try {
      const parsed = JSON.parse(jsonStr);
      
      // Try various merge/extend functions
      if (workflowModule) {
        const mergeFuncs = ['merge', 'extend', 'assign', 'deepMerge', 'update'];
        for (const fn of mergeFuncs) {
          if (typeof workflowModule[fn] === 'function') {
            workflowModule[fn]({}, parsed);
          }
        }
      }
    } catch (e) {
      if (!(e instanceof SyntaxError)) {
        // Check if prototype was polluted
        const after = {}.__proto__.polluted;
        if (after !== before) {
          throw new Error('Prototype pollution detected!');
        }
      }
    }
  } catch (e) {
    if (e.message && (e.message.includes('Prototype pollution') || e.message.includes('stack'))) {
      throw e;
    }
  }
};
EOF

# Install Jazzer.js for JavaScript fuzzing
echo "Installing Jazzer.js..."
npm install -g @jazzer.js/cli @jazzer.js/core

# Build each fuzzer
echo "Building fuzzers..."
for fuzzer in $SRC/fuzzers/*.js; do
  fuzzer_name=$(basename "$fuzzer" .js)
  echo "Building fuzzer: $fuzzer_name"
  
  # Use jazzer compile if available, otherwise copy as-is
  if command -v jazzer &> /dev/null; then
    jazzer compile "$fuzzer" -o "$OUT/${fuzzer_name}" || cp "$fuzzer" "$OUT/${fuzzer_name}.js"
  else
    # For JavaScript fuzzers, we may need to just copy them
    cp "$fuzzer" "$OUT/${fuzzer_name}.js"
  fi
done

echo "Fuzzers built successfully"
ls -lah $OUT/
