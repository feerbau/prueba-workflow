FROM gcr.io/oss-fuzz-base/base-builder

# Install Node.js and npm/pnpm (build dependencies)
RUN apt-get update && apt-get install -y \
    nodejs npm \
    && npm install -g pnpm \
    && rm -rf /var/lib/apt/lists/*

# Install Jazzer.js for JavaScript fuzzing
RUN npm install -g @jazzer.js/instrumentor

# Create source directories
RUN mkdir -p $SRC/workflow $WORK/fuzzers

# Clone the workflow repository
RUN git clone --depth 1 https://github.com/vercel/workflow $SRC/workflow

WORKDIR $SRC/workflow

# Install project dependencies
RUN pnpm install --frozen-lockfile 2>&1 || true

# Copy build script
COPY build.sh $SRC/
RUN chmod +x $SRC/build.sh
